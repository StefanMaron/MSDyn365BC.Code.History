codeunit 135507 "Company Info. Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Company Information]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'companyInformation';
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
    procedure TestGetCompanyInformationWithComplexType()
    var
        CompanyInformation: Record "Company Information";
        Response: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 204030] User can get the company information that has non-empty values for complex type field address.
        Initialize;

        // [GIVEN] The company information record exists and has values assigned to the fields contained in complex types.
        CompanyInformation.Get();

        // [WHEN] The user calls GET for the given Company Information.
        TargetURL := LibraryGraphMgt.CreateTargetURL(CompanyInformation.SystemId, PAGE::"Company Information Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(Response, TargetURL);

        // [THEN] The response text contains the Company Information.
        VerifyCompanyInformationProperties(Response, CompanyInformation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        ModifiedName: Text;
        RequestBody: Text;
        Response: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 204030] User can modify a company information through a PATCH request.
        Initialize;

        // [Given] A company information exists.
        CompanyInformation.Get();
        CompanyInformation.Name := LibraryUtility.GenerateGUID;
        ModifiedName := CompanyInformation.Name;
        RequestBody := GetSimpleCompanyInformationJSON(CompanyInformation);

        // [WHEN] The user makes a patch request to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL(CompanyInformation.SystemId, PAGE::"Company Information Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, Response);

        // [THEN] The response text contains the new values.
        VerifyPropertyInJSON(Response, 'displayName', ModifiedName);

        // [THEN] The record in the database contains the new values.
        CompanyInformation.Get();
        CompanyInformation.TestField(Name, ModifiedName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyCompanyInformationWithComplexType()
    var
        CompanyInformation: Record "Company Information";
        RequestBody: Text;
        Response: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 204030] User can modify a complex type in a company information through a PATCH request.
        Initialize;

        // [GIVEN] A company information record exists with an address.
        CompanyInformation.Get();
        CompanyInformation.Address := LibraryUtility.GenerateGUID;
        CompanyInformation."Address 2" := LibraryUtility.GenerateGUID;
        RequestBody := GetCompanyInformationWithAddressJSON(CompanyInformation);

        // [WHEN] The user makes a patch request to the service and specifies address fields.
        TargetURL := LibraryGraphMgt.CreateTargetURL(CompanyInformation.SystemId, PAGE::"Company Information Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, Response);

        // [THEN] The response contains the new values.
        VerifyAddressIncompanyInformation(Response, CompanyInformation);

        // [THEN] The company information in the database contains the updated values.
        CompanyInformation.Get();
        VerifyAddressIncompanyInformation(Response, CompanyInformation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveComplexTypeFromCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        TargetURL: Text;
        RequestBody: Text;
        Response: Text;
    begin
        // [SCENARIO 204030] User can clear the values encapsulated in a complex type by specifying null.
        Initialize;

        // [GIVEN] A company information exists with an address.
        CompanyInformation.Get();
        RequestBody := '{ "address" : null }';

        // [WHEN] A user makes a PATCH request to the company information.
        TargetURL := LibraryGraphMgt.CreateTargetURL(CompanyInformation.SystemId, PAGE::"Company Information Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, Response);

        // [THEN] The response contains the updated company information.
        CompanyInformation.Get();
        VerifyAddressIncompanyInformation(Response, CompanyInformation);

        // [THEN] The company information address fields are empty.
        CompanyInformation.TestField(Address, '');
        CompanyInformation.TestField("Address 2", '');
        CompanyInformation.TestField(City, '');
        CompanyInformation.TestField(County, '');
        CompanyInformation.TestField("Country/Region Code", '');
        CompanyInformation.TestField("Post Code", '');
    end;

    local procedure VerifyCompanyInformationProperties(CompanyInformationJSON: Text; var CompanyInformation: Record "Company Information")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Assert.AreNotEqual('', CompanyInformationJSON, EmptyJSONErr);
        GeneralLedgerSetup.Get();

        VerifyPropertyInJSON(CompanyInformationJSON, 'displayName', CompanyInformation.Name);
        VerifyPropertyInJSON(CompanyInformationJSON, 'phoneNumber', CompanyInformation."Phone No.");
        VerifyPropertyInJSON(CompanyInformationJSON, 'faxNumber', CompanyInformation."Fax No.");
        VerifyPropertyInJSON(CompanyInformationJSON, 'email', CompanyInformation."E-Mail");
        VerifyPropertyInJSON(CompanyInformationJSON, 'website', CompanyInformation."Home Page");
        VerifyPropertyInJSON(CompanyInformationJSON, 'taxRegistrationNumber', CompanyInformation."VAT Registration No.");
        VerifyPropertyInJSON(CompanyInformationJSON, 'industry', CompanyInformation."Industrial Classification");
        VerifyPropertyInJSON(CompanyInformationJSON, 'currencyCode', GeneralLedgerSetup."LCY Code");
        VerifyAddressIncompanyInformation(CompanyInformationJSON, CompanyInformation);
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    local procedure VerifyAddressIncompanyInformation(CompanyInfoJSON: Text; var CompanyInformation: Record "Company Information")
    begin
        with CompanyInformation do
            LibraryGraphMgt.VerifyAddressProperties(CompanyInfoJSON, Address, "Address 2", City, County, "Country/Region Code", "Post Code");
    end;

    local procedure GetSimpleCompanyInformationJSON(var CompanyInformation: Record "Company Information") CompanyInformationJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JSONObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JSONObject);

        if CompanyInformation.Name = '' then
            CompanyInformation.Name := LibraryUtility.GenerateGUID;

        JSONManagement.AddJPropertyToJObject(JSONObject, 'displayName', CompanyInformation.Name);

        CompanyInformationJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure GetCompanyInformationWithAddressJSON(var CompanyInformation: Record "Company Information") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        AddressJSON: Text;
    begin
        JSON := GetSimpleCompanyInformationJSON(CompanyInformation);

        with CompanyInformation do
            GraphMgtComplexTypes.GetPostalAddressJSON(Address, "Address 2", City, County, "Country/Region Code", "Post Code", AddressJSON);

        JSON := LibraryGraphMgt.AddComplexTypetoJSON(JSON, 'address', AddressJSON);
    end;
}

