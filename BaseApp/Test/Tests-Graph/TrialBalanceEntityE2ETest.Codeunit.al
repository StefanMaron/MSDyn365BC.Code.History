#if not CLEAN18
codeunit 135523 "Trial Balance Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Trial Balance]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'trialBalance';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTrialBalanceRecords()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve Trial Balance Report information from the trialBalance API.
        Initialize;

        // [WHEN] A GET request is made to the trialBalance API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Trial Balance Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response is empty.
        Assert.AreNotEqual('', ResponseText, 'GET response must not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTrialBalanceRecord()
    var
        TempTrialBalanceEntityBuffer: Record "Trial Balance Entity Buffer" temporary;
        TrialBalanceEntityBufferJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a trialBalance record through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a trialBalance JSON object to send to the service.
        TrialBalanceEntityBufferJSON := GetTrialBalanceJSON(TempTrialBalanceEntityBuffer);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Trial Balance Entity", ServiceNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, TrialBalanceEntityBufferJSON, ResponseText);

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

    local procedure GetTrialBalanceJSON(var TrialBalanceEntityBuffer: Record "Trial Balance Entity Buffer") TrialBalanceJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        if TrialBalanceEntityBuffer."No." = '' then
            TrialBalanceEntityBuffer."No." :=
              LibraryUtility.GenerateRandomCode(TrialBalanceEntityBuffer.FieldNo("No."), DATABASE::"Trial Balance Entity Buffer");
        if TrialBalanceEntityBuffer.Name = '' then
            TrialBalanceEntityBuffer.Name := LibraryUtility.GenerateGUID;

        JSONManagement.AddJPropertyToJObject(JsonObject, 'number', TrialBalanceEntityBuffer."No.");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'display', TrialBalanceEntityBuffer.Name);

        TrialBalanceJSON := JSONManagement.WriteObjectToString;
    end;
}
#endif
