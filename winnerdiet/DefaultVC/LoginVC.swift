//
//  LoginVC.swift
//  winnerdiet
//
//  Created by godowondev on 2018. 11. 13..
//  Copyright © 2018년 Dreamteams. All rights reserved.
//

import UIKit
import WebKit

class LoginVC: UIViewController, XMLParserDelegate, NaverThirdPartyLoginConnectionDelegate {

    let common = Common()
    let swFrontWebView = SWFrontWebVC()
    
    @IBOutlet weak var myEmail: UITextField!
    @IBOutlet weak var myPassword: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var naverLoginBtn: UIButton!
    @IBOutlet weak var hiddenWebView: UIWebView!
    
    @IBAction func loginBtnClicked(_ sender: Any) {
        
        let a = myEmail.text!
        let b = myPassword.text!
        
        connectHttpAsync(resourceURL: common.api_url + "?action=checkLogin&type=email&a="+a+"&b="+b)
        
        /*
        if(myEmail.text=="test@test.com" && myPassword.text=="rheodn82"){
            
        }else{
            let alertController = UIAlertController(title:"정확한 정보를 입력해 주세요",message:nil,preferredStyle:.alert)
            self.present(alertController,animated:true,completion:{Timer.scheduledTimer(withTimeInterval: 0.5, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
        }
 */
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
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // change 2 to desired number of seconds
                            if(!self.id.isEmpty)
                            {
                                self.connectHttpAsync(resourceURL: self.common.api_url + "?action=checkLogin&type=naver&a="+self.id)
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

    func connectHttpAsync(resourceURL: String) {
        
        print(resourceURL)
        // 세션 생성, 환경설정
        let defaultSession = URLSession(configuration: .default)
        
        guard let url = URL(string: "\(resourceURL)") else {
            print("URL is nil")
            return
        }
        
        // Request
        let request = URLRequest(url: url)
        
        // dataTask
        let dataTask = defaultSession.dataTask(with: request) { data, response, error in
            // getting Data Error
            guard error == nil else {
                print("Error occur: \(String(describing: error))")
                return
            }
            
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                // 통신에 성공한 경우 data에 Data 객체가 전달됩니다.
                
                // 받아오는 데이터가 json 형태일 경우,
                // json을 serialize하여 json 데이터를 swift 데이터 타입으로 변환
                // json serialize란 json 데이터를 String 형태로 변환하여 Swift에서 사용할 수 있도록 하는 것을 말합니다.
                guard (try? JSONSerialization.jsonObject(with: data, options: [])) != nil else {
                    print(resourceURL)
                    print("No Json Result")
                    return
                }
                
                // 원하는 작업
                if let strData = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    let str = String(strData)
                    print(str)
                    
                    let jsonResult = self.jsonEncode(text: str)
                    
                    let result_code = jsonResult?["result_code"] as! String
                    //print(result_code)
                    
                    let result_msg = jsonResult?["result_msg"] as! String
                    //print(result_msg)
                    
                    if(result_code=="0000"){
                        let login_info = jsonResult?["login_info"] as! String
                        self.common.setUD("login_info", login_info)
                        self.dismiss(animated: true, completion: nil)
                    }else{
                        DispatchQueue.main.async {
                            self.showToast(message: result_msg)
                        }
                        
                    }
                }
                
            }
        }
        dataTask.resume()
    }
    
    func jsonEncode(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options:[]) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
}
