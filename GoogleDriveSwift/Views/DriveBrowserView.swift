//
//  DriveBrowserView.swift
//  GoogleDriveSwift
//
//  Created by Loc Nguyen on 11/5/19.
//  Copyright © 2019 Loc Nguyen. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

protocol DriveBrowserViewDelegate {
    func onPressBack()
    func onPressSignOut()
    func onPressPrevDir()
    func onPressFile(file: GTLRDrive_File)
    func onPressMyDrive()
    func onPressShared()
}

class DriveBrowserView: UIView {
    
    var STATUS_BAR_HEIGHT = CGFloat(20)
    let HEADER_HEIGHT = CGFloat(50) // 20 = height of safe area
    let BACK_BUTTON_MARGIN = CGFloat(16)
    let BACK_BUTTON_SIZE = CGFloat(50)
    let ROW_HEIGHT = CGFloat(40)
    let darkBlue = UIColor(red: 39/255, green: 63/255, blue: 89/255, alpha: 1)
    let darkerBlue = UIColor(red: 30/255, green: 50/255, blue: 71/255, alpha: 1)

    var delegate: DriveBrowserViewDelegate?
    var tableView: UITableView!
    var loadingView: UIActivityIndicatorView!
    var maskButton: UIButton!
    var drawerView: UIView!
    var myDriveView: UIView!
    var sharedView: UIView!
    var signOutView: UIView!
    var inRoot = true // Use to check if in the root path of Google Drive
    var items = [GTLRDrive_File]() {
        didSet {
            items = items.sorted(by: DriveApi.sortFiles)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 11.0, *), let window = UIApplication.shared.keyWindow {
            STATUS_BAR_HEIGHT = window.safeAreaInsets.top
        }
        initMainView()
        initDrawerView()
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(openDrawer))
        edgePan.edges = .right
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(closeDrawer))
        swipe.direction = .right
        
        self.addGestureRecognizer(edgePan)
        self.addGestureRecognizer(swipe)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initMainView() {
        self.backgroundColor = .white
        for view in self.subviews {
            view.removeFromSuperview()
        }
        // ----------------- HEADER -----------------
        let statusBar = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: STATUS_BAR_HEIGHT))
        statusBar.backgroundColor = darkBlue
        self.addSubview(statusBar)
        
        let headerView = UIView(frame: CGRect(x: 0, y: STATUS_BAR_HEIGHT, width: self.frame.width, height: HEADER_HEIGHT))
        headerView.backgroundColor = darkBlue
        self.addSubview(headerView)
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: headerView.frame.width, height: HEADER_HEIGHT))
        titleLabel.text = "Google Drive"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.frame.size.width = titleLabel.intrinsicContentSize.width
        titleLabel.center.x = headerView.center.x
        headerView.addSubview(titleLabel)
        
        let backButton = UIButton(frame: CGRect(x: BACK_BUTTON_MARGIN, y: 0, width: BACK_BUTTON_SIZE, height: BACK_BUTTON_SIZE))
        backButton.setTitle("Back", for: .normal)
        backButton.contentHorizontalAlignment = .left;
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        backButton.center.y = titleLabel.center.y
        backButton.addTarget(self, action: #selector(onPressBack), for: .touchUpInside)
        headerView.addSubview(backButton)
        // ----------------- END HEADER -----------------
        
        // ----------------- TABLE VIEW -----------------
        tableView = UITableView(frame: CGRect(x: 0, y: STATUS_BAR_HEIGHT + HEADER_HEIGHT, width: self.frame.width, height: self.frame.height - STATUS_BAR_HEIGHT - HEADER_HEIGHT))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .groupTableViewBackground
        self.addSubview(tableView)
        // ----------------- END TABLE VIEW -----------------
        
        // ----------------- INDICATOR VIEW -----------------
        loadingView = UIActivityIndicatorView(frame: self.frame)
        loadingView.style = .gray
        loadingView.transform = CGAffineTransform(scaleX: 5, y: 5)
        self.addSubview(loadingView)
        // ----------------- END INDICATOR VIEW -----------------
        
        // ----------------- DRAWER BUTTON -----------------
        let drawerButton = UIButton(frame: CGRect(x: self.frame.width - BACK_BUTTON_SIZE - BACK_BUTTON_MARGIN, y: 0, width: BACK_BUTTON_SIZE, height: BACK_BUTTON_SIZE))
        drawerButton.setImage(UIImage(named: "drawerIcon"), for: .normal)
        drawerButton.contentEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 0)
        drawerButton.center.y = titleLabel.center.y
        drawerButton.addTarget(self, action: #selector(onPressDrawer), for: .touchUpInside)
        headerView.addSubview(drawerButton)
        // ----------------- END DRAWER BUTTON -----------------
    }
    
    private func initDrawerView() {
        // ----------------- BLACK OPACITY PART -----------------
        maskButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        maskButton.backgroundColor = .black
        maskButton.alpha = 0
        maskButton.addTarget(self, action: #selector(closeDrawer), for: .touchUpInside)
        self.addSubview(maskButton)
        // ----------------- END BLACK OPACITY PART -----------------

        // ----------------- DRAWER VIEW -----------------
        drawerView = UIView(frame: CGRect(x: self.frame.width, y: 0, width: self.frame.width*2/3, height: self.frame.height))
        drawerView.backgroundColor = darkBlue
        // ----------------- MY DRIVE -----------------
        myDriveView = UIView(frame: CGRect(x: 0, y: 50, width: drawerView.frame.width, height: ROW_HEIGHT))
        myDriveView.backgroundColor = darkerBlue
        
        let myDriveLabel = UILabel(frame: CGRect(x: 20, y: 0, width: myDriveView.frame.width - 20, height: ROW_HEIGHT))
        myDriveLabel.text = "My Drive"
        myDriveLabel.font = UIFont.systemFont(ofSize: 14)
        myDriveLabel.textColor = .white
        
        let myDriveButton = UIButton(frame: CGRect(x: 0, y: 0, width: myDriveView.frame.width, height: ROW_HEIGHT))
        myDriveButton.addTarget(self, action: #selector(onPressMyDrive), for: .touchUpInside)
        
        myDriveView.addSubview(myDriveLabel)
        myDriveView.addSubview(myDriveButton)
        drawerView.addSubview(myDriveView)
        // ----------------- END MY DRIVE -----------------
        
        // ----------------- SHARED -----------------
        sharedView = UIView(frame: CGRect(x: 0, y: myDriveView.frame.maxY, width: drawerView.frame.width, height: ROW_HEIGHT))
        
        let sharedLabel = UILabel(frame: CGRect(x: 20, y: 0, width: sharedView.frame.width - 20, height: ROW_HEIGHT))
        sharedLabel.text = "Shared"
        sharedLabel.font = UIFont.systemFont(ofSize: 14)
        sharedLabel.textColor = .white
        
        let sharedButton = UIButton(frame: CGRect(x: 0, y: 0, width: sharedView.frame.width, height: ROW_HEIGHT))
        sharedButton.addTarget(self, action: #selector(onPressShared), for: .touchUpInside)
        
        sharedView.addSubview(sharedLabel)
        sharedView.addSubview(sharedButton)
        drawerView.addSubview(sharedView)
        // ----------------- END SHARED -----------------
        
        let line = UIView(frame: CGRect(x: 0, y: sharedView.frame.maxY, width: drawerView.frame.width, height: 1))
        line.backgroundColor = .white
        drawerView.addSubview(line)
        
        // ----------------- SIGN OUT -----------------
        signOutView = UIView(frame: CGRect(x: 0, y: line.frame.maxY, width: drawerView.frame.width, height: ROW_HEIGHT))
        
        let signOutLabel = UILabel(frame: CGRect(x: 20, y: 0, width: signOutView.frame.width - 20, height: ROW_HEIGHT))
        signOutLabel.text = "Sign out Google Drive"
        signOutLabel.font = UIFont.systemFont(ofSize: 14)
        signOutLabel.textColor = .white
        
        let signOutButton = UIButton(frame: CGRect(x: 0, y: 0, width: signOutView.frame.width, height: ROW_HEIGHT))
        signOutButton.addTarget(self, action: #selector(onPressSignOut), for: .touchUpInside)
        
        signOutView.addSubview(signOutLabel)
        signOutView.addSubview(signOutButton)
        drawerView.addSubview(signOutView)
        // ----------------- END SIGNOUT -----------------

        self.addSubview(drawerView)
        // ----------------- END DRAWER VIEW -----------------
    }
    
    public func reloadTableView(_ files: [GTLRDrive_File], inRoot: Bool = true) {
        items = files
        self.inRoot = inRoot
        tableView.reloadData()
        let cells = tableView.visibleCells
        for cell in cells {
            cell.alpha = 0
        }
        for cell in cells {
            UIView.animate(withDuration: 0.5) {
                cell.alpha = 1
            }
        }
    }
    
    public func setLoading(_ loading: Bool) {
        if loading {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }
    
    @objc private func onPressDrawer() {
        openDrawer()
    }
    
    @objc private func openDrawer() {
        UIView.animate(withDuration: 0.2) {
            self.maskButton.alpha = 0.7
            self.drawerView.transform = CGAffineTransform(translationX: -(self.drawerView.frame.width), y: 0)
        }
    }
    
    @objc private func closeDrawer() {
        UIView.animate(withDuration: 0.2) {
            self.maskButton.alpha = 0
            self.drawerView.transform = CGAffineTransform.identity
        }
    }
    
    @objc private func onPressMyDrive() {
        myDriveView.backgroundColor = darkerBlue
        sharedView.backgroundColor = darkBlue
        closeDrawer()
        delegate?.onPressMyDrive()
        
    }
    
    @objc private func onPressShared() {
        myDriveView.backgroundColor = darkBlue
        sharedView.backgroundColor = darkerBlue
        closeDrawer()
        delegate?.onPressShared()
    }
    
    @objc private func onPressBack() {
        delegate?.onPressBack()
    }
    
    @objc private func onPressSignOut() {
        closeDrawer()
        delegate?.onPressSignOut()
    }
}
extension DriveBrowserView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inRoot ? items.count : items.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DropboxBrowserRowCell.ROW_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = GoogleDriveBrowserRowCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "GoogleDriveBrowserRowCell")
        cell.selectionStyle = .none
        if inRoot {
            cell.setData(data: items[indexPath.row])
            return cell
        }
        // In children directory
        if indexPath.row == 0 {
            cell.stylePreviousDirectory()
        } else {
            cell.setData(data: items[indexPath.row - 1])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if inRoot {
            delegate?.onPressFile(file: items[indexPath.row])
            return
        }
        if indexPath.row == 0 {
            delegate?.onPressPrevDir()
        } else {
            delegate?.onPressFile(file: items[indexPath.row - 1])
        }
    }
}
