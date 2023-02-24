rows(1..m).
columns(1..n).
number(1..maxNumber).  %numero di pacchi, il massimo è maxNumber
dimension(1..maxDim).   %dimensione dei pacchi, la massima è maxDim  
direction(u;d;l;r). 
time(0..maxTime).   %numero di passi, il massimo è maxTime 

%boxCoord(Id,Lunghezza,X,Y) dove (X,Y) sono le posizioni del vertice in basso
boxCoord(1,2,2,4).
boxCoord(2,2,3,2).
%boxCoord(3,1,4,2).
%boxCoord(4,1,5,2).
%boxCoord(3,1,4,5).

deposit(1,1,1). %deposita il box 1 in basso a sx
deposit(2,4,5).
%deposit(3,3,1).
%deposit(4,5,4).

%STATO INIZIALE, posiziono con on le celle
on(0,Id,X,Y):-boxCoord(Id,L,X1,Y1),X>=X1,X<X1+L,Y>=Y1,Y<Y1+L,columns(X),rows(Y).
vertexPosition(0,Id,X,Y):-boxCoord(Id,L,X,Y).

occupiedCell(T,X,Y):-on(T,_,X,Y).

% Non posso avere box che si "collidono"
:- on(T,Id1,X,Y),on(T,Id2,X,Y),Id1!=Id2.

%occupiedRow attivo indica che nelle celle (Xi,Y) c'e' ALMENO una cella occupata poi quando lo richiamo metto che N deve essere uguale alla lunghezza L. 
occupiedRow(T,X,Y,N):-dimension(N),occupiedCell(T,X1,Y),columns(X1),columns(X),rows(Y),X1>=X,X1<X+N,time(T).
%freeRow attivo dice che c'e' ALMENO una cella libera 
freeRow(T,X,Y,N):-dimension(N),not occupiedCell(T,X1,Y),columns(X1),columns(X),rows(Y),X1>=X,X1<X+N,time(T).
%occupiedColumn attivo indica che nelle celle (X,Yi) c'e' ALMENO una cella occupata poi quando lo richiamo metto che N deve essere uguale alla lunghezza L. 
occupiedColumn(T,X,Y,N):-dimension(N),occupiedCell(T,X,Y1),rows(Y1),columns(X),rows(Y),Y1>=Y,Y1<Y+N,time(T).
%freeColumn attivo dice che c'e' ALMENO una cella libera
freeColumn(T,X,Y,N):-dimension(N),not occupiedCell(T,X,Y1),rows(Y1),columns(X),rows(Y),Y1>=Y,Y1<Y+N,time(T).

%controllo se posso muovere all'istante T il blocco Id in direzione ... => controlla che sia libero PER OGNI cella davanti (Sarebbe un for each codificato con not exist not) e ALMENO una cella dietro
pushable(T,Id,u):-vertexPosition(T,Id,X,Y),not occupiedRow(T,X,Y+L,L),boxCoord(Id,L,_,_),rows(Y+L),columns(X),freeRow(T,X,Y-1,L).
pushable(T,Id,d):-vertexPosition(T,Id,X,Y),not occupiedRow(T,X,Y-1,L),boxCoord(Id,L,_,_),rows(Y-1),columns(X),freeRow(T,X,Y+L,L).
pushable(T,Id,l):-vertexPosition(T,Id,X,Y),not occupiedColumn(T,X-1,Y,L),boxCoord(Id,L,_,_),columns(X-1),columns(X),freeColumn(T,X+L,Y,L).
pushable(T,Id,r):-vertexPosition(T,Id,X,Y),not occupiedColumn(T,X+L,Y,L),boxCoord(Id,L,_,_),columns(X+L),columns(X),freeColumn(T,X-1,Y,L).

%se è pushabile, allora muovo la scatola scegliendo AL MASSIMO una tra le mosse valide (al massimo perche se arriva al goal non ha senso che faccia altre mosse)
validMoves(T,Id,D):-vertexPosition(T,Id,X,Y),direction(D),pushable(T,Id,D),rows(Y),columns(X).
0{move(T,Id,D):validMoves(T,Id,D)}1:-time(T),T<maxTime.   %cosi facendo so che non posso avere due move allo stesso istante di tempo

%se non sposto una scatola, allora rimane nella sua posizione originale
on(T+1,Id,X,Y):-on(T,Id,X,Y), not move(T,Id,_),T<maxTime.
vertexPosition(T+1,Id,X,Y):- vertexPosition(T,Id,X,Y), not move(T,Id,_),T<maxTime.

%se invece la sposto, sposto sia le coordinate del vertice che gli on
on(T+1, Id, XNew, YNew) :-  move(T, Id, D), on(T, Id, XOld, YOld), newCoord(XNew, YNew, XOld, YOld, D),T<maxTime.
vertexPosition(T+1, Id, XNew, YNew) :-  move(T, Id, D), vertexPosition(T, Id, XOld, YOld), newCoord(XNew, YNew, XOld, YOld, D),T<maxTime.

newCoord(XNew, YNew, XOld, YOld, u) :- XNew = XOld, YNew = YOld +1,columns(XNew),columns(XOld),rows(YNew),rows(YOld).
newCoord(XNew, YNew, XOld, YOld, d) :- XNew = XOld, YNew = YOld -1,columns(XNew),columns(XOld),rows(YNew),rows(YOld).
newCoord(XNew, YNew, XOld, YOld, l) :- XNew = XOld -1, YNew = YOld,columns(XNew),columns(XOld),rows(YNew),rows(YOld).
newCoord(XNew, YNew, XOld, YOld, r) :- XNew = XOld+1, YNew = YOld,columns(XNew),columns(XOld),rows(YNew),rows(YOld).

%setto il GOAL
goal(T,Id) :- vertexPosition(T,Id,X,Y),deposit(Id,X,Y),time(T).
:- goal(T,Id), move(T2,Id,_),time(T2),T2>T,vertexPosition(T,Id,_,_).

%% STATO FINALE
:- not goal(maxTime,Id),vertexPosition(maxTime,Id,_,_).

%minimizzo il numero di mosse
requiredMoves(M) :- M = #count{T:move(T,Id,D)}.
#minimize {M:requiredMoves(M)}.


%#show boxCoord/4.
%#show occupiedRow/4.
%#show move/3.
%#show occupiedCell/3.
%#show freeRow/4.
%#show goal/2.
%#show on/4.
%#show pushable/3.
#show vertexPosition/4.

