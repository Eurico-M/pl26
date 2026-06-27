p(a).
p(X) :-
    q(X),
    r(X).
p(X) :-
    u(X).

q(X) :-
    r(X).
q(X) :-
    s(X),
    t(X).

r(a).
r(b).

s(a).
s(b).
s(c).
s(X) :-
    v(X, X, X).

u(d).

v(X, Y, Z) :-
    r(X);
    q(Z).
