//
//  DriveBrowserViewController.swift
//  GoogleDriveSwift
//
//  Created by Loc Nguyen on 11/5/19.
//  Copyright © 2019 Loc Nguyen. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class DriveBrowserViewController: UIViewController {

    var service = GTLRDriveService()
    private var drive: DriveApi?
    var mainView: GoogleDriveBrowserView!
    var currentPath = [String]()
    var onFinish: ((_ data: [String: Any]?, _ error: String?) -> Void)?
    var mimeTypes = [String]()
    var didOpenSignIn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentPath.append("My Drive")
        mainView = GoogleDriveBrowserView(frame: self.view.frame)
        mainView.delegate = self
        self.view.addSubview(mainView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didOpenSignIn {
            setupGoogleSignIn()
        } else {
            loadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupGoogleSignIn() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDriveReadonly]
        GIDSignIn.sharedInstance().signIn()
        didOpenSignIn = true
    }
    
    fileprivate func loadData() {
        mainView.setLoading(true)
        drive = GoogleDrive(service)
        for type in mimeTypes {
            drive?.mimeTypes.append(contentsOf: Utils.convertFileTypeToMimeType(type))
        }
        if let path = currentPath.last {
            if path == "My Drive" {
                drive?.listFilesInMyDrive(onCompleted: { (list, error) in
                    self.mainView.setLoading(false)
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                    if let list = list {
                        self.mainView.reloadTableView(list, inRoot: true)
                    }
                })
            } else if path == "Shared" {
                drive?.listFilesInShared(onCompleted: { (list, error) in
                    self.mainView.setLoading(false)
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                    if let list = list {
                        self.mainView.reloadTableView(list, inRoot: true)

                    }
                })
            } else {
                drive?.listFiles(path, onCompleted: { (list, error) in
                    self.mainView.setLoading(false)
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                    if let list = list {
                        self.mainView.reloadTableView(list, inRoot: false)
                    }
                })
            }
        }
    }
    
    fileprivate func downloadToData(file: GTLRDrive_File) {
        drive?.download(file.identifier!, onCompleted: { (data, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.onFinish?(nil, error.localizedDescription)
                return
            }
            if let data = data {
                let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory())
                guard let uri = tempDir.appendingPathComponent(file.name!) else {
                    self.onFinish?(nil, "Can't not access temporary directory")
                    return
                }
                do {
                    try data.write(to: uri)
                    let dictionary = [
                        "fileName": file.name ?? "",
                        "fileSize": Int(truncating: file.size ?? 0),
                        "mimeType": "application/pdf",
                        "uri": uri.absoluteString
                        ] as [String : Any]
                    self.onFinish?(dictionary, nil)
                } catch let error as NSError {
                    self.onFinish?(nil, error.description)
                }
            }
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    @IBAction func backAction(_ sender: Any) {
        currentPath.remove(at: currentPath.count - 1)
        if currentPath.count == 0 {
            dismiss(animated: true, completion: nil)
            return
        }
        loadData()
    }
}
extension GoogleDriveBrowserViewController: GoogleDriveBrowserViewDelegate {
    func onPressMyDrive() {
        currentPath.removeAll()
        currentPath.append("My Drive")
        loadData()
    }
    
    func onPressShared() {
        currentPath.removeAll()
        currentPath.append("Shared")
        loadData()
    }
    
    func onPressBack() {
        dismiss(animated: true, completion: nil)
    }
    
    func onPressFile(file: GTLRDrive_File) {
        if file.isFolder() {
            guard let id = file.identifier else { return }
            currentPath.append(id)
            loadData()
            return
        }
        guard let id = file.identifier, let name = file.name, let size = file.size as? Int else {
            self.onFinish?(nil, "Failed to choose file from Google Drive")
            self.dismiss(animated: true, completion: nil)
            return
        }
        let dictionary = [
            "id": id,
            "name": name,
            "size": size,
            "mimeType": "application/pdf",
            "service": "google",
            "remoteEmail": service.authorizer?.userEmail ?? ""
            ] as [String : Any]
        onFinish?(dictionary, nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    func onPressPrevDir() {
        currentPath.remove(at: currentPath.count - 1)
        loadData()
    }
    
    func onPressSignOut() {
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().signIn()
    }
}
extension GoogleDriveBrowserViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let _ = error {
            service.authorizer = nil
            dismiss(animated: true, completion: nil)
        } else {
            service.authorizer = user.authentication.fetcherAuthorizer()
            loadData()
        }
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        print("Dismiss GoogleSignIn")
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        UserDefaults.standard.set("google", forKey: FILE_PICKER_SERVICE) //setObject
        present(viewController, animated: true, completion: nil)
    }
}
