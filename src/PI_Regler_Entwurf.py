import sympy as sp

#Parameter of PT2 
#t_25 = 7.7
#Temp_25 = 2.5
#t_75 = 20
#Temp_75 = 7.5
#k = 10

t_25 = 7.81#7.812
Temp_25 = 1.25
t_75 = 20.0
Temp_75 = 3.75
k = 5

r_PT2 = t_25/t_75
P_PT2 = -18.56075*r_PT2+(0.57311/(r_PT2-0.20747))+4.16423
X_PT2 = 14.2792*pow(r_PT2, 3)-9.3891*pow(r_PT2, 2)+0.25437*r_PT2+1.32148

T2_PT2 = (t_75-t_25)/(X_PT2*(1+1/P_PT2))
T1_PT2 = T2_PT2/P_PT2

print("\nT2 PT2:")
sp.pprint(T2_PT2)
print("\nT1 PT2:")
sp.pprint(T1_PT2)

b0_PT2 = k
a2_PT2 = T1_PT2*T2_PT2
a1_PT2 = T1_PT2+T2_PT2
a0_PT2 = 1

print("\nb0 PT2:")
sp.pprint(k)
print("\na2 PT2:")
sp.pprint(a2_PT2)
print("\na1 PT2:")
sp.pprint(a1_PT2)
print("\na0 PT2:")
sp.pprint(a0_PT2)

Tu = T2_PT2
Tg = T1_PT2
Ks = k

print("\nParameter Tu:")
sp.pprint(Tu)
print("\nParameter Tg:")
sp.pprint(Tg)
print("\nParameter Ks:")
sp.pprint(k)

#PI Controller -> Chien, Hrones und Reswick
kr = 0.35 * (Tg / (Tu * Ks))
Tn = 1.2 * Tg
P = 10

print("\n kr:")
sp.pprint(kr)
print("\nTn:")
sp.pprint(Tn)

#z-Transformation

b1_PID = kr*Tn
b0_PID = kr
a1_PID = Tn
a0_PID = 0

Ta =1/5

print("\nb1_PID:")
sp.pprint(b1_PID)
print("\nb0_PID:")
sp.pprint(b0_PID)
print("\na1_PID:")
sp.pprint(a1_PID)
print("\na0_PID:")
sp.pprint(a0_PID)


def A1(b1, b0, a1, a0):
    return (2*a1+a0*Ta)

def A0(b1, b0, a1, a0):
    return (-2*a1+a0*Ta)

def B1(b1, b0, a1, a0):
    return (2*b1+b0*Ta)

def B0(b1, b0, a1, a0):
    return (-2*b1+b0*Ta)

fixPoint = 6

#while (abs(B2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)/A2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)+B1(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)/A2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)+B0(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)/A2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0))) * (2 ** fixPoint) < 1:
    #fixPoint = fixPoint + 1


print("\n\n\nPID-coefficient: y[k] = x[k]B2 + x[k-1]B1 + x[k-2]B0 - y[k-1]A1 - y[k-2]A0")
print("\nB1_PID:")
sp.pprint(B1(b1_PID, b0_PID, a1_PID, 0)/A1(b1_PID, b0_PID, a1_PID, 0) * 2 ** fixPoint)
print("\nB0_PID:")
sp.pprint(B0(b1_PID, b0_PID, a1_PID, 0)/A1(b1_PID, b0_PID, a1_PID, 0) * 2 ** fixPoint)
print("\nA1_PID:")
sp.pprint(A0(b1_PID, b0_PID, a1_PID, 0)/A1(b1_PID, b0_PID, a1_PID, 0) * 2 ** fixPoint)

print("\nSUM of B's (Inegrator need to be > 1):")
#sp.pprint((B2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)/A2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)+B1(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)/A2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)+B0(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)/A2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, 0)) * (2 ** fixPoint))
print("need of at least FixPoints:")
sp.pprint(fixPoint)

print("\n\n\nPT2-coefficient: y[k] = x[k]B2 + x[k-1]B1 + x[k-2]B0 - y[k-1]A1 - y[k-2]A0")
print("\nB2_PT2:")
#sp.pprint(B2(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2)/A2(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2))
print("\nB1_PT2:")
#sp.pprint(B1(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2)/A2(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2))
print("\nB0_PT2:")
#sp.pprint(B0(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2)/A2(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2))
print("\nA1_PT2:")
#sp.pprint(A1(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2)/A2(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2))
print("\nA0_PT2:")
#sp.pprint(A0(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2)/A2(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2))
