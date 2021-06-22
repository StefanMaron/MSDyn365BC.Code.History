codeunit 134633 "Graph Collect Mgt CompanyInfo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Address]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestGetEmailAddress()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        EmptyAddress: Text;
        ExpectedAddress: Text;
        RetrievedAddress: Text;
        AddressesString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        ExpectedAddress := LibraryUtility.GenerateGUID;
        AddressesString := '[{' +
          '"address": "' + ExpectedAddress + '",' +
          '"name": "name",' +
          '"type": "' + Type + '"' +
          '}]';

        // Exercise
        GraphMgtCompanyInfo.GetEmailAddress(AddressesString, Type, RetrievedAddress);
        GraphMgtCompanyInfo.GetEmailAddress(AddressesString, Type + 'x', EmptyAddress);

        // Verify
        Assert.AreEqual(ExpectedAddress, RetrievedAddress, 'Unexpected email address.');
        Assert.AreEqual('', EmptyAddress, 'Email should be empty for unexpected type.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPhoneNumber()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        Empty: Text;
        Expected: Text;
        Retrieved: Text;
        JsonString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        Expected := LibraryUtility.GenerateGUID;
        JsonString := '[{' +
          '"number": "' + Expected + '",' +
          '"type": "' + Type + '"' +
          '}]';

        // Exercise
        GraphMgtCompanyInfo.GetPhone(JsonString, Type, Retrieved);
        GraphMgtCompanyInfo.GetPhone(JsonString, Type + 'x', Empty);

        // Verify
        Assert.AreEqual(Expected, Retrieved, 'Unexpected phone number.');
        Assert.AreEqual('', Empty, 'Value should be empty for unexpected type.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPostalAddress()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        City: Text[30];
        Country: Code[10];
        PostalCode: Code[10];
        State: Text[30];
        Street1: Text[50];
        Street2: Text[50];
        JsonString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        JsonString := '[{' +
          '"city": "1",' +
          '"countryOrRegion": "2",' +
          '"postalCode": "3",' +
          '"postOfficeBox": "4",' +
          '"state": "5",' +
          '"street": "6",' +
          '"type": "' + Type + '"' +
          '}]';

        // Exercise & Verify
        GraphMgtCompanyInfo.GetPostalAddress(JsonString, Type + 'x', Street1, Street2, City, State, Country, PostalCode);
        Assert.AreEqual('', City, 'City should be empty.');
        Assert.AreEqual('', Country, 'Country should be empty.');
        Assert.AreEqual('', PostalCode, 'Post code should be empty.');
        Assert.AreEqual('', State, 'County should be empty.');
        Assert.AreEqual('', Street1, 'Address should be empty.');
        Assert.AreEqual('', Street2, 'Address 2 should be empty.');

        GraphMgtCompanyInfo.GetPostalAddress(JsonString, Type, Street1, Street2, City, State, Country, PostalCode);
        Assert.AreEqual('1', City, 'Unexpected value for City.');
        Assert.AreEqual('2', Country, 'Unexpected value for Country Code.');
        Assert.AreEqual('3', PostalCode, 'Unexpected value Post Code.');
        Assert.AreEqual('5', State, 'Unexpected value for County.');
        Assert.AreEqual('6', Street1, 'Unexpected value for Address.');
        Assert.AreEqual('', Street2, 'Unexpected value for Address 2.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetSocialNetworks()
    var
        TempO365SocialNetwork: Record "O365 Social Network" temporary;
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        SocialLinksJSON: Text;
    begin
        // Setup
        CreateSocialNetworks(TempO365SocialNetwork);

        // Execute
        GraphMgtCompanyInfo.GetSocialNetworksJSON(TempO365SocialNetwork, SocialLinksJSON);

        // Verify
        VerifyMatchingSocialNetworksJSON(TempO365SocialNetwork, SocialLinksJSON);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetWebsite()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        Expected: Text;
        Retrieved: Text;
        JsonString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        Expected := LibraryUtility.GenerateGUID;
        JsonString := '{' +
          '"address": "' + Expected + '",' +
          '"type": "' + Type + '"' +
          '}';

        // Exercise
        GraphMgtCompanyInfo.GetWebsite(JsonString, Retrieved);

        // Verify
        Assert.AreEqual(Expected, Retrieved, 'Unexpected website.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasEmailAddress()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        AddressString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        AddressString := '[{' +
          '"address": "address@example.com",' +
          '"name": "name",' +
          '"type": "' + Type + '"' +
          '}]';

        // Exercise and Verify
        Assert.IsTrue(GraphMgtCompanyInfo.HasEmailAddress(AddressString, Type), 'Email address should be present.');
        Assert.IsFalse(GraphMgtCompanyInfo.HasEmailAddress(AddressString, Type + 'x'), 'Email address should not be present.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasPhoneNumber()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        PhonesString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        PhonesString := '[{' +
          '"number": "555-555-5555",' +
          '"type": "' + Type + '"' +
          '}]';

        // Exercise and Verify
        Assert.IsTrue(GraphMgtCompanyInfo.HasPhoneNumber(PhonesString, Type), 'Phone number should be present.');
        Assert.IsFalse(GraphMgtCompanyInfo.HasPhoneNumber(PhonesString, Type + 'x'), 'Phone number should not be present.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasPostalAddress()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        AddressString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        AddressString := '[{' +
          '"city": "1",' +
          '"countryOrRegion": "US",' +
          '"postalCode": "2",' +
          '"postOfficeBox": null,' +
          '"state": "3",' +
          '"street": "4",' +
          '"type": "' + Type + '"' +
          '}]';

        // Exercise and Verify
        Assert.IsTrue(GraphMgtCompanyInfo.HasPostalAddress(AddressString, Type), 'Postal address should be present.');
        Assert.IsFalse(GraphMgtCompanyInfo.HasPostalAddress(AddressString, Type + 'x'), 'Postal address should not be present.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostalAddressToJSON()
    var
        CompanyInformation: Record "Company Information";
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        PostalAddressJSON: Text;
    begin
        // Setup
        GetCompanyWithAddress(CompanyInformation);

        // Execute
        PostalAddressJSON := GraphMgtCompanyInfo.PostalAddressToJSON(CompanyInformation);

        // Verify
        VerifyMatchingPostalAddress(PostalAddressJSON, CompanyInformation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetPostalAddress()
    var
        CompanyInformation: Record "Company Information";
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        PostalAddressJSON: Text;
    begin
        // Setup
        GetCompanyWithAddress(CompanyInformation);
        PostalAddressJSON := GraphMgtCompanyInfo.PostalAddressToJSON(CompanyInformation);

        // Execute
        GraphMgtCompanyInfo.ProcessComplexTypes(CompanyInformation, PostalAddressJSON);
        CompanyInformation.Modify(true);

        // Verify
        VerifyMatchingPostalAddress(PostalAddressJSON, CompanyInformation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetBlankPostalAddress()
    var
        CompanyInformation: Record "Company Information";
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
    begin
        // Setup
        GetCompanyWithAddress(CompanyInformation);
        CompanyInformation.Modify(true);

        // Execute
        GraphMgtCompanyInfo.ProcessComplexTypes(CompanyInformation, 'null');
        CompanyInformation.Modify(true);

        // Verify
        CompanyInformation.TestField(Address, '');
        CompanyInformation.TestField("Address 2", '');
        CompanyInformation.TestField(City, '');
        CompanyInformation.TestField(County, '');
        CompanyInformation.TestField("Country/Region Code", '');
        CompanyInformation.TestField("Post Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetInvalidPostalAddress()
    var
        CompanyInformation: Record "Company Information";
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        InvalidCountryCode: Code[10];
        PostalAddressJSON: Text;
        ActualError: Text;
    begin
        // Setup
        GetCompanyWithAddress(CompanyInformation);
        InvalidCountryCode := 'zq-v1'; // Invalid country/region code
        CompanyInformation."Country/Region Code" := InvalidCountryCode;
        PostalAddressJSON := GraphMgtCompanyInfo.PostalAddressToJSON(CompanyInformation);

        // Execute
        CompanyInformation.FindFirst;
        asserterror GraphMgtCompanyInfo.ProcessComplexTypes(CompanyInformation, PostalAddressJSON);
        ActualError := GetLastErrorText;

        // Verify
        asserterror CompanyInformation.Validate("Country/Region Code", InvalidCountryCode);
        Assert.ExpectedError(ActualError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetSamePostalAddress()
    var
        CompanyInformation: Record "Company Information";
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        PostalAddressJSON: Text;
    begin
        // Setup
        GetCompanyWithAddress(CompanyInformation);
        CompanyInformation.Modify(true);
        PostalAddressJSON := GraphMgtCompanyInfo.PostalAddressToJSON(CompanyInformation);

        // Execute
        GraphMgtCompanyInfo.ProcessComplexTypes(CompanyInformation, PostalAddressJSON);

        // Verify
        VerifyMatchingPostalAddress(PostalAddressJSON, CompanyInformation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetSecondPostalAddress()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        PostalAddressJSON: Text;
        ActualAddress1: Text[50];
        ActualAddress2: Text[50];
        ActualCity: Text[30];
        ActualCounty: Text[30];
        ActualCountryCode: Code[10];
        ActualPostCode: Code[20];
    begin
        // Setup
        PostalAddressJSON := GraphMgtCompanyInfo.UpdatePostalAddressJson('', 'Shipping', 'A', 'B', 'C', 'D', 'E', 'F');

        // Execute
        PostalAddressJSON := GraphMgtCompanyInfo.UpdatePostalAddressJson(PostalAddressJSON, 'Business', '1', '2', '3', '4', '5', '6');

        // Verify
        GraphMgtCompanyInfo.GetPostalAddress(PostalAddressJSON, 'Business',
          ActualAddress1, ActualAddress2, ActualCity, ActualCounty, ActualCountryCode, ActualPostCode);
        Assert.AreEqual('1', ActualAddress1, 'Unexpected JSON value.');
        Assert.AreEqual('2', ActualAddress2, 'Unexpected JSON value.');
        Assert.AreEqual('3', ActualCity, 'Unexpected JSON value.');
        Assert.AreEqual('4', ActualCounty, 'Unexpected JSON value.');
        Assert.AreEqual('5', ActualCountryCode, 'Unexpected JSON value.');
        Assert.AreEqual('6', ActualPostCode, 'Unexpected JSON value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetSecondPostalAddressBlank()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        PostalAddressJSON: Text;
        ActualAddress1: Text[50];
        ActualAddress2: Text[50];
        ActualCity: Text[30];
        ActualCounty: Text[30];
        ActualCountryCode: Code[10];
        ActualPostCode: Code[20];
    begin
        // Setting a postal address blank in the JSON array should not affect
        // the other addresses that are in the collection.

        // Setup
        PostalAddressJSON := GraphMgtCompanyInfo.UpdatePostalAddressJson('', 'Business', '1', '2', '3', '4', '5', '6');

        // Execute
        PostalAddressJSON := GraphMgtCompanyInfo.UpdatePostalAddressJson(PostalAddressJSON, 'Shipping', '', '', '', '', '', '');

        // Verify
        GraphMgtCompanyInfo.GetPostalAddress(PostalAddressJSON, 'Business',
          ActualAddress1, ActualAddress2, ActualCity, ActualCounty, ActualCountryCode, ActualPostCode);
        Assert.AreEqual('1', ActualAddress1, 'Unexpected JSON value.');
        Assert.AreEqual('2', ActualAddress2, 'Unexpected JSON value.');
        Assert.AreEqual('3', ActualCity, 'Unexpected JSON value.');
        Assert.AreEqual('4', ActualCounty, 'Unexpected JSON value.');
        Assert.AreEqual('5', ActualCountryCode, 'Unexpected JSON value.');
        Assert.AreEqual('6', ActualPostCode, 'Unexpected JSON value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressJson()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        ExpectedAddress: Text;
        RetrievedAddress: Text;
        AddressesString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        ExpectedAddress := LibraryUtility.GenerateGUID;
        AddressesString := '[{' +
          '"address": "OriginalAddress",' +
          '"name": "name",' +
          '"type": "Original"' +
          '}]';

        // Exercise
        AddressesString := GraphMgtCompanyInfo.UpdateEmailAddressJson(AddressesString, Type, ExpectedAddress);

        // Verify
        GraphMgtCompanyInfo.GetEmailAddress(AddressesString, Type, RetrievedAddress);
        Assert.AreEqual(ExpectedAddress, RetrievedAddress, 'Unexpected email address.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatePhoneJson()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        Expected: Text;
        Retrieved: Text;
        JsonString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        Expected := LibraryUtility.GenerateGUID;
        JsonString := '[{' +
          '"number": "12345",' +
          '"type": "Original"' +
          '}]';

        // Exercise
        JsonString := GraphMgtCompanyInfo.UpdatePhoneJson(JsonString, Type, Expected);

        // Verify
        GraphMgtCompanyInfo.GetPhone(JsonString, Type, Retrieved);
        Assert.AreEqual(Expected, Retrieved, 'Unexpected phone number.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatePostalAddressJson()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        AddressesString: Text;
        Type: Text;
        City: Text[30];
        Country: Code[10];
        PostalCode: Code[10];
        State: Text[30];
        Street1: Text[50];
        Street2: Text[50];
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        AddressesString := '[{' +
          '"city": "1",' +
          '"countryOrRegion": "US",' +
          '"postalCode": "2",' +
          '"postOfficeBox": null,' +
          '"state": "3",' +
          '"street": "4",' +
          '"type": "Original"' +
          '}]';

        // Exercise
        AddressesString := GraphMgtCompanyInfo.UpdatePostalAddressJson(AddressesString, Type, 'a', 'b', 'c', 'd', 'e', 'f');

        // Verify
        GraphMgtCompanyInfo.GetPostalAddress(AddressesString, Type, Street1, Street2, City, State, Country, PostalCode);
        Assert.AreEqual('a', Street1, 'Unexpected address.');
        Assert.AreEqual('b', Street2, 'Unexpected address 2.');
        Assert.AreEqual('c', City, 'Unexpected city.');
        Assert.AreEqual('d', State, 'Unexpected state.');
        Assert.AreEqual('E', Country, 'Unexpected country code.');
        Assert.AreEqual('F', PostalCode, 'Unexpected post code.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSocialNetworks()
    var
        TempO365SocialNetwork: Record "O365 Social Network" temporary;
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        SocialLinksJSON: Text;
    begin
        // Setup
        CreateSocialNetworks(TempO365SocialNetwork);

        // Execute
        GraphMgtCompanyInfo.GetSocialNetworksJSON(TempO365SocialNetwork, SocialLinksJSON);
        GraphMgtCompanyInfo.UpdateSocialNetworks(SocialLinksJSON);

        // Verify
        VerifyMatchingSocialNetworks(TempO365SocialNetwork);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateSocialNetworks()
    var
        O365SocialNetwork: Record "O365 Social Network";
        TempO365SocialNetwork: Record "O365 Social Network" temporary;
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        SocialLinksJSON: Text;
    begin
        // Setup
        CreateSocialNetworks(O365SocialNetwork);

        // Execute
        LoadSocialNetworks(TempO365SocialNetwork);
        TempO365SocialNetwork.FindFirst;
        TempO365SocialNetwork.Validate(URL, LibraryUtility.GenerateGUID);
        TempO365SocialNetwork.Modify();

        TempO365SocialNetwork.FindSet;
        GraphMgtCompanyInfo.GetSocialNetworksJSON(TempO365SocialNetwork, SocialLinksJSON);
        GraphMgtCompanyInfo.UpdateSocialNetworks(SocialLinksJSON);

        // Verify
        VerifyMatchingSocialNetworks(TempO365SocialNetwork);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteSocialNetworks()
    var
        O365SocialNetwork: Record "O365 Social Network";
        TempO365SocialNetwork: Record "O365 Social Network" temporary;
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        SocialLinksJSON: Text;
        DeletedLinks: array[2] of Code[20];
    begin
        // Setup
        CreateSocialNetworks(O365SocialNetwork);

        // Execute
        LoadSocialNetworks(TempO365SocialNetwork);

        TempO365SocialNetwork.SetFilter("Media Resources Ref", '<>%1', '');
        TempO365SocialNetwork.FindFirst;
        DeletedLinks[1] := TempO365SocialNetwork.Code;
        TempO365SocialNetwork.Delete();

        TempO365SocialNetwork.SetRange("Media Resources Ref", '');
        TempO365SocialNetwork.FindFirst;
        DeletedLinks[2] := TempO365SocialNetwork.Code;
        TempO365SocialNetwork.Delete();

        TempO365SocialNetwork.Reset();
        TempO365SocialNetwork.FindSet;
        GraphMgtCompanyInfo.GetSocialNetworksJSON(TempO365SocialNetwork, SocialLinksJSON);
        GraphMgtCompanyInfo.UpdateSocialNetworks(SocialLinksJSON);

        // Verify that social network with media resource is not deleted and has empty URL
        Assert.IsTrue(O365SocialNetwork.Get(DeletedLinks[1]), StrSubstNo('Social Network %1 has been deleted', DeletedLinks[1]));
        Assert.AreEqual('', O365SocialNetwork.URL, StrSubstNo('URL for Social Network %1 is wrong', DeletedLinks[1]));

        // Verify that social network without media resource is deleted
        Assert.IsFalse(O365SocialNetwork.Get(DeletedLinks[2]), StrSubstNo('Social Network %1 has not been deleted', DeletedLinks[2]));

        // Verify matching social networks with not empty URL
        VerifyMatchingSocialNetworks(TempO365SocialNetwork);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateWorkWebsiteJson()
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        Expected: Text[80];
        Retrieved: Text;
        JsonString: Text;
        Type: Text;
    begin
        // Setup
        Type := LibraryUtility.GenerateGUID;
        Expected := LibraryUtility.GenerateGUID;
        JsonString := '{' +
          '"address": "OriginalAddress",' +
          '"displayName": "name",' +
          '"type": "Original"' +
          '}';

        // Exercise
        JsonString := GraphMgtCompanyInfo.UpdateWorkWebsiteJson(JsonString, Type, Expected);

        // Verify
        GraphMgtCompanyInfo.GetWebsite(JsonString, Retrieved);
        Assert.AreEqual(Expected, Retrieved, 'Unexpected email address.');
    end;

    local procedure RandomCode10(): Code[10]
    begin
        exit(LibraryUtility.GenerateGUID);
    end;

    local procedure GetCompanyWithAddress(var CompanyInformation: Record "Company Information")
    var
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.FindFirst;
        CountryRegion.FindLast;
        CompanyInformation.Address := RandomCode10;
        CompanyInformation."Address 2" := RandomCode10;
        CompanyInformation.City := RandomCode10;
        CompanyInformation.County := RandomCode10;
        CompanyInformation."Country/Region Code" := CountryRegion.Code;
        CompanyInformation."Post Code" := RandomCode10;
    end;

    local procedure VerifyMatchingPostalAddress(ActualJSON: Text; CompanyInformation: Record "Company Information")
    var
        TempCompanyInfo: Record "Company Information" temporary;
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        // Apply complex type JSON to TempCompanyInfo
        RecRef.GetTable(TempCompanyInfo);
        with TempCompanyInfo do
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ActualJSON, RecRef,
              FieldNo(Address), FieldNo("Address 2"), FieldNo(City), FieldNo(County), FieldNo("Country/Region Code"), FieldNo("Post Code"));
        RecRef.SetTable(TempCompanyInfo);

        // Verify Company Information fields match TempCompanyInfo fields (which were from the JSON)
        with TempCompanyInfo do begin
            CompanyInformation.TestField(Address, Address);
            CompanyInformation.TestField("Address 2", "Address 2");
            CompanyInformation.TestField(City, City);
            CompanyInformation.TestField(County, County);
            CompanyInformation.TestField("Country/Region Code", "Country/Region Code");
            CompanyInformation.TestField("Post Code", "Post Code");
        end;
    end;

    local procedure VerifyMatchingSocialNetworks(var ExpectedO365SocialNetwork: Record "O365 Social Network")
    var
        ActualO365SocialNetwork: Record "O365 Social Network";
        ActualCount: Integer;
        ExpectedCount: Integer;
    begin
        ExpectedO365SocialNetwork.SetFilter(URL, '<>%1', '');
        ExpectedCount := ExpectedO365SocialNetwork.Count();
        ActualO365SocialNetwork.SetFilter(URL, '<>%1', '');
        ActualCount := ActualO365SocialNetwork.Count();
        Assert.AreEqual(ExpectedCount, ActualCount, 'Wrong count of social networks');
        if ExpectedCount > 0 then
            repeat
                ActualO365SocialNetwork.Get(CopyStr(ExpectedO365SocialNetwork.Name, 1, MaxStrLen(ExpectedO365SocialNetwork.Code)));
                ActualO365SocialNetwork.TestField(Name, ExpectedO365SocialNetwork.Name);
                ActualO365SocialNetwork.TestField(URL, ExpectedO365SocialNetwork.URL);
            until ExpectedO365SocialNetwork.Next = 0;
    end;

    local procedure VerifyMatchingSocialNetworksJSON(var ExpectedO365SocialNetwork: Record "O365 Social Network"; SocialLinksJSON: Text)
    var
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
    begin
        GraphMgtCompanyInfo.UpdateSocialNetworks(SocialLinksJSON);
        VerifyMatchingSocialNetworks(ExpectedO365SocialNetwork);
    end;

    local procedure CreateSocialNetworks(var O365SocialNetwork: Record "O365 Social Network")
    var
        i: Integer;
        "Count": Integer;
    begin
        Count := LibraryRandom.RandIntInRange(3, 5);
        for i := 1 to Count do begin
            O365SocialNetwork.Init();
            O365SocialNetwork.Name := LibraryUtility.GenerateGUID + LibraryUtility.GenerateGUID;
            O365SocialNetwork.Code := CopyStr(O365SocialNetwork.Name, 1, MaxStrLen(O365SocialNetwork.Code));
            O365SocialNetwork.Validate(URL, LibraryUtility.GenerateGUID);
            if not O365SocialNetwork.IsTemporary then
                if i mod 2 = 1 then
                    O365SocialNetwork."Media Resources Ref" := LibraryUtility.GenerateGUID;
            O365SocialNetwork.Insert(true);
        end;
    end;

    local procedure LoadSocialNetworks(var TempO365SocialNetwork: Record "O365 Social Network" temporary)
    var
        O365SocialNetwork: Record "O365 Social Network";
    begin
        TempO365SocialNetwork.DeleteAll();
        O365SocialNetwork.FindSet;
        repeat
            TempO365SocialNetwork.Init();
            TempO365SocialNetwork.Code := O365SocialNetwork.Code;
            TempO365SocialNetwork.Name := O365SocialNetwork.Name;
            TempO365SocialNetwork.URL := O365SocialNetwork.URL;
            TempO365SocialNetwork."Media Resources Ref" := O365SocialNetwork."Media Resources Ref";
            TempO365SocialNetwork.Insert(true);
        until O365SocialNetwork.Next = 0;
    end;
}

