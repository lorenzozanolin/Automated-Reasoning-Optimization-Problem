% Model that optimize the sakoban problem
int: n;  % height of the rectangle
int: m;  % base of the rectangle
int: k;  % number of cartons, each of them is a square
int: maxTime; %maximum number of steps
int: maxDim;  %maximum size of a carton

set of int: STEPS = 1..maxTime-1;
set of int: CARTONS = 1..k;
set of int: ROWS = 1..n;
set of int: COLUMNS = 1..m;
set of int: SIZE = 1..maxDim;
set of int: MOVES = {0,1,2,3}; % 0:down  1:up  2: left  3:right

n = 5;
m = 5;
k = 2;
maxTime = 2;
maxDim = 2;
initialCoords = array2d(1..k,1..3,
                        [3,3,2,%  first is x (column), second is y (row), third is dimension
                         4,1,1]);    
movesDoneAtTime = [0];
boxSelectedAtTime = [1];
                        
array [CARTONS,1..3] of par int: initialCoords;   % initialCoords[i][1] and coord[i][2] are the initial coordinates of carton i, initialCoords[i][3] is the length of the i-th box.
array [CARTONS,1..2,1..maxTime] of var int: vertexCoords;  %save vertex coordinates at each step (to generate successive coordinates)

array[STEPS] of var MOVES: movesDoneAtTime; %array containing the moves done at time i... this is calculated by solver
array[STEPS] of var CARTONS: boxSelectedAtTime; %array containing the box selected at time i... this is calculated by solver
array[STEPS] of var 0..k: boxMovedAtTime; %array containing the box moved at time i... this is calculated by solver
array [CARTONS,1..2] of par int: finalCoords;   % finalCoords[i][1] and coord[i][2] are the final coordinates of carton i.
array [ROWS,COLUMNS,1..maxTime] of var 0..k: room;  % room[i][j] = 0 if the cell is full, id means a box of id=id is on that cell.


predicate pushable(var CARTONS:id , STEPS:t, MOVES:d) =  %pushable se è libero davanti e dietro la scatola, verso quella direzione
%    if (d = 0 /\ not exists(carton in CARTONS)(room[vertexCoords[id,2, t]-initialCoords[id,3], vertexCoords[id,1,t],t] = carton))  %check upfront, poi va sostituito con exist
%    then 
%      true
%    else
%      false
%    endif
    d == 0 -> (
      exists(i in 0..initialCoords[id,3]-1)(
        room[vertexCoords[id,2, t]-initialCoords[id,3], vertexCoords[id,1,t]+i,t] == 0
      )
    )
;

constraint
  
  %load the initial coordinates, then we need to generate all the occupied positions
  
  forall(x in ROWS, y in COLUMNS)(
    forall(c in CARTONS)(
        if ( (x < initialCords[c,1] \/ x > initialCords[c,1] + initialCords[c,3]) /\ (y < initialCords[c,2] \/ y > initialCords[c,1] + initialCords[c,3]))
        then
            rooms[x,y,1] = 0
        else
            rooms[x,y,1] = c
        endif
  
%  (forall(carton in CARTONS)(
%    forall(i in 0..initialCoords[carton,3]-1)(  %from row i to row i+l
%      forall(j in 0..initialCoords[carton,3]-1)(  %from column j to column j+l
%        ( room[initialCoords[carton,2]-i, initialCoords[carton,1]+j,1] = carton)))  %the rows is substracted from n because in input is given bottom-left coordinates, but we populate starting from top left
%     /\   
%   forall(i in ROWS)(
%    forall(j in COLUMNS)(
%      if (room[i,j,1] != carton)(
%      )
%    ))     
        
     /\
   vertexCoords[c,1,1] = initialCoords[c,1] /\ %x column
   vertexCoords[c,2,1] = initialCoords[c,2]) %y rows
   
   ) /\ 
   

  %move, it moves the selected box
 (forall(t in STEPS) (
    %for each move in movesDoneAtTime we move the box
    ((movesDoneAtTime[t] = 0 /\ pushable(boxSelectedAtTime[t],t,0))->  %down
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] /\  %x untouched
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t] +1) /\
     boxMovedAtTime[t] = boxSelectedAtTime[t]) %y 
    
    /\
    
    (movesDoneAtTime[t] = 1 ->  %up
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] /\  %x 
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t] -1)/\
     boxMovedAtTime[t] = boxSelectedAtTime[t]) %y 
    
   /\
    
    (movesDoneAtTime[t] = 2 ->  %left
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] - 1 /\  %x 
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t])/\
     boxMovedAtTime[t] = boxSelectedAtTime[t]) %y 
    
    /\
    
    (movesDoneAtTime[t] = 3 ->  %right
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] + 1 /\  %x 
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t])/\
     boxMovedAtTime[t] = boxSelectedAtTime[t]) %y 
    
  ))
  
  /\
  
  %inertia, all boxes not moved at time i must have same coords at time i+1
  (forall(t in STEPS) (
    forall(carton in CARTONS)(
      (carton != boxMovedAtTime[t] ->  %if a box was not moved
      (vertexCoords[carton,1,t+1] = vertexCoords[carton,1,t] /\  %x untouched
       vertexCoords[carton,2,t+1] = vertexCoords[carton,2,t])) %y untouched
  )))
  
  /\

 (forall(t in 2..maxTime)( %popolate at time t+1 
  forall(carton in CARTONS)(
    forall(i in 0..initialCoords[carton,3]-1)(  %from row i to row i+l
      forall(j in 0..initialCoords[carton,3]-1)(  %from column j to column j+l
        room[vertexCoords[carton,2,t]-i, vertexCoords[carton,1,t] +j,t] = carton  %the rows is substracted from n because in input is given bottom-left coordinates, but we populate starting from top left
    )
   ))))
   
  % /\
   
   %%final state
   %(forall(carton in CARTONS)(
   %  vertexCoords[carton,1,maxTime] = finalCoords[carton,1] /\
   %  vertexCoords[carton,2,maxTime] = finalCoords[carton,2]
   %))
  
;

solve satisfy;

output [ "matrice : \n"] ++
    [  %output matrice corretta
        show(room[i,j,t]) ++
        
        if j == m /\ i == n then "\n\n"
        else
          if j==m then "\n"
          else " "
          endif
        endif |
        
        t in 1..maxTime, i in ROWS, j in COLUMNS
    ] ++ [ "coordinate all'istante : \n"] ++ 
    [  show(vertexCoords[i,j,t]) ++ 
        if j == 2 /\ i == k then "\n\n"
        else
          if j==2 then "\n"
          else " "
          endif
        endif |
        t in 1..maxTime, i in CARTONS, j in 1..2
    ]++
    [  show(boxMovedAtTime[t])|
        t in STEPS
    ];
    