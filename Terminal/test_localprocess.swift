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
import SwiftTerm

class TermDelegate: TerminalDelegate, LocalProcessDelegate {
    func processTerminated(_ source: LocalProcess, exitCode: Int32?) {}
    func dataReceived(slice: ArraySlice<UInt8>) {}
    func getWindowSize() -> winsize { return winsize(ws_row: 24, ws_col: 80, ws_xpixel: 0, ws_ypixel: 0) }
    func send(source: Terminal, data: ArraySlice<UInt8>) {}
}
