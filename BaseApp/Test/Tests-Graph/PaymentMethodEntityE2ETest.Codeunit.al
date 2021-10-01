#if not CLEAN18
codeunit 135518 "Payment Method Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Payment Method]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'paymentMethods';
        PaymentMethodPrefixTxt: Label 'GRAPH';
        EmptyJSONErr: Label 'The JSON should not be blank.';
        WrongPropertyValueErr: Label 'Incorrect property value for %1.';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPaymentMethods()
    var
        PaymentMethodCode: array[2] of Text;
        PaymentMethodJSON: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
        "Count": Integer;
    begin
        // [SCENARIO] User can retrieve all Payment Method records from the paymentMethods API.
        Initialize;

        // [GIVEN] 2 payment methods in the Payment Method Table
        for Count := 1 to 2 do
            PaymentMethodCode[Count] := CreatePaymentMethod;

        // [WHEN] A GET request is made to the Payment Method API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Payment Methods Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 Payment Method should exist in the response
        for Count := 1 to 2 do
            GetAndVerifyIDFromJSON(ResponseText, PaymentMethodCode[Count], PaymentMethodJSON[Count]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePaymentMethods()
    var
        PaymentMethod: Record "Payment Method";
        TempPaymentMethod: Record "Payment Method" temporary;
        PaymentMethodJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a Payment Method through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a Payment Method JSON object to send to the service.
        PaymentMethodJSON := GetPaymentMethodJSON(TempPaymentMethod);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Payment Methods Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, PaymentMethodJSON, ResponseText);

        // [THEN] The response text contains the Payment Method information.
        VerifyPaymentMethodProperties(ResponseText, TempPaymentMethod);

        // [THEN] The Payment Method has been created in the database.
        PaymentMethod.Get(TempPaymentMethod.Code);
        VerifyPaymentMethodProperties(ResponseText, PaymentMethod);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyPaymentMethods()
    var
        PaymentMethod: Record "Payment Method";
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        PaymentMethodCode: Text;
    begin
        // [SCENARIO] User can modify a Payment Method through a PATCH request.
        Initialize;

        // [GIVEN] A Payment Method exists.
        PaymentMethodCode := CreatePaymentMethod;
        PaymentMethod.Get(PaymentMethodCode);
        PaymentMethod.Description := LibraryUtility.GenerateGUID;
        RequestBody := GetPaymentMethodJSON(PaymentMethod);

        // [WHEN] The user makes a patch request to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL(PaymentMethod.SystemId, PAGE::"Payment Methods Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, ResponseText);

        // [THEN] The response text contains the new values.
        VerifyPaymentMethodProperties(ResponseText, PaymentMethod);

        // [THEN] The record in the database contains the new values.
        PaymentMethod.Get(PaymentMethod.Code);
        VerifyPaymentMethodProperties(ResponseText, PaymentMethod);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePaymentMethods()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodCode: Text;
        TargetURL: Text;
        Responsetext: Text;
    begin
        // [SCENARIO] User can delete a Payment Method by making a DELETE request.
        Initialize;

        // [GIVEN] An Payment Method exists.
        PaymentMethodCode := CreatePaymentMethod;
        PaymentMethod.Get(PaymentMethodCode);

        // [WHEN] The user makes a DELETE request to the endpoint for the Payment Method.
        TargetURL := LibraryGraphMgt.CreateTargetURL(PaymentMethod.SystemId, PAGE::"Payment Methods Entity", ServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', Responsetext);

        // [THEN] The response is empty.
        Assert.AreEqual('', Responsetext, 'DELETE response should be empty.');

        // [THEN] The Payment Method is no longer in the database.
        Assert.IsFalse(PaymentMethod.Get(PaymentMethodCode), 'Payment Method should be deleted.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreatePaymentMethod(): Text
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        Commit();

        exit(PaymentMethod.Code);
    end;

    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; PaymentMethodCode: Text; PaymentMethodJSON: Text)
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(ResponseText, 'code', PaymentMethodCode, PaymentMethodCode,
            PaymentMethodJSON, PaymentMethodJSON), 'Could not find the Payment Method in JSON');
        LibraryGraphMgt.VerifyIDInJson(PaymentMethodJSON);
    end;

    local procedure GetNextPaymentMethodID(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetFilter(Code, StrSubstNo('%1*', PaymentMethodPrefixTxt));
        if PaymentMethod.FindLast then
            exit(IncStr(PaymentMethod.Code));

        exit(CopyStr(PaymentMethodPrefixTxt + '00001', 1, 10));
    end;

    local procedure GetPaymentMethodJSON(var PaymentMethod: Record "Payment Method") PaymentMethodJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        if PaymentMethod.Code = '' then
            PaymentMethod.Code := GetNextPaymentMethodID;
        if PaymentMethod.Description = '' then
            PaymentMethod.Description := LibraryUtility.GenerateGUID;
        JSONManagement.AddJPropertyToJObject(JsonObject, 'code', PaymentMethod.Code);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'displayName', PaymentMethod.Description);
        PaymentMethodJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    local procedure VerifyPaymentMethodProperties(PaymentMethodJSON: Text; PaymentMethod: Record "Payment Method")
    begin
        Assert.AreNotEqual('', PaymentMethodJSON, EmptyJSONErr);
        LibraryGraphMgt.VerifyIDInJson(PaymentMethodJSON);
        VerifyPropertyInJSON(PaymentMethodJSON, 'code', PaymentMethod.Code);
        VerifyPropertyInJSON(PaymentMethodJSON, 'displayName', PaymentMethod.Description);
    end;
}
#endif
