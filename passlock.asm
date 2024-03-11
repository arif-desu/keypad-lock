RS EQU P0.7			;RS pin of LCD
RW EQU P0.6			;RW pin of LCD
E  EQU P0.5			;E (latch enable) pin of LCD
SEL EQU 41H		;SEL is used as a flag, location - bit addressable area of RAM
CONT EQU P3.3	;control pin of servo


ORG 000H 

ACALL DEBOUNCE
ACALL LCD_INIT
ACALL DELAY3sec

MOV DPTR,#TEXT1
ACALL LCD_OUT
ACALL DELAY3sec


MAIN:

SETB P3.1			;lock button
SETB P3.2			;unlock button
CLR CONT
ACALL LCD_INIT
;Y3:
;ACALL LCD_INIT2
MOV DPTR,#TEXT2
ACALL LCD_OUT
ACALL LINE2
MOV DPTR,#TEXT3
ACALL LCD_OUT
ACALL DEBOUNCE


OPT1:JB P3.2,OPT2
ACALL LOCK
ACALL CLRSCR
ACALL LINE1
MOV DPTR,#TEXT4
ACALL LCD_OUT
ACALL DELAY3sec
SJMP MAIN



OPT2:
JB P3.1,OPT1
ACALL READ_KEYPRESS	;take input
ACALL LINE1 			; go to line 1 after reading input
MOV DPTR,#CHKMSG
ACALL LCD_OUT
ACALL DELAY3sec			;3 sec
ACALL CHECK_PASSWORD    ;check password right or wrong  
SJMP MAIN



;LCD functions- START
LCD_INIT: MOV DPTR,#INIT_COMMANDS			;Setup LCD to display
          SETB SEL
          ACALL LCD_OUT
          CLR SEL
          RET      

LCD_INIT2:
MOV DPTR,#INIT2		;Setup LCD to display
          SETB SEL
          ACALL LCD_OUT
          CLR SEL
          RET      

LCD_OUT:  CLR A
           MOVC A,@A+DPTR
           JZ EXIT				;when value at DPTR=0, A+DPTR=0, then exit 
           INC DPTR
           JB SEL,CMD			;if SEL=1, write command, else write data. SEL=1 only through INIT
           ACALL DATA_WRITE
           SJMP LCD_OUT
CMD:      ACALL CMD_WRITE 
           SJMP LCD_OUT
EXIT:	   RET          

LINE2:MOV A,#0C0H 		;move to line 2 beginning
    ACALL CMD_WRITE
    RET   
    
LINE1: MOV A,#80H    	;move to line 1 beginning
ACALL CMD_WRITE
RET

CLRSCR: MOV A,#01H			;clrscreen command 01H
ACALL CMD_WRITE
RET

CMD_WRITE: MOV P2,A			;write commands to lcd
    CLR RS
    CLR RW
    SETB E
    CLR E
    ACALL DELAY
    RET

DATA_WRITE:MOV P2,A				;write data to lcd
    SETB RS
    CLR RW
    SETB E
    CLR E
    ACALL DELAY
    RET

DELAY: 				;10ms delay for properly writing to lcd
MOV TMOD,#01H	;T0 in M1(16 bit timer)
MOV TH0,#0DCH
MOV TL0,#00H
MOV TCON,#10H	;T0 run
WAIT: JNB TF0,WAIT
CLR TR0
CLR TF0
RET

;LCD functions END

    
DELAY3sec:MOV R3,#46D				;3s delay to keep for displaying stuff for long
MOV TMOD,#01H
BACK:  MOV TH0,#00000000B   
       MOV TL0,#00000000B   
       SETB TR0             
HERE1: JNB TF0,HERE1         
       CLR TR0             
       CLR TF0             
       DJNZ R3,BACK
       RET
       
DEBOUNCE: MOV R3,#250D			;250ms debouncing delay
MOV TMOD,#01H
BACK2:   MOV TH0,#0FCH 			;64536 so count = 1000us=1ms
        MOV TL0,#018H 
        SETB TR0 
HERE2:  JNB TF0,HERE2 
        CLR TR0 
        CLR TF0 
        DJNZ R3,BACK2			;repeat 1ms delay 250 times. 1msx250 = 250ms
        RET       

DELAY500us:
MOV TMOD,#01H
MOV TH0,#0FEH
MOV TL0,#34H
SETB TR0
BACK4: JNB TF0,BACK4
CLR TR0
CLR TF0
RET

DELAY20ms:
MOV R6,#40D
START:
ACALL DELAY500us
DJNZ R6,START
RET


DELAY1_5ms:
MOV R6,#03H
BACK3:ACALL DELAY500us
DJNZ R6,BACK3
RET

;Delays -END

;UnLocker -START
UNLOCK:
MOV R5,#90D
X1:
CLR CONT
ACALL DELAY20ms
SETB CONT
ACALL DELAY500us
DJNZ R5,X1
SETB P3.2
CLR CONT
RET

;UnLocker -END

;Locker start
LOCK:
MOV R5,#90D
X2:
CLR CONT
ACALL DELAY20ms
SETB CONT
ACALL DELAY1_5ms
DJNZ R5,X2
SETB P3.1
CLR CONT
RET
;Locker End


;Keyscanning - START
READ_KEYPRESS: ACALL CLRSCR
ACALL LINE1
MOV DPTR,#IPMSG
ACALL LCD_OUT
ACALL LINE2
MOV R0,#4D				;take 4 digits as input
MOV R1,#160D			;input password is stored in 160,161,162,163,164
ROTATE:ACALL KEY_SCAN
MOV @R1,A					;store value of scanned key
ACALL DATA_WRITE			;write value scanned key
ACALL DEBOUNCE				;250ms debounce
INC R1						;get ready to store to next location
DJNZ R0,ROTATE
RET


KEY_SCAN:MOV P1,#0FFH 			;initialize P3 with 1s
CLR P1.0 				;row 1
JB P1.4, NEXT1 				;column 1
MOV A,#49D					;1
RET

NEXT1:JB P1.5,NEXT2
MOV A,#50D		;2

RET
NEXT2: JB P1.6,NEXT3
MOV A,#51D		;3

RET

NEXT3:SETB P1.0				;if R1 buttons not pressed, set r1
CLR P1.1 					;R2 activate
JB P1.4,NEXT4 
MOV A,#52D			;4

RET
NEXT4:JB P1.5,NEXT5
MOV A,#53D			;5

RET
NEXT5: JB P1.6,NEXT6
MOV A,#54D			;6
RET

NEXT6:SETB P1.1
CLR P1.2			;R3 activate
JB P1.4, NEXT7
MOV A,#55D			;7

RET
NEXT7:JB P1.5,NEXT8
MOV A,#56D			;8

RET
NEXT8: JB P1.6,NEXT9
MOV A,#57D			;9

RET

NEXT9:SETB P1.2
CLR P1.3			;R4 activate
JB P1.4, NEXT10
MOV A,#48D

RET
NEXT10:JB P1.5,NEXT11
MOV A,#48D			;0

RET
NEXT11: JB P1.6,NEXT12
MOV A,#48D

RET

NEXT12:LJMP KEY_SCAN			;check for keypress again

;Keyscanning -END


;Pass check -START
CHECK_PASSWORD:		;check password
MOV R0,#4D			;check 4 digits
MOV R1,#160D		;start checking from location 160
MOV DPTR,#PASSW 	;move into DPTR first digit of pass
RPT:CLR A
MOVC A,@A+DPTR		;load nth digit of password
XRL A,@R1			;if the stored and entered password is same, A XOR R1 = 0
JNZ FAIL			;if A is not 0, pass wrong
INC R1				;next location of password digit
INC DPTR
DJNZ R0,RPT

ACALL CLRSCR		;if password was correct, this line will be executed
ACALL LINE1
MOV DPTR,#TEXT_S1
ACALL LCD_OUT
ACALL LINE2
ACALL DELAY3sec
ACALL UNLOCK				;drive servo to 0 degree
MOV DPTR,#TEXT_S2
ACALL LCD_OUT
ACALL DELAY3sec
SJMP GOBACK

FAIL:
ACALL CLRSCR 
ACALL LINE1
MOV DPTR,#TEXT_F1
ACALL LCD_OUT
ACALL DELAY3sec
ACALL LINE2
MOV DPTR,#TEXT_F2
ACALL LCD_OUT
ACALL DELAY3sec
GOBACK:RET

;Pass check - END

INIT_COMMANDS:  DB 0CH,01H,06H,80H,3CH,0    
INIT2: DB 02H,01H,06H,80H,3CH,0 

TEXT1: DB "WELCOME",0 
TEXT2: DB "U = UNLOCK",0
TEXT3: DB "L = LOCK",0
TEXT4: DB "DOOR LOCKED",0
IPMSG: DB "ENTER PASSWORD",0
CHKMSG: DB "CHECKING PASS",0
TEXT_S1: DB "ACCESS - GRANTED",0
TEXT_S2: DB "DOOR OPENED",0
TEXT_F1: DB "WRONG PASSWORD",0
TEXT_F2: DB "ACCESS DENIED",0
PASSW: DB 56D,48D,53D,49D,0			;ascii codes of 8,0,5,1
END