; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; GCD.asm
; 12/5/2022
; Itay Aharon Goldberg  
; Yonatan Kupfer   
; Description: This code contains two routines that compute 
; the GCD algorithm of an array and specific integers
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.model small
.stack 200h
.data
.data
result dw ?
input_arr dw 3024, 1234, 1244, 44, 12414
inputLen EQU 5
.code

;input: AX=a, BX=b
;output: result gcd(a,b)
recGCD proc Near
	push ax
	push bx
	push dx

	;stop condition
	cmp bx, 0
	je bIsZero
	
	jmp bIsntZero
	;if b=0
bIsZero:	
	mov result, ax
	jmp stop
	
	;if b!=0
bIsntZero:
	
	;define: ax=b, bx=(a)mod(b)
	mov dx,0
	div bx
	mov ax, bx
	mov bx, dx
	
	;recurcive call
	call recGCD
	 
	;stop the rutine
stop:	
	pop dx
	pop bx
	pop ax
	ret
recGCD endp

;input: input_arr
;output: ax = gcd(input_arr)
;the routine compute recurcivly the value of gcd(a,b,c,...)
;when (a,b,c,...) represent the array values. the routine compute for each element
;the gcd of it with the gcd of the elemnts on his right. 
arrGCD proc

	cmp si,inputLen-1
	jb nextIter
	
	;if si = inputLen-1 then result=input_arr(inputLen)
	shl si, 1
	mov ax, [input_arr+si]
	shr si, 1
	mov result, ax
	;stop the iteration
	jmp stoparr
	
	;if si < inputLen-1 then call arrGCD when si++
nextIter:
	inc si	
	call arrGCD
	dec si
		
	shl si, 1 ;fit the index to dw
	mov ax, [input_arr+si] ;recGCD input
	mov bx, result	 ;recGCD input
	call recGCD 	;result = gcd(input_arr(si),result)
	shr si, 1
	
stoparr:
	mov ax, result
	ret
arrGCD endp

main:
	mov ax, @data
	mov ds, ax

	mov si,0
	mov ax, 21
	mov bx, 14
	mov dx, 201h
	;call recGCD
	call arrGCD
	
.exit
end main
