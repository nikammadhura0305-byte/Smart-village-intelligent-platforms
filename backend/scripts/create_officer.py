import argparse

from sqlalchemy import func, select

from app.core.security import hash_password
from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models import User, Village


def main() -> None:
    parser = argparse.ArgumentParser(description="Create or promote a local village officer account.")
    parser.add_argument("--email", required=True)
    parser.add_argument("--full-name", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--village-name", required=True)
    parser.add_argument("--district", required=True)
    parser.add_argument("--taluka")
    args = parser.parse_args()

    init_db()
    with SessionLocal() as db:
        email = args.email.strip().lower()
        village_name = args.village_name.strip()
        district = args.district.strip()
        user = db.scalar(select(User).where(User.email == email))
        village = db.scalar(
            select(Village).where(
                func.lower(Village.name) == village_name.lower(),
                func.lower(Village.district) == district.lower(),
            )
        )
        if village is None:
            village = Village(
                name=village_name,
                district=district,
                taluka=args.taluka.strip() if args.taluka else None,
            )
            db.add(village)
            db.flush()
        elif args.taluka and args.taluka.strip():
            village.taluka = args.taluka.strip()
        if user is None:
            user = User(
                full_name=args.full_name,
                email=email,
                password_hash=hash_password(args.password),
                role="village_officer",
                village=village,
            )
            db.add(user)
        else:
            user.full_name = args.full_name
            user.password_hash = hash_password(args.password)
            user.role = "village_officer"
            user.village_id = village.id
        db.commit()
        print(f"Officer ready: {user.email} ({user.role})")


if __name__ == "__main__":
    main()
