//
//  BackTableViewController.swift
//  test
//
//  Created by design on 2015. 9. 17..
//  Copyright (c) 2015년 design. All rights reserved.
//

import Foundation

@available(iOS 8.0, *)
class SWRearTableVC: UITableViewController {
    @IBOutlet weak var myName: UILabel!
    
    let common = Common()
    
    var TableArray = [String]()
    var url:String = ""
    var encodedUrl:String = ""
    var selUrl:String = ""
    var selMode:String = ""
    
    override func viewDidLoad() {
        
        let login_info = common.getUD("login_info") ?? ""
        
        TableArray = [
            "홈[Home]",
            "몸짱너머",
            "친구초대",
            "쇼미더머니",
            "만보기"
        ]
        
        if(login_info.isEmpty){
            TableArray.append("로그인")
        }else{
            TableArray.append("로그아웃")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        
        cell.textLabel?.text = TableArray[indexPath.row]
        cell.textLabel?.font = UIFont(name: "systemFont", size: 9)
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let DestVC = segue.destination as! SWFrontWebVC
        let indexPath : IndexPath = self.tableView.indexPathForSelectedRow!
        let selTitle = TableArray[indexPath.row]

        
        switch selTitle {
        case "홈[Home]" :
            url = "/"
            
        case "몸짱너머" :
            url = "/webzine/list.php"
            
        case "친구초대" :
            url = "/member/body_invitation.php"
            
        case "쇼미더머니" :
            url = "/bbs/?b_code=gift"
            
        case "만보기" :
            url = "/step.php"
            
        case "로그인" :
            url = "/login/login.php"
            
        case "로그아웃" :
            url = "/login/logout.php"
            common.setUD("login_info", "")
        
        default :
            title = "홈[Home]"
            url = "/"
            
        }
        
        //let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)

        DestVC.selUrl = url //encodedUrl
        print(url)

    }


}
    
