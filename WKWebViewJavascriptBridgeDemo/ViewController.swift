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
        loadDemoPage()
    }
    
    func loadDemoPage() {
        enum LoadDemoPageError: Error {
            case nilPath
        }
        
        do {
            let pagePath = Bundle.main.path(forResource: "Demo", ofType: "html")
            guard pagePath != nil else {
                throw LoadDemoPageError.nilPath
            }
            let pageHtml = try String(contentsOfFile: pagePath!, encoding: .utf8)
            let baseURL = URL(fileURLWithPath: pagePath!)
            webView.loadHTMLString(pageHtml, baseURL: baseURL)
        } catch LoadDemoPageError.nilPath {
            print(print("webView loadDemoPage error: pagePath is nil"))
        } catch let error {
            print("webView loadDemoPage error: \(error)")
        }
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
