//
//  ArtWork.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

enum ArtWorks:String{
    case small
    case medium
    case large
}

enum PlayerState:String{
    case ReadyToPlay
    case Buffering
    case Playing
    case Paused
    case Interrupted
    case Invalid
}

import AVFoundation

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
