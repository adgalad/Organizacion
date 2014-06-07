	.data

LockFlag:	.space	1
			.align 2	
bloqueado:	.asciiz	"El Computador esta bloqueado: Introduzca el password para desbloquearlo\n\n"
aceptado:	.asciiz	"La clave ha sido aceptada"
display_c:	.word	0xffff0008
display_d:	.word	0xffff000c
		
		
		
	.text
	
	.globl LockFlag 
	
main: 		li		$t0,	1
			sw 		$t0,	LockFlag
				    
    		#li		$v0,	100
			#syscall
continua:	lw		$s0,	LockFlag
			beqz	$s0,	correcto
            la 		$a0,	bloqueado
            jal 	PrintString
            b 		continua
            
correcto:	la 		$a0,	aceptado
			li		$v0,	4
			syscall
            li 		$v0,	10
            syscall
            
PrintString:lw 		$t0,	display_d
			lw		$t1,	display_c
			move	$t3,	$a0

loopd:		lw		$t2,	0($t1)
			andi	$t2,	$t2,	0x1
			beqz	$t2,	loopd
			lb		$t4,	0($t3)
			beqz	$t4,	salir
			sw		$t4,	0($t0)
			addi 	$t3,	$t3,	1
			b 		loopd
			
salir:		jr	$ra	
			

			
			
