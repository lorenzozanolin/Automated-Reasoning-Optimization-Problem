import random
import subprocess
import numpy as numpy
import re

#ASP = f'clingo --time-limit 300 {ISTANZA_ASP}'

def printField(matrix):
    for i in range(len(matrix)):
        print(str(matrix[i])+"\n")

def isFree(matrix, row, column, l):    #controlla se la sua area tocca quella delle altre
    status = True
    for i in range(row, row+l):
        for j in range(column, column+l):
            if i >= matrix.shape[0] or j >= matrix.shape[1]:
                # se le coordinate sono fuori dalla matrice, salta
                continue
            
            if matrix[i][j] != 0:
                status = False
    return status

def occupyMatrix(matrix, column, row, l,id):  #popolo la matrice scendendo verso il basso e verso dx
    for i in range(row, row+l):
        for j in range(column, column+l):
            if i >= matrix.shape[0] or j >= matrix.shape[1]:
                # se le coordinate sono fuori dalla matrice, salta
                continue
            matrix[i][j] = id
            
def generateBoxes(values,field,number):    #per generare il numero di box
    aspCoordinates = []
    mznCoordinates = []
    for i in range(1,number+1):    #al massimo number boxes
        #alto a sx
        row = random.randrange(1,values[0]-1) #da 3 a n-2 perche cosi non tocca i bordi (NB la matrice va da 0 a m-1)
        column = random.randrange(1,values[1]-1)
        size = random.randrange(1,values[3])
        
        if(field[row][column] == 0 and abs(row-values[0])>1 and abs(column-values[1])>1 and isFree(field,row,column,size)): #se non sta sui bordi e in x,y è libero e se l'area è libera
            #print(column,row)
            occupyMatrix(field,column,row,size,i)    #aggiorno la matrice 
            #id, size, column, row
            mznCoordinates.append((i,size,column+1,row+size))
            aspCoordinates.append((i,size,column+1,values[0]-(row+size)+1))
            values[4]+=1    #incremento il numero di box
    return mznCoordinates,aspCoordinates
    
def generateGoals(matrix,initialCoordinates,values):
    initialCoordinates = sorted(initialCoordinates, key=lambda x: x[1],reverse=True)   #ordino i box in base alla loro dimensione (in posiz 3) e posiziono per primo quelli più grandi
    absoluteCoords = [lst[:2] + (lst[2]-1,) + (lst[3]-lst[1],) for lst in initialCoordinates]   #absolute coords, alto a sx
    mznFinalCoords=[]
    aspFinalCoords=[]
    
    for i in range(len(absoluteCoords)):
        searchGoal(matrix,absoluteCoords[i][1],absoluteCoords[i][0],mznFinalCoords,aspFinalCoords,values)
    #print(mznFinalCoords)
    #print(aspFinalCoords)
    return mznFinalCoords,aspFinalCoords

def searchGoal(matrix,size,id,mznFinalCoords,aspFinalCoords,values):
    #data la matrice e la dimensione del pacco, parti dal fondo a sx e cerca uno spazio libero
    #print(values[0],values[1])
    #print(matrix.shape[0],matrix.shape[1])
    j = 0
    for i in range(matrix.shape[0]-1, -1, -1):
        #print(i)
        #print(matrix[i][j])
        while j<matrix.shape[1] and matrix[i][j]!=0:
            j+=1
        if j<matrix.shape[1]:
            #print("occupata")
            occupyMatrix(matrix,j,i-size+1,size,id)
            #print("x:"+ str(j), "y:"+str(i))
            mznFinalCoords.append((id,j+1,(i+1))) #deve essere id,x,y
            aspFinalCoords.append((id,j+1,values[0]-i))
            break

def generateValues(values,difficulty): #per le istante easy, le scatole hanno dimensione massima 3
    #values = [m,n,maxTime,maxDim,boxNumber]   
    
    if(difficulty == 'e'):    
        values[0] = random.randrange(3,5) #n    (tra 3 e 4)
        values[1] = random.randrange(3,5)  #m
        values[3] = 2   #dimensione massima delle scatole, nelle istanze semplici massimo 3
        values[2] = 25  #massimo 35 spostamenti
        numberOfBoxes = 2   #per le istnaze MASSIMO 4 box, poi quelle effettive sono salvate in values[4]
    if(difficulty == 'm'):
        values[0] = random.randrange(4,6)  #n   (tra 4 e 5)
        values[1] = random.randrange(4,6)  #m
        values[3] = 3   #dimensione massima delle scatole, nelle istanze semplici massimo 3
        values[2] = 35  #massimo 35 spostamenti
        numberOfBoxes = 2  #per le istnaze MASSIMO 4 box, poi quelle effettive sono salvate in values[4]
    if(difficulty == 'h'):
        values[0] = random.randrange(7,9)  #n
        values[1] = random.randrange(7,9)  #m
        values[3] = 4   #dimensione massima delle scatole, nelle istanze semplici massimo 3
        values[2] = 55  #massimo 35 spostamenti
        numberOfBoxes = 4  #per le istnaze MASSIMO 4 box, poi quelle effettive sono salvate in values[4]
    
    
    matrix = numpy.zeros((values[0], values[1]), dtype=int)  #matrice che codifica la stanza
    mznICoordinates,aspICoordinates = generateBoxes(values,matrix,numberOfBoxes) #genero i box e le loro coordinate iniziali
    #print("VALORI INIZIALI : \n")
    #print("mzn: "+str(mznICoordinates)+"\n")
    #print("asp: "+str(aspICoordinates)+"\n")
    #printField(matrix)
    
    mznFCoordinates,aspFCoordinates = generateGoals(matrix,mznICoordinates,values) #genero le coordinate finali per ogni box inserito 
    #print("VALORI FINALI : \n")
    #print("mzn: "+str(mznFCoordinates)+"\n")
    #print("asp: "+str(aspFCoordinates)+"\n")
    #printField(matrix)
    return mznICoordinates,aspICoordinates,mznFCoordinates,aspFCoordinates

def createASPInstance(f,values,initialCoordinates,finalCoordinates):  
    constantList = ["n","m","maxTime","maxDim","boxNumber"] #boxNumber è il numero di scatole, maxDim è la dimensione della scatola piu grande. Ogni scatola ha una dimensione variabile tra 1..maxDim
    
    for i in range(0,len(constantList)):    #constants
        f.write("#const "+ constantList[i] +"="+ str(values[i]) +".\n")
    
    for i in range(0,len(initialCoordinates)):     #coordinates
        f.write("boxCoord"+ str(initialCoordinates[i]) +".\n")
    
    for i in range(0,len(finalCoordinates)):     #depositis
        f.write("deposit"+ str(finalCoordinates[i]) +".\n")

def createMINIZINCInstance(f,values,initialCoordinates,finalCoordinates):
    constantList = ["n","m","maxTime","maxDim","k"] #k è il numero di scatole, maxDim è la dimensione della scatola piu grande. Ogni scatola ha una dimensione variabile tra 1..maxDim
    
    for i in range(0,len(constantList)):    #constants
        f.write(constantList[i] +"="+ str(values[i]) +";\n")
    
    f.write("initialCoords = array2d(1..k,1..3,\n[")
    for i in range(0,len(initialCoordinates)):     #initial coordinates
        f.write("|"+ str(initialCoordinates[i][2]) +","+ str(initialCoordinates[i][3]) +","+ str(initialCoordinates[i][1])+"\n")   
    f.write("|]);")
    
    f.write("finalCoords = array2d(1..k,1..2,\n[")
    finalCoordinates = sorted(finalCoordinates, key=lambda x: x[0])
    for i in range(0,len(finalCoordinates)):     #initial coordinates
        f.write("|"+ str(finalCoordinates[i][1]) +","+ str(finalCoordinates[i][2]) +"\n")   
    f.write("|]);")

def writeInstance(epochs,difficulty):
    values = [0,0,0,0,0]
    for i in range(epochs):
        initialM,initialA,finalM,finalA = generateValues(values,difficulty)
        f = open("./Answer Set Programming/Istanze/"+difficulty+"Istance"+str(i+1)+".lp", "w")
        createASPInstance(f,values,initialA,finalA)
        f.close()
        f = open("./Constraint Programming/Istanze/"+difficulty+"Istance"+str(i+1)+".dzn", "w") 
        createMINIZINCInstance(f,values,initialM,finalM)
        f.close()
        values = [0,0,0,0,0]
        
def getTimes(command) :
    process = subprocess.run(['gtime'] + command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    gtimeResults = process.stderr.split('\n')[-3].split()
    time = list(map(int, re.split('\:|\.', gtimeResults[2][:-7])))
    milliseconds = (time[0] * 60 * 1000) + (time[1] * 1000) + (time[2] * 10)
    maxMemory = int(gtimeResults[-1][:-13])
    return milliseconds, maxMemory
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#writeInstance(epochs,difficulty)   
writeInstance(5,"e")
writeInstance(20,"m")
writeInstance(5,"h")

print("Done")