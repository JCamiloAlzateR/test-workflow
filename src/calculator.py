"""Simple calculator module."""


def add(a: int | float, b: int | float) -> int | float:
    """Add two numbers."""
    return a + b


def subtract(a: int | float, b: int | float) -> int | float:
    """Subtract b from a."""
    return a - b


def multiply(a: int | float, b: int | float) -> int | float:
    """Multiply two numbers."""
    return a * b


def divide(a: int | float, b: int | float) -> float:
    """Divide a by b. Raises ZeroDivisionError if b is 0."""
    if b == 0:
        raise ZeroDivisionError("Cannot divide by zero")
    return a / b


def power(base: int | float, exp: int | float) -> float:
    """Raise base to the power of exp."""
    return base**exp
