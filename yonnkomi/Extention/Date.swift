//
//  Date.swift
//  manga2
//
//  Created by Ryosuke Takaoka on 2025/02/09.
//

import Foundation

//date型
extension Date{
    //DateをString型に変更
    //「○月○日」
    func toMonthDayString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP") //日本語
        formatter.dateFormat = "M月d日" //フォーマットを指定
        return formatter.string(from: self)
    }
    
    //時間：分
    func toTimeString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP") //日本
        formatter.dateFormat = "H:m" //時間：分
        return formatter.string(from: self)
    }
}
