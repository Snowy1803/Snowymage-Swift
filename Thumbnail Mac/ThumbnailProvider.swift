//
//  ThumbnailProvider.swift
//  Thumbnail Mac
//
//  Created by Emil Pedersen on 11/02/2021.
//

import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        handler(QLThumbnailReply(contextSize: request.maximumSize, drawing: { (context) -> Bool in
            // Draw the thumbnail here.
            
            guard let data = try? Data(contentsOf: request.fileURL) else {
                return false
            }
            
            var reader = SnowReader(source: data)
            
            guard let img = reader.read() else {
                return false
            }
            
            context.draw(img, in: CGRect(x: 0, y: 0, width: context.width, height: context.height))
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
    }
}
