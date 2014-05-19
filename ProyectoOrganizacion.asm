

	.data
	
FAT:		.space  256  # 256 bytes reservados para la Tabla FAT
directorio:	.space  3584 # 256 casillas de 14 bytes (13 para nombre y uno para cluster de inicio)
discoDuro:	.space  1024 # 1024 bytes (1 kb) reservados para el disco 
buffer:		.space  1025 # Espacio reservado para el buffer del input (Maximo 1 Kb + 1)
bufferIO:	.space	1025 # Espacio reservado para el buffer del IO de archivos


error1:		.asciiz "Error: El Disco esta lleno\n"
error2:		.asciiz "Error: El Archivo que desea crear ya existe en el Disco\n"
error3:		.asciiz "Error: El Archivo no existe en el Disco\n"
error4:		.asciiz "Error: Comando invalido\n"
error5:		.asciiz "Error: No hay espacio suficiente\n"
error6:		.asciiz "Error: El nombre del archivo es muy largo\n"
error7:		.asciiz "Error: El nombre al que quieres renombrar ya existe \n"

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
		addi $t0, $0, 255
		la $t1, FAT
		sb  $t0, 0($t1)
		
		imprime(bienvenida)
main:		imprime(prompt)

		jal  input
		move $a0, $v0
		
		jal  split
		add  $s0, $v0, $0	# $s0  almacena el comando recibido por prompt
		add  $s1, $v1, $0	# $s1 almacena el argumento recibido por prompt
	
		add  $a2, $s1, $0			
		
		la   $a1, textCrear
		move $a0, $s0
		jal  compararString
		beqz $v0, ifImprimir
		move $a0, $s1		
		jal  crear
		b    main
		
ifImprimir:	la   $a1, textImprimir
		move $a0, $s0
		jal  compararString
		beqz $v0, ifCopiar  
		move $a0, $s1
		jal  imprimir
		b    main
		
ifCopiar:	la   $a1, textCopiar
		move $a0, $s0
		jal  compararString
		beqz $v0, ifRen 
		
ifRen:		la   $a1, textRenombrar
		move $a0, $s0
		jal  compararString
		beqz $v0, ifSizeOf
		jal ren
		b main 
		
ifSizeOf:	la   $a1, textSizeOf
		move  $a0, $s0
		jal  compararString
		beqz $v0, ifSalir 
		
ifSalir:	la   $a1, textSalir
		move $a0, $s0
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
		jr   $ra
		
# Entrada: $a0 ( parametro con la direccion de la palabra )
# Salida: $v0, $v1 ( parametro con la direccion de las palabras )	
split:		move $v0, $a0
		move $v1, $a0
		
loopSplit:      lb   $t0, 0($v1)
		beq  $t0, ' ', salirInput
		beq  $t0, '\n', salirInput
		addi $v1, $v1, 1
		b    loopSplit
		
salirInput:	add  $t0, $0, $0
		sb   $t0, 0($v1) 
		addi $v1, $v1, 1
		jr   $ra



# Entrada: $a0 ( direccion con el nombre del archivo )
# Salida:  nada

# Comandos

# Entrada:
# Salida:	

crear:		addi $sp, $sp, -8
		sw $fp, 8($sp)
		sw $ra, 4($sp)
		addi $fp, $sp, 8
		move $a0, $s1
		jal split
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 8
		
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
		add $t5, $0, $0
		add $t0, $0, $0
		move $t3, $s1
		
tamanonombre:	lb $t5, 0($t3)		# Verifico si el nombre del archivo no excede los 12 caracteres
		beqz $t5, cheqnombre
		addi $t0, $t0, 1
		addi $t3, $t3, 1
		b tamanonombre
		
CError6:	imprime(error6)
		jr $ra
CError2:	imprime(error2)
		jr $ra
		
cheqnombre:	addi $t5, $t5, 12
		bgt $t0, $t5, CError6		


		add $t3, $0, $0		# Chequeo si existe el nombre en el directorio
		add $t5, $0, $0
		addi $t5, $t5, 256
		la $t0, directorio
		move $a1, $s1
		
cheqdirect:	la $a0, 0($t0) 		
		addi $sp, $sp, -12
		sw $fp, 12($sp)
		sw $ra, 8($sp)
		sw $t0, 4($sp)
		addi $fp, $sp, 12
		jal compararString
		lw $t0, -8($fp)
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 12
		addi $t3, $t3, 1
		addi $t0, $t0, 14
		bgtz $v0, CError2
		blt $t3, $t5, cheqdirect
		
		
		add $t3, $0, $0		# Cuento el numero de bytes a guardar
		la $t0, bufferIO
		
contandopal:	addi $t0, $t0, 1
		lb $t1, 0($t0)
		beqz $t1, espaciolibre
		addi $t3, $t3, 1
		b contandopal
		
CError5:	imprime(error5)
		jr $ra
		 
espaciolibre:	beqz $t3, salircrear	# Verifico si hay espacio suficiente
		la $t4, FAT
		lbu  $t4, 0($t4)
		add $t5, $0, $0
		addi $t5, $t5, 4
		mul $t4, $t4, $t5
		bgt $t3, $t4, CError5
		
		
		la $t0, bufferIO
		la $t4, FAT		# El FAT 0, esta reservado para uso del SMD
		la $t5, discoDuro		
		add $t2, $0, $0
		
clusterlibres1:	move $t9, $t4		# Encuentro Clusters libres para almacenar
		addi $t4, $t4, 1			
clusterlibres:	lb $t1, 0($t4)
		beqz $t1, clusterlibre
		addi $t4, $t4, 1	
		b clusterlibres
		
clusterlibre:	bnez $t2, marcandofat	# Calculo la biyeccion entre el indice de FAT y el HDD
clusterlibre1:	la $t6, FAT
		sub $t6, $t4, $t6
		mul $t6, $t6, 4
		add $t6, $t5, $t6
		
		add $t8, $0, $0		# Guardo 4bytes en un cluster
guardando:	lb $t7, 0($t0)
		sb $t7, 0($t6)
		addi $t0, $t0, 1
		addi $t6, $t6, 1
		addi $t2, $t2, 1
		addi $t8, $t8, 1
		beq $t3, $t2, marcandofatf
		beq $t8, 4, clusterlibres1
		b guardando
	
marcandofat:	ble $t2, 4, entradadirect	# Identifico en el cluster de FAT, el proximo cluster de la plabra
marcandofat1:	la $t6, FAT
		sub $t6, $t4, $t6
		sb $t6, 0($t9)
		b clusterlibre1
		
entradadirect:	la $t6,	directorio		# Creo la entrada en el directorio
entradadirect1:	lb $t7, 0($t6)
		beqz $t7, llenardirect
		addi $t6, $t6, 14
		b entradadirect1
		
llenardirect:	addi $sp, $sp, -4
		sw $t6, 4($sp)
		move $t7, $s1
llenardirect1:	lb $t8, 0($t7)
		beqz $t8, llenardirect2
		sb $t8, 0($t6)
		addi $t7,$t7, 1
		addi $t6, $t6, 1
		b llenardirect1
		
llenardirect2:	lw $t7, 4($sp)
		addi $sp, $sp, 4
		addi $t7, $t7, 13
		la $t6, FAT
		sub $t6, $t4, $t6
		sb $t6, 0($t7)
		b marcandofat1
		
		
marcandofatf:	subi $t6, $0, 1		# Marco -1 en el cluster en FAT para el ultimo cluster usado.
		sb $t6, 0($t4)
				    
salircrear:	jr   $ra


# Entrada: $a0 ( direccion con el nombre del archivo )
# Salida:  nada
imprimir: 	li   $t0, 0
		la   $t1, directorio

		# En loopExisteImp:		
		# $t0 iterador
		# $t1 direccion del directorio
		# $a0 direccion con nombre del archivo
		
loopExisteImp:	jal  compararString
		beq  $v0, 1 , existeImpri
		beq  $t0, 255, noExisteImpri
		addi $t1, $t1, 14			# flag
		addi $t0, $t0, 1
		b loopExisteImp

existeImpri:    la   $t0 bufferIO
		addi $t1, $t1, 13 			# flag
		
		# En loopImpri:
		# $t0 variable para moverse y escribir el bufferIO
		# $t1 direccion con la FAT
		# $t2 direccion del disco duro
		# $t3 variable para moverse en el Disco y la FAT
		
loopImpri:	la   $t2 discoDuro	
		lb   $t3, 0($t1)
		la   $t1, FAT
		add  $t1, $t1, $t3
		lb   $t3, 0($t1) 
		beqz $t3, salirImpri
		sll  $t3, $t3, 2
		add  $t2, $t2, $t3
		lw   $t3, 0($t2)
		sw   $t3, 0($t0)
		addi $t0, $t0, 4
		b loopImpri

salirImpri:	imprime(bufferIO)
		jr $ra		

noExisteImpri:  imprime(error3)
		jr   $ra




# Entrada: 
# Salida: 
copiar:		b main


# Entrada: 
# Salida: 
ren:		move $a0, $s1		# Divide los dos nombres de archivo en s1
		addi $sp, $sp, -8
		sw $fp, 8($sp)
		sw $ra, 4($sp)
		addi $fp, $sp, 8
		jal split
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 8
		move $t8, $v0
		move $t9, $v1
		
		move $a0, $t9		# Elimino el salto de linea al final del argumento
		addi $sp, $sp, -8	
		sw $fp, 8($sp)
		sw $ra, 4($sp)
		addi $fp, $sp, 8
		jal split
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 8
		
		la $t0, directorio
		addi $t5, $0, 256
		move $a1, $t9
		add $t3, $0, $0
		
cheqdirect1:	la $a0, 0($t0)		# Chequeo si el nombre a renombrar, exista en el directorio
		addi $sp, $sp, -12
		sw $fp, 12($sp)
		sw $ra, 8($sp)
		sw $t0, 4($sp)
		addi $fp, $sp, 12
		jal compararString
		lw $t0, -8($fp)
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 12
		bgtz $v0, renError7
		addi $t3, $t3, 1
		addi $t0, $t0, 14
		blt $t3, $t5, cheqdirect1
		
		add $t2, $0, $0
		move $t0, $t9		# verifico si el nombre a cambiar tiene 12 chars o menos
rencuentachar:	lb $t1, 0($t0)
		beqz $t1, verificanum
		addi $t0, $t0, 1
		addi $t2, $t2, 1
		b rencuentachar
		
renError7:	imprime(error7)
		jr $ra

renError6:	imprime(error6)
		jr $ra
					
verificanum:	bge $t2, 13, renError6		
		
		la $t0, directorio
		addi $t5, $0, 256
		move $a1, $t8
		add $t3, $0, $0
		
cheqdirect2:	la $a0, 0($t0) 		# Busco el archivo en el directorio
		addi $sp, $sp, -16
		sw $fp, 16($sp)
		sw $ra, 12($sp)
		sw $t0, 8($sp)
		sw $a1, 4($sp)
		addi $fp, $sp, 16
		jal compararString
		lw $a1, -12($fp)
		lw $t0, -8($fp)
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 12
		move $t7, $t0
		bgtz $v0, limpionombre
		addi $t3, $t3, 1
		addi $t0, $t0, 14
		beq  $t3, $t5, renError3
		b cheqdirect2

renError3:	imprime(error3)		
		
limpionombre:	add $t6, $0, $0
		sb $t6, 0($t0)
		addi $t0, $t0, 1
		lb $t5, 0($t0)
		beqz $t5, renombro
		b limpionombre
		
renombro:	lb $t6, 0($t9)
		beqz $t6, rensalir
		sb $t6, 0($t7)
		addi $t9, $t9, 1
		addi $t7, $t7, 1
		b renombro
		
rensalir:	jr $ra	
	
			
		
		
		
		
		


#Entrada: $s1 ( nombre del archivo )
#Salida:   ( Unidades de cluster ) y ( Unidades de Bytes ) 
sizeof:		move $v1, $s1
		jal split
		


