//
//  UIImage+Resize.swift
//  HED-CoreML
//
//  Created by Andrey Volodin on 03.07.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//
import Cocoa
public extension NSImage {
    public func resized(to newSize: NSSize) -> NSImage {
      if let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
        bitmapRep.size = newSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.addRepresentation(bitmapRep)
        return resizedImage
      }
      
      return NSImage(size: NSSize(width: 0, height: 0))
    }
}

