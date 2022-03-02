# Theo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import ./datatypes

# No exceptions allowed
{.push raises: [].}

# Logical Shift Right
# --------------------------------------------------------

func shrSmall(r {.noalias.}: var BigInt, a: BigInt, k: SomeInteger) =
  ## Shift right by k.
  ##
  ## k MUST be less than the base word size (2^32 or 2^64)
  # Note: for speed, loading a[i] and a[i+1]
  #       instead of a[i-1] and a[i]
  #       is probably easier to parallelize for the compiler
  #       (antidependence WAR vs loop-carried dependence RAW)
  r.limbs.setLen(a.len)

  when cpuEndian == littleEndian:
    for i in 0 ..< a.len-1:
      r[i] = (a[i] shr k) or (a[i+1] shl (WordBitWidth - k))
    r[^1] = a[^1] shr k
  else:
    for i in countdown(a.len-1, 1):
      r[i] = (a[i] shr k) or (a[i-1] shl (WordBitWidth - k))
    r[0] = a[0] shr k

func shrLarge(r {.noalias.}: var BigInt, a: BigInt, w, shift: SomeInteger) =
  ## Shift right by `w` words + `shift` bits
  ## Assumes `r` is 0 initialized
  if w >= a.len:
    r.setLen(0)
    return

  r.limbs.setLen(a.len)

  when cpuEndian == littleEndian:
    for i in w ..< a.len-1:
      r[i-w] = (a[i] shr shift) or (a[i+1] shl (WordBitWidth - shift))
    r[^(1+w)] = a[^1] shr shift
  else:
    for i in countdown(a.len-1, 1+w):
      r[i-w] = (a[i] shr shift) or (a[i-1] shl (WordBitWidth - k))
    r[0] = a[w] shr shift

func shrWords(r {.noalias.}: var BigInt, a: BigInt, w: SomeInteger) =
  ## Shift right by w word
  r.limbs.setLen(a.len)

  when cpuEndian == littleEndian:
    for i in 0 ..< a.len-w:
      r[i] = a[i+w]
  else:
    for i in countdown(a.len-w, 0):
      r[i] = a[i+w]

# Logical Shift Left
# --------------------------------------------------------
