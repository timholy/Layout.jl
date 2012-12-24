# Graphical layout manager for Julia

This is intended for experiments with graphical layout management in [Julia][Julia]. It's not clear whether this has a long-term future as a standalone repository, or whether it will be integrated into other packages. For now, it's separate just to avoid breaking things in those other packages.

## Rough sketch of "vision"

1. Implement the "highly flexible" core, probably based on a linear programming model such as the [Auckland Layout Model][ALM]. This will allow support for generating figures as files (svg, pdf, png, etc) with very few constraints. TODO: find out whether this core can be directly used for window resize events via callbacks.
2. Implement representations of toolkit layout managers, hopefully as special cases of the flexible core. Main targets might be Tk and HTML5/CSS (someone besides me should probably do the latter).
3. Figure out how to integrate this into [Compose][Compose] and/or [Winston][Winston].

[Julia]: http://julialang.org "Julia"
[Compose]: https://github.com/dcjones/compose
[ALM]: https://www.cs.auckland.ac.nz/courses/compsci705s2c/lectures/geraldpapers/reading1_LutterothStrandhWeber.pdf
[Winston]: https://github.com/nolta/Winston.jl
