//
//  PreviewViewController.swift
//  QuickLook
//
//  Created by Emil Pedersen on 11/02/2021.
//

import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
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
            
            let image = NSImage(cgImage: img, size: NSSize(width: img.width, height: img.height))
            
            let imageView = NSImageView(frame: NSRect(origin: .zero, size: image.size))
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyDown
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(imageView)
            
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            
            // Call the completion handler so Quick Look knows that the preview is fully loaded.
            // Quick Look will display a loading spinner while the completion handler is not called.
            
            handler(nil)
        } catch let e {
            handler(e)
        }
    }
}
