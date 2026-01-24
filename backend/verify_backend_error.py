import requests
import json

try:
    response = requests.get('http://127.0.0.1:8000/api/shields/')
    print(f"Status Code: {response.status_code}")
    if response.status_code != 200:
        print("Error content:")
        try:
            print(json.dumps(response.json(), indent=2))
        except:
            print(response.text)
    else:
        print("Success! Shields API is available.")

except Exception as e:
    print(f"Connection failed: {e}")
