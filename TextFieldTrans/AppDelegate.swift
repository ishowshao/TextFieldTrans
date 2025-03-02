import Cocoa
import ApplicationServices

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    @IBOutlet weak var apiURL: NSTextField!
    
    var globalMonitor: Any?
    
    // The path to the log file
    // Use the Documents directory in the app sandbox for logging.
    let logFilePath: String = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentDirectory = urls.first {
            return documentDirectory.appendingPathComponent("TextFieldTrans.log").path
        }
        // Fallback to temporary directory if for some reason the documents directory isn't available.
        return NSTemporaryDirectory() + "TextFieldTrans.log"
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Log that the app has started
        logToFile("Application did finish launching")
        
        // 从 UserDefaults 加载保存的 API URL
        if let savedURL = UserDefaults.standard.string(forKey: "APIURL"), !savedURL.isEmpty {
            apiURL.stringValue = savedURL
            logToFile("加载保存的 API URL: \(savedURL)")
        }
        
        // Register a global hotkey: Command+Shift+E (key code 14 corresponds to "E")
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 14 {
                self.logToFile("Hotkey pressed")
                self.replaceFocusedInputText()
            }
        })
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 14 {
                self.logToFile("Local hotkey pressed")
                self.replaceFocusedInputText()
                // Returning nil prevents the event from being propagated further.
                return nil
            }
            return event
        }
    }
    
    func replaceFocusedInputText() {
        // 获取系统中当前焦点的元素
        let systemElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(systemElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard result == .success, let element = focusedElement as! AXUIElement? else {
            logToFile("无法获取焦点元素: \(result.rawValue)")
            return
        }
        
        // 先获取当前文本
        var value: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        guard textResult == .success, let currentText = value as? String, !currentText.isEmpty else {
            logToFile("未能获取输入框中的文本")
            return
        }
        
        // 调用翻译接口
        translateText(currentText) { translatedText in
            // 如果翻译返回nil或空字符串，则不替换
            guard let newText = translatedText, !newText.isEmpty else {
                self.logToFile("翻译失败或返回为空，保留原文本")
                return
            }
            
            // 替换文本（需要在主线程上更新UI）
            DispatchQueue.main.async {
                let error = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newText as CFTypeRef)
                if error == .success {
                    self.logToFile("成功替换文本")
                } else {
                    self.logToFile("替换文本失败: \(error.rawValue)")
                }
            }
        }
    }
    
    @IBAction func apiURLDidChange(_ sender: NSTextField) {
        let newURL = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(newURL, forKey: "APIURL")
        logToFile("API URL 已保存: \(newURL)")
    }

    /// 使用指定的翻译服务将文本翻译成英文
    func translateText(_ text: String, completion: @escaping (String?) -> Void) {
        // 从输入框中获取用户配置的 API URL，如果为空则记录日志并返回
        let urlString = apiURL.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else {
            logToFile("API URL 为空，请在界面中输入有效的 URL")
            completion(nil)
            return
        }
        
        guard let url = URL(string: urlString) else {
            logToFile("无效的 API URL: \(urlString)")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // 对文本进行 URL 编码，并构造 POST 字符串
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let postString = "text=\(encodedText)"
        request.httpBody = postString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 发起网络请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logToFile("翻译请求错误: \(error.localizedDescription)")
                completion(nil)
                return
            }
            // 检查是否有数据返回，并尝试转为字符串
            guard let data = data,
                  let translatedString = String(data: data, encoding: .utf8),
                  !translatedString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self.logToFile("翻译接口返回数据为空")
                completion(nil)
                return
            }
            completion(translatedString)
        }
        task.resume()
    }
    
    /// Writes a log message to a file with a timestamp.
    func logToFile(_ message: String) {
        print(message)
        let timestamp = Date()
        let logMessage = "[\(timestamp)] \(message)\n"
        
        // Check if file exists; if so, append. Otherwise, create it.
        if FileManager.default.fileExists(atPath: logFilePath) {
            if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
                fileHandle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                print("Could not open file handle for logging.")
            }
        } else {
            do {
                try logMessage.write(toFile: logFilePath, atomically: true, encoding: .utf8)
            } catch {
                print("Error creating log file: \(error)")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        logToFile("Application will terminate")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
