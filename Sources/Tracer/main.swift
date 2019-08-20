import Commander
import Foundation



//let path = "/Users/felix/Documents/GitLab/TDFMallShop/TDFMallShop"
//let path = "/Users/felix/Documents/GitLab/TDFHomeModule/TDFHomeModule"
//let path = "/Users/felix/Documents/GitLab/TDFGroupSettingModule/TDFGroupSettingModule"

let _ = command(
    
    Option("path", default: "./"),
    Option("type", default: "unused", description: "Find Unused Classes"),
    Option("ignore-prefix", default: ""),
    Option("ignore-suffix", default: "")
    
) { path, type, ignorePrefix, ignoreSuffix in
    
    let t = Tracer(path)
    
    if let tracerType = TracerTypeOption(rawValue: type) {
        
        t.resultType = tracerType
    }
    
    t.ignorePrefix = ignorePrefix
    t.ignoreSuffix = ignoreSuffix
    
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .full
    dateFormatter.timeStyle = .full
    
    let begin = Date()
    print("Start Tracer :: \(dateFormatter.string(from: begin))")
    t.run()
    let end = Date()
    print("Stop Tracer :: \(dateFormatter.string(from: end))")
    let cost = end.timeIntervalSince(begin)
    print("TotalCost :: \(String(describing: cost)) second")
    
}.run()
