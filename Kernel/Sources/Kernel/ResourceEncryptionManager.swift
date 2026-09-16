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

public enum ResourceType: UInt8 {
    case ram = 0x01
    case gpu = 0x02
}

public struct ResourceEncryptionManager {
    private var _e_ptr: UnsafeMutableRawPointer
    
    public init(masterSeed: UInt64) {
        _e_ptr = UnsafeMutableRawPointer.allocate(byteCount: 4096, alignment: 64)
        _e_ptr.storeBytes(of: masterSeed, as: UInt64.self)
        for i in 1..<512 {
            let pVal = _e_ptr.load(fromByteOffset: (i-1)*8, as: UInt64.self)
            _e_ptr.storeBytes(of: pVal &* 0x9e3779b185ebca87 &+ 0x1, toByteOffset: i*8, as: UInt64.self)
        }
    }
    
    public func requestResourceAccess(appPID: Int32, resource: ResourceType, isVialSecure: Bool) -> Bool {
        let p1 = _e_ptr.load(fromByteOffset: 128, as: UInt64.self)
        let p2 = _e_ptr.load(fromByteOffset: 256, as: UInt64.self)
        let c = UInt64(appPID) ^ p1 ^ (p2 &<< 3)
        let res = c & 0x0F
        
        let target = _e_ptr.advanced(by: Int(res) * 8)
        let chk = target.load(as: UInt64.self)
        
        if isVialSecure {
            let m = chk ^ UInt64(resource.rawValue)
            target.storeBytes(of: m, as: UInt64.self)
            return true
        }
        
        return false
    }
}
