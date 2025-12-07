INCLUDE Irvine32.inc
INCLUDE GraphWin.inc
INCLUDE Plotting.inc
INCLUDE DataFormat.inc

.DATA

fullBlock  WORD 2 dup(2588h), 0
written    DWORD ?

.CODE

PlotSnake PROC consoleHandle:DWORD, snakePtr:PTR BLOCK, sLen:DWORD, pWritten:PTR DWORD
    mov esi, snakePtr 
    mov ecx, sLen

LOOP_SNAKE:
    pushad
    INVOKE SetConsoleCursorPosition, consoleHandle, (BLOCK PTR [esi]).pos
    INVOKE WriteConsoleW, consoleHandle, ADDR fullBlock, 2, pWritten, 0
    popad

    add esi, SIZEOF BLOCK 
    loop LOOP_SNAKE 
    ret
PlotSnake ENDP


PlotApples PROC consoleHandle:DWORD, applePtr:PTR APPLE, aLen:DWORD, pWritten:PTR DWORD
    .IF aLen == 0
        ret
    .ENDIF 
    mov esi, applePtr
    mov ecx, aLen

LOOP_APPLE:
    mov al, (APPLE ptr [esi]).eaten
    .IF al == 0
        pushad
        INVOKE SetConsoleCursorPosition, consoleHandle, (APPLE ptr [esi]).pos
        INVOKE SetConsoleTextAttribute, consoleHandle, 0Ch
        INVOKE WriteConsoleW, consoleHandle, ADDR fullBlock, 2, pWritten, 0
        INVOKE SetConsoleTextAttribute, consoleHandle, 07h
        popad
    .ENDIF

    add esi, TYPE APPLE
    loop LOOP_APPLE 
    ret
PlotApples ENDP


PlotObst PROC consoleHandle:DWORD, obstPtr:PTR OBSTACLE, oLen:DWORD, pWritten:PTR DWORD
    mov esi, obstPtr
    mov ecx, oLen

LOOP_OBST:
    pushad
    INVOKE SetConsoleCursorPosition, consoleHandle, (OBSTACLE ptr [esi]).pos
    mov al, (OBSTACLE ptr [esi]).harmful
    .IF al == 0
        INVOKE SetConsoleTextAttribute, consoleHandle, 08h
    .ELSE
        INVOKE SetConsoleTextAttribute, consoleHandle, 0Dh
    .ENDIF
    INVOKE WriteConsoleW, consoleHandle, ADDR fullBlock, 2, pWritten, 0
    INVOKE SetConsoleTextAttribute, consoleHandle, 07h
    popad

    add esi, TYPE OBSTACLE
    loop LOOP_OBST 
    ret
PlotObst ENDP

PlotBox PROC consoleHandle:DWORD, boxPtr:PTR COORD, bLen:DWORD, pWritten:PTR DWORD
    .IF bLen == 0
        ret
    .ENDIF
    mov esi, boxPtr 
    mov ecx, bLen

LOOP_BOX:
    pushad
	mov ax, (COORD ptr [esi]).X
	mov bx, (COORD ptr [esi]).Y
	
	.IF bx >= 1Ah
	    jmp NEXT
	.ENDIF
    INVOKE SetConsoleTextAttribute, consoleHandle, 06h
    INVOKE SetConsoleCursorPosition, consoleHandle, (COORD ptr [esi]) 
    INVOKE WriteConsoleW, consoleHandle, ADDR fullBlock, 2, ADDR written, 0
    INVOKE SetConsoleTextAttribute, consoleHandle, 0Fh
	
NEXT:
    popad
    add esi, SIZEOF COORD
    loop LOOP_BOX
    ret
PlotBox ENDP

END

