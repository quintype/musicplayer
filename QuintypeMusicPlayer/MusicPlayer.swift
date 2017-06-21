//
//  musicPlayer.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
//import Quintype

open class Player: NSObject {
    
    open static let sharedInstance = Player()

    static var randomContextForObserver:Int = 0
    var playerItem:AVPlayerItem?
    var timeObserver:Any?
    var _timeObserverQueue:DispatchQueue?
    
    weak var dataSource:MusicPlayerDataSource?{
        
        didSet {    //called when dataSource changes
            guard let unwrappedDelegate = self.multicastDelegate else {
                return
            }
            
            unwrappedDelegate.invoke { (delegate) in
                guard let unwrappedDataSource = self.dataSource else{return}
                delegate.shouldupdateTracksList(tracks: unwrappedDataSource.musicPlayerDidAskForQueue())
            }
            print("MusicPlayerDataSource Changed")
        }
        
    }
    
    var timeObserverQueue:DispatchQueue{
        
        get{
            if _timeObserverQueue == nil{
                _timeObserverQueue = DispatchQueue.main
            }
            return _timeObserverQueue!
        }
        
        set{
            _timeObserverQueue = newValue
        }
        
    }
    
    var bgTaskIdentifier = UIBackgroundTaskInvalid
    public static let BackgroundPolicy:String = "Background_Policy"
    var player:AVPlayer!
    
    var scrubbingRate : Float!
    
    var currentPlayerItemDuration:CMTime{
        get{
            if self.player.currentItem == nil{
                return kCMTimeInvalid
            }
            return self.player.currentItem!.duration
        }
    }
    
    typealias NotificationBlock = (Notification) -> ()
    
    var playerItemDIdPlayToItem:NotificationBlock?
    
    open var multicastDelegate:MulticastDelegate<MusicPlayerDelegate>!
    var kInterval = 0.5
    var playerState: PlayerState!
    
    
    var commandCenter: MPRemoteCommandCenter!
    var nowPlayingInfoCenter: MPNowPlayingInfoCenter!
    var notificationCenter: NotificationCenter!
    
    var nowPlayingInfo: [String : AnyObject]?
    
    var playerHeight:CGFloat = 0
    
    required public init(playerAttributes:Dictionary<String,Any>? = nil){
        super.init()
        
        commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.seekForwardCommand.isEnabled = true
        commandCenter.seekBackwardCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        
        nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        notificationCenter = NotificationCenter.default
        
        commonInit()
        configure(playerAttributes: playerAttributes)
        
        self.configureCommandCenter()
    }
    
    func configurePlayerItemDidEndBlock(){
        
        self.playerItemDIdPlayToItem = {notification in
            self.beginBgTask()
            self.player.seek(to: kCMTimeZero, completionHandler: { (finished) in
                guard let datasource = self.dataSource else {self.removeStatusObservers(); return}
                datasource.musicPlayerDidReachEndOfCurrentItem(manager: self)
                
                _ = self.player.actionAtItemEnd
                
                if datasource.musicPlayerShoulMoveToNextItem(manager: self){
                    if let nextItemURL = datasource.musicPlayerDidAskForNextItem(manager: self){
                        self.playWithURL(url: nextItemURL)
                        return
                    }
                    self.removeStatusObservers();
                }
                self.endBgTask()
            })
        }
        
    }
    
    func beginBgTask(){
        if self.bgTaskIdentifier == UIBackgroundTaskInvalid{
            self.bgTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                UIApplication.shared.endBackgroundTask(self.bgTaskIdentifier)
                self.bgTaskIdentifier = UIBackgroundTaskInvalid
            })
        }
    }
    
    func endBgTask(){
        if self.bgTaskIdentifier != UIBackgroundTaskInvalid{
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: {
                UIApplication.shared.endBackgroundTask(self.bgTaskIdentifier)
                self.bgTaskIdentifier = UIBackgroundTaskInvalid
            })
            
        }
    }
    
    func configure(playerAttributes:Dictionary<String,Any>?){
        guard let attributes = playerAttributes else{return}
        
        if let bgPolicy = (attributes[Player.BackgroundPolicy] as? NSNumber)?.boolValue{
            if bgPolicy{
            Player.enableBackgroundPlay()
            }
            
        }
        
    }
    
    private func commonInit(){
        multicastDelegate = MulticastDelegate<MusicPlayerDelegate>()
        player = AVPlayer.init()
        self.configurePlayerItemDidEndBlock()
    }
    
    func removeStatusObservers(){
        if self.playerItem != nil{
            self.playerItem?.removeObserver(self, forKeyPath: "status")
            self.playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            self.playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            self.playerItem = nil
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    class func enableBackgroundPlay(){
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let avError{
            print(avError)
        }
    }
    
    func initTimeObserver(){
        
        let interval = kInterval
        //make the callback fire every half seconds
        let playerDuration = self.currentPlayerItemDuration
        
        if playerDuration == kCMTimeInvalid{
            return
        }
        
        timeObserver = self.player.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: interval, preferredTimescale: CMTimeScale.init(NSEC_PER_SEC)), queue: timeObserverQueue) { (time) in
            
            self.multicastDelegate.invoke(invokation: { (delegate:MusicPlayerDelegate) in
                delegate.musicPlayerPeriodicEvent(manager: self, periodicTimeObserverEventDidOccur: CMTimeWrapper.init(seconds: CMTimeGetSeconds(time), value: time.value, timeScale: time.timescale))
            })
            
            self.syncScrubber()
        }
        
    }
    
    
    func syncScrubber(){
        //update seeker position as music plays
        if self.currentPlayerItemDuration == kCMTimeInvalid{
            
            self.multicastDelegate.invoke(invokation: { (delegate:MusicPlayerDelegate) in
                delegate.durationDidBecomeInvalidWhileSyncingScrubber(manager: self)
            })
            return
        }
        
        let durationSeconds = CMTimeGetSeconds(self.currentPlayerItemDuration)
        
        // Make sure the duration is finite. A live stream for example doesn't quantitively have a finite duration.
        if durationSeconds.isFinite{
            self.multicastDelegate.invoke(invokation: { (delegate) in
                delegate.musicPlayerSyncScrubber(manager: self, syncScrubberWithCurrent: CMTimeGetSeconds(self.player.currentTime()), duration: durationSeconds)
            })
        }
    }
    
    func deinitTimeObserver(){
        if timeObserver != nil{
            self.player.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
    }
    
    func playWithURL(url:URL){
        
        removeStatusObservers()
        
        DispatchQueue.main.async {
            self.playerItem = AVPlayerItem.init(url: url)
            self.player.replaceCurrentItem(with: self.playerItem!)
            self.addStatusObservers()
        }
        
        self.multicastDelegate.invoke { (delegate) in
            delegate.shouldShowMusicPlayer(shouldShow: true)
        }
    }
    
    
    deinit {
        deinitTimeObserver()
        removeStatusObservers()
        timeObserver = nil
        playerItem = nil
    }
}



