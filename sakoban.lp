% i : sono come un for, le variabili iniziano con maiuscole, le costanti per minuscole
%esempio n=5 m=6 k=1

tile(1..m*n).   %piastrelle
number(1..k).   %numero di box
direction(u;d;l;r). %direzione di sPostamento
time(0..p). %time, upperbound è il limnite di passi p

%controllo se la cella Pos è libera, confronto per ogni box se qualcuno è in quella Posizione (da verificare se funziona)
%free(T,Pos):-time(T),not on(T,_,Pos),tile(Pos). %da rivedere per il verso opposto
%:-free(T,Pos),on(T,Id,Pos),tile(Pos),time(T),box(Id,Pos),number(Id).

%box(Id,Posizione)
%inizialmente in Posizione (2,1) => 7, poi box non lo uso piu
box(1,7). %box(2,12).  
deposit(1,26).   %Posizione dove depositare il blocco 1

%box(Id,Pos,k) => all'inizio
%box(Id,k) => per sapere la size del box
% STATO INIZIALE
% on(tempo,id_box,cella), ricorda che il tempo fa da discriminante per le tuple, quindi non serve disattivare
on(0,Id,Pos) :- box(Id,Pos), tile(Pos), number(Id).

% ogni oggetto è in esattamente una cella in ogni istante (fissata una scatola, per ogni cella, esattamente una sola contiene la scatola) No triple (x,y,_)
1{ on(T,Id,Pos) : tile(Pos)}1 :- time(T), number(Id).

%% due box non Possono essere nella stessa cella ad ogni istante
:- on(T,Id1,Pos),on(T,Id2,Pos),Id1!=Id2,time(T),number(Id1),number(Id2).

%% in un istante muovo esattamente una scatola dato che non muovo il sokoban(1 sola mossa per istante di tempo)
1{ move(T, Id, D, SPos, FPos) : push(T, Id, D, SPos, FPos),number(Id)}1 :- time(T).
:- move(T,Id1, D1, SPos1, FPos1), move(T,Id2,D2, SPos2, FPos2),Id1!=Id2,time(T),number(Id1),number(Id2),direction(D1),direction(D2),tile(SPos1),tile(SPos2),tile(FPos1),tile(FPos2).


% in una partita una scatola deve essere mossa almeno una volta e massimo p(fissata una scatola, guardo tutte le altre Posizioni)
:- not move(_,Id,_,_,_),number(Id). %ogni scatola deve essere mossa almeno una volta

%% se faccio una mossa l'oggetto si muove, poi non mi interessa disattivare il vecchio on
on(T+1,Id,FPos):- move(T,Id,D,SPos,FPos), on(T,Id,SPos),tile(SPos),tile(FPos), time(T), direction(D),number(Id),T<p.


%%se non muovo una scatola, rimane ferma all'istante successivo
on(T+1,Id,SPos):- not move(T,Id,_,_,_),on(T,Id,SPos),time(T), time(T+1),T<p.

%%movimento
push(T,Id,D,SPos,FPos):-number(Id),direction(D),tile(SPos),tile(FPos),SPos!=FPos,time(T),reachable(T,SPos,FPos,D),on(T,Id,SPos).

%% reachable mi permette di dire se Posso sPostare un pacco verso d, ovvero se le due Posizioni sono vicine e se è libero lo spazio davanti alla cassa
%%SPos = posizione del pacco, FPos = posizione d'arrivo, SPos+-X = posizione davanti al pacco
reachable(T,SPos,FPos,u):- tile(SPos), tile(FPos),tile(SPos+n), FPos = SPos - n, not on(T,_,FPos), not on(T,_,SPos+n),time(T).    %n
reachable(T,SPos,FPos,d):- tile(SPos), tile(FPos),tile(SPos-n), FPos = SPos + n, not on(T,_,FPos), not on(T,_,SPos-n),time(T).    %s
reachable(T,SPos,FPos,r):- tile(SPos), tile(FPos),tile(SPos-1), FPos = SPos + 1, not on(T,_,FPos), not on(T,_,SPos-1),time(T).    %e
reachable(T,SPos,FPos,l):- tile(SPos), tile(FPos),tile(SPos+1), FPos = SPos - 1, not on(T,_,FPos), not on(T,_,SPos+1),time(T).    %o

%goal :- on(T,Id,Pos),tile(Pos),deposit(Id,Pos),number(Id),time(T).
%
%% STATO FINALE
:- not goal.
%
%#show move/5.
%#show do/1. %non mostro solo push
#show on/3.

%calcola area, ovvero setto come bloccate le celle coperte dal blocco
on(T,Id,(Pos-n)),...,on(T,Id,(Pos-(n*k))):-on(T,Id,Pos),box(Id,k)