//
//  QuintypePlayer.swift
//  QuintypePlayer
//
//  Created by Albin.git on 6/20/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//


open class QuintypeMusicPlayer{
    
    internal static var QMPlayer:QuintypeMusicPlayer = QuintypeMusicPlayer()
    internal var clientID : String = ""
    
    private var player:Player!
    
    open static func sharedInstance(clientId:String)->Player{
    
        QuintypeMusicPlayer.QMPlayer.clientID = clientId
        
        if QMPlayer.player == nil{
            QMPlayer.player = Player()
        }
        return QMPlayer.player
    }
    
}

