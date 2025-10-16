import os
os.system('cls' if os.name == 'nt' else 'clear')

"""
Linear Programming Example using Pyomo
LP Formulation:
minimize z = 0.05Xs + 0.07Xw + 0.15Xd
subject to:
    Xs + Xw + Xd = 300
    Xs <= 150
    Xw <= 100
    Xd <= 200
variables:
    Xs, Xw, Xd >= 0
"""

from pyomo.environ import *

# create a model
model = ConcreteModel()

# define variables
model.Xs = Var(within = NonNegativeReals)
model.Xw = Var(within = NonNegativeReals)
model.Xd = Var(within = NonNegativeReals)

# define objective function
model.obj = Objective(expr = 0.05*model.Xs + 0.07*model.Xw + 
                      0.15*model.Xd, sense = minimize)

# define constraints
model.c1 = Constraint(expr = model.Xs + model.Xw + model.Xd == 300)
model.c2 = Constraint(expr = model.Xs <= 150)
model.c3 = Constraint(expr = model.Xw <= 100)
model.c4 = Constraint(expr = model.Xd <= 200)

# solve the model
solver = SolverFactory('glpk')
results = solver.solve(model)

# display the results
print("Optimal Cost:", model.obj())
print("Xs:", model.Xs())
print("Xw:", model.Xw())
print("Xd:", model.Xd())
