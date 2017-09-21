# Networking-Controller

This is a simple, lightweight library for making asynchronous network requests on iOS. It is thread safe, meaning that networking requests can be made from any thread, without the dangers of the common pitfalls found in multi threaded environments.

## Installation

You can install this library with Carthage, Cocoapods, or Swift's package manager

### Carthage

Add this line to you `Cartfile`:

    github "Chandlerdea/NetworkingController"
    
Run `carthage update` and then add the created framework in `$(SRCROOT)/Carthage/build/iOS` to the Embedded Binaries section of you project.

