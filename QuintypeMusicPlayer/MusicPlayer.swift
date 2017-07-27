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
import SystemConfiguration

open class Player: NSObject {
    
    open static let sharedInstance = Player(playerAttributes: [Player.BackgroundPolicy:NSNumber.init(value: true)])
    
    static var randomContextForObserver:Int = 0
    var playerItem:AVPlayerItem?
    var timeObserver:Any?
    var _timeObserverQueue:DispatchQueue?
    
    var statusObserversAdded = false
    
    open weak var dataSource:MusicPlayerDataSource?{
        
        didSet {    //called when dataSource changes
            guard let unwrappedDelegate = self.multicastDelegate else {
                return
            }
            
            unwrappedDelegate.invoke { (delegate) in
                guard let unwrappedDataSource = self.dataSource else{return}
                
                let tracks = unwrappedDataSource.musicPlayerDidAskForQueue()
                
                let userDefaults = UserDefaults.standard
                
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: tracks)
                
                userDefaults.set(encodedData, forKey: "PreviouslyPlayedSongs")
                
                userDefaults.synchronize()
                
                delegate.shouldupdateTracksList(tracks: tracks)
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
    open var player:AVPlayer!
    
    var scrubbingRate : Float!
    
    open var currentPlayerItemDuration:CMTime{
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
    
    open var playerHeight:CGFloat = 0
    
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
    
    public func getPreviouslyPlayedPlayListWithCurrentItem() -> ([Tracks],Int)?{
        
        let userDefaults = UserDefaults.standard
        
        guard let decoded  = userDefaults.data(forKey: "PreviouslyPlayedSongs"), let tracks = NSKeyedUnarchiver.unarchiveObject(with: decoded) as? [Tracks] else{
            return nil
        }
        
        if let currentTrackIndex = userDefaults.value(forKey: "currentlyPlayingSong") as? Int{
            
            return (tracks,currentTrackIndex)
            
        }
        
        return nil
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
    
    public func playWithURL(url:URL){
        
        let keys = ["duration","tracks","playable","rate"]
        let asset = AVURLAsset(url: url, options: .none)
        
        self.player.isMuted = true
        
        if self.isInternetAvailable(){
            
            asset.loadValuesAsynchronously(forKeys: keys, completionHandler: {
                
                for key in keys{
                    var error:NSError? = nil
                    let status = asset.statusOfValue(forKey: key, error: &error)
                    
                    if status == .failed{
                        self.playerState = PlayerState.Failed
                        return
                    }
                }
                
                if asset.isPlayable == false{
                    self.playerState = PlayerState.Failed
                    return
                }
                
                DispatchQueue.main.async {
                    self.removeStatusObservers()
                    self.playerItem = AVPlayerItem(asset: asset)
                    self.addStatusObservers()
                }
                
            })
        }else{
            //Handle No internet condition
            DispatchQueue.main.async {
                let banner = Banner(title: "No Internet", subtitle: "Please connect to internet.")
                banner.show()
                self.deinitTimeObserver()
                self.player = nil
                
                self.player = AVPlayer()
                
                self.removeStatusObservers()
                self.updatePlayerUI()
                
            }
            
            
        }
        
        if playerHeight == 0{
            playerHeight = 70
            self.multicastDelegate.invoke { (delegate) in
                delegate.shouldShowMusicPlayer(shouldShow: true)
            }
        }
    }
    
    func updateCurrentSongIndex(){
        
        let index = self.dataSource?.musicPlayerDidAskForCurrentSongIndex()
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(index!, forKey: "currentlyPlayingSong")
        userDefaults.synchronize()
        
    }
    
    public func updateLastPlayedItem(url:URL){
        self.removeStatusObservers()
        
        self.playerState = PlayerState.Paused
        self.playerItem = AVPlayerItem.init(url: url)
        self.player.replaceCurrentItem(with: self.playerItem!)
        
    }
    
    internal func isInternetAvailable() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
        
    }
    
    deinit {
        deinitTimeObserver()
        removeStatusObservers()
        timeObserver = nil
        playerItem = nil
    }
}
