import ArgumentParser

struct LSOptions: ParsableArguments {
    @Argument(help: "Paths to list")
    var paths: [String] = []

    @Flag(name: [.short, .long], help: "do not ignore entries starting with .")
    var all: Bool = false

    @Flag(name: [.customShort("A"), .customLong("almost-all")], help: "do not list implied . and ..")
    var almostAll: Bool = false

    @Flag(name: [.short, .long], help: "use a long listing format")
    var longFormat: Bool = false

    @Flag(name: [.customShort("h"), .customLong("human-readable")], help: "with -l and -s, print sizes like 1K 234M 2G etc.")
    var humanReadable: Bool = false

    @Flag(name: [.short, .long], help: "list directories themselves, not their contents")
    var directory: Bool = false

    @Flag(name: [.customShort("R"), .customLong("recursive")], help: "list subdirectories recursively")
    var recursive: Bool = false
    
    @Flag(name: .customShort("1"), help: "list one file per line")
    var onePerLine: Bool = false

    @Flag(name: .customShort("C"), help: "list entries by columns")
    var columns: Bool = false

    @Flag(name: .customShort("x"), help: "list entries by lines instead of by columns")
    var across: Bool = false

    @Flag(name: [.customShort("m")], help: "fill width with a comma separated list of entries")
    var commas: Bool = false

    @Flag(name: .customShort("Q"), help: "enclose entry names in double quotes")
    var quoteName: Bool = false

    @Flag(name: [.customShort("q"), .customLong("hide-control-chars")], help: "print ? instead of nongraphic characters")
    var hideControlChars: Bool = false
    
    @Flag(name: [.customShort("b"), .customLong("escape")], help: "print C-style escapes for nongraphic characters")
    var escape: Bool = false

    @Flag(name: [.customShort("N"), .customLong("literal")], help: "print entry names without quoting")
    var literal: Bool = false

    @Flag(name: [.customShort("r"), .customLong("reverse")], help: "reverse order while sorting")
    var reverse: Bool = false

    @Flag(name: .customShort("t"), help: "sort by modification time, newest first")
    var sortByTime: Bool = false

    @Flag(name: .customShort("S"), help: "sort by file size, largest first")
    var sortBySize: Bool = false

    @Flag(name: .customShort("X"), help: "sort alphabetically by entry extension")
    var sortByExtension: Bool = false

    @Flag(name: .customShort("U"), help: "do not sort; list entries in directory order")
    var unsorted: Bool = false
    
    @Flag(name: .customShort("v"), help: "natural sort of (version) numbers within text")
    var sortByVersion: Bool = false

    @Flag(name: .customShort("c"), help: "with -lt: sort by, and show, ctime")
    var useCTime: Bool = false

    @Flag(name: .customShort("u"), help: "with -lt: sort by, and show, access time")
    var useATime: Bool = false
    
    @Flag(name: .customShort("T"), help: "print complete time information for the file")
    var fullTime: Bool = false
    
    @Option(name: .customLong("time-style"), help: "time/date format with -l")
    var timeStyle: String?

    @Option(name: .customLong("time"), help: "change the default of using modification times")
    var timeOption: String?
    
    @Flag(name: .customShort("i"), help: "print the index number of each file")
    var inode: Bool = false
    
    @Flag(name: [.customShort("s"), .customLong("size")], help: "print the allocated size of each file, in blocks")
    var showBlocks: Bool = false

    @Flag(name: .customShort("n"), help: "like -l, but list numeric user and group IDs")
    var numericUidGid: Bool = false

    @Flag(name: .customShort("o"), help: "like -l, but do not list group information")
    var noGroup: Bool = false

    @Flag(name: .customShort("g"), help: "like -l, but do not list owner")
    var noOwner: Bool = false

    @Flag(name: .customShort("G"), help: "in a long listing, don't print group names")
    var noGroupNames: Bool = false

    @Flag(name: [.customShort("F"), .customLong("classify")], help: "append indicator (one of */=>@|) to entries")
    var classify: Bool = false

    @Flag(name: .customLong("file-type"), help: "likewise, except do not append '*'")
    var fileType: Bool = false

    @Flag(name: .customShort("p"), help: "append / indicator to directories")
    var indicatorSlash: Bool = false

    @Flag(name: .customShort("L"), help: "when showing file information for a symbolic link, show information for the file the link references")
    var dereference: Bool = false

    @Flag(name: .customShort("H"), help: "follow symbolic links listed on the command line")
    var dereferenceCommandLine: Bool = false

    @Flag(name: .customShort("Z"), help: "print any security context of each file")
    var securityContext: Bool = false

    @Option(name: .customLong("color"), help: "colorize the output")
    var color: String?

    @Option(name: .customLong("sort"), help: "sort by WORD instead of name")
    var sortOpt: String?

    @Option(name: .customLong("format"), help: "across -x, commas -m, horizontal -x, long -l, single-column -1, verbose -l, vertical -C")
    var formatOpt: String?
    
    @Flag(name: .customLong("group-directories-first"), help: "group directories before files")
    var groupDirectoriesFirst: Bool = false

    @Option(name: .customLong("quoting-style"), help: "use quoting style WORD for entry names")
    var quotingStyle: String?

    @Flag(name: .customLong("zero"), help: "end each output line with NUL, not newline")
    var zero: Bool = false
    
    @Flag(name: .customLong("author"), help: "with -l, print the author of each file")
    var author: Bool = false
    
    @Option(name: .customLong("block-size"), help: "scale sizes by SIZE before printing them")
    var blockSize: String?
    
    @Option(name: .customLong("hide"), help: "do not list implied entries matching shell PATTERN (overridden by -a or -A)")
    var hide: String?
    
    @Option(name: .customLong("ignore"), help: "do not list implied entries matching shell PATTERN")
    var ignore: String?
}
