//
//  ViewController.swift
//  test
//
//  Created by design on 2015. 9. 17..
//  Copyright (c) 2015년 design. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore
import MessageUI
import Social
import FBSDKShareKit
import HealthKit

@available(iOS 8.0, *)
class SWFrontWebVC: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, XMLParserDelegate, NaverThirdPartyLoginConnectionDelegate{

    @IBOutlet weak var myTitle: UILabel!
    @IBOutlet weak var myViewForWeb: UIView!
    
    @IBAction func backBtnClicked(_ sender: Any) {

        let url = webView.url?.absoluteString
        
        if(url==common.default_url){
            exit(0)
        }else if(url?.range(of: "step.php") != nil){
            loadPage(url: common.default_url)
        }else if(webView.canGoBack){
            webView.goBack()
        }else{
            loadPage(url: common.default_url)
        }
    }
    
    @IBAction func menuBtnClicked(_ sender: Any) {
        self.revealViewController().revealToggle(self)
    }
    
    let common = Common()
    
    var refreshControl:UIRefreshControl?
    var healthStore = HKHealthStore()
    var stepData =  [String:Int]()
    
    var selTitle:String = ""
    var url:String = ""
    var webViewUrl:String = ""
    var osWebUrl:String = ""
    var selUrl:String = ""
    
    var selMode:String = ""
    var myUrl:String = ""
    var alertController: UIAlertController!
    var webView: WKWebView!
    //var contentController = WKUserContentController()
    var createWebView: WKWebView!
    
    // 네이버 로그인
    var foundCharacters = "";
    var email = ""
    var id = ""
    var gender = ""
    var name = ""

    override func viewDidLoad() {
        
        super.viewDidLoad()
        //webView.uiDelegate = self // js alert 사용을 위해 필요
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
        myTitle.isUserInteractionEnabled = true
        myTitle.addGestureRecognizer(tap)
        
        //App Delegate 에서 DidBecomeActive감지
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadWebView(_:)), name: NSNotification.Name("ReloadWebView"), object: nil)
        
        // 슬라이딩 메뉴
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        self.dismiss(animated: true, completion: nil)
        
        myTitle.backgroundColor = UIColor.init(red: 81/255, green: 61/255, blue: 238/255, alpha: 1)
        
        
        let contentController = WKUserContentController()
        contentController.add(self, name: common.js_name)
        
        // wkwebview 설정
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = contentController
        
        let item = WKWebView()
        item.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height-60)
        
        webView = WKWebView(frame: item.frame, configuration: configuration)
        
        webViewUrl = selUrl
        
        if(webViewUrl.isEmpty)
        {
            webViewUrl = common.default_url
        }
        

        /*

         */
            
        if let theWebView = webView{
            loadPage(url:webViewUrl)
            theWebView.uiDelegate = self
            theWebView.navigationDelegate = self
            
            refreshControl = UIRefreshControl.init()
            refreshControl!.addTarget(self, action:#selector(pullToRefresh), for: UIControl.Event.valueChanged)
            theWebView.scrollView.addSubview(self.refreshControl!)
            //theWebView.UIDelegate = self
            myViewForWeb.addSubview(theWebView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setNavController()
        checkNetwork()
        
        let login_info = common.getUD("login_info") ?? ""
        
        if(login_info.isEmpty){
            self.moveToLoginView()
        }else if(webViewUrl.range(of: "login/login.php") != nil) {
            self.moveToLoginView()
        }else{
            if(selUrl.range(of: "login/logout.php") != nil)
            {
                selUrl = "/";
            }
            let login_url = common.api_url+"?action=autoLogin&s_url="+selUrl+"&login_info="+login_info
            let url = URL(string: login_url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            let request = URLRequest(url: url!)
            webView.load(request)
        }
        
    }
    
    // 웹뷰 팝업처리
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        //뷰를 생성하는 경우
        let frame = UIScreen.main.bounds
        
        //파라미터로 받은 configuration
        createWebView = WKWebView(frame: frame, configuration: configuration)
        
        //오토레이아웃 처리
        createWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        createWebView.navigationDelegate = self
        createWebView.uiDelegate = self
        
        
        view.addSubview(createWebView!)
        
        return createWebView!
        
        /* 현재 창에서 열고 싶은 경우
         self.webView.load(navigationAction.request)
         return nil
         */
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if webView == createWebView {
            createWebView?.removeFromSuperview()
            createWebView = nil
        }
    }
    // 웹뷰 팝업처리 끝
    
    @objc func pullToRefresh(refresh:UIRefreshControl){
        webView.reload()
    }
    
    @objc func tapFunction(){
        loadPage(url: common.default_url)
    }
    
    func setNavController(){
        //상단바 숨기기
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        /*
        //페이지변환시 fade효과
        let transition: CATransition = CATransition()
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade
        self.navigationController!.view.layer.add(transition, forKey: nil)
        */
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func loadView() {
        super.loadView()
        
        UserDefaults.standard.register(defaults: ["UserAgent": UIWebView().stringByEvaluatingJavaScript(from: "navigator.userAgent")! + common.user_agent])
    }
    
    func checkNetwork(){
        if(CheckNetwork.isConnected()==false)
        {
            self.moveToErrorView()
        }
    }
    
    func moveToErrorView(){
        let next = storyboard?.instantiateViewController(withIdentifier: "ErrorVC")as! ErrorVC
        self.navigationController?.pushViewController(next, animated: false)
        self.dismiss(animated: false, completion: nil)
    }
    
    func moveToLoginView(){
        let next = storyboard?.instantiateViewController(withIdentifier: "LoginNav")as! UINavigationController
        self.present(next, animated:true, completion:nil)
    }
    
    func webView(_ webView: WKWebView,
                 didStartProvisionalNavigation navigation: WKNavigation){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation){
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        refreshControl?.endRefreshing()
        
        if (webView.url?.absoluteString==common.default_url)
        {
            sendDeviceInfo()
        }
        
        if ((webView.url?.absoluteString.range(of: "step.php")) != nil)
        {
            sendStepInfo()
        }
        
    }
    
    // 웹뷰 결제처리
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        if url.absoluteString.range(of: "//itunes.apple.com/") != nil {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
            
        }else if !url.absoluteString.hasPrefix("http://") && !url.absoluteString.hasPrefix("https://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        
        switch navigationAction.navigationType {
        case .linkActivated:
            if navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
                UIApplication.shared.open(navigationAction.request.url!, options: [:]) // target='_blank' 처리
                //webView.load(URLRequest(url: url))
                decisionHandler(.cancel)
                return
            }
        case .backForward:
            break
        case .formResubmitted:
            break
        case .formSubmitted:
            break
        case .other:
            break
        case .reload:
            break
        }
        
        decisionHandler(.allow)
    }
    
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else {
            return nil
        }
        guard let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame else {
            webView.load(URLRequest(url: url))
            return nil
        }
        return nil
    }
    // 웹뷰 결제처리 끝
    
    // MARK: WKUIDelegate methods
    


    
    @objc func reloadWebView(_ notification: Notification?) {
        refreshControl?.beginRefreshing()
        webView.reload()
    }

    

    
    
    // 로그인전
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
                        self.loadPage(url: url)
                        
                        // Naver Sign Out
                        //loginConn?.resetToken()
                    }
                }
                dataTask.resume()
            }
        }
        
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
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if(message.name==common.js_name){
            if let message = message.body as? String {
                
                print(message)
                
                let data = Data(message.utf8)
                let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                
                let exec = json["exec"] as? String
                let value = json["value"] as? String
                
                if(exec=="login_info")
                {
                    common.setUD("login_info",value ?? "")
                }
                
            }
        }
    }
    
    func alert(title : String?, msg : String,
               style: UIAlertController.Style = .alert,
               dontRemindKey : String? = nil) {
        if dontRemindKey != nil,
            UserDefaults.standard.bool(forKey: dontRemindKey!) == true {
            return
        }
        
        let ac = UIAlertController.init(title: title,
                                        message: msg, preferredStyle: style)
        ac.addAction(UIAlertAction.init(title: "OK",
                                        style: .default, handler: nil))
        
        if dontRemindKey != nil {
            ac.addAction(UIAlertAction.init(title: "Don't Remind",
                                            style: .default, handler: { (aa) in
                                                UserDefaults.standard.set(true, forKey: dontRemindKey!)
                                                UserDefaults.standard.synchronize()
            }))
        }
        DispatchQueue.main.async {
            self.present(ac, animated: true, completion: nil)
        }
    }
    
    func sendDeviceInfo(){
        
        var device_id = common.getUD("device_id")
        var device_token = common.getUD("device_token")
        var device_model = common.getUD("device_model")
        var app_version = common.getUD("app_version")
        
        if(device_id == nil){
            device_id = UIDevice.current.identifierForVendor!.uuidString
            device_model = UIDevice.current.modelName
            app_version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
                as? String
        }
        
        if (device_id == nil) {device_id=""}
        if (device_token == nil) {device_token=""}
        if (device_model == nil) {device_model=""}
        if (app_version == nil) {app_version=""}
        
        common.setUD("device_id", device_id!)
        common.setUD("device_token", device_token!)
        common.setUD("device_model", device_model!)
        common.setUD("app_version", app_version!)
        common.setUD("app_start_yn", "N")
        
        let data = "act=setAppDeviceInfo&device_type=iOS" +
            "&device_id="+device_id!+"&device_token="+device_token!+"&device_model="+device_model!+"&app_version="+app_version!
        let enc_data = Data(data.utf8).base64EncodedString()
        print("jsNativeToServer(enc_data)")
        webView.evaluateJavaScript("jsNativeToServer('" + enc_data + "')", completionHandler:nil)
        
    }
    
    func loadPage(url:String) {
        let url = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        let request = URLRequest(url: url!)
        webView.load(request)
    }
    
    func sendStepInfo(){
        
        if HKHealthStore.isHealthDataAvailable(){
            //let writeDataTypes = dataTypesToWrite()
            let readDataTypes = dataTypesToRead()
            
            //healthStore.requestAuthorization(toShare: writeDataTypes as? Set<HKSampleType>, read: readDataTypes as?
            healthStore.requestAuthorization(toShare: nil, read: readDataTypes as?
                Set<HKObjectType>, completion: { (success, error) in
                    if(!success){
                        print("error")
                        
                        return
                    }
            })
        }
        
        self.getSteps()
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self.stepData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            let data = "act=setStepInfo&step_data=" + jsonString!
            let enc_data = Data(data.utf8).base64EncodedString()
            print("step_data : jsNativeToServer(enc_data)")
            webView.evaluateJavaScript("jsNativeToServer('" + enc_data + "')", completionHandler:nil)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func dataTypesToRead() -> NSSet{
        let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let returnSet = NSSet(objects: stepsCount!)
        
        return returnSet
    }
    
    func getSteps() {
        
        let stepsCount = HKQuantityType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount)
        
        let sort = [
            NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        ]
        
        
        let stepsSampleQuery = HKSampleQuery(sampleType: stepsCount!,
                                             predicate: nil,
                                             limit: 1000,
                                             sortDescriptors: sort)
        {   query, results, error in
            if let results = results as? [HKQuantitySample] {
                
                var myString: String = ""
                self.stepData = [:]
                for steps in results as [HKQuantitySample]
                {
                    let step_date = steps.startDate
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: step_date)
                    
                    let step_count = steps.quantity.doubleValue(for: HKUnit.count())
                    
                    if (self.stepData[dateString]==nil){
                        self.stepData.updateValue(Int(step_count), forKey: dateString)
                    }else{
                        let new_count = Int(step_count) + self.stepData[dateString]!
                        self.stepData.updateValue(new_count, forKey: dateString)
                    }
                    
                    myString = dateString
                    print(step_date)
                    print(dateString)
                    print(Int(step_count))
                    //print(steps)
                }
                
                if !myString.isEmpty {
                    self.stepData.removeValue(forKey: myString)
                }
                
                print(self.stepData)
                
                
                
            }
        }
        
        // Don't forget to execute the Query!
        healthStore.execute(stepsSampleQuery)
        
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: common.app_name, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "확인", style: .cancel) { _ in
            completionHandler()
        }
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: common.app_name, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        }
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
