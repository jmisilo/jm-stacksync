#!/bin/bash

# GENERATED

# Configuration
BASE_URL="http://localhost:8080"
ENDPOINT="/execute"
URL="${BASE_URL}${ENDPOINT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print test header
print_test() {
    echo -e "\n${BLUE}=== Test $1: $2 ===${NC}"
}

# Function to check if service is running
check_service() {
    echo -e "${YELLOW}Checking if service is running at ${URL}...${NC}"
    if ! curl -s --connect-timeout 5 "${BASE_URL}" > /dev/null 2>&1; then
        echo -e "${RED}Error: Service is not running at ${BASE_URL}${NC}"
        echo -e "${YELLOW}Make sure your Flask app is running on ${BASE_URL}${NC}"
        exit 1
    fi
    echo -e "${GREEN}Service is running!${NC}\n"
}

# Check service availability
check_service

# Test 1: Basic successful execution
print_test "1" "Basic successful execution"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "def main():\n    return {\"message\": \"Hello, World!\", \"status\": \"success\"}"
  }'

# Test 2: Test with calculations
print_test "2" "Test with calculations"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "def main():\n    result = 2 + 2\n    return {\"calculation\": \"2 + 2\", \"result\": result}"
  }'

# Test 3: Test with array/list data
print_test "3" "Test with array/list data"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "def main():\n    numbers = [1, 2, 3, 4, 5]\n    return {\"numbers\": numbers, \"sum\": sum(numbers)}"
  }'

# Test 4: Test error handling - missing main function
print_test "4" "Error handling - missing main function"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "print(\"This script has no main function\")"
  }'

# Test 5: Test error handling - main function returns None
print_test "5" "Error handling - main function returns None"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "def main():\n    print(\"This returns None\")\n    return None"
  }'

# Test 6: Test error handling - non-JSON serializable return
print_test "6" "Error handling - non-JSON serializable return"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "def main():\n    return {\"func\": lambda x: x}"
  }'

# Test 7: Test error handling - runtime exception
print_test "7" "Error handling - runtime exception"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "def main():\n    return 1/0"
  }'

# Test 8: Test validation error - missing script field
print_test "8" "Validation error - missing script field"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def main():\n    return \"wrong field name\""
  }'

# Test 9: Test with installed packages (numpy)
print_test "9" "Test with installed packages (numpy)"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "import numpy as np\n\ndef main():\n    arr = np.array([1, 2, 3, 4, 5])\n    return {\"array\": arr.tolist(), \"mean\": float(np.mean(arr))}"
  }'

# Test 10: Test with installed packages (pandas)
print_test "10" "Test with installed packages (pandas)"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "import pandas as pd\n\ndef main():\n    df = pd.DataFrame({\"a\": [1, 2, 3], \"b\": [4, 5, 6]})\n    return {\"data\": df.to_dict(), \"shape\": list(df.shape)}"
  }'

# Test 11: Test with requests package
print_test "11" "Test with requests package (mock request)"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "import requests\n\ndef main():\n    # This will fail due to network restrictions in sandbox\n    try:\n        response = requests.get(\"https://httpbin.org/json\")\n        return {\"status\": \"success\", \"data\": response.json()}\n    except Exception as e:\n        return {\"status\": \"expected_failure\", \"error\": str(e)}"
  }'

# Test 12: Test timeout scenario (long running)
print_test "12" "Test timeout scenario"
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "import time\n\ndef main():\n    time.sleep(25)  # This should timeout\n    return {\"message\": \"This should not be reached\"}"
  }'

echo -e "\n${GREEN}=== All tests completed ===${NC}"
echo -e "${YELLOW}Note: Some tests are expected to fail (that's the point of error handling tests)${NC}"
