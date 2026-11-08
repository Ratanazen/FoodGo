# FoodGo v2.0 — Database Architecture & ER Diagram (`Database/`)

**Course / Group**: AUB Batch 09 • Year 3 • Semester 1 • Group 7 (`aub-batch-09-y3-s1-m-g7-Food-Delivery-App`)  
**Database Engine**: SQLite 3 (`db.sqlite3`) / PostgreSQL-compatible SQL (`foodgo_schema_and_seed.sql`)  
**ORM**: Django 5.1 ORM (`foodgo-server/core/models.py`)

---

## Included Files
- `db.sqlite3` — Pre-migrated and seeded SQLite database containing 7 Cambodian & international restaurants, 23 authentic food items, categories, addresses, customer, delivery driver (`driver_sokha`), and partner accounts.
- `foodgo_schema_and_seed.sql` — Full SQL DDL schema + `INSERT` seed statements exported directly from `db.sqlite3`.
- `DATABASE_ER_DIAGRAM.md` — Entity-Relationship diagram and table reference.

---

## Entity-Relationship Diagram (ERD)

```mermaid
erDiagram
    USER ||--o{ ADDRESS : "has saved"
    USER ||--o{ ORDER : "places"
    USER ||--o| DRIVER : "operates as"
    USER ||--o{ RESTAURANT : "owns"
    USER ||--o{ FAVORITE : "bookmarks"
    USER ||--o{ NOTIFICATION : "receives"

    RESTAURANT_CATEGORY ||--o{ RESTAURANT : "classifies"
    RESTAURANT ||--o{ FOOD_CATEGORY : "organizes menu"
    FOOD_CATEGORY ||--o{ FOOD_ITEM : "contains"
    RESTAURANT ||--o{ ORDER : "fulfills"

    ORDER ||--|{ ORDER_ITEM : "includes"
    FOOD_ITEM ||--o{ ORDER_ITEM : "referenced in"
    ADDRESS ||--o{ ORDER : "delivers to"
    ORDER ||--o| PAYMENT : "paid via KHQR/Card/COD"
    ORDER ||--o| DELIVERY : "assigned to"
    DRIVER ||--o{ DELIVERY : "completes"
    ORDER ||--o| REVIEW : "rated by"

    USER {
        int id PK
        string username UK
        string email
        string phone
        string role "customer | driver | restaurant_owner | admin"
    }

    RESTAURANT {
        int id PK
        int owner_id FK
        int category_id FK
        string name
        decimal rating
        decimal delivery_fee
        int delivery_time_min
        int delivery_time_max
        boolean is_active
    }

    FOOD_ITEM {
        int id PK
        int category_id FK
        string name
        decimal price
        boolean is_available
        boolean is_popular
        string image_url
    }

    ORDER {
        int id PK
        int customer_id FK
        int restaurant_id FK
        int address_id FK
        string status "pending | confirmed | preparing | ready | picked_up | on_the_way | delivered | cancelled"
        decimal total_amount
        string special_instructions
        datetime created_at
    }

    DRIVER {
        int id PK
        int user_id FK
        string vehicle_type
        string license_plate
        boolean is_online
        decimal current_lat
        decimal current_lng
    }

    PAYMENT {
        int id PK
        int order_id FK
        string method "ABA KHQR | Bakong | Card | Cash"
        decimal amount
        string status "pending | paid | failed"
        string transaction_id
    }
```

---

## Restoring or Resetting the Database

### Option 1: Using Django Management Command (Recommended)
```bash
cd foodgo-server
./venv/bin/python manage.py migrate
./venv/bin/python manage.py seed_data
```

### Option 2: Importing SQL Dump into SQLite
```bash
sqlite3 foodgo_restored.sqlite3 < Database/foodgo_schema_and_seed.sql
```
