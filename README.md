# Approov Quickstart: iOS Swift AsyncHTTPClient

This quickstart is written specifically for native iOS apps that you wish to protect with Approov and that are written in Swift, making API calls using [`AsyncHTTPClient`](https://github.com/swift-server/async-http-client), an HTTP Client library built on top of SwiftNIO. If this is not your situation then please check if there is a more relevant quickstart guide available.

This quickstart provides the basic steps for integrating Approov into your app. A more detailed step-by-step guide using a [Shapes App Example](https://github.com/approov/quickstart-ios-swift-asynchttpclient/blob/master/SHAPES-EXAMPLE.md) is also available.

To follow this guide you should have received an onboarding email for a trial or paid Approov account.

Note that the minimum requirement is iOS 10. You cannot use Approov in apps that support iOS versions older than this.

## ADDING APPROOV SERVICE DEPENDENCY
The Approov integration is available via the [`Swift Package Manager`](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app). This allows inclusion into a project by first removing the existing dependency on `AsyncHTTPClient` from the project and then adding a dependency on the `ApproovAsyncHTTPClient` package in Xcode through the `File -> AddPackages...` menu item or in the project's `Package Dependency` section. In the search box of the add packages dialog enter the url of the git repository `https://github.com/approov/approov-service-ios-swift-asynchttpclient.git`, then choose `Exact Version`.

![Add Package Dependency](readme-images/add-package-repository.png)

The `ApproovAsyncHTTPClient` package is actually an open source wrapper layer that allows you to easily use Approov with `AsyncHTTPClient`. It has further dependencies to the closed source [Approov SDK](https://github.com/approov/approov-ios-sdk) and a fork of AsyncHTTPClient that has been modified to enable setting a custom TLS pinning checker.

## USING APPROOV SERVICE
The `ApproovHTTPClient` class mimics the interface of the `HTTPClient` class from the `AsyncHTTPClient` package, but includes an additional ApproovSDK attestation call. The simplest way to use the `ApproovAsyncHTTPClient` package is to import  `ApproovAsyncHTTPClient`, then find and replace all the `HTTPClient` with `ApproovHTTPClient`.

```swift
try! ApproovService.initialize("<enter-your-config-string-here>")
let httpClient: ApproovHTTPClient = ApproovHTTPClient(eventLoopGroupProvider: .createNew)
```

Additionally, the Approov SDK wrapper class, `ApproovService` needs to be initialized before using any `ApproovHTTPClient` object. The `<enter-your-config-string-here>` is a custom string that configures your Approov account access. This will have been provided in your Approov onboarding email (it will be something like `#123456#K/XPlLtfcwnWkzv99Wj5VmAxo4CrU267J1KlQyoz8Qo=`).

For API domains that are configured to be protected with an Approov token, this adds the `Approov-Token` header and pins the connection. This may also substitute header values and URL query parameter values when using secrets protection.

Please note in the above code, the `ApproovService` is instantiated and might throw a `configurationError`exception if the configuration string provided as parameter is different than the one already used to initialize previously. If the underlying Appproov SDK can not be initialized because of a permanent issue, an `initializationFailure` is returned which should be considered permanent. Failure to initialise the `ApproovService` should cancel any network requests since lack of initialization is generally considered fatal.

## ERROR MESSAGES
The `ApproovService` functions may throw specific errors to provide additional information:

* `permanentError` might be due to a feature not being enabled through using the command line
* `rejectionError` an attestation has been rejected, the `ARC` and `rejectionReasons` may contain specific device information that would help troubleshooting
* `networkingError` generally can be retried since it can be a temporary network issue
* `pinningError` is a certificate error
* `configurationError` a configuration feature is disabled or wrongly configured (e.g. attempting to initialize with different configuration from a previous initialization)
* `initializationFailure` the ApproovService failed to be initialized

## CHECKING IT WORKS
Initially you won't have set which API domains to protect, so the ApproovService implementation will not add anything. It will have called Approov though and made contact with the Approov cloud service. You will see logging from Approov saying `unknown URL`.

Your Approov onboarding email should contain a link allowing you to access [Live Metrics Graphs](https://approov.io/docs/latest/approov-usage-documentation/#metrics-graphs). After you have run your app with Approov integration you should be able to see the results in the live metrics within a minute or so. At this stage you could even release your app to get details of your app population and the attributes of the devices they are running on.

## NEXT STEPS
To actually protect your APIs there are some further steps. Approov provides two different options for protection:

* [API PROTECTION](https://github.com/approov/quickstart-ios-swift-asynchttpclient/blob/master/API-PROTECTION.md): You should use this if you control the backend API(s) being protected and are able to modify them to ensure that a valid Approov token is being passed by the app. An [Approov Token](https://approov.io/docs/latest/approov-usage-documentation/#approov-tokens) is short lived crytographically signed JWT proving the authenticity of the call.

* [SECRETS PROTECTION](https://github.com/approov/quickstart-ios-swift-asynchttpclient/blob/master/SECRETS-PROTECTION.md): If you do not control the backend API(s) being protected, and are therefore unable to modify it to check Approov tokens, you can use this approach instead. It allows app secrets, and API keys, to be protected so that they no longer need to be included in the built code and are only made available to passing apps at runtime.

Note that it is possible to use both approaches side-by-side in the same app, in case your app uses a mixture of 1st and 3rd party APIs.

See [REFERENCE](https://github.com/approov/quickstart-ios-swift-asynchttpclient/blob/master/REFERENCE.md) for a complete list of all of the `ApproovService` methods.

## BITCODE SUPPORT
In order to use a bitcode enabled Approov service, you can still use the swift package repository at `https://github.com/approov/approov-service-ios-swift-asynchttpclient.git` but append the `-bitcode` suffix to the required SDK version, i.e. you could use `3.1.2-bitcode` as a version in the Swift Package Manager window.

Please Note: Bitcode will become obsolete in the near future, which unfortunately affects Xcode version 14. If you wish to use a swift package as source and build bitcode, you must use an `Xcode 13` or earlier. 
