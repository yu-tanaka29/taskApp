//
//  ViewController.swift
//  taskApp
//
//  Created by 田中 勇輝 on 2022/04/15.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    // table
    @IBOutlet weak var tableView: UITableView!
    // 絞り込み
    @IBOutlet weak var chooseCategory: UITextField!
    var pickerView: UIPickerView = UIPickerView()
    
    // Realmインスタンス取得
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    // カテゴリリスト
    var categoryArray = try! Realm().objects(Category.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // データを表示していない部分に罫線を表示するコード
        tableView.fillerRowHeight = UITableView.automaticDimension
        // デリゲート等
        tableView.delegate = self
        tableView.dataSource = self
        // カスタムセル(xib)
        tableView.register(UINib(nibName: "MainTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        
        // ピッカー設定
        pickerView.delegate = self
        pickerView.dataSource = self
        
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
    
        // インプットビュー設定
        chooseCategory.inputView = pickerView
        chooseCategory.inputAccessoryView = toolbar
    }
    
    // 絞り込み関連
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryArray[row].name
    }
    // 絞り込み決定押下
    @objc func done() {
        chooseCategory.endEditing(true)
        if categoryArray.count != 0 {
            chooseCategory.text = "\(categoryArray[pickerView.selectedRow(inComponent: 0)].name)"
            
            let id = categoryArray[pickerView.selectedRow(inComponent: 0)].id
            taskArray = try! Realm().objects(Task.self).filter("id = \(id)").sorted(byKeyPath: "date", ascending: true)
            tableView.reloadData()
        }
    }
    // 全件表示
    @IBAction func allDisplay(_ sender: Any) {
        taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        tableView.reloadData()
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! MainTableViewCell
        
        // Cellに値を設定する
        let task = taskArray[indexPath.row]
        cell.titleLabel.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.dateLabel.text = dateString
        
        if categoryArray.count != 0 {
            cell.categoryLabel.text = categoryArray[task.category_id].name
        }
        
        return cell
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
    // segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
}

