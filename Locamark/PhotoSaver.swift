//
//  PhotoSaver.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import UIKit

class PhotoSaver: NSObject {
    var completion: ((Error?) -> Void)?

    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Error?) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving QR code: \(error.localizedDescription)")
        } else {
            print("QR code saved successfully!")
        }
        completion?(error)
    }
}
