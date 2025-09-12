import WatchConnectivity

class PhoneConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // Recebe dados do Watch
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let samples = userInfo["heartRates"] as? [[String: Any]] {
            var formatted: [(Date, Double)] = []
            
            for sample in samples {
                if let ts = sample["date"] as? TimeInterval,
                   let bpm = sample["bpm"] as? Double {
                    let date = Date(timeIntervalSince1970: ts)
                    formatted.append((date, bpm))
                    print("📲 Recebido do Watch: \(bpm) BPM em \(date)")
                }
            }
            
            // Envia para o servidor
            if !formatted.isEmpty {
                NetworkManager.shared.sendHeartRateData(formatted)
            }
        }
    }
}
