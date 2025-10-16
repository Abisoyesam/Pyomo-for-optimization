import os
os.system('cls' if os.name == 'nt' else 'clear')

'''
Linear Programming (Pyomo) Problem 3
LP Formulation using set notation:
    Set notation is used when decision variables are many and can be indexed.
    x1 -> variable one
    x2 -> variable two
    x3 -> variable three

Objective function:
    maximize z = 60*x1 + 30*x2 + 20*x3
subject to:
    8*x1 + 6*x2 + x3 <= 48
    4*x1 + 6*x2 + 1.5*x3 <= 20
    2*x1 + 1.5*x2 + 0.5*x3 <= 8
    x2 <= 5

Using Set Notation:
maximize z = sum(P[i] * x[i] for i in I)
I = {1, 2, 3}  # index set for variables
Subject to:
    sum(L[i] * x[i] for i in I) <= 48) L = {8, 6, 1}
    sum(F[i] * x[i] for i in I) <= 20) F = {4, 6, 1.5}
    sum(C[i] * x[i] for i in I) <= 8) C = {2, 1.5, 0.5}
    x[2] <= 5
'''

from pyomo.environ import *

# create a model
model = ConcreteModel()

# Set of indices for decision variables
model.I = Set(initialize=["Desk", "Table", "Chair"])

# define parameters for the objective function and constaint coefficients
model.P = Param(model.I, initialize={
    "Desk": 60, "Table": 30, "Chair": 20})
model.L = Param(model.I, initialize = {
    "Desk": 8, "Table": 6, "Chair": 1})
model.F = Param(model.I, initialize = {
    "Desk": 4, "Table": 6, "Chair": 1.5})
model.C = Param(model.I, initialize = {
    "Desk": 2, "Table": 1.5, "Chair": 0.5})

# define decision variables
model.x = Var(model.I, within=NonNegativeReals)

# define the objective function
model.obj = Objective(expr=sum(model.P[i] * model.x[i] for i in model.I), 
                      sense=maximize)

# define the constraints
model.c1 = Constraint(expr=sum(model.L[i] * model.x[i] for i in model.I) <= 48)
model.c2 = Constraint(expr=sum(model.F[i] * model.x[i] for i in model.I) <= 20)
model.c3 = Constraint(expr=sum(model.C[i] * model.x[i] for i in model.I) <= 8)
model.c4 = Constraint(expr=model.x["Table"] <= 5)

# solve the model
solver = SolverFactory('glpk')
results = solver.solve(model)

# display the results
print("Status:", results.solver.termination_condition)
print("Objective Value:", model.obj())
for i in model.I:
    print(f"{i}: {model.x[i]()}")  # Display the value of each decision variable
    