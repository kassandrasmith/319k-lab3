;****************** main.s ***************
; Program written by: Kassandra Smith and Madhumitha Venkataraman
; Date Created: 1/24/2015 
; Last Modified: 1/31/2015
; Section 4-5pm     TA: Wooseok Lee
; Lab number: 1
; Brief description of the program
; The overall objective of this system is a digital lock
; Hardware connections
;  PE3 is switch input  (1 means switch is not pressed, 0 means switch is pressed)
;  PE4 is switch input  (1 means switch is not pressed, 0 means switch is pressed)
;  PE2 is LED output (0 means door is locked, 1 means door is unlocked) 
; The specific operation of this system is to 
;   unlock if both switches are pressed


;EQU #, # is the location where the GPIO stuff is located

GPIO_PORTE_DATA_R       EQU   0x400243FC
GPIO_PORTE_DIR_R        EQU   0x40024400
GPIO_PORTE_AFSEL_R      EQU   0x40024420
GPIO_PORTE_DEN_R        EQU   0x4002451C
GPIO_PORTE_AMSEL_R      EQU   0x40024528
GPIO_PORTE_PCTL_R       EQU   0x4002452C
SYSCTL_RCGCGPIO_R	EQU   0x400FE608


;LEDBit=0x04
;SwitchBits=0x18



;An AREA statement defines ARM-compatible segment
;ALIGN=2, 2^2=4, 4bytes=32 bits, makes the code word-aligned
;Thumb is the instruction set being used

      AREA    |.text|, CODE, READONLY, ALIGN=2
      THUMB
      EXPORT  Start
		  
Start
	;Initialize the clock,
	LDR R1, =SYSCTL_RCGCGPIO_R      ;activate clock
    LDR R0, [R1]                 
    ORR R0, R0, #0x10               ; set bit 5 to turn on clock
    STR R0, [R1]                  	; put it back
    NOP
    NOP                             ;stabilize
	
	;configure the rest of the port
	;p. 354
	
	;Set DEN so that the bits are useable
	LDR R1, =GPIO_PORTE_DEN_R       ;Port E digital port
    MOV R0, #0xFF                   ; 1 enables digital I/O
    STR R0, [R1]    
	
	;since we want the two switches to be inputs and the led to be an output we make all bits 0 except the LEDbit
	LDR R1, =GPIO_PORTE_DIR_R       ;direction register
    MOV R0,#0x04                    ; PortE bit 2 is set to 1
    STR R0, [R1] 

	;We don't need the pins' special funtions so we set it to 0
	LDR R1, =GPIO_PORTE_AFSEL_R     ; alternate function select
    MOV R0, #0                      ; 0, alternate function is off
    STR R0, [R1]  	

	;We want to disable analog functionality
	LDR R1, =GPIO_PORTE_AMSEL_R     ;analog functionality
    MOV R0, #0                      ; 0, analog is off
    STR R0, [R1]                    
	
	;none of the pins (p.146 Table 4.5) need to be turned on
	LDR R1, =GPIO_PORTE_PCTL_R      ; configure as GPIO
    MOV R0, #0             ; 0 means configure Port E as GPIO
    STR R0, [R1]                  
	
	
loop
	AND R1, #0x0
 LDR R1, =GPIO_PORTE_DATA_R ; pointer to Port E data
 LDR R3, [R1] ;loads the on bits into R3
 AND R3, #0x18 ;masks the on bits so that only the two switches show
 EOR R3, #0x18 ;exlusive or compensates for negative logic
 ADD R4, R3 ;puts the on bits into R4 and R5 for mask
 ADD R5, R3
 AND R4, #0x10 ;masks for 4th bit
 AND R5, #0x8  ;masks for 3rd bit
 LSR R4, #2 ;Shifts right to get on/off bits in the same place as the LED bit
 LSR R5, #1 
 AND R4, R5 ;Ands, will be 1 if both switches are on, 0 in any other instance
 
 ;stores whatever the result is 1 or 0 LED bit into the machine
 	LDR R1, =GPIO_PORTE_DATA_R
	STR R4, [R1]

	
	B loop
 
      ALIGN        ; make sure the end of this section is aligned
      END          ; end of file