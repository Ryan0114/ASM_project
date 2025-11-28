INCLUDE Irvine32.inc
INCLUDE Macros.inc 
INCLUDE GraphWin.inc 
INCLUDE DataFormat.inc 
INCLUDE Plotting.inc

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
written DWORD ? 
snake BLOCK <<10, 1>,0>, <<8, 1>,0>, <<6,1>,0>, <<4,1>,0>, <<2,1>,0>, 16 dup(<>)
snakeLen DWORD 5
lastPos BLOCK <>
apples APPLE <<20, 20>,0>, <<26, 20>,0>, <<32, 20>, 0>
appleLen DWORD LENGTHOF apples 
obstacles OBSTACLE <<10, 10>>, <<20, 10>>, <<30, 10>>, <<40, 10>>
obstacleLen DWORD LENGTHOF obstacles
goal COORD <42, 9>
congrats WORD 'C', 'o', 'n', 'g', 'r', 'a', 't', 'u', 'l', 'a', 't', 'i', 'o', 'n', 's', '!', 0

.CODE 
main PROC 
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE 
	mov consoleHandle, eax 

; TODO
; stage selection

; TODO
; stage loading

MAIN_LOOP: 
	call ClrScr 

; plot snake
    INVOKE PlotSnake, consoleHandle, ADDR snake, snakeLen, ADDR written

; plot apple
    INVOKE PlotApples, consoleHandle, ADDR apples, appleLen, ADDR written

; plot obstacle    
    INVOKE PlotObst, consoleHandle, ADDR obstacles, obstacleLen, ADDR written

; plot goal
    pushad
    INVOKE SetConsoleTextAttribute, consoleHandle, 09h
    INVOKE SetConsoleCursorPosition, consoleHandle, goal 
    INVOKE WriteConsoleW, consoleHandle, ADDR fullBlock, 2, ADDR written, 0
    INVOKE SetConsoleTextAttribute, consoleHandle, 0Fh
    popad

INPUT:
    ; Detect input char
	call ReadChar 
    ; call ReadKey

    ; mov ebx, 4 ; clear direction 

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
    mov ecx, snakeLen
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
    mov ecx, obstacleLen
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
    mov ecx, snakeLen 
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
    mov ecx, appleLen
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

        mov eax, snakeLen
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

CHECK_GOAL:
    mov ax, snake[0].pos.X
    cmp ax, goal.X
    jne CHECK_SUPP
    mov ax, snake[0].pos.Y
    cmp ax, goal.Y
    jne CHECK_SUPP

    jmp FINISH
    

; check if supported by apples or obstacles 
CHECK_SUPP:
    call ClrScr 

; plot snake
    INVOKE PlotSnake, consoleHandle, ADDR snake, snakeLen, ADDR written

; plot apple
    INVOKE PlotApples, consoleHandle, ADDR apples, appleLen, ADDR written

; plot obstacle    
    INVOKE PlotObst, consoleHandle, ADDR obstacles, obstacleLen, ADDR written

; plot goal
    pushad
    INVOKE SetConsoleTextAttribute, consoleHandle, 09h
    INVOKE SetConsoleCursorPosition, consoleHandle, goal 
    INVOKE WriteConsoleW, consoleHandle, ADDR fullBlock, 2, ADDR written, 0
    INVOKE SetConsoleTextAttribute, consoleHandle, 0Fh
    popad

    mov ecx, snakeLen
    mov esi, 0
LOOP_SUPP:
    mov ax, snake[esi].pos.X
    mov bx, snake[esi].pos.Y
    inc bx
    push ecx
    push esi

    mov ecx, obstacleLen
    mov esi, 0
SUPP_OBST:
    cmp ax, obstacles[esi].pos.X
    jne CONT_OBST
    cmp bx, obstacles[esi].pos.Y
    jne CONT_OBST

    jmp SUPPORTED

CONT_OBST:
    add esi, TYPE obstacles
    loop SUPP_OBST

    mov ecx, appleLen 
    mov esi, 0
SUPP_APPLE:
    .IF apples[esi].eaten == 0
        cmp ax, apples[esi].pos.X
        jne CONT_APPLE_SUPP
        cmp bx, apples[esi].pos.Y
        jne CONT_APPLE_SUPP

        jmp SUPPORTED
    .ENDIF

CONT_APPLE_SUPP:
    add esi, TYPE apples 
    loop SUPP_APPLE

CONT_SUPP:
    pop esi
    pop ecx
    add esi, TYPE snake
    loop LOOP_SUPP
    
; if not supported, then apply gravity tell supported or full into the void (Y > threshold)
GRAVITY:
    mov ecx, snakeLen
    mov esi, 0 
LOOP_GRAVITY:
    inc snake[esi].pos.Y    
    .IF snake[esi].pos.Y >= 1Ch
        call ClrScr
        jmp END_FUNC
    .ENDIF

    add esi, TYPE snake
    loop LOOP_GRAVITY

    push 100
    call Sleep

    jmp CHECK_SUPP

SUPPORTED:
	jmp MAIN_LOOP 
	 
FINISH:
    call ClrScr
    INVOKE WriteConsoleW, consoleHandle, ADDR congrats, LENGTHOF congrats, ADDR written, 0

    call Crlf
    call WaitMsg

; TODO
; jump to stage selection page

END_FUNC: 
	call WaitMsg 
	exit
main ENDP 
END main
