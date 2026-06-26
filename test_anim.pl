:- consult('phi_anim.pl').

test_orbit :-
    writeln("Testing Two-Body Orbit Physics Steps..."),
    init_sim_state(orbit, State0),
    writeln(init_state(State0)),
    % Run 5 physics steps
    run_steps(orbit, State0, 0.0, 5, StateN),
    writeln(final_state(StateN)),
    % Verify it didn't collapse or error
    StateN = orbit_sim(Px1, Py1, _, _, Px2, Py2, _, _, _, _, _, _),
    assertion(Px1 \== Px2),
    assertion(Py1 \== Py2),
    writeln("Two-Body Orbit Physics: PASS\n").

test_spinning_top :-
    writeln("Testing Spinning Top Physics Steps..."),
    init_sim_state(spinning_top, State0),
    writeln(init_state(State0)),
    % Run 10 physics steps
    run_steps(spinning_top, State0, 0.0, 10, StateN),
    writeln(final_state(StateN)),
    StateN = spinning_top_sim(_, _, SpinRate, _, TiltAngle, _, _),
    assertion(SpinRate < 25.0),
    assertion(TiltAngle > 0.05),
    writeln("Spinning Top Physics: PASS\n").

test_pendulum :-
    writeln("Testing Damped Pendulum Physics Steps..."),
    init_sim_state(pendulum, State0),
    writeln(init_state(State0)),
    % Run 10 physics steps
    run_steps(pendulum, State0, 0.0, 10, StateN),
    writeln(final_state(StateN)),
    StateN = pendulum_sim(_, _, _, Theta, Omega, _),
    assertion(Theta \== 0.95),
    assertion(Omega \== 0.0),
    writeln("Damped Pendulum Physics: PASS\n").

test_piston :-
    writeln("Testing Piston Physics Steps..."),
    init_sim_state(piston, State0),
    writeln(init_state(State0)),
    % Run 5 physics steps
    run_steps(piston, State0, 0.0, 5, StateN),
    writeln(final_state(StateN)),
    StateN = piston_sim(P, V, T_kelvin, _, _),
    assertion(P \== 62355.0),
    assertion(V \== 0.02),
    assertion(T_kelvin \== 300.0),
    writeln("Piston Physics: PASS\n").

test_rendering :-
    writeln("Testing frame rendering for all modes..."),
    forall(member(Mode, [bouncing_ball, projectile, orbit, spinning_top, pendulum, circuit, piston]), (
        format("Rendering frame for mode: ~w~n", [Mode]),
        init_sim_state(Mode, State),
        render_frame(Mode, State, 0.0, ["Test line 1", "Test line 2"], false),
        nl
    )),
    writeln("Rendering test: PASS\n").

run_steps(_, State, _, 0, State) :- !.
run_steps(Mode, State, T, N, FinalState) :-
    physics_step(Mode, State, T, NextState, NextT, _),
    N1 is N - 1,
    run_steps(Mode, NextState, NextT, N1, FinalState).

:- initialization((
    test_orbit,
    test_spinning_top,
    test_pendulum,
    test_piston,
    test_rendering,
    writeln("All tests completed successfully!"),
    halt(0)
)).
