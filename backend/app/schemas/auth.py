from pydantic import BaseModel, ConfigDict, EmailStr, Field


class VillageCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    district: str = Field(min_length=2, max_length=100)
    state: str = Field(default="Maharashtra", min_length=2, max_length=100)


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    village: VillageCreate


class OfficerRegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    village_id: int = Field(gt=0)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    email: EmailStr
    role: str
    village_id: int | None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class VillageOption(BaseModel):
    id: int
    name: str
    district: str
    taluka: str | None = None


class PendingOfficerResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    village: str
    district: str
