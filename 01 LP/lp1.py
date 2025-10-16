import os
os.system('cls' if os.name == 'nt' else 'clear')

'''
!pip install pyomo
!app-get install -y -qq glpk-utils

LP Problem Example
maximize z = 4*x1 + 3*x2
subject to:
    x1 + x2 <= 40
    2x1 + x2 <= 60
'''

from pyomo.environ import *
# create a model
model = ConcreteModel()

# define the variables
model.x1 = Var(within = NonNegativeReals)
model.x2 = Var(within = NonNegativeReals)

# define the objective function 
model.obj = Objective(expr = 4*model.x1 + 3*model.x2, sense = maximize)

# define the constraints
model.c1 = Constraint(expr = model.x1 + model.x2 <= 40)
model.c2 = Constraint(expr = 2*model.x1 + model.x2 <= 60)

# solve the model
solver = SolverFactory('glpk')
results = solver.solve(model)

# display the results
print("Status:", results.solver.termination_condition)
print("Objective value:", model.obj())
print("x1:", model.x1())
print("x2:", model.x2())