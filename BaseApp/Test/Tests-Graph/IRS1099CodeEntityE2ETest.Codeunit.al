#if not CLEAN25
codeunit 135519 "IRS 1099 Code Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [IRS 1099 Form-Box]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'irs1099Codes';
        IRS1099FormBoxPrefixTxt: Label 'GRAPH';
        EmptyJSONErr: Label 'The JSON should not be blank.';
        WrongPropertyValueErr: Label 'Incorrect property value for %1.';

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyIDandLastModifiedDateTime()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        IRS1099FormBoxCode: Text;
        IRS1099FormBoxId: Guid;
    begin
        // [SCENARIO] Create an IRS1099FormBox and verify it has Id and LastDateTimeModified.
        Initialize();

        // [GIVEN] a modified IRS1099FormBox record
        IRS1099FormBoxCode := CreateIRS1099FormBox();

        // [WHEN] we retrieve the IRS1099FormBox from the database
        IRS1099FormBox.Get(IRS1099FormBoxCode);
        IRS1099FormBoxId := IRS1099FormBox.SystemId;

        // [THEN] the IRS1099FormBox should have an integration id and last date time modified
        IRS1099FormBox.TestField("Last Modified Date Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIRS1099FormBox()
    var
        IRS1099FormBoxCode: array[2] of Text;
        IRS1099FormBoxJSON: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
        "Count": Integer;
    begin
        // [SCENARIO] User can retrieve all IRS1099FormBox records from the IRS1099FormBox API.
        Initialize();

        // [GIVEN] 2 irs1099Codes in the IRS1099FormBox Table
        for Count := 1 to 2 do
            IRS1099FormBoxCode[Count] := CreateIRS1099FormBox();

        // [WHEN] A GET request is made to the irs1099Codes API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"IRS 1099 Form-Box Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 iIRS1099FormBoxCodes should exist in the response
        for Count := 1 to 2 do
            GetAndVerifyIDFromJSON(ResponseText, IRS1099FormBoxCode[Count], IRS1099FormBoxJSON[Count]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateIRS1099FormBox()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        TempIRS1099FormBox: Record "IRS 1099 Form-Box" temporary;
        IRS1099FormBoxJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create an IRS1099FormBox through a POST method and check if it was created
        Initialize();

        // [GIVEN] The user has constructed an IRS1099FormBox JSON object to send to the service.
        IRS1099FormBoxJSON := GetIRS1099FormBoxJSON(TempIRS1099FormBox);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"IRS 1099 Form-Box Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, IRS1099FormBoxJSON, ResponseText);

        // [THEN] The response text contains the IRS1099FormBox information.
        VerifyIRS1099FormBoxProperties(ResponseText, TempIRS1099FormBox);

        // [THEN] The IRS1099FormBox has been created in the database.
        IRS1099FormBox.Get(TempIRS1099FormBox.Code);
        VerifyIRS1099FormBoxProperties(ResponseText, IRS1099FormBox);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyIRS1099FormBox()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        IRS1099FormBoxCode: Text;
    begin
        // [SCENARIO] User can modify an IRS1099FormBox through a PATCH request.
        Initialize();

        // [GIVEN] An IRS1099FormBox exists.
        IRS1099FormBoxCode := CreateIRS1099FormBox();
        IRS1099FormBox.Get(IRS1099FormBoxCode);
        IRS1099FormBox.Description := LibraryUtility.GenerateGUID();
        RequestBody := GetIRS1099FormBoxJSON(IRS1099FormBox);

        // [WHEN] The user makes a patch request to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL(IRS1099FormBox.SystemId, PAGE::"IRS 1099 Form-Box Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, ResponseText);

        // [THEN] The response text contains the new values.
        VerifyIRS1099FormBoxProperties(ResponseText, IRS1099FormBox);

        // [THEN] The record in the database contains the new values.
        IRS1099FormBox.Get(IRS1099FormBox.Code);
        VerifyIRS1099FormBoxProperties(ResponseText, IRS1099FormBox);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteIRS1099FormBox()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        IRS1099FormBoxCode: Text;
        TargetURL: Text;
        Responsetext: Text;
    begin
        // [SCENARIO] User can delete an IRS1099FormBox by making a DELETE request.
        Initialize();

        // [GIVEN] An IRS1099FormBox exists.
        IRS1099FormBoxCode := CreateIRS1099FormBox();
        IRS1099FormBox.Get(IRS1099FormBoxCode);

        // [WHEN] The user makes a DELETE request to the endpoint for the IRS1099FormBox.
        TargetURL := LibraryGraphMgt.CreateTargetURL(IRS1099FormBox.SystemId, PAGE::"IRS 1099 Form-Box Entity", ServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', Responsetext);

        // [THEN] The response is empty.
        Assert.AreEqual('', Responsetext, 'DELETE response should be empty.');

        // [THEN] The IRS1099FormBox is no longer in the database.
        Assert.IsFalse(IRS1099FormBox.Get(IRS1099FormBoxCode), 'IRS1099FormBox should be deleted.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; IRS1099FormBoxCode: Text; IRS1099FormBoxJSON: Text)
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(ResponseText, 'code', IRS1099FormBoxCode, IRS1099FormBoxCode,
            IRS1099FormBoxJSON, IRS1099FormBoxJSON), 'Could not find the irs1099FormCode in JSON');
        LibraryGraphMgt.VerifyIDInJson(IRS1099FormBoxJSON);
    end;

    local procedure GetNextIRS1099FormBoxID(): Code[10]
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.SetFilter(Code, StrSubstNo('%1*', IRS1099FormBoxPrefixTxt));
        if IRS1099FormBox.FindLast() then
            exit(IncStr(IRS1099FormBox.Code));

        exit(IRS1099FormBoxPrefixTxt + '00001');
    end;

    local procedure GetIRS1099FormBoxJSON(var IRS1099FormBox: Record "IRS 1099 Form-Box") IRS1099FormBoxJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        if IRS1099FormBox.Code = '' then
            IRS1099FormBox.Code := GetNextIRS1099FormBoxID();
        if IRS1099FormBox.Description = '' then
            IRS1099FormBox.Description := LibraryUtility.GenerateGUID();

        JSONManagement.AddJPropertyToJObject(JsonObject, 'code', IRS1099FormBox.Code);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'displayName', IRS1099FormBox.Description);

        IRS1099FormBoxJSON := JSONManagement.WriteObjectToString();
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    local procedure VerifyIRS1099FormBoxProperties(IRS1099FormBoxJSON: Text; IRS1099FormBox: Record "IRS 1099 Form-Box")
    begin
        Assert.AreNotEqual('', IRS1099FormBoxJSON, EmptyJSONErr);
        LibraryGraphMgt.VerifyIDInJson(IRS1099FormBoxJSON);
        VerifyPropertyInJSON(IRS1099FormBoxJSON, 'code', IRS1099FormBox.Code);
        VerifyPropertyInJSON(IRS1099FormBoxJSON, 'displayName', IRS1099FormBox.Description);
    end;

    local procedure CreateIRS1099FormBox(): Text
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.Init();
        IRS1099FormBox.Validate(Code, GetNextIRS1099FormBoxID());
        IRS1099FormBox.Insert(true);

        Commit();

        exit(IRS1099FormBox.Code);
    end;
}
#endif