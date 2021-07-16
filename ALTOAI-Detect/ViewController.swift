import UIKit
import Vision
import AVFoundation
import CoreMedia
import VideoToolbox
import ZIPFoundation
import RandomColorSwift

class ViewController: UIViewController, UIDocumentPickerDelegate {
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var debugImageView: UIImageView!
    @IBOutlet weak var stopStartButton: UIButton!
    
    @IBOutlet weak var confidenceSlider: UISlider!
    @IBOutlet weak var confidenceValueLabel: UILabel!
    @IBOutlet weak var iouSlider: UISlider!
    @IBOutlet weak var iouValueLabel: UILabel!
    
    var storeImage = false
    
    
    let yolo = YOLO()
    
    var frame_num = 0
    var videoCapture: VideoCapture!
    var isVideoCaptureStarted: Bool = false
    
    var request: VNCoreMLRequest!
    var startTimes: [CFTimeInterval] = []
    
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    
    let ciContext = CIContext()
    var resizedPixelBuffer: CVPixelBuffer?
    
    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()
    let semaphore = DispatchSemaphore(value: 2)
    
    var activityIndicator : ActivityIndicator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeLabel.text = ""
        activityIndicator = ActivityIndicator(view:self.view, navigationController:nil,tabBarController: nil)
        
        confidenceSlider.value = yolo.confidenceThreshold
        confidenceValueLabel.text = "\(String(format: "%.2f", confidenceSlider.value))"
        iouSlider.value = yolo.iouThreshold
        iouValueLabel.text = "\(String(format: "%.2f", iouSlider.value))"
        
        setUp()
        
        frameCapturingStartTime = CACurrentMediaTime()
    }
    
    func setUp() {
        setUpBoundingBoxes()
        setUpCoreImage()
        setUpVision()
        setUpCamera()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(#function)
    }
    
    // MARK: - Initialization
    
    func setUpBoundingBoxes() {
        boundingBoxes.forEach { boundingBox in
            boundingBox.shapeLayer.removeFromSuperlayer()
            boundingBox.textLayer.removeFromSuperlayer()
        }
        boundingBoxes.removeAll()
        for _ in 0..<yolo.maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        // Make colors for the bounding boxes. There is one color for each class,
        
        colors = randomColors(count: yolo.numClasses, luminosity: .light)
//        for r: CGFloat in [0.2, 0.4, 0.6, 0.8, 1.0] {
//            for g: CGFloat in [0.3, 0.6, 0.7, 0.8] {
//                for b: CGFloat in [0.2, 0.4, 0.8, 0.6, 1.0] {
//                    let color = UIColor(red: r, green: g, blue: b, alpha: 1)
//                    colors.append(color)
//                }
//            }
//        }
    }
    
    func setUpCoreImage() {
        let status = CVPixelBufferCreate(nil, yolo.inputWidth, yolo.inputHeight,
                                         kCVPixelFormatType_32BGRA, nil,
                                         &resizedPixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create resized pixel buffer", status)
        }
    }
    
    func setUpVision() {
        guard let visionModel = try? VNCoreMLModel(for: yolo.model.model) else {
            print("Error: could not create Vision model")
            return
        }
        
        request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
        
        // NOTE: If you choose another crop/scale option, then you must also
        // change how the BoundingBox objects get scaled when they are drawn.
        // Currently they assume the full input image is used.
        request.imageCropAndScaleOption = .scaleFill
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 40
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.vga640x480) { success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxes {
                    box.addToLayer(self.videoPreview.layer)
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
                self.isVideoCaptureStarted = true
            }
        }
    }
    
    
    //MARK: This is a sample code on download model from AWS S3 url. just for testing purpose only. The URL should be updated as per model path from  API
    
    @IBAction func startStop(_ sender: Any) {
        isVideoCaptureStarted ? stopVideoCapture() : startVideoCapture()
    }
    
    func startVideoCapture() {
        self.videoCapture.start()
        isVideoCaptureStarted = true
    }
    
    func stopVideoCapture() {
        self.videoCapture.stop()
        isVideoCaptureStarted = false
    }
    
    @IBAction func open(_ sender: Any) {
        stopVideoCapture()
        
        let documentPickerController = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType.zip], asCopy: true)
        documentPickerController.allowsMultipleSelection = false
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        activityIndicator?.showActivityIndicator()
        unzip(urls.first!)
    }
    
    func unzip(_ zipURL:URL) {
       // guard let zipURL = zipURL else { return }
        
        let fileManager = FileManager()
        var destinationURL = getDocumentsDirectory()
        
        destinationURL.appendPathComponent(zipURL.deletingPathExtension().lastPathComponent)
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            if (fileManager.fileExists(atPath: zipURL.path)) {
                try fileManager.unzipItem(at: zipURL, to: destinationURL)
                print("ZIP archive extracted to: \(destinationURL)")
            }
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
        }
        compileModel(at: destinationURL)
        startVideoCapture()
        activityIndicator?.stopActivityIndicator()
    }
    
    func compileModel(at url:URL) {
        var modelLoaded = false
        var jsonLoaded = false
        
        let fileManager = FileManager.default
        let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: url.path)!
        while let element = enumerator.nextObject() as? String {
            if (jsonLoaded && modelLoaded) {
                break
            }
            
            if (element.hasSuffix(".mlmodel")) {
                
                let modelURL = URL(fileURLWithPath: url.path+"/"+element)
                guard let compiledModelURL = try? MLModel.compileModel(at: modelURL)else {
                    print("Error in compiling model.")
                    return
                }
                guard let model = try? MLModel(contentsOf: compiledModelURL) else {
                    print("Error in getting model")
                    return
                }
                let yoloModel = yolo_model(model: model)
                yolo.model = yoloModel
                modelLoaded = true
                continue
            } else if (element.hasSuffix(".json")) {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: url.path+"/"+element), options: .mappedIfSafe)
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    print(json)
                    if let json = json as? Dictionary<String, AnyObject>, let model = json["model"] as? Dictionary<String, AnyObject> {
                        let input_shapes = model["input_shapes"] as? Dictionary ?? [:]
                        let height = input_shapes["height"] as? Int ?? 416
                        let width = input_shapes["width"] as? Int ?? 416
                        yolo.inputHeight = height
                        yolo.inputWidth = width
                        
                        let classes = model["classes"] as? Array<Dictionary<String, AnyObject>> ?? []
                        let names = classes.compactMap { $0["name"] } as! Array<String>
                        if (names.count>0) {
                            yolo.numClasses = names.count
                            yolo.labels = names
                            jsonLoaded = true
                        }
                    }
                } catch {
                    print("Error in getting json")
                }
                continue
            } else {
                continue
            }
        }
        if (jsonLoaded && modelLoaded) {
            setUp()
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        startVideoCapture()
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if (sender == confidenceSlider) {
            confidenceValueLabel.text = "\(String(format: "%.2f", confidenceSlider.value))"
            yolo.confidenceThreshold = confidenceSlider.value
        } else  if (sender == iouSlider) {
            iouValueLabel.text = "\(String(format: "%.2f", iouSlider.value))"
            yolo.iouThreshold = iouSlider.value
        }
    }
    
    @IBAction func downloadModel(_ sender: Any) {
        let logo_url = URL(string: "https://jey-public.s3-us-west-1.amazonaws.com/mlmodel/MobileNet.mlmodel")
        
//        let fileURL2 = URL(string: "https://ml-assets.apple.com/coreml/models/Image/ImageClassification/MobileNetV2/MobileNetV2.mlmodel")
        
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .documentDirectory,
                                             in: .userDomainMask).first!
        //Destination url, in our case Playground Shared Data Directory
        let documentsDirectory = appSupportURL.appendingPathComponent("MobileNet.mlmodel")
        let task = URLSession.shared.downloadTask(with: logo_url!) { localURL, urlResponse, error in
            if let localURL = localURL {
                print("if condition")
                let fileManager = FileManager.default
                do {
                    
                    if fileManager.fileExists(atPath: documentsDirectory.path) {
                        print("Already downloaded")
                    }
                    else {
                        // Copy from temporary location to custom location.
                        try fileManager.copyItem(at: localURL, to: documentsDirectory)
                        print("downloaded")
                    }
                    
                    
                }
                catch {
                    fatalError("Error in copying to documents directory \(error)")
                }
                
            }
            else{
                print("unable to download")
            }
        }
        task.resume()
        
        
    }
    
    // MARK: - UI stuff
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    // MARK: - Doing inference
    
    func predict(image: UIImage) {
        if let pixelBuffer = image.pixelBuffer(width: yolo.inputWidth, height: yolo.inputHeight) {
            predict(pixelBuffer: pixelBuffer)
        }
    }
    
    func predict(pixelBuffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame.
        let startTime = CACurrentMediaTime()
        
        // Resize the input with Core Image to 416x416.
        guard let resizedPixelBuffer = resizedPixelBuffer else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = CGFloat(yolo.inputWidth) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let sy = CGFloat(yolo.inputHeight) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        ciContext.render(scaledImage, to: resizedPixelBuffer)
        
//        print("image sizes : \(CGFloat(CVPixelBufferGetWidth(pixelBuffer))) , \(CGFloat(CVPixelBufferGetHeight(pixelBuffer)))")
        
        // This is an alternative way to resize the image (using vImage):
        //if let resizedPixelBuffer = resizePixelBuffer(pixelBuffer,
        //                                              width: YOLO.inputWidth,
        //                                              height: YOLO.inputHeight)
        
        // Resize the input to 416x416 and give it to our model.
        
        
        DispatchQueue.global().async { [self] in
            let fileManager = FileManager.default
            
            let documentsDirectory = fileManager.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first!
            
            // let documentsDirectory = appSupportURL.appendingPathComponent("test.png")
            
            let image = UIImage(ciImage: CIImage(cvPixelBuffer: resizedPixelBuffer))
            // self.frame_num  = self.frame_num+1
            
            if storeImage {
                let fileName = "resize_image_\(self.frame_num).jpg"
                // create the destination file url to save your image
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                // get your UIImage jpeg data representation and check if the destination file url already exists
                if let data = image.jpegData(compressionQuality: 1.0),
                   !FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        // writes the image data to disk
                        
                        try data.write(to: fileURL)
                        print("file saved : \(fileURL)")
                    } catch {
                        print("error saving file:", error)
                    }
                }
            }
        }
        
        
        if let boundingBoxes = try? yolo.predict(image: resizedPixelBuffer) {
            let elapsed = CACurrentMediaTime() - startTime
            showOnMainThread(boundingBoxes, elapsed)
        }
    }
    
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame. Note that
        // predict() can be called on the next frame while the previous one is
        // still being processed. Hence the need to queue up the start times.
        startTimes.append(CACurrentMediaTime())
        
        // Vision will automatically resize the input image.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let features = observations.first?.featureValue.multiArrayValue {
            
            let boundingBoxes = yolo.computeBoundingBoxes(features: features)
            let elapsed = CACurrentMediaTime() - startTimes.remove(at: 0)
            showOnMainThread(boundingBoxes, elapsed)
        }
    }
    
    func showOnMainThread(_ boundingBoxes: [YOLO.Prediction], _ elapsed: CFTimeInterval) {
        DispatchQueue.main.async {
            // For debugging, to make sure the resized CVPixelBuffer is correct.
            //var debugImage: CGImage?
            //VTCreateCGImageFromCVPixelBuffer(resizedPixelBuffer, nil, &debugImage)
            //self.debugImageView.image = UIImage(cgImage: debugImage!)
            
            self.show(predictions: boundingBoxes)
            
            let fps = self.measureFPS()
            self.timeLabel.text = String(format: "Elapsed %.5f seconds - %.2f FPS", elapsed, fps)
            
            self.semaphore.signal()
        }
    }
    
    func measureFPS() -> Double {
        // Measure how many frames were actually delivered per second.
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }
        return currentFPSDelivered
    }
    
    func show(predictions: [YOLO.Prediction]) {
        //print("Show method called ! ")
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                // The predicted bounding box is in the coordinate space of the input
                // image, which is a square image of 416x416 pixels. We want to show it
                // on the video preview, which is as wide as the screen and has a 4:3
                // aspect ratio. The video preview also may be letterboxed at the top
                // and bottom.
                let width = videoPreview.bounds.width
                let height = videoPreview.bounds.height // width * 4 / 3
                
                //        width  = 480.0
                //        height = 640.0
                
                let scaleX = width / CGFloat(yolo.inputWidth)
                let scaleY = height / CGFloat(yolo.inputHeight)
                // print("Scaled values: \(scaleX, scaleY)")
                //        scaleX = width / 480.0
                //        scaleY = height / 640.0
                
                let top = (view.bounds.height - height) / 2
                //print("WH show method : \(width) , \(height), \(top)")
                
                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                rect.origin.y += top
                rect.size.width *= scaleX
                rect.size.height *= scaleY
                
                // Show the bounding box.

                let label = String(format: "%@ %.2f", yolo.labels.count > prediction.classIndex ? yolo.labels[prediction.classIndex] : "Object_\(prediction.classIndex)", prediction.score)
                let color = colors[prediction.classIndex]
                // print("Printing Calculated Rectangle : \(rect)")
                boundingBoxes[i].show(frame: rect, label: label, color: color)
            } else {
                boundingBoxes[i].hide()
            }
        }
    }
}

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // For debugging.
        //predict(image: UIImage(named: "dog416")!); return
        
        semaphore.wait()
        
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            DispatchQueue.global().async { [self] in
                let fileManager = FileManager.default
                
                let documentsDirectory = fileManager.urls(for: .documentDirectory,
                                                          in: .userDomainMask).first!
                
                // let documentsDirectory = appSupportURL.appendingPathComponent("test.png")
                if (storeImage) {
                    let image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
                    self.frame_num  = self.frame_num+1
                    let fileName = "image_\(self.frame_num).jpg"
                    // create the destination file url to save your image
                    let fileURL = documentsDirectory.appendingPathComponent(fileName)
                    // get your UIImage jpeg data representation and check if the destination file url already exists
                    if let data = image.jpegData(compressionQuality: 1.0),
                       !FileManager.default.fileExists(atPath: fileURL.path) {
                        do {
                            // writes the image data to disk
                            
                            try data.write(to: fileURL)
                            print("file saved : \(fileURL)")
                        } catch {
                            print("error saving file:", error)
                        }
                    }
                }
                
                self.predict(pixelBuffer: pixelBuffer)
                //self.predictUsingVision(pixelBuffer: pixelBuffer)
            }
        }
    }
}
