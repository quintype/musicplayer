//
//  MulticastDelegate.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation
import UIKit


class MulticastDelegate<T>: NSObject {
    
    var weakDelegates:NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    func addDelegate(delegate:T){
        weakDelegates.add(delegate as AnyObject?)
    }
    
    func removeDelegate(delegate:T){
        if weakDelegates.contains(delegate as AnyObject?){
            weakDelegates.remove(delegate as AnyObject?)
        }
    }
    
    
    func invoke(invokation:(T) -> ()){
        let enumerator = self.weakDelegates.objectEnumerator()
        
        while let delegate: AnyObject = enumerator.nextObject() as AnyObject? {
            invokation(delegate as! T)
        }
    }
}
