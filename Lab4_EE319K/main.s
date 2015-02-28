;****************** main.s ***************
; Program written by: put your names here
; Date Created: 1/24/2015 
; Last Modified: 1/24/2015 
; Section 1-2pm     TA: Wooseok Lee
; Lab number: 4
; Brief description of the program
;   If the switch is presses, the LED toggles at 8 Hz
; Hardware connections
;  PE0 is switch input  (1 means pressed, 0 means not pressed)
;  PE1 is LED output (1 activates external LED on protoboard) 
;Overall functionality of this system is the similar to Lab 3, with four changes:
;1-  activate the PLL to run at 80 MHz (12.5ns bus cycle time) 
;2-  initialize SysTick with RELOAD 0x00FFFFFF 
;3-  add a heartbeat to PF2 that toggles every time through loop 
;4-  add debugging dump of input, output, and time
; Operation
;	1) Make PE1 an output and make PE0 an input. 
;	2) The system starts with the LED on (make PE1 =1). 
;   3) Wait about 62 ms
;   4) If the switch is pressed (PE0 is 1), then toggle the LED once, else turn the LED on. 
;   5) Steps 3 and 4 are repeated over and over


SWITCH                  EQU 0x40024004  ;PE0
LED                     EQU 0x40024008  ;PE1
SYSCTL_RCGCGPIO_R       EQU 0x400FE608
SYSCTL_RCGC2_GPIOE      EQU 0x00000010   ; port E Clock Gating Control
SYSCTL_RCGC2_GPIOF      EQU 0x00000020   ; port F Clock Gating Control
GPIO_PORTE_DATA_R       EQU 0x400243FC
GPIO_PORTE_DIR_R        EQU 0x40024400
GPIO_PORTE_AFSEL_R      EQU 0x40024420
GPIO_PORTE_PUR_R        EQU 0x40024510
GPIO_PORTE_DEN_R        EQU 0x4002451C
GPIO_PORTF_DATA_R       EQU 0x400253FC
GPIO_PORTF_DIR_R        EQU 0x40025400
GPIO_PORTF_AFSEL_R      EQU 0x40025420
GPIO_PORTF_DEN_R        EQU 0x4002551C
NVIC_ST_CTRL_R          EQU 0xE000E010
NVIC_ST_RELOAD_R        EQU 0xE000E014
NVIC_ST_CURRENT_R       EQU 0xE000E018
GPIO_PORTE_PCTL_R       EQU   0x4002452C
GPIO_PORTE_LOCK_R 		EQU   0x40025520
GPIO_PORTE_CR_R 		EQU   0x40025524
GPIO_PORTE_AMSEL_R      EQU   0x40024528
           THUMB
           AREA    DATA, ALIGN=4
SIZE       EQU    50
;You MUST use these two buffers and two variables
;You MUST not change their names
;These names MUST be exported
           EXPORT DataBuffer  
           EXPORT TimeBuffer  
           EXPORT DataPt [DATA,SIZE=4] 
           EXPORT TimePt [DATA,SIZE=4]
DataBuffer SPACE  SIZE*4
TimeBuffer SPACE  SIZE*4
DataPt     SPACE  4
TimePt     SPACE  4

    
      ALIGN          
      AREA    |.text|, CODE, READONLY, ALIGN=2
      THUMB
      EXPORT  Start
      IMPORT  TExaS_Init


Start BL   TExaS_Init  ; running at 80 MHz, scope voltmeter on PD3
; initialize Port E
    LDR R1, =SYSCTL_RCGCGPIO_R ;activate clock
	LDR R0, [R1]
	ORR R0, R0, #0x30 ;set bit 4 to turn on clock
	STR R0, [R1] ;put it back
	NOP ;wait for stabilization,
	NOP
	LDR R1, =GPIO_PORTE_LOCK_R ;unlock the lock register
	LDR R0, =0x4C4F434B ;unlock GPIO Port E Commit Register
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_CR_R;enable commit for Port E
	MOV R0, #0xFF ;1 means allow access
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_AMSEL_R ;disable analog functionality
	LDR R0, [R1]
	BIC R0, #0x03 ;Clear bits 1 and 0
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_PCTL_R ;configure as GPIO
	LDR R0, [R1]
	BIC R0, #0x14 ;0 means configure Port E as GPIO
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_DIR_R ;set direction register
	LDR R0, [R1]
	ORR R0,#0x02 ;PORTE bit 1 is set to 1
	BIC R0,#0x01 ;clear bit 0
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_AFSEL_R ;disable alternate function select
	LDR R0, [R1]
	BIC R0, #0x14 ;We don't need the pins' special functions so we set it to 0
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_DEN_R ;Set DEN so that the bits are useable, Port E digital port
	LDR R0, [R1]
	ORR R0, #0x03 
	STR R0, [R1]
	LDR R1, =GPIO_PORTE_DATA_R
	LDR R0, [R1]
	ORR R0, #0x02 ;starting the program with the LED on
	STR R0, [R1]
	AND R5, R5, #0 ;clearing register 5, to be used as counter for delay
; initialize Port F
	LDR R1, =GPIO_PORTF_DIR_R ;set direction register
	LDR R0, [R1]
	ORR R0,#0x02 ;PORTF bit 1 is set to 1
	BIC R0,#0x01 ;clear bit 0
	STR R0, [R1]
	LDR R1, =GPIO_PORTF_AFSEL_R ;disable alternate function select
	LDR R0, [R1]
	BIC R0, #0x14 ;We don't need the pins' special functions so we set it to 0
	STR R0, [R1]
	LDR R1, =GPIO_PORTF_DEN_R ;Set DEN so that the bits are useable, Port E digital port
	LDR R0, [R1]
	ORR R0, #0x03 
	STR R0, [R1]
	LDR R1, =GPIO_PORTF_DATA_R
; initialize debugging dump, including SysTick


      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  BL   Debug_Capture
	ADD R5, #1018 ;set R5 to 3250
	MUL R5, R5 
delay ;delay function
	ADD R5, #-1 ;subtract one from R5
	CMP R5, #0 ;if R5 greater than zero, branch to delay
	BGT delay ;if R5 is equal to zero, proceed
	
	LDR R2, =GPIO_PORTE_DATA_R
	LDR R6, =GPIO_PORTE_DATA_R
	
	LDR R6, [R6] ;load data from Port E
	
	AND R6, #0x01 ;masking for bit 0
	CMP R6, #0x01 ;check and see is bit 0 is "1" (switch not pressed)
	BNE turnon ;if switch is not pressed, take the branch
	LDR R6, =GPIO_PORTE_DATA_R
	LDR R6, [R6] ;load data from Port E
	AND R6, #0x02 ;masking for bit 1
	EOR R6, R6, #0x2 ;NOT bit 1
	STR R6, [R2] ;store result back to Port E
	B loop ;Branch back to beginning of loop
turnon ;turning or keeping the LED on
	LDR R1, =GPIO_PORTE_DATA_R
	LDR R2, =GPIO_PORTE_DATA_R
	LDR R1, [R1] ;load data from Port E
	ORR R1, #0x02 ;set bit 1 to "1"
	STR R1, [R2] ;store result back to Port E
	;end subroutine
;heartbeat
; Delay
;input PE0 test output PE1
	  B    loop


;------------Debug_Init------------
; Initializes the debugging instrument
; Input: none
; Output: none
; Modifies: none
; Note: push/pop an even number of registers so C compiler is happy
Debug_Init
      
; init SysTick
	  LDR R1, =NVIC_ST_CTRL_R
	  MOV R0, #0
	  STR R0, [R1]
	  LDR R1, =NVIC_ST_RELOAD_R
	  LDR R0, =0x00FFFFFF
	  STR R0, [R1]
	  LDR R1, =NVIC_ST_CTRL_R
	  MOV R0, #0x05
	  STR R0, [R1]
i     RN 0 
Array RN 1
	  MOV i, #0
	  MOV R2, #0xF
loop2 STR R2, [Array,i] 
	  ADD i, #2
	  CMP i, #20
	  BLO loop2
	  LDR R1, =DataBuffer
	  LDR R0, =DataPt
	  STR R1, [R0] 
	  LDR R1, =TimeBuffer
	  LDR R0, =TimePt
	  STR R1, [R0]  
      BX LR

;------------Debug_Capture------------
; Dump Port E and time into buffers
; Input: none
; Output: none
; Modifies: none
; Note: push/pop an even number of registers so C compiler is happy
Debug_Capture
      PUSH {R4, R5, R6, LR} 
	  LDR R0, =GPIO_PORTE_DATA_R
	  LDR R1, =NVIC_ST_CTRL_R
	  LDR R2, [R0]
	  LDR R3, [R0]
	  AND R2, #0x01
	  AND R3, #0x02
	  LSR R3, #1 
	  LSL R2, #4 
	  ADD R2, R2, R3; masking stuff ends here
	  LDR R4, = DataPt
	  LDR R6, = DataBuffer 
	  LDR R5, [R4] 
	  CMP R5, #SIZE 
	  BHS done; full?
	  STR R2, [R6,R5] 
	  ADD R5, #1 
	  STR R5, [R4] 
	  LDR R4, = TimePt
	  LDR R5, = TimeBuffer
	  LDR R6, [R4] 
	  STR R1, [R5,R6]
	  ADD R6, #1
	  STR R6, [R4] 
done  POP {R4, R5, R6, LR}
      BX LR


    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file