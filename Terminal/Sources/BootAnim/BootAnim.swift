// Copyright 2026 Aarav Ravindra Kharade
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import SwiftCrossUI
import DefaultBackend
import SwiftTerm

@main
struct BootAnimApp: App {
    typealias Backend = DefaultBackend
    let identifier = "com.arkos.bootanim"

    var body: some Scene {
        WindowGroup("ArkOS Boot", id: "main") {
            BootAnimView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .defaultSize(width: 800, height: 600)
    }
}

class TerminalManager: TerminalDelegate, LocalProcessDelegate, ObservableObject {
    var terminal: Terminal!
    var process: LocalProcess!
    
    @Published var screenText: String = ""
    
    init() {
        terminal = Terminal(delegate: self)
        process = LocalProcess(delegate: self, dispatchQueue: .main)
    }
    
    func startShell() {
        process.startProcess(executable: "/bin/sh", args: ["-i"], environment: nil, execName: nil)
    }
    
    func send(source: Terminal, data: ArraySlice<UInt8>) {
        process.send(data: data)
    }
    
    func dataReceived(slice: ArraySlice<UInt8>) {
        terminal.feed(byteArray: Array(slice))
        updateScreenText()
    }
    
    func processTerminated(_ source: LocalProcess, exitCode: Int32?) {
    }
    
    func getWindowSize() -> winsize {
        return winsize(ws_row: 24, ws_col: 80, ws_xpixel: 0, ws_ypixel: 0)
    }
    
    func updateScreenText() {
        let start = Position(col: 0, row: 0)
        let end = Position(col: terminal.cols - 1, row: terminal.rows - 1)
        screenText = terminal.getText(start: start, end: end)
    }
}

struct BootAnimView: View {
    @State var phase: Int = 0 // 0: Expanding dot, 1: Revolving, 2: Shockwave, 3: Terminal
    @State var angle: Double = 0.0
    @State var showCursor: Bool = true
    @State var terminalOutput: String = "arkos@localhost:~$ "
    
    // We create a mock terminal just in case
    var terminalManager = TerminalManager()
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)
            
            if phase < 3 {
                if phase == 2 {
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: 200, height: 200)
                }
                
                Circle()
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                
                if phase == 1 {
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Circle()
                                .foregroundColor(.white)
                                .frame(width: 10, height: 10)
                                .padding(.leading, Int(cos(angle) * 50))
                                .padding(.top, Int(sin(angle) * 50))
                            Spacer()
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Circle()
                                .foregroundColor(.white)
                                .frame(width: 10, height: 10)
                                .padding(.leading, Int(cos(angle + (2 * .pi / 3)) * 50))
                                .padding(.top, Int(sin(angle + (2 * .pi / 3)) * 50))
                            Spacer()
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Circle()
                                .foregroundColor(.white)
                                .frame(width: 10, height: 10)
                                .padding(.leading, Int(cos(angle + (4 * .pi / 3)) * 50))
                                .padding(.top, Int(sin(angle + (4 * .pi / 3)) * 50))
                            Spacer()
                        }
                        Spacer()
                    }
                }
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text(terminalOutput)
                            .foregroundColor(.green)
                            // Ideally use a monospace font here, SwiftCrossUI text font modifiers if available
                        
                        if showCursor {
                            Rectangle()
                                .foregroundColor(.white)
                                .frame(width: 10, height: 20)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(10)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    func startAnimation() {
        Task {
            phase = 0
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            phase = 1
            for _ in 0..<60 {
                angle += 0.2
                try? await Task.sleep(nanoseconds: 33_000_000)
            }
            
            phase = 2
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            phase = 3
            
            terminalManager.startShell()
            
            while true {
                // Manually pull from TerminalManager to keep the view updated since @ObservedObject 
                // in SwiftCrossUI behaves via State bindings when manual trigger is needed.
                let newOutput = terminalManager.screenText
                if newOutput != "" && newOutput != terminalOutput {
                    terminalOutput = newOutput
                }
                
                showCursor.toggle()
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
}
