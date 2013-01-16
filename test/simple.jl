# API demo
# This is a stripped-down version for the layout here: http://postimage.org/image/s6pskvknf/
# See scatter_image.jl for a more comprehensive implementation. This one
# is here to provide a relatively simple test-case for early development.
# It cuts several corners:
#    hard-codes the minimum space needed for the axis labels
#    uses pixels for all measurements

require("Layout")
using Layout

# Create a fake window
win = Window(0, 0, 800, 600)

# Create the overall layout inside win. This is specified in terms of named tabstops. 
xtabs = [:scatterL, :scatterR, :margeEL, :margeER, :imageL, :imageR]
ytabs = [:margeNT, :margeNB, :scatterT, :scatterB, :buttonsT]
l = LayoutLP(win, xtabs, ytabs)

# Create a sub-layout for the buttons
# After the parent, the next two arguments refer to parent coordinates.
# The last two arguments introduce tab stops in the child
# lbuttons = LayoutLP(l, [:W, :E], [:buttonsT, :S], [:cancelL, :cancelR, :doneL], [])

# Specify image dimensions
imsz = [384,512]
imheight = () -> imsz[1]
imwidth = () -> imsz[2]
# These are only nominally hard-coding the image size; you could change
# imsz[1] or imsz[2] and it would update to the new dimensions.

# Now specify the geometry. This is done by adding constraints and penalties. Note that a "subplot" function would take care of many of these for you, but here we're going low-level because this GUI has a lot of custom requirements.

# First we require that the tabstops are in increasing order. One can pick out
# a subset of the tab stops and do something different for the rest
# (partial ordering)
increasing(l, xtabs)
increasing(l, ytabs)

# Now add particular constraints
addconstraints(l,
        # Ensure the proper aspect ratio for the image
        :($imheight()*(imageR-imageL) == $imwidth()*(scatterB-scatterT)),
        # Leave enough room for scatterplot y labels
        :(scatterL-W > 40),
        # Scatterplot bottom label
        :(buttonsT-scatterB > 40),
        # Ensure a small gap between east marginal axis and the image axis
        :(imageL > margeER + 10)
    )
# addconstraints(lbuttons, :(S-N > 25))
addconstraints(l, :(S - buttonsT > 25))

# Yet more constraints
addconstraints(l,
        # we want lots of space for the primary displays
        :(soft(imageR-imageL>0.3*(E-W), 1.0)),
        :(soft(scatterR-scatterL>0.4*(E-W), 1.0)),
        # we'd like the marginal axes to be substantially thinner than the scatterplot
        :(soft(margeER-margeEL == (scatterR-scatterL)/3, 1.0)),
        :(soft(margeNB-margeNT == (scatterB-scatterT)/3, 1.0)),
        # small gaps for the marginal axes
        :(margeEL-scatterR>5),
        :(scatterT-margeNB>5)
    )

# Reward leaving as much vertical space as possible
# addobjective(l, :(100*(scatterB-scatterT)))

lpp, stuffer = lpparse(l)
lpsolve(lpp, stuffer)

@show l[xtabs]
@show l[ytabs]
