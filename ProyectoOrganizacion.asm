

	.data
.align 2	
FAT:		.space  256  # 256 bytes reservados para la Tabla FAT
.align 2
directorio:	.space  3584 # 256 casillas de 14 bytes (13 para nombre y uno para cluster de inicio)
.align 2
discoDuro:	.space  1024 # 1024 bytes (1 kb) reservados para el disco 
.align 2
buffer:		.space  60   # Espacio reservado para el buffer del input (Maximo 1 Kb + 1)
.align 2
bufferIO:	.space	1025 # Espacio reservado para el buffer del IO de archivos

error1:		.asciiz "Error: No hay espacio suficiente\n"
error2:		.asciiz "Error: El Archivo que desea crear ya existe en el Disco\n"
error3:		.asciiz "Error: El Archivo no existe en el Disco\n"
error4:		.asciiz "Error: Comando invalido\n"	
error5:		.asciiz "Error: El nombre del archivo es muy largo\n"
error6:		.asciiz "Error: El nombre al que quieres renombrar ya existe \n"
sizeofbytes:	.asciiz "\n Total de bytes: "
sizeofclusters:	.asciiz "\n Total de clusters: "
salto:		.asciiz "\n"
NombArchivo:	.asciiz "El nombre del archivo es:" 
bienvenida:	.asciiz "   Sistema Manejador de Disco Duro (SMD)\n"
prompt:		.asciiz ">> "
textCrear:	.asciiz "crear"
textCopiar:	.asciiz "copiar"
textRenombrar:	.asciiz "ren"
textSizeOf:	.asciiz "sizeof"
textImprimir:	.asciiz "imprimir"
textBuscar:	.asciiz "buscar"
textDir:	.asciiz "dir"
textSalir:	.asciiz "salir"	
	
	.text
# macro para imprimir un string almacenado en memoria
.macro imprime(%etiqueta)
	li $v0 , 4
	la $a0 , %etiqueta
	syscall
.end_macro

# inicializo la casilla 0 de FAT en 255 ( el total de clusters libres )
		addi $t0, $0, 254
		la $t1, FAT
		sb  $t0, 0($t1)

		
		imprime(bienvenida)
main:		imprime(prompt)

		
		la   $s0, buffer
		li   $s1, 0 
		move $s2, $0
limpiarBuffer:  sb   $s2, 0($s0)
		addi $s1, $s1, 1
		addi $s0, $s0, 1
		bne  $s1, 60, limpiarBuffer


		la   $s0, bufferIO
		li   $s1, 0 
		move $s2, $0

		jal  input
		move $a0, $v0
		
		jal  split
		add  $s0, $v0, $0	# $s0  almacena el comando recibido por prompt
		add  $s1, $v1, $0	# $s1 almacena el argumento recibido por prompt			
		
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
		move $a1, $s1 
		jal  copiar
		b    main 
		
ifRen:		la   $a1, textRenombrar
		move $a0, $s0
		jal  compararString
		beqz $v0, ifSizeOf
		move $a0, $s1
		jal  ren
		b    main 
		
ifSizeOf:	la    $a1, textSizeOf
		move  $a0, $s0
		jal   compararString
		beqz  $v0, ifBuscar
		li    $a2, 0
		move  $a0, $s1
		jal   sizeof
		b     main 

ifBuscar:	la    $a1, textBuscar
		move  $a0, $s0
		jal   compararString
		beqz  $v0, ifDir
		move  $a0, $s1
		jal   buscar
		move  $s1, $v0
		imprime(NombArchivo)
		li    $v0 , 4
		move  $a0 , $s1
		syscall
		move  $v0, $s1
		b     main 

ifDir:		la   $a1, textDir
		move $a0, $s0
		jal  compararString
		beqz $v0, ifSalir
		jal  dir
		b    main
		
		
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
		beqz $t0, salirInput
		addi $v1, $v1, 1
		b    loopSplit
		
salirInput:	add  $t0, $0, $0
		sb   $t0, 0($v1) 
		addi $v1, $v1, 1
		jr   $ra



# Entrada: $a0 ( direccion con el nombre del archivo )
# Salida:  nada

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

CError5:	imprime(error5)
		jr $ra
CError2:	imprime(error2)
		jr $ra

cheqnombre:	addi $t5, $t5, 12
		bgt $t0, $t5, CError5		


		add $t3, $0, $0		# Chequeo si existe el nombre en el directorio
		add $t5, $0, $0
		addi $t5, $t5, 256
		la $t0, directorio

		
		
cheqdirect:	move $a1, $s1
		la $a0, 0($t0) 		

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

contandopal:	lb $t1, 0($t0)
		beqz $t1, espaciolibre
		addi $t0, $t0, 1
		addi $t3, $t3, 1
		b contandopal

CError1:	imprime(error1)
		jr $ra

espaciolibre:	beqz $t3, salircrear	# Verifico si hay espacio suficiente
		la $t4, FAT
		lbu  $t4, 0($t4)
		add $t5, $0, $0
		addi $t5, $t5, 4
		mul $t4, $t4, $t5
		bgt $t3, $t4, CError1


		la $t0, bufferIO
		la $t4, FAT		# El FAT 0, esta reservado para uso del SMD
		la $t5, discoDuro		
		add $t2, $0, $0
		addi $t4, $t4, 1
		b clusterlibres


clusterlibres1:	move $t9, $t4		# Encuentro Clusters libres para almacenar
		addi $t4, $t4, 1			
clusterlibres:	lbu $t1, 0($t4)
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
		sub $t6, $t9, $t6
		sb $t6, 0($t7)
		b marcandofat1


marcandofatf:	add $t6, $0, 255		# Marco -1 en el cluster en FAT para el ultimo cluster usado.
		sb $t6, 0($t4)
		li $t0, 4
		div  $t3, $t0
		mflo $t3
		mfhi $t2
		beqz $t2, descuentlibre
		addi $t3, $t3, 1

descuentlibre:	la $t2, FAT
		lbu $t0, 0($t2)
		sub $t0, $t0, $t3
		sb $t0, 0($t2)

salircrear:	jr   $ra



# Entrada: $a0 ( direccion con el nombre del archivo )
# Salida:  nada
imprimir: 	li   $t0, 0
		la   $t1, directorio

		# En loopExisteImp:		
		# $t0 iterador
		# $t1 direccion del directorio
		# $a0 direccion con nombre del archivo
		
loopExisteImp:	addi $sp, $sp, -16
		sw   $ra, 4($sp)
		sw   $t0, 8($sp)
		sw   $t1, 12($sp)
		sw   $a0, 16($sp)
		move $a1, $t1
		jal  split
		move $a0, $v0
		jal  compararString
		lw   $ra, 4($sp)
		lw   $t0, 8($sp)
		lw   $t1, 12($sp)
		lw   $a0, 16($sp)
		addi $sp, $sp, 16
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
		lb   $t3, 0($t1)
		sll  $t3, $t3, 2
		la   $t2, discoDuro
		add  $t2, $t2, $t3
		lw   $t3, 0($t2)
		sw   $t3, 0($t0) 
		addi $t0, $t0, 4 
loopImpri:	la   $t2 discoDuro	
		lbu  $t3, 0($t1)
		la   $t1, FAT
		add  $t1, $t1, $t3
		lbu  $t3, 0($t1) 
		beq  $t3, '\n', salirImpri
		beqz $t3, salirImpri
		sll  $t3, $t3, 2
		add  $t2, $t2, $t3
		lw   $t3, 0($t2)
		sw   $t3, 0($t0)
		addi $t0, $t0, 4
		b loopImpri

salirImpri:	imprime(bufferIO)
		imprime(salto)
		jr $ra		

noExisteImpri:  imprime(error3)
		jr   $ra




# Entrada: $a0 ( archivo fuente ) $a1 (archivo destino )
# Salida: 
copiar:		move $a0, $a1		
		addi $sp, $sp, -8
		sw $fp, 8($sp)
		sw $ra, 4($sp)
		addi $fp, $sp, 8
		jal split
		lw $ra -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 8
		move $t8, $v0
		move $t9, $v1
		
		move $a0, $t9		# Elimino el Salto de linea al final del argumento
		addiu $sp, $sp, -8
		sw $fp, 8($sp)
		sw $ra, 4($sp)
		addi $fp, $sp, 8
		jal split
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 8
		
		
		la $t0, directorio	# Verifico si el archivo fuente existe en el directorio
		add $t1, $0, $0
		add $t2, $0, 254
		
cheqdirect4:	move $a0, $t8
		move $a1, $t0
		addi $sp, $sp, -16
		sw $fp, 16($sp)
		sw $ra, 12($sp)
		sw $t0, 8($sp)
		sw $t1, 4($sp)
		addi $fp, $sp, 16
		jal compararString
		lw $t1, -12($fp)
		lw $t0, -8($fp)
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		bgtz $v0, cheqdirect5
		addiu $sp, $sp, 16
		addi $t1, $t1, 1
		addi $t0, $t0, 14
		blt $t1, $t2, cheqdirect4
		b copiarError3
		
copiarError3:	imprime(error3)
		jr $ra
		
cheqdirect5:	move $t6, $t0
		addi $sp, $sp, -4
		sw $t6, 4($sp)
		la $t0, directorio		# Verifico si el archivo destino existe en el directorio
		add $t1, $0, $0
		addi $t2, $0, 254
		
cheqdirect5.1:	move $a0, $t9
		move $a1, $t0
		addi $sp, $sp, -16
		sw $fp, 16($sp)
		sw $ra,	12($sp)
		sw $t0, 8($sp)
		sw $t1, 4($sp)
		addi $fp, $sp, 16
		jal compararString
		lw $t1, -12($fp)
		lw $t0, -8($fp)
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 16
		bgtz $v0, tamfuente1
		addi $t1, $t1, 1
		addi $t0, $t0, 14
		blt $t1, $t2, cheqdirect5.1
		b copiarError3
		
tamfuente1:	move $t7, $t0		# Determino el tamano de clusters de la fuente
		move $t5, $t0
		lb $t1, 13($t6)
		add $t6, $0, $0
		addi $sp, $sp, -4
		sw $t1, 4($sp)
tamfuente1.1:	la $t0, FAT
		add $t0, $t0, $t1
		mul $t1, $t1, 4
		la $t2, discoDuro
		add $t2, $t1, $t2
		add $t3, $0, $0
		
tamfuente1.2:	lb $t4, 0($t2)
		beqz $t4, tamfuente2
		addi $t3, $t3, 1
		addi $t6, $t6, 1
		addi $t2, $t2, 1
		blt $t3, 4, tamfuente1.2
		lbu $t1, 0($t0)
		beq $t1, 255, tamfuente2
		beq $t3, 4, tamfuente1.1
		
tamfuente2:	lbu $t1, 13($t7)	# Determino el tamano de clusters del destino 
		add $t7, $0, $0
		addi $sp, $sp, -4
		sw $t1, 4($sp)
tamfuente2.1:	la $t0, FAT
		add $t0, $t0, $t1
		mul $t1, $t1, 4
		la $t2, discoDuro
		add $t2, $t1, $t2
		add $t3, $0, $0
		
tamfuente2.2:	lb $t4, 0($t2)
		beqz $t4, vercapacidad
		addi $t3, $t3, 1
		addi $t7, $t7, 1
		addi $t2, $t2, 1
		blt $t3, 4, tamfuente2.2
		lbu $t1, 0($t0)
		beq $t1, 255, vercapacidad
		beq $t3, 4, tamfuente2.1
		
vercapacidad:	sub $t0, $t7, $t6		# Calculo la diferencia de bytes que posee un archivo del otro
		bltz $t0, cheqespacio
		bgtz $t0, borrarcluster
		b llenabufferIO
		
	
cheqespacio:	la $t1, FAT			# Verifica si hay espacio suficiente para copiar
		lbu $t1, 0($t1)
		mul $t1, $t1, 4
		mul $t0, $t0, -1
		ble $t0, $t1, llenabufferIO
		b copiarError1
		
copiarError1:	imprime(error1)
		jr $ra
		
borrarcluster:	div $t0, $t6, 4			# Determina los clusters sobrantes del archivo destino
		mfhi $t2
		sgt $t2, $t2, 0
		add $t0, $t0, $t2
		div $t1, $t7, 4
		mfhi $t2
		sgt $t2, $t2, 0
		add $t1, $t1, $t2
		sub $t0, $t1, $t0
		sub $t1, $t1, $t0
		
		lw $t2, 4($sp)
borrarcluster1:	la $t3, FAT			# ubica los cluster sobrantes a borrar del archivo destino
		add $t3, $t3, $t2
		sw $t3, 0($sp)
		lbu $t2, 0($t3)
		subi $t1, $t1, 1
		bgtz $t1, borrarcluster1
		
borrarcluster2:	la $t3, FAT			# Limpia la tabla FAT de los cluster sobrantes del archivo destino
		la $t4, discoDuro
		add $t3, $t3, $t2
		mul $t2, $t2, 4
		add $t4, $t4, $t2
		sb $0, 0($t4)			# Limpio el cluster en el discoduro
		sb $0, 1($t4)
		sb $0, 2($t4)
		sb $0, 3($t4)
		lbu $t2, 0($t3)
		sb $0, 0($t3)
		subi $t0, $t0, 1
		bgtz $t0, borrarcluster2
		
		
llenabufferIO:	lw $t3, 8($sp)			# Llena bufferIO con la informacion del cluster fuente
		add $t4, $0, $0
		la $t1, bufferIO
llenabufferIO1:	la $t0, FAT
		la $t2, discoDuro
		add $t0, $t0, $t3
		mul $t3, $t3, 4
		add $t2, $t2, $t3
		
		add $t3, $0, $0
llenabufferIO2:	lb $t5, 0($t2)
		sb $t5, 0($t1)
		addi $t1, $t1, 1
		addi $t2, $t2, 1
		addi $t3, $t3, 1
		addi $t4, $t4, 1
		beq $t4, $t6, sobreescribir
		blt $t3, 4 llenabufferIO2
		lbu $t3, 0($t0)
		b llenabufferIO1
		
sobreescribir:	add $s7, $0, $0			# Empezamos a copiar los datos del buffer en el archivo destino
		lw $t3, 4($sp)
		la $t2, bufferIO
sobreescribir1:	la $t0, FAT
		la $t1, discoDuro
		add $t0, $t0, $t3
		mul $t3, $t3, 4
		add $t1, $t1, $t3
		
		add $t3, $0, $0
sobreescribir2:	lb $t5, 0($t2)
		sb $t5, 0($t1)
		subi $t4, $t4, 1
		addi $s7, $s7, 1
		addi $t2, $t2, 1
		addi $t3, $t3, 1
		addi $t1, $t1, 1
		beqz $t4, llamarcrear
		beq $s7, $t7, llamarcrear
		blt $t3, 4, sobreescribir2
		lbu $t3, 0($t0)
		b sobreescribir1
		
llamarcrear:	beqz $t4, salircopiar
		sw $t4, -4($sp)
		move $t0, $t2
		la $t4, FAT		# El FAT 0, esta reservado para uso del SMD
		la $t5, discoDuro		
		add $t2, $0, $0
		addi $t4, $t4, 1

						
cluslibre:	lbu $t1, 0($t4)		# Encuentro Clusters libres para almacenar
		beqz $t1, cluslibre1
		addi $t4, $t4, 1	
		b cluslibre
		
cluslibre1:	lw $t3, 0($sp)
		la $s7, FAT
		sub $s7, $t4, $s7
		sb $s7, 0($t3)
		lw $t3, -4($sp)
		j clusterlibre
		

salircopiar:	jr $ra
			


# Entrada: $a0 (nombre del archivo a renombrar) $a1 (nuevo nombre del archivo
# Salida: nada
ren:		addi $sp, $sp, -8
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
		addi $t5, $0, 255
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
		bgtz $v0, renError6
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
		
renError6:	imprime(error6)
		jr $ra

renError5:	imprime(error5)
		jr $ra
					
verificanum:	bge $t2, 13, renError5		
		
		la $t0, directorio
		addi $t5, $0, 255
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
	
			
		

# Entrada: $a0 ( Direccion con el nombre del string a buscar)
# Salida: $v0 ( Nombre del archivo que contiene el string buscado)	
		
buscar:		move $t1, $a0

loopSplit2:     lb   $t0, 0($t1)
		beq  $t0, '\0', salirSplit2
		beq  $t0, '\n', salirSplit2
		addi $t1, $t1, 1
		b    loopSplit2
		
salirSplit2:	add  $t0, $0, $0
		sb   $t0, 0($t1)	
		
		# $t0 directorio
		# $t1 string
		# $t2 disco duro
		# $t3 FAT
		# $t4 auxiliar
		# $t5 iterador
		# $t6 iterador
		
		li   $t6, 0
		
loopBuscarDir:	la   $t0, directorio
		li   $t1, 14
		mul  $t1, $t1, $t6 
		add  $t0, $t0, $t1
		addi $t0, $t0, 13
		move $t1, $a0
		lb   $t4, 0($t0)


loopBuscarFAT:	la   $t2, discoDuro
		sll  $t4, $t4, 2
		add  $t2, $t2, $t4 
		li   $t5, 0

loopComparar:   lb   $t4, 0($t2)
		lb   $t7, 0($t1)
		bne  $t4, $t7, salirLoop
		addi $t5, $t5, 1
		addi $t2, $t2, 1
		addi $t1, $t1, 1
		bne  $t5, 4, loopComparar
		
		la  $t0, FAT
		add $t0, $t0, $t4
		lbu $t4, 0($t0)
		beq $t4, $0, retornarBuscar
		b loopBuscarFAT

salirLoop:	addi $t6, $t6, 1
		blt  $t6, 256, loopBuscarDir      
		li   $v0, -1
		jr   $ra
		
retornarBuscar:	li   $t0, 14
		mul  $t6, $t0, $t6
		la   $v0, directorio
		add  $v0, $v0, $t6
		jr   $ra				
		
		


#Entrada: $a0 ( nombre del archivo )
#Salida:  nada

sizeof:		move $t9, $a0		# Elimino el salto de linea al final del argumento
		addi $sp, $sp, -8
		sw $fp, 8($sp)
		sw $ra, 4($sp)
		addi $fp, $sp, 8
		jal split
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 8
		
		add $t0, $0, $0		# Chequeo si el archivo existe
		la $t1, directorio
		add $t2, $0, $0
		addi $t3, $0, 255
		move $a1, $t9
		
cheqdirect3:	la $a0, 0($t1)
		addi $sp, $sp, -20
		sw $fp, 20($sp)
		sw $ra, 16($sp)
		sw $a1, 12($sp)
		sw $t0, 8($sp)
		sw $t1, 4($sp)
		addi $fp, $sp, 20
		jal compararString
		lw $t1, -16($fp)
		lw $t0, -12($fp)
		lw $a1, -8($fp)
		lw $ra, -4($fp)
		lw $fp, 0($fp)
		addiu $sp, $sp, 20
		move $t0, $t1
		bgtz $v0, calculator
		addi $t2, $t2, 1
		addi $t1, $t1, 14
		beq $t2, $t3, sizeofError3
		b cheqdirect3
		
sizeofError3:	imprime(error3)
		jr $ra
		
calculator:	add $t6, $0, $0
		lbu $t1, 13($t0)	# Realizo la biyeccion del FAT al DiscoDuro
calculator1:	la $t0, FAT
		la $t3,	discoDuro
		add $t0, $t0, $t1
		mul $t2, $t1, 4
		add $t3, $t3, $t2
		
		
		add $t4, $0, $0
cuentacluster:	lb $t5, 0($t3)			# Cuenta byte a byte las palabras almacenadas en el discoduro
		beqz $t5, imprimirsizeof
		addi $t4, $t4, 1
		addi $t6, $t6, 1
		addi $t3, $t3, 1
		blt $t4, 4, cuentacluster
		lbu $t1, 0($t0)
		beq $t1, 255, imprimirsizeof
		b calculator1
		
imprimirsizeof:	li $v0, 4
		la $a0, sizeofbytes
		syscall
		 
		li $v0, 1
		move $a0, $t6
		syscall
		li $t0, 4
		div $t6, $t0
		mflo $t6
		mfhi $t0
		beqz $t0, impcluster
		addi $t6, $t6, 1
		
impcluster:	beq $a2, 1, sizeofsalir
		li $v0, 4
		la $a0, sizeofclusters
		syscall
		
		li $v0, 1
		move $a0, $t6
		syscall

		
		li $v0, 4
		la $a0, salto
		syscall
		
sizeofsalir:	jr $ra
		

#Entrada: nada
#Salida: nada
		
dir:		li   $t0, 0
		la   $t1, directorio
		move $t2, $a0
		
loopDir:	lb   $a0, 0($t1)
		beqz $a0, siguiente
		la   $a0, 0($t1)
		li   $v0, 4
		syscall	
		addi $sp, $sp, -12
		sw   $t0, 4($sp)	
		sw   $t1, 8($sp)
		sw   $ra, 12($sp)
		li   $a2, 1
		jal  sizeof
		lw   $t0, 4($sp)	
		lw   $t1, 8($sp)
		lw   $ra, 12($sp)
		addi $sp, $sp, 12
		imprime(salto)
		imprime (salto)
		
siguiente:	addi $t1, $t1, 14
		addi $t0, $t0, 1
		beq  $t0, 255, salir
		b loopDir
		
salir:		jr $ra	
		
		
		


