//
//  ViewController.swift
//  WKWebViewJavascriptBridgeDemo
//
//  Created by Lision on 2018/1/23.
//  Copyright © 2018年 Lision. All rights reserved.
//

import UIKit
import WebKit
import WKWebViewJavascriptBridge

class ViewController: UIViewController {
    let webView = WKWebView(frame: CGRect(), configuration: WKWebViewConfiguration())
    var bridge: WKWebViewJavascriptBridge!
    let callbackBtn = UIButton(type: .custom)
    let reloadBtn = UIButton(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup webView
        webView.frame = view.bounds
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        // setup btns
        callbackBtn.backgroundColor = UIColor(red: 255.0/255, green: 166.0/255, blue: 124.0/255, alpha: 1.0)
        callbackBtn.setTitle("Call Handler", for: .normal)
        callbackBtn.addTarget(self, action: #selector(callHandler), for: .touchUpInside)
        view.insertSubview(callbackBtn, aboveSubview: webView)
        callbackBtn.frame = CGRect(x: 10, y: UIScreen.main.bounds.size.height - 80, width: UIScreen.main.bounds.size.width * 0.4, height: 35)
        reloadBtn.backgroundColor = UIColor(red: 216.0/255, green: 103.0/255, blue: 216.0/255, alpha: 1.0)
        reloadBtn.setTitle("Reload Webview", for: .normal)
        reloadBtn.addTarget(self, action: #selector(reloadWebView), for: .touchUpInside)
        view.insertSubview(reloadBtn, aboveSubview: webView)
        reloadBtn.frame = CGRect(x: UIScreen.main.bounds.size.width * 0.6 - 10, y: UIScreen.main.bounds.size.height - 80, width: UIScreen.main.bounds.size.width * 0.4, height: 35)
        
        // setup bridge
        bridge = WKWebViewJavascriptBridge(webView: webView)
        bridge.isLogEnable = true
        bridge.register(handlerName: "testiOSCallback") { (paramters, callback) in
            print("testiOSCallback called: \(String(describing: paramters))")
            callback?("Response from testiOSCallback")
        }
        bridge.call(handlerName: "testJavascriptHandler", data: ["foo": "before ready"], callback: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDemoPage()
    }
    
    func loadDemoPage() {
        enum LoadDemoPageError: Error {
            case nilPath
        }
        
        do {
            guard let pagePath = Bundle.main.path(forResource: "Demo", ofType: "html") else {
                throw LoadDemoPageError.nilPath
            }
            let pageHtml = try String(contentsOfFile: pagePath, encoding: .utf8)
            let baseURL = URL(fileURLWithPath: pagePath)
            webView.loadHTMLString(pageHtml, baseURL: baseURL)
        } catch LoadDemoPageError.nilPath {
            print(print("webView loadDemoPage error: pagePath is nil"))
        } catch let error {
            print("webView loadDemoPage error: \(error)")
        }
    }
    
    @objc func callHandler() {
        let data = ["greetingFromiOS": "Hi there, JS!"]
        bridge.call(handlerName: "testJavascriptHandler", data: data) { (response) in
            print("testJavascriptHandler responded: \(String(describing: response))")
        }
    }
    
    @objc func reloadWebView() {
        webView.reload()
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("webViewDidStartLoad")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webViewDidFinishLoad")
    }
}
