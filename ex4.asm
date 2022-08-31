; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ex4.asm
; 09/06/2022
; Itay Aharon Goldberg
; Yonatan Kupfer
; Description: a game. user moves the symbol 'O' to collect 'X's. the program print the score
; of the user at the end (press 'q')
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.model small
.stack 100h
.data
	Olocation dw 1840d
	Xlocation dw 0
	score dw -1
	counter dw 0
	msg_score	db 'Score:   ',0Ah,0Dh,'$'

.code

;input: dx as movement in x & y
;output: none
;the routine move O on the screen & update the O's locations variables
moveO proc uses ax bx

	;delete last O
	mov bx, Olocation
	mov al, 32d
	mov ah, 15d
	mov es:[bx],ax
	
	;update Olocation
	add Olocation, dx
	
	;print O
	mov bx, Olocation
	mov al, 79d
	mov ah, 4d
	mov es:[bx],ax
	
	ret
moveO endp

;input: none
;output: none
;generate a location on screen and print X & update Xlocation
printX proc uses ax bx cx dx

	;define new location
	;bx = [sec]*256+[min]
	mov al, 2
	out 70h, al
	in al, 71h
	mov bl, al
	
	mov al, 0
	out 70h, al
	in al, 71h
	mov bh, al
	
	;fit the result to the screen
	mov dx, 0
	mov ax, bx
	mov cx, 2000d
	div cx
	add dx, dx
	
	;check for different location
	mov bx, Xlocation
	cmp bx, dx
	jz printX

	mov Xlocation, dx
	
	;print X
	mov bx, Xlocation
	mov al, 58h
	mov ah, 4d
	mov es:[bx],ax
	
	inc score

	ret
	
printX endp

;new interrupt 1c
ISR_New_Int1c proc far uses ax es
	
	inc counter
	
	int 80h ;use the old interupt
	iret
ISR_New_Int1c endp

;replace the interrupts in the IVT
replace_Int proc far uses ax es
	mov ax,0h ; IVT is location is '0000' address of RAM
	mov es,ax
	
	cli ; block interrupts
	
	;moving Int1c into IVT[080h]
	mov ax,es:[1ch*4] ;copying old ISR 1c IP to free vector
	mov es:[80h*4],ax
	mov ax,es:[1ch*4+2] ;copying old ISR 1c CS to free vector
	mov es:[80h*4+2],ax
	
	;moving ISR_New_Int1c into IVT[1c]
	mov ax,offset ISR_New_int1c ;copying IP of ISR_New to IVT[1c]
	mov es:[1ch*4],ax
	mov ax,cs ;copying CS of our ISR_New into IVT[1c]
	mov es:[1ch*4+2],ax
	
	sti ;enable interrupts

	ret
replace_Int endp

;restore IVT 1c
restoreIVT proc far uses ax es
	mov ax, 0h
	mov es,ax
	
	cli ; block interrupts
	
	;moving old interrupt 1c back into IVT[1c]
	mov ax,es:[80*4]
	mov es:[1ch*4],ax
	mov ax,es:[80*4+2]
	mov es:[1ch*4+2],ax
	
	sti ;enable interrupts
	
	ret

restoreIVT endp

main:
; -------------------- Adjustments & settings --------------
	;replac_Int_1ch
	call replace_Int
	
	;set es, ds to the screen and data offset
	mov ax, @data
	mov ds, ax
	mov ax, 0b800h
	mov es, ax
	
	;reset screen
	mov cx, 2001d
l1:	
	mov bx, cx
	add bx, bx
	sub bx, 2
	mov al, 32d
	mov ah, 15d
	mov es:[bx],ax
	loop l1
	
	;print initial O
	mov dx, 0
	call moveO
	
	;print initial X
	call printX
	
	;fit the 09h hardwere interrupt
	in al, 21h
	or al, 02h
	out 21h, al
	
; -------------------- Receiving input & identify --------------

	;Checks for input
wti:
	mov bx, counter
	cmp bx, 3
	jb skip
	mov counter, 0
	jmp auto
skip:
	in al, 64h
	test al, 01
	jz wti
	
	;set the input to al
	in al, 60h
	
	mov cl, al
auto:
	mov al, cl
	mov bx, Olocation
	
	;identify
	cmp al, 9eh ;send when input is A
	je ieA
	cmp al, 0a0h ;send when input is D
	je ieD
	cmp al, 91h ;send when input is W
	je ieW
	cmp al, 9fh ;send when input is S
	je ieS
	cmp al, 90h ;send when input is Q
	je quit
	
	jmp wti

; -------------------- move the O --------------

	;al = A
ieA:
	;screen borders check
	mov ax, bx
	mov bh, 0a0h
	div bh
	cmp ah,0
	je wti
	
	mov dx, -2
	call moveO
	jmp Xcheck
	
	;al = D
ieD:
	;screen borders check
	mov ax, bx
	mov bh, 0a0h
	div bh
	cmp ah,158d
	je wti
	
	mov dx, 2
	call moveO
	jmp Xcheck
	
	;al = W
ieW:
	;screen borders check
	cmp bx,9eh
	jbe wti
	
	mov dx, -0a0h
	call moveO
	jmp Xcheck
	
	;al = S
ieS:
	;screen borders check
	cmp bx,3840d
	jge wti
	
	mov dx, 0a0h
	call moveO
	jmp Xcheck
	
; -------------------- Replace X --------------
Xcheck:
	mov ax, Olocation
	mov bx, Xlocation
	cmp ax,bx
	jnz wti
	call printX
	jmp wti
	
; -------------------- quit --------------
quit:	
	
	;score msg
	mov ax, score
	mov bh, 10d
	div bh
	add ax, 3030h
	mov [msg_score + 6], al
	mov [msg_score + 7], ah
	
	mov dx,offset msg_score
	call restoreIVT
	mov ah,9h
	int 21h
	
	;redefine 09 interrupt
	in al, 21h
	and al, 0fdh
	out 21h, al
	
.exit
end main