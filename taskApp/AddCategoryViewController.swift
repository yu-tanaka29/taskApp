//
//  AddCategoryViewController.swift
//  taskApp
//
//  Created by 田中 勇輝 on 2022/04/20.
//

import UIKit
import RealmSwift

class AddCategoryViewController: UIViewController {

    let realm = try! Realm()
    // Category
    var category: Category!
    
    @IBOutlet weak var categoryField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // キャンセルボタン
    @IBAction func cancelButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // 追加ボタン
    @IBAction func addButton(_ sender: Any) {
        try! realm.write {
            self.category.name = self.categoryField.text!
            self.realm.add(self.category, update: .modified)
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
