//
//  Item.swift
//  yonnkomi
//
//  Created by Ryosuke Takaoka on 2025/07/20.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
