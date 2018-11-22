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
    public var isLogEnable: Bool {
        get {
            return self.base!.isLogEnable
        }
        set(newValue) {
            self.base!.isLogEnable = newValue
        }
    }

    private let iOS_Native_InjectJavascript = "iOS_Native_InjectJavascript"
    private let iOS_Native_FlushMessageQueue = "iOS_Native_FlushMessageQueue"
    
    private weak var webView: WKWebView?
    private var base: WKWebViewJavascriptBridgeBase!
    
    public init(webView: WKWebView) {
        super.init()
        self.webView = webView
        base = WKWebViewJavascriptBridgeBase()
        base.delegate = self
        addScriptMessageHandlers()
    }
    
    deinit {
        removeScriptMessageHandlers()
    }
    
    // MARK: - Public Funcs
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
    
    // MARK: - Private Funcs
    private func flushMessageQueue() {
        webView?.evaluateJavaScript("WKWebViewJavascriptBridge._fetchQueue();") { (result, error) in
            if error != nil {
                print("WKWebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: \(String(describing: error))")
            }
            
            guard let resultStr = result as? String else { return }
            self.base.flush(messageQueueString: resultStr)
        }
    }
    
    private func addScriptMessageHandlers() {
        webView?.configuration.userContentController.add(LeakAvoider(delegate: self), name: iOS_Native_InjectJavascript)
        webView?.configuration.userContentController.add(LeakAvoider(delegate: self), name: iOS_Native_FlushMessageQueue)
    }
    
    private func removeScriptMessageHandlers() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: iOS_Native_InjectJavascript)
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: iOS_Native_FlushMessageQueue)
    }
}

extension WKWebViewJavascriptBridge: WKWebViewJavascriptBridgeBaseDelegate {
    func evaluateJavascript(javascript: String) {
        webView?.evaluateJavaScript(javascript, completionHandler: nil)
    }
}

extension WKWebViewJavascriptBridge: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == iOS_Native_InjectJavascript {
            base.injectJavascriptFile()
        }
        
        if message.name == iOS_Native_FlushMessageQueue {
            flushMessageQueue()
        }
    }
}

class LeakAvoider: NSObject {
    weak var delegate: WKScriptMessageHandler?
    
    init(delegate: WKScriptMessageHandler) {
        super.init()
        self.delegate = delegate
    }
}

extension LeakAvoider: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
