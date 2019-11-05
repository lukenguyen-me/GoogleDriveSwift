//
//  DriveBrowserCell.swift
//  GoogleDriveSwift
//
//  Created by Loc Nguyen on 11/5/19.
//  Copyright © 2019 Loc Nguyen. All rights reserved.
//
import UIKit
import GoogleAPIClientForREST

class DriveBrowserCell: UITableViewCell {
    
    static let ROW_HEIGHT = CGFloat(70)
    let ICON_SIZE = CGFloat(40)
    let ICON_LEADING = CGFloat(16)
    let HORIZONTAL_ICON_LABEL = CGFloat(10)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func renderUI(thumbnail: String?, image: String, name: String, time: String) {
        for view in contentView.subviews {
            view.removeFromSuperview()
        }
        contentView.backgroundColor = .white
        
        let typeImageView = UIImageView(frame: CGRect(x: ICON_LEADING, y: (DriveBrowserCell.ROW_HEIGHT - ICON_SIZE)/2, width: ICON_SIZE, height: ICON_SIZE))
        contentView.addSubview(typeImageView)
        Utils.setImageFromUrl(url: thumbnail ?? "", defaultImage: image, imageView: typeImageView)
        
        let nameLabel = UILabel(frame: CGRect(x: typeImageView.frame.maxX + HORIZONTAL_ICON_LABEL, y: typeImageView.center.y - ICON_SIZE/2, width: 0, height: 0))
        nameLabel.text = name
        nameLabel.textColor = .black
        nameLabel.font = UIFont.systemFont(ofSize: 13)
        nameLabel.frame.size = nameLabel.intrinsicContentSize
        contentView.addSubview(nameLabel)

        let timeLabel = UILabel(frame: CGRect(x: typeImageView.frame.maxX + HORIZONTAL_ICON_LABEL, y: typeImageView.frame.maxY - 20, width: 0, height: 0))
        timeLabel.text = time
        timeLabel.textColor = .black
        timeLabel.font = UIFont.systemFont(ofSize: 13)
        timeLabel.frame.size = timeLabel.intrinsicContentSize
        contentView.addSubview(timeLabel)
        
        let bottomLine = UIView(frame: CGRect(x: 0, y: DriveBrowserCell.ROW_HEIGHT-1, width: contentView.frame.width, height: 1))
        bottomLine.backgroundColor = .groupTableViewBackground
        contentView.addSubview(bottomLine)
    }
    
    func stylePreviousDirectory() {
        for view in contentView.subviews {
            view.removeFromSuperview()
        }
        contentView.backgroundColor = .white
        
        let typeImageView = UIImageView(frame: CGRect(x: ICON_LEADING, y: (DriveBrowserCell.ROW_HEIGHT - ICON_SIZE)/2, width: ICON_SIZE, height: ICON_SIZE))
        contentView.addSubview(typeImageView)
        typeImageView.image = UIImage(named: "folderIcon")
        
        let nameLabel = UILabel(frame: CGRect(x: typeImageView.frame.maxX + HORIZONTAL_ICON_LABEL, y: typeImageView.center.y - 5, width: 0, height: 0))
        nameLabel.text = ".."
        nameLabel.textColor = .black
        nameLabel.font = UIFont.systemFont(ofSize: 13)
        nameLabel.frame.size = nameLabel.intrinsicContentSize
        contentView.addSubview(nameLabel)
        
        let bottomLine = UIView(frame: CGRect(x: 0, y: DriveBrowserCell.ROW_HEIGHT-1, width: contentView.frame.width, height: 1))
        bottomLine.backgroundColor = .groupTableViewBackground
        contentView.addSubview(bottomLine)
    }
    
    func setData(data: GTLRDrive_File) {
        var fileSize = ""
        var dateStr = ""
        if let size = data.size as? Int {
            if size > 1073741824 {
                fileSize = String.localizedStringWithFormat("%.1fGB", Double(size / 1073741824))
            } else if size > 1048576 {
                fileSize = String.localizedStringWithFormat("%.1fMB", Double(size / 1048576))
            } else {
                fileSize = String.localizedStringWithFormat("%.1fKB", Double(size / 1024))
            }
        }
        if let date = data.modifiedTime?.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateStr = data.isFolder() ? "\(formatter.string(from: date))" : "\(formatter.string(from: date)) | \(fileSize)"
        }
        renderUI(thumbnail: data.thumbnailLink, image: data.isFolder() ? "folderIcon" : "fileIcon", name: data.name!, time: dateStr)
    }
    
}

