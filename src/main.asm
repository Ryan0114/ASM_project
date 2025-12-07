INCLUDE Irvine32.inc
INCLUDE Macros.inc 
INCLUDE GraphWin.inc 
INCLUDE DataFormat.inc 
INCLUDE Plotting.inc
INCLUDE GameMechanism.inc

main EQU start@0 

GetStdHandle PROTO :DWORD 
WriteConsoleW PROTO :DWORD, :PTR WORD, :DWORD, :PTR DWORD, :DWORD 
ExitProcess PROTO :DWORD 
BufferSize = 5000

Select_Load_Stage PROTO

.DATA 
buffer byte BufferSize dup(?)
fileInput byte 100 dup(?)
filename byte "../src/stages/s", 2 dup(?), ".txt", 0
fileHandle handle ?

consoleHandle DWORD ? 
fullBlock WORD 2 dup(2588h), 0
scr_height BYTE 28
scr_width BYTE 58 
written DWORD ? 

snake BLOCK 15 dup(<>)
snakeLen DWORD ?
apples APPLE 15  dup(<>)
appleLen DWORD ?
obstacles OBSTACLE 60 dup(<>)
obstacleLen DWORD ?
boxes COORD 15 dup(<>)
boxLen DWORD ?
goal COORD <>
lastPos BLOCK <>

update_box DWORD ?
update BYTE ?

stageText byte 2 dup(?),0
xyUI COORD <?,?>

; TODO
; 2. box 

.CODE 
main PROC 
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE 
	mov consoleHandle, eax 

; title screen
TITLE_SCREEN:
    call ClrScr
	
    INVOKE SetConsoleTextAttribute, consoleHandle, 0Ah
	mov xyUI.X, 10
	mov xyUI.Y, 7
	INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
	mWrite <"  ____              _          ____                _         ____                      ">
	mov xyUI.X, 10
	mov xyUI.Y, 8
	INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
	mWrite <" / ___| _ __   __ _| | _____  |  _ \ _   _ _______| | ___   / ___| __ _ _ __ ___   ___ ">
	mov xyUI.X, 10
	mov xyUI.Y, 9
	INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
	mWrite <" \___ \| '_ \ / _` | |/ / _ \ | |_) | | | |_  /_  / |/ _ \ | |  _ / _` | '_ ` _ \ / _ \">
	mov xyUI.X, 10
	mov xyUI.Y, 10
	INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
	mWrite <"  ___) | | | | (_| |   <  __/ |  __/| |_| |/ / / /| |  __/ | |_| | (_| | | | | | |  __/">
	mov xyUI.X, 10
	mov xyUI.Y, 11
	INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
	mWrite <" |____/|_| |_|\__,_|_|\_\___| |_|    \__,_/___/___|_|\___|  \____|\__,_|_| |_| |_|\___|">
	mov xyUI.X, 10
	mov xyUI.Y, 12
	INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
    INVOKE SetConsoleTextAttribute, consoleHandle, 0Fh
    call WaitMsg

SELECT_STAGE:
; stage selection and load stage
    call ClrScr
    call Select_Load_Stage 
    call WaitMsg

MAIN_LOOP: 
	call ClrScr 

; plot snake
    INVOKE PlotSnake, consoleHandle, ADDR snake, snakeLen, ADDR written

; plot apple
    INVOKE PlotApples, consoleHandle, ADDR apples, appleLen, ADDR written

; plot obstacle    
    INVOKE PlotObst, consoleHandle, ADDR obstacles, obstacleLen, ADDR written

; plot box
    INVOKE PlotBox, consoleHandle, ADDR boxes, boxLen, ADDR written

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

    mov ebx, 4 ; clear direction 

    ; store new direction in bl

	.IF ax == 1177h ; W
	    mov bl, 1	
	.ELSEIF ax == 1F73h ; S 
	    mov bl, 3	
	.ELSEIF ax == 1E61h ; A
	    mov bl, 2	
	.ELSEIF ax == 2064h ; D 
	    mov bl, 0	
    .ELSEIF ax == 1071h ; Q 
        jmp SELECT_STAGE 
    .ELSEIF ax == 1372h ; R
        jmp TITLE_SCREEN
	.ELSEIF ax == 011Bh ; ESC 
		jmp END_FUNC 
	.ELSE 
		jmp NEXT_LOOP
	.ENDIF

; check if the direction is valid
    mov al, snake[0].dir
    cmp al, bl
    je CHECK_INTERSECTING

    mov bh, bl
    and al, 1
    and bh, 1
    cmp al, bh
    je NO_UPDATE

CHECK_INTERSECTING:
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

; invoke check intersecting
    INVOKE CheckIntersection, ax, dx, ADDR snake, snakeLen, ADDR obstacles, obstacleLen
    .IF bh == 1 
        jmp GAMEOVER 
    .ELSEIF bh == 2
        jmp NO_UPDATE
    .ENDIF

; check collision with boxes
	.IF boxLen == 0
		jmp CHECK_BORDER
	.ENDIF
    mov ecx, boxLen
    mov esi, 0
BOX_COLLISION_CHECK:
    cmp ax, boxes[esi].X
    jne CONT_BOX_COLLISION
    cmp dx, boxes[esi].Y
    jne CONT_BOX_COLLISION
    push esi

; check box destination empty
    .IF bl == 0
        add ax, 2
    .ENDIF
    .IF bl == 2
        add ax, -2
    .ENDIF

    .IF bl == 1
        add dx, -1
    .ENDIF
    .IF bl == 3
        add dx, 1
    .ENDIF
    
    ; snake and obstacle 
    INVOKE CheckIntersection, ax, dx, ADDR snake, snakeLen, ADDR obstacles, obstacleLen
    .IF bh == 1 
        jmp NO_UPDATE 
    .ENDIF
    .IF bh == 2
        jmp NO_UPDATE
    .ENDIF

    ; box
    push ecx
    push esi
    mov ecx, boxLen
    mov esi, 0
BB_COLL:
    cmp ax, boxes[esi].X
    jne CONT_BB_COLL
    cmp dx, boxes[esi].Y
    jne CONT_BB_COLL

    jmp NO_UPDATE
CONT_BB_COLL:
    add esi, SIZEOF COORD
    loop BB_COLL

    ; apple
    mov ecx, appleLen
    mov esi, 0
BA_COLL:
    mov bh, apples[esi].eaten
    .IF bh == 0
        cmp ax, apples[esi].pos.X
        jne CONT_BA_COLL
        cmp dx, apples[esi].pos.Y
        jne CONT_BA_COLL

        jmp NO_UPDATE
    .ENDIF
CONT_BA_COLL:
    add esi, SIZEOF APPLE 
    loop BA_COLL

    pop esi
    pop ecx
    ; goal
    cmp ax, goal.X
    jne ORI_VAL
    cmp dx, goal.Y
    jne ORI_VAL

    jmp NO_UPDATE

ORI_VAL:
    .IF bl == 0
        add ax, -2
    .ENDIF
    .IF bl == 2
        add ax, 2
    .ENDIF

    .IF bl == 1
        add dx, 1
    .ENDIF
    .IF bl == 3
        add dx, -1
    .ENDIF
 
; move box
    pop esi
    .IF bl == 0
        add boxes[esi].X, 2
    .ELSEIF bl == 1
        add boxes[esi].Y, -1
    .ELSEIF bl == 2
        add boxes[esi].X, -2
    .ELSEIF bl == 3
        jmp NO_UPDATE
    .ENDIF
	mov update_box, esi
	mov update, 1
    jmp CHECK_BORDER
CONT_BOX_COLLISION:
    add esi, TYPE boxes
    dec ecx
    jnz near ptr BOX_COLLISION_CHECK 

    jmp CHECK_BORDER
	
; --- (old)

; ------- Check border --------
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
	
; -- (new)
	.IF update ==1
		mov update, 0
CHECK_BOX_SUPP:
		push eax
		push edx
WN_SUPP:
		mov esi, update_box
		mov ax, boxes[esi].X 
		mov dx, boxes[esi].Y
		inc dx
		INVOKE CheckIntersection, ax, dx, ADDR snake, snakeLen, ADDR obstacles, obstacleLen
		.IF bh == 1 
			jmp MOVE_ON 
		.ENDIF
		.IF bh == 2
			jmp MOVE_ON
		.ENDIF
; check box supported by apple
		mov ecx, appleLen
		mov esi, 0
BA_SUPP:
		mov bh, apples[esi].eaten
		.IF bh == 0
			cmp ax, apples[esi].pos.X
			jne CONT_BA_SUPP
			cmp dx, apples[esi].pos.Y
			jne CONT_BA_SUPP
			
			jmp MOVE_ON
		.ENDIF
CONT_BA_SUPP:
		add esi, SIZEOF APPLE
		loop BA_SUPP
		
APPLE_GRAVITY:
		mov esi, update_box
		add boxes[esi].Y, 1
		.IF dx >= 1Ch
			jmp MOVE_ON
		.ENDIF
		jmp WN_SUPP
	
MOVE_ON:
		pop edx
		pop eax
	.ENDIF
; --

; check tail-supported box
	.IF boxLen == 0
		jmp NO_UPDATE
	.ENDIF
	mov ecx, boxLen
	mov esi, 0
	mov ax, lastPos.pos.X
	mov dx, lastPos.pos.Y
	dec dx
T_SUPP:
	cmp ax, boxes[esi].X 
	jne CONT_T_SUPP
	cmp dx, boxes[esi].Y
	jne CONT_T_SUPP
	
	mov update_box, esi
	jmp CHECK_BOX_SUPP_T
CONT_T_SUPP:
	add esi, SIZEOF COORD
	loop T_SUPP

; ---------------
CHECK_BOX_SUPP_T:
	push eax
	push edx
WN_SUPP_T:
	mov esi, update_box
	mov ax, boxes[esi].X 
	mov dx, boxes[esi].Y
	inc dx
	INVOKE CheckIntersection, ax, dx, ADDR snake, snakeLen, ADDR obstacles, obstacleLen
	.IF bh == 1 
		jmp MOVE_ON_T
	.ENDIF
	.IF bh == 2
		jmp MOVE_ON_T
	.ENDIF
; check box supported by apple
	mov ecx, appleLen
	mov esi, 0
BA_SUPP_T:
	mov bh, apples[esi].eaten
	.IF bh == 0
		cmp ax, apples[esi].pos.X
		jne CONT_BA_SUPP_T
		cmp dx, apples[esi].pos.Y
		jne CONT_BA_SUPP_T
		
		jmp MOVE_ON_T
	.ENDIF
CONT_BA_SUPP_T:
	add esi, SIZEOF APPLE
	loop BA_SUPP_T
	
APPLE_GRAVITY_T:
	mov esi, update_box
	add boxes[esi].Y, 1
	.IF dx >= 1Ch
		jmp MOVE_ON_T
	.ENDIF
	jmp WN_SUPP_T

MOVE_ON_T:
	pop edx
	pop eax
;----------------------

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
    xor dx, dx ; store whether snake is supported only by harmful obstacle 
CHECK_SUPP:
    call ClrScr 

; plot snake
    INVOKE PlotSnake, consoleHandle, ADDR snake, snakeLen, ADDR written

; plot apple
    INVOKE PlotApples, consoleHandle, ADDR apples, appleLen, ADDR written

; plot obstacle    
    INVOKE PlotObst, consoleHandle, ADDR obstacles, obstacleLen, ADDR written

; plot box
    INVOKE PlotBox, consoleHandle, ADDR boxes, boxLen, ADDR written    

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

    mov dl, obstacles[esi].harmful
    .IF dl == 0
        jmp SUPPORTED
    .ELSE
        mov dh, 1
    .ENDIF


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

; ---------- check box support ------------
	.IF boxLen == 0
		jmp SUPP_GOAL
	.ENDIF
    mov ecx, boxLen
    mov esi, 0
SUPP_BOX:
    cmp ax, boxes[esi].X
    jne CONT_BOX_SUPP
    cmp bx, boxes[esi].Y
    jne CONT_BOX_SUPP

    jmp SUPPORTED

CONT_BOX_SUPP:
    add esi, TYPE boxes
    loop SUPP_BOX

; ---------- check goal support ----------; 374
SUPP_GOAL:
    cmp ax, goal.X
    jne CONT_SUPP
    cmp bx, goal.Y
    jne CONT_SUPP

    jmp SUPPORTED

 
CONT_SUPP:
    pop esi
    pop ecx
    add esi, TYPE snake
    dec ecx
    jnz near PTR LOOP_SUPP

    .IF dh == 1
        jmp GAMEOVER
    .ENDIF
   
; if not supported, then apply gravity tell supported or full into the void (Y > threshold)
GRAVITY:
    mov ecx, snakeLen
    mov esi, 0 
LOOP_GRAVITY:
    inc snake[esi].pos.Y    
    .IF snake[esi].pos.Y >= 1Ch
        jmp GAMEOVER 
    .ENDIF

    add esi, TYPE snake
    loop LOOP_GRAVITY

    push 100
    call Sleep

    jmp CHECK_SUPP

SUPPORTED:
NEXT_LOOP:
	jmp MAIN_LOOP 
	 
FINISH:
    call ClrScr
	
	mov xyUI.X, 10
    mov xyUI.Y, 7
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"   ____                            _         _       _   _                 ">
    mov xyUI.X, 10
    mov xyUI.Y, 8
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"  / ___|___  _ __   __ _ _ __ __ _| |_ _   _| | __ _| |_(_) ___  _ __  ___ ">
    mov xyUI.X, 10
    mov xyUI.Y, 9
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <" | |   / _ \| '_ \ / _` | '__/ _` | __| | | | |/ _` | __| |/ _ \| '_ \/ __|">
    mov xyUI.X, 10
    mov xyUI.Y, 10
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <" | |__| (_) | | | | (_| | | | (_| | |_| |_| | | (_| | |_| | (_) | | | \__ \">
    mov xyUI.X, 10
    mov xyUI.Y, 11
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"  \____\___/|_| |_|\__, |_|  \__,_|\__|\__,_|_|\__,_|\__|_|\___/|_| |_|___/">
    mov xyUI.X, 10
    mov xyUI.Y, 12
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"                   |___/                                                   ">
    mov xyUI.X, 10
    mov xyUI.Y, 13
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    call WaitMsg

; jump to stage selection page
    jmp SELECT_STAGE

GAMEOVER:
    call ClrScr
	
    mov xyUI.X, 10
    mov xyUI.Y, 7
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"   ____    _    __  __ _____    _____     _______ ____  ">
    mov xyUI.X, 10
    mov xyUI.Y, 8
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"  / ___|  / \  |  \/  | ____|  / _ \ \   / / ____|  _ \ ">
    mov xyUI.X, 10
    mov xyUI.Y, 9
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <" | |  _  / _ \ | |\/| |  _|   | | | \ \ / /|  _| | |_) |">
    mov xyUI.X, 10
    mov xyUI.Y, 10
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <" | |_| |/ ___ \| |  | | |___  | |_| |\ V / | |___|  _ < ">
    mov xyUI.X, 10
    mov xyUI.Y, 11
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"  \____/_/   \_\_|  |_|_____|  \___/  \_/  |_____|_| \_\">
    mov xyUI.X, 10
    mov xyUI.Y, 12
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"text">
	call WaitMsg
    jmp SELECT_STAGE

END_FUNC: 
    call ClrScr
	
    mov xyUI.X, 20
    mov xyUI.Y, 7
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"  _____ _               _____           _ "> 
    mov xyUI.X, 20
    mov xyUI.Y, 8
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <" |_   _| |__   ___     | ____|_ __   __| |"> 
    mov xyUI.X, 20
    mov xyUI.Y, 9
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"   | | | '_ \ / _ \    |  _| | '_ \ / _` |"> 
    mov xyUI.X, 20
    mov xyUI.Y, 10
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"   | | | | | |  __/    | |___| | | | (_| |"> 
    mov xyUI.X, 20
    mov xyUI.Y, 11
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"   |_| |_| |_|\___|    |_____|_| |_|\__,_|">
    mov xyUI.X, 20
    mov xyUI.Y, 12
    invoke SetConsoleCursorPosition, consoleHandle, xyUI
	call WaitMsg 
	exit
main ENDP 

Select_Load_Stage PROC
chooseStage:
    mov xyUI.X, 10
	mov xyUI.Y, 7
	INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"   ____ _                           __   __                 ____  _                    ">
    mov xyUI.X, 10
    mov xyUI.Y, 8
    INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"  / ___| |__   ___   ___  ___  ___  \ \ / /__  _   _ _ __  / ___|| |_ __ _  __ _  ___  ">
    mov xyUI.X, 10
    mov xyUI.Y, 9
    INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <" | |   | '_ \ / _ \ / _ \/ __|/ _ \  \ V / _ \| | | | '__| \___ \| __/ _` |/ _` |/ _ \ ">
    mov xyUI.X, 10
    mov xyUI.Y, 10
    INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <" | |___| | | | (_) | (_) \__ \  __/   | | (_) | |_| | |     ___) | || (_| | (_| |  __/ ">
    mov xyUI.X, 10
    mov xyUI.Y, 11
    INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"  \____|_| |_|\___/ \___/|___/\___|   |_|\___/ \__,_|_|    |____/ \__\__,_|\__, |\___| ">
    mov xyUI.X, 10
    mov xyUI.Y, 12
    INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"                                                                           |___/       ">
    mov xyUI.X, 10
    mov xyUI.Y, 14
    INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
    mWrite <"(eg 01, 02, ..., 99) : ">
	mov edx, offset fileInput
	mov ecx, sizeof fileInput
	call ReadString

	mov ecx, sizeof fileInput 
	mov edi, offset fileInput
	mov al, 0
	repne scasb
	mov ebx, sizeof fileInput
    sub ebx, ecx
    dec ebx ; get lenghof fileInput
	cmp ebx, 2
	jne file_not_ok
	
    mov xyUI.X, 10
    mov xyUI.Y, 15
    INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
	; handle full filename
	mov al, fileInput[0]
	mov filename[15], al
	mov stageText[0], al
	mov al, fileInput[1]
	mov filename[16], al
	mov stageText[1], al
	
	mWrite <"Loading Stage : ">
	mov edx, offset stageText
	call WriteString
	mWrite <", ">
	mov edx, offset filename
	call OpenInputFile
	mov fileHandle, eax
	cmp eax,INVALID_HANDLE_VALUE
	jne file_ok
file_not_ok:
	call ClrScr
	mov xyUI.X, 10
    mov xyUI.Y, 13
    INVOKE SetConsoleCursorPosition, consoleHandle, xyUI
	mWrite <"Stage not found.",0dh,0ah>
	jmp chooseStage
file_ok:
	mov edx, offset buffer
	mov ecx, BufferSize
	call ReadFromFile
	jnc check_Buffer_Size
	mWrite "Error reading file. "
	call WriteWindowsMsg
	jmp close_File
check_Buffer_Size:
	cmp eax, BufferSize
	jb buf_size_ok
	mWrite <"Error: Buffer too small for the file",0dh,0ah>
	jmp quit
buf_size_ok:
	mov buffer[eax],0
	mov ecx, eax
	mov ebx, 0
	xor edx,edx
	xor esi,esi

; initialize
    mov snakeLen, 0 
    mov obstacleLen, 0 
    mov appleLen, 0 
    mov boxLen, 0

readEachChar:
	movzx eax, byte ptr [buffer + ebx]
	cmp eax, '0'
	jb notNUM
	cmp eax, '9'
	ja notNUM
	; isNum
	; handle First digit
	sub eax, '0'
	push edx
	push ebx
	mov ebx, 10
	mul ebx
	pop ebx
	pop edx
	; handle second digit
	inc ebx
	dec ecx
	push edx
	movzx edx, byte ptr [buffer + ebx]
	sub edx, '0'
	add eax, edx
	pop edx
	; call WriteDec ; Get integer in eax !
	
	; dx
	; 00 for snake X ; 01 for snake Y ; line 1
	; 10 for obs X ; 11 for obs Y     ; line 2
	; 20 for goal X ; 21 for goal Y   ; line 3
	; 30 for apple X ; 31 for apple Y ; line 4
	; 40 for trap X ; 41 for trap Y   ; line 5
	; 50 for box X ; 51 for box Y     ; line 6
	cmp dx, 0
	je loadSnakeX
	cmp dx, 1
	je loadSnakeY
	cmp dx, 10
	je loadObsX
	cmp dx, 11
	je loadObsY
	cmp dx, 20
	je loadGoalX
	cmp dx, 21
	je loadGoalY
	cmp dx, 30
	je loadAppleX
	cmp dx, 31
	je loadAppleY
	cmp dx, 40
	je loadTrapX
	cmp dx, 41
	je loadTrapY
	cmp dx, 50
	je loadBoxesX
	cmp dx, 51
	je loadBoxesY
;------------------------
loadSnakeX:
	mov snake[esi].pos.X, ax
	mov eax, esi
	jmp looping
loadSnakeY:
	mov snake[esi].pos.Y, ax
	mov snake[esi].dir, 0
	add esi,TYPE snake
	mov eax, snakeLen
	add eax, 1
	mov snakeLen, eax
	jmp looping
loadObsX:
	mov obstacles[esi].pos.X, ax
	jmp looping
loadObsY:
	mov obstacles[esi].pos.Y, ax
	mov obstacles[esi].harmful, 0
	add esi,TYPE obstacles
	mov eax, obstacleLen
	add eax, 1
	mov obstacleLen, eax
	jmp looping
loadGoalX:
	mov goal.X, ax
	jmp looping
loadGoalY:
	mov goal.Y, ax
	jmp looping
loadAppleX:
	mov apples[esi].pos.X, ax
	jmp looping
loadAppleY:
	mov apples[esi].pos.Y, ax
    mov apples[esi].eaten, 0
	add esi,TYPE apples
	mov eax, appleLen
	add eax, 1
	mov appleLen,eax
	jmp looping
loadBoxesX:
	mov boxes[esi].X, ax
	jmp looping
loadBoxesY:
	mov boxes[esi].Y, ax
	add esi,TYPE boxes
	mov eax, boxLen
	add eax, 1
	mov boxLen, eax
	jmp looping
loadTrapX:
	mov obstacles[esi].pos.X, ax
	jmp looping
loadTrapY:
	mov obstacles[esi].pos.Y, ax
	mov obstacles[esi].harmful, 1
	add esi,TYPE obstacles
	mov eax, obstacleLen
	add eax, 1
	mov obstacleLen, eax
	jmp looping
;------------------------
notNUM:
	cmp eax, ','
	je casePosY
	cmp eax, ';'
	je caseNextPos
; nextLine
	xor esi, esi
;	add edx, 9
	dec ecx
	inc ebx
	
; -----------------
    .IF edx <= 9
        mov edx,10
    .ELSEIF edx <= 19
        mov edx,20
    .ELSEIF edx <= 29
        mov edx,30
    .ELSEIF edx <= 39
        mov edx,40
    .ELSE
        mov edx,50
    .ENDIF
; -----------------	
	
	cmp dx, 40 ; handle trap data
	jne looping
	push edx
	mov esi, obstacleLen
	mov eax, TYPE obstacles
	mul esi
	mov esi, eax
	pop edx
	jmp looping
casePosY:
	add edx, 1
	jmp looping
caseNextPos:
	add edx, -1
	jmp looping
looping:
	inc ebx
	dec ecx
	cmp ecx,0
	je close_File 
	jmp readEachChar
	;-----------------------
close_File:
	mov eax, fileHandle
	call CloseFile
quit:
	ret
Select_Load_Stage ENDP
END main
