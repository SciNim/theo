# Megalo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./datatypes,
  ./primitives/addcarry_subborrow,
  ./op_init

# Negate
# --------------------------------------------------------

func negate(r: var BigInt) =
  ## Negation (physical)
  ## In 2-complement
  ## -x <=> not(x) + 1
  var carry = Carry(1)
  for i in 0 ..< r.len:
    addC(carry, r[i], not(r[i]), Zero, carry)

# Addition
# --------------------------------------------------------

func add*(r {.noalias.}: var BigInt, a, b: BigInt) =
  ## BigInt addition
  # TODO:
  # - relax the aliasing constraint
  # - dispatch on fixed size add for add that fits in registers
  #   and build add recursively
  #   to avoid loop counters resetting carry chains.
  # - Support negative inputs
  # - Support compile-time
  var maxP = a.unsafeAddr
  var minLen = b.len
  var maxLen = a.len
  r.isNeg = a.isNeg # sign of the largest magnitude
  if a.len < b.len:
    maxP = b.unsafeAddr
    minLen = a.len
    maxLen = b.len
    r.isNeg = b.isNeg

  r.limbs.setLen(maxLen)
  var carry = Carry(0)
  for i in 0 ..< minLen:
    addC(carry, r[i], a[i], b[i], carry)
  for i in minLen ..< maxLen:
    addC(carry, r[i], maxP[][i], Zero, carry)

  if bool carry:
    r.limbs.setLen(r.len+1)
    r.limbs[^1] = One

  r.normalize()

# Substraction
# --------------------------------------------------------

func sub*(r {.noalias.}: var BigInt, a, b: BigInt) =
  ## BigInt substraction
  # TODO:
  # - relax the aliasing constraint
  # - dispatch on fixed size sub for sub that fits in registers
  #   and build sub recursively
  #   to avoid loop counters resetting borrow chains.
  # - Support compile-time
  if a.isNeg != b.isNeg: # Different signs, add magnitudes
    r.add(a, b)
    r.isNeg = a.isNeg
    return

  var maxP = a.unsafeAddr
  var minLen = b.len
  var maxLen = a.len
  if a.len < b.len:
    maxP = b.unsafeAddr
    minLen = a.len
    maxLen = b.len

  r.limbs.setLen(maxLen)
  var borrow = Borrow(0)
  for i in 0 ..< minLen:
    subB(borrow, r[i], a[i], b[i], borrow)
  if a.len < b.len:
    for i in minLen ..< maxLen:
      subB(borrow, r[i], Zero, b[i], borrow)
  else:
    for i in minLen ..< maxLen:
      subB(borrow, r[i], a[i], Zero, borrow)

  if bool borrow:
    borrow = Borrow(0)
    for i in 0 ..< maxLen:
      subB(borrow, r[i], Zero, r[i], borrow)

  r.normalize()
