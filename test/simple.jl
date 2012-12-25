# API demo
# This is a stripped-down version for the layout here: http://postimage.org/image/s6pskvknf/
# See scatter_image.jl for a more comprehensive implementation. This one
# is here to provide a relatively simple test-case for early development.
# It cuts several corners:
#    hard-codes the image size as 384x512
#    hard-codes the minimum space needed for the axis labels
#    uses pixels for all measurements

require("Layout")
using Layout

# Create a fake window
win = Window(0, 0, 800, 600)

# Create the overall layout inside win. This is specified in terms of named tabstops. 
l = LayoutLP(win,
         [:scatterL, :scatterR, :margeEL, :margeER, :imageL, :imageR],
         [:margeNT, :margeNB, :scatterT, :scatterB, :buttonsT])

# Create a sub-layout for the buttons
# After the parent, the next two arguments refer to parent coordinates.
# The last two arguments introduce tab stops in the child
# lbuttons = LayoutLP(l, [:W, :E], [:buttonsT, :S], [:cancelL, :cancelR, :doneL], [])

# Now specify the geometry. This is done by adding constraints and penalties. Note that a "subplot" function would take care of many of these for you, but here we're going low-level because this GUI has a lot of custom requirements.

# First we require that the tabstops are in increasing order. Can also use "decreasing". One can pick out a subset of the tab stops and do something different for the rest (partial ordering)
increasing(l, l.xsyms)
l = increasing(l, l.ysyms)
# Now add particular constraints
l = addconstraints(l,
        # Ensure the proper aspect ratio for the image
        :(384*(imageR-imageL) == 512*(scatterB-scatterT)),
        # Leave enough room for scatterplot y labels
        :(scatterL-W > 40),
        # Scatterplot bottom label
        :(buttonsT-scatterB > 40),
        # Ensure a small gap between east marginal axis and the image axis
        :(imageL > margeER + 10)
    )
# Add penalties: these encourage desirable behavior, but are not strictly enforced
# l = addpenalties(l,
#         # we'd like the image to occupy approximately 40% of the horizontal space
#         :(5*abs((imageR-imageL)-0.4*w)),
#         # small gaps for the marginal axes
#         :(10*abs(margeEL-scatterR-5)),
#         :(10*abs(margeNS-scatterT-5)),
#     )

parse(l)
