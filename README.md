# Croutons for Gameboy Advance, 2002

A smooth-motion Tetris game for Gameboy Advance written in pure ARM Thumb assembly in under 4k uncompressed for the 2002 GBAEmu competition (where it took 2nd place).

The main code is in `Tetris4k.s`. The other files are build-related and small scripts to create the assets.

https://github.com/Clafou/GBA-Croutons/assets/992689/ab3259e5-cc51-4c4a-84f1-3988ab32d1f9

# Original text
```
                      ...Croutons...

                  All code and graphics
                   by Sébastien Molines
                       a.k.a. Clafou


This Tetris clone is my first creation for the
Gameboy Advance console.


I attempted to add smooth animation to the classic Tetris
game. The pieces move pixel by pixel and you can also see
them spin (if you're quick enough to notice). I used the
Gameboy Advance's rotation features to achieve this, and
also its alpha-blending features when pieces are blown up.


I did all the programming in ARM Thumb assembly language
to make the file as small as possible. If you'd like to
take a look you will be able to find the source code at
[redacted].


The graphics aren't much to look at, but the font is over
ten years old (I made it and used it originally for demos
on the Atari ST, under the name of Bigfoot/MJJ).


I haven't had the chance to test this on a real Gameboy
Advance. I hope it does work. If I do get the chance, I
might make a new version with improvements, for example
if the colors don't come out well.


Sébastien (clafou@[redacted])
```
