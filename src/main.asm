; safe_square.asm
; 使用 Irvine32.inc，不在堆疊上分配字串緩衝區
; 請用 ML /coff 組譯並以 Irvine32.lib 連結

INCLUDE Irvine32.inc
INCLUDE Macros.inc

main EQU start@0

.DATA
    ; 使用靜態資料區，不放在堆疊上
    squareChar    BYTE 219, 0      ; '█' (full block), null-terminated
    infoMsg       BYTE "Author: Huang - safe demo", 0Dh,0Ah,0
    colors        BYTE 12,10,9,14  ; 4 種顏色：light red, light green, light blue, yellow
    colorMask     DWORD 3          ; 用於 mod 4 (and 3)
    rows          BYTE 10
    cols          BYTE 10

.CODE
main PROC
    ; 清螢幕並顯示說明字串（safe）
    call Clrscr
    mov edx, OFFSET infoMsg
    call WriteString

    ; 取得 row、col 值（都存在 .DATA 並為 byte）
    movzx ecx, rows     ; ecx = rows
    xor esi, esi        ; esi = current row index (y)

row_loop:
    push ecx            ; 保存外迴圈計數
    movzx ecx, cols     ; ecx = cols
    xor edi, edi        ; edi = current col index (x)

col_loop:
    ; 計算 index = (x + y) mod 4  --> 使用 and 3
    mov eax, esi
    add eax, edi
    and eax, 3
    mov bl, colors[eax] ; bl = color code

    ; 設定文字顏色（Irvine32 提供，會使用 bl）
    call SetTextColor

    ; 寫一個字元（WriteChar 由 Irvine32 處理，讀取 .DATA 的字元）
    mov al, squareChar
    call WriteChar

    inc edi
    loop col_loop

    call Crlf           ; 換行到下一列
    pop ecx             ; 恢復外迴圈計數
    inc esi
    loop row_loop

    ; 重設顏色並停在螢幕下方
    mov bl, 7
    call SetTextColor
    call Crlf
    call WaitMsg        ; 等待按鍵
    exit
main ENDP
END main
