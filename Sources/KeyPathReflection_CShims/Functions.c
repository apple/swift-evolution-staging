//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#include "include/Functions.h"

#if defined(__arm64e__)
#include <ptrauth.h>

const void *__ptrauth_strip_asda(const void *ptr) {
    return ptrauth_strip(ptr, ptrauth_key_asda);
}

#endif
