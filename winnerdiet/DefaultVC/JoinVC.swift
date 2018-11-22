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

    let common = Common()
    
    struct ValidationError: Error {
        let message: String
        init(message m: String) {
            message = m
        }
    }
    
    
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var pw1: UITextField!
    @IBOutlet weak var pw2: UITextField!
    
    @IBAction func joinBtnClicked(_ sender: Any) {
        
        let my_name = name.text ?? ""
        let my_email = email.text ?? ""
        let my_pw1 = pw1.text ?? ""
        let my_pw2 = pw2.text ?? ""
        
        let ruleEmail = ValidationRulePattern(pattern: EmailValidationPattern.standard, error: ValidationError(message: "😫"))
        let ruleLength = ValidationRuleLength(min: 5, max: 10, error: ValidationError(message: "😫"))
        let ruleNameLength = ValidationRuleLength(min: 2, max: 20, error: ValidationError(message: "😫"))
        
        let resultName = my_name.validate(rule: ruleNameLength)
        
        switch resultName {
        case .valid:
            print("😀")
            break
        case .invalid: self.showToast(message: "이름은 2자 이상으로 입력해 주세요")
        return
            break
        }
        
        let resultEmail = my_email.validate(rule: ruleEmail)
        
        switch resultEmail {
        case .valid:
            print("😀")
            break
        case .invalid: self.showToast(message: "이메일을 정확히 입력해 주세요")
            return
            break
        }
        
        let resultPassword = my_pw1.validate(rule: ruleLength)
        
        switch resultPassword {
        case .valid:
            print("😀")
            break
        case .invalid: self.showToast(message: "패스워드는 5~10자리로 입력해 주세요")
            return
            break
        }
        
        if(my_pw1 != my_pw2)
        {
            self.showToast(message: "패스워드가 일치하지 않습니다")
        }
        
        let parameters: Parameters = [
            "action": "joinMember",
            "mb_name": my_name,
            "mb_email": my_email,
            "mb_password": my_pw1
        ]
        
        //print(parameters)
        
        Alamofire.request(
            self.common.api_url,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.default
            //headers: ["Content-Type":"application/json", "Accept":"application/json"] // post에서 작동안함
            )
            .validate(statusCode: 200..<300)
            .responseJSON {
                response in
                if let data = response.result.value
                {
                    print(data)
                    
                    let json = JSON(data)
                    
                    let result_code = json["result_code"].string ?? ""
                    let result_msg = json["result_msg"].string ?? ""
                    
                    if(result_code == "0000"){
                        let login_info = json["login_info"].string ?? ""
                        
                        self.common.setUD("login_info", login_info)
                        self.dismiss(animated: true, completion: nil)
                    }
                    else{
                        self.showToast(message: result_msg)
                    }
                    /*
                    for result in JSON[""].arrayValue {
                        let result_code = result["result_code"].stringValue
                        
                        print(result_code)
                    }
 */
                    /*
                    if(JSON["result_code"].bool! != "0000")
                    {
                        self.showToast(message: JSON["result_msg"])
                    }
 */
                }
        }
        
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
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
