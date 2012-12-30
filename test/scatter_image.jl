# API demo
# This is for the layout here: http://postimage.org/image/s6pskvknf/

require("LayoutLP")
using LayoutLP

# Create a fake window
win = Window(0, 0, 800, 600)

# Create the overall layout inside window "win". This is specified in terms of named tabstops.
xtabs = [:scatterL, :scatterR, :margeEL, :margeER, :imageL, :imageR]
ytabs = [:margeNT, :margeNB, :scatterT, :scatterB, :buttonsT]
l = LayoutLP(win, xtabs, ytabs)

# Now we'd probably do something like this:
cimage = canvas(l, [:imageL, :imageR], [:scatterT, :scatterB])
himage = image(cimage, "peppers.png")
# ... and then rely on height(himage) and width(himage) to give us the image dimensions.
# But because the canvas & image functionality is not yet worked out,
# let's do it this way:
imsz = [384,512]
height = () -> imsz[1]
width = () -> imsz[2]
# These are only nominally hard-coding the image size; you could change
# imsz[1] or imsz[2] and it would update to the new dimensions.

# For plot axes, the "outer" canvas include all labels, the "inner" canvas is the graphing area
outerscatter, innerscatter = plotaxis(l, [:scatterL, :scatterR], [:scatterT, :scatterB])
outermargE, innermargE = plotaxis(l, [:margeEL, :margeER], [:scatterT, :scatterB])
outermargN, innermargN = plotaxis(l, [:scatterL, :scatterR], [:margeNT, :margeNB])

# Create a sub-layout for the buttons
# The first two refer to parent coordinates, the second introduce tab stops in the child
lbuttons = LayoutLP(l, [:W, :E], [:buttonsT, :S], [:cancelL, :cancelR, :doneL], [])

# Create the image object inside the image canvas, so we have something to refer to in getting its height and width
himg = image(cimg)   # note: no image data yet, all we need now is the handle

# Now specify the geometry. This is done by adding constraints and penalties. Note that a "subplot" function would take care of many of these for you, but here we're going low-level because this GUI has a lot of custom requirements.

# First we require that the tabstops are in increasing order. Can also use "decreasing". One can pick out a subset of the tab stops and do something different for the rest (partial ordering)
increasing(l, l.xsyms)
l = increasing(l, l.ysyms)
# Now add particular constraints
l = addconstraints(l,
        # Ensure the proper aspect ratio for the image
        :(height($himg)*(imageR-imageL) = width($himg)*(scatterB-scatterT)),
        # Leave enough room for scatterplot y labels
        :(left($outerscatter) > W),
        :(left($outermargN) > W),
        # Scatterplot bottom label
        :(bottom($outerscatter) < buttonsT),
        # Ensure a small gap between east marginal axis and the image axis
        :(imageL > margeER + max(10px, 5mm))
    )
# Add penalties: these encourage desirable behavior, but are not strictly enforced
l = addpenalties(l,
        # we'd like the image to occupy approximately 40% of the horizontal space
        :(5*abs((imageR-imageL)-0.4*w)),
        # small gaps for the marginal axes
        :(10*abs(margeEL-scatterR-5px)),
        :(10*abs(margeEL-scatterR-5px)),
    )
