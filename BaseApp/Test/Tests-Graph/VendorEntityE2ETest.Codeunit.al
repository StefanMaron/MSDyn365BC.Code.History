codeunit 135503 "Vendor Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Vendor]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'vendors';
        VendorKeyPrefixTxt: Label 'GRAPHVENDOR';
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
    procedure TestGetSimpleVendor()
    var
        Vendor: Record Vendor;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 201343] User can get a simple vendor with a GET request to the service.
        Initialize;

        // [GIVEN] A vendor exists in the system.
        CreateSimpleVendor(Vendor);

        // [WHEN] The user makes a GET request for a given Vendor.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Vendor.Id, PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response text contains the vendor information.
        VerifyVendorSimpleProperties(ResponseText, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorWithComplexType()
    var
        Vendor: Record Vendor;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 201343] User can get a vendor that has non-empty values for complex type fields.
        Initialize;

        // [GIVEN] A vendor exists and has values assigned to some of the fields contained in complex types.
        CreateVendorWithAddress(Vendor);

        // [WHEN] The user calls GET for the given Vendor.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Vendor.Id, PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response text contains the Vendor information.
        VerifyVendorSimpleProperties(ResponseText, Vendor);
        VerifyVendorAddress(ResponseText, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSimpleVendor()
    var
        Vendor: Record Vendor;
        TempVendor: Record Vendor temporary;
        VendorJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 201343] Create an vendor through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed a simple vendor JSON object to send to the service.
        VendorJSON := GetSimpleVendorJSON(TempVendor);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, VendorJSON, ResponseText);

        // [THEN] The response text contains the vendor information.
        VerifyVendorSimpleProperties(ResponseText, TempVendor);

        // [THEN] The vendor has been created in the database.
        Vendor.Get(TempVendor."No.");
        VerifyVendorSimpleProperties(ResponseText, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateVendorWithComplexType()
    var
        Vendor: Record Vendor;
        VendorWithComplexTypeJSON: Text;
        TargetURL: Text;
        ResponseTxt: Text;
    begin
        // [SCENARIO 201343] Create a vendor with a complex type through a POST method and check if it was created
        Initialize;

        // [GIVEN] A payment term
        Commit();

        // [GIVEN] A JSON text with an vendor that has the Address as a property
        VendorWithComplexTypeJSON := GetVendorWithAddressJSON(Vendor);

        // [WHEN] The user posts the consructed object to the vendor entity endpoint.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, VendorWithComplexTypeJSON, ResponseTxt);

        // [THEN] The response contains the values of the vendor created.
        VerifyVendorSimpleProperties(ResponseTxt, Vendor);
        VerifyVendorAddress(ResponseTxt, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateVendorWithTemplate()
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        TempVendor: Record Vendor temporary;
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [Template]
        // [SCENARIO 201343] User can create a new vendor and have the system apply a template.
        Initialize;
        LibraryInventory.CreatePaymentTerms(PaymentTerms);
        LibraryInventory.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] A template selection rule exists to set the payment terms based on the payment method.
        with Vendor do
            LibraryGraphMgt.CreateSimpleTemplateSelectionRule(ConfigTmplSelectionRules, PAGE::"Vendor Entity", DATABASE::Vendor,
              FieldNo("Payment Method Code"), PaymentMethod.Code,
              FieldNo("Payment Terms Code"), PaymentTerms.Code);

        // [GIVEN] The user has constructed a vendor object containing a templated payment method code.
        CreateSimpleVendor(TempVendor);
        TempVendor."Payment Method Code" := PaymentMethod.Code;

        RequestBody := GetSimpleVendorJSON(TempVendor);
        RequestBody := LibraryGraphMgt.AddPropertytoJSON(RequestBody, 'paymentMethodId', PaymentMethod.Id);
        RequestBody := LibraryGraphMgt.AddPropertytoJSON(RequestBody, 'paymentTermsId', PaymentTerms.Id);

        // [WHEN] The user sends the request to the endpoint in a POST request.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, RequestBody, ResponseText);

        // [THEN] The response contains the sent vendor values and also the updated Payment Terms
        TempVendor."Payment Terms Code" := PaymentTerms.Code;
        VerifyVendorSimpleProperties(ResponseText, TempVendor);
        VerifyVendorAddress(ResponseText, Vendor);

        // [THEN] The vendor is created in the database with the payment terms set from the template.
        Vendor.Get(TempVendor."No.");
        VerifyVendorSimpleProperties(ResponseText, Vendor);
        VerifyVendorAddress(ResponseText, Vendor);

        // Cleanup
        ConfigTmplSelectionRules.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyVendor()
    var
        Vendor: Record Vendor;
        TempVendor: Record Vendor temporary;
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 201343] User can modify a vendor through a PATCH request.
        Initialize;

        // [GIVEN] A vendor exists.
        CreateSimpleVendor(Vendor);
        TempVendor.TransferFields(Vendor);
        TempVendor.Name := LibraryUtility.GenerateGUID;
        RequestBody := GetSimpleVendorJSON(TempVendor);

        // [WHEN] The user makes a patch request to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Vendor.Id, PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, ResponseText);

        // [THEN] The response text contains the new values.
        VerifyVendorSimpleProperties(ResponseText, TempVendor);

        // [THEN] The record in the database contains the new values.
        Vendor.Get(Vendor."No.");
        VerifyVendorSimpleProperties(ResponseText, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorModifyWithComplexTypes()
    var
        Vendor: Record Vendor;
        TempVendor: Record Vendor temporary;
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 201343] User can modify a complex type in a vendor through a PATCH request.
        Initialize;

        // [GIVEN] A vendor exists with an address.
        CreateVendorWithAddress(Vendor);
        TempVendor.TransferFields(Vendor);

        // Create modified address
        RequestBody := GetVendorWithAddressJSON(TempVendor);

        // [WHEN] The user makes a patch request to the service and specifies Address field.
        Commit();        // Need to commit transaction to unlock integration record table.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Vendor.Id, PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, ResponseText);

        // [THEN] The response contains the new values.
        VerifyVendorSimpleProperties(ResponseText, TempVendor);
        VerifyVendorAddress(ResponseText, Vendor);

        // [THEN] The vendor in the database contains the updated values.
        Vendor.Get(Vendor."No.");
        VerifyVendorAddress(ResponseText, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveComplexTypeFromVendor()
    var
        Vendor: Record Vendor;
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 201343] User can clear the values encapsulated in a complex type by specifying null.
        Initialize;

        // [GIVEN] A Vendor exists with a specific address.
        CreateVendorWithAddress(Vendor);
        RequestBody := '{ "address" : null }';

        // [WHEN] A user makes a PATCH request to the specific vendor.
        Commit(); // Need to commit in order to unlock integration record table.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Vendor.Id, PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, ResponseText);

        // [THEN] The response contains the updated vendor.
        Vendor.Get(Vendor."No.");
        VerifyVendorSimpleProperties(ResponseText, Vendor);

        // [THEN] The Vendor's address
        VerifyVendorAddress(ResponseText, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteVendor()
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
        TargetURL: Text;
        Responsetext: Text;
    begin
        // [SCENARIO 201343] User can delete a vendor by making a DELETE request.
        Initialize;

        // [GIVEN] A vendor exists.
        CreateSimpleVendor(Vendor);
        VendorNo := Vendor."No.";

        // [WHEN] The user makes a DELETE request to the endpoint for the vendor.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Vendor.Id, PAGE::"Vendor Entity", ServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', Responsetext);

        // [THEN] The response is empty.
        Assert.AreEqual('', Responsetext, 'DELETE response should be empty.');

        // [THEN] The vendor is no longer in the database.
        Assert.IsFalse(Vendor.Get(VendorNo), 'Vendor should be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDemoDataIntegrationRecordIdsForVendors()
    var
        IntegrationRecord: Record "Integration Record";
        Vendor: Record Vendor;
        BlankGuid: Guid;
    begin
        // [SCENARIO 184722] Integration record ids should be set correctly.
        // [GIVEN] We have demo data applied correctly
        Vendor.SetRange(Id, BlankGuid);
        Assert.IsFalse(Vendor.FindFirst, 'No vendors should have null id');

        // [WHEN] We look through all vendors.
        // [THEN] The integration record for the vendor should have the same record id.
        Vendor.Reset();
        if Vendor.Find('-') then begin
            repeat
                Assert.IsTrue(IntegrationRecord.Get(Vendor.SystemId), 'The vendor id should exist in the integration record table');
                Assert.AreEqual(
                  IntegrationRecord."Record ID", Vendor.RecordId,
                  'The integration record for the vendor should have the same record id as the vendor.');
            until Vendor.Next <= 0
        end;
    end;

    local procedure CreateSimpleVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor."No." := GetNextVendorID;
        Vendor.Name := LibraryUtility.GenerateGUID;
        Vendor.Insert(true);

        Commit();
    end;

    local procedure CreateVendorWithAddress(var Vendor: Record Vendor)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.FindFirst;
        CreateSimpleVendor(Vendor);
        Vendor.Address := LibraryUtility.GenerateGUID;
        Vendor."Address 2" := LibraryUtility.GenerateGUID;
        Vendor.City := LibraryUtility.GenerateGUID;
        Vendor.County := LibraryUtility.GenerateGUID;
        Vendor."Country/Region Code" := CountryRegion.Code;
        Vendor.Modify(true);
    end;

    local procedure GetNextVendorID(): Text[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetFilter("No.", StrSubstNo('%1*', VendorKeyPrefixTxt));
        if Vendor.FindLast then
            exit(IncStr(Vendor."No."));

        exit(CopyStr(VendorKeyPrefixTxt + '00001', 1, 20));
    end;

    local procedure GetSimpleVendorJSON(var Vendor: Record Vendor) SimpleVendorJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        if Vendor."No." = '' then
            Vendor."No." := GetNextVendorID;
        if Vendor.Name = '' then
            Vendor.Name := LibraryUtility.GenerateGUID;
        JSONManagement.AddJPropertyToJObject(JsonObject, 'number', Vendor."No.");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'displayName', Vendor.Name);
        SimpleVendorJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure VerifyVendorSimpleProperties(VendorJSON: Text; Vendor: Record Vendor)
    begin
        Assert.AreNotEqual('', VendorJSON, EmptyJSONErr);
        LibraryGraphMgt.VerifyIDInJson(VendorJSON);
        VerifyPropertyInJSON(VendorJSON, 'number', Vendor."No.");
        VerifyPropertyInJSON(VendorJSON, 'displayName', Vendor.Name);
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    local procedure VerifyVendorAddress(VendorJSON: Text; var Vendor: Record Vendor)
    begin
        with Vendor do
            LibraryGraphMgt.VerifyAddressProperties(VendorJSON, Address, "Address 2", City, County, "Country/Region Code", "Post Code");
    end;

    local procedure GetVendorWithAddressJSON(var Vendor: Record Vendor) Json: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        AddressJson: Text;
    begin
        Json := GetSimpleVendorJSON(Vendor);
        with Vendor do
            GraphMgtComplexTypes.GetPostalAddressJSON(Address, "Address 2", City, County, "Country/Region Code", "Post Code", AddressJson);
        Json := LibraryGraphMgt.AddComplexTypetoJSON(Json, 'address', AddressJson);
    end;
}

