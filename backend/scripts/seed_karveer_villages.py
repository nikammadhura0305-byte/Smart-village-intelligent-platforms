from sqlalchemy import func, select

from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models import Village

DISTRICT = "Kolhapur"
TALUKA = "Karvir"
VILLAGES = (
    "Adur",
    "Amashi",
    "Ambewadi",
    "Arale",
    "Ardewadi",
    "Are",
    "Bachani",
    "Bahireshwar",
    "Balinge",
    "Beed",
    "Bele",
    "Bhamate",
    "Bhatanwadi",
    "Bhuye",
    "Bhuyewadi",
    "Bololi",
    "Chafodi",
    "Chikhali",
    "Chinchawad",
    "Chinchawade Tarf Kale",
    "Chuye",
    "Daryache Wadgaon",
    "Dewale",
    "Dhangarwadi",
    "Dhondewadi",
    "Dindanerli",
    "Donawade",
    "Donwadi",
    "Durgulwadi",
    "Gadegoundwadi",
    "Gandhinagar",
    "Ganeshwadi",
    "Garjan",
    "Ghanawade",
    "Ghungurwadi",
    "Girgaon",
    "Gokul Shirgaon",
    "Haladi",
    "Halasawade",
    "Hanbarwadi",
    "Hanmantwadi",
    "Hasur",
    "Hirawade Dumala",
    "Hirawade Khalasa",
    "Ispurli",
    "Jaityal",
    "Jatharwadi",
    "Kalambe Tarf Kale",
    "Kalambe Tarf Thane",
    "Kanchanwadi",
    "Kandalgaon",
    "Kandgaon",
    "Kaneri",
    "Kaneriwadi",
    "Kavane",
    "Kekatwadi",
    "Kerle",
    "Kerli",
    "Khatangale",
    "Khebavade",
    "Khupire",
    "Koge",
    "Kogil Budruk",
    "Kogil Khurd",
    "Koparde",
    "Kothali",
    "Kuditre",
    "Kurdu",
    "Kurukali",
    "Mahe",
    "Mandare",
    "Mhalasavade",
    "Mhalunge",
    "Mharul",
    "Morewadi",
    "Mudashingi",
    "Nagaon",
    "Nagdeowadi",
    "Nandawal",
    "Nandgaon",
    "Nerli",
    "New Wadade",
    "Nigave Dumala",
    "Nigave Khalasa",
    "Nitawade",
    "Padali Budruk",
    "Padali Khalasa",
    "Padvalwadi",
    "Panchgaon",
    "Parite",
    "Pasarde",
    "Patekarwadi",
    "Rajaputwadi",
    "Sabalewadi",
    "Sadale Madale",
    "Sadoli Dumala",
    "Sadoli Khalasa",
    "Sangawade",
    "Sangawadewadi",
    "Sangrul",
    "Sarnobatwadi",
    "Savarde Dumala",
    "Savarwadi",
    "Shelakewadi",
    "Shindewadi",
    "Shinganapur",
    "Shiroli Dumala",
    "Shiye",
    "Sonali",
    "Tamgaon",
    "Teraswadi",
    "Uchgaon",
    "Ujalaiwadi",
    "Upawade",
    "Vadakshivale",
    "Vadanage",
    "Vakare",
    "Varanage",
    "Vasagade",
    "Wadipeer",
    "Waliwade",
    "Washi",
    "Yevati",
)


def main() -> None:
    init_db()
    created = 0
    updated = 0

    with SessionLocal() as db:
        for name in VILLAGES:
            village = db.scalar(
                select(Village).where(
                    func.lower(Village.name) == name.lower(),
                    func.lower(Village.district) == DISTRICT.lower(),
                )
            )
            if village is None:
                db.add(Village(name=name, district=DISTRICT, taluka=TALUKA, state="Maharashtra"))
                created += 1
                continue

            if village.taluka and village.taluka.casefold() != TALUKA.casefold():
                raise ValueError(
                    f"{village.name}, {village.district} already has taluka "
                    f"{village.taluka!r}; resolve the conflicting record before seeding."
                )
            if village.taluka is None:
                village.taluka = TALUKA
                updated += 1

        db.commit()

    print(f"Karveer catalog: {len(VILLAGES)} villages; {created} created, {updated} updated.")


if __name__ == "__main__":
    main()
