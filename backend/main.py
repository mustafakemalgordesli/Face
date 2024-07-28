# main.py
# uvicorn main:app --reload
import os
import uuid
from datetime import datetime
from fastapi import FastAPI, Depends, File, UploadFile, Form, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Table, MetaData
from sqlalchemy.orm import relationship, Session
from typing import List, Optional
from db import Base, engine, get_db
from fastapi.middleware.cors import CORSMiddleware
from routes.user import user_router
from dotenv import load_dotenv
from fastapi.staticfiles import StaticFiles  # StaticFiles import edildi
# In main.py
from models.user import Permission
from fastapi.staticfiles import StaticFiles
from verify_token import verify_jwt_token


load_dotenv()

metadata = MetaData()

# Define the Apartments model
class Apartment(Base):
    __tablename__ = "apartments"

    id = Column(Integer, primary_key=True, index=True)
    number = Column(String, unique=True, nullable=False)
    floor = Column(Integer)

# Define the Residents model
class Resident(Base):
    __tablename__ = "residents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    apartment_id = Column(Integer, ForeignKey("apartments.id"))
    url = Column(String, nullable=True)  # Nullable url field

    apartment = relationship("Apartment", back_populates="residents")
    created_permissions = relationship("Permission", back_populates="assigned_by")

Apartment.residents = relationship("Resident", back_populates="apartment")

# Define the Users model
users_table = Table(
    'users', metadata,
    Column('id', Integer, primary_key=True, index=True),
    Column('fullname', String, nullable=False),
    Column('email', String, unique=True, nullable=False),
    Column('password', String, nullable=False),
    Column('imageurl', String, nullable=True),
    Column('vector', String, nullable=True),
    extend_existing=True  # Bu satırı ekleyin
)

# Create the tables in the database
Base.metadata.create_all(bind=engine)

# Define the Pydantic models
class ApartmentCreateItem(BaseModel):
    number: str
    floor: int

class ApartmentCreate(BaseModel):
    apartments: List[ApartmentCreateItem]

class ResidentCreateItem(BaseModel):
    user_id: int
    apartment_id: int
    url: Optional[str]  # Make url field optional

class ResidentCreate(BaseModel):
    residents: List[ResidentCreateItem]

class ResidentResponse(BaseModel):
    id: int
    user_id: int
    apartment_id: int
    url: Optional[str]  # Make url field optional

    class Config:
        from_attributes = True

class ApartmentResponse(BaseModel):
    id: int
    number: str
    floor: int
    residents: List[ResidentResponse] = []

    class Config:
        from_attributes = True

class PermissionCreate(BaseModel):
    user_mail: int
    apartment_id: int
    start_date: datetime
    end_date: datetime

class PermissionResponse(BaseModel):
    id: int
    assigned_by_id: int
    user_id: int
    apartment_id: int
    start_date: datetime
    end_date: datetime

    class Config:
        from_attributes = True

# Create a FastAPI instance
app = FastAPI()

app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(user_router)

# Statik dosyalara hizmet vermek için StaticFiles middleware'i ekle
app.mount("/static", StaticFiles(directory="static"), name="static")

origins = ["*"]
# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Endpoint to add multiple apartments
@app.post("/apartments/", response_model=List[ApartmentResponse])
def create_apartments(apartments: ApartmentCreate, db: Session = Depends(get_db)):
    created_apartments = []
    for apartment in apartments.apartments:
        existing_apartment = db.query(Apartment).filter(Apartment.number == apartment.number).first()
        if existing_apartment:
            raise HTTPException(status_code=400, detail=f"Apartment with number {apartment.number} already exists")
        
        db_apartment = Apartment(number=apartment.number, floor=apartment.floor)
        db.add(db_apartment)
        db.commit()
        db.refresh(db_apartment)
        created_apartments.append(db_apartment)
    return created_apartments

# Endpoint to add multiple residents with optional image upload
@app.post("/residents/", response_model=ResidentResponse)
async def create_resident_with_image(
    user_id: int = Form(...),
    apartment_id: int = Form(...),
    image: UploadFile = File(None),  # Make image optional
    db: Session = Depends(get_db)
):
    try:
        url = None
        if image:
            # Generate a unique filename using uuid
            file_extension = os.path.splitext(image.filename)[1]
            unique_filename = f"{uuid.uuid4()}{file_extension}"
            filepath = os.path.join("static", unique_filename)
            
            # Save the image to a static directory
            with open(filepath, "wb") as file:
                file.write(image.file.read())

            # Generate URL based on the saved path
            url = f"/static/{unique_filename}"

        # Create the resident with the generated URL if image is provided
        resident = Resident(user_id=user_id, apartment_id=apartment_id, url=url)
        db.add(resident)
        db.commit()
        db.refresh(resident)

        return resident
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
# Endpoint to get all residents
@app.get("/residents/", response_model=List[ResidentResponse])
def read_residents(db: Session = Depends(get_db)):
    residents = db.query(Resident).all()
    return residents

@app.get("/apartments")
async def get_apartments(request: Request, db: Session = Depends(get_db)):
    try:
        decoded_token = verify_jwt_token(request.headers.get("authorization"))
        if decoded_token is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        db_resident = db.query(Resident).filter(Resident.user_id == decoded_token["id"]).all()
        
        apartments = []
        
        for res in db_resident:
            apart = db.query(Apartment).filter(Apartment.id == res.apartment_id).first()
            apartments.append(apart)
        
        return apartments

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

