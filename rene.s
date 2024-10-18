	.setcpu		"4510"

;	Determine whether MID loading is from D81 or SDC.
	.define		DEF_RENE_USEMINI	0
	.define		DEF_RENE_TIMING_QTR	1

	.feature	leading_dot_in_identifiers, loose_string_term

ptrPatchData		=	$B0
ptrPatchTemp		=	$B4

ptrScreen			=	$C8
ptrTemp0			=	$CC

numConvLEAD0		=	$C2
numConvDIGIT		=	$C3
numConvVALUE		=	$C4
numConvHeapPtr		=	$C6

ADDR_SCREEN			=	$4000

ADDR_COLOUR			=	$0000
BANK_COLOUR			=	$0FF8

VEC_CPU_IRQ			=	$FFFE
VEC_CPU_RESET		=	$FFFC
VEC_CPU_NMI 		=	$FFFA

.if 	DEF_RENE_TIMING_QTR
;118Hz
VAL_REN_DEFTEMPO	=	508475
.else
;472Hz
VAL_REN_DEFTEMPO	=	127119
.endif


;VAL_REN_PBNKSTRT	=	$00020000
VAL_REN_PBNKSTRT	=	$08000000


	.macro	.defPStr Arg
	.byte	.strlen(Arg), Arg
	.endmacro

	.macro	__REN_DIV_MEM32_MEM16 mem0, mem1
		LDA	mem0
		STA	$D770
		LDA	mem0 + 1
		STA	$D771
		LDA	mem0 + 2
		STA	$D772
		LDA	mem0 + 3
		STA	$D773

		LDA	mem1
		STA	$D774
		LDA	mem1 + 1
		STA	$D775
		LDA	#$00
		STA	$D776
		STA	$D777

		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020

;	Result in $D76C-
	.endmacro


	.macro	__REN_DIV_MEM16_MEM8 mem0, mem1
		LDA	mem0
		STA	$D770
		LDA	mem0 + 1
		STA	$D771
		LDA	#$00
		STA	$D772
		STA	$D773

		LDA	mem1
		STA	$D774
		LDA	#$00
		STA	$D775
		STA	$D776
		STA	$D777

		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020

;	Result in $D76C-
	.endmacro

	.macro	__REN_ASL_MEM32	mem
		CLC
		LDA	mem
		ASL
		STA	mem
		LDA	mem + 1
		ROL
		STA	mem + 1
		LDA	mem + 2
		ROL
		STA	mem + 2
		LDA	mem + 3
		ROL
		STA	mem + 3
	.endmacro

	.macro	__REN_LSR_MEM16	mem
		CLC
		LDA	mem + 1
		LSR	
		STA	mem + 1
		LDA	mem
		ROR
		STA	mem
	.endmacro

	.macro	__REN_MOV_MEM32_MEM32	mem0, mem1
		LDA	mem1
		STA	mem0
		LDA	mem1 + 1
		STA	mem0 + 1
		LDA	mem1 + 2
		STA	mem0 + 2
		LDA	mem1 + 3
		STA	mem0 + 3
	.endmacro


;===========================================================
;BASIC interface
;-----------------------------------------------------------
	.code
;start 2 before load address so
;we can inject it into the binary
	.org		$07FF			
						
	.byte		$01, $08		;load address
	
;BASIC next addr and this line #
	.word		_basNext, $000A		
	.byte		$9E			;SYS command
	.asciiz		"2061"			;2061 and line end
_basNext:
	.word		$0000			;BASIC prog terminator
	.assert		* = $080D, error, "BASIC Loader incorrect!"
;-----------------------------------------------------------
bootstrap:
		JMP	init
;===========================================================


;===========================================================
;===========================================================

	.include	"benito.s"

;===========================================================
;===========================================================

strRenFNam:
;	.defPStr	""
	.byte		$00
	.byte		$20, $20, $20, $20, $20, $20, $20, $20
	.byte		$20, $20, $20, $20, $20, $20, $20, $20
	.byte		$20, $20, $20, $20
	.byte		$00

strRenFErr:
	.defPStr	"ERROR OPENING FILE!"


flgRenDirty:
	.byte		$00
flgRenPlay:
	.byte		$00
flgRenLoad:
	.byte		$00
flgRenRsrt:
	.byte		$00
flgRenDidE:
	.byte		$00

cntRenTick:
	.word		$0000
cntRenNEvt:
	.dword		$00000000

cntRenMusTick:
	.byte		$00
valRenMusTimr:
	.word		$0000

;Last status byte for running status
valRenLstS:
	.byte		$00

;Number of 32nds in quarter note
valRen32PQ:
	.byte		$08

;Tempo
valRenTmpo:
	.dword		VAL_REN_DEFTEMPO

;Microseconds per pulse
valRenMSPP:
	.dword		VAL_REN_DEFTEMPO / VAL_BEN_DEFPPQNT

valRenBuf0:
	.byte		$00, $00, $00, $00

valRenErr0:
	.word		$0000

valRenTmp0:
	.byte		$00
	.byte		$00

valRenDummy:
	.dword		$00000000


;===========================================================
;===========================================================

;-----------------------------------------------------------
init:
;-----------------------------------------------------------
;	disable standard CIA irqs
		LDA	#$7F
		STA	$DC0D		;CIA IRQ control
		
;	No decimal mode, no interrupts
		CLD
		SEI

;	Setup Mega65 features and speed
		JSR	initM65IOFast

;	Disable ROM write-protect
		LDA	#$70
		STA	$D640
;	This is required as part of the hypervisor interface
		CLV

;	Clear the input buffer
		LDX	#$00
@loop0:
		LDA	$D610
		STX	$D610
		BNE	@loop0

	.if	.not	DEF_RENE_USEMINI
		LDA	#$C0
		STA	Z:ptrBigglesBufHi
		LDA	#$03
		STA	Z:ptrBigglesFNmHi
	.endif

		JSR	initState
		JSR	initScreen
		JSR	initAudio

		JSR	benitoInit

		JSR	initIRQ

main:
		LDA	flgRenRsrt
		BEQ	@tstkeys

		JSR	resetSong
		JSR	loadSong

		JMP	@update

@tstkeys:
		LDA	$D610
		BEQ	main

		LDX	#$00
		STX	$D610

		CMP	#'t'
		BNE	@tstF1

		LDA	#64
		STA	$00

		LDA	#' '
		JMP	@testspc

@tstF1:
		CMP	#$F1
		BNE	@testspc

		JSR	resetSong
		JSR	resetPatches

		JSR	getFileName

		JSR	loadPatches
		JSR	loadSong

		JMP	@update

@testspc:
		CMP	#' '
		BNE	@next0

		LDA	flgRenLoad
		BNE	@doplay

		JMP	@next0

@doplay:
		SEI
		LDA	flgRenPlay
		EOR	#$01
		STA	flgRenPlay
		CLI

		JMP	@update

@update:
		SEI
		LDA	#$01
		STA	flgRenDirty
		CLI

@next0:
		JMP	main


;-----------------------------------------------------------
error:
;-----------------------------------------------------------
		SEI

		LDA	#<(ADDR_SCREEN + 2 * 80)
		STA	ptrScreen
		LDA	#>(ADDR_SCREEN + 2 * 80)
		STA	ptrScreen + 1

		LDA	#<strRenFErr
		STA	ptrTemp0
		LDA	#>strRenFErr
		STA	ptrTemp0 + 1

		JSR	displayPString

		LDA	#<(ADDR_SCREEN + (2 * 80) + 24)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (2 * 80) + 24)
		STA	numConvHeapPtr + 1

		LDA	valRenErr0
		STA	numConvVALUE
		LDA	valRenErr0 + 1
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		CLI

;@halt:
;		JMP	@halt

		RTS


;-----------------------------------------------------------
resetSong:
;-----------------------------------------------------------
		SEI
		LDA	#$00
		STA	flgRenLoad

		LDA	flgRenPlay
		BEQ	@cont0

		JSR	benitoStop

@cont0:
		LDA	#$00
		STA	flgRenPlay
		STA	flgRenRsrt

		STA	valRenLstS

		CLI

	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesCloseFile
	.else
		JSR	miniCloseFile
	.endif

		RTS


;-----------------------------------------------------------
resetPatches:
;-----------------------------------------------------------
		LDA	#<.loword(VAL_REN_PBNKSTRT)
		STA	ptrPatchData
		LDA	#>.loword(VAL_REN_PBNKSTRT)
		STA	ptrPatchData + 1
		LDA	#<.hiword(VAL_REN_PBNKSTRT)
		STA	ptrPatchData + 2
		LDA	#>.hiword(VAL_REN_PBNKSTRT)
		STA	ptrPatchData + 3

		RTS


;-----------------------------------------------------------
getFileName:
;-----------------------------------------------------------
		LDA	strRenFNam
		STA	valRenDummy

		LDA	#$14
		STA	strRenFNam

		LDA	#<(ADDR_SCREEN + 2 * 80)
		STA	ptrScreen
		LDA	#>(ADDR_SCREEN + 2 * 80)
		STA	ptrScreen + 1

		LDA	#<strRenFNam
		STA	ptrTemp0
		LDA	#>strRenFNam
		STA	ptrTemp0 + 1

@loop0:
		JSR	displayPString

		LDY	valRenDummy
		LDA	(ptrScreen), Y
		ORA	#$80
		STA	(ptrScreen), Y

		INY
		LDA	#$20
		STA	(ptrScreen), Y

@loop1:
		LDA	$D610
		BEQ	@loop1

		CMP	#$14
		BEQ	@delkey

		CMP	#$0D
		BEQ	@retkey

		CMP	#$20
		BCC	@next1

		CMP	#$7B
		BCC	@acceptkey

@next1:
		LDA	#$00
		STA	$D610
		JMP	@loop1

@acceptkey:
		LDY	valRenDummy
		CPY	#$10
		BCC	@append0

		JMP	@next1

@append0:
		CMP	#$61
		BCC	@append1

		CMP	#$7B
		BCC	@append2

@append1:
		INY
		STA	strRenFNam, Y
		STY	valRenDummy

		JMP	@next0

@append2:
		SEC
		SBC	#$20
		JMP	@append1

@delkey:
		LDY	valRenDummy
		BEQ	@next1

		LDA	#$20
		STA	strRenFNam, Y
		DEY
		STY	valRenDummy

		JMP	@next0

@retkey:
		LDY	valRenDummy
		BEQ	@next1

		STY	strRenFNam
		LDA	#$00
		STA	$D610

;		JMP	@load0
		RTS

@next0:
		LDA	#$00
		STA	$D610
		JMP	@loop0

		RTS


;-----------------------------------------------------------
loadPatches:
;-----------------------------------------------------------
		SEI

		LDA	#$01
		STA	valRenErr0
		LDA	#$01
		STA	valRenErr0 + 1

	.if	.not	DEF_RENE_USEMINI
		LDY	strRenFNam
		INY
		LDA	#$00
		STA	strRenFNam, Y

		LDX	#<(strRenFNam + 1)
		LDY	#>(strRenFNam + 1)

		JSR	bigglesSetFileName

		LDY	strRenFNam
		INY
		LDA	#$20
		STA	strRenFNam, Y

		JSR	bigglesOpenFile
	.else
		LDA	strRenFNam
		LDX	#<(strRenFNam + 1)
		LDY	#>(strRenFNam + 1)

		JSR	miniSetFileName

		LDA	#VAL_DOSFTYPE_SEQ
		JSR	miniSetFileType

		JSR	miniOpenFile
	.endif
		BCC	@cont1

@fail0:
		LDA	#$00
		STA	$D020

	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesCloseFile
	.else
		JSR	miniCloseFile
	.endif
		JSR	error

		CLI
		RTS

@cont1:
		LDA	#$10
		STA	valRenErr0
		LDA	#$01
		STA	valRenErr0 + 1

		__REN_MOV_MEM32_MEM32	ptrPatchTemp, ptrPatchData

		LDZ	#$00
@loop0:
	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		BCS	@fail0

		NOP
		STA	(ptrPatchTemp), Z
		STA	$D020

		INZ
		CPZ	#$93
		BNE	@loop0

@done:
		LDA	#$00
		STA	$D020

	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesCloseFile
	.else
		JSR	miniCloseFile
	.endif

		CLI
		RTS


;-----------------------------------------------------------
loadSong:
;-----------------------------------------------------------
		SEI

		LDA	#$01
		STA	valRenErr0
		LDA	#$00
		STA	valRenErr0 + 1

	.if	.not	DEF_RENE_USEMINI
		LDY	strRenFNam
		INY
		LDA	#$00
		STA	strRenFNam, Y

		LDX	#<(strRenFNam + 1)
		LDY	#>(strRenFNam + 1)

		JSR	bigglesSetFileName

		LDY	strRenFNam
		INY
		LDA	#$20
		STA	strRenFNam, Y

		JSR	bigglesOpenFile
	.else
		LDA	strRenFNam
		LDX	#<(strRenFNam + 1)
		LDY	#>(strRenFNam + 1)

		JSR	miniSetFileName

		LDA	#VAL_DOSFTYPE_SEQ
		JSR	miniSetFileType

		JSR	miniOpenFile
	.endif
		BCC	@cont1

@fail0:
	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesCloseFile
	.else
		JSR	miniCloseFile
	.endif
		JSR	error

		CLI
		RTS

@cont1:
		LDA	#$10
		STA	valRenErr0
		LDA	#$00
		STA	valRenErr0 + 1

;		JSR	readHeader
;		BCS	@fail0

		LDA	#$20
		STA	valRenErr0

		JSR	findTrack
		BCS	@fail0

		LDA	#$30
		STA	valRenErr0

		JSR	benitoPrepare

		LDZ	#$03
		NOP
		LDA	(ptrPatchData), Z
		STA	cntRenMusTick

		LDA	#$00
		STA	valRenMusTimr
		STA	valRenMusTimr + 1


;		JSR	readVariLen
;		BCS	@fail0

;		__REN_MOV_MEM32_MEM32 cntRenNEvt, valRenBuf0

		LDA	#$28
		STA	cntRenNEvt
		LDA	#$00
		STA	cntRenNEvt + 1
		STA	cntRenNEvt + 2
		STA	cntRenNEvt + 3

@done:
		LDA	#$01
		STA	flgRenLoad
		STA	flgRenDirty
		CLI

		RTS


;-----------------------------------------------------------
readVariLen:
;-----------------------------------------------------------
	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		LBCS	@fail0

		STA	valRenBuf0

		LDA	#$00
		STA	valRenBuf0 + 1
		STA	valRenBuf0 + 2
		STA	valRenBuf0 + 3

		LDA	valRenBuf0
		AND	#$80
		BEQ	@done0

		AND	#$7F
		STA	valRenBuf0

		LDX	#$06
@loop2:
		__REN_ASL_MEM32 valRenBuf0

		DEX
		BPL	@loop2

	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		BCS	@fail0

		ORA	valRenBuf0
		STA	valRenBuf0

		BRA	@done0






		LDY	#$03
@loop0:
	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		BCS	@fail0

		STA	valRenTmp0

		LDX	#$06
@loop1:
		__REN_ASL_MEM32 valRenBuf0

		DEX
		BPL	@loop1

		LDA	valRenTmp0
		AND	#$7F
		ORA	valRenBuf0
		STA	valRenBuf0

		DEY
		BMI	@done0

		LDA	valRenTmp0
		AND	#$80
		BNE	@loop0

@done0:

;@halt:
;		INC	$D020
;		JMP	@halt

		CLC
		RTS

@fail0:
		SEC
		RTS


;-----------------------------------------------------------
findTrack:
;-----------------------------------------------------------
		LDA	#$93
		STA	valRenBuf0
		LDA	#$00
		STA	valRenBuf0 + 1
		STA	valRenBuf0 + 2
		STA	valRenBuf0 + 3

		JSR	readSkipBytes
		BCS	@fail0

		CLC
		RTS

@fail0:
		SEC
		RTS


;-----------------------------------------------------------
readSkipBytes:
;-----------------------------------------------------------
@loop0:
		LDA	valRenBuf0
		ORA	valRenBuf0 + 1
		ORA	valRenBuf0 + 2
		ORA	valRenBuf0 + 3

		BEQ	@done0

	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		BCS	@fail0

		SEC
		LDA	valRenBuf0
		SBC	#$01
		STA	valRenBuf0
		LDA	valRenBuf0 + 1
		SBC	#$00
		STA	valRenBuf0 + 1
		LDA	valRenBuf0 + 2
		SBC	#$00
		STA	valRenBuf0 + 2
		LDA	valRenBuf0 + 3
		SBC	#$00
		STA	valRenBuf0 + 3

		JMP	@loop0

@done0:
		CLC
		RTS

@fail0:
		SEC
		RTS


;-----------------------------------------------------------
reneCalcTimer:
;-----------------------------------------------------------
		__REN_DIV_MEM32_MEM16 valRenTmpo, valBenPPQN

		LDA	$D76C
		STA	valRenMSPP
		LDA	$D76D
		STA	valRenMSPP + 1
		LDA	$D76E
		STA	valRenMSPP + 2
		LDA	$D76F
		STA	valRenMSPP + 3

		__REN_DIV_MEM16_MEM8 valBenPPQN, valRen32PQ

		LDA	$D76C
		STA	valBenPP32
		STA	valBenPP64
		LDA	$D76D
		STA	valBenPP32 + 1
		STA	valBenPP64 + 1

		__REN_LSR_MEM16 valBenPP64

		JSR	reneSetTimer

		RTS


;-----------------------------------------------------------
reneSetTimer:
;-----------------------------------------------------------
;@halt:
;		INC	$D020
;		JMP	@halt
;		LDA	#$00
;		STA	$D020

;	Timer A to LOWORD
		LDA	valRenMSPP
		STA	$DC04
		LDA	valRenMSPP + 1
		STA	$DC05

;	Timer B to HIWORD
		LDA	valRenMSPP + 2
		STA	$DC06
		LDA	valRenMSPP + 3
		STA	$DC07

;	CIA#1 Timer B to count on Timer A underflow and init
		LDA	#%01010011
		STA	$DC0F

;	Timer A to count on system phi and init
		LDA	#%00010001
		STA	$DC0E

		RTS


;-----------------------------------------------------------
plyrNOP:
;-----------------------------------------------------------
		RTI


;-----------------------------------------------------------
plyrIRQ:
;-----------------------------------------------------------
		PHP				;save the initial state
		PHA
		PHX
		PHY
		PHZ

		CLD

;		JSR	sandyProcADMAIRQ
;		JSR	sandyIRQDeferPoll

		LDA	$DC0D		;IRQ regs, timer b?
		AND	#$02
		BNE	@proc
		
;	Some other interrupt source


;!!!FIXME:	Actually test the panic switch


;		LDA	#$0C
;		INC	$D020

		JMP	@done
		
@proc:
;		LDA	flgRenDirty
;		BEQ	@cont

		LDA	#$00
		STA	flgRenDirty

@cont:
		LDA	#$01
		STA	$D020

		LDA	#<ADDR_SCREEN
		STA	numConvHeapPtr
		LDA	#>ADDR_SCREEN
		STA	numConvHeapPtr + 1

		LDA	cntRenTick
		STA	numConvVALUE
		LDA	cntRenTick + 1
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		LDA	#<(ADDR_SCREEN + 8)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + 8)
		STA	numConvHeapPtr + 1

		LDA	cntRenNEvt
		STA	numConvVALUE
		LDA	cntRenNEvt + 1
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		CLC
		LDA	#$01
		ADC	cntRenTick
		STA	cntRenTick
		LDA	#$00
		ADC	cntRenTick + 1
		STA	cntRenTick + 1

		LDA	flgRenLoad
		LBEQ	@finish

		LDA	flgRenPlay
		AND	#$7F
		BNE	@play0

		LDA	flgRenPlay
		LBPL	@finish

		JSR	benitoStop

		LDA	#$00
		STA	flgRenPlay
		JMP	@skip0

@play0:
		ORA	#$80
		STA	flgRenPlay

		LDA	#$00
		STA	flgRenDidE

		CLC
		LDA	valRenMusTimr
		ADC	cntRenMusTick
		STA	valRenMusTimr
		LDA	valRenMusTimr + 1
		ADC	#$00
		STA	valRenMusTimr + 1

		LBEQ	@skip0

		SEC
		LDA	valRenMusTimr
		SBC	#$00
		STA	valRenMusTimr
		LDA	valRenMusTimr + 1
		SBC	#$01
		STA	valRenMusTimr + 1

@loop0:
		LDA	cntRenNEvt
		ORA	cntRenNEvt + 1
		ORA	cntRenNEvt + 2
		ORA	cntRenNEvt + 3

		BNE	@update0

		JSR	handleEvent
		LBCS	@fail0

		LDA	#$01
		STA	flgRenDidE

		LDA	flgRenRsrt
		LBNE	@finish

		JSR	readVariLen
		LBCS	@fail0

		__REN_MOV_MEM32_MEM32 cntRenNEvt, valRenBuf0

		LDZ	#$00
		NEG
		NEG
		LDA	cntRenNEvt
		NEG
		NEG
		LSR

.if		DEF_RENE_TIMING_QTR
		NEG
		NEG
		LSR
		NEG
		NEG
		LSR
.endif

		NEG
		NEG
		STA	cntRenNEvt

;		LDA	cntRenNEvt
;		ORA	cntRenNEvt + 1
;		ORA	cntRenNEvt + 2
;		ORA	cntRenNEvt + 3
;		BEQ	@insert0

		JMP	@loop0

@insert0:
		LDA	#$01
		STA	cntRenNEvt
		BRA	@skip0

@update0:
		LDA	flgRenDidE
		BNE	@skip0

		SEC
		LDA	cntRenNEvt
		SBC	#$01
		STA	cntRenNEvt
		LDA	cntRenNEvt + 1
		SBC	#$00
		STA	cntRenNEvt + 1
		LDA	cntRenNEvt + 2
		SBC	#$00
		STA	cntRenNEvt + 2
		LDA	cntRenNEvt + 3
		SBC	#$00
		STA	cntRenNEvt + 3

@skip0:
;		JSR	benitoPulse

		LDA	#<(ADDR_SCREEN + 16)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + 16)
		STA	numConvHeapPtr + 1

		LDA	valBenDbg0
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT



@finish:
;		LDA	#%11111101
;		LDA	#%10000010
;		STA	$DC0D

@done:

;		LDA	valMnchADMAENB
;		TSB	$D713
		LDZ	#$00
		NOP
		LDA	(ptrBenitoStat), Z
		STA	$D020


		LDA	#$00
;		STA	$D020
		STA	$D021

		PLZ
		PLY
		PLX
		PLA
		PLP

		RTI

@fail0:
		JSR	benitoStop

		LDA	#$00
		STA	flgRenPlay

		JMP	@done

;-----------------------------------------------------------
handleEvent:
;-----------------------------------------------------------
	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		BCS	@exit

		LDY	#$00

		CMP	#$80
		BCC	@running

		STA	valBenBuf0
		JMP	@event

@running:
		STA	valBenBuf0 + 1
		LDA	valRenLstS
		STA	valBenBuf0
		INY

@event:
		LDA	valBenBuf0
		AND	#$F0
		CMP	#$F0
		BNE	@voiced

		LDA	valBenBuf0
		CMP	#$FF
		BEQ	@meta

		JSR	handleSysEvent
		BCS	@exit

		JMP	@finish

@meta:
		JSR	handleMetaEvent
		JMP	@exit

@voiced:
		STY	valRenDummy
		INY

		LDA	valBenBuf0
		AND	#$7F
		LSR
		LSR
		LSR
		LSR

		TAX
		LDA	valBenEvB0, X
		TAX
		INX
		STX	valBenLen0

		SEC
		SBC	valRenDummy

		TAX
		DEX
@loop0:
		BMI	@update

	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		BCS	@exit

		STA	valBenBuf0, Y
		INY

		DEX
		JMP	@loop0

@update:
		LDA	valBenBuf0
		STA	valRenLstS

		JSR	benitoEvent

@finish:
		CLC

@exit:
		RTS


;-----------------------------------------------------------
handleMetaEvent:
;-----------------------------------------------------------
	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		BCS	@exit


		CMP	#$2F
		BNE	@tstdbg

;		Stop playback
		JSR	benitoStop
		BRA	@done

@tstdbg:
		CMP	#$58
		BNE	@tsttempo

		LDA	#$05
		BRA	@skip

@tsttempo:
		CMP	#$51
		BNE	@other

@halt:
		INC	$D020
		JMP	@halt

@other:
	.if	.not	DEF_RENE_USEMINI
		JSR	bigglesReadByte
	.else
		JSR	miniReadByte
	.endif
		BCS	@exit

@skip:
		STA	valRenBuf0
		LDA	#$00
		STA	valRenBuf0 + 1
		STA	valRenBuf0 + 2
		STA	valRenBuf0 + 3

		JSR	readSkipBytes

@done:
		CLC

@exit:
		RTS


;-----------------------------------------------------------
handleSysEvent:
;-----------------------------------------------------------

@exit:
		RTS


;-----------------------------------------------------------
displayPString:
;-----------------------------------------------------------
		LDY	#$00
		LDZ	#$00

		LDA	(ptrTemp0), Y
		TAX
		BEQ	@exit

		INY

@loop0:
		LDA	(ptrTemp0), Y
		STA	(ptrScreen), Z

		INY
		INZ

		DEX
		BNE	@loop0

@exit:
		RTS


;-----------------------------------------------------------
numConvPRTINT:  
;-----------------------------------------------------------
		PHA
		PHX
		PHY
		
		LDY	#$00

		LDX	#$4         		;OUTPUT UP TO 5 DIGITS

;de	I'm pretty sure we have a problem below and this will help fix it
;		STX	numConvLEAD0       	;INIT LEAD0 TO NON-NEG
		LDA	#%10000000
		STA	numConvLEAD0
		
;
@PRTI1:
		LDA	#'0'        		;INIT DIGIT COUNTER
		STA	numConvDIGIT
;
@PRTI2:
		SEC            	 		;BEGIN SUBTRACTION PROCESS
        LDA	numConvVALUE
        SBC	numConvT10L, X      	;SUBTRACT LOW ORDER BYTE
        PHA            		;AND SAVE.
        LDA	numConvVALUE + $1    	;GET H.O BYTE
        SBC	numConvT10H, X      	;AND SUBTRACT H.O TBL OF 10
        BCC	@PRTI3       		;IF LESS THAN, BRANCH
;
        STA	numConvVALUE + $1    	;IF NOT LESS THAN, SAVE IN
        PLA             		;VALUE.
        STA	numConvVALUE
        INC	numConvDIGIT       	;INCREMENT DIGIT COUNTER
        JMP	@PRTI2
;
;
@PRTI3:
		PLA             		;FIX THE STACK
        LDA	numConvDIGIT       	;GET CHARACTER TO OUTPUT
                
		CPX	#$0         		;LAST DIGIT TO OUTPUT?
        BEQ	@PRTI5       		;IF SO, OUTPUT REGARDLESS

		CMP	#'0'        		;A ZERO?

;de	#$31+ is not negative so this wouldn't work??
;       BEQ 	@PRTI4       		;IF SO, SEE IF A LEADING ZERO
;		STA 	numConvLEAD0       	;FORCE LEAD0 TO NEG.
;de 	We'll do this instead
		BNE	@PRTI5
@PRTI4:   	
		BIT	numConvLEAD0       	;SEE IF ZERO VALUES OUTPUT
;de	I need to this as well
;       BPL 	@PRTI6       		;YET.
;		BPL 	@space			;de I want spaces.
		BMI	@space

@PRTI5:
;		JSR 	numConvCOUT
;de	And this too (only l6bit here)
		CLC
		ROR	numConvLEAD0

		STA	(numConvHeapPtr), Y
		INY
		
		JMP	@PRTI6			;de This messes the routine but
						;I need spaces

@space:
		LDA	#' '
		STA	(numConvHeapPtr), Y
		INY
		
@PRTI6:
		DEX             		;THROUGH YET?
		BPL 	@PRTI1


		PLY
		PLX
		PLA
		
		RTS

numConvT10L:
	.byte 		<1
	.byte 		<10
	.byte		<100
	.byte		<1000
	.byte		<10000

numConvT10H:		
	.byte		>1
	.byte		>10
	.byte		>100
	.byte		>1000
	.byte		>10000



;-----------------------------------------------------------
setCoefficient:
;-----------------------------------------------------------
		STX	$D6F4

		STX	$D6F4
		STX	$D6F4
		STX	$D6F4
		STX	$D6F4

		STA	$D6F5

		RTS



valMnchMsVol:
	.word		$FFDC
valMnchLLVol:
	.word		$B31A
valMnchLRVol:
	.word		$332C
valMnchRLVol:
	.word		$332C
valMnchRRVol:
	.word		$B31A
valMnchDummy:
	.byte		$00

;-----------------------------------------------------------
setMasterVolume:
;-----------------------------------------------------------
;	Check if on Nexys - need the amplifier on (bit 0)
		LDA	$D629
		AND	#$40
		BEQ	@nonnexys

		LDA	#$01
		STA	valMnchDummy
		JMP	@cont0

@nonnexys:
		LDA	#$00
		STA	valMnchDummy
		
@cont0:
		LDX	#$1E				;Speaker Left master 
		LDA	valMnchMsVol
		ORA	valMnchDummy

		JSR	setCoefficient

		LDX	#$1F
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$3E				;Speaker right master
		LDA	valMnchMsVol
		ORA	valMnchDummy

		JSR	setCoefficient

		LDX	#$3F
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$DE				;Headphones right? master
		LDA	valMnchMsVol
		ORA	valMnchDummy

		JSR	setCoefficient

		LDX	#$DF
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$FE				;Headphones left? master
		LDA	valMnchMsVol
		ORA	valMnchDummy

		JSR	setCoefficient

		LDX	#$FF
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		RTS

;-----------------------------------------------------------
setLeftLVolume:
;-----------------------------------------------------------
		LDX	#$10				;Speaker left digi left
		LDA	valMnchLLVol
		JSR	setCoefficient

		LDX	#$11
		LDA	valMnchLLVol + 1
		JSR	setCoefficient

		LDX	#$F0				;Headphones left? digi left
		LDA	valMnchLLVol
		JSR	setCoefficient

		LDX	#$F1
		LDA	valMnchLLVol + 1
		JSR	setCoefficient
		
		RTS


;-----------------------------------------------------------
setLeftRVolume:
;-----------------------------------------------------------
		LDX	#$12				;Speaker left, digi right
		LDA	valMnchLRVol
		JSR	setCoefficient

		LDX	#$13
		LDA	valMnchLRVol + 1
		JSR	setCoefficient

		LDX	#$F2				;Headphone left?, digi right
		LDA	valMnchLRVol
		JSR	setCoefficient

		LDX	#$F3
		LDA	valMnchLRVol + 1
		JSR	setCoefficient
		
		RTS


;-----------------------------------------------------------
setRightRVolume:
;-----------------------------------------------------------
		LDX	#$32				;Speaker right, digi right
		LDA	valMnchRRVol
		JSR	setCoefficient

		LDX	#$33
		LDA	valMnchRRVol + 1
		JSR	setCoefficient

		LDX	#$D2				;Headphone right?, digi right
		LDA	valMnchRRVol
		JSR	setCoefficient

		LDX	#$D3
		LDA	valMnchRRVol + 1
		JSR	setCoefficient
		
		RTS

;-----------------------------------------------------------
setRightLVolume:
;-----------------------------------------------------------
		LDX	#$30				;Speaker right, digi left
		LDA	valMnchRLVol
		JSR	setCoefficient

		LDX	#$31
		LDA	valMnchRLVol + 1
		JSR	setCoefficient

		LDX	#$D0				;Headphone right?, digi left
		LDA	valMnchRLVol
		JSR	setCoefficient

		LDX	#$D1
		LDA	valMnchRLVol + 1
		JSR	setCoefficient

		RTS


mixervals:
	.byte $1c, $C0, $1d, $C0 ; OPL_FM LFT
	.byte $3c, $C0, $3d, $C0 ; OPL_FM RGT
	.byte $dc, $C0, $dd, $C0 ; OPL_FM HDL
	.byte $fc, $C0, $fd, $C0 ; OPL_FM HDR

;-----------------------------------------------------------
initAudio:
;-----------------------------------------------------------
		LDY	#$00
@loop0:
		LDX	mixervals, Y
		LDA mixervals + 1, Y
		JSR	setCoefficient
		INY
		INY
		CPY	#$10
		BNE	@loop0

		RTS


		LDX	#$00
		LDA	#$00
@loop:
		JSR	setCoefficient

		INX
		BNE	@loop

;	Check if on Nexys - mono to right side although appears
;	on left.
		LDA	$D629
		AND	#$40
		BEQ	@cont0

		LDA	#$00
		STA	valMnchLLVol
		STA	valMnchLRVol
		STA	valMnchLLVol + 1
		STA	valMnchLRVol + 1

		LDA	#$EE
		STA	valMnchRLVol
		STA	valMnchRRVol
		LDA	#$7F
		STA	valMnchRLVol + 1
		STA	valMnchRRVol + 1

@cont0:
		JSR	setMasterVolume
		JSR	setLeftLVolume
		JSR	setLeftRVolume
		JSR	setRightRVolume
		JSR	setRightLVolume

		LDX	#$00				;SID left 
		LDA	valMnchMsVol
		JSR	setCoefficient

		LDX	#$01
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$C0				;SID left 
		LDA	valMnchMsVol
		JSR	setCoefficient

		LDX	#$C1
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$22				;SID right
		LDA	valMnchMsVol
		JSR	setCoefficient

		LDX	#$23
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$E2				;SID right
		LDA	valMnchMsVol
		JSR	setCoefficient

		LDX	#$E3
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		RTS



;-----------------------------------------------------------
initM65IOFast:
;-----------------------------------------------------------
;	Go fast, first attempt
		LDA	#65
		STA	$00

;	Enable M65 enhanced registers
		LDA	#$47
		STA	$D02F
		LDA	#$53
		STA	$D02F
;	Switch to fast mode, be sure
; 	1. C65 fast-mode enable
		LDA	$D031
		ORA	#$40
		STA	$D031
; 	2. MEGA65 48MHz enable (requires C65 or C128 fast 
;	mode to truly enable, hence the above)
		LDA	#$40
		TSB	$D054
		
		RTS


;-----------------------------------------------------------
initState:
;-----------------------------------------------------------
;	Prevent VIC-II compatibility changes
		LDA	#$80
		TRB	$D05D		
		
		LDA	#$00
		STA	$D020
		STA	$D021

;	Set the location of screen RAM
		LDA	#<ADDR_SCREEN
		STA	$D060
		LDA	#>ADDR_SCREEN
		STA	$D061
		LDA	#$00
		STA	$D062
		STA	$D063

;	lower case
		LDA	#$16
		STA	$D018

;	Normal text mode
		LDA	#$00
		STA	$D054

;	H640, fast CPU, extended attributes
		LDA	#$E0
		STA	$D031

;	Adjust D016 smooth scrolling for VIC-III H640 offset
;		LDA	#$C9
;		STA	$D016
		LDA	$D016
		AND	#$F8
		ORA	#$02
		STA	$D016


;	640x200 16bits per char, 16 pixels wide per char
;	= 640/16 x 16 bits = 80 bytes per row
		LDA	#<80
		STA	$D058
		LDA	#>80
		STA	$D059
;	Draw 80 chars per row
		LDA	#80
		STA	$D05E

		RTS


;-----------------------------------------------------------
initScreen:
;-----------------------------------------------------------
		LDA	#<ADDR_SCREEN
		STA	ptrScreen
		LDA	#>ADDR_SCREEN
		STA	ptrScreen + 1
	
		LDX	#$18
@loop0:
		LDZ	#$00
		LDA	#$20
@loop1:
		STA	(ptrScreen), Z
		INZ
		
		CPZ	#$50
		BNE	@loop1
		
		CLC
		LDA	#$50
		ADC	ptrScreen
		STA	ptrScreen
		LDA	#$00
		ADC	ptrScreen + 1
		STA	ptrScreen + 1
		
		DEX
		BPL	@loop0

		LDA	#<ADDR_COLOUR
		STA	ptrScreen
		LDA	#>ADDR_COLOUR
		STA	ptrScreen + 1
		LDA	#<BANK_COLOUR
		STA	ptrScreen + 2
		LDA	#>BANK_COLOUR
		STA	ptrScreen + 3

		LDX	#$18
@loop2:
		LDZ	#$00
		LDA	#$0F
@loop3:
		NOP
		STA	(ptrScreen), Z
		INZ

		CPZ	#$50
		BNE	@loop3
		
		CLC
		LDA	#$50
		ADC	ptrScreen
		STA	ptrScreen
		LDA	#$00
		ADC	ptrScreen + 1
		STA	ptrScreen + 1
		
		DEX
		BPL	@loop2


		RTS


;-----------------------------------------------------------
initIRQ:
;-----------------------------------------------------------
		LDA	#<plyrIRQ		;install our handler
		STA	VEC_CPU_IRQ
		LDA	#>plyrIRQ
		STA	VEC_CPU_IRQ + 1

		LDA	#<plyrNOP		;install our handler
		STA	VEC_CPU_RESET
		LDA	#>plyrNOP
		STA	VEC_CPU_RESET + 1

		LDA	#<plyrNOP		;install our handler
		STA	VEC_CPU_NMI
		LDA	#>plyrNOP
		STA	VEC_CPU_NMI + 1

;	make sure that the IO port is set to output
		LDA	$00
		ORA	#$07
		STA	$00
		
;	Now, exclude BASIC + KERNAL from the memory map 
		LDA	#$1D
		STA	$01

;	Unset all CIA#1 IRQ sources
		LDA	#%01111111
		STA	$DC0D

;	Set Timer B CIA#1 IRQ source
		LDA	#%10000010
		STA	$DC0D

		JSR	reneSetTimer

		CLI

		RTS




	.if	.not	DEF_RENE_USEMINI
	.include	"bigglesworth.s"
	.else
	.include	"minime.s"
	.endif
