import pandas as pd
import matplotlib.pyplot as plt
import math

data = pd.read_excel(r'./benchmarks.xlsx',skiprows=1)
print(data)

ASP_times = pd.DataFrame(data, columns=['total time (s)']).values
ASP_times[ASP_times == 'e'] = 300
ASP_times = [math.log(item) for item in ASP_times]
MZN_times = pd.DataFrame(data, columns=['total time (s).1']).values
MZN_times[MZN_times == 'e'] = 300
MZN_times = [math.log(item) for item in MZN_times]

#setto i valori dell'asse x
x_ticks = list(range(1,31)) #valori  che assumono gli assi
x_labels = x_ticks

print(ASP_times)
plt.plot(x_ticks, ASP_times, label = "ASP")
plt.plot(x_ticks, MZN_times, label = "MZN")
plt.title('Times comparison to end computations')
plt.xticks(ticks=x_ticks,labels=x_labels)
# naming the x axis
plt.xlabel('Instances')
# naming the y axis
plt.ylabel('Time (s) \n (logarithmic scale)')
plt.grid(True,linewidth=0.5,color="#E8E8E8")
# show a legend on the plot
plt.legend()

# function to show the plot
plt.show()



