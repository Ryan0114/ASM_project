INCLUDE Irvine32.inc
INCLUDE DataFormat.inc
INCLUDE GameMechanism.inc

.data
.code

CheckIntersection PROC x:WORD, y:WORD, 
                       snakePtr:PTR BLOCK, sLen:DWORD, 
                       obstaclePtr:PTR OBSTACLE, oLen:DWORD
; check if the destination is empty
SELF_INTERSECTING:
    mov ecx, sLen
    add ecx, -1
    mov esi, snakePtr 
    add esi, SIZEOF BLOCK 
    
SELF_INTERSECTING_LOOP:
    cmp ax, (BLOCK PTR [esi]).pos.X
    jne CONTINUE_SELF 

    cmp dx, (BLOCK PTR [esi]).pos.Y
    jne CONTINUE_SELF 

    jmp NO_UPDATE

CONTINUE_SELF:
    add esi, SIZEOF BLOCK 
    loop SELF_INTERSECTING_LOOP

OBSTACLE_COLLISION:
    mov ecx, oLen
    mov esi, obstaclePtr 
OBSTACLE_LOOP:
    cmp ax, (OBSTACLE PTR [esi]).pos.X
    jne CONTINUE_OBS

    cmp dx, (OBSTACLE PTR [esi]).pos.Y
    jne CONTINUE_OBS
    
    mov bh, (OBSTACLE PTR [esi]).harmful
    .IF bh == 0
        jmp NO_UPDATE
    .ELSE 
        jmp GAMEOVER 
    .ENDIF

CONTINUE_OBS:
    add esi, SIZEOF OBSTACLE 
    loop OBSTACLE_LOOP

    jmp NO_INTERSECTION

NO_UPDATE:
    mov bh, 2
    jmp RETURN
GAMEOVER:
    mov bh, 1
    jmp RETURN
NO_INTERSECTION:
    mov bh, 0 
RETURN:
    ret
CheckIntersection ENDP

; -------------- check supported --------------
CheckSupported PROC
    
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
    mov ecx, boxLen
    mov esi, 0
SUPP_BOX:
CheckSupported ENDP
END
