//
//  MediaControll.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/14/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation
import MediaPlayer

//MARK: - Control Center NowPlaying

extension MusicPlayer{
    
    func configureCommandCenter() {
        
        self.commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let musicPlayer = self else { return .commandFailed }
            
            musicPlayer.didClickOnPlay()
            musicPlayer.updateNowPlayingInfoElapsedTime()
            
            return .success
        })
        
        self.commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let musicPlayer = self else { return .commandFailed }
            if musicPlayer.player.isPlaying{
                musicPlayer.didClickOnPlay()
                musicPlayer.updateNowPlayingInfoElapsedTime()
            }
            return .success
        })
        
        self.commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let musicPlayer = self else { return .commandFailed }
            musicPlayer.didClickOnNext()
            musicPlayer.updateNowPlayingInfoElapsedTime()
            return .success
        })
        
        self.commandCenter.previousTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let musicPlayer = self else { return .commandFailed }
            musicPlayer.didClickOnPrevious()
            musicPlayer.updateNowPlayingInfoElapsedTime()
            return .success
        })
        
        self.commandCenter.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            if let unwrappedEvent = event as? MPChangePlaybackPositionCommandEvent{
                print(unwrappedEvent.positionTime)
                let position = unwrappedEvent.positionTime
                let playerItemDuration = self.currentPlayerItemDuration
                
                let  valued = (position * (1)/playerItemDuration.seconds)
                
                self.deinitTimeObserver()
                self.initTimeObserver()
                
                self.scrub(value: Float(valued), minValue: 0, maxValue: 1, isSeeking: { (isSeeking) in
                    print(isSeeking)
                })
            }
            return .success
        }
        
        self.commandCenter.seekForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            return .success
        }
    }
    
    func updateNowPlayingInfoForCurrentPlaybackItem(){
        guard (self.player) != nil else {
            self.configureNowPlayingInfo(nil)
            return
        }
        
        guard let datasource = self.dataSource else {self.removeStatusObservers(); return}
        
        let unwrappedUrl = datasource.musicPlayerDidAskForArtWorksImageUrl(manager: self,size: .medium)
        let titleAndAuthor = datasource.musicPlayerDidAskForTrackTitleAndAuthor(manager: self)
        
        let nowPlayingInfo = [MPMediaItemPropertyTitle:titleAndAuthor.0,
                              MPMediaItemPropertyArtist:titleAndAuthor.1,
                              MPMediaItemPropertyPlaybackDuration:"\(self.currentPlayerItemDuration.seconds)",
            MPNowPlayingInfoPropertyPlaybackRate:NSNumber(value: 1.0 as Float)] as [String : Any]
        
        self.downloadImage(url: unwrappedUrl, completion: { (image) -> (Void) in
            guard var nowPlayingInfo = self.nowPlayingInfo else { return }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 100, height: 100), requestHandler: { (size) -> UIImage in
                return image
            })
            self.configureNowPlayingInfo(nowPlayingInfo)
        })
        
        self.configureNowPlayingInfo(nowPlayingInfo as [String : AnyObject]?)
        
        self.updateNowPlayingInfoElapsedTime()
    }
    
    func downloadImage(url:URL?, completion:@escaping ((UIImage) -> (Void))){
        if let unwrappedUrl = url{
            URLSession.shared.dataTask(with: unwrappedUrl) { (data, response, error) in
                DispatchQueue.main.async {
                    if let unwrappedData = data{
                        completion(UIImage(data: unwrappedData) ?? UIImage())
                    }
                }
                
                }.resume()
        }
    }
    
    func configureNowPlayingInfo(_ nowPlayingInfo: [String: AnyObject]?) {
        self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }
    
    func updateNowPlayingInfoElapsedTime() {
        guard var nowPlayingInfo = self.nowPlayingInfo else { return }
        print("Player Current Time:\(self.player.currentTime().seconds)")
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: self.player.currentTime().seconds as Double);
        
        self.configureNowPlayingInfo(nowPlayingInfo)
    }
    
    func resetNowPlayingInfoCenter(){
        self.nowPlayingInfo = nil
        self.nowPlayingInfoCenter.nowPlayingInfo = nil
    }
    
    func updatePlayerUI(){
        
        //set the duration
        let playerDuration = self.currentPlayerItemDuration
        
        self.multicastDelegate.invoke { (delegate) in
            delegate.setPlayeritemDuration(duration: playerDuration.seconds)
            
        }
        
        //set artwork Image
        guard let datasource = self.dataSource else {self.removeStatusObservers(); return}
        
        let unwrappedUrl = datasource.musicPlayerDidAskForArtWorksImageUrl(manager: self,size: .medium)
        let trackname = datasource.musicPlayerDidAskForTrackTitleAndAuthor(manager: self)
        
        self.multicastDelegate.invoke(invokation: { (delegate:MusicPlayerDelegate) in
            delegate.didsetArtWorkWithUrl(url: unwrappedUrl)
            delegate.didsetName(title: trackname.0,AutorName: trackname.1)
        })
        
        
    }
    
    func getQueuedTracks() -> [Tracks]?{
        guard let unwrappedDataSource = dataSource else{return nil}
        return unwrappedDataSource.musicPlayerDidAskForQueue()
    }
    
    func getCurrentSongIndex() -> Int?{
        guard let unwrappedDataSource = dataSource else{return nil }
        return unwrappedDataSource.musicPlayerDidAskForCurrentSongIndex()
    }
}

