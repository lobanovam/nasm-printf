;__________________________________________________________
section .rodata

formatStr: db 'Hello, %s, lets %% count together: %%%b, %c, %d, %x',10, 0
string1: db 'Sasha', 0
ErrorMsg: db  10, 'ERROR: unknown specificator!', 10, 0
msglen: equ $ - ErrorMsg

jumpTable:
          dq Bin
          dq Char
          dq Decimal
times ('o' - 'd' - 1)  dq  Dflt
          dq Oct
times ('s' - 'o' - 1)  dq  Dflt
          dq String 
times ('x' - 's' - 1)  dq  Dflt
          dq Hex

;__________________________________________________________
section .data

char: db 0h
reversed_str: times 16 db 0h
ordinary_str: times 16 db 0h

;__________________________________________________________


section .text
global _my_print

_my_print:   

          pop r15         ; removing return addres
        ;   mov rdi, formatStr
        ;   mov rsi, string1
        ;   mov rdx, 128
        ;   mov rcx, 'f'
        ;   mov r8, -100
        ;   mov r9, 0x1a2b3c4d

          
          push r9         ; pushing register arguments (6 args)
          push r8
          push rcx
          push rdx
          push rsi
          push rdi        ; first argument is format string

          call scanFormat

          pop rdi
          pop rsi
          pop rdx
          pop rcx
          pop r8
          pop r9 
          
          ;mov rax, 60       ; exit
          ;mov rdi, 0        ;  
          ;syscall    

          push r15         ; return adddres 
          ret 
;----------------------------------------------------------
;----------------------------------------------------------
;scanFormat
;----------------------------------------------------------
scanFormat:
          push rbp
          mov rbp, rsp

          add rbp, 16     ; now rbp points to format string
          mov rsi, [rbp]   ; rsi - pointer to format str
          add rbp, 8     ; now rbp points to first arg
.next:
          mov al, [rsi]    ; al - char of rsi (*rsi)
          cmp al, 0        ; if '\0' - done
          je .done

          cmp al, '%'      ; found %
          je .args

          call Putch       ; if nothing special
          inc rsi
          jmp .next

.args:    
          call putArg
          inc rsi
          jmp .next


.done:
          pop rbp
          ret
;----------------------------------------------------------
;----------------------------------------------------------
;putArg
;----------------------------------------------------------
putArg:
          xor rax, rax

          inc rsi      
          mov al, [rsi] ; al = specificator

          cmp al, '%'   ; special case
          je .persent

          cmp al, 'b'   ; lower than b - unknown 
          jl Dflt

          cmp al, 'x'   ; higher than x - unknown 
          jg Dflt
          
          jmp [jumpTable + 8*(rax - 'b')]    ; jumping with jumpTable

.persent:  
          call Putch
.done:
          ret
;----------------------------------------------------------
;----------------------------------------------------------
;Putch
;Expects:  rsi - char to put in stdout
;----------------------------------------------------------
Putch:
          push rcx   ; syscall destroys r11 and rcx 
          push r11

          mov rax, 1  ; syscall for write()
          mov rdx, 1  ; msg len
          mov rdi, 1  ; stdout

          syscall

          pop r11
          pop rcx

          ret
;----------------------------------------------------------
;----------------------------------------------------------
;Puts
;Expects:  rsi - string to put in stdout
;----------------------------------------------------------
Puts:  

.next:    cmp [rsi], byte 0
          je .done

          call Putch
          inc rsi
          jmp .next

.done:
          ret
;----------------------------------------------------------



;__________________________________________________________
;____________________printf Funcs__________________________
;__________________________________________________________

;----------------------------------------------------------
;Bin
;----------------------------------------------------------
Bin:      push rsi

          mov rax, [rbp]
          mov cl, 1 ; base
          call BOH

          add rbp, 8
          pop rsi
          jmp putArg.done
;----------------------------------------------------------
;----------------------------------------------------------
;Char
;----------------------------------------------------------
Char:     push rsi

          mov rax, [rbp]      ;rax - char from stack
          mov rsi, char
          mov byte [rsi], al  ; *buffer = al
          call Putch

          add rbp, 8
          pop rsi
          jmp putArg.done
;----------------------------------------------------------
;----------------------------------------------------------
;Decimal
;----------------------------------------------------------
Decimal:  push rsi

          mov rax, [rbp]
          call DecNum

          add rbp, 8
          pop rsi
          jmp putArg.done
;----------------------------------------------------------
;----------------------------------------------------------
;Oct
;----------------------------------------------------------
Oct:      push rsi

          mov rax, [rbp]
          mov cl, 3 ; base
          call BOH
        
          add rbp, 8
          pop rsi
          jmp putArg.done
;----------------------------------------------------------
;----------------------------------------------------------
;String
;----------------------------------------------------------
String:   push rsi

          mov rsi, [rbp]  ; rsi = pointer to str to put
          call Puts

          add rbp, 8
          pop rsi
          jmp putArg.done
;----------------------------------------------------------
;----------------------------------------------------------
;Hex
;----------------------------------------------------------
Hex:      push rsi
          
          mov rax, [rbp]
          mov cl, 4 ; base
          call BOH

          add rbp, 8
          pop rsi
          
          jmp putArg.done
;----------------------------------------------------------
;----------------------------------------------------------
;Dflt
;----------------------------------------------------------
Dflt:     push rcx
          push r11
      
          push rsi

          mov rax, 1
          mov rdi, 1
          mov rsi, ErrorMsg
          mov rdx, msglen

          syscall

          pop rsi

          pop r11
          pop rcx 
          jmp putArg.done
;----------------------------------------------------------


;__________________________________________________________
;____________________Util Funcs____________________________
;__________________________________________________________


;----------------------------------------------------------
;BOH
;Expects: rax - num to convert
;         cl - numerical system base
;----------------------------------------------------------
BOH:
          mov rdi, reversed_str
          push rcx
          mov rcx, 16
          call ClearBuff
          pop rcx
          mov rsi, reversed_str

          xor r12, r12                 ;counter
          mov rdx, -1  ;1111....1111
          shl rdx, cl                  ;1111....0000 (for base = 4)
          not rdx                      ;0000....1111 (for base = 4)

          mov r13, rdx                  ; memorizing mask

.loop:    and rdx, rax
          cmp rdx, 9
          jbe .digit

          add rdx, 7         ; it's letter
.digit:  
          add rdx, '0'       ; to ascii
          mov [rsi], rdx     ; to reversed_str
          inc r12
          
          inc rsi
          shr rax, cl        ; next <base> bytes
          mov rdx, r13       ; restoring mask
          cmp rax, 0
          jne .loop

          mov rcx, r12       ; setting counter
          call RvrsPrint

          ret 

;----------------------------------------------------------
;----------------------------------------------------------
;DecNum
;Expects: rax - num to convert to decimal
;----------------------------------------------------------
DecNum:  
          mov rdi, reversed_str
          mov rcx, 16
          call ClearBuff
          mov rsi, reversed_str
          mov ebx, 10       ; base of division
          xor rcx, rcx

          cmp eax, 0
          jge .loop
          
          mov r14, 1h       ; flag - negative number
          neg eax

.loop:
          xor edx, edx      ; (edx, eax) : (ebx)
          div ebx           ; eax - div, edx - mod (ostatok) 
          add edx, '0'      ; to ascii
          mov [rsi], edx
          inc rsi
          inc rcx           ; digit counter
          cmp eax, 0
          jne .loop

          cmp r14, 1h
          jne .done
          mov byte [rsi], '-'
          inc rsi
          inc rcx
          
.done:
          call RvrsPrint

          ret
;----------------------------------------------------------
;----------------------------------------------------------
;RvsrPrint
;Expects: rcx - digit counter (with '-')
;         rsi + 1 - addr of last symb of reversed str
;----------------------------------------------------------
RvrsPrint:
          dec rsi
          mov rdi, ordinary_str
          push rcx
          mov rcx, 16
          call ClearBuff
          pop rcx
          mov rdi, ordinary_str
.loop:
          mov ah, byte [rsi]
          mov byte [rdi], ah 
          inc rdi
          dec rsi
          loop .loop

          mov rsi, ordinary_str
          call Puts

          ret



;----------------------------------------------------------
;----------------------------------------------------------
;ClearBuff
;Expects: rdi - addr of buff to clear
;         rcx - bytes counter
;----------------------------------------------------------
ClearBuff:
.loop     mov byte [rdi], 0h
          inc rdi
          loop .loop
          ret 
;----------------------------------------------------------





