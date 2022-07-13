# ================================
# Build image
# ================================
# FROM swiftlang/swift:nightly-5.6-focal as build
FROM swiftlang/swift:nightly-main-focal as build


# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Build including tests with discovery
RUN swift build --build-tests
