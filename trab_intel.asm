 .MODEL small

.STACK 1024

.DATA

	LF						EQU 0AH ;line feed
	CR						EQU 0DH ;carriage return
	end_of_string			EQU 00H ;'\0'
	space					EQU 20H ;' '

	flag_i					DB 0
	flag_o					DB 0
	flag_v					DB 0
	exit_code				DB 0

	prompt					DB 100 DUP(end_of_string)
	in_buffer				DB 100 DUP(?)
	input_file_name			DB 100 DUP(end_of_string)
	output_file_name		DB 100 DUP(end_of_string)
	tension_atoi            DB 4 DUP(end_of_string)

	default_input_file_name DB "a.in"
	default_output_file_name DB "a.out"

.CODE



printf PROC NEAR
	mov ah, 09h
	int 21h
	ret
	printf ENDP


strcpy_s PROC NEAR

	strcpy_loop:
		mov al, [si]
		cmp al, end_of_string
		je	ret_strcpy
		cmp al, space
		je	ret_strcpy

		mov [di], al
		inc di
		inc si
		JMP strcpy_loop

	ret_strcpy:
		inc di
		mov [di], end_of_string
		ret
		strcpy_s ENDP
		

-----------------------------------------------------------
gets	proc	near
	mov		ah,0ah						; L� uma linha do teclado
	lea		dx, in_buffer
	mov		byte ptr in_buffer, 96	; 2 caracteres no inicio e um eventual CR LF no final
	int		21h

	lea		si,in_buffer+2					; Copia do buffer de teclado para o FileName
	pop		di
	mov		cl,in_buffer+1
	mov		ch,0
	mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax
	rep 	movsb

	mov		byte ptr es:[di],0			; Coloca marca de fim de string
	ret
gets	endp



;---------------------------get_argv-----------------------
;in_buffer <- argv

get_argv_pointer PROC NEAR
	mov AH, 0AH
	lea dx, in_buffer
	int 21h
	
	RET
	get_argv_pointer ENDP
;---------------------------get_file_name-----------------------
;input_file_name <- nome do arquivo de input 

get_file_name PROC NEAR
	lea	si,	in_buffer

	get_file_name_loop:
		mov	al,	[si]
		inc si
		mov ah,	[si]

		cmp al, end_of_string
		JE	ret_get_file_name

		cmp	ah, '-'
		JE	possible_argument

		possible_argument:
			cmp ah,	'i'
			JE input_found
			JMP	get_file_name_loop

		input_found:
			inc si
			inc si
			mov	al,	[si]
			cmp	al, '-'
			JE	ret_get_file_name
			cmp	al, end_of_string
			JE	ret_get_file_name
			
			lea di, input_file_name

			call strcpy_s

		ret_get_file_name:
			ret
			get_file_name ENDP
			

get_output_file_name PROC NEAR
	lea si, in_buffer

	output_file_name_loop:
		mov ah, [si]

		cmp ah, end_of_string
		JE ret_get_output_name

		cmp ah, '-'
		JE possible_argument2

		inc si
		jmp output_file_name_loop

		possible_argument2:
			inc si
			mov ah, [si]
			cmp ah, 'o'

			je output_name_found
			jmp output_file_name_loop

		output_name_found:
			inc si
			inc si
			lea di, output_file_name
			call strcpy_s
	
	ret_get_output_name:
		ret
		get_output_file_name ENDP


get_tension PROC NEAR
	lea si, in_buffer

	get_tension_loop:
		mov ah, [si]

		cmp ah, end_of_string
		JE ret_get_tension

		cmp ah, '-'
		JE	possible_argument3

		inc si
		jmp get_tension_loop

		possible_argument3:
			inc si
			mov ah, [si]
			cmp ah, 'v'
			je voltage_found
			jmp get_tension_loop

		voltage_found:
			inc si
			inc si
			lea di, tension_atoi

			call strcpy_s

	ret_get_tension:
		ret
		get_tension ENDP


.STARTUP

	XOR AX, 	AX
	XOR BX, 	BX

	mov flag_i, 0
	mov flag_o, 0
	mov flag_v, 0
	mov exit_code, 0


	call get_argv_pointer
	call get_file_name
	call get_output_file_name
	call get_tension

	lea dx, tension_atoi
	call printf

	lea dx, input_file_name
	call printf

	lea dx, output_file_name
	call printf
		
.EXIT 0

END
	end