# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import  std/[unittest,times],
        ../megalo/[
          io_hex,
          io_bytes,
          io_int,
          op_addsub,
          op_comparisons
        ],
        ../megalo/datatypes,
        ../helpers/prng_unsafe,
        # Test helpers
        ./support/canaries

# Random seed for reproducibility
var rng: RngState
let seed = uint32(getTime().toUnix() and (1'i64 shl 32 - 1)) # unixTime mod 2^32
rng.seed(seed)
echo "\n------------------------------------------------------\n"
echo "test_addsub xoshiro512** seed: ", seed

proc main() =
  suite "Arithmetic operations - Addition with no aliasing " & " [" & $WordBitwidth & "-bit mode]":
    test "Adding 2 zeros":
      var a = BigInt.fromHex"0x00000000_00000000_00000000_00000000"
      let b = BigInt.fromHex"0x00000000_00000000_00000000_00000000"

      echo "a: ", a

      var r: BigInt
      r.add(a, b)
      check:
        a.isZero()
        b.isZero()
        r.isZero()

    test "Adding 1 zero - real addition":
      block:
        var a = BigInt.fromHex"0x00000000_00000000_00000000_00000000"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000001"

        var r: BigInt
        r.add(a, b)
        check:
          a.isZero()
          b.isOne()
          r.isOne()
      block:
        var a = BigInt.fromHex"0x00000000_00000000_00000000_00000001"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000000"

        var r: BigInt
        r.add(a, b)
        check:
          a.isOne()
          b.isZero()
          r.isOne()

    test "Adding non-zeros":
      block:
        var a = BigInt.fromHex"0x00000000_00000001_00000000_00000000"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000001"

        var r: BigInt
        r.add(a, b)
        let c = BigInt.fromHex"0x00000000_00000001_00000000_00000001"
        check:
          r == c
      block:
        var a = BigInt.fromHex"0x00000000_00000000_00000000_00000001"
        let b = BigInt.fromHex"0x00000000_00000001_00000000_00000000"

        var r: BigInt
        r.add(a, b)
        let c = BigInt.fromHex"0x00000000_00000001_00000000_00000001"
        check:
          r == c

    test "Addition limbs carry":
      block:
        var a = BigInt.fromHex"0x00000000_FFFFFFFF_FFFFFFFF_FFFFFFFE"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000001"

        var r: BigInt
        r.add(a, b)
        let c = BigInt.fromHex"0x00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF"
        check:
          r == c

      block:
        var a = BigInt.fromHex"0x00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000001"

        var r: BigInt
        r.add(a, b)
        let c = BigInt.fromHex"0x00000001_00000000_00000000_00000000"
        check:
          r == c

main()
