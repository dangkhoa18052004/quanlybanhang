# app/utils/helpers.py
from decimal import Decimal

def to_float(value):
    """Convert any numeric value to float safely"""
    if value is None:
        return 0.0
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, Decimal):
        return float(value)
    try:
        return float(value)
    except (ValueError, TypeError):
        return 0.0