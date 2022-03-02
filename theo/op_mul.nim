# Theo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./datatypes,
  ./op_init,
  ./primitives/extended_precision

# No exceptions allowed
{.push raises: [].}

# Multiplication
# --------------------------------------------------------------

func mul*(r {.noalias.}: var BigInt, a, b: BigInt) =
  ## Multi-precision multiplication
  ## r <- a*b
  ##
  # TODO:
  # - relax the aliasing constraint
  # - use Karatsuba for large int
  # - dispatch on fixed size mul for mul that fits in registers
  #   and build mul recursively
  #   to avoid loop counters resetting carry chains.

  r.limbs.setLen(a.len+b.len)

  # We use Product Scanning / Comba multiplication
  var t, u, v = Word(0)

  for i in 0 ..< r.len:
    let ib = min(b.len-1, i)
    let ia = i - ib
    for j in 0 ..< min(a.len - ia, ib+1):
      mulAcc(t, u, v, a[ia+j], b[ib-j])

    r[i] = v
    v = u
    u = t
    t = Word(0)

  r.normalize()
