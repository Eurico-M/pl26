p(X) :-
  q(X).

q(X) :-
  r(X),
  t(X).

r(X) :-
  p(X).

s(X) :-
  q(X).

t(X) :-
  s(X).
