require("SymbolicLP")
module Layout
using SymbolicLP
import SymbolicLP.addconstraints, SymbolicLP.addobjective, SymbolicLP.lpparse, SymbolicLP.lpsolve
import Base.ref

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
width(w::Window) = w.width
height(w::Window) = w.height
syms(w::Window) = [:N, :S, :E, :W]

# function ref(win::Window, s::Symbol)
#     if s == :N
#         return win.y
#     elseif s == :W
#         return win.x
#     elseif s == :S
#         return win.y+win.height
#     elseif s == :E
#         return win.x+win.width
#     elseif s == :h
#         return win.height
#     elseif s == :w
#         return win.width
#     else
#         error("Symbol ", s, " not recognized")
#     end
# end
# xsyms(win::Window) = [:W, :E]
# ysyms(win::Window) = [:N, :S]

type LayoutLP <: AbstractLayout
    parent::AbstractLayout
    parentx::Vector{Symbol}  # x-tabstops in parent defining borders of this layout
    parenty::Vector{Symbol}
    sym::LPBlock             # symbolic LPBlock for both x- and y-tabstops
    lookup::Dict{Symbol,Int} # lookup from symbols to (solved) tabstops
    tabs::Vector{Float64}    # location of x,y tab stops (solution of LP)
    children::Vector
end

function LayoutLP(win::Window, xs::Vector{Symbol}, ys::Vector{Symbol})
    l = LayoutLP(win,
            [:W, :E],
            [:N, :S],
            lpcheck(xs, ys)...
        )
    addconstraints(l.sym, :(W == 0),
                          :(N == 0),
                          :($(xs[1]) >= W),
                          :($(ys[1]) >= N),
                          :($(xs[end]) <= E),
                          :($(ys[end]) <= S),
                          :(soft(E-W == $width($win), 1.0)),
                          :(soft(S-N == $height($win), 1.0)))
    l
end
LayoutLP(win::Window, xs::Vector, ys::Vector) = LayoutLP(win, convert(Vector{Symbol}, xs), convert(Vector{Symbol}, ys))

LayoutLP(parent::AbstractLayout, px::Vector{Symbol}, py::Vector{Symbol}, xs::Vector{Symbol}, ys::Vector{Symbol}) = LayoutLP(parent,
    checksyms(syms(parent), px),
    checksyms(syms(parent), py),
    lpcheck(xs, ys)...
)
LayoutLP(parent::AbstractLayout, px::Vector, py::Vector, xs::Vector, ys::Vector) = LayoutLP(parent,
    convert(Vector{Symbol}, px),
    convert(Vector{Symbol}, py),
    convert(Vector{Symbol}, xs),
    convert(Vector{Symbol}, ys))

ref(l::LayoutLP, s::Symbol) = l.tabs[l.lookup[s]]
function ref(l::LayoutLP, S::Array{Symbol})
    R = similar(S, Float64)
    i = 1
    for s in S
        R[i] = l.tabs[l.lookup[s]]
        i += 1
    end
    R
end

syms(l::LayoutLP) = l.sym.syms
# xsyms(l::LayoutLP) = l.xsyms
# ysyms(l::LayoutLP) = l.ysyms

function lpcheck(xs::Vector{Symbol}, ys::Vector{Symbol})
    xs = vcat(:W, xs, :E)
    ys = vcat(:N, ys, :S)
    s = checkunique(vcat(xs, ys))
    (LPBlock(s),
     Dict{Symbol, Int}(s, 1:length(s)),
     fill(nan(Float64), length(s)),
     Array(LayoutLP, 0)
    )
end

function checkunique(syms::Vector{Symbol})
    if length(unique(syms)) < length(syms)
        error("Duplicated symbols in ", syms)
    end
    syms
end
# function checkparent(parent::Window, syms::Vector{Symbol})
#     for i = 1:length(syms)
#         if !contains((:N,:S,:E,:W), syms[i])
#             error("Cannot find ", syms[i], " in parent")
#         end
#     end
#     syms
# end
function checksyms(psyms::Vector{Symbol}, syms::Vector{Symbol})
    for i = 1:length(syms)
        if !contains(psyms, syms[i])
            error("Cannot find ", syms[i], " in parent")
        end
    end
    syms
end

function increasing(l::LayoutLP, syms::Vector{Symbol})
    if isempty(syms)
        return
    end
    args = Array(Any, 2*length(syms)-1)
    args[1:2:end] = syms
    args[2:2:end] = :(<)
    addconstraints(l, expr(:comparison, args))
end

addconstraints(l::LayoutLP, ex::Expr...) = addconstraints(l.sym, ex...)
addobjective(l::LayoutLP, ex::Expr) = addobjective(l.sym, ex)

# function addtabsx(l::LayoutLP, s::Symbol...)
#     if !isempty(s)
#         # TODO: check that these are different from any existing x,y tabstops
#         l.xtabs = vcat(l.xtabs, s...)
#         l.parsed = false
#     end
# end
# addtabsy

function getlayoutslp(l::LayoutLP)
    lpb = LPBlock[l.sym]
    llp = LayoutLP[l]
    for c in l.children
        if isa(c, LayoutLP)
            clpb, cllp = getlayouts(c)
            append!(lpb, clpb)
            append!(llp, cllp)
        end
    end
    lpb, llp
end

# This should generally be called only for the top-level LayoutLP
function lpparse(l::LayoutLP)
    lpb, llp = getlayoutslp(l)
    lpp, chunks = lpparse(Float64, lpb...)
    stuffer = p -> begin
        ilpb = 1
        for this in llp
            this.tabs = p[chunks[ilpb]]
            ilpb += 1
        end
    end
    lpp, stuffer
end

function lpsolve(lpp::LPParsed{Float64}, stuffer::Function)
    lpd = lpeval(lpp)
    z, p, flag = lpsolve(lpd)
    if flag != 0
        s = IOString()
        SymbolicLP.LinProgGLPK.print_linprog_flag(s, flag)
        error(bytestring(s))
    end
    stuffer(p)
    nothing
end

export Layout, LayoutLP, Window, addconstraints, addobjective, increasing, lpparse, lpsolve

end
