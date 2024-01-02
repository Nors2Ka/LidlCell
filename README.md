# LidlCell
A minimally working FreeCell game, written from scratch with Odin and SDL2.

To build it use `odin build . -vet`. This will build in the same directory, so you should add `-out:path` for that. To run you have to have `SDL2.dll` in the same directory.

## About
Almost no functions were used semi-intentionally, for 90% of the work it wasn't necessary since things didn't repeat too much, but at the very end it was obvious that things like card placing could have been pulled out to ease up many parts of the code. If I were to make this into a polished thing I would definetely need to do that, but at this point I'd rather move onto something else.
