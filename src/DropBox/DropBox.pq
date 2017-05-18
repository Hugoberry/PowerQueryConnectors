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
        json=content // Json.Document(content)
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

ToText =
(Val as any, optional RecursTypes as logical) as text =>
let
    RecursTypes = if (RecursTypes<>null) then RecursTypes else false,
    Tried = (try Val),
    Value = if Tried[HasError] then Tried[Error] else Tried[Value],
    CaseValues = {
    { (x)=> Value.Is(x, type type), Type.ToText(Value, RecursTypes) },
    { (x)=> Value.Is(x, type function),
        let
            Type = Value.Type(Value),
            Params = Type.FunctionParameters(Type),
            Reqd = Type.FunctionRequiredParameters(Type),
            Ret = Type.FunctionReturn(Type)
        in
        "function (" &
        Record.TransformJoin(Params, (k,v) =>
            (if List.PositionOf(Record.FieldNames(Params), k) >= Reqd then "optional " else "") &
            k & " as " & @ToText(v, RecursTypes)
        )
        & ") as " & @ToText(Ret, RecursTypes)
    },
    { (x)=> Value.Is(x, type table), "#table(" & @ToText(Table.ColumnNames(Value), RecursTypes) & ", " & @ToText(Table.ToRows(Value), RecursTypes) & ")"},
    { (x)=> Value.Is(x, type record), "[" &
        Record.TransformJoin(Value, (k,v) => k & "=" & @ToText(v, RecursTypes))
    & "]" },
    { (x)=> Value.Is(x, type list), "{" & Text.Combine(List.Transform(Value, each @ToText(_, RecursTypes)), ", ") & "}" },
    { (x)=> x = null, "null" },
    { (x)=> true, Expression.Constant(Value) }
    },
    Return = List.First(List.Select(CaseValues, each _{0}(Value))){1}
in Return;

Type.ToText =
(Type as any, optional Recurs as logical) as text =>
let
    Recurs = if (Recurs<>null) then Recurs else false,

    CaseValues = {
    { (x)=> (try x)[HasError], "error" },
    { (x)=> Type.Is(x, type type), "type"},    //if Recurs then  else 
    { (x)=> Type.Is(x, type function), "function"},
    { (x)=> Type.Is(x, type table), if Recurs then "table " & @Type.ToText(Type.TableRow(NonNull), Recurs) else "table"},
    { (x)=> Type.Is(x, type record), if Recurs then
        let
            Record = Type.RecordFields(NonNull)
        in "[" & Record.TransformJoin(Record, (k,v) =>
            (if v[Optional] then "optional " else "") & Expression.Identifier(k) & " = " & @Type.ToText(v[Type], Recurs)
        ) & "]"
    else "record"},
    { (x)=> Type.Is(x, type list), if Recurs then "{" & @Type.ToText(Type.ListItem(NonNull), Recurs) & "}" else "list"},
    { (x)=> Type.Is(x, type binary), "binary"},
    { (x)=> Type.Is(x, type logical), "logical"},
    { (x)=> Type.Is(x, type number), "number"},
    { (x)=> Type.Is(x, type text), "text"},
    { (x)=> Type.Is(x, type date), "date"},
    { (x)=> Type.Is(x, type time), "time"},
    { (x)=> Type.Is(x, type datetime), "datetime"},
    { (x)=> Type.Is(x, type datetimezone), "datetimezone"},
    { (x)=> Type.Is(x, type duration), "duration"},
    { (x)=> Type.Is(type anynonnull, x), "anynonnull"},
    { (x)=> Type.Is(type null, x), "null"},
    { (x)=> Type.Is(None.Type, x), "none"},
//    { (x)=> Type.Is(type any, x), "any"},
    { (x)=> true, "?"}
    },
    NonNull = Type.NonNullable(Type),
    Return = if Type.Is(type any, Type) then "any"
    else (if Type.IsNullable(Type) then "nullable " else "")
    & List.First(List.Select(CaseValues, each _{0}(NonNull))){1}
in Return;

Record.TransformJoin = 
(Rec as record, Lambda as function, optional Delimiter as text) as text =>
let
    Delimiter = if (Delimiter<>null) then Delimiter else ", ",

    Keys = Record.FieldNames(Rec),
    Transformed = List.Transform(Keys, each Lambda(_, Record.Field(Rec,_))),
    Combined = Text.Combine(Transformed, Delimiter),

    Return = Combined
in
    Return;