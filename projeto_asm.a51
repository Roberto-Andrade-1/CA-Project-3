;--------- constantes -------------
TempoL EQU 0x06						; Valor do reload do timer 250ms
TempoH EQU 0x06		

MAX EQU 50  						; numero a ser apresentado no display
DECI EQU 40 						; valor para chegar aos 10 milissegundos
SEGS EQU 100						; valor para chegar a 1 segundo

;----------- portas --------------
display1 EQU P1						; porta para o primeiro display
display2 EQU P2						; porta para o segundo display

BA	EQU P3.4						; porta do botao da opcao A
BB	EQU P3.5						; porta do botao da opcao b
BC	EQU P3.6						; porta do botao da opcao C
BD	EQU P3.7						; porta do botao da opcao d
	
;---------------------------------

CSEG AT 0300H
segmentos:	DB	0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x3F, 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0xBF, 0x88, 0x83, 0xC6, 0xA1 
				;0.,   1.,   2.,   3.,   4.,   5.,   -.,   0,    1,    2,    3,    4,    5,    6,    7,    8,    9,    -,    A,    b,    C,    d

; jump para o inicio do programa
CSEG AT 0000H
	JMP Inicio						; salta para o inicio do programa

;---------------------------------
;          interrupcoes          |
;---------------------------------

; interrupcao do 3.2 comeca a decrementar os 5 segundos
CSEG AT 0003H
	JMP interrupcaoExterna0
	
; timer no mode 0, ativada quando ha overflow do timer 0
CSEG AT 000BH
	JMP interrupcaoTimer
	
; interrupcao do 3.3 quando um dos botoes de resposta sao primidos ativa a AND
CSEG AT 0013H
	JMP interrupcaoExterna1
	

; botao 1 e primido
interrupcaoExterna0:
	CLR TR0             			; Para o timer
	CLR EX0							; para não poder clicar no botao outravez e comecar de novo
	SETB EX1						; ativa a externa 1 pode clicar nas opcoes
	CALL inicializacoes				; chama a rotina de inicializacoes 
	SETB TR0            			; Inicia o timer
	RETI

; Resposta selecionada 
interrupcaoExterna1:
	
	JNB BA, aPressed 				; se o botao A for primido salta para o aPressed
	JNB BB, bPressed				; se o botao b for primido salta para o aPressed
	JNB BC, cPressed				; se o botao C for primido salta para o aPressed
	JNB BD, dPressed				; se o botao d for primido salta para o aPressed
	JMP fimE1
	aPressed:		
		MOV R6, #18					; para mostrar A
		MOV R5, #1					; R1 passa para 1 para "dizer" que respondeu
		CLR EX1						; desativa a externa 1 para nao poder mudar de opcao
		JMP fimE1					; salta para o fim da rotina
	bPressed:
		MOV R6, #19					; para mostrar b
		MOV R5, #1					; R1 passa para 1 para "dizer" que respondeu
		CLR EX1						; desativa a externa 1 para nao poder mudar de opcao
		JMP fimE1					; salta para o fim da rotina
	cPressed:
		MOV R6, #20					; para mostrar C
		MOV R5, #1					; R1 passa para 1 para "dizer" que respondeu
		CLR EX1						; desativa a externa 1 para nao poder mudar de opcao
		JMP fimE1					; salta para o fim da rotina
	dPressed:
		MOV R6, #21					; para mostrar d
		MOV R5, #1					; R1 passa para 1 para "dizer" que respondeu
		CLR EX1						; desativa a externa 1 para nao poder mudar de opcao
	fimE1:
		RETI
	
; overflow do tempo
interrupcaoTimer: 

	CJNE R4, #1, resto				; se nao chegou ao fim do tempo ou se nao tem uma resposta, nao conta os um segundo
	DJNZ R2, fimT0					; decrementa o R2 (40 ms) até chegar a zero
	MOV R2, #DECI					; dá reset no R2 para voltar a contar os 40 ms
	DJNZ R3, fimT0					; decrementa o R3 (100) até chegar a 0, quando chega a 0 passou 1s
	CJNE R7, #1, muda				; se R7 não é igual a 1 salta para a etiqueta "muda"
	MOV R7, #0						; R7 fica com o valor 0, para continuar a mostrar a mesma resposta
	JMP continua					; salta para a etiqueta continua
	muda:
		MOV R7, #1					; Põe R7 a 1 para continuar a mostrar a mesma resposta
	continua:
		MOV R3, #SEGS				; volta a por R3 a 100
		JMP fimT0					; salta para o fimT0
	
resto:
	DJNZ R2, fimT0					; Decrementa R2 (40), se não é zero salta
	INC R0							; aumenta em 1 o valor do registo 0
	MOV R2, #DECI					; reset do R2, para voltar a contar os 40ms
	CJNE R0, #10, fimT0				; se ainda não passou os 0,1s (400ms) salta para o fimT0
	MOV R0, #0						; reset do R0 para voltar a contar 0,1s
	DJNZ R1, fimT0					; Decrementa R1, se não é zero salta
	INC R4							; aqui incrementamos o R4 para saber que chegou ao fim do tempo e sem resposta
fimT0:
	RETI	
	
;-----------------------------------------------------------------
	
; R0 - conta 10x 40ms
; R1 - tempo a mostrar nos displays
; R2 - conta os 40 ms
; R3 - conta 100x 40ms
; R4 - usado para saber se tem tempo para responder, ou se o tempo acabou
; R5 - 1:respondeu / 0: não respondeu
; R6 - fica com a resposta "a" ou "b" ou "c" ou "d"
; R7 - durante 1s fica a "1", depois durante 1s fica a "0" 

; inicio do programa
CSEG AT 0080H
	Inicio:
		MOV SP, #7
		CALL inicializacoes
		CALL ativaInterrupcoes
		CALL confTemp
		
	verificaResposta:
		CJNE R5, #1, continuaCiclo	; Se R5 for 1 entao uma resposta foi selecionada, caso contrario salta para "continuaCiclo"
		MOV R4, #1					; R4 fica com o valor 1, usado para ativar os intervalos de 1s
		
		SETB EX0					; ativa a externa 0
		CJNE R7, #1, loopResposta	; Se R7 for 1 fica durante 1 segundo neste loop, caso contrario salta para "loopResposta"
		CALL mostraDisplays			; chama a rotina para mostrar o tempo em que parou
		JMP verificaResposta		; salta para "verificaResposta"
	loopResposta:
		CALL resposta				; chama a rotina para mostrar a opcao selecionada
		JMP verificaResposta		; salta para a etiqueta "verificaResposta"
		
		
	continuaCiclo:
		CALL mostraDisplays			; chama a rotina de mostrar o tempo, quando ta a decrementar
		CJNE R1, #0, verificaResposta; se R1 for igual a zero chegou ao fim do tempo, se não for igual volta para o ciclo
		MOV R4, #1					; mete o valor 1 em R4 
		SETB EX0					; ativa a externa 0
		
		
	verificaSemResposta:
		CJNE R4, #0, loopSemResposta; Se R4 for 0 continua, caso contrario salta para a etiqueta "loopSemResposta"
		JMP verificaResposta		; salto para a etiqueta "verificaResposta"
	loopSemResposta:
		CJNE R7, #1,loopSemResposta2; Se R7 for 1 continua para mostrar durante 1s o tempo a 0.0, caso contrario salta para a etiqueta "loopSemResposta2"
		CALL mostraDisplays			; chama a rotina de mostrar o tempo restante no caso 0.0s
		JMP loopSemResposta			; salta para a etiqueta de "loopSemResposta"
	loopSemResposta2:
		CALL semResposta			; chama a rotina de "semResposta" para mostrar -.-
		JMP verificaSemResposta		; salta para a etiqueta "verificaSemResposta"
		

; rotina de mostrar a resposta selecionada
resposta:
	MOV DPTR, #segmentos			; em DPTR fica o valor do endereco dos segmentos
	CLR A							; limpamos o valor de A
		
	MOV A, #6						; A fica com o valor 6, representa -.
	MOVC A, @A+DPTR					; no A fica o endereco onde esta o valor a mostrar no display
	MOV display1, A					; no display e mostrado esse valor
	
	MOV A, R6						; A fica com o valor de R6, representa a resposta selecionada 
	MOVC A, @A+DPTR					; no A fica o endereco onde esta o valor a mostrar no display
	MOV display2, A					; no display e mostrado esse valor
	
	RET

; rotina caso não haja resposta até o fim do tempo
semResposta:
	MOV DPTR, #segmentos			; em DPTR fica o valor do endereco dos segmentos
	CLR A							; limpamos o valor de A
		
	MOV A, #6						; A fica com o valor 6, representa -.
	MOVC A, @A+DPTR					; no A fica o endereco onde esta o valor a mostrar no display
	MOV display1, A					; no display e mostrado esse valor
	
	MOV A, #17						; A fica com o valor 17, representa -
	MOVC A, @A+DPTR					; no A fica o endereco onde esta o valor a mostrar no display
	MOV display2, A					; no display e mostrado esse valor
	
	RET

; rotina para mostrar o tempo nos displays
mostraDisplays:
	MOV DPTR, #segmentos			; em DPTR fica o valor do endereco dos segmentos
	CLR A							; limpamos o valor de A
		
	MOV A, R1						; R1 vai ter o valor por exemplo 45, A fica com esse valor
	MOV B, #10						; B fica com o valor 10 guardado
	DIV AB 							; dividimos A por B onde A guarda o valor 4 e B o valor 5 		
	MOVC A, @A+DPTR					; no A fica o endereco onde esta o valor a mostrar no display
	MOV display1, A					; no display e mostrado esse valor
		
	MOV A, B						; guardamos o valor que tinhamos em B no A
	ADD A, #7						; adicionamos 7 para ir buscar o valor correto
	MOVC A, @A+DPTR					; no A fica o endereco onde esta o valor a mostrar no display
	MOV display2, A					; no display e mostrado esse valor
	RET

; onde inicializamos registos com alguns valores
inicializacoes:
	MOV R0, #0						; dá o valor de 0 a R0, quando chega a 10 significa 0,1s
	MOV R1, #MAX					; R1 fica com o valor 50, representa os 5 segundos
	MOV R2, #DECI					; R2 fica com o valor 40ms 
	MOV R3, #SEGS					; R3 fica com o valor 100, para fazer os 1 segundo
	MOV R4, #0						; R4 fica com o valor 0
	MOV R5, #0						; R5 fica com o valor 0
	MOV R6, #0						; R6 fica com o valor 0
	MOV R7, #0						; R7 fica com o valor 0
	RET

; onde são ativadas interrupcoes
ativaInterrupcoes:
	MOV IE, #83H					; ativa as interrupcoes necessarias EA=1, ET1=0, EX1=0, ET0=1 e EX0=1 -> IE=10000011
	SETB IT0						; ativa a interrupcao 0
	SETB EX0						; ativa a excecao 0
	SETB EX1 						; ativa a excecao 1
	RET
	
; configura o timer
confTemp:
	MOV TMOD, #02H 					; definir o timer 0 no modo 2 (8 bit - auto reload)
	MOV TL0, #TempoL				; defenimos o TL
	MOV TH0, #TempoH				; definimos o TH
	RET
	
END