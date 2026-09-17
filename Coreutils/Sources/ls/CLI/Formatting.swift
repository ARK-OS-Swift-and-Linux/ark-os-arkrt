import Foundation
import libark

struct Formatting {
    static func format(_ files: [FileMetadata], options: LSOptions) -> [String] {
        var output: [String] = []
        
        let colorize = options.color == "always" || (options.color == "auto" && Terminal.stdout.isTTY) || (options.color == nil && Terminal.stdout.isTTY)
        let lsColors = colorize ? LSColors.defaultColors() : nil
        
        if options.longFormat {
            // Compute formatted sizes
            let sizes: [String] = files.map { file in
                if options.si {
                    return file.size.bytes.humanReadableShort(format: .si)
                } else if options.humanReadable {
                    return file.size.bytes.humanReadableShort(format: .iec)
                } else {
                    return String(file.size)
                }
            }
            
            // Need to compute max widths for alignment
            let links = files.map { String($0.linkCount) }
            let maxSizeLen = sizes.map { $0.count }.max() ?? 0
            let maxLinksLen = links.map { $0.count }.max() ?? 0
            
            for (index, file) in files.enumerated() {
                let perms = PermissionFormatter.format(metadata: file)
                let linkStr = String(file.linkCount).padding(toLength: maxLinksLen, withPad: " ", startingAt: 0)
                
                let uidStr = OwnerFormatter.format(uid: file.uid)
                let gidStr = OwnerFormatter.format(gid: file.gid)
                let sizeStr = sizes[index].padding(toLength: maxSizeLen, withPad: " ", startingAt: 0)
                
                // Formatted time
                let ts: timespec
                if options.useCTime {
                    ts = file.changeTime
                } else if options.useATime {
                    ts = file.accessTime
                } else if options.timeOption == "ctime" || options.timeOption == "status" {
                    ts = file.changeTime
                } else if options.timeOption == "atime" || options.timeOption == "access" || options.timeOption == "use" {
                    ts = file.accessTime
                } else {
                    ts = file.modificationTime
                }
                
                let timeStyle: TimeStyle
                if options.fullTime {
                    timeStyle = .fullIso
                } else if let style = options.timeStyle {
                    switch style {
                    case "full-iso": timeStyle = .fullIso
                    case "long-iso": timeStyle = .longIso
                    case "iso": timeStyle = .iso
                    case "locale": timeStyle = .locale
                    default:
                        if style.hasPrefix("+") {
                            let customFmt = String(style.dropFirst())
                            timeStyle = .custom(customFmt)
                        } else {
                            timeStyle = .locale
                        }
                    }
                } else {
                    timeStyle = .locale
                }
                
                let timeStr = Timestamp(ts).humanReadable(format: timeStyle)
                
                let nameFormatter = NameFormatter(classify: options.classify)
                let rawName = nameFormatter.format(metadata: file)
                let name = lsColors?.format(name: rawName, for: file) ?? rawName
                
                var line = "\(perms) \(linkStr) \(uidStr) \(gidStr) \(sizeStr) \(timeStr) \(name)"
                if let target = file.symlinkTarget {
                    let targetColor = lsColors != nil ? "\u{001B}[01;36m\(target)\u{001B}[0m" : target
                    line += " -> \(targetColor)"
                }
                output.append(line)
            }
        } else {
            // Simple single column, columns, or comma separated
            let nameFormatter = NameFormatter(classify: options.classify)
            let names = files.map { file -> String in
                let rawName = nameFormatter.format(metadata: file)
                return lsColors?.format(name: rawName, for: file) ?? rawName
            }
            if options.commas {
                output = [names.joined(separator: ", ")]
            } else if options.columns {
                output = formatColumns(names: names, width: Terminal.stdout.width)
            } else {
                output = names
            }
        }
        
        return output
    }
    
    static func formatColumns(names: [String], width: Int) -> [String] {
        if names.isEmpty { return [] }
        let maxNameLen = names.map { $0.count }.max() ?? 0
        let colWidth = maxNameLen + 2 // 2 spaces between columns
        var numCols = width / colWidth
        if numCols < 1 { numCols = 1 }
        
        let numRows = Int(ceil(Double(names.count) / Double(numCols)))
        var output: [String] = []
        
        for row in 0..<numRows {
            var line = ""
            for col in 0..<numCols {
                let index = col * numRows + row
                if index < names.count {
                    let name = names[index]
                    line += name.padding(toLength: colWidth, withPad: " ", startingAt: 0)
                }
            }
            output.append(line.trimmingCharacters(in: .whitespaces))
        }
        return output
    }

}
