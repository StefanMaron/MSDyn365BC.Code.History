#if not CLEAN18
codeunit 135524 "Aged AP Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Purchase] [Aged Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'agedAccountsPayable';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAgedAPRecords()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve Aged Accounts Payable Report information from the agedAccountsPayable API.
        Initialize;

        // [WHEN] A GET request is made to the agedAccountsPayable API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Aged AP Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response is empty.
        Assert.AreNotEqual('', ResponseText, 'GET response must not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateAgedAPRecord()
    var
        TempAgedReportEntity: Record "Aged Report Entity" temporary;
        AgedReportEntityJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a agedAccountsPayable record through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a agedAccountsPayable JSON object to send to the service.
        AgedReportEntityJSON := GetAgedAPJSON(TempAgedReportEntity);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Aged AP Entity", ServiceNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, AgedReportEntityJSON, ResponseText);

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

    local procedure GetAgedAPJSON(var AgedReportEntity: Record "Aged Report Entity") AgedReportEntityJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        if AgedReportEntity."No." = '' then
            AgedReportEntity."No." := LibraryUtility.GenerateRandomCode(AgedReportEntity.FieldNo("No."), DATABASE::"Aged Report Entity");

        JSONManagement.AddJPropertyToJObject(JsonObject, 'vendorNumber', AgedReportEntity."No.");

        AgedReportEntityJSON := JSONManagement.WriteObjectToString;
    end;
}
#endif
