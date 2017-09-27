//
//  Tracks.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation
//import Soundcloud

open class Tracks:SafeJsonObject,NSCoding{
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
    public var stream_url: URL?
    
    ///Downloading URL
    public var download_url: String?
    
    ///Track title
    public var title: String?
    
    ///Image URL to artwork
    public var artwork_url: URL?
    
    public var downloaded:Bool?
    
    
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
            
        }else if key == "artwork_url"{
            
            if var unwrappedUrl = value as? String{

                unwrappedUrl.append("?client_id=\(QuintypeMusicPlayer.QMPlayer.clientID)")
                
                let url = URL(string: unwrappedUrl)
                self.artwork_url = url
                
            }else{
                super.setValue(value, forKey: key)
            }
            
        }else if key == "stream_url"{
            if var unwrappedStreamingUrl = value as? String{
                
                unwrappedStreamingUrl.append("?client_id=\(QuintypeMusicPlayer.QMPlayer.clientID)")
                
                let url = URL(string: unwrappedStreamingUrl)
                
                self.stream_url = url
                
            }else{
                self.stream_url = nil
            }
        }else {
            super.setValue(value, forKey: key)
        }
    }
    
    public override init() {
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        
        if let unwrappedId = aDecoder.decodeObject(forKey: "id") as? NSNumber{
            id = unwrappedId
        }
        
        created_at = aDecoder.decodeObject(forKey: "created_at") as? NSNumber
        user = aDecoder.decodeObject(forKey: "user") as? User1
        duration = aDecoder.decodeObject(forKey: "duration") as? NSNumber
        streamable = aDecoder.decodeObject(forKey: "streamable") as? Bool
        downloadable = aDecoder.decodeObject(forKey: "downloadable") as? Bool
        
        download_url = aDecoder.decodeObject(forKey: "download_url") as? String
        stream_url = aDecoder.decodeObject(forKey: "stream_url") as? URL
        title = aDecoder.decodeObject(forKey: "title") as? String
        artwork_url = aDecoder.decodeObject(forKey: "artwork_url") as? URL
    }
    
    open func encode(with aCoder: NSCoder) {
        
        aCoder.encode(id ?? NSNumber.self, forKey: "id")
        aCoder.encode(created_at ?? NSNumber.self, forKey: "created_at")
        
        if let unwrappedUser = user{
            aCoder.encode(unwrappedUser, forKey: "user")
        }
        
        aCoder.encode(duration ?? NSNumber.self, forKey: "duration")
        aCoder.encode(streamable ?? false, forKey: "streamable")
        aCoder.encode(downloadable ?? false, forKey: "downloadable")
        aCoder.encode(stream_url ?? URL(string:""), forKey: "stream_url")
        aCoder.encode(download_url ?? "", forKey: "download_url")
        aCoder.encode(title ?? "", forKey: "title")
        aCoder.encode(artwork_url ?? URL(string:""), forKey: "artwork_url")
        
        
        
    }
    
}


open class User1 : SafeJsonObject,NSCoding{
    ///User's identifier
    public var id: NSNumber?
    
    ///Username
    public var username: String?
    
    public required init?(coder aDecoder: NSCoder) {
        if let unwrappedId = aDecoder.decodeObject(forKey: "id") as? NSNumber{
            id = unwrappedId
        }
        
        username = aDecoder.decodeObject(forKey: "username") as? String
        
    }
    
    public override init() {
        
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(id ?? NSNumber.self, forKey: "id")
        aCoder.encode(username ?? "", forKey: "username")
    }
}








