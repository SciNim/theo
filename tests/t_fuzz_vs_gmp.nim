import  std/[unittest,times,strutils],
        ../megalo/[
          io_hex,
          io_bytes,
          io_int,
          op_addsub,
          op_comparisons
        ],
        ../megalo/datatypes,
        ../helpers/prng_unsafe,
        # Third-party
        gmp, stew/byteutils

# TODO: skewed RNG to stress test rare edge cases like carries
import std/random
var bitSizeRNG = initRand(0xFACADE)

var gmpRng: gmp_randstate_t
gmp_randinit_mt(gmpRng)
# The GMP seed varies between run so that
# test coverage increases as the library gets tested.
# This requires to dump the seed in the console or the function inputs
# to be able to reproduce a bug
let seed = uint32(getTime().toUnix() and (1'i64 shl 32 - 1)) # unixTime mod 2^32
echo "GMP seed: ", seed
gmp_randseed_ui(gmpRng, seed)

const # https://gmplib.org/manual/Integer-Import-and-Export.html
  GMP_WordLittleEndian = -1'i32
  GMP_WordNativeEndian = 0'i32
  GMP_WordBigEndian = 1'i32

  GMP_MostSignificantWordFirst = 1'i32
  GMP_LeastSignificantWordFirst = -1'i32

proc main_add(numSizes: int) =
  var gmpRng: gmp_randstate_t
  gmp_randinit_mt(gmpRng)
  # The GMP seed varies between run so that
  # test coverage increases as the library gets tested.
  # This requires to dump the seed in the console or the function inputs
  # to be able to reproduce a bug
  let seed = uint32(getTime().toUnix() and (1'i64 shl 32 - 1)) # unixTime mod 2^32
  echo "GMP seed: ", seed
  gmp_randseed_ui(gmpRng, seed)

  var r, a, b: mpz_t
  mpz_init(r)
  mpz_init(a)
  mpz_init(b)

  for _ in 0 ..< numSizes:
    let aBits = bitSizeRNG.rand(126 .. 2048)
    let bBits = bitSizeRNG.rand(126 .. 2048)
    let rBits = bitSizeRNG.rand(62 .. 4096+128)

    var r, a, b: mpz_t
    mpz_init(r)
    mpz_init(a)
    mpz_init(b)

    # Generate random values in the range 0 ..< 2^aBits
    # TODO - negative values
    mpz_urandomb(a, gmpRng, aBits.culong)
    mpz_urandomb(b, gmpRng, bBits.culong)
    mpz_setbit(r, culong max(aBits,bBits) + 1)

    # discard gmp_printf(" -- %#Zx mod %#Zx\n", a.addr, m.addr)

    #########################################################
    # Conversion buffers
    let aLen = (aBits + 7) div 8
    let bLen = (bBits + 7) div 8

    var aBuf = newSeq[byte](aLen)
    var bBuf = newSeq[byte](bLen)

    var aW, bW: csize # Word written by GMP

    discard mpz_export(aBuf[0].addr, aW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, a)
    discard mpz_export(bBuf[0].addr, bW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, b)

    # Since the modulus is using all bits, it's we can test for exact amount copy
    doAssert aLen >= aW, "Expected at most " & $aLen & " bytes but wrote " & $aW & " for " & toHex(aBuf) & " (big-endian)"
    doAssert bLen >= bW, "Expected at most " & $bLen & " bytes but wrote " & $bW & " for " & toHex(bBuf) & " (big-endian)"

    # Build the bigint
    let aTest = BigInt.fromRawUint(aBuf.toOpenArray(0, aW-1), bigEndian)
    let bTest = BigInt.fromRawUint(bBuf.toOpenArray(0, bW-1), bigEndian)

    #########################################################
    # Addition
    r.mpz_add(a, b)

    # Megalo
    var rTest: BigInt
    rTest.add(aTest, bTest)

    #########################################################
    # Check
    let rLen = (mpz_sizeinbase(r, 2) + 7) div 8
    var rGMP = newSeq[byte](rLen)

    var rW: csize # Word written by GMP
    discard mpz_export(rGMP[0].addr, rW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, r)

    var rMegalo = newSeq[byte](rLen)
    doAssert rMegalo.exportRawUint(rTest, bigEndian)

    # Note: in bigEndian, GMP aligns left while Megalo aligns right
    doAssert rGMP.toOpenArray(0, rW-1) == rMegalo.toOpenArray(rLen-rW, rLen-1), block:
      # Reexport as bigEndian for debugging
      discard mpz_export(aBuf[0].addr, aW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, a)
      discard mpz_export(bBuf[0].addr, bW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, b)
      "\nAddition with operands\n" &
      "  a (" & align($aBits, 4) & "-bit):   " & aBuf.toOpenArray(0, aW-1).toHex & "\n" &
      "  b (" & align($bBits, 4) & "-bit):   " & bBuf.toOpenArray(0, bW-1).toHex & "\n" &
      "into r of size " & align($rBits, 4) & "-bit failed:" & "\n" &
      "  GMP:     " & rGMP.toHex() & "\n" &
      "  Megalo:  " & rMegalo.toHex() & "\n" &
      "(Note that GMP aligns bytes left while Megalo aligns bytes right)"

proc main_sub(numSizes: int) =
  var r, a, b: mpz_t
  mpz_init(r)
  mpz_init(a)
  mpz_init(b)

  for i in 0 ..< numSizes:
    echo i

    let aBits = bitSizeRNG.rand(126 .. 2048)
    let bBits = bitSizeRNG.rand(126 .. 2048)
    let rBits = bitSizeRNG.rand(62 .. 4096+128)

    var r, a, b: mpz_t
    mpz_init(r)
    mpz_init(a)
    mpz_init(b)

    # Generate random values in the range 0 ..< 2^aBits
    # TODO - negative values
    mpz_urandomb(a, gmpRng, aBits.culong)
    mpz_urandomb(b, gmpRng, bBits.culong)
    mpz_setbit(r, culong max(aBits,bBits) + 1)

    # discard gmp_printf(" -- %#Zx mod %#Zx\n", a.addr, m.addr)

    #########################################################
    # Conversion buffers
    let aLen = (aBits + 7) div 8
    let bLen = (bBits + 7) div 8

    var aBuf = newSeq[byte](aLen)
    var bBuf = newSeq[byte](bLen)

    var aW, bW: csize # Word written by GMP

    discard mpz_export(aBuf[0].addr, aW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, a)
    discard mpz_export(bBuf[0].addr, bW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, b)

    # Since the modulus is using all bits, it's we can test for exact amount copy
    doAssert aLen >= aW, "Expected at most " & $aLen & " bytes but wrote " & $aW & " for " & toHex(aBuf) & " (big-endian)"
    doAssert bLen >= bW, "Expected at most " & $bLen & " bytes but wrote " & $bW & " for " & toHex(bBuf) & " (big-endian)"

    # Build the bigint
    let aTest = BigInt.fromRawUint(aBuf.toOpenArray(0, aW-1), bigEndian)
    let bTest = BigInt.fromRawUint(bBuf.toOpenArray(0, bW-1), bigEndian)

    #########################################################
    # Addition
    r.mpz_sub(a, b)

    # Megalo
    var rTest: BigInt
    rTest.sub(aTest, bTest)

    #########################################################
    # Check
    let rLen = (mpz_sizeinbase(r, 2) + 7) div 8
    var rGMP = newSeq[byte](rLen)

    var rW: csize # Word written by GMP
    discard mpz_export(rGMP[0].addr, rW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, r)

    var rMegalo = newSeq[byte](rLen)
    doAssert rMegalo.exportRawUint(rTest, bigEndian)

    # Note: in bigEndian, GMP aligns left while Megalo aligns right
    doAssert rGMP.toOpenArray(0, rW-1) == rMegalo.toOpenArray(rLen-rW, rLen-1), block:
      # Reexport as bigEndian for debugging
      discard mpz_export(aBuf[0].addr, aW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, a)
      discard mpz_export(bBuf[0].addr, bW.addr, GMP_MostSignificantWordFirst, 1, GMP_WordNativeEndian, 0, b)
      "\nSubstraction with operands\n" &
      "  a (" & align($aBits, 4) & "-bit):   " & aBuf.toOpenArray(0, aW-1).toHex & "\n" &
      "  b (" & align($bBits, 4) & "-bit):   " & bBuf.toOpenArray(0, bW-1).toHex & "\n" &
      "into r of size " & align($rBits, 4) & "-bit failed:" & "\n" &
      "  GMP:     " & rGMP.toHex() & "\n" &
      "  Megalo:  " & rMegalo.toHex() & "\n" &
      "(Note that GMP aligns bytes left while Megalo aligns bytes right)"


main_add(128)
main_sub(128)
