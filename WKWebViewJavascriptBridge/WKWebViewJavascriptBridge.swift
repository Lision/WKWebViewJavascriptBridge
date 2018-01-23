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
    private weak var webView: WKWebView!
    private var base: WKWebViewJavascriptBridgeBase!
    
    public init(webView: WKWebView) {
        self.webView = webView
        super.init()
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
        webView.evaluateJavaScript("WebViewJavascriptBridge._fetchQueue();") { (result, error) in
            if error != nil {
                print("WKWebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: \(String(describing: error))")
            }
            
            guard let resultStr = result as? String else { return }
            self.base.flush(messageQueueString: resultStr)
        }
    }
}

extension WKWebViewJavascriptBridge: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.flushMessageQueue()
    }
}
