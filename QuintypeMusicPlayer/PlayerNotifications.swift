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

extension MusicPlayer{
    
    func addStatusObservers(){
        self.playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: &MusicPlayer.randomContextForObserver)
        
        self.playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: &MusicPlayer.randomContextForObserver)
        
        self.playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: &MusicPlayer.randomContextForObserver)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: OperationQueue.main, using: self.playerItemDIdPlayToItem!)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AVPlayerItemBecameCurrentNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleVideoPlaying(_:)), name: NSNotification.Name(rawValue: "AVPlayerItemBecameCurrentNotification"), object: nil)
        
    }
    
    func handleVideoPlaying(_ notification:Notification){
        if let object = notification.object as? AVPlayerItem{
            if object.asset.tracks(withMediaType: AVMediaTypeVideo).count == 0{
                print("Playing audio")
            }else{
                print("Playing Video")
                self.didClickOnPlay()
                
            }
        }
    }
    
    func handleInterruptions(_ notification:Notification){
        
        guard let typeKey = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,let interruptionType = AVAudioSessionInterruptionType(rawValue: typeKey) else{
            return
        }
        
        switch interruptionType {
        case .began:
            print("began")
            self.player.pause()
            break
        case .ended:
            print("ended")
            self.player.play()
            break
        }
        
    }
    
    // The player is going to take some time to buffer the remote resource and prepare it for play. So, only play the music when the player is ready.
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        
        if (keyPath ?? "" == "status")  && context == &MusicPlayer.randomContextForObserver{
            
            if let playerItemD = object as? AVPlayerItem{
                
                print(playerItemD.status.rawValue)
                
                
                switch playerItemD.status {
                case .readyToPlay:
                    self.playerState = PlayerState.ReadyToPlay
                    
                    print("KEYPATH:\(keyPath):player Status AVPlayerStatus.readyToPlay")
                    
                    initTimeObserver()
                    updatePlayerUI()
                    player.play()
                    
                    //set play button
                    self.multicastDelegate.invoke { (delegate) in
                        delegate.setPlayButton(state: PlayerState.ReadyToPlay)
                    }
                    
                    break
                case .failed:
                    
                    deinitTimeObserver()
                    self.player = nil
                    
                    self.player = AVPlayer()
                    
                    updatePlayerUI()
                    self.playerState = PlayerState.Invalid
                    
                    self.multicastDelegate.invoke { (delegate) in
                        delegate.setPlayButton(state: PlayerState.ReadyToPlay)
                    }
                    // TODO: - Add UI for popup error
                    //                    let banner = Banner(title: "Incorrect URL", subtitle: "Playing next item")
                    //                    banner.show()
                    
                    
                    self.didClickOnNext()
                    
                    break
                case .unknown:
                    self.playerState = PlayerState.Interrupted
                    deinitTimeObserver()
                    break
                    
                }
            }
            
        }else if  (keyPath ?? "" == "playbackLikelyToKeepUp")  && context == &MusicPlayer.randomContextForObserver{
            
            if self.playerItem?.isPlaybackLikelyToKeepUp ?? false{
                
                //set play button
                
                self.multicastDelegate.invoke { (delegate) in
                    delegate.setPlayButton(state: PlayerState.Playing)
                }
                
                print("KEYPATH:\(keyPath):player Item Status isPlaybackLikelyToKeepUp")
                
                //update the control center after buffering is finished
                
                self.updateNowPlayingInfoForCurrentPlaybackItem()
                
                if UIApplication.shared.applicationState == .background{
                    self.player.play()
                    self.endBgTask()
                }
                
            }else{
                print("KEYPATH:\(keyPath):player Item Status Playback NOT LikelyToKeepUp")
                print("buffering")
            }
        }
        else if  (keyPath ?? "" == "playbackBufferEmpty")  && context == &MusicPlayer.randomContextForObserver{
            
            self.playerState = PlayerState.Buffering
            
            //set play button
            self.multicastDelegate.invoke { (delegate) in
                delegate.setPlayButton(state: PlayerState.Buffering)
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
            
        else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
