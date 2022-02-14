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

#ifndef KEYPATH_REFLECTION_FUNCTIONS
#define KEYPATH_REFLECTION_FUNCTIONS

#include <stddef.h>

// Used to allocate keypaths at runtime.

// HeapObject *swift_allocObject(Metadata *type, size_t size, size_t alignMask);
extern void *swift_allocObject(void *type, size_t size, size_t alignMask);

#ifdef __arm64e__
const void *__ptrauth_strip_asda(const void *ptr);
#endif

#endif
