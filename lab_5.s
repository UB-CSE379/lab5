	.data

	.global prompt
	;.global mydata
	.global buttonScore
	.global spaceScore
	.global roundState

prompt:	.string "Your prompt with instructions is place here", 0
;mydata:	.byte	0x20	; This is where you can store data.
			; The .byte assembler directive stores a byte
			; (initialized to 0x20) at the label mydata.
			; Halfwords & Words can be stored using the
			; directives .half & .word
roundState: .byte 0

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

lab5:								; This is your main routine which is called from
; your C wrapper.
	PUSH {r4-r12,lr}   		; Preserve registers to adhere to the AAPCS
	ldr r4, ptr_to_prompt
	;ldr r5, ptr_to_mydata

 	bl uart_init
	bl uart_interrupt_init
	bl gpio_interrupt_init
	NOP
	NOP
	NOP


LOOP5:

	B LOOP5

	; This is where you should implement a loop, waiting for the user to
	; enter a q, indicating they want to end the program.

	POP {lr}		; Restore registers to adhere to the AAPCS
	MOV pc, lr

	.end
