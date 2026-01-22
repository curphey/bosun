# Order processing - works fine in dev with 10 orders
# Production has 50,000 orders... oops

from dataclasses import dataclass
from typing import List
import database as db


@dataclass
class Order:
    id: int
    customer_id: int
    total: float


@dataclass
class Customer:
    id: int
    name: str
    email: str


@dataclass
class OrderItem:
    id: int
    order_id: int
    product_name: str
    quantity: int
    price: float


# N+1 Problem: 1 query for orders, then N queries for customers
def get_orders_with_customers() -> List[dict]:
    orders = db.query("SELECT * FROM orders")  # 1 query

    result = []
    for order in orders:
        # N queries - one per order!
        customer = db.query(f"SELECT * FROM customers WHERE id = {order.customer_id}")[0]
        result.append({
            "order": order,
            "customer": customer
        })

    return result


# N+1 Problem: Gets worse - 1 + N + N queries
def get_orders_with_details() -> List[dict]:
    orders = db.query("SELECT * FROM orders")  # 1 query

    result = []
    for order in orders:
        # N queries for customers
        customer = db.query(f"SELECT * FROM customers WHERE id = {order.customer_id}")[0]
        # N more queries for items
        items = db.query(f"SELECT * FROM order_items WHERE order_id = {order.id}")

        result.append({
            "order": order,
            "customer": customer,
            "items": items
        })

    return result


# Bonus: N+1 inside N+1 = N*M+1 queries
def get_full_order_report() -> List[dict]:
    orders = db.query("SELECT * FROM orders")  # 1 query

    result = []
    for order in orders:
        customer = db.query(f"SELECT * FROM customers WHERE id = {order.customer_id}")[0]
        items = db.query(f"SELECT * FROM order_items WHERE order_id = {order.id}")

        # For each item, fetch product details - N*M queries!
        enriched_items = []
        for item in items:
            product = db.query(f"SELECT * FROM products WHERE name = '{item.product_name}'")[0]
            enriched_items.append({
                "item": item,
                "product": product
            })

        result.append({
            "order": order,
            "customer": customer,
            "items": enriched_items
        })

    return result


# Could be fixed with JOIN or eager loading:
# SELECT o.*, c.* FROM orders o JOIN customers c ON o.customer_id = c.id

# Pagination without limit - fetches entire table
def get_all_orders_paginated(page: int, page_size: int) -> List[Order]:
    all_orders = db.query("SELECT * FROM orders")  # Gets ALL orders
    start = page * page_size
    end = start + page_size
    return all_orders[start:end]  # Then slices in memory... yikes


# Missing index - full table scan on every call
def find_orders_by_status(status: str) -> List[Order]:
    # status column has no index, scans 50k rows every time
    return db.query(f"SELECT * FROM orders WHERE status = '{status}'")


# Repeated queries in loop - should batch
def update_order_statuses(order_ids: List[int], new_status: str):
    for order_id in order_ids:
        db.execute(f"UPDATE orders SET status = '{new_status}' WHERE id = {order_id}")
    # Should be: UPDATE orders SET status = ? WHERE id IN (?, ?, ?)
