import json
import os
import subprocess
import tempfile
from flask import Flask, request, jsonify
from pydantic import BaseModel, ValidationError

app = Flask(__name__)

class Executor:
    def __init__(self):
        self.__nsjail_config = "/app/nsjail.cfg"
        self.__sandbox_dir = "/tmp/sandbox"

        self._error_prefix, self._error_suffix = "__ERROR_START__", "__ERROR_END__"
        self._result_prefix, self._result_suffix = "__RESULT_START__", "__RESULT_END__"

        os.makedirs(self.__sandbox_dir, exist_ok=True)

    def execute(self, code: str, timeout: int = 20):
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', dir=self.__sandbox_dir, delete=False) as f:
            wrapper_code = f"""
import json
import sys
import traceback

{code}

if __name__ == "__main__":
    try:
        if 'main' not in globals():
            raise Exception("No main() function found in script")

        result = main()

        if result is None:
            raise Exception("main() function must return a value")

        try:
            json.dumps(result)
        except (TypeError, ValueError):
            raise Exception("main() function must return JSON-serializable data")

        print("{self._result_prefix}")
        print(json.dumps(result))
        print("{self._result_suffix}")

    except Exception as e:
        print("{self._error_prefix}")
        print(str(e))
        print("{self._error_suffix}")
        sys.exit(1)
"""
            f.write(wrapper_code)
            script_path = f.name

        try:
            result = subprocess.run(
                [
                    "/usr/local/bin/nsjail",
                    "--config", self.__nsjail_config,
                    "--bindmount", f"{script_path}:/tmp/script.py" # binds the script into the jail, so it can be executed
                ],
                capture_output=True,
                text=True,
                timeout=timeout
            )

            stdout = result.stdout
            stderr = result.stderr

            if self._error_prefix in stdout:
                error_msg = self._extract_result(stdout, self._error_prefix, self._error_suffix)

                raise Exception(error_msg)

            if self._result_prefix not in stdout:
                if result.returncode != 0:
                    raise Exception(f"Script execution failed: {stderr}")
                raise Exception("No result returned from the script")

            result_json = self._extract_result(stdout, self._result_prefix, self._result_suffix)

            try:
                parsed_result = json.loads(result_json)
            except json.JSONDecodeError:
                raise Exception("Invalid JSON returned from main() function")

            return {
                "result": parsed_result,
            }

        except subprocess.TimeoutExpired:
            raise Exception(f"Script execution timed out after {timeout} seconds")

        except Exception as e:
            raise e

        finally:
            os.unlink(script_path)

    @staticmethod
    def _extract_result(result: str, prefix: str, suffix: str) -> str:
        start = result.find(prefix) + len(prefix+"\n")
        end = result.find(suffix)

        return result[start:end].strip()

executor = Executor()

class ExecuteRequestBody(BaseModel):
    script: str

@app.route("/execute", methods=["POST"])
def execute():
    try:
        body = ExecuteRequestBody(**request.get_json())

        result = executor.execute(body.script)

        return jsonify(result)

    except ValidationError as e:
        return jsonify({"error": "Validation failed", "details": e.errors()}), 400

    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
