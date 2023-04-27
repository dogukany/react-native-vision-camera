//
//  PhotoCaptureDelegate.swift
//  mrousavy
//
//  Created by Marc Rousavy on 15.12.20.
//  Copyright © 2020 mrousavy. All rights reserved.
//

import AVFoundation

private var delegatesReferences: [NSObject] = []

// MARK: - PhotoCaptureDelegate

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let promise: Promise

  required init(promise: Promise) {
    self.promise = promise
    super.init()
    delegatesReferences.append(self)
  }

  func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    defer {
      delegatesReferences.removeAll(where: { $0 == self })
    }
    if let error = error as NSError? {
      promise.reject(error: .capture(.unknown(message: error.description)), cause: error)
      return
    }

    guard let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
        promise.reject(error: .capture(.fileError))
        return 
      }

    let fileName = "\(UUID().uuidString).jpeg"
      
    guard let fileURL = directory.appendingPathComponent(fileName) else {
      promise.reject(error: .capture(.fileError))
      return
    }
    
    guard let data = photo.fileDataRepresentation() else {
       promise.reject(error: .capture(.fileError))
       return
     }

    do {
        try data.write(to: fileURL)
      let exif = photo.metadata["{Exif}"] as? [String: Any]
      let width = exif?["PixelXDimension"]
      let height = exif?["PixelYDimension"]

      promise.resolve([
        "path":  fileURL.path,
        "width": width as Any,
        "height": height as Any,
        "isRawPhoto": photo.isRawPhoto,
        "metadata": photo.metadata,
        "thumbnail": photo.embeddedThumbnailPhotoFormat as Any,
      ])
    } catch {
      promise.reject(error: .capture(.fileError), cause: error as NSError)
    }
  }

  func photoOutput(_: AVCapturePhotoOutput, didFinishCaptureFor _: AVCaptureResolvedPhotoSettings, error: Error?) {
    defer {
      delegatesReferences.removeAll(where: { $0 == self })
    }
    if let error = error as NSError? {
      promise.reject(error: .capture(.unknown(message: error.description)), cause: error)
      return
    }
  }
}
