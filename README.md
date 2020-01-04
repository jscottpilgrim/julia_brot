# julia_brot

Explore the mandelbrot and julia sets

## Requirements

- `jdk-11.0.3+`
- `jruby-9.2.9.0+`
- `propane gem`

Currently you can ignore `illegal reflective access` warnings

## Start

Navigate to directory containing julia_brot.rb and run:

`jruby julia_brot.rb`

## Controls

- Arrow keys: move image
- Z: zoom in
- X: zoom out
- R: reset to standard mandelbrot
- D: activate or deactivate double precision shaders. Higher precision is necessary to zoom farther than ~0.00005, but frame rate will drop (significantly! likely to single digits)
- P: pause loop animation
- Y: print to console the characteristics of current fractal

Mandelbrot View Only:
- Left Click: view the julia set of the seed clicked in mandelbrot
- Right Click: starting seed of a julia loop animation. a red line will be drawn to your mouse position, click again for an animated loop between the starting and ending julia seeds
