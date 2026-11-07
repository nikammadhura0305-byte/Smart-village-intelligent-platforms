"""
Officer Approval Helper Script for Smart Village Intelligence System.
Usage:
    python backend/approve_officer.py                       # Lists all pending officers and activates them
    python backend/approve_officer.py <email_or_id>         # Approves a specific officer
"""

import sys
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent / "smart_village.db"

def approve(target: str | None = None):
    if not DB_PATH.exists():
        print(f"Error: Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    if target:
        if target.isdigit():
            cursor.execute(
                "UPDATE users SET is_active = 1 WHERE id = ?", (int(target),)
            )
            cursor.execute("SELECT id, email, full_name, role, is_active FROM users WHERE id = ?", (int(target),))
        else:
            cursor.execute(
                "UPDATE users SET is_active = 1 WHERE LOWER(email) = LOWER(?)", (target.strip(),)
            )
            cursor.execute("SELECT id, email, full_name, role, is_active FROM users WHERE LOWER(email) = LOWER(?)", (target.strip(),))
        user = cursor.fetchone()
        conn.commit()
        if user:
            print(f"SUCCESS: Approved officer '{user[2]}' ({user[1]}). is_active is now {user[4]}.")
        else:
            print(f"User '{target}' not found in database.")
    else:
        # Check pending officers
        cursor.execute("SELECT id, email, full_name, role, is_active FROM users WHERE role = 'village_officer' AND is_active = 0")
        pending = cursor.fetchall()
        if not pending:
            print("No pending officers found waiting for approval.")
        else:
            print(f"Found {len(pending)} pending officer(s):")
            for u in pending:
                print(f" - ID: {u[0]}, Name: {u[2]}, Email: {u[1]}")

            # Approve all pending
            cursor.execute("UPDATE users SET is_active = 1 WHERE role = 'village_officer' AND is_active = 0")
            conn.commit()
            print("All pending officers have been APPROVED and ACTIVATED successfully!")

    # Show all active officers
    cursor.execute("SELECT id, email, full_name, role, is_active FROM users WHERE role = 'village_officer'")
    officers = cursor.fetchall()
    print("\nCurrent Village Officers in system:")
    for o in officers:
        status_str = "ACTIVE (Approved)" if o[4] else "PENDING"
        print(f" - ID {o[0]}: {o[2]} <{o[1]}> -> {status_str}")

    conn.close()

if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else None
    approve(arg)
