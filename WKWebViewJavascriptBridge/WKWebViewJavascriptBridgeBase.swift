//
//  WKWebViewJavascriptBridgeBase.swift
//  WKWebViewJavascriptBridge
//
//  Created by Lision on 2018/1/21.
//  Copyright © 2018年 Lision. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
protocol WKWebViewJavascriptBridgeBaseDelegate: AnyObject {
    func evaluateJavascript(javascript: String)
}

@available(iOS 9.0, *)
class WKWebViewJavascriptBridgeBase: NSObject {
    typealias Callback = (_ responseData: Any?) -> Void
    typealias Handler = (_ parameters: [String: Any]?, _ callback: Callback?) -> Void
    typealias Message = [String: Any]
    
    weak var delegate: WKWebViewJavascriptBridgeBaseDelegate?
    var startupMessageQueue = [Message]()
    var responseCallbacks = [String: Callback]()
    var messageHandlers = [String: Handler]()
    var uniqueId = 0
    
    override init() {
        super.init()
    }
    
    func reset() {
        self.startupMessageQueue = [Message]()
        self.responseCallbacks = [String: Callback]()
        self.uniqueId = 0
    }
    
    func send(data: Any?, callback: Callback?, handlerName: String?) {
        var message = [String: Any]()
        
        if data != nil {
            message["data"] = data
        }
        
        if callback != nil {
            self.uniqueId += 1
            let callbackID = "native_iOS_cb_\(self.uniqueId)"
            self.responseCallbacks[callbackID] = callback
            message["callbackID"] = callbackID
        }
        
        if handlerName != nil {
            message["handlerName"] = handlerName
        }
        
        self.queue(message: message)
    }
    
    func flush(messageQueueString: String) {
        guard let messages = self.deserialize(messageJSON: messageQueueString) else {
            log(messageQueueString)
            return
        }
        
        for message in messages {
            log(message)
            
            if let responseID = message["responseID"] as? String {
                let callback = self.responseCallbacks[responseID]
                callback!(message["responseData"]!)
                self.responseCallbacks.removeValue(forKey: responseID)
            } else {
                var callback: Callback?
                if let callbackID = message["callbackID"] {
                    callback = { (_ responseData: Any?) -> Void in
                        guard responseData != nil else {
                            return
                        }
                        
                        let msg = ["responseID": callbackID, "responseData": responseData!] as Message
                        self.queue(message: msg)
                    }
                } else {
                    callback = { (_ responseData: Any?) -> Void in
                        // no logic
                    }
                }
                
                guard let handlerName = message["handlerName"] as? String else {
                    return
                }
                guard let handler = self.messageHandlers[handlerName] else {
                    log("NoHandlerException, No handler for message from JS: \(message)")
                    return
                }
                handler(message["data"] as? [String : Any], callback)
            }
        }
    }
    
    // MARK: - Private
    fileprivate func queue(message: Message) {
        if self.startupMessageQueue.isEmpty {
            self.dispatch(message: message)
        } else {
            self.startupMessageQueue.append(message)
        }
    }
    
    fileprivate func dispatch(message: Message) {
        guard var messageJSON = self.serialize(message: message, pretty: false) else {
            return
        }
        
        messageJSON = messageJSON.replacingOccurrences(of: "\\", with: "\\\\")
        messageJSON = messageJSON.replacingOccurrences(of: "\"", with: "\\\"")
        messageJSON = messageJSON.replacingOccurrences(of: "\'", with: "\\\'")
        messageJSON = messageJSON.replacingOccurrences(of: "\n", with: "\\n")
        messageJSON = messageJSON.replacingOccurrences(of: "\r", with: "\\r")
//        messageJSON = messageJSON.replacingOccurrences(of: "\f", with: "\\f")
//        messageJSON = messageJSON.replacingOccurrences(of: "\u2028", with: "\\u2028")
//        messageJSON = messageJSON.replacingOccurrences(of: "\u2029", with: "\\u2029")
        
        let javascriptCommand = "WebViewJavascriptBridge._handleMessageFromObjC('\(messageJSON)');"
        if Thread.current.isMainThread {
            self.delegate?.evaluateJavascript(javascript: javascriptCommand)
        } else {
            DispatchQueue.main.async {
                self.delegate?.evaluateJavascript(javascript: javascriptCommand)
            }
        }
    }
    
    // MARK: - JSON
    fileprivate func serialize(message: Message, pretty: Bool) -> String? {
        var result: String?
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: pretty ? .prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0))
            result = String(data: data, encoding: .utf8)!
        } catch let error {
            log(error)
        }
        return result
    }
    
    fileprivate func deserialize(messageJSON: String) -> [Message]? {
        var result = [Message]()
        guard let data = messageJSON.data(using: .utf8) else {
            return nil
        }
        do {
            result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [WKWebViewJavascriptBridgeBase.Message]
        } catch let error {
            log(error)
        }
        return result
    }
    
    // MARK: - Log
    fileprivate func log<T>(_ message: T, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
            let fileName = (file as NSString).lastPathComponent
            print("\(fileName):\(line) \(function) | \(message)")
        #endif
    }
}
