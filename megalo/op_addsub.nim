# Megalo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./datatypes,
  ./primitives/addcarry_subborrow

# Addition
# --------------------------------------------------------

func add*(r {.noalias.}: var BigInt, a, b: BigInt) =
  ## BigInt addition
  # TODO:
  # - relax the aliasing constraint
  # - dispatch on fixed size add for add that fits in registers
  #   and build add recursively
  #   to avoid loop counters resetting carry chains.
  var maxP = a.unsafeAddr
  var minLen = b.len
  var maxLen = a.len
  if a.len < b.len:
    maxP = b.unsafeAddr
    minLen = a.len
    maxLen = b.len

  r.limbs.setLen(maxLen)
  var carry = Carry(0)
  for i in 0 ..< minLen:
    addC(carry, r[i], a[i], b[i], carry)
  for i in minLen ..< maxLen:
    addC(carry, r[i], maxP[][i], Zero, carry)

  if bool carry:
    r.limbs.setLen(r.len+1)
    r.limbs[^1] = One

# Substraction
# --------------------------------------------------------

