import ArgumentParser
import SystemPackage
import libark

struct LSCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "ls",
        abstract: "List directory contents"
    )
    
    @OptionGroup var options: LSOptions
    
    mutating func run() throws {
        let parser = LSParser(options: options)
        try parser.parse()
    }
}

LSCommand.main()
