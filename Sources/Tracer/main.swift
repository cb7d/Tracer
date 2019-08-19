import Commander



//let path = "/Users/felix/Documents/GitLab/TDFMallShop/TDFMallShop"
let path = "/Users/felix/Documents/GitLab/TDFHomeModule/TDFHomeModule"

//let path = "/Users/felix/Documents/GitLab/TDFGroupSettingModule/TDFGroupSettingModule"

let _ = command(
    
    Option("path", default: "./"),
    Option("type", default: "unused", description: "Find Unused Classes")
    
) { path, type in
    
    let type = TracerTypeOption(rawValue: type)
    
    let t = Tracer(path, type: type ?? TracerTypeOption.unused)
    
    t.run()
    
}.run()
