;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  A more dynamic, userfriendlier version of the Creating/Eating Block Sprite
;;     by leod
;;
;;  EXTRA BIT OFF = Creating Block Snake
;;  EXTRA BIT ON  = Eating Block Snake
;;
;;
;;  Comes with a .map16 file to insert on any page (change the defines below if using
;;  a different page than page 5), to be inserted so the tiles fit snuggly in
;;  the bottom right corner.
;;  Feel free to edit how the tiles look and act, the only important thing for this sprite
;;  to work is their position in the map16 table.
;;  They act like normal used blocks/air to everything but this sprite, feel free to change that.
;;
;;  I have included a .dsc file, which contains descriptions for the blocks.
;;  Place it in the same folder as your ROM, and give it the same name (eg "Mariohack.dsc")
;;  If you already have a .dsc file, you can open this file in notepad and copypaste it into
;;  your .dsc file.
;;  If you changed which page the blocks are on, you will have to change the first number (a 5)
;;  in every row to your page number.
;;
;;  IMPORTANT: The sprite can never come in contact with any map16 tiles in the same
;;             positions as the imported ones on a different page, it will treat them
;;             just like the interaction blocks.
;;
;;
;;  The Sprite reacts to the blocks as follows:
;;  [1][2][3][4][5][6][7]
;;
;;  [1] Turn left from its current direction. This means if it's travelling right, it will now move up.
;;  [2] Turn right from its current direction. This means if it's travelling down, it will now move left.
;;  [3] Turn left  when the ON/OFF switch is ON or right when it is OFF.
;;  [4] Turn right when the ON/OFF switch is ON or left  when it is OFF.
;;  [5] Move faster.
;;  [6] Move slower.
;;  [7] Ends the snake, always use this to terminate it, otherwise the sound effect will stay permanently.
;;
;;  The ON/OFF blocks are never generated by the sprites, so they can't go out of synch by
;;  hitting a switch after one part of the duo/trio/however many you have passes one.
;;  This means that you can't use it with multiple snakes in a row and expect them to
;;  travel different paths along the same ON/OFF blocks.
;;  I also recommend ExAnimating them, so the player can actually see what change the ON/OFF
;;  switch causes beforehand.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if !SA1 = 1
	!RAMBank = $40
else
	!RAMBank = $7E
endif

if !EXLEVEL
	!LookupRAM		= $0BF6|!Base2
	!L1_Lookup_Lo	= !LookupRAM+96+96
	!L1_Lookup_Hi	= !LookupRAM+96+96+32
endif

!Map16Page = $03        	;what page did you insert the .map16 on? default is 05
!StandardTile = $0132   	;what map16 tile to generate from creating block, by default used blocks
							;if you change this, I recommend editing the included .map16 to
							;have all the used blocks look (and act) like your block instead
!StandardAir = $0025    	;what map16 tile to generate from eating block, by default thin air

!InitDir = $01          	;initial direction of the snakes, values are:
							 ;0 sprite moves up
							 ;1 sprite moves right
							 ;2 sprite moves down
							 ;3 sprite moves left
							;note that you can place turning blocks right on the tile the snake
							;spawns on to individually change their directions.

!GFXTile = $2E   			;graphics to use for the sprite, used block in SP1 by default
!Props = $20     			;yxppccct props for the sprite, by default:
							;00100000 (no flip, 10 priority, palette 000 (8), tile page 1 (SP1/2))
							;increase priority to 11 if the sprite goes behind any tiles (that'd be $30)

!SFX = $04       			;the sfx to repeatedly play while the sprite is running, grinder sound by default
!SFXBank = $1DFA|!Base2 	;the sfx bank
							;note that most sfx sound dumb when repeated, so only change this if you know
							;what you're doing
							;values can be found at http://smwc.me/t/6665



;don't change these defines. or do, but it won't help much, they're just random sprite tables
!Eating = !160E       ;depending on extra bit, 0 = creating, 1 = eating

!State = !1594        ;0 = don't bother checking for blocks; 1 = check for blocks and spawn

!Direction = !187B    ;sprite direction, directions are as follows:
                        ;0 sprite moves up
                        ;1 sprite moves right
                        ;2 sprite moves down
                        ;3 sprite moves left
                        ;4 sprite does not move

!Speed = !1602        ;sprite speed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite INIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
LDA #$FF
STA $1909|!Base2     ;while this is #$FF, this sprite doesn't move,
                        ;is set to #$00 when mario touches a brown block
LDA #$01             ;initial speed
STA !Speed,x

LDA #$04             ;initial direction (DONT CHANGE, THIS IS THE STANDING STILL DIRECTION)
STA !Direction,x

STZ !State,x

STZ !Eating,x
LDA !7FAB10,x        ; check for extra bit
AND #$04             ; (bit 2 -> %100 -> $4)
BEQ NoExtraIsSet     ; if not set, skip the following
INC !Eating,x
NoExtraIsSet:
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB                     ; \
PHK                     ;  | The same old
PLB                     ; /
JSR MainCode            ;  Jump to sprite code
PLB                     ; Yep
RTL                     ; Return1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


XSpeed:
db $00,$08,$00,$F8,$00
db $00,$10,$00,$F0,$00
db $00,$20,$00,$E0,$00
YSpeed:
db $F8,$00,$08,$00,$00
db $F0,$00,$10,$00,$00
db $E0,$00,$20,$00,$00
;slow
;up, right, down, left, still
;fast

  Return11:
RTS

  MainCode:
JSR SubGFX

LDA $9D             ;if sprites are locked, Return1
BNE Return11

LDA #$02
%SubOffScreen()	;handle off screen situation



;// start moving when mario touches a block
LDA !State,x
BNE KeepQuiet

LDA $1909|!Base2
CMP #$FF
BEQ KeepQuiet

LDA #$01
STA !State,x

LDA #!InitDir
STA !Direction,x

LDA #$FF
STA $1909|!Base2

KeepQuiet:
;// check for blocks on grid positions if !State is 1
LDA !State,x
BEQ NoBlocks

LDA !E4,x       ;check x pos
AND #$0F
BNE NoBlocks

LDA !D8,x       ;check y pos
AND #$0F
BNE NoBlocks

;\ START MAP16CHECK
LDA !14E0,x
XBA           ;load 16bit X position
LDA !E4,x
REP #$20
	AND #$FFF0  ;(clear the low nybble to make it align to the grid)
	STA $9A 		;store it into the block addresses
SEP #$20

LDA !14D4,x
XBA           ;load 16bit Y position
LDA !D8,x
REP #$20
	AND #$FFF0  ;(clear the low nybble to make it align to the grid)
	STA $98 		;store it into the block addresses
SEP #$20

JSR CheckMap16
LDA [$05]      ;check the map16 tile
CMP #$F2
BCC StandardAction   ;is it F2 or below? those are not our tiles
STA $00

LDA !Eating,x
BNE CheckEat

LDA $00
CMP #$F8        ;if it's a creating block, ignore every block below F9
BCC NoBlocks

JSR DoActionCreating         ;if not, do stuff
BRA NoBlocks


CheckEat:
LDA $00
CMP #$F9        ;if it's an eating block, ignore every block above F8
BCS NoBlocks

JSR DoActionEating         ;if not, do stuff
BRA NoBlocks
;/ END MAP16CHECK

StandardAction:
LDA !Eating,x
BNE EatInstead

PHP
REP #$30
LDA #!StandardTile
STA $03
%ChangeMap16()
PLP
BRA NoBlocks

EatInstead:
PHP
REP #$30
LDA #!StandardAir
STA $03
%ChangeMap16()
PLP

NoBlocks:
;// movement
LDA !Speed,x
STA $0F
ASL
ASL
CLC : ADC $0F
STA $0F

LDA !Direction,x    ;index by direction
CLC : ADC $0F
TAY
LDA XSpeed,y        ;load x speed
STA !B6,x
LDA YSpeed,y        ;load y speed
STA !AA,x

JSL $01801A         ;update x
JSL $018022         ;update y


LDA !Direction,x
CMP #$04            ;if sprite is moving
BEQ NoNoise

LDA $14
AND #$03            ;every 4 frames
BNE NoNoise

LDA #!SFX           ;play sound effect
STA !SFXBank

NoNoise:
;// sprite->mario contact
JSL $01A7DC             ;check for Mario/sprite contact (carry set = contact)
BCC NoContact           ;go to NoContact if no contact

%SubVertPos()
LDA $0E                 ;check range between heights
CMP #$E6                ;if Mario isn't above sprite
BPL SolidAF

LDA $7D                 ;if Mario speed is upward, go to SolidAF, so the sprite is just solid
BMI SolidAF

JSR RideY               ;ride the sprite
BRA NoContact

SolidAF:
JSL $01B44F             ;solid sprite

NoContact:
RTS


OnOff:
LDY $14AF|!Base2
BNE .Other
DEC
DEC
RTS
.Other
DEC
RTS

OffOn:
LDY $14AF|!Base2
BNE .Other
DEC
DEC
RTS
.Other
DEC
DEC
DEC
RTS

DoActionEating:
LDA $00
PHA               ;preserve map16 number

;/spawning the new block
LDA #!Map16Page
XBA
PLA
PHA
CLC
ADC #$07        ;substract 7 from the block to turn it into a block with the same "props"

CMP #$FB
BNE .NoOnOff
JSR OnOff       ;if the block is one of the on/off ones, this'll make the block create the left/right
BRA .NoOffOn
.NoOnOff
CMP #$FC        ;used block instead of the on/off one, to keep in synch
BNE .NoOffOn
JSR OffOn
.NoOffOn

PHP
REP #$30
STA $03
%ChangeMap16()
PLP


PLA               ;get back map16 number
SEC
SBC #$F2          ;substract #$F9 to turn the air blocks into an index
ASL               ;shift left (multiply by 2 cause 16bit table)
TAX               ;index by block
JMP.w (Actions,x)   ;go to indexed state



DoActionCreating:
LDA $00
PHA               ;preserve map16 number

;/spawning the new block
LDA #!Map16Page
XBA
PLA
PHA
SEC
SBC #$07        ;substract 7 from the block to turn it into a block with the same "props"

CMP #$F4
BNE .NoOnOff
JSR OnOff       ;if the block is one of the on/off ones, this'll make the block create the left/right
BRA .NoOffOn
.NoOnOff
CMP #$F5        ;used block instead of the on/off one, to keep in synch
BNE .NoOffOn
JSR OffOn
.NoOffOn

PHP
REP #$30
STA $03
%ChangeMap16()
PLP


PLA               ;get back map16 number
SEC
SBC #$F9          ;substract #$F9 to turn the air blocks into an index
ASL               ;shift left (multiply by 2 cause 16bit table)
TAX               ;index by block
JMP.w (Actions,x)   ;go to indexed state

Actions:
dw ActionLeft,ActionRight,ActionOnOff,ActionOffOn,ActionSpeed,ActionSlow,ActionDeath


ActionLeft:
LDX $15E9|!Base2

LDA !Direction,x
DEC               ;decrease one from direction to turn left
BPL .Okay
LDA #$03          ;if it'd become #$FF, load #$03 instead
.Okay
STA !Direction,x  ;store
RTS


ActionRight:
LDX $15E9|!Base2

LDA !Direction,x
INC               ;add one to direction to turn right
CMP #$04
BNE .Okay
LDA #$00          ;if it'd become #$04, become #$00 instead
.Okay
STA !Direction,x  ;store
RTS


ActionOnOff:
LDA $14AF|!Base2
BNE ActionRight
BRA ActionLeft

ActionOffOn:
LDA $14AF|!Base2
BNE ActionLeft
BRA ActionRight


ActionSpeed:
LDX $15E9|!Base2

LDA !Speed,x
INC               ;add one to speed
CMP #$03          ;if it would overstore, don't store at all
BEQ .Okay
STA !Speed,x      ;store
.Okay
RTS


ActionSlow:
LDX $15E9|!Base2

LDA !Speed,x
DEC               ;take one from speed
BMI .Okay         ;if it would understore, don't store at all
STA !Speed,x      ;store
.Okay
RTS


ActionDeath:
LDX $15E9|!Base2

STZ !14C8,x       ;kill this sprite kk
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Graphics Routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubGFX:

	; DSS Modification
	lda #$77                 ; find or queue ExGFX D77
	%FindAndQueueGFX()
	bcs .dss_loaded
	rts

.dss_loaded
	%GetDrawInfo()
	PHX

	LDA $00         	;load sprite x pos
	STA $0300|!Base2,y ;store to oam x pos

	LDA $01         ;load sprite y pos
	DEC
	STA $0301|!Base2,y     ;store to oam y pos

	LDA !dss_tile_buffer+$00
	STA $0302|!Base2,y

	LDA #$21
	STA $0303|!Base2,y

	PLX

	LDY #$02        ; #$00 = 8x8, #$02 = 16x16, #$FF = variable
	LDA #$00        ; tiles drawn; #$00 = 1, #$01 = 2, etc.
	JSL $01B7B3     ; handle oam
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ride sprite routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


RideY:
LDA #$01
STA $1471|!Base2               ;set "on sprite" flag
STZ $7D                 ;zero out mario's y speed

LDA #$E1                ;load E1
LDY $187A|!Base2
BEQ NoYoshi
LDA #$D1                ;if on yoshi, load D1 instead (one block higher)
  NoYoshi:
CLC
ADC !D8,x               ;add sprite y position, low byte
STA $96                 ;store to mario y position, low byte
LDA !14D4,x             ;load sprite y position, high byte
ADC #$FF                ;decrease by 1 or keep same depending on overflow
STA $97                 ;store to mario y position

RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (JSR) Routine to check Map16 tile in block positions 98-9B
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckMap16:
LDA $98
AND #$F0
STA $06
LDA $9A
LSR #4
ORA $06
PHA
LDA $5B
AND #$01
BEQ .CODE_01D977
PLA
LDX $99
CLC
ADC.l $00BA80,x
STA $05
LDA.l $00BABC,x
ADC $9B
STA $06
BRA .CODE_01D989

.CODE_01D977
PLA
LDX $9B
CLC
if !EXLEVEL
	ADC.L !L1_Lookup_Lo,x
	STA $05
	LDA.L !L1_Lookup_Hi,x
else
	ADC.l $00BA80,x
	STA $05
	LDA.l $00BA9C,x
endif
ADC $99
STA $06

.CODE_01D989
LDA.b #!RAMBank
STA $07
LDX $15E9|!Base2
RTS
; [$05] now contains the Map16 tile number. To access it, do LDA [$05]. This will load the low byte.
; To check a 16-bit Map16 value, do:
; LDA [$05]
; XBA
; INC $07
; LDA [$05]
; XBA
; REP #$20
; A now contains the 16-bit Map16 tile number that the sprite is touching.
