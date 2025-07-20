//
//  String.swift
//  manga2
//
//  Created by Ryosuke Takaoka on 2025/02/09.
//

import Foundation

extension String{
    /// 日付の文字列を「〇日前」「〇時間前」「〇分前」「〇秒前」の形式に変換
    func timeAgo() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        
        guard let targetDate = dateFormatter.date(from: self) else {
            return "日付のフォーマットが正しくありません"
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: targetDate, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)日前"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)時間前"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分前"
        } else if let seconds = components.second, seconds >= 0 {
            return "\(seconds)秒前"
        } else {
            return "今"
        }
    }
    
}

