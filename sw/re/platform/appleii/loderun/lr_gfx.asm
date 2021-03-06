;
;	LODE RUNNER - TITLE_DATA
; - ported from the original Apple II version
; - by tcdev 2014 msmcdoug@gmail.com
;
				.list		(meb)										; macro expansion binary
				
       	.area   idaseg (ABS)

.include "coco3.asm"

        ; $4000
        .org    MMUTSK1+2
        .db     GFXPAGE, GFXPAGE+1

        .org    tile_data-0x4000
        
.ifdef GFX_1BPP
  .include "tile_data_m1bpp.asm"
.else
  .ifdef GFX_MONO
    .include "tile_data_m2bpp.asm"
  .else
    .include "tile_data_c2bpp.asm"
  .endif
.endif       
        
        .org    title_data-0x4000

.ifdef GFX_1BPP
  .include "title_data_m1bpp.asm"
.else
  .ifdef GFX_MONO
    .include "title_data_m2bpp.asm"
  .else
    .include "title_data_c2bpp.asm"
  .endif
.endif

				.org		gameover_data-0x4000

.ifdef GFX_1BPP
  .include "gameover_data_m1bpp.asm"
.else
  .ifdef GFX_MONO
    .include "gameover_data_m2bpp.asm"
  .else
    .include "gameover_data_c2bpp.asm"
  .endif
.endif

; end of page $37 which appears on HGR1
; due to video offset in GIME registers
				.org		0x7ff0
				.db			0, 0, 0, 0, 0, 0, 0, 0
				.db			0, 0, 0, 0, 0, 0, 0, 0
				  
        ; $4000,$6000
        .org    MMUTSK1+2
        .db     VIDEOPAGE+2, VIDEOPAGE+3
