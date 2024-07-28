from typing import Optional
import jwt
import os

def verify_jwt_token(token: str) -> Optional[dict]:
    secret_key = os.getenv("SECRET_KEY")
    try:
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        print("Token expired.")
    except jwt.InvalidTokenError:
        print("Invalid token.")
    return None