# Theo
# Copyright 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import ../datatypes

# ############################################################
#
#   Extended precision primitives for X86-64 on GCC & Clang
#
# ############################################################

static:
  doAssert(defined(gcc) or defined(clang) or defined(llvm_gcc))
  doAssert sizeof(int) == 8
  doAssert X86

func div2n1n*(q, r: var uint64, n_hi, n_lo, d: uint64) {.inline.}=
  ## Division uint128 by uint64
  ## Warning ⚠️ :
  ##   - if n_hi == d, quotient does not fit in an uint64 and will throw SIGFPE
  ##   - if n_hi > d result is undefined

  # DIV r/m64
  # Divide RDX:RAX (n_hi:n_lo) by r/m64
  #
  # Inputs
  #   - numerator high word in RDX,
  #   - numerator low word in RAX,
  #   - divisor as r/m parameter (register or memory at the compiler discretion)
  # Result
  #   - Quotient in RAX
  #   - Remainder in RDX

  # 1. name the register/memory "divisor"
  # 2. don't forget to dereference the var hidden pointer
  # 3. -
  # 4. no clobbered registers beside explicitly used RAX and RDX
  when defined(cpp):
    asm """
      divq %[divisor]
      : "=a" (`q`), "=d" (`r`)
      : "d" (`n_hi`), "a" (`n_lo`), [divisor] "rm" (`d`)
      :
    """
  else:
    asm """
      divq %[divisor]
      : "=a" (`*q`), "=d" (`*r`)
      : "d" (`n_hi`), "a" (`n_lo`), [divisor] "rm" (`d`)
      :
    """
