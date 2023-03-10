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
set of int: MOVES = {0,1,2,3,4}; % 0:down  1:up  2: left  3:right 4:none

n = 6;
m = 6;
k = 3;
maxTime = 15;
maxDim = 2;
initialCoords = array2d(1..k,1..3,
                        [|3,3,2  %  first is x (column), second is y (row), third is dimension
                         |2,3,1
                         |5,2,1|]);     
                         
finalCoords = array2d(1..k,1..2,
                      [|1,6
                       |3,6
                       |4,6|]);      
                         
                         
                        
array [CARTONS,1..3] of par int: initialCoords;   % initialCoords[i][1] and coord[i][2] are the initial coordinates of carton i, initialCoords[i][3] is the length of the i-th box.
array [CARTONS,1..2,1..maxTime] of var int: vertexCoords;  %save vertex coordinates at each step (to generate successive coordinates)

array[STEPS] of var MOVES: movesDoneAtTime; %array containing the moves done at time i... this is calculated by solver
array[STEPS] of var CARTONS: boxSelectedAtTime; %array containing the box selected at time i... this is calculated by solver
array [CARTONS,1..2] of par int: finalCoords;   % finalCoords[i][1] and coord[i][2] are the final coordinates of carton i.
array [ROWS,COLUMNS,1..maxTime] of var 0..3: room;  % room[i][j] = 0 if the cell is full, id means a box of id=id is on that cell.

predicate setInitialMatrix()=
%load the initial coordinates, then we need to generate all the occupied positions
  forall(row in ROWS, col in COLUMNS)(  %set empty cells
    if (not exists(c in CARTONS)(
          (row >= initialCoords[c,2] - initialCoords[c,3] + 1 /\ row <= initialCoords[c,2] ) /\ (col >= initialCoords[c,1] /\ col <= initialCoords[c,1] + initialCoords[c,3] - 1)
       ))
    then
         room[row,col,1] = 0
    endif
  ) 
   
  /\

  forall(c in CARTONS)(  %set occupied cells
    forall(i in 0..initialCoords[c,3]-1)(  %from row i to row i+l
      forall(j in 0..initialCoords[c,3]-1)(  %from column j to column j+l
        ( room[initialCoords[c,2]-i, initialCoords[c,1]+j,1] = c)))  %the rows is substracted from n because in input is given bottom-left coordinates, but we populate starting from top left
        
        /\
   %save coordinates for each box
   vertexCoords[c,1,1] = initialCoords[c,1] /\ %x column
   vertexCoords[c,2,1] = initialCoords[c,2] %y rows
   
  ) 
;

predicate pushable(var CARTONS:id , STEPS:t, var MOVES:d) =  %pushable se è libero davanti e dietro la scatola, verso quella direzione

    (d == 0 -> (  %DOWN
      exists(i in 0..initialCoords[id,3]-1)(  %check behind the box, where the sokoban is
        room[vertexCoords[id,2, t]-initialCoords[id,3], vertexCoords[id,1,t]+i,t] == 0
      )
      /\
      
      not exists(i in 0..initialCoords[id,3]-1)(  %check over the box, all cells must be empty
        room[vertexCoords[id,2, t]+1, vertexCoords[id,1,t]+i,t] != 0
      )
    ))
    
    /\
    
   (d == 1 -> ( %UP
      exists(i in 0..initialCoords[id,3]-1)(  %check behind the box, where the sokoban is
        room[vertexCoords[id,2, t]+1, vertexCoords[id,1,t]+i,t] == 0
      )
      /\
      
      not exists(i in 0..initialCoords[id,3]-1)(  %check over the box, all cells must be empty
        room[vertexCoords[id,2, t]-initialCoords[id,3], vertexCoords[id,1,t]+i,t] != 0
      )
    )
   )
   
   /\
    
   (d == 2 -> ( %LEFT
      exists(i in 0..initialCoords[id,3]-1)(  %check behind the box, where the sokoban is
        room[vertexCoords[id,2, t]-i, vertexCoords[id,1,t]+initialCoords[id,3],t] == 0
      )
      /\
      
      not exists(i in 0..initialCoords[id,3]-1)(  %check over the box, all cells must be empty
        room[vertexCoords[id,2, t]-i, vertexCoords[id,1,t]-1,t] != 0
      )
    )
   )
   
   /\
    
   (d == 3 -> ( %RIGHT
      exists(i in 0..initialCoords[id,3]-1)(  %check behind the box, where the sokoban is
        room[vertexCoords[id,2, t]-i, vertexCoords[id,1,t]-1,t] == 0
      )
      /\
      
      not exists(i in 0..initialCoords[id,3]-1)(  %check over the box, all cells must be empty
        room[vertexCoords[id,2, t]-i, vertexCoords[id,1,t]+initialCoords[id,3],t] != 0
      )
    )
   )
;

predicate inertia() = 
%inertia, all boxes not moved at time i must have same coords at time i+1
  (forall(t in STEPS) (
    forall(carton in CARTONS)(
      (carton != boxSelectedAtTime[t] ->  %if a box was not moved
      (vertexCoords[carton,1,t+1] = vertexCoords[carton,1,t] /\  %x untouched
       vertexCoords[carton,2,t+1] = vertexCoords[carton,2,t])) %y untouched
      )
          
     /\
     %if the box selected is not pushable toward the direction selected, then false
     (not exists(carton in CARTONS)(
      not pushable(boxSelectedAtTime[t],t,movesDoneAtTime[t]) /\ boxSelectedAtTime[t] = carton)
     )
     
         
  ))
;

predicate move() = 
  %move, it moves the selected box and update its coordinates
  (forall(t in STEPS) (
    %for each move in movesDoneAtTime we move the box
    ((movesDoneAtTime[t] = 0 /\ pushable(boxSelectedAtTime[t],t,0))->  %down
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] /\  %x untouched
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t] +1)) %y 
    
    /\
    
    ((movesDoneAtTime[t] = 1 /\ pushable(boxSelectedAtTime[t],t,1)) -> %up
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] /\  %x 
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t] -1)) %y  
    
    /\
    
    ((movesDoneAtTime[t] = 2 /\ pushable(boxSelectedAtTime[t],t,2))->  %left
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] - 1 /\  %x-1 
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t])) %y 
    
    /\
    
    (movesDoneAtTime[t] = 3 /\ pushable(boxSelectedAtTime[t],t,3) ->  %right
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] + 1 /\  %x 
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t])) %y 
     
    /\
    
    (movesDoneAtTime[t] = 4 ->  %none movement
    (vertexCoords[boxSelectedAtTime[t],1,t+1] = vertexCoords[boxSelectedAtTime[t],1,t] /\  %x 
     vertexCoords[boxSelectedAtTime[t],2,t+1] = vertexCoords[boxSelectedAtTime[t],2,t])) %y 
    
  ))
;

predicate printMatrix() = 

  forall(t in 1..maxTime)(
    forall(row in ROWS, col in COLUMNS )(  %set empty cells
      if (not exists(c in CARTONS)(
            (row >= vertexCoords[c,2,t] - initialCoords[c,3] + 1 /\ row <= vertexCoords[c,2,t] ) /\ (col >= vertexCoords[c,1,t] /\ col <= vertexCoords[c,1,t] + initialCoords[c,3] - 1)
         ))
      then
           room[row,col,t] = 0
      endif
    ) 
  
   
  /\

    forall(c in CARTONS)(  %set occupied cells
      forall(i in 0..initialCoords[c,3]-1)(  %from row i to row i+l
        forall(j in 0..initialCoords[c,3]-1)(  %from column j to column j+l
          ( room[vertexCoords[c,2,t]-i, vertexCoords[c,1,t]+j,t] = c))))  %the rows is substracted from n because in input is given bottom-left coordinates, but we populate starting from top left
  )  
;

predicate finalPosition() =
  forall(box in CARTONS)(
  (vertexCoords[box,1,maxTime] = finalCoords[box,1]) /\
  (vertexCoords[box,2,maxTime] = finalCoords[box,2]) 
  )
 ;
  
constraint
  
  setInitialMatrix() /\ inertia() /\ move() /\ printMatrix() /\ finalPosition()
  
;

%Count number of null moves, then i want to maximize it  
var int: nullMoves = count(move in movesDoneAtTime) (move == 4);

solve	:: int_search(movesDoneAtTime,input_order,indomain_min)
   :: int_search(boxSelectedAtTime,first_fail,indomain_random)
   :: restart_linear(10)
   maximize nullMoves;

output [ "matrice : \n"] ++
    [  %output matrice corretta
        show(room[i,j,t]) ++
        
        if j == m /\ i == n then "\n\n"
        else
          if j==m then "\n"
          else " "
          endif
        endif |
        
        t in 1..maxTime,
        i in ROWS, j in COLUMNS
    ]% ++ [ "coordinate all'istante : \n"] ++ 
    
    %[  show(vertexCoords[i,j,t]) ++ 
    %    if j == 2 /\ i == k then "\n\n"
    %    else
    %      if j==2 then "\n"
    %      else " "
    %      endif
    %    endif |
    %    t in 1..maxTime, i in CARTONS, j in 1..2
    %];%++
    
    %print only useful moves
    ++
    ["Moves :"]
    
    ++[ " " ++ show(movesDoneAtTime[t]) ++" "|
        t in STEPS where fix(movesDoneAtTime[t])!=4
    ]
    
    ++
    
    ["\nBoxes :"]
    
    ++[ " " ++ show(boxSelectedAtTime[t]) ++" "|
        t in STEPS where fix(movesDoneAtTime[t])!=4
    ]
    
    ++
    
    ["\nTotal count : " ++ show(maxTime-nullMoves-1)]
     
    ;
    
    
