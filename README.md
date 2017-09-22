# Networking-Controller

This is a simple, lightweight library for making asynchronous network requests on iOS. It is thread safe, meaning that networking requests can be made from any thread, without the dangers of the common pitfalls found in multi threaded environments.

## Requirements

This is written in Swift 4, works with macOS, iOS, watchOS, and tvOS.

## Installation

You can install this library with Carthage, Cocoapods, or Swift's package manager

### Carthage

Add this line to you `Cartfile`:

    github "Chandlerdea/NetworkingController"
    
Run `carthage update` and then add the created framework in `$(SRCROOT)/Carthage/build/iOS` to the Embedded Binaries section of you project.

### Cocopods

I'm having trouble linting the cocoapod, so cocoapods support isn't available just yet. I'll be adding it as soon as I figure out the issue.

### Swift Package Manager

In your Packages.swift file, add this code

    import PackageDescription

    let package = Package(
        url: "https://github.com/Chandlerdea/NetworkingController/NetworkingController.swift"
        majorVersion: 1
    )
    
## How to Use

Using the library is pretty simple. The `NetworkingController` is given a `URLRequest` to perform, and gives its delegates the data returned from the request. There is only one public function, `perform(request:)`, and `successDelegate` and `errorDelegate` properties. A typical use looks like this:

    class Foo {

      private lazy var controller: NetworkingController = {
        let controller: NetworkingController = NetworkingController()
        controller.successDelegate = self
        controller.errorDelegate = self
        return controller
      }()

      func doStuff() {
        let url: URL = URL(string: "http://www.google.com")!
        let request: URLRequest = URLRequest(url: url)
        self.controller.perform(request: request)
      }
    }

    extension Foo: NetworkingControllerErrorDelegate {

      func requestDidFail(_ request: URLRequest, error: NSError, status: URLResponseStatus?) {

      }

      func sessionDidFail(_ error: NSError?) {

      }
    }

    extension Foo: NetworkingControllerSuccessDelegate {

      func requestDidComplete(_ request: URLRequest, data: Data) {

      }
    }
    
    
If you have any critiques, or ideas, open a PR or let me know!
