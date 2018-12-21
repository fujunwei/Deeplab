//
//  UIImage+CVPixelBuffer.swift
//  HED-CoreML
//
//  Created by Andrey Volodin on 19.06.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//
import Cocoa
extension NSImage {
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        guard let context = CGContext(data: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            else {
                return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        
//        NSGraphicsPushContext(context)
      NSGraphicsContext.saveGraphicsState()
      let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
      NSGraphicsContext.current = graphicsContext
      
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
//        NSGraphicsPopContext()
      NSGraphicsContext.restoreGraphicsState()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
  
  public func pixelData() -> [UInt8]? {
    let dataSize = size.width * size.height * 4
    var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: &pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    
    return pixelData
  }
  
  
  
}

