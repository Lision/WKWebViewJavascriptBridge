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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = view.bounds
        webView.navigationDelegate = self
        bridge = WKWebViewJavascriptBridge(webView: webView)
        view.addSubview(webView)
    }
    
    func loadDemoPage() {
        let pagePath = Bundle.main.path(forResource: "Demo", ofType: "html")
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
