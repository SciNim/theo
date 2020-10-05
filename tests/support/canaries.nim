# Megalo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import ../../constantine/datatypes

# Canaries
# --------------------------------------------------------------
#
# This file initializes a type with canary
# to detect initialization bugs that are silent
# when initialized from zero.

when sizeof(Word) == 8:
  const Canary = Word(0xAAFACADEAAFACADE'u64)
else:
  const Canary = Word(0xAAFACADE'u32)

func canary*(T: typedesc): T =
  for i in 0 ..< result.limbs.len:
    result.limbs[i] = Canary
