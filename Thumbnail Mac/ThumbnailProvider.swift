//
//  ThumbnailProvider.swift
//  Thumbnail Mac
//
//  Created by Emil Pedersen on 11/02/2021.
//

import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        guard let data = try? Data(contentsOf: request.fileURL) else {
            handler(nil, CocoaError(.fileReadCorruptFile))
            return
        }
        
        var reader = SnowReader(source: data)
        
        guard let img = reader.read() else {
            handler(nil, CocoaError(.fileReadCorruptFile))
            return
        }
        
        let width = CGFloat(img.width)
        let height = CGFloat(img.height)
        
        let scaleX = request.maximumSize.width / width
        let scaleY = request.maximumSize.height / height
        let scale = min(scaleX, scaleY)
        
        handler(QLThumbnailReply(contextSize: CGSize(width: scale * width, height: scale * height), drawing: { (context) -> Bool in
            // Draw the thumbnail here.
            context.draw(img, in: CGRect(x: 0, y: 0, width: context.width, height: context.height))
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
    }
}
