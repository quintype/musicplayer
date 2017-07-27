//
//  PlayerProtocol.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation

public protocol MusicPlayerDataSource:class{
    
    func musicPlayerDidReachEndOfCurrentItem(manager:Player)
    func musicPlayerShoulMoveToNextItem(manager:Player) -> Bool
    func musicPlayerShoulMoveToPreviousItem(manager:Player) -> Bool
    func musicPlayerDidAskForNextItem(manager:Player) -> URL?
    func musicPlayerDidAskForPreviousItem(manager:Player) -> URL?
    func musicPlayerDidAskForArtWorksImageUrl(manager:Player,size:ArtWorks) -> URL?
    func musicPlayerDidAskForTrackTitleAndAuthor(manager:Player) -> (String,String)
    func musicPlayerDidAskForQueue() -> [Tracks]
    func musicPlayerDidAskForCurrentSongIndex() -> Int
    
}


public protocol MusicPlayerDelegate:class{
    
    func musicPlayerPeriodicEvent(manager:Player,periodicTimeObserverEventDidOccur time:CMTimeWrapper)
    func musicPlayerSyncScrubber(manager: Player, syncScrubberWithCurrent time: Double, duration:Double)
    func resetDisplayIfNecessary(manager:Player)
    func durationDidBecomeInvalidWhileSyncingScrubber(manager:Player)
    func setPlayButton(state:PlayerState)
    func setPlayeritemDuration(duration:Double)
    func didsetArtWorkWithUrl(url:URL?)
    func didsetName(title:String?,AutorName:String?)
    func shouldShowMusicPlayer(shouldShow:Bool)
    func shouldupdateTracksList(tracks:[Tracks]?)
    
    func showBufferedRange(value:Double)
    
}
