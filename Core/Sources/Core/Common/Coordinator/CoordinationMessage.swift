//
//  CoordinationMessage.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import Foundation

public class CoordinationMessage<T> {
    
    public var content: T?
    
    public init(content: T?) {
        self.content = content
    }
}
