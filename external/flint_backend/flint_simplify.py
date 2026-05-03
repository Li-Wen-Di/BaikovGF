#!/usr/bin/env python
"""Batch rational simplification backend powered by python-flint.

This backend expects a JSON payload with the shape

{
  "variables": ["x", "y"],
  "expressions": [
    {"id": "expr1", "ast": {...}}
  ],
  "workers": 4
}

The AST only supports Integer, Rational, Symbol, Plus, Times and Power
with integer exponents.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from time import perf_counter
from typing import Any, Dict, Iterable, List, Tuple

import flint


class FLINTBackendError(Exception):
    """Structured backend error."""


@dataclass
class RationalFunction:
    """A rational function stored as a reduced numerator/denominator pair."""

    num: Any
    den: Any

    def normalize(self) -> "RationalFunction":
        if self.den == 0:
            raise FLINTBackendError("Encountered a zero denominator in FLINT normalization.")
        if self.num == 0:
            zero = self.den * 0
            one = zero + 1
            self.num = zero
            self.den = one
            return self

        gcd_poly = self.num.gcd(self.den)
        if gcd_poly != 1:
            self.num = self.num / gcd_poly
            self.den = self.den / gcd_poly

        leading = self.den.leading_coefficient()
        if leading != 1:
            self.num = self.num / leading
            self.den = self.den / leading

        if self.den.leading_coefficient() < 0:
            self.num = -self.num
            self.den = -self.den

        return self

    def add(self, other: "RationalFunction") -> "RationalFunction":
        return RationalFunction(
            self.num * other.den + other.num * self.den,
            self.den * other.den,
        ).normalize()

    def mul(self, other: "RationalFunction") -> "RationalFunction":
        return RationalFunction(self.num * other.num, self.den * other.den).normalize()

    def pow(self, exponent: int) -> "RationalFunction":
        if exponent == 0:
            one = self.num * 0 + 1
            return RationalFunction(one, one)
        if exponent > 0:
            return RationalFunction(self.num**exponent, self.den**exponent).normalize()
        exponent = -exponent
        return RationalFunction(self.den**exponent, self.num**exponent).normalize()


def _ctx_and_generators(variable_names: Iterable[str]) -> Tuple[Any, Dict[str, Any]]:
    names = tuple(variable_names)
    ctx = flint.fmpq_mpoly_ctx.get(names)
    generators = dict(zip(names, ctx.gens()))
    return ctx, generators


def _constant_rf(ctx: Any, value: Any) -> RationalFunction:
    one = ctx.constant(1)
    return RationalFunction(ctx.constant(value), one)


def _parse_int_string(value: str) -> int:
    try:
        return int(value)
    except Exception as exc:
        raise FLINTBackendError(f"Invalid integer literal: {value}") from exc


def _ast_to_rf(node: Dict[str, Any], ctx: Any, generators: Dict[str, Any]) -> RationalFunction:
    head = node.get("head")

    if head == "Integer":
        return _constant_rf(ctx, int(node["value"]))

    if head == "Rational":
        return _constant_rf(ctx, flint.fmpq(int(node["p"]), int(node["q"])))

    if head == "Symbol":
        name = node["name"]
        if name not in generators:
            raise FLINTBackendError(f"Unknown variable in FLINT AST: {name}")
        one = ctx.constant(1)
        return RationalFunction(generators[name], one)

    if head == "Plus":
        args = node.get("args", [])
        result = _constant_rf(ctx, 0)
        for arg in args:
            result = result.add(_ast_to_rf(arg, ctx, generators))
        return result

    if head == "Times":
        args = node.get("args", [])
        result = _constant_rf(ctx, 1)
        for arg in args:
            result = result.mul(_ast_to_rf(arg, ctx, generators))
        return result

    if head == "Power":
        exponent = _parse_int_string(node["exp"])
        base = _ast_to_rf(node["base"], ctx, generators)
        return base.pow(exponent)

    raise FLINTBackendError(f"Unsupported AST head: {head}")


def _coefficient_ast(coeff: Any) -> Dict[str, Any]:
    numerator = int(coeff.numer())
    denominator = int(coeff.denom())
    if denominator == 1:
        return {"head": "Integer", "value": str(numerator)}
    return {"head": "Rational", "p": str(numerator), "q": str(denominator)}


def _multiply_ast(factors: List[Dict[str, Any]]) -> Dict[str, Any]:
    filtered = [factor for factor in factors if not (factor.get("head") == "Integer" and factor.get("value") == "1")]
    if not filtered:
        return {"head": "Integer", "value": "1"}
    if len(filtered) == 1:
        return filtered[0]
    return {"head": "Times", "args": filtered}


def _power_ast(symbol_name: str, exponent: int) -> Dict[str, Any]:
    symbol_ast = {"head": "Symbol", "name": symbol_name}
    if exponent == 1:
        return symbol_ast
    return {"head": "Power", "base": symbol_ast, "exp": str(exponent)}


def _poly_to_ast(poly: Any, variable_names: List[str]) -> Dict[str, Any]:
    if poly == 0:
        return {"head": "Integer", "value": "0"}

    terms: List[Dict[str, Any]] = []
    for monom, coeff in poly.terms():
        factors: List[Dict[str, Any]] = []
        coeff_ast = _coefficient_ast(coeff)
        if coeff_ast != {"head": "Integer", "value": "1"} or all(exp == 0 for exp in monom):
            factors.append(coeff_ast)
        for var_name, exponent in zip(variable_names, monom):
            if exponent:
                factors.append(_power_ast(var_name, int(exponent)))
        terms.append(_multiply_ast(factors))

    if len(terms) == 1:
        return terms[0]
    return {"head": "Plus", "args": terms}


def _simplify_one(entry: Dict[str, Any], variable_names: List[str]) -> Dict[str, Any]:
    ctx, generators = _ctx_and_generators(variable_names)
    rf = _ast_to_rf(entry["ast"], ctx, generators).normalize()
    return {
        "id": entry["id"],
        "status": "ok",
        "numerator": _poly_to_ast(rf.num, variable_names),
        "denominator": _poly_to_ast(rf.den, variable_names),
        "numeratorString": str(rf.num),
        "denominatorString": str(rf.den),
    }


def _simplify_one_safe(payload: Tuple[Dict[str, Any], List[str]]) -> Dict[str, Any]:
    entry, variable_names = payload
    start = perf_counter()
    try:
        result = _simplify_one(entry, variable_names)
        result["elapsedSeconds"] = perf_counter() - start
        return result
    except Exception as exc:
        return {
            "id": entry.get("id", "<unknown>"),
            "status": "error",
            "message": str(exc),
            "elapsedSeconds": perf_counter() - start,
        }


def _load_payload(args: argparse.Namespace) -> Dict[str, Any]:
    if args.input_file:
        return json.loads(Path(args.input_file).read_text(encoding="utf-8"))
    return json.load(sys.stdin)


def _write_payload(args: argparse.Namespace, payload: Dict[str, Any]) -> None:
    content = json.dumps(payload, ensure_ascii=False)
    if args.output_file:
        Path(args.output_file).write_text(content, encoding="utf-8")
    else:
        sys.stdout.write(content)


def main() -> int:
    parser = argparse.ArgumentParser(description="Batch rational simplification via python-flint.")
    parser.add_argument("--input-file", help="Optional JSON input file. Defaults to stdin.")
    parser.add_argument("--output-file", help="Optional JSON output file. Defaults to stdout.")
    parser.add_argument("--workers", type=int, help="Override worker count.")
    args = parser.parse_args()

    try:
        total_start = perf_counter()
        payload = _load_payload(args)
        variable_names = payload.get("variables", [])
        expressions = payload.get("expressions", [])
        requested_workers = args.workers or payload.get("workers") or 1
        max_available = os.cpu_count() or 1
        workers = max(1, min(int(requested_workers), max_available, max(len(expressions), 1)))

        if workers == 1 or len(expressions) <= 1:
            results = [_simplify_one_safe((entry, variable_names)) for entry in expressions]
        else:
            with ProcessPoolExecutor(max_workers=workers) as executor:
                results = list(executor.map(_simplify_one_safe, [(entry, variable_names) for entry in expressions]))

        response = {
            "status": "ok",
            "workersUsed": workers,
            "pythonVersion": sys.version,
            "flintVersion": flint.__version__,
            "elapsedSeconds": perf_counter() - total_start,
            "results": results,
        }
    except Exception as exc:
        response = {
            "status": "error",
            "message": str(exc),
        }

    _write_payload(args, response)
    return 0 if response.get("status") == "ok" else 1


if __name__ == "__main__":
    raise SystemExit(main())
