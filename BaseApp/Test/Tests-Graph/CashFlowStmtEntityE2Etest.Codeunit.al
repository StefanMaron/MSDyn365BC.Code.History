#if not CLEAN18
codeunit 135522 "CashFlow Stmt. Entity E2E test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Cash Flow Statement]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'cashFlowStatement';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCashFlowRecords()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve Cash Flow Statement Report information from the cashFlowStatement API.
        Initialize;

        // [WHEN] A GET request is made to the cashFlowStatement API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Cash Flow Statement Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response is empty.
        Assert.AreNotEqual('', ResponseText, 'GET response must not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCashFlowRecord()
    var
        TempAccScheduleLineEntity: Record "Acc. Schedule Line Entity" temporary;
        IncomeStmtEntityE2ETest: Codeunit "Income Stmt. Entity E2E Test";
        IncomeStatementEntityBufferJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a cashFlowStatement record through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a cashFlowStatement JSON object to send to the service.
        IncomeStatementEntityBufferJSON := IncomeStmtEntityE2ETest.GetIncomeStatementJSON(TempAccScheduleLineEntity);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Cash Flow Statement Entity", ServiceNameTxt);
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
#endif
