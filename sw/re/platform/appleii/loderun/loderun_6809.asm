;
;	LODE RUNNER
; - ported from the original Apple II version
; - by tcdev 2014 msmcdoug@gmail.com
;
				.list		(meb)										; macro expansion binary
				
       	.area   idaseg (ABS)

.define			PLATFORM_COCO3
;.define			PLATFORM_WILLIAMS

.define			DEBUG

START_LEVEL_0_BASED	.equ		0

;
; 6809 stuff
;
						.macro	CLC
						andcc		#~(1<<0)
						.endm
						.macro	SEC
						orcc		#(1<<0)
						.endm

.ifdef PLATFORM_COCO3

.define			HAS_TITLE
.define			TILES_EXTERNAL
;.define			LEVELS_EXTERNAL
						
; COCO registers
PIA0				.equ		0xFF00
PIA1				.equ		0xFF20

KEYCOL			.equ		PIA0+2
KEYROW			.equ		PIA0

; GIME registers  	
INIT0				.equ		0xFF90
INIT1				.equ		0xFF91
IRQENR			.equ		0xFF92
FIRQENR			.equ		0xFF93
TMRMSB			.equ		0xFF94
TMRLSB			.equ		0xFF95
VMODE				.equ		0xFF98
VRES				.equ		0xFF99
BRDR				.equ		0xFF9A
VSC					.equ		0xFF9C
VOFFMSB			.equ		0xFF9D
VOFFLSB			.equ		0xFF9E
HOFF				.equ		0xFF9F
MMUTSK1			.equ		0xFFA0
MMUTSK2			.equ		0xFFA8
PALETTE			.equ		0xFFB0
CPU089			.equ		0xFFD8
CPU179			.equ		0xFFD9
ROMMODE			.equ		0xFFDE
RAMMODE			.equ		0xFFDF

HGR1_MSB		.equ		0x00
HGR2_MSB		.equ		0x20

						.macro HGR1
						lda			#0xE0								; screen at page $38
						sta			VOFFMSB
						.endm

						.macro HGR2
						lda			#0xE4								; screen at page $39
						sta			VOFFMSB
						.endm
						
codebase		.equ		0x4000
.endif

						.org		codebase
;stack				.equ		.-2
stack					.equ		0x8000
start:

.ifdef PLATFORM_COCO3
; initialise PLATFORM_COCO3 hardware
				ldu			#stack
				orcc		#0x50										; disable interrupts
; - disable PIA interrupts
				lda			#0x34
				sta			PIA0+1									; PIA0, CA1,2 control
				sta			PIA0+3									; PIA0, CB1,2 control
				sta			PIA1+1									; PIA1, CA1,2 control
				sta			PIA1+3									; PIA1, CB1,2 control
; - initialise GIME
				lda			IRQENR									; ACK any pending GIME interrupt
				lda			#0x60										; enable GIME MMU,IRQ
				sta			INIT0     							
				lda			#0x00										; slow timer, task 1
				sta			INIT1     							
;				lda			#0x08										; VBLANK IRQ
				lda			#0x00										; no VBLANK IRQ
				sta			IRQENR    							
				lda			#0x00										; no FIRQ enabled
				sta			FIRQENR   							
				lda			#0x80										; graphics mode, 60Hz, 1 line/row
				sta			VMODE     							
;				lda			#0x7A										; 225 scanlines, 128 bytes/row, 16 colours
				lda			#0x0C										; 192 scanlines, 40 bytes/row, 2 colours (320x192)
				sta			VRES      							
				lda			#0x00										; black
				sta			BRDR      							
				lda			#0xE0										; screen at page $38
				sta			VOFFMSB
				lda			#0x00      							
				sta			VOFFLSB   							
				lda			#0x00										; normal display, horiz offset 0
				sta			HOFF      							
				lda			#0x00
				sta			PALETTE
				lda			#0x12
				sta			PALETTE+1
				sta			CPU179									; select fast CPU clock (1.79MHz)
				
.ifdef TILES_EXTERNAL
; tiles @$8000-$A2BF
				lda			#0
				ldx			#(MMUTSK1+4)
				sta			,x+											; page 0 @$8000-$9FFF
				inca
				sta			,x+											; page 1 @$A000-$BFFF
.endif
				
.endif
			
				lda			#0x3F
				tfr			a,dp
					
; start lode runner
				jsr			read_paddles
;				lda			#1
;				jsr			sub_6359								; examine h/w and check disk sig			

display_title_screen: ; $6008
				jsr			gcls1
				lda			#0
				sta			*row
				sta			*attract_mode
				sta			*level_0_based
				lda			#HGR1_MSB
				sta			*hires_page_msb_1
				sta			*display_char_page
.ifdef HAS_TITLE
; coco code is different now				
				ldy			#title_data
				lda			*hires_page_msb_1
				ldb			#0											; 2 centres the title screen
				tfr			d,x
				lda			#35											; 35 bytes/line
				sta			*col
				lda			#192										; 192 lines/screen
				sta			*row
1$:			ldb			,y+											; count
				lda			,y+											; byte
2$:			sta			,x+
				dec			*col										; line byte count
				tst			*col										; done line?
				bne			3$											; no, skip
				pshs		b
				ldb			#35
				stb			*col										; reset line byte count
				ldb			#5
				abx															; adjust video ptr
				dec			*row										; dec line count
				puls		b
3$:			decb														; done count?
				bne			2$											; no, loop
				tst			*row										; done screen?
				bne			1$											; no, loop
.else				
				lda			#8
				sta			*row
				lda			#2
				sta			*col
				jsr			display_message
				.asciz			"INSERT TITLE SCREEN HERE"
.endif				
				HGR1
				jmp			title_wait_for_key

zero_score_and_init_game: ; $6056
				lda			#0
				sta			*score_1e1_1
				sta			*score_1e3_1e2
				sta			*score_1e5_1e4
				sta			*score_1e6
; stuff
				sta			*demo_inp_cnt
				ldy			#attract_move_tbl
				sty			*msb_demo_inp_ptr
				lda			#5											; number of lives
				sta			*no_lives
				lda			*attract_mode
				lsra
				;beq			loc_6099
				bra			loc_6099
; do some crap
				jmp			display_title_screen

loc_6099:	; $6099
				jsr			cls_and_display_game_status
				HGR1
main_game_loop:
				ldb			#1
				jsr			init_read_unpack_display_level
				lda			#0
				sta			*key_1
				sta			*key_2
				lda			*attract_mode
				lsra
				beq			1$
				jsr			keybd_flush
				lda			*current_col
				sta			*col
				lda			*current_row
				sta			*row
				lda			#9											; player
				jsr			blink_char_and_wait_for_key
1$:	; $60bf
				ldb			#0
				stb			*dig_dir
; stuff
in_level_loop:
				jsr			handle_player						; digging, falling, keys
				lda			*level_active						; alive?
				beq			dec_lives								; no, exit
				;jsr			sub_8811
				lda			*no_gold
				bne			1$
				jsr			draw_end_of_screen_ladder
1$:			lda			*current_row
				bne			2$											; not top row
				lda			*y_offset_within_tile
				cmpa		#2
				bne			2$											; not top of tile
				lda			*no_gold								; any gold left?
				beq			next_level							; no, go
				cmpa		#0xff										; issue with eos ladder?
				beq			next_level							; yes, go
2$:			jsr			respawn_guards_and_update_holes
				lda			*level_active						; alive?
				beq			dec_lives								; no, exit
				;jsr			sub_8811
				jsr			handle_guards
				lda			*level_active						; alive?
				beq			dec_lives								; no, exit
.if 1
; delay for Coco
				ldx			#8000
9$:			dex
				bne			9$
.endif
.if 0
9$:			ldx			#PIA0
				ldb			#0											; all columns
				stb			2,x											; column strobe
				lda			,x
				coma														; any key pressed?
				bne			9$											; yes, loop
.endif				
				bra			in_level_loop

next_level:
				inc			*level									; next level
				inc			*level_0_based					; used for reading level data
				inc			*no_lives								; extra life
				bne			3$											; skip if no wrap
				dec			*no_lives								; =255
3$:			ldb			#15
				stb			*byte_5c
4$:			ldb			#1
				lda			#0											; add 100
				jsr			update_and_display_score
				dec			*byte_5c
				bne			4$											; add 1500
next_level_cont:				
				jmp			main_game_loop				

dec_lives:	; $613F
				dec			*no_lives
				jsr			display_no_lives
				;jsr			sub_78e1								; sound stuff
; stuff
				lda			*attract_mode
				lsra														; demo mode?
				beq			loc_61d0								; yes, go
				lda			*no_lives								; any lives left?
				bne			next_level_cont					; yes, continue
				;jsr			loc_84c8								; (some high score stuff)
				jsr			game_over_animation
				;bcs			check_start_new_game
				
title_wait_for_key: ; $618e
				jsr			keybd_flush
				ldb			#4											; timeout
1$:			pshs		b
				ldy			#0
2$:			lda			*paddles_detected
				cmpa		#0xcb										; detected?
				beq			3$											; no, skip
; check for joystick buttons here				
3$:			ldx			#PIA0
				ldb			#0											; all columns
				stb			2,x											; column strobe
				lda			,x
				coma														; any key pressed?
				bne			check_start_new_game		; yes, exit
				leay		-1,y
				bne			2$
				puls		b
				decb														; done?
				bne			1$											; no, loop
				lda			*attract_mode						; in attract mode?
				bne			loc_61de								; yes, skip
				ldb			#1
				stb			*attract_mode						; set attract mode
				stb			*level
				stb			*byte_ac
				stb			*game_active
; do some other crap
				lbra		zero_score_and_init_game

loc_61d0:	; $61D0
				lda			#0
				;sta			*byte_99
; reads $C000 (keybd) but not used!?!				
				ldb			*byte_ac
				beq			check_start_new_game
				jmp			title_wait_for_key
				
loc_61de:	; $61DE
				cmpa		#1											; attract mode
				bne			loc_61f3
				beq			high_score_screen
				
read_and_display_scores:	; $61E4
				lda			#1
				;jsr			sub_6359								; disk access
high_score_screen: ; $61E9
				jsr			cls_and_display_high_scores
				lda			#2
				sta			*attract_mode
				jmp			title_wait_for_key				

loc_61f3:	; $61F3
				jmp			display_title_screen
				
check_start_new_game: ; $61F6
; check for 'e' key for editor (not supported)
				ldx			#PIA0
				ldb			#~(1<<0)								; col0
				stb			2,x											; column strobe
				lda			,x											; active low
				bita		#(1<<6)									; <ENTER>?
				beq			read_and_display_scores	; yes, go
start_new_game:	; $6201
				ldb			#START_LEVEL_0_BASED
				stb			*level_0_based
				incb
				stb			*level
				stb			*game_active
				lda			#2
				sta			*attract_mode
				jmp			zero_score_and_init_game														

init_read_unpack_display_level:	; $6238
				stb			*editor_n
				ldb			#0xff
				stb			*current_col						; flag no player
				incb														; B=0
				stb			*no_eos_ladder_tiles
				stb			*no_gold
				stb			*no_guards
				stb			*curr_guard
				stb			*dig_sprite
				stb			*packed_byte_cnt
				stb			*nibble_cnt
				stb			*row
				tfr			b,a											; A=0
				ldb			#0x1e										; number of holes
				ldy			#hole_cnt
7$:			sta			b,y
				decb
				bpl			7$											; clear all hole counters
				ldb			#5											; number of guards
				ldy			#guard_cnt
8$:			sta			b,y				
				decb
				bpl			8$											; zero all guard counters
				lda			#1
				sta			*level_active
				jsr			read_level_data
				ldb			*row
5$:			ldy			#lsb_row_addr						; table for row LSB entries
				lda			b,y											; get entry for row
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1					; table for MSB entries
				lda			b,y											; get entry for row
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2					; table for MSB entries (#2)
				lda			b,y											; get entry for row
				sta			*byte_9
				ldx			#level_data_packed			; was in disk buffer
				ldb			*packed_byte_cnt
				abx															; ptr packed byte
				lda			#0
				sta			*col										; col=0
4$:			lda			*nibble_cnt
				lsra
				lda			,x											; source (packed) byte
				bcs			1$											; do high nibble
				anda		#0x0f										; low nibble
				bra			2$
1$:			lsra
				lsra
				lsra
				lsra
				inc			*packed_byte_cnt
				inx															; source (packed) addr
2$:			inc			*nibble_cnt
				ldb			*col
.if 0
; wipe enemies from the game
				cmpa		#8
				bne			0$
				lda			#0
0$:				
.endif				
				cmpa		#10											; data byte 0-9?
				bcs			3$											; yes, valid (skip)
				lda			#0											; invalid, ignore
3$:			ldy			*msb_row_level_data_addr
				sta			b,y											; destination (unpacked) byte
				ldy			*byte_9
				sta			b,y											; destination (unpacked) byte 2
				inc			*col
				ldb			*col
				cmpb		#28											; last column?
				bcs			4$											; no, loop
				inc			*row
				ldb			*row
				cmpb		#16											; last row?
				bcs			5$											; no, loop
				jsr			init_and_draw_level
				bcc			draw_ok
				lda			*level_0_based
				beq			jmp_display_title_screen
				ldb			#0
				;inc			*byte_97
				decb
				jmp			init_read_unpack_display_level
draw_ok:	; $62C3
				rts

jmp_display_title_screen:	; $62C4
				jmp			display_title_screen
				
read_level_data:	; $6264
; copies from disk buffer to low memory ($0D00)
				;sta			byte_b7f4								; disk area = *level_active???
				lda			*attract_mode
				lsra														; demo mode?
				beq			read_attract_mode_levels
				lda			*level_0_based
; nothing like original code from here-on in			

	; hack - 5 levels only atm
1$:			cmpa		#5
				bcs			2$
				suba		#5
				bra			1$
2$:
	; end of hack
					
				adda		#>game_level_data
				sta			*msb_line_addr_pg1
				lda			#<game_level_data
				sta			*lsb_line_addr_pg1
				ldx			*msb_line_addr_pg1
				ldy			#level_data_packed
				clrb
				bra			copy_level_data
				
read_attract_mode_levels:
				lda			*level
				deca
				adda		#>demo_level_data
				sta			*msb_line_addr_pg1
				lda			#<demo_level_data
				sta			*lsb_line_addr_pg1
				ldx			*msb_line_addr_pg1
				ldy			#level_data_packed
				clrb
copy_level_data:
				lda			,x+
				sta			,y+
				decb
				bne			copy_level_data
				rts
				
init_and_draw_level: ; $63B3
				ldb			#15											; last row
				stb			*row
1$:			ldy			#lsb_row_addr
				lda			b,y											; get lsb of row
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y											; get msb of row
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9
				ldb			#27											; last column
				stb			*col
2$:			ldx			*msb_row_level_data_addr
				lda			b,x
				cmpa		#6											; end-of-screen ladder?
				bne			4$											; no, skip
				ldb			*no_eos_ladder_tiles
				cmpb		#0x4d										; max?
				bcc			3$											; yes, skip
				inc			*no_eos_ladder_tiles
				incb
				lda			*row
				ldy			#eos_ladder_row
				sta			b,y											; store row
				lda			*col
				ldy			#eos_ladder_col
				sta			b,y											; store col
				tfr			a,b											; B=col
3$:			lda			#0
				ldx			*msb_row_level_data_addr
				sta			b,x											; update tilemap
				ldx			*byte_9
				sta			b,x											; update tilemap
				bra			8$
4$:			cmpa		#7											; gold?
				bne			5$											; no, skip
				inc			*no_gold
				bra			8$
5$:			cmpa		#8											; guard?
				bne			6$											; no, skip
				lda			*no_guards
				cmpa		#5											; max?
				bcc			3$											; yes, go
				inc			*no_guards							; add a guard
				inca
				ldy			#guard_col
				exg			a,b											; A=col,B=guard
				sta			b,y											; set guard column
				pshs		a
				lda			*row
				ldy			#guard_row
				sta			b,y											; set guard row
				lda			#0
				ldy			#byte_c70
				sta			b,y
				lda			#2
				ldy			#guard_x_offset
				sta			b,y
				ldy			#guard_y_offset
				sta			b,y
				lda			#0
				ldy			*byte_9
				puls		b												; B=col
				sta			b,y											; update tilemap (with space)
				lda			#8											; guard
				bra			8$
6$:			cmpa		#9											; player?
				bne			7$											; no, skip
				tst			*current_col						; already got a player?
				bpl			3$											; yes, ignore
				stb			*current_col						; set player column
				lda			*row
				sta			*current_row						; set player row
				lda			#2
				sta			*x_offset_within_tile
				sta			*y_offset_within_tile
				lda			#8
				sta			*sprite_index
				lda			#0											; space
				ldx			*byte_9
				sta			b,x											; update tilemap
				lda			#9											; player
				bra			8$
7$:			cmpa		#5											; fall-thru?
				bne			8$											; no, skip
				lda			#1											; display diggable brick
8$:			jsr			display_char_pg2
				dec			*col
				ldb			*col
				lbpl		2$
				dec			*row
				ldb			*row
				lbpl		1$
				lda			*current_col
				bpl			draw_level
				SEC
				rts

draw_level:	; $648B
				jsr			wipe_or_draw_level
				ldb			#15											; last row
				stb			*row
1$:			ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldb			#27											; last column
				stb			*col			
2$:			ldy			*msb_row_level_data_addr
				lda			b,y											; get tilemap data
				cmpa		#9											; player?
				beq			3$											; yes, continue
				cmpa		#8											; enemy?
				bne			4$											; no, skip
3$:			lda			#0											; space
				jsr			display_char_pg2				; wipe player & enemies from bg
4$:			dec			*col
				ldb			*col										; done all columns?
				bpl			2$											; no, loop
				dec			*row
				ldb			*row										; done all rows?
				bpl			1$											; no, loop
				CLC
				rts

handle_player: ; $64bd
				lda			#1
				;sta			unk_94
				lda			*dig_dir
				beq			not_digging
				bpl			1$											; digging right
				jmp			digging_left
1$:			jmp			digging_right
not_digging:	; $64CD
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*byte_8
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; update tilemap addr
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#3											; ladder?
				beq			cant_fall								; yes, exit
				cmpa		#4											; rope?
				bne			check_falling						; no, skip
				lda			*y_offset_within_tile
				cmpa		#2
				beq			cant_fall
check_falling:	; $64EB				
				lda			*y_offset_within_tile
				cmpa		#2
				bcs			handle_falling
				ldb			*current_row
				cmpb		#15											; bottom row?
				beq			cant_fall								; yes, skip
				ldy			#lsb_row_addr+1
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1+1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2+1
				lda			b,y
				sta			*byte_9									; setup tilemap address to row below
				ldb			*current_col
				ldy			*msb_row_level_data_addr
				lda			b,y											; get object from tilemap
				cmpa		#0											; space?
				beq			handle_falling					; yes, go
				cmpa		#8											; enemy?
				beq			cant_fall								; yes, go
				ldy			*byte_9									
				lda			b,y											; get object from tilemap
				cmpa		#1											; brick?
				beq			cant_fall								; yes, go
				cmpa		#2											; solid?
				beq			cant_fall								; yes, go
				cmpa		#3											; ladder?
				bne			handle_falling					; no, go
cant_fall:
				jmp			check_falling_sound				
				
handle_falling:	; $6525
				lda			#0
				sta			*unk_9b
				jsr			calc_char_and_addr
				jsr			wipe_char
				lda			#7											; char=0x13 (fall left)
				ldb			*dir										; left?
				bmi			1$											; yes, skip
				lda			#0x0f										; char=0x0f (fall right)
1$:			sta			*sprite_index
				jsr			adjust_x_offset_in_tile
				inc			*y_offset_within_tile
				lda			*y_offset_within_tile
				cmpa		#5											; >=5?
				bcc			fall_check_row_below		; yes, skip
				jsr			check_for_gold
				jmp			draw_sprite

fall_check_row_below:	; $654A
				lda			#0
				sta			*y_offset_within_tile
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap				
				cmpa		#1											; brick?
				bne			1$											; no, skip
				lda			#0											; space
1$:			ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap
				inc			*current_row
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr	; setup tilemap address
				ldb			*current_col
				lda			#9											; player
				ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap
				jmp			draw_sprite

check_falling_sound:	; $6584
				lda			*unk_9b
				bne			check_controls
				lda			#0x64
				ldb			#8
				jsr			play_falling_sound
check_controls:	; $658F				
				lda			#0x20
				;sta			*byte_a4
				sta			*unk_9b
				jsr			read_controls
				lda			*key_1
				cmpa		#0xc9										; 'I'?
				bne			check_down_key					; no, skip
				jsr			move_up
				bcs			check_left_key
				rts
check_down_key:
				cmpa		#0xcb										; 'K'?
				bne			check_dig_left_key			; no, skip
				jsr			move_down
				bcs			check_left_key
				rts
check_dig_left_key:
				cmpa		#0xd5										; U'?
				bne			check_dig_right_key			; no, skip
				jsr			dig_left
				bcs			check_left_key
				rts
check_dig_right_key:
				cmpa		#0xcf										; 'O'?
				bne			check_left_key					; no, skip
				jsr			dig_right
				bcs			check_left_key
				rts
check_left_key:
				lda			*key_2
				cmpa		#0xca										; 'J'?
				bne			check_right_key					; no, skip
				jmp			move_left
check_right_key:				
				cmpa		#0xcc										; 'L'?
				bne			no_keys									; no, skip
				jmp			move_right
no_keys:				
				rts

move_left: ; 65D3
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap & video addresses
				ldb			*x_offset_within_tile
				cmpb		#3
				bcc			can_move_left
				ldb			*current_col
				beq			9$											; left-most? yes, exit
				decb														; previous column
				ldy			*msb_row_level_data_addr
				lda			b,y											; get tile data
				cmpa		#2											; solid?
				beq			9$											; yes, exit
				cmpa		#1											; brick?
				beq			9$											; yes, exit
				cmpa		#5											; fall-thru?
				bne			can_move_left						; no, continue				
9$:			rts
				
can_move_left: ; $6600
				jsr			calc_char_and_addr			; X(lsb)=scanline
				jsr			wipe_char
				lda			#-1
				sta			*dir										; set direction right
				jsr			adjust_y_offset_within_tile
				dec			*x_offset_within_tile
				bpl			2$
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from filemap
				cmpa		#1											; brick?
				bne			1$											; no, skip
				lda			#0
1$:			ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap
				dec			*current_col						; previous tile
				decb
				lda			#9											; player
				sta			b,y											; update tilemap
				lda			#4
				sta			*x_offset_within_tile
				bra			3$
2$:			jsr			check_for_gold
3$:			ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#4											; rope?
				beq			4$											; yes, go
				lda			#0											; 1st sprite index (runner left)
				ldb			#2											; last sprite index (runner left)								
				bra			5$
4$:			lda			#3											; 1st sprite index (swinger left)
				ldb			#5											; last sprite index (swinger left)
5$:			jsr			update_sprite_index
				jmp			draw_sprite				

move_right: ; $6645
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap & video addresses
				ldb			*x_offset_within_tile
				cmpb		#2
				bcs			can_move_right
				ldb			*current_col
				cmpb		#27											; right-most?
				beq			9$											; yes, exit
				incb														; next column
				ldy			*msb_row_level_data_addr
				lda			b,y											; get tile data
				cmpa		#2											; solid?
				beq			9$											; yes, exit
				cmpa		#1											; brick?
				beq			9$											; yes, exit
				cmpa		#5											; fall-thru?
				bne			can_move_right					; no, continue				
9$:			rts

can_move_right: ; $6674
				jsr			calc_char_and_addr			; X(lsb)=scanline
				jsr			wipe_char
				lda			#1
				sta			*dir										; set direction right
				jsr			adjust_y_offset_within_tile
				inc			*x_offset_within_tile
				lda			*x_offset_within_tile
				cmpa		#5
				bcs			2$
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from filemap
				cmpa		#1											; brick?
				bne			1$											; no, skip
				lda			#0
1$:			ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap
				inc			*current_col						; next tile
				incb
				lda			#9											; player
				sta			b,y											; update tilemap
				lda			#0
				sta			*x_offset_within_tile
				bra			3$
2$:			jsr			check_for_gold
3$:			ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#4											; rope?
				beq			4$											; yes, go
				lda			#8											; 1st sprite index (runner right)
				ldb			#0x0a										; last sprite index (runner right)								
				bra			5$
4$:			lda			#0x0b										; 1st sprite index (swinger right)
				ldb			#0x0d										; last sprite index (swinger right)
5$:			jsr			update_sprite_index
				jmp			draw_sprite				

move_up: ; $66BD
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*byte_8
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#3											; ladder?
				beq			check_move_up						; yes, go
				ldb			*y_offset_within_tile
				cmpb		#3											; <3?
				bcs			cant_move_up						; yes, exit
				ldb			*current_row
				ldy			#lsb_row_addr+1					; row below???
				lda			b,y											; get object from tilemap
				sta			*byte_8
				ldy			#msb_row_addr_2+1				; row below?
				lda			b,y											; get object from tilemap
				sta			*byte_9
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#3											; ladder?
				beq			can_move_up
cant_move_up:	; $66EB
				SEC
				rts
				
check_move_up:	; $66ED				
				ldb			*y_offset_within_tile
				cmpb		#3											; >=3?
				bcc			can_move_up							; yes, go
				ldb			*current_row
				beq			cant_move_up						; top row? yes, exit
				ldy			#lsb_row_addr-1
				lda			b,y
				sta			*lsb_row_level_data_addr
				ldy			#msb_row_addr_1-1
				lda			b,y
				sta			*msb_row_level_data_addr	; adjust tilemap address to row above
				ldb			*current_col
				ldy			*msb_row_level_data_addr
				lda			b,y											; get object from tilemap
				cmpa		#1											; brick?
				beq			cant_move_up						; yes, exit
				cmpa		#2											; solid?
				beq			cant_move_up						; yes, exit
				cmpa		#5											; fall-thru?
				beq			cant_move_up						; yes, exit
				
can_move_up:
				jsr			calc_char_and_addr
				jsr			wipe_char
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap and video address
				jsr			adjust_x_offset_in_tile
				dec			*y_offset_within_tile
				bpl			climber_check_for_gold	; change tiles? no, skip
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#1											; brick?
				bne			1$											; no, skip
				lda			#0											; space
1$:			ldy			*msb_row_level_data_addr
				lda			b,y
				dec			*current_row
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldb			*current_col
				lda			#9											; player
				ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap
				lda			#4
				sta			*y_offset_within_tile
				bra			update_climber_sprite
climber_check_for_gold:
				jsr			check_for_gold
update_climber_sprite:
				lda			#0x10										; 1st sprite index (climber)
				ldb			#0x11										; last sprite index (climber)
				jsr			update_sprite_index
				jsr			draw_sprite
				CLC															; flag able to move
				rts

move_down:	; $6766
				ldb			*y_offset_within_tile
				cmpb		#2
				bcs			can_move_down
				ldb			*current_row
				cmpb		#15											; bottom row?
				bcc			cant_move_down					; yes, exit
				ldy			#lsb_row_addr+1					; row below
				lda			b,y
				sta			*lsb_row_level_data_addr
				ldy			#msb_row_addr_1+1
				lda			b,y
				sta			*msb_row_level_data_addr	; adjust tilemap address for row below
				ldb			*current_col
				ldy			*msb_row_level_data_addr
				lda			b,y											; get object from tilemap
				cmpa		#2											; solid?
				beq			cant_move_down					; yes, exit
				cmpa		#1											; brick?
				bne			can_move_down						; no, go
cant_move_down:	; $6788
				SEC															; flag unable to move
				rts				

can_move_down:	; $678A
				jsr			calc_char_and_addr
				jsr			wipe_char
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9
				jsr			adjust_x_offset_in_tile
				inc			*y_offset_within_tile
				lda			*y_offset_within_tile
				cmpa		#5											; <5?
				bcs			2$											; yes, skip
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#1											; brick?
				bne			1$											; no, skip
				lda			#0
1$:			ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap
				inc			*current_row						; row below
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr	; update tilemap address
				ldb			*current_col
				lda			#9											; player
				ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap
				lda			#0
				sta			*y_offset_within_tile
				jmp			update_climber_sprite
2$:			jmp			climber_check_for_gold				
				
cant_dig_left:	; $67D8
				jmp			finish_dig_left
				rts
				
dig_left:	; $67db
				lda			#0xff
				sta			*dig_dir
				sta			*key_1
				sta			*key_2
				lda			#0
				sta			*dig_sprite
digging_left:
				ldb			*current_row
				cmpb		#15											; bottom row?
				bcc			cant_dig_left						; yes, exit
				incb														; row below
				jsr			set_row_addr_1_2
				ldb			*current_col
				beq			cant_dig_left						; left-most edge? yes, exit
				decb														; column to the left
				ldy			*msb_row_level_data_addr
				lda			b,y											; get tilemap data (below, left)
				cmpa		#1											; brick?
				bne			cant_dig_left						; no, exit
				ldb			*current_row
				jsr			set_row_addr_1_2
				ldb			*current_col
				decb														; column to the left
				ldy			*msb_row_level_data_addr
				lda			b,y											; get tilemap data (left)
				cmpa		#0											; space?
				lbne		abort_dig_left					; no, go
				jsr			calc_char_and_addr
				jsr			wipe_char
				jsr			adjust_x_offset_in_tile
				jsr			adjust_y_offset_within_tile
				ldb			*dig_sprite
				ldy			#sprite_to_char_tbl+0x36
				lda			b,y
				pshs		a
				ldy			#sprite_to_char_tbl+0x43
				lda			b,y
				puls		b
				;jsr			sub_87d5
				ldb			*dig_sprite
				lda			#0											; sprite=0, tile=$B (running left)
				cmpb		#6
				bcc			1$
				lda			#6
1$:			sta			*sprite_index
				jsr			draw_sprite
				ldb			*dig_sprite
				cmpb		#0x0c
				beq			loc_6898
				cmpb		#0
				beq			2$
				ldy			#sprite_to_char_tbl+0x11
				lda			b,y
				pshs		a
				lda			*current_col
				deca
				ldb			*current_row
				jsr			calc_colx5_scanline
				tfr			d,x											; X(lsb)=scanline
				tfr			a,b											; B=x_in_2_pixel_incs
				puls		a												; A=char
				jsr			wipe_char
				ldb			*dig_sprite
2$:			ldy			#sprite_to_char_tbl+0x12
				lda			b,y
				pshs		a
				lda			*current_col				
				deca
				sta			*col
				ldb			*current_row
				stb			*row
				jsr			calc_colx5_scanline
				tfr			d,x											; X(lsb)=scanline
				tfr			a,b											; B=x_in_2_pixel_incs
				puls		a												; A=char
				jsr			display_transparent_char
				ldb			*dig_sprite
				ldy			#sprite_to_char_tbl+0x2a
				lda			b,y
				inc			*row
				jsr			display_char_pg1
				inc			*dig_sprite
				CLC															; flag
				rts

abort_dig_left:	; $686E
; stuff
finish_dig_left:	; $6892
				lda			#0
				sta			*dig_dir
				SEC
				rts

loc_6898: ; $6898
				ldb			*current_col
				decb
				jmp			add_hole_entry
												
cant_dig_right:	; $689E
				jmp			finish_dig_right
																				
dig_right: ; 68a1
				lda			#1
				sta			*dig_dir
				sta			*key_1
				sta			*key_2
				lda			#0x0c
				sta			*dig_sprite
digging_right:				
				ldb			*current_row
				cmpb		#15											; bottom row?
				bcc			cant_dig_right					; yes, exit
				incb														; row below
				jsr			set_row_addr_1_2
				ldb			*current_col
				cmpb		#27											; right-most edge?
				bcc			cant_dig_right					; yes, exit
				incb														; column to the right
				ldy			*msb_row_level_data_addr
				lda			b,y											; get tilemap data (below, right)
				cmpa		#1											; brick?
				bne			cant_dig_right					; no, exit
				ldb			*current_row
				jsr			set_row_addr_1_2
				ldb			*current_col
				incb														; column to the right
				ldy			*msb_row_level_data_addr
				lda			b,y											; get tilemap data (right)
				cmpa		#0											; space?
				lbne		abort_dig_right					; no, go
				jsr			calc_char_and_addr
				jsr			wipe_char
				jsr			adjust_x_offset_in_tile
				jsr			adjust_y_offset_within_tile
				ldb			*dig_sprite
				ldy			#sprite_to_char_tbl+0x2A
				lda			b,y
				pshs		a
				ldy			#sprite_to_char_tbl+0x37
				lda			b,y
				puls		b
				;jsr			sub_87d5
				ldb			*dig_sprite
				lda			#8											; sprite=8, tile=9 (running right)
				cmpb		#0x12
				bcc			1$
				lda			#0x0e
1$:			sta			*sprite_index
				jsr			draw_sprite
				ldb			*dig_sprite
				cmpb		#0x18
				beq			loc_6962
				cmpb		#0x0c
				beq			2$
				ldy			#sprite_to_char_tbl+0x11
				lda			b,y
				pshs		a
				lda			*current_col
				inca
				ldb			*current_row
				jsr			calc_colx5_scanline
				tfr			d,x											; X(lsb)=scanline
				tfr			a,b											; B=x_in_2_pixel_incs
				puls		a												; A=char
				jsr			wipe_char
				ldb			*dig_sprite
2$:			ldy			#sprite_to_char_tbl+0x12
				lda			b,y
				pshs		a
				lda			*current_col				
				inca
				sta			*col
				ldb			*current_row
				stb			*row
				jsr			calc_colx5_scanline
				tfr			d,x											; X(lsb)=scanline
				tfr			a,b											; B=x_in_2_pixel_incs
				puls		a												; A=char
				jsr			display_transparent_char
				inc			*row
				ldb			*dig_sprite
				ldy			#sprite_to_char_tbl+0x1e
				lda			b,y
				jsr			display_char_pg1
				inc			*dig_sprite
				CLC															; flag
				rts

abort_dig_right:	; $6936
finish_dig_right:	; $695C
				lda			#0
				sta			*dig_dir
				SEC
				rts

loc_6962: ; $6962
				ldb			*current_col
				incb
				jmp			add_hole_entry
								
sprite_to_char_tbl:	; $6968
				.db 		0xB, 0xC, 0xD, 0x18, 0x19, 0x1A, 0xF, 0x13, 9, 0x10, 0x11, 0x15, 0x16
				.db 		0x17, 0x25, 0x14, 0xE, 0x12, 0x1B, 0x1B, 0x1C, 0x1C, 0x1D, 0x1D, 0x1E
				.db 		0x1E, 0, 0, 0, 0, 0x26, 0x26, 0x27, 0x27, 0x1D, 0x1D, 0x1E, 0x1E, 0
				.db 		0, 0, 0, 0x1F, 0x1F, 0x20, 0x20, 0x21, 0x21, 0x22, 0x22, 0x23, 0x23
				.db 		0x24, 0x24, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x24, 0x24
				.db 		0x24, 0x24, 0x24, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 2, 2, 1

handle_attract_mode:	; $69B8
				ldx			#PIA0
				ldb			#0										; all columns
				stb			2,x										; column strobe
				lda			,x										; active low
				coma													; active high
				bne			exit_demo							; key pressed, go
				bra			next_demo_inp
exit_demo:				
				lsr			*byte_ac
				lsr			*level_active					; kill player
				lda			#1
				sta			*no_lives
				rts

next_demo_inp:	; $69D6
				lda			*demo_inp_cnt					; counter=0?
				bne			1$										; no, skip
				ldy			*msb_demo_inp_ptr
				lda			0,y										; get 1st byte
				sta			*demo_inp_key_1_2
				lda			1,y										; get 2nd byte
				sta			*demo_inp_cnt
				leay		2,y										; next entry
				sty			*msb_demo_inp_ptr			; update ptr
1$:			ldb			*demo_inp_key_1_2
				andb		#0x0f									; low nibble
				ldy			#demo_inp_remap_tbl
				lda			b,y										; get equivalent keycode
				sta			*key_1
				ldb			*demo_inp_key_1_2
				lsrb
				lsrb
				lsrb
				lsrb
				lda			b,y										; get equivalent keycode
				sta			*key_2
				dec			*demo_inp_cnt
				rts

demo_inp_remap_tbl:	; $6A0B
;								I, J, K, L, O, U, <SPACE>
				.db			0xC9, 0xCA, 0xCB, 0xCC, 0xCF, 0xD5, 0xA0
								
; Coco Keyboard
;    7  6  5  4  3  2  1  0
;	0: G  F  E  D  C  B  A  @
; 1: O  N  M  L  K  J  I  H
; 2: W  V  U  T  S  R  Q  P
; 3: SP RT LT DN UP Z  Y  X
; 4: '  &  %  $  #  "  !  0
; 4: 7  6  5  4  3  2  1  0
; 5: ?  >  =  <  +  *  )  (
; 5: /  .  _  ,  ;  :  9  8
; 6: SH F2 F1 CT AL BK CL CR

page:		.db			0

read_controls:	; $6a12
.ifdef DEBUG
				ldx			#PIA0
				ldb			#~(1<<0)								; col0
				stb			2,x											; column strobe
				lda			,x											; active low
				bita		#(1<<6)									; <ENTER>?
				bne			93$
				lda			page
				coma		
				sta			page
				bne			91$
				HGR1
				bra			92$
91$:		HGR2
92$:		lda			,x											; active low
				bita		#(1<<6)
				beq			92$											; wait for key release
93$:				
.endif
				lda			*attract_mode
				cmpa		#1
				beq			handle_attract_mode
				ldy			#got_key
				pshs		y												; set return address
.ifdef PLATFORM_COCO3				
1$:				
				ldx			#PIA0
				ldb			#~(1<<4)								; col4
				stb			2,x											; columns strobe
				lda			,x											; active low
				coma
				anda		#(1<<6)									; bit6=CTRL
				sta			*zp_ff
				ldb			#~(1<<0)								; col0
				stb			2,x											; columns strobe
				lda			,x											; active low
				bita		#(1<<6)									; <ENTER>?
				bne			10$
				tst			*zp_ff									; CTRL?
				bne			10$											; no, skip
				lda			#0x8d										; CTRL-M
				rts
10$:		ldb			#~(1<<1)								; col1
				stb			2,x											; columns strobe
				lda			,x											; active low
				bita		#(1<<0)									; 'A'?
				bne			11$											; no, skip
				tst			*zp_ff									; CTRL?
				beq			11$											; no, skip
				lda			#0x81										; CTRL-A
				rts
11$:		bita		#(1<<1)									; 'I'?
				bne			2$											; no, skip
				lda			#0xc9										; 'I'
				rts
2$:			ldb			#~(1<<2)								; col2
				stb			2,x											; columns strobe
				lda			,x											; active low
				bita		#(1<<1)									; 'J'?
				bne			31$											; no, skip
				lda			#0xca										; 'J'
				rts
31$:		bita		#(1<<2)									; 'R'?
				bne			3$											; no, skip
				tst			*zp_ff									; CTRL?
				beq			3$											; no, skip
				lda			#0x92										; CTRL-R
				rts				
3$:			ldb			#~(1<<3)								; col3
				stb			2,x											; columns strobe
				lda			,x											; active low
				bita		#(1<<1)									; 'K'?
				bne			4$											; no, skip
				lda			#0xcb										; 'K'
				rts
4$:			ldb			#~(1<<4)								; col4
				stb			2,x											; column strobe
				lda			,x											; active low
				bita		#(1<<1)									; 'L'?
				bne			5$											; no, skip
				lda			#0xcc										; 'L'
				rts
5$:			ldb			#~(1<<5)								; col5
				stb			2,x											; column strobe
				lda			,x											; active low
				bita		#(1<<2)									; 'U'?
				bne			6$											; no, skip
				lda			#0xd5										; 'U'
				rts
6$:			tst			*zp_ff									; CTRL?
				beq			7$
				ldb			#~(1<<6)								; col6
				stb			2,x											; column_strobe
				lda			,x											; active low
				bita		#(1<<0)									; 'F'?
				bne			61$											; no, skip
; not useful becuase it's not leading-edge				
				lda			#0x80										; CTRL-@
				rts
61$:		bita		#(1<<1)									; 'N'?
				bne			7$											; no, skip
				lda			#0x9e										; CTRL-^			
				rts
7$:			ldb			#~(1<<7)								; col7
				stb			2,x											; column strobe
				lda			,x											; active low
				bita		#(1<<1)									; 'O'?
				bne			8$											; no, skip
				lda			#0xcf										; 'O'
				rts
8$:			clra
.endif
				rts
got_key:
				tfr			a,b											; B=(apple)key
				stb			*msg_char
				bne			key_pressed
; stuff (but fall thru here)				
key_pressed:	; $6A2B
				cmpb		#0xa0										; normal character?
				bcc			2$											; yes, go
				stb			*msg_char
				ldb			#0xff
1$:			incb
				ldy			#ctl_keys
				lda			b,y											; get key entry
				beq			2$											; done? yes, exit				
				cmpa		*msg_char								; match?
				bne			1$											; no, loop
				ldx			#ctl_key_vector_fn
				aslb														; entry offset
				abx
				ldy			,x
				pshs		y												; set as return address
				rts
2$:			; paddle stuff
				ldb			*msg_char				
				stb			*key_1
				stb			*key_2
				rts

goto_next_level:	; $6A56
				inc			*no_lives
				inc			*level
				inc			*level_0_based
				lsr			*level_active						; 'kill' player
				lsr			*game_active
				rts
				
extra_life:	; $6A61
				inc			*no_lives
				bne			1$
				dec			*no_lives
1$:			jsr			display_no_lives
				lsr			*game_active
				jmp			read_controls

freeze:	; $6A76
;				jsr			wait_for_key
				cmpa		#0x9b
;				bne			freeze
				jmp			read_controls
																				
terminate_game:	; $6A81
				lda			#1
				sta			*no_lives
abort_life:	; $6A84
				lsr			*level_active
				rts

speed_up:	; $6ABC
				lda			*game_speed
; the original source jumps to $6ACD
; which equates to 1$ in the slow_down routine
; but it's obviously a cut-n-paste error
; and makes no difference to the execution
				beq			1$
				dec			*game_speed
1$:			jmp			read_controls

slow_down:	; $6AC5
				lda			*game_speed
				cmpa		#0x0f
				beq			1$
				inc			*game_speed
1$:			jmp			read_controls
												
ctl_keys:	; $6B59
				.db			0x9e										; CTRL-^ (next level)
				.db			0x80										; CTRL-@ (extra life)
				.db			0x9b										; ESC (freeze toggle)
				.db			0x92										; CTRL-R (terminate game)
				.db			0x81										; CTRL-A (abort life)
				.db			0x88										; CTRL-H (speed up)
				.db			0x95										; CTRL-U (slow down)
				.db			0x8d										; CTRL-M (display high scores)
				.db			0

ctl_key_vector_fn:
				.dw			#goto_next_level
				.dw			#extra_life
				.dw			#freeze
				.dw			#terminate_game
				.dw			#abort_life
				.dw			#speed_up
				.dw			#slow_down
				.dw			#ctrl_m
												
calc_char_and_addr:	; $6b85
				lda			*current_col
				ldb			*x_offset_within_tile
				jsr			calc_x_in_2_pixel_incs
				stb			*msg_char								; store x_in_2_pixel_incs
				ldb			*current_row
				lda			*y_offset_within_tile
				jsr			calc_scanline						; B=scanline
				tfr			d,x											; X(lsb)=scanline
				ldb			*sprite_index
				ldy			#sprite_to_char_tbl
				lda			b,y											; A=lookup char from sprite
				ldb			*msg_char								; restore x_in_2_pixel_incs
				rts

check_for_gold: ; $6b9d
				lda			*x_offset_within_tile
				cmpa		#2											; offset=2?
				bne			9$											; no, return
				lda			*y_offset_within_tile
				cmpa		#2											; offset=2?
				bne			9$											; no, return
				ldb			*current_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*byte_8
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*current_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#7											; gold?
				bne			9$											; no, exit
				;lsr		unk_94
				dec			*no_gold
				ldb			*current_row
				stb			*row
				ldb			*current_col
				stb			*col
				lda			#0											; space
				ldy			*byte_9
				sta			b,y											; wipe gold from tilemap
				jsr			display_char_pg2				; wipe gold from bg page
				ldb			*row
				lda			*col
				jsr			calc_colx5_scanline			; A=col*5, B=scanline
				tfr			d,x											; X(lsb)=scanline
				tfr			a,b											; B=x_in_2_pixel_incs
				lda			#7											; gold
				jsr			wipe_char								; from video display
				ldb			#2
				lda			#0x50										; add 250
				jsr			update_and_display_score
				;jsr		sub_87e1								; sound
9$:			rts
								
update_sprite_index: ; $6bf4
; A=1st, B=last
				inc			*sprite_index
				cmpa		*sprite_index
				bcs			2$
1$:			sta			*sprite_index				
				rts
2$:			cmpb		*sprite_index
				bcs			1$
				rts				
				
draw_sprite: ; $6c02
				jsr			calc_char_and_addr
				jsr			display_transparent_char
				rts

adjust_x_offset_in_tile:	; $6C13
				lda			*x_offset_within_tile
				cmpa		#2
				bcs			1$
				beq			2$
				dec			*x_offset_within_tile
				jmp			check_for_gold
1$:			inc			*x_offset_within_tile
				jmp			check_for_gold
2$:			rts

adjust_y_offset_within_tile: ; $6C26
				lda			*y_offset_within_tile
				cmpa		#2
				bcs			1$
				beq			2$
				dec			*y_offset_within_tile
				jmp			check_for_gold
1$:			inc			*y_offset_within_tile
				jmp			check_for_gold				
2$:			rts

add_hole_entry:	; $6C39
				lda			#0
				sta			*byte_9c
				lda			*current_row
				inca														; row below
				stb			*col
				sta			*row
				exg			a,b											; A=col, B=row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				lda			#0											; space
				ldb			*col
				ldy			*msb_row_level_data_addr
				sta			b,y
				jsr			display_char_pg1
				lda			#0											; space
				jsr			display_char_pg2
				dec			*row										; row above
				lda			#0											; space
				jsr			display_char_pg1
				inc			*row										; row below
				ldb			#0xff
1$:			incb														; next hole
				cmpb		#0x1e										; max?
				beq			2$											; yes, exit
				ldy			#hole_cnt
				lda			b,y											; empty entry?
				bne			1$											; yes, loop
				lda			*row
				ldy			#hole_row								; store row of hole
				sta			b,y
				lda			*col
				ldy			#hole_col								; store col of hole
				sta			b,y
				lda			#180										; init counter
				ldy			#hole_cnt								; store hole counter
				sta			b,y
				SEC
2$:			rts

handle_guards:	; $6C82
				ldb			*no_guards							; any guards?
				beq			9$											; no, exit
; stuff
				jsr			update_guards
				lda			*level_active						; player killed?
				beq			9$											; yes, skip
; stuff				
9$:			rts

update_guards:	; $6CDB
				inc			*curr_guard
				ldb			*no_guards
				cmpb		*curr_guard							; max?
				bcc			1$											; no, skip
				ldb			#1
				stb			*curr_guard
1$:			jsr			copy_guard_to_curr
				lda			*byte_16
				bmi			check_guard_falling
				beq			check_guard_falling
				dec			*byte_16
				lda			*byte_16
				cmpa		#13
				bcc			save_guard_and_ret
				jmp			loc_6e65				

save_guard_and_ret:	; $6CFB
				ldb			*curr_guard
				ldy			#guard_cnt
				lda			b,y
				beq			2$
				jmp			copy_curr_to_guard
2$:			jmp			loc_6db7
				rts

check_guard_falling:	; $6D08
				ldb			*curr_guard_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*byte_8
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*curr_guard_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#3											; ladder?
				beq			2$											; yes, go
				cmpa		#4											; rope?
				bne			1$											; no, skip
				lda			*curr_guard_y_offset
				cmpa		#2
				beq			2$											; yes, go
1$:			lda			*curr_guard_y_offset
				cmpa		#2
				bcs			handle_guard_falling
				ldb			*curr_guard_row
				cmpb		#15											; bottom row?
				beq			2$											; yes, go
				ldy			#(lsb_row_addr+1)
				lda			b,y											; row below
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9
				ldy			#msb_row_addr_1
				lda			b,y
				sta			msb_row_level_data_addr	; setup tilemap address
				lda			*curr_guard_col
				ldy			*msb_row_level_data_addr
				lda			b,y											; get object from tilemap
				cmpa		#0											; space?
				beq			handle_guard_falling		; yes, go
				cmpa		#9											; player?
				beq			handle_guard_falling		; yes, go
				cmpa		#8											; guard?
				beq			2$											; yes, go
				ldy			*byte_9									; get object from tilemap
				cmpa		#1											; brick?
				beq			2$											; yes, go
				cmpa		#2											; solid?
				beq			2$											; yes, go
				cmpa		#3											; ladder?
				bne			handle_guard_falling		; no, go
2$: ; $6D61
				jmp			calc_guard_movement

handle_guard_falling:	; $ 6D64
				jsr			calc_guard_xychar
				jsr			wipe_char
				jsr			adjust_guard_x_offset
				lda			#6											; =char $36 = fall left
				ldb			*curr_guard_dir					; left?
				bmi			1$											; yes, skip
				lda			#0x0d										; =char $35 = fall right
1$:			sta			*curr_guard_sprite
				inc			*curr_guard_y_offset
				lda			*curr_guard_y_offset
				cmpa		#5
				bcc			loc_6dc0
				lda			*curr_guard_y_offset
				cmpa		#2
				bne			3$
				jsr			check_guard_pickup_gold
				ldb			*curr_guard_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*byte_8
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*curr_guard_col
				ldy			*byte_9
				lda			b,y											; get tilemap object
				cmpa		#1											; brick?
				bne			3$											; no, go
				lda			*byte_16
				bpl			2$
				dec			*no_gold
2$:			lda			*unk_5f
				sta			*byte_16
				lda			#0
				ldb			#0x75										; add 750
				jsr			update_and_display_score
				;jsr			sub_87e1								; sound stuff				
3$:			jsr			calc_guard_xychar
				jsr			display_transparent_char
				jmp			copy_curr_to_guard

loc_6dc0:	; $6DC0
				lda			#0
				sta			*curr_guard_y_offset
				ldb			*curr_guard_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*curr_guard_col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#1											; brick?
				bne			1$											; no, skip
				lda			#0											; space
1$:			ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap				
				inc			*curr_guard_row					; row below
				ldb			*curr_guard_row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*curr_guard_row
				ldy			*msb_row_level_data_addr
				lda			b,y											; get object from tilemap
				cmpa		#9											; player?
				bne			2$											; no, skip
				lsr			*level_active						; kill player
2$:			ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#1											; brick?
				bne			loc_6e58								; no, go
				ldb			*curr_guard_row
				decb														; row above
				stb			*row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*curr_guard_col
				stb			*col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				cmpa		#0											; brick?
				beq			guard_drop_gold								; yes, go
				dec			*no_gold
				jmp			loc_6e46
				
guard_drop_gold:	; $6E31
loc_6e46:	; $6E46
loc_6e58:	; $6E58
								
				rts

loc_6e65:	; $6E65
				cmpa		#7											; byte_16
				bcs			calc_guard_movement
				jsr			calc_guard_xychar
				jsr			wipe_char
				ldb			*byte_16
; stuff				
				rts

somthing:	; $6E7F 
				.db			2, 1, 2, 3, 2, 1

calc_guard_movement:	; $6E85
				rts
												
copy_curr_to_guard:	; $75A8
				ldb			*curr_guard
				lda			*curr_guard_col
				ldy			#guard_col
				sta			b,y
				lda			*curr_guard_row
				ldy			#guard_row
				sta			b,y
				lda			*curr_guard_x_offset
				ldy			#guard_x_offset
				sta			b,y
				lda			*curr_guard_y_offset
				ldy			#guard_y_offset
				sta			b,y
				lda			*byte_16
				ldy			#byte_c70
				sta			b,y
				lda			*curr_guard_dir
				ldy			#guard_dir
				sta			b,y
				lda			*curr_guard_sprite
				ldy			#guard_sprite
				sta			b,y
				rts
								
copy_guard_to_curr:	; $75CE
				ldb			*curr_guard
				ldy			#guard_col
				lda			b,y
				sta			*curr_guard_col
				ldy			#guard_row
				lda			b,y
				sta			*curr_guard_row
				ldy			#guard_x_offset
				lda			b,y
				sta			*curr_guard_x_offset
				ldy			#guard_y_offset
				lda			b,y
				sta			*curr_guard_y_offset
				ldy			#guard_sprite
				lda			b,y
				sta			*curr_guard_sprite
				ldy			#guard_dir
				lda			b,y
				sta			*curr_guard_dir
				ldy			#byte_c70
				lda			b,y
				sta			*byte_16
				rts
				
respawn_guards_and_update_holes: ; $75F4
; stuff
1$:			ldb			#0x1e										; number of holes
check_hole:
				ldy			#hole_cnt
				lda			b,y											; get hole counter
				stb			*byte_88								; save hole#
				tsta														; 6809 only!
				bne			update_hole							; active, go
				jmp			next_hole

update_hole:	; $760f
				dec			b,y											; dec hole counter
				beq			restore_brick
				ldy			#hole_col
				lda			b,y
				sta			*col
				ldy			#hole_row
				lda			b,y
				sta			*row
				ldy			#hole_cnt
				lda			b,y
				cmpa		#20											; counter=20?
				bne			chk_hole_cnt_10					; no, skip
				lda			#0x37										; brick re-fill 0
update_hole_tile:	; $7627
				jsr			display_char_pg2
				lda			*col
				ldb			*row
				jsr			calc_colx5_scanline		
				tfr			d,x											; X(lsb)=scanline
				tfr			a,b											; B=x_in_2_pixel_incs
				lda			#0											; space
				jsr			wipe_char
goto_next_hole: ; $7636				
				jmp			next_hole
chk_hole_cnt_10:	; $7636
				cmpa		#10											; counter=10?
				bne			goto_next_hole					; no, skip
				lda			#0x38										; brick refill 1
				bra			update_hole_tile

restore_brick:	; $7641
				ldb			*byte_88								; hole#
				ldy			#hole_row
				lda			b,y
				sta			*row
				tfr			a,b											; B=row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*byte_88								; hole#
				ldy			#hole_col
				lda			b,y
				sta			*col
				tfr			a,b											; B=col
				ldy			*msb_row_level_data_addr
				lda			b,y											; get object from tilemap
				cmpa		#0											; space?
				bne			1$											; no, skip
				jmp			redisplay_brick
1$:			cmpa		#9											; player?
				bne			2$											; no, skip
				lsr			*level_active						; kill player
2$:			cmpa		#8											; guard?
				beq			4$											; yes, go
				cmpa		#7											; gold?	
				bne			3$											; no, skip
				dec			*no_gold
3$:			jmp			redisplay_brick
4$:
; guard
				jmp			next_hole

redisplay_brick:	; $7701				
				lda			#1											; brick
				ldy			*msb_row_level_data_addr
				sta			b,y											; update tilemap
				jsr			display_char_pg1
				lda			#1											; brick
				jsr			display_char_pg2
				
next_hole:	; $770D
				ldb			*byte_88								; hole#
				decb														; next hole
				bmi			1$											; done? yes, exit
				jmp			check_hole							; loop
1$:			rts				
								
ctrl_m:	; $77AC
				jsr			cls_and_display_high_scores
				ldb			#5
0$:			pshs		b
				ldy			#0
1$:			ldx			#PIA0
				ldb			#0											; all columns
				stb			2,x											; column strobe
				lda			,x											; active low
				coma														; active high
				bne			2$											; key, exit
				leay		-1,y
				bne			1$
				puls		b
				decb
				bne			0$
2$:			HGR1
; stuff to restore pg2 - critical				
				rts
				
cls_and_display_high_scores:	; $786B
				jsr			gcls2
				lda			#HGR2_MSB
				sta			*display_char_page
				lda			#0
				sta			*col
				sta			*row
				jsr			display_message
				.ascii	"    LODE RUNNER HIGH SCORES\r\r\r"
				.ascii	"    INITIALS LEVEL  SCORE\r"
				.ascii	"    -------- ----- --------\r"
				.db			0
				lda			#1
				sta			*byte_55								; counter
1$:			cmpa		#10											; 10th score?
				bne			2$											; no, skip
				lda			#1
				jsr			display_digit
				lda			#0
				jsr			display_digit						; "10"
				bra			3$
2$:			lda			#(0x80|0x20)						; space
				jsr			display_character
				lda			*byte_55
				jsr			display_digit
3$:			jsr			display_message
				.asciz	".    "
; *** start of fudge
				lda			#(0x80|0x4D)
				jsr			display_character				
				lda			#(0x80|0x4D)
				jsr			display_character				
				lda			#(0x80|0x43)
				jsr			display_character		
				jsr			display_message
				.asciz	"    "		
				lda			#42
				jsr			cnv_byte_to_3_digits
				lda			*hundreds
				jsr			display_digit
				lda			*tens
				jsr			display_digit
				lda			*units
				jsr			display_digit
				jsr			display_message
				.asciz	"  "
				lda			#0x31
				jsr			cnv_bcd_to_2_digits
				lda			*tens
				jsr			display_digit
				lda			*units
				jsr			display_digit
				lda			#0x41
				jsr			cnv_bcd_to_2_digits
				lda			*tens
				jsr			display_digit
				lda			*units
				jsr			display_digit
				lda			#0x59
				jsr			cnv_bcd_to_2_digits
				lda			*tens
				jsr			display_digit
				lda			*units
				jsr			display_digit
				lda			#0x26
				jsr			cnv_bcd_to_2_digits
				lda			*tens
				jsr			display_digit
				lda			*units
				jsr			display_digit
; stuff
				jsr			cr
				inc			*byte_55								; next score
				lda			*byte_55
				cmpa		#11											; done all scores?
				bcc			done_hs
				lbra		1$
done_hs:	; $799A				
				HGR2
				lda			#HGR1_MSB
				sta			*display_char_page				
				rts
																																				
cls_and_display_game_status:	; $79AD
				jsr			gcls1
				jsr			gcls2
				lda			*display_char_page			; 0x00/0x20
				ora			#0x1b
				ldb			#0x80										; 0x1b80 = offset
				tfr			d,x				
				lda			#0xaa										; pattern
				ldb			#34											; last column on screen
1$:			sta			0,x           					
				sta			40,x          					
				sta			80,x          					
				sta			120,x										; 4 scanlines of pixels
				inx															; next video address
				decb														; done line?
				bpl			1$											; no, loop
				lda			#16
				sta			*row
				lda			#0
				sta			*col
				jsr			display_message
				.asciz			"SCORE        MEN    LEVEL   "
				jsr			display_no_lives
				jsr			display_level
				ldd			#0x0000									; add 0
				bra			update_and_display_score				

get_line_addr_pgs_1_2: ; $7A3E
				lda			#40
				mul
				stb			*lsb_line_addr_pg1
				stb			*lsb_line_addr_pg2
				ora			#HGR1_MSB
				sta			*msb_line_addr_pg1
				eora		#(HGR1_MSB | HGR2_MSB)
				sta			*msb_line_addr_pg2
				rts
				
gcls1: ; $7A51
				lda			#HGR1_MSB
				ldb			#0
				tfr			d,x											; start addr
				adda		#0x1E
				tfr			d,y											; end addr
				bra			gcls
gcls2:
				lda			#HGR2_MSB
				ldb			#0
				tfr			d,x											; start addr
				adda		#0x1E
				tfr			d,y											; end addr
gcls:		sty			*byte_a
				lda			#0x00
1$:			sta			,x+
				cmpx		*byte_a
				bne			1$
				rts

display_no_lives:	; $7A70
				lda			*no_lives
				ldb			#16											; col=16
display_byte:
				stb			*col
				jsr			cnv_byte_to_3_digits
				lda			#16											; row=16
				sta			*row
				lda			*hundreds
				jsr			display_digit
				lda			*tens
				jsr			display_digit
				lda			*units
				jmp			display_digit

display_level: ; $7A8C
				lda			*level
				ldb			#25											; col=25
				bra			display_byte

update_and_display_score:	; $7A92
				pshs		b
				adda		*score_1e1_1
				daa     		
				sta			*score_1e1_1
				puls		a
				adca		*score_1e3_1e2
				daa     		
				sta			*score_1e3_1e2
				lda			*score_1e5_1e4
				adca		#0
				daa
				sta			*score_1e5_1e4
				lda			*score_1e6
				adca		#0
				daa
				sta			*score_1e6
				lda			#5											; col=5
				sta			*col
				lda			#16											; row=16
				sta			*row
				lda			*score_1e6
				jsr			cnv_bcd_to_2_digits
				lda			*units
				jsr			display_digit
				lda			*score_1e5_1e4
				jsr			cnv_bcd_to_2_digits
				lda			*tens
				jsr			display_digit
				lda			*units
				jsr			display_digit
				lda			*score_1e3_1e2
				jsr			cnv_bcd_to_2_digits
				lda			*tens
				jsr			display_digit
				lda			*units
				jsr			display_digit
				lda			*score_1e1_1
				jsr			cnv_bcd_to_2_digits
				lda			*tens
				jsr			display_digit
				lda			*units
				bra			display_digit

cnv_bcd_to_2_digits: ; $7AE9
				sta			*tens
				anda		#0x0f
				sta			*units
				lda			*tens
				lsra
				lsra
				lsra
				lsra
				sta			*tens
				rts
				
cnv_byte_to_3_digits: ; $7AF8
				ldb			#0
				stb			*tens
				stb			*hundreds
1$:			cmpa		#100
				bcs			2$
				inc			*hundreds
				suba		#100
				bne			1$											; loop counting hundreds
2$:			cmpa		#10
				bcs			3$
				inc			*tens
				suba		#10
				bne			2$											; loop counting tens
3$:			sta			*units									; store units
				rts

display_digit: ; $7B15
				adda		#0x3b										; convert to 'ASCII'
				ldb			*display_char_page
				cmpb		#HGR2_MSB								; page 2?
				beq			1$											; yes, skip
				jsr			display_char_pg1
				inc			*col
				rts
1$:			jsr			display_char_pg2
				inc			*col
				rts				

remap_character: ; $7B2A
				cmpa		#0xc1										; <'A'
				bcs			1$											; yes, go
				cmpa		#0xdB										; <= 'Z'?
				bcs			3$											; yes, go
1$:			ldb			#0x7c
				cmpa		#0xa0										; space?
				beq			2$											; yes, go
				ldb			#0xdb
				cmpa		#0xbe										; >
				beq			2$                  		
				incb                        		
				cmpa		#0xae										; .
				beq			2$                  		
				incb                        		
				cmpa		#0xa8										; (
				beq			2$                  		
				incb                        		
				cmpa		#0xa9										; )
				beq			2$                  		
				incb                        		
				cmpa		#0xaf										; /
				beq			2$                  		
				incb                        		
				cmpa		#0xad										; -
				beq			2$                  		
				incb                        		
				cmpa		#0xbc										; <
				beq			2$                  		
				lda			#0x10               		
				rts                         		
2$:			tfr			b,a                 		
3$:			suba		#0x7c										; zero-based
				rts
			
display_character: ; $7B64
				cmpa		#0x8d										; cr?
				beq			cr											; yes, handle
				jsr			remap_character					; returned in A
				ldb			*display_char_page
				cmpb		#HGR2_MSB								; page 2?
				beq			1$											; yes, skip
				jsr			display_char_pg1
				inc			*col
				rts
1$:			jsr			display_char_pg2
				inc			*col
				rts

cr: ; 7B7D
				inc			*row										; next row
				lda			#0
				sta			*col										; col=0
				rts

display_char_pg1:	; $82AA
; A=char
				sta			*msg_char
				lda			#HGR1_MSB
				bra			display_char
display_char_pg2: ; $82B0
				sta			*msg_char
				lda			#HGR2_MSB
display_char:				
				sta			*hires_page_msb_1
				ldb			*row
				jsr			calc_colx5_scanline			; B=scanline
				stb			*scanline
				ldb			*col
				jsr			calc_col_addr_shift
				sta			*col_addr_offset
				stb			*col_pixel_shift
				lsrb
				ldx			#left_char_masks
				lda			b,x
				sta			*lchar_mask
				ldx			#right_char_masks
				lda			b,x
				sta			*rchar_mask
				jsr			render_char_in_buffer
				ldx			#char_render_buf
				lda			*scanline
				ldb			#40
				mul
				ora			*hires_page_msb_1				; OR-in page address
				tfr			d,y
				ldb			*col_addr_offset
				leay		b,y
				ldb			#11
2$:			lda			0,y
				anda		*lchar_mask
				ora			,x+
				sta			0,y
				lda			1,y
				anda		*rchar_mask
				ora			,x+
				sta			1,y
				leay		40,y
				decb
				bne			2$
				rts

left_char_masks:	; $8328
				.db			0x00, 0xc0, 0xf0, 0xfc
right_char_masks:	; $832F
				.db			0x3f, 0x0f, 0x03, 0x00

wipe_char:	; $8336
; A=char, B=x_in_2_pixel_incs, X(lsb)=scanline
				exg			d,x				
				stb			*scanline
				exg			d,x
				sta			*msg_char
				jsr			calc_addr_shift_for_x		; A=addr, B=shift
				sta			*col_addr_offset
				stb			*col_pixel_shift
				jsr			render_char_in_buffer
				ldb			#11
				stb			*scanline_cnt
;				ldb			#0
				ldy			#char_render_buf
				lda			*col_pixel_shift
wipe_2_byte_char_from_video:
				ldb			*scanline
				jsr			get_line_addr_pgs_1_2
				lda			,y+											; get data from render buffer
				coma														; invert character data
				ldb			*col_addr_offset
				ldx			*msb_line_addr_pg1
				pshs		x
				anda		b,x											; mask off character
				ldx			*msb_line_addr_pg2
				ora			b,x											; OR-in background
				puls		x
				sta			b,x											; update video byte
				incb														; next byte
				lda			,y+											; get data from render buffer
				coma														; invert character data
				ldx			*msb_line_addr_pg1
				pshs		x
				anda		b,x											; mask off character
				ldx			*msb_line_addr_pg2
				ora			b,x											; OR-in background
				puls		x
				sta			b,x											; update video byte
				inc			*scanline
				dec			*scanline_cnt
				bne			wipe_2_byte_char_from_video			
				rts

display_transparent_char:	; $83A7
; A=char, B=x_in_2_pixel_incs, X(lsb)=scanline
				exg			d,x											; X(lsb)=scanline
				stb			*scanline
				exg			d,x
				sta			*msg_char								
				jsr			calc_addr_shift_for_x
				sta			*col_addr_offset
				stb			*col_pixel_shift
				jsr			render_char_in_buffer
				lda			#11
				sta			*scanline_cnt
				lda			#0
				sta			*byte_52
				ldx			#char_render_buf
OR_2_byte_char_to_video:	; $83C3
				ldb			*scanline
				jsr			get_line_addr_pgs_1_2				
				ldb			*col_addr_offset
				ldy			*msb_line_addr_pg1
				lda			b,y											; get video byte
				ldy			*msb_line_addr_pg2
				eora		b,y											; background
				anda		,x											; char render buf
				ora			*byte_52
				sta			*byte_52
				lda			,x											; get byte to be rendered
				ldy			*msb_line_addr_pg1
				ora			b,y
				sta			b,y											; update video byte
				inx															; next render buffer address
				incb														; next video address
				lda			b,y
				ldy			*msb_line_addr_pg2
				eora		b,y
				anda		,x
				ora			*byte_52
				sta			*byte_52
				lda			,x											; get byte to be rendered
				ldy			*msb_line_addr_pg1
				ora			b,y
				sta			b,y											; update video byte
				inx															; next render buffer address
				inc			*scanline
				dec			*scanline_cnt
				bne			OR_2_byte_char_to_video
				rts
								
render_char_in_buffer:	; $8438
				ldx			#char_bank_tbl
				lda			*col_pixel_shift				; 0,2,4,6 (same as word offset)
				ldy			a,x											; ptr entry
				leax		,y											; entry (X=bank address)
				lda			*msg_char
				ldb			#22
				mul															; offset into bank
				leax		d,x											; X=ptr char data
				ldb			#(11*2)
				ldy			#char_render_buf				; destination
1$:			lda			,x+
				sta			,y+
				decb														; done all bytes?
				bne			1$											; no, loop
				rts

char_render_buf:
				.ds			22
				
char_bank_tbl:
				.dw			#tile_data+0*22*104
				.dw			#tile_data+1*22*104
				.dw			#tile_data+2*22*104
				.dw			#tile_data+3*22*104

draw_end_of_screen_ladder:	; $8631
				lda			#0
				sta			eos_ladder_col					; flag ladder OK
				ldb			*no_eos_ladder_tiles
				stb			no_eos_ladder_entries
1$:			ldb			no_eos_ladder_entries		; done last ladder?
				beq			9$											; yes, exit
				ldy			#eos_ladder_col
				lda			b,y											; get col
				bmi			8$											; -1?, yes, ignore
				sta			*col
				ldy			#eos_ladder_row
				lda			b,y
				sta			*row
				tfr			a,b											; B=row
				ldy			#lsb_row_addr
				lda			b,y
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9									; setup tilemap address
				ldb			*col
				ldy			*byte_9
				lda			b,y											; get object from tilemap
				bne			7$											; not a space, skip
				lda			#3											; ladder
				;ldy			*byte_9
				sta			b,y											; update tilemap
				ldy			*msb_row_level_data_addr
				lda			b,y											; get object from tilemap
				bne			4$											; not a space, skip
				lda			#3											; ladder
				sta			b,y											; update tilemap
4$:			lda			#3											; ladder
				jsr			display_char_pg2
				lda			*col
				ldb			*row
				jsr			calc_colx5_scanline			; B=scanline
				tfr			d,x											; X(lsb)=scanline
				tfr			a,b											; B=col*5=x_in_2_pixel_incs
				lda			#3											; ladder
				jsr			display_transparent_char	; update video
				ldb			no_eos_ladder_entries
				lda			#0xff
				ldy			#eos_ladder_col
				sta			b,y											; flag ladder (tile) drawn
				bra			8$
7$:			lda			#1											; flag ladder error
				sta			eos_ladder_col
8$:			dec			no_eos_ladder_entries
				jmp			1$
9$:			lda			eos_ladder_col					; ladder drawn OK?
				bne			91$											; no, skip
				dec			*no_gold								; ???
91$:		rts

no_eos_ladder_entries:
				.ds			1

keybd_flush:	; $869F
; no such concept on the COCO3
; - so wait until no keys pressed
				ldx			#PIA0
				ldb			#0											; all columns
1$:			stb			2,x											; column strobe
				lda			,x											; active low
				coma														; active high
				bne			1$											; keys pressed, loop
				rts
												
display_message:	; $86E0
				puls		x
1$:			stx			*msg_addr								; store msg ptr
				lda			,x											; msg char
				beq			9$											; yes, exit
				ora			#0x80										; *** FUDGE
				jsr			display_character   		
				ldx			*msg_addr								; msg ptr
				inx															; inc
				bra			1$											; loop
9$:			inx															; skip NULL
				pshs		x
				rts

blink_char_and_wait_for_key:	; $8700
				sta			blink_char
1$:			lda			#0x68
				sta			*timer
				lda			#0											; space
				ldb			blink_char
				bne			2$											; not a space, skip
				lda			#0x0a										; solid square
2$:			jsr			display_char_pg1
3$:			ldx			#PIA0
				ldb			#0											; all columns
				stb			2,x											; column strobe
				lda			,x
				coma														; any key pressed?
				bne			blink_got_key						; yes, exit
; read keyboard
				dec			*timer									; timeout?
				bne			3$											; no, loop
				lda			blink_char
				jsr			display_char_pg1
				lda			#0x68
				sta			*timer
; read keyboard
4$:
				dec			*timer								; timeout?
				bne			4$										; no, loop
				bra			1$										; loop waiting for key

blink_got_key:
				pshs		a
				lda			blink_char
				jsr			display_char_pg1
				puls		a
				rts
				
blink_char:
				.db			6
								
read_paddles: ; $87A2
				lda			#0xcb										; no paddles detected?
				sta			*paddles_detected
				rts

play_falling_sound:	; $87BA
; *** TBD
				rts
				
set_row_addr_1_2:	; $884B
				ldy			#lsb_row_addr
				lda			b,y
				sta			*lsb_row_level_data_addr
				sta			*byte_8
				ldy			#msb_row_addr_1
				lda			b,y
				sta			*msb_row_level_data_addr
				ldy			#msb_row_addr_2
				lda			b,y
				sta			*byte_9
				rts
				
calc_colx5_scanline:	; $885d
; A=col, B=row
				pshs		a												; save col
				ldy			#row_to_scanline_tbl
				lda			b,y											; A=scanline
				puls		b												; B=col
				pshs		a												; save scanline
				ldy			#col_x_5_tbl
				lda			b,y											; A=col*5
				puls		b												; B=scanline
				rts

calc_col_addr_shift:	; $8868
				ldx			#col_to_addr_tbl
				lda			b,x											; A=col address
				aslb
				andb		#0x06										; B=shift
				rts

calc_addr_shift_for_x:	; $8872
; B=x_in_2_pixel_incs
				tfr			b,a
				lsra
				lsra														; A=addr
				lslb
				andb		#7											; B=shift
				rts
				
calc_scanline: ; $887C
; A=y_offset_within_tile, B=row
				pshs		a												; save y_offset_within_tile
				jsr			calc_colx5_scanline			; B=scanline
				puls		a												; restore y_offset_within_tile
				ldy			#byte_888a
				addb		a,y											; B=scanline
				rts

byte_888a:
				.db			-5, -3, 0, 2, 4
								
calc_x_in_2_pixel_incs: ; $888F
; A=col, B=x_offset_within_tile
				pshs		b												; save x_offset_within_tile
				jsr			calc_colx5_scanline			; A=colx5
				tfr			a,b											; B=colx5
				puls		a												; restore x_offset_within_tile
				ldy			#byte_889d
				addb		a,y											; B=x as count of 2-pixel increments
				rts

byte_889d:
				.db			-2, -1, 0, 1, 2
								
wipe_or_draw_level:	; $88A2
				jsr			display_no_lives
				jsr			display_level
; nothing like the 6502 code!
				lda			#HGR2_MSB
				clrb
				tfr			d,x
				adda		#0x1b
				orb			#0x80										; end addr (line 176)
				tfr			d,y
				sty			*byte_a
				lda			#HGR1_MSB
				clrb
				tfr			d,y
1$:			lda			,x+
				sta			,y+
				cmpx		*byte_a
				bne			1$
				rts

game_over_animation:	; $8B1A
				lda			#8
				sta			*row
				lda			#8
				sta			*col
				jsr			display_message
				.asciz			" GAME OVER "
				rts

attract_move_tbl:	; $9B00
				.db 		0x16, 0x4C, 0x66, 2, 0x55, 1, 0x66, 2, 0x36, 0x18, 0x55, 1, 0x44, 1
				.db 		0x66, 0x14, 0x36, 0xD, 0x30, 0x17, 0x60, 8, 0x66, 3, 0x16, 0x16, 0x66
				.db 		4, 0x36, 0x23, 0x32, 1, 0x62, 1, 0x55, 1, 0x66, 0x20, 0x16, 7, 0x66
				.db 		2, 0x36, 0x25, 0x30, 0x14, 0x60, 0xE, 0x10, 0x11, 0x16, 0x25, 0x10, 8
				.db 		0x16, 0x23, 0x10, 6, 0x60, 2, 0x30, 0xF, 0x36, 0x17, 0x66, 2, 0x16, 7
				.db 		0x55, 1, 0x66, 0x1E, 0x16, 0x38, 0x44, 1, 0x16, 5, 0x44, 1, 0x16, 7
				.db 		0x44, 1, 0x36, 7, 0x55, 1, 0x36, 4, 0x55, 1, 0x16, 3, 0x55, 1, 0x16
				.db 		3, 0x36, 0xB, 0x55, 1, 0x16, 3, 0x36, 0xE, 0x44, 1, 0x66, 1, 0x60, 0xC
				.db 		0x30, 0x29, 0x60, 2, 0x44, 1, 0x16, 0x2B, 0x10, 4, 0x60, 5, 0x30, 1
				.db 		0x36, 0x67, 0x32, 1, 0x44, 1, 0x66, 0x2B, 0x36, 0xC, 0x30, 0x15, 0x36
				.db 		0x12, 0x55, 1, 0x16, 3, 0x55, 1, 0x36, 5, 0x55, 1, 0x16, 3, 0x36, 8
				.db 		0x66, 2, 0x16, 0x4A, 0x10, 4, 0x60, 7, 0x30, 9, 0x36, 0x15, 0x66, 0xA
				.db 		0x16, 0xD, 0x44, 1, 0x66, 2, 0x16, 4, 0x44, 1, 0x16, 2, 0x44, 6, 0x16
				.db 		4, 0x44, 1, 0x16, 2, 0x62, 0x15, 0x36, 0x31, 0x66, 1, 0x62, 4, 0x12
				.db 		6, 0x44, 1, 0x66, 0x37, 0x36, 1, 0x30, 0x1D, 0x60, 0x33, 0x36, 0x32
				.db 		0x66, 3, 0x16, 1, 0x10, 0x1B, 0x60, 5, 0x36, 0x28, 0x44, 1, 0x66, 0x1F
				.db 		0x36, 0x14, 0x44, 1, 0x55, 1, 0x66, 0x2D, 0x36, 1, 0x30, 0x12, 0x60
				.db 		0x25, 0x66, 1, 0x55, 1, 0x16, 0xD, 0x66, 2, 0x36, 9, 0x30, 0xA, 0x36
				.db 		4, 0x44, 1, 0x36, 3, 0x44, 1, 0x36, 3, 0x16, 0x22, 0x44, 1, 0x16, 7
				.db 		0x44, 4, 0x16, 3, 0x44, 1, 0x16, 0x27, 0x12, 0xE, 0x16, 0x1E, 0x55, 1
				.db 		0x66, 0x19, 0x36, 1, 0x30, 3, 0x60, 7, 0x10, 0x1F, 0x60, 7, 0x30, 9
				.db 		0x36, 0x33, 0x66, 4, 0x10, 9, 0x16, 8, 0x12, 1, 0x62, 0xC, 0x32, 1
				.db 		0x36, 0x32, 0x44, 1, 0x16, 0xB, 0x44, 1, 0x16, 9, 0x44, 1, 0x10, 0x2C
				.db 		0x60, 4, 0x30, 3, 0x36, 0xA, 0x44, 1, 0x16, 5, 0x44, 1, 0x36, 3, 0x44
				.db 		1, 0x36, 3, 0x44, 1, 0x66, 3, 0x36, 3, 0x55, 1, 0x36, 8, 0x55, 1
				.db 		0x66, 0x4C, 0x16, 9, 0x10, 0x15, 0x44, 1, 0x10, 0x2F, 0x16, 9, 0x12
				.db 		3, 0x16, 0x12, 0x66, 2, 0x36, 6, 0x66, 0x2D, 0x55, 1, 0x16, 3, 0x10
				.db 		0x1C, 0x55, 1, 0x16, 3, 0x44, 1, 0x36, 3, 0x32, 0x15, 0x36, 0xB, 0x30
				.db 		0xB, 0x60, 0xC, 0x44, 1, 0x62, 0xD, 0x12, 2, 0x16, 0xD, 0x44, 1, 0x66
				.db 		0x20, 0x36, 4, 0x30, 0x17, 0x36, 0x1E, 0x44, 1, 0x36, 0x2F, 0x30, 8
				.db 		0x60, 3, 0x10, 0x22, 0x16, 0x1B, 0x66, 0x26, 0x55, 7, 0x16, 3, 0x55
				.db 		1, 0x66, 0x1D, 0x16, 2, 0x10, 0x85, 0x60, 2, 0x30, 3, 0x36, 3, 0x32
				.db 		0xF, 0x36, 3, 0x30, 0xC, 0x36, 0x20, 0x66, 1, 0x16, 0xA, 0x60, 6, 0x66
				.db 		2, 0x36, 8, 0x30, 5, 0x60, 2, 0x66, 2, 0x16, 8, 0x10, 1, 0x60, 6
				.db 		0x66, 1, 0x36, 8, 0x30, 4, 0x60, 3, 0x66, 1, 0x16, 8, 0x10, 2, 0x60
				.db 		3, 0x30, 1, 0x36, 8, 0x30, 3, 0x60, 3, 0x16, 9, 0x10, 2, 0x60, 3
				.db 		0x30, 3, 0x36, 7, 0x30, 3, 0x60, 2, 0x10, 2, 0x16, 8, 0x10, 1, 0x60
				.db 		2, 0x30, 2, 0x36, 0xA, 0x30, 2, 0x60, 2, 0x10, 3, 0x16, 4, 0x10, 3
				.db 		0x60, 5, 0x30, 2, 0x36, 7, 0x66, 0x16, 0x36, 2, 0x66, 0x33, 0x55, 1
				.db 		0x36, 5, 0x55, 1, 0x36, 4, 0x55, 1, 0x36, 3, 0x55, 1, 0x36, 3, 0x55
				.db 		1, 0x66, 0xA9, 0x62, 0xC, 0x66, 7, 0x60, 0xF, 0x55, 1, 0x66, 0x18, 0x16
				.db 		0x2A, 0x55, 1, 0x16, 3, 0x66, 1, 0x60, 7, 0x66, 3, 0x36, 3, 0x30, 0x1B
				.db 		0x36, 8, 0x44, 1, 0x66, 0x18, 0x36, 0xF, 0x66, 8, 0x44, 1, 0x66, 0x38
				.db 		0x30, 0xE, 0x66, 0x11, 0x60, 4, 0x66, 0x49, 0x37, 3, 0, 0, 0, 0, 0
				.db 		0x30, 3, 0, 0, 0, 0, 0, 0x33, 7, 0, 0, 0, 0, 0, 0x30, 3, 0, 0
				.db 		0, 0, 0, 0x37, 3, 0, 0, 0, 0, 0, 0x30, 3, 0, 0, 0, 0, 0, 0x33
				.db 		7, 0, 0, 0, 0, 0, 0x30, 3, 0, 0, 0, 0, 0, 0x37, 3, 0, 0, 0, 0
				.db 		0, 0x30, 3, 0, 0, 0, 0, 0, 0x33, 7, 0, 0, 0, 0, 0, 0x30, 3, 0
				.db 		0, 0, 0, 0, 0x37, 3, 0, 0, 0, 0, 0, 0x30, 3, 0, 0, 0, 9, 0, 0x33
				.db 		7, 0, 0, 0, 0, 0, 0x30, 3, 0, 0x30, 0x11, 0x11, 0x11, 0x11, 0x11
				.db 		0x11, 0x11, 0x11, 3, 0, 0x30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				.db 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				.db 		0
									
; zero-page registers
.include "zeropage.asm"

eos_ladder_col:	; $C00
					.ds		0x30
eos_ladder_row:	; $C30
					.ds		0x30
guard_col:	; $C60
					.ds		8					
guard_row:	; $C68
					.ds		8					
byte_c70:	; $C70
					.ds		8					
guard_x_offset:	; $C78
					.ds		8					
guard_y_offset:	; $C80
					.ds		8					
guard_sprite:	; $C88
					.ds		8					
guard_dir:	; $C90
					.ds		8					
guard_cnt:	; $C98
					.ds		8					
hole_col:	; $CA0
					.ds		0x20
hole_row:	; $CC0
					.ds		0x20
hole_cnt:	; $CE0
					.ds		0x20

lsb_row_addr:	; $1C05
					.db		<(ldu1+0*28), <(ldu1+1*28), <(ldu1+2*28), <(ldu1+3*28)
					.db		<(ldu1+4*28), <(ldu1+5*28), <(ldu1+6*28), <(ldu1+7*28)
					.db		<(ldu1+8*28), <(ldu1+9*28), <(ldu1+10*28), <(ldu1+11*28)
					.db		<(ldu1+12*28), <(ldu1+13*28), <(ldu1+14*28), <(ldu1+15*28)
msb_row_addr_1: ; $1C15
					.db		>(ldu1+0*28), >(ldu1+1*28), >(ldu1+2*28), >(ldu1+3*28)
					.db		>(ldu1+4*28), >(ldu1+5*28), >(ldu1+6*28), >(ldu1+7*28)
					.db		>(ldu1+8*28), >(ldu1+9*28), >(ldu1+10*28), >(ldu1+11*28)
					.db		>(ldu1+12*28), >(ldu1+13*28), >(ldu1+14*28), >(ldu1+15*28)
msb_row_addr_2:	; $1C25
					.db		>(ldu2+0*28), >(ldu2+1*28), >(ldu2+2*28), >(ldu2+3*28)
					.db		>(ldu2+4*28), >(ldu2+5*28), >(ldu2+6*28), >(ldu2+7*28)
					.db		>(ldu2+8*28), >(ldu2+9*28), >(ldu2+10*28), >(ldu2+11*28)
					.db		>(ldu2+12*28), >(ldu2+13*28), >(ldu2+14*28), >(ldu2+15*28)

col_x_5_tbl:	; $1C35
					.db 	0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75
					.db 	80, 85, 90, 95, 100, 105, 110, 115, 120, 125, 130, 135

row_to_scanline_tbl:	; $1c51
				.db			0, 11, 22, 33, 44, 55, 66, 77, 88, 99, 110, 121
				.db			132, 143, 154, 165, 181

col_to_addr_tbl:	; $1c62
				.db			0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16
				.db			17, 18, 20, 21, 22, 23, 25, 26, 27, 28, 30, 31, 32, 33

; 			.nlist
; .include "tiles.asm"
; .include "title.asm"
; .include "levels.asm"

				.nlist

.ifndef TILES_EXTERNAL				
.include "tiles.asm"
.else
tile_data	.equ	0x8000
.endif

.ifdef HAS_TITLE
	.include "title.asm"
.endif

.include "levels.asm"

				.list

end_of_data	.equ		.

; this was in low memory on the apple

level_data_packed:
				.ds		256
				
				.bndry	512
level_data_unpacked_1:
ldu1:
				.ds			512
level_data_unpacked_2:
ldu2:
				.ds			512
				
				.end		start
			