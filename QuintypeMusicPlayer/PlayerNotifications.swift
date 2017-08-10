//
//  PlayerNotification.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

extension Player{
    
    func addStatusObservers(){
        
        self.playerItem?.addObserver(self, forKeyPath: "status", options: [.initial,.old], context: &Player.randomContextForObserver)
        
        self.playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.new], context: &Player.randomContextForObserver)
        
        self.playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new], context: &Player.randomContextForObserver)
        
        self.playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.initial,.new], context: &Player.randomContextForObserver)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem, queue: OperationQueue.main, using: self.playerItemDIdPlayToItem!)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AVPlayerItemBecameCurrentNotification"), object: self.playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleVideoPlaying(_:)), name: NSNotification.Name(rawValue: "AVPlayerItemBecameCurrentNotification"), object: self.playerItem)
        
        
        statusObserversAdded = true
        
        self.player.replaceCurrentItem(with: self.playerItem)
    }
    
    func handleVideoPlaying(_ notification:Notification){
        
        if let object = notification.object as? AVPlayerItem{
            
            if object.asset.tracks(withMediaType: AVMediaTypeVideo).count == 0{
                print("Playing audio")
                self.shouldPause()
            }else{
                print("Playing Video")
                self.shouldPause()
            }
        }
    }
    
    func shouldPause(){
        self.player.pause()
        self.playerState = PlayerState.Paused
        self.multicastDelegate.invoke { (delegate) in
            delegate.setPlayButton(state: self.playerState)
        }
    }
    
    func shouldPlay(){
        self.player.play()
        self.playerState = PlayerState.Playing
        self.multicastDelegate.invoke { (delegate) in
            delegate.setPlayButton(state: self.playerState)
        }
    }
    
    
    // The player is going to take some time to buffer the remote resource and prepare it for play. So, only play the music when the player is ready.

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        print("KEYPATH:\(keyPath):player Status")
        
        if (keyPath ?? "" == "loadedTimeRanges")  && context == &Player.randomContextForObserver{
            
            self.handleLoadedTimeRanges()
            
        }else
            
            if (keyPath ?? "" == "status")  && context == &Player.randomContextForObserver{
                
                self.handleStatusNotification(object: object,keyPath: keyPath)
                
                
            }else if  (keyPath ?? "" == "playbackLikelyToKeepUp")  && context == &Player.randomContextForObserver{
                
                self.handleLikelyToKeepUp(keyPath: keyPath)
                
            }else if  (keyPath ?? "" == "playbackBufferEmpty")  && context == &Player.randomContextForObserver{
                
                self.handleBufferEmptyNotification(keyPath:keyPath)
            }
                
            else{
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func handleLoadedTimeRanges(){
        let playerItem = self.playerItem
        
        guard let times = playerItem?.loadedTimeRanges else{
            return
        }
        
        let values = times.map({$0.timeRangeValue})
        
        print("Values:\(values)")
        
        let durationTotal = values.reduce(0, { (actual, range) -> Double in
            return actual + range.end.seconds
        })
        
        let dur2 = durationTotal
        let progress = dur2/self.currentPlayerItemDuration.seconds
        
        print("Progress:\(progress)")
        
        if values.count > 1{
            print(values.count)
        }
        
        self.multicastDelegate.invoke(invokation: { (delegate) in
            delegate.showBufferedRange(value: progress)
        })
        
   
    }
    
    func handleStatusNotification(object:Any?,keyPath:String?){
        if let playerItemD = object as? AVPlayerItem{
            
            switch playerItemD.status {
                
            case .readyToPlay:
                
                self.playerState = PlayerState.ReadyToPlay
                
                print("KEYPATH:\(keyPath):player Status AVPlayerStatus.readyToPlay")
                
                initTimeObserver()
                
                
                player.play()
                
                
                break
                
            case .failed:
                
                deinitTimeObserver()
                self.player = nil
                
                self.player = AVPlayer()
                
                updatePlayerUI()
                self.playerState = PlayerState.Failed
                
                self.multicastDelegate.invoke { (delegate) in
                    delegate.setPlayButton(state: self.playerState)
                }
                
                if Helper.isInternetAvailable(){
                    
                    let banner = Banner(title: "Incorrect URL", subtitle: "Please try again")
                    banner.show()
                    
                }else{
                    let banner = Banner(title: "No Internet", subtitle: "Please connect to internet.")
                    banner.show()
                }
                
                break
                
            case .unknown:
                self.playerState = PlayerState.Invalid
                deinitTimeObserver()
                break
                
            }
        }
    }
    
    func handleLikelyToKeepUp(keyPath:String?){
        if self.playerItem?.isPlaybackLikelyToKeepUp ?? false{
            
            //set play button
            self.playerState = PlayerState.Playing
            
            self.multicastDelegate.invoke { (delegate) in
                delegate.setPlayButton(state: self.playerState)
            }
            
            print("KEYPATH:\(keyPath):player Item Status isPlaybackLikelyToKeepUp")
            
            //update the control center after buffering is finished
            
            self.updateNowPlayingInfoForCurrentPlaybackItem()
            
            if UIApplication.shared.applicationState == .background{
                self.player.play()
                self.endBgTask()
            }
            
        }else{
            self.playerState = PlayerState.Buffering
            
            //set play button
            self.multicastDelegate.invoke { (delegate) in
                delegate.setPlayButton(state: self.playerState)
            }
        }
    }
    
    func handleBufferEmptyNotification(keyPath:String?){
        self.playerState = PlayerState.Buffering
        
        //set play button
        self.multicastDelegate.invoke { (delegate) in
            delegate.setPlayButton(state: self.playerState)
        }
        
        if self.playerItem?.isPlaybackBufferEmpty ?? false{
            print("KEYPATH:\(keyPath):player Item Status isPlaybackBufferEmpty")
            
            if UIApplication.shared.applicationState == .background{
                self.beginBgTask()
            }
            
        }else{
            print("buffer Not empty")
        }
    }
    
    
    func removeStatusObservers(){
        print(#function)
        
        if statusObserversAdded{
            if self.playerItem != nil{
                
                self.playerItem?.removeObserver(self, forKeyPath: "status")
                self.playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
                self.playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
                self.playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AVPlayerItemBecameCurrentNotification"), object: self.playerItem)
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem)
                
//                self.playerItem = nil
                statusObserversAdded = false
                
            }
        }
    }
}
