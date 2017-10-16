// Data connector for for the TP-Link HS-100 smart plug
section TPLinkSmartPlug;
//A GUID that represents this client
GUID = "72fc1bfa-d102-42a3-a394-eb6687e3ed19";

[DataSource.Kind="TPLinkSmartPlug", Publish="TPLinkSmartPlug.Publish"]
shared TPLinkSmartPlug.Devices = () =>
        let
            Credential = Extension.CurrentCredential(),
            payload = [method= "login",
                  params= [
                             appType= "Kasa_Android",
                             cloudUserName=Credential[Username],
                             cloudPassword=Credential[Password],
                             terminalUUID= GUID
                            ]
                ],
            first= Web.Contents("https://wap.tplinkcloud.com", [Content=Json.FromValue(payload)]),
            tok = Json.Document(first)[result][token],
            source = Web.Contents("https://wap.tplinkcloud.com",[Query=[token = tok],Content = Json.FromValue([method="getDeviceList"])]),
            response = Json.Document(source)[result][deviceList]{0},
            objects = #table(
                                {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},{
                                {response[alias],response[deviceId], TPLinkSmartPlug.Device(response[deviceId]), "Table", "Table",    true}
                             }),
            navTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
        in 
            navTable;

shared TPLinkSmartPlug.Device = (deviceId as text) =>
        let
            Credential = Extension.CurrentCredential(),
            payload = [method= "login",
                  params= [
                             appType= "Kasa_Android",
                             cloudUserName=Credential[Username],
                             cloudPassword=Credential[Password],
                             terminalUUID= GUID
                            ]
                ],
            first= Web.Contents("https://wap.tplinkcloud.com", [Content=Json.FromValue(payload)]),
            tok = Json.Document(first)[result][token],
            statsRequest = [method="passthrough",
            params=[deviceId=deviceId,
                    requestData=Json.FromValue([system=[get_sysinfo="null"]])
                ]
            ],
            source = Web.Contents("https://wap.tplinkcloud.com",[Query=[token = tok],Content = Json.FromValue(statsRequest)]),
            response = Record.ToTable(Json.Document(Json.Document(source)[result][responseData])[system][get_sysinfo])
        in 
            response;


// Data Source Kind description
TPLinkSmartPlug = [
    Authentication = [
        // Key = [],
        UsernamePassword = []
        // Windows = [],
        //Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
TPLinkSmartPlug.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = TPLinkSmartPlug.Icons,
    SourceTypeImage = TPLinkSmartPlug.Icons
];

TPLinkSmartPlug.Icons = [
    Icon16 = { Extension.Contents("TPLinkSmartPlug16.png"), Extension.Contents("TPLinkSmartPlug20.png"), Extension.Contents("TPLinkSmartPlug24.png"), Extension.Contents("TPLinkSmartPlug32.png") },
    Icon32 = { Extension.Contents("TPLinkSmartPlug32.png"), Extension.Contents("TPLinkSmartPlug40.png"), Extension.Contents("TPLinkSmartPlug48.png"), Extension.Contents("TPLinkSmartPlug64.png") }
];


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