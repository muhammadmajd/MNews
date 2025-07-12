//
//  UIImageView+Extensions.swift
//

import UIKit

// A simple cache to avoid re-downloading images that have already been loaded.
let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    
    /// Asynchronously loads an image from a URL and sets it on the image view.
    /// - Parameter url: The URL of the image to download.
    func loadImage(from url: URL) {
        // Set a placeholder image or clear the current one
        self.image = nil
        
        // Check if the image is already in the cache
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
            self.image = cachedImage
            return
        }
        
        // If not in cache, start a data task to download it
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // Ensure there's data and no error
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                print("Failed to download image from URL: \(url)", error ?? "Unknown error")
                return
            }
            
            // Store the newly downloaded image in the cache
            imageCache.setObject(image, forKey: url.absoluteString as NSString)
            
            // Switch back to the main thread to update the UI
            DispatchQueue.main.async {
                self?.image = image
            }
        }.resume()
    }
}
