//
//  JoinVC.swift
//  winnerdiet
//
//  Created by godowondev on 2018. 11. 15..
//  Copyright © 2018년 Dreamteams. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Validator

class JoinVC: UIViewController {

    struct ValidationError: Error {
        let message: String
        init(message m: String) {
            message = m
        }
    }
    
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var pw1: UITextField!
    @IBOutlet weak var pw2: UITextField!
    
    @IBAction func joinBtnClicked(_ sender: Any) {
        
        let my_email = email.text
        let my_pw1 = pw1.text
        let my_pw2 = pw2.text
        
        let ruleEmail = ValidationRulePattern(pattern: EmailValidationPattern.standard, error: ValidationError(message: "😫"))
        let ruleLength = ValidationRuleLength(min: 5, max: 10, error: ValidationError(message: "😫"))
        
        let resultEmail = my_email?.validate(rule: ruleEmail)
        
        switch resultEmail {
        case .valid?:
            print("😀")
            break
        case .invalid?: self.showToast(message: "이메일을 정확히 입력해 주세요")
            return
            break
        case .none: break
        }
        
        let resultPassword = my_pw1?.validate(rule: ruleLength)
        
        switch resultPassword {
        case .valid?:
            print("😀")
            break
        case .invalid?: self.showToast(message: "패스워드는 5~10자리로 입력")
        return
            break
        case .none: break
        }
        
        if(my_pw1 != my_pw2)
        {
            self.showToast(message: "패스워드가 일치하지 않습니다")
        }
        
        
        
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        

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
