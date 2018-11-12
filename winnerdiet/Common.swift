//
//  Common.swift
//  dreamteams_ios
//
//  Created by godowondev on 2018. 5. 13..
//  Copyright © 2018년 dreamteams. All rights reserved.
//

import Foundation
import UIKit

class Common {
    
    let app_name:String = "WinnerDiet"
    let default_url:String = "http://m.dreamteams.co.kr/"
    let api_url:String = "https//m.dreamteams.co.kr/app/api.php"
    let sns_callback_url:String = "http://m.dreamteams.co.kr/sns/callback_from_app.php"
    let user_agent:String = "dreamteams_app_ios"
    let js_name:String = "DreamteamsApp"
    
    let naver_client_id:String = "Lk2Zb2Zrbg5OH5O_S7sK"
    let naver_client_secret:String = "zash4KwwvV"
    let naver_url_scheme:String = "winnerdiet"
    let naver_app_name:String = "네이버 아이디로 로그인"
    
    let kakao_template_id = "10642"
    let apiHelper = APIHelper()
    
    func setUD(_ name:String,_ data:String) {
        print("setUD : " + name + " - " + data)
        UserDefaults.standard.set(data, forKey: name)
        UserDefaults.standard.synchronize()
    }
    
    func getUD(_ name:String) -> String? {
        print("getUD : " + name)
        return UserDefaults.standard.string(forKey: name)
        UserDefaults.standard.synchronize()
    }
    
    func setUDimage(_ name:String,_ data:Any) {
        print("setUDimage : " + name)
        UserDefaults.standard.set(data, forKey: name)
        UserDefaults.standard.synchronize()
    }
    
    func getToday() -> String{
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        return formatter.string(from: date)
    }
}
