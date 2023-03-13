import random
import subprocess
import numpy as numpy
import re

#ASP = f'clingo --time-limit 300 {ISTANZA_ASP}'
 
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
    for i in range(0,len(finalCoordinates)):     #initial coordinates
        f.write("|"+ str(finalCoordinates[i][1]) +","+ str(finalCoordinates[i][2]) +"\n")   
    f.write("|]);")
    

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
    coordinates = []
    for i in range(1,number+1):    #al massimo number boxes
        row = random.randrange(values[3]-1,values[0]-2) #da 3 a n-2 perche cosi non tocca i bordi (NB la matrice va da 0 a m-1)
        column = random.randrange(1,values[1]-2)
        size = random.randrange(1,values[3])
        
        if(field[row][column] == 0 and abs(row-values[0])>1 and abs(column-values[1])>1 and isFree(field,row-(size-1),column,size)): #se non sta sui bordi e in x,y è libero e se l'area è libera
            occupyMatrix(field,column,row-(size-1),size,i)    #aggiorno la matrice 
            coordinates.append((i,size,column+1,values[0]-row))    
            values[4]+=1    #incremento il numero di box
    return coordinates
    
def generateGoals(matrix,initialCoordinates,values):
    initialCoordinates = sorted(initialCoordinates, key=lambda x: x[1],reverse=True)   #ordino i box in base alla loro dimensione (in posiz 2) e posiziono per primo quelli più grandi
    finalCoords=[]
    #print("Coordinate"+str(initialCoordinates)+"\n")
    for i in range(len(initialCoordinates)):
        searchGoal(matrix,initialCoordinates[i][1],initialCoordinates[i][0],finalCoords,values)
    return finalCoords

def searchGoal(matrix,size,id,finalCoords,values):
    #data la matrice e la dimensione del pacco, parti dal fondo a sx e cerca uno spazio libero
    j = 0
    for i in range(matrix.shape[0]-1, -1, -1):
        while matrix[i][j]!=0:
            j+=1
        occupyMatrix(matrix,j,i-size+1,size,id)
        finalCoords.append((id,j+1,values[0]-i)) #deve essere id,x,y
        break

def easyValues(values): #per le istante easy, le scatole hanno dimensione massima 3
    #values = [m,n,maxTime,maxDim,boxNumber]
    
    values[0] = random.randrange(5,7)  #n
    values[1] = random.randrange(5,7)  #m
    values[3] = 3   #dimensione massima delle scatole, nelle istanze semplici massimo 3
    values[2] = 25  #massimo 35 spostamenti
    numberOfBoxes = 4   #per le istnaze MASSIMO 4 box, poi quelle effettive sono salvate in values[4]
    
    matrix = numpy.zeros((values[0], values[1]), dtype=int)  #matrice che codifica la stanza
    initialCoordinates = generateBoxes(values,matrix,numberOfBoxes) #genero i box e le loro coordinate iniziali
    finalCoordinates = generateGoals(matrix,initialCoordinates,values) #genero le coordinate finali per ogni box inserito 
    #printField(matrix)
    return initialCoordinates,finalCoordinates
    #print(str(list(zip(constantList,values)))+"\n"+str(coordinates))

def writeInstance(epochs):
    values = [0,0,0,0,0]
    for i in range(epochs):
        initialCoords, finalCoords = easyValues(values)
        f = open("./Answer Set Programming/Istanze/eIstance"+str(i+1)+".lp", "w")
        createASPInstance(f,values,initialCoords,finalCoords)
        f.close()
        f = open("./Constraint Programming/Istanze/eIstance"+str(i+1)+".dzn", "w") 
        createMINIZINCInstance(f,values,initialCoords,finalCoords)
        f.close()
        

def getTimes(command) :
    process = subprocess.run(['gtime'] + command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    gtimeResults = process.stderr.split('\n')[-3].split()
    time = list(map(int, re.split('\:|\.', gtimeResults[2][:-7])))
    milliseconds = (time[0] * 60 * 1000) + (time[1] * 1000) + (time[2] * 10)
    maxMemory = int(gtimeResults[-1][:-13])
    return milliseconds, maxMemory

writeInstance(15)








#choice = input("Select instance difficulty : 1.Easy 2.Medium 3.Hard \n")