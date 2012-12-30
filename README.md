# Graphical layout manager for Julia

This is intended for experiments with graphical layout management in [Julia][Julia]. It's not clear whether this has a long-term future as a standalone repository, or whether it will be integrated into other packages. For now, it's separate just to avoid breaking things in those other packages.

## Rough sketch of "vision"

1. Implement the "flexible core," probably based on a linear programming model such as the [Auckland Layout Model][ALM]. This will support figures as vector-graphics files (svg, pdf, etc), and impose very few built-in constraints on layout. We may also want to support other optimizers besides linear programming. If they can't run quickly, they may not be suitable for real-time window resizing, but they could be used to create figures for publication.
2. Find out whether the flexible core can be directly used for window resize events via callbacks (main targets might be Tk and HTML5/CSS). If not, then we probably need a raw representation that directly exposes the toolkit's manager, and then for SVG/PDF/etc we may need to mimic the toolkit's behavior in the context of the flexible core (yuck).
3. Figure out how to integrate this into [Compose][Compose] and/or [Winston][Winston].

## Examples of layout

[Image1](http://postimage.org/image/s6pskvknf/) challenges:

1. Marginal axes must be aligned with the axes of the scatterplot
2. The image must not look squashed or stretched along any axis
3. Image is aligned with the scatterplot
4. Adequate space for all labels, without overlapping other elements

## Status

There's a first draft of a working manager, based on linear programming. The test file "simple.jl" should run and produce reasonable results.

The LP interface is based on [SymbolicLP](https://github.com/timholy/SymbolicLP.jl).

[Julia]: http://julialang.org "Julia"
[Compose]: https://github.com/dcjones/compose
[ALM]: https://www.cs.auckland.ac.nz/courses/compsci705s2c/lectures/geraldpapers/reading1_LutterothStrandhWeber.pdf
[Winston]: https://github.com/nolta/Winston.jl
