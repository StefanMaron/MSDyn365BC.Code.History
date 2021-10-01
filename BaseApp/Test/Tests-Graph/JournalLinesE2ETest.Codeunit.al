#if not CLEAN18
codeunit 135505 "Journal Lines E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Journal]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        Assert: Codeunit Assert;
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
        LibraryGraphJournalLines: Codeunit "Library - Graph Journal Lines";
        ServiceNameTxt: Label 'journals';
        ServiceSubpageNameTxt: Label 'journalLines';
        AmountNameTxt: Label 'amount';
        LineNumberNameTxt: Label 'lineNumber';
        DocumentNoNameTxt: Label 'documentNumber';
        AccountNoNameTxt: Label 'accountNumber';
        BalAccountNoNameTxt: Label 'balancingAccountNumber';
        AccountIdNameTxt: Label 'accountId';
        JournalBatchNameTxt: Label 'journalDisplayName';

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
        LibraryERM: Codeunit "Library - ERM";
        JournalName: Code[10];
        Amount: Decimal;
        LineNo: Integer;
        AccountNo: Code[20];
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create a journal line through a POST method and check if it was created
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;
        if GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalName) then begin
            GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
            GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting);
            GenJournalBatch.Modify();
        end;

        // [GIVEN] a JSON text with a journal line containing all the available fields
        LineNo := LibraryGraphJournalLines.GetNextJournalLineNo(JournalName);
        LineJSON := LibraryGraphJournalLines.CreateLineWithGenericLineValuesJSON(LineNo, Amount);
        AccountNo := LibraryGraphJournalLines.CreateAccount;
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, AccountNoNameTxt, AccountNo);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);

        // [THEN] the response text should contain the journal line information and the integration record table should map the JournalLineID with the ID
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        VerifyLineNoInJson(ResponseText, Format(LineNo), JournalName);
        LibraryGraphMgt.VerifyIDFieldInJsonWithoutIntegrationRecord(ResponseText, 'id');

        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        LibraryGraphJournalLines.CheckLineWithGenericLineValues(GenJournalLine, Amount);
        Assert.AreEqual(
          JournalName, GenJournalLine."Journal Batch Name", 'Journal Line ' + JournalBatchNameTxt + ' should be the default');
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'Journal Line ' + AccountNoNameTxt + ' should be changed');
        Assert.AreEqual(
          GenJournalBatch."Bal. Account No.",
          GenJournalLine."Bal. Account No.",
          'Journal Line ' + BalAccountNoNameTxt + ' should be changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateJournalLineAtTheTop()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        Amount: Decimal;
        LineNo: Integer;
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create a journal line through a POST method and check if it was created
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a JSON text with a journal line containing only the amount
        LineNo := LibraryGraphJournalLines.GetNextJournalLineNo(JournalName);
        Amount := LibraryRandom.RandDecInRange(1, 500, 1);
        LineJSON := LibraryGraphMgt.AddComplexTypetoJSON('', AmountNameTxt, Format(Amount, 0, 9));
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);

        // [THEN] the response text should contain the journal line information and the integration record table should map the JournalLineID with the ID
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        VerifyLineNoInJson(ResponseText, Format(LineNo), JournalName);

        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        Assert.AreEqual(Amount, GenJournalLine.Amount, 'Journal Line ' + AmountNameTxt + ' should be changed');
        Assert.AreNotEqual('', GenJournalLine."Document No.", 'Document No should not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateJournalLineBetweenOtherLines()
    var
        JournalName: Code[10];
        Amount: Decimal;
        LineNo: array[4] of Integer;
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
        DocumentNo: Code[20];
        ResponseDocumentNo: Text;
    begin
        // [SCENARIO] Create a journal line through a POST method and check if it was created
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] 2 lines with total balance of 0 and 1 more at the end
        Amount := LibraryRandom.RandDecInRange(1, 500, 1);
        DocumentNo := LibraryUtility.GenerateGUID;
        LineNo[1] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, Amount, DocumentNo);
        LineNo[2] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, -Amount, DocumentNo);
        LineNo[3] := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);

        Assert.AreNotEqual(1, LineNo[3] - LineNo[2], 'The Lines created should have Line Nos with difference at least > 1');

        // [GIVEN] a JSON text with a journal line containing the LineNo and the Amount fields
        Amount := LibraryRandom.RandDecInRange(1, 500, 1);
        LineNo[4] := LineNo[2] + 1;
        LineJSON := CreateLineWithAmountJSON(LineNo[4], Amount);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);

        // [THEN] the response text should contain the journal line ID, Line No and Document No
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJsonWithoutIntegrationRecord(ResponseText, 'id');
        VerifyLineNoInJson(ResponseText, Format(LineNo[4]), JournalName);
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, DocumentNoNameTxt, ResponseDocumentNo),
          'The response should contain ' + DocumentNoNameTxt);
        Assert.AreNotEqual('', ResponseDocumentNo, 'Document No should not be empty.');
        Assert.AreNotEqual(DocumentNo, ResponseDocumentNo, 'The Document No should be increased');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateJournalLineAtTheBottom()
    var
        JournalName: Code[10];
        Amount: Decimal;
        LineNo: array[3] of Integer;
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
        DocumentNo: Code[20];
        ResponseDocumentNo: Text;
    begin
        // [SCENARIO] Create a journal line through a POST method and check if it was created
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] 2 lines with total balance of 0
        Amount := LibraryRandom.RandDecInRange(1, 500, 1);
        DocumentNo := LibraryUtility.GenerateGUID;
        LineNo[1] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, Amount, DocumentNo);
        LineNo[2] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, -Amount, DocumentNo);

        // [GIVEN] a JSON text with a journal line containing the LineNo and the Amount fields
        Amount := LibraryRandom.RandDecInRange(1, 500, 1);
        LineNo[3] := LibraryGraphJournalLines.GetNextJournalLineNo(JournalName);
        LineJSON := CreateLineWithAmountJSON(LineNo[3], Amount);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);

        // [THEN] the response text should contain the journal line ID, Line No and Document No
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJsonWithoutIntegrationRecord(ResponseText, 'id');
        VerifyLineNoInJson(ResponseText, Format(LineNo[3]), JournalName);
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, DocumentNoNameTxt, ResponseDocumentNo),
          'The response should contain ' + DocumentNoNameTxt);
        Assert.AreNotEqual('', ResponseDocumentNo, 'Document No should not be empty.');
        Assert.AreNotEqual(DocumentNo, ResponseDocumentNo, 'The Document No should be increased');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        GenJournalLineGUID: Guid;
        LineNo: Integer;
        LineNoInJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a line and use a GET method with an ID specified to retrieve it
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a line in the General Journal Table
        LineNo := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        GenJournalLineGUID := GenJournalLine.SystemId;
        Commit();

        // [WHEN] we GET the line from the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, GetJournalLineURL(GenJournalLineGUID));
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the line should exist in the response
        LibraryGraphMgt.VerifyIDFieldInJsonWithoutIntegrationRecord(ResponseText, 'id');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, LineNumberNameTxt, LineNoInJSON),
          'Could not find the ' + LineNumberNameTxt + ' in the JSON');
        Assert.AreEqual(Format(LineNo), LineNoInJSON, 'The response JSON does not contain the correct Line No');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetJournalLines()
    var
        JournalName: Code[10];
        LineNo: array[2] of Integer;
        LineJSON: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create lines and use a GET method to retrieve them
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] 2 lines in the General Journal Table
        LineNo[1] := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);
        LineNo[2] := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);
        Commit();

        // [WHEN] we GET all the lines from the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 lines should exist in the response
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, LineNumberNameTxt, Format(LineNo[1]), Format(LineNo[2]), LineJSON[1], LineJSON[2]),
          'Could not find the lines in JSON');
        LibraryGraphMgt.VerifyIDFieldInJsonWithoutIntegrationRecord(LineJSON[1], 'id');
        LibraryGraphMgt.VerifyIDFieldInJsonWithoutIntegrationRecord(LineJSON[2], 'id');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        GenJournalLineGUID: Guid;
        LineNo: Integer;
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
        NewLineNo: Integer;
        NewAmount: Decimal;
        NewAccountNo: Code[20];
    begin
        // [SCENARIO] Create a journal line, use a PATCH method to change it and then verify the changes
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a line in the Journal Lines Table
        LineNo := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);

        // [GIVEN] a JSON text with an amount property
        NewLineNo := LibraryGraphJournalLines.GetNextJournalLineNo(JournalName);
        LineJSON := LibraryGraphJournalLines.CreateLineWithGenericLineValuesJSON(NewLineNo, NewAmount);
        NewAccountNo := LibraryGraphJournalLines.CreateAccount;
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, AccountNoNameTxt, NewAccountNo);

        // [GIVEN] the journal line's unique GUID
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetFilter("Line No.", Format(LineNo));
        GenJournalLine.FindFirst;
        GenJournalLineGUID := GenJournalLine.SystemId;
        Assert.AreNotEqual('', GenJournalLineGUID, 'Journal Line GUID should not be empty');
        Commit();

        // [WHEN] we PATCH the JSON to the web service, with the unique JournalLineID
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, GetJournalLineURL(GenJournalLineGUID));
        LibraryGraphMgt.PatchToWebService(TargetURL, LineJSON, ResponseText);

        // [THEN] the JournalLine in the table should have the values that were given
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", NewLineNo);
        GenJournalLine.FindFirst;
        LibraryGraphJournalLines.CheckLineWithGenericLineValues(GenJournalLine, NewAmount);
        Assert.AreEqual(NewAccountNo, GenJournalLine."Account No.", 'Journal Line ' + AccountNoNameTxt + ' should be changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyJournalLinesDisplayNameThrowsError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: array[2] of Code[10];
        GenJournalLineGUID: Guid;
        LineNo: Integer;
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create a journal line and check if an error is thrown when we PATCH the journal display name
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] 2 journals
        JournalName[1] := LibraryGraphJournalLines.CreateJournal;
        JournalName[2] := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a line in the Journal Lines Table
        LineNo := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName[1]);

        // [GIVEN] a JSON text with an amount property
        LineJSON := LibraryGraphMgt.AddPropertytoJSON('', JournalBatchNameTxt, JournalName[2]);

        // [GIVEN] the journal line's unique GUID
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName[1]);
        GenJournalLine.SetFilter("Line No.", Format(LineNo));
        GenJournalLine.FindFirst;
        GenJournalLineGUID := GenJournalLine.SystemId;
        Assert.AreNotEqual('', GenJournalLineGUID, 'Journal Line GUID should not be empty');
        Commit();

        // [WHEN] we PATCH the JSON to the web service, with the different journal batch name
        // [THEN] we get an error
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName[1]), PAGE::"Journal Entity", ServiceNameTxt, GetJournalLineURL(GenJournalLineGUID));
        asserterror LibraryGraphMgt.PatchToWebService(TargetURL, LineJSON, ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        GenJournalLineGUID: Guid;
        LineNo: Integer;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create a journal line, use a DELETE method to remove it and then verify the deletion
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a journal line in the table
        LineNo := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);

        // [GIVEN] the journal line's unique GUID
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetFilter("Line No.", Format(LineNo));
        GenJournalLine.FindFirst;
        GenJournalLineGUID := GenJournalLine.SystemId;
        Assert.AreNotEqual('', GenJournalLineGUID, 'GenJournalLineGUID should not be empty');
        Commit();

        // [WHEN] we DELETE the journal line from the web service, with the journal line's unique ID
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, GetJournalLineURL(GenJournalLineGUID));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the journal line shouldn't exist in the table
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetFilter("Line No.", Format(LineNo));
        Assert.IsFalse(GenJournalLine.FindFirst, 'The Journal Line should be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetFromJournalLinesDirectlyFails()
    var
        JournalName: Code[10];
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Getting a Journal Line directly from the /journalLines endpoint fails
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a line in the General Journal Table
        LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);
        Commit();

        // [WHEN] we GET the line from the web service
        // [THEN] it should fail immediately
        TargetURL := LibraryGraphMgt.CreateSubpageURL('', PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostFromJournalLinesDirectlyFails()
    var
        Amount: Decimal;
        LineJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Creating a Journal Line directly from the /journalLines endpoint fails
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a JSON text with a journal line containing only the amount
        Amount := LibraryRandom.RandDecInRange(1, 500, 1);
        LineJSON := LibraryGraphMgt.AddComplexTypetoJSON('', AmountNameTxt, Format(Amount, 0, 9));
        Commit();

        // [WHEN] we POST the JSON to the web service
        // [THEN] the request should fail
        TargetURL := LibraryGraphMgt.CreateSubpageURL('', PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountNoAndIdSync()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        JournalName: Code[10];
        LineNo: array[3] of Integer;
        AccountNo: Code[20];
        AccountGUID: Guid;
        LineJSON: array[3] of Text;
        TargetURL: Text;
        ResponseText: array[3] of Text;
    begin
        // [SCENARIO] Create a journal line through a POST method and check if the Account Id and the Account No Sync correctly
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a G/L Account with Direct Posting enabled
        AccountNo := LibraryGraphJournalLines.CreateAccount;
        GLAccount.Get(AccountNo);
        AccountGUID := GLAccount.SystemId;

        // [GIVEN] JSON texts for journal lines with and without AccountNo and AccountId
        LineNo[1] := LibraryGraphJournalLines.GetNextJournalLineNo(JournalName);
        LineNo[2] := LibraryGraphJournalLines.GetNextJournalLineNo(JournalName);
        LineNo[3] := LibraryGraphJournalLines.GetNextJournalLineNo(JournalName);

        LineJSON[1] := LibraryGraphMgt.AddPropertytoJSON('', AccountNoNameTxt, AccountNo);
        LineJSON[2] := LibraryGraphMgt.AddPropertytoJSON('', AccountIdNameTxt, AccountGUID);
        LineJSON[3] := LibraryGraphMgt.AddPropertytoJSON('', AccountNoNameTxt, AccountNo);
        LineJSON[3] := LibraryGraphMgt.AddPropertytoJSON(LineJSON[3], AccountIdNameTxt, AccountGUID);

        Commit();

        // [WHEN] we POST the JSONs to the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[1], ResponseText[1]);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[2], ResponseText[2]);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[3], ResponseText[3]);

        // [THEN] the journal lines created should have the same account information
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[1]);
        GenJournalLine.FindFirst;
        Assert.AreEqual(
          AccountNo, GenJournalLine."Account No.", 'Journal Line ' + AccountNoNameTxt + ' should have the correct Account No');
        Assert.AreEqual(
          AccountGUID, GenJournalLine."Account Id", 'Journal Line ' + AccountIdNameTxt + ' should have the correct Account Id');

        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        GenJournalLine.FindFirst;
        Assert.AreEqual(
          AccountNo, GenJournalLine."Account No.", 'Journal Line ' + AccountNoNameTxt + ' should have the correct Account No');
        Assert.AreEqual(
          AccountGUID, GenJournalLine."Account Id", 'Journal Line ' + AccountIdNameTxt + ' should have the correct Account Id');

        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[3]);
        GenJournalLine.FindFirst;
        Assert.AreEqual(
          AccountNo, GenJournalLine."Account No.", 'Journal Line ' + AccountNoNameTxt + ' should have the correct Account No');
        Assert.AreEqual(
          AccountGUID, GenJournalLine."Account Id", 'Journal Line ' + AccountIdNameTxt + ' should have the correct Account Id');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountNoAndIdSyncErrors()
    var
        GLAccount: Record "G/L Account";
        JournalName: Code[10];
        AccountNo: Code[20];
        AccountGUID: Guid;
        LineJSON: array[2] of Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create a journal line through a POST method and check if the Account Id and the Account No Sync throws the errors
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a G/L Account with Direct Posting enabled
        AccountNo := LibraryGraphJournalLines.CreateAccount;
        GLAccount.Get(AccountNo);
        AccountGUID := GLAccount.SystemId;
        GLAccount.Delete();

        // [GIVEN] JSON texts for journal lines with and without AccountNo and AccountId
        LineJSON[1] := LibraryGraphMgt.AddPropertytoJSON('', AccountNoNameTxt, AccountNo);
        LineJSON[2] := LibraryGraphMgt.AddPropertytoJSON('', AccountIdNameTxt, AccountGUID);

        Commit();

        // [WHEN] we POST the JSON to the web service
        // [THEN] we will get errors because the Account doesn't exist
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[1], ResponseText);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[2], ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateJournalLineWithDimensions()
    var
        JournalName: Code[10];
        LineNo: Integer;
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
        GlobalDimensionCode: Code[20];
        GlobalDimensionValue: Code[20];
        NonGlobalDimensionCode: Code[20];
        NonGlobalDimensionValue: Code[20];
    begin
        // [SCENARIO] Create a journal line through a POST method and check if it was created
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a JSON text with a dimensions property
        LineNo := LibraryGraphJournalLines.GetNextJournalLineNo(JournalName);
        LineJSON :=
          CreateLineWithDimensionsJSON(
            LineNo, 1, 1, 1, 1, GlobalDimensionCode, GlobalDimensionValue, NonGlobalDimensionCode, NonGlobalDimensionValue);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, ServiceSubpageNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);

        // [THEN] The dimensioins should present in JSON response and be added on Jornal Line
        VerifyDimensionsInJSON(ResponseText, GlobalDimensionCode, GlobalDimensionValue, NonGlobalDimensionCode, NonGlobalDimensionValue);
        VerifyDimensionsOnJournalLine(
          JournalName, LineNo, GlobalDimensionCode, GlobalDimensionValue, NonGlobalDimensionCode, NonGlobalDimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateModifyDeleteDimensionsOnExistingJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        GenJournalLineGUID: Guid;
        LineNo: Integer;
        LineJSON: array[3] of Text;
        TargetURL: Text;
        ResponseText: Text;
        GlobalDimensionCode: array[3] of Code[20];
        GlobalDimensionValue: array[3] of Code[20];
        NonGlobalDimensionCode: array[3] of Code[20];
        NonGlobalDimensionValue: array[3] of Code[20];
        I: Integer;
    begin
        // [SCENARIO] Create a journal line, use a PATCH method to add dimensions and then verify the changes
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateJournal;

        // [GIVEN] a line in the Journal Lines Table
        LineNo := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);

        // [GIVEN] the journal line's unique GUID
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        GenJournalLineGUID := GenJournalLine.SystemId;
        Assert.AreNotEqual('', GenJournalLineGUID, 'Journal Line GUID should not be empty');
        Commit();
        VerifyDimensionsOnJournalLine(JournalName, LineNo, '', '', '', '');

        // [GIVEN] Web service URL for a line with the unique JournalLineID
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), PAGE::"Journal Entity", ServiceNameTxt, GetJournalLineURL(GenJournalLineGUID));

        // [GIVEN] a JSON text with a dimensions property
        LineJSON[1] :=
          CreateLineWithDimensionsJSON(
            LineNo, 1, 1, 1, 1, GlobalDimensionCode[1], GlobalDimensionValue[1], NonGlobalDimensionCode[1], NonGlobalDimensionValue[1]);
        LineJSON[2] :=
          CreateLineWithDimensionsJSON(
            LineNo, 1, 2, 2, 1, GlobalDimensionCode[2], GlobalDimensionValue[2], NonGlobalDimensionCode[2], NonGlobalDimensionValue[2]);
        LineJSON[3] :=
          CreateLineWithDimensionsJSON(
            LineNo, 0, 0, 0, 0, GlobalDimensionCode[3], GlobalDimensionValue[3], NonGlobalDimensionCode[3], NonGlobalDimensionValue[3]);

        for I := 1 to 3 do begin
            // [WHEN] we PATCH the JSON to the web service, with the unique JournalLineID
            Clear(ResponseText);
            LibraryGraphMgt.PatchToWebService(TargetURL, LineJSON[I], ResponseText);

            // [THEN] The dimensioins should present in JSON response and be added on Jornal Line
            VerifyDimensionsInJSON(
              ResponseText, GlobalDimensionCode[I], GlobalDimensionValue[I], NonGlobalDimensionCode[I], NonGlobalDimensionValue[I]);
            VerifyDimensionsOnJournalLine(
              JournalName, LineNo, GlobalDimensionCode[I], GlobalDimensionValue[I], NonGlobalDimensionCode[I], NonGlobalDimensionValue[I]);
        end;
    end;

    local procedure GetJournalID(JournalName: Code[10]): Guid
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalName);
        exit(GenJournalBatch.SystemId);
    end;

    local procedure CreateLineWithAmountJSON(LineNo: Integer; Amount: Decimal): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJObjectToJObject(JsonObject, AmountNameTxt, Format(Amount, 0, 9));
        JSONManagement.AddJObjectToJObject(JsonObject, LineNumberNameTxt, LineNo);

        exit(JSONManagement.WriteObjectToString);
    end;

    local procedure CreateLineWithDimensionsJSON(LineNo: Integer; GlobalDimensionNo: Integer; GlobalDimensionValueNo: Integer; NonGlobalDimensionNo: Integer; NonGlobalDimensionValueNo: Integer; var GlobalDimensionCode: Code[20]; var GlobalDimensionValue: Code[20]; var NonGlobalDimensionCode: Code[20]; var NonGlobalDimensionValue: Code[20]): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonArray: DotNet JArray;
        JsonObject: DotNet JObject;
        GlobalDimensionJsonObject: DotNet JObject;
        NonGlobalDimensionJsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.InitializeEmptyCollection;

        if (GlobalDimensionNo > 0) and (GlobalDimensionValueNo > 0) then begin
            GetGlobalDimension(GlobalDimensionNo, GlobalDimensionValueNo, GlobalDimensionCode, GlobalDimensionValue);
            GetDimensionJObject(GlobalDimensionCode, GlobalDimensionValue, GlobalDimensionJsonObject);
            JSONManagement.AddJObjectToCollection(GlobalDimensionJsonObject);
        end;

        if (NonGlobalDimensionNo > 0) and (NonGlobalDimensionValueNo > 0) then begin
            GetNonGlobalDimension(NonGlobalDimensionNo, NonGlobalDimensionValueNo, NonGlobalDimensionCode, NonGlobalDimensionValue);
            GetDimensionJObject(NonGlobalDimensionCode, NonGlobalDimensionValue, NonGlobalDimensionJsonObject);
            JSONManagement.AddJObjectToCollection(NonGlobalDimensionJsonObject);
        end;

        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetJsonArray(JsonArray);
        JSONManagement.AddJObjectToJObject(JsonObject, LineNumberNameTxt, LineNo);
        JSONManagement.AddJArrayToJObject(JsonObject, 'dimensions', JsonArray);

        exit(JSONManagement.WriteObjectToString);
    end;

    local procedure GetDimensionJObject("Code": Code[20]; Value: Code[20]; var JsonObject: DotNet JObject)
    var
        JSONManagement: Codeunit "JSON Management";
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'code', Code);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'valueCode', Value);
    end;

    local procedure GetGlobalDimension(DimensionNumber: Integer; ValueNumber: Integer; var "Code": Code[20]; var Value: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        I: Integer;
    begin
        GLSetup.Get();
        if DimensionNumber = 1 then
            DimensionValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 1 Code")
        else
            DimensionValue.SetRange("Dimension Code", GLSetup."Shortcut Dimension 2 Code");

        DimensionValue.Find('-');
        for I := 2 to ValueNumber do
            DimensionValue.Next;

        Code := DimensionValue."Dimension Code";
        Value := DimensionValue.Code;
    end;

    local procedure GetNonGlobalDimension(DimensionNumber: Integer; ValueNumber: Integer; var "Code": Code[20]; var Value: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        I: Integer;
    begin
        GLSetup.Get();
        Dimension.SetFilter(Code, '<>%1&<>%2', GLSetup."Shortcut Dimension 1 Code", GLSetup."Shortcut Dimension 2 Code");
        Dimension.Find('-');
        for I := 2 to DimensionNumber do
            Dimension.Next;

        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.Find('-');
        for I := 2 to ValueNumber do
            DimensionValue.Next;

        Code := DimensionValue."Dimension Code";
        Value := DimensionValue.Code;
    end;

    local procedure VerifyDimensionsOnJournalLine(JournalName: Code[10]; LineNo: Integer; ExpectedGlobalDimensionCode: Code[20]; ExpectedGlobalDimensionValue: Code[20]; ExpectedNonGlobalDimensionCode: Code[20]; ExpectedNonGlobalDimensionValue: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        ExpectedDimensionCount: Integer;
    begin
        if ExpectedGlobalDimensionCode <> '' then
            ExpectedDimensionCount += 1;
        if ExpectedNonGlobalDimensionCode <> '' then
            ExpectedDimensionCount += 1;

        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;

        Assert.AreEqual(ExpectedGlobalDimensionValue, GenJournalLine."Shortcut Dimension 1 Code", 'Incorrect Shortcut Dimension 1 Code.');
        Assert.AreEqual('', GenJournalLine."Shortcut Dimension 2 Code", 'Incorrect Shortcut Dimension 2 Code.');

        DimensionSetEntry.SetRange("Dimension Set ID", GenJournalLine."Dimension Set ID");
        if ExpectedDimensionCount > 0 then begin
            Assert.IsTrue(DimensionSetEntry.FindFirst, 'Incorrect count of dimensions on journal line.');
            Assert.AreEqual(ExpectedDimensionCount, DimensionSetEntry.Count, 'Incorrect count of dimensions on journal line.');
        end else
            Assert.IsFalse(DimensionSetEntry.FindFirst, 'Incorrect count of dimensions on journal line.');

        DimensionSetEntry.SetRange("Dimension Code", ExpectedGlobalDimensionCode);
        DimensionSetEntry.SetRange("Dimension Value Code", ExpectedGlobalDimensionValue);
        if ExpectedGlobalDimensionCode <> '' then
            Assert.IsTrue(
              DimensionSetEntry.FindFirst,
              StrSubstNo('Dimension (%1,%2) must exist.', ExpectedGlobalDimensionCode, ExpectedGlobalDimensionValue))
        else
            Assert.IsFalse(
              DimensionSetEntry.FindFirst,
              StrSubstNo('Dimension (%1,%2) must not exist.', ExpectedGlobalDimensionCode, ExpectedGlobalDimensionValue));

        DimensionSetEntry.SetRange("Dimension Code", ExpectedNonGlobalDimensionCode);
        DimensionSetEntry.SetRange("Dimension Value Code", ExpectedNonGlobalDimensionValue);
        if ExpectedNonGlobalDimensionCode <> '' then
            Assert.IsTrue(
              DimensionSetEntry.FindFirst,
              StrSubstNo('Dimension (%1,%2) must exist.', ExpectedNonGlobalDimensionCode, ExpectedNonGlobalDimensionValue))
        else
            Assert.IsFalse(
              DimensionSetEntry.FindFirst,
              StrSubstNo('Dimension (%1,%2) must not exist.', ExpectedNonGlobalDimensionCode, ExpectedNonGlobalDimensionValue));
    end;

    local procedure VerifyDimensionsInJSON(ResponseJSON: Text; ExpectedCode1: Code[20]; ExpectedValue1: Code[20]; ExpectedCode2: Code[20]; ExpectedValue2: Code[20])
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        JsonArray: DotNet JArray;
        LineJsonObject: DotNet JObject;
        ExpectedDimensionCount: Integer;
        ActualCode1: Code[20];
        ActualValue1: Code[20];
        ActualCode2: Code[20];
        ActualValue2: Code[20];
    begin
        if ExpectedCode1 <> '' then
            ExpectedDimensionCount += 1;
        if ExpectedCode2 <> '' then
            ExpectedDimensionCount += 1;

        JSONManagement.InitializeObject(ResponseJSON);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetArrayPropertyValueFromJObjectByName(JsonObject, 'dimensions', JsonArray);
        JSONManagement.InitializeCollectionFromJArray(JsonArray);
        Assert.AreEqual(ExpectedDimensionCount, JSONManagement.GetCollectionCount, 'Incorrect count of dimensions in JSON response.');

        if ExpectedDimensionCount = 0 then
            exit;

        JSONManagement.GetJObjectFromCollectionByIndex(LineJsonObject, 0);
        GetDimensionFromJObject(LineJsonObject, ActualCode1, ActualValue1);
        JSONManagement.GetJObjectFromCollectionByIndex(LineJsonObject, 1);
        GetDimensionFromJObject(LineJsonObject, ActualCode2, ActualValue2);
        if ExpectedCode1 = ActualCode1 then begin
            Assert.AreEqual(ExpectedCode1, ActualCode1, StrSubstNo('Unexpected dimension %1 in JSON response.', ActualCode1));
            Assert.AreEqual(ExpectedValue1, ActualValue1, StrSubstNo('Unexpected value for dimension %1 in JSON response.', ActualCode1));
            Assert.AreEqual(ExpectedCode2, ActualCode2, StrSubstNo('Unexpected dimension %1 in JSON response.', ActualCode2));
            Assert.AreEqual(ExpectedValue2, ActualValue2, StrSubstNo('Unexpected value for dimension %1 in JSON response.', ActualCode2));
        end else begin
            Assert.AreEqual(ExpectedCode1, ActualCode2, StrSubstNo('Unexpected dimension %1 in JSON response.', ActualCode2));
            Assert.AreEqual(ExpectedValue1, ActualValue2, StrSubstNo('Unexpected value for dimension %1 in JSON response.', ActualCode2));
            Assert.AreEqual(ExpectedCode2, ActualCode1, StrSubstNo('Unexpected dimension %1 in JSON response.', ActualCode1));
            Assert.AreEqual(ExpectedValue2, ActualValue1, StrSubstNo('Unexpected value for dimension %1 in JSON response.', ActualCode1));
        end;
    end;

    local procedure GetDimensionFromJObject(var JsonObject: DotNet JObject; var "Code": Code[20]; var Value: Code[20])
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CodeText: Text;
        ValueText: Text;
    begin
        GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, 'code', CodeText);
        GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, 'valueCode', ValueText);
        Code := CopyStr(CodeText, 1, MaxStrLen(Code));
        Value := CopyStr(ValueText, 1, MaxStrLen(Value));
    end;

    local procedure VerifyLineNoInJson(JSONTxt: Text; ExpectedLineNo: Text; JournalName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
        LineNo: Integer;
        LineNoValue: Text;
    begin
        Assert.IsTrue(LibraryGraphMgt.GetObjectIDFromJSON(JSONTxt, LineNumberNameTxt, LineNoValue), 'Could not find LineNo');
        Assert.AreEqual(ExpectedLineNo, LineNoValue, 'LineNo does not match');

        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        Evaluate(LineNo, LineNoValue);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
    end;

    local procedure GetJournalLineURL(JournalLineId: Text): Text
    begin
        exit(ServiceSubpageNameTxt + '(' + LibraryGraphMgt.StripBrackets(JournalLineId) + ')');
    end;
}
#endif
