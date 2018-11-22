//
//  MainVC.swift
//  winnerdiet
//
//  Created by godowondev on 2018. 11. 21..
//  Copyright © 2018년 Dreamteams. All rights reserved.
//

import UIKit
import Alamofire
import Alamofire_Synchronous
import SwiftyJSON

class MainVC: UIViewController, iCarouselDelegate,iCarouselDataSource {

    let common = Common()
    
    var items: [Int] = []
    var titles: [String] = []
    var periods: [String] = []
    var mem_counts: [String] = []
    var btn_names: [String] = []
    var btn_images: [String] = []
    var btn_tags: [String] = []
    
    let screenSize: CGRect = UIScreen.main.bounds
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var myCarousel: iCarousel!
    @IBOutlet weak var myTitle: UIButton!
    
    
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
        
        //print(self.view.frame.height)
        //myCarousel.frame.size.height = self.view.frame.height/2
        
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
                            let btn_image = index.1["btn_image"].string ?? ""
                            let btn_tag = index.1["btn_tag"].string ?? ""
                            
                            print(id)
                            print(title)
                            
                            self.items.append(id)
                            self.titles.append(title)
                            self.periods.append(period)
                            self.btn_names.append(btn_name)
                            self.btn_images.append(btn_image)
                            self.btn_tags.append(btn_tag)
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
        getGameData()
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

            if(btn_images[index].isEmpty){
                itemView.image = UIImage(named: "item_bg_diet")
            } else {
                itemView.image = UIImage(named: "\(btn_images[index])")
            }

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
        
            case 3 :
                moveToWebViewWithUrl(url:common.default_url + "/step.php")
            
            case 4 :
                moveToWebViewWithUrl(url:common.default_url + "/webzine/list.php")
            
            case 5 :
                moveToWebViewWithUrl(url:common.default_url + "/member/body_invitation.php")

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
}

