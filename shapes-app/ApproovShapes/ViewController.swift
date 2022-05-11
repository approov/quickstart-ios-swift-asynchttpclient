// MIT License
//
// Copyright (c) 2016-present, Critical Blue Ltd.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
// import ApproovAsyncHTTPClient
import AsyncHTTPClient
import UIKit


class ViewController: UIViewController {
    
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusTextView: UILabel!

    let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
    // *** UNCOMMENT THE LINE BELOW FOR APPROOV (and comment the line above) ***
    // let httpClient: ApproovHTTPClient = ApproovHTTPClient(eventLoopGroupProvider: .createNew)

    // API key for https://shapes.approov.io/v1/shapes and https://shapes.approov.io/v3/shapes
    let apiKeyHeaderName = "Api-Key"
    let apiSecretKey = "yXClypapWNHIifHUWmBIyPFAm"
    // *** UNCOMMENT THE LINE BELOW FOR APPROOV SECRET PROTECTION (and comment the line above) ***
    // let apiSecretKey = "shapes_api_key_placeholder"

    override func viewDidLoad() {
        super.viewDidLoad()
        // *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
        // try! ApproovService.initialize(config: "<enter-your-config-string-here>")
        // *** UNCOMMENT THE LINE BELOW FOR APPROOV SECRET PROTECTION ***
        // ApproovService.addSubstitutionHeader(header: apiKeyHeaderName, prefix: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    /*
     * Check unprotected hello endpoint
     */
    @IBAction func checkHello() {
        Task() {
            let helloURL = URL(string: "https://shapes.approov.io/v1/hello")!

            // Display busy screen
            DispatchQueue.main.async {
                self.statusImageView.image = UIImage(named: "approov")
                self.statusTextView.text = "Checking connectivity..."
            }

            let message: String
            let image: UIImage?
            let request = HTTPClientRequest(url: helloURL.absoluteString)
            do {
                let response = try await httpClient.execute(request, timeout: .seconds(30))
                if response.status == .ok {
                    // successful http response
                    message = "\(response.status.code): OK"
                    image = UIImage(named: "hello")
                } else {
                    // unexpected http response
                    message = "\(response.status.code): \(response.status.reasonPhrase)"
                    image = UIImage(named: "confused")
                }
            } catch {
                // other networking failure
                message = "Networking error: \(error.localizedDescription)"
                image = UIImage(named: "confused")
            }
            NSLog("\(helloURL): \(message)")

            // Display the image on screen using the main queue
            DispatchQueue.main.async {
                self.statusImageView.image = image
                self.statusTextView.text = message
            }
        }
    }

    /*
     * Check Approov-protected shapes endpoint
     */
    @IBAction func checkShape() {
        checkShapeAsyncAwait()
        /*
         * EITHER
         *     uncomment the checkShapeAsyncAwait() call above for using AsyncHTTPClient with Swift concurrency
         *     (async/await) and comment out the call to checkShapeEventLoopFuture() below
         * OR
         *     uncomment the checkShapeEventLoopFuture() call below for using AsyncHTTPClient with a SwiftNIO
         *     EventLoopFuture and comment out the call to checkShapeAsyncAwait() above
         */
        // checkShapeEventLoopFuture()
    }

    /*
     * Check Approov-protected shapes endpoint using Swift concurrency async/await
     */
    @IBAction func checkShapeAsyncAwait() {
        Task() {
            // URL for shapes API
            let shapesURL = URL(string: "https://shapes.approov.io/v1/shapes")!
            // *** UNCOMMENT THE LINE BELOW FOR APPROOV (and comment the line above) ***
            // let shapesURL = URL(string: "https://shapes.approov.io/v3/shapes")!

            // Display busy screen
            DispatchQueue.main.async {
                self.statusImageView.image = UIImage(named: "approov")
                self.statusTextView.text = "Checking app authenticity (async/await)..."
            }

            let message: String
            let image: UIImage?
            var request = HTTPClientRequest(url: shapesURL.absoluteString)
            request.headers.add(name: apiKeyHeaderName, value: apiSecretKey)
            do {
                let response = try await httpClient.execute(request, timeout: .seconds(30))
                if response.status == .ok {
                    // Successful http response
                    let data = try await response.body.collect(upTo: 1024 * 1024) // 1 MB
                        // Unmarshal the JSON response
                        do {
                        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                            let jsonDict = jsonObject as? [String: Any]
                            let shape = (jsonDict!["shape"] as? String)!.lowercased()
                            switch shape {
                            case "circle":
                            message = "\(response.status.code): Approoved!"
                                image = UIImage(named: "Circle")
                            case "rectangle":
                            message = "\(response.status.code): Approoved!"
                                image = UIImage(named: "Rectangle")
                            case "square":
                            message = "\(response.status.code): Approoved!"
                                image = UIImage(named: "Square")
                            case "triangle":
                            message = "\(response.status.code): Approoved!"
                                image = UIImage(named: "Triangle")
                            default:
                            message = "\(response.status.code): Approoved: unknown shape '\(shape)'"
                                image = UIImage(named: "confused")
                            }
                        } catch {
                        message = "\(response.status.code): Invalid JSON from Shapes response"
                            image = UIImage(named: "confused")
                        }
                    } else {
                        // Unexpected http response
                        message = "\(response.status.code): \(response.status.reasonPhrase)"
                            image = UIImage(named: "confused")
                    }
            } catch {
                // Other networking failure
                message = "Networking error: \(error.localizedDescription)"
                image = UIImage(named: "confused")
            }
            NSLog("\(shapesURL): \(message)")

            // Display the image on screen using the main queue
            DispatchQueue.main.async {
                self.statusImageView.image = image
                self.statusTextView.text = message
            }
        }
    }

    /*
     * Check Approov-protected shapes endpoint using
     */
    @IBAction func checkShapeEventLoopFuture() {
        // URL for shapes API
        let shapesURL = URL(string: "https://shapes.approov.io/v1/shapes")!
        // *** UNCOMMENT THE LINE BELOW FOR APPROOV (and comment the line above) ***
        // let shapesURL = URL(string: "https://shapes.approov.io/v3/shapes")!

        // Display busy screen
        DispatchQueue.main.async {
            self.statusImageView.image = UIImage(named: "approov")
            self.statusTextView.text = "Checking app authenticity (background task)..."
        }

        do {
            var request = try HTTPClient.Request(url: shapesURL.absoluteString, method: .GET)
            request.headers.add(name: apiKeyHeaderName, value: apiSecretKey)

            httpClient.execute(request: request).whenComplete { result in
                let message: String
                let image: UIImage?
                switch result {
                case .failure(let error):
                    // process error
                    // Other networking failure
                    message = "Networking error: \(error.localizedDescription)"
                    image = UIImage(named: "confused")
                case .success(let response):
                    if response.status == .ok {
                        // handle response
                        // Successful http response
                        let data = response.body! // 1 MB
                            // Unmarshal the JSON response
                            do {
                            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                                let jsonDict = jsonObject as? [String: Any]
                                let shape = (jsonDict!["shape"] as? String)!.lowercased()
                                switch shape {
                                case "circle":
                                message = "\(response.status.code): Approoved!"
                                    image = UIImage(named: "Circle")
                                case "rectangle":
                                message = "\(response.status.code): Approoved!"
                                    image = UIImage(named: "Rectangle")
                                case "square":
                                message = "\(response.status.code): Approoved!"
                                    image = UIImage(named: "Square")
                                case "triangle":
                                message = "\(response.status.code): Approoved!"
                                    image = UIImage(named: "Triangle")
                                default:
                                message = "\(response.status.code): Approoved: unknown shape '\(shape)'"
                                    image = UIImage(named: "confused")
                                }
                            } catch {
                            message = "\(response.status.code): Invalid JSON from Shapes response"
                                image = UIImage(named: "confused")
                            }
                    } else {
                        // handle remote error
                        // Unexpected http response
                        message = "\(response.status.code): \(response.status.reasonPhrase)"
                            image = UIImage(named: "confused")
                    }
                }
                NSLog("\(shapesURL): \(message)")
                // Display the image on screen using the main queue
                DispatchQueue.main.async {
                    self.statusImageView.image = image
                    self.statusTextView.text = message
                }
            }
        } catch {
            // Other failure
            let message = "Error: \(error.localizedDescription)"
            NSLog("\(shapesURL): \(message)")
            // Display the image on screen using the main queue
            DispatchQueue.main.async {
                self.statusImageView.image = UIImage(named: "confused")
                self.statusTextView.text = message
            }
        }
    }

}
