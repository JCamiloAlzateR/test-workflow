"""Advanced operations with intentional bugs for testing."""


def modulo(a: int, b: int) -> int:
    """Return a % b without checking for zero."""
    return a % b  # Bug: no zero check


def square_root(n: float) -> float:
    """Return sqrt(n) without checking for negative."""
    return n**0.5  # Bug: should check for negative


def int_divide(a: int, b: int) -> int:
    """Integer division that silently truncates."""
    return int(a / b)  # Bug: should use // operator


def power_zero(base: float) -> float:
    """Return base to power of zero."""
    return base**0  # Bug: 0**0 is 1, should be documented
