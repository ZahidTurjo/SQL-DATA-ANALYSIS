import pandas as pd
from sqlalchemy import create_engine
import mysql.connector
from pathlib import Path

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '682462',  
    'database': 'ecommerce_database'
}


def create_database():
    conn = mysql.connector.connect(
        host=db_config['host'],
        user=db_config['user'],
        password=db_config['password']
    )
    cursor = conn.cursor()
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_config['database']}")
    conn.commit()
    cursor.close()
    conn.close()
    print("Database created!")


engine = create_engine(
    f"mysql+pymysql://{db_config['user']}:{db_config['password']}@{db_config['host']}/{db_config['database']}"
)


def load_data():
    
    BASE_DIR = Path(__file__).resolve().parent.parent  # project root
    DATA_DIR = BASE_DIR / "data" / "E_commerce_DATASET"
    
    print("Loading data from:", DATA_DIR)
    print("Files found:", list(DATA_DIR.iterdir()))
    
    customers = pd.read_csv(DATA_DIR / "customers.csv")
    if 'signup_date' in customers.columns:
        customers['signup_date'] = pd.to_datetime(customers['signup_date'], errors='coerce')
    customers.to_sql('customers', con=engine, if_exists='replace', index=False, chunksize=1000)
    print(" Customers loaded")
    
    
    products = pd.read_csv(DATA_DIR / "products.csv")
    products.to_sql('products', con=engine, if_exists='replace', index=False, chunksize=1000)
    print("Products loaded")
    
    
    events_file = DATA_DIR / "events.csv"
    if events_file.exists():
        events = pd.read_csv(events_file)
        if 'timestamp' in events.columns:
            events['timestamp'] = pd.to_datetime(events['timestamp'], errors='coerce')
        events.to_sql('events', con=engine, if_exists='replace', index=False, chunksize=1000)
        print("Events loaded")
    
    # 4. ORDERS
    orders = pd.read_csv(DATA_DIR / "orders.csv")
    if 'order_time' in orders.columns:
        orders['order_time'] = pd.to_datetime(orders['order_time'], errors='coerce')
    orders.to_sql('orders', con=engine, if_exists='replace', index=False, chunksize=1000)
    print(" Orders loaded")
    
    # 5. ORDER_ITEMS (optional)
    order_items_file = DATA_DIR / "order_items.csv"
    if order_items_file.exists():
        order_items = pd.read_csv(order_items_file)
        order_items.to_sql('order_items', con=engine, if_exists='replace', index=False, chunksize=1000)
        print("Order Items loaded")
    
    # 6. REVIEWS (optional)
    reviews_file = DATA_DIR / "reviews.csv"
    if reviews_file.exists():
        reviews = pd.read_csv(reviews_file)
        if 'review_time' in reviews.columns:
            reviews['review_time'] = pd.to_datetime(reviews['review_time'], errors='coerce')
        reviews.to_sql('reviews', con=engine, if_exists='replace', index=False, chunksize=1000)
        print(" Reviews loaded")
    
    print("\n All tables loaded successfully!")


if __name__ == "__main__":
    create_database()
    load_data()
