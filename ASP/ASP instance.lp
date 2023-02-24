%----------------------------------------------------------------------------------------------------------------
% This instance takes care of moving the boxes given in input into the goals also given in input
% All constants are given also the input
%----------------------------------------------------------------------------------------------------------------

rows(1..m).
columns(1..n).
number(1..maxNumber).  %number of boxes
dimension(1..maxDim).   %dimension of each box, maximum is maxDim  
time(0..maxTime).   %number of steps, maximum is maxTime
direction(u;d;l;r). 

%INITIAL STATE

% given vertex coordinates of a box, predicate on is true for every "piece" of the box.
on(0,Id,X,Y):-boxCoord(Id,L,X1,Y1),X>=X1,X<X1+L,Y>=Y1,Y<Y1+L,columns(X),rows(Y).    

% vertexPosition is true only for the vertex coordinates in a specific time, i.e. for each box at every step it represents where every vertex is placed on.
vertexPosition(0,Id,X,Y):-boxCoord(Id,L,X,Y).  

% if it activates a cell then it marks it as occupied.
occupiedCell(T,X,Y):-on(T,_,X,Y).

% The problem can't have boxes that "collide"
:- on(T,Id1,X,Y),on(T,Id2,X,Y),Id1!=Id2.

% occupiedRow active indicates that in the cells (Xi,Y) there is AT LEAST one occupied cell.
occupiedRow(T,X,Y,N):-dimension(N),occupiedCell(T,X1,Y),columns(X1),columns(X),rows(Y),X1>=X,X1<X+N,time(T).
% freeRow is true if there is AT LEAST one free cell.
freeRow(T,X,Y,N):-dimension(N),not occupiedCell(T,X1,Y),columns(X1),columns(X),rows(Y),X1>=X,X1<X+N,time(T).
% occupiedColumn active indicates that in the cells (X,Yi) there is AT LEAST one occupied cell. 
occupiedColumn(T,X,Y,N):-dimension(N),occupiedCell(T,X,Y1),rows(Y1),columns(X),rows(Y),Y1>=Y,Y1<Y+N,time(T).
% freeColumn is true if there is AT LEAST one free cell.
freeColumn(T,X,Y,N):-dimension(N),not occupiedCell(T,X,Y1),rows(Y1),columns(X),rows(Y),Y1>=Y,Y1<Y+N,time(T).

% Check if it's possible movement toward direction D => check that it is free FOR EACH cell in front (It is a for each encoded with not exist not) and AT LEAST one cell behind.
pushable(T,Id,u):-vertexPosition(T,Id,X,Y),not occupiedRow(T,X,Y+L,L),boxCoord(Id,L,_,_),rows(Y+L),columns(X),freeRow(T,X,Y-1,L).
pushable(T,Id,d):-vertexPosition(T,Id,X,Y),not occupiedRow(T,X,Y-1,L),boxCoord(Id,L,_,_),rows(Y-1),columns(X),freeRow(T,X,Y+L,L).
pushable(T,Id,l):-vertexPosition(T,Id,X,Y),not occupiedColumn(T,X-1,Y,L),boxCoord(Id,L,_,_),columns(X-1),columns(X),freeColumn(T,X+L,Y,L).
pushable(T,Id,r):-vertexPosition(T,Id,X,Y),not occupiedColumn(T,X+L,Y,L),boxCoord(Id,L,_,_),columns(X+L),columns(X),freeColumn(T,X-1,Y,L).

% if it is pushable, then it moves the box choosing AT THE MOST one of the valid moves (at the most because if it reaches the goal it makes no sense to make other moves).
validMoves(T,Id,D):-vertexPosition(T,Id,X,Y),direction(D),pushable(T,Id,D),rows(Y),columns(X).
0{move(T,Id,D):validMoves(T,Id,D)}1:-time(T),T<maxTime.   %cosi facendo so che non posso avere due move allo stesso istante di tempo.

% if it doesn't move a box, then the box stays in its original position.
on(T+1,Id,X,Y):-on(T,Id,X,Y), not move(T,Id,_),T<maxTime.
vertexPosition(T+1,Id,X,Y):- vertexPosition(T,Id,X,Y), not move(T,Id,_),T<maxTime.

% if it moves a box, it moves both the vertex coordinates and the on's predicate.
on(T+1, Id, XNew, YNew) :-  move(T, Id, D), on(T, Id, XOld, YOld), newCoord(XNew, YNew, XOld, YOld, D),T<maxTime.
vertexPosition(T+1, Id, XNew, YNew) :-  move(T, Id, D), vertexPosition(T, Id, XOld, YOld), newCoord(XNew, YNew, XOld, YOld, D),T<maxTime.

% calcution of new coordinates for each cell being pushed
newCoord(XNew, YNew, XOld, YOld, u) :- XNew = XOld, YNew = YOld +1,columns(XNew),columns(XOld),rows(YNew),rows(YOld).
newCoord(XNew, YNew, XOld, YOld, d) :- XNew = XOld, YNew = YOld -1,columns(XNew),columns(XOld),rows(YNew),rows(YOld).
newCoord(XNew, YNew, XOld, YOld, l) :- XNew = XOld -1, YNew = YOld,columns(XNew),columns(XOld),rows(YNew),rows(YOld).
newCoord(XNew, YNew, XOld, YOld, r) :- XNew = XOld+1, YNew = YOld,columns(XNew),columns(XOld),rows(YNew),rows(YOld).

%GOAL
goal(T,Id) :- vertexPosition(T,Id,X,Y),deposit(Id,X,Y),time(T).
:- goal(T,Id), move(T2,Id,_),time(T2),T2>T,vertexPosition(T,Id,_,_).

%% FINAL STATE
:- not goal(maxTime,Id),vertexPosition(maxTime,Id,_,_).

% used to visualize final vertexes position hiding the timestamp
finalVertex(Id,X,Y):-vertexPosition(maxTime,Id,X,Y).

% minimize number of moves.
requiredMoves(M) :- M = #count{T:move(T,Id,D)}.
#minimize {M:requiredMoves(M)}.

#show move/3.
#show finalVertex/3.
