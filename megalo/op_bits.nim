# Megalo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./datatypes,
  ./primitives/bithacks

# Bitwise operations
# --------------------------------------------------------------

func log2*(a: BigInt): Word =
  ## Compute the logarithm in base 2 of a bigint
  ## This is equivalent to getting the most significant bit
  for i in countdown(a.len-1, 0):
    let msb = log2(a[i])
    if msb != 0:
      return msb + i.Word*WordBitWidth
  return Zero

func bits*(a: BigInt): int =
  ## Returns the number of bits in `a`
  log2(a).int + 1
