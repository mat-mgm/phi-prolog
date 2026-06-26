:- module(physics_solver, [solve_nl/2, run_tests/0]).

:- use_module(library(clpr)).
:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(library(dcg/basics)).

:- set_prolog_flag(toplevel_prompt, '~m~d~l~! φ ?- ').

%% ==========================================
%% DIMENSIONS
%% Vectors represent: [L, M, T, I, Theta, N, J]
%% ==========================================

base_dimension(length,  [1,0,0,0,0,0,0]).
base_dimension(mass,    [0,1,0,0,0,0,0]).
base_dimension(time,    [0,0,1,0,0,0,0]).
base_dimension(current, [0,0,0,1,0,0,0]).
base_dimension(temp,    [0,0,0,0,1,0,0]).
base_dimension(amount,  [0,0,0,0,0,1,0]).
base_dimension(lum,     [0,0,0,0,0,0,1]).

% Variable dimensions
var_dim(f,       [1,1,-2,0,0,0,0]).
var_dim(m,       [0,1,0,0,0,0,0]).
var_dim(a,       [1,0,-2,0,0,0,0]).
var_dim(v,       [1,0,-1,0,0,0,0]).
var_dim(u,       [1,0,-1,0,0,0,0]).
var_dim(t,       [0,0,1,0,0,0,0]).
var_dim(s,       [1,0,0,0,0,0,0]).
var_dim(ke,      [2,1,-2,0,0,0,0]).
var_dim(pe,      [2,1,-2,0,0,0,0]).
var_dim(g,       [1,0,-2,0,0,0,0]).
var_dim(h,       [1,0,0,0,0,0,0]).
var_dim(volts,  [2,1,-3,-1,0,0,0]).
var_dim(amp,    [0,0,0,1,0,0,0]).
var_dim(res,    [2,1,-3,-2,0,0,0]).
var_dim(p,      [2,1,-3,0,0,0,0]).
var_dim(g_const, [3,-1,-2,0,0,0,0]).
var_dim(m1,      [0,1,0,0,0,0,0]).
var_dim(m2,      [0,1,0,0,0,0,0]).
var_dim(r,       [1,0,0,0,0,0,0]).
var_dim(density,  [-3,1,0,0,0,0,0]).
var_dim(vol,      [3,0,0,0,0,0,0]).
var_dim(pressure, [-1,1,-2,0,0,0,0]).
var_dim(freq,     [0,0,-1,0,0,0,0]).
var_dim(lambda,   [1,0,0,0,0,0,0]).
var_dim(t_period, [0,0,1,0,0,0,0]).
var_dim(n_amount, [0,0,0,0,0,1,0]).
var_dim(r_gas,    [2,1,-2,0,-1,-1,0]).
var_dim(temp,     [0,0,0,0,1,0,0]).
var_dim(torque,   [2,1,-2,0,0,0,0]).
var_dim(i_inertia, [2,1,0,0,0,0,0]).
var_dim(alpha_rot, [0,0,-2,0,0,0,0]).
var_dim(omega_rot, [0,0,-1,0,0,0,0]).
var_dim(l_ang_mom, [2,1,-1,0,0,0,0]).
var_dim(ke_rot,   [2,1,-2,0,0,0,0]).
var_dim(q_heat,   [2,1,-2,0,0,0,0]).
var_dim(c_heat,   [2,0,-2,0,-1,0,0]).
var_dim(delta_temp, [0,0,0,0,1,0,0]).





% Dimensions arithmetic
dim_add([], [], []).
dim_add([A|As], [B|Bs], [C|Cs]) :-
    C is A + B,
    dim_add(As, Bs, Cs).

dim_sub([], [], []).
dim_sub([A|As], [B|Bs], [C|Cs]) :-
    C is A - B,
    dim_sub(As, Bs, Cs).

dim_scale([], _, []).
dim_scale([H|T], Factor, [ScaledH|ScaledT]) :-
    ScaledH is H * Factor,
    dim_scale(T, Factor, ScaledT).

dim_equal([], []).
dim_equal([H1|T1], [H2|T2]) :-
    abs(H1 - H2) < 0.0001,
    dim_equal(T1, T2).

%% ==========================================
%% UNITS SYSTEM
%% unit(UnitName, DimensionVector, ScaleToSI)
%% ==========================================

unit(m,   [1,0,0,0,0,0,0], 1.0).
unit(km,  [1,0,0,0,0,0,0], 1000.0).
unit(cm,  [1,0,0,0,0,0,0], 0.01).

unit(kg,  [0,1,0,0,0,0,0], 1.0).
unit(g,   [0,1,0,0,0,0,0], 0.001).

unit(s,   [0,0,1,0,0,0,0], 1.0).
unit(h,   [0,0,1,0,0,0,0], 3600.0).
unit(min, [0,0,1,0,0,0,0], 60.0).

unit(mps,  [1,0,-1,0,0,0,0], 1.0).
unit(kmph, [1,0,-1,0,0,0,0], 0.2777777777777778).

unit(mps2, [1,0,-2,0,0,0,0], 1.0).

unit(newton, [1,1,-2,0,0,0,0], 1.0).
unit(n,      [1,1,-2,0,0,0,0], 1.0).

unit(joule,  [2,1,-2,0,0,0,0], 1.0).
unit(j,      [2,1,-2,0,0,0,0], 1.0).

unit(watt,   [2,1,-3,0,0,0,0], 1.0).
unit(w,      [2,1,-3,0,0,0,0], 1.0).

unit(volt,   [2,1,-3,-1,0,0,0], 1.0).
unit(v,      [2,1,-3,-1,0,0,0], 1.0).

unit(amp,    [0,0,0,1,0,0,0], 1.0).
unit(a,      [0,0,0,1,0,0,0], 1.0).

unit(ohm,    [2,1,-3,-2,0,0,0], 1.0).
unit(r,      [2,1,-3,-2,0,0,0], 1.0).

% Density units
unit(kg_per_m3, [-3,1,0,0,0,0,0], 1.0).
unit(g_per_cm3, [-3,1,0,0,0,0,0], 1000.0).

% Volume units
unit(m3,        [3,0,0,0,0,0,0], 1.0).
unit(liter,     [3,0,0,0,0,0,0], 0.001).
unit(l,         [3,0,0,0,0,0,0], 0.001).
unit(liters,    [3,0,0,0,0,0,0], 0.001).

% Pressure units
unit(pascal,    [-1,1,-2,0,0,0,0], 1.0).
unit(pa,        [-1,1,-2,0,0,0,0], 1.0).
unit(atm,       [-1,1,-2,0,0,0,0], 101325.0).
unit(bar,       [-1,1,-2,0,0,0,0], 100000.0).

% Frequency units
unit(hertz,     [0,0,-1,0,0,0,0], 1.0).
unit(hz,        [0,0,-1,0,0,0,0], 1.0).

% Wavelength units
unit(nm,        [1,0,0,0,0,0,0], 1e-9).

% Temperature units
unit(kelvin,    [0,0,0,0,1,0,0], 1.0).
unit(k,         [0,0,0,0,1,0,0], 1.0).

% Amount of substance units
unit(mole,      [0,0,0,0,0,1,0], 1.0).
unit(mol,       [0,0,0,0,0,1,0], 1.0).
unit(moles,     [0,0,0,0,0,1,0], 1.0).

% Gas constant units
unit(j_per_mol_k, [2,1,-2,0,-1,-1,0], 1.0).

% Rotational dynamics units
unit(n_m,        [2,1,-2,0,0,0,0], 1.0).
unit(kg_m2,      [2,1,0,0,0,0,0], 1.0).
unit(rad_per_s2, [0,0,-2,0,0,0,0], 1.0).
unit(rad_per_s,  [0,0,-1,0,0,0,0], 1.0).
unit(kg_m2_per_s, [2,1,-1,0,0,0,0], 1.0).

% Heat units
unit(j_per_kg_k, [2,0,-2,0,-1,0,0], 1.0).





% Word plural aliases
unit(meters,    [1,0,0,0,0,0,0], 1.0).
unit(kilograms, [0,1,0,0,0,0,0], 1.0).
unit(seconds,   [0,0,1,0,0,0,0], 1.0).
unit(hours,     [0,0,1,0,0,0,0], 3600.0).
unit(minutes,   [0,0,1,0,0,0,0], 60.0).
unit(watts,     [2,1,-3,0,0,0,0], 1.0).
unit(volts,     [2,1,-3,-1,0,0,0], 1.0).
unit(amps,      [0,0,0,1,0,0,0], 1.0).
unit(ohms,      [2,1,-3,-2,0,0,0], 1.0).


%% ==========================================
%% EQUATION REGISTRY & INFERENCE/LEARNING
%% ==========================================

:- dynamic learned_eq/2.

% Core base equations
base_eq(newton,           f = m * a).
base_eq(velocity,         v = u + a * t).
base_eq(displacement,     s = u * t + 0.5 * a * t * t).
base_eq(kinetic_energy,   ke = 0.5 * m * v * v).
base_eq(potential_energy, pe = m * g * h).
base_eq(ohm,              volts = amp * res).
base_eq(power,            p = volts * amp).
base_eq(gravity,          f = g_const * m1 * m2 / (r * r)).
base_eq(density,          density = m / vol).
base_eq(hydrostatic_pres, pressure = density * g * h).
base_eq(centripetal_acc,  a = v * v / r).
base_eq(wave_speed,       v = freq * lambda).
base_eq(wave_period,      freq = 1 / t_period).
base_eq(ideal_gas,        pressure * vol = n_amount * r_gas * temp).
base_eq(torque_eq,        torque = i_inertia * alpha_rot).
base_eq(rotational_ke,    ke_rot = 0.5 * i_inertia * omega_rot * omega_rot).
base_eq(angular_momentum, l_ang_mom = i_inertia * omega_rot).
base_eq(heat_energy,      q_heat = m * c_heat * delta_temp).






base_eq_normalized(Name, NormalEq) :-
    base_eq(Name, Eq),
    to_pow(Eq, NormalEq).

learn_equations :-
    retractall(learned_eq(_, _)),
    forall(
        base_eq_normalized(Name, Eq),
        (
            assertz(learned_eq(Name, Eq)),
            expr_vars(Eq, Vars),
            forall(
                member(V, Vars),
                (
                    (solve_for(Eq, V, Expr) ->
                        (learned_eq(Name, V = Expr) ->
                            true
                        ;
                            assertz(learned_eq(Name, V = Expr))
                        )
                    ;
                        true
                    )
                )
            )
        )
    ).

% Automatically run equation compilation on load
:- initialization(learn_equations).

%% ==========================================
%% SYMBOLIC ALGEBRA ENGINE
%% ==========================================

% Convert multiplications to power representation: X * X -> X^2
to_pow(X, X) :- var(X), !.
to_pow(X, X) :- number(X), !.
to_pow(X, X) :- atom(X), !.
to_pow(A = B, SA = SB) :- !, to_pow(A, SA), to_pow(B, SB).
to_pow(A * B, R) :-
    to_pow(A, SA),
    to_pow(B, SB),
    (SA == SB -> R = SA^2 ; R = SA * SB), !.
to_pow(A + B, SA + SB) :- !, to_pow(A, SA), to_pow(B, SB).
to_pow(A - B, SA - SB) :- !, to_pow(A, SA), to_pow(B, SB).
to_pow(A / B, SA / SB) :- !, to_pow(A, SA), to_pow(B, SB).
to_pow(A^B, SA^SB) :- !, to_pow(A, SA), to_pow(B, SB).
to_pow(sqrt(A), sqrt(SA)) :- !, to_pow(A, SA).

% solve_for(Equation, Target, IsolatedExpr)
solve_for(LHS = RHS, Target, Expr) :-
    LHS == Target, !, Expr = RHS.
solve_for(LHS = RHS, Target, Expr) :-
    contains(LHS, Target), !,
    isolate(RHS = LHS, Target, Target = Expr).
solve_for(LHS = RHS, Target, Expr) :-
    contains(RHS, Target), !,
    isolate(LHS = RHS, Target, Target = Expr).

% isolation rules
isolate(Target = RHS, Target, Target = RHS) :- !.
isolate(LHS = Target, Target, Target = LHS) :- !.
isolate(L = A + B, Target, Result) :-
    (contains(A, Target) ->
        isolate(L - B = A, Target, Result)
    ;
        isolate(L - A = B, Target, Result)
    ).
isolate(L = A - B, Target, Result) :-
    (contains(A, Target) ->
        isolate(L + B = A, Target, Result)
    ;
        isolate(A - L = B, Target, Result)
    ).
isolate(L = A * B, Target, Result) :-
    (contains(A, Target) ->
        isolate(L / B = A, Target, Result)
    ;
        isolate(L / A = B, Target, Result)
    ).
isolate(L = A / B, Target, Result) :-
    (contains(A, Target) ->
        isolate(L * B = A, Target, Result)
    ;
        isolate(A / L = B, Target, Result)
    ).
isolate(L = A^B, Target, Result) :-
    number(B), !,
    InvB is 1.0 / B,
    isolate(L^InvB = A, Target, Result).
isolate(L = A^B, Target, Result) :-
    number(A), !,
    isolate(log(L)/log(A) = B, Target, Result).
isolate(L = sqrt(A), Target, Result) :-
    isolate(L^2 = A, Target, Result).

% contains(Expr, Target)
contains(Target, Target) :- !.
contains(A = B, Target) :- (contains(A, Target); contains(B, Target)), !.
contains(A + B, Target) :- (contains(A, Target); contains(B, Target)), !.
contains(A - B, Target) :- (contains(A, Target); contains(B, Target)), !.
contains(A * B, Target) :- (contains(A, Target); contains(B, Target)), !.
contains(A / B, Target) :- (contains(A, Target); contains(B, Target)), !.
contains(A^B, Target) :- (contains(A, Target); contains(B, Target)), !.
contains(sqrt(A), Target) :- contains(A, Target), !.

%% ==========================================
%% MATHEMATICAL PROPAGATION & MATH EVAL
%% ==========================================

% Extract all unique variables in an expression
expr_vars(A = B, Vs) :- !,
    expr_vars(A, VA),
    expr_vars(B, VB),
    append(VA, VB, VAB),
    list_to_set(VAB, Vs).
expr_vars(X, [X]) :- atom(X), !.
expr_vars(X, []) :- number(X), !.
expr_vars(A + B, Vs) :- !, expr_vars(A, VA), expr_vars(B, VB), append(VA, VB, VAB), list_to_set(VAB, Vs).
expr_vars(A - B, Vs) :- !, expr_vars(A, VA), expr_vars(B, VB), append(VA, VB, VAB), list_to_set(VAB, Vs).
expr_vars(A * B, Vs) :- !, expr_vars(A, VA), expr_vars(B, VB), append(VA, VB, VAB), list_to_set(VAB, Vs).
expr_vars(A / B, Vs) :- !, expr_vars(A, VA), expr_vars(B, VB), append(VA, VB, VAB), list_to_set(VAB, Vs).
expr_vars(A^B, Vs) :- !, expr_vars(A, VA), expr_vars(B, VB), append(VA, VB, VAB), list_to_set(VAB, Vs).
expr_vars(sqrt(A), Vs) :- !, expr_vars(A, Vs).

% Substitute state variable values into math term
substitute_vars(X, _, X) :- number(X), !.
substitute_vars(X, State, Val) :-
    atom(X), !,
    (get_var(X, State, var(X, V, _, _)) ->
        (nonvar(V) -> Val = V ; Val = X)
    ;
        (X == g_const -> Val = 6.6743e-11 ; Val = X)
    ).
substitute_vars(A + B, S, SA + SB) :- substitute_vars(A, S, SA), substitute_vars(B, S, SB).
substitute_vars(A - B, S, SA - SB) :- substitute_vars(A, S, SA), substitute_vars(B, S, SB).
substitute_vars(A * B, S, SA * SB) :- substitute_vars(A, S, SA), substitute_vars(B, S, SB).
substitute_vars(A / B, S, SA / SB) :- substitute_vars(A, S, SA), substitute_vars(B, S, SB).
substitute_vars(A^B, S, SA^SB) :- substitute_vars(A, S, SA), substitute_vars(B, S, SB).
substitute_vars(sqrt(A), S, sqrt(SA)) :- substitute_vars(A, S, SA).

% substitute_vars_symbolic
substitute_vars_symbolic(X, _, X) :- number(X), !.
substitute_vars_symbolic(X, State, Val) :-
    atom(X), !,
    (get_var(X, State, var(X, V, _, _)) ->
        (nonvar(V) -> Val = V ; Val = X)
    ;
        (X == g_const -> Val = 6.6743e-11 ; Val = X)
    ).
substitute_vars_symbolic(A + B, S, SA + SB) :- substitute_vars_symbolic(A, S, SA), substitute_vars_symbolic(B, S, SB).
substitute_vars_symbolic(A - B, S, SA - SB) :- substitute_vars_symbolic(A, S, SA), substitute_vars_symbolic(B, S, SB).
substitute_vars_symbolic(A * B, S, SA * SB) :- substitute_vars_symbolic(A, S, SA), substitute_vars_symbolic(B, S, SB).
substitute_vars_symbolic(A / B, S, SA / SB) :- substitute_vars_symbolic(A, S, SA), substitute_vars_symbolic(B, S, SB).
substitute_vars_symbolic(A^B, S, SA^SB) :- substitute_vars_symbolic(A, S, SA), substitute_vars_symbolic(B, S, SB).
substitute_vars_symbolic(sqrt(A), S, sqrt(SA)) :- substitute_vars_symbolic(A, S, SA).

% Evaluate the math using either is/2 or CLP(R)
evaluate_math(Expr, Value) :-
    ground(Expr), !,
    catch(Value is Expr, _, fail).
evaluate_math(Expr, Value) :-
    catch({ Value = Expr }, _, fail).

% Dimensional Analysis
eval_dim(X, _, [0,0,0,0,0,0,0]) :- number(X), !.
eval_dim(X, State, Dim) :-
    atom(X), !,
    (get_var(X, State, var(X, _, Dim, _)) ->
        true
    ;
        (X == g_const -> Dim = [3,-1,-2,0,0,0,0] ; var_dim(X, Dim))
    ).
eval_dim(A + B, State, Dim) :-
    eval_dim(A, State, DimA),
    eval_dim(B, State, DimB),
    dim_equal(DimA, DimB),
    Dim = DimA.
eval_dim(A - B, State, Dim) :-
    eval_dim(A, State, DimA),
    eval_dim(B, State, DimB),
    dim_equal(DimA, DimB),
    Dim = DimA.
eval_dim(A * B, State, Dim) :-
    eval_dim(A, State, DimA),
    eval_dim(B, State, DimB),
    dim_add(DimA, DimB, Dim).
eval_dim(A / B, State, Dim) :-
    eval_dim(A, State, DimA),
    eval_dim(B, State, DimB),
    dim_sub(DimA, DimB, Dim).
eval_dim(A^B, State, Dim) :-
    number(B),
    eval_dim(A, State, DimA),
    dim_scale(DimA, B, Dim).
eval_dim(sqrt(A), State, Dim) :-
    eval_dim(A, State, DimA),
    dim_scale(DimA, 0.5, Dim).

%% ==========================================
%% SEARCH & PLANNING ENGINE (A* SEARCH)
%% ==========================================

get_var(Name, [var(Name, V, D, S)|_], var(Name, V, D, S)) :- !.
get_var(Name, [_|Rest], Var) :- get_var(Name, Rest, Var).

var_known(State, Name) :-
    get_var(Name, State, var(Name, Val, _, _)),
    nonvar(Val).

can_solve_eq_learned(EqName, State, TargetName, Expr) :-
    learned_eq(EqName, TargetName = Expr),
    % Dimension check
    eval_dim(Expr, State, ExprDim),
    get_var(TargetName, State, var(TargetName, _, TargetDim, _)),
    dim_equal(ExprDim, TargetDim),
    % Requirement check
    expr_vars(Expr, Required),
    forall(member(V, Required), var_known(State, V)).

% solve_state(State, Target, Path, Value)
solve_state(State, Target, Path, Value) :-
    heuristic(State, H),
    astar([[State, 0, H, []]], Target, Path, Value).

heuristic(State, H) :-
    include(unknown_var, State, Unknowns),
    length(Unknowns, H).

unknown_var(var(_, Val, _, _)) :- var(Val).

% astar(Queue, Target, Path, Value)
astar([[State, _, _, Path]|_], Target, Path, Value) :-
    get_var(Target, State, var(Target, Value, _, _)),
    nonvar(Value), !.

astar([[State, G, _, Path]|Rest], Target, FinalPath, Value) :-
    findall([NextState, G2, F, [Step|Path]],
        (
            learned_eq(EqName, TargetName = Expr),
            member(var(TargetName, Val, _, _), State),
            var(Val),
            can_solve_eq_learned(EqName, State, TargetName, Expr),
            % Apply equation
            substitute_vars(Expr, State, EvaluatedExpr),
            evaluate_math(EvaluatedExpr, TargetVal),
            copy_term(State, NextState),
            get_var(TargetName, NextState, var(TargetName, NewVal, _, _)),
            NewVal = TargetVal,
            % Step info
            substitute_vars_symbolic(Expr, State, SubbedExpr),
            Step = step(EqName, TargetName, Expr, SubbedExpr, TargetVal),
            G2 is G + 1,
            heuristic(NextState, H),
            F is G2 + H
        ),
        Children),
    append(Rest, Children, Open),
    keys_sort_by_f(Open, SortedOpen),
    astar(SortedOpen, Target, FinalPath, Value).

keys_sort_by_f(Queue, Sorted) :-
    map_list_to_pairs(get_f_score, Queue, Pairs),
    keysort(Pairs, SortedPairs),
    pairs_values(SortedPairs, Sorted).

get_f_score([_, _, F, _], F).

%% ==========================================
%% NATURAL LANGUAGE DCG GRAMMAR & PARSER
%% ==========================================

% Tokenizer (Punctuation-Aware and Case-Insensitive)
tokenize(String, Tokens) :-
    string_lower(String, LowerString),
    string_codes(LowerString, Codes),
    maplist(replace_punctuation, Codes, CleanCodes),
    string_codes(CleanString, CleanCodes),
    split_string(CleanString, " ", " ", WordStrings),
    exclude(==(""), WordStrings, NonEmptyStrings),
    maplist(convert_token, NonEmptyStrings, Tokens).

replace_punctuation(Code, 32) :- % replace punctuation with space (code 32)
    member(Code, [44, 63, 33, 58, 59, 40, 41, 91, 93, 34, 39]), !. % , ? ! : ; ( ) [ ] " '
replace_punctuation(Code, Code).

convert_token(WordStr, Number) :-
    number_string(Number, WordStr), !.
convert_token(WordStr, WordAtom) :-
    string_codes(WordStr, Codes),
    strip_trailing_dots(Codes, CleanCodes),
    string_codes(CleanWordStr, CleanCodes),
    (   number_string(Number, CleanWordStr)
    ->  Number = Number
    ;   atom_string(WordAtom, CleanWordStr)
    ).

strip_trailing_dots(Codes, CleanCodes) :-
    reverse(Codes, Rev),
    strip_leading_dots(Rev, RevClean),
    reverse(RevClean, CleanCodes).

strip_leading_dots([46|Rest], Clean) :- !, % code 46 is '.'
    strip_leading_dots(Rest, Clean).
strip_leading_dots(Cs, Cs).


% DCG Rules
sentence(State, Goal) -->
    items(Items),
    { extract_state_goal(Items, State, Goal) }.

items([Item|Rest]) -->
    phrase_item(Item),
    !,
    items(Rest).
items([]) --> [].

% Match phrase kinds
phrase_item(var(u, 0, [1,0,-1,0,0,0,0], 1.0)) --> [from, rest].
phrase_item(var(u, N, Dim, Scale)) --> [from], number_or_float(N), unit_name(UName, Dim, Scale), { unit_type(UName, velocity) }.
phrase_item(var(v, N, Dim, Scale)) --> [to], number_or_float(N), unit_name(UName, Dim, Scale), { unit_type(UName, velocity) }.
phrase_item(var(u, N, Dim, Scale)) --> [initial, velocity, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(v, N, Dim, Scale)) --> [final, velocity, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(h, N, Dim, Scale)) --> [height, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(h, N, Dim, Scale)) --> [height], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(vol, N, Dim, Scale)) --> [volume, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(vol, N, Dim, Scale)) --> [volume], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(r, N, Dim, Scale)) --> [separation, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(r, N, Dim, Scale)) --> [radius, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(lambda, N, Dim, Scale)) --> [wavelength, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(lambda, N, Dim, Scale)) --> [wavelength], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(t_period, N, Dim, Scale)) --> [period, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(t_period, N, Dim, Scale)) --> [period], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(temp, N, Dim, Scale)) --> [temperature, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(temp, N, Dim, Scale)) --> [temperature], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(delta_temp, N, Dim, Scale)) --> [temperature, difference, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(delta_temp, N, Dim, Scale)) --> [change, in, temperature, of], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(delta_temp, N, Dim, Scale)) --> [temperature, difference], number_or_float(N), unit_name(_, Dim, Scale).
phrase_item(var(delta_temp, N, Dim, Scale)) --> [change, in, temperature], number_or_float(N), unit_name(_, Dim, Scale).






phrase_item(var(Name, N, Dim, Scale)) -->
    optional_preposition,
    number_or_float(N),
    unit_name(UName, Dim, Scale),
    { determine_name_from_unit(UName, Name) }.

phrase_item(goal(GoalName)) -->
    goal_word,
    goal_target(GoalName).

phrase_item(ignored) --> [Word], { filler_word(Word) }.

optional_preposition --> [at].
optional_preposition --> [for].
optional_preposition --> [of].
optional_preposition --> [in].
optional_preposition --> [].

goal_word --> [find].
goal_word --> [what, is].
goal_word --> [calculate].
goal_word --> [solve, for].

goal_target(f)     --> [force].
goal_target(r)     --> [separation].
goal_target(r)     --> [radius].
goal_target(density)   --> [density].
goal_target(vol)       --> [volume].
goal_target(pressure)  --> [pressure].
goal_target(freq)      --> [frequency].
goal_target(lambda)    --> [wavelength].
goal_target(t_period)  --> [period].
goal_target(n_amount)  --> [amount, of, substance].
goal_target(n_amount)  --> [moles].
goal_target(temp)      --> [temperature].
goal_target(torque)       --> [torque].
goal_target(i_inertia)    --> [moment, of, inertia].
goal_target(i_inertia)    --> [inertia].
goal_target(alpha_rot)    --> [angular, acceleration].
goal_target(omega_rot)    --> [angular, velocity].
goal_target(l_ang_mom)    --> [angular, momentum].
goal_target(ke_rot)       --> [rotational, kinetic, energy].
goal_target(ke_rot)       --> [rotational, energy].
goal_target(q_heat)       --> [heat].
goal_target(q_heat)       --> [heat, energy].
goal_target(c_heat)       --> [specific, heat].
goal_target(c_heat)       --> [specific, heat, capacity].
goal_target(delta_temp)   --> [temperature, difference].
goal_target(delta_temp)   --> [change, in, temperature].



goal_target(m)     --> [mass].
goal_target(a)     --> [acceleration].
goal_target(t)     --> [time].
goal_target(v)     --> [velocity].
goal_target(u)     --> [initial, velocity].
goal_target(s)     --> [displacement].
goal_target(s)     --> [distance].
goal_target(ke)    --> [kinetic, energy].
goal_target(pe)    --> [potential, energy].
goal_target(volts) --> [voltage].
goal_target(amp)   --> [current].
goal_target(res)   --> [resistance].
goal_target(p)     --> [power].

unit_type(mps,  velocity).
unit_type(kmph, velocity).

determine_name_from_unit(kg, m).
determine_name_from_unit(g, m).
determine_name_from_unit(s, t).
determine_name_from_unit(min, t).
determine_name_from_unit(h, t).
determine_name_from_unit(mps, v).
determine_name_from_unit(kmph, v).
determine_name_from_unit(mps2, a).
determine_name_from_unit(newton, f).
determine_name_from_unit(n, f).
determine_name_from_unit(joule, ke).
determine_name_from_unit(j, ke).
determine_name_from_unit(watt, p).
determine_name_from_unit(w, p).
determine_name_from_unit(volt, volts).
determine_name_from_unit(v, volts).
determine_name_from_unit(amp, amp).
determine_name_from_unit(a, amp).
determine_name_from_unit(ohm, res).
determine_name_from_unit(r, res).
determine_name_from_unit(m, s).
determine_name_from_unit(km, s).
determine_name_from_unit(cm, s).
determine_name_from_unit(kg_per_m3, density).
determine_name_from_unit(g_per_cm3, density).
determine_name_from_unit(m3, vol).
determine_name_from_unit(liter, vol).
determine_name_from_unit(l, vol).
determine_name_from_unit(liters, vol).
determine_name_from_unit(pascal, pressure).
determine_name_from_unit(pa, pressure).
determine_name_from_unit(atm, pressure).
determine_name_from_unit(bar, pressure).
determine_name_from_unit(hertz, freq).
determine_name_from_unit(hz, freq).
determine_name_from_unit(nm, lambda).
determine_name_from_unit(kelvin, temp).
determine_name_from_unit(k, temp).
determine_name_from_unit(mole, n_amount).
determine_name_from_unit(mol, n_amount).
determine_name_from_unit(moles, n_amount).
determine_name_from_unit(n_m, torque).
determine_name_from_unit(kg_m2, i_inertia).
determine_name_from_unit(rad_per_s2, alpha_rot).
determine_name_from_unit(rad_per_s, omega_rot).
determine_name_from_unit(kg_m2_per_s, l_ang_mom).
determine_name_from_unit(j_per_kg_k, c_heat).




determine_name_from_unit(meters, s).
determine_name_from_unit(kilograms, m).
determine_name_from_unit(seconds, t).
determine_name_from_unit(hours, t).
determine_name_from_unit(minutes, t).
determine_name_from_unit(watts, p).
determine_name_from_unit(volts, volts).
determine_name_from_unit(amps, amp).
determine_name_from_unit(ohms, res).


number_or_float(N) --> [N], { number(N) }.
unit_name(UName, Dim, Scale) --> [UName], { unit(UName, Dim, Scale) }.

extract_state_goal(Items, State, Goal) :-
    extract_state_goal(Items, [], State, _, Goal).

extract_state_goal([], State, State, Goal, Goal).
extract_state_goal([var(Name, Val, Dim, Scale)|Rest], StateAcc, State, GoalAcc, Goal) :-
    extract_state_goal(Rest, [var(Name, Val, Dim, Scale)|StateAcc], State, GoalAcc, Goal).
extract_state_goal([goal(G)|Rest], StateAcc, State, _, Goal) :-
    extract_state_goal(Rest, StateAcc, State, G, Goal).
extract_state_goal([ignored|Rest], StateAcc, State, GoalAcc, Goal) :-
    extract_state_goal(Rest, StateAcc, State, GoalAcc, Goal).

% Fillers
filler_word(a).
filler_word(an).
filler_word(the).
filler_word(object).
filler_word(mass).
filler_word(car).
filler_word(goes).
filler_word(accelerates).
filler_word(accelerating).
filler_word(at).
filler_word(for).
filler_word(in).
filler_word(from).
filler_word(to).
filler_word(and).
filler_word(with).
filler_word(has).
filler_word(having).
filler_word(rest).
filler_word(velocity).
filler_word(force).
filler_word(acceleration).
filler_word(time).
filler_word(displacement).
filler_word(distance).
filler_word(energy).
filler_word(kinetic).
filler_word(potential).
filler_word(voltage).
filler_word(current).
filler_word(resistance).
filler_word(power).
filler_word(of).
filler_word(is).
filler_word(after).
filler_word(starts).
filler_word(starting).
filler_word(stops).
filler_word(stopping).
filler_word(constant).
filler_word(uniform).
filler_word(moves).
filler_word(moving).
filler_word(travels).
filler_word(traveling).
filler_word(height).
filler_word(density).
filler_word(volume).
filler_word(pressure).
filler_word(frequency).
filler_word(wavelength).
filler_word(period).
filler_word(temperature).
filler_word(mole).
filler_word(moles).
filler_word(torque).
filler_word(inertia).
filler_word(angular).
filler_word(momentum).
filler_word(heat).
filler_word(specific).
filler_word(capacity).
filler_word(difference).
filler_word(change).





%% ==========================================
%% INITIALIZATION & SOLVER PIPELINE
%% ==========================================

initialize_state(ParsedVars, FullState) :-
    AllVars = [
        var(f, _, [1,1,-2,0,0,0,0], 1.0),
        var(m, _, [0,1,0,0,0,0,0], 1.0),
        var(a, _, [1,0,-2,0,0,0,0], 1.0),
        var(v, _, [1,0,-1,0,0,0,0], 1.0),
        var(u, _, [1,0,-1,0,0,0,0], 1.0),
        var(t, _, [0,0,1,0,0,0,0], 1.0),
        var(s, _, [1,0,0,0,0,0,0], 1.0),
        var(ke, _, [2,1,-2,0,0,0,0], 1.0),
        var(pe, _, [2,1,-2,0,0,0,0], 1.0),
        var(g, 9.8, [1,0,-2,0,0,0,0], 1.0),
        var(h, _, [1,0,0,0,0,0,0], 1.0),
        var(volts, _, [2,1,-3,-1,0,0,0], 1.0),
        var(amp, _, [0,0,0,1,0,0,0], 1.0),
        var(res, _, [2,1,-3,-2,0,0,0], 1.0),
        var(p, _, [2,1,-3,0,0,0,0], 1.0),
        var(g_const, 6.6743e-11, [3,-1,-2,0,0,0,0], 1.0),
        var(m1, _, [0,1,0,0,0,0,0], 1.0),
        var(m2, _, [0,1,0,0,0,0,0], 1.0),
        var(r, _, [1,0,0,0,0,0,0], 1.0),
        var(density, _, [-3,1,0,0,0,0,0], 1.0),
        var(vol, _, [3,0,0,0,0,0,0], 1.0),
        var(pressure, _, [-1,1,-2,0,0,0,0], 1.0),
        var(freq, _, [0,0,-1,0,0,0,0], 1.0),
        var(lambda, _, [1,0,0,0,0,0,0], 1.0),
        var(t_period, _, [0,0,1,0,0,0,0], 1.0),
        var(n_amount, _, [0,0,0,0,0,1,0], 1.0),
        var(r_gas, 8.314462618, [2,1,-2,0,-1,-1,0], 1.0),
        var(temp, _, [0,0,0,0,1,0,0], 1.0),
        var(torque, _, [2,1,-2,0,0,0,0], 1.0),
        var(i_inertia, _, [2,1,0,0,0,0,0], 1.0),
        var(alpha_rot, _, [0,0,-2,0,0,0,0], 1.0),
        var(omega_rot, _, [0,0,-1,0,0,0,0], 1.0),
        var(l_ang_mom, _, [2,1,-1,0,0,0,0], 1.0),
        var(ke_rot, _, [2,1,-2,0,0,0,0], 1.0),
        var(q_heat, _, [2,1,-2,0,0,0,0], 1.0),
        var(c_heat, _, [2,0,-2,0,-1,0,0], 1.0),
        var(delta_temp, _, [0,0,0,0,1,0,0], 1.0)




    ],
    maplist(merge_var(ParsedVars), AllVars, FullState).

merge_var(ParsedVars, var(Name, Value, Dim, Scale), var(Name, MergedValue, Dim, Scale)) :-
    (member(var(Name, Val, _, ParseScale), ParsedVars) ->
        MergedValue is Val * ParseScale / Scale
    ;
        MergedValue = Value
    ).

% Main parser/solver entry point
solve_nl(Sentence, Result) :-
    tokenize(Sentence, Tokens),
    (phrase(sentence(ParsedVars, Goal), Tokens) ->
        initialize_state(ParsedVars, State),
        (solve_state(State, Goal, Path, Value) ->
            format_derivation(Path, Goal, Value, Result)
        ;
            writeln("Error: Could not solve the problem with the given facts."),
            fail
        )
    ;
        writeln("Error: Could not parse the sentence structure."),
        fail
    ).

% Format step-by-step logical derivation walkthrough
format_derivation(Path, Goal, Value, Result) :-
    reverse(Path, ForwardPath),
    writeln("Derivation Steps:"),
    print_steps(ForwardPath),
    get_goal_unit(Goal, UnitSymbol),
    format("Solved Result: ~w = ~6f ~w~n", [Goal, Value, UnitSymbol]),
    Result = Value.

print_steps([]).
print_steps([step(EqName, TargetName, Expr, SubbedExpr, TargetVal)|Rest]) :-
    format("  - ~w equation: ~w = ~w~n", [EqName, TargetName, Expr]),
    format("    Substitution: ~w = ~w~n", [TargetName, SubbedExpr]),
    format("    Computed:     ~w = ~6f~n", [TargetName, TargetVal]),
    print_steps(Rest).

get_goal_unit(f, newton).
get_goal_unit(a, mps2).
get_goal_unit(t, s).
get_goal_unit(m, kg).
get_goal_unit(v, mps).
get_goal_unit(u, mps).
get_goal_unit(s, m).
get_goal_unit(ke, joule).
get_goal_unit(pe, joule).
get_goal_unit(volts, volt).
get_goal_unit(amp, amp).
get_goal_unit(res, ohm).
get_goal_unit(p, watt).
get_goal_unit(m1, kg).
get_goal_unit(m2, kg).
get_goal_unit(r, m).
get_goal_unit(density, kg_per_m3).
get_goal_unit(vol, m3).
get_goal_unit(pressure, pascal).
get_goal_unit(freq, hertz).
get_goal_unit(lambda, m).
get_goal_unit(t_period, s).
get_goal_unit(n_amount, mole).
get_goal_unit(r_gas, j_per_mol_k).
get_goal_unit(temp, kelvin).
get_goal_unit(torque, n_m).
get_goal_unit(i_inertia, kg_m2).
get_goal_unit(alpha_rot, rad_per_s2).
get_goal_unit(omega_rot, rad_per_s).
get_goal_unit(l_ang_mom, kg_m2_per_s).
get_goal_unit(ke_rot, joule).
get_goal_unit(q_heat, joule).
get_goal_unit(c_heat, j_per_kg_k).
get_goal_unit(delta_temp, kelvin).





%% ==========================================
%% TEST SUITE
%% ==========================================

run_tests :-
    writeln("=================================================="),
    writeln("RUNNING PHYSICS SOLVER TEST SUITE"),
    writeln("=================================================="),
    
    writeln("\n--- TEST 1: Force Acceleration (Newton's 2nd Law) ---"),
    writeln("Input: '2 kg mass accelerating at 3 mps2 find force'"),
    solve_nl("2 kg mass accelerating at 3 mps2 find force", _),
    
    writeln("\n--- TEST 2: Chained Kinematics & Force ---"),
    writeln("Input: '2 kg starting from rest accelerates to 20 mps in 5 s find force'"),
    solve_nl("2 kg starting from rest accelerates to 20 mps in 5 s find force", _),
    
    writeln("\n--- TEST 3: Electrical Circuits (Ohm's Law & Power) ---"),
    writeln("Input: 'voltage of 12 volt and current of 2 amp find resistance'"),
    solve_nl("voltage of 12 volt and current of 2 amp find resistance", _),
    writeln("Input: 'voltage of 12 volt and current of 2 amp find power'"),
    solve_nl("voltage of 12 volt and current of 2 amp find power", _),
    
    writeln("\n--- TEST 4: Unit Conversion (km/h -> m/s) ---"),
    writeln("Input: 'starts from 36 kmph to 72 kmph in 5 s find acceleration'"),
    solve_nl("starts from 36 kmph to 72 kmph in 5 s find acceleration", _),
    
    writeln("\n--- TEST 5: Potential Energy ---"),
    writeln("Input: 'object of 5 kg mass at height of 10 m find potential energy'"),
    solve_nl("object of 5 kg mass at height of 10 m find potential energy", _),
    
    writeln("\n--- TEST 6: Robust Punctuation & Case-Insensitive Parsing ---"),
    writeln("Input: 'Mass of 2 kg, starting from rest, accelerates to 20 mps in 5 s. Find force.'"),
    solve_nl("Mass of 2 kg, starting from rest, accelerates to 20 mps in 5 s. Find force.", _),

    writeln("\n--- TEST 7: Density Calculation ---"),
    writeln("Input: 'mass of 10 kg and volume of 2 m3 find density'"),
    solve_nl("mass of 10 kg and volume of 2 m3 find density", _),

    writeln("\n--- TEST 8: Hydrostatic Pressure ---"),
    writeln("Input: 'density of 1000 kg_per_m3 at height of 10 m find pressure'"),
    solve_nl("density of 1000 kg_per_m3 at height of 10 m find pressure", _),

    writeln("\n--- TEST 9: Circular Motion (Centripetal Acceleration & Newton's 2nd Law) ---"),
    writeln("Input: 'mass of 2 kg moving at 10 mps with radius of 5 m find force'"),
    solve_nl("mass of 2 kg moving at 10 mps with radius of 5 m find force", _),

    writeln("\n--- TEST 10: Wave Speed ---"),
    writeln("Input: 'frequency of 500 hz and wavelength of 0.6 m find velocity'"),
    solve_nl("frequency of 500 hz and wavelength of 0.6 m find velocity", _),

    writeln("\n--- TEST 11: Wave Period ---"),
    writeln("Input: 'period of 0.02 seconds find frequency'"),
    solve_nl("period of 0.02 seconds find frequency", _),

    writeln("\n--- TEST 12: Ideal Gas Law ---"),
    writeln("Input: 'volume of 0.024 m3 and temperature of 300 kelvin and 1 mol find pressure'"),
    solve_nl("volume of 0.024 m3 and temperature of 300 kelvin and 1 mol find pressure", _),

    writeln("\n--- TEST 13: Torque ---"),
    writeln("Input: 'torque of 10 n_m and inertia of 2 kg_m2 find angular acceleration'"),
    solve_nl("torque of 10 n_m and inertia of 2 kg_m2 find angular acceleration", _),

    writeln("\n--- TEST 14: Rotational Kinetic Energy ---"),
    writeln("Input: 'inertia of 4 kg_m2 moving at 3 rad_per_s find rotational kinetic energy'"),
    solve_nl("inertia of 4 kg_m2 moving at 3 rad_per_s find rotational kinetic energy", _),

    writeln("\n--- TEST 15: Heat Energy ---"),
    writeln("Input: 'mass of 2 kg and specific heat of 4186 j_per_kg_k and temperature difference of 10 k find heat'"),
    solve_nl("mass of 2 kg and specific heat of 4186 j_per_kg_k and temperature difference of 10 k find heat", _),

    writeln("\n=================================================="),
    writeln("TEST SUITE COMPLETE"),
    writeln("==================================================").






