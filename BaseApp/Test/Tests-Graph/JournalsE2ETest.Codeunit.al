codeunit 135535 "Journals E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Journal]
    end;

    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAPIGeneralJournal: Codeunit "Library API - General Journal";
        Assert: Codeunit Assert;
        TypeHelper: Codeunit "Type Helper";
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
        ServiceNameTxt: Label 'journals';
        JournalNameTxt: Label 'code';
        JournalDescriptionNameTxt: Label 'displayName';
        IsInitialized: Boolean;
        JournalBalAccountIdTxt: Label 'balancingAccountId';
        JournalBalAccountNoTxt: Label 'balancingAccountNumber';

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalName: Code[10];
        JournalDescription: Text[50];
        JournalJSON: Text;
        JournalBalAccountNo: Code[20];
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create a Journal through a POST method and check if it was created
        // [GIVEN] a journal batch json
        Initialize;

        JournalJSON := CreateJournalJSON(JournalName, JournalDescription, JournalBalAccountNo);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Journal Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, JournalJSON, ResponseText);

        // [THEN] the response text should contain the journal information and the journal should exist
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        VerifyJSONContainsJournalValues(ResponseText, JournalName, JournalDescription, JournalBalAccountNo);

        Assert.IsTrue(
          GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalName),
          'The journal batch should exist in the table.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetJournals()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalNames: array[2] of Code[10];
        JournalJSON: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create journal batches and use a GET method to retrieve them
        // [GIVEN] 2 journal batches in the table
        Initialize;

        JournalNames[1] := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        JournalNames[2] := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");

        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalNames[1]);
        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalNames[2]);

        Commit();

        // [WHEN] we POST the JSON to the web service
        ResponseText := '';
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Journal Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 lines should exist in the response
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, JournalNameTxt, JournalNames[1], JournalNames[2], JournalJSON[1], JournalJSON[2]),
          'Could not find the lines in JSON');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalNames: array[2] of Code[10];
        JournalDescription: Text[50];
        JournalGUID: Guid;
        JournalJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
        JournalBalAccountNo: Code[20];
    begin
        // [SCENARIO] Create a Journal, use a PATCH method to change it and then verify the changes
        // [GIVEN] a journal batch the table
        Initialize;

        JournalNames[1] := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalNames[1]);
        GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalNames[1]);
        JournalGUID := GenJournalBatch.Id;

        // [GIVEN] a journal json
        JournalJSON := CreateJournalJSON(JournalNames[2], JournalDescription, JournalBalAccountNo);
        Commit();

        // [WHEN] we PATCH the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(JournalGUID, PAGE::"Journal Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, JournalJSON, ResponseText);

        // [THEN] the journal in the table should have the values that were given and the old name should not exist
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        VerifyJSONContainsJournalValues(ResponseText, JournalNames[2], JournalDescription, JournalBalAccountNo);

        Assert.IsFalse(
          GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalNames[1]),
          'The old journal name should not exist in the table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalName: Code[10];
        JournalGUID: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a Journal, use a DELETE method to remove it and then verify the deletion
        // [GIVEN] a journal batch in the table
        Initialize;

        JournalName := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalName);
        GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalName);
        JournalGUID := GenJournalBatch.Id;

        // [WHEN] we DELETE the journal line from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(JournalGUID, PAGE::"Journal Entity", ServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the Journal batch shouldn't exist in the table
        Assert.IsFalse(
          GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName, JournalName),
          'The journal batch should not exist in the table');
    end;

    local procedure CreateJournalJSON(var JournalName: Code[10]; var JournalDescription: Text[50]; var JournalBalAccountNo: Code[20]): Text
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalJSON: Text;
    begin
        JournalName := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        JournalDescription := LibraryUtility.GenerateGUID;
        JournalBalAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting;
        GLAccount.Get(JournalBalAccountNo);
        JournalJSON := LibraryGraphMgt.AddPropertytoJSON('', JournalNameTxt, JournalName);
        JournalJSON := LibraryGraphMgt.AddPropertytoJSON(JournalJSON, JournalDescriptionNameTxt, JournalDescription);
        JournalJSON := LibraryGraphMgt.AddPropertytoJSON(JournalJSON, JournalBalAccountIdTxt, TypeHelper.GetGuidAsString(GLAccount.Id));

        exit(JournalJSON);
    end;

    local procedure VerifyJSONContainsJournalValues(JSONTxt: Text; ExpectedJournalName: Text; ExpectedJournalDescription: Text; ExpectedJournalBalAccountNo: Code[20])
    var
        JournalNameValue: Text;
        JournalDecriptionValue: Text;
        JournalBalAccountNo: Text;
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(JSONTxt, JournalNameTxt, JournalNameValue), 'Could not find journal name.');
        Assert.AreEqual(ExpectedJournalName, JournalNameValue, 'Journal name does not match.');

        if ExpectedJournalDescription <> '' then begin
            Assert.IsTrue(
              LibraryGraphMgt.GetObjectIDFromJSON(JSONTxt, JournalDescriptionNameTxt, JournalDecriptionValue),
              'Could not find journal description.');
            Assert.AreEqual(ExpectedJournalDescription, JournalDecriptionValue, 'Journal description does not match.');
        end;

        if ExpectedJournalBalAccountNo <> '' then begin
            Assert.IsTrue(
              LibraryGraphMgt.GetObjectIDFromJSON(JSONTxt, JournalBalAccountNoTxt, JournalBalAccountNo),
              'Could not find journal description.');
            Assert.AreEqual(ExpectedJournalBalAccountNo, JournalBalAccountNo, 'Journal balancing account number does not match.');
        end;
    end;
}

