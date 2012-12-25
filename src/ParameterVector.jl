module ParameterVector
import Base.(+), Base.(-), Base.(*)
export LinearConstraints

type LinearConstraints{T<:FloatingPoint}
    A::Matrix{T}
    b::Vector{T}
    Aeq::Matrix{T}
    beq::Vector{T}
    lb::Vector{T}
    ub::Vector{T}
end
# Empty/default constructors
LinearConstraints{T}(::Type{T}, n::Int) = LinearConstraints(zeros(T,0,0), zeros(T,0), zeros(T,0,0), zeros(T,0), fill(-inf(T),n), fill(inf(T),n))
LinearConstraints{T}(::Type{T}) = LinearConstraints(zeros(T,0,0), zeros(T,0), zeros(T,0,0), zeros(T,0), zeros(T,0), zeros(T,0))
LinearConstraints() = LinearConstraints(Float64)
# The "interesting" constructor, the expression parser
function LinearConstraints{T<:FloatingPoint}(::Type{T}, syms::Vector{Symbol}, exprs::Vector{Expr})
    n = length(syms)
    symdict = Dict{Symbol, Int}(syms, 1:n)
    Arows = Array(Matrix{T}, 0)
    b = Array(T, 0)
    Aeqrows = Array(Matrix{T}, 0)
    beq = Array(T, 0)
    lb = fill(-inf(T), n)
    ub = fill(inf(T), n)
    for ex in exprs
        if ex.head == :(=)
            error("Use ==, not =, in comparisons")
        end
        if ex.head != :comparison
            error("Expression is not an equality or inequality:\n", ex)
        end
        pargs = similar(ex.args)
        for i = 1:length(ex.args)
            carg = ex.args[i]
            tmp = lcparse(T, carg, symdict)
            if isa(tmp, LinearIndexExpr) && tmp.indx[1] == -1
                error("Error parsing this expression: ", carg)
            end
            pargs[i] = tmp
        end
        for i = 2:2:length(ex.args)
            op = ex.args[i]
            darg = pargs[i-1] - pargs[i+1]
            if op == :(==)
                # equality
                row = zeros(T, 1, n) # TODO: consider sparse
                row[darg.indx] = darg.coef
                push(Aeqrows, row)
                push(beq, -darg.rhs)
            else
                # inequality
                gflag = op == :(>) || op == :(>=)
                if length(darg.indx) == 0
                    println("Warning: expression that uses no variables")
                elseif length(darg.indx) == 1
                    # upper/lower bound
                    if darg.coef[1] < 0
                        gflag = !gflag
                    end
                    val = -darg.rhs/darg.coef[1]
                    if gflag
                        lb[darg.indx[1]] = val
                    else
                        ub[darg.indx[1]] = val
                    end
                else
                    # inequality
                    row = zeros(T, 1, n) # TODO: consider sparse
                    val = -darg.rhs
                    if gflag
                        row[darg.indx] = -darg.coef
                        val = -val
                    else
                        row[darg.indx] = darg.coef
                    end
                    push(Arows, row)
                    push(b, val)
                end
            end
        end
    end
    A = isempty(Arows) ? zeros(T, 0, n) : vcat(Arows...)
    Aeq = isempty(Aeqrows) ? zeros(T, 0, n) : vcat(Aeqrows...)
    LinearConstraints(A, b, Aeq, beq, lb, ub)
end

lcparse{T}(::Type{T}, arg::Number, symdict::Dict{Symbol, Int}) = convert(T, arg)
function lcparse{T}(::Type{T}, arg::Symbol, symdict::Dict{Symbol, Int})
    l = LinearIndexExpr(T, symdict, arg)
    if l.indx[1] == -1
        return eval(arg)  # try to evaluate it, perhaps it's a constant
    end
    l
end
function lcparse{T}(::Type{T}, ex::Expr, symdict::Dict{Symbol, Int})
    if ex.head == :call && !contains((:(+), :(-), :(*), :(/)), ex.args[1])
        @show ex
        @show ex.head
        return eval(ex)
    end
    n = length(ex.args)
    args = Array(Any, n)
    for i = 1:n
        args[i] = lcparse(T, ex.args[i], symdict)
    end
    eval(expr(ex.head, args))
end
# TODO?: "soft" constraints, e.g., y <= max (x1,x2) using
#     x1 <= z
#     x2 <= z
#     y <= z
# + penalty on z.
# This is tricky from an indexing standpoint, and really in a different category,
# because the penalty would have to be adjusted by the user to enforce the
# constraint.

type LinearIndexExpr{T}
    indx::Vector{Int}
    coef::Vector{T}
    rhs::T
end
LinearIndexExpr{T}(::Type{T}, syms::Dict{Symbol, Int}, sym::Symbol) = LinearIndexExpr([get(syms, sym, -1)], [one(T)], zero(T))

(+){T}(l::LinearIndexExpr{T}, n::Number) = LinearIndexExpr(l.indx, l.coef, l.rhs+n)
(+){T}(n::Number, l::LinearIndexExpr{T}) = l+n
(*){T}(l::LinearIndexExpr{T}, n::Number) = LinearIndexExpr(l.indx, n*l.coef, n*l.rhs)
(*){T}(n::Number, l::LinearIndexExpr{T}) = l*n
function (+){T}(l1::LinearIndexExpr{T}, l2::LinearIndexExpr{T})
    indx = Array(Int, 0)
    coef = Array(T, 0)
    ind1 = l1.indx
    ind2 = l2.indx
    i1 = 1
    i2 = 1
    ii1 = ind1[i1]
    ii2 = ind2[i2]
    while i1 <= length(ind1) || i2 <= length(ind2)
        if ii1 < ii2
            push(indx, ii1)
            push(coef, l1.coef[i1])
            i1 += 1
            ii1 = i1 > length(ind1) ? typemax(Int) : ind1[i1]
        elseif ii1 > ii2
            push(indx, ii2)
            push(coef, l2.coef[i2])
            i2 += 1
            ii2 = i2 > length(ind2) ? typemax(Int) : ind2[i2]
        else
            push(indx, ii1)
            push(coef, l1.coef[i1] + l2.coef[i2])
            i1 += 1
            i2 += 1
            ii1 = i1 > length(ind1) ? typemax(Int) : ind1[i1]
            ii2 = i2 > length(ind2) ? typemax(Int) : ind2[i2]
        end
    end
    LinearIndexExpr(indx, coef, l1.rhs+l2.rhs)
end
(-){T}(l::LinearIndexExpr{T}) = LinearIndexExpr(l.indx, -l.coef, -l.rhs)
(-){T}(l1::LinearIndexExpr{T}, l2::LinearIndexExpr{T}) = l1 + (-l2)
(-){T}(l::LinearIndexExpr{T}, n::Number) = LinearIndexExpr(l.indx, l.coef, l.rhs-n)
(-){T}(n::Number, l::LinearIndexExpr{T}) = LinearIndexExpr(l.indx, -l.coef, n-l.rhs)


end  # module