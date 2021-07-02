import UIKit
import Vision
import AVFoundation
import CoreMedia
import VideoToolbox

class ViewController: UIViewController {
  @IBOutlet weak var videoPreview: UIView!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var debugImageView: UIImageView!
    
    var boolstoreImage = false

   
    let yolo = YOLO()
    
  var frame_num = 0
  var videoCapture: VideoCapture!
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

    setUpBoundingBoxes()
    setUpCoreImage()
    setUpVision()
    setUpCamera()

    frameCapturingStartTime = CACurrentMediaTime()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print(#function)
  }

  // MARK: - Initialization

  func setUpBoundingBoxes() {
    for _ in 0..<YOLO.maxBoundingBoxes {
      boundingBoxes.append(BoundingBox())
    }

    // Make colors for the bounding boxes. There is one color for each class,
    // 80 classes in total.
    for r: CGFloat in [0.2, 0.4, 0.6, 0.8, 1.0] {
      for g: CGFloat in [0.3, 0.7, 0.6, 0.8] {
        for b: CGFloat in [0.4, 0.8, 0.6, 1.0] {
          let color = UIColor(red: r, green: g, blue: b, alpha: 1)
          colors.append(color)
        }
      }
    }
  }

  func setUpCoreImage() {
    let status = CVPixelBufferCreate(nil, YOLO.inputWidth, YOLO.inputHeight,
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
    videoCapture.fps = 50
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
      }
    }
  }

    
    //MARK: This is a sample code on download model from AWS S3 url. just for testing purpose only. The URL should be updated as per model path from  API
    
    
    @IBAction func downloadModel(_ sender: Any) {
        let logo_url = URL(string: "https://jey-public.s3-us-west-1.amazonaws.com/mlmodel/MobileNet.mlmodel")
          
          let fileURL2 = URL(string: "https://ml-assets.apple.com/coreml/models/Image/ImageClassification/MobileNetV2/MobileNetV2.mlmodel")
          
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
    if let pixelBuffer = image.pixelBuffer(width: YOLO.inputWidth, height: YOLO.inputHeight) {
      predict(pixelBuffer: pixelBuffer)
    }
  }

  func predict(pixelBuffer: CVPixelBuffer) {
    
    
    var storeImage = false
    // Measure how long it takes to predict a single video frame.
    let startTime = CACurrentMediaTime()

    // Resize the input with Core Image to 416x416.
    guard let resizedPixelBuffer = resizedPixelBuffer else { return }
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let sx = CGFloat(YOLO.inputWidth) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
    let sy = CGFloat(YOLO.inputHeight) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
    let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
    let scaledImage = ciImage.transformed(by: scaleTransform)
    ciContext.render(scaledImage, to: resizedPixelBuffer)
    
    print("image sizes : \(CGFloat(CVPixelBufferGetWidth(pixelBuffer))) , \(CGFloat(CVPixelBufferGetHeight(pixelBuffer)))")

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
    if let data = UIImageJPEGRepresentation(image,1.0),
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
        var width = view.bounds.width
        var height = width * 4 / 3
        
//        width  = 480.0
//        height = 640.0
        
        
        //image sizes : 480.0 , 640.0
        //WH show method : 375.0 , 500.0

        
        //print("WH show method : \(width) , \(height)")

        var scaleX = width / CGFloat(YOLO.inputWidth)
        var scaleY = height / CGFloat(YOLO.inputHeight)
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
        let label = String(format: "%@ %.1f", b405_labels[prediction.classIndex], prediction.score * 100)
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

        let image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
            self.frame_num  = self.frame_num+1
            let fileName = "image_\(self.frame_num).jpg"
        // create the destination file url to save your image
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        // get your UIImage jpeg data representation and check if the destination file url already exists
        if let data = UIImageJPEGRepresentation(image,1.0),
          !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                // writes the image data to disk
                
                try data.write(to: fileURL)
                print("file saved : \(fileURL)")
            } catch {
                print("error saving file:", error)
            }
        }
        
        self.predict(pixelBuffer: pixelBuffer)
        //self.predictUsingVision(pixelBuffer: pixelBuffer)
      }
    }
  }
}
