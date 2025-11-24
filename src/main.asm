INCLUDE Irvine32.inc
INCLUDE Macros.inc 
INCLUDE GraphWin.inc 
INCLUDE DataFormat.inc 

main EQU start@0 

GetStdHandle PROTO :DWORD 
WriteConsoleW PROTO :DWORD, :PTR WORD, :DWORD, :PTR DWORD, :DWORD 
ExitProcess PROTO :DWORD 

.DATA 
consoleHandle DWORD ? 
fullBlock WORD 2 dup(2588h), 0 ; '█' (full block), null-terminated
colors BYTE 12,10,9,14 ;light red, light green, light blue, yellow 
colorMask DWORD 3 
rows BYTE 10 
cols BYTE 10 
cnt DWORD ? 
snake BLOCK <<8, 1>,0>, <<6,1>,0>, <<4,1>,0>, <<2,1>,0>, 16 dup(<>)
snakeLen BYTE 4
lastPos BLOCK <>
apples APPLE <<20, 20>,0>

.CODE 
main PROC 
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE 
	mov consoleHandle, eax 

MAIN_LOOP: 
	call ClrScr 

; plot snake
	movzx ecx, snakeLen 
	mov esi, 0 
PLOT_SNAKE: 
	pushad
	INVOKE SetConsoleCursorPosition, consoleHandle, snake[esi].pos 
	INVOKE WriteConsoleW, 
		consoleHandle, 
		ADDR fullBlock, 
		2, 
		ADDR cnt, 
		0 
	popad
	add esi, TYPE snake 
	loop PLOT_SNAKE

; plot apple
    .IF apples.eaten == 0 
        pushad
        INVOKE SetConsoleCursorPosition, consoleHandle, apples.pos 
        INVOKE SetConsoleTextAttribute, consoleHandle, 0ch
        INVOKE WriteConsoleW, 
            consoleHandle, 
            ADDR fullBlock, 
            2, 
            ADDR cnt, 
            0 
        INVOKE SetConsoleTextAttribute, consoleHandle, 07h
        popad
    .ENDIF

    ; Detect input char
	call ReadChar ; ReadKey to continue without waiting user input 

    ; store new direction in bl

	; UP ARROW, or W 
	.IF ax == 1177h
	    mov bl, 1	
	.ENDIF 
	; DOWN ARROW, or S 
	.IF ax == 1F73h
	    mov bl, 3	
	.ENDIF 
	; LEFT ARROW, or A 
	.IF ax == 1E61h 
	    mov bl, 2	
	.ENDIF 
    ; RIGHT ARROW, or D 
	.IF ax == 2064h 
	    mov bl, 0	
	.ENDIF 
	; ESC 
	.IF ax == 011Bh 
		jmp END_FUNC 
	.ENDIF 

    movzx ecx, snakeLen 
    mov esi, 0
UPDATE_POS:
    mov ax, WORD PTR snake[esi].pos.X
    mov WORD PTR lastPos.pos.X, ax 
    mov ax, WORD PTR snake[esi].pos.Y
    mov WORD PTR lastPos.pos.Y, ax
    mov al, BYTE PTR snake[esi].dir
    mov BYTE PTR lastPos.dir, al

    ; right
    .IF bl == 0
        add snake[esi].pos.X, 2 
    .ENDIF
    ; top
    .IF bl == 1
        add snake[esi].pos.Y, -1
    .ENDIF
    ; left
    .IF bl == 2
        add snake[esi].pos.X, -2
    .ENDIF
    ; down
    .IF bl == 3
        add snake[esi].pos.Y, 1 
    .ENDIF
    
    mov bh, snake[esi].dir
    mov snake[esi].dir, bl
    mov bl, bh
    add esi, TYPE snake 

    loop UPDATE_POS

    ; check apple
    .IF apples.eaten == 0
        mov ax, snake[0].pos.X
        cmp ax, apples.pos.X
        jne DETECT_BORDER
        mov ax, snake[0].pos.Y
        cmp ax, apples.pos.Y
        jne DETECT_BORDER 

        movzx eax, snakeLen
        imul eax, TYPE snake
        mov bx, lastPos.pos.X
        mov snake[eax].pos.X, bx
        mov bx, lastPos.pos.Y
        mov snake[eax].pos.Y, bx
        mov bl, lastPos.dir
        mov snake[eax].dir, bl    
        inc snakeLen
        mov apples.eaten, 1
    .ENDIF

DETECT_BORDER:    
	; Detect border
	; If over the border then stay at the original position
	; x lowerbound
	.IF snake[0].pos.X <= 0h
		add snake[0].pos.X, 2
	.ENDIF
	; x upperbound
	; mov ax,xyBound.x
	.IF snake[0].pos.X >= 60h
		sub snake[0].pos.X, 2
	.ENDIF
	; y lowerbound
	.IF snake[0].pos.Y == 0h
		add snake[0].pos.Y, 1
	.ENDIF
	; y upperbound
	.IF snake[0].pos.Y == 1Ah
		sub snake[0].pos.Y, 1
	.ENDIF
	
	jmp MAIN_LOOP 
	 
 END_FUNC: 
	call WaitMsg 
	exit
main ENDP 
END main
