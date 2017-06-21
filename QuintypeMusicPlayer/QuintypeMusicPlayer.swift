//
//  QuintypePlayer.swift
//  QuintypePlayer
//
//  Created by Albin.git on 6/20/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

open class QuintypeMusicPlayer{
    
    public static let sharedInstance:QuintypePlayer = QuintypePlayer()
    
    private var _musicPlayer:Player?
    
    open static var player:Player{
        get{
            if QuintypePlayer.sharedInstance._musicPlayer == nil{
                QuintypePlayer.sharedInstance._musicPlayer = Player()
            }
            return QuintypePlayer.sharedInstance._musicPlayer!
        }
    }
}
