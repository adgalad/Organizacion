	.kdata

		__m1_:	.asciiz "  Exception "
		__m2_:	.asciiz " occurred and ignored\n"
		__e0_:	.asciiz "  [Interrupt] "
		__e1_:	.asciiz	"  [TLB]"
		__e2_:	.asciiz	"  [TLB]"
		__e3_:	.asciiz	"  [TLB]"
		__e4_:	.asciiz	"  [Address error in inst/data fetch] "
		__e5_:	.asciiz	"  [Address error in store] "
		__e6_:	.asciiz	"  [Bad instruction address] "
		__e7_:	.asciiz	"  [Bad data address] "
		__e8_:	.asciiz	"  [Error in syscall] "
		__e9_:	.asciiz	"  [Breakpoint] "
		__e10_:	.asciiz	"  [Reserved instruction] "
		__e11_:	.asciiz	""
		__e12_:	.asciiz	"  [Arithmetic overflow] "
		__e13_:	.asciiz	"  [Trap] "
		__e14_:	.asciiz	""
		__e15_:	.asciiz	"  [Floating point] "
		__e16_:	.asciiz	""
		__e17_:	.asciiz	""
		__e18_:	.asciiz	"  [Coproc 2]"
		__e19_:	.asciiz	""
		__e20_:	.asciiz	""
		__e21_:	.asciiz	""
		__e22_:	.asciiz	"  [MDMX]"
		__e23_:	.asciiz	"  [Watch]"
		__e24_:	.asciiz	"  [Machine check]"
		__e25_:	.asciiz	""
		__e26_:	.asciiz	""
		__e27_:	.asciiz	""
		__e28_:	.asciiz	""
		__e29_:	.asciiz	""
		__e30_:	.asciiz	"  [Cache]"
		__e31_:	.asciiz	""
		__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
				.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
				.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
				.word __e28_, __e29_, __e30_, __e31_
s1:				.word 0
s2:				.word 0
s3:				.word 0

				.align	2	
InputBuffer:	.space	10			# Donde se almacena el password recibido
				.align	2
BufferSize:		.word	10			# Tamano maximo del buffer de entrada, expresado en bytes
				.align 	2
Password:		.asciiz	"holavale\n"	# Clave que desbloquea el computador
				.align	2
InputSize:		.word 	0			# Contiene la tamano real del InputBuffer
				.align	2
BufferPtr:		.word	0			# Apunta a la primera posicion del InputBuffer

teclado_c:		.word	0xffff0000
teclado_d:		.word	0xffff0004

bloqueando:		.asciiz "Bloqueando pantalla \n"

	.ktext 0x80000180
	
	#####################################################
# Save $at, $v0, and $a0
#
	.set noat
	move $k1, $at            # Save $at
	.set at

	sw $v0, s1               # Not re-entrant and we can't trust $sp
	sw $a0, s2               # But we need to use these registers
	sw $ra,	s3
	
	
#####################################################
# Determino si es una exception especial ( Syscall 100 o interrupcion ).
#

		mfc0 	$k0, 	$13
		srl		$a0,	$k0,	2
		andi	$a0,	0xf
		lw		$t0,	s1
		beq		$a0,	$0,		inter
		beq		$t0,	100,	ini
		b trapH
				
ini:	
		li		$t0,	1					# inicializo el estado del screensaver
		sw		$t0,	LockFlag
		lw		$t0,	teclado_c
		lw		$t1,	0($t0)
		ori		$t1,	0x2					# activar interrupcion de teclado
		sw 		$t1,	0($t0)
		la		$t0,	InputSize
		sw		$0,		0($t0)				# Inicializo InputSize en 0
		la		$t0,	BufferPtr
		la 		$t1,	InputBuffer			
		sw		$t1,	0($t0)				# BufferPtr apunta a InputBuffer
		
		li		$v0,	4
		la		$a0,	bloqueando
		syscall
		
		b ret
	

# Funcion que compara dos string, que entran como argumentos a0,a1 
# devuelve en v0, true o false en caso de ser iguales o no
compararString: lb   $t0, 0($a0)
				lb   $t1, 0($a1)
				bne  $t0, $t1, noIguales
				beqz $t0, iguales
				addi $a0, $a0, 1
				addi $a1, $a1, 1
				b    compararString
		
iguales:		li   $v0, 0
				jr   $ra
		
noIguales:		li   $v0, 1
				jr   $ra
		
#####################################################
		
		
inter:	lw 		$t0, 	teclado_d
		lb 		$t1, 	0($t0)
		lw		$t2,	BufferPtr
		sb		$t1,	0($t2)				# Guardo la tecla presionada en el InputBuffer
		lw		$t3,	InputSize
		addi	$t3,	$t3,	1
		sw		$t3,	InputSize			# Aumento el contador
		addi 	$t2,	$t2,	0x1			
		sw		$t2,	BufferPtr			# BufferPtr apunta a la siguiente direccion
		
		beq		$t1,	10,		cheq		# El caracter introducido es un salto de linea
		beq		$t3,	10,		cheq		# Ya se llego al limite de caracteres introducidos
		
		eret
		
cheq:	li		$s0,	0
		la		$a0,	InputBuffer
		la		$a1,	Password
		jal 	compararString
		lw		$ra,	s3
		sb		$v0,	LockFlag					
		
		
		
		
		
		eret
	


#####################################################
# Print information about exception
#
trapH:	li 		$v0, 	4                	# syscall 4 (print_str)
		la 		$a0, 	__m1_
		syscall

		li 		$v0, 	1                	# syscall 1 (print_int)
		mfc0 	$k0, 	$13            		# Get Cause register
		srl 	$a0, 	$k0, 	2           # Extract ExcCode Field
		andi 	$a0, 	$a0, 	0xf
		syscall
	
		li 		$v0, 	4                	# syscall 4 (print_str)
		andi 	$a0, 	$k0, 	0x3c
		lw 		$a0, 	__excp($a0)      	# $a0 has the index into
	                        				# the __excp array (exception
	                        				# number * 4)
		nop 
		syscall

#####################################################
# Bad PC exception requires special checks
#
	bne $k0, 0x18 ok_pc
	nop

	mfc0 $a0, $14            # EPC
	andi $a0, $a0, 0x3        # Is EPC word-aligned?
	beq $a0, 0, ok_pc
	nop

	li $v0, 10               # Exit on really bad PC
	syscall

#####################################################
#  PC is alright to continue
#
ok_pc:

	li $v0, 4                # syscall 4 (print_str)
	la $a0, __m2_            # "occurred and ignored" message
	syscall

	srl $a0, $k0, 2           # Extract ExcCode Field
	andi $a0, $a0, 0xf
	bne $a0, 0, ret           # 0 means exception was an interrupt
	
#####################################################
# Return from (non-interrupt) exception. Skip offending
# instruction at EPC to avoid infinite loop.
#
ret:

	mfc0 $k0, $14            # Get EPC register value
	addiu $k0, $k0, 4         # Skip faulting instruction by skipping
	                        # forward by one instruction
                          # (Need to handle delayed branch case here)
	mtc0 $k0, $14            # Reset the EPC register


#####################################################
# Restore registers and reset procesor state
#
	lw $v0, s1               # Restore $v0 and $a0
	lw $a0, s2
	sw $0,	s1
	sw $0,	s2

	.set noat
	move $at, $k1            # Restore $at
	.set at

	mtc0 $0, $13             # Clear Cause register

	mfc0 $k0, $12            # Set Status register
	ori  $k0, 0x1            # Interrupts enabled
	mtc0 $k0, $12


#####################################################
# Return from exception on MIPS32
#
salir:	eret

# End of exception handling
#####################################################
