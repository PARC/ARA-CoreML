import Foundation
import UIKit
import CoreML

class YOLO {
  public static let inputWidth = 416
  public static let inputHeight = 416
  public static let maxBoundingBoxes = 10

  // Tweak these values to get more or fewer predictions.
  let confidenceThreshold: Float = 0.6
  let iouThreshold: Float = 0.6

  struct Prediction {
    let classIndex: Int
    let score: Float
    let rect: CGRect
  }

  //let model = Yolov3()
  //let model = model_b405_new()
let model = yolo_v3_tiny_trained()
  public init() { }

  public func predict(image: CVPixelBuffer) throws -> [Prediction] {
    //if let output = try? model.prediction(input1: image) {
    if let output = try? model.prediction(inputs: image) {

        //return computeBoundingBoxes(features: [output.output1, output.output2, output.output3])
        return computeBoundingBoxes(features: output.predictions)
    } else {
      return []
    }
  }

  public func computeBoundingBoxes( features: MLMultiArray) -> [Prediction] {
 

    var predictions = [Prediction]()

    let blockSize: Float = 32
    let numClasses = 5
    var boxesPerCell = features.count / (numClasses+5)
    boxesPerCell = 3
    
    var increment = numClasses+5

    
    var anchors2 = [(81, 82), (135, 169), (344, 319)]


    
    
    func offset(_ channel: Int, _ x: Int, _ y: Int) -> Int {
      return channel + y + x
    }
    var total_bbox = (features.count) / (numClasses + 5)
    

    for j in 0..<total_bbox {
        
        
        
    var tx = Float(features[0+(increment*j)])
        
    var ty = Float(features[1+(increment*j)])
    var tw = Float(features[2+(increment*j)])
                        //print("pointer : \(3+(11*i))")
                        //print("th : \(features[14336])")
    var th = Float(features[3+(increment*j)])
        
        
    //tx  = tx/416.0 * (416.0)
    let tc = Float(features[4+(increment*j)])
    let confidence = sigmoid(tc)
   
          //image sizes : 480.0 , 640.0
     
    var class_probs = [Float](repeating: 0, count: numClasses)
        
        
    for c in 0..<numClasses {
        class_probs[c] = Float(features[5+c+(increment*j)])
    }
        
    let (detectedClass, bestClassScore) = class_probs.argmax()
   // print("tc :  \(tc),confidence : \(confidence)")
    // print("confidence, detectedClass, bestClassScore : ",confidence, detectedClass, bestClassScore)
    let confidenceInClass = bestClassScore * confidence
   // print("confidenceInClass  : ",confidenceInClass)
        
    if confidenceInClass >= confidenceThreshold {
        let rect = CGRect(x: CGFloat(tx)  - (CGFloat(tw)/2), y: CGFloat(ty) - (CGFloat(th)/2),
                                    width: CGFloat(tw), height: CGFloat(th))
        
        let prediction = Prediction(classIndex: detectedClass,score:    confidenceInClass,rect: rect)
        predictions.append(prediction)
    }
    }
   // }
    let filtered = nonMaxSuppression(boxes: predictions, limit: 20, threshold: iouThreshold)
        
   print(filtered)
    
    
    
    // We already filtered out any bounding boxes that have very low scores,
    // but there still may be boxes that overlap too much with others. We'll
    // use "non-maximum suppression" to prune those duplicate bounding boxes.
    
    if (predictions.count <=  5){
    return  predictions
    }
    else {
    return filtered
    }
    }
        //nonMaxSuppression(boxes: predictions, limit: YOLO.maxBoundingBoxes, threshold: iouThreshold)
  
}
