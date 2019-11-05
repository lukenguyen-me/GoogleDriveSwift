//
//  GoogleDrive.swift
//  GoogleDriveSwift
//
//  Created by Loc Nguyen on 11/5/19.
//  Copyright © 2019 Loc Nguyen. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST

enum GDriveError: Error {
    case NoDataAtPath
}

class DriveApi {
    
    private let service: GTLRDriveService
    public static let MIME_TYPE_FOLDER = "application/vnd.google-apps.folder"
    public static let CONDITION_IN_MY_DRIVE = "'me' in owners"
    public static let CONDITION_IN_SHARED = "sharedWithMe"
    public static let CONDITION_IN_ROOT = "'root' in parents"
    public static let CONDITION_IS_FOLDER = "mimeType='application/vnd.google-apps.folder'"

    var mimeTypes = [String]()
    
    init(_ service: GTLRDriveService) {
        self.service = service
    }
    
    class func sortFiles(first: GTLRDrive_File, second: GTLRDrive_File) -> Bool {
        guard let firstName = first.name, let secondName = second.name else { return false }
        if first.isFolder() || second.isFolder() {
            return first.isFolder()
        }
        return firstName < secondName
    }
    
    public func listFilesInMyDrive(onCompleted: @escaping ([GTLRDrive_File]?, Error?) -> ()) {
        search(conditions: [GoogleDrive.CONDITION_IN_MY_DRIVE, GoogleDrive.CONDITION_IN_ROOT]) { (files, error) in
            guard let list = files else {
                onCompleted(nil, error)
                return
            }
            onCompleted(list, nil)
        }
    }
    
    public func listFilesInShared(onCompleted: @escaping ([GTLRDrive_File]?, Error?) -> ()) {
        search(conditions: [GoogleDrive.CONDITION_IN_SHARED]) { (files, error) in
            guard let list = files else {
                onCompleted(nil, error)
                return
            }
            onCompleted(list, nil)
        }
    }
    
    public func listFilesInFolder(_ folder: String, onCompleted: @escaping ([GTLRDrive_File]?, Error?) -> ()) {
        search(conditions: ["name contains '\(folder)'", GoogleDrive.CONDITION_IS_FOLDER]) { (files, error) in
            guard let ID = files?.first?.identifier else {
                onCompleted(nil, error)
                return
            }
            self.listFiles(ID, onCompleted: onCompleted)
        }
    }
    
    public func listFiles(_ folderID: String, onCompleted: @escaping ([GTLRDrive_File]?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "'\(folderID)' in parents"
        query.fields = "kind,nextPageToken,files(mimeType,id,kind,name,webViewLink,thumbnailLink,trashed,modifiedTime,size)"

        service.executeQuery(query) { (ticket, result, error) in
            onCompleted((result as? GTLRDrive_FileList)?.files, error)
        }
    }
    
    public func uploadFile(_ folderName: String, filePath: String, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        
        search(conditions: ["names contains '\(folderName)'"]) { (files, error) in
            
            if let ID = files?.first?.identifier {
                self.upload(ID, path: filePath, MIMEType: MIMEType, onCompleted: onCompleted)
            } else {
                self.createFolder(folderName, onCompleted: { (folderID, error) in
                    guard let ID = folderID else {
                        onCompleted?(nil, error)
                        return
                    }
                    self.upload(ID, path: filePath, MIMEType: MIMEType, onCompleted: onCompleted)
                })
            }
        }
    }
    
    private func upload(_ parentID: String, path: String, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        
        guard let data = FileManager.default.contents(atPath: path) else {
            onCompleted?(nil, GDriveError.NoDataAtPath)
            return
        }
        
        let file = GTLRDrive_File()
        file.name = path.components(separatedBy: "/").last
        file.parents = [parentID]
        
        let uploadParams = GTLRUploadParameters.init(data: data, mimeType: MIMEType)
        uploadParams.shouldUploadWithSingleRequest = true
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParams)
        query.fields = "id"
        
        self.service.executeQuery(query, completionHandler: { (ticket, file, error) in
            onCompleted?((file as? GTLRDrive_File)?.identifier, error)
        })
    }
    
    public func download(_ fileID: String, onCompleted: @escaping (Data?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        service.executeQuery(query) { (ticket, file, error) in
            onCompleted((file as? GTLRDataObject)?.data, error)
        }
    }
    
    public func search(conditions: [String] = [], onCompleted: @escaping ([GTLRDrive_File]?, Error?) -> ()) {
        service.shouldFetchNextPages = true;
        let query = GTLRDriveQuery_FilesList.query()
        query.fields = "kind,nextPageToken,files(mimeType,id,kind,name,webViewLink,thumbnailLink,trashed,modifiedTime,size)"
        if conditions.count > 0 {
            var q = ""
            q = "\(conditions.joined(separator: " and "))"
            if mimeTypes.count > 0 {
                q += " and (mimeType='application/vnd.google-apps.folder'"
                for i in 0..<mimeTypes.count {
                    q += " or mimeType='\(mimeTypes[i])'"
                }
                q += ")"
            }
            query.q = q
        }
        service.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files, error)
        }
    }
    
    public func createFolder(_ name: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = GoogleDrive.MIME_TYPE_FOLDER
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"
        
        service.executeQuery(query) { (ticket, folder, error) in
            onCompleted((folder as? GTLRDrive_File)?.identifier, error)
        }
    }
    
    public func delete(_ fileID: String, onCompleted: ((Error?) -> ())?) {
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)
        service.executeQuery(query) { (ticket, nilFile, error) in
            onCompleted?(error)
        }
    }
}
extension GTLRDrive_File {
    public func isFolder() -> Bool {
        guard let type = self.mimeType else {
            return false
        }
        return type == GoogleDrive.MIME_TYPE_FOLDER
    }
}
