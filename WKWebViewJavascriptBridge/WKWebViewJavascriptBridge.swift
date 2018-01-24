//
//  WKWebViewJavascriptBridge.swift
//  WKWebViewJavascriptBridge
//
//  Created by Lision on 2018/1/21.
//  Copyright © 2018年 Lision. All rights reserved.
//

import Foundation
import WebKit

@available(iOS 9.0, *)
public class WKWebViewJavascriptBridge: NSObject {
    private let iOS_Native_InjectJavascript = "iOS_Native_InjectJavascript"
    private let iOS_Native_FlushMessageQueue = "iOS_Native_FlushMessageQueue"
    
    private weak var webView: WKWebView!
    private var base: WKWebViewJavascriptBridgeBase!
    
    public init(webView: WKWebView) {
        super.init()
        self.webView = webView
        self.webView.configuration.userContentController.add(self, name: iOS_Native_InjectJavascript)
        self.webView.configuration.userContentController.add(self, name: iOS_Native_FlushMessageQueue)
        base = WKWebViewJavascriptBridgeBase()
        base.delegate = self
    }
    
    public func reset() {
        base.reset()
    }
    
    public func register(handlerName: String, handler: @escaping WKWebViewJavascriptBridgeBase.Handler) {
        base.messageHandlers[handlerName] = handler
    }
    
    public func remove(handlerName: String) -> WKWebViewJavascriptBridgeBase.Handler? {
        return base.messageHandlers.removeValue(forKey: handlerName)
    }
    
    public func call(handlerName: String, data: Any? = nil, callback: WKWebViewJavascriptBridgeBase.Callback? = nil) {
        base.send(handlerName: handlerName, data: data, callback: callback)
    }
    
    func flushMessageQueue() {
        webView.evaluateJavaScript("WKWebViewJavascriptBridge._fetchQueue();") { (result, error) in
            if error != nil {
                print("WKWebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: \(String(describing: error))")
            }
            
            guard let resultStr = result as? String else { return }
            self.base.flush(messageQueueString: resultStr)
        }
    }
}

extension WKWebViewJavascriptBridge: WKWebViewJavascriptBridgeBaseDelegate {
    func evaluateJavascript(javascript: String) {
        self.webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
}

extension WKWebViewJavascriptBridge: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == iOS_Native_InjectJavascript {
//            self.base.injectJavascriptFile()
            print("self.base.injectJavascriptFile()")
        }
        
        if message.name == iOS_Native_FlushMessageQueue {
            self.flushMessageQueue()
        }
    }
}
