import Foundation
import UIKit
import CoreML

class YOLO {
    var inputWidth = 416
    var inputHeight = 416
    var maxBoundingBoxes = 20
    var numClasses = 1
    
    var labels = ["face"]
    
    // Tweak these values to get more or fewer predictions.
    var confidenceThreshold: Float = 0.6
    var iouThreshold: Float = 0.5
    
    struct Prediction {
        let classIndex: Int
        let score: Float
        let rect: CGRect
    }
    
    var model : yolo_model = yolo_model(model: yolo_v3_tiny_416x416_face_detector().model)
    
    public init() { }
    
    public func predict(image: CVPixelBuffer) throws -> [Prediction] {
        if let output = try? model.prediction(inputs: image) {
            return computeBoundingBoxes(features: output.predictions)
        } else {
            return []
        }
    }
    
    public func computeBoundingBoxes( features: MLMultiArray) -> [Prediction] {
        var predictions = [Prediction]()
        
        let increment = numClasses+5
        let total_bbox = (features.count) / (numClasses + 5)
        
        for j in 0..<total_bbox {
            
            let tx = Float(truncating: features[0+(increment*j)])
            let ty = Float(truncating: features[1+(increment*j)])
            let tw = Float(truncating: features[2+(increment*j)])
            let th = Float(truncating: features[3+(increment*j)])
            
            let tc = Float(truncating: features[4+(increment*j)])
            let confidence = sigmoid(tc)
            
            var class_probs = [Float](repeating: 0, count: numClasses)
            
            for c in 0..<numClasses {
                class_probs[c] = Float(truncating: features[5+c+(increment*j)])
            }
            
            let (detectedClass, bestClassScore) = class_probs.argmax()

            let confidenceInClass = bestClassScore * confidence
            
            if confidenceInClass >= confidenceThreshold {
                let rect = CGRect(x: CGFloat(tx)  - (CGFloat(tw)/2), y: CGFloat(ty) - (CGFloat(th)/2),
                                  width: CGFloat(tw), height: CGFloat(th))
                
                let prediction = Prediction(classIndex: detectedClass,score:    confidenceInClass,rect: rect)
                predictions.append(prediction)
            }
        }
        
        // We already filtered out any bounding boxes that have very low scores,
        // but there still may be boxes that overlap too much with others. We'll
        // use "non-maximum suppression" to prune those duplicate bounding boxes.
        
        
        return  nonMaxSuppression(boxes: predictions, limit: maxBoundingBoxes, threshold: iouThreshold)
        
    }
    
}

