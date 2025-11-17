INCLUDE Irvine32.inc
INCLUDE Macros.inc
INCLUDE GraphWin.inc
INCLUDE DataFormat.inc

main EQU start@0

GetStdHandle  PROTO :DWORD
WriteConsoleW PROTO :DWORD, :PTR WORD, :DWORD, :PTR DWORD, :DWORD
ExitProcess   PROTO :DWORD

.DATA
    consoleHandle DWORD ?

    fullBlock     WORD 2 dup(2588h), 0      ; '█' (full block), null-terminated
    colors        BYTE 12,10,9,14  ;light red, light green, light blue, yellow
    colorMask     DWORD 3
    rows          BYTE 10
    cols          BYTE 10
    cnt           DWORD ?

    snake COORD <10, 10>

.CODE
main PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov consoleHandle, eax

MAIN_LOOP:
    call ReadChar

    ; Detect input char
    ; UP ARROW, or W
    .IF ax == 1177h		
        sub snake.y, 1
        call ClrScr
    .ENDIF
    ; DOWN ARROW, or S
    .IF ax == 1F73h
        add snake.y, 1
        call ClrScr
    .ENDIF
    ; LEFT ARROW, or A
    .IF ax == 1E61h
        sub snake.x, 2
        call ClrScr
    .ENDIF
    ; RIGHT ARROW, or D
    .IF ax == 2064h
        add snake.x, 2
        call ClrScr
    .ENDIF
    ; ESC
    .IF ax == 011Bh
        jmp END_FUNC
    .ENDIF

    INVOKE SetConsoleCursorPosition, consoleHandle, snake
    invoke WriteConsoleW, 
        consoleHandle,
        ADDR fullBlock,
        LENGTHOF fullBlock,
        ADDR cnt,
        0


    jmp MAIN_LOOP

END_FUNC:
    call WaitMsg   
    exit
main ENDP
END main
