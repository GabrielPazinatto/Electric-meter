.MODEL large
.STACK 1024

.DATA

	LF						EQU 0AH ;line feed
	CR						EQU 0DH ;carriage return
	end_of_string			EQU 00H ;'\0'
	space					EQU 20H ;' '

	CRLF					DB CR,LF

	num_count				dw 0
	counter 				DW 0
	flag_i					DB 0
	flag_o					DB 0
	flag_v					DB 0
	exit_code				DB 0

	read_bytes				dw 0
	input_file_handle 		DW 0
	output_file_handle		DW 0

	char					db 2 DUP(0)
	input_file_line         db 1000 DUP(0)
	
	input_file_line_vector  DB 10 DUP(end_of_string)
	prompt					DB 100 DUP(end_of_string)
	in_buffer				DB 100 DUP(?)
	input_file_name			DB 100 DUP(end_of_string)
	output_file_name		DB 100 DUP(end_of_string)
	voltage_atoi            DB 10 DUP(end_of_string)
	voltage					Dw 0
	next					dw 0

	str_voltage_1			db 4 DUP(0)
	str_voltage_2			db 4 DUP(0)
	str_voltage_3			db 4 DUP(0)

	voltage_1				DW 0
	voltage_2				DW 0
	voltage_3				DW 0

	str_127					db "127",end_of_string
	str_220					db "220",end_of_string

	default_input_file_name DB "a.in",end_of_string
	default_output_file_name DB "a.out",end_of_string

	msg_error_open_input_file		DB "Arquivo de entrada nao pode ser aberto.", end_of_string
	msg_error_invalid_voltage DB "Valor de tensao incorreta.", end_of_string
	msg_error_open_output_file   DB "Arquivo de saida nao pode ser aberto.", end_of_string
	msg_error_couldnt_create_output DB "Arquivo de saida nao pode ser criado.", end_of_string

.CODE


;----------------------------------------------
;di <- destiny
;si <- source

strcpy_s PROC NEAR
	mov bl, [si]
	cmp bl, space
	je ret_strcpy
	cmp bl, end_of_string
	je ret_strcpy

	mov [di], bl
	inc si
	inc di
	jmp strcpy_s

	ret_strcpy:
		inc di
		mov [di], end_of_string
		ret
		strcpy_s ENDP

;----------------------------------------------


terminate PROC NEAR
	mov ah, 4ch
	mov al, 0
	int 21H
	ret
	terminate ENDP


;----------------------------------------------
get_argv PROC NEAR

	push ds ; Salva as informações de segmentos
	push es
	mov ax,ds ; Troca DS com ES para poder usa o REP MOVSB
	mov bx,es
	mov ds,bx
	mov es,ax
	mov si,80h ; Obtém o tamanho do string da linha de comando e coloca em CX
	mov ch,0
	mov cl,[si]
	mov ax,cx ; Salva o tamanho do string em AX, para uso futuro
	mov si,81h ; Inicializa o ponteiro de origem
	lea di, in_buffer ; Inicializa o ponteiro de destino
	rep movsb
	pop es ; retorna as informações dos registradores de segmentos
	pop ds

	ret

	get_argv ENDP

;----------------------------------------------
	printf_s	proc	near

	;	While (*s!='\0') {
		mov		dl,[bx]
		cmp		dl,0
		je		ps_1

	;		putchar(*s)
		push	bx
		mov		ah,2
		int		21H
		pop		bx

	;		++s;
		inc		bx
			
	;	}
		jmp		printf_s
			
	ps_1:
		mov dl, LF
		int 21H
		mov dl, cr
		int 21h
		ret
		
	printf_s	endp

;----------------------------------------------



;----------------------------------------------
get_tension PROC NEAR
	lea si, in_buffer

	get_tension_loop:
		mov ah, [si]

		cmp ah, end_of_string
		JE voltage_not_found

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
			lea di, voltage_atoi

			call strcpy_s
			jmp ret_get_tension

		voltage_not_found:
			mov voltage, 127
			lea di, voltage_atoi
			lea si, str_127
			call strcpy_s

	ret_get_tension:
		ret
		get_tension ENDP

;----------------------------------------------

get_output_file_name PROC NEAR
	lea si, in_buffer

	output_file_name_loop:
		mov al, [si]

		cmp al, end_of_string
		JE output_file_name_not_found

		cmp al, '-'
		JE possible_argument2

		inc si
		jmp output_file_name_loop

		possible_argument2:
			inc si
			mov al, [si]
			cmp al, 'o'

			je output_name_found
			jmp output_file_name_loop

		output_file_name_not_found:
			lea si, default_output_file_name
			lea di, output_file_name

			call strcpy_s

			jmp ret_get_file_name

		output_name_found:
			inc si
			inc si

			mov al, [si]

			lea di, output_file_name
			call strcpy_s
	
	ret_get_output_name:
		ret
		get_output_file_name ENDP

;----------------------------------------------

get_file_name PROC NEAR
	lea	si,	in_buffer

	get_file_name_loop:
		mov	al,	[si]

		cmp al, end_of_string
		JE	input_file_name_not_found

		cmp	al, '-'
		JE	possible_argument

		inc si
		jmp get_file_name_loop

		possible_argument:
			inc si
			mov al, [si]
			cmp al,	'i'
			
			JE input_found
			JMP	get_file_name_loop

		input_file_name_not_found:
			lea si, default_input_file_name
			lea di, input_file_name

			call strcpy_s

			jmp ret_get_file_name

		input_found:
			inc si
			inc si

			lea di, input_file_name

			call strcpy_s

		ret_get_file_name:
			ret
	get_file_name ENDP

;----------------------------------------------

open_input_file PROC NEAR
	test al, al
	mov al, 0							;abre no modo de leitura
	mov ah, 3dh
	int 21H
	mov bx, ax

	jc perror_open_input_file
	ret

	perror_open_input_file:
		lea bx, msg_error_open_input_file
		call printf_s

		mov ah, 4ch
		mov al, 1
		int 21h
	
	ret
	open_input_file ENDP

;----------------------------------------------

open_output_file PROC NEAR
	test al, al

	mov al, 1							;abre no modo de escrita
	mov ah, 3dh
	int 21H
	mov bx, ax

	jc try_create_output
	retry:

	jc perror_open_output_file
	ret

	try_create_output:
		call create_output_file
		jmp retry

	perror_open_output_file:
		lea bx, msg_error_open_output_file
		call printf_s

		call terminate
	
	ret
	open_output_file ENDP

;----------------------------------------------

create_output_file PROC NEAR
	test al, al
	
	lea dx, output_file_name
	mov cx,	0
	mov ah, 3ch
	int 21H

	mov ax, output_file_handle
	ret

	create_output_file ENDP

;----------------------------------------------

atoi	proc near
		; A = 0;
		mov		ax,0
atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		atoi_1
		; 	A = 10 * A
		mov		cx,10
		mul		cx
		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx
		; 	A = A - '0'
		sub		ax,'0'
		; 	++S
		inc		bx
		;}
		jmp		atoi_2
atoi_1:
		; return
		ret
atoi	endp

;----------------------------------------------

check_voltage_input PROC NEAR
	push ax
	mov ax, voltage

	cmp ax, 127
	je ret_check_voltage
	cmp ax, 220
	je ret_check_voltage

	jmp invalid_voltage

	invalid_voltage:
		lea bx, msg_error_invalid_voltage
		call printf_s
		call terminate

	ret_check_voltage:
		ret

	check_voltage_input ENDP

;----------------------------------------------
advance_file_pointer PROC NEAR ;dx <- numero de bytes para avançar
	mov ah, 42h
	mov al, 1
	mov bx, input_file_handle
	mov cx, 0
	int 21H
	ret

advance_file_pointer ENDP
;----------------------------------------------
ascii_is_int PROC NEAR ;dl <- char
                       ;si <- 1 se representar um numero, 0 caso contrario
	cmp dl, 49
	jb not_ascii
	cmp dl, 57
	ja not_ascii

	mov si, 1
	ret

	not_ascii:
		mov si, 0
		ret

	ascii_is_int ENDP

;----------------------------------------------
letter_is_in_string PROC NEAR 		  ; dl <- char
	push ax
	push si                			  ; dh <- 1 se estiver, 0 caso contrario
	mov si, 0						  ; bx <- ponteiro para string
	loop_search_char:
		mov al, [bx+si]

		cmp al, 0
		je char_not_found

		cmp al, dl
		je char_found
		
		inc si
		jmp loop_search_char 

	char_not_found:
		mov dh, 0
		pop si
		pop ax
		ret
	
	char_found:
		mov dh, 1
		pop si
		pop ax
		ret
	ret

letter_is_in_string ENDP


;----------------------------------------------

get_input_text PROC NEAR
	mov ah, 3fh
	mov cx, 10000
	mov bx, input_file_handle
	;lea dx, input_text
	int 21h
	ret

get_input_text ENDP

;----------------------------------------------
;----------------------------------------------
getline PROC NEAR

	mov counter, 0

	getchar_loop:
		mov ah, 3fh
		mov cx, 1
		lea dx, char
		mov bx, input_file_handle

		test ax, ax
		int 21H
		mov read_bytes, ax
		jc end_get_line

		push bx

		mov dl, char
		
		;cmp dl, 0
		;je end_get_line
		cmp dl, 0AH
		je end_get_line
		cmp dl, 0DH
		je end_get_line

		lea bx, input_file_line
		add bx, counter

		mov byte ptr [bx], dl
		pop bx

		inc counter
		jmp getchar_loop

	end_get_line:
		mov byte ptr [bx+1], end_of_string
		mov dx, 1
		call advance_file_pointer
		ret
getline ENDP


;----------------------------------------------

.STARTUP

	;-----------------------------getting input
	lea bx, in_buffer
	call get_argv

	call get_tension
	call get_output_file_name
	call get_file_name
	;------------------------------converting input

	lea bx, voltage_atoi
	call atoi
	mov voltage, ax
	
	;-----------------------------checking input

	lea dx, input_file_name
	call open_input_file
	mov input_file_handle, bx

	lea dx, output_file_name
	call open_output_file
	mov output_file_handle, bx

	call check_voltage_input

	;-----------------------------

read_line:

	call getline                  ;le uma linha do input

	lea bx, input_file_line       ;se tiver a letra f, é por que esta escrito fim
	mov dl, 'f'            
	call letter_is_in_string
	cmp dh, 1
	je end_read_line              ;entao para de ler o arquivo
	
	;lea bx, input_file_line
	;call printf_s

	cmp read_bytes, 0
	jne read_line

	end_read_line:

	;-----------------------------processing

	;lea bx, voltage_atoi
	;call printf_s

	;lea bx, output_file_name
	;call printf_s

	;lea bx, input_file_name
	;call printf_s


.EXIT 0

END
	end