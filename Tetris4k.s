@ 4-kb Tetris game by Sébastien Molines, May 2002


	.equ _DelayDieFull, 10		@ Waiting time during which you're allowed to control the piece when "dying" (piece blocked from going down)
	.equ _BufferMapLines, 4		@ Lines kept above the visible area in the map
	.equ _AreaXBegin, 12		@ X-coordinate of the leftmost tetris area in the map
	.equ _MaxPieceY, 24*8		@ Lowest line coordinate
	.equ _Char_Tile, 0			@ Tile number for the beginning of the fonts
	.equ _CharOTile, 15			@ Tile number for character "O"
	.equ _Char1Tile, 32			@ Tile number for character "1"
	.equ _PalettePieces, 1		@ Starting palette number for tetris blocks
	.equ _PaletteText, 10		@ Palette number for text
	.equ _PaletteNumbers, 11	@ Palette number for score and level numbers
	.equ _AcceleratorSpeed, 255	@ Acceleration for down key
	.equ _BangsPerLevel, 10		@ Number of times you need to bring lines down to move up a level
	.equ _YNext,7				@ Line number at which to display the next piece
	.equ _YLevel,16				@ Line number at which to display the level
	.equ _YScore,19				@ Line number at which to display the score
	.equ _XSideText, 3			@ Column at which to display next, score and level
	.equ _InitialPieceX, 8*(3+_AreaXBegin)	@ X coordinate at which new pieces appear
	.equ _InitialPieceY, 8*1	@ Y coordinate at which new pieces appear


@ --------------------
@ --- Allows multiboot
    .GLOBAL    __gba_multiboot
__gba_multiboot:
@ --------------------




@ ====================
@       Inits
@ ====================


.GLOBAL     AgbMain
AgbMain:

        adr    r0,1f + 1                @ add r0,pc,#1 also works here
                                        @  for those that want to conserve labels.
        bx     r0

	.THUMB                          @ ..or you can use .CODE 16 
1:

									@ Debug: Here ends up at 80001c8 (was 8000208, god knows what happened)





@ --- Disables all sprites for now

	bl	VSync						@ Not sure it's needed, but since I read that sprites are disabled outside of VBL...
	bl	DisableAllSprites


@ --- Creates the gradient palettes


@ r0: Working reg
@ r1: Palette destination pointer (BG)
@ r2: Palette destination pointer (Sprites)
@ r3: Red   (0...31)
@ r4: Green (0...31)
@ r5: Blue  (0...31)
@ r6: Loop counter
@ r7: Source colors (bytes, 0xFF means end)

	ldr r1,=0x05000000	@ BG palette
	ldr r2,=0x05000200	@ Sprite palette
	ldr r7,=Colors

OnePal:					@ --- Loop start

	ldrb r3,[r7,#0]		@ Reads R
	cmp  r3,#0xFF		@ Tests for the end byte
	beq  PalDone
	ldrb r4,[r7,#1]		@ Reads G
	ldrb r5,[r7,#2]		@ Reads B
	add  r7,#3			
	mov r6,#16

PalLoop:				@ --- Loop start
	mov r0,r5
	lsl r0,#5
	add r0,r4
	lsl r0,#5
	add r0,r3			@ r0 now a GBA palette entry
	strh r0,[r1]		@ Stores in the BG palette
	strh r0,[r2]		@ Stores in the sprite palette
	add	r1,#2
	add	r2,#2

	add r3,#1			@ Brightens R
	cmp r3,#31
	ble ROk
	mov r3,#31
ROk:add r4,#1			@ Brightens G
	cmp r4,#31
	ble GOk
	mov r4,#31
GOk:add r5,#1			@ Brightens B
	cmp r5,#31
	ble BOk
	mov r5,#31
BOk:
	sub r6,#1
	bne PalLoop			@ --- Loop end
	b	OnePal

PalDone:				@ --- Loop end



@ --- Creates the font tiles

@ Uses:
@ r0 = Pointer to source
@ r1 = Pointer to destination
@ r2 = Work register: 8-bit line
@ r3 = Work register: generated tile line
@ r4 = Loop counter for pixels
@ r5 = Loop counter for lines
@ r6 = Loop counter for characters
@ r7 = Rotate value
@ r8 = Used to hold the previous line for the shadow effect

	ldr r0,=Font
	ldr r1,=0x06000000	@ Tile memory address
	mov r7,#4
	mov r6,#41			@ Number of characters

FontCharLoop:			@ --- Loop start
	mov r2,#0
	mov r8,r2			@ Clears the shadow
	mov r5,#7			@ Number of lines

FontLineLoop:			@ --- Loop start
	ldrb r2,[r0]		@ Reads one line
	add r0,#1			@ Increments the pointer
	lsl	r2,#24			@ Shifts to the most significant byte
	mov r3,#0			@ Clears the register
	mov r4,#8			@ Number of pixels

FontPixelLoop:			@ --- Loop start
	add	r2,r2			@ Shifts the source. C = bit shifted out
	bcc BlankBit		@ 0: Do nothing
	add r3,#12 			@ 1: Sets bits 2&3 in the 4-bit value

BlankBit:
	ror r3,r7			@ Shifts to the next 4-bit pixel
	sub	r4,#1
	bne	FontPixelLoop	@ --- Loop end

	mov r2,r3			@ Need to back this up
	add	r3,r8			@ Adds the shadow
	lsr r2,#4+2			@ Prepares the next shadow: shifted to the right and in bit 0&1
	mov r8,r2			@ Keeps the next shadow value

	stmia r1!,{r3}		@ Stores the line

	sub	r5,#1
	bne	FontLineLoop	@ --- Loop end

	mov	r3,#0			@ Blank line
	add	r3,r8			@ Adds the shadow
	stmia r1!,{r3}		@ Stores the line

	sub	r6,#1
	bne	FontCharLoop	@ --- Loop end



@ --- Creates the other tiles
@ Runs with:
@ r1 = Tile memory

	@ - Solid tile

	ldr r3,=0x11111111			@ Value for one line of the tile
	mov r2,#8					@ 8 lines
	bl	ClearLoop				@ Copie this repeated value into VRAM

	@ - Tetris tile

	ldr r0,=TetrisTile
	bl  CopyBlock




@ --- Prepares the sprite blocks

@ r0: Source pointer (either a blank tile, or the tetris-block tile)
@ r1: Destination pointer (the sprite memory)
@ r2: Pointer to the tetris-block tile
@ r3: Work register for copy
@ r4: The tetris piece in 16-bit binary (gets shifted)
@ r5: Loop counter for bits
@ r6: Pointer to the binary tetris blocks
@ r7: Loop counter for sprites
@ r8: Pointer to the blank tile


	ldr r3,=BlankTile
	mov r8,r3
	ldr r2,=TetrisTile
	mov	r7,#7*4
	ldr r6,=Pieces
	ldr r1,=0x06010000		@ Sprite tile memory address


OneSprite:			@ --- Loop start
	mov r5,#16
	ldrh r4,[r6]	@ Reads the binary value
	lsl	r4,#16		@ Shifts the 16 bits into the high halfword
	add	r6,#2

OneBit:				@ --- Loop start

	mov r0,r8		@ By default, we take the blank block
	add	r4,r4		@ Gets bit 31 in flag C and shifts
	bcc Blank		@ C is set?
	mov r0,r2		@ Yes: we take the tetris block
Blank:		
	bl	CopyBlock	@ Copies the tile

	sub r5,#1
	bne OneBit		@ --- Loop end

	sub r7,#1
	bne OneSprite	@ --- Loop end







@ --- Initializes r7, which will never change from now on

	ldr r7,=Variables


@ --- Sets BG0 and BG1

	ldr	r4,=0x04000000
	ldr r1,=0b0000001000000011	@ BG0
								@ 00: Size=256x256 (32x32 tiles)
								@ 0: Overflow off
								@ 00010: Map address offset 0x1000 (to 0x1800)
								@ 0: 16 colors per tile
								@ 0: Mosaic off
								@ 00: Unused bits
								@ 00: Tile data offet 0
								@ 11: Lowest priority
	strh r1,[r4,#8]
	mov  r1,#_BufferMapLines*8
	strh r1,[r4,#0x12]			@ BG1 Y-scroll value

	ldr r1,=0b1000001100000010	@ BG1
								@ 10: Size=256x512 (32x64 tiles)
								@ 0: Overflow off
								@ 00011: Map address offset 0x1800 (to 0x2800)
								@ 0: 16 colors per tile
								@ 0: Mosaic off
								@ 00: Unused bits
								@ 00: Tile data offet 0
								@ 10: Priority for above BG0
	strh r1,[r4,#0x0A]




@ --- Inits for the introduction

	mov	r0,#0b0001001001			@ Mode 0 1D with BG0+BG1
	lsl r0,#6						@ r0 =0b0001001001000000


	mov r5,#_Text_Intro				@ Text index for the intro




@ --- Pre-game scrolling text


PreGameScrollingText:

@ Runs with:
@ r0 = Wanted video mode
@ r5 = Text pointer

	@ - Clears BG1

	ldr r1,=0x06001800			@ Map address
	mov r2,#4
	lsl r2,#8					@ r2 = 0x400 (0x400 words = 0x1000 bytes to clear)
	bl	ClearMemory

	@ - Changes the video mode

	ldr	r4,=0x04000000
	strh r0,[r4]




@ --- Intro

@ r5 = Text index in the 5-bit buffer
@ r6 = Current line number (8...175)
@ r0-r4,r8 = Used by DisplayString


	mov r0,#5
	mul r5,r0
	str	r5,[r7,#TextStart-Variables]	@ Stores the text index
	mov r6,#8

IntroLoop:

	@ - Changes the line number

	add r6,#1					@ Moves up
	cmp r6,#176					@ Brings back up if necessary
	blt	LineOK
	mov r6,#8
LineOK:

	@ - Sets the new BG1 offset

	ldr	r1,=0x04000000
	strh r6,[r1,#0x16]			@ Y-scroll value

	mov r1,#0x7
	and r1,r6
	bne	IntroLoopEnd

	@ - Our line number is a multiple of 8: we the next line of text

	ldr r1,=0x06001800			@ Map address
	mov r0,r6
	lsr r0,#3					@ Line number/8
	sub r0,#1					@ 1 line above
	lsl r0,#6					@ * 64
	add r1,r0					@ r1 = Line's map address

	mov r2,#16					@ First we clear the line
	bl	ClearMemory
	sub r1,#16*4

	mov r0,r5					@ Then we display the text
	bl	DisplayStringCentered

	@ - If we reached the end of the text, we wrap

	cmp r0,#0					@ 31 = code for wrap
	bne	NoWrap
	ldr	r0,[r7,#TextStart-Variables]	@ Restores the index
NoWrap:
	mov r5,r0

	@ - Copies the line one screen below for transitioning

	ldr r1,=0x06001800			@ Map address
	mov r0,r6
	lsr r0,#3					@ Line number/8
	sub r0,#1					@ 1 line above
	lsl r0,#6					@ * 64
	add r1,r0					@ r1 = Line's map address
	mov r0,r1					@ Restores the source  @TODO: Optimize!

	ldr	r1,=21*64
	add r1,r1,r0				@ Destination is a screen below
	bl	Copy8Words				@ Copies the 1st half of the line
	bl	Copy8Words				@ Copies the 2nd half of the line


	@ - Waits for VBLs and checks the keypad

IntroLoopEnd:

	mov r3,#3					@ Number of VBLs to wait for between moves
	mov r4,#0b01000				@ Mask for the Start button

IntroSyncLoop:
	ldr r0,=0x04000130			@ Keypad register
	ldrh r0,[r0]				@ r0 = Keypad value
	and r4,r0					@ We do an "and" as bit for pressed down = 0
	bl	VSync
	sub r3,#1
	bne	IntroSyncLoop

	cmp r4,#0
	bne	IntroLoop				@ Loops if the Start button hasn't been pressed




@ --- Initializations for a new game

	@ - Initializes the random number generator

@ Runs with:
@ r2 = VCount value

	str r2,[r7,#RandomSeed-Variables]	@ Stores VCount into the seed

	@ - Reinitializes all the variables

	mov r1,r7						@ From Variables
	mov r2,#(VariablesNoWipe-Variables)/4	@ Number of words to clear
	bl	ClearMemory					@ Clears the memory area




@ --- Creates the BG0 map

	ldr r1,=0x06001000			@ Map address
	mov r2,#20+_BufferMapLines	@ Y-counter
	mov r3,#0					@ Two 0 tiles with palette 0
	ldr r4,=0x80299029			@ Two 0x29 tiles, with palettes 8 and 9

FillY:
	mov r0,#_AreaXBegin/2
FillLeft:
	stmia r1!,{r3}
	sub r0,#1
	bne FillLeft

	mov r0,#5
FillMiddle:
	stmia r1!,{r4}
	sub r0,#1
	bne FillMiddle

	mov r0,#11-(_AreaXBegin/2)
FillRight:
	stmia r1!,{r3}
	sub r0,#1
	bne FillRight

	sub r2,#1
	bne FillY

	mov r2,#16*(32-20-_BufferMapLines)	@ Number of copies needed to fill the rest of the map (16*number of remaining lines)
	bl	ClearMemory




@ --- Displays the text

	mov r0,#_Text_Next
	mov r1,#_YNext-2
	bl	DisplayStringWithPos
	mov r1,#_YLevel-1
	bl	DisplayStringWithPos
	mov r1,#_YScore-1
	bl	DisplayStringWithPos
	mov r0,#1
	mov r1,#_YLevel
	bl	DisplayNumber
	mov r0,#0
	mov r1,#_YScore
	bl	DisplayNumber


@ --- Enables BG0, disables BG1, disables fade-out

	mov	r0,#0b0001000101			@ Mode 0 1D with BG0
	lsl r0,#6						@ r0 =0b0001000101000000
	ldr	r4,=0x04000000
	strh r0,[r4]

	add r4,#0x50
	mov r0,#0
	strh r0,[r4]					@ Clears BLDCNT (to disable fade-out)



@ --- Initializes the tetris piece

	mov	r2,#7							@ We want a value within [0;7[
	bl	GetRandom						@ Random value in r0			
	str r0,[r7,#NextPieceType-Variables]@ Stores the Piece type

	b	StartNewPiece






@ ====================
@      Main Loop
@ ====================




InfiniteLoop:


	bl	VSync						@ Synchronizes



@ === Updates the sprite display

@ --- The sprite's attributes 0 to 3

@	ldr r7,=Variables
	ldr r0,[r7,#PieceX-Variables]	@ Reads PieceX
	ldr r1,[r7,#PieceY-Variables]	@ Reads PieceY
	sub r1,#_BufferMapLines*8		@ Substracts for entry from the top of the screen
	mov r2,#0xFF					@ Mask
	and r1,r2						@ Attribute 0

	mov r2,#7
	lsl r2,#24						@ r2 = 0x07000000
	mov r3,#1
	lsl r3,#8						@ r3 = 0x100
	orr r1,r3						@ Rotate on
	strh r1,[r2,#0]					@ Stores attribute 0
	mov r3,#0x80
	lsl	r3,#8						@ r3 = 0x8000
	orr r0,r3
	strh r0,[r2,#2]					@ Stores attribute 1

	ldr r0,[r7,#PieceSpin-Variables]	@ Reads PieceSpin
	lsl r0,#4							@ *16
	ldr r1,[r7,#PieceType-Variables]	@ Reads PieceType
	lsl r1,#6							@ *4*16
	add r0,r1							@ Now r0 is the right tile number
	add r1,#1*64						@ Palettes for pieces start at 1 (*64 as the bits are shifted)
	lsl r1,#6							@ Shifts into the palette bits
	add r0,r1							@ Now r0 is the right attribute 2
	strh r0,[r2,#4]						@ Stores attribute 2


@ --- The rotation animation

	ldr r3,=CosSin					@ Cosine and sine table
	ldr r0,[r7,#SpinAnimOfs-Variables]	@ Reads animation offset
	ldr r1,[r7,#SpinAnimDir-Variables]	@ Reads animation direction
	add r3,r0						@ Adds the offset
	sub r0,#4						@ Decreases the offset (for next time)
	bge SpinAnimOfsOK				@ Check we're within bounds
	mov r0,#0						@ If not, make it within bounds
SpinAnimOfsOK:
	str r0,[r7,#SpinAnimOfs-Variables]	@ Stores the new value

	ldrh r0,[r3,#0]					@ Gets the cosine
	strh r0,[r2,#6+8*0]				@ Stores cos in DX 
	strh r0,[r2,#6+8*3]				@ Stores cos in DMY
	ldrh r0,[r3,#2]					@ Gets the sine
	cmp	r1,#1						@ What's our direction?	
	bne	SpinAnimDirOK				@ 1: do nothing
	neg	r0,r0						@ Else: negates sine
SpinAnimDirOK:
	strh r0,[r2,#6+8*1]				@ Stores sin in DMX 
	neg	r0,r0						@ Negates 
	strh r0,[r2,#6+8*2]				@ Stores -sin in DY






@ --- Checks the A and B buttons (PadSpin)

@ r0 = PadSpin { -1;0;1}
@ r1 = PadSpinRefuse { -1;0;1}
@ r2 = working reg
@ r3 = working reg

@	ldr r7,=Variables
	ldr r1,[r7,#PadSpinRefuse-Variables]	@ Reads PadSpinRefuse


	ldr r2,=0x04000130
	ldrh r2,[r2]		@ r2 = keypad register content
	mov r0,#0
	mov r3,#0b01
	and r3,r2
	bne ButtAUp
	add	r0,#1			@ Button A is down: +1
ButtAUp:
	mov r3,#0b10
	and r3,r2
	bne ButtBUp
	sub	r0,#1			@ Button B is down: -1
ButtBUp:
						@ We now have r0 = PadSpin { -1;0;1}

	mov r2,#0			@ DirectionSpin initialized to 0
	cmp	r0,#0
	bne SpinNotZero
	mov	r1,#0			@ Set PadSpinRefuse to 0 to allow the next button push to operate
	b	SpinDone

SpinNotZero:
	cmp r0,r1
	beq	SpinDone		@ PadSpin == PadSpinRefuse? Then we do nothing

						@ Here the conditions are OK to attempt a spin
	mov r2,r0			@ DirectionSpin set to PadSpin
	mov r1,r0			@ PadSpinRefuse set to PadSpin to not allow another spin until button is released

SpinDone:
	str r2,[r7,#DirectionSpin-Variables]	@ Stores DirectionSpin
	str r1,[r7,#PadSpinRefuse-Variables]	@ Stores PadSpinRefuse




@ === Horizontal move


@ --- Checks the buttons (PadDirectionX and PadDirectionX)

	ldr r2,=0x04000130
	ldrh r2,[r2]		@ r2 = keypad register content
	mov r0,#0
	mov r1,#0
	ldr r3,[r7,#DelayDie-Variables]		@ Reads DelayDie
	add r3,r0							@ Adds zero to it
	ble	PadDone							@ If DelayDie <=0 we force the buttons to zero (we're not allowed to continue playing)

	mov r3,#0b00100000
	and r3,r2
	bne LeftUp
	sub	r0,#1			@ Button Left is down: -1
LeftUp:
	mov r3,#0b00010000
	and r3,r2
	bne RightUp
	add	r0,#1			@ Button Right is down: +1
RightUp:				@ Now r0 = PadDirectionX
	mov r3,#0b10000000
	and r3,r2
	bne DownUp
	add	r1,#_AcceleratorSpeed			@ Button Down is down: r1+=1
DownUp:					@ Now r0 = PadDirectionX
						@     r1 = PadDirectionY

PadDone:
	str r0,[r7,#PadDirectionX-Variables]	@ Stores PadDirectionX
	str r1,[r7,#PadDirectionY-Variables]	@ Stores PadDirectionY


@ --- Sets DirectionX
@     If PadDirectionX is null (i.e pad is released), we leave DirectionX unchanged unless we're on an even X position. That's to continue sliding into an aligned position.
@     Otherwise we just set DirectionX to the value of PadDirectionX

	ldr r2,[r7,#PieceX-Variables]		@ Reads PieceX
	mov r3,#0b0111						@ Mask
	and r2,r3							@ Keeps only the 3 low bits
	bic r2,r0							@ r2 = (LowX)&(NOT PadDirectionX). Gives 1 if PadDirectionX=0 and LowX!=0, 0 in all other cases
	bne SkipDirXStore					@ If result is 0 we leave DirectionX as it was
	str r0,[r7,#DirectionX-Variables]	@ Stores DirectionX
SkipDirXStore:



@ --- Sets DirectionXAmount
@	  If DirectionX  is non-null, we add SpeedX to it

	ldr r0,[r7,#DirectionX-Variables]
	cmp r0,#0
	beq	SkipAmountXInc
	ldr r0,[r7,#DirectionXAmount-Variables]
	ldr r1,[r7,#SpeedX-Variables]
	add r0,r1
	str r0,[r7,#DirectionXAmount-Variables]
SkipAmountXInc:
	

@ --- Sets DirectionYAmount
@	  We just add SpeedY+PadDirectionY to it

	ldr r0,[r7,#PadDirectionY-Variables]
	ldr r1,[r7,#SpeedY-Variables]
	add r1,r0
	ldr r0,[r7,#DirectionYAmount-Variables]
	add r0,r1
	str r0,[r7,#DirectionYAmount-Variables]



@ --- Collision test for spins


CollisionTests:


@	ldr r7,=Variables
	ldr r4,[r7,#PieceX-Variables]		@ Reads PieceX
	ldr r5,[r7,#PieceY-Variables]		@ Reads PieceY
	ldr r6,[r7,#PieceSpin-Variables]	@ Reads PieceSpin
	ldr r0,[r7,#DirectionSpin-Variables]	@ Reads DirectionSpin

	add r6,r0								@ Takes the position (we'll test it now)
	mov r1,#0x03							@ Mask
	and r6,r1								@ Keeps PieceSpin within bounds

	mov	r8,pc							@ Return address
	b	MultipleCollisionTests			@ The collision tests
	b	SpinAllowed						@ Executed only if there was no collison
	b	SpinTestDone					@ Executed otherwise


SpinAllowed:
	str r6,[r7,#PieceSpin-Variables]	@ Saves the new PieceSpin
	ldr r0,[r7,#DirectionSpin-Variables]
	cmp r0,#0
	beq SpinTestDone
	str r0,[r7,#SpinAnimDir-Variables]	@ Sets SpinAnimDir
	mov r0,#CosSinEnd-CosSin-4			@ Offset of the last CosSin pair
	str r0,[r7,#SpinAnimOfs-Variables]	@ Sets SpinAnimOfs
	mov r0,#0
	str r0,[r7,#DirectionSpin-Variables]	@ Sets DirectionSpin to zero so it won't repeat


SpinTestDone:


@ --- Collision test for horizontal moves

@	ldr r7,=Variables
@	ldr r4,[r7,#PieceX-Variables]		@ Reads PieceX
@	ldr r5,[r7,#PieceY-Variables]		@ Reads PieceY
	ldr r6,[r7,#PieceSpin-Variables]	@ Reads PieceSpin


	ldr r1,[r7,#DirectionXAmount-Variables]	@ Reads the amount
	sub r1,#128								@ If it's < minimum we don't move
	blt	HMoveOK
	str r1,[r7,#DirectionXAmount-Variables]	@ Otherwise, stores the next amount

	ldr r0,[r7,#DirectionX-Variables]	@ Reads DirectionX
	add r4,r0							@ Takes the position (we'll test it now)

	mov	r8,pc						@ Return address
	b	MultipleCollisionTests		@ The collision tests
	str r4,[r7,#PieceX-Variables]	@ Executed only if there was no collison (saves the new x)

HMoveOK:



@ --- Collision test for downward moves

	ldr r4,[r7,#PieceX-Variables]		@ Reads PieceX
@	ldr r5,[r7,#PieceY-Variables]		@ Reads PieceY
@	ldr r6,[r7,#PieceSpin-Variables]	@ Reads PieceSpin

	ldr r1,[r7,#DirectionYAmount-Variables]	@ Reads the amount
	sub r1,#128								@ If it's < minimum we don't move
	blt	VMoveOK
	str r1,[r7,#DirectionYAmount-Variables]	@ Otherwise, stores the next amount

	add r5,#1						@ Takes the position (we'll test it now)
	mov	r8,pc						@ Return address
	b	MultipleCollisionTests		@ The collision tests
	b	DownNotStuck				@ Executed only if there was no collison
	mov r2,#1						@ Signals that we are touching the bottom
	b	DownDone					@ Executed otherwise

DownNotStuck:
	str r5,[r7,#PieceY-Variables]	@ Stores the new PieceY
	mov r0,#_DelayDieFull
	str r0,[r7,#DelayDie-Variables]	@ Reinits DelayDie
VMoveOK:
	mov r2,#0						@ Signals that we are not touching the bottom (or are not aware of it)


DownDone:

	ldr r0,[r7,#DirectionXAmount-Variables]
	cmp r0,#128								@ Have we got any more move to do?
	bge	CollisionTests
	ldr r0,[r7,#DirectionYAmount-Variables]
	cmp r0,#128								@ Have we got any more move to do?
	bge	CollisionTests

	cmp r2,#0						@ Are we touching the bottom?
	bne	Dying						@ Yes: Do special tests
InfiniteLoopNear:					@ No:  Loop	
	b InfiniteLoop

Dying:

@ === The piece is touching the bottom!

	ldr r0,[r7,#DelayDie-Variables]			@ Decreases DelayDie
	sub r0,#1								@ Is DelayDie > 0?
	str r0,[r7,#DelayDie-Variables]			@ (we store DelayDie)
	bgt	InfiniteLoopNear					@ Yes: Not dead yet

	ldr r0,[r7,#PieceX-Variables]			@ Reads PieceX
	mov r1,#0x07							@ Mask
	and r0,r1								@ Is PieceX MOD 8 null?
	bne InfiniteLoopNear					@ No: Not dead yet, let it slide into position

@ === The piece is now finished!


@ --- Checks if it's game over (piece finished at the top)

	cmp	r5,#_InitialPieceY+8				@ Compares PieceY to its initial value
	bge	NotOver
	
	
	@ --- Sets everything for game over

	ldr r0,=0x04000050		@ Fading and blending register
	mov r2,#0b11000001		@ (Source1 = BG0, Mode = fade out)
	strh r2,[r0]			@ Stores BLDCNT
	mov r2,#5				@ Fade out amount (can be 0...16 inclusive)
	strh r2,[r0,#4]			@ Stores BLDY

	mov	r0,#0b0001001101			@ Mode 0 1D with BG0+BG1
	lsl r0,#6						@ r0 =0b0001001101000000
	mov r5,#_Text_GameOver			@ Text index for game over
	b	PreGameScrollingText

NotOver:


@ --- Here we store tiles in the game area where our piece is

	ldr r1,[r7,#PieceSpin-Variables]	@ Reads PieceSpin
	bl	GetCurrentPiece16bit			@ Gets the binary source in r0
	ldr r2,[r7,#PieceX-Variables]		@ Reads PieceX
	ldr r1,[r7,#PieceY-Variables]		@ Reads PieceY
	bl	StoreCurrentPiece

@ --- Here we read the game area to know if each of the 4 lines where our piece landed is full

@ Uses:
@ r0 - r3: Wiped by the ReadArea subroutine
@ r4 = Line coordinate
@ r5 = Result

	ldr r4,[r7,#PieceY-Variables]	@ Reads PieceY
	cmp r4,#_MaxPieceY-4*8
	ble WithinLimits
	mov r4,#_MaxPieceY-4*8
WithinLimits:

	mov r0,#_AreaXBegin*8	@ x = PieceX + 0
	mov r1,r4				@ y = PieceY
	bl	ReadArea			@ Calls the read subroutine
	mov r5,r2				@ Saves the result in r5

	mov r0,#(_AreaXBegin+4)*8	@ x = PieceX + 4
	mov r1,r4				@ y = PieceY
	bl	ReadArea			@ Calls the read subroutine
	and r5,r2				@ Does an 'and' with previous result

	mov r0,#(_AreaXBegin+6)*8	@ x = PieceX + 6 (not 8 as we're only 10 blocks wide; it's OK to read some blocks twice)
	mov r1,r4				@ y = PieceY
	bl	ReadArea			@ Calls the read subroutine
	and r5,r2				@ Does an 'and' with previous result

	mvn r5,r5				@ Does a 'not' on r5
							@ Result: r5 = 0x0000ijkl (each letter corresponding to 4 bits)
							@ With i = 0 if line at y+0 is full, not full otherwise
							@      j = 0 if line at y+1 is full, not full otherwise
							@      k = 0 if line at y+2 is full, not full otherwise
							@      l = 0 if line at y+3 is full, not full otherwise


	mov r9,r4				@ Keeps it handy


@ --- Here we check how many lines are full

@ Runs with:
@ r4 = Line number
@ r5 = Binary value representing which of the 4 lines are full (4 bits per line)
@ r9 = Backup: Line coordinate

@ Uses:
@ r2 = Full lines counter
@ r3 = Work register
@ r5 = Binary value representing which of the 4 lines are full (4 bits per line)
@ r6 = Loop counter


	mov r2,#0				@ Inits the full lines counter to zero
	mov r6,#4				@ Inits the counter

CountFullsLoop:				@ --- Loop start
	mov r3,#0xF				@ Mask
	lsl r3,#4*3				@ Mask = 0xF000
	and r3,r5				@ Checks the 4 bits
	bne	ItsNotFull			@ Full line? (Z=0 means it's full)
	add	r2,#1							@ Increments the full line counter
ItsNotFull:
	lsl	r5,#4				@ Gets to the next 4 bits
	sub	r6,#1
	bne	CountFullsLoop		@ --- Loop end

	lsr	r5,#16				@ Restores r5



	str	r2,[r7,#LinesRemoved-Variables]	@ Keeps this safe


	@ - Checks if there's anything to remove

	cmp	r2,#0							@ If no line is full we skip the line removal bit
	bne	DoRemoval
	b	StartNewPiece					@ Couldn't simply do a beq StartNewPiece above as it's out of range)

										@ However, I can take this opportunity to stick a POOL here!

	.POOL								@ BTW I verified the compiler's behaviour with POOLs in debugger: If the same values from a pool are used more than once (i.e. in different instructions), the value is still stored just once, great!


DoRemoval:


	@ - Increments the score

	ldr r0,[r7,#Score-Variables]	@ Reads the score
	add r0,r2						@ Score += number of lines
	str r0,[r7,#Score-Variables]	@ Stores it
	mov r1,#_YScore					@ Line number
	bl	DisplayNumber				@ Displays the score

	@ - Increments the level if necessary

	ldr r0,[r7,#Level-Variables]
	ldr r1,[r7,#BangsForNextLevel-Variables]
	add r1,#1
	cmp r1,#_BangsPerLevel
	blt LevelOK
	mov r1,#0
	add r0,#1
LevelOK:
	str r0,[r7,#Level-Variables]
	str r1,[r7,#BangsForNextLevel-Variables]
	mov r1,#_YLevel					@ Line number
	add r0,#1						@ 1-based
	bl	DisplayNumber				@ Displays the score







@ --- Animation
@ --- Part 1: Create the sprite tiles

@ Runs with:
@ r4 = Pointer to the map
@ r5 = Binary value representing which of the 4 lines are full (4 bits per line)
@ r9 = Backup: Line coordinate

@ Uses:
@ r0 = Pointer to the source tile graphics
@ r1 = Pointer to the sprite memory
@ r2 = Loop counter (both for x and for word copies)
@ r3 = Work register
@ r4 = Pointer to the map
@ r5 = Binary value representing which of the 4 lines are full (4 bits per line)
@ r6 = Loop counter (for y)
@ r8 = Offset added to r1 for targetting the sprite corresponding to the tile's color


	lsr r4,#3				@ Divides y by 8 to obtain the line number
	lsl r4,#6				@ y*32*2
	add r4,#_AreaXBegin*2	@ Adds x*2. Now r4 = (in binary) 0000 0YYY YYXX XXX0
	ldr r0,=0x06001000		@ Address of the beginning of the game area in the map
	add	r4,r0				@ r0 = top-left of our line in the map

	ldr r1,=0x06010000+7*4*16*32	@ Free sprite tile memory address (after the ones allocated to the pieces)
	mov r0,r1						@ Keeps this handy

	mov r2,#0xE				@ See below
	lsl r2,#8				@ Obtained by shift: 0xE00 (7*0x800/4)
	bl	ClearMemory			@ Clears the sprites.
	mov r1,r0				@ Restores the address


	mov	r6,#4				@ Line counter initialized to 4
SpritizeY1:					@ --- Loop start
	mov	r2,#8*8				@ Counter initialized for 8 tiles
	bl	SetSpriteSource		@ Sets the source to blocks if the line is full, otherwise to void
	bl	SpritizeX			@ Subroutine
	add r4,#(32-8)*2		@ Moves to the next line
	sub r6,#1				@ Decreases the line counter
	bne SpritizeY1			@ --- Loop end

	sub	r4,#4*2*32-2*8		@ Moves up 4 lines and right by 8 blocks
	lsr	r5,#4*4				@ Restores r5

	mov	r6,#4				@ Line counter initialized to 4
SpritizeY2:					@ --- Loop start
	mov	r2,#2*8				@ Counter initialized for 2 tiles
	bl	SetSpriteSource		@ Sets the source to blocks if the line is full, otherwise to void
	bl	SpritizeX			@ Subroutine
	add r4,#(32-2)*2		@ Moves to the next line
	sub r6,#1				@ Decreases the line counter
	bne SpritizeY2			@ --- Loop end

	sub	r4,#3*2*32			@ Restores r4 step 1: Moves up 3 lines
	sub	r4,#1*2*32+2*8		@ Restores r4 step 2: Moves up 1 line and left by 8 blocks (2 steps because offset too big)
	lsr	r5,#4*4				@ Restores r5



@ --- Animation
@ --- Part 2: Initialize the sprites variables

@ Runs with:
@ r4 = Pointer to the map
@ r5 = Binary value representing which of the 4 lines are full (4 bits per line)
@ r9 = Backup: Line coordinate

@ Uses:
@ r0 = Work register
@ r1 = Work register
@ r2 = Work register
@ r3 = Loop counter
@ r6 = Pointer to the variables buffer
@ r9 = Backup: Line coordinate

	mov r6,r7
	add	r6,#AnimSpritesXYDxDy-Variables
	mov	r3,#7

InitLayersLoop:				@ --- Loop start

	mov r1,#_AreaXBegin*8	@ X
	lsl	r1,#8				@ 8-bit fraction
	mov r2,r9				@ Y
	sub r2,#_BufferMapLines*8	@ Takes the margin into account
	lsl	r2,#8				@ 8-bit fraction
	stmia r6!,{r1,r2}		@ Stores X and Y

	mov r2,#30		@94
	lsl r2,#4
	bl	GetRandom			@ Random value in r0
	lsr r2,#1				@ Divides by 2
	sub r0,r2				@ Makes it centered on 0
	stmia r6!,{r0}			@ Stores Dx

	mov r2,#42		@89
	bl	GetRandom			@ Random value in r0
	add r0,#50	@100				@ Plus minimum value
	lsl	r0,#3				@ *8
	stmia r6!,{r0}			@ Stores Dy


	sub	r3,#1
	bne	InitLayersLoop		@ --- Loop end

	sub	r6,#4*4*7			@ Restores r6





@ --- Here we scroll down over any full line, thus removing them from the game

@ Runs with:
@ r5 = Binary value ending with 4-bit 0 if the line is full
@ r9 = Backup: Line coordinate

@ Uses:
@ r0 = Pointer to source
@ r1 = Pointer to destination
@ r2 = Loop counter and number of the line being tested (0 to 3 included)
@ r3 = Working register
@ r4 = Line number of the 1st line in our piece area
@ r5 = (Gets shifted) Binary value ending with 4-bit 0 if the line is full
@ r6 = Loop counter for the copy of lines

	mov r4,r9				@ Restores

	lsr r4,#3				@ Divides y by 8 to obtain the line number
	mov r2,#0				@ We start with line 0

DoDownLoop:					@ --- Loop start
	mov r3,#0x0F			@ Mask
	lsl r3,#3*4				@ Result: r3 = 0xF000
	and r3,r5				@ Tests the 4 bits
	bne NotFull				@ Result = 0: Full line, to be deleted


	@ - It's a full line, we copy down over the full line

	mov r0,r4				@ r0 = y
	add r0,r2				@ +r2 for the line of the area containing our block
	mov r6,r4				@ r6 = loop counter

	lsl r0,#6				@ y*=32*2
	add r0,#_AreaXBegin*2	@ Adds x*2. Now r0 = (in binary) 0000 0YYY YYXX XXX0
	ldr r1,=0x06001000		@ Address of the beginning of the game area in the map
	add	r0,r1				@ r0 = top-left of our line in the map
	mov r1,r0				@ Target = source
	sub r0,#64				@ Source moved up one line.

CopyDownLoop:				@ --- Loop start
	bl	Copy5Words			@ Copies the line
	sub r0,#64+5*4			@ Points to the previous line
	sub r1,#64+5*4			@ Points to the previous line
	sub r6,#1
	bne	CopyDownLoop		@ --- Loop end

NotFull:
	lsl r5,#4				@ Shifts the register to test the line above
	add r2,#1				@ Moves to the next line (one row below)
	cmp r2,#4
	bne	DoDownLoop			@ --- Loop end





	@ --- Restores

	mov r6,r7
	add	r6,#AnimSpritesXYDxDy-Variables




@ --- Animation
@ --- Do the sound effect

	@ Info from Audio Advance:
	@	//turn on sound circuit
	@	REG_SOUNDCNT_X = 0x80;
	@	//full volume, enable sound 4 to left and right
	@	REG_SOUNDCNT_L=0x8877;

	ldr	r0,=0x4000060					@ Sound registers
	mov r1,#0x80
	strh r1,[r0,#0x24]				@ Writes REG_SOUNDCNT_X

	mov r1,#0x88
	lsl r1,#8
	add r1,#0x77
	strh r1,[r0,#0x20]				@ Writes REG_SOUNDCNT_L

	@ According to tests in Audio Advance's SoundTest4 ROM in the VisualBoyAdvance emulator (I hope it doesn't sound too bad on the real hardware) I got:
	@ a Sound Length:		0
	@ b Envlp Step Time:	3
	@ c Envlp Step Dir:		0 (descending)
	@ d Envlp Init Vol:		9 to F (depending on the number of lines to remove)
	@ e Frequency Ratio:	7
	@ f Polynomia Step:		0 (15 steps)
	@ g Shift Frequency:	4
	@ h Loop Mode:			0 (loop)
	@ i Sound Reset:		1 (turn it on to play)
	@ That's with
	@           (bits):  FEDCBA9876543210
	@ REG_SOUND4CNT_L =  ddddcbbb00aaaaaa
	@ REG_SOUND4CNT_H =  ih000000ggggfeee

	ldr	r1,[r7,#LinesRemoved-Variables]	@ 1-4 value corresponding to the number of lines
	lsl r1,#5						@ = (Lines*2  )<<4
	add r1,#0x73					@ = (Lines*2+7)<<4 + 3
	lsl r1,#8						@ Shifts into the upper byte
	strh r1,[r0,#0x18]				@ Writes REG_SOUND4CNT_L

	mov r1,#1
	lsl r1,#15						@ Sets bit 15
	add r1,#0x47					@ = 0x8047
	strh r1,[r0,#0x1c]				@ Writes REG_SOUND4CNT_H



@ --- Animation
@ --- Part 3: Do the animation


@ Runs with:
@ r6 = Pointer to the variables buffer
@ r8 = Backup: Binary value representing which of the 4 lines are full (4 bits per line)
@ r9 = Backup: Line coordinate

@ Uses:
@ r0 = Pointer to OAM registers memory
@ r1 = Loop counter
@ r2 = Work register
@ r3 = Work register
@ r4 = (Unused)
@ r5 = Loop counter for frames
@ r6 = Pointer to the variables buffer

	mov r5,#64

AnimFrameLoop:				@ --- Loop start

	bl	VSync				@ Synchronizes
	ldr r0,=0x07000000		@ OAM registers memory
	mov r1,#1				@ Starts with type 1


DisplaySpritesLoop:			@ --- Loop start

	@ - Makes attribute 0

	ldr	r3,[r6,#4*1]		@ Reads Y
	ldr r2,[r6,#4*3]		@ Reads Dy
	sub r2,#21	@43				@ Applies gravity
	str r2,[r6,#4*3]		@ Stores Dy
	sub r3,r2				@ Y -= Dy
	str	r3,[r6,#4*1]		@ Stores Y
	lsr	r3,#8				@ Gets rid of the fraction
	mov r2,#0xFF			@ Mask
	and r3,r2				@ Masks Y

	mov r2,#0b01			@ Type = wide
	lsl r2,#14				@ Moves to bits 14,15
	add r2,r3				@ Adds Y
	strh r2,[r0,#0]			@ 1st sprite's attribute 0
	mov r2,#0b10			@ Type = high
	lsl r2,#14				@ Moves to bits 14,15
	add r2,r3				@ Adds Y
	strh r2,[r0,#8+0]		@ 2nd sprite's attribute 0

	@ - Makes attribute 1

	ldr	r3,[r6,#4*0]		@ Reads X
	ldr r2,[r6,#4*2]		@ Reads Dx
	add r3,r2				@ X += Dx
	str	r3,[r6,#4*0]		@ Stores X
	lsr	r3,#8				@ Gets rid of the fraction
	mov r2,#0xFF			@ Mask = 0FF
	lsl r2,#1				@ Mask = 1FE
	add r2,#1				@ Mask = 1FF
	and r3,r2				@ Masks X

	mov r2,#0b11			@ Size = 64
	lsl r2,#14				@ Moves to bits 14,15
	add r2,r3				@ Adds X
	strh r2,[r0,#2]			@ 1st sprite's attribute 1
	mov r2,#0b10			@ Size = 32
	lsl r2,#14				@ Moves to bits 14,15
	add r2,r3				@ Adds X
	add r2,#8*8				@ x+8*8 for second sprite
	strh r2,[r0,#8+2]		@ 2nd sprite's attribute 1

	@ - Makes attribute 2

							@ Attribute 2 is:
							@ Bit#:    FEDCBA9876543210
							@ Content: LLLLPPTTTTTTTTTT
							@ We need: LLLLPPTTTT000000	(since our T is multiple of 64)
							@ Which can be obtained easily since TTTT = LLLL + 6 (LLLL is 1-7, LLLL is 7-13).
							@ We can just do ((LLLL) * (1000001) + 6) << 6.

	mov r2,#0b1000001		@ Multiplier
	mul r2,r1				@ r2 = LLLL00LLLL
	add r2,#6+0b10000		@ r2 = LLLL01TTTT (the sprite tiles we've made start at 7*64 because our rotated elements are stored from 0 to 7*64-1 - The 01 is for priority 1)
	lsl r2,#6				@ r2 = LLLL01TTTT000000. That's attribute 2!
	strh r2,[r0,#4]			@ 1st sprite's attribute 2
	add r2,#32				@ For the 2nd sprite, adds 32 to the tile number
	strh r2,[r0,#8+4]		@ 2nd sprite's attribute 2


	add r0,#8*2				@ Next pair of sprites
	add r6,#4*4				@ Next pair of sprite variables
	add r1,#1
	cmp r1,#7
	ble	DisplaySpritesLoop	@ --- Loop end


	@ - Shakes the screen

	ldr r2,=Spring
	mov r3,#64
	sub r3,r5
	cmp	r3,#SpringEnd-Spring
	blt	SpringIndexOK
	mov r3,#SpringEnd-Spring-1

SpringIndexOK:
	ldrb r2,[r2,r3]				@ Reads the value (centered around 128 with oscillation)
	ldr	r3,[r7,#LinesRemoved-Variables]
	mul	r2,r3					@ Multiplies by the number of lines
	lsr	r2,#4					@ Divides by 16
	lsl	r3,#3					@ r3 *= 8
	sub r2,r3					@ Substracts to oscillate around zero
	add r2,#_BufferMapLines*8 	@ Adds the margin (we don't start at 0)
	ldr r3,=0x04000000			@ Video registers
	strh r2,[r3,#0x12]			@ Stores the Y-scroll register


	@ - Sets the alpha-blending

	ldr r0,=0x04000050		@ Alpha-blending register
	mov r2,#0b0010000101
	lsl r2,#6
	add r2,#0b10000			@ r2 = 0b0010000101010000 (Source1 = Sprites, Source2 = BG0+Backdrop, Mode = alpha-blend)
	strh r2,[r0]			@ Stores BLDCNT
	mov	r2,r5				@ The loop counter
	lsr r2,#2				@ Coeff1 (in [0,16])
	mov r3,#16				@ Maximum value = 16
	sub r3,r2				@ Coeff2 (16-Coeff1)
	lsl r3,#8				@ Moves Coeff2 into bits 8...12
	add r3,r2				@ Moves Coeff1 into bits 0...4
	strh r3,[r0,#2]			@ Stores BLDALPHA


	@ - End of the animation loop

	sub r6,#4*4*7			@ Restores r6
	sub	r5,#1
	bne	AnimFrameLoop		@ --- Loop end






@ --- Animation finished


	@ - Video cleanup

	bl	DisableAllSprites	@ Disables all the sprites we've created

	mov r2,#0				@ Setting for turning alpha-blending off
	strh r2,[r0]			@ Stores BLDCNT


	@ - Turns off the sound circuit (to save batteries)

	ldr	r0,=0x4000060			@ Sound registers
	mov r1,#0
	strh r1,[r0,#0x24]			@ Writes REG_SOUNDCNT_X





@ === Starts with the next piece

StartNewPiece:

@ --- Initializes the speeds


	ldr r0,[r7,#Level-Variables]
	lsl r0,#2						@ *4
	mov r1,#128
	add r1,r0
	str r1,[r7,#SpeedX-Variables]

	lsl r0,#2						@ *2 (i.e. *8 as was already *4)
	mov r1,#64
	add r1,r0
	str r1,[r7,#SpeedY-Variables]





	mov r0,#_DelayDieFull
	str r0,[r7,#DelayDie-Variables]		@ Reinits DelayDie

	mov r0,#_InitialPieceX
	str r0,[r7,#PieceX-Variables]		@ Inits X
	mov r0,#_InitialPieceY
	str r0,[r7,#PieceY-Variables]		@ Inits Y
	mov r0,#0
	str r0,[r7,#PieceSpin-Variables]	@ Inits spin

	ldr r0,[r7,#NextPieceType-Variables]@ Reads NextPieceType
	str r0,[r7,#PieceType-Variables]	@ And makes it the current PieceType
	mov	r2,#7							@ We want a value within [0;7[
	bl	GetRandom						@ Random value in r0			
	str r0,[r7,#NextPieceType-Variables]@ Stores the Piece type

	mov r4,r0							@ Keeps piece type (for upcoming call to StorePiece)


@ --- Erases the old next piece

	ldr r0,=0x06001000
	mov r1,#32*7+4
	add r1,r1
	add	r1,r0,r1
	add r0,#_AreaXBegin*2
	mov r5,#6
EraseLoop:
	bl	Copy3Words
	sub r0,#3*4
	add r1,#64-3*4
	sub r5,#1
	bne EraseLoop

@ --- Displays the next piece

	mov r0,r4							@ r0 = type
	mov r1,#0							@ r1 = spin
	bl	GetPiece16bit					@ Returns the binary piece in r0
	mov r2,#8*5							@ r2 = x
	mov r1,#8*(4+4)						@ r1 = y (also r4= type)
	bl	StorePiece						@ Displays the piece




	b InfiniteLoop










@ ===================
@     Subroutines 
@ ===================






@ --- VBL Synchronization

@ Uses:
@ r0 = Pointer to the video control memory
@ r1 = Work register
@ r2 = VCount value (will be used initialize the random generator)

VSync:

	ldr r2,[r7,#VCount-Variables]
	add r2,#1
	str r2,[r7,#VCount-Variables]

	ldr r0,=0x04000000
VBLEndWait:					@ In case we are still inside a VBlank period, waits until it ends
	ldrh r1,[r0,#6]
	cmp r1,#160
	bge VBLEndWait
VBLWait:					@ Waits until we reach the Vblank period
	ldrh r1,[r0,#6]
	cmp r1,#160
	blt VBLWait
	bx	lr



@ --- Disables all sprites

@ Uses:
@ r1 = Attribute 0 value to disable a sprite
@ r2 = Loop counter (used as offset too)
@ r3 = Pointer to the OAM memory

DisableAllSprites:

	ldr r3,=0x07000000		@ OAM registers memory
	mov r1,#0x2F			@ r1 = 0b101111
	lsl r1,#4				@ r1 = 0b1011110000 (y=240, D=1, R=0, i.e. turned off)
	mov r2,#127				@ r2 = 127 (start at sprite 127)
	lsl r2,#3				@ r2 = 127*8 (start at offset 127*8)
DisableLoop:
	strh r1,[r3,r2]
	sub r2,#8
	bge	DisableLoop
	bx	lr





@ --- Subs used when creating sprites from tiles (when lines have been completed)

@ Uses:
@ r0 = Pointer to the source tile graphics
@ r1 = Pointer to the sprite memory
@ r2 = Loop counter (both for x and for word copies)
@ r3 = Work register
@ r4 = Pointer to the source map
@ r5 = Binary value representing which of the 4 lines are full (4 bits per line)
@ r6 = Loop counter (for y)
@ r8 = Offset added to r1 for targetting the sprite corresponding to the tile's color

@ This sets the source depending on value of r5 & 0xF000

SetSpriteSource:
	ldr r0,=BlankTile		@ Default source: the blank tile
	mov r3,#0x0F			@ Mask
	lsl r3,#3*4				@ Result: r3 = 0xF000
	and r3,r5				@ Tests the lower 4 bits
	bne NotFullLine			@  =0: Do nothing, the line won't be removed
	ldr r0,=TetrisTile		@ !=0: Sets the source to the Tetris block tile
NotFullLine:
	lsl	r5,#4				@ Shifts r5 to be ready for the next line
	bx	lr

@ This deals with one line

SpritizeX:					@ --- Loop start
	ldrh r3,[r4]			@ Reads the map entry
	add	r4,#2				@ Increments the pointer
	lsr	r3,#12				@ Gets the palette number
	sub r3,#1				@ Starts from zero
	lsl r3,#11				@ Multiplies by 2048 (that's the memory we're taking for each of the 7 color layers)
	add	r1,r3				@ Adds the offset
	mov r8,r3				@ Keeps it handy
CopyLoop:					@ --- Loop start
	ldmia r0!,{r3}			@ Reads
	stmia r1!,{r3}			@ Stores
	sub r2,#1				@ Decreases the loop counter
	mov r3,#0x7				@ Mask
	and r3,r2				@ r3 = loop counter MOD 8
	bne CopyLoop			@ --- Loop end
	sub r0,#8*4				@ Restores the source pointer
	mov r3,r8				@ Restores the offset
	sub	r1,r3				@ Removes the offset: our pointer is now ready for the next tile as it has been incremented by the stmias.
	cmp r2,#0
	bne SpritizeX			@ --- Loop end
	bx	lr







@ --- Collision test

@ Called with:
@ r4 = PieceX
@ r5 = PieceY
@ r6 = PieceSpin
@ r7 = Variables
@ r8 = Return address

@ Uses:
@ r0 - r3: Wiped by the ReadArea subroutine
@ r6 = Combined background results
@ r9 = Backup storage of PieceSpin

MultipleCollisionTests:

	mov r9,r6		@ Backs up PieceSpin

	add r0,r4,#0	@ With x = x+0
	add r1,r5,#0	@ With y = y+0
	bl	ReadArea	@ Calls the read subroutine
	mov r6,r2		@ Saves the result in r6

	add r0,r4,#0	@ With x = x+0
	add r1,r5,#7	@ With y = y+7
	bl	ReadArea	@ Calls the read subroutine
	orr	r6,r2		@ Does an 'or' with previous result

	add r0,r4,#7	@ With x = x+7
	add r1,r5,#0	@ With y = y+0
	bl	ReadArea	@ Calls the read subroutine
	orr	r6,r2		@ Does an 'or' with previous result

	add r0,r4,#7	@ With x = x+7
	add r1,r5,#7	@ With y = y+7
	bl	ReadArea	@ Calls the read subroutine
	orr	r6,r2		@ Does an 'or' with previous result

	mov r1,r9					@ Copies PieceSpin to r1 (for the call)
	bl	GetCurrentPiece16bit	@ Call returns the current piece in r0
	mov r1,#1					@ Default value to add to return address =1 (for Thumb code)
	and r0,r6					@ The collision test
	beq NoCollision
	mov r1,#3					@ Collision: Value to add to return address = 3 (2 to skip the save instruction + 1 for Thumb code)

NoCollision:

	mov r6,r9		@ Restores PieceSpin
	add	r8,r1		@ Updates the return address
	bx	r8			@ Jumps to the return address (skipping the first instruction if collision)

















@ --- Linear congruential random number generator

GetRandom:

@ Called with:
@ r2 = Ceiling: return a random value within [0;r2[
@ r7 = Variables
@ Uses:
@ r0 = Result
@ r1 = Working register

	ldr r0,[r7,#RandomSeed-Variables]	@ Reads the seed
	ldr r1,=25173						@ Multiplier
	mul r0,r1							@ We do the multiply
	ldr r1,=13849						@ Increment
	add r0,r1							@ We add the increment
	lsl r0,#16							@ Modulus = 65536
	lsr r0,#16							@ We apply the modulus by erasing the top halfword using shifts
	str r0,[r7,#RandomSeed-Variables]	@ Stores the seed
	mul r0,r2							@ Multiplies to obtain a number within [0;r2[
	lsr r0,#16							@ Result: [0;r2[
	bx	lr								@ Returns






@ --- Copies in memory

@ r0: Pointer to source
@ r1: Pointer to destination
@ r3: Working register

CopyBlock:
Copy8Words:
	ldmia r0!,{r3}
	stmia r1!,{r3}
	ldmia r0!,{r3}
	stmia r1!,{r3}
	ldmia r0!,{r3}
	stmia r1!,{r3}
Copy5Words:
	ldmia r0!,{r3}
	stmia r1!,{r3}
	ldmia r0!,{r3}
	stmia r1!,{r3}
Copy3Words:
	ldmia r0!,{r3}
	stmia r1!,{r3}
	ldmia r0!,{r3}
	stmia r1!,{r3}
	ldmia r0!,{r3}
	stmia r1!,{r3}
	bx  lr




@ --- Clears memory

@ r1: Pointer to destination
@ r2: Number of loops
@ r3: Working register

ClearMemory:
	mov r3,#0
ClearLoop:
	stmia r1!,{r3}
	sub r2,#1
	bne ClearLoop
	bx  lr






@ --- Returns a 16-bit value representing the current piece

@ Called with:
@ r7 = Variables:
@ r1 = PieceSpin
@ r0 = Piece type (for calls to GetPiece16bit only)
@ Uses:
@ r0 = Result register
@ r1 = Work register

GetCurrentPiece16bit:
	ldr r0,[r7,#PieceType-Variables]	@ Reads PieceType

GetPiece16bit:
	lsl r0,#2							@ *4
	add r0,r1
	add r0,r0							@ *2 (stored as 16-bit values)
	ldr r1,=Pieces
	ldrh r0,[r1,r0]						@ Reads the value
	bx  lr




@ --- Reads a 4x4 section in the game area, returned as a 16-bit value

@ Called with:
@ r0 = x
@ r1 = y
@ Uses:
@ r0 = Pointer to map area
@ r1 = Work register
@ r2 = Result register
@ r3 = Loop counter


ReadArea:

	lsr r0,#3			@ Divides x by 8
	lsr r1,#3			@ Divides y by 8
	lsl r1,#5			@ Occupies bits 5 to 9 
	add r0,r1			@ r0 = (in binary) 0000 00YY YYYX XXXX

	mov r2,#0			@ Clears the result register
	mov r3,#4*4			@ Inits the counter

	ldr r1,=0x06001000	@ Address of the beginning of the game area in the map
	add r0,r0			@ *2
	add	r0,r1			@ r0 = top-left of our piece area in the map

ReadLoopY:				@ --- Loop start
ReadLoopX:				@ --- Loop start

	lsl r2,#1			@ Shifts the bits collected
	ldrh r1,[r0]		@ Reads the map value
	add r0,#2			@ Moves the pointer to the next map value

	lsr r1,#12			@ Gets the palette number
	cmp r1,#8			@ Is it an occupied tile?
	bge IsFree			@ No:  Leaves bit 0 clear
	add r2,#1			@ Yes: Sets bit 0

IsFree:
	sub r3,#1			@ Decreases the loop counter
	mov r1,#0x3			@ Mask
	and r1,r3			@ r1 = loop counter MOD 4
	bne ReadLoopX		@ --- Loop end

	add r0,#(32-4)*2	@ Moves to the next line

	cmp r3,#0
	bne ReadLoopY		@ --- Loop end

	bx  lr



@ --- Extracts a 5-bit value from the data starting at Text5Bit

@ Called with:
@ r0 = Number (multiple of 5) of bits from the start
@ r8 = Return address

@ Uses:
@ r2-r3 = Work registers

@ Returns:
@ r2 = 5-bit value


Get5BitValue:
	mov r2,r0
	lsr r2,#3		@ r2 = P
	ldr r3,=Text5Bit
	add r2,r3		@ r2 = pointer to byte at offset P
	ldrb r3,[r2,#1]		@ r3 = byte at offset P+1
	ldrb r2,[r2]		@ r2 = byte at offset P
	lsl r2,#8
	orr r2,r3		@ r2 = (byte at offset P)<<8 + (byte at offset P+1)

	mov r3,#0x7
	and r3,r0		@ r3 = p
	sub r3,#11		@ r3 = (p-11)
	neg r3,r3		@ r3 = 11-p

	lsr r2,r3		@ >>(11-p)
	mov r3,#0b011111
	and r2,r3		@ r3 = our 5-bit value

	add r0,#5		@ Increments the pointer for the next time

	mov r3,#1
	add r8,r3
	bx	r8			@ Returns



@ --- Displays text

@ Called with:
@ r0 = String address
@ r1 = Target y coordinate in blocks (DisplayStringWithPos)
@ r1 = Target map line address (DisplayStringCentered)

@ Uses:
@ r0 = Pointer to the text
@ r1 = Pointer to the map
@ r2 = Work register
@ r3 = Work register
@ r4 = Loop counter

DisplayStringWithPos:

	mov r8,pc
	b	Get5BitValue		@ Reads the value (number of chars) into r2
	mov r4,r2				@ Keeps it in r4

	lsl r1,#6				@ y*32*2
	add r1,#_XSideText*2	@ + x*2

	ldr r2,=0x06001000		@ Address of the beginning of the game area in the map
	add r1,r2				@ r1 = Destination
	b ContinueDisplayString


DisplayStringCentered:

	mov r8,pc
	b	Get5BitValue		@ Reads the value (number of chars) into r2@ Reads the value (number of chars) into r2

	cmp r2,#31				@ Was it 31 (wrap)?
	bne	NotWrapSignal
	mov r0,#0				@ Yes: sets r0 to zero
	bx	lr					@      and returns

NotWrapSignal:

	cmp	r2,#0				@ Was it 0 (blank line)?
	beq	StringDone			@ Yes: returns

	mov r4,r2				@ Number of characters to display

	lsr r2,#1				@ Prepares the centering
	lsl r2,#1				@
	add r1,#15*2			@ x += 15
	sub r1,r2				@ x -= (n/2)... Centered!

ContinueDisplayString:

StringLoop:

	mov r8,pc
	b	Get5BitValue		@ Reads the value into r2
	mov r3,#_PaletteText	@ Palette index
	lsl r3,#12				@ Palette in its own bits
	add r3,#_Char_Tile		@ r3 = Tile value with the tile number set to the first character
	add r2,r3				@ Makes it a character tile
	strh r2,[r1]			@ Stores
	add r1,#2				@ Increments
	sub r4,#1
	bne	StringLoop

StringDone:
	bx	lr







@ --- Displays a number, right-aligned

@ Called with:
@ r0 = Number
@ r1 = Line number
@ Uses:
@ r0 = Number (gets divided by 10)
@ r1 = Work register
@ r2 = Work register
@ r3 = Target pointer


DisplayNumber:

	ldr r3,=0x06001000			@ Address of the tile map
	add r3,#18					@ Offset
	lsl r1,#6					@ *64
	add r3,r1					@ Points to the target in the map

DispNumLoop:

@ Division by 10 - From ARM's documentation "ARM7TDMI Data Sheet (ARM DDI 0029E)"
@ takes argument in r0
@ returns quotient in r0, remainder in r1
	MOV r1, r0
	LSR r2, r0, #2
	SUB r0, r2
	LSR r2, r0, #4
	ADD r0, r2
	LSR r2, r0, #8
	ADD r0, r2
	LSR r2, r0, #16
	ADD r0, r2
	LSR r0, #3
	LSL r2, r0, #2	@ Originally ASL r2, r0, #2 but compiler gives error
	ADD r2, r0
	LSL r2, #1		@ Originally ASL r2, #1 but compiler gives error
	SUB r1, r2
	CMP r1, #10
	BLT 0f
	ADD r0, #1
	SUB r1, #10
0:

	add r1,#_CharOTile				@ Makes it a tile number for O
	cmp r1,#_CharOTile				@ Was it number 0?
	beq	Num0						@ We're fine with letter O for zero
	add r1,#_Char1Tile-_CharOTile-1	@ Make it a number tile
Num0:

	mov r2,#_PaletteNumbers			@ Palette index
	lsl r2,#12						@ Palette in its own bits
	orr r1,r2						@ Palette bits in r1

	strh r1,[r3]					@ Stores the tile
	sub r3,#2						@ Moves to the previous tile

	cmp r0,#0						@ Any more digits to display?
	bne	DispNumLoop					@ Yes: loop

	bx	lr












@ === StorePiece: Writes the piece into BG0

@ Called with:
@ r0 = Binary source register
@ r1 = Target y coordinate in pixels
@ r2 = Target x coordinate in pixels
@ r4 = Piece type (for calls to StorePiece only)
@ Uses:
@ r0 = Binary source register (gets shifted)
@ r1 = Work register
@ r2 = Pointer to map area
@ r3 = Loop counter
@ r4 = Map entry for a part of the piece

StoreCurrentPiece:
	ldr r4,[r7,#PieceType-Variables]	@ Reads PieceType

StorePiece:
	add r4,#1							@ Piece palettes start at 1
	lsl r4,#12							@ Shifts into the right bits
	add r4,#42							@ r4 = tile value (tile=42, palette=PieceType+1)

	lsr r2,#3							@ Divides x by 8
	lsr r1,#3							@ Divides y by 8
	lsl r1,#5							@ Occupies bits 5 to 9 
	add r2,r1							@ r0 = (in binary) 0000 00YY YYYX XXXX

	lsl r0,#16							@ Moves 16-bit value into the high hword
	mov r3,#4*4							@ Inits the counter

	ldr r1,=0x06001000					@ Address of the beginning of the game area in the map
	add r2,r2							@ *2
	add	r2,r1							@ r2 = top-left of our piece area in the map

StoreLoopY:								@ --- Loop start
StoreLoopX:								@ --- Loop start

	add r0,r0							@ Shifts the bits (gets the top bit in flag C)
	bcc	IsZero							@ Branches if C = 0
	strh r4,[r2]						@ Writes the map value

IsZero:

	add r2,#2							@ Moves the pointer to the next map value

	sub r3,#1							@ Decreases the loop counter
	mov r1,#0x3							@ Mask
	and r1,r3							@ r1 = loop counter MOD 4
	bne StoreLoopX						@ --- Loop end

	add r2,#(32-4)*2					@ Moves to the next line

	cmp r3,#0
	bne StoreLoopY						@ --- Loop end
	bx  lr




	.POOL

	.ALIGN(4)


@ --- Tile graphics

TetrisTile:
	.word 0x5FFFFFFC
	.word 0x16FFFFDB
	.word 0x118634BB
	.word 0x117775BB
	.word 0x118795BB
	.word 0x118778BB
	.word 0x1111116B
	.word 0x11111115



@ --- My Tetris pieces (in their 4 spun versions) described in binary.
@     Break each hword into 4 parts and you can see the shape.

Pieces:
	.hword 0b0000011001100000	@ Square
	.hword 0b0000011001100000
	.hword 0b0000011001100000
	.hword 0b0000011001100000

	.hword 0b0000111001000000	@ 'T' shape
	.hword 0b0010011000100000
	.hword 0b0000001001110000
	.hword 0b0000010001100100

	.hword 0b0000000011110000
	.hword 0b0100010001000100	@ Bar (vertical)
	.hword 0b0000111100000000
	.hword 0b0010001000100010

	.hword 0b0000011011000000	@ 's' shape
	.hword 0b0100011000100000
	.hword 0b0000001101100000
	.hword 0b0000010001100010

	.hword 0b0000110001100000	@ Inverted 's' shape
	.hword 0b0010011001000000
	.hword 0b0000011000110000
	.hword 0b0000001001100100

	.hword 0b0000111000100000
	.hword 0b0010001001100000
	.hword 0b0000010001110000
	.hword 0b0000011001000100	@ 'r' shape

	.hword 0b0000001011100000
	.hword 0b0100010001100000
	.hword 0b0000011101000000
	.hword 0b0000011000100010	@ Inverted 'r' shape



@ --- Cosine and sine values used for the sprite rotation
@     Obtained by calculating round(256*sin(angle))

CosSin:
	.hword 0x100, 0x000		@     0
	.hword 0x0ED, 0x062		@  pi/8
	.hword 0x0B5, 0x0B5		@ 2pi/8
	.hword 0x062, 0x0ED		@ 3pi/8

@	.hword 0x100, 0x000		@     0
@	.hword 0x0DE, 0x080		@  pi/6
@	.hword 0x080, 0x0DE		@ 2pi/6

CosSinEnd:


Spring:
	.byte 79
	.byte 43
	.byte 25
	.byte 24
	.byte 39
	.byte 66
	.byte 97
	.byte 128
	.byte 152
	.byte 168
	.byte 172
	.byte 168
	.byte 158
	.byte 145
	.byte 134
	.byte 128
SpringEnd:


SNext:
	.byte 5
	.byte 14,5,24,20,29		@ Next:

	.byte 6
	.byte 12,5,22,5,12,29	@ Level:

	.byte 6
	.byte 19,3,15,18,5,29	@ Score:



@ --- Colors uses to create gradient palettes

Colors:
	.byte	0,0,0		@  0: Background
	.byte	8,6,19		@  1: Piece 0 (square)
	.byte	23,13,0		@  2: Piece 1 (T shape)
	.byte	23,1,1		@  3: Piece 2 (bar)
	.byte	0,17,13		@  4: Piece 3 (s shape)
	.byte	0,11,18		@  5: Piece 4 (inverted s shape)
	.byte	21,21,7		@  6: Piece 5 (r shape)
	.byte	16,9,23		@  7: Piece 6 (inverted r shape)
	.byte	7,6,13		@  8: Vertical bar 1
	.byte	8,7,14		@  9: Vertical bar 2
	.byte	12,12,12	@ 10: Font 1
	.byte	16,9,23		@ 11: Font 2
	.byte	0xFF		@ Terminator


@ --- My old font

Font:
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000

	.byte 0b00000111
	.byte 0b00001111
	.byte 0b00011011
	.byte 0b00110011
	.byte 0b00111111
	.byte 0b01100011
	.byte 0b01100011

	.byte 0b01111100
	.byte 0b01100110
	.byte 0b01100010
	.byte 0b01111110
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01111110

	.byte 0b00011110
	.byte 0b00110001
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01100001
	.byte 0b00111110

	.byte 0b01111000
	.byte 0b01101100
	.byte 0b01100110
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01111110

	.byte 0b00111110
	.byte 0b01100001
	.byte 0b01100000
	.byte 0b01111111
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b00111111

	.byte 0b00111110
	.byte 0b01100011
	.byte 0b01100000
	.byte 0b01111100
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01100000

	.byte 0b00011110
	.byte 0b00110000
	.byte 0b01100000
	.byte 0b01101111
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00111110

	.byte 0b00100001
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01111111
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100011

	.byte 0b00001100
	.byte 0b00000100
	.byte 0b00001100
	.byte 0b00001100
	.byte 0b00001100
	.byte 0b00001100
	.byte 0b00001100

	.byte 0b00000111
	.byte 0b00000011
	.byte 0b00000011
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00110011
	.byte 0b00011110

	.byte 0b01100001
	.byte 0b01100011
	.byte 0b01100110
	.byte 0b01101000
	.byte 0b01111100
	.byte 0b01110110
	.byte 0b01100011

	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01000011
	.byte 0b01111110

	.byte 0b01000001
	.byte 0b01100011
	.byte 0b01111111
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100011

	.byte 0b01100010
	.byte 0b01110011
	.byte 0b01111011
	.byte 0b01101111
	.byte 0b01100111
	.byte 0b01100011
	.byte 0b01100001

	.byte 0b00011100
	.byte 0b00110010
	.byte 0b01100001
	.byte 0b01100001
	.byte 0b01100001
	.byte 0b01100011
	.byte 0b00111110

	.byte 0b01111100
	.byte 0b01000110
	.byte 0b01100011
	.byte 0b01111110
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01100000

	.byte 0b00011100
	.byte 0b00110010
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100010
	.byte 0b01100000
	.byte 0b00111111

	.byte 0b01111100
	.byte 0b01100110
	.byte 0b01100011
	.byte 0b01111110
	.byte 0b01100100
	.byte 0b01100010
	.byte 0b01100011

	.byte 0b00011110
	.byte 0b00110000
	.byte 0b01100000
	.byte 0b00111110
	.byte 0b00000011
	.byte 0b01100011
	.byte 0b00111110

	.byte 0b01111111
	.byte 0b00001100
	.byte 0b00011000
	.byte 0b00011000
	.byte 0b00011000
	.byte 0b00011000
	.byte 0b00011000

	.byte 0b01100010
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100110
	.byte 0b01111100

	.byte 0b01100110
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00110110
	.byte 0b00011100
	.byte 0b00001000

	.byte 0b01100011
	.byte 0b01100011
	.byte 0b01101011
	.byte 0b01111111
	.byte 0b01110111
	.byte 0b01100011
	.byte 0b01000001

	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00110110
	.byte 0b00011100
	.byte 0b00110110
	.byte 0b01100011
	.byte 0b01100011

	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00110011
	.byte 0b00011110
	.byte 0b00001100
	.byte 0b00011000
	.byte 0b00110000

	.byte 0b00111111
	.byte 0b01000011
	.byte 0b00000110
	.byte 0b00001100
	.byte 0b00011000
	.byte 0b00110001
	.byte 0b01111111

	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00110000
	.byte 0b00110000
	.byte 0b00100000

	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00011000
	.byte 0b00011000

	.byte 0b00110000
	.byte 0b00110000
	.byte 0b00100000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000

	.byte 0b00011000
	.byte 0b00011000
	.byte 0b00011000
	.byte 0b00011000
	.byte 0b00000000
	.byte 0b00010000
	.byte 0b00011000

	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00000000
	.byte 0b00111100
	.byte 0b00111110
	.byte 0b00000000
	.byte 0b00000000

	.byte 0b00111100
	.byte 0b00001100
	.byte 0b00001100
	.byte 0b00001100
	.byte 0b00001100
	.byte 0b00001100
	.byte 0b00111111

	.byte 0b00111110
	.byte 0b00000011
	.byte 0b00000011
	.byte 0b00111110
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01111111

	.byte 0b00111110
	.byte 0b00000011
	.byte 0b00000011
	.byte 0b00111110
	.byte 0b00000011
	.byte 0b00000011
	.byte 0b00111110

	.byte 0b01100000
	.byte 0b01100010
	.byte 0b01100110
	.byte 0b01100110
	.byte 0b01111111
	.byte 0b00000110
	.byte 0b00000110

	.byte 0b01111110
	.byte 0b01100000
	.byte 0b01100000
	.byte 0b01111110
	.byte 0b00000011
	.byte 0b00000011
	.byte 0b01111110

	.byte 0b00001100
	.byte 0b00011000
	.byte 0b00110000
	.byte 0b00111110
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00111110

	.byte 0b01111111
	.byte 0b00000011
	.byte 0b00000110
	.byte 0b00001100
	.byte 0b00001100
	.byte 0b00011000
	.byte 0b00011000

	.byte 0b00111110
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00111110
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00111110

	.byte 0b00111110
	.byte 0b01100011
	.byte 0b01100011
	.byte 0b00111110
	.byte 0b00000110
	.byte 0b00001100
	.byte 0b00011000


@ --- Text in 5-bit buffer

Text5Bit:

.equ _Text_Next, 0
	.equ _Text_Level, 5
	.equ _Text_Score, 11
	.equ _Text_GameOver, 17
	.equ _Text_Intro, 58
	.byte 35,139,138,21,133,177,88,89,141,242
	.byte 42,142,22,148,15,177,101,224,1,112
	.byte 145,103,48,78,129,149,27,71,130,12
	.byte 14,64,19,133,46,7,211,255,255,255
	.byte 255,255,240,30,229,96,222,210,138,143
	.byte 72,228,250,209,238,159,128,159,255,255
	.byte 255,255,255,128,11,132,139,57,130,116
	.byte 12,168,122,60,16,96,114,0,2,180
	.byte 66,102,4,204,1,5,11,73,38,96
	.byte 56,90,89,153,242,1,194,210,137,249
	.byte 0,73,96,184,101,2,26,18,20,2
	.byte 200,35,50,136,51,162,74,224,53,236
	.byte 75,139,51,7,139,224,120,97,176,38
	.byte 125,65,99,62,64,162,10,3,62,178
	.byte 2,210,199,139,52,44,228,55,145,46
	.byte 56,6,246,192,180,77,18,247,49,242
	.byte 56,92,157,20,128,22,84,113,4,173
	.byte 175,6,246,128,0,3,210,4,62,5
	.byte 6,95,80,93,44,98,138,229,63,32
	.byte 77,60,0,0,0,111,208,251,130,143
	.byte 4,24,28,252,0,76,36,89,204,20
	.byte 65,100,16,5,196,0,128,42,210,143
	.byte 116,193,71,213,161,89,65,68,20,16
	.byte 73,70,89,130,112,75,184,0,102,179
	.byte 40,40,130,128,50,147,239,48,81,224
	.byte 27,221,73,61,152,162,10,8,36,163
	.byte 44,246,0,184,128,162,10,2,62,238
	.byte 152,101,39,220,20,120,2,49,149,133
	.byte 144,104,85,209,5,76,128,96,177,156
	.byte 0,43,151,215,172,96,14,90,0,213
	.byte 149,16,89,1,38,206,95,80,9,143
	.byte 184,43,0,76,182,44,130,192,49,46
	.byte 44,208,26,1,238,25,124,62,115,128
	.byte 197,16,26,118,96,17,70,26,204,160
	.byte 162,10,9,192,165,38,14,90,76,9
	.byte 112,228,80,204,164,0,77,66,200,20
	.byte 43,174,38,62,255,172,39,176,57,224
	.byte 104,105,66,200,8,125,232,208,187,32
	.byte 98,92,89,129,1,177,64,34,149,210
	.byte 19,31,119,2,176,2,92,10,62,129
	.byte 103,0,0,2,31,255,255,255,255,255
	.byte 255,255,255,255,224,73,228,82,209,46
	.byte 60,205,71,130,136,44,12,246,49,247
	.byte 75,142,8,21,240,97,65,15,255,255
	.byte 255,255,255,255,255,255,255,240,1,31
	.byte 19,18,228,207,224,2,62,103,188,213
	.byte 151,192,4,254,1,160,96,246,252,0
	.byte 79,223,140,156,174,47,220,130,177,143
	.byte 3,10,247,6,68,240,1,31,150,197
	.byte 150,94,226,128,52,3,84,175,128,7
	.byte 248,165,86,151,224,3,191,42,206,96
	.byte 11,136,0,186,159,165,16,23,46,96
	.byte 51,228,9,208,165,104,2,226,85,52
	.byte 152,15,34,134,128,157,97,7,202,128
	.byte 51,228,202,32,160,11,158,208,179,62
	.byte 0,19,250,32,178,44,203,246,177,244
	.byte 152,30,96,49,246,47,128,0,1,95
	.byte 255,255,255,255,255,248,21,68,5,203
	.byte 254,95,89,129,95,255,255,255,255,255
	.byte 248,1,4,128,111,171,8,7,62,128
	.byte 64,108,91,52,36,40,40,132,204,7
	.byte 11,74,11,166,136,125,105,42,32,160
	.byte 52,138,80,72,179,125,100,50,205,193
	.byte 113,1,71,189,147,3,66,66,176,54
	.byte 10,88,17,48,160,22,71,206,112,0
	.byte 106,131,55,184,23,75,22,151,76,0
	.byte 106,138,99,0,210,122,46,84,184,0
	.byte 40,228,82,60,0,229,16,80,26,69
	.byte 40,38,243,82,225,145,64,103,213,196
	.byte 13,18,247,0,23,11,24,10,32,160
	.byte 56,90,81,63,32,9,44,23,12,176
	.byte 33,108,86,62,13,43,168,9,166,133
	.byte 56,107,68,62,83,0,36,22,48,20
	.byte 65,64,26,209,15,148,192,243,60,225
	.byte 105,68,252,128,36,176,92,50,164,173
	.byte 171,3,71,202,96,0,0,10,36,192
	.byte 203,234,11,190,172,32,24,149,148,20
	.byte 125,38,82,130,136,40,38,250,200,101
	.byte 0,222,66,238,57,125,122,198,0,201
	.byte 113,0,154,0,52,112,216,19,62,188
	.byte 52,138,94,26,64,6,18,10,61,235
	.byte 0,73,96,186,129,57,64,243,2,111
	.byte 105,112,243,2,136,40,14,22,148,79
	.byte 200,2,75,5,195,47,103,131,200,161
	.byte 160,5,84,178,159,75,128,98,134,149
	.byte 145,103,187,73,244,13,18,247,5,128
	.byte 156,36,154,22,96,11,136,240,178,8
	.byte 15,196,194,184,137,113,248,0,85,32
	.byte 27,200,82,0,182,44,179,68,37,199
	.byte 2,93,176,201,160,162,42,209,0,51
	.byte 153,90,38,100,12,11,143,80,156,180
	.byte 75,128,249,16,178,5,30,5,148,176
	.byte 5,16,88,25,44,40,38,157,20,19
	.byte 104,88,206,0,24,171,140,249,82,174
	.byte 13,10,204,236,9,2,3,98,187,180
	.byte 164,202,87,2,136,76,193,42,184,15
	.byte 112,40,130,186,69,11,0,128,200,151
	.byte 12,139,225,243,156,4,210,96,101,245
	.byte 0,194,224,5,196,1,146,226,90,136
	.byte 13,0,23,102,136,75,142,4,204,23
	.byte 147,220,121,193,133,12,202,6,22,128
	.byte 105,64,183,62,252,0,0,82,185,79
	.byte 200,249,206,0,195,96,76,250,128,0
	.byte 0,0,15,128


	.ALIGN(4)		@ Not necessary but I think I've read somewhere the file needs to be a multiple of 4 in size so you never know




	.BSS			@ TODO: Find how if this is the right way to declare a real BSS section... Right now instructions and data are accepted in it!

Variables:
NextPieceType:		.ds 2
PieceType:			.ds 2
PieceSpin:			.ds 2
PieceX:				.ds 2
PieceY:				.ds 2
DirectionX:			.ds 2	@ Can be {-1,0,1}
DirectionXAmount:	.ds 2
SpeedX:				.ds 2
SpeedY:				.ds 2
DirectionYAmount:	.ds 2
DirectionSpin:		.ds 2	@ Can be {-1,0,1}
PadDirectionX:		.ds 2	@ Can be {-1,0,1}
PadDirectionY:		.ds 2	@ Can be {   0,2}
PadSpinRefuse:		.ds 2
DelayDie:			.ds 2
SpinAnimOfs:		.ds 2	@ {0,4,8}, gets decreased by 4 until null
SpinAnimDir:		.ds 2   @ {-1,1} depending on DirectionSpin
Score:				.ds 2
Level:				.ds 2
BangsForNextLevel:	.ds 2
LinesRemoved:		.ds 2	@ {0...4}
TextStart:			.ds 2
BlankTile:			.ds 16


VariablesNoWipe:			@ From here is the area we don't want to reset these to zero at each game

VCount:				.ds 2
RandomSeed:			.ds 2
AnimSpritesXYDxDy:	.ds 8*7	@ For each type, 4 words: X, Y, Dx, Dy
