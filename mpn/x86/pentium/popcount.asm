dnl  Intel P5 mpn_popcount -- mpn bit population count.
dnl
dnl  P5: 8.0 cycles/limb

dnl  Copyright 2001 Free Software Foundation, Inc.
dnl 
dnl  This file is part of the GNU MP Library.
dnl 
dnl  The GNU MP Library is free software; you can redistribute it and/or
dnl  modify it under the terms of the GNU Lesser General Public License as
dnl  published by the Free Software Foundation; either version 2.1 of the
dnl  License, or (at your option) any later version.
dnl 
dnl  The GNU MP Library is distributed in the hope that it will be useful,
dnl  but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl  Lesser General Public License for more details.
dnl 
dnl  You should have received a copy of the GNU Lesser General Public
dnl  License along with the GNU MP Library; see the file COPYING.LIB.  If
dnl  not, write to the Free Software Foundation, Inc., 59 Temple Place -
dnl  Suite 330, Boston, MA 02111-1307, USA.

include(`../config.m4')


C unsigned long mpn_popcount (mp_srcptr src, mp_size_t size);
C
C An arithmetic approach has been found to be slower than the table lookup,
C due to needing too many instructions.

deflit(TABLE_NAME,mpn_popcount``'_table')

	RODATA
	ALIGN(8)
	GLOBL	TABLE_NAME
TABLE_NAME:
forloop(i,0,255,
`	.byte	m4_popcount(i)
')

defframe(PARAM_SIZE,8)
defframe(PARAM_SRC, 4)

	TEXT
	ALIGN(8)

PROLOGUE(mpn_popcount)
deflit(`FRAME',0)

	movl	PARAM_SIZE, %ecx
	xorl	%eax, %eax	C total

	shll	%ecx		C size in byte pairs
	jz	L(done)

	pushl	%ebx	FRAME_pushl()
	pushl	%esi	FRAME_pushl()

	movl	PARAM_SRC, %esi
	xorl	%edx, %edx	C byte

	xorl	%ebx, %ebx	C byte

ifdef(`PIC',`
	pushl	%ebp	FRAME_pushl()

	call	L(here)
L(here):
	popl	%ebp
	addl	$_GLOBAL_OFFSET_TABLE_+[.-L(here)], %ebp

	movl	TABLE_NAME@GOT(%ebp), %ebp
define(TABLE,`(%ebp,$1)')
',`
define(TABLE,`TABLE_NAME`'($1)')
')


	ALIGN(8)	C necessary on P55 for claimed speed
L(top):
	C eax	total
	C ebx	byte
	C ecx	counter, 2*size to 2
	C edx	byte
	C esi	src
	C edi
	C ebp	[PIC] table

	addl	%ebx, %eax
	movb	-1(%esi,%ecx,2), %bl

	addl	%edx, %eax
	movb	-2(%esi,%ecx,2), %dl

	movb	TABLE(%ebx), %bl
	decl	%ecx

	movb	TABLE(%edx), %dl
	jnz	L(top)


ifdef(`PIC',`
	popl	%ebp
')
	addl	%ebx, %eax
	popl	%esi

	addl	%edx, %eax
	popl	%ebx

L(done):
	ret

EPILOGUE()
