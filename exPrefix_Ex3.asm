; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; exPrefix.asm
; 19/5/2022
; Itay Aharon Goldberg  
; Yonatan Kupfer   
; Description: the program gets a number(hex) by stack and print(decimal) the number several time
; when each time the least significant (decimal) digit deleted.
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.model small
.stack 100h
.data
.code

;input: integer(h) by stack
;output: non
;send the number to the printNum routine and then deletes the least 
;significant (decimal) digit each iteration.
numPrefix proc near

	mov bp,sp
	add bp,2
	
	push bx
	push dx
	push ax
	
	;ax gets the requested value from stack
	mov ax, [bp] 

	;stop condition
	cmp ax,0
	jz stop1
	
	;define & save the registers
	push cx
	push si
	push ax

	mov si, 0 ;printer index (in line)	
	add bx, 160d ;line index
	mov cx, 0ah
	call printNum ;print the value in ax
	
	pop ax
	pop si

	mov dx, 0
	idiv cx ;ax = floor[ax/10], dx = (ax)mod(10)

	push ax
	call numPrefix ;recursive call
	pop ax
	pop cx

	;clean the stack & redefine the registers
stop1:
	pop ax
	pop dx
	pop bx
	ret
	
numPrefix endp 

;input: integer(h) by ax
;output: non
;print (cast to decimal) a number digit by digit.
;the routine divide the number and store the last decimal digit in the stack
;then, pop & print the digits last to first.
printNum proc near
	;stop condition
	cmp ax,0
	jz stop2

	mov dx, 0
	idiv cx ;ax = floor[ax/10], dx = (ax)mod(10)
	
	push dx
	call printNum ;recursive call
	
	;print dx
	pop dx	
	mov ah, 15d
	mov al, dl
	add al, 30h
	mov es:[bx+si],ax
	add si,2
stop2:	
	ret
	
printNum endp


main:
	mov ax, 0b800h
	mov es, ax
	
	mov bx, 280h	
	
	mov ax, 3120h
	push ax
	call numPrefix

.exit
end main