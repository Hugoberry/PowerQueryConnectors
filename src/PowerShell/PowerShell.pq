// This file contains your Data Connector logic
section PowerShell;

[DataSource.Kind="PowerShell", Publish="PowerShell.Publish"]
shared PowerShell.Execute = (optional filePath as text) =>
    let
        folder = filePath,
        file = filePath,
        out = AdoDotNet.Query("System.Data.CData.PowerShell","ScriptLocation='"&folder&"';ExecuteQuery=True","select * from "&file)
    in
        out;

// Data Source Kind description
PowerShell = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
PowerShell.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = PowerShell.Icons,
    SourceTypeImage = PowerShell.Icons
];

PowerShell.Icons = [
    Icon16 = { Extension.Contents("PowerShell16.png"), Extension.Contents("PowerShell20.png"), Extension.Contents("PowerShell24.png"), Extension.Contents("PowerShell32.png") },
    Icon32 = { Extension.Contents("PowerShell32.png"), Extension.Contents("PowerShell40.png"), Extension.Contents("PowerShell48.png"), Extension.Contents("PowerShell64.png") }
];
