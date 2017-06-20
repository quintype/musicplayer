//
//  PlayerProtocol.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation

protocol MusicPlayerDataSource:class{
    
    func musicPlayerDidReachEndOfCurrentItem(manager:MusicPlayer)
    func musicPlayerShoulMoveToNextItem(manager:MusicPlayer) -> Bool
    func musicPlayerShoulMoveToPreviousItem(manager:MusicPlayer) -> Bool
    func musicPlayerDidAskForNextItem(manager:MusicPlayer) -> URL?
    func musicPlayerDidAskForPreviousItem(manager:MusicPlayer) -> URL?
    func musicPlayerDidAskForArtWorksImageUrl(manager:MusicPlayer,size:ArtWorks) -> URL?
    func musicPlayerDidAskForTrackTitleAndAuthor(manager:MusicPlayer) -> (String,String)
    func musicPlayerDidAskForQueue() -> [Tracks]
    func musicPlayerDidAskForCurrentSongIndex() -> Int
    
}


protocol MusicPlayerDelegate:class{
    
    func musicPlayerPeriodicEvent(manager:MusicPlayer,periodicTimeObserverEventDidOccur time:CMTimeWrapper)
    func musicPlayerSyncScrubber(manager: MusicPlayer, syncScrubberWithCurrent time: Double, duration:Double)
    func resetDisplayIfNecessary(manager:MusicPlayer)
    func durationDidBecomeInvalidWhileSyncingScrubber(manager:MusicPlayer)
    func setPlayButton(state:PlayerState)
    func setPlayeritemDuration(duration:Double)
    func didsetArtWorkWithUrl(url:URL?)
    func didsetName(title:String?,AutorName:String?)
    func shouldShowMusicPlayer(shouldShow:Bool)
    func shouldupdateTracksList(tracks:[Tracks]?)
    
}
