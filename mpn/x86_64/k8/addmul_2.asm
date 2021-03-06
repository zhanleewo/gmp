dnl  AMD64 mpn_addmul_2 -- Multiply an n-limb vector with a 2-limb vector and
dnl  add the result to a third limb vector.

dnl  Copyright 2008, 2011, 2012, 2016 Free Software Foundation, Inc.

dnl  This file is part of the GNU MP Library.
dnl
dnl  The GNU MP Library is free software; you can redistribute it and/or modify
dnl  it under the terms of either:
dnl
dnl    * the GNU Lesser General Public License as published by the Free
dnl      Software Foundation; either version 3 of the License, or (at your
dnl      option) any later version.
dnl
dnl  or
dnl
dnl    * the GNU General Public License as published by the Free Software
dnl      Foundation; either version 2 of the License, or (at your option) any
dnl      later version.
dnl
dnl  or both in parallel, as here.
dnl
dnl  The GNU MP Library is distributed in the hope that it will be useful, but
dnl  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
dnl  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
dnl  for more details.
dnl
dnl  You should have received copies of the GNU General Public License and the
dnl  GNU Lesser General Public License along with the GNU MP Library.  If not,
dnl  see https://www.gnu.org/licenses/.

include(`../config.m4')

C	     cycles/limb     cycles/limb cfg	cycles/limb am1+am1
C AMD K8,K9	 2.375
C AMD K10	 2.375
C AMD bull	 5.2		<-		4.6-4.75		bad
C AMD pile	 4.96		<-		4.6-4.75		bad
C AMD steam	 ?
C AMD excavator	 ?
C AMD bobcat	 5.75				5.0			bad
C AMD jaguar	 5.9				5.2-5.4			bad
C Intel P4	15-16
C Intel core2	 4.5				4.25-4.5		bad
C Intel NHM	 4.33				4.55			bad
C Intel SBR	 3.4		 2.93		3.24			bad
C Intel IBR	 3.35		 2.6		2.95			bad
C Intel HWL	 3.3		 2.15		2.3			bad
C Intel BWL	 2.33		 2.33		1.65			bad
C Intel SKL	 2.37		 2.21		1.64			bad
C Intel atom	20		18.7
C Intel SLM	 8		 8.5
C VIA nano	 4.4

C This code is the result of running a code generation and optimization tool
C suite written by David Harvey and Torbjorn Granlund.

C TODO
C  * Tune feed-in and wind-down code.

C INPUT PARAMETERS
define(`rp',     `%rdi')
define(`up',     `%rsi')
define(`n_param',`%rdx')
define(`vp',     `%rcx')

define(`v0', `%r8')
define(`v1', `%r9')
define(`w0', `%rbx')
define(`w1', `%rcx')
define(`w2', `%rbp')
define(`w3', `%r10')
define(`n',  `%r11')

ABI_SUPPORT(DOS64)
ABI_SUPPORT(STD64)

ASM_START()
	TEXT
	ALIGN(16)
PROLOGUE(mpn_addmul_2)
	FUNC_ENTRY(4)
	mov	n_param, n
	push	%rbx
	push	%rbp

	mov	0(vp), v0
	mov	8(vp), v1

	mov	R32(n_param), R32(%rbx)
	mov	(up), %rax
	lea	-8(up,n_param,8), up
	lea	-8(rp,n_param,8), rp
	mul	v0
	neg	n
	and	$3, R32(%rbx)
	jz	L(b0)
	cmp	$2, R32(%rbx)
	jc	L(b1)
	jz	L(b2)

L(b3):	mov	%rax, w1
	mov	%rdx, w2
	xor	R32(w3), R32(w3)
	mov	8(up,n,8), %rax
	dec	n
	jmp	L(lo3)

L(b2):	mov	%rax, w2
	mov	8(up,n,8), %rax
	mov	%rdx, w3
	xor	R32(w0), R32(w0)
	add	$-2, n
	jmp	L(lo2)

L(b1):	mov	%rax, w3
	mov	8(up,n,8), %rax
	mov	%rdx, w0
	xor	R32(w1), R32(w1)
	inc	n
	jmp	L(lo1)

L(b0):	mov	$0, R32(w3)
	mov	%rax, w0
	mov	8(up,n,8), %rax
	mov	%rdx, w1
	xor	R32(w2), R32(w2)
	jmp	L(lo0)

	ALIGN(32)
L(top):	mov	$0, R32(w1)
	mul	v0
	add	%rax, w3
	mov	(up,n,8), %rax
	adc	%rdx, w0
	adc	$0, R32(w1)
L(lo1):	mul	v1
	add	w3, (rp,n,8)
	mov	$0, R32(w3)
	adc	%rax, w0
	mov	$0, R32(w2)
	mov	8(up,n,8), %rax
	adc	%rdx, w1
	mul	v0
	add	%rax, w0
	mov	8(up,n,8), %rax
	adc	%rdx, w1
	adc	$0, R32(w2)
L(lo0):	mul	v1
	add	w0, 8(rp,n,8)
	adc	%rax, w1
	adc	%rdx, w2
	mov	16(up,n,8), %rax
	mul	v0
	add	%rax, w1
	adc	%rdx, w2
	adc	$0, R32(w3)
	mov	16(up,n,8), %rax
L(lo3):	mul	v1
	add	w1, 16(rp,n,8)
	adc	%rax, w2
	adc	%rdx, w3
	xor	R32(w0), R32(w0)
	mov	24(up,n,8), %rax
	mul	v0
	add	%rax, w2
	mov	24(up,n,8), %rax
	adc	%rdx, w3
	adc	$0, R32(w0)
L(lo2):	mul	v1
	add	w2, 24(rp,n,8)
	adc	%rax, w3
	adc	%rdx, w0
	mov	32(up,n,8), %rax
	add	$4, n
	js	L(top)

L(end):	xor	R32(w1), R32(w1)
	mul	v0
	add	%rax, w3
	mov	(up), %rax
	adc	%rdx, w0
	adc	R32(w1), R32(w1)
	mul	v1
	add	w3, (rp)
	adc	%rax, w0
	adc	%rdx, w1
	mov	w0, 8(rp)
	mov	w1, %rax

	pop	%rbp
	pop	%rbx
	FUNC_EXIT()
	ret
EPILOGUE()
