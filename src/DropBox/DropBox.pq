// This file contains your Data Connector logic
section DropBox;

appKey="fianhvd3kknjeke";
appSecret="9fckd26kf1myv0u";
redirectUrl = "https://preview.powerbi.com/views/oauthredirect.html";

windowWidth = 720;
windowHeight = 1024;

[DataSource.Kind="DropBox", Publish="DropBox.Publish"]
shared DropBox.Contents = (path as text) =>
    let
       key = Extension.CurrentCredential()[access_token],
       content = Web.Contents("https://api.dropboxapi.com/2/files/list_folder",[
            Content = Json.FromValue([
                    path = path,
                    recursive=false,
                    include_media_info=false,
                    include_deleted=false,
                    include_has_explicit_shared_members=false]),
            Headers=[#"Content-type" = "application/json", #"Authorization" = "Bearer " & key]]),
        json=Json.Document(content)
    in
        json;

// Data Source Kind description
DropBox = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Label = Extension.LoadString("AuthenticationLabel")
        ]
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

StartLogin = (resourceUrl, state, display) =>
    let
        AuthorizeUrl = "https://www.dropbox.com/oauth2/authorize?" & Uri.BuildQueryString([
            response_type = "code",
            client_id = appKey,
            state = state,
            redirect_uri = redirectUrl])
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirectUrl,
            WindowHeight = windowHeight,
            WindowWidth = windowWidth,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        parts = Uri.Parts(callbackUri)[Query],
        result = if (Record.HasFields(parts, {"error", "error_description"})) then 
                    error Error.Record(parts[error], parts[error_description], parts)
                 else
                    TokenMethod(parts[code])
    in
        result;

TokenMethod = (code) =>
    let
        response = Web.Contents("https://api.dropboxapi.com/oauth2/token", [
            Content = Text.ToBinary(Uri.BuildQueryString([
                grant_type = "authorization_code",
                client_id = appKey,
                client_secret = appSecret,
                code = code,
                redirect_uri = redirectUrl])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"], ManualStatusHandling = {400}]),
        body = Json.Document(response),
        result = if (Record.HasFields(body, {"error", "error_description"})) then 
                    error Error.Record(body[error], body[error_description], body)
                 else
                    body
    in
        result;

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

