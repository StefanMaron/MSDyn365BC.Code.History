codeunit 135532 "Dimension Lines E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Dimension Line]
    end;

    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        GraphMgtCustomerPayments: Codeunit "Graph Mgt - Customer Payments";
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
        LibraryGraphJournalLines: Codeunit "Library - Graph Journal Lines";
        ServiceNameTxt: Label 'dimensionLines';
        ParentIdNameTxt: Label 'parentId';
        DimensionIdNameTxt: Label 'id';
        DimensionCodeNameTxt: Label 'code';
        DimensionValueIdNameTxt: Label 'valueId';
        DimensionValueCodeNameTxt: Label 'valueCode';

    [Scope('OnPrem')]
    procedure Initialize()
    begin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDimensionLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        JournalName: Code[10];
        CustomerPaymentsGUID: Guid;
        LineNo: Integer;
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create a dimension line in a customer payment through a POST method and check if it was created
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateCustomerPaymentsJournal;

        // [GIVEN] a line in the Customer Payments
        LineNo := LibraryGraphJournalLines.GetNextCustomerPaymentNo(JournalName);
        CustomerPaymentsGUID := CreateCustomerPayment(JournalName);

        // [GIVEN] a dimension with a value
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LineJSON := CreateDimensionJSON(CustomerPaymentsGUID, Dimension.Code, DimensionValue.Code);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, DimensionIdNameTxt, Dimension.Id);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, DimensionValueIdNameTxt, DimensionValue.Id);
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);

        // [THEN] the response text should contain the dimension information and the customer payment should have the new dimension
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        VerifyJSONContainsDimensionValues(ResponseText, Dimension.Code, DimensionValue.Code);

        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        Assert.IsTrue(
          DimensionSetIDContainsDimension(GenJournalLine."Dimension Set ID", Dimension.Code, DimensionValue.Code),
          'The dimension line should exist in the SetID of the journal line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDimensionLineFailsWithoutParentId()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LineJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Creating a dimension line through a POST method without specifying a parent Id fails
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a dimension with a value
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON('', DimensionCodeNameTxt, Dimension.Code);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, DimensionValueCodeNameTxt, DimensionValue.Code);
        Commit;

        // [WHEN] we POST the JSON to the web service
        // [THEN] the request fails because it doesn't have a parent Id
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDoesntWorkWithAlreadyExistingCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        JournalName: Code[10];
        CustomerPaymentsGUID: Guid;
        LineNo: Integer;
        LineJSON: array[2] of Text;
        DimensionCode: Code[20];
        DimensionValueCode: array[2] of Code[20];
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Try to create a dimension line with an already existing code
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateCustomerPaymentsJournal;

        // [GIVEN] a customer payment in the General Journal Table
        LineNo := LibraryGraphJournalLines.GetNextCustomerPaymentNo(JournalName);
        CustomerPaymentsGUID := CreateCustomerPayment(JournalName);

        // [GIVEN] 2 dimension json texts
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode := Dimension.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode[1] := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode[2] := DimensionValue.Code;
        LineJSON[1] := CreateDimensionJSON(CustomerPaymentsGUID, DimensionCode, DimensionValueCode[1]);
        LineJSON[2] := CreateDimensionJSON(CustomerPaymentsGUID, DimensionCode, DimensionValueCode[2]);
        Commit;

        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[1], ResponseText);

        // [WHEN] we POST the JSON to the web service, with the customer payment filter
        ResponseText := '';
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[2], ResponseText);

        // [THEN] the POST should fail and the dimension should stay the same
        Assert.AreEqual('', ResponseText, 'The POST should fail.');

        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        Assert.IsTrue(
          DimensionSetIDContainsDimension(GenJournalLine."Dimension Set ID", DimensionCode, DimensionValueCode[1]),
          'The dimension line should exist in the SetID of the journal line.');
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure TestGetDimensionLines()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        JournalName: Code[10];
        CustomerPaymentsGUID: Guid;
        LineJSON: array[2] of Text;
        DimensionCode: array[2] of Code[20];
        DimensionValueCode: array[2] of Code[20];
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create dimension lines in a journal line and use a GET method to retrieve them
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateCustomerPaymentsJournal;

        // [GIVEN] a customer payment in the General Journal Table
        CustomerPaymentsGUID := CreateCustomerPayment(JournalName);

        // [GIVEN] 2 dimensions with dimension values
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode[1] := Dimension.Code;
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode[2] := Dimension.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode[1]);
        DimensionValueCode[1] := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode[2]);
        DimensionValueCode[2] := DimensionValue.Code;

        LineJSON[1] := CreateDimensionJSON(CustomerPaymentsGUID, DimensionCode[1], DimensionValueCode[1]);
        LineJSON[2] := CreateDimensionJSON(CustomerPaymentsGUID, DimensionCode[2], DimensionValueCode[2]);
        Commit;

        // [GIVEN] the dimension lines are added in the customer payment
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[1], ResponseText);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[2], ResponseText);

        // [WHEN] we POST the JSON to the web service
        ResponseText := '';
        TargetURL := CreateDimensionLinesURLWithFilter(CustomerPaymentsGUID);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 dimension lines should exist in the response
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, DimensionCodeNameTxt, DimensionCode[1], DimensionCode[2], LineJSON[1], LineJSON[2]),
          'Could not find the lines in JSON');
        VerifyJSONContainsDimensionValues(LineJSON[1], DimensionCode[1], DimensionValueCode[1]);
        VerifyJSONContainsDimensionValues(LineJSON[2], DimensionCode[2], DimensionValueCode[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDimensionLinesOfJournalLines()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        JournalName: Code[10];
        JournalLineGUID: Guid;
        LineJSON: array[2] of Text;
        DimensionCode: array[2] of Code[20];
        DimensionValueCode: array[2] of Code[20];
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create dimension lines in a journal line and use a GET method to retrieve them
        // [GIVEN] a customer payment in the General Journal Table
        LibraryGraphJournalLines.Initialize;

        JournalName := LibraryGraphJournalLines.CreateJournal;
        JournalLineGUID := CreateJournalLine(JournalName);

        // [GIVEN] 2 dimensions with dimension values
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode[2] := Dimension.Code;
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode[1] := Dimension.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode[2]);
        DimensionValueCode[2] := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode[1]);
        DimensionValueCode[1] := DimensionValue.Code;

        LineJSON[2] := CreateDimensionJSON(JournalLineGUID, DimensionCode[2], DimensionValueCode[2]);
        LineJSON[1] := CreateDimensionJSON(JournalLineGUID, DimensionCode[1], DimensionValueCode[1]);
        Commit;

        // [GIVEN] the dimension lines are added in the customer payment
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[2], ResponseText);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[1], ResponseText);

        // [WHEN] we POST the JSON to the web service
        ResponseText := '';
        TargetURL := CreateDimensionLinesURLWithFilter(JournalLineGUID);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 dimension lines should exist in the response
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, DimensionCodeNameTxt, DimensionCode[2], DimensionCode[1], LineJSON[2], LineJSON[1]),
          'Could not find the lines in JSON');
        VerifyJSONContainsDimensionValues(LineJSON[2], DimensionCode[2], DimensionValueCode[2]);
        VerifyJSONContainsDimensionValues(LineJSON[1], DimensionCode[1], DimensionValueCode[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDimensionLinesFailsWithoutFilter()
    var
        GLAccount: Record "G/L Account";
        AccountNo: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Using a GET request to retrieve dimension lines without a filter fails
        LibraryGraphJournalLines.Initialize;

        AccountNo := LibraryGraphJournalLines.CreateAccount;
        GLAccount.Get(AccountNo);

        // [GIVEN] a Target URL without filters
        TargetURL := CreateDimensionLinesURLWithFilter(GLAccount.Id);

        // [WHEN] we GET from the web service
        // [THEN] the request fails
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDimensionLinesFailsWithNonSupportedEntity()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Using a GET request to retrieve dimension lines with a random entity fails
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a Target URL without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);

        // [WHEN] we GET from the web service
        // [THEN] the request fails
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyDimensionLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        JournalName: Code[10];
        CustomerPaymentsGUID: Guid;
        DimensionGUID: Guid;
        LineNo: Integer;
        LineJSON: array[2] of Text;
        DimensionCode: Code[20];
        DimensionValueCode: array[2] of Code[20];
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a dimension line, use a PATCH method to change it and then verify the changes
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateCustomerPaymentsJournal;

        // [GIVEN] a customer payment in the General Journal Table
        LineNo := LibraryGraphJournalLines.GetNextCustomerPaymentNo(JournalName);
        CustomerPaymentsGUID := CreateCustomerPayment(JournalName);

        // [GIVEN] 2 dimension json texts
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode := Dimension.Code;
        DimensionGUID := Dimension.Id;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode[1] := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode[2] := DimensionValue.Code;
        LineJSON[1] := CreateDimensionJSON(CustomerPaymentsGUID, DimensionCode, DimensionValueCode[1]);

        // [GIVEN] a json text with the new dimension value
        LineJSON[2] := LibraryGraphMgt.AddPropertytoJSON('', DimensionValueCodeNameTxt, DimensionValueCode[2]);
        Commit;

        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[1], ResponseText);

        // [WHEN] we PATCH the JSON to the web service, with the corresponding keys
        ResponseText := '';
        TargetURL := CreateDimensionLinesURLWithKeys(CustomerPaymentsGUID, DimensionGUID);
        LibraryGraphMgt.PatchToWebService(TargetURL, LineJSON[2], ResponseText);

        // [THEN] the dimension lines in the customer payment should have the values that were given
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        VerifyJSONContainsDimensionValues(ResponseText, DimensionCode, DimensionValueCode[2]);

        GenJournalLine.Reset;
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        Assert.IsTrue(
          DimensionSetIDContainsDimension(GenJournalLine."Dimension Set ID", DimensionCode, DimensionValueCode[2]),
          'The dimension line should exist in the SetID of the journal line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyOfDimensionCodeDoesntWork()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        JournalName: Code[10];
        CustomerPaymentsGUID: Guid;
        DimensionGUID: Guid;
        LineNo: Integer;
        LineJSON: array[2] of Text;
        DimensionCode: array[2] of Code[20];
        DimensionValueCode: array[2] of Code[20];
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Try to change the code of an existing dimension line
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateCustomerPaymentsJournal;

        // [GIVEN] a customer payment in the General Journal Table
        LineNo := LibraryGraphJournalLines.GetNextCustomerPaymentNo(JournalName);
        CustomerPaymentsGUID := CreateCustomerPayment(JournalName);

        // [GIVEN] 2 dimensions with dimension values
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode[1] := Dimension.Code;
        DimensionGUID := Dimension.Id;
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode[2] := Dimension.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode[1]);
        DimensionValueCode[1] := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode[2]);
        DimensionValueCode[2] := DimensionValue.Code;

        LineJSON[1] := CreateDimensionJSON(CustomerPaymentsGUID, DimensionCode[1], DimensionValueCode[1]);
        LineJSON[2] := CreateDimensionJSON(CustomerPaymentsGUID, DimensionCode[2], DimensionValueCode[2]);
        Commit;

        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON[1], ResponseText);

        // [WHEN] we PATCH the JSON to the web service, with the new dimension code
        ResponseText := '';
        TargetURL := CreateDimensionLinesURLWithKeys(CustomerPaymentsGUID, DimensionGUID);
        asserterror LibraryGraphMgt.PatchToWebService(TargetURL, LineJSON[2], ResponseText);

        // [THEN] the patch should fail and the dimension line should remain the same
        Assert.AreEqual('', ResponseText, 'The PATCH should fail.');

        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        Assert.IsTrue(
          DimensionSetIDContainsDimension(GenJournalLine."Dimension Set ID", DimensionCode[1], DimensionValueCode[1]),
          'The dimension line should exist in the SetID of the journal line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDimensionLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        JournalName: Code[10];
        CustomerPaymentsGUID: Guid;
        LineNo: Integer;
        LineJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a dimension line, use a DELETE method to remove it and then verify the deletion
        LibraryGraphJournalLines.Initialize;

        // [GIVEN] a journal
        JournalName := LibraryGraphJournalLines.CreateCustomerPaymentsJournal;

        // [GIVEN] a customer payment in the General Journal Table
        LineNo := LibraryGraphJournalLines.GetNextCustomerPaymentNo(JournalName);
        CustomerPaymentsGUID := CreateCustomerPayment(JournalName);

        // [GIVEN] a dimension line in the journal line
        LibraryDimension.CreateDimension(Dimension);
        DimensionValue.Reset;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LineJSON := CreateDimensionJSON(CustomerPaymentsGUID, Dimension.Code, DimensionValue.Code);
        Commit;

        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);

        // [WHEN] we DELETE the dimension line from the web service, with the corresponding keys
        TargetURL := CreateDimensionLinesURLWithKeys(CustomerPaymentsGUID, Dimension.Id);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the dimension line shouldn't exist in the table
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetFilter("Line No.", Format(LineNo));
        GenJournalLine.FindFirst;
        Assert.IsFalse(
          DimensionSetIDContainsDimension(GenJournalLine."Dimension Set ID", Dimension.Code, DimensionValue.Code),
          'The dimension line shouldn''t exist in the SetID of the journal line.');
    end;

    local procedure CreateDimensionJSON(ParentId: Guid; DimensionCode: Code[20]; DimensionValueCode: Code[20]): Text
    var
        LineJSON: Text;
    begin
        LineJSON := LibraryGraphMgt.AddPropertytoJSON('', ParentIdNameTxt, ParentId);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, DimensionCodeNameTxt, DimensionCode);
        LineJSON := LibraryGraphMgt.AddPropertytoJSON(LineJSON, DimensionValueCodeNameTxt, DimensionValueCode);

        exit(LineJSON);
    end;

    local procedure CreateCustomerPayment(JournalName: Code[10]): Guid
    var
        GenJournalLine: Record "Gen. Journal Line";
        LineNo: Integer;
        BlankGUID: Guid;
    begin
        LineNo := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, '', BlankGUID, '', BlankGUID, 0, '');
        GraphMgtCustomerPayments.SetCustomerPaymentsTemplateAndBatch(GenJournalLine, JournalName);
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        exit(GenJournalLine.Id);
    end;

    local procedure CreateJournalLine(JournalName: Code[10]): Guid
    var
        GenJournalLine: Record "Gen. Journal Line";
        LineNo: Integer;
    begin
        LineNo := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);
        GraphMgtJournalLines.SetJournalLineTemplateAndBatch(GenJournalLine, JournalName);
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst;
        exit(GenJournalLine.Id);
    end;

    local procedure CreateDimensionLinesURLWithFilter(ParentIDFilter: Guid): Text
    var
        TargetURL: Text;
        UrlFilter: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);

        UrlFilter := '$filter=parentId eq ' + LibraryGraphMgt.StripBrackets(Format(ParentIDFilter));

        if StrPos(TargetURL, '?') <> 0 then
            TargetURL := TargetURL + '&' + UrlFilter
        else
            TargetURL := TargetURL + '?' + UrlFilter;

        exit(TargetURL);
    end;

    local procedure CreateDimensionLinesURLWithKeys(ParentIDKey: Guid; IdKey: Guid): Text
    var
        TargetURL: Text;
        ServiceNameWithKeys: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Dimension Lines Entity", ServiceNameTxt);

        ServiceNameWithKeys :=
          ServiceNameTxt + '(parentId=' + LibraryGraphMgt.StripBrackets(Format(ParentIDKey)) +
          ',id=' + LibraryGraphMgt.StripBrackets(Format(IdKey)) + ')';

        TargetURL := LibraryGraphMgt.STRREPLACE(TargetURL, ServiceNameTxt, ServiceNameWithKeys);

        exit(TargetURL);
    end;

    local procedure VerifyJSONContainsDimensionValues(JSONTxt: Text; ExpectedDimensionCode: Text; ExpectedDimensionValueCode: Text)
    var
        DimensionCodeValue: Text;
        DimensionValueCodeValue: Text;
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(JSONTxt, DimensionCodeNameTxt, DimensionCodeValue), 'Could not find dimension code.');
        Assert.AreEqual(ExpectedDimensionCode, DimensionCodeValue, 'Dimension code does not match.');

        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(JSONTxt, DimensionValueCodeNameTxt, DimensionValueCodeValue),
          'Could not find dimension value code.');
        Assert.AreEqual(ExpectedDimensionValueCode, DimensionValueCodeValue, 'Dimension value code does not match.');
    end;

    local procedure DimensionSetIDContainsDimension(DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20]): Boolean
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.SetRange("Dimension Value Code", DimensionValueCode);

        exit(DimensionSetEntry.FindFirst);
    end;
}

