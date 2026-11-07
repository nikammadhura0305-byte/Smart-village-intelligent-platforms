import argparse

from sqlalchemy import select

from app.core.security import hash_password
from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models import User


def main() -> None:
    parser = argparse.ArgumentParser(description="Create or promote an administrator account.")
    parser.add_argument("--email", required=True)
    parser.add_argument("--full-name", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()

    init_db()
    email = args.email.strip().lower()
    with SessionLocal() as db:
        user = db.scalar(select(User).where(User.email == email))
        if user is None:
            user = User(
                full_name=args.full_name.strip(),
                email=email,
                password_hash=hash_password(args.password),
                role="admin",
                is_active=True,
            )
            db.add(user)
        else:
            user.full_name = args.full_name.strip()
            user.password_hash = hash_password(args.password)
            user.role = "admin"
            user.is_active = True
        db.commit()
        print(f"Administrator ready: {user.email}")


if __name__ == "__main__":
    main()
