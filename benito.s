;VAL_FAC_M65RATERTL	=	$FD90
;VAL_FAC_M65RATERTH	=	$0134

	.define		DEF_BEN_USEXEMU	0


VAL_BEN_CNTPALCS	=	985248
VAL_BEN_CNTNTSCS	=	1022730

VAL_BEN_DEFPPQNT	=	96


ptrBenitoA32		=	$80
ptrBenitoB32		=	$84

ptrBenitoReg		=	$88
ptrBenitoVal		=	$8C
ptrBenitoStat		=	$98

OPL2M65				=	$FE00000
OPL2REG				=	$7FFDF40
OPL2VAL				=	$7FFDF50
OPL2STT				=	$7FFDF60


ptrBenitoPBDat32	=	$90
ptrBenitoPBDes16	=	$94


	.macro	__BEN_DIV_IMM32_IMM32 imm0, imm1
		LDA	#<(.loword(imm0))
		STA	$D770
		LDA	#>(.loword(imm0))
		STA	$D771
		LDA	#<(.hiword(imm0))
		STA	$D772
		LDA	#>(.hiword(imm0))
		STA	$D773

		LDA	#<(.loword(imm1))
		STA	$D774
		LDA	#>(.loword(imm1))
		STA	$D775
		LDA	#<(.hiword(imm1))
		STA	$D776
		LDA	#>(.hiword(imm1))
		STA	$D777

		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020

;	Result in $D768/C
	.endmacro


	.macro	__BEN_DIV_MEM32_IMM32 mem, imm
		LDA	mem
		STA	$D770
		LDA	mem + 1
		STA	$D771
		LDA	mem + 2
		STA	$D772
		LDA	mem + 3
		STA	$D773

		LDA	#<(.loword(imm))
		STA	$D774
		LDA	#>(.loword(imm))
		STA	$D775
		LDA	#<(.hiword(imm))
		STA	$D776
		LDA	#>(.hiword(imm))
		STA	$D777

		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020

;	Result in $D768/C
	.endmacro

	.macro	__BEN_WRITE_OPL_REG_IMM	reg, val
		LDA	#reg
		STA	valBenOPLReg
		LDA	#val
		STA	valBenOPLVal
		JSR	_write_OPL

;		JSR	_wait_OPL
	.endmacro


;Pulses per "quarter note"
valBenPPQN:
	.word		VAL_BEN_DEFPPQNT

;Pulses per "32nd note"
valBenPP32:
	.word		VAL_BEN_DEFPPQNT / 8
valBenPP64:
	.word		VAL_BEN_DEFPPQNT / 16

valBenTmp0:
	.dword		$00000000
valBenTmp1:
	.dword		$00000000

valBenLen0:
	.byte		$00
valBenBuf0:
	.repeat	128
	.byte		$00
	.endrepeat

valBenEvB0:
	.byte		$02, $02, $02, $02, $01, $01, $02, $FF

valBenSyB0:
	.byte		$FF, $01, $02, $01, $00, $00, $00, $00
	.byte		$00, $00, $00, $00, $00, $00, $00, $FF

valBenDbg0:
	.byte		$00


valBenInstOfs:
	.repeat	16
	.byte		$00
	.endrepeat

valBenOpOffsets:
	.byte		0, 3, 1, 4
	.byte		2, 5, 8, 11
	.byte		9, 12, 10, 13
	.byte		16, 19, 17, 20
	.byte		18, 21

valBenNoteFreqs:
	.word		$200, $21E, $23F, $261
	.word		$285, $2AB, $2D4, $300
	.word		$32E, $35E, $390, $3C7

valBenMDVDRState:
	.byte		$00

valBenRhythmOp:
	.byte		$00, $00, $14, $12, $15, $11

valBenRhythmChn:
	.byte		$00, $00, $07, $08, $08, $07

valBenMDVDRtbl:
	.byte		$00, $10, $08, $04, $02, $01

valBenOPLReg:
	.byte		$00
valBenOPLVal:
	.byte		$00

valBenChnAlloc:
	.byte		$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
valBenChnNote:
	.byte		$00, $00, $00, $00, $00, $00, $00, $00, $00
valBenChnB0Reg:
	.byte		$00, $00, $00, $00, $00, $00, $00, $00, $00


;-----------------------------------------------------------
benitoInit:
;-----------------------------------------------------------
		LDA	#<.loword(OPL2REG)
		STA	ptrBenitoReg
		LDA	#>.loword(OPL2REG)
		STA	ptrBenitoReg + 1
		LDA	#<.hiword(OPL2REG)
		STA	ptrBenitoReg + 2
		LDA	#>.hiword(OPL2REG)
		STA	ptrBenitoReg + 3
		LDA	#<.loword(OPL2VAL)
		STA	ptrBenitoVal
		LDA	#>.loword(OPL2VAL)
		STA	ptrBenitoVal + 1
		LDA	#<.hiword(OPL2VAL)
		STA	ptrBenitoVal + 2
		LDA	#>.hiword(OPL2VAL)
		STA	ptrBenitoVal + 3

		LDA	#<.loword(OPL2STT)
		STA	ptrBenitoStat
		LDA	#>.loword(OPL2STT)
		STA	ptrBenitoStat + 1
		LDA	#<.hiword(OPL2STT)
		STA	ptrBenitoStat + 2
		LDA	#>.hiword(OPL2STT)
		STA	ptrBenitoStat + 3

.if		DEF_BEN_USEXEMU
		LDA	#<.loword(OPL2M65)
		STA	ptrBenitoReg
		LDA	#>.loword(OPL2M65)
		STA	ptrBenitoReg + 1
		LDA	#<.hiword(OPL2M65)
		STA	ptrBenitoReg + 2
		LDA	#>.hiword(OPL2M65)
		STA	ptrBenitoReg + 3
.endif

		__BEN_WRITE_OPL_REG_IMM $c0, $f0
		__BEN_WRITE_OPL_REG_IMM $c1, $f0
		__BEN_WRITE_OPL_REG_IMM $c2, $f0
		__BEN_WRITE_OPL_REG_IMM $c3, $f0
		__BEN_WRITE_OPL_REG_IMM $c4, $f0
		__BEN_WRITE_OPL_REG_IMM $c5, $f0
		__BEN_WRITE_OPL_REG_IMM $c6, $f0
		__BEN_WRITE_OPL_REG_IMM $c7, $f0
		__BEN_WRITE_OPL_REG_IMM $c8, $f0

		__BEN_WRITE_OPL_REG_IMM $B0, $00
		__BEN_WRITE_OPL_REG_IMM $B1, $00
		__BEN_WRITE_OPL_REG_IMM $B2, $00
		__BEN_WRITE_OPL_REG_IMM $B3, $00
		__BEN_WRITE_OPL_REG_IMM $B4, $00
		__BEN_WRITE_OPL_REG_IMM $B5, $00
		__BEN_WRITE_OPL_REG_IMM $B6, $00
		__BEN_WRITE_OPL_REG_IMM $B7, $00
		__BEN_WRITE_OPL_REG_IMM $B8, $00

		__BEN_WRITE_OPL_REG_IMM	$01, $00
		__BEN_WRITE_OPL_REG_IMM	$BD, $00
		__BEN_WRITE_OPL_REG_IMM	$08, $00
		__BEN_WRITE_OPL_REG_IMM	$01, $20

		__BEN_WRITE_OPL_REG_IMM	$C0, $F0
		__BEN_WRITE_OPL_REG_IMM	$B0, $00
		__BEN_WRITE_OPL_REG_IMM	$20, $01
		__BEN_WRITE_OPL_REG_IMM	$23, $01
		__BEN_WRITE_OPL_REG_IMM	$60, $E4
		__BEN_WRITE_OPL_REG_IMM	$63, $E4
		__BEN_WRITE_OPL_REG_IMM	$80, $9D
		__BEN_WRITE_OPL_REG_IMM	$83, $9D
		__BEN_WRITE_OPL_REG_IMM	$A0, $AC
		__BEN_WRITE_OPL_REG_IMM	$B0, $2A

		RTS


;-----------------------------------------------------------
benitoPrepare:
;-----------------------------------------------------------
		LDX	#$08
		LDA	#$FF
@loop2:
		STA	valBenChnAlloc, X
		DEX
		BPL	@loop2

		LDY	#$0F
		LDA	#$00
@loop0:
		STA	valBenInstOfs, Y
		DEY
		BPL	@loop0

		STA	valBenTmp0 + 1

		LDZ	#$0A
		NOP
		LDA	(ptrPatchData), Z

		STA	valBenTmp0

		LDY	#$00
@loop1:
		TYA
		CLC
		ADC	#$0B
		TAZ

		NOP
		LDA	(ptrPatchData), Z
		DEC

		TAX

		TYA
		ASL
		ASL
		ASL
		ASL

		CLC
		ADC	#$13

		STA	valBenInstOfs, X

		CLC
		ADC	#$0D

		TAZ
		NOP
		LDA	(ptrPatchData), Z

		ORA	valBenTmp0 + 1
		STA	valBenTmp0 + 1

		INY
		CPY	valBenTmp0
		BNE	@loop1

;		FIXME:  limit hardware channels to 9

		LDA	valBenTmp0 + 1
		BEQ	@cont0

;		FIXME:  limit hardware channels to 6

		LDA	#$20

@cont0:
		STA	valBenMDVDRState

		LDA	#$BD
		STA	valBenOPLReg
		LDA	valBenMDVDRState
		STA	valBenOPLVal
		JSR	_write_OPL

		RTS


;-----------------------------------------------------------
benitoStop:
;-----------------------------------------------------------

		RTS


;-----------------------------------------------------------
benitoEvent:
;-----------------------------------------------------------
;@halt:
;		INC	$D020
;		JMP	@halt

		LDA	valBenBuf0
		AND	#$F0

		CMP	#$80
		BNE	@tstnoteon

@noteoff:
		JSR	_benitoNoteOff
		RTS

@tstnoteon:
		CMP	#$90
		BNE	@tstcntrlr

;		LDA	valBenBuf0 + 2
;		BEQ	@noteoff
		JSR	_benitoNoteOn
		RTS

@tstcntrlr:
		CMP	#$B0
		BNE	@tstprogram

;		JSR	_benitoCCChange
		JSR	_benitoNoteOff
		RTS

@tstprogram:
		CMP	#$C0
		BNE	@exit

;		JSR	_benitoPrgChange
		JSR	_benitoNoteOff

@exit:
		RTS


;-----------------------------------------------------------
_benitoCCChange:
;-----------------------------------------------------------

		RTS


;-----------------------------------------------------------
_benitoPrgChange:
;-----------------------------------------------------------

		RTS


;-----------------------------------------------------------
_allocate_hw_chan:
;-----------------------------------------------------------
		LDX	#$00

@loop:
		LDA	valBenChnAlloc, X
		BMI	@found

		INX
		CPX	#$09
		BNE	@loop

;		LDX	#$FF
;		SEC

		LDX	#$02
		CLC

		RTS

@found:
		CLC
		RTS



;-----------------------------------------------------------
_write_OPL:
;-----------------------------------------------------------
		LDA	valBenOPLReg


;		CMP	#$BD
;		BEQ	@exit

;.if .not DEF_BEN_USEXEMU
		AND	#$F0
		CMP	#$C0
		BNE	@start

		LDA	valBenOPLVal
		ORA	#$30
		STA	valBenOPLVal

;		LDA	valBenOPLVal
;		CMP	#$F0
;		BEQ	@start
;		RTS
;.endif


@start:
		PHZ

.if		DEF_BEN_USEXEMU
		LDZ	valBenOPLReg
		LDA	valBenOPLVal
		NOP
		STA	(ptrBenitoReg), Z
		STA	$D020
		PLZ
		JSR	_wait_OPL
		RTS
.endif

		LDZ	#$00
		LDA	valBenOPLReg
		NOP
		STA	(ptrBenitoReg), Z

		JSR	_wait_short_OPL

		LDA	valBenOPLVal
		NOP
		STA	(ptrBenitoVal), Z

		JSR	_wait_OPL

		PLZ

@exit:
		RTS


;-----------------------------------------------------------
_wait_short_OPL:
;-----------------------------------------------------------
		PHX

;		LDX	#$40
;@loop0:
;		DEX
;		BNE	@loop0

		PLX
		RTS


;-----------------------------------------------------------
_wait_OPL:
;-----------------------------------------------------------
		PHX

;		LDX	#$FF
;@loop0:
;		DEX
;		BNE	@loop0

		PLX
		RTS


;-----------------------------------------------------------
_setup_operator:
;-----------------------------------------------------------
		LDX	#$00
@loop0:
		CLC
		ADC	#$20
		STA	valBenTmp0 + 2

		STA	valBenOPLReg

		NOP
		LDA	(ptrPatchData), Z
		INZ

		STA	valBenOPLVal
		JSR	_write_OPL

		LDA	valBenTmp0 + 2

		INX
		CPX	#$04
		BNE	@loop0

		CLC
		ADC	#$60

		STA	valBenOPLReg

		NOP
		LDA	(ptrPatchData), Z
		INZ

		STA	valBenOPLVal
		JSR	_write_OPL

		RTS


;-----------------------------------------------------------
_setup_channel:
;-----------------------------------------------------------
		LDA	valBenTmp0
		ORA	#$C0

		STA	valBenOPLReg

		LDZ	valBenTmp0 + 1
		INZ
		INZ
		NOP
		LDA	(ptrPatchData), Z
		INZ

		STA	valBenOPLVal

		JSR	_write_OPL

		LDA	valBenTmp0
		ASL
		TAX
		LDA	valBenOpOffsets, X
		JSR	_setup_operator

		LDA	valBenTmp0
		ASL
		TAX
		INX
		LDA	valBenOpOffsets, X
		JSR	_setup_operator

		RTS


;-----------------------------------------------------------
_setup_frequency:
;-----------------------------------------------------------
		LDA	valBenBuf0 + 1
		SEC
		SBC	#$1F
		BPL	@cont

		LDA	#$00

@cont:
		STA	valBenTmp0 + 2
		LDA	#$00
		STA	valBenTmp0 + 3

@loop0:
		LDA	valBenTmp0 + 2
		CMP	#$0C
		BCC	@update

		INC	valBenTmp0 + 3

		SEC
		LDA	valBenTmp0 + 2
		SBC	#$0C
		STA	valBenTmp0 + 2

		BRA	@loop0

@update:
		LDA	valBenTmp0 + 3
		ASL
		ASL
		STA	valBenTmp0 + 3

		LDA	valBenTmp0 + 2
		ASL
		TAX
		LDA	valBenNoteFreqs + 1, X
		
		ORA	valBenTmp0 + 3
		ORA	#$20
		STA	valBenTmp0 + 3

		LDA	valBenTmp0
		ORA	#$A0

		STA	valBenOPLReg

		LDA	valBenNoteFreqs, X

		STA	valBenOPLVal
		JSR	_write_OPL

		LDA	valBenTmp0
		ORA	#$B0

		STA	valBenOPLReg

		LDA	valBenTmp0 + 3

		LDX	valBenTmp1 + 1
		STA	valBenChnB0Reg, X

		STA	valBenOPLVal
		JSR	_write_OPL

		RTS


;-----------------------------------------------------------
_setup_rhythm:
;-----------------------------------------------------------
		CMP	#$01
		BNE	@test6

		LDA	#$06
		STA	valBenTmp0

		JSR	_setup_channel

		LDZ	valBenTmp0 + 1
		NOP
		LDA	(ptrPatchData), Z
		INZ

		STA	valBenTmp0 + 3

		LDA	#$A6
		STA	valBenOPLReg

		LDA	valBenTmp0 + 3
		STA	valBenOPLVal
		JSR	_write_OPL

		NOP
		LDA	(ptrPatchData), Z

		AND	#$DF

		STA	valBenTmp0 + 3

		LDA	#$B6
		STA	valBenOPLReg

		LDA	valBenTmp0 + 3
		STA	valBenOPLVal
		JSR	_write_OPL

		LDA	valBenMDVDRState
		ORA	#$10
		STA	valBenMDVDRState

		LDA	#$BD
		STA	valBenOPLReg

		LDA	valBenMDVDRState
		STA	valBenOPLVal
		JSR	_write_OPL

		RTS

@test6:
		CMP	#$06
		LBCS	@exit

		TAY
		STA	valBenTmp1

		LDA	valBenTmp0 + 1
		CLC
		ADC	#$08

		TAZ

		LDA	valBenRhythmOp, Y

		JSR	_setup_operator

		LDZ	valBenTmp0 + 1

		LDY	valBenTmp1

		LDA	valBenRhythmChn, Y
		STA	valBenTmp0 + 2
		CLC
		ADC	#$A0

		STA	valBenOPLReg

		NOP
		LDA	(ptrPatchData), Z
		INZ

		STA	valBenOPLVal
		JSR	_write_OPL


		LDA	valBenTmp0 + 2
		CLC
		ADC	#$B0

		STA	valBenOPLReg

		NOP
		LDA	(ptrPatchData), Z
		INZ

		AND	#$DF

		STA	valBenOPLReg
		JSR	_write_OPL

		LDA	valBenTmp0 + 2
		CLC
		ADC	#$C0

		STA	valBenOPLReg

		NOP
		LDA	(ptrPatchData), Z

		STA	valBenOPLVal

		JSR	_write_OPL

		LDY	valBenTmp1

		LDA	valBenMDVDRState
		ORA	valBenMDVDRtbl, Y
		STA	valBenMDVDRState

		LDA	#$BD
		STA	valBenOPLReg

		LDA	valBenMDVDRState
		STA	valBenOPLVal
		JSR	_write_OPL

@exit:
		RTS


;-----------------------------------------------------------
_benitoNoteOn:
;-----------------------------------------------------------
;@halt:
;		INC	$D020
;		JMP	@halt

		LDA	valBenBuf0
		AND	#$0F

		STA	valBenTmp0

		TAX
		LDA	valBenInstOfs, X

		STA	valBenTmp0 + 1

		BEQ	@exit

		CLC
		ADC	#$0D
		TAZ
		NOP
		LDA	(ptrPatchData), Z
		BEQ	@regular

		JSR	_setup_rhythm

		RTS

@regular:
		JSR	_allocate_hw_chan
		BCS	@exit

		LDA	valBenTmp0
		STX	valBenTmp1 + 1
		STA	valBenChnAlloc, X

		LDA	valBenBuf0 + 1
		STA	valBenChnNote, X

		STX	valBenTmp1
		TXA
		STA	valBenTmp0

		JSR	_setup_channel

		JSR	_setup_frequency

@exit:
		RTS


;-----------------------------------------------------------
_benitoNoteOff:
;-----------------------------------------------------------
		LDA	valBenBuf0
		AND	#$0F

		LDX	#$00
@loop:
		CMP	valBenChnAlloc, X
		BEQ	@tstnote

@next:
		INX
		CPX	#$09
		BNE	@loop

		TAX
		LDA	valBenInstOfs, X

		BEQ	@exit

		CLC
		ADC	#$0D

		TAZ
		NOP
		LDA	(ptrPatchData), Z

		BEQ	@exit

		CMP	#$06
		BCS	@exit

		TAX

		LDA	valBenMDVDRtbl, X
		EOR	#$FF
		AND	valBenMDVDRState
		STA	valBenMDVDRState
		STA	valBenOPLVal
		LDA	#$BD
		STA	valBenOPLReg

		JSR	_write_OPL

@exit:
		RTS

@tstnote:
		PHA
		LDA	valBenBuf0 + 1
		CMP	valBenChnNote, X
		BEQ	@found

		PLA
		BRA	@next

@found:
		PLA

		LDA	#$FF
		STA	valBenChnAlloc, X
		LDA	#$00
		STA	valBenChnNote, X

		LDA	valBenChnB0Reg, X
		AND	#$DF
		STA	valBenOPLVal

		TXA
		CLC
		ADC	#$B0
		STA	valBenOPLReg

		JSR	_write_OPL

		RTS
