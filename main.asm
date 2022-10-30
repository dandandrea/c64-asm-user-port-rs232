PRINT_LINE = $AB1E
CHKIN = $FFC6
CHRIN = $FFCF
CHKOUT = $ffc9
CHROUT = $FFD2
SETLFS = $FFBA
SETNAM = $FFBD
OPEN = $FFC0

OUT_ISR = $0400
OUT_DATA_EVERY = $0401
OUT_DATA_ONCE = $0402

numint = #2; 60 interrupts per second on NTSC C64

* = $1000
        ; Install custom ISR

        ; Disable interrupts
        sei

        ; Make copy of original interrupt routine's address
        lda $0314
        sta ORIGISRLO
        lda $0315
        sta ORIGISRHI

        ; Point the machine to our new interrupt routine
        lda #<MAIN
        sta $0314
        lda #>MAIN
        sta $0315

        ; Enable interrupts
        cli

        ; Configure RS-232 output

        ; SETLFS
        lda #2          ; file #
        ldx #2          ; 2 = rs-232 device
        ldy #0
        jsr SETLFS              

        ; SETNAM alternative
        lda #%00001000
        sta $0293

        ; OPEN
        jsr OPEN

        ; CHKOUT
        ldx #2
        jsr CHKOUT

L1      sei
        lda OUT_DATA_ONCE
        cmp #0
        beq L2

        cli
        lda OUT_DATA_ONCE
        adc #63
        jsr CHROUT
        sei
        lda #0
        sta OUT_DATA_ONCE

L2      cli
        jmp L1

        ; Done
        rts

MAIN
        ; Acknowledge IRQ
        dec $d019

        ; Save register values
        pha ; a
        txa
        pha ; x
        tya
        pha ; y

        ; Do a thing (every interrupt)
        lda DATA
        sta OUT_DATA_EVERY

        lda counter
        sta OUT_ISR

        ; nth interrupt?
        lda counter
        cmp numint
        bne notn

        ; Do another thing (every n interrupts)
        ; Transmit byte
        lda DATA
        sta OUT_DATA_ONCE

        ; Do another thing (every n interrupts)
        inc DATA

        ; DATA overflow?
        lda DATA
        cmp #27
        bne nooverflow

        lda #1
        sta DATA

nooverflow
        ; Reset counter
        lda #$ff
        sta counter

notn
        ; Increment the counter
        inc counter

        ; Restore register values
        pla ; y
        tay
        pla ; x
        tax
        pla ; a

        ; Done, now call original interrupt routine
        jmp (ORIGISRLO) ; Now call the original interrupt routine

ORIGISRLO
        BYTE 0

ORIGISRHI
        BYTE 0

counter BYTE 0

DATA    BYTE 1