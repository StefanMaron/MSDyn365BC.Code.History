#if not CLEAN18
codeunit 135521 "Income Stmt. Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Income Statement]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'incomeStatement';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIncomeStatementRecords()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] User can retrieve Income Statement Report information from the incomeStatement API.
        Initialize;

        // [WHEN] A GET request is made to the incomeStatement API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Income Statement Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response is empty.
        Assert.AreNotEqual('', ResponseText, 'GET response must not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateIncomeStatementRecord()
    var
        TempAccScheduleLineEntity: Record "Acc. Schedule Line Entity" temporary;
        IncomeStatementEntityBufferJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a incomeStatement record through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a incomeStatement JSON object to send to the service.
        IncomeStatementEntityBufferJSON := GetIncomeStatementJSON(TempAccScheduleLineEntity);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Income Statement Entity", ServiceNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, IncomeStatementEntityBufferJSON, ResponseText);

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

    [Scope('OnPrem')]
    procedure GetIncomeStatementJSON(var AccScheduleLineEntity: Record "Acc. Schedule Line Entity") IncomeStatementJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        if AccScheduleLineEntity."Line No." = 0 then
            AccScheduleLineEntity."Line No." := LibraryRandom.RandIntInRange(1, 10000);
        if AccScheduleLineEntity.Description = '' then
            AccScheduleLineEntity.Description := LibraryUtility.GenerateGUID;

        JSONManagement.AddJPropertyToJObject(JsonObject, 'lineNumber', AccScheduleLineEntity."Line No.");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'display', AccScheduleLineEntity.Description);

        IncomeStatementJSON := JSONManagement.WriteObjectToString;
    end;
}
#endif
