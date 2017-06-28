//
//  CMTimeWrapper.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation

open class CMTimeWrapper:NSObject{
    open var seconds:Double
    open var value:Int64
    open var timeScale:Int32
    
    init(seconds:Double, value:Int64, timeScale:Int32) {
        self.seconds = seconds
        self.value = value
        self.timeScale = timeScale
        super.init()
    }
}
