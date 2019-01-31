import UIKit
import WebKit
import JavaScriptCore
import MessageUI
import Social
import FBSDKShareKit
import HealthKit
import GoogleMobileAds
import CoreLocation

class MainWebVC: UIViewController, NaverThirdPartyLoginConnectionDelegate, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, XMLParserDelegate, MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate, GADInterstitialDelegate, CLLocationManagerDelegate {

    // 기본
    var sUrl:String = ""
    let common = Common()
    let apiHelper = APIHelper()
    
    // ios 11이하 버젼에서는 스토리보드를 이용한 WKWebView를 사용할수 없으므로 아래와 같이 수동처리
    //@IBOutlet weak var webView: WKWebView!
    var webView: WKWebView!
    var createWebView: WKWebView!
    
    //GPS
    var locationManager:CLLocationManager!
    
    // 전면광고
    var frontAd: GADInterstitial!
    
    // 이미지 업로드
    var picker = UIImagePickerController()
    
    // 리프레시
    var refreshControl = UIRefreshControl()
    
    // 만보기
    var healthStore = HKHealthStore()
    var stepData =  [String:Int]()
    
    // 네이버 로그인
    var foundCharacters = "";
    var email = ""
    var id = ""
    var gender = ""
    var name = ""
    
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        setGPS()
        setWebView()
    }
    
    // 앱이 꺼지지 않은 상태에서 다시 뷰가 보일때 viewWillAppear부터 시작됨
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        setNavController()
        checkNetwork()
        
        let urlFromPush = common.getUD("urlFromPush") ?? ""
        
        if(!urlFromPush.isEmpty)
        {
            common.setUD("urlFromPush","")
            loadPage(url: urlFromPush)
        }
    }
    
    func setGPS() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() //권한 요청
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //위치가 업데이트될때마다
        if let coor = manager.location?.coordinate{
            if(!String(coor.latitude).isEmpty && !String(coor.longitude).isEmpty)
            {
                common.setUD("latitude", String(coor.latitude))
                common.setUD("longtitude", String(coor.longitude))
                locationManager.stopUpdatingLocation()
                //print("latitude" + String(coor.latitude) + "/ longitude" + String(coor.longitude))
            }
        }
    }
    
    func setWebView() {
        print("setWebView")
        
        //App Delegate 에서 DidBecomeActive감지
        //NotificationCenter.default.addObserver(self, selector: #selector(self.reloadWebView(_:)), name: NSNotification.Name("ReloadView"), object: nil)
        
        UserDefaults.standard.register(defaults: ["UserAgent": UIWebView().stringByEvaluatingJavaScript(from: "navigator.userAgent")! + common.user_agent])
        
        // ios 11이하 버젼에서는 스토리보드를 이용한 WKWebView를 사용할수 없으므로 아래와 같이 수동처리
        let contentController = WKUserContentController()
        contentController.add(self, name: common.js_name)
        contentController.add(self, name: common.bootpay_js_name)
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self as WKUIDelegate
        webView.navigationDelegate = self as WKNavigationDelegate
        
        
        var url = URL(string: common.default_url)
        if(!sUrl.isEmpty){
            url = URL(string: sUrl)
        }
        
        let request = URLRequest(url: url!)
        
        webView.load(request)
        
        view = webView
        
        setupRefreshControl()
        
        // 카메라 촬영
        picker.delegate = view as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
    }
    
    @objc func reloadWebView(_ notification: Notification?) {
        print("reloadWebView")
        
        refreshControl.beginRefreshing()
        webView.reload()

    }
    
    @objc
    private func refreshWebView(sender: UIRefreshControl) {
        print("refreshWebView")
        webView.reload()
        sender.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setNavController(){
        //상단바 숨기기
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        //페이지변환시 fade효과
        let transition: CATransition = CATransition()
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade
        //self.navigationController!.view.layer.add(transition, forKey: nil)
    }
    
    func sendDeviceInfo(){
        
        
        var device_id = common.getUD("device_id")
        var device_token = common.getUD("device_token")
        var device_model = common.getUD("device_model")
        var app_version = common.getUD("app_version")
        var latitude = common.getUD("latitude")
        var longtitude = common.getUD("longtitude")
        
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
        if (latitude == nil) {latitude=""}
        if (longtitude == nil) {longtitude=""}
        
        let new_app_version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as! String
        let old_app_version = app_version ?? ""
        
        if(new_app_version != old_app_version)
        {
            app_version=new_app_version
        }
        
        common.setUD("device_id", device_id!)
        common.setUD("device_token", device_token!)
        common.setUD("device_model", device_model!)
        common.setUD("app_version", app_version!)
        
        let data = "act=setAppDeviceInfo&device_type=iOS" +
            "&device_id="+device_id!+"&device_token="+device_token!+"&device_model="+device_model!+"&app_version="+app_version!+"&latitude="+latitude!+"&longtitude="+longtitude!
        let enc_data = Data(data.utf8).base64EncodedString()
        print("jsNativeToServer(enc_data)")
        webView.evaluateJavaScript("jsNativeToServer('" + enc_data + "')", completionHandler:nil)
        
    }
    
    private func setupRefreshControl() {
        //let refreshControl = UIRefreshControl()
        //refreshControl.backgroundColor = common.uicolorFromHex(0x8912f6)
        //refreshControl.tintColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(refreshWebView(sender:)), for: UIControl.Event.valueChanged)
        webView.scrollView.addSubview(refreshControl)
    }
    
    func loadPage(url:String) {
        print("loadPage")
        let url = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        let request = URLRequest(url: url!)
        webView.load(request)
    }
    
    func checkNetwork(){
        if(CheckNetwork.isConnected()==false)
        {
            self.moveToErrorView()
        }
    }
    
    func moveToErrorView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let next = storyboard.instantiateViewController(withIdentifier: "ErrorVC")as! ErrorVC
        self.navigationController?.pushViewController(next, animated: false)
        self.dismiss(animated: false, completion: nil)
    }
    
    // 만보기 시작
    func dataTypesToRead() -> NSSet{
        let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let returnSet = NSSet(objects: stepsCount!)
        
        return returnSet
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
        
        self.stepData = [:]
        for days in 0...14
        {
            self.getSteps(days:days)
        }
        self.dateDiffSteps()
        
        //구글에서 데이터를 받아오는 시간을 기다린다
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            do {
                print(self.stepData)
                let jsonData = try JSONSerialization.data(withJSONObject: self.stepData, options: .prettyPrinted)
                let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
                let data = "act=setStepInfo&step_data=" + jsonString!
                let enc_data = Data(data.utf8).base64EncodedString()
                print("step_data : jsNativeToServer(enc_data)")
                self.webView.evaluateJavaScript("jsNativeToServer('" + enc_data + "')", completionHandler:nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func getSteps(days:Int) {
        
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let today = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let endDate = today.addingTimeInterval(TimeInterval(-days*24*60*60))
        let startDate = Calendar.current.startOfDay(for: endDate)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        //총합을 구하는 쿼리
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
   
            var resultCount = 0.0
            
            guard let result = result else {
                print("Failed to fetch steps rate")
                return
            }
 
            if let sum = result.sumQuantity() {
                
                resultCount = sum.doubleValue(for: HKUnit.count())
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: endDate)
                
                if (self.stepData[dateString]==nil){
                    self.stepData.updateValue(Int(resultCount), forKey: dateString)
                }else{
                    let new_count = self.stepData[dateString]! + Int(resultCount)
                    self.stepData.updateValue(new_count, forKey: dateString)
                }
                
                print(dateString)
                print(resultCount)
            }
            
        }
        
        //건강앱에서 강제로 넣은값은 가져오는 쿼리
        let minus_query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .separateBySource) { (_, result, error) in
            
            var resultCount = 0.0
            
            guard let result = result else {
                print("Failed to fetch steps rate")
                return
            }
            
            
            for source in result.sources!
            {
                if(source.name=="건강" || source.name=="Health")
                {
                    if let sum = result.sumQuantity(for: source) {
 
                        resultCount = sum.doubleValue(for: HKUnit.count())
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let dateString = dateFormatter.string(from: endDate)
                        
                        if (self.stepData[dateString]==nil){
                            self.stepData.updateValue(-Int(resultCount), forKey: dateString)
                        }else{
                            let new_count = self.stepData[dateString]! - Int(resultCount)
                            self.stepData.updateValue(new_count, forKey: dateString)
                        }
                        
                        print(dateString)
                        print("-\(resultCount)")
                    }
                    
                    return
                }
            }
        }
        
        //총합을 구한다
        healthStore.execute(query)
        //건강앱에서 강제로 넣은값은 뺀다
        healthStore.execute(minus_query)
    }
    
    func dateDiffSteps() {
            
        //시작일과 종료일이 다른데이터의 경우 종료일의 걸음수에 더해준다
        let stepsCount = HKQuantityType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount)
        
        let sort = [
            NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        ]

        let diffDateQuery = HKSampleQuery(sampleType: stepsCount!,
                                             predicate: nil,
                                             limit: 500,
                                             sortDescriptors: sort)
        {   query, results, error in
            if let results = results as? [HKQuantitySample] {
                
                for steps in results as [HKQuantitySample]
                {
                    //아이폰 기기의 데이터만 가져오기
                    if(steps.device?.model=="iPhone")
                    {
                        let start_date = steps.startDate
                        let end_date = steps.endDate
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let startDate = dateFormatter.string(from: start_date)
                        let endDate = dateFormatter.string(from: end_date)
                        
                        if(!(startDate==endDate))
                        {
                            let step_count = steps.quantity.doubleValue(for: HKUnit.count())
                            
                            print(startDate)
                            print(endDate)
                            print(Int(step_count))
                            
                            if (self.stepData[endDate]==nil){
                                self.stepData.updateValue(Int(step_count), forKey: endDate)
                            }else{
                                let new_count = Int(step_count) + self.stepData[endDate]!
                                self.stepData.updateValue(new_count, forKey: endDate)
                            }
                        }
                    }
                }
                //print(self.stepData)
            }
        }

        //시작일과 종료일이 다른데이터의 경우 종료일의 걸음수에 더해준다
        healthStore.execute(diffDateQuery)
        
    }
    // 만보기 끝
    
    // 네이버 로그인 시작
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
    
    // 문자발송
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

//BOOTPAY 시작
extension MainWebVC  {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        refreshControl.endRefreshing()
        
        if let cur_url = webView.url?.absoluteString{
            /*
            if(cur_url.hasSuffix("step.php"))
            {
                sendStepInfo()
            }
            else if(cur_url.hasSuffix("challenge.php"))
            {
                frontAd = GADInterstitial(adUnitID: common.admob_front_ad)
                frontAd.delegate = self
                let request = GADRequest()
                request.testDevices = [kGADSimulatorID, "f4debf541bf25e9a44ac6794249bde14" ]
                frontAd.load(request)
            }
            else if(cur_url.hasSuffix("index2.php"))
            {   
                frontAd = GADInterstitial(adUnitID: common.admob_front_ad)
                frontAd.delegate = self
                let request = GADRequest()
                request.testDevices = [kGADSimulatorID, "f4debf541bf25e9a44ac6794249bde14" ]
                frontAd.load(request)
            }
            */
        }
        
        
        sendDeviceInfo()
        
        registerAppId()
        setDevice()
        startTrace()
        registerAppIdDemo()
    }
    
    func registerAppId() {
        doJavascript("BootPay.setApplicationId('\(common.bootpay_id)');")
    }
    
    func registerAppIdDemo() {
        doJavascript("window.setApplicationId('\(common.bootpay_id)');")
    }
    
    internal func setDevice() {
        doJavascript("window.BootPay.setDevice('IOS');")
    }
    
    internal func startTrace() {
        doJavascript("BootPay.startTrace();")
    }
    
    func isMatch(_ urlString: String, _ pattern: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let result = regex.matches(in: urlString, options: [], range: NSRange(location: 0, length: urlString.characters.count))
        return result.count > 0
    }
    
    func isItunesURL(_ urlString: String) -> Bool {
        return isMatch(urlString, "\\/\\/itunes\\.apple\\.com\\/")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            print(url)
            if(isItunesURL(url.absoluteString)) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
                decisionHandler(.cancel)
            } else if url.scheme != "http" && url.scheme != "https" {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
        
        /*
         //KCP
         guard let url = navigationAction.request.url else {
         decisionHandler(.cancel)
         return
         }
         
         print(url)
         
         if url.absoluteString.range(of: "//itunes.apple.com/") != nil {
         UIApplication.shared.open(url)
         decisionHandler(.cancel)
         return
         
         } else if !url.absoluteString.hasPrefix("http://") && !url.absoluteString.hasPrefix("https://") {
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
         */
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name==common.js_name){
            if let message = message.body as? String {
                
                print(message)
                
                if message == "STEP_DATA" {
                    sendStepInfo()
                }
                else if message == "LOAD_FRONT_AD" {
                    frontAd = GADInterstitial(adUnitID: common.admob_front_ad)
                    frontAd.delegate = self
                    let request = GADRequest()
                    request.testDevices = [kGADSimulatorID, "f4debf541bf25e9a44ac6794249bde14" ]
                    frontAd.load(request)
                }
                else if message == "SHOW_FRONT_AD" {
                    if frontAd.isReady {
                        frontAd.present(fromRootViewController: self)
                    }
                }
                else if message == "NAVER" {
                    print("NAVERLOGIN")
                    let naverConnection = NaverThirdPartyLoginConnection.getSharedInstance()
                    naverConnection?.delegate = self
                    naverConnection?.requestThirdPartyLogin()
                }
                else if message == "KAKAO" {
                    print("KAKAOLOGIN")
                    let session: KOSession = KOSession.shared();
                    if session.isOpen() {
                        session.close()
                    }
                    session.presentingViewController = self
                    session.open(completionHandler: { (error) -> Void in
                        if error != nil{
                            print(error?.localizedDescription as Any)
                        }else if session.isOpen() == true{
                            
                            KOSessionTask.userMeTask(completion: { (error, me) in
                                if let error = error as NSError? {
                                    self.alert(title: "kakaologin_error", msg: error.description)
                                } else if let me = me as KOUserMe? {
                                    print("id: \(String(describing: me.id))")
                                    
                                    self.name = (me.properties!["nickname"])!
                                    if(me.account?.email == nil)
                                    {
                                        self.email = "null"
                                    }else{
                                        self.email = (me.account?.email)!
                                        
                                    }
                                    self.id = me.id!
                                    
                                    let url = self.common.sns_callback_url +
                                        "?login_type=kakao" +
                                        "&success_yn=Y" +
                                        "&id=" + self.id +
                                        "&email=" + self.email +
                                        "&name=" + self.name
                                    
                                    print(url)
                                    
                                    self.loadPage(url: url)
                                    
                                } else {
                                    print("has no id")
                                }
                            })
                        }else{
                            print("isNotOpen")
                        }
                    })
                }else {
                    let data = Data(message.utf8)
                    let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                    
                    let share_type = json["share_type"] as? String
                    
                    let link_url = json["link_url"] as? String
                    let title = json["title"] as? String
                    let img_url = json["img_url"] as? String
                    let content = json["content"] as? String
                    
                    if(share_type == "MMS")
                    {
                        if (MFMessageComposeViewController.canSendText()) {
                            let controller = MFMessageComposeViewController()
                            controller.body = title! + "\n\n" + content! + "\n\n" +  link_url!
                            controller.recipients = [""]
                            controller.messageComposeDelegate = self
                            self.present(controller, animated: true, completion: nil)
                        }
                    }
                    else if(share_type == "KAKAO")
                    {
                        var stringDictionary: Dictionary = [String: String]()
                        stringDictionary["${title}"] = title
                        stringDictionary["${content}"] = content
                        
                        KLKTalkLinkCenter.shared().sendCustom(withTemplateId: common.kakao_template_id, templateArgs: stringDictionary as! [String : String], success: nil, failure: nil)
                    }
                    else if(share_type == "KAKAOSTORY")
                    {
                        if !SnsLinkHelper.canOpenStoryLink() {
                            SnsLinkHelper.openiTunes("itms://itunes.apple.com/app/id486244601")
                            return
                        }
                        let bundle = Bundle.main
                        var postMessage: String!
                        if let bundleId = bundle.bundleIdentifier, let appVersion: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                            let appName: String = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                            postMessage = SnsLinkHelper.makeStoryLink(title! + " " + link_url!, appBundleId: bundleId, appVersion: appVersion, appName: appName, scrapInfo: nil)
                        }
                        if let urlString = postMessage {
                            _ = SnsLinkHelper.openSNSLink(urlString)
                        }
                    }
                    else if share_type == "LINE" {
                        if !SnsLinkHelper.canOpenLINE() {
                            SnsLinkHelper.openiTunes("itms://itunes.apple.com/app/id443904275")
                            return
                        }
                        let postMessage = SnsLinkHelper.makeLINELink(title! + " " + link_url!)
                        if let urlString = postMessage {
                            _ = SnsLinkHelper.openSNSLink(urlString)
                        }
                        
                    }
                    else if share_type == "BAND" {
                        if !SnsLinkHelper.canOpenBAND() {
                            SnsLinkHelper.openiTunes("itms://itunes.apple.com/app/id542613198")
                            return
                        }
                        let postMessage = SnsLinkHelper.makeBANDLink(title! + " " + link_url!, link_url!)
                        if let urlString = postMessage {
                            _ = SnsLinkHelper.openSNSLink(urlString)
                        }
                    }
                    else if share_type == "FACEBOOK" {
                        
                        // import FBSDKShareKit 을 이용할경우
                        let cont = FBSDKShareLinkContent()
                        //cont.contentTitle = title!  // 작동안함
                        //cont.contentDescription = content! // 작동안함
                        cont.contentURL = URL(string: link_url!)
                        
                        let dialog = FBSDKShareDialog()
                        dialog.fromViewController = self
                        dialog.mode = FBSDKShareDialogMode.native
                        if !dialog.canShow() {
                            dialog.mode = FBSDKShareDialogMode.automatic
                        }
                        dialog.shareContent = cont
                        dialog.show()
                        
                        /*
                         // import Social 을 이용할경우
                         let facebookShare = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                         if let facebookShare = facebookShare{
                         facebookShare.setInitialText(title!) // 작동안함
                         //facebookShare.add(UIImage(named: "iOSDevCenters.jpg")!)
                         facebookShare.add(URL(string: link_url!))
                         self.present(facebookShare, animated: true, completion: nil)
                         }
                         */
                    }
                }
            }
        }else if(message.name==common.bootpay_js_name){
            if let message = message.body as? String {
                
                print(message)
            }
            
            guard let body = message.body as? [String: Any] else {
                
                if message.body as? String == "close" {
                    onClose()
                }
                return
            }
            guard let action = body["action"] as? String else {
                return
            }
            
            
            print(action)
            
            
            // 해당 함수 호출
            if action == "BootpayCancel" {
                onCancel(data: body)
            } else if action == "BootpayError" {
                onError(data: body)
            } else if action == "BootpayBankReady" {
                onReady(data: body)
            } else if action == "BootpayConfirm" {
                onConfirm(data: body)
            } else if action == "BootpayDone" {
                onDone(data: body)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, cred)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

}

// 웹뷰 alert 팝업처리
extension MainWebVC {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if navigationAction.targetFrame == nil {
            if let url = navigationAction.request.url {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            
            return nil
        }
        
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
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if webView == createWebView {
            createWebView?.removeFromSuperview()
            createWebView = nil
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
    
}
// 웹뷰 팝업처리 끝

//MARK: Bootpay Callback Protocol
extension MainWebVC {
    // 에러가 났을때 호출되는 부분
    func onError(data: [String: Any]) {
        print(data)
        
        let json = dicToJsonString(data)
        alert(title: "bootpay_error", msg: json)
    }
    
    // 가상계좌 입금 계좌번호가 발급되면 호출되는 함수입니다.
    func onReady(data: [String: Any]) {
        print("ready")
        print(data)
    }
    
    // 결제가 진행되기 바로 직전 호출되는 함수로, 주로 재고처리 등의 로직이 수행
    func onConfirm(data: [String: Any]) {
        print(data)

        let json = dicToJsonString(data).replacingOccurrences(of: "\"", with: "'")
        //print(json)
        doJavascript("BootPay.transactionConfirm( \(json) );"); // 결제 승인
        
        // 중간에 결제창을 닫고 싶을 경우
        // doJavascript("BootPay.removePaymentWindow();");
    }
    
    // 결제 취소시 호출
    func onCancel(data: [String: Any]) {
        print(data)
        webView.reload()
    }
    
    // 결제완료시 호출
    func onDone(data: [String: Any]) {
        print(data)
        let receipt_id = data["receipt_id"] as! String
        sUrl = common.default_url + "/pay/bootpay_check.php?receipt_id=" + receipt_id
        loadPage(url: sUrl)
    }
    
    //결제창이 닫힐때 실행되는 부분
    func onClose() {
        print("close")
    }
    
    internal func doJavascript(_ script: String) {
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    fileprivate func dicToJsonString(_ data: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            let jsonStr = String(data: jsonData, encoding: .utf8)
            if let jsonStr = jsonStr {
                return jsonStr
            }
            return ""
        } catch {
            print(error.localizedDescription)
            return ""
        }
    }
    
}
//BOOTPAY 끝
