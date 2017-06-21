//
//  Tracks.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation
//import Soundcloud

open class Tracks:NSObject{
    ///Track's identifier
    public var id: NSNumber?
    
    ///Creation date of the track
    public var created_at: NSNumber?
    
    ///User that created the track (not a full user)
    public var user: User1?
    
    ///Track duration
    public var duration: NSNumber?
    
    ///Is streamable
    public var streamable: Bool?
    
    ///Is downloadable
    public var downloadable: Bool?
    
    ///Streaming URL
    public var stream_url: String?
    
    ///Downloading URL
    public var download_url: String?
    
    ///Track title
    public var title: String?
    
    ///Image URL to artwork
    public var artwork_url: String?
    
    public var trackDict: [String:AnyObject]?
    
    
    override open func setValue(_ value: Any?, forKey key: String) {
        
        if key == "user" {
            let user = User1()
            let data = value as? [String : AnyObject]
            
            if let userName = data?["username"] as? String{
                user.username = userName
            }
            if let id = data?["id"] as? NSNumber{
                user.id = id
            }
            
            self.user = user
    
    }else {
            super.setValue(value, forKey: key)
        }
    }
}

public class User1 : SafeJsonObject{
    ///User's identifier
    public var id: NSNumber?
    
    ///Username
    public var username: String?
    
}

