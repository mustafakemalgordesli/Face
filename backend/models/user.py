from db import Base
from sqlalchemy import Column, Integer, String, ForeignKey, LargeBinary, DateTime
from sqlalchemy.orm import relationship

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, nullable=False)
    fullname = Column(String, nullable=True)
    password = Column(String, nullable=False)
    imageurl = Column(String, nullable=True)
    vector = Column(LargeBinary, nullable=True)

    granted_permissions = relationship("Permission", foreign_keys="Permission.user_id", back_populates="user")

class Permission(Base):
    __tablename__ = "permissions"

    id = Column(Integer, primary_key=True, index=True)
    assigned_by_id = Column(Integer, ForeignKey("residents.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    apartment_id = Column(Integer, ForeignKey("apartments.id"))
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    qr_image_url = Column(String, nullable=True)  # Add this line

    assigned_by = relationship("Resident", back_populates="created_permissions")
    user = relationship("User", back_populates="granted_permissions")
    apartment = relationship("Apartment")
