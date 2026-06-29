p(a).

q(X) :-
  r(X).

s(X,Y) :-
  t(X),
  u(Y).

t(X) :-
  s(X,X).

v(X) :-
  w(X).

x(X) :-
  y(X).

y(X) :-
  z(X).

z(X) :-
  x(X).
