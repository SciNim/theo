# Megalo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./datatypes, ./op_init

# No exceptions allowed
{.push raises: [].}

# Bytes decoding
# -----------------------------------------------------------

func fromRawUintLE(
        dst: var BigInt,
        src: openarray[byte]) =
  ## Parse an unsigned integer from its canonical
  ## little-endian unsigned representation
  ## and store it into a BigInt
  ##
  ## Can work at compile-time
  # TODO: error on destination to small

  var
    dst_idx = 0
    acc = Zero
    acc_len = 0

  for src_idx in 0 ..< src.len:
    let src_byte = Word(src[src_idx])

    # buffer reads
    acc = acc or (src_byte shl acc_len)
    acc_len += 8 # We count bit by bit

    # if full, dump
    if acc_len >= WordBitWidth:
      dst.limbs[dst_idx] = acc
      inc dst_idx
      acc_len -= WordBitWidth
      acc = src_byte shr (8 - acc_len)

  if dst_idx < dst.limbs.len:
    dst.limbs[dst_idx] = acc

func fromRawUintBE(
        dst: var BigInt,
        src: openarray[byte]) =
  ## Parse an unsigned integer from its canonical
  ## big-endian unsigned representation (octet string)
  ## and store it into a BigInt.
  ##
  ## In cryptography specifications, this is often called
  ## "Octet string to Integer"
  ##
  ## Can work at compile-time

  var
    dst_idx = 0
    acc = Zero
    acc_len = 0

  for src_idx in countdown(src.len-1, 0):
    let src_byte = Word(src[src_idx])

    # buffer reads
    acc = acc or (src_byte shl acc_len)
    acc_len += 8 # We count bit by bit

    # if full, dump
    if acc_len >= WordBitWidth:
      dst.limbs[dst_idx] = acc
      inc dst_idx
      acc_len -= WordBitWidth
      acc = src_byte shr (8 - acc_len)

  if dst_idx < dst.limbs.len:
    dst.limbs[dst_idx] = acc

func fromRawUint*(
        dst: var BigInt,
        src: openarray[byte],
        srcEndianness: static Endianness) =
  ## Parse an unsigned integer from its canonical
  ## big-endian or little-endian unsigned representation
  ## And store it into a BigInt of size `bits`
  ##
  ## Can work at compile-time
  ## from a canonical integer representation
  dst.setBytewidth src.len

  when srcEndianness == littleEndian:
    dst.fromRawUintLE(src)
  else:
    dst.fromRawUintBE(src)

  dst.normalize()

func fromRawUint*(
        T: type BigInt,
        src: openarray[byte],
        srcEndianness: static Endianness): T {.inline.}=
  ## Parse an unsigned integer from its canonical
  ## big-endian or little-endian unsigned representation
  ## And store it into a BigInt of size `bits`
  ##
  ## Can work at compile-time
  ## from a canonical integer representation
  result.fromRawUint(src, srcEndianness)

# Bytes encoding
# -----------------------------------------------------------

template toByte(x: SomeUnsignedInt): byte =
  ## At compile-time, conversion to bytes checks the range
  ## we want to ensure this is done at the register level
  ## at runtime in a single "mov byte" instruction
  when nimvm:
    byte(x and 0xFF)
  else:
    byte(x)

template blobFrom(dst: var openArray[byte], src: SomeUnsignedInt, startIdx: int, endian: static Endianness) =
  ## Write an integer into a raw binary blob
  ## Swapping endianness if needed
  when endian == cpuEndian:
    for i in 0 ..< sizeof(src):
      dst[startIdx+i] = toByte((src shr (i * 8)))
  else:
    for i in 0 ..< sizeof(src):
      dst[startIdx+sizeof(src)-1-i] = toByte((src shr (i * 8)))

func exportRawUintLE(
        dst: var openarray[byte],
        src: BigInt) =
  ## Serialize a bigint into its canonical little-endian representation
  ## I.e least significant bit first

  var
    src_idx, dst_idx = 0
    acc: Word = 0
    acc_len = 0

  var tail = dst.len
  while tail > 0:
    let w = if src_idx < src.limbs.len: src.limbs[src_idx]
            else: 0
    inc src_idx

    if acc_len == 0:
      # We need to refill the buffer to output 64-bit
      acc = w
      acc_len = WordBitWidth
    else:
      when WordBitWidth == sizeof(Word) * 8:
        let lo = acc
        acc = w
      else: # If using 63-bit (or less) out of uint64
        let lo = (w shl acc_len) or acc
        dec acc_len
        acc = w shr (WordBitWidth - acc_len)

      if tail >= sizeof(Word):
        # Unrolled copy
        dst.blobFrom(src = lo, dst_idx, littleEndian)
        dst_idx += sizeof(Word)
        tail -= sizeof(Word)
      else:
        # Process the tail and exit
        when cpuEndian == littleEndian:
          # When requesting little-endian on little-endian platform
          # we can just copy each byte
          # tail is inclusive
          for i in 0 ..< tail:
            dst[dst_idx+i] = toByte(lo shr (i*8))
        else: # TODO check this
          # We need to copy from the end
          for i in 0 ..< tail:
            dst[dst_idx+i] = toByte(lo shr ((tail-i)*8))
        return

func exportRawUintBE(
        dst: var openarray[byte],
        src: BigInt) =
  ## Serialize a bigint into its canonical big-endian representation
  ## (octet string)
  ## I.e most significant bit first
  ##
  ## In cryptography specifications, this is often called
  ## "Octet string to Integer"

  var
    src_idx = 0
    acc: Word = 0
    acc_len = 0

  var tail = dst.len
  while tail > 0:
    let w = if src_idx < src.limbs.len: Word(src.limbs[src_idx])
            else: 0
    inc src_idx

    if acc_len == 0:
      # We need to refill the buffer to output 64-bit
      acc = w
      acc_len = WordBitWidth
    else:
      when WordBitWidth == sizeof(Word) * 8:
        let lo = acc
        acc = w
      else: # If using 63-bit (or less) out of uint64
        let lo = (w shl acc_len) or acc
        dec acc_len
        acc = w shr (WordBitWidth - acc_len)

      if tail >= sizeof(Word):
        # Unrolled copy
        tail -= sizeof(Word)
        dst.blobFrom(src = lo, tail, bigEndian)
      else:
        # Process the tail and exit
        when cpuEndian == littleEndian:
          # When requesting little-endian on little-endian platform
          # we can just copy each byte
          # tail is inclusive
          for i in 0 ..< tail:
            dst[tail-1-i] = toByte(lo shr (i*8))
        else: # TODO check this
          # We need to copy from the end
          for i in 0 ..< tail:
            dst[tail-1-i] = toByte(lo shr ((tail-i)*8))
        return

func exportRawUint*(
        dst: var openarray[byte],
        src: BigInt,
        dstEndianness: static Endianness): bool =
  ## Serialize a bigint into its canonical big-endian or little endian
  ## representation.
  ## A destination buffer of size "(BigInt.bits + 7) div 8" at minimum is needed,
  ## i.e. bits -> byte conversion rounded up
  ##
  ## If the buffer is bigger, output will be zero-padded left for big-endian
  ## or zero-padded right for little-endian.
  ## I.e least significant bit is aligned to buffer boundary
  ##
  ## Returns false if the destination buffer is too small

  if dst.len >= (BigInt.bits + 7) shr 3:
    # "BigInt -> Raw int conversion: destination buffer is too small"
    return false

  if BigInt.len == 0:
    zeroMem(dst, dst.len)

  when dstEndianness == littleEndian:
    exportRawUintLE(dst, src)
  else:
    exportRawUintBE(dst, src)

  return true
