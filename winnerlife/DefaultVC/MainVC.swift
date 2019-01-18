//
//  MainVC.swift
//  winnerlife
//
//  Created by godowondev on 2018. 11. 21..
//  Copyright © 2018년 Dreamteams. All rights reserved.
//

import UIKit
import Alamofire
import Alamofire_Synchronous
import SwiftyJSON
import FBSDKShareKit
import MessageUI
import Kingfisher

class MainVC: UIViewController, iCarouselDelegate, iCarouselDataSource, MFMessageComposeViewControllerDelegate {

    let common = Common()
    
    var items: [Int] = []
    var titles: [String] = []
    var periods: [String] = []
    var mem_counts: [String] = []
    var btn_names: [String] = []
    var btn_image_urls: [String] = []
    var btn_tags: [String] = []
    var btn_tag_contents: [String] = []
    
    let screenSize: CGRect = UIScreen.main.bounds
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var myCarousel: iCarousel!
    @IBOutlet weak var myTitle: UIButton!
    
    @IBAction func fbBtnClicked(_ sender: Any) {
        // import FBSDKShareKit 을 이용할경우
        let cont = FBSDKShareLinkContent()
        //cont.contentTitle = title!  // 작동안함
        //cont.contentDescription = content! // 작동안함
        cont.contentURL = URL(string: common.share_url)
        
        let dialog = FBSDKShareDialog()
        dialog.fromViewController = self
        dialog.mode = FBSDKShareDialogMode.native
        if !dialog.canShow() {
            dialog.mode = FBSDKShareDialogMode.automatic
        }
        dialog.shareContent = cont
        dialog.show()
    }
    
    @IBAction func bandBtnClicked(_ sender: Any) {
        if !SnsLinkHelper.canOpenBAND() {
            SnsLinkHelper.openiTunes("itms://itunes.apple.com/app/id1441615512")
            return
        }
        let postMessage = SnsLinkHelper.makeBANDLink("위너다이어트 " + common.share_url, common.share_url)
        if let urlString = postMessage {
            _ = SnsLinkHelper.openSNSLink(urlString)
        }
    }
    
    @IBAction func ktalkBtnClicked(_ sender: Any) {
        
        
        // Feed 타입 템플릿 오브젝트 생성
        let template = KMTFeedTemplate { (feedTemplateBuilder) in
            
            // 컨텐츠
            feedTemplateBuilder.content = KMTContentObject(builderBlock: { (contentBuilder) in
                contentBuilder.title = "위너다이어트"
                contentBuilder.desc = self.common.share_url
                contentBuilder.imageURL = URL(string: self.common.share_url+"/images/winner512.png")!
                contentBuilder.imageWidth = 400
                contentBuilder.imageHeight = 400
                contentBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    linkBuilder.mobileWebURL = URL(string: self.common.share_url)
                })
            })
            
        }
        
        // 카카오링크 실행
        KLKTalkLinkCenter.shared().sendDefault(with: template, success: { (warningMsg, argumentMsg) in
            
            // 성공
            print("warning message: \(String(describing: warningMsg))")
            print("argument message: \(String(describing: argumentMsg))")
            
        }, failure: { (error) in
            
            // 실패
            print("error \(error)")
            
        })
    }
    
    @IBAction func kstoryBtnClicked(_ sender: Any) {
        if !SnsLinkHelper.canOpenStoryLink() {
            SnsLinkHelper.openiTunes("itms://itunes.apple.com/app/id1441615512")
            return
        }
        let bundle = Bundle.main
        var postMessage: String!
        if let bundleId = bundle.bundleIdentifier, let appVersion: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let appName: String = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            postMessage = SnsLinkHelper.makeStoryLink("위너 다이어트 " + self.common.share_url, appBundleId: bundleId, appVersion: appVersion, appName: appName, scrapInfo: nil)
        }
        if let urlString = postMessage {
            _ = SnsLinkHelper.openSNSLink(urlString)
        }
    }
    
    @IBAction func mmsBtnClicked(_ sender: Any) {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = "위너다이어트\n\n함께 운동하실까요?\n\n" +  common.share_url
            controller.recipients = [""]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // background
        let image = UIImage(named: "logo_winner")
        navigationItem.titleView = UIImageView(image: image)
        
        setGradient()
        
        // carousel
        myCarousel.type = .coverFlow2
        myCarousel.dataSource = self
        myCarousel.delegate = self
        
        //App Delegate 에서 DidBecomeActive감지
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadView(_:)), name: NSNotification.Name("ReloadView"), object: nil)
        
        //print(self.view.frame.height)
        //myCarousel.frame.size.height = self.view.frame.height/2
        
    }

    override func viewWillAppear(_ animated: Bool) {
        getGameData()
        UIView.transition(with: self.myCarousel, duration: 0.3, options: .transitionCrossDissolve, animations: { self.myCarousel.reloadData() }, completion: nil)
    }
    
    @objc func reloadView(_ notification: Notification?) {
        getGameData()
        UIView.transition(with: self.myCarousel, duration: 0.3, options: .transitionCrossDissolve, animations: { self.myCarousel.reloadData() }, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func setGradient() {
        let gradientLayer:CAGradientLayer = CAGradientLayer()
        gradientLayer.frame.size = self.view.frame.size
        gradientLayer.colors = [UIColor.blue.withAlphaComponent(1).cgColor,UIColor.white.withAlphaComponent(1).cgColor]
        backgroundView.layer.addSublayer(gradientLayer)
    }
    
    public func getGameData(){
        
        items = []
        titles = []
        periods = []
        mem_counts = []
        btn_names = []
        btn_image_urls = []
        btn_tags = []
        btn_tag_contents = []
        
        let parameters: Parameters = [
            "action": "getGameData"
        ]
        
        
        let response = Alamofire.request(
            self.common.api_url,
            method: .post,
            parameters: parameters)
            .responseJSON(options: .allowFragments)
        
        if let data = response.result.value
        {
            //print(data)
            
            let json = JSON(data)
            
            let result_code = json["result_code"].string ?? ""
            let result_msg = json["result_msg"].string ?? ""
            
            if(result_code == "0000"){
                for (index,subJson):(String, JSON) in json {
                    // Do something you want
                    if(index == "game_data")
                    {
                        let game_data_json = JSON(subJson)
                        
                        for(index):(String, JSON) in game_data_json {
                            
                            let id = Int(index.0) ?? 0
                            let title = index.1["title"].string ?? ""
                            let period = index.1["period"].string ?? ""
                            let btn_name = index.1["btn_name"].string ?? ""
                            let btn_image_url = index.1["btn_image_url"].string ?? ""
                            let btn_tag = index.1["btn_tag"].string ?? ""
                            let btn_tag_content = index.1["btn_tag_content"].string ?? ""
                            
                            print(id)
                            print(title)
                            
                            self.items.append(id)
                            self.titles.append(title)
                            self.periods.append(period)
                            self.btn_names.append(btn_name)
                            self.btn_image_urls.append(btn_image_url)
                            self.btn_tags.append(btn_tag)
                            self.btn_tag_contents.append(btn_tag_content)
                        }
                    }
                }
            }else{
                self.showToast(message: result_msg)
            }
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        /*
        for i in 0 ... items.count {
            items.append(i)
            titles.append("title" + String(i))
            periods.append("periods" + String(i))
        }
        */
        //getGameData()
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return items.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {

        var fontsize1: CGFloat
        var fontsize2: CGFloat
        var label1: UILabel
        var label2: UILabel
        var label3: UILabel
        var button1: UIButton
        var itemView: UIImageView

        //reuse view if available, otherwise create a new view
        if let view = view as? UIImageView {
            itemView = view
            //get a reference to the label in the recycled view
            label1 = itemView.viewWithTag(1) as! UILabel
            label2 = itemView.viewWithTag(1) as! UILabel

            
        } else {

            if(screenSize.height<650){
                myTitle.titleLabel?.font = UIFont(name:"NanumBarunGothicOTFBold", size: 15)
                myTitle.frame.size.height = 15
                myTitle.setTitle("건강한 다이어트. 당신이 주인공입니다!", for:.normal)
                
                fontsize1 = 15
                fontsize2 = 10
            }else{
                fontsize1 = 25
                fontsize2 = 15
            }

            //don't do anything specific to the index within
            //this `if ... else` statement because the view will be
            //recycled and used with other index values later
            itemView = UIImageView(frame: CGRect(x: 0, y: 0, width: myCarousel.frame.size.width, height: myCarousel.frame.maxY - myTitle.frame.maxY - 20))
            itemView.contentMode = .scaleToFill

            //kingfisher 사용 캐시기능
            itemView.kf.setImage(with: URL(string: "\(btn_image_urls[index])"), placeholder: UIImage(named: "menu_image_1"), options: [.transition(ImageTransition.fade(0.5))])

            label1 = UILabel()
            label1.frame = CGRect(x: itemView.frame.minX, y: itemView.frame.maxY+10, width: itemView.frame.width, height: fontsize1+4)
            label1.backgroundColor = UIColor.clear
            label1.textAlignment = .left
            label1.font = UIFont(name:"NanumBarunGothicOTFBold", size: fontsize1)
            label1.text = "\(titles[index])"
            itemView.addSubview(label1)
            

            
            label2 = UILabel()
            label2.frame = CGRect(x: label1.frame.minX, y: label1.frame.maxY+5, width: itemView.frame.width, height: fontsize2+4)
            label2.backgroundColor = UIColor.clear
            label2.textAlignment = .left
            label2.font = UIFont(name:"NanumBarunGothicOTFBold", size: fontsize2)
            label1.textColor = UIColor.darkGray
            label2.text = "\(periods[index])"
            itemView.addSubview(label2)
            
            
            button1 = UIButton()
            button1.frame = CGRect(x: itemView.frame.maxX-160, y: itemView.frame.maxY-fontsize1*2-20, width: 140, height: fontsize1*2)
            button1.backgroundColor = common.uicolorFromHex(0xffea00)
            button1.layer.cornerRadius = 10
            button1.setTitleColor(UIColor.black, for: .normal)
            button1.titleLabel?.font = UIFont(name:"NanumBarunGothicOTFBold", size: fontsize2+3)
            button1.setTitle("\(btn_names[index])",for:.normal)
            if(!btn_tags[index].isEmpty)
            {
                button1.tag = Int(btn_tags[index]) ?? 0
                button1.accessibilityIdentifier = btn_tag_contents[index]
                button1.addTarget(self, action:#selector(self.customBtnClicked(sender:)), for: .touchUpInside)
            }
            itemView.addSubview(button1)
            itemView.isUserInteractionEnabled = true
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise"
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        
        

        return itemView
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 1.1
        }
        return value
    }
    
    @objc public func customBtnClicked(sender: UIButton) {
        print(sender.tag)
        
        switch sender.tag {
        
        case 1 :
            moveToWebViewWithUrl(url:sender.accessibilityIdentifier ?? "")

        default:
            print("default")
            
        }
        
    }
    
    func moveToWebViewWithUrl(url:String){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let next = storyboard.instantiateViewController(withIdentifier: "NavigationWebVC")as! NavigationWebVC
        next.selUrl = url
        self.navigationController?.pushViewController(next, animated: false)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
}

