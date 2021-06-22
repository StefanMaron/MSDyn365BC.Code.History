codeunit 135526 "Ret. Earnings Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Retained Earnings]
    end;

    var
        ServiceNameTxt: Label 'retainedEarningsStatement';
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetainedEarningsStatementRecords()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve Retained Earnings Statement Report information from the retainedEarningsStatement API.
        Initialize;

        // [WHEN] A GET request is made to the retainedEarningsStatement API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Retained Earnings Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response is empty.
        Assert.AreNotEqual('', ResponseText, 'GET response must not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateRetainedEarningsStatementRecord()
    var
        TempAccScheduleLineEntity: Record "Acc. Schedule Line Entity" temporary;
        IncomeStmtEntityE2ETest: Codeunit "Income Stmt. Entity E2E Test";
        IncomeStatementEntityBufferJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a retainedEarningsStatement record through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a retainedEarningsStatement JSON object to send to the service.
        IncomeStatementEntityBufferJSON := IncomeStmtEntityE2ETest.GetIncomeStatementJSON(TempAccScheduleLineEntity);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Retained Earnings Entity", ServiceNameTxt);
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
}

