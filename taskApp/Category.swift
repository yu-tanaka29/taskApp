//
//  Category.swift
//  taskApp
//
//  Created by 田中 勇輝 on 2022/04/20.
//
import RealmSwift

class Category: Object {
    // 管理用ID、プライマリーキー
    @objc dynamic var id = 0
    
    // カテゴリ名
    @objc dynamic var name = ""
    
    // idをプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}
