from flask import Flask, request, jsonify
from pydantic import BaseModel, ValidationError

app = Flask(__name__)

class Executor:
    """A class to execute code in a nsjail sandboxed environment."""

    def __init__(self):
        pass


    def execute(self, code: str, timeout: int | None = 20):
        pass

executor = Executor()

class ExecuteRequestBody(BaseModel):
    script: str

@app.post("/execute")
def execute():
    try:
        body = ExecuteRequestBody(**request.get_json())

        # send script to the "sandbox" for execution
        result = executor.execute(body.script)

        print(result)

        return {"result": result}

    except ValidationError as e:
        return jsonify({"error": "Validation failed", "details": e.errors()}), 400

    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
