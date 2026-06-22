# φ (phi) — Unified Prolog Physics Solver

`phi` is a multi-directional, constraint-based classical physics engine and solver written in SWI-Prolog. It translates natural language physics word problems into logic queries, plans solution paths across chained formulas using A* search, and evaluates values and units using CLP(R) (Constraint Logic Programming over Reals).

## Key Features

*   **Multi-directional Solving**: Formulas are modeled as pure logical relations. You can solve for any variable in an equation (e.g. solve for acceleration $a$, mass $m$, or force $f$ from $f = m \cdot a$ with the same source code).
*   **Symbolic Algebra Core**: Automatically isolates variables across linear and simple non-linear physics equations at startup.
*   **Heuristic Solver & Planner**: Chains equations dynamically using an $A^*$ pathfinding search to resolve multi-step physics problems.
*   **SI Unit Conversion & Dimensional Verification**: Validates all calculations using 7-element dimension vectors and automatically normalizes input units (e.g., converting $\text{km/h}$ to $\text{m/s}$ or $\text{grams}$ to $\text{kilograms}$) before evaluating.
*   **Natural Language Ingestion**: Employs a Definite Clause Grammar (DCG) parser to ingest English word problems, extracting parameters, units, and goals.

---

## Getting Started

### Prerequisites

You can run `phi` either via **Nix Flakes** (recommended for a zero-install reproducible environment) or standard **SWI-Prolog**.

#### Method A: Using Nix (Zero Install)

If you have Nix installed with Flakes enabled, simply run:

```bash
nix develop
```

This enters a shell environment where the custom `phi` executable wrapper is loaded on your `$PATH`.

#### Method B: Using SWI-Prolog

Ensure you have [SWI-Prolog](https://www.swi-prolog.org/) installed on your machine.

---

## Usage

### Running the REPL

Launch the interactive shell by running the `phi` command (if using Nix) or loading the solver in `swipl`:

```bash
# Using Nix
phi

# Using standard SWI-Prolog
swipl -s physics_solver.pl
```

Your prompt will change to the project's signature `φ` shell:
```prolog
Welcome to phi: The Unified Prolog Physics Solver Env!
1 φ ?- 
```

### Example Natural Language Queries

Enter queries as strings to the `solve_nl/2` predicate:

```prolog
% Kinematics & Force chain
1 φ ?- solve_nl("2 kg starting from rest accelerates to 20 mps in 5 s find force", Result).

Derivation Steps:
  - velocity equation: a = (v-u)/t
    Substitution: a = (20.0-0.0)/5.0
    Computed:     a = 4.000000
  - newton equation: f = m*a
    Substitution: f = 2.0*4.0
    Computed:     f = 8.000000
Solved Result: f = 8.000000 newton
Result = 8.0.

% Unit conversion
2 φ ?- solve_nl("starts from 36 kmph to 72 kmph in 5 s find acceleration", Result).

Derivation Steps:
  - velocity equation: a = (v-u)/t
    Substitution: a = (20.0-10.0)/5.0
    Computed:     a = 2.000000
Solved Result: a = 2.000000 mps2
Result = 2.0.
```

### Running the Test Suite

Run the built-in validation suite directly:

```bash
phi -g "run_tests, halt."
```

---

## Repository Structure

```
├── flake.nix          # Nix flake defining SWI-Prolog and dev shell
├── flake.lock         # Nix lockfile
├── phi                # Bash wrapper script for swipl
├── physics_solver.pl  # Core Prolog implementation source
└── README.md          # Documentation
```
