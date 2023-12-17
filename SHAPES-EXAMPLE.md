# Shapes Example

This quickstart is written specifically for native iOS apps that you wish to protect with Approov and that are written in Swift, making API calls using [`AsyncHTTPClient`](https://github.com/swift-server/async-http-client), a HTTP Client library built on top of SwiftNIO. This quickstart provides a step-by-step example of integrating Approov into an app using a simple `Shapes` example that shows a geometric shape based on a request to an API backend that can be protected with Approov.

## WHAT YOU WILL NEED
* Access to a trial or paid Approov account
* The `approov` command line tool [installed](https://approov.io/docs/latest/approov-installation/) with access to your account
* [Xcode](https://developer.apple.com/xcode/) version 13 installed (version 13.3 is used in this guide)
* The contents of this repo
* An Apple mobile device with iOS 13 or higher

## RUNNING THE SHAPES APP WITHOUT APPROOV

Open the `ApproovShapes.xcodeproj` project in the `shapes-app` folder using `File->Open` in Xcode. Ensure the `ApproovShapes` project is selected at the top of Xcode's project explorer panel.

Select your codesigning certificate in the `Signing & Capabilities` tab and run the application on your prefered device.

![Codesign App](readme-images/codesign-app.png)

Once the application is running you will see two buttons:

<p>
    <img src="readme-images/app-startup.png" width="256" title="Shapes App Startup">
</p>

Press the `Hello` button and you should see this:

<p>
    <img src="readme-images/hello-okay.png" width="256" title="Hello Okay">
</p>

This checks the connectivity by connecting to the endpoint `https://shapes.approov.io/v1/hello`. Now press the `Shape` button and you will see this (or another shape):

<p>
    <img src="readme-images/shapes-good.png" width="256" title="Shapes Good">
</p>

This contacts `https://shapes.approov.io/v1/shapes` to get the name of a random shape. This endpoint is protected with an API key that is built into the code, and therefore can be easily extracted from the app.

The subsequent steps of this guide show you how to provide better protection, either by using an Approov token or by migrating the API key to become an Approov managed secret.

## ADD THE APPROOV SERVICE DEPENDENCY

First you need to remove the existing dependency on `AsyncHTTPClient` from the project because the `ApproovAsyncHTTPClient` package already contains a dependency to a copy (fork) of the original `AsyncHTTPClient` package that has been modified to allow setting a custom TLS pinning verifier. Select the `ApproovShapes` project in Xcode and then in `Package Dependencies` select `async-http-client`, click the &mdash; symbol below and confirm removal.

![Remove Package Dependency](readme-images/remove-package-repository.png)

Get the latest Approov integration by using the `Swift Package Manager`. The repository located at `https://github.com/approov/approov-service-ios-swift-asynchttpclient.git` includes further dependencies to a fork of `AsyncHTTPClient` that has been modified to enable setting a custom TLS pinning checker and the closed source Approov SDK and includes tags pointing to the relevant Approov SDK release versions. The `ApproovAsyncHTTPClient` package is actually an open source wrapper layer that allows you to easily use Approov with AsyncHTTPClient. Install the dependency by selecting the `ApproovShapes` project in Xcode and then selecting `File`, `Add Packages` and in the search box enter the url of the git repository `https://github.com/approov/approov-service-ios-swift-asynchttpclient.git`:

![Add Package Dependency](readme-images/add-package-repository.png)

You will then have to select the relevant `ApproovAsyncHTTPClient` package version you wish to use; each version is identified by a tag, with the main branch usually pointing to the latest version. Select the `Exact Version` option and this selects the package version. Once you click `Add Package` the last screen will confirm the package product and target selection:

![Add Package Dependency Confirmation](readme-images/add-package-confirm.png)

Click `Add Package` again, the `ApproovAsyncHTTPClient` package is now included as a dependency in your project.

## ENSURE THE SHAPES API IS ADDED

In order for Approov tokens to be generated for `https://shapes.approov.io/v1/shapes` it is necessary to inform Approov about it:

```
approov api -add shapes.approov.io
```

Tokens for this domain will be automatically signed with the specific secret for this domain, rather than the normal one for your account.

## MODIFY THE APP TO USE APPROOV

Before using Approov you need to import the `ApproovAsyncHTTPClient` module. In the `ViewController.swift` source file import the service module by uncommenting line 19:

```swift
// *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
import ApproovAsyncHTTPClient
import AsyncHTTPClient
```

Uncomment the call in the ViewController.swift source file at line 31 and comment line 29 to create an ApproovHTTPClient instead of a HTTPClient:
```swift
// let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
// *** UNCOMMENT THE LINE BELOW FOR APPROOV (and comment the line above) ***
let httpClient: ApproovHTTPClient = ApproovHTTPClient(eventLoopGroupProvider: .createNew)
```

In the same file, locate and uncomment line 42 inside the `viewDidLoad` function that initializes the `ApproovService` and remember to add the `config` parameter. The Approov SDK needs a configuration string to identify the account associated with the app. You will have received this in your Approov onboarding email (it will be something like `#123456#K/XPlLtfcwnWkzv99Wj5VmAxo4CrU267J1KlQyoz8Qo=`):

```swift
try! ApproovService.initialize(config: "<enter-you-config-string-here>")
```

The configuration string can also be obtained by issuing this Approov CLI command:

```swift
approov sdk -getConfigString
```

The `ApproovAsyncHTTPClient` class automatically fetches an Approov token and adds it in the `Approov-Token` header. It also applies pinning for the connection to ensure that no Man-in-the-Middle can eavesdrop on any communication being made.
Lastly, make sure we are using the Approov protected endpoint for the shapes server. Find lines 116-118 in the `checkShapeAsyncAwait` function and change them as shown below to point to `v3/shapes`:

```swift
// let shapesURL = URL(string: "https://shapes.approov.io/v1/shapes")!
// *** UNCOMMENT THE LINE BELOW FOR APPROOV API PROTECTION (and comment the line above) ***
let shapesURL = URL(string: "https://shapes.approov.io/v3/shapes")!
```

## ADD YOUR SIGNING CERTIFICATE TO APPROOV

You should add the signing certificate used to sign apps. These are available in your Apple development account portal. Go to the initial screen showing program resources:

![Apple Program Resources](readme-images/program-resources.png)

Click on `Certificates` and you will be presented with the full list of development and distribution certificates for the account. Click on the certificate being used to sign applications from your particular Xcode installation and you will be presented with the following dialog:

![Download Certificate](readme-images/download-cert.png)

Now click on the `Download` button and a file with a `.cer` extension is downloaded, e.g. `development.cer`. Add it to Approov with:

```
approov appsigncert -add development.cer -autoReg
```

This ensures that any app signed with the certificate will be recognized by Approov.

If it is not possible to download the correct certificate from the portal then it is also possible to [add app signing certificates from the app](https://approov.io/docs/latest/approov-usage-documentation/#adding-apple-app-signing-certificates-from-app).

> **IMPORTANT:** Apps built to run on the iOS simulator are not code signed and thus auto-registration does not work for them. In this case you can consider [forcing a device ID to pass](https://approov.io/docs/latest/approov-usage-documentation/#forcing-a-device-id-to-pass) to get a valid attestation.

## RUNNING THE SHAPES APP WITH APPROOV

Run the app (without any debugger attached) and press the `Shape` button. You should now see this (or another shape):

<p>
    <img src="readme-images/shapes-good.png" width="256" title="Shapes Good">
</p>

This means that the app is getting a validly signed Approov token to present to the shapes endpoint.

## WHAT IF I DON'T GET SHAPES

If you still don't get a valid shape then there are some things you can try. Remember this may be because the device you are using has some characteristics that cause rejection for the currently set [Security Policy](https://approov.io/docs/latest/approov-usage-documentation/#security-policies) on your account:

* Ensure that the version of the app you are running is signed with the correct certificate.
* Look at the [`syslog`](https://developer.apple.com/documentation/os/logging) output from the device. Information about any Approov token fetched or an error is logged. You can easily [check](https://approov.io/docs/latest/approov-usage-documentation/#loggable-tokens) the validity.
* Use `approov metrics` to see [Live Metrics](https://approov.io/docs/latest/approov-usage-documentation/#metrics-graphs) of the cause of failure.
* You can use a debugger or simulator and get valid Approov tokens on a specific device by ensuring you are [forcing a device ID to pass](https://approov.io/docs/latest/approov-usage-documentation/#forcing-a-device-id-to-pass). As a shortcut, you can use the `latest` as discussed so that the `device ID` doesn't need to be extracted from the logs or an Approov token.
* Also, you can use a debugger and get valid Approov tokens on any device if you [mark the signing certificate as being for development](https://approov.io/docs/latest/approov-usage-documentation/#development-app-signing-certificates).
* Inspect any exceptions for additional information

## SHAPES APP WITH SECRETS PROTECTION

This section provides an illustration of an alternative option for Approov protection if you are not able to modify the backend to add an Approov token check. We continue to use `https://shapes.approov.io/v1/shapes/` that simply checks for an API key, so please revert the changes to the code so it uses `https://shapes.approov.io/v1/shapes/` in ViewController.swift at line 116.

```swift
let shapesURL = URL(string: "https://shapes.approov.io/v1/shapes")!
// *** UNCOMMENT THE LINE BELOW FOR APPROOV API PROTECTION (and comment the line above) ***
// let shapesURL = URL(string: "https://shapes.approov.io/v3/shapes")!
```

The `apiSecretKey` variable also needs to be changed as follows, removing the actual API key from the code in ViewController.swift, lines 43-45:

```swift
// let apiSecretKey = "yXClypapWNHIifHUWmBIyPFAm"
// *** UNCOMMENT THE LINE BELOW FOR APPROOV SECRETS PROTECTION (and comment the line above) ***
let apiSecretKey = "shapes_api_key_placeholder"
```

You must inform Approov that it should map `shapes_api_key_placeholder` to `yXClypapWNHIifHUWmBIyPFAm` (the actual API key) in requests as follows:

```
approov secstrings -addKey shapes_api_key_placeholder -predefinedValue yXClypapWNHIifHUWmBIyPFAm
```

> Note that this command requires an [admin role](https://approov.io/docs/latest/approov-usage-documentation/#account-access-roles).

Next we need to inform Approov that it needs to substitute the placeholder value for the real API key on the `Api-Key` header. Find line 44 and uncomment it as shown:

```swift
// *** UNCOMMENT THE LINE BELOW FOR APPROOV SECRETS PROTECTION ***
ApproovService.addSubstitutionHeader(header: "Api-Key", prefix: nil)
```

This processes the headers and replaces in the actual API key as required.

Run the app again and press the `Get Shape` button. You should now see this (or another shape):

<p>
    <img src="readme-images/shapes-good.png" width="256" title="Shapes Good">
</p>

This means that the app is able to access the API key, even though it is no longer embedded in the app code, and provide it to the shapes request.
