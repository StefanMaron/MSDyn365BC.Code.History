codeunit 135517 "Currency Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Currency]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'currencies';
        CurrencyPrefixTxt: Label 'GRAPH';
        EmptyJSONErr: Label 'The JSON must not be blank.';
        WrongPropertyValueErr: Label 'Incorrect property value for %1.';

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyIDandLastModifiedDateTime()
    var
        Currency: Record Currency;
        IntegrationRecord: Record "Integration Record";
        CurrencyCode: Text;
        CurrencyId: Guid;
    begin
        // [SCENARIO] Create a currency and verify it has Id and LastDateTimeModified.
        Initialize;

        // [GIVEN] a modified currency record
        CurrencyCode := CreateCurrency;

        // [WHEN] we retrieve the currency from the database
        Currency.Get(CurrencyCode);
        CurrencyId := Currency.Id;

        // [THEN] the currency should have an integration id and last date time modified
        IntegrationRecord.Get(CurrencyId);
        IntegrationRecord.TestField("Integration ID");
        Currency.TestField("Last Modified Date Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCurrencies()
    var
        CurrencyCode: array[2] of Text;
        CurrencyJSON: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
        "Count": Integer;
    begin
        // [SCENARIO] User can retrieve all Currency records from the Currencies API.
        Initialize;

        // [GIVEN] 2 currencies in the Currency Table
        for Count := 1 to 2 do
            CurrencyCode[Count] := CreateCurrency;

        // [WHEN] A GET request is made to the Currencies API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Currencies Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 item categories should exist in the response
        for Count := 1 to 2 do
            GetAndVerifyIDFromJSON(ResponseText, CurrencyCode[Count], CurrencyJSON[Count]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCurrency()
    var
        Currency: Record Currency;
        TempCurrency: Record Currency temporary;
        CurrencyJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a Currency through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a Currency JSON object to send to the service.
        CurrencyJSON := GetCurrencyJSON(TempCurrency);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Currencies Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, CurrencyJSON, ResponseText);

        // [THEN] The response text contains the Currency information.
        VerifyCurrencyProperties(ResponseText, TempCurrency);

        // [THEN] The Currency has been created in the database.
        Currency.Get(TempCurrency.Code);
        VerifyCurrencyProperties(ResponseText, Currency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyCurrency()
    var
        Currency: Record Currency;
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        CurrencyCode: Text;
    begin
        // [SCENARIO] User can modify a currency through a PATCH request.
        Initialize;

        // [GIVEN] A currency exists.
        CurrencyCode := CreateCurrency;
        Currency.Get(CurrencyCode);
        Currency.Description := LibraryUtility.GenerateGUID;
        RequestBody := GetCurrencyJSON(Currency);

        // [WHEN] The user makes a patch request to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Currency.Id, PAGE::"Currencies Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, ResponseText);

        // [THEN] The response text contains the new values.
        VerifyCurrencyProperties(ResponseText, Currency);

        // [THEN] The record in the database contains the new values.
        Currency.Get(Currency.Code);
        VerifyCurrencyProperties(ResponseText, Currency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteCurrency()
    var
        Currency: Record Currency;
        CurrencyCode: Text;
        TargetURL: Text;
        Responsetext: Text;
    begin
        // [SCENARIO] User can delete a currency by making a DELETE request.
        Initialize;

        // [GIVEN] A currency exists.
        CurrencyCode := CreateCurrency;
        Currency.Get(CurrencyCode);

        // [WHEN] The user makes a DELETE request to the endpoint for the currency.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Currency.Id, PAGE::"Currencies Entity", ServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', Responsetext);

        // [THEN] The response is empty.
        Assert.AreEqual('', Responsetext, 'DELETE response must be empty.');

        // [THEN] The currency is no longer in the database.
        Assert.IsFalse(Currency.Get(CurrencyCode), 'Currency must be deleted.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateCurrency(): Text
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Commit();

        exit(Currency.Code);
    end;

    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; CurrencyCode: Text; CurrencyJSON: Text)
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(ResponseText, 'code', CurrencyCode, CurrencyCode,
            CurrencyJSON, CurrencyJSON), 'Could not find the currency in JSON');
        LibraryGraphMgt.VerifyIDInJson(CurrencyJSON);
    end;

    local procedure GetNextCurrencyID(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.SetFilter(Code, StrSubstNo('%1*', CurrencyPrefixTxt));
        if Currency.FindLast then
            exit(IncStr(Currency.Code));

        exit(CopyStr(CurrencyPrefixTxt + '00001', 1, 10));
    end;

    local procedure GetCurrencyJSON(var Currency: Record Currency) CurrencyJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        if Currency.Code = '' then
            Currency.Code := GetNextCurrencyID;
        if Currency.Description = '' then
            Currency.Description := LibraryUtility.GenerateGUID;

        JSONManagement.AddJPropertyToJObject(JsonObject, 'code', Currency.Code);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'displayName', Currency.Description);

        CurrencyJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    local procedure VerifyCurrencyProperties(CurrencyJSON: Text; Currency: Record Currency)
    begin
        Assert.AreNotEqual('', CurrencyJSON, EmptyJSONErr);
        LibraryGraphMgt.VerifyIDInJson(CurrencyJSON);
        VerifyPropertyInJSON(CurrencyJSON, 'code', Currency.Code);
        VerifyPropertyInJSON(CurrencyJSON, 'displayName', Currency.Description);
    end;
}

