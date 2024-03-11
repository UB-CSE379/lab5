	.data

	.global prompt
	;.global mydata
	.global buttonScore
	.global spaceScore
	.global roundState

;SCORES
buttonScore: .byte 0 ;address to keep track of button Score
spaceScore: .byte 0 ;address to keep track of space Score

	.text

	.global uart_interrupt_init
	.global gpio_interrupt_init
	.global UART0_Handler
	.global Switch_Handler
	.global Timer_Handler			; This is needed for Lab #6
	.global simple_read_character
	.global output_character		; This is from your Lab #4 Library
	.global read_string				; This is from your Lab #4 Library
	.global output_string			; This is from your Lab #4 Library
	.global uart_init					; This is from your Lab #4 Library
	.global lab5

ptr_to_prompt:		.word prompt
;ptr_to_mydata:		.word mydata

ptr_to_buttonScore: .word buttonScore
ptr_to_spaceScore: .word spaceScore
ptr_to_roundState: 	.word roundState

uart_interrupt_init:

	; Your code to initialize the UART0 interrupt goes here
	; Set the Receive Interrupt Mask

	MOV r0, #0xC000
	MOVT r0, #0x4000 ; UART Base Address

	LDRB r4, [r0, #0x038] ; UARTIM Offset

	ORR r4, r4, #0x10 ; 0001 0000
	STRB r4, [r0, #0x038]

	;Configure Processor to Allow Interrupts in UART
	MOV r1, #0xE000
	MOVT r1, #0xE000 ; ENO Base Address

	LDRB r5, [r1, #0x100]
	ORR r5, r5, #0x20 ; 0010 0000
	STRB r5, [r1, #0x100]

	MOV pc, lr


gpio_interrupt_init:

	; Your code to initialize the SW1 interrupt goes here
	; Don't forget to follow the procedure you followed in Lab #4
	; to initialize SW1.

	;Enable Clock Address for Port F
    MOV r1, #0xE000
    MOVT r1, #0x400F

    ;NEED TO ENABLE CLOCK FOR ONLY PORT F
    LDRB r4, [r1, #0x608]
    ORR r4, r4, #0x20	; find specfic port 0010 0000
    STRB r4, [r1, #0x608] ;enable clock for Port F


    ;Initlize r3 with Port F address
    ; Set Pin 4 Direction to Input
    MOV r3, #0x5000
    MOVT r3, #0x4002
    LDRB r5, [r3, #0x400] ;offset 0x400 to port F
    AND r5, r5, #0xEF ; configure pin 4 as input
    STRB r5, [r3, #0x400] ; write 0 to configure pin 4 as input

	;Enable pull-up resistor
	LDRB r6, [r3, #0x510]
	ORR r6, r6, #0x10 ;
	STRB r6, [r3, #0x510] ;Write 1 to enable pull-up resistor

    ;Initilize pin as digital
    LDRB r7, [r3, #0x51C]
    ORR r7, r7, #0x10  ; enable pin 4 , by writing 1
	STRB r7, [r3, #0x51C] ;write 1 to make pin digital

	;Enable Edge Sensitive GPIOIS
	LDR r8, [r3, #0x404]
	BIC r8, r8, #0x10	;Write 0 to pin 4 to enable edge sensitive
	STR r8, [r3, #0x404]

	; Allow GPIOEV to determine edge, write 0 to pin on port
	LDR r9, [r3, #0x408]
	BIC r9, r9, #0x10
	STR r9, [r3, #0x408]

	; Write 0 to pin when button press ; Select this
	LDR r6, [r3, #0x40C]
	BIC r6, r6, #0x10
	STR r6, [r3, #0x40C]

	;Enable the Interrupt, write 1 to Bit 4
	LDR r7, [r3, #0x410]
	ORR r7, r7, #0x10 ; 0001 0000
	STR r7, [r3, #0x410]

	;ENO, set bit 30 bit
	MOV r8, #0xE000
	MOVT r8, #0xE000 ;ENO Base Address

	MOV r12, #1

	LDR r9, [r8, #0x100] ; ENO Offset
	LSL r12, r12, #30   ; 0100 0000 0000 0000 0000 0000 0000 0000
	ORR r9, r9, r12
	STR r9, [r8, #0x100]

	MOV pc, lr


UART0_Handler:

	; Your code for your UART handler goes here.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler
	PUSH {r4-r12, lr}

	; Clear Interrupt
	MOV r4, #0xC000
	MOVT r4, #0x4000 ; UART0 Base Address

	LDRB r5, [r4, #0x044] ;UARTICR Offset
	; Set the bit 4 (RXIC)
	ORR r5, r5, #0x10 ; 0001 0000
	STRB r5, [r4, #0x044]

	;if prompt was presented, then this handler gets point, if not no point
	;Check if round started
	LDR r5, ptr_to_roundState
	LDRB r6, [r5]
	CMP r6, #1
	BNE UART_END ;if not 1 round did not start, end handler

	;Check if space was pressed first, before giving point
	BL simple_read_character
	CMP r0, #0x32; ASCII for Space
	BNE UART_END ; if not space, go end round


	;Handle giving point
	LDR r7, ptr_to_spaceScore
	LDRB r8, [r7]
	ADD r8, r8, #1
	STRB r8, [r7]


UART_END:



	POP {r4-r12, lr}

	BX lr       	; Return


Switch_Handler:

	; Your code for your Switch handler goes here.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler
	PUSH {r4 - r12, lr}

	; Clear Interrupt
	MOV r4, #0x5000
	MOVT r4, #0x4002

	;GPIOICR Offset
	LDRB r5, [r4, #0x41C]
	ORR r5, r5, #0x10 ; 0001 0000
	STRB r5, [r4, #0x41C]

	;if prompt was presented, then this handler gets point, if not no point
	;Check if round started
	LDR r5, ptr_to_roundState
	LDRB r6, [r5]
	CMP r6, #1
	BNE SWITCH_END ;if not 1 round did not start, end handler

	;Handle giving point
	LDR r7, ptr_to_buttonScore
	LDRB r8, [r7]
	ADD r8, r8, #1
	STRB r8, [r7]



SWITCH_END:


	POP {r4 - r12, lr}

	BX lr       	; Return


Timer_Handler:

	; Your code for your Timer handler goes here.  It is not needed for
	; Lab #5, but will be used in Lab #6.  It is referenced here because
	; the interrupt enabled startup code has declared Timer_Handler.
	; This will allow you to not have to redownload startup code for
	; Lab #6.  Instead, you can use the same startup code as for Lab #5.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler.

	BX lr       	; Return


simple_read_character:

	PUSH {r4 - r12, lr}
	; Read from UART0 Data Register
	MOV r4, #0xC000
	MOVT r4, #0x4000

	LDRB r5, [r4, #0x18]

	LDRB r0, [r5] ;r0 has the character

	POP {r4 - r12, lr}


	MOV pc, lr	; Return

	.end
