# Theo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# ----------------------------------------------

when sizeof(int) == 8 and not defined(Megalo32):
  type Word* = uint64
else:
  type Word* = uint32

const
  WordBitWidth* = sizeof(Word) * 8
  Zero* = Word(0)
  One* = Word(1)

type
  Carry* = uint8  # distinct range[0'u8 .. 1]
  Borrow* = uint8 # distinct range[0'u8 .. 1]

const GCC_Compatible* = defined(gcc) or defined(clang) or defined(llvm_gcc)
const X86* = defined(amd64) or defined(i386)

when sizeof(int) == 8 and GCC_Compatible:
  type
    uint128*{.importc: "unsigned __int128".} = object

type
  BigInt* = object
    ## A multi-precision integer
    # Representation
    # - Limbs: store the integer in a*2^w + b*2^(w-1) + ... + z*2^0
    #   Limb-endianness is little-endian, least significant limb at position 0
    #   Word-endianness is native-endian.
    # - isNeg: a flag that indicates if the integer is negative
    limbs*: seq[Word]
    isNeg*: bool

template len*(a: BigInt): int = a.limbs.len
template `[]`*(a: BigInt, i: int): Word = a.limbs[i]
template `[]=`*(a: var BigInt, i: int, v: Word) = a.limbs[i] = v
