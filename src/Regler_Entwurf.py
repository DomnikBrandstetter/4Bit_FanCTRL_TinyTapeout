import sympy as sp

def A2(b2, b1, b0, a2, a1, a0, Ta):
    return (4*a2+2*a1*Ta+a0*Ta*Ta)

def A1(b2, b1, b0, a2, a1, a0, Ta):
    return ((-8*a2+2*a0*Ta*Ta)/(A2(b2, b1, b0, a2, a1, a0, Ta)))

def A0(b2, b1, b0, a2, a1, a0, Ta):
    return ((4*a2-2*a1*Ta+a0*Ta*Ta)/(A2(b2, b1, b0, a2, a1, a0, Ta)))

def B2(b2, b1, b0, a2, a1, a0, Ta):
    return ((4*b2+2*b1*Ta+b0*Ta*Ta)/(A2(b2, b1, b0, a2, a1, a0, Ta)))

def B1(b2, b1, b0, a2, a1, a0, Ta):
    return ((-8*b2+2*b0*Ta*Ta)/(A2(b2, b1, b0, a2, a1, a0, Ta)))

def B0(b2, b1, b0, a2, a1, a0, Ta):
    return ((4*b2-2*b1*Ta+b0*Ta*Ta)/(A2(b2, b1, b0, a2, a1, a0, Ta)))

#System Parameter
t_25 = 7.81
t_75 = 20.0
k = 5
#time step PT2 
Ta_PT2 =1/1000 # 1kHz
#time step PI
Ta_PI =1/5 #5 Hz
#time step PID
Ta_PID =1/100 #100 Hz


#calculate PT2
print("\n---------------------------------PT2---------------------------------")
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

print("\nPT2 Parameter:")
print("\nb0 PT2:")
sp.pprint(k)
print("\na2 PT2:")
sp.pprint(a2_PT2)
print("\na1 PT2:")
sp.pprint(a1_PT2)
print("\na0 PT2:")
sp.pprint(a0_PT2)

print("\n\n\nPT2-coefficients: y[k] = x[k]B2 + x[k-1]B1 + x[k-2]B0 - y[k-1]A1 - y[k-2]A0 / Timestep: " + str(Ta_PT2))
print("\nB2_PT2-coefficient:")
sp.pprint(B2(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2, Ta_PT2))
print("\nB1_PT2-coefficient:")
sp.pprint(B1(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2, Ta_PT2))
print("\nB0_PT2-coefficient:")
sp.pprint(B0(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2, Ta_PT2))
print("\nA1_PT2-coefficient:")
sp.pprint(A1(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2, Ta_PT2))
print("\nA0_PT2-coefficient:")
sp.pprint(A0(0, 0, b0_PT2, a2_PT2, a1_PT2, a0_PT2, Ta_PT2))

#PI-Controller
print("\n---------------------------------PI-Controller---------------------------------")

Tu = T2_PT2
Tg = T1_PT2
Ks = k

#PI Controller -> Chien, Hrones und Reswick
kr = 0.35 * (Tg / (Tu * Ks))
Tn = 1.2 * Tg
Tv = 0
P = 10

print("\n kr:")
sp.pprint(kr)
print("\nTn:")
sp.pprint(Tn)
print("\nTv:")
sp.pprint(Tv)

#z-Transformation
b1_PI = kr * Tn + kr * (Tv/P)
b0_PI = kr
a1_PI = Tn
a0_PI = 0

print("\nPI-Controller Parameter:")
print("\nb1_PI-coefficient:")
sp.pprint(b1_PI)
print("\nb0_PI-coefficient:")
sp.pprint(b0_PI)
print("\na1_PI-coefficient:")
sp.pprint(a1_PI)
print("\na0_PI-coefficient:")
sp.pprint(a0_PI)


fixPoint = 1

while (abs(B2(0, b1_PI, b0_PI, 0, a1_PI, a0_PI, Ta_PI)+B0(0, b1_PI, b0_PI, 0, a1_PI, a0_PI, Ta_PI))) * (2 ** fixPoint) < 1:
    fixPoint = fixPoint + 1

print("\n\nPI-coefficients: y[k] = x[k]B2 + x[k-1]B1 - y[k-1]A1 / Timestep: " + str(Ta_PI) )
print("\nB2_PI-coefficient (scaled to the power of 2):")
sp.pprint(B2(0, b1_PI, b0_PI, 0, a1_PI, a0_PI, Ta_PI) * (2 ** fixPoint))
print("\nB1_PI-coefficient (scaled to the power of 2):")
sp.pprint(B0(0, b1_PI, b0_PI, 0, a1_PI, a0_PI, Ta_PI) * (2 ** fixPoint))
print("\nA1_PI-coefficient (scaled to the power of 2):")
sp.pprint(A0(0, b1_PI, b0_PI, 0, a1_PI, a0_PI, Ta_PI) * (2 ** fixPoint))
print("\nSUM of B's (To have an integrator, the sum of the B's must be > 1):")
sp.pprint((B2(0, b1_PI, b0_PI, 0, a1_PI, a0_PI, Ta_PI)+B0(0, b1_PI, b0_PI, 0, a1_PI, a0_PI, Ta_PI)) * (2 ** fixPoint))
print("number of FixPoints:")
sp.pprint(fixPoint)

print("\n---------------------------------PID-Controller---------------------------------")

#PID Controller -> Chien, Hrones und Reswick
kr = 0.6 * (Tg / (Tu * Ks))
Tn = Tg
Tv = 0.5 * Tu
P = 10

print("\n kr:")
sp.pprint(kr)
print("\nTn:")
sp.pprint(Tn)
print("\nTv:")
sp.pprint(Tv)

#z-Transformation
b2_PID = kr * Tn * (Tv/P) + kr * Tv * Tn
b1_PID = kr * Tn + kr * (Tv/P)
b0_PID = kr
a2_PID = Tn * (Tv/P)
a1_PID = Tn
a0_PID = 0

print("\nPID-Controller Parameter:")
print("\nb2_PID-coefficient:")
sp.pprint(b2_PID)
print("\nb1_PID-coefficient:")
sp.pprint(b1_PID)
print("\nb0_PID-coefficient:")
sp.pprint(b0_PID)
print("\na2_PID-coefficient:")
sp.pprint(a2_PID)
print("\na1_PID-coefficient:")
sp.pprint(a1_PID)
print("\na0_PID-coefficient:")
sp.pprint(a0_PID)

fixPoint = 1

while (abs(B2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID)+B1(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID)+B0(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID))) * (2 ** fixPoint) < 1:
    fixPoint = fixPoint + 1

print("\n\n\nPID-coefficients: y[k] = x[k]B2 + x[k-1]B1 + x[k-2]B0 - y[k-1]A1 - y[k-2]A0 / Timestep: " + str(Ta_PID))
print("\nB2_PID-coefficient (scaled to the power of 2):")
sp.pprint(B2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID) * 2 ** fixPoint)
print("\nB1_PID-coefficient (scaled to the power of 2):")
sp.pprint(B1(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID) * 2 ** fixPoint)
print("\nB0_PID-coefficient (scaled to the power of 2):")
sp.pprint(B0(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID) * 2 ** fixPoint)
print("\nA1_PID-coefficient (scaled to the power of 2):")
sp.pprint(A1(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID) * 2 ** fixPoint)
print("\nA0_PID-coefficient (scaled to the power of 2):")
sp.pprint(A0(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID) * 2 ** fixPoint)
print("\nSUM of B's (To have an integrator, the sum of the B's must be > 1):")
sp.pprint((B2(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID)+B1(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID)+B0(b2_PID, b1_PID, b0_PID, a2_PID, a1_PID, a0_PID, Ta_PID)) * (2 ** fixPoint))
print("number of FixPoints:")
sp.pprint(fixPoint)

