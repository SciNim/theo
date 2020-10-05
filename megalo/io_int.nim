# Megalo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import ./datatypes

# No exceptions allowed
{.push raises: [].}

# Words
# -----------------------------------------------------------

func fromInt*(a: var BigInt, n: SomeUnsignedInt) {.inline.} =
  ## Create a BigInt from an unsigned int
  ## Assumes the same endianness
  a.setLen(1)
  a.limbs[0] = Word(n)
