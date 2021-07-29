//
//  yolo_model.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 15.07.2021.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class yolo_modelInput : MLFeatureProvider {

    /// inputs as color (kCVPixelFormatType_32BGRA) image buffer, 416 pixels wide by 416 pixels high
    var inputs: CVPixelBuffer

    var featureNames: Set<String> {
        get {
            return ["inputs"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "inputs") {
            return MLFeatureValue(pixelBuffer: inputs)
        }
        return nil
    }
    
    init(inputs: CVPixelBuffer) {
        self.inputs = inputs
    }

    convenience init(inputsWith inputs: CGImage) throws {
        let __inputs = try MLFeatureValue(cgImage: inputs, pixelsWide: 416, pixelsHigh: 416, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
        self.init(inputs: __inputs)
    }

    convenience init(inputsAt inputs: URL) throws {
        let __inputs = try MLFeatureValue(imageAt: inputs, pixelsWide: 416, pixelsHigh: 416, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
        self.init(inputs: __inputs)
    }

    func setInputs(with inputs: CGImage) throws  {
        self.inputs = try MLFeatureValue(cgImage: inputs, pixelsWide: 416, pixelsHigh: 416, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }

    func setInputs(with inputs: URL) throws  {
        self.inputs = try MLFeatureValue(imageAt: inputs, pixelsWide: 416, pixelsHigh: 416, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }
}


/// Model Prediction Output Type
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class yolo_modelOutput : MLFeatureProvider {

    /// Source provided by CoreML

    private let provider : MLFeatureProvider


    /// predictions as 2535 by 6 matrix of floats
    lazy var predictions: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "predictions")!.multiArrayValue
    }()!

    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(predictions: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["predictions" : MLFeatureValue(multiArray: predictions)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class yolo_model {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "yolo-v3-tiny-416x416-face-detector", withExtension:"mlmodelc")!
    }

    /**
        Construct yolo_model instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of yolo_model.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `yolo_model.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct yolo_model instance by automatically loading the model from the app's bundle.
    */
    @available(*, deprecated, message: "Use init(configuration:) instead and handle errors appropriately.")
    convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct yolo_model instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct yolo_model instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<yolo_model, Error>) -> Void) {
        return self.load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct yolo_model instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<yolo_model, Error>) -> Void) {
        MLModel.__loadContents(of: modelURL, configuration: configuration) { (model, error) in
            if let error = error {
                handler(.failure(error))
            } else if let model = model {
                handler(.success(yolo_model(model: model)))
            } else {
                fatalError("SPI failure: -[MLModel loadContentsOfURL:configuration::completionHandler:] vends nil for both model and error.")
            }
        }
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as yolo_modelInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as yolo_modelOutput
    */
    func prediction(input: yolo_modelInput) throws -> yolo_modelOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as yolo_modelInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as yolo_modelOutput
    */
    func prediction(input: yolo_modelInput, options: MLPredictionOptions) throws -> yolo_modelOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return yolo_modelOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        - parameters:
            - inputs as color (kCVPixelFormatType_32BGRA) image buffer, 416 pixels wide by 416 pixels high

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as yolo_modelOutput
    */
    func prediction(inputs: CVPixelBuffer) throws -> yolo_modelOutput {
        let input_ = yolo_modelInput(inputs: inputs)
        return try self.prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        - parameters:
           - inputs: the inputs to the prediction as [yolo_modelInput]
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [yolo_modelOutput]
    */
    func predictions(inputs: [yolo_modelInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [yolo_modelOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [yolo_modelOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  yolo_modelOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
