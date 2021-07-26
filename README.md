![](Rources/WKWebViewJavascriptBridge.jpg)

[![language](https://img.shields.io/badge/Language-Swift-FFA08F.svg)](https://github.com/apple/swift)&nbsp;
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-FE95AE.svg?style=flat)](https://github.com/Carthage/Carthage)&nbsp;
[![License MIT](https://img.shields.io/badge/license-MIT-FC89CD.svg?style=flat)](https://raw.githubusercontent.com/Lision/WKWebViewJavascriptBridge/master/LICENSE)&nbsp;
[![Support](https://img.shields.io/badge/support-iOS%209%2B%20-FB7DEC.svg?style=flat)](https://www.apple.com/nl/ios/)&nbsp;
[![CocoaPods](https://img.shields.io/cocoapods/p/WKWebViewJavascriptBridge.svg?style=flat)](http://cocoadocs.org/docsets/WKWebViewJavascriptBridge)&nbsp;
[![Build Status](https://api.travis-ci.org/Lision/WKWebViewJavascriptBridge.svg?branch=master)](https://travis-ci.org/Lision/WKWebViewJavascriptBridge)&nbsp;
[![CocoaPods](https://img.shields.io/cocoapods/v/WKWebViewJavascriptBridge.svg?style=flat)](http://cocoapods.org/pods/WKWebViewJavascriptBridge)

> [中文介绍](https://github.com/Lision/WKWebViewJavascriptBridge/blob/master/README_ZH-CN.md)

> This project is inspired by [WebViewJavascriptBridge](https://github.com/marcuswestin/WebViewJavascriptBridge)!

# What Can WKWebViewJavascriptBridge Do?

You can write hybrid modules in just a few lines of code by using WKWebViewJavascriptBridge without the need to be concerned with the underlying messaging implementation.

![](Rources/WKWebViewJavascriptBridgeDemo.gif)

# Why Only Support WKWebView?

### Advantages of WKWebView

It is well known that **WKWebView loads web pages faster and more efficiently than UIWebView**, and also **doesn't have as much memory overhead** for you.

Under the current timeline, most iOS apps only support iOS 9.0+.

### UIWebView Cross-Domain Access Vulnerability

The reason for the iOS platform cross-domain access vulnerability is due to UIWebView turning on the WebKitAllowUniversalAccessFromFileURLs and WebKitAllowFileAccessFromFileURLs options.

**WKWebView default allowFileAccessFromFileURLs and allowUniversalAccessFromFileURLs option is false.**

# Features

- **Swift Support:** Swift 3.2 ~ 5 Support.
- **High Performance:** The messaging performance is higher than intercept requests.
- **High Speed:** No need to consider alert box safety timeout.
- **Lightweight:** This framework contains only 3 files.
- **Non-intrusive:** There is no need to make the webview class inherit from other base class.

# Usage

### 1. Instantiate WKWebViewJavascriptBridge with a WKWebView: 

``` swift
bridge = WKWebViewJavascriptBridge(webView: webView)
```

### 2. Register a Handler in Native, and Call a JS Handler: 

``` swift
bridge.register(handlerName: "testiOSCallback") { (parameters, callback) in
    print("testiOSCallback called: \(String(describing: parameters))")
    callback?("Response from testiOSCallback")
}

bridge.call(handlerName: "testJavascriptHandler", data: ["foo": "before ready"], callback: nil)
```

### 3. Copy and Paste setupWKWebViewJavascriptBridge into Your JS: 

``` js
function setupWKWebViewJavascriptBridge(callback) {
    if (window.WKWebViewJavascriptBridge) { return callback(WKWebViewJavascriptBridge); }
    if (window.WKWVJBCallbacks) { return window.WKWVJBCallbacks.push(callback); }
    window.WKWVJBCallbacks = [callback];
    window.webkit.messageHandlers.iOS_Native_InjectJavascript.postMessage(null)
}
```

### 4. Finally, Call setupWKWebViewJavascriptBridge and then Use The Bridge to Register Handlers and Call Native Handlers:

``` js
setupWKWebViewJavascriptBridge(function(bridge) {

	/* Initialize your app here */

	bridge.registerHandler('testJavascriptHandler', function(data, responseCallback) {
		console.log('iOS called testJavascriptHandler with', data)
		responseCallback({ 'Javascript Says':'Right back atcha!' })
	})

	bridge.callHandler('testiOSCallback', {'foo': 'bar'}, function(response) {
		console.log('JS got response', response)
	})
})
```

# Installation

### Cocoapods

1. Add `pod 'WKWebViewJavascriptBridge', '~> 1.2.0'` to your Podfile.
2. Run `pod install` or `pod update`.
3. Add `import WKWebViewJavascriptBridge`.

### Carthage

1. Add `github "Lision/WKWebViewJavascriptBridge" ~> 1.2.0` to your Cartfile.
2. Run `carthage update --platform ios`.
3. Add the `WKWebViewJavascriptBridge` framework to your project.

### Manually

Either clone the repo and manually add the Files in [WKWebViewJavascriptBridge](https://github.com/Lision/WKWebViewJavascriptBridge/tree/master/WKWebViewJavascriptBridge).

# Requirements

This framework requires `iOS 9.0+` and `Xcode 9.0+`.

# Contact

- Email: lisionmail@gmail.com
- Sina: [@Lision](https://weibo.com/5071795354/profile)
- Twitter: [@Lision](https://twitter.com/LisionChat)

# License

[![](https://camo.githubusercontent.com/5e085da09b057cc65da38f334ab63f0c2705f46a/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f7468756d622f662f66382f4c6963656e73655f69636f6e2d6d69742d38387833312d322e7376672f31323870782d4c6963656e73655f69636f6e2d6d69742d38387833312d322e7376672e706e67)](https://raw.githubusercontent.com/Lision/WKWebViewJavascriptBridge/master/LICENSE)

WKWebViewJavascriptBridge is provided under the MIT license. See LICENSE file for details.
