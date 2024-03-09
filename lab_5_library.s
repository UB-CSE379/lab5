	.data

	.global prompt
	.global mydata

prompt:	.string "Your prompt with instructions is place here", 0
mydata:	.byte	0x20	; This is where you can store data. 
			; The .byte assembler directive stores a byte
			; (initialized to 0x20) at the label mydata.  
			; Halfwords & Words can be stored using the 
			; directives .half & .word 

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
ptr_to_mydata:		.word mydata

uart_interrupt_init:
		
	; Your code to initialize the UART0 interrupt goes here
	PUSH {r4-r12,lr} 
	; Set the Receive Interrupt Mask 
	
	MOV r0, #0xC000
	MOVT r0, #0x4000 ; UART Base Address
	
	LDRB r4, [r0, #0x038] ; UARTIM Offset
	
	ORR r4, r4, #0x10 ; 0001 0000
	STRB r4, [r0, #0x038
	
	;Configure Processor to Allow Interrupts in UART
	MOV r1, #0xE000
	MOVT r1, #0xE000 ; ENO Base Address
	
	LDRB r5, [r1, #0x100] 
	ORR r5, r5, #0x20 ; 0010 0000
	STRB r5, [r1, #0x100] 
	
	POP {r4-r12,lr}
	MOV pc, lr


gpio_interrupt_init:
		
	; Your code to initialize the SW1 interrupt goes here
	; Don't forget to follow the procedure you followed in Lab #4
	; to initialize SW1.
	PUSH {r4-r12,lr} 
	
	;Enable Clock Address for Port F
    MOV r1, #0xE000
    MOVT r1, #0x400F
    
    ;NEED TO ENABLE CLOCK FOR ONLY PORT F 
    LDRB r4, [r1, #0x608]
    ORR r4, r4, #0x10	; find specfic port 
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
	STRB r7, [r7, #0x51C] ;write 1 to make pin digital
	
	;Enable Edge Sensitive GPIOIS
	LDRB r8, [r3, #0x404]
	AND r8, r8, #0xEF ; Write 0 to pin 4 to enable edge sensitive
	STRB r8, [r3, #0x404] 
	
	; Allow GPIOEV to determine edge, write 0 to pin on port
	LDRB r9, [r3, #0x408]
	AND r9, r9, #0xEF; ; write 0 to allow gpioev to determine edge
	STRB r9, [r3, #0x408]
	
	;get data if button is pressed, released
	; Write 0 to pin when button press 
	; Write 1 to pin when button release
	LDRB r10, [r3, #0x51C] ; GPIO DATA to see if button is pressed
	AND r10, r10, #0x10
	CMP r10, #0x10
	BNE PRESS: 
	;Not being Pressed below, write 1 to button release
	LDRB r6, [r3, #0x40C]
	ORR r6, r6, #0x10		; 0001 0000
	STRB r6, [r3, #0x40C]
	B CONT
	
PRESS: ; pressed write 0 to pin 
	LDRB r6, [r3, #0x40C] 
	AND r6, r6, #0xEF	; 1110 1111
	STRB r6, [r3, #0x40C]
	
CONT: 
	;Enable the Interrupt, write 1 to Bit 4
	LDRB r7, [r3, #0x410]
	ORR r7, r7, #0x10
	STRB r7, [r3, #0x410]
	
	;ENO, set bit 30 bit
	MOV r8, #0xE000
	MOVT r8, #0xE000 ;ENO Base Address
	
	LDRB r9, [r8, #0x100] ; ENO Offset
	ORR r9, r9, #0x40000000   ; 0100 0000 0000 0000 0000 0000 0000 0000
	STRB r9, [r8, #0x100]
	
	POP {r4-r12,lr}
	
	MOV pc, lr


UART0_Handler: 
	
	; Your code for your UART handler goes here.
	; Remember to preserver registers r4-r11 by pushing then popping 
	; them to & from the stack at the beginning & end of the handler

	BX lr       	; Return


Switch_Handler:
	
	; Your code for your UART handler goes here.
	; Remember to preserver registers r4-r11 by pushing then popping 
	; them to & from the stack at the beginning & end of the handler

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
	
	MOV pc, lr	; Return

	.end
