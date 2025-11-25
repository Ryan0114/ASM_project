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
snake BLOCK <<10, 1>,0>, <<8, 1>,0>, <<6,1>,0>, <<4,1>,0>, <<2,1>,0>, 16 dup(<>)
snakeLen BYTE 5
lastPos BLOCK <>
apples APPLE <<20, 20>,0>, <<26, 20>,0>, <<32, 20>, 0>
appleLen BYTE LENGTHOF apples 
obstacles OBSTACLE <<30, 10>>, <<40, 10>>
obstacleLen BYTE LENGTHOF obstacles

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
    movzx ecx, appleLen 
    mov esi, 0
PLOT_APPLE:
    .IF apples[esi].eaten == 0 
        pushad
        INVOKE SetConsoleCursorPosition, consoleHandle, apples[esi].pos 
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
    add esi, TYPE apples
    loop PLOT_APPLE

; plot obstacle    
    movzx ecx, obstacleLen
    mov esi, 0
PLOT_OBSTACLE:
    pushad
    INVOKE SetConsoleCursorPosition, consoleHandle, obstacles[esi].pos
    INVOKE SetConsoleTextAttribute, consoleHandle, 08h
    INVOKE WriteConsoleW,
        consoleHandle,
        ADDR fullBlock,
        2,
        ADDR cnt,
        0
    INVOKE SetConsoleTextAttribute, consoleHandle, 07h
    popad
    add esi, TYPE obstacles
    loop PLOT_OBSTACLE

INPUT:
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

; check if the direction is valid
    mov al, snake[0].dir
    cmp al, bl
    je SELF_INTERSECTING 

    mov bh, bl
    and al, 1
    and bh, 1
    cmp al, bh
    je NO_UPDATE

; check if the destination is empty
SELF_INTERSECTING:
    movzx ecx, snakeLen
    add ecx, -2
    mov esi, TYPE snake 

    mov ax, snake[0].pos.X
    .IF bl == 0
        add ax, 2
    .ENDIF
    .IF bl == 2
        add ax, -2
    .ENDIF

    mov dx, snake[0].pos.Y
    .IF bl == 1
        add dx, -1
    .ENDIF
    .IF bl == 3
        add dx, 1
    .ENDIF


SELF_INTERSECTING_LOOP:
    cmp ax, snake[esi].pos.X
    jne CONTINUE_SELF 

    cmp dx, snake[esi].pos.Y
    jne CONTINUE_SELF 

    jmp NO_UPDATE

CONTINUE_SELF:
    add esi, TYPE snake
    loop SELF_INTERSECTING_LOOP

OBSTACLE_COLLISION:
    movzx ecx, obstacleLen
    mov esi, 0 
OBSTACLE_LOOP:
    cmp ax, obstacles[esi].pos.X
    jne CONTINUE_OBS

    cmp dx, obstacles[esi].pos.Y
    jne CONTINUE_OBS

    jmp NO_UPDATE

CONTINUE_OBS:
    add esi, TYPE obstacles
    loop OBSTACLE_LOOP

CHECK_BORDER:
    .IF ax <= 0h
	    jmp NO_UPDATE	
	.ENDIF
	.IF ax >= 78h
	    jmp NO_UPDATE	
	.ENDIF
	.IF dx == 0h
	    jmp NO_UPDATE	
	.ENDIF
	.IF dx == 1Dh
	    jmp NO_UPDATE	
	.ENDIF

UPDATE_POS:
    movzx ecx, snakeLen 
    mov esi, 0
UPDATE_LOOP:
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

    loop UPDATE_LOOP

NO_UPDATE:   
    ; check apple
    movzx ecx, appleLen
    mov esi, 0
APPLE_EATEN:
    mov al, apples[esi].eaten
    .IF al == 0
        mov ax, snake[0].pos.X
        cmp ax, apples[esi].pos.X
        jne CONTINUE_APPLE
        mov ax, snake[0].pos.Y
        cmp ax, apples[esi].pos.Y
        jne CONTINUE_APPLE

        movzx eax, snakeLen
        imul eax, TYPE snake
        mov bx, lastPos.pos.X
        mov snake[eax].pos.X, bx
        mov bx, lastPos.pos.Y
        mov snake[eax].pos.Y, bx
        mov bl, lastPos.dir
        mov snake[eax].dir, bl    
        inc snakeLen
        mov apples[esi].eaten, 1
    .ENDIF
CONTINUE_APPLE:
    add esi, TYPE apples 
    loop APPLE_EATEN

	jmp MAIN_LOOP 
	 
 END_FUNC: 
	call WaitMsg 
	exit
main ENDP 
END main
