

	.data
	
FAT:		.space  256  # 256 bytes reservados para la Tabla FAT
directorio:	.space  3328 # 256 casillas de 14 bytes (12 para nombre, uno para un caracter null y uno para cluster de inicio)
discoDuro:	.space  1024 # 1024 bytes (1 kb) reservados para el disco 
buffer:		.space  1025 # Espacio reservado para el buffer del input (Maximo 1 Kb + 1)
bufferIO:	.space	1025 # Espacio reservado para el buffer del IO de archivos


error1:		.asciiz "Error: El Disco esta lleno\n"
error2:		.asciiz "Error: El Archivo que desea crear ya existe en el Disco\n"
error3:		.asciiz "Error: El Archivo no existe en el Disco\n"
error4:		.asciiz "Error: Comando invalido\n"

bienvenida:	.asciiz "   Sistema Manejador de Disco Duro (SMD)\n"
prompt:		.asciiz ">> "

textCrear:	.asciiz "crear"
textCopiar:	.asciiz "copiar"
textRenombrar:	.asciiz "ren"
textSizeOf:	.asciiz "sizeof"
textImprimir:	.asciiz "imprimir"
textSalir:	.asciiz "salir"
	
	
	.text

# macro para imprimir un string almacenado en memoria
.macro imprime(%etiqueta)
	li $v0 , 4
	la $a0 , %etiqueta
	syscall
.end_macro

# inicializo la casilla 0 de FAT en 255 ( el total de clusters libres )
		li $t0, 255
		la $t1, FAT
		sw $t0, 0($t1)
		
		imprime(bienvenida)
main:		imprime(prompt)

		jal  input

		add  $s0, $v0, $0	# $s0  almacena el comando recibido por prompt
		add  $s1, $v1, $0	# $s1 almacena el argumento recibido por prompt
	
		add  $a2, $s1, $0			
		
		la   $a1, textCrear
		add  $a0, $s0, $0
		jal  compararString
		beq  $v0, 1, crear  
		
		la   $a1, textImprimir
		add  $a0, $s0, $0
		jal  compararString
		beq  $v0, 1, imprimir  
		
		la   $a1, textCopiar
		add  $a0, $s0, $0
		jal  compararString
		beq  $v0, 1, copiar 
		
		la   $a1, textRenombrar
		add  $a0, $s0, $0
		jal  compararString
		beq  $v0, 1, ren 
		
		la   $a1, textSizeOf
		add  $a0, $s0, $0
		jal  compararString
		beq  $v0, 1, sizeof 
		
		la   $a1, textSalir
		add  $a0, $s0, $0
		jal  compararString
		beq  $v0, 1, salirMain 
		
		imprime(error4)
		b main
		
	
		
salirMain:      li  $v0, 10
		syscall
	

# Funcion que compara dos string, que entran como argumentos a0,a1 
# devuelve en v0, true o false en caso de ser iguales o no
compararString: lb   $t0, 0($a0)
		lb   $t1, 0($a1)
		bne  $t0, $t1, noIguales
		beqz $t0, iguales
		addi $a0, $a0, 1
		addi $a1, $a1, 1
		b    compararString
		
iguales:	li   $v0, 1
		jr   $ra
		
noIguales:	li   $v0, 0
		jr   $ra
		

# Funcion que lee por consola un comando y el string argumento
# y devuelve la direccion de ambos strings en los registros v0,v1 (split)				
input:		la   $v0 , 8
		la   $a0 , buffer
		li   $a1 , 40
		syscall
		
		la   $v0, 0($a0)		
		la   $v1, 0($a0)
		
# Entrada: $v1 ( parametro con la direccion de la palabra )
# Salida: $v1 ( parametro con la direccion de la palabra )	
split:		lb   $t0, 0($v1)
		beq  $t0, 32, salirInput
		beq  $t0, '\n', salirInput
		addi $v1, $v1, 1
		b    split
		
salirInput:	add  $t0, $0, $0
		sb   $t0, 0($v1) 
		addi $v1, $v1, 1
		jr   $ra




# Comandos

# Entrada:
# Salida:	
crear:		move $v1, $s1
		jal split
		li   $v0, 13
		move $a0, $s1
		li   $a1, 0
		li   $a2, 0
		syscall
		
		move $a0, $v0
		li   $v0, 14
		la   $a1, bufferIO
		li   $a2, 1025
		syscall
				
		li $v0, 16
		syscall

		add $t3, $0, $0
		la $t0, bufferIO
		
contandopal:	addi $t0, $t0, 1
		lb $t1, 0($t0)
		beqz $t1, espaciolibre
		addi $t3, $t3, 1
		b contandopal		
		 
espaciolibre:	la $t4, FAT
		lw $t4, 0($t4)
		add $t5, $0, $0
		addi $t5, $t5, 4
		mul $t4, $t4, $t5
		bgt $t4, $t5, 
		b main

imprimir: 	li $v0 4
		la $a0, 0($s1)
		syscall
		b main

copiar:		b main

ren:		b main

#Entrada: $s1 ( nombre del archivo )
#Salida:   ( Unidades de cluster ) y ( Unidades de Bytes ) 
sizeof:		move $v1, $s1
		jal split
		


