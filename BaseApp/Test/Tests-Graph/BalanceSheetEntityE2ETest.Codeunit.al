#if not CLEAN18
codeunit 135520 "Balance Sheet Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Balance Sheet]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ServiceNameTxt: Label 'balanceSheet';
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBalanceSheetRecords()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve Balance Sheet Report information from the balanceSheet API.
        Initialize;

        // [WHEN] A GET request is made to the balanceSheet API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Balance Sheet Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response is empty.
        Assert.AreNotEqual('', ResponseText, 'GET response must not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateBalanceSheetRecord()
    var
        TempBalanceSheetBuffer: Record "Balance Sheet Buffer" temporary;
        BalanceSheetBufferJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a balanceSheet record through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a balanceSheet JSON object to send to the service.
        BalanceSheetBufferJSON := GetBalanceSheetJSON(TempBalanceSheetBuffer);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Balance Sheet Entity", ServiceNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, BalanceSheetBufferJSON, ResponseText);

        // [THEN] The response is empty.
        Assert.AreEqual('', ResponseText, 'CREATE response must be empty.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryApplicationArea.EnableFoundationSetup;
        IsInitialized := true;
    end;

    local procedure GetBalanceSheetJSON(var BalanceSheetBuffer: Record "Balance Sheet Buffer") BalanceSheetJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        if BalanceSheetBuffer."Line No." = 0 then
            BalanceSheetBuffer."Line No." := LibraryRandom.RandIntInRange(1, 10000);
        if BalanceSheetBuffer.Description = '' then
            BalanceSheetBuffer.Description := LibraryUtility.GenerateGUID;

        JSONManagement.AddJPropertyToJObject(JsonObject, 'lineNumber', BalanceSheetBuffer."Line No.");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'display', BalanceSheetBuffer.Description);

        BalanceSheetJSON := JSONManagement.WriteObjectToString;
    end;
}
#endif
