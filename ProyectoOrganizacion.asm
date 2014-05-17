

	.data
	
FAT:		.space  256  # 256 bytes reservados para la Tabla FAT
Directorio:	.space  2304 # 256 casillas de 9 bytes (8 para nombre y uno para cluster de inicio)
DiscoDuro:	.space  1024 # 1024 bytes (1 kb) reservados para el disco 
Buffer:		.space  1025 # Espacio reservado para el buffer del input (Maximo 1 Kb + 1)


Error1:		.asciiz "Error: El Disco esta lleno\n"
Error2:		.asciiz "Error: El Archivo que desea crear ya existe en el Disco\n"
Error3:		.asciiz "Error: El Archivo no existe en el Disco\n"

Bienvenida:	.asciiz "   Sistema Manejador de Disco Duro (SMD)\n"
Prompt:		.asciiz ">> "

text:		.asciiz "imprimir"
	.text

# macro para imprimir un string almacenado en memoria
.macro imprime(%etiqueta)
	li $v0 , 4
	la $a0 , %etiqueta
	syscall
.end_macro



		imprime(Bienvenida)
Main:		imprime(Prompt)

		jal  input
		
		add  $s0, $v0, $0
		add  $s1, $v1, $0
		
		add  $a0, $v0, $0
		la   $a1, text
		add  $a2, $v1, $0
		jal  compararString
		beqz $v0, salirMain 
		jal  imprimir
		
	
		
salirMain:      li  $v0, 10
		syscall
	



# Funcion que compara dos string, que entran como argumentos a0,a1 
# devuelve true o false en caso de ser iguales o no
compararString: lb   $t0, 0($a0)
		lb   $t1, 0($a1)
		bne  $t0, $t1, noIguales
		beq  $t0, '\0', iguales
		addi $a0, $a0, 1
		addi $a1, $a1, 1
		j    compararString
iguales:	addi $v0, $0, 1
		jr   $ra
noIguales:	add  $v0, $0, $0
		jr   $ra
		

# Funcion que lee por consola un comando y el string argumento
# y devuelve la direccion de ambos strings en los registros v0,v1 (split)				
input:		la   $v0 , 8
		la   $a0 , Buffer
		li   $a1 , 40
		syscall
		
		la   $v0, 0($a0)		
		la   $v1, 0($a0)
split:		lb   $t0, 0($v1)
		beq  $t0, 32, salirInput
		addi $v1, $v1, 1
		b    split
salirInput:	add  $t0, $0, $0
		sb   $t0, 0($v1) 
		addi $v1, $v1, 1
		jr   $ra




# Comandos
crear:

imprimir:	li $v0, 4
		la $a0, 0($s1)
		syscall
		
		jr $ra
		

copiar:

ren:

sizeof:


