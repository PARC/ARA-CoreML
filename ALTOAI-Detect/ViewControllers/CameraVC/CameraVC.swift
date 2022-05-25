import UIKit
import Vision
import AVFoundation
import CoreMedia
import VideoToolbox
import ZIPFoundation
import RandomColorSwift

class CameraVC: UIViewController, UIDocumentPickerDelegate {
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var debugImageView: UIImageView!
 
    @IBOutlet weak var slidersVisibilityButton: UIButton!
    @IBOutlet weak var slidersView: UIView!
    
    @IBOutlet weak var confidenceSlider: UISlider!
    @IBOutlet weak var confidenceValueLabel: UILabel!
    @IBOutlet weak var iouSlider: UISlider!
    @IBOutlet weak var iouValueLabel: UILabel!
    
    var storeImage = true
    
    var yolo = YOLO()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeLabel.text = ""
        
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
        guard let model = yolo.model, let visionModel = try? VNCoreMLModel(for: model.model) else {
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
        videoCapture.fps = 50
        let preset = UIDevice.current.userInterfaceIdiom == .pad ? AVCaptureSession.Preset.vga640x480 : AVCaptureSession.Preset.hd1280x720
        videoCapture.setUp(sessionPreset: preset) { success in
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
    
    // MARK: -
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func toggleSlidersPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.slidersView.alpha = self?.slidersView.alpha == 1.0 ? 0.0 : 1.0
        }
    }
    
    func startVideoCapture() {
        self.videoCapture.start()
        isVideoCaptureStarted = true
    }
    
    func stopVideoCapture() {
        self.videoCapture.stop()
        isVideoCaptureStarted = false
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
    
    // MARK: - Rotation Stuff
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        //layer.videoOrientation = orientation
        self.videoCapture.previewLayer?.connection?.videoOrientation = orientation
        self.videoCapture.videoOutput.connection(with: AVMediaType.video)?.videoOrientation = orientation
        self.videoCapture.previewLayer?.frame = self.view.bounds
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  self.videoCapture.previewLayer?.connection  {
            
            let currentDevice: UIDevice = UIDevice.current
            
            let orientation: UIDeviceOrientation = currentDevice.orientation
            
            let previewLayerConnection : AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                
                }
            }
        }
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
        let tmpW = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let tmpH = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let yoloW = CGFloat(yolo.inputWidth)
        let yoloH = CGFloat(yolo.inputHeight)
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
            if storeImage {
                let fileManager = FileManager.default
                
                let documentsDirectory = fileManager.urls(for: .documentDirectory,
                                                             in: .userDomainMask).first!
                // to get images of correct dimensions instead of 2x
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let ciContext = CIContext()
                guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {return}
                let image = UIImage(cgImage: cgImage)
                //let image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
                let fileName = "image_\(self.frame_num).png"
                // create the destination file url to save your image
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                // get your UIImage jpeg data representation and check if the destination file url already exists
                if self.frame_num % 50 == 0,
                   let data = image.pngData(),
                   !FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        // writes the image data to disk

                        try data.write(to: fileURL)
                        print("file saved : \(fileURL)")
                    } catch {
                        print("error saving file:", error)
                    }
                }
                
                // let documentsDirectory = appSupportURL.appendingPathComponent("test.png")
                // to get images of correct dimensions instead of 2x
                let ciResizeImage = CIImage(cvPixelBuffer: resizedPixelBuffer)
                //let ciContext = CIContext()
                guard let cgResizeImage = ciContext.createCGImage(ciResizeImage, from: ciResizeImage.extent) else {return}
                let resizeimage = UIImage(cgImage: cgResizeImage)
                //let resizeimage = UIImage(ciImage: CIImage(cvPixelBuffer: resizedPixelBuffer))
                // self.frame_num  = self.frame_num+1
                
                
                let resizefileName = "resize_image_\(self.frame_num).png"
                // create the destination file url to save your image
                let resizefileURL = documentsDirectory.appendingPathComponent(resizefileName)
                // get your UIImage jpeg data representation and check if the destination file url already exists
                if self.frame_num % 50 == 0,
                   let data = resizeimage.pngData(),
                   !FileManager.default.fileExists(atPath: resizefileURL.path) {
                    do {
                        // writes the image data to disk
                        
                        try data.write(to: resizefileURL)
                        print("file saved : \(resizefileURL)")
                    } catch {
                        print("error saving file:", error)
                    }
                }
                self.frame_num  = self.frame_num+1
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
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer/*, orientation: CGImagePropertyOrientation.init(UIDevice.current.orientation)*/)
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
            self.timeLabel.text = String(format: "%.5f", elapsed)
            self.fpsLabel.text = String(format: "%.2f", fps)
            
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
                // on the video preview, which is as wide as the screen and has a 16:9
                // aspect ratio. The video preview also may be letterboxed at the top
                // and bottom.
                
                var width : CGFloat = 0
                var height : CGFloat = 0
                
                let videoRatio : CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 4 / 3 : 16 / 9
                
                let orientation = UIDevice.current.orientation
                let isPortrait = orientation == .portrait || orientation == .portraitUpsideDown
                if (isPortrait) {
                    width = videoPreview.bounds.width
                    height = width * videoRatio
                } else {
                    height = videoPreview.frame.height
                    width = height * videoRatio
                }
                
                let scaleX = width / CGFloat(yolo.inputWidth)
                let scaleY = height / CGFloat(yolo.inputHeight)
                
                //print("WH show method : \(width) , \(height), \(top)")
                
                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                if isPortrait {
                    rect.origin.y += (videoPreview.bounds.height - height) / 2
                } else {
                    rect.origin.x += (videoPreview.bounds.width - width) / 2
                }
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

extension CameraVC: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // For debugging.
        //predict(image: UIImage(named: "dog416")!); return
        
        semaphore.wait()
        
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            DispatchQueue.global().async { [self] in
//                let fileManager = FileManager.default
//
//                let documentsDirectory = fileManager.urls(for: .documentDirectory,
//                                                          in: .userDomainMask).first!
//
//                // let documentsDirectory = appSupportURL.appendingPathComponent("test.png")
//                if (storeImage) {
//                    let image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
//                    self.frame_num  = self.frame_num+1
//                    let fileName = "image_\(self.frame_num).jpg"
//                    // create the destination file url to save your image
//                    let fileURL = documentsDirectory.appendingPathComponent(fileName)
//                    // get your UIImage jpeg data representation and check if the destination file url already exists
//                    if let data = image.jpegData(compressionQuality: 1.0),
//                       !FileManager.default.fileExists(atPath: fileURL.path) {
//                        do {
//                            // writes the image data to disk
//
//                            try data.write(to: fileURL)
//                            print("file saved : \(fileURL)")
//                        } catch {
//                            print("error saving file:", error)
//                        }
//                    }
//                }
                
                self.predict(pixelBuffer: pixelBuffer)
                //self.predictUsingVision(pixelBuffer: pixelBuffer)
            }
        }
    }
}

extension CGImagePropertyOrientation {
  init(_ orientation: UIDeviceOrientation) {
    switch orientation {
    case .landscapeRight: self = .left
    case .landscapeLeft: self = .right
    case .portrait: self = .down
    case .portraitUpsideDown: self = .up
    default: self = .up
    }
  }
}
