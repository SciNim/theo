# Megalo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./datatypes,
  ./primitives/bithacks

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

# Canonicalization
# --------------------------------------------

func normalize*(a: var BigInt) =
  ## Canonicalize a bigint after computation
  ## This logically removes extra unused words in the BigInt representation
  ## to maintain the invariant that all allocated words are used.
  # Note: The unused words are not returned to the GC
  var extraWords = 0
  # TODO: we might want to do a binary search
  for i in countdown(a.len-1, 0):
    if a[i] != Zero:
      break
    inc extraWords
  a.limbs.setLen(a.len-extraWords)

# Bitwise
# --------------------------------------------

func wordsRequiredForBits*(bits: int): int =
  ## Compute the number of limbs required
  ## from the announced bit length
  (bits + WordBitWidth - 1) shr static(log2(uint32 WordBitWidth))

func setBitwidth*(a: var BigInt, bits: SomeInteger) =
  ## Dimension a bigint to handle `bits` sized inputs
  a.limbs.setLen bits.wordsRequiredForBits()

func wordsRequiredForBytes*(bytes: int): int =
  ## Compute the number of limbs required
  ## from the announced byte length
  const WordByteWidth = WordBitWidth div 8
  (bytes + WordByteWidth - 1) shr static(log2(uint32 WordByteWidth))

func setBytewidth*(a: var BigInt, bytes: SomeInteger) =
  ## Dimension a bigint to handle `bytes` sized inputs
  a.limbs.setLen bytes.wordsRequiredForBytes()
