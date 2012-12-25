require("ParameterVector"); using ParameterVector
syms = [:left, :middle, :right]
lc = LinearConstraints(Float64, syms, [:(left <= middle <= right), :(5 < middle), :(2*(right-middle) == 7)])
@assert lc.A == [1.0 -1.0 0.0; 0.0 1.0 -1.0]
@assert lc.b == zeros(2)
@assert lc.Aeq == [0.0 -2.0 2.0]
@assert lc.beq == [7.0]
@assert lc.lb == [-Inf, 5.0, -Inf]
@assert lc.ub == [Inf, Inf, Inf]
