@rem This runs the GBARM tool to make the ROM file work on the real hardware

gbarm\gbarm -v -t"CROUTONS" -cAGBP -mSM tetris4k.gba

gbarm\gbarm -i tetris4k.gba

pause
