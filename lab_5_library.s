	.data

	;.global prompt
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
	.global print_all_numbers
	.global read_character

;ptr_to_prompt:		.word prompt
;ptr_to_mydata:		.word mydata

ptr_to_buttonScore: .word buttonScore
ptr_to_spaceScore: .word spaceScore
ptr_to_roundState: 	.word roundState

U0FR: 	.equ 0x18	; UART0 Flag Register

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

	;Check if enter pressed
	BL simple_read_character
	CMP r0, #0xA ;ASCII for ENTER
	BEQ UART_ENTER;

	;Check if q was pressed to end program
	CMP r0, #0x81 ; ASCII for q
	BEQ UART_END

	;Check if space was pressed first, before letting Handler move
	BL simple_read_character
	CMP r0, #0x32; ASCII for Space
	BNE UART_END ; if not space, exit

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

	;Handle giving point
	LDR r7, ptr_to_spaceScore
	LDRB r8, [r7]
	ADD r8, r8, #1
	STRB r8, [r7]
	B UART_END

UART_ENTER:
	ldr r0, ptr_to_roundstate
    ldrb r1,[r0]
    ADD r1,r1, #1
    STRB r1, [r0]
    B UART_END

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


uart_init:
	PUSH {r4-r12,lr} 	; Store any registers in the range of r4 through r12
							; Your code for your uart_init routine is placed here
	MOV r0, #0xE618
    MOVT r0, #0x400F
    MOV r1, #0x1
    STR r1, [r0]



    MOV r0, #0xE608
    MOVT r0, #0x400F
    MOV r1, #0x1
    STR r1, [r0]



    MOV r0, #0xC030
    MOVT r0, #0x4000
    MOV r1, #0x0
    STR r1, [r0]



     MOV r0, #0xC024
    MOVT r0, #0x4000
    MOV r1, #8
    STR r1, [r0]



    MOV r0, #0xC028
    MOVT r0, #0x4000
    MOV r1, #44
    STR r1, [r0]



    MOV r0, #0xCFC8
    MOVT r0, #0x4000
    MOV r1, #0x0
    STR r1, [r0]



    MOV r0, #0xC02C
    MOVT r0, #0x4000
    MOV r1, #0x60
    STR r1, [r0]



    MOV r0, #0xC030
    MOVT r0, #0x4000
    MOV r1, #0x301
    STR r1, [r0]



    MOV r0, #0x451C
    MOVT r0, #0x4000
    MOV r1, #0x03
    LDR r2 ,[r0]
    ORR r1 , r1, r2
    STR r1, [r0]


    MOV r0, #0x4420
    MOVT r0, #0x4000
    MOV r1, #0x03
    LDR r2 ,[r0]
    ORR r1 , r1, r2
    STR r1, [r0]


	MOV r0, #0x452C
    MOVT r0, #0x4000
    MOV r1, #0x11
    LDR r2 ,[r0]
    ORR r1 , r1, r2
    STR r1, [r0]

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________


gpio_btn_and_LED_init:
	PUSH {r4-r12,lr}	; Spill registers to stack

	;Enable Clocks for Ports B, D, and F
	MOV r4, #0xE000
	MOVT r4, #0x400F
	LDRB r5, [r4, #0x608]		  ;00  1  0  1  0  1  0
	ORR r5, r5, #0x2A ;0010 1010  Port F, E, D, C, B, A
	STRB r5, [r4, #0x608]

	;Port F Pin 4 is input, write 0
		; - need a pull-up resistor for SW1
	; Port D Pins 0-3 are input for Btns, write 0
	; Port B Pins 0-3 are output for LEDs, write 1
	; Port B Base Address-> 0x40005000
	MOV r6, #0x5000
	MOVT r6, #0x4000
	;Port D Base Address -> 0x40007000
	MOV r7, #0x7000
	MOVT r7, #0x4000

	;Port F Base Address -> 0x40025000
	MOV r8, #0x5000
	MOVT r8, #0x4002

	;Set Pin Directions
	;Port B Pin Direction is Output, write 1 to pins 0 - 3
	LDRB r9, [r6, #0x400]
    ORR r9, r9, #0x0F ;configure pins 0 - 3 as output
    STRB r9, [r6, #0x400] ; write 1 to mem

	;Port D Pin Direction is Input, Write 0 to pins 0-3
	LDRB r9, [r7, #0x400]
	AND r9, r9, #0x00
	STRB r9, [r7, #0x400]

	;Port F Pin Direction is Input, Write 0 to pin 4
	; Port F Pin Direction Output for pins 0 - 3, write 1
	LDRB r9, [r8, #0x400]
	ORR r9, r9, #0x0E ; 0000 1110
	STRB r9, [r8, #0x400]

    ;SET PIN AS DIGITAL
    ; Set Pins 0-3 in Port B Digital, write 1
    LDRB r10, [r6, #0x51C]
    ORR r10, r10, #0x0F
    STRB r10, [r6, #0x51C]

    ; Set Pins 0-3 in Port D Digital, write 1
    LDRB r11, [r7, #0x51C]
    ORR r11, r11, #0x0F
    STRB r11, [r7, #0x51C]

    ; Initilize Pull-up resistor for Port F, write 1
    LDRB r12, [r8, #0x510]
    ORR r12, r12, #0x10
    STRB r12, [r8, #0x510]

    ; Set Pin pins 1-4 in Port F Digital, write 1
    LDRB r12, [r8, #0x51C]
    ORR r12, r12, #0x1E
    STRB r12, [r8, #0x51C]

          ; Your code is placed here

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________


output_character:
	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here
	MOV r1, #0xC000			;Base address
	MOVT r1, #0x4000
LOOP2:
	LDRB r2, [r1, #U0FR]
	AND r2,r2, #0x20
	CMP r2, #0x20
	BEQ LOOP2
	STRB r0,[r1]

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________


read_character:
	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here
  	MOV r1, #0xC000
	MOVT r1, #0x4000

LOOP1:

	LDRB r2, [r1, #U0FR]
	AND r2,r2, #0x10
	CMP r2, #0x10
	BEQ LOOP1

	LDRB r0,[r1]

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________

print_all_numbers:
    PUSH {r4-r12, lr}        ; Save registers that will be used.

    MOV r2, r0               ; Copy the target number to r2 for manipulation.
    MOV r3, #0               ; r3 will count the number of digits.

    ; Special handling to print 0 directly if the number is 0.
    CMP r2, #0
    BEQ print_zero           ; If the number is zero, print it directly and skip to done.

extract_digits:
    CMP r2, #0               ; Check if there are more digits to process.
    BLE print_digits         ; If r2 is less or equal to 0, start printing digits.

    ; Extract the last digit and push it onto the stack.
    MOV r6, #10
    UDIV r1, r2, r6          ; Divide r2 by 10, quotient in r1.
    MUL r4, r1, r6           ; Multiply quotient by 10.
    SUB r0, r2, r4           ; Subtract to find the remainder, which is the last digit.
    PUSH {r0}                ; Push the digit onto the stack.
    ADD r3, r3, #1           ; Increment the digit count.
    MOV r2, r1               ; Prepare the next number for extraction.
    B extract_digits

print_digits:
    CMP r3, #0               ; Check if there are digits to print.
    BLE done                 ; If no digits to print, we're done.

    ; Pop a digit off the stack and print it.
    POP {r0}                 ; Pop the next digit.
    ADD r0, r0, #'0'         ; Convert to ASCII.
    BL output_character      ; Print the character.
    SUB r3, r3, #1           ; Decrement the digit count.
    B print_digits           ; Continue printing until all digits are printed.

print_zero:
    MOV r0, #'0'             ; Move ASCII code for '0' into r0.
    BL output_character      ; Print '0'.

done:
    POP {r4-r12, lr}         ; Restore registers.
    MOV pc, lr               ; Return from subroutine.


;_________________________________________________________________________________________________________

read_string:
	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here
    MOV r4, r0

LOOP_RS:
    BL read_character
    CMP r0, #0xD
    BEQ ENTER
    STRB r0, [r4]
    BL output_character
    ADD r4, r4, #1
    B LOOP_RS

ENTER:
    MOV r0, #0x0
    STRB r0, [r4]

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________


output_string:
	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here
    MOV r4, r0

LOOP_OS:
	LDRB r6, [r4]
	ADD r4, r4, #1

	CMP r6, #0x0
	BEQ EXIT
	MOV r0,r6
	BL output_character
	B LOOP_OS



EXIT:

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________

int2string:
	PUSH {r4-r12,lr} 	; Store any registers in the range of r4 through r12
							; that are used in your routine.  Include lr if this
							; routine calls another routine.

						; Your code for your int2string routine is placed here
						;handle negatives
    MOV r4, r0
    MOV r5, r1        ; Move int into r5
    MOV r10, #0       ; Initialize accum

    CMP r5, #0
    BGE pos      ; If positive
    MOV r8, #'-'
    STRB r8, [r4], #1
    RSB r5, r5, #0    ; make positive

pos: ; Check if the num is zero
    CMP r5, #0
    BEQ zero_fin ; If zero, go to zero_finalize

conversion:
    ; Extract digits from the number
    MOV r7, #10
    UDIV r8, r5, r7
    MUL r11, r8, r7
    SUB r7, r5, r11
    ADD r7, r7, #'0'
    PUSH {r7}
    ADD r10, r10, #1  ; Increment
    MOV r5, r8
    CMP r5, #0
    BNE conversion ; Loop

r_loop:
    CMP r10, #0
    BEQ f
    POP {r7}
    STRB r7, [r4], #1 ; Store the digit
    SUBS r10, r10, #1 ; Decrement
    B r_loop    ; Repeat until all digits are stored



zero_fin:
    MOV r8, #'0'
    STRB r8, [r4], #1 ; Store and increment
    B f       ; Go to f to null-term and end

f:

    MOV r8, #0
    STRB r8, [r4]

    POP {r4-r12,lr}   ; Restore registers
    mov pc, lr

;_______________________________________________________________________________________________

string2int:
	PUSH {r4-r12,lr} 	; Store any registers in the range of r4 through r12
							; Your code for your string2int routine is placed here

    MOV r2, #0
    MOV r3, #10            ; Base val
    MOV r8, #0             ;flag for neg nums
    LDRB r4, [r0]          ; Load
    CMP r4, #'-'           ; Compare ASCII value
    BNE conv_loop
    ADD r0, r0, #1         ; If '-', skip
    MOV r8, #1             ; Set flag

conv_loop:
    LDRB r4, [r0], #1      ; Load a byte, increment r0
    CMP r4, #0
    BEQ conver_d    ; If byte is NULL, done with conversion

    SUB r4, r4, #0x30      ; Convert ASCII digit to int
    MUL r2, r2, r3         ; Multiply result by 10
    ADD r2, r2, r4         ; Add to accumulator

    B conv_loop         ; Loop

conver_d:
    CMP r8, #1             ; Check if the number was neg
    BEQ make_neg      ; If neg adjust
    B move_res          ; move result into r0

make_neg:
    RSB r2, r2, #0             ; Negate

move_res:
    MOV r0, r2
    POP {r4-r12,lr}

	mov pc, lr

;_________________________________________________________________________________________________________________________________________________


read_from_push_btns:
	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here
    ;Initilize r3 with PORT D Base Address
    MOV r3, #0x7000
    MOVT r3, #0x4000

LOOP20:
 	;GPIODATA
 	LDRB r9, [r3, #0x3FC]
 	AND r9, r9, #0x0F ; if r9 == 0000 0001 SW5 is pressed
 					  ; if r9 == 0000 0010 SW4 is pressed
 					  ; if r9 == 0000 0100 SW3 is pressed
 					  ; if r9 == 0000 1000 SW2 is pressed

 	;Find which button was pressed
 	CMP r9, #0x01 ; SW5 is pressed
 	BEQ PRESS_5

 	CMP r9, #0x02; SW4 is pressed
 	BEQ PRESS_4

 	CMP r9, #0x04; SW3 is pressed
 	BEQ PRESS_3

 	CMP r9, #0x08; SW2 is pressed
 	BEQ PRESS_2

 	;MOV r0, #0 ; Nothing is pressed
 	B LOOP20

PRESS_5:
	MOV r0, #5
	B STOP_BTNS
PRESS_4:
	MOV r0, #4
	B STOP_BTNS
PRESS_3:
	MOV r0, #3
	B STOP_BTNS
PRESS_2:
	MOV r0, #2
	B STOP_BTNS

STOP_BTNS:
	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________


illuminate_LEDs:
	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here
    ;Get LEDS
    ;MOV r0, #0 ;First LED
    ;MOV r0, #1 ; Second LED
    ;MOV r0, #2 ; Third LED
    ;MOV r0, #3; 4th LED
    ;MOV r0, #5 ; ALL LEDS

	; Get Port B Base Address
	MOV r6, #0x5000
	MOVT r6, #0x4000

	LDRB r1, [r6, #0x3FC]
    CMP r0, #0
    BEQ LED0

    CMP r0, #1
    BEQ LED1

    CMP r0, #2
    BEQ LED2

    CMP r0, #3
    BEQ LED3

    CMP r0, #4
    BEQ LEDALL
LED0:
	ORR r1, r1, #0x01
	STRB r1, [r6, #0x3FC]
	B LED_STOP

LED1:
	ORR r1, r1, #0x02
	STRB r1, [r6, #0x3FC]
	B LED_STOP

LED2:
	ORR r1, r1, #0x04
	STRB r1, [r6, #0x3FC]
	B LED_STOP

LED3:
	ORR r1, r1, #0x08
	STRB r1, [r6, #0x3FC]
	B LED_STOP
LEDALL:
	ORR r1, r1, #0x0F
	STRB r1, [r6, #0x3FC]
	B LED_STOP
LED_STOP:

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________


illuminate_RGB_LED:

	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here
    ;Initialize Clock Address
    ; Color is passed in from r0
    ;MOV r0, #1 	;RED
    ;MOV r0, #2 ;BLUE
    ;MOV r0, #3 ;GREEN
    ;MOV r0, #4 ;PURPLE -> RED AND BLUE
    ;MOV r0, #5 ;YELLOW -> RED AND GREEN
    ;MOV r0, #6 ;WHITE -> RED, BLUE, AND GREEN

    MOV r3, #0x5000
    MOVT r3, #0x4002

    LDRB r9, [r3, #0x3FC] ; GPIODATA

	CMP r0, #1
	BEQ RED

 	CMP r0, #2
  	BEQ BLUE

   	CMP r0, #3
	BEQ GREEN

	CMP r0, #4
	BEQ PURPLE

	CMP r0, #5
	BEQ YELLOW

	CMP r0, #6
	BEQ WHITE


    ; RED , turn on pin 1, turn off pin 2 and 3
RED:
    ORR r9, r9, #0x02     ; need to turn pin 1 on that is 0000 0010
    STRB r9, [r3, #0x3FC]		; Turn on 0000 0010
	B COLOR_STOP

    ; BLUE, turn on pin 2, turn off pin 1 and 3 so 0000 0100
BLUE:
	ORR r9, r9, #0x04
	STRB r9, [r3, #0x3FC]
	B COLOR_STOP

    ; GREEN, turn on pin 3, turn off pin 1 and 2 so 0000 1000
GREEN:
	ORR r9, r9, #0x08
	STRB r9, [r3, #0x3FC]
	B COLOR_STOP

    ; PURPLE = red + blue, pins 1 and 2 on, 3 off -> 0000 0110
PURPLE:
	ORR r9, r9, #06
	STRB r9, [r3, #0x3FC]
	B COLOR_STOP

    ; YELLOW = red + green, pins 1 and 3, 2 off -> 0000 1010
YELLOW:
	ORR r9, r9, #0x0A
	STRB r9, [r3, #0x3FC]
	B COLOR_STOP

    ; WHITE = red + blue + green, pins 1-3 on -> 0000 1110
WHITE:
	ORR r9, r9, #0x0E
	STRB r9, [r3, #0x3FC]
	B COLOR_STOP

COLOR_STOP:

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________


read_tiva_push_button:
	PUSH {r4-r12,lr}	; Spill registers to stack

          ; Your code is placed here

    ;Initialize r3 with Port F address
    MOV r3, #0x5000
    MOVT r3, #0x4002
LOOP30:
    LDRB r9, [r3, #0x3FC] ;GPIODATA
    AND r9, r9, #0x10	;

    CMP r9, #0x10 ; check if pin is being pressed
    BEQ LOOP30
    BNE PRESS ; if r9 == 0, r0 = 1
    MOV r0, #0 ; if r9 == 1, r0 = 0

	B STOP

PRESS:
	MOV r0, #1; button is being pressed


STOP:


	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

;_________________________________________________________________________________________________________________________________________________

div_and_mod:
	PUSH {r4-r12, lr}    ; Save registers

    CMP r1, #0            ; Check for zero or negative divisor
    BLE zeros_or_invalid  ; If divisor <= 0, go to error handling or zero initialization

    ; Direct division to calculate quotient
    UDIV r2, r0, r1       ; r2 = r0 / r1, quotient

    ; Calculate remainder
    MUL r3, r2, r1        ; r3 = r2 * r1
    SUB r3, r0, r3        ; r3 = r0 - r3, remainder

    ; Move the quotient to r0 and remainder to r1
    MOV r0, r2            ; Quotient
    MOV r1, r3            ; Remainder

    B cleanup             ; Go to cleanup

zeros_or_invalid:
    MOV r0, #0            ; Set quotient to zero
    MOV r1, #0            ; Set remainder to zero

cleanup:
	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr


	.end
