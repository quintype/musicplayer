//
//  QuintypePlayer.swift
//  QuintypePlayer
//
//  Created by Albin.git on 6/20/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//


open class QuintypeMusicPlayer{
    
    public static let sharedInstance:QuintypeMusicPlayer = QuintypeMusicPlayer()
    
    private var _musicPlayer:Player?
    
    open static var player:Player{
        get{
            if QuintypeMusicPlayer.sharedInstance._musicPlayer == nil{
                QuintypeMusicPlayer.sharedInstance._musicPlayer = Player()
            }
            return QuintypeMusicPlayer.sharedInstance._musicPlayer!
        }
    }
}

