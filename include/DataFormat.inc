; basic unit of snake
; dir: 0 RIGHT, 1 UP, 2 LEFT, 3 DOWN
BLOCK STRUCT
    pos COORD <> 
    dir BYTE ?
BLOCK ENDS

; apple
APPLE STRUCT
    pos COORD <>
    eaten BYTE 0
APPLE ENDS

; obstacle
OBSTACLE STRUCT
    pos COORD <>
OBSTACLE ENDS
