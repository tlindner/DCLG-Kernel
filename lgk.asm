         org $7000
vert  rmb 1
horz  rmb 2
palette rmb 16
border rmb 1
start
    NOP
    clr vert
    clr horz
    clr horz+1
    ldb #16		copy palette registers
    ldx #$ffb0
    ldy #palette
pal_loop
    lda ,x+
    anda #$3f
    sta ,y+
    decb
    bne pal_loop
    lda $ff9a
    anda #$3f
    sta border

    ORCC #$50	disable interrupts
    CLR $FF93	clear gime firq interrupts
    LDA #$34
    STA $FF23	silence coco speaker
    LDX #$FF00	load pointers to PIA
    LDY #$FF03
    LDD #$3C34
    STA $FF01	PIA 0 CA2 goes hi, access output regs
    STB $FF03	PIA 0 CB2 goes lo, access output regs, 4 way position: 1 (left vert)
* clock light gun interface box 16 times, looking for state 16
    LDB #$10
start_loop
    JSR clock	Clock serial hi, then lo
    JSR test_comp	test comparator
    BMI device_syncd
    DECB
    BNE start_loop	loop until we find proper state
    lbra clean_up

device_syncd
    LDB #$08	Clock serial 8 times
clk_loop
    JSR   clock	Clock serial hi, then lo
    DECB
    BNE clk_loop
* we are now in state 7
    LDA #$50	set dac to 20
    JSR set_dac	Write A to DAC
    LDD #$343D
    STA $FF01	CA2 to lo
    STB $FF03	CB2 to hi (set joystick), interrupt on frame sync
    TST $FF00
    TST $FF02
    SYNC			wait for frame sync
    TST $FF02
    STA $FF03	turn off frame sync interrupt
    STB $FF01	turn on horizontal sync interrupt
    JSR clock3	clock serial high
    LDD #$3F3F	white color
    STA $FF9A	coco3 border register
    STD $FFB0	coco 3 palette registers
    STD $FFB2
    STD $FFB4
    STD $FFB6
    STD $FFB8
    STD $FFBA
    STD $FFBC
    STD $FFBE
    LDB #$CE	preload line counter to -50
line_loop
    SYNC			wait for horizontal sync
    TST ,X		(x == FF00)
    BMI found_signal	branch if comparator set
    INCB			increment b for each scan line
    TST ,Y		(y == FF03)
    BPL line_loop	branch if not end of frame
    NOP
done
    JMP clean_up

found_signal
    STB   vert
    JSR   clock2	clock serial hi to low
    LDA   #$35
    STA   $FF01	pia 0, cb2 is low
    SYNC
    SYNC
    SYNC
    LDA   #$50	dac value: 20
    JSR   set_dac	Write A to DAC
    LDA   #$14
    CLRB
    JSR   pause	delay loop (uses X)
    ASL   $FF00
    ROLB
    STB   horz
    BEQ   skip
    LDA   #$B4	dac value 45
skip
    BSR   set_dac	Write A to DAC
    JSR   pause	delay loop (uses X)
    ASL   $FF00
    ROR   horz+1
    BSR   clock_alt	clock serial lo
    LDA   #$14	dac value 5
    BSR   set_dac	Write A to DAC
    LDB   #$07
read_loop
    JSR   pause	delay loop (uses X)
    ASL   $FF00
    ROR   horz+1
    BSR   clock	Clock serial hi, then lo
    DECB
    BNE read_loop	loop back (read 7 times)

clean_up
    LDA   #$02	set serial high
    STA   $FF20
    LDA   #$3C	turn sound back on
    STA   $FF23

    ldb #16		copy palette registers
    ldx #$ffb0
    ldy #palette
clean_loop
    lda ,y+
    sta ,x+
    decb
    bne clean_loop
    lda border
    sta $ff9a
    CLR $FF93	clear gime firq interrupts
    LDD #$3C34
    STA $FF01	PIA 0 CA2 goes hi, access output regs
    STB $FF03	PIA 0 CB2 goes lo, access output regs, 4 way position: 1 (left vert)
    andcc #$af
    rts

clock
    BSR clock3
clock_alt
    LDA   $FF20	get rs232 / dac
    ANDA  #$FD	clear tx
    BRA clck_continue
clock2
    BSR   clock_alt
clock3
    LDA   $FF20
    ORA   #$02	set rs232 tx high
clck_continue
    STA   $FF20	send to rs232
    LDA   #$0A
clck_loop
    DECA
    BNE   clck_loop
    RTS

set_dac
    PSHS  A		save dac value for later
    LDA   $FF20	get pia value
    ANDA  #$03	keep serial and cassette
    ORA   ,S+		or in bits provided, adjust stack pointer
    STA   $FF20
    LDA   #$32	wait for comparator to settle
sd_loop
    DECA
    BNE   sd_loop
    RTS

test_comp
    LDA #$50	new dac value (20)
    BSR set_dac	write A to dac
    LDA #$14	new dac value (5)
    TST $FF00	test negative flag on comparator output
    BPL tc_1
    LDA #$84	new dac value (33)
tc_1
    BSR set_dac	write a to dac
    LDA $FF00
    RTS

pause
    LDX #$00C8
ps_loop
    LEAX -$1,X
    BNE ps_loop
    RTS
    end start
