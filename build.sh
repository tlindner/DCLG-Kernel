#!/bin/sh

lwasm lgk.asm --decb -olgk.BIN --list=lgk.lst
decb dskini LGK.DSK
decb copy -2b lgk.BIN LGK.DSK,LGK.BIN
decb copy -t lgk.bas LGK.DSK,LGK.BAS
