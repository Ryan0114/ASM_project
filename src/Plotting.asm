INCLUDE Irvine32.inc
INCLUDE GraphWin.inc
INCLUDE Plotting.inc
INCLUDE DataFormat.inc

.DATA

fullBlock  WORD 2 dup(2588h), 0
written    DWORD ?

.CODE

PlotSnake PROC consoleHandle:DWORD, snakePtr:PTR BLOCK, snakeLen:DWORD, pWritten:PTR DWORD
    mov esi, snakePtr 
    mov ecx, snakeLen

LOOP_SNAKE:
    pushad
    INVOKE SetConsoleCursorPosition, consoleHandle, (BLOCK PTR [esi]).pos
    INVOKE WriteConsoleW, consoleHandle, ADDR fullBlock, 2, pWritten, 0
    popad

    add esi, SIZEOF BLOCK 
    loop LOOP_SNAKE 
    ret
PlotSnake ENDP


PlotApples PROC consoleHandle:DWORD, applePtr:PTR APPLE, appleLen:DWORD, pWritten:PTR DWORD
    mov esi, applePtr
    mov ecx, appleLen

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


PlotObst PROC consoleHandle:DWORD, obstPtr:PTR OBSTACLE, obstLen:DWORD, pWritten:PTR DWORD
    mov esi, obstPtr
    mov ecx, obstLen

LOOP_OBST:
    pushad
    INVOKE SetConsoleCursorPosition, consoleHandle, (OBSTACLE ptr [esi]).pos
    INVOKE SetConsoleTextAttribute, consoleHandle, 08h
    INVOKE WriteConsoleW, consoleHandle, ADDR fullBlock, 2, pWritten, 0
    INVOKE SetConsoleTextAttribute, consoleHandle, 07h
    popad

    add esi, TYPE OBSTACLE
    loop LOOP_OBST 
    ret
PlotObst ENDP

END

