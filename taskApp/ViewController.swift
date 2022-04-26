//
//  ViewController.swift
//  taskApp
//
//  Created by 田中 勇輝 on 2022/04/15.
//
import UIKit
import RealmSwift
import UserNotifications
class ViewController: UIViewController {
    // MARK: - IBOutlet
    // tableView
    @IBOutlet weak var tableView: UITableView!
    // 絞り込み
    @IBOutlet weak var chooseCategory: UITextField!
    // MARK: - Private
    var pickerView: UIPickerView = UIPickerView()
    // Realmインスタンス取得
    // TODO: なんで強制アンラップ？
    var realm: Realm?
    // DB内のタスクが格納されるリスト
    // TODO: なんでTask.selfにしてるの？Taskじゃダメなの？
    // TODO
    var taskArray: Results<Task>?
    // カテゴリリスト
    // TODO: なんで上でrealmのインスタンス取ってるのにここでまたRealm()してるの
    var categoryArray = try! Realm().objects(Category.self)
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // データを表示していない部分に罫線を表示するコード
        self.tableView.fillerRowHeight = UITableView.automaticDimension
        // デリゲート等
        self.tableView.delegate = self
        self.tableView.dataSource = self
        // カスタムセル(xib)
        self.tableView.register(UINib(nibName: "MainTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        // ピッカー設定
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        // インプットビュー設定
        self.chooseCategory.inputView = self.pickerView
        self.chooseCategory.inputAccessoryView = toolbar
        
        
    }
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.realm = try? Realm()
        self.taskArray = self.realm?.objects(Task.self)
        self.tableView.reloadData()
    }
    // segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: なんでここでダウンキャストしてるの？
        let inputViewController: InputViewController = segue.destination as! InputViewController
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            //try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)  // ←追加
            //inputViewController.task = self.taskArray[indexPath!.row]
            inputViewController.task = self.realm?.objects(Task.self).sorted(byKeyPath: "date", ascending: true)[indexPath!.row]
        } else {
            let task = Task()
            if let allTask = self.realm?.objects(Task.self),
               allTask.count != 0 {
                task.id = allTask.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
        }
    }
    // MARK: - IBAction
    /// 全件表示ボタン押下時
    ///
    /// - Parameter sender: UIButton
    @IBAction func allDisplay(_ sender: UIButton) {
        // TODO: なんで上でrealmのインスタンス取ってるのにここでまたRealm()してるの
        self.taskArray = self.realm?.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        self.tableView.reloadData()
    }
    // MARK: - Private Methods
    // 絞り込み決定押下
    @objc func done() {
        self.chooseCategory.endEditing(true)
        if self.categoryArray.count != 0 {
            self.chooseCategory.text = "\(self.categoryArray[self.pickerView.selectedRow(inComponent: 0)].name)"
            let id = self.categoryArray[self.pickerView.selectedRow(inComponent: 0)].id
            // TODO: なんで上でrealmのインスタンス取ってるのにここでまたRealm()してるの
            self.taskArray = self.realm?.objects(Task.self).filter("category_id = \(id)").sorted(byKeyPath: "date", ascending: true)
            self.tableView.reloadData()
        }
    }
}
// MARK: - UITableViewDelegate, UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    /// セクション数を設定
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - section: セクション情報
    /// - Returns: セクション数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.taskArray?.count ?? 0 // nilなら0
    }
    /// セルの情報を設定
    ///
    /// - Parameters:
    ///   - tableView: UITabelView
    ///   - indexPath: セクション情報およびセル番号情報
    /// - Returns: セル
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! MainTableViewCell
        // Cellに値を設定する
        if let task = self.taskArray?[indexPath.row] { // taskをアンラップする
            cell.titleLabel.text = task.title
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString:String = formatter.string(from: task.date)
            cell.dateLabel.text = dateString
            if self.categoryArray.count != 0 {
                cell.categoryLabel.text = self.categoryArray[task.category_id].name
            }
        }
        return cell
    }
    /// セル押下直後の設定
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: セクション情報およびセル番号情報
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
            if let task = self.taskArray?[indexPath.row] { // taskのアンラップ
                // ローカル通知をキャンセルする
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
                // データベースから削除する
                try! self.realm?.write {
                    self.realm?.delete(task)
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
    }
}
// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    // 絞り込み関連
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    // TODO: docコメント
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.categoryArray.count
    }
    // TODO: docコメント
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.categoryArray[row].name
    }
}
