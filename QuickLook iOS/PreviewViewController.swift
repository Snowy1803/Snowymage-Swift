//
//  PreviewViewController.swift
//  QuickLook iOS
//
//  Created by Emil Pedersen on 11/02/2021.
//

import UIKit
import QuickLook

class PreviewViewController: UIViewController, QLPreviewingController, UIScrollViewDelegate {
        
    var imageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
    */
    

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        do {
            let data = try Data(contentsOf: url)
            
            var reader = SnowReader(source: data)
            
            guard let img = reader.read() else {
                throw CocoaError(.fileReadCorruptFile)
            }
            
            let image = UIImage(cgImage: img)
            
            print(self.view.frame)
            
            let imageView = UIImageView(image: image)
            imageView.frame = view.bounds
            imageView.contentMode = .scaleAspectFit
            
            let scrollView = UIScrollView()
            scrollView.frame = view.bounds
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 6
            scrollView.delegate = self
            scrollView.showsVerticalScrollIndicator = false
            scrollView.addSubview(imageView)
            
            self.imageView = imageView
            
            self.view.addSubview(scrollView)
            
            // Call the completion handler so Quick Look knows that the preview is fully loaded.
            // Quick Look will display a loading spinner while the completion handler is not called.
            
            handler(nil)
        } catch let e {
            handler(e)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
