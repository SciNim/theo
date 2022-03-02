# Theo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# ############################################################
#
#               Extended precision primitives
#
# ############################################################

import
  ../datatypes,
  ./addcarry_subborrow

# ############################################################
#
#                     32-bit words
#
# ############################################################

func div2n1n*(q, r: var uint32, n_hi, n_lo, d: uint32) {.inline.}=
  ## Division uint64 by uint32
  ## Warning ⚠️ :
  ##   - if n_hi == d, quotient does not fit in an uint32
  ##   - if n_hi > d result is undefined
  ##
  ## To avoid issues, n_hi, n_lo, d should be normalized.
  ## i.e. shifted (== multiplied by the same power of 2)
  ## so that the most significant bit in d is set.
  let dividend = (uint64(n_hi) shl 32) or uint64(n_lo)
  let divisor = uint64(d)
  q = uint32(dividend div divisor)
  r = uint32(dividend mod divisor)

func mul*(hi, lo: var uint32, a, b: uint32) {.inline.} =
  ## Extended precision multiplication
  ## (hi, lo) <- a*b
  let dblPrec = uint64(a) * uint64(b)
  lo = uint32(dblPrec)
  hi = uint32(dblPrec shr 32)

func muladd1*(hi, lo: var uint32, a, b, c: uint32) {.inline.} =
  ## Extended precision multiplication + addition
  ## (hi, lo) <- a*b + c
  ##
  ## Note: 0xFFFFFFFF² -> (hi: 0xFFFFFFFE, lo: 0x00000001)
  ##       so adding any c cannot overflow
  let dblPrec = uint64(a) * uint64(b) + uint64(c)
  lo = uint32(dblPrec)
  hi = uint32(dblPrec shr 32)

func muladd2*(hi, lo: var uint32, a, b, c1, c2: uint32) {.inline.}=
  ## Extended precision multiplication + addition + addition
  ## (hi, lo) <- a*b + c1 + c2
  ##
  ## Note: 0xFFFFFFFF² -> (hi: 0xFFFFFFFE, lo: 0x00000001)
  ##       so adding 0xFFFFFFFF leads to (hi: 0xFFFFFFFF, lo: 0x00000000)
  ##       and we have enough space to add again 0xFFFFFFFF without overflowing
  let dblPrec = uint64(a) * uint64(b) + uint64(c1) + uint64(c2)
  lo = uint32(dblPrec)
  hi = uint32(dblPrec shr 32)

# ############################################################
#
#                     64-bit words
#
# ############################################################

when sizeof(int) == 8 and not defined(Megalo32):
  when nimvm:
    from ./compiletime_fallback import mul_nim, muladd1, muladd2
  else:
    when defined(vcc):
      from ./extended_precision_x86_64_msvc import div2n1n, mul, muladd1, muladd2
    elif GCCCompatible:
      when X86:
        from ./extended_precision_x86_64_gcc import div2n1n
        from ./extended_precision_64bit_uint128 import mul, muladd1, muladd2
      else:
        from ./extended_precision_64bit_uint128 import div2n1n, mul, muladd1, muladd2
    export div2n1n, mul
  export muladd1, muladd2

# ############################################################
#
#                  Composite primitives
#
# ############################################################

func mulDoubleAdd2*[T: uint32|uint64](r2: var Carry, r1, r0: var T, a, b, c: T, dHi: Carry, dLo: T) {.inline.} =
  ## (r2, r1, r0) <- 2*a*b + c + (dHi, dLo)
  ## with r = (r2, r1, r0) a triple-word number
  ## and d = (dHi, dLo) a double-word number
  ## r2 and dHi are carries, either 0 or 1

  var carry: Carry

  # (r1, r0) <- a*b
  # Note: 0xFFFFFFFF_FFFFFFFF² -> (hi: 0xFFFFFFFF_FFFFFFFE, lo: 0x00000000_00000001)
  mul(r1, r0, a, b)

  # (r2, r1, r0) <- 2*a*b
  # Then  (hi: 0xFFFFFFFF_FFFFFFFE, lo: 0x00000000_00000001) * 2
  #       (carry: 1, hi: 0xFFFFFFFF_FFFFFFFC, lo: 0x00000000_00000002)
  addC(carry, r0, r0, r0, Carry(0))
  addC(r2, r1, r1, r1, carry)

  # (r1, r0) <- (r1, r0) + c
  # Adding any uint64 cannot overflow into r2 for example Adding 2^64-1
  #       (carry: 1, hi: 0xFFFFFFFF_FFFFFFFD, lo: 0x00000000_00000001)
  addC(carry, r0, r0, c, Carry(0))
  addC(carry, r1, r1, T(0), carry)

  # (r1, r0) <- (r1, r0) + (dHi, dLo) with dHi a carry (previous limb r2)
  # (dHi, dLo) is at most (dhi: 1, dlo: 0xFFFFFFFF_FFFFFFFF)
  # summing into (carry: 1, hi: 0xFFFFFFFF_FFFFFFFD, lo: 0x00000000_00000001)
  # result at most in (carry: 1, hi: 0xFFFFFFFF_FFFFFFFF, lo: 0x00000000_00000000)
  addC(carry, r0, r0, dLo, Carry(0))
  addC(carry, r1, r1, T(dHi), carry)

func mulAcc*[T: uint32|uint64](t, u, v: var T, a, b: T) {.inline.} =
  ## (t, u, v) <- (t, u, v) + a * b
  var UV: array[2, T]
  var carry: Carry
  when nimvm:
    mul_nim(UV[1], UV[0], a, b)
  else:
    mul(UV[1], UV[0], a, b)
  addC(carry, v, v, UV[0], Carry(0))
  addC(carry, u, u, UV[1], carry)
  t += T(carry)
