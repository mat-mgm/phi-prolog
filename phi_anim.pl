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
    current_prolog_flag(argv, Argv),
    (Argv = [ModeStr|_] ->
        atom_string(Mode, ModeStr),
        (Mode == test ->
            true
        ; member(Mode, [bouncing_ball, projectile, orbit, spinning_top, pendulum, circuit, piston]) ->
            run_animation(Mode)
        ;
            menu
        )
    ;
        menu
    ).

:- initialization(main, main).

%% ==========================================
%% MAIN MENU IMPLEMENTATION
%% ==========================================
write_menu_line(Width, String) :-
    format_line(String, Width, Formatted),
    format("\e[2;36m│\e[0m~w\e[2;36m│\e[0m\r\n", [Formatted]).

write_menu_separator(Width) :-
    make_divider_line(Width, Div),
    format("\e[2;36m├~w┤\e[0m\r\n", [Div]).

menu :-
    % Complete screen clear and cursor reset
    write("\e[H\e[2J"),
    
    (tty_size(_Rows, Cols) -> true ; Cols = 96),
    Width is max(80, Cols - 2),
    
    % Top border
    make_divider_line(Width, TopDiv),
    format("\e[2;36m┌~w┐\e[0m\r\n", [TopDiv]),
    
    % Header
    write_menu_line(Width, "  \e[1;36mphi Unified Physics Solver & Animator - Interactive Main Menu\e[0m"),
    
    % Separator
    write_menu_separator(Width),
    
    % Logo
    write_menu_line(Width, ""),
    write_menu_line(Width, "            \e[1;36m██████╗ ██╗  ██╗██╗\e[0m"),
    write_menu_line(Width, "            \e[1;36m██╔══██╗██║  ██║██║\e[0m"),
    write_menu_line(Width, "            \e[1;36m██████╔╝███████║██║\e[0m"),
    write_menu_line(Width, "            \e[1;36m██╔═══╝ ██╔══██║██║\e[0m"),
    write_menu_line(Width, "            \e[1;36m██║     ██║  ██║██║\e[0m"),
    write_menu_line(Width, "            \e[1;36m╚═╝     ╚═╝  ╚═╝╚═╝\e[0m"),
    write_menu_line(Width, ""),
    
    % Subtitle
    write_menu_line(Width, "  \e[1;33mphi - A multi-domain non-linear constraint physics simulation engine\e[0m"),
    write_menu_line(Width, ""),
    
    % Separator
    write_menu_separator(Width),
    write_menu_line(Width, ""),
    write_menu_line(Width, "  Select an interactive physics-driven ASCII animation:"),
    write_menu_line(Width, ""),
    write_menu_line(Width, "    \e[1;32m[1]\e[0m 🏀 Bouncing Ball (Gravity & elastic boundaries)"),
    write_menu_line(Width, "    \e[1;32m[2]\e[0m 🚀 Projectile Launcher (Parabolic trajectory & collision)"),
    write_menu_line(Width, "    \e[1;32m[3]\e[0m 🪐 Binary Orbital Sim (Two-body gravity solver)"),
    write_menu_line(Width, "    \e[1;32m[4]\e[0m 🌀 Spinning Top (Gyroscopic precession & tilt)"),
    write_menu_line(Width, "    \e[1;32m[5]\e[0m ⛓️ Damped Pendulum (Gravity torque & damping)"),
    write_menu_line(Width, "    \e[1;32m[6]\e[0m ⚡ AC Circuit Solver (Multi-variable electrical loop)"),
    write_menu_line(Width, "    \e[1;32m[7]\e[0m 💨 Ideal Gas Piston (Multi-variable thermodynamic chamber)"),
    write_menu_line(Width, ""),
    write_menu_line(Width, "    \e[1;31m[Q]\e[0m Quit Simulator"),
    write_menu_line(Width, ""),
    
    % Separator
    write_menu_separator(Width),
    write_menu_line(Width, "  Press [1-7] to start animation, or [Q] to quit."),
    format("\e[2;36m└~w┘\e[0m\r\n", [TopDiv]),
    write("  Selection: "),
    flush_output,
    
    get_single_char(Char),
    char_code(Key, Char),
    (Key == '1' ->
        run_animation(bouncing_ball)
    ; Key == '2' ->
        run_animation(projectile)
    ; Key == '3' ->
        run_animation(orbit)
    ; Key == '4' ->
        run_animation(spinning_top)
    ; Key == '5' ->
        run_animation(pendulum)
    ; Key == '6' ->
        run_animation(circuit)
    ; Key == '7' ->
        run_animation(piston)
    ; (Key == 'q' ; Key == 'Q') ->
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

run_animation_direct(Mode) :-
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
    write("\e[H\e[2J"),
    halt.

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
next_mode(orbit, spinning_top).
next_mode(spinning_top, pendulum).
next_mode(pendulum, circuit).
next_mode(circuit, piston).
next_mode(piston, bouncing_ball).

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
    (X_new >= 56.0 ->
        NextX = 56.0,
        NextVx is -Vx * 0.95
    ; X_new =< 1.0 ->
        NextX = 1.0,
        NextVx is -Vx * 0.95
    ;
        NextX = X_new,
        NextVx = Vx
    ),
    
    % Elapsed time since the current bounce phase began
    DT_phase is NextT - PhaseStartT,
    
    % Query solver for vertical displacement (height delta)
    format(string(QueryY), "initial velocity of ~f mps acceleration of -9.8 mps2 time of ~f s find displacement", [PhaseU0, DT_phase]),
    safe_solve_nl(QueryY, Sy, 0.0, DerivText),
    
    % Query solver for current vertical velocity
    format(string(QueryVy), "initial velocity of ~f mps acceleration of -9.8 mps2 time of ~f s find velocity", [PhaseU0, DT_phase]),
    safe_solve_nl(QueryVy, Vy_new, 0.0),
    
    Y_calc is PhaseY0 + Sy,
    
    % Handle ground collision
    (Y_calc =< 0.0 ->
        % Reconstruct impact velocity
        Vy_impact is PhaseU0 + (-9.8) * DT_phase,
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
        DT_phase is NextT - T_start,
        
        % Query X displacement via solver
        format(string(QueryX), "initial velocity of ~f mps acceleration of 0 mps2 time of ~f s find displacement", [Ux, DT_phase]),
        safe_solve_nl(QueryX, Sx, 0.0),
        
        % Query Y displacement via solver
        format(string(QueryY), "initial velocity of ~f mps acceleration of -9.8 mps2 time of ~f s find displacement", [Uy, DT_phase]),
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
        ; Y_calc =< 0.0, DT_phase > 0.2 ->
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
        CurrExplFrame is ExplFrame + 1,
        (CurrExplFrame > 6 ->
            % Reset launcher
            NextState = flying,
            NextX = 2.0,
            NextY = 0.0,
            NextT_start = NextT,
            NextTrail = [],
            NextExplFrame = 0
        ;
            NextState = exploding,
            NextX = X,
            NextY = Y,
            NextT_start = T_start,
            NextTrail = Trail,
            NextExplFrame = CurrExplFrame
        ),
        DerivLines = ["Projectile Exploding!", "Target Hit! Velocity = 0 mps", "Energy dissipated in explosion."]
        
    ; State == landed ->
        CurrExplFrame is ExplFrame + 1,
        (CurrExplFrame > 6 ->
            % Reset launcher
            NextState = flying,
            NextX = 2.0,
            NextY = 0.0,
            NextT_start = NextT,
            NextTrail = [],
            NextExplFrame = 0
        ;
            NextState = landed,
            NextX = X,
            NextY = Y,
            NextT_start = T_start,
            NextTrail = Trail,
            NextExplFrame = CurrExplFrame
        ),
        DerivLines = ["Projectile Landed!", "Impacted the ground.", "Waiting for next launch..."]
    ).

% 3. Binary Orbit Step (Two-Body)
physics_step(orbit, orbit_sim(Px1, Py1, Vx1, Vy1, Px2, Py2, Vx2, Vy2, Trail1, Trail2, M1, M2), T,
             orbit_sim(NextPx1, NextPy1, NextVx1, NextVy1, NextPx2, NextPy2, NextVx2, NextVy2, NextTrail1, NextTrail2, M1, M2), NextT, DerivLines) :-
    dt(Dt),
    NextT is T + Dt,
    
    Dx is Px2 - Px1,
    Dy is Py2 - Py1,
    R is sqrt(Dx * Dx + Dy * Dy),
    
    (R < 1.5 ->
        % Collision! Reset
        init_sim_state(orbit, orbit_sim(NextPx1, NextPy1, NextVx1, NextVy1, NextPx2, NextPy2, NextVx2, NextVy2, NextTrail1, NextTrail2, _, _)),
        DerivLines = ["Collision detected!", "Bodies collided and merged.", "System Reset!"]
    ;
        % Query gravity solver for mutual force
        format(string(QueryF), "mass1 of ~e kg mass2 of ~e kg radius of ~f m find force", [M1, M2, R]),
        safe_solve_nl(QueryF, Force, 0.0, DerivText),
        
        % Query solver for acceleration of body 1
        format(string(QueryA1), "force of ~f newton mass of ~e kg find acceleration", [Force, M1]),
        safe_solve_nl(QueryA1, Acc1, 0.0),
        
        % Query solver for acceleration of body 2
        format(string(QueryA2), "force of ~f newton mass of ~e kg find acceleration", [Force, M2]),
        safe_solve_nl(QueryA2, Acc2, 0.0),
        
        % Directions: body 1 accelerated towards body 2, body 2 accelerated towards body 1
        Ax1 is Acc1 * Dx / R,
        Ay1 is Acc1 * Dy / R,
        Ax2 is -Acc2 * Dx / R,
        Ay2 is -Acc2 * Dy / R,
        
        % Update velocities (Euler-Cromer)
        NextVx1 is Vx1 + Ax1 * Dt,
        NextVy1 is Vy1 + Ay1 * Dt,
        NextVx2 is Vx2 + Ax2 * Dt,
        NextVy2 is Vy2 + Ay2 * Dt,
        
        % Update positions
        NextPx1 is Px1 + NextVx1 * Dt,
        NextPy1 is Py1 + NextVy1 * Dt,
        NextPx2 is Px2 + NextVx2 * Dt,
        NextPy2 is Py2 + NextVy2 * Dt,
        
        % Update trails
        append(Trail1, [(Px1, Py1)], TempTrail1),
        (length(TempTrail1, L1), L1 > 20 -> TempTrail1 = [_|NextTrail1] ; NextTrail1 = TempTrail1),
        append(Trail2, [(Px2, Py2)], TempTrail2),
        (length(TempTrail2, L2), L2 > 20 -> TempTrail2 = [_|NextTrail2] ; NextTrail2 = TempTrail2),
        
        split_string(DerivText, "\n", "", DerivRawLines),
        exclude(==(""), DerivRawLines, DerivLines)
    ).

% 4. Spinning Top Step
physics_step(spinning_top, spinning_top_sim(X0, Y0, SpinRate, PrecessionAngle, TiltAngle, State, CollapseFrame), T,
             spinning_top_sim(X0, Y0, NextSpinRate, NextPrecessionAngle, NextTiltAngle, NextState, NextCollapseFrame), NextT, DerivLines) :-
    dt(Dt),
    NextT is T + Dt,
    (State == collapsed ->
        NextSpinRate = 0.0,
        NextPrecessionAngle = PrecessionAngle,
        NextTiltAngle = TiltAngle,
        NextCollapseFrame is CollapseFrame + 1,
        (NextCollapseFrame > 30 ->
            init_sim_state(spinning_top, spinning_top_sim(X0, Y0, NextSpinRate, NextPrecessionAngle, NextTiltAngle, NextState, NextCollapseFrame))
        ;
            NextState = collapsed
        ),
        DerivLines = ["Top has collapsed!", "Friction stopped rotation.", "System resetting..."]
    ;
        % Query decay of spin velocity
        format(string(QueryDecay), "initial velocity of ~f mps acceleration of -0.8 mps2 time of ~f s find velocity", [SpinRate, Dt]),
        safe_solve_nl(QueryDecay, TempSpinRate, 0.0, DerivText),
        (TempSpinRate < 2.0 ->
            NextSpinRate = 0.0,
            NextPrecessionAngle = PrecessionAngle,
            NextTiltAngle = 1.57,
            NextState = collapsed,
            NextCollapseFrame = 0
        ;
            NextSpinRate = TempSpinRate,
            PrecessionRate is 20.0 * sin(TiltAngle) / NextSpinRate,
            NextPrecessionAngle is PrecessionAngle + PrecessionRate * Dt,
            TiltRate is 0.15 / (NextSpinRate + 0.001),
            NextTiltAngle is TiltAngle + TiltRate * Dt,
            NextState = stable,
            NextCollapseFrame = 0
        ),
        split_string(DerivText, "\n", "", DerivRawLines),
        exclude(==(""), DerivRawLines, DerivLines)
    ).

% 5. Damped Pendulum Step
physics_step(pendulum, pendulum_sim(PivotX, PivotY, Length, Theta, Omega, State), T,
             pendulum_sim(PivotX, PivotY, Length, NextTheta, NextOmega, NextState), NextT, DerivLines) :-
    dt(Dt),
    NextT is T + Dt,
    GAcc = -9.8,
    Force is GAcc * sin(Theta),
    format(string(QueryA), "force of ~f newton mass of 1.0 kg find acceleration", [Force]),
    safe_solve_nl(QueryA, Acc, 0.0, DerivText),
    Alpha is Acc / Length,
    Damping = -0.08,
    DampedOmega is Omega + Damping * Omega * Dt,
    NextOmega is DampedOmega + Alpha * Dt,
    NextTheta is Theta + NextOmega * Dt,
    NextState = State,
    split_string(DerivText, "\n", "", DerivRawLines),
    exclude(==(""), DerivRawLines, DerivLines).

% 6. Circuit Solver Step
physics_step(circuit, circuit_sim(_V, _I, _R, _P, _), T,
             circuit_sim(NextV, NextI, NextR, NextP, NextT), NextT, DerivLines) :-
    dt(Dt),
    NextT is T + Dt,
    % Oscillate voltage: V(t) = 10 * sin(NextT) + 12
    NextV is 10.0 * sin(NextT) + 12.0,
    % Oscillate resistance: R(t) = 4 * cos(0.5 * NextT) + 6
    NextR is 4.0 * cos(0.5 * NextT) + 6.0,
    % Query the multi-variable solver for current and power simultaneously
    format(string(Query), "voltage of ~2f volt and resistance of ~2f ohm find current and power", [NextV, NextR]),
    safe_solve_nl(Query, [NextI, NextP], [0.0, 0.0], DerivText),
    split_string(DerivText, "\n", "", DerivRawLines),
    exclude(==(""), DerivRawLines, DerivLines).

% 7. Ideal Gas Piston Step
physics_step(piston, piston_sim(_P, _V, _T_kelvin, Particles, T), T,
             piston_sim(NextP, NextVol, NextTemp, NextParticles, NextT), NextT, DerivLines) :-
    dt(Dt),
    NextT is T + Dt,
    % Temperature oscillates: T(t) = 300 + 80 * cos(0.5 * t)
    NextTemp is 300.0 + 80.0 * cos(0.5 * NextT),
    % Volume oscillates: V(t) = 0.02 + 0.01 * sin(0.7 * t)
    NextVol is 0.02 + 0.01 * sin(0.7 * NextT),
    % Calculate piston wall position dynamically for boundary check
    PistonX is round(10.0 + NextVol * 1000.0),
    % Query the multi-variable solver for pressure
    format(string(Query), "volume of ~4f m3 and temperature of ~2f kelvin and 0.5 mol find pressure", [NextVol, NextTemp]),
    safe_solve_nl(Query, NextP, 0.0, DerivText),
    % Update particles positions and velocities (bounce boundaries)
    update_particles(Particles, Dt, PistonX, NextParticles),
    split_string(DerivText, "\n", "", DerivRawLines),
    exclude(==(""), DerivRawLines, DerivLines).

update_particles([], _, _, []).
update_particles([p(X, Y, VX, VY)|Rest], Dt, PistonX, [p(NextX, NextY, NextVX, NextVY)|NextRest]) :-
    TX is X + VX * Dt,
    TY is Y + VY * Dt,
    % Bounce X off left wall (5) and piston wall (PistonX)
    (TX < 6.0 ->
        NextX = 6.0, NextVX is -VX
    ; TX > PistonX - 1 ->
        NextX is PistonX - 1.0, NextVX is -VX
    ;
        NextX = TX, NextVX = VX
    ),
    % Bounce Y off top wall (17) and bottom wall (3)
    (TY < 4.0 ->
        NextY = 4.0, NextVY is -VY
    ; TY > 16.0 ->
        NextY = 16.0, NextVY is -VY
    ;
        NextY = TY, NextVY = VY
    ),
    update_particles(Rest, Dt, PistonX, NextRest).


%% ==========================================
%% SIMULATION STATE INITIALIZERS
%% ==========================================
init_sim_state(bouncing_ball, bouncing_ball(X, Y, Vx, Vy, PhaseStartT, PhaseU0, PhaseY0, Trail)) :-
    X = 2.0,
    Y = 18.0,
    Vx = 4.0,
    Vy = 0.0,
    PhaseStartT = 0.0,
    PhaseU0 = 0.0,
    PhaseY0 = 18.0,
    Trail = [].

init_sim_state(projectile, projectile_sim(X, Y, Ux, Uy, T_start, Trail, flying, TargetX, TargetY, 0)) :-
    X = 2.0,
    Y = 0.0,
    Ux is 22.0 * cos(55.0 * 3.14159 / 180.0),
    Uy is 22.0 * sin(55.0 * 3.14159 / 180.0),
    T_start = 0.0,
    Trail = [],
    TargetX = 50.0,
    TargetY = 0.5.

init_sim_state(orbit, orbit_sim(21.0, 10.0, 0.0, -2.5, 37.0, 10.0, 0.0, 2.5, [], [], 3e12, 3e12)) :- !.

init_sim_state(spinning_top, spinning_top_sim(29.0, 1.0, 25.0, 0.0, 0.05, stable, 0)) :- !.

init_sim_state(pendulum, pendulum_sim(29.0, 17.0, 12.0, 0.95, 0.0, stable)) :- !.
init_sim_state(circuit, circuit_sim(12.0, 2.0, 6.0, 24.0, 0.0)) :- !.
init_sim_state(piston, piston_sim(62355.0, 0.02, 300.0, Particles, 0.0)) :-
    Particles = [
        p(10.0, 5.0,  15.0,  8.0),
        p(12.0, 8.0,  -8.0,  12.0),
        p(15.0, 12.0, 10.0, -10.0),
        p(8.0,  14.0, 12.0,  6.0),
        p(14.0, 6.0,  -6.0, -12.0),
        p(18.0, 10.0,  9.0,  11.0),
        p(11.0, 15.0, -11.0,  7.0),
        p(16.0, 4.0,   7.0, -9.0),
        p(7.0,  9.0,  14.0, -8.0),
        p(13.0, 11.0, -12.0, -6.0),
        p(19.0, 7.0,   8.0,  13.0),
        p(9.0,  6.0,  -9.0,  9.0),
        p(17.0, 13.0, -10.0, -8.0),
        p(12.0, 12.0,  11.0,  5.0),
        p(15.0, 15.0,  -7.0, -11.0)
    ], !.

%% ==========================================
%% VIEWPORT ASCII RENDERING ENGINE
%% ==========================================
empty_viewport(Grid) :-
    length(Grid, 20),
    maplist(empty_row, Grid).

empty_row(Row) :-
    length(Row, 58),
    maplist(=(' '), Row).

set_cell(Grid, X, Y, Char, NewGrid) :-
    RowIdx is 19 - round(Y),
    ColIdx is round(X),
    RowIdx >= 0, RowIdx < 20,
    ColIdx >= 0, ColIdx < 58, !,
    nth0(RowIdx, Grid, Row, RestRows),
    nth0(ColIdx, Row, _, RestCols),
    nth0(ColIdx, NewRow, Char, RestCols),
    nth0(RowIdx, NewGrid, NewRow, RestRows).
set_cell(Grid, _, _, _, Grid).

draw_vertical_walls(Grid, NewGrid) :-
    draw_wall_loop(0, 19, Grid, Grid1),
    draw_wall_loop(57, 19, Grid1, NewGrid).

draw_wall_loop(_, -1, Grid, Grid) :- !.
draw_wall_loop(Col, Row, Grid, NewGrid) :-
    Y is Row,
    set_cell(Grid, Col, Y, '║', TempGrid),
    NextRow is Row - 1,
    draw_wall_loop(Col, NextRow, TempGrid, NewGrid).

draw_ground(Grid, NewGrid) :-
    draw_ground_loop(1, 56, Grid, NewGrid).

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
        (4.0, 17.0), (12.0, 3.0), (8.0, 11.0), (18.0, 16.0),
        (32.0, 2.0), (52.0, 15.0), (46.0, 10.0), (28.0, 18.0),
        (3.0, 4.0), (55.0, 5.0), (40.0, 14.0), (50.0, 7.0),
        (22.0, 8.0)
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

render_viewport(orbit, orbit_sim(Px1, Py1, _, _, Px2, Py2, _, _, Trail1, Trail2, _, _), Grid, NewGrid) :-
    empty_viewport(Grid),
    draw_space_background(Grid, Grid1),
    draw_orbit_trail(Trail1, Grid1, Grid2),
    draw_orbit_trail(Trail2, Grid2, Grid3),
    set_cell(Grid3, Px1, Py1, '●', Grid4),
    set_cell(Grid4, Px2, Py2, '●', NewGrid).

render_viewport(spinning_top, spinning_top_sim(X0, Y0, _SpinRate, PrecessionAngle, TiltAngle, State, _), Grid, NewGrid) :-
    empty_viewport(Grid),
    draw_ground(Grid, Grid1),
    (State == collapsed ->
        set_cell(Grid1, X0, Y0, '▲', G2),
        set_cell(G2, X0 - 1.0, Y0, '═', G3),
        set_cell(G3, X0 - 2.0, Y0, '║', G4),
        set_cell(G4, X0 - 3.0, Y0, '║', G5),
        set_cell(G5, X0 + 1.0, Y0, '◄', G6),
        set_cell(G6, X0 + 2.0, Y0, '█', G7),
        set_cell(G7, X0 + 3.0, Y0, '█', G8),
        set_cell(G8, X0 + 4.0, Y0, '█', G9),
        set_cell(G9, X0 + 5.0, Y0, '►', NewGrid)
    ;
        SpinCharIndex is integer(PrecessionAngle * 7) mod 9,
        draw_top_layers(Grid1, 0, X0, Y0, TiltAngle, PrecessionAngle, SpinCharIndex, NewGrid)
    ).

render_viewport(pendulum, pendulum_sim(PivotX, PivotY, Length, Theta, _, _), Grid, NewGrid) :-
    empty_viewport(Grid),
    draw_ceiling(Grid, Grid1),
    draw_pendulum_rod(Grid1, PivotX, PivotY, Length, Theta, Grid2),
    set_cell(Grid2, PivotX, PivotY, '█', Grid3),
    BobX is PivotX + Length * sin(Theta),
    BobY is PivotY - Length * cos(Theta),
    set_cell(Grid3, BobX, BobY, '❂', NewGrid).

render_viewport(circuit, circuit_sim(V, I, R, P, Time), Grid, NewGrid) :-
    empty_viewport(Grid),
    draw_wires(Grid, G1),
    draw_battery(G1, V, G2),
    draw_resistor(G2, R, G3),
    draw_bulb(G3, P, G4),
    draw_electrons(G4, I, Time, NewGrid).

render_viewport(piston, piston_sim(_, Vol, Temp, Particles, _), Grid, NewGrid) :-
    empty_viewport(Grid),
    PistonX is round(10.0 + Vol * 1000.0),
    draw_chamber(Grid, PistonX, G1),
    draw_particles(G1, Particles, Temp, NewGrid).

draw_horizontal_line(Grid, _, XStart, XEnd, _, Grid) :- XStart > XEnd, !.
draw_horizontal_line(Grid, Y, XStart, XEnd, Char, NewGrid) :-
    set_cell(Grid, XStart, Y, Char, G1),
    NextX is XStart + 1,
    draw_horizontal_line(G1, Y, NextX, XEnd, Char, NewGrid).

draw_vertical_line(Grid, _, YStart, YEnd, _, Grid) :- YStart > YEnd, !.
draw_vertical_line(Grid, X, YStart, YEnd, Char, NewGrid) :-
    set_cell(Grid, X, YStart, Char, G1),
    NextY is YStart + 1,
    draw_vertical_line(G1, X, NextY, YEnd, Char, NewGrid).

draw_chamber(Grid, PistonX, NewGrid) :-
    draw_vertical_line(Grid, 5, 4, 16, '│', G1),
    set_cell(G1, 5, 17, '┌', G2),
    set_cell(G2, 5, 3, '└', G3),
    NextX is 6,
    draw_horizontal_line(G3, 17, NextX, PistonX, '─', G4),
    draw_horizontal_line(G4, 3, NextX, PistonX, '─', G5),
    draw_vertical_line(G5, PistonX, 3, 17, '█', G6),
    NextX2 is PistonX + 1,
    (NextX2 =< 52 ->
        draw_horizontal_line(G6, 10, NextX2, 52, '═', G7)
    ;
        G7 = G6
    ),
    set_cell(G7, 53, 11, '┌', G8),
    set_cell(G8, 53, 10, '│', G9),
    set_cell(G9, 53, 9, '└', G10),
    set_cell(G10, 54, 11, '─', G11),
    set_cell(G11, 54, 10, 'H', G12),
    set_cell(G12, 54, 9, '─', G13),
    set_cell(G13, 55, 11, '┐', G14),
    set_cell(G14, 55, 10, '│', G15),
    set_cell(G15, 55, 9, '┘', NewGrid).

draw_particles(Grid, [], _, Grid).
draw_particles(Grid, [p(X, Y, _, _)|Rest], Temp, NewGrid) :-
    (Temp > 320.0 ->
        Char = '*'
    ; Temp < 280.0 ->
        Char = '.'
    ;
        Char = 'o'
    ),
    set_cell(Grid, X, Y, Char, TempGrid),
    draw_particles(TempGrid, Rest, Temp, NewGrid).

draw_wires(Grid, NewGrid) :-
    % corners: single-line borders
    set_cell(Grid, 6, 17, '┌', G1),
    set_cell(G1, 52, 17, '┐', G2),
    set_cell(G2, 6, 2, '└', G3),
    set_cell(G3, 52, 2, '┘', G4),
    % top and bottom horizontal lines
    draw_horiz(G4, 7, 51, 17, G5),
    draw_horiz(G5, 7, 51, 2, G6),
    % left and right vertical lines
    draw_vert(G6, 6, 3, 16, G7),
    draw_vert(G7, 52, 3, 16, NewGrid).

draw_horiz(Grid, Max, Max, Y, NewGrid) :-
    set_cell(Grid, Max, Y, '─', NewGrid), !.
draw_horiz(Grid, X, Max, Y, NewGrid) :-
    set_cell(Grid, X, Y, '─', TempGrid),
    NextX is X + 1,
    draw_horiz(TempGrid, NextX, Max, Y, NewGrid).

draw_vert(Grid, X, Max, Max, NewGrid) :-
    set_cell(Grid, X, Max, '│', NewGrid), !.
draw_vert(Grid, X, Y, Max, NewGrid) :-
    set_cell(Grid, X, Y, '│', TempGrid),
    NextY is Y + 1,
    draw_vert(TempGrid, X, NextY, Max, NewGrid).

draw_battery(Grid, _V, NewGrid) :-
    set_cell(Grid, 5, 12, '[', G1),
    set_cell(G1, 6, 12, '+', G2),
    set_cell(G2, 7, 12, ']', G3),
    set_cell(G3, 6, 11, '│', G4),
    set_cell(G4, 6, 10, 'V', G5),
    set_cell(G5, 6, 9, '│', G6),
    set_cell(G6, 5, 8, '[', G7),
    set_cell(G7, 6, 8, '-', G8),
    set_cell(G8, 7, 8, ']', NewGrid).

draw_resistor(Grid, _R, NewGrid) :-
    set_cell(Grid, 51, 12, '[', G1),
    set_cell(G1, 52, 12, 'R', G2),
    set_cell(G2, 53, 12, ']', G3),
    set_cell(G3, 52, 11, '│', G4),
    set_cell(G4, 52, 10, 'R', G5),
    set_cell(G5, 52, 9, '│', G6),
    set_cell(G6, 51, 8, '[', G7),
    set_cell(G7, 52, 8, '_', G8),
    set_cell(G8, 53, 8, ']', NewGrid).

draw_bulb(Grid, P, NewGrid) :-
    set_cell(Grid, 27, 17, '(', G1),
    set_cell(G1, 28, 17, ' ', G2),
    set_cell(G2, 29, 17, '*', G3),
    set_cell(G3, 30, 17, ' ', G4),
    set_cell(G4, 31, 17, ')', G5),
    (P > 40.0 ->
        set_cell(G5, 29, 18, '│', G6),
        set_cell(G6, 28, 18, '╱', G7),
        set_cell(G7, 30, 18, '╲', G8),
        set_cell(G8, 28, 17, '─', G9),
        set_cell(G9, 30, 17, '─', G10),
        set_cell(G10, 29, 16, '│', G11),
        set_cell(G11, 28, 16, '╲', G12),
        set_cell(G12, 30, 16, '╱', NewGrid)
    ; P > 10.0 ->
        set_cell(G5, 28, 18, '╱', G6),
        set_cell(G6, 30, 18, '╲', G7),
        set_cell(G7, 28, 16, '╲', G8),
        set_cell(G8, 30, 16, '╱', NewGrid)
    ;
        NewGrid = G5
    ).

draw_electrons(Grid, I, T, NewGrid) :-
    circuit_path(Path),
    length(Path, L),
    Pos is round(5.0 * I * T) mod L,
    draw_electron_loop(0, 8, Pos, L, Path, Grid, NewGrid).

draw_electron_loop(8, _, _, _, _, Grid, Grid) :- !.
draw_electron_loop(Idx, Count, Pos, L, Path, Grid, NewGrid) :-
    Offset is (Pos + Idx * 13) mod L,
    nth0(Offset, Path, (X, Y)),
    (is_overlapping(X, Y) ->
        TempGrid = Grid
    ;
        set_cell(Grid, X, Y, 'e', TempGrid)
    ),
    NextIdx is Idx + 1,
    draw_electron_loop(NextIdx, Count, Pos, L, Path, TempGrid, NewGrid).

is_overlapping(X, Y) :- X == 6, Y >= 8, Y =< 12, !.
is_overlapping(X, Y) :- X == 52, Y >= 8, Y =< 12, !.
is_overlapping(X, Y) :- Y == 17, X >= 27, X =< 31, !.

circuit_path(Path) :-
    findall((X, 17), between(6, 52, X), Top),
    findall((52, Y), (between(3, 17, Y_rev), Y is 19 - Y_rev), Right),
    findall((X, 2), (between(6, 51, X_rev), X is 57 - X_rev), Bottom),
    findall((6, Y), between(3, 16, Y), Left),
    append(Top, Right, Temp1),
    append(Temp1, Bottom, Temp2),
    append(Temp2, Left, Path).


draw_top_layers(Grid, 8, _, _, _, _, _, Grid) :- !.
draw_top_layers(Grid, L, X0, Y0, Tilt, Prec, Shift, NewGrid) :-
    draw_top_layer(Grid, L, X0, Y0, Tilt, Prec, Shift, TempGrid),
    L1 is L + 1,
    draw_top_layers(TempGrid, L1, X0, Y0, Tilt, Prec, Shift, NewGrid).

draw_top_layer(Grid, 0, X0, Y0, _, _, _, NewGrid) :-
    set_cell(Grid, X0, Y0, '▲', NewGrid).

draw_top_layer(Grid, 1, X0, Y0, Tilt, Prec, _, NewGrid) :-
    X is X0 + 8.0 * (1/7) * sin(Tilt) * sin(Prec),
    Y is Y0 + 8.0 * (1/7) * cos(Tilt),
    set_cell(Grid, X - 1.0, Y, '\\', G1),
    set_cell(G1, X, Y, '═', G2),
    set_cell(G2, X + 1.0, Y, '/', NewGrid).

draw_top_layer(Grid, 2, X0, Y0, Tilt, Prec, _, NewGrid) :-
    X is X0 + 8.0 * (2/7) * sin(Tilt) * sin(Prec),
    Y is Y0 + 8.0 * (2/7) * cos(Tilt),
    set_cell(Grid, X - 2.0, Y, '\\', G1),
    set_cell(G1, X - 1.0, Y, '═', G2),
    set_cell(G2, X, Y, '═', G3),
    set_cell(G3, X + 1.0, Y, '═', G4),
    set_cell(G4, X + 2.0, Y, '/', NewGrid).

draw_top_layer(Grid, 3, X0, Y0, Tilt, Prec, Shift, NewGrid) :-
    X is X0 + 8.0 * (3/7) * sin(Tilt) * sin(Prec),
    Y is Y0 + 8.0 * (3/7) * cos(Tilt),
    set_cell(Grid, X - 5.0, Y, '(', G1),
    set_cell(G1, X + 5.0, Y, ')', G2),
    S is abs(Shift) mod 9,
    build_disk_chars_9(0, S, Chars),
    draw_disk_row_top(G2, X - 4.0, Y, Chars, NewGrid).

draw_top_layer(Grid, 4, X0, Y0, Tilt, Prec, _, NewGrid) :-
    X is X0 + 8.0 * (4/7) * sin(Tilt) * sin(Prec),
    Y is Y0 + 8.0 * (4/7) * cos(Tilt),
    set_cell(Grid, X - 2.0, Y, '[', G1),
    set_cell(G1, X - 1.0, Y, '═', G2),
    set_cell(G2, X, Y, '═', G3),
    set_cell(G3, X + 1.0, Y, '═', G4),
    set_cell(G4, X + 2.0, Y, ']', NewGrid).

draw_top_layer(Grid, 5, X0, Y0, Tilt, Prec, _, NewGrid) :-
    X is X0 + 8.0 * (5/7) * sin(Tilt) * sin(Prec),
    Y is Y0 + 8.0 * (5/7) * cos(Tilt),
    set_cell(Grid, X - 1.0, Y, '/', G1),
    set_cell(G1, X, Y, '─', G2),
    set_cell(G2, X + 1.0, Y, '\\', NewGrid).

draw_top_layer(Grid, 6, X0, Y0, Tilt, Prec, _, NewGrid) :-
    X is X0 + 8.0 * (6/7) * sin(Tilt) * sin(Prec),
    Y is Y0 + 8.0 * (6/7) * cos(Tilt),
    set_cell(Grid, X, Y, '║', NewGrid).

draw_top_layer(Grid, 7, X0, Y0, Tilt, Prec, _, NewGrid) :-
    X is X0 + 8.0 * (7/7) * sin(Tilt) * sin(Prec),
    Y is Y0 + 8.0 * (7/7) * cos(Tilt),
    set_cell(Grid, X, Y, '║', NewGrid).

build_disk_chars_9(9, _, []) :- !.
build_disk_chars_9(Idx, Shift, [Char|Rest]) :-
    (Idx == Shift -> Char = '★' ; Char = '═'),
    NextIdx is Idx + 1,
    build_disk_chars_9(NextIdx, Shift, Rest).

draw_disk_row_top(Grid, _, _, [], Grid) :- !.
draw_disk_row_top(Grid, X, Y, [C|Rest], NewGrid) :-
    set_cell(Grid, X, Y, C, TempGrid),
    NextX is X + 1.0,
    draw_disk_row_top(TempGrid, NextX, Y, Rest, NewGrid).

draw_ceiling(Grid, NewGrid) :-
    draw_ceiling_loop(1, 46, Grid, NewGrid).

draw_ceiling_loop(Col, _Max, Grid, Grid) :-
    set_cell(Grid, Col, 16.0, '═', Grid), !.
draw_ceiling_loop(Col, Max, Grid, NewGrid) :-
    set_cell(Grid, Col, 16.0, '═', TempGrid),
    NextCol is Col + 1,
    draw_ceiling_loop(NextCol, Max, TempGrid, NewGrid).

draw_pendulum_rod(Grid, _, _, I, _, Grid) :- I =< 0.5, !.
draw_pendulum_rod(Grid, PivotX, PivotY, I, Theta, NewGrid) :-
    X is PivotX + I * sin(Theta),
    Y is PivotY - I * cos(Theta),
    set_cell(Grid, X, Y, '░', TempGrid),
    NextI is I - 0.5,
    draw_pendulum_rod(TempGrid, PivotX, PivotY, NextI, Theta, NewGrid).

%% ==========================================
%% COLORIZED RENDER PIPELINE
%% ==========================================
print_viewport_row_colorized([]).
print_viewport_row_colorized([Char|Rest]) :-
    (integer(Char) -> Code = Char ; char_code(Char, Code)),
    print_char_colorized(Code),
    print_viewport_row_colorized(Rest).

print_char_colorized(32)   :- !, put_char(' ').
print_char_colorized(79)   :- !, write("\e[1;32mO\e[0m").  % O (ball)
print_char_colorized(118)  :- !, write("\e[1;32mv\e[0m").  % v (ball falling)
print_char_colorized(94)   :- !, write("\e[1;32m^\e[0m").  % ^ (ball rising)
print_char_colorized(95)   :- !, write("\e[1;32m_\e[0m").  % _ (ball squashed)
print_char_colorized(111)  :- !, write("\e[2;32mo\e[0m").  % o (trail ball)
print_char_colorized(46)   :- !, write("\e[2;37m.\e[0m").  % . (trail older)
print_char_colorized(9552) :- !, write("\e[1;33m═\e[0m").  % ═ (ground/ceiling)
print_char_colorized(9553) :- !, write("\e[2;36m║\e[0m").  % ║ (walls)
print_char_colorized(9608) :- !, write("\e[1;37m█\e[0m").  % █ (cannon/pivot)
print_char_colorized(9700) :- !, write("\e[1;37m◤\e[0m").  % ◤ (cannon)
print_char_colorized(42)   :- !, write("\e[1;33m*\e[0m").  % * (projectile)
print_char_colorized(9678) :- !, write("\e[1;31m◎\e[0m").  % ◎ (target)
print_char_colorized(9788) :- !, write("\e[1;33m☼\e[0m").  % ☼ (star)
print_char_colorized(9679) :- !, write("\e[1;36m●\e[0m").  % ● (planet/body)
print_char_colorized(183)  :- !, write("\e[2;36m·\e[0m").  % · (trail)
print_char_colorized(64)   :- !, write("\e[1;31m@\e[0m").  % @ (explosion)
print_char_colorized(35)   :- !, write("\e[1;33m#\e[0m").  % # (explosion)
print_char_colorized(9650) :- !, write("\e[1;33m▲\e[0m").  % ▲ (spinning top spindle)
print_char_colorized(9664) :- !, write("\e[1;33m◄\e[0m").  % ◄ (collapsed top body)
print_char_colorized(9654) :- !, write("\e[1;33m►\e[0m").  % ► (collapsed top body)
print_char_colorized(9733) :- !, write("\e[1;35m★\e[0m").  % ★ (precession indicator)
print_char_colorized(9472) :- !, write("\e[1;33m─\e[0m").  % ─ (spinning top disk)
print_char_colorized(9738) :- !, write("\e[1;31m❂\e[0m").  % ❂ (pendulum bob)
print_char_colorized(9617) :- !, write("\e[2;37m░\e[0m").  % ░ (pendulum rod)
print_char_colorized(164)  :- !, write("\e[1;31m¤\e[0m").  % ¤ (explosion)
print_char_colorized(101)  :- !, write("\e[1;36me\e[0m").  % e (electron)
print_char_colorized(9474) :- !, write("\e[2;36m│\e[0m").  % │ (wire/resistor/battery)
print_char_colorized(9484) :- !, write("\e[2;36m┌\e[0m").  % ┌ (corner)
print_char_colorized(9488) :- !, write("\e[2;36m┐\e[0m").  % ┐ (corner)
print_char_colorized(9492) :- !, write("\e[2;36m└\e[0m").  % └ (corner)
print_char_colorized(9496) :- !, write("\e[2;36m┘\e[0m").  % ┘ (corner)
print_char_colorized(9585) :- !, write("\e[1;33m╱\e[0m").  % ╱ (bulb ray)
print_char_colorized(9586) :- !, write("\e[1;33m╲\e[0m").  % ╲ (bulb ray)
print_char_colorized(Code) :-
    char_code(Char, Code),
    put_char(Char).

print_middle_rows([], [], _).
print_middle_rows([ViewportRow|ViewportRest], [PanelRow|PanelRest], Width) :-
    (sub_string(PanelRow, _, _, _, "──") ->
        write("\e[2;36m│\e[0m"),
        print_viewport_row_colorized(ViewportRow),
        make_divider_line(Width, Div),
        format("\e[2;36m├~w┤\e[0m", [Div]),
        write("\r\n")
    ;
        write("\e[2;36m│\e[0m"),
        print_viewport_row_colorized(ViewportRow),
        write("\e[2;36m│\e[0m"),
        write(PanelRow),
        write("\e[2;36m│\e[0m"),
        write("\r\n")
    ),
    print_middle_rows(ViewportRest, PanelRest, Width).

%% ==========================================
%% TELEMETRY & SIDEBAR PANEL BUILDER
%% ==========================================
visible_length(String, Len) :-
    string_codes(String, Codes),
    codes_visible_length(Codes, 0, Len).

codes_visible_length([], Acc, Acc).
codes_visible_length([27|Rest], Acc, Len) :- !,
    skip_escape(Rest, NextRest),
    codes_visible_length(NextRest, Acc, Len).
codes_visible_length([Code|Rest], Acc, Len) :-
    char_width(Code, W),
    Acc1 is Acc + W,
    codes_visible_length(Rest, Acc1, Len).

skip_escape([], []) :- !.
skip_escape([109|Rest], Rest) :- !.
skip_escape([_|Rest], Out) :-
    skip_escape(Rest, Out).

format_line(String, Width, Formatted) :-
    format(string(Str), "~w", [String]),
    visible_length(Str, L),
    (L > Width ->
        truncate_visible(Str, Width, TruncStr),
        string_concat(TruncStr, "\e[0m", Formatted)
    ; L == Width ->
        Formatted = Str
    ;
        Diff is Width - L,
        length(PadCodes, Diff),
        maplist(=(32), PadCodes),
        string_codes(PadStr, PadCodes),
        string_concat(Str, PadStr, Formatted)
    ).

truncate_visible(String, Width, Truncated) :-
    string_codes(String, Codes),
    truncate_codes_visible(Codes, Width, TruncCodes),
    string_codes(Truncated, TruncCodes).

truncate_codes_visible([], _, []).
truncate_codes_visible(_, 0, []) :- !.
truncate_codes_visible([27|Rest], Width, [27|TruncRest]) :- !,
    copy_escape(Rest, EscPart, NextRest),
    append(EscPart, TempRest, TruncRest),
    truncate_codes_visible(NextRest, Width, TempRest).
truncate_codes_visible([Code|Rest], Width, [Code|TruncRest]) :-
    char_width(Code, W),
    Width1 is Width - W,
    (Width1 >= 0 ->
        truncate_codes_visible(Rest, Width1, TruncRest)
    ;
        TruncRest = []
    ).

char_width(Code, 0) :-
    (Code == 65039 ; Code == 65038 ; Code == 127 ; Code < 32), !.
char_width(Code, 2) :-
    ( Code >= 127744, Code =< 129791 ; % Emojis
      Code == 9889 ;                   % ⚡
      Code == 9939                     % ⛓
    ), !.
char_width(_, 1).

copy_escape([], [], []) :- !.
copy_escape([109|Rest], [109], Rest) :- !.
copy_escape([Code|Rest], [Code|EscRest], OutRest) :-
    copy_escape(Rest, EscRest, OutRest).

make_divider_line(Width, Divider) :-
    length(Codes, Width),
    maplist(=(9472), Codes), % 9472 is '─'
    string_codes(Divider, Codes).

make_padding_string(Width, Padding) :-
    length(Codes, Width),
    maplist(=(32), Codes),  % 32 is ' '
    string_codes(Padding, Codes).

format_line_width(Width, String, Formatted) :-
    format_line(String, Width, Formatted).

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

get_right_panel(bouncing_ball, bouncing_ball(X, Y, Vx, Vy, _, _, _, _), T, DerivLines, Width, PanelLines) :-
    Mass = 2.0,
    Speed is sqrt(Vx * Vx + Vy * Vy),
    PE is Mass * 9.8 * Y,
    KE is 0.5 * Mass * Speed * Speed,
    TE is PE + KE,
    
    L1 = "\e[1;36m  PHYSICS TELEMETRY\e[0m",
    make_divider_line(Width, L2),
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Position (X):   \e[32m~2f m\e[0m", [X]),
    format(string(L5), "  Height (Y):     \e[32m~2f m\e[0m", [Y]),
    format(string(L6), "  Velocity (Vx):  \e[32m~2f m/s\e[0m", [Vx]),
    format(string(L7), "  Velocity (Vy):  \e[32m~2f m/s\e[0m", [Vy]),
    format(string(L8), "  Speed (v):      \e[32m~2f m/s\e[0m", [Speed]),
    format(string(L9), "  Kinetic Energy: \e[32m~1f J\e[0m", [KE]),
    format(string(L10), "  Pot. Energy:    \e[32m~1f J\e[0m", [PE]),
    format(string(L11), "  Total Energy:   \e[32m~1f J\e[0m", [TE]),
    L12 = L2,
    L13 = "\e[1;36m  SOLVER DERIVATION\e[0m",
    L14 = L2,
    
    maplist(format_line_width(Width), [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11, L12, L13, L14], TelemetryLines),
    
    take_n(3, DerivLines, DerivTrunc),
    maplist(format_line_width(Width), DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    make_padding_string(Width, PadStr),
    pad_to_length(20, PadStr, FullList, PanelLines).

get_right_panel(projectile, projectile_sim(X, Y, Ux, Uy, _, _, State, TargetX, TargetY, _), T, DerivLines, Width, PanelLines) :-
    L1 = "\e[1;36m  PHYSICS TELEMETRY\e[0m",
    make_divider_line(Width, L2),
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Position (X):   \e[32m~2f m\e[0m", [X]),
    format(string(L5), "  Height (Y):     \e[32m~2f m\e[0m", [Y]),
    format(string(L6), "  Init Vel (Ux):  \e[32m~2f m/s\e[0m", [Ux]),
    format(string(L7), "  Init Vel (Uy):  \e[32m~2f m/s\e[0m", [Uy]),
    format(string(L8), "  Target (X, Y):  \e[32m(~1f, ~1f)\e[0m", [TargetX, TargetY]),
    format(string(L9), "  State:          \e[33m~w\e[0m", [State]),
    L10 = L2,
    L11 = "\e[1;36m  SOLVER DERIVATION\e[0m",
    L12 = L2,
    
    maplist(format_line_width(Width), [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11, L12], TelemetryLines),
    
    take_n(5, DerivLines, DerivTrunc),
    maplist(format_line_width(Width), DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    make_padding_string(Width, PadStr),
    pad_to_length(20, PadStr, FullList, PanelLines).

get_right_panel(orbit, orbit_sim(Px1, Py1, Vx1, Vy1, Px2, Py2, Vx2, Vy2, _, _, M1, M2), T, DerivLines, Width, PanelLines) :-
    Dx is Px2 - Px1,
    Dy is Py2 - Py1,
    R is sqrt(Dx * Dx + Dy * Dy),
    Speed1 is sqrt(Vx1 * Vx1 + Vy1 * Vy1),
    Speed2 is sqrt(Vx2 * Vx2 + Vy2 * Vy2),
    F is 6.6743e-11 * M1 * M2 / (R * R),
    
    L1 = "\e[1;36m  PHYSICS TELEMETRY\e[0m",
    make_divider_line(Width, L2),
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Body 1:         \e[32m(~1f,~1f)\e[0m", [Px1, Py1]),
    format(string(L5), "  Body 2:         \e[32m(~1f,~1f)\e[0m", [Px2, Py2]),
    format(string(L6), "  Speed 1:        \e[32m~2f m/s\e[0m", [Speed1]),
    format(string(L7), "  Speed 2:        \e[32m~2f m/s\e[0m", [Speed2]),
    format(string(L8), "  Mutual Dist R:  \e[32m~2f m\e[0m", [R]),
    format(string(L9), "  Grav. Force F:  \e[32m~2e N\e[0m", [F]),
    format(string(L10), "  Mass 1:         \e[32m~1e kg\e[0m", [M1]),
    format(string(L11), "  Mass 2:         \e[32m~1e kg\e[0m", [M2]),
    L12 = L2,
    L13 = "\e[1;36m  SOLVER DERIVATION\e[0m",
    L14 = L2,
    
    maplist(format_line_width(Width), [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11, L12, L13, L14], TelemetryLines),
    
    take_n(3, DerivLines, DerivTrunc),
    maplist(format_line_width(Width), DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    make_padding_string(Width, PadStr),
    pad_to_length(20, PadStr, FullList, PanelLines).

get_right_panel(spinning_top, spinning_top_sim(_, _, SpinRate, PrecAngle, TiltAngle, State, _), T, DerivLines, Width, PanelLines) :-
    L1 = "\e[1;36m  PHYSICS TELEMETRY\e[0m",
    make_divider_line(Width, L2),
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Spin Rate (ws): \e[32m~2f r/s\e[0m", [SpinRate]),
    format(string(L5), "  Prec Angle (p): \e[32m~2f rad\e[0m", [PrecAngle]),
    format(string(L6), "  Tilt Angle (th):\e[32m~2f rad\e[0m", [TiltAngle]),
    format(string(L7), "  State:          \e[33m~w\e[0m", [State]),
    L8 = L2,
    L9 = "\e[1;36m  SOLVER DERIVATION\e[0m",
    L10 = L2,
    
    maplist(format_line_width(Width), [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10], TelemetryLines),
    
    take_n(7, DerivLines, DerivTrunc),
    maplist(format_line_width(Width), DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    make_padding_string(Width, PadStr),
    pad_to_length(20, PadStr, FullList, PanelLines).

get_right_panel(pendulum, pendulum_sim(_, _, Length, Theta, Omega, State), T, DerivLines, Width, PanelLines) :-
    Vel is Omega * Length,
    AccTang is -9.8 * sin(Theta),
    PE is 1.0 * 9.8 * Length * (1.0 - cos(Theta)),
    KE is 0.5 * 1.0 * Vel * Vel,
    TE is PE + KE,
    
    L1 = "\e[1;36m  PHYSICS TELEMETRY\e[0m",
    make_divider_line(Width, L2),
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Angle (theta):  \e[32m~2f rad\e[0m", [Theta]),
    format(string(L5), "  Ang Vel (w):    \e[32m~2f r/s\e[0m", [Omega]),
    format(string(L6), "  Tang Acc (at):  \e[32m~2f m/s2\e[0m", [AccTang]),
    format(string(L7), "  PE (Energy):    \e[32m~1f J\e[0m", [PE]),
    format(string(L8), "  KE (Energy):    \e[32m~1f J\e[0m", [KE]),
    format(string(L9), "  TE (Energy):    \e[32m~1f J\e[0m", [TE]),
    format(string(L10), "  State:          \e[33m~w\e[0m", [State]),
    L11 = L2,
    L12 = "\e[1;36m  SOLVER DERIVATION\e[0m",
    L13 = L2,
    
    maplist(format_line_width(Width), [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11, L12, L13], TelemetryLines),
    
    take_n(4, DerivLines, DerivTrunc),
    maplist(format_line_width(Width), DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    make_padding_string(Width, PadStr),
    pad_to_length(20, PadStr, FullList, PanelLines).

get_right_panel(circuit, circuit_sim(V, I, R, P, _), T, DerivLines, Width, PanelLines) :-
    L1 = "\e[1;36m  PHYSICS TELEMETRY\e[0m",
    make_divider_line(Width, L2),
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Voltage (V):    \e[32m~2f V\e[0m", [V]),
    format(string(L5), "  Resistance (R): \e[32m~2f ohm\e[0m", [R]),
    format(string(L6), "  Current (I):    \e[32m~2f A\e[0m", [I]),
    format(string(L7), "  Power (P):      \e[32m~2f W\e[0m", [P]),
    L8 = L2,
    L9 = "\e[1;36m  SOLVER DERIVATION\e[0m",
    L10 = L2,
    
    maplist(format_line_width(Width), [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10], TelemetryLines),
    
    take_n(7, DerivLines, DerivTrunc),
    maplist(format_line_width(Width), DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    make_padding_string(Width, PadStr),
    pad_to_length(20, PadStr, FullList, PanelLines).

get_right_panel(piston, piston_sim(P, V, T_kelvin, _, _), T, DerivLines, Width, PanelLines) :-
    L1 = "\e[1;36m  PHYSICS TELEMETRY\e[0m",
    make_divider_line(Width, L2),
    format(string(L3), "  Sim Time (t):   \e[32m~2f s\e[0m", [T]),
    format(string(L4), "  Temperature (T):\e[32m~2f K\e[0m", [T_kelvin]),
    format(string(L5), "  Volume (V):     \e[32m~4f m3\e[0m", [V]),
    format(string(L6), "  Pressure (P):   \e[32m~1f Pa\e[0m", [P]),
    L7 = "  Gas Const (R):  \e[32m8.314 J/K\e[0m",
    L8 = "  Moles (n):      \e[32m0.50 mol\e[0m",
    L9 = L2,
    L10 = "\e[1;36m  SOLVER DERIVATION\e[0m",
    L11 = L2,
    
    maplist(format_line_width(Width), [L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11], TelemetryLines),
    
    take_n(6, DerivLines, DerivTrunc),
    maplist(format_line_width(Width), DerivTrunc, DerivPadded),
    
    append(TelemetryLines, DerivPadded, FullList),
    make_padding_string(Width, PadStr),
    pad_to_length(20, PadStr, FullList, PanelLines).


%% ==========================================
%% HEADER & FOOTER FORMATTERS
%% ==========================================
title_row_string(Mode, Paused, TotalInnerWidth, RowString) :-
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
    PadCount is TotalInnerWidth - VisLen,
    length(PadCodes, PadCount),
    maplist(=(32), PadCodes),
    string_codes(PadStr, PadCodes),
    format(string(RowString), "\e[2;36m│\e[0m~w~w\e[2;36m│\e[0m", [TitleText, PadStr]).

get_hint_line(bouncing_ball, "  System: 2.0 kg ball falling under gravity (g=-9.8 mps2) and bouncing off borders.").
get_hint_line(projectile, "  System: Cannon firing projectile at 55 deg, 22.0 mps. Hits trigger explosions!").
get_hint_line(orbit, "  System: Two massive bodies orbiting each other via gravitational attraction solver.").
get_hint_line(spinning_top, "  System: Spinning top undergoing gyroscopic precession and tilt decay due to friction.").
get_hint_line(pendulum, "  System: Damped simple pendulum swinging under gravity torque with air resistance.").
get_hint_line(circuit, "  System: AC circuit loop with moving electrons and dynamically solved I & P.").
get_hint_line(piston, "  System: Piston chamber. Temperature & Volume oscillate; CLP(R) solves Pressure P.").

%% ==========================================
%% WINDOW RENDERING ENTRY POINT
%% ==========================================
render_frame(Mode, SimState, T, DerivLines, Paused) :-
    write("\e[H"),
    (tty_size(_Rows, Cols) -> true ; Cols = 96),
    TotalInnerWidth is max(80, Cols - 2),
    RightPanelWidth is TotalInnerWidth - 59,
    
    render_viewport(Mode, SimState, _, ViewportGrid),
    get_right_panel(Mode, SimState, T, DerivLines, RightPanelWidth, PanelLines),
    title_row_string(Mode, Paused, TotalInnerWidth, TitleRow),
    
    make_divider_line(TotalInnerWidth, TopDiv),
    format("\e[2;36m┌~w┐\e[0m\r\n", [TopDiv]),
    write(TitleRow), write("\r\n"),
    
    make_divider_line(58, LeftDiv),
    make_divider_line(RightPanelWidth, RightDiv),
    format("\e[2;36m├~w┬~w┤\e[0m\r\n", [LeftDiv, RightDiv]),
    
    print_middle_rows(ViewportGrid, PanelLines, RightPanelWidth),
    
    format("\e[2;36m├~w┴~w┤\e[0m\r\n", [LeftDiv, RightDiv]),
    
    format_line("  [Space] Pause/Play  |  [Tab] Switch Mode  |  [R] Reset  |  [Q] Exit to Menu", TotalInnerWidth, F_controls),
    format("\e[2;36m│\e[0m~w\e[2;36m│\e[0m\r\n", [F_controls]),
    get_hint_line(Mode, HintText),
    format_line(HintText, TotalInnerWidth, F_hint),
    format("\e[2;36m│\e[0m~w\e[2;36m│\e[0m\r\n", [F_hint]),
    format("\e[2;36m└~w┘\e[0m\r\n", [TopDiv]),
    flush_output.
