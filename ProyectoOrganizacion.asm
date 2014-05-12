

	.data
	
FAT:		.space  512  # 256 bytes reservados para la Tabla FAT
Directorio:	.space  256  # 512 casillas de 2 bytes (nombre y cluster de inicio) reservados para el Directorio 
DiscoDuro:	.space  1024 # 1024 bytes (1 kb) reservados para el disco 

Error1:		.asciiz "Error: El Disco esta lleno\n"
Error2:		.asciiz "Error: El Archivo que desea crear ya existe en el Disco\n"
Error3:		.asciiz "Error: El Archivo no existe en el Disco\n"

Bienvenida:	.asciiz "   Sistema Manejador de Disco Duro (SMD)\n"
Prompt:		.asciiz ">> "

	.text

# macro para imprimir un string almacenado en memoria
.macro imprime(%etiqueta)
	li $v0 , 4
	la $a0 , %etiqueta
	syscall
.end_macro



	imprime(Bienvenida)
loop:	imprime(Prompt)
	#
	# Reconocer funcion
	#
	
crear:

imprimir:

copiar:

ren:

sizeof:


