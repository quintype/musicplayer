//
//  MulticastDelegate.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation
import UIKit


open class MulticastDelegate<T>: NSObject {
    
    open var weakDelegates:NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    public func addDelegate(delegate:T){
        weakDelegates.add(delegate as AnyObject?)
    }
    
    public func removeDelegate(delegate:T){
        if weakDelegates.contains(delegate as AnyObject?){
            weakDelegates.remove(delegate as AnyObject?)
        }
    }
    
    
    public func invoke(invokation:(T) -> ()){
        let enumerator = self.weakDelegates.objectEnumerator()
        
        while let delegate: AnyObject = enumerator.nextObject() as AnyObject? {
            invokation(delegate as! T)
        }
    }
}
