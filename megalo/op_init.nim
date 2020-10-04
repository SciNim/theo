# Megalo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import ./datatypes

# No exceptions allowed
{.push raises: [].}
{.push inline.}

# Initialization
# --------------------------------------------

func setZero*(a: var BigInt) =
  a.limbs.setLen(0)

func setOne*(a: var BigInt) =
  a.limbs.setLen(1)
  a.limbs[0] = One
