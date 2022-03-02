# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import  std/[unittest,times],
        ../theo/[
          io_hex,
          io_bytes,
          io_int,
          op_addsub,
          op_comparisons
        ],
        ../theo/datatypes,
        ../helpers/prng_unsafe

# Random seed for reproducibility
var rng: RngState
let seed = uint32(getTime().toUnix() and (1'i64 shl 32 - 1)) # unixTime mod 2^32
rng.seed(seed)
echo "\n------------------------------------------------------\n"
echo "test_addsub xoshiro512** seed: ", seed

proc main() =
  suite "Arithmetic operations - Addition without no aliasing " & " [" & $WordBitwidth & "-bit mode]":
    test "Adding 2 zeros":
      var a = BigInt.fromHex"0x00000000_00000000_00000000_00000000"
      let b = BigInt.fromHex"0x00000000_00000000_00000000_00000000"

      var r: BigInt
      r.add(a, b)
      check:
        a.isZero()
        b.isZero()
        r.isZero()

    test "Adding 1 zero":
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

proc main_alias() =
  suite "Arithmetic operations - Addition with aliasing " & " [" & $WordBitwidth & "-bit mode]":
    test "Adding 2 zeros":
      var a = BigInt.fromHex"0x00000000_00000000_00000000_00000000"
      let b = BigInt.fromHex"0x00000000_00000000_00000000_00000000"

      a.add(a, b)
      check:
        a.isZero()
        b.isZero()

    test "Adding 1 zero":
      block:
        var a = BigInt.fromHex"0x00000000_00000000_00000000_00000000"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000001"

        a.add(a, b)
        check:
          a.isOne()
          b.isOne()
      block:
        var a = BigInt.fromHex"0x00000000_00000000_00000000_00000001"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000000"

        a.add(a, b)
        check:
          a.isOne()
          b.isZero()

    test "Adding non-zeros":
      block:
        var a = BigInt.fromHex"0x00000000_00000001_00000000_00000000"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000001"

        a.add(a, b)
        let c = BigInt.fromHex"0x00000000_00000001_00000000_00000001"
        check:
          a == c
      block:
        var a = BigInt.fromHex"0x00000000_00000000_00000000_00000001"
        let b = BigInt.fromHex"0x00000000_00000001_00000000_00000000"

        a.add(a, b)
        let c = BigInt.fromHex"0x00000000_00000001_00000000_00000001"
        check:
          a == c

    test "Addition limbs carry":
      block:
        var a = BigInt.fromHex"0x00000000_FFFFFFFF_FFFFFFFF_FFFFFFFE"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000001"

        a.add(a, b)
        let c = BigInt.fromHex"0x00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF"
        check:
          a == c

      block:
        var a = BigInt.fromHex"0x00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF"
        let b = BigInt.fromHex"0x00000000_00000000_00000000_00000001"

        a.add(a, b)
        let c = BigInt.fromHex"0x00000001_00000000_00000000_00000000"
        check:
          a == c

main()
# main_alias() # broken if we don't use raw pointer after b40959fea84e9d6aa7eacfdafd6af979fc4e4e1b

# static:
#   main()
#   main_alias()
