# FoodGo - Food Delivery Application

A full-stack food delivery application inspired by Foodpanda.

## Technologies Used
* **Frontend:** React, Tailwind CSS, Vite, Axios, React Router Dom
* **Backend:** Django, Django REST Framework, Simple JWT
* **Database:** SQLite (Default for development) / PostgreSQL
* **Payments:** Stripe (integration stubbed)
* **Image Storage:** Cloudinary (integration stubbed)

## Project Structure
* `backend/` - Django backend API
* `frontend/` - React frontend application

## Setup Instructions

### Backend Setup
1. `cd backend`
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install django djangorestframework psycopg2-binary django-cors-headers djangorestframework-simplejwt django-filter cloudinary stripe
   ```
4. Run migrations:
   ```bash
   python manage.py migrate
   ```
5. Create a superuser:
   ```bash
   python manage.py createsuperuser
   ```
6. Start the development server:
   ```bash
   python manage.py runserver
   ```

### Frontend Setup
1. `cd frontend`
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm run dev
   ```

## API Endpoints (Base URL: `/api/`)
* `/token/` - Get JWT token
* `/token/refresh/` - Refresh JWT token
* `/restaurants/` - List/Create restaurants
* `/food-categories/` - List/Create food categories
* `/food-items/` - List/Create food items
* `/orders/` - List/Create orders
