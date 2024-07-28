# routes/user.py

from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Request, Query
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
import bcrypt
from datetime import datetime, timedelta
import jwt
import os
import uuid
from typing import Optional
from preprocess import Preprocess
import cv2
import pickle
import numpy as np

from db import get_db
from models.user import User
from verify_token import verify_jwt_token
from models.user import Permission
import qrcode

STATIC_FOLDER = os.path.join(os.path.dirname(__file__), '..', 'static')

prep = Preprocess()

user_router = APIRouter()


class UserCreate(BaseModel):
    fullname: str
    email: EmailStr
    password: str
    
class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    fullname: Optional[str] = None
    email: EmailStr
    imageurl: Optional[str] = None

    class Config:
        from_attributes = True 

class AuthResponse(BaseModel):
    user: UserResponse
    token: str

class PermissionCreate(BaseModel):
    user_id: int
    apartment_id: int
    start_date: datetime
    end_date: datetime

class PermissionResponse(BaseModel):
    id: int
    user_id: int
    apartment_id: int
    start_date: datetime
    end_date: datetime
    qr_image_url: Optional[str] = None  # Add this line

    class Config:
        from_attributes = True


class PermissionAssign(BaseModel):
    permission_id: int
    user_id: int

def create_jwt_token(user_id: int, username: str, exp: datetime = None) -> str:
    secret_key = os.getenv("SECRET_KEY")
    if not secret_key:
        raise ValueError("SECRET_KEY environment variable is not set")
    
    payload = {
        'id': user_id,
        'email': username,
        'exp': exp if exp is not None else datetime.utcnow() + timedelta(weeks=4)
    }
    jwt_token = jwt.encode(payload, secret_key, algorithm='HS256')
    return jwt_token

@user_router.post("/user/register", response_model=AuthResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    try:
        if db.query(User).filter(User.email == user.email).first():
            raise HTTPException(status_code=400, detail="Email already registered")
        
        hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        db_user = User(email=user.email, fullname=user.fullname, password=hashed_password)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        jwt_token = create_jwt_token(db_user.id, db_user.email)
        return AuthResponse(token=jwt_token, user=UserResponse(id=db_user.id, fullname=db_user.fullname, email=db_user.email))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@user_router.post("/user/login", response_model=AuthResponse)
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    try:
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user is None:
            raise HTTPException(status_code=400, detail="Invalid credentials")

        if not bcrypt.checkpw(user.password.encode('utf-8'), db_user.password.encode('utf-8')):
            raise HTTPException(status_code=400, detail="Invalid credentials")

        jwt_token = create_jwt_token(db_user.id, db_user.email)
        return AuthResponse(token=jwt_token, user=UserResponse(id=db_user.id, fullname=db_user.fullname, email=db_user.email, imageurl=db_user.imageurl))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@user_router.post("/user/photo", response_model=UserResponse)
async def update_profile_photo(request: Request, image: UploadFile = File(...), db: Session = Depends(get_db)):
    try:
        decoded_token = verify_jwt_token(request.headers.get("authorization"))
        if decoded_token == None:
            raise HTTPException(status_code=401, detail="Invalid token")
        db_user = db.query(User).filter(User.id == decoded_token["id"]).first()
        
        file_extension = os.path.splitext(image.filename)[-1]  # Extract the file extension
        filename = str(uuid.uuid4()) +file_extension
        
        filepath = os.path.join("static", filename)
        
        with open(filepath, "wb") as f:
            contents = await image.read()
            f.write(contents)
            
        face, coor = prep.getFace(cv2.imread(filepath))
        
        if face != None:
            (x1, y1, x2, y2) =coor[0]
            img = cv2.imread(filepath)
            cropped_image = img[y1:y2, x1:x2]
            data_serialized = pickle.dumps(prep.embedding(cropped_image))
            db_user.vector = data_serialized            
            crop_name = f"cropped_{filename}.jpg"
            crop_path = os.path.join(STATIC_FOLDER, crop_name)
            cv2.imwrite(crop_path, cropped_image)


        url = f"/static/{filename}"
        db_user.imageurl = url
        db.commit()
        return db_user
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@user_router.post("/user/photo/test")
async def update_profile_photo_test(request: Request, image: UploadFile = File(...), db: Session = Depends(get_db)):
    try:
        decoded_token = verify_jwt_token(request.headers.get("authorization"))
        if decoded_token is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        db_user = db.query(User).filter(User.id == decoded_token["id"]).first()
        if db_user is None:
            raise HTTPException(status_code=404, detail="User not found")
        
        contents = await image.read()
        np_array = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(np_array, cv2.IMREAD_COLOR)
        
        face, coor = prep.getFace(image)
                
        if face is None:
            raise HTTPException(status_code=400, detail="Face not found")
        
        (x1, y1, x2, y2) = coor[0]
        cropped_image = image[y1:y2, x1:x2]
        vector = prep.embedding(cropped_image)
        
        if db_user.vector is None:
            raise HTTPException(status_code=400, detail="User vector not found")
        
        sim = prep.euclid_distance(pickle.loads(db_user.vector), vector)
        if 0 < sim < 1:
            return {"issuccess": True}
        return {"issuccess": False}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@user_router.get("/user/getuser", response_model=UserResponse)
async def get_user(mail: str | None = None, db: Session = Depends(get_db)):
    try:
        db_user = db.query(User).filter(User.email == mail).first()
        if db_user is None:
            raise HTTPException(status_code=404, detail="User not found")
        return db_user
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@user_router.post("/user/permission/create", response_model=PermissionResponse)
def create_permission(permission: PermissionCreate, db: Session = Depends(get_db)):   
    try:
        assigned_by_id = 1  # This should be dynamically determined based on the logged-in resident
        
        jwt = create_jwt_token(permission.user_id, "", permission.end_date)
        
        img = qrcode.make(jwt)
        
        filename =  str(uuid.uuid4()) + ".png"
        
        filepath = os.path.join(STATIC_FOLDER, filename)
        
        img.save(filepath)
        
        new_permission = Permission(
            assigned_by_id=assigned_by_id,
            user_id=permission.user_id,
            apartment_id=permission.apartment_id,
            start_date=permission.start_date,
            end_date=permission.end_date,
            qr_image_url = f"/static/{filename}"
        )
        db.add(new_permission)
        db.commit()
        db.refresh(new_permission)
        return new_permission
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@user_router.get("/permission")
def get_permission(request: Request, db: Session = Depends(get_db)):
    try:
        decoded_token = verify_jwt_token(request.headers.get("authorization"))
        if decoded_token == None:
            raise HTTPException(status_code=401, detail="Invalid token")
        permissions = db.query(Permission).filter(Permission.user_id == decoded_token["id"]).all()
        return permissions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@user_router.post("/user/permission/assign", response_model=PermissionResponse)
def assign_permission(permission: PermissionAssign, db: Session = Depends(get_db)):
    try:
        permission_entry = db.query(Permission).filter(Permission.id == permission.permission_id).first()
        if not permission_entry:
            raise HTTPException(status_code=404, detail="Permission not found")
        permission_entry.user_id = permission.user_id
        db.commit()
        db.refresh(permission_entry)
        return permission_entry
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
