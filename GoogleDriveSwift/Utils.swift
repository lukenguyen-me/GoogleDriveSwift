//
//  Utils.swift
//  GoogleDriveSwift
//
//  Created by Loc Nguyen on 11/5/19.
//  Copyright © 2019 Loc Nguyen. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftyDropbox

class Utils: NSObject {

    class func convertFileTypeToExtension(_ fileType: String) -> [String] {
        switch fileType {
        case "pdf":
            return [".pdf"]
        case "images":
            return [".jpg", ".jpeg", ".png"]
        case "documents":
            return [".doc", ".docx"]
        default:
            return [String]()
        }
    }
    
    class func convertFileTypeToMimeType(_ fileType: String) -> [String] {
        switch fileType {
        case "pdf":
            return ["application/pdf"]
        case "images":
            return ["image/png", "image/jpeg", "application/vnd.google-apps.photo"]
        case "documents":
            return ["application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.google-apps.document"]
        default:
            return [String]()
        }
    }
    
    class func setImageFromUrl(url: String, defaultImage: String, imageView: UIImageView) {
        imageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: defaultImage), options: [], completed: nil)
    }

    class func forceSignInDropbox(_ completion: @escaping (_ result: String?) -> Void)  {
        DropboxClientsManager.resetClients()
        UserDefaults.standard.set("dropbox", forKey: FILE_PICKER_SERVICE) //setObject
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: UIApplication.shared.delegate?.window!!.rootViewController) { (url) in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                completion("Success")
            } else {
                completion(nil)
            }
        }
    }
}
