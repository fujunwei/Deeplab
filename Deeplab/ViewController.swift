//
//  ViewController.swift
//  Deeplab
//
//  Created by mac-webgl-stable on 12/21/18.
//  Copyright © 2018 mac-webgl-stable. All rights reserved.
//

import Cocoa
import CoreML

class ViewController: NSViewController {
  let deep_lab = deeplab()
  var inputImage: NSImage!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.inputImage = NSImage(named: "woman.jpg")
    
    // Convert our image to proper input format
    // In this case we need to feed pixel buffer which is 513*513 sized.
    let inputW = 513
    let inputH = 513
    
    // Use different models based on what output we need
    let multiArray: MLMultiArray?;
    multiArray = preprocess(image: self.inputImage, width: inputW, height: inputH)
    
    let featureProvider: MLFeatureProvider
    featureProvider = try! deep_lab.prediction(sub_7__0: multiArray!)
    
    // Retrieve results
    guard let outputFeatures = featureProvider.featureValue(
        for: "ResizeBilinear_3__0")?.multiArrayValue else {
      fatalError("Couldn't retrieve features")
    }
    
    // Calculate total buffer size by multiplying shape tensor's dimensions
    let bufferSize = outputFeatures.shape.lazy.map { $0.intValue }.reduce(1, { $0 * $1 })
    
    // Get data pointer to the buffer
    let dataPointer = UnsafeMutableBufferPointer(
        start: outputFeatures.dataPointer.assumingMemoryBound(to: Double.self),
        count: bufferSize)
    
    let file = "file.txt" // this is the file. we will write to and read from it
    var text = "" // just a text
    let semi = ","
    for i in 0..<bufferSize {
      let value = dataPointer[i]
      if (i == 0) {
        text = "\(value)";
      } else {
        text = "\(text)\(semi)\(value)";
      }
    }
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let fileURL = dir.appendingPathComponent(file)
        //writing
        do {
          try text.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {
          /* error handling here */
        }
    }
  }
  
  
  public func preprocess(image: NSImage, width: Int, height: Int) -> MLMultiArray? {
    let size = CGSize(width: width, height: height)
    
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
  }
  
  @IBAction func selectedModelChanged(_ sender: NSSegmentedControl) {
  }
  
  @IBAction func doInferencePressed(_ sender: NSButton) {
  }
}

