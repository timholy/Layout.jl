require("ParameterVector")
module Layout
using ParameterVector
import Base.show, Base.parse

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
xsyms(win::Window) = [:W, :E]
ysyms(win::Window) = [:N, :S]

type LPData
    f::Vector{Float64}
    lc::LinearConstraints{Float64}
end
LPData() = LPData(zeros(0), LinearConstraints(Float64))
type LayoutLP <: AbstractLayout
    parent::AbstractLayout
    parentx::Vector{Symbol}  # names of x,y tab stops in parent
    parenty::Vector{Symbol}
    xsyms::Vector{Symbol}    # names of x,y tab stops
    ysyms::Vector{Symbol}
    constraints::Vector{Expr}
    penalties::Vector{Expr}
    parsed::Bool
    xtabs::Vector{Float64}   # location of x,y tab stops
    ytabs::Vector{Float64}
    solved::Bool
    lp::LPData
    children::Vector
end

LayoutLP(win::Window, xs::Vector{Symbol}, ys::Vector{Symbol}) = LayoutLP(win,
    [:W, :E],
    [:N, :S],
    lpcheck(xs, ys)...
)
LayoutLP(win::Window, xs::Vector, ysims::Vector) = LayoutLP(win, convert(Vector{Symbol}, xs), convert(Vector{Symbol}, ysims))

LayoutLP(parent::AbstractLayout, px::Vector{Symbol}, py::Vector{Symbol}, xs::Vector{Symbol}, ys::Vector{Symbol}) = LayoutLP(parent,
    checkparent(xsyms(parent), px),
    checkparent(ysyms(parent), py),
    lpcheck(xs, ys)...
)
LayoutLP(parent::AbstractLayout, px::Vector, py::Vector, xs::Vector, ys::Vector) = LayoutLP(parent,
    convert(Vector{Symbol}, px),
    convert(Vector{Symbol}, py),
    convert(Vector{Symbol}, xs),
    convert(Vector{Symbol}, ys))

xsyms(l::LayoutLP) = l.xsyms
ysyms(l::LayoutLP) = l.ysyms

function lpcheck(xs::Vector{Symbol}, ys::Vector{Symbol})
    xs = vcat(:W, xs, :E)
    ys = vcat(:N, ys, :S)
    checkunique(vcat(xs, ys))
    (xs,
     ys,
     Array(Expr, 0),
     [:(abs(w-parent[w])), :(abs(h-parent[h]))],
     false,
     zeros(length(xs)+2),
     zeros(length(ys)+2),
     false,
     LPData(),
     Array(LayoutLP, 0)
    )
end

function checkunique(syms::Vector{Symbol})
    if length(unique(syms)) < length(syms)
        error("Duplicated symbols in ", syms)
    end
    syms
end
function checkparent(parent::Window, syms::Vector{Symbol})
    for i = 1:length(syms)
        if !contains((:N,:S,:E,:W), syms[i])
            error("Cannot find ", syms[i], " in parent")
        end
    end
    syms
end
function checkparent(psyms::Vector{Symbol}, syms::Vector{Symbol})
    for i = 1:length(syms)
        if !contains(psyms, syms[i])
            error("Cannot find ", syms[i], " in parent")
        end
    end
    syms
end

function increasing(l::LayoutLP, syms::Vector{Symbol})
    if isempty(syms)
        return l
    end
    args = Array(Any, 2*length(syms)-1)
    args[1:2:end] = syms
    args[2:2:end] = :(<)
    addconstraints(l, expr(:comparison, args))
end

function addconstraints(l::LayoutLP, ex::Expr...)
    if !isempty(ex)
        l.constraints = vcat(l.constraints, ex...)
        l.parsed = false
    end
    l
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
    l.lp.lc = LinearConstraints(Float64, vcat(l.xsyms, l.ysyms), l.constraints)
    l
end


export Layout, LayoutLP, Window, addconstraints, increasing

end
