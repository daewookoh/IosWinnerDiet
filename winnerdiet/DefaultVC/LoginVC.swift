//
//  LoginVC.swift
//  winnerdiet
//
//  Created by godowondev on 2018. 11. 13..
//  Copyright © 2018년 Dreamteams. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import SwiftyJSON
import Validator

class LoginVC: UIViewController, XMLParserDelegate, NaverThirdPartyLoginConnectionDelegate {

    let common = Common()
    let swFrontWebView = SWFrontWebVC()
    
    struct ValidationError: Error {
        let message: String
        init(message m: String) {
            message = m
        }
    }
    
    @IBOutlet weak var myEmail: UITextField!
    @IBOutlet weak var myPassword: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var naverLoginBtn: UIButton!
    @IBOutlet weak var hiddenWebView: UIWebView!
    
    @IBAction func loginBtnClicked(_ sender: Any) {
        
        let a = myEmail.text!
        let b = myPassword.text!
        
        let ruleEmail = ValidationRulePattern(pattern: EmailValidationPattern.standard, error: ValidationError(message: "😫"))
        let ruleLength = ValidationRuleLength(min: 5, max: 10, error: ValidationError(message: "😫"))
        
        let resultEmail = a.validate(rule: ruleEmail)
        
        switch resultEmail {
        case .valid:
            print("😀")
            break
        case .invalid: self.showToast(message: "이메일을 정확히 입력해 주세요")
        return
            break
        }
        
        let resultPassword = b.validate(rule: ruleLength)
        
        switch resultPassword {
        case .valid:
            print("😀")
            break
        case .invalid: self.showToast(message: "패스워드는 5~10자리로 입력해 주세요")
        return
            break
        }
        
        let parameters: Parameters = [
            "action": "checkLogin",
            "type": "email",
            "a": a,
            "b": b
        ]
        
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
                        self.common.setUD("perform_auto_login_yn", "Y")
                        self.dismiss(animated: true, completion: nil)
                    }
                    else{
                        self.showToast(message: result_msg)
                    }
 
                }
        }
        
        //connectHttpAsync(resourceURL: common.api_url + "?action=checkLogin&type=email&a="+a+"&b="+b)
        
    }
    
    @IBAction func naverLoginBtnClicked(_ sender: Any) {
        let naverConnection = NaverThirdPartyLoginConnection.getSharedInstance()
        naverConnection?.delegate = self as! NaverThirdPartyLoginConnectionDelegate
        naverConnection?.requestThirdPartyLogin()
    }

    
    // 네이버 로그인
    var foundCharacters = "";
    var email = ""
    var id = ""
    var gender = ""
    var name = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loginBtn.layer.cornerRadius = 5
        naverLoginBtn.layer.cornerRadius = 5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // 네이버 로그인
    // 인그인전
    // 로그인 토큰이 없는 경우, 로그인 화면을 오픈한다.
    func oauth20ConnectionDidOpenInAppBrowser(forOAuth request: URLRequest!) {
        // Open Naver SignIn View Controller
        let naverSignInViewController = NLoginThirdPartyOAuth20InAppBrowserViewController(request: request)!
        present(naverSignInViewController, animated: true, completion: nil)
    }
    
    // 로그인후
    func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
        getNaverDataFromURL()
    }
    
    func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        getNaverDataFromURL()
    }
    
    func oauth20ConnectionDidFinishDeleteToken() {
        // Do Nothing
    }
    
    func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        // Do Nothing
    }
    
    func getNaverDataFromURL() {
        
        // Naver SignIn Success
        
        let loginConn = NaverThirdPartyLoginConnection.getSharedInstance()
        let tokenType = loginConn?.tokenType
        let accessToken = loginConn?.accessToken
        
        // Get User Profile
        if let url = URL(string: "https://apis.naver.com/nidlogin/nid/getUserProfile.xml") {
            if tokenType != nil && accessToken != nil {
                let authorization = "\(tokenType!) \(accessToken!)"
                var request = URLRequest(url: url)
                
                request.setValue(authorization, forHTTPHeaderField: "Authorization")
                let dataTask = URLSession.shared.dataTask(with: request) {(data, response, error) in
                    if let str = String(data: data!, encoding: .utf8) {
                        
                        var parser = XMLParser()
                        parser = XMLParser(data: data!)
                        parser.delegate = self
                        parser.parse()
                        
                        print("\n"+self.id+"\n"+self.gender+"\n"+self.name+"\n"+self.email+"\n")
                        
                        print(str)
                        
                        let url = self.common.sns_callback_url +
                            "?login_type=naver" +
                            "&success_yn=Y" +
                            "&id=" + self.id +
                            "&gender=" + self.gender +
                            "&name=" + self.name +
                            "&email=" + self.email
                        
                        let my_url = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
                        let request = URLRequest(url: my_url!)
                        self.hiddenWebView.loadRequest(request)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if(!self.id.isEmpty)
                            {
                                let parameters: Parameters = [
                                    "action": "checkLogin",
                                    "type": "naver",
                                    "a": self.id
                                ]
                                
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
                                                self.common.setUD("perform_auto_login_yn", "Y")
                                                self.dismiss(animated: true, completion: nil)
                                            }
                                            else{
                                                self.showToast(message: result_msg)
                                            }
                                            
                                        }
                                }
                            }
                        }
                        //self.moveToSWFrontWebVCWithUrl(url: url)

                        //print(url)
                        // Naver Sign Out
                        //loginConn?.resetToken()
                    }
                }
                dataTask.resume()
            }
        }
        
    }
    
    func moveToSWFrontWebVCWithUrl(url: String)
    {
        self.dismiss(animated: true, completion: nil)
        common.setUD("loginUrl", url)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "id" { foundCharacters = "" }
        else if elementName == "gender" { foundCharacters = "" }
        else if elementName == "name" { foundCharacters = "" }
        else if elementName == "email" { foundCharacters = "" }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        foundCharacters += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "id" { id = foundCharacters }
        else if elementName == "gender" { gender = foundCharacters }
        else if elementName == "name" { name = foundCharacters }
        else if elementName == "email" { email = foundCharacters }
    }
    // 네이버 로그인 끝

}
