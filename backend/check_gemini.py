import requests
import os

def check_gemini():
    api_key = ""
    try:
        with open(".env", "r") as f:
            for line in f:
                if line.startswith("GEMINI_API_KEY="):
                    api_key = line.split("=")[1].strip()
                    break
    except Exception as e:
        print(f"Error reading .env: {e}")
        return

    if not api_key:
        print("GEMINI_API_KEY not found in .env")
        return

    print(f"Testing key: {api_key[:6]}...{api_key[-4:]}")
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            models = response.json().get('models', [])
            print("SUCCESS: Connected to Gemini API!")
            print(f"Found {len(models)} models.")
            for m in models:
                print(f" - {m['name']}")
        else:
            print(f"FAILED: API Call failed with status {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"Error during API call: {e}")

if __name__ == "__main__":
    check_gemini()
