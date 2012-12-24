module Layout
import Base.show

abstract AbstractLayout

# :N, :S, :E, :W refer to the layout north, south, east, and west respectively.
# :h, :w refer to the layout height and width
# inside expressions, drop the :
# :(parent[N]), :(parent[S]), ... refer to parent north, south, ...
# :(parent[h]) and :(parent[w]) are similar
#

# Note: :w may differ from :(parent[w]), if there is no feasible solution for a
# window of that size. For example, if the layout includes a lot of components
# with a minimum size, then there may be no solution for very small windows. In
# this case, the window will simply display the fraction of the layout that fits
# within the boundaries, anchored at the top left. This is a different approach
# from ALM's, but seems a lot more straightforward (in particular, it avoids a lot
# of juggling penalty coefficients).
# The attempt to make the two equal will be via "soft penalties" added to the LP problem,
#     abs(w-parent[w])
#     abs(h-parent[h])
# See the ALM paper for information about adding soft penalties. Note that these
# define what a scale of "1" means in terms of penalty coefficients.
# TOCONSIDER: is there ever a reason to allow these two penalties to have
# different coefficients?? Can't think of why...

# This is just a placeholder for now, to get development going
type Window <: AbstractLayout
    x::Int
    y::Int
    width::Int
    height::Int
end
function ref(win::Window, s::Symbol)
    if s == :N
        return win.y
    elseif s == :W
        return win.x
    elseif s == :S
        return win.y+win.height
    elseif s == :E
        return win.x+win.width
    elseif s == :h
        return win.height
    elseif s == :w
        return win.width
    else
        error("Symbol ", s, " not recognized")
    end
end

type LayoutLP <: AbstractLayout
    parent
    xsyms::Vector{Symbol}  # names of x,y tab stops
    ysyms::Vector{Symbol}
    constraints::Vector{Expr}
    penalties::Vector{Expr}
    parsed::Bool
    xtabs::Vector{Float64} # location of x,y tab stops
    ytabs::Vector{Float64}
    solved::Bool
    lp::LPData
    children::Vector{AbstractLayout}
end

type LPData
    f::Vector{Float64}
    A::Matrix{Float64}
    b::Vector{Float64}
    Aeq::Matrix{Float64}
    beq::Vector{Float64}
    lb::Vector{Float64}
    ub::Vector{Float64}
end
LPData() = LPData(zeros(0), zeros(0,0), zeros(0), zeros(0,0), zeros(0), zeros(0), zeros(0))

LayoutLP(win::Window, xsyms::Vector{Symbol}, ysyms::Vector{Symbol}) = LayoutLP(win,
    vcat(:W, xsyms, :E),
    vcat(:N, ysyms, :S),
    Array(Expr, 0),
    [:(abs(w-parent[w])), :(abs(h-parent[h]))],
    false,
    zeros(length(xsyms)),
    zeros(length(ysyms)),
    false,
    LPData(),
    Array(LayoutLP, 0))


function addconstraints(l::LayoutLP, ex::Expr...)
    if !isempty(ex)
        l.constraints = vcat(l.constraints, ex...)
        l.parsed = false
    end
end

function addtabsx(l::LayoutLP, s::Symbol...)
    if !isempty(s)
        # TODO: check that these are different from any existing x,y tabstops
        l.xtabs = vcat(l.xtabs, s...)
        l.parsed = false
    end
end
# addtabsy

function parse(l::LayoutLP)
end


export Layout, LayoutLP, addconstraints, addpenalties, 

end
