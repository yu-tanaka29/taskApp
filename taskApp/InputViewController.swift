//
//  InputViewController.swift
//  taskApp
//
//  Created by 田中 勇輝 on 2022/04/15.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var titleTextField: UITextField! // タイトル
    @IBOutlet weak var categoryMenu: UITextField! // カテゴリ名
    var pickerView: UIPickerView = UIPickerView()
    @IBOutlet weak var contentsTextView: UITextView! // 内容
    @IBOutlet weak var datePicker: UIDatePicker! // 日付
    
    let realm = try! Realm()
    
    var task: Task!
    var category: Category!
    var categoryArray = try! Realm().objects(Category.self)
    
    var chooseCategory = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        titleTextField.text = task.title
        if categoryArray.count != 0 {
            categoryMenu.text = categoryArray[task.category_id].name
        }
        contentsTextView.text = task.contents
        datePicker.date = task.date
        
        // ピッカー設定
        pickerView.delegate = self
        pickerView.dataSource = self
        
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        
        // インプットビュー設定
        categoryMenu.inputView = pickerView
        categoryMenu.inputAccessoryView = toolbar
        
    }
    
    
    // カテゴリ選択
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryArray[row].name
    }
    // 決定ボタン押下
    @objc func done() {
        categoryMenu.endEditing(true)
        if categoryArray.count != 0 {
            chooseCategory = categoryArray[pickerView.selectedRow(inComponent: 0)].id
            categoryMenu.text = "\(categoryArray[pickerView.selectedRow(inComponent: 0)].name)"
        }
    }
    
    // segueで画面遷移する時に呼ばれる(カテゴリ追加画面へ遷移時)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let addCategoryViewController: AddCategoryViewController = segue.destination as! AddCategoryViewController
        
        let category = Category()
        
        let allCategories = realm.objects(Category.self)
        if allCategories.count != 0 {
            category.id = allCategories.max(ofProperty: "id")! + 1
        }
        addCategoryViewController.category = category
    }
    
    // 保存／更新ボタン
    @IBAction func saveButton(_ sender: Any) {
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.category_id = chooseCategory
            
            self.realm.add(self.task, update: .modified)
        }
        
        setNotification(task: task)
        // トップ画面(一覧画面)に戻る
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    // キャンセルボタン
    @IBAction func cancelButton(_ sender: Any) {
        // 前の画面に戻る
        self.navigationController?.popViewController(animated: true)
    }
    
    // Backボタン
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        content.sound = UNNotificationSound.default
        
        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calender = Calendar.current
        let dateComponents = calender.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        print(dateComponents)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通信登録 OK") // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します
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
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
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
