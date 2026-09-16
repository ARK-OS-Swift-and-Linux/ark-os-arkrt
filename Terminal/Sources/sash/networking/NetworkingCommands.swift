import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct NetworkingCommands {
    
    public static func runCURL(args: [String], currentDirectory: String) {
        guard let urlString = args.first else {
            print("curl: missing URL argument")
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("curl: invalid URL '\(urlString)'")
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("curl: error - \(error.localizedDescription)")
            } else if let data = data {
                if let str = String(data: data, encoding: .utf8) {
                    print(str)
                } else {
                    print("curl: (binary data)")
                }
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
    
    public static func runWGET(args: [String], currentDirectory: String) {
        guard let urlString = args.first else {
            print("wget: missing URL argument")
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("wget: invalid URL '\(urlString)'")
            return
        }
        
        let filename = url.lastPathComponent.isEmpty ? "index.html" : url.lastPathComponent
        let destPath = currentDirectory + "/" + filename
        let destURL = URL(fileURLWithPath: destPath)
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.downloadTask(with: url) { tempLocalUrl, response, error in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    if FileManager.default.fileExists(atPath: destPath) {
                        try FileManager.default.removeItem(at: destURL)
                    }
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destURL)
                    print("wget: saved to '\(filename)'")
                } catch {
                    print("wget: file error - \(error.localizedDescription)")
                }
            } else if let error = error {
                print("wget: error - \(error.localizedDescription)")
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
}
