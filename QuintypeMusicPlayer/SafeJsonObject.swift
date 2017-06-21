//
//  SafeJsonObject.swift
//  QuintypeMusicPlayer
//
//  Created by Albin.git on 6/21/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import Foundation

// MARK: Json parser classs for safely paring json

public class SafeJsonObject: NSObject {
    
    override public func setValue(_ value: Any?, forKey key: String) {
        let selectorString = "set\(key.uppercased().characters.first!)\(String(key.characters.dropFirst())):"
        let selector = Selector(selectorString)
        if responds(to: selector) {
            //print(key ,":", value)
            super.setValue(value, forKey: key)
        }
    }
    
}
