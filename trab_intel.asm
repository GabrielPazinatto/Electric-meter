.MODEL small
.STACK 4096
.DATA

	comma                   EQU 44
	LF						EQU 0AH ;line feed
	CR						EQU 0DH ;carriage return
	end_of_string			EQU 00H ;'\0'
	space					EQU 20H ;' '

	CRLF					DB CR,LF
	str_CRLF				DB CR,LF,end_of_string
	sw_n	dw	0 							; Usada dentro da funcao sprintf_w
	sw_f	db	0							; Usada dentro da funcao sprintf_w
	sw_m	dw	0							; Usada dentro da funcao sprintf_w
                   
	counter 				DW 0            ; Usada em varias funçoes como contador
	read_bytes				dw 0            ; Quantidade de bytes lidos a cada chamado da funçao getline
	input_file_handle 		DW 0            ; handle do arquivo de entrada
	output_file_handle		DW 0            ; handle do arquivo de saida

	input_file_is_invalid 	dw 0

	char					db 0            ; Armazena um char
	input_file_line         db 1000 DUP(0)  ; Armazena uma linha do arquivo

	bad_voltage_count		dw -1
	no_voltage_count		dw -1
	line_count				dw -1
	str_line_count          DB 5 DUP(end_of_string), end_of_string
	
	in_buffer				DB 100 DUP(?)               ; Armazena os argumentos de entrada
	input_file_name			DB 100 DUP(end_of_string)   ; Nome do arquivo de entrada
	output_file_name		DB 100 DUP(end_of_string)   ; nome do arquivo de saida
	voltage_atoi            DB 10 DUP(end_of_string)    ; string da voltagem
	voltage					Dw 0                        ; voltagem
	max_voltage				dw 0
	min_voltage				dw 0

	str_voltage_1			db 10 DUP(0)                 ; string da primeira voltagem lida em cada linha
	str_voltage_2			db 10 DUP(0)                 ; string da segunda voltagem lida em cada linha
	str_voltage_3			db 10 DUP(0)                 ; string da terceira voltagem lida em cada linha

	first_is_int			dw 0     ;usadas na funçao de busca por espaço entre numeros
	second_is_space			dw 0
	third_is_int			dw 0

	voltage_1				DW 0     ; Primeira voltagem encontrada em cada linha
	voltage_2				DW 0     ; Segunda
	voltage_3				DW 0     ; Terceira

	str_127					db "127",end_of_string
	str_220					db "220",end_of_string

	default_input_file_name DB "a.in",end_of_string
	default_output_file_name DB "a.out",end_of_string

	msg_error_open_input_file		DB "Arquivo de entrada nao pode ser aberto.", end_of_string
	msg_error_invalid_voltage DB "Valor de tensao incorreta.", end_of_string
	msg_error_open_output_file   DB "Arquivo de saida nao pode ser aberto.", end_of_string
	msg_error_couldnt_create_output DB "Arquivo de saida nao pode ser criado.", end_of_string
	msg_error_couldnt_close_file DB "Nao foi possivel fechar um dos arquivos.", end_of_string

	msg_space DB " ", end_of_string
	msg_linha DB "Linha ",end_of_string
	msg_invalido DB "Invalida: ", end_of_string

	msg_input DB "-i ",end_of_string
	msg_voltage DB "-v ",end_of_string
	msg_output DB "-o ", end_of_string

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
		mov	ah,2
		mov dl, cr
		int 21h

		mov	ah,2
		mov dl, LF
		int 21H
		ret
		
	printf_s	endp

;----------------------------------------------
	printf	proc	near

	;	While (*s!='\0') {
		mov		dl,[bx]
		cmp		dl,0
		je		ps_1_2

	;		putchar(*s)
		push	bx
		mov		ah,2
		int		21H
		pop		bx

	;		++s;
		inc		bx
			
	;	}
		jmp		printf
			
	ps_1_2:
		ret
		
	printf	endp

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
	je ret_check_voltage_127
	cmp ax, 220
	je ret_check_voltage_220

	jmp invalid_voltage

	invalid_voltage:
		lea bx, msg_error_invalid_voltage
		call printf_s
		call terminate

	ret_check_voltage_127:
		lea si, max_voltage
		mov [si], 137
		lea si, min_voltage
		mov [si], 117
		ret

	ret_check_voltage_220:
		lea si, max_voltage
		mov [si], 230
		lea si, min_voltage
		mov [si], 210
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
	cmp dl, 48
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
close_file PROC NEAR ; <- bx file handle
	mov ah, 3EH
	
	cmp bx, 0 ;;aparentemente usar essa int com bx == 0 fecha o stdin?
	je not_close

	test ax, ax
	int 21H
	jc not_close
	ret

	not_close:
		lea bx, msg_error_couldnt_close_file
		call printf_s
		ret

	close_file ENDP

;----------------------------------------------
get_voltage_readings PROC NEAR
	lea bx, input_file_line
	mov counter, 0

	lea di, str_voltage_1
	voltage_reading_loop_1:
		mov byte ptr dl, [bx]

		cmp dl, 0
		je end_reading_voltage

		call ascii_is_int
		cmp si, 1
		je get_reading_1
		inc bx
		jmp voltage_reading_loop_1
		get_reading_1:
			mov byte ptr [di], dl			
			inc bx
			inc di
			mov byte ptr dl, [bx]

			cmp dl,0
			je end_reading_voltage

			call ascii_is_int
			cmp si, 1
			je get_reading_1

			mov [di+1], end_of_string

			lea di, str_voltage_2
			jmp voltage_reading_loop_2

	voltage_reading_loop_2:
		mov byte ptr dl, [bx]

		cmp dl,0
		je end_reading_voltage
		cmp dl,cr
		je end_reading_voltage
		cmp dl,LF
		je end_reading_voltage

		call ascii_is_int
		cmp si, 1
		je get_reading_2
		inc bx
		jmp voltage_reading_loop_2
		get_reading_2:
			mov byte ptr [di], dl			
			inc bx
			inc di
			mov byte ptr dl, [bx]

			cmp dl,0
			je end_reading_voltage
			cmp dl,cr
			je end_reading_voltage
			cmp dl,LF
			je end_reading_voltage

			call ascii_is_int
			cmp si, 1
			je get_reading_2

			mov [di+1], end_of_string
			lea di, str_voltage_3
			jmp voltage_reading_loop_3

	voltage_reading_loop_3:
		mov byte ptr dl, [bx]

		cmp dl,0
		je end_reading_voltage
		cmp dl,cr
		je end_reading_voltage
		cmp dl,LF
		je end_reading_voltage

		call ascii_is_int
		cmp si, 1
		je get_reading_3
		inc bx
		jmp voltage_reading_loop_3
		get_reading_3:
			mov byte ptr [di], dl			
			inc bx
			inc di
			mov byte ptr dl, [bx]

			cmp dl,0
			je end_reading_voltage

			call ascii_is_int
			cmp si, 1
			je get_reading_3
			mov [di+1], end_of_string
	end_reading_voltage:
		ret
get_voltage_readings ENDP

;----------------------------------------------
convert_readings_to_int PROC NEAR
	lea bx, str_voltage_1
	call atoi
	mov voltage_1, ax

	lea bx, str_voltage_2
	call atoi
	mov voltage_2, ax

	lea bx, str_voltage_3
	call atoi
	mov voltage_3, ax

	ret
convert_readings_to_int ENDP

;----------------------------------------------
check_invalid_line PROC NEAR
	mov si, 0
	mov cx, 0

	count_commas:
		lea bx, input_file_line
		mov dl, byte [bx+si]

		cmp dl, 0
		je stop_counting_c

		cmp dl, comma
		je found_comma
		
		inc si
		jmp count_commas

		found_comma:
			inc cx
			inc si
			jmp count_commas

		stop_counting_c:
			cmp cx, 2
			jne wrong_val


	mov dx, voltage_1
	cmp voltage_1, 499
	ja wrong_val

	mov dx, voltage_2
	cmp	dx, 499
	ja wrong_val

	mov dx, voltage_3
	cmp dx, 499
	ja wrong_val

	correct_val:
		mov ax, 0
		ret
	wrong_val:
		mov ax, 1
		ret
check_invalid_line ENDP

;----------------------------------------------
sprintf_w	proc	near
;void sprintf_w(char *string, WORD n) {
	mov		sw_n,ax
;	k=5;
	mov		cx,5
;	m=10000;
	mov		sw_m,10000
;	f=0;
	mov		sw_f,0
;	do {
sw_do:
;		quociente = n / m : resto = n % m;	// Usar instru��o DIV
	mov		dx,0
	mov		ax,sw_n
	div		sw_m
;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	mov		sw_f,1
sw_continue:
;		n = resto;
	mov		sw_n,dx
;		m = m/10;
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
;		--k;
	dec		cx
;	} while(k);
	cmp		cx,0
	jnz		sw_do
;	if (!f)
;		*string++ = '0';
	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:
;	*string = '\0';
	mov		byte ptr[bx],0
;}
	ret
sprintf_w	endp

;----------------------------------------------
invalid_line_found PROC NEAR
	lea bx, msg_linha
	call printf

	mov ax, line_count
	lea bx, str_line_count
	call sprintf_w

	lea bx, str_line_count
	call printf

	lea bx, msg_space
	call printf

	lea bx, msg_invalido
	call printf

	lea bx, input_file_line
	call printf_s

	inc input_file_is_invalid

	ret

invalid_line_found ENDP

;----------------------------------------------
clear_voltage_strings PROC NEAR
	mov counter, 0
	lea di, str_voltage_1
	lea si, str_voltage_2
	lea bx, str_voltage_3

	clear_loop:
		mov byte ptr [di+counter], 0
		mov byte ptr [si+counter], 0
		mov byte ptr [bx+counter], 0

		inc counter
		cmp counter, 9
		je end_clear
		jmp clear_loop

	end_clear:
		ret
	clear_voltage_strings ENDP

;----------------------------------------------
clear_line_input PROC NEAR
	mov si, 99
	lea bx, input_file_line

	clear_loop1:
		mov byte ptr [bx+si], 0
		dec si

		cmp si, -1
		je end_clear1
		jmp clear_loop1

	end_clear1:
		ret

	clear_line_input ENDP
;----------------------------------------------
fprintf PROC NEAR
	mov ah, 40h
	mov cx, 1
	mov bx, output_file_handle
	ret

fprintf ENDP

;----------------------------------------------

fprintf_s PROC NEAR
	mov ah, 40h
	mov cx, 1
	mov bx, output_file_handle

	mov ah, 40h
	mov cx, 1
	mov bx, output_file_handle
	lea dx, str_CRLF

	ret

fprintf_s ENDP
;----------------------------------------------

check_voltage_quality PROC 	NEAR
	check_no_voltage:
	cmp voltage_1, 9
	ja check_bad_voltage
	cmp voltage_2, 9
	ja check_bad_voltage
	cmp voltage_3, 9
	ja check_bad_voltage

	inc no_voltage_count
	ret

	check_bad_voltage:
		mov ax, voltage_1
		cmp ax, max_voltage
		ja bad_voltage_found
		cmp ax, min_voltage
		jb bad_voltage_found

		mov ax, voltage_2
		cmp ax, max_voltage
		ja bad_voltage_found
		cmp ax, min_voltage
		jb bad_voltage_found

		mov ax, voltage_3
		cmp ax, max_voltage
		ja bad_voltage_found
		cmp ax, min_voltage
		jb bad_voltage_found

	end_check_quality:
		ret

	bad_voltage_found:
		inc bad_voltage_count
		ret



check_voltage_quality ENDP

;----------------------------------------------
.STARTUP
	;------------------------------------------------
	;
	;	CHECANDO O INPUT E TENTANDO ABRIR OS ARQUIVOS
	;
	;------------------------------------------------

	;-----------------------------pegando infos do cmdline
	lea bx, in_buffer
	call get_argv

	call get_tension
	call get_output_file_name
	call get_file_name
	;------------------------------convertendo voltagem
	lea bx, voltage_atoi
	call atoi
	mov voltage, ax
	;-----------------------------checando input
	lea dx, input_file_name       ;tenta abrir o arquivo de input
	call open_input_file
	mov input_file_handle, bx

	lea dx, output_file_name      ;tenta abrir o arquivo de output
	call open_output_file
	mov output_file_handle, bx

	call check_voltage_input      ;checa se a tensao informada é valida
	;------------------------------------------------
	;
	;	PROCURANDO LINHAS INVALIDAS NO INPUT
	;
	;------------------------------------------------

read_line:
	;----------------------------- limpa as strings lidas
	call clear_line_input
	call clear_voltage_strings
	;----------------------------- le uma linha do input
	call getline                  
	inc line_count
	;----------------------------- se nao tiver sido lido nenhum byte, para de ler o arquivo
	cmp read_bytes, 0             
	je end_read_line
	;----------------------------- ;se tiver a letra f, é por que esta escrito fim
	lea bx, input_file_line       
	mov dl, 'f'            
	call letter_is_in_string
	cmp dh, 1
	je end_read_line              ;entao para de ler o arquivo
	;----------------------------- se tiver a letra F, é por que esta escrito FIM
	lea bx, input_file_line       
	mov dl, 'F'            
	call letter_is_in_string
	cmp dh, 1
	je end_read_line              ;entao para de ler o arquivo
	;----------------------------- printa a linha (debug)
	lea bx, input_file_line
	;call printf_s
	;----------------------------- 
	call get_voltage_readings     ;isola a parte da linha com as leituras
	call convert_readings_to_int  ;converte as leituras para int
	call check_invalid_line       ;checa se a linha é invalida

	cmp ax, 0                     ;se a linha for invalida, informa o usuario e ativa flag de arquivo invalido
	je valid_line

	call invalid_line_found

	valid_line:
		jmp read_line             
	end_read_line:
		mov dx, input_file_is_invalid ;se alguma linha for invalida, encerra a execuçao
		cmp dx, 0
		jna gen_output       ;se nao, gera o arquivo de saida

		call terminate

		gen_output:

		
	;------------------------------------------------
	;
	;	GERANDO ARQUIVO DE SAIDA
	;
	;------------------------------------------------

	mov ah, 42h                ;retorna o ponteiro de arquivo para a posiçao inicial
	mov al, 0
	mov bx, input_file_handle
	mov cx, 0
	mov dx, 0
	int 21h

read_line_2:

	;----------------------------- limpa as strings lidas
	call clear_line_input
	call clear_voltage_strings
	;----------------------------- le uma linha do input
	call getline                  
	inc line_count
	;----------------------------- se nao tiver sido lido nenhum byte, para de ler o arquivo
	cmp read_bytes, 0             
	je read_line_2_end
	;----------------------------- ;se tiver a letra f, é por que esta escrito fim
	lea bx, input_file_line       
	mov dl, 'f'            
	call letter_is_in_string
	cmp dh, 1
	je read_line_2_end         ;entao para de ler o arquivo
	;----------------------------- se tiver a letra F, é por que esta escrito FIM
	lea bx, input_file_line       
	mov dl, 'F'            
	call letter_is_in_string
	cmp dh, 1
	je read_line_2_end          ;entao para de ler o arquivo
	;----------------------------- printa a linha (debug)
	lea bx, input_file_line
	;call printf_s
	;----------------------------- 
	call get_voltage_readings     ;isola a parte da linha com as leituras
	call convert_readings_to_int  ;converte as leituras para int
	call check_voltage_quality    ;incrementa os contadores de voltagem ruim, e sem voltagem

	;call terminate

	jmp read_line_2

	read_line_2_end:
		lea bx, msg_input
		call printf
		lea bx, input_file_name
		call printf_s

		lea bx, msg_voltage
		call printf
		lea bx, voltage_atoi
		call printf_s

		lea bx, msg_output
		call printf
		lea bx, output_file_name
		call printf_s

		lea bx, str_CRLF
		call printf

terminate_execution:
	mov bx, input_file_handle
	call close_file
	mov bx, output_file_handle
	call close_file

.EXIT 0

END
	end