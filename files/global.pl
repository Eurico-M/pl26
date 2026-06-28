:- dynamic lsp/1.
:- dynamic def/6.
:- dynamic use/9.


validate_file(File, Errors) :-
    % atom_string(File, SFile),
    % string_concat("file://",SFile,URI),
    current_source_module(DefaultModule, user),
    absolute_file_name(File, Path, [
        file_type(prolog),
        access(read),
        expand(true),
        file_errors(fail)
    ]),
    validate_source(Path, DefaultModule, Errors).
    % validate_source(Path, Errors).

% validate_source(Path, Errors) :-
%     assert(lsp(on)),
%     load_files(Path, []),
%     retractall(lsp(_)),
%     findall(T, retract(m(T)), Errors).

validate_source(Path, DefaultModule, Errors) :-
    assert(lsp(on)),
    load_files(Path, []),
    retractall(lsp(_)),
    findall(T, retract(m(T)), Errors),
    current_source_module(_, DefaultModule).

validate_text(URI, S, Ts) :-
    string_concat("file://", FileAsS, URI),
    atom_string(File, FileAsS),
    retractall(def(_, _, _, _, File, _)),
    retractall(use(_, _, _, _, _, _, _, File, _)),
    retractall(dec(_, _, _, _, File, _)),
    open(string(S), read, Stream),
    current_source_module(DefaultModule, user),
    assert(lsp(on)),
    load_files(File, [stream(Stream)]),
    % close(Stream),
    current_source_module(_, DefaultModule),
    retractall(lsp(_)),
    findall(T, retract(m(T)), Ts).

test_validate(FilePath, Errors) :-
    open(FilePath, read, In),
    read_codes(In, Codes),
    close(In),
    string_codes(String, Codes),
    validate_text(FilePath, String, Errors).

/**
 * Read the line and store some info.
 */

user:term_expansion(G, GF) :-
    lsp(on),
    prolog_load_context(file, F),
    prolog_load_context(term_position, Pos),
    current_source_module(M, M),
    arg(2, Pos, Line),
    analyse(G, Line, F, M, GF),
    !.

% user:term_expansion(G, GF) :-
%     lsp(on),
%     prolog_load_context(file, F),
%     prolog_load_context(term_position, Pos),
%     current_source_module(M, M),
%     (   source_location(F, Line)
%     ->  true
%     ;   arg(1, Pos, Line)
%     ),
%     analyse(G, Line, F, M, GF),
%     !.

analyse((?- _G), _L, _F, _M, (?- true)) :-
    !.
analyse((:- G), L, F, M, (:- true)) :-
    !,
    directive(G, L, F, M).

% Now let us look for use-defs in rules.
analyse((H :- B), L, F, M, Na) :-
    !,
    rule((H :- B), L, F, M, Na).

% Facts are just defs
analyse(H0, Line, File, MH0, Na) :-
    strip_module(MH0:H0, MH, H),
    functor(H, Na, Ar),
    (   def(Na, Ar, MH, _, _, predicate)
    ->  true
    ;   writeln(user_error, (Na, Ar, MH, Line, File, predicate)),
        assert(def(Na, Ar, MH, Line, File, predicate))
    ).

rule((A0 :- B), Line, File, Module, Na) :-
    strip_module(Module:A0, MH, A),
    functor(A, Na, Ar),
    (   def(Na, Ar, MH, _, _, predicate)
    ->  true
    ;   assert(def(Na, Ar, MH, Line, File, predicate))
    ),
    body(B, Line, File, Module, MH:Na/Ar).

directive(module(M, Ls), L, F, M0) :-
    assert(def('', 0, M, L, F, module)),
    assert(use('', 0, M, '', 0, M0, L, F, module)),
    current_source_module(M0, M),
    maplist(mod(L, F, M), Ls).

directive(op(A, B, C), _Line, _File, M) :-
    op(A, B, M:C).

directive(use_module(_A), _Line, _File, _M) :-
    !.
directive(use_module(_A, _B), _Line, _File, _M) :-
    !.
directive(load_files(_A, _B), _Line, _File, _M) :-
    !.
directive(ensure_loaded(_A), _Line, _File, _M) :-
    !.
directive(consult(_A), _Line, _File, _M) :-
    !.
directive(reconsult(_A), _Line, _File, _M) :-
    !.
directive(compile(_A), _Line, _File, _M) :-
    !.
directive(use_module(_A, _B, _C), _Line, _File, _M) :-
    !.

directive((A, B), Line, File, M) :-
    !,
    directive(A, Line, File, M),
    directive(B, Line, File, M).

% Ignore other directives.
directive(_, _Line, _File, _M).

body(A, _L, _F, _M, _) :-
    var(A),
    !.
body(M:A, L, F, _M, P0) :-
    !,
    body(A, L, F, M, P0).
body((A, B), L, F, M, P0) :-
    !,
    body(A, L, F, M, P0),
    body(B, L, F, M, P0).
body((A; B), L, F, M, P0) :-
    !,
    body(A, L, F, M, P0),
    body(B, L, F, M, P0).
body((A -> B), L, F, M, P0) :-
    !,
    body(A, L, F, M, P0),
    body(B, L, F, M, P0).
body(A, L, F, M, M0:Na0/Ar0) :-
    functor(A, NA, Ar),
    assert(use(NA, Ar, M, Na0, Ar0, M0, L, F, predicate)).



list_calls(L) :-
    findall((Caller/CallerArity, Called/CalledArity: Line),
        use(Called, CalledArity, _, Caller, CallerArity, _, Line, _, _),
    L).

list_by_caller(Caller, L) :-
    findall((Caller/CallerArity, Called/CalledArity: Line),
        use(Called, CalledArity, _, Caller, CallerArity, _, Line, _, _),
    L).

list_by_called(Called, L) :-
    findall((Caller/CallerArity, Called/CalledArity: Line),
        use(Called, CalledArity, _, Caller, CallerArity, _, Line, _, _),
    L).


entry_points(L) :-
    findall(Name/Arity:Line,
        (
            def(Name, Arity, _, Line, _, _),
            \+ use(Name, Arity, _, _, _, _, _, _, _)
        ),
        L).


undefined_calls(L) :-
    findall(Name/Arity:Line,
        (
            use(Name, Arity, _, _, _, _, Line, _, _),
            \+ def(Name, Arity, _, _, _, _)
        ),
        L).


list_by_arity(Arity, L) :-
    findall(Name/Arity: Line, def(Name, Arity, _, Line, _, _), L).




edge(A/Aar, B/Bar) :-
    use(B, Bar, _, A, Aar, _, _, _, _).



% connected(Start/StartArity, End/EndArity) :-
%   use(End, EndArity, _, Start, StartArity, _, _, _, _).

% connected(Start/StartArity, End/EndArity) :-
%   use(Middle, MiddleArity, _, Start, StartArity, _, _, _, _),
%   connected(Middle/MiddleArity, End/EndArity).



% connected(Start/StartArity, End/EndArity, Path) :-
%     connected(Start/StartArity, End/EndArity, Path, [Start/StartArity]).

% connected(Start/StartArity, End/EndArity, [Start/StartArity, End/EndArity], _Visited) :-
%     use(End, EndArity, _, Start, StartArity, _, _, _, _).

% connected(Start/StartArity, End/EndArity, [Start/StartArity|Rest], Visited) :-
%     use(Middle, MiddleArity, _, Start, StartArity, _, _, _, _),
%     \+ member(Middle/MiddleArity, Visited),
%     connected(Middle/MiddleArity, End/EndArity, Rest, [Middle/MiddleArity|Visited]).



connected(Start, End, Path) :-
    connected(Start, End, Path, [Start]).

connected(Start, End, [Start, End], _Visited) :-
    edge(Start, End).

connected(Start, End, [Start|Rest], Visited) :-
    edge(Start, Middle),
    \+ member(Middle, Visited),
    connected(Middle, End, Rest, [Middle|Visited]).



reachable_from(Start, L) :-
    findall(End, connected(Start, End, _), Unsorted),
    sort(Unsorted, L).

reaches(End, L) :-
    findall(Start, connected(Start, End, _), Unsorted),
    sort(Unsorted, L).


% cycles(L) :-
%     findall(Name/Arity, cycle_path(Name/Arity, [], []), L).

% cycle_path(Node, _Visited, RecStack) :-
%     member(Node, RecStack),
%     !.

% cycle_path(Node, Visited, _RecStack) :-
%     member(Node, Visited),
%     !,
%     fail.

% cycle_path(Node, Visited, RecStack) :-
%     edge(Node, Next),
%     cycle_path(Next, [Node|Visited], [Node|RecStack]).

can_cycle(L) :-
    findall(Predicate, cycle(Predicate), L).

cycle(Start) :-
    cycle_path(Start, []).

cycle_path(Curr, Visited) :-
    member(Curr, Visited),
    !.

cycle_path(Curr, Visited) :-
    edge(Curr, Next),
    cycle_path(Next, [Curr|Visited]).




cycles(L) :-
    findall(Predicate, connected(Predicate, Predicate, _), L).




write_dot :-
    open('graph.dot', write, Out),
    writeln(Out, 'digraph Calls {'),

    forall(def(Name, Arity, _, _, _, _),
        format(Out, '  "~w/~w";~n', [Name, Arity])),

    forall(use(Called, CalledArity, _, Caller, CallerArity, _, _, _, _),
        format(Out, '  "~w/~w" -> "~w/~w";~n', [Caller, CallerArity, Called, CalledArity])),

    writeln(Out, '}'),
    close(Out).


% write_dot :-
%     open('graph.dot', write, Out),
%     writeln(Out, 'digraph Calls {'),

%     forall(use(Called, CalledArity, _, Caller, CallerArity, _, Line, _, _),
%         format(Out, '  "~w/~w" -> "~w/~w:~w";~n', [Caller, CallerArity, Called, CalledArity, Line])),

%     writeln(Out, '}'),
%     close(Out).
