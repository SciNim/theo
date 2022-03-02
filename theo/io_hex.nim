# Theo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ./datatypes,
  ./io_bytes, ./op_bits

# No exceptions allowed
{.push raises: [].}

# ############################################################
#
#                     Conversion helpers
#
# ############################################################

func readHexChar(c: char): uint8 {.inline, raises:[ValueError].}=
  ## Converts an hex char to an int
  ## CT: leaks position of invalid input if any.
  case c
  of '0'..'9': result = uint8 ord(c) - ord('0')
  of 'a'..'f': result = uint8 ord(c) - ord('a') + 10
  of 'A'..'F': result = uint8 ord(c) - ord('A') + 10
  else:
    raise newException(ValueError, $c & "is not a hexadecimal character")

func skipPrefixes(current_idx: var int, str: string, radix: static range[2..16]) {.inline.} =
  ## Returns the index of the first meaningful char in `hexStr` by skipping
  ## "0x" prefix
  ## CT:
  ##   - leaks if input length < 2
  ##   - leaks if input start with 0x, 0o or 0b prefix

  if str.len < 2:
    return

  assert current_idx == 0, "skipPrefixes only works for prefixes (position 0 and 1 of the string)"
  if str[0] == '0':
    case str[1]
    of {'x', 'X'}:
      assert radix == 16, "Parsing mismatch, 0x prefix is only valid for a hexadecimal number (base 16)"
      current_idx = 2
    of {'o', 'O'}:
      assert radix == 8, "Parsing mismatch, 0o prefix is only valid for an octal number (base 8)"
      current_idx = 2
    of {'b', 'B'}:
      assert radix == 2, "Parsing mismatch, 0b prefix is only valid for a binary number (base 2)"
      current_idx = 2
    else: discard

func countNonBlanks(hexStr: string, startPos: int): int =
  ## Count the number of non-blank characters
  ## ' ' (space) and '_' (underscore) are considered blank
  ##
  ## CT:
  ##   - Leaks white-spaces and non-white spaces position
  const blanks = {' ', '_'}

  for c in hexStr:
    if c in blanks:
      result += 1

func hexToBytes(hexStr: string, output: var seq[byte], order: static[Endianness]) {.raises: [ValueError].} =
  ## Read a hex string and store it in a byte array `output`.
  ## The string may be shorter than the byte array.
  ##
  ## The source string must be hex big-endian.
  ## The destination array can be big or little endian
  var
    skip = 0
    dstIdx: int
    shift = 4
  skipPrefixes(skip, hexStr, 16)

  const blanks = {' ', '_'}
  let nonBlanksCount = countNonBlanks(hexStr, skip)

  let maxStrSize = output.len * 2
  let size = hexStr.len - skip - nonBlanksCount

  output.setLen(size shr 1)

  if size < maxStrSize:
    # include extra byte if odd length
    dstIdx = output.len - (size + 1) div 2
    # start with shl of 4 if length is even
    shift = 4 - size mod 2 * 4

  for srcIdx in skip ..< hexStr.len:
    if hexStr[srcIdx] in blanks:
      continue

    let nibble = hexStr[srcIdx].readHexChar shl shift
    when order == bigEndian:
      output[dstIdx] = output[dstIdx] or nibble
    else:
      output[output.high - dstIdx] = output[output.high - dstIdx] or nibble
    shift = (shift + 4) and 4
    dstIdx += shift shr 2

func nativeEndianToHex(bytes: openarray[byte], order: static[Endianness]): string =
  ## Convert a byte-array to its hex representation
  ## Output is in lowercase and not prefixed.
  ## This assumes that input is in platform native endianness
  const hexChars = "0123456789abcdef"
  result = newString(2 + 2 * bytes.len)
  result[0] = '0'
  result[1] = 'x'
  for i in 0 ..< bytes.len:
    when order == system.cpuEndian:
      result[2 + 2*i] = hexChars[int bytes[i] shr 4 and 0xF]
      result[2 + 2*i+1] = hexChars[int bytes[i] and 0xF]
    else:
      result[2 + 2*i] = hexChars[int bytes[bytes.high - i] shr 4 and 0xF]
      result[2 + 2*i+1] = hexChars[int bytes[bytes.high - i] and 0xF]

# ############################################################
#
#                      Hex conversion
#
# ############################################################

func fromHex*(T: type BigInt, s: string): T {.noInit, raises: [ValueError].} =
  ## Convert a hex string to BigInt that can hold
  ## the specified number of bits
  ##
  ## Hex string is assumed big-endian

  # 1. Convert to canonical uint
  var bytes: seq[byte]
  s.hexToBytes(bytes, bigEndian)

  # 2. Convert canonical uint to Big Int
  result.fromRawUint(bytes, bigEndian)

func appendHex*(dst: var string, big: BigInt, order: static Endianness = bigEndian) =
  ## Append the BigInt hex into an accumulator
  ## Note. Leading zeros are not removed.
  ## Result is prefixed with 0x

  # 1. Convert Big Int to canonical uint
  var bytes = newSeq[byte]((big.bits+7) shr 3)
  let ok = exportRawUint(bytes, big, cpuEndian)
  assert ok, "Unexpected error while converting a BigInt to hex."

  # 2 Convert canonical uint to hex
  dst.add bytes.nativeEndianToHex(order)

func toHex*(big: BigInt, order: static Endianness = bigEndian): string =
  ## Stringify an int to hex.
  ## Note. Leading zeros are not removed.
  ## Result is prefixed with 0x
  result.appendHex(big, order)
