#!/usr/bin/env swipl

:- use_module(library(lists)).
:- use_module(library(system)).
:- use_module(library(clpr)).

% Import the core physics solver module
:- use_module('phi.pl').

%% ==========================================
%% CONFIGURATION & CONSTANTS
%% ==========================================
dt(0.12).           % Frame time step for physics calculations
sleep_time(0.08).   % Real-time frame sleep duration

%% ==========================================
%% INITIALIZATION & ENTRY POINT
%% ==========================================
main :-
    menu.

:- initialization(main).

%% ==========================================
%% MAIN MENU IMPLEMENTATION
%% ==========================================
menu :-
    % Complete screen clear and cursor reset
    write("\e[H\e[2J"),
    
    % Print styled ASCII Logo in Cyan
    write("\e[1;36m"),
    writeln("      ██████╗ ██╗  ██╗██╗ "),
    writeln("      ██╔══██╗██║  ██║██║ "),
    writeln("      ██████╔╝███████║██║ "),
    writeln("      ██╔═══╝ ██╔══██║██║ "),
    writeln("      ██║     ██║  ██║██║ "),
    writeln("      ╚═╝     ╚═╝  ╚═╝╚═╝ "),
    write("\e[0m"),
    
    % Subtitle
    write("\e[1;33m"),
    writeln("  φ (phi) - Unified Physics Solver & Animator"),
    write("\e[0m"),
    writeln("  ==========================================="),
    nl,
    writeln("  Select an interactive physics-driven ASCII animation:"),
    nl,
    writeln("    \e[1;32m[1]\e[0m 🏀 Bouncing Ball (Gravity & elastic boundaries)"),
    writeln("    \e[1;32m[2]\e[0m 🚀 Projectile Launcher (Parabolic trajectory & collision)"),
    writeln("    \e[1;32m[3]\e[0m 🪐 Planetary Orbit (Gravitational force solver)"),
    nl,
    writeln("    \e[1;31m[Q]\e[0m Quit Simulator"),
    nl,
    write("  Press a key to select... "),
    flush_output,
    
    get_single_char(Char),
    char_code(Key, Char),
    (Key == '1' ->
        run_animation(bouncing_ball)
    ; Key == '2' ->
        run_animation(projectile)
    ; Key == '3' ->
        run_animation(orbit)
    ; Key == 'q' ->
        write("\e[H\e[2J"), halt
    ; Key == 'Q' ->
        write("\e[H\e[2J"), halt
    ;
        menu
    ).

%% ==========================================
%% ANIMATION RUNNER
%% ==========================================
run_animation(Mode) :-
    init_sim_state(Mode, SimState),
    T = 0.0,
    Paused = false,
    DerivLines = ["Simulation initialized.", "Waiting for first step..."],
    
    write("\e[?25l"), % Hide cursor
    write("\e[H\e[2J"), % Clear screen
    
    setup_call_cleanup(
        shell('stty raw -echo'),
        animate_loop(state(Mode, SimState, T, Paused, DerivLines)),
        (
            shell('stty cooked echo'),
            write("\e[?25h") % Show cursor
        )
    ),
    
    menu.

%% ==========================================
%% ANIMATION LOOP
%% ==========================================
animate_loop(state(Mode, SimState, T, Paused, DerivLines)) :-
    render_frame(Mode, SimState, T, DerivLines, Paused),
    
    check_input(Key),
    handle_key(Key, Mode, SimState, T, Paused, NextMode, NextSimState, NextT, NextPaused, Action),
    
    (Action == quit ->
        true
    ;
        (NextPaused == true ->
            NewSimState = NextSimState,
            NewT = NextT,
            NewDerivLines = DerivLines
        ;
            physics_step(NextMode, NextSimState, NextT, NewSimState, NewT, NewDerivLines)
        ),
        
        sleep_time(S),
        sleep(S),
        animate_loop(state(NextMode, NewSimState, NewT, NextPaused, NewDerivLines))
    ).

%% ==========================================
%% KEYBOARD INPUT HANDLERS
%% ==========================================
check_input(Key) :-
    wait_for_input([user_input], Ready, 0.0),
    (Ready == [user_input] ->
        get_single_char(Code),
        char_code(Key, Code)
    ;
        Key = none
    ).

handle_key('q', _, _, _, _, _, _, _, _, quit) :- !.
handle_key('Q', _, _, _, _, _, _, _, _, quit) :- !.
handle_key(' ', Mode, SimState, T, Paused, Mode, SimState, T, NextPaused, continue) :-
    !,
    (Paused == true -> NextPaused = false ; NextPaused = true).
handle_key('r', Mode, _, _, Paused, Mode, NewSimState, 0.0, Paused, continue) :-
    !,
    init_sim_state(Mode, NewSimState).
handle_key('R', Mode, _, _, Paused, Mode, NewSimState, 0.0, Paused, continue) :-
    !,
    init_sim_state(Mode, NewSimState).
handle_key('\t', Mode, _, _, Paused, NextMode, NewSimState, 0.0, Paused, continue) :-
    !,
    next_mode(Mode, NextMode),
    init_sim_state(NextMode, NewSimState).
handle_key(_, Mode, SimState, T, Paused, Mode, SimState, T, Paused, continue).

next_mode(bouncing_ball, projectile).
next_mode(projectile, orbit).
next_mode(orbit, bouncing_ball).

%% ==========================================
%% SOLVER WRAPPER WITH FAILSAFE
%% ==========================================
safe_solve_nl(Query, Val, Fallback, DerivText) :-
    (catch(with_output_to(string(DerivText), solve_nl(Query, Val)), _, fail) ->
        true
    ;
        Val = Fallback,
        DerivText = "Solver Fallback applied.\nEquation resolution failed."
    ).

safe_solve_nl(Query, Val, Fallback) :-
    safe_solve_nl(Query, Val, Fallback, _).

%% ==========================================
%% SIMULATION PHYSICS STEPS
%% ==========================================

% 1. Bouncing Ball Step
physics_step(bouncing_ball, bouncing_ball(X, Y, Vx, _Vy, PhaseStartT, PhaseU0, PhaseY0, Trail), T,
             bouncing_ball(NextX, NextY, NextVx, NextVy, NextPhaseStartT, NextPhaseU0, NextPhaseY0, NextTrail), NextT, DerivLines) :-
    dt(Dt),
    NextT is T + Dt,
    
    % Update X position with constant horizontal velocity, bouncing off walls
    X_new is X + Vx * Dt,
    (X_new >= 46.0 ->
        NextX = 46.0,
        NextVx is -Vx * 0.95
    ; X_new =< 1.0 ->
        NextX = 1.0,
        NextVx is -Vx * 0.95
    ;
        NextX = X_new,
        NextVx = Vx
    ),
    
    % Elapsed time since the current bounce phase began
    dT_phase is NextT - PhaseStartT,
    
    % Query solver for vertical displacement (height delta)
    format(string(QueryY), "initial velocity of ~f mps acceleration of -9.8 mps2 time of ~f s find displacement", [PhaseU0, dT_phase]),
    safe_solve_nl(QueryY, Sy, 0.0, DerivText),
    
    % Query solver for current vertical velocity
    format(string(QueryVy), "initial velocity of ~f mps acceleration of -9.8 mps2 time of ~f s find velocity", [PhaseU0, dT_phase]),
    safe_solve_nl(QueryVy, Vy_new, 0.0),
    
    Y_calc is PhaseY0 + Sy,
    
    % Handle ground collision
    (Y_calc =< 0.0 ->
        % Reconstruct impact velocity
        Vy_impact is PhaseU0 + (-9.8) * dT_phase,
        U_bounce is -0.80 * Vy_impact,
        
        (U_bounce < 0.6 ->
            % Stop bouncing vertically, just roll
            NextY = 0.0,
            NextVy = 0.0,
            NextPhaseStartT = NextT,
            NextPhaseU0 = 0.0,
            NextPhaseY0 = 0.0
        ;
            % Start a new bounce phase
            NextY = 0.0,
            NextVy = U_bounce,
            NextPhaseStartT = NextT,
            NextPhaseU0 = U_bounce,
            NextPhaseY0 = 0.0
        )
    ;
        NextY = Y_calc,
        NextVy = Vy_new,
        NextPhaseStartT = PhaseStartT,
        NextPhaseU0 = PhaseU0,
        NextPhaseY0 = PhaseY0
    ),
    
    % Update Trail
    append(Trail, [(X, Y)], TempTrail),
    (length(TempTrail, L), L > 6 ->
        TempTrail = [_|NextTrail]
    ;
        NextTrail = TempTrail
    ),
    
    % Format derivation text
    split_string(DerivText, "\n", "", DerivRawLines),
    exclude(==(""), DerivRawLines, DerivLines).

% 2. Projectile Launcher Step
physics_step(projectile, projectile_sim(X, Y, Ux, Uy, T_start, Trail, State, TargetX, TargetY, ExplFrame), T,
             projectile_sim(NextX, NextY, Ux, Uy, NextT_start, NextTrail, NextState, TargetX, TargetY, NextExplFrame), NextT, DerivLines) :-
    dt(Dt),
    NextT is T + Dt,
    
    (State == flying ->
        dT_phase is NextT - T_start,
        
        % Query X displacement via solver
        format(string(QueryX), "initial velocity of ~f mps acceleration of 0 mps2 time of ~f s find displacement", [Ux, dT_phase]),
        safe_solve_nl(QueryX, Sx, 0.0),
        
        % Query Y displacement via solver
        format(string(QueryY), "initial velocity of ~f mps acceleration of -9.8 mps2 time of ~f s find displacement", [Uy, dT_phase]),
        safe_solve_nl(QueryY, Sy, 0.0, DerivText),
        
        X_calc is 2.0 + Sx,
        Y_calc is Sy,
        
        % Check collision with target
        Dist is sqrt((X_calc - TargetX)^2 + (Y_calc - TargetY)^2),
        (Dist =< 1.8 ->
            NextX = X_calc,
            NextY = Y_calc,
            NextState = exploding,
            NextT_start = NextT,
            NextExplFrame = 0,
            NextTrail = Trail
        ; Y_calc =< 0.0, dT_phase > 0.2 ->
            NextX = X_calc,
            NextY = 0.0,
            NextState = landed,
            NextT_start = NextT,
            NextExplFrame = 0,
            NextTrail = Trail
        ;
            NextX = X_calc,
            NextY = Y_calc,
            NextState = flying,
            NextT_start = T_start,
            NextExplFrame = 0,
            append(Trail, [(X_calc, Y_calc)], TempTrail),
            (length(TempTrail, L), L > 12 ->
                TempTrail = [_|NextTrail]
            ;
                NextTrail = TempTrail
            )
        ),
        
        split_string(DerivText, "\n", "", DerivRawLines),
        exclude(==(""), DerivRawLines, DerivLines)
        
    ; State == exploding ->
        NextExplFrame is ExplFrame + 1,
        NextT_start = T_start,
        (NextExplFrame > 6 ->
            % Reset launcher
            NextState = flying,
            NextX = 2.0,
            NextY = 0.0,
            NextT_start = NextT,
            NextTrail = []
        ;
            NextState = exploding,
            NextX = X,
            NextY = Y,
            NextTrail = Trail
        ),
        DerivLines = ["Projectile Exploding!", "Target Hit! Velocity = 0 mps", "Energy dissipated in explosion."]
        
    ; State == landed ->
        NextExplFrame is ExplFrame + 1,
        NextT_start = T_start,
        (NextExplFrame > 6 ->
            % Reset launcher
            NextState = flying,
            NextX = 2.0,
            NextY = 0.0,
            NextT_start = NextT,
            NextTrail = []
        ;
            NextState = landed,
            NextX = X,
            NextY = Y,
            NextTrail = Trail
        ),
        DerivLines = ["Projectile Landed!", "Impacted the ground.", "Waiting for next launch..."]
    ).

% 3. Planetary Orbit Step
physics_step(orbit, orbit_sim(Px, Py, Vx, Vy, Trail, MassStar, MassPlanet), T,
             orbit_sim(NextPx, NextPy, NextVx, NextVy, NextTrail, MassStar, MassPlanet), NextT, DerivLines) :-
    dt(Dt),
    NextT is T + Dt,
    
    dx is Px - 24.0,
    dy is Py - 8.0,
    R is sqrt(dx * dx + dy * dy),
    
    (R < 1.3 ->
        % Collision with central Star! Reset planet
        init_sim_state(orbit, orbit_sim(NextPx, NextPy, NextVx, NextVy, NextTrail, _, _)),
        DerivLines = ["Collision detected!", "Planet fell into the star.", "System Reset!"]
    ;
        % Query gravity solver for force
        format(string(QueryF), "mass1 of 1e13 kg mass2 of 1 kg radius of ~f m find force", [R]),
        safe_solve_nl(QueryF, Force, 0.0, DerivText),
        
        % Query solver for acceleration
        format(string(QueryA), "force of ~f newton mass of 1 kg find acceleration", [Force]),
        safe_solve_nl(QueryA, Acc, 0.0),
        
        % Update velocities (Euler-Cromer integration step)
        Ax is -Acc * dx / R,
        Ay is -Acc * dy / R,
        
        NextVx is Vx + Ax * Dt,
        NextVy is Vy + Ay * Dt,
        
        NextPx is Px + NextVx * Dt,
        NextPy is Py + NextVy * Dt,
        
        append(Trail, [(Px, Py)], TempTrail),
        (length(TempTrail, L), L > 24 ->
            TempTrail = [_|NextTrail]
        ;
            NextTrail = TempTrail
        ),
        
        split_string(DerivText, "\n", "", DerivRawLines),
        exclude(==(""), DerivRawLines, DerivLines)
    ).

%% ==========================================
%% SIMULATION STATE INITIALIZERS
%% ==========================================
init_sim_state(bouncing_ball, bouncing_ball(X, Y, Vx, Vy, PhaseStartT, PhaseU0, PhaseY0, Trail)) :-
    X = 2.0,
    Y = 15.0,
    Vx = 4.0,
    Vy = 0.0,
    PhaseStartT = 0.0,
    PhaseU0 = 0.0,
    PhaseY0 = 15.0,
    Trail = [].

init_sim_state(projectile, projectile_sim(X, Y, Ux, Uy, T_start, Trail, flying, TargetX, TargetY, 0)) :-
    X = 2.0,
    Y = 0.0,
    Ux is 22.0 * cos(55.0 * 3.14159 / 180.0),
    Uy is 22.0 * sin(55.0 * 3.14159 / 180.0),
    T_start = 0.0,
    Trail = [],
    TargetX = 40.0,
    TargetY = 0.5.

init_sim_state(orbit, orbit_sim(Px, Py, Vx, Vy, Trail, 1e13, 1.0)) :-
    Px = 24.0,
    Py = 15.0,
    Vx = -9.76,
    Vy = 0.0,
    Trail = [].

%% ==========================================
%% VIEWPORT ASCII RENDERING ENGINE
%% ==========================================
empty_viewport(Grid) :-
    length(Grid, 17),
    maplist(empty_row, Grid).

empty_row(Row) :-
    length(Row, 48),
    maplist(=(' '), Row).

set_cell(Grid, X, Y, Char, NewGrid) :-
    RowIdx is 16 - round(Y),
    ColIdx is round(X),
    RowIdx >= 0, RowIdx < 17,
    ColIdx >= 0, ColIdx < 48, !,
    nth0(RowIdx, Grid, Row, RestRows),
    nth0(ColIdx, Row, _, RestCols),
    nth0(ColIdx, NewRow, Char, RestCols),
    nth0(RowIdx, NewGrid, NewRow, RestRows).
set_cell(Grid, _, _, _, Grid).

draw_vertical_walls(Grid, NewGrid) :-
    draw_wall_loop(0, 16, Grid, Grid1),
    draw_wall_loop(47, 16, Grid1, NewGrid).

draw_wall_loop(_, -1, Grid, Grid) :- !.
draw_wall_loop(Col, Row, Grid, NewGrid) :-
    Y is Row,
    set_cell(Grid, Col, Y, '║', TempGrid),
    NextRow is Row - 1,
    draw_wall_loop(Col, NextRow, TempGrid, NewGrid).

draw_ground(Grid, NewGrid) :-
    draw_ground_loop(1, 46, Grid, NewGrid).

draw_ground_loop(Col, _Max, Grid, Grid) :-
    set_cell(Grid, Col, 0.0, '═', Grid), !.
draw_ground_loop(Col, Max, Grid, NewGrid) :-
    set_cell(Grid, Col, 0.0, '═', TempGrid),
    NextCol is Col + 1,
    draw_ground_loop(NextCol, Max, TempGrid, NewGrid).

draw_trail([], Grid, Grid).
draw_trail([Pt|Rest], Grid, NewGrid) :-
    length(Rest, Len),
    (Len > 3 -> Char = 'o' ; Char = '.'),
    Pt = (X, Y),
    set_cell(Grid, X, Y, Char, TempGrid),
    draw_trail(Rest, TempGrid, NewGrid).

draw_orbit_trail([], Grid, Grid).
draw_orbit_trail([Pt|Rest], Grid, NewGrid) :-
    Pt = (X, Y),
    set_cell(Grid, X, Y, '·', TempGrid),
    draw_orbit_trail(Rest, TempGrid, NewGrid).

draw_space_background(Grid, NewGrid) :-
    Stars = [
        (4.0, 14.0), (12.0, 3.0), (8.0, 9.0), (18.0, 14.0),
        (32.0, 2.0), (42.0, 13.0), (36.0, 10.0), (28.0, 15.0),
        (3.0, 4.0), (45.0, 4.0)
    ],
    draw_stars_list(Stars, Grid, NewGrid).

draw_stars_list([], Grid, Grid).
draw_stars_list([(X, Y)|Rest], Grid, NewGrid) :-
    set_cell(Grid, X, Y, '.', TempGrid),
    draw_stars_list(Rest, TempGrid, NewGrid).

draw_explosion(TX, TY, Frame, Grid, NewGrid) :-
    TX1 is TX + 1, TX2 is TX - 1, TY1 is TY + 1, TY2 is TY - 1,
    TX3 is TX + 2, TX4 is TX - 2, TY3 is TY + 2, TY4 is TY - 2,
    TX5 is TX + 3, TX6 is TX - 3,
    (Frame =:= 0 ->
        set_cell(Grid, TX, TY, '*', NewGrid)
    ; Frame =:= 1 ->
        set_cell(Grid, TX, TY, '¤', NewGrid)
    ; Frame =:= 2 ->
        set_cell(Grid, TX, TY, '☼', G1),
        set_cell(G1, TX1, TY, '*', G2),
        set_cell(G2, TX2, TY, '*', G3),
        set_cell(G3, TX, TY1, '*', G4),
        set_cell(G4, TX, TY2, '*', NewGrid)
    ; Frame =:= 3 ->
        set_cell(Grid, TX, TY, '@', G1),
        set_cell(G1, TX1, TY1, '\\', G2),
        set_cell(G2, TX2, TY1, '/', G3),
        set_cell(G3, TX1, TY2, '/', G4),
        set_cell(G4, TX2, TY2, '\\', G5),
        set_cell(G5, TX3, TY, '#', G6),
        set_cell(G6, TX4, TY, '#', NewGrid)
    ; Frame =:= 4 ->
        set_cell(Grid, TX, TY, ' ', G1),
        set_cell(G1, TX3, TY3, '.', G2),
        set_cell(G2, TX4, TY3, '.', G3),
        set_cell(G3, TX3, TY4, '.', G4),
        set_cell(G4, TX4, TY4, '.', G5),
        set_cell(G5, TX5, TY, '*', G6),
        set_cell(G6, TX6, TY, '*', NewGrid)
    ;
        NewGrid = Grid
    ).

draw_landed(X, Y, Frame, Grid, NewGrid) :-
    X1 is X + 1, X2 is X - 1, X3 is X + 2, X4 is X - 2,
    (Frame =:= 0 ->
        set_cell(Grid, X, Y, '_', NewGrid)
    ; Frame =:= 1 ->
        set_cell(Grid, X, Y, '_', G1),
        set_cell(G1, X1, Y, '.', G2),
        set_cell(G2, X2, Y, '.', NewGrid)
    ; Frame =:= 2 ->
        set_cell(Grid, X, Y, '.', G1),
        set_cell(G1, X3, Y, '.', G2),
        set_cell(G2, X4, Y, '.', NewGrid)
    ;
        NewGrid = Grid
    ).

render_viewport(bouncing_ball, bouncing_ball(X, Y, _, Vy, _, _, _, Trail), Grid, NewGrid) :-
    empty_viewport(Grid),
    draw_vertical_walls(Grid, Grid1),
    draw_ground(Grid1, Grid2),
    draw_trail(Trail, Grid2, Grid3),
    (Y =< 0.1 ->
        BallChar = '_'
    ; Vy < -3.5 ->
        BallChar = 'v'
    ; Vy > 3.5 ->
        BallChar = '^'
    ;
        BallChar = 'O'
    ),
    set_cell(Grid3, X, Y, BallChar, NewGrid).

render_viewport(projectile, projectile_sim(X, Y, _, _, _, Trail, State, TargetX, TargetY, ExplFrame), Grid, NewGrid) :-
    empty_viewport(Grid),
    draw_ground(Grid, Grid1),
    set_cell(Grid1, 1.0, 0.0, '█', G2),
    set_cell(G2, 2.0, 0.0, '█', G3),
    set_cell(G3, 2.0, 1.0, '◤', G4),
    set_cell(G4, TargetX, TargetY, '◎', G5),
    draw_trail(Trail, G5, G6),
    (State == flying ->
        set_cell(G6, X, Y, '*', NewGrid)
    ; State == exploding ->
        draw_explosion(TargetX, TargetY, ExplFrame, G6, NewGrid)
    ; State == landed ->
        draw_landed(X, Y, ExplFrame, G6, NewGrid)
    ;
        NewGrid = G6
    ).

render_viewport(orbit, orbit_sim(Px, Py, _, _, Trail, _, _), Grid, NewGrid) :-
    empty_viewport(Grid),
    draw_space_background(Grid, Grid1),
    set_cell(Grid1, 24.0, 8.0, '☼', Grid2),
    draw_orbit_trail(Trail, Grid2, Grid3),
    set_cell(Grid3, Px, Py, '●', NewGrid).

%% ==========================================
%% COLORIZED RENDER PIPELINE
%% ==========================================
print_viewport_row_colorized([]).
print_viewport_row_colorized([Char|Rest]) :-
    print_char_colorized(Char),
    print_viewport_row_colorized(Rest).

print_char_colorized(32)   :- !, put_char(' ').
print_char_colorized(79)   :- !, write("\e[1;32mO\e[0m").  % O (ball)
print_char_colorized(118)  :- !, write("\e[1;32mv\e[0m").  % v (ball falling)
print_char_colorized(94)   :- !, write("\e[1;32m^\e[0m").  % ^ (ball rising)
print_char_colorized(95)   :- !, write("\e[1;32m_\e[0m").  % _ (ball squashed)
print_char_colorized(111)  :- !, write("\e[2;32mo\e[0m").  % o (trail ball)
print_char_colorized(46)   :- !, write("\e[2;37m.\e[0m").  % . (trail older)
print_char_colorized(9552) :- !, write("\e[1;33m═\e[0m").  % ═ (ground)
print_char_colorized(9553) :- !, write("\e[2;36m║\e[0m").  % ║ (walls)
print_char_colorized(9608) :- !, write("\e[1;37m█\e[0m").  % █ (cannon)
print_char_colorized(9700) :- !, write("\e[1;37m◤\e[0m").  % ◤ (cannon)
print_char_colorized(42)   :- !, write("\e[1;33m*\e[0m").  % * (projectile)
print_char_colorized(9678) :- !, write("\e[1;31m◎\e[0m").  % ◎ (target)
print_char_colorized(9788) :- !, write("\e[1;33m☼\e[0m").  % ☼ (star)
print_char_colorized(9679) :- !, write("\e[1;36m●\e[0m").  % ● (planet)
print_char_colorized(183)  :- !, write("\e[2;36m·\e[0m").  % · (planet trail)
print_char_colorized(64)   :- !, write("\e[1;31m@\e[0m").  % @ (explosion)
print_char_colorized(35)   :- !, write("\e[1;33m#\e[0m").  % # (explosion)
print_char_colorized(164)  :- !, write("\e[1;31m¤\e[0m").  % ¤ (explosion)
print_char_colorized(Code) :-
    char_code(Char, Code),
    put_char(Char).

print_middle_rows([], []).
print_middle_rows([ViewportRow|ViewportRest], [PanelRow|PanelRest]) :-
    write("\e[2;36m║\e[0m"),
    print_viewport_row_colorized(ViewportRow),
    write("\e[2;36m║\e[0m"),
    write(PanelRow),
    write("\e[2;36m║\e[0m"),
    nl,
    print_middle_rows(ViewportRest, PanelRest).

%% ==========================================
%% TELEMETRY & SIDEBAR PANEL BUILDER
%% ==========================================
format_line(String, Width, Formatted) :-
    format(string(Str), "~w", [String]),
    string_codes(Str, Codes),
    length(Codes, L),
    (L >= Width ->
        length(TruncCodes, Width),
        append(TruncCodes, _, Codes),
        string_codes(Formatted, TruncCodes)
    ;
        Diff is Width - L,
        length(PadCodes, Diff),
        maplist(=(32), PadCodes),
        append(Codes, PadCodes, NewCodes),
        string_codes(Formatted, NewCodes)
    ).

format_line_29(String, Formatted) :-
    format_line(String, 29, Formatted).

take_n(0, _, []) :- !.
take_n(_, [], []) :- !.
take_n(N, [H|T], [H|R]) :-
    N1 is N - 1,
    take_n(N1, T, R).

pad_to_length(Len, _, List, List) :-
    length(List, L),
    L >= Len, !.
pad_to_length(Len, Val, List, Padded) :-
    append(List, [Val], NewList),
    pad_to_length(Len, Val, NewList, Padded).

get_right_panel(bouncing_ball, bouncing_ball(X, Y, Vx, Vy, _, _, _, _), T, DerivLines, PanelLines) :-
    Mass = 2.0,
    Speed is sqrt(Vx * Vx + Vy * Vy),
    PE is Mass * 9.8 * Y,
    KE is 0.5 * Mass * Speed * Speed,
    TE is PE + KE,
    
    L1 = "\e[1;36m  === PHYSICS TELEMETRY ===\e[0m",
    L2 = "  -------------------------",
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Position (X):   \e[32m~2f m\e[0m", [X]),
    format(string(L5), "  Height (Y):     \e[32m~2f m\e[0m", [Y]),
    format(string(L6), "  Velocity (Vx):  \e[32m~2f m/s\e[0m", [Vx]),
    format(string(L7), "  Velocity (Vy):  \e[32m~2f m/s\e[0m", [Vy]),
    format(string(L8), "  Speed (v):      \e[32m~2f m/s\e[0m", [Speed]),
    format(string(L9), "  Kinetic Energy: \e[32m~1f J\e[0m", [KE]),
    format(string(L10), "  Pot. Energy:    \e[32m~1f J\e[0m", [PE]),
    format(string(L11), "  Total Energy:   \e[32m~1f J\e[0m", [TE]),
    L12 = "  -------------------------",
    L13 = "\e[1;36m  === SOLVER DERIVATION ===\e[0m",
    L14 = "  -------------------------",
    
    maplist(format_line_29, [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11, L12, L13, L14], TelemetryLines),
    
    take_n(3, DerivLines, DerivTrunc),
    maplist(format_line_29, DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    pad_to_length(17, "                           ", FullList, PanelLines).

get_right_panel(projectile, projectile_sim(X, Y, Ux, Uy, _, _, State, TargetX, TargetY, _), T, DerivLines, PanelLines) :-
    L1 = "\e[1;36m  === PHYSICS TELEMETRY ===\e[0m",
    L2 = "  -------------------------",
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Position (X):   \e[32m~2f m\e[0m", [X]),
    format(string(L5), "  Height (Y):     \e[32m~2f m\e[0m", [Y]),
    format(string(L6), "  Init Vel (Ux):  \e[32m~2f m/s\e[0m", [Ux]),
    format(string(L7), "  Init Vel (Uy):  \e[32m~2f m/s\e[0m", [Uy]),
    format(string(L8), "  Target (X, Y):  \e[32m(~1f, ~1f)\e[0m", [TargetX, TargetY]),
    format(string(L9), "  State:          \e[33m~w\e[0m", [State]),
    L10 = "  -------------------------",
    L11 = "\e[1;36m  === SOLVER DERIVATION ===\e[0m",
    L12 = "  -------------------------",
    
    maplist(format_line_29, [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11, L12], TelemetryLines),
    
    take_n(5, DerivLines, DerivTrunc),
    maplist(format_line_29, DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    pad_to_length(17, "                           ", FullList, PanelLines).

get_right_panel(orbit, orbit_sim(Px, Py, Vx, Vy, _, MassStar, MassPlanet), T, DerivLines, PanelLines) :-
    dx is Px - 24.0,
    dy is Py - 8.0,
    R is sqrt(dx * dx + dy * dy),
    Speed is sqrt(Vx * Vx + Vy * Vy),
    F is 6.6743e-11 * MassStar * MassPlanet / (R * R),
    
    L1 = "\e[1;36m  === PHYSICS TELEMETRY ===\e[0m",
    L2 = "  -------------------------",
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Planet X:       \e[32m~2f m\e[0m", [Px]),
    format(string(L5), "  Planet Y:       \e[32m~2f m\e[0m", [Py]),
    format(string(L6), "  Velocity (Vx):  \e[32m~2f m/s\e[0m", [Vx]),
    format(string(L7), "  Velocity (Vy):  \e[32m~2f m/s\e[0m", [Vy]),
    format(string(L8), "  Speed (v):      \e[32m~2f m/s\e[0m", [Speed]),
    format(string(L9), "  Orbital Dist R: \e[32m~2f m\e[0m", [R]),
    format(string(L10), "  Grav. Force F:  \e[32m~2f N\e[0m", [F]),
    format(string(L11), "  Star Mass M:    \e[32m~1e kg\e[0m", [MassStar]),
    L12 = "  -------------------------",
    L13 = "\e[1;36m  === SOLVER DERIVATION ===\e[0m",
    L14 = "  -------------------------",
    
    maplist(format_line_29, [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11, L12, L13, L14], TelemetryLines),
    
    take_n(3, DerivLines, DerivTrunc),
    maplist(format_line_29, DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    pad_to_length(17, "                           ", FullList, PanelLines).

%% ==========================================
%% HEADER & FOOTER FORMATTERS
%% ==========================================
title_row_string(Mode, Paused, RowString) :-
    (Paused == true ->
        StatusStr = "\e[1;31mPAUSED\e[0m",
        StatusPlain = "PAUSED"
    ;
        StatusStr = "\e[1;32mRUNNING\e[0m",
        StatusPlain = "RUNNING"
    ),
    format(string(TitleText), " phi Unified Physics Solver - ~w Animation [~w]", [Mode, StatusStr]),
    format(string(Plain), " phi Unified Physics Solver - ~w Animation [~w]", [Mode, StatusPlain]),
    string_codes(Plain, Codes),
    length(Codes, VisLen),
    PadCount is 78 - VisLen,
    length(PadCodes, PadCount),
    maplist(=(32), PadCodes),
    string_codes(PadStr, PadCodes),
    format(string(RowString), "\e[2;36m║\e[0m~w~w\e[2;36m║\e[0m", [TitleText, PadStr]).

get_hint_line(bouncing_ball, "  System: 2.0 kg ball falling under gravity (g=-9.8 mps2) and bouncing off borders.").
get_hint_line(projectile, "  System: Cannon firing projectile at 55 deg, 22.0 mps. Hits trigger explosions!").
get_hint_line(orbit, "  System: Planet orbiting a massive star (M=1e13 kg) using Newton's gravity solver.").

%% ==========================================
%% WINDOW RENDERING ENTRY POINT
%% ==========================================
render_frame(Mode, SimState, T, DerivLines, Paused) :-
    write("\e[H"),
    render_viewport(Mode, SimState, _, ViewportGrid),
    get_right_panel(Mode, SimState, T, DerivLines, PanelLines),
    title_row_string(Mode, Paused, TitleRow),
    
    write("\e[2;36m╔══════════════════════════════════════════════════════════════════════════════╗\e[0m\n"),
    write(TitleRow), write("\n"),
    write("\e[2;36m╠════════════════════════════════════════════════╦═════════════════════════════╣\e[0m\n"),
    
    print_middle_rows(ViewportGrid, PanelLines),
    
    write("\e[2;36m╠════════════════════════════════════════════════╩═════════════════════════════╣\e[0m\n"),
    write("\e[2;37m║  [Space] Pause/Play  |  [Tab] Switch Mode  |  [R] Reset  |  [Q] Exit to Menu         ║\e[0m\n"),
    get_hint_line(Mode, HintText),
    format_line(HintText, 78, F_hint),
    format("\e[2;36m║\e[0m~w\e[2;36m║\e[0m~n", [F_hint]),
    write("\e[2;36m╚══════════════════════════════════════════════════════════════════════════════╝\e[0m\n"),
    flush_output.
