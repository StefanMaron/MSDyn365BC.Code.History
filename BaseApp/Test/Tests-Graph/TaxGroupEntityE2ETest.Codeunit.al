codeunit 135509 "Tax Group Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Tax Group]
    end;

    var
        ServiceNameTxt: Label 'taxGroups';
        LibraryERM: Codeunit "Library - ERM";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        EmptyJSONErr: Label 'The JSON should not be blank.';
        WrongPropertyValueErr: Label 'Incorrect property value for %1.';

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyIDandLastDateModified()
    var
        TempTaxGroupBuffer: Record "Tax Group Buffer" temporary;
        IntegrationRecord: Record "Integration Record";
        TaxGroupCode: Text;
        TaxGroupGUID: Text;
        BlankGuid: Guid;
        BlankDateTime: DateTime;
    begin
        // [SCENARIO] Create an Tax Group and verify it has Id and LastDateTimeModified
        // [GIVEN] a new Tax Group
        Initialize;
        CreateTaxGroup(TaxGroupCode, TaxGroupGUID);
        Commit();

        // [THEN] the Tax Group should have an integration id and last date time modified
        Assert.IsTrue(IntegrationRecord.Get(TaxGroupGUID), 'Could not find the integration record with Code ' + TaxGroupCode);
        Assert.AreNotEqual(IntegrationRecord."Integration ID", BlankGuid,
          'Integration record should not get the blank guid with Code ' + TaxGroupCode);
        TempTaxGroupBuffer.LoadRecords;
        TempTaxGroupBuffer.Get(TaxGroupGUID);
        Assert.AreNotEqual(TempTaxGroupBuffer."Last Modified DateTime", BlankDateTime, 'Last Modified Date Time should be updated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTaxGroups()
    var
        TaxGroupCode: array[2] of Text;
        TaxGroupId: Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create Tax Groups and use a GET method to retrieve them
        // [GIVEN] 2 Tax Groups in the Tax Group Table
        Initialize;
        CreateTaxGroup(TaxGroupCode[1], TaxGroupId);
        CreateTaxGroup(TaxGroupCode[2], TaxGroupId);
        Commit();

        // [WHEN] we GET all the Tax Groups from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Tax Group Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 Tax Groups should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, TaxGroupCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTaxGroup()
    var
        TaxGroupCode: Text;
        TaxGroupId: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve the Tax Group record from the Tax Group API.
        Initialize;

        // [GIVEN] A Tax Group exists in the Tax Group Table
        CreateTaxGroup(TaxGroupCode, TaxGroupId);
        Commit();

        // [WHEN] A GET request is made to the Tax Group API.
        TargetURL := LibraryGraphMgt.CreateTargetURL(TaxGroupId, PAGE::"Tax Group Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the Tax Group should exist in the response
        LibraryGraphMgt.VerifyGUIDFieldInJson(ResponseText, 'id', TaxGroupId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTaxGroup()
    var
        TaxGroupBuffer: Record "Tax Group Buffer";
        TaxGroupId: Text;
        ResponseText: Text;
        TargetURL: Text;
        TaxGroupJSON: Text;
    begin
        // [SCENARIO] Create a Tax Group through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a Tax Group JSON object to send to the service.
        TaxGroupBuffer.Init();
        TaxGroupBuffer.Code := LibraryUtility.GenerateRandomCode(TaxGroupBuffer.FieldNo(Code), DATABASE::"Tax Group Buffer");
        TaxGroupBuffer.Description := Format(CreateGuid);
        TaxGroupJSON := GetTaxGroupJSON(TaxGroupBuffer);
        Commit();

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Tax Group Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, TaxGroupJSON, ResponseText);

        // [THEN] The tax group has been created in the database.
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', TaxGroupId);
        VerifyTaxGroupProperties(ResponseText, TaxGroupId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyTaxGroup()
    var
        TaxGroupBuffer: Record "Tax Group Buffer";
        TaxGroupCode: Text;
        TaxGroupId: Text;
        ResponseText: Text;
        TargetURL: Text;
        TaxGroupJSON: Text;
    begin
        // [SCENARIO] User can modify a Tax Group through a PATCH request.
        Initialize;

        // [GIVEN] An Tax Group exists.
        CreateTaxGroup(TaxGroupCode, TaxGroupId);
        TaxGroupBuffer.Code := CopyStr(TaxGroupCode, 1, MaxStrLen(TaxGroupBuffer.Code));
        TaxGroupBuffer.Id := TaxGroupId;
        TaxGroupBuffer.Description := Format(CreateGuid);
        TaxGroupJSON := GetTaxGroupJSON(TaxGroupBuffer);
        Commit();

        // [WHEN] The user makes a patch request to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL(TaxGroupId, PAGE::"Tax Group Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, TaxGroupJSON, ResponseText);

        // [THEN] The record in the database contains the new values.
        LibraryGraphMgt.VerifyGUIDFieldInJson(ResponseText, 'id', TaxGroupId);

        // [THEN] The record in the database contains the new values.
        VerifyTaxGroupProperties(ResponseText, TaxGroupId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteTaxGroup()
    var
        TaxGroupCode: Text;
        TaxGroupId: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can delete a Tax Group by making a DELETE request.
        Initialize;

        // [GIVEN] A Tax Group exists.
        CreateTaxGroup(TaxGroupCode, TaxGroupId);
        Commit();

        // [WHEN] The user makes a DELETE request to the endpoint for the Tax Group.
        TargetURL := LibraryGraphMgt.CreateTargetURL(TaxGroupId, PAGE::"Tax Group Entity", ServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] The response is empty.
        Assert.AreEqual('', ResponseText, 'DELETE response should be empty.');

        // [THEN] The tax area is no longer in the database.
        VerifyTaxGroupWasDeleted(TaxGroupId);
    end;

    [Normal]
    local procedure CreateTaxGroup(var TaxGroupCode: Text; var TaxGroupId: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TaxGroup: Record "Tax Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if GeneralLedgerSetup.UseVat then begin
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
            TaxGroupCode := VATProductPostingGroup.Code;
            TaxGroupId := VATProductPostingGroup.Id;
        end else begin
            LibraryERM.CreateTaxGroup(TaxGroup);
            TaxGroupCode := TaxGroup.Code;
            TaxGroupId := TaxGroup.Id;
        end;
    end;

    [Normal]
    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; TaxCode: array[2] of Text)
    var
        TaxGroupJSON: array[2] of Text;
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(ResponseText, 'code', TaxCode[1], TaxCode[2], TaxGroupJSON[1], TaxGroupJSON[2]),
          'Could not find the TaxGroup in JSON');
        LibraryGraphMgt.VerifyIDInJson(TaxGroupJSON[1]);
        LibraryGraphMgt.VerifyIDInJson(TaxGroupJSON[2]);
    end;

    local procedure GetTaxGroupJSON(var TaxGroupBuffer: Record "Tax Group Buffer") TaxGroupJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'id', FormatGuid(TaxGroupBuffer.Id));
        JSONManagement.AddJPropertyToJObject(JsonObject, 'code', TaxGroupBuffer.Code);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'displayName', TaxGroupBuffer.Description);
        TaxGroupJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    local procedure VerifyTaxGroupProperties(TaxGroupJSON: Text; TaxGroupID: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxGroup: Record "Tax Group";
        ExpectedCode: Text;
        ExpectedDecritpion: Text;
    begin
        Assert.AreNotEqual('', TaxGroupJSON, EmptyJSONErr);
        LibraryGraphMgt.VerifyIDInJson(TaxGroupJSON);

        if GeneralLedgerSetup.UseVat then begin
            VATProductPostingGroup.SetRange(Id, TaxGroupID);
            Assert.IsTrue(VATProductPostingGroup.FindFirst, 'VAT Product Group was not created for given ID');
            ExpectedCode := VATProductPostingGroup.Code;
            ExpectedDecritpion := VATProductPostingGroup.Description;
        end else begin
            TaxGroup.SetFilter(Id, TaxGroupID);
            Assert.IsTrue(TaxGroup.FindFirst, 'Tax Group was not created for given ID');
            ExpectedCode := TaxGroup.Code;
            ExpectedDecritpion := TaxGroup.Description;
        end;

        VerifyPropertyInJSON(TaxGroupJSON, 'code', ExpectedCode);
        VerifyPropertyInJSON(TaxGroupJSON, 'displayName', ExpectedDecritpion);
    end;

    local procedure VerifyTaxGroupWasDeleted(TaxGroupId: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TaxGroup: Record "Tax Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if GeneralLedgerSetup.UseVat then begin
            VATProductPostingGroup.SetRange(Id, TaxGroupId);
            Assert.IsFalse(VATProductPostingGroup.FindFirst, 'VATProductPostingGroup should be deleted.');
        end else begin
            TaxGroup.SetRange(Id, TaxGroupId);
            Assert.IsFalse(TaxGroup.FindFirst, 'TaxGroup should be deleted.');
        end;
    end;

    local procedure FormatGuid(Value: Guid): Text
    begin
        exit(LowerCase(LibraryGraphMgt.StripBrackets(Value)));
    end;
}

