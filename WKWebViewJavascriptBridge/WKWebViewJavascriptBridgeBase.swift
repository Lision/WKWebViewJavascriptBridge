//
//  WKWebViewJavascriptBridgeBase.swift
//  WKWebViewJavascriptBridge
//
//  Created by Lision on 2018/1/21.
//  Copyright © 2018年 Lision. All rights reserved.
//

import Foundation

protocol WKWebViewJavascriptBridgeBaseDelegate: AnyObject {
    typealias CompletionHandler = ((Any?, Error?) -> Void)?
    
    func evaluateJavascript(javascript: String, completion: CompletionHandler)
}

extension WKWebViewJavascriptBridgeBaseDelegate {
    func evaluateJavascript(javascript: String) {
        evaluateJavascript(javascript: javascript, completion: nil)
    }
}

@available(iOS 9.0, *)
public class WKWebViewJavascriptBridgeBase: NSObject {
    var isLogEnable = false
    
    public typealias Callback = (_ responseData: Any?) -> Void
    public typealias Handler = (_ parameters: [String: Any]?, _ callback: Callback?) -> Void
    public typealias Message = [String: Any]
    
    weak var delegate: WKWebViewJavascriptBridgeBaseDelegate?
    var startupMessageQueue: [Message]? = []
    var responseCallbacks = [String: Callback]()
    var messageHandlers = [String: Handler]()
    var uniqueId = 0
    let bridgeContainerName: String
    
    init(_ bridgeName: String?) {
        bridgeContainerName = bridgeName ?? "WKWebViewJavascriptBridge"
        super.init()
    }
    
    func reset() {
        startupMessageQueue = nil
        responseCallbacks = [String: Callback]()
        uniqueId = 0
    }
    
    func send(handlerName: String, data: Any?, callback: Callback?) {
        var message = [String: Any]()
        message["handlerName"] = handlerName
        
        if data != nil {
            message["data"] = data
        }
        
        if callback != nil {
            uniqueId += 1
            let callbackID = "native_iOS_cb_\(uniqueId)"
            responseCallbacks[callbackID] = callback
            message["callbackID"] = callbackID
        }
        
        queue(message: message)
    }
    
    func flush(messageQueueString: String) {
        guard let messages = deserialize(messageJSON: messageQueueString) else {
            log(messageQueueString)
            return
        }
        
        for message in messages {
            log(message)
            
            if let responseID = message["responseID"] as? String {
                guard let callback = responseCallbacks[responseID] else { continue }
                callback(message["responseData"])
                responseCallbacks.removeValue(forKey: responseID)
            } else {
                var callback: Callback?
                if let callbackID = message["callbackID"] {
                    callback = { (_ responseData: Any?) -> Void in
                        let msg = ["responseID": callbackID, "responseData": responseData ?? NSNull()] as Message
                        self.queue(message: msg)
                    }
                } else {
                    callback = { (_ responseData: Any?) -> Void in
                        // no logic
                    }
                }
                
                guard let handlerName = message["handlerName"] as? String else { continue }
                guard let handler = messageHandlers[handlerName] else {
                    log("NoHandlerException, No handler for message from JS: \(message)")
                    continue
                }
                handler(message["data"] as? [String : Any], callback)
            }
        }
    }
    
    func injectJavascriptFile() {
        let js = WKWebViewJavascriptBridgeJS
        delegate?.evaluateJavascript(javascript: js, completion: { [weak self] (_, error) in
            guard let self = self else { return }
            if let error = error {
                self.log(error)
                return
            }
            self.startupMessageQueue?.forEach({ (message) in
                self.dispatch(message: message)
            })
            self.startupMessageQueue = nil
        })
    }
    
    // MARK: - Private
    private func queue(message: Message) {
        if startupMessageQueue == nil {
            dispatch(message: message)
        } else {
            startupMessageQueue?.append(message)
        }
    }
    
    private func dispatch(message: Message) {
        guard var messageJSON = serialize(message: message, pretty: false) else { return }
        
        messageJSON = messageJSON.replacingOccurrences(of: "\\", with: "\\\\")
        messageJSON = messageJSON.replacingOccurrences(of: "\"", with: "\\\"")
        messageJSON = messageJSON.replacingOccurrences(of: "\'", with: "\\\'")
        messageJSON = messageJSON.replacingOccurrences(of: "\n", with: "\\n")
        messageJSON = messageJSON.replacingOccurrences(of: "\r", with: "\\r")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{000C}", with: "\\f")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{2028}", with: "\\u2028")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        
        let javascriptCommand = "\(bridgeContainerName)._handleMessageFromiOS('\(messageJSON)');"
        if Thread.current.isMainThread {
            delegate?.evaluateJavascript(javascript: javascriptCommand)
        } else {
            DispatchQueue.main.async {
                self.delegate?.evaluateJavascript(javascript: javascriptCommand)
            }
        }
    }
    
    // MARK: - JSON
    private func serialize(message: Message, pretty: Bool) -> String? {
        var result: String?
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: pretty ? .prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0))
            result = String(data: data, encoding: .utf8)
        } catch let error {
            log(error)
        }
        return result
    }
    
    private func deserialize(messageJSON: String) -> [Message]? {
        var result = [Message]()
        guard let data = messageJSON.data(using: .utf8) else { return nil }
        do {
            result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [WKWebViewJavascriptBridgeBase.Message]
        } catch let error {
            log(error)
        }
        return result
    }
    
    // MARK: - Log
    private func log<T>(_ message: T, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        guard isLogEnable else {
            return
        }
        
        let fileName = (file as NSString).lastPathComponent
        print("\(fileName):\(line) \(function) | \(message)")
        #endif
    }
    
    lazy var WKWebViewJavascriptBridgeJS = """
    ;(function() {
        if (window.\(bridgeContainerName)) {
            return;
        }

        if (!window.onerror) {
            window.onerror = function(msg, url, line) {
                console.log("WKWebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
            }
        }
        window.\(bridgeContainerName) = {
            registerHandler: registerHandler,
            callHandler: callHandler,
            _fetchQueue: _fetchQueue,
            _handleMessageFromiOS: _handleMessageFromiOS
        };

        var sendMessageQueue = [];
        var messageHandlers = {};

        var responseCallbacks = {};
        var uniqueId = 1;

        function registerHandler(handlerName, handler) {
            messageHandlers[handlerName] = handler;
        }

        function callHandler(handlerName, data, responseCallback) {
            if (arguments.length == 2 && typeof data == 'function') {
                responseCallback = data;
                data = null;
            }
            _doSend({ handlerName:handlerName, data:data }, responseCallback);
        }

        function _doSend(message, responseCallback) {
            if (responseCallback) {
                var callbackID = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
                responseCallbacks[callbackID] = responseCallback;
                message['callbackID'] = callbackID;
            }
            sendMessageQueue.push(message);
            window.webkit.messageHandlers.iOS_Native_FlushMessageQueue.postMessage(null)
        }

        function _fetchQueue() {
            var messageQueueString = JSON.stringify(sendMessageQueue);
            sendMessageQueue = [];
            return messageQueueString;
        }

        function _dispatchMessageFromiOS(messageJSON) {
            var message = JSON.parse(messageJSON);
            var messageHandler;
            var responseCallback;

            if (message.responseID) {
                responseCallback = responseCallbacks[message.responseID];
                if (!responseCallback) {
                    return;
                }
                responseCallback(message.responseData);
                delete responseCallbacks[message.responseID];
            } else {
                if (message.callbackID) {
                    var callbackResponseId = message.callbackID;
                    responseCallback = function(responseData) {
                        _doSend({ handlerName:message.handlerName, responseID:callbackResponseId, responseData:responseData });
                    };
                }

                var handler = messageHandlers[message.handlerName];
                if (!handler) {
                    console.log("WKWebViewJavascriptBridge: WARNING: no handler for message from iOS:", message);
                } else {
                    handler(message.data, responseCallback);
                }
            }
        }

        function _handleMessageFromiOS(messageJSON) {
            _dispatchMessageFromiOS(messageJSON);
        }

        setTimeout(_callWVJBCallbacks, 0);
        function _callWVJBCallbacks() {
            var callbacks = window.WKWVJBCallbacks;
            delete window.WKWVJBCallbacks;
            for (var i = 0; i < callbacks.length; i++) {
                callbacks[i](\(bridgeContainerName));
            }
        }
    })();
    """
}
