//
//  PlayerAction.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import AVFoundation
import MediaPlayer
import UIKit


//MARK: - Player Actions

extension Player{
    
    /* The user is dragging the movie controller thumb to scrub through the movie. */
    public func beginScrubbing() {
        scrubbingRate = self.player.rate
        self.player.rate = 0.0
        //self.removeObservers()
        self.deinitTimeObserver()
        
    }
    
    /* The user has released the movie thumb control to stop scrubbing through the movie. */
    public func endScrubbing() {
        
        if timeObserver == nil{
            let playerItemDuration = self.currentPlayerItemDuration
            if playerItemDuration == kCMTimeInvalid{
                return
            }
            initTimeObserver()
            
        }
        if scrubbingRate != nil{
            self.player.rate = scrubbingRate
            scrubbingRate = 0.0
        }
    }
    
    public  func scrub(value:Float,minValue:Float,maxValue:Float,isSeeking seekValue:@escaping (Bool) -> ()) {
        let playerItemDuration = self.currentPlayerItemDuration
        
        if playerItemDuration == kCMTimeInvalid{
            return
        }
        
        let durationSeconds = playerItemDuration.seconds
        
        if durationSeconds.isFinite{
            let minimumValue = Float64(minValue)
            let maximumValue = Float64(maxValue)
            let valued = Float64(value)
            let time = durationSeconds * (valued - minimumValue)/(maximumValue - minimumValue)
            let cmTime = CMTime.init(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            
            self.multicastDelegate.invoke(invokation: { (delegate) in
                
                delegate.musicPlayerPeriodicEvent(manager: self, periodicTimeObserverEventDidOccur: CMTimeWrapper.init(seconds: time, value: cmTime.value, timeScale: cmTime.timescale))
            })
            
            self.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: time as Double);
            self.nowPlayingInfoCenter.nowPlayingInfo = self.nowPlayingInfo
            
            self.player.seek(to: CMTimeMakeWithSeconds(time, CMTimeScale.init(NSEC_PER_SEC)), completionHandler: { (finished) in
                self.timeObserverQueue.async {
                    seekValue(false)
                }
            })
        }
    }
    
    public  func didClickOnPlay(){
        
        //currently not playing Should Play
        
        if !self.player.isPlaying{
            
            self.player.play()
            
            self.playerState = PlayerState.Playing
            
            self.multicastDelegate.invoke { (delegate) in
                delegate.setPlayButton(state: PlayerState.Playing)
            }
            
        }else{
            
            //currently playing Should Pause
            
            self.player.pause()
            
            self.playerState = PlayerState.Paused
            
            self.multicastDelegate.invoke { (delegate) in
                delegate.setPlayButton(state: PlayerState.Paused)
            }
            
        }
    }
    
    public func didClickOnNext(){
        
        guard let datasource = self.dataSource else {self.removeStatusObservers(); return}
        
        self.multicastDelegate.invoke { (delegate) in
            delegate.resetDisplayIfNecessary(manager: self)
        }
        
        if datasource.musicPlayerShoulMoveToNextItem(manager: self){
            if let nextItemURL = datasource.musicPlayerDidAskForNextItem(manager: self){
                self.playWithURL(url: nextItemURL)
                return
            }
            self.removeStatusObservers();
        }
    }
    
    public  func didClickOnPrevious(){
        guard let datasource = self.dataSource else {self.removeStatusObservers(); return}
        
        self.multicastDelegate.invoke { (delegate) in
            delegate.resetDisplayIfNecessary(manager: self)
        }
        
        if datasource.musicPlayerShoulMoveToPreviousItem(manager: self){
            if let nextItemURL = datasource.musicPlayerDidAskForPreviousItem(manager: self){
                self.playWithURL(url: nextItemURL)
                return
            }
            self.removeStatusObservers();
        }
    }
    
    public  func didFastForward(withRate:Float){
        self.kInterval = Double(withRate)/0.5
        self.player.rate = withRate
    }
    
    public  func didRewindTenSeconds(value:Float){
        
        self.scrub(value: value, minValue: 0, maxValue: 1) { (seeking) in
            print(seeking)
        }
    }
}
