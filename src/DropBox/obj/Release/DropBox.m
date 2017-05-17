// This file contains your Data Connector logic
section DropBox;

appKey="fianhvd3kknjeke";
appSecret="9fckd26kf1myv0u";
redirectUrl = "https://preview.powerbi.com/views/oauthredirect.html";

windowWidth = 720;
windowHeight = 1024;

[DataSource.Kind="DropBox", Publish="DropBox.Publish"]
shared DropBox.Contents = (optional message as text) =>
    let
        _message = if (message <> null) then message else "(no message)",
        a = "Hello from DropBox: " & _message
    in
        a;

// Data Source Kind description
DropBox = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
DropBox.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = DropBox.Icons,
    SourceTypeImage = DropBox.Icons
];

DropBox.Icons = [
    Icon16 = { Extension.Contents("DropBox16.png"), Extension.Contents("DropBox20.png"), Extension.Contents("DropBox24.png"), Extension.Contents("DropBox32.png") },
    Icon32 = { Extension.Contents("DropBox32.png"), Extension.Contents("DropBox40.png"), Extension.Contents("DropBox48.png"), Extension.Contents("DropBox64.png") }
];
