// Data connector for for the TP-Link HS-100 smart plug
section TPLinkSmartPlug;
//A GUID that represents this client
GUID = "72fc1bfa-d102-42a3-a394-eb6687e3ed19";

[DataSource.Kind="TPLinkSmartPlug", Publish="TPLinkSmartPlug.Publish"]
shared TPLinkSmartPlug.Devices = () =>
        let
            credential = Extension.CurrentCredential(),
            payload = [ method= "login",
                        params= [
                                 appType= "Kasa_Android",
                                 cloudUserName=credential[Username],
                                 cloudPassword=credential[Password],
                                 terminalUUID= GUID
                                ]
                        ],
            tokenRequest = Web.Contents("https://wap.tplinkcloud.com", [Content=Json.FromValue(payload)]),
            token = Json.Document(tokenRequest)[result][token],
            devicesRequest = Web.Contents("https://wap.tplinkcloud.com",[Query=[token = token],Content = Json.FromValue([method="getDeviceList"])]),
            devicesList = Json.Document(devicesRequest)[result][deviceList]{0},
            devicesTable = #table(
                                {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},{
                                {devicesList[alias],devicesList[deviceId], TPLinkSmartPlug.DeviceInfo(devicesList[deviceId]), "Table", "Table",    true}
                             }),
            devicesNavigation = Table.ToNavigationTable(devicesTable, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
        in 
            devicesNavigation;

TPLinkSmartPlug.DeviceInfo = (deviceId as text) =>
        let
            credential = Extension.CurrentCredential(),
            payload = [ method= "login",
                        params= [
                                 appType= "Kasa_Android",
                                 cloudUserName=credential[Username],
                                 cloudPassword=credential[Password],
                                 terminalUUID= GUID
                                ]
                        ],
            tokenRequest = Web.Contents("https://wap.tplinkcloud.com", [Content=Json.FromValue(payload)]),
            token = Json.Document(tokenRequest)[result][token],
            statsPayload = [ method="passthrough",
                             params=[ deviceId=deviceId,
                                     requestData=Json.FromValue([system=[get_sysinfo="null"]])
                                    ]
                            ],
            statsRequest = Web.Contents("https://wap.tplinkcloud.com",[Query=[token = token],Content = Json.FromValue(statsPayload)]),
            statsResponse = Json.Document(Json.Document(statsRequest)[result][responseData])[system],
            stats = if statsResponse[get_sysinfo]?=null then Record.ToTable(statsResponse) else Record.ToTable(statsResponse[get_sysinfo])
        in 
            stats;

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