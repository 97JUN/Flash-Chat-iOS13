//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
        
        
    }
    
    func loadMessages() {

        
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)  //날짜별로 정렬
            .addSnapshotListener { (querysnapshot, error) in
            
            self.messages = []
            
            if let e = error {
                print("There was an issue retrieving data from Firestore/ \(e)")
            } else  {
                if let snapshotDocuments = querysnapshot?.documents {
                    for doc in snapshotDocuments    {
                        let data = doc.data()
                        if  let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String {
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage) //배열을 만들고 새 메시지를 해당 메시지 배열에                                 다시 추가하는 방식
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                            
                        }
                        
                    }
                }
            }
            }
    }
    
    
    @IBAction func sendPressed(_ sender: UIButton) {    //data 저장하는 부분
        
        if let messageBody = messageTextfield.text , let messageSensder = Auth.auth().currentUser?.email  {//현재 사용자에 접근, 현재 사용자가 있는경우 이메일을 보관하고 내부에 저장한다.
                db.collection(K.FStore.collectionName).addDocument(data: [  //add data 기능 찾기.
                
                K.FStore.senderField: messageSensder,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970
            ])
            { (error) in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                } else  {
                    print("Successfully saved data.")
                    
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                }
            }
            
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        
        do {
            try  Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
            
        } catch let signOutError as NSError {
            print(" Error signing out: %@", signOutError)
        }
    }
    
}



extension   ChatViewController: UITableViewDataSource   {   // 몇개의 행과 열을 원하는지 설정
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]//현재 로그인한 사용자나 다른 사람이 셀에 입력(새로운 상수 코드 생성
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        //현재 사용자의 메시지 입니다.
        if message.sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }
        //이것은 다른 발신자로부터의 메시지인 경우이다.
        else {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
            
        }
        
        
        return cell
    }
    
    
}


