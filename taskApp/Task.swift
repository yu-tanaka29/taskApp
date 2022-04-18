//
//  Task.swift
//  taskApp
//
//  Created by 田中 勇輝 on 2022/04/18.
//

import RealmSwift

class Task: Object {
    // 管理用ID、プライマリーキー
    @objc dynamic var id = 0
    
    // タイトル
    @objc dynamic var title = ""
    
    // 内容
    @objc dynamic var contents = ""
    
    // 日時
    @objc dynamic var date = Date()
    
    // idをプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}
