//
//  ViewController.swift
//  Deeplab
//
//  Created by mac-webgl-stable on 12/21/18.
//  Copyright © 2018 mac-webgl-stable. All rights reserved.
//

import Cocoa
//class ViewController: NSViewController {
//
//  override func viewDidLoad() {
//    super.viewDidLoad()
//
//    // Do any additional setup after loading the view.
//  }
//
//  override var representedObject: Any? {
//    didSet {
//    // Update the view, if already loaded.
//    }
//  }
//
//
//}

import CoreML

class ViewController: NSViewController {
  
  enum SelectedModel: Int {
    case fuse = 0, dsn5, dsn4, dsn3, dsn2, dsn1
    
    var outputLayerName: String {
      switch self {
      case .fuse:
        return "upscore-fuse"
      case .dsn5:
        return "upscore-dsn5"
      case .dsn4:
        return "upscore-dsn4"
      case .dsn3:
        return "upscore-dsn3"
      case .dsn2:
        return "upscore-dsn2"
      case .dsn1:
        return "upscore-dsn1"
      }
    }
  }
  
//  let hedMain = HED_fuse()
  let deep_lab = deeplab()

  var selectedModel: SelectedModel = .fuse
  
  var cachedCalculationResults: [SelectedModel : NSImage] = [:]
  
  @IBOutlet weak var resultsSegmentedControl: NSSegmentedControl!
  @IBOutlet weak var imageView: NSImageView!
  var inputImage: NSImage!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.inputImage = NSImage(named: "pic1.jpg")
//    self.imageView.image = inputImage
    
    // Remember the time when we started
    let startDate = Date()
    
    // Convert our image to proper input format
    // In this case we need to feed pixel buffer which is 500x500 sized.
    let inputW = 500
    let inputH = 500
//    guard let inputPixelBuffer = inputImage.resized(to: NSSize(width: inputW, height: inputH))
//      .pixelBuffer(width: inputW, height: inputH) else {
//        fatalError("Couldn't create pixel buffer.")
//    }
    
//    guard let inputPixelData = inputImage.resized(to: NSSize(width: inputW, height: inputH))
//      .pixelData() else {
//        fatalError("Couldn't create pixel buffer.")
//    }
    
    // Use different models based on what output we need
    let featureProvider: MLFeatureProvider
//    featureProvider = try! hedMain.prediction(data: inputPixelBuffer)
    
    let multiArray: MLMultiArray?;
    multiArray = preprocess(image: self.inputImage, width: 513, height: 513)
    
    featureProvider = try! deep_lab.prediction(sub_7__0: multiArray!)
    
    // Retrieve results
    guard let outputFeatures = featureProvider.featureValue(for: "ResizeBilinear_3__0")?.multiArrayValue else {
      fatalError("Couldn't retrieve features")
    }
    
    // Calculate total buffer size by multiplying shape tensor's dimensions
    let bufferSize = outputFeatures.shape.lazy.map { $0.intValue }.reduce(1, { $0 * $1 })
    
    // Get data pointer to the buffer
    let dataPointer = UnsafeMutableBufferPointer(start: outputFeatures.dataPointer.assumingMemoryBound(to: Double.self),
                                                 count: bufferSize)
    
    for i in 0..<bufferSize {
      let value = dataPointer[i]
      NSLog("float:%f ",value);
    }
    // Prepare buffer for single-channel image result
    var imgData = [UInt8](repeating: 0, count: bufferSize)
    
    // Normalize result features by applying sigmoid to every pixel and convert to UInt8
    for i in 0..<inputW {
      for j in 0..<inputH {
        let idx = i * inputW + j
        let value = dataPointer[idx]
        
        let sigmoid = { (input: Double) -> Double in
          return 1 / (1 + exp(-input))
        }
        
        let result = sigmoid(value)
        imgData[idx] = UInt8(result * 255)
      }
    }
    
    // Create single chanel gray-scale image out of our freshly-created buffer
    let cfbuffer = CFDataCreate(nil, &imgData, bufferSize)!
    let dataProvider = CGDataProvider(data: cfbuffer)!
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let cgImage = CGImage(width: inputW, height: inputH, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: inputW, space: colorSpace, bitmapInfo: [], provider: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    let resultImage = NSImage(cgImage: cgImage!, size: NSSize(width: inputW, height: inputH))
    
    // Calculate the time of inference
    let endDate = Date()
    print("Inference is finished in \(endDate.timeIntervalSince(startDate)) for model: \(self.selectedModel.outputLayerName)")
    
    // Cache results
    self.cachedCalculationResults[self.selectedModel] = resultImage
    
    // Enable edge-mode results
    //    self.resultsSegmentedControl.setEnabled(true, forSegmentAt: 1)
  }
  
  
  public func preprocess(image: NSImage, width: Int, height: Int) -> MLMultiArray? {
    let size = CGSize(width: 513, height: 513)
    
    
    guard let pixels = image.resized(to: size).pixelData()?.map({ (Double($0) / 127.5 - 1)}) else {
      return nil
    }
    
    guard let array = try? MLMultiArray(shape: [3, height, width] as [NSNumber], dataType: .double) else {
      return nil
    }
    
    let r = pixels.enumerated().filter { $0.offset % 4 == 0 }.map { $0.element }
    let g = pixels.enumerated().filter { $0.offset % 4 == 1 }.map { $0.element }
    let b = pixels.enumerated().filter { $0.offset % 4 == 2 }.map { $0.element }
    
    let combination = r + g + b
    for (index, element) in combination.enumerated() {
      array[index] = NSNumber(value: element)
    }
    
    return array
  }
  
  @IBAction func selectedResultsChanged(_ sender: NSSegmentedControl) {
    if sender.selectedSegment == 0 {
      self.imageView.image = self.inputImage
    } else {
//      self.imageView.image = self.cachedCalculationResults[self.selectedModel]
    }
  }
  
  @IBAction func selectedModelChanged(_ sender: NSSegmentedControl) {
    self.selectedModel = SelectedModel(rawValue: sender.selectedSegment)!
    
    if cachedCalculationResults[selectedModel] == nil {
      resultsSegmentedControl.selectedSegment = 0
//      resultsSegmentedControl.setEnabled(false, forSegmentAt: 1)
      
//      self.imageView.image = self.inputImage
    } else {
//      resultsSegmentedControl.setEnabled(true, forSegmentAt: 1)
//      if resultsSegmentedControl.selectedSegmentIndex == 1 {
//        self.imageView.image = cachedCalculationResults[self.selectedModel]
//      }
    }
  }
  
  @IBAction func doInferencePressed(_ sender: NSButton) {
    guard cachedCalculationResults[selectedModel] == nil else {
      return
    }
    
    
  }
}

