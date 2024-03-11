	.data

	.global initialprompt
	.global press_enter
	.global press_button
	.global data1
	.global buttonScore
	.global spaceScore
	.global roundState




initialprompt: 	.cstring "\r\n--------------------------------------------------------------------------------\r\n|                                                                              |\r\n|                         THE REFLEX GAME DIRECTIONS                           |\r\n|                                                                              |\r\n--------------------------------------------------------------------------------\r\n|                                                                              |\r\n| Welcome to the Reflex Game! Compete against another player to see who has    |\r\n| the fastest reflexes. One player uses the SW1 button on the Tiva board, and  |\r\n| the other uses the space bar on the keyboard.                                |\r\n|                                                                              |\r\n| HOW TO PLAY:                                                                 |\r\n| 1. Read the rules.                                                            |\r\n| 2. Press the Enter key when you're ready to start the round.                 |\r\n| 3. After a random delay, you'll be prompted to press your button (SW1 or     |\r\n|    space bar). The first to press wins the round.                            |\r\n| 4. If you press too early, you're disqualified for that round.               |\r\n| 5. Scores are displayed after each round. Press Enter to start the next one. |\r\n|                                                                              |\r\n| The game continues until one player scores three points and wins!            |\r\n|                                                                              |\r\n| Good luck, and may the quickest reflex win!                                  |\r\n|                                                                              |\r\n********************************************************************************\r\n"
;initialprompt: 	.cstring " This is a reflex game. It will test which player has the faster reflex. \r\n User 1 has to press the space bar on the keyboard \r\n User 2 has to press the SW1 button on the Tiva \r\n Once round starts, a prompt will appear randomly to tell you to press your button. \r\n If you press your button first, you get a point \r\n If you press it before the prompt appears, you are disqualified for that round \r\n The first to 3 wins! \r\n"
press_enter: 	.string "Press Enter To Start!!!",0
press_button: 	.string "Press Your Button!!!",0
data1: 			.string"placeholder",0

;mydata:	.byte	0x20	; This is where you can store data.
			; The .byte assembler directive stores a byte
			; (initialized to 0x20) at the label mydata.
			; Halfwords & Words can be stored using the
			; directives .half & .word
roundState: 	.byte 0

	.text

	.global uart_interrupt_init
	.global gpio_interrupt_init
	.global UART0_Handler
	.global Switch_Handler
	.global Timer_Handler			; This is needed for Lab #6
	.global simple_read_character
	.global output_character		; This is from your Lab #4 Library
	.global read_character
	.global read_string				; This is from your Lab #4 Library
	.global output_string			; This is from your Lab #4 Library
	.global uart_init					; This is from your Lab #4 Library
	.global lab5
	.global print_all_numbers

ptr_to_button		.word press_button
ptr_to_data1		.word data1
ptr_to_enter:		.word press_enter
ptr_to_prompt1:		.word initialprompt
;ptr_to_mydata:		.word mydata
ptr_to_buttonScore: .word buttonScore
ptr_to_spaceScore: 	.word spaceScore
ptr_to_roundstate: 	.word roundState ; round_start

lab5:								; This is your main routine which is called from
; your C wrapper.
	PUSH {r4-r12,lr}   		; Preserve registers to adhere to the AAPCS

	bl uart_init
	bl uart_interrupt_init ;initializations
	bl gpio_interrupt_init

	MOV r8, #150 ;counter

	ldr r0, ptr_to_prompt1
	BL output_string			; displaying intial prompt

	MOV r0, #0xD	;Newline
    BL output_character
    MOV r0, #0xA
    BL output_character

    ldr r0, ptr_to_enter
	BL output_string

WAITING1:

	ldr r0, ptr_to_data1
	BL read_character
	MOV r6, r0

	MOV r0, #0xD	;Newline
    BL output_character
    MOV r0, #0xA
    BL output_character

    CMP r6, #13
    BNE WAITING1

TIMERLOOP:

    CMP r8, #0
    BGT DECREMENT

    ldr r0, ptr_to_roundstate
    ldrb r1,[r0]
    ADD r1,r1, #1
    STRB r1, [r0]

	MOV r0, #0xD	;Newline
    BL output_character
    MOV r0, #0xA
    BL output_character

    ldr r0, ptr_to_button
    BL output_string

    MOV r0, #12
    BL output_character






DECREMENT:
	SUB r8,r8, #1
	B TIMERLOOP












	;ldr r5, ptr_to_mydata




LOOP5:

	B LOOP5

	; This is where you should implement a loop, waiting for the user to
	; enter a q, indicating they want to end the program.

	POP {lr}		; Restore registers to adhere to the AAPCS
	MOV pc, lr

	.end
