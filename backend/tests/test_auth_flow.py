import requests
import sys

BASE_URL = "http://localhost:8000/api/v1"
EMAIL = "test@example.com"
PASSWORD = "password123"

def test_auth_flow():
    print("Testing Authentication Flow...")

    # 1. Signup
    print("\n[1] Registering new user...")
    signup_data = {
        "email": EMAIL,
        "password": PASSWORD,
        "full_name": "Test User"
    }
    # Using JSON for signup
    response = requests.post(f"{BASE_URL}/auth/signup", json=signup_data)
    if response.status_code == 200:
        print("✅ Signup successful:", response.json())
    elif response.status_code == 400 and "already exists" in response.text:
         print("⚠️ User already exists, proceeding to login...")
    else:
        print("❌ Signup failed:", response.text)
        sys.exit(1)

    # 2. Login
    print("\n[2] Logging in...")
    login_data = {
        "username": EMAIL,
        "password": PASSWORD
    }
    # OAuth2 expects form data
    response = requests.post(f"{BASE_URL}/auth/login/access-token", data=login_data)
    if response.status_code != 200:
        print("❌ Login failed:", response.text)
        sys.exit(1)
    
    token_data = response.json()
    access_token = token_data["access_token"]
    print(f"✅ Login successful. Token: {access_token[:20]}...")

    # 3. Get Me
    print("\n[3] Fetching current user profile...")
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.get(f"{BASE_URL}/auth/me", headers=headers)
    
    if response.status_code == 200:
        print("✅ Profile fetch successful:", response.json())
    else:
        print("❌ Profile fetch failed:", response.text)
        sys.exit(1)

    print("\n🎉 All tests passed!")

if __name__ == "__main__":
    # Ensure requests is installed
    try:
        import requests
    except ImportError:
        print("Please install requests: pip install requests")
        sys.exit(1)
        
    test_auth_flow()
