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
	char_buffer_1
	char_buffer_2

.CODE

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
		JE	end_get_file_name

		cmp	ah, '-'
		JE	possible_argument

		possible_argument:
			cmp ah,	'i'
			JE input_found
			JMP	get_file_name_loop

		input_found:
			inc si
			mov	al,	[si]
			cmp	al, '-'
			JE	end_get_file_name
			cmp	al, end_of_string
			JE	end_get_file_name
			
			mov byte flag_i, 1
			lea di, input_file_name

			read_input_file_name_loop:
				mov	al, [si]
				cmp	al, end_of_string
				JE	end_get_file_name

				mov [di], al
				inc di
				JMP read_input_file_name_loop


		end_get_file_name:
			cmp	flag_i, 1
			JE ret_get_file_name
			mov byte exit_code, 'i'

		ret_get_file_name:
			mov [di], end_of_string
			ret
			get_file_name ENDP
			

wrong_parameter_found PROC NEAR
	;;;


.STARTUP

	XOR AX, 	AX
	XOR BX, 	BX

	mov byte flag_i, 0
	mov byte flag_o, 0
	mov byte flag_v, 0
	mov byte exit_code, 0
	

.EXIT 0