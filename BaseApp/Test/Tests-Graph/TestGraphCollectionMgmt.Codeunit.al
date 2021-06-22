codeunit 134629 "Test Graph Collection Mgmt."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Collection]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        LibraryUtility: Codeunit "Library - Utility";
        CrLf: Text[2];
        InboundContactConnectionName: Text;
        IsInitialized: Boolean;
        WebsiteType: Option Other,Home,Work,Blog,"Profile";
        PhoneType: Option Home,Business,Mobile,Other,Assistant,HomeFax,BusinessFax,OtherFax,Pager,Radio;
        AddressType: Option Unknown,Home,Business,Other;
        BusinessType: Option Company,Individual;
        FlagStatusOption: Option NotFlagged,Complete,Flagged;

    local procedure Initialize()
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        LibraryGraphSync.DeleteAllLogRecords;
        LibraryGraphSync.DeleteAllContactIntegrationMappingDetails;
        LibraryGraphSync.RegisterTestConnections;
        InboundContactConnectionName := GraphConnectionSetup.GetInboundConnectionName(DATABASE::Contact);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundContactConnectionName, false);

        if IsInitialized then
            exit;

        CrLf[1] := 13;
        CrLf[2] := 10;

        IsInitialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyCollection()
    var
        JSONManagement: Codeunit "JSON Management";
        String: Text;
    begin
        Initialize;

        // Setup
        JSONManagement.InitializeCollection('');

        // Exercise
        String := JSONManagement.WriteCollectionToString;

        // Verify
        String := DelChr(String, '=', CrLf + ' ');
        Assert.AreEqual('[]', String, 'not an empty collection');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyCollectionFromString()
    var
        JSONManagement: Codeunit "JSON Management";
        String: Text;
    begin
        Initialize;

        // Setup
        JSONManagement.InitializeCollection('[ ]');

        // Exercise
        String := JSONManagement.WriteCollectionToString;

        // Verify
        String := DelChr(String, '=', CrLf + ' ');
        Assert.AreEqual('[]', String, 'not an empty collection');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyCollectionFromEmptyString()
    var
        JSONManagement: Codeunit "JSON Management";
        String: Text;
    begin
        Initialize;

        // Setup
        JSONManagement.InitializeCollection('');

        // Exercise
        String := JSONManagement.WriteCollectionToString;

        // Verify
        String := DelChr(String, '=', CrLf + ' ');
        Assert.AreEqual('[]', String, 'not an empty collection');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyObject()
    var
        JSONManagement: Codeunit "JSON Management";
        String: Text;
    begin
        Initialize;

        // Setup
        JSONManagement.InitializeEmptyObject;

        // Exercise
        String := JSONManagement.WriteObjectToString;

        // Verify
        String := DelChr(String, '=', CrLf + ' ');
        Assert.AreEqual('{}', String, 'not an empty object');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyObjectFromString()
    var
        JSONManagement: Codeunit "JSON Management";
        String: Text;
    begin
        Initialize;

        // Setup
        JSONManagement.InitializeObject('{ }');

        // Exercise
        String := JSONManagement.WriteObjectToString;

        // Verify
        String := DelChr(String, '=', CrLf + ' ');
        Assert.AreEqual('{}', String, 'not an empty object');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyObjectFromEmptyString()
    var
        JSONManagement: Codeunit "JSON Management";
        String: Text;
    begin
        Initialize;

        // Setup
        JSONManagement.InitializeObject('');

        // Exercise
        String := JSONManagement.WriteObjectToString;

        // Verify
        String := DelChr(String, '=', CrLf + ' ');
        Assert.AreEqual('{}', String, 'not an empty object');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetArrayCollection()
    var
        JSONManagement: Codeunit "JSON Management";
        JsonArray: DotNet JArray;
        JsonObject: DotNet JObject;
        JSONStr: Text;
    begin
        // Setup
        JSONStr := '{"Latitude":51.592687,"Longitude":0.426847,"Addresses":["Address 1","Address 2","Address 3","Address 4","Address 5"]}';

        // Exercise
        JSONManagement.InitializeObject(JSONStr);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetArrayPropertyValueFromJObjectByName(JsonObject, 'Addresses', JsonArray);
        JSONManagement.InitializeCollectionFromJArray(JsonArray);

        // Verify
        Assert.IsTrue(JSONManagement.GetCollectionCount = 5, 'Could not retrieve JArray (invalid nr. of items)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetCategoriesStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        CategoriesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddCategory('1. Priority 1 - Must do / Urgent');
        GraphCollectionMgtContact.AddCategory('8. Work - other');
        CategoriesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetCategoriesString(CategoriesString);

        // Verify
        Assert.AreNotEqual('', CategoriesString, '');
        Assert.AreEqual('[  "1. Priority 1 - Must do / Urgent",  "8. Work - other"]', DelChr(CategoriesString, '=', CrLf), '');
        Assert.AreEqual(CategoriesString, GraphContact.GetCategoriesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetCategoriesStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        CategoriesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddCategory('1. Priority 1 - Must do / Urgent');
        GraphCollectionMgtContact.AddCategory('8. Work - other');
        CategoriesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetCategoriesString(CategoriesString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id); // Required to 'clear' the BLOB

        // Verify
        Assert.AreNotEqual('', CategoriesString, '');
        Assert.AreEqual('[  "1. Priority 1 - Must do / Urgent",  "8. Work - other"]', DelChr(CategoriesString, '=', CrLf), '');
        Assert.AreEqual(CategoriesString, GraphContact.GetCategoriesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetEmailAddressesStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddEmailAddress('', 'contoso@contoso.com');
        EmailAddressesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetEmailAddressesString(EmailAddressesString);

        // Verify
        Assert.AreNotEqual('', EmailAddressesString, '');
        Assert.AreEqual(EmailAddressesString, GraphContact.GetEmailAddressesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetEmailAdressesStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddEmailAddress('', 'contoso@contoso.com');
        EmailAddressesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetEmailAddressesString(EmailAddressesString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', EmailAddressesString, '');
        Assert.AreEqual(EmailAddressesString, GraphContact.GetEmailAddressesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetWebsitesStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddWebsite(WebsiteType::Work, 'http://www.contoso.com', '', '');
        WebsitesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetWebsitesString(WebsitesString);

        // Verify
        Assert.AreNotEqual('', WebsitesString, '');
        Assert.AreEqual(WebsitesString, GraphContact.GetWebsitesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetWebsitesStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddWebsite(WebsiteType::Work, 'http://www.contoso.com', '', '');
        GraphCollectionMgtContact.AddWebsite(WebsiteType::Work, 'http://www.contoso.com', '', '');
        WebsitesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetWebsitesString(WebsitesString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', WebsitesString, '');
        Assert.AreEqual(WebsitesString, GraphContact.GetWebsitesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetImAddressesStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        ImAddressesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddImAddress('sip:contoso@contoso.com');
        GraphCollectionMgtContact.AddImAddress('sip:info@contoso.com');
        ImAddressesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetImAddressesString(ImAddressesString);

        // Verify
        Assert.AreNotEqual('', ImAddressesString, '');
        Assert.AreEqual('[  "sip:contoso@contoso.com",  "sip:info@contoso.com"]', DelChr(ImAddressesString, '=', CrLf), '');
        Assert.AreEqual(ImAddressesString, GraphContact.GetImAddressesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetImAddressesStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        ImAddressesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddImAddress('sip:contoso@contoso.com');
        GraphCollectionMgtContact.AddImAddress('sip:info@contoso.com');
        ImAddressesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetImAddressesString(ImAddressesString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', ImAddressesString, '');
        Assert.AreEqual('[  "sip:contoso@contoso.com",  "sip:info@contoso.com"]', DelChr(ImAddressesString, '=', CrLf), '');
        Assert.AreEqual(ImAddressesString, GraphContact.GetImAddressesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetPhonesStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddPhone(PhoneType::Business, '0123456789');
        PhonesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetPhonesString(PhonesString);

        // Verify
        Assert.AreNotEqual('', PhonesString, '');
        Assert.AreEqual(PhonesString, GraphContact.GetPhonesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetPhonesStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddPhone(PhoneType::Business, '0123456789');
        PhonesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetPhonesString(PhonesString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', PhonesString, '');
        Assert.AreEqual(PhonesString, GraphContact.GetPhonesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetPostalAddressesStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddPostalAddress(AddressType::Business, '', 'Street', 'City', 'State', 'Country', '');
        PostalAddressesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetPostalAddressesString(PostalAddressesString);

        // Verify
        Assert.AreNotEqual('', PostalAddressesString, '');
        Assert.AreEqual(PostalAddressesString, GraphContact.GetPostalAddressesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetPostalAddressesStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddPostalAddress(AddressType::Business, '', 'Street', 'City', 'State', 'Country', '');
        PostalAddressesString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetPostalAddressesString(PostalAddressesString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', PostalAddressesString, '');
        Assert.AreEqual(PostalAddressesString, GraphContact.GetPostalAddressesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetPersonalNotesStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        PersonalNotesString := 'comment1' + CrLf + 'Comment2';

        // Execute
        GraphContact.SetPersonalNotesString(PersonalNotesString);

        // Verify
        Assert.AreEqual(PersonalNotesString, GraphContact.GetPersonalNotesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetPersonalNotesStringInserted()
    var
        GraphContact: Record "Graph Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        PersonalNotesString := 'comment1' + CrLf + 'Comment2';

        // Execute
        GraphContact.SetPersonalNotesString(PersonalNotesString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreEqual(PersonalNotesString, GraphContact.GetPersonalNotesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetChildrenStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        ChildrenString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddChildren('Daughter');
        GraphCollectionMgtContact.AddChildren('Son');
        ChildrenString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetChildrenString(ChildrenString);

        // Verify
        Assert.AreNotEqual('', ChildrenString, '');
        Assert.AreEqual('[  "Daughter",  "Son"]', DelChr(ChildrenString, '=', CrLf), '');
        Assert.AreEqual(ChildrenString, GraphContact.GetChildrenString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetChildrenStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        ChildrenString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddChildren('Daughter');
        GraphCollectionMgtContact.AddChildren('Son');
        ChildrenString := GraphCollectionMgtContact.WriteCollectionToString;

        // Execute
        GraphContact.SetChildrenString(ChildrenString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', ChildrenString, '');
        Assert.AreEqual('[  "Daughter",  "Son"]', DelChr(ChildrenString, '=', CrLf), '');
        Assert.AreEqual(ChildrenString, GraphContact.GetChildrenString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetFlagStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        FlagString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeObject('');
        GraphCollectionMgtContact.AddFlag('', '', '2020-01-01T00:00:00.0000000', 'UTC', '', '', FlagStatusOption::Flagged);
        FlagString := GraphCollectionMgtContact.WriteObjectToString;

        // Execute
        GraphContact.SetFlagString(FlagString);

        // Verify
        Assert.AreNotEqual('', FlagString, '');
        Assert.AreEqual(FlagString, GraphContact.GetFlagString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetFlagStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        FlagString: Text;
    begin
        Initialize;

        // Setup
        GraphCollectionMgtContact.InitializeObject('');
        GraphCollectionMgtContact.AddFlag('', '', '2020-01-01T00:00:00.0000000', 'UTC', '', '', FlagStatusOption::Flagged);
        FlagString := GraphCollectionMgtContact.WriteObjectToString;

        // Execute
        GraphContact.SetFlagString(FlagString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', FlagString, '');
        Assert.AreEqual(FlagString, GraphContact.GetFlagString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetBusinessTypeStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        BusinessTypeString: Text;
    begin
        Initialize;

        // Setup
        BusinessTypeString := GraphCollectionMgtContact.AddBusinessType(BusinessType::Individual);

        // Execute
        GraphContact.SetBusinessTypeString(BusinessTypeString);

        // Verify
        Assert.AreNotEqual('', BusinessTypeString, '');
        Assert.AreEqual(BusinessTypeString, GraphContact.GetBusinessTypeString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetBusinessTypeStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        BusinessTypeString: Text;
    begin
        Initialize;

        // Setup
        BusinessTypeString := GraphCollectionMgtContact.AddBusinessType(BusinessType::Individual);

        // Execute
        GraphContact.SetBusinessTypeString(BusinessTypeString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', BusinessTypeString, '');
        Assert.AreEqual(BusinessTypeString, GraphContact.GetBusinessTypeString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetIsBankStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
    begin
        Initialize;

        // Setup
        IsBankString := GraphCollectionMgtContact.AddIsBank(true);

        // Execute
        GraphContact.SetIsBankString(IsBankString);

        // Verify
        Assert.AreNotEqual('', IsBankString, '');
        Assert.AreEqual(IsBankString, GraphContact.GetIsBankString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetIsBankStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
    begin
        Initialize;

        // Setup
        IsBankString := GraphCollectionMgtContact.AddIsBank(true);

        // Execute
        GraphContact.SetIsBankString(IsBankString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', IsBankString, '');
        Assert.AreEqual(IsBankString, GraphContact.GetIsBankString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetIsCustomerStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsCustomerString: Text;
    begin
        Initialize;

        // Setup
        IsCustomerString := GraphCollectionMgtContact.AddIsCustomer(true);

        // Execute
        GraphContact.SetIsCustomerString(IsCustomerString);

        // Verify
        Assert.AreNotEqual('', IsCustomerString, '');
        Assert.AreEqual(IsCustomerString, GraphContact.GetIsCustomerString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetIsCustomerStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsCustomerString: Text;
    begin
        Initialize;

        // Setup
        IsCustomerString := GraphCollectionMgtContact.AddIsCustomer(true);

        // Execute
        GraphContact.SetIsCustomerString(IsCustomerString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', IsCustomerString, '');
        Assert.AreEqual(IsCustomerString, GraphContact.GetIsCustomerString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetIsVendorStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsVendorString: Text;
    begin
        Initialize;

        // Setup
        IsVendorString := GraphCollectionMgtContact.AddIsVendor(true);

        // Execute
        GraphContact.SetIsVendorString(IsVendorString);

        // Verify
        Assert.AreNotEqual('', IsVendorString, '');
        Assert.AreEqual(IsVendorString, GraphContact.GetIsVendorString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetIsVendorStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsVendorString: Text;
    begin
        Initialize;

        // Setup
        IsVendorString := GraphCollectionMgtContact.AddIsVendor(true);

        // Execute
        GraphContact.SetIsVendorString(IsVendorString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', IsVendorString, '');
        Assert.AreEqual(IsVendorString, GraphContact.GetIsVendorString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetIsContactStringNotInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsContactString: Text;
    begin
        Initialize;

        // Setup
        IsContactString := GraphCollectionMgtContact.AddIsContact(true);

        // Execute
        GraphContact.SetIsContactString(IsContactString);

        // Verify
        Assert.AreNotEqual('', IsContactString, '');
        Assert.AreEqual(IsContactString, GraphContact.GetIsContactString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAndGetIsContactStringInserted()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsContactString: Text;
    begin
        Initialize;

        // Setup
        IsContactString := GraphCollectionMgtContact.AddIsContact(true);

        // Execute
        GraphContact.SetIsContactString(IsContactString);
        GraphContact.Insert();
        GraphContact.Get(GraphContact.Id);

        // Verify
        Assert.AreNotEqual('', IsContactString, '');
        Assert.AreEqual(IsContactString, GraphContact.GetIsContactString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneEmptyStrings()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneHomeAddress()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home"}]';
        PhonesString := '[]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneHomePhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[{"Type":"Home"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneHomeFax()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[{"Type":"HomeFax"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneHomeWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[]';
        WebsitesString := '[{"Type":"Home"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneOtherAddressHomePhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other"}]';
        PhonesString := '[{"Type":"Home"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneOtherAddressHomeWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other"}]';
        PhonesString := '[]';
        WebsitesString := '[{"Type":"Home"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneHomeAddressOtherPhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home"}]';
        PhonesString := '[{"Type":"Other"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasHomeAddressOrPhoneOtherAddressOtherPhoneOtherWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other"}]';
        PhonesString := '[{"Type":"Other"}]';
        WebsitesString := '[{"Type":"Other"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasHomeAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneEmptyStrings()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneBusinessAddress()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business"}]';
        PhonesString := '[]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneBusinessPhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[{"Type":"Business"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneBusinessFax()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[{"Type":"BusinessFax"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneWorkWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[]';
        WebsitesString := '[{"Type":"Work"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneOtherAddressBusinessPhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other"}]';
        PhonesString := '[{"Type":"Business"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneOtherAddressWorkWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other"}]';
        PhonesString := '[]';
        WebsitesString := '[{"Type":"Work"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneBusinessAddressOtherPhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business"}]';
        PhonesString := '[{"Type":"Other"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasBusinessAddressOrPhoneOtherAddressOtherPhoneOtherWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other"}]';
        PhonesString := '[{"Type":"Other"}]';
        WebsitesString := '[{"Type":"Other"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasBusinessAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneEmptyStrings()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneOtherAddress()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other"}]';
        PhonesString := '[]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneOtherPhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[{"Type":"Other"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneOtherFax()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[{"Type":"OtherFax"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneOtherWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';
        PhonesString := '[]';
        WebsitesString := '[{"Type":"Other"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneHomeAddressOtherPhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home"}]';
        PhonesString := '[{"Type":"Other"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneHomeAddressOtherWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home"}]';
        PhonesString := '[]';
        WebsitesString := '[{"Type":"Other"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneOtherAddressHomePhone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other"}]';
        PhonesString := '[{"Type":"Home"}]';
        WebsitesString := '[]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsTrue(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasOtherAddressOrPhoneHomeAddressHomePhoneHomeWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
        Result: Boolean;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home"}]';
        PhonesString := '[{"Type":"Home"}]';
        WebsitesString := '[{"Type":"Home"}]';

        // Exercise
        Result := GraphCollectionMgtContact.HasOtherAddressOrPhone(PostalAddressesString, PhonesString, WebsitesString);

        // Verify
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeAddress()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeAddressPartialInfo()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","City":"City","State":"State"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, '', '', 'City', 'State', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeAddressEmptyString()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';

        // Exercise
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, '', '', '', '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessAddress()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'Address', 'Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessAddressPartialInfo()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","City":"City","State":"State"}]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, '', '', 'City', 'State', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessAddressEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, '', '', '', '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherAddress()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherAddressPartialInfo()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","City":"City","State":"State"}]';

        // Exercise
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, '', '', 'City', 'State', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherAddressEmptyString()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';

        // Exercise
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, '', '', '', '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeAddressFieldAddress()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateHomeAddress(PostalAddressesString, 'New Address', 'Address 2', 'City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'New Address', 'Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeAddressFieldAddress2()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateHomeAddress(PostalAddressesString, 'Address', 'New Address 2', 'City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'New Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeAddressFieldCity()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateHomeAddress(PostalAddressesString, 'Address', 'Address 2', 'New City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'New City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeAddressFieldState()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateHomeAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'New State', 'US', '90210');
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'City', 'New State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeAddressFieldCountry()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateHomeAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'State', 'CA', '90210');
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'City', 'State', 'CA', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeAddressFieldPostCode()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateHomeAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'State', 'US', '56432');
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'City', 'State', 'US', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeAddress()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Home","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateHomeAddress(PostalAddressesString,
            'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeAddressEmptyString()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateHomeAddress(PostalAddressesString,
            'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
        GraphCollectionMgtContact.GetHomeAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessAddressFieldAddress()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateBusinessAddress(PostalAddressesString, 'New Address', 'Address 2', 'City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'New Address', 'Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessAddressFieldAddress2()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateBusinessAddress(PostalAddressesString, 'Address', 'New Address 2', 'City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'Address', 'New Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessAddressFieldCity()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateBusinessAddress(PostalAddressesString, 'Address', 'Address 2', 'New City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'Address', 'Address 2', 'New City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessAddressFieldState()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateBusinessAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'New State', 'US', '90210');
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'Address', 'Address 2', 'City', 'New State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessAddressFieldCountry()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateBusinessAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'State', 'CA', '90210');
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'Address', 'Address 2', 'City', 'State', 'CA', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessAddressFieldPostCode()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateBusinessAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'State', 'US', '56432');
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'Address', 'Address 2', 'City', 'State', 'US', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessAddress()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Business","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateBusinessAddress(PostalAddressesString,
            'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessAddressEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateBusinessAddress(PostalAddressesString,
            'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
        GraphCollectionMgtContact.GetBusinessAddress(PostalAddressesString, Contact.Address, Contact."Address 2",
          Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");

        // Verify
        VerifyContactAddress(Contact, 'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherAddressFieldAddress()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateOtherAddress(PostalAddressesString, 'New Address', 'Address 2', 'City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'New Address', 'Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherAddressFieldAddress2()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateOtherAddress(PostalAddressesString, 'Address', 'New Address 2', 'City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'New Address 2', 'City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherAddressFieldCity()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateOtherAddress(PostalAddressesString, 'Address', 'Address 2', 'New City', 'State', 'US', '90210');
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'New City', 'State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherAddressFieldState()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateOtherAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'New State', 'US', '90210');
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'City', 'New State', 'US', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherAddressFieldCountry()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateOtherAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'State', 'CA', '90210');
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'City', 'State', 'CA', '90210');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherAddressFieldPostCode()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateOtherAddress(PostalAddressesString, 'Address', 'Address 2', 'City', 'State', 'US', '56432');
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'Address', 'Address 2', 'City', 'State', 'US', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherAddress()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[{"Type":"Other","PostOfficeBox":"","Street":"Address\r\nAddress 2","City":"City","State":"State","CountryOrRegion":"US","PostalCode":"90210"}]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateOtherAddress(PostalAddressesString,
            'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherAddressEmptyString()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PostalAddressesString: Text;
    begin
        Initialize;

        // Setup
        PostalAddressesString := '[]';

        // Exercise
        PostalAddressesString :=
          GraphCollectionMgtContact.UpdateOtherAddress(PostalAddressesString,
            'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
        GraphCollectionMgtContact.GetOtherAddress(PostalAddressesString, ContactAltAddress.Address, ContactAltAddress."Address 2",
          ContactAltAddress.City, ContactAltAddress.County, ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");

        // Verify
        VerifyContactAltAddress(ContactAltAddress, 'New Address', 'New Address 2', 'New City', 'New State', 'CA', '56432');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomePhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetHomePhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomePhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomePhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomePhoneNoHomePhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomePhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomePhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomePhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '00123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessPhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business"}]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessPhoneNoBusinessPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '10123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMobilePhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetMobilePhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMobilePhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Mobile"}]';

        // Exercise
        GraphCollectionMgtContact.GetMobilePhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMobilePhoneNoMobilePhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetMobilePhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMobilePhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetMobilePhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '20123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetOtherPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherPhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Other"}]';

        // Exercise
        GraphCollectionMgtContact.GetOtherPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherPhoneNoOtherPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Business","Number":"10123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetOtherPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetOtherPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '30123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAssistantPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetAssistantPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAssistantPhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Assistant"}]';

        // Exercise
        GraphCollectionMgtContact.GetAssistantPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAssistantPhoneNoAssistantPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetAssistantPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAssistantPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Assistant","Number":"40123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetAssistantPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '40123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeFaxPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetHomeFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeFaxPhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"HomeFax"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomeFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeFaxPhoneNoHomeFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomeFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"HomeFax","Number":"50123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomeFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '50123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessFaxPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessFaxPhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"BusinessFax"}]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessFaxPhoneNoBusinessFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"BusinessFax","Number":"60123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetBusinessFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '60123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherFaxPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetOtherFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherFaxPhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home"}]';

        // Exercise
        GraphCollectionMgtContact.GetOtherFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherFaxPhoneNoOtherFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetOtherFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Assert.AreEqual('', Contact."Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOtherFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"OtherFax","Number":"70123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetOtherFaxPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '70123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPagerPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetPagerPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPagerPhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Pager"}]';

        // Exercise
        GraphCollectionMgtContact.GetPagerPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPagerPhoneNoPagerPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetPagerPhone(PhonesString, Contact."Phone No.");

        // Verify
        Assert.AreEqual('', Contact."Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPagerPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Pager","Number":"80123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetPagerPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '80123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetRadioPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetRadioPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetRadioPhoneMissingNumber()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Radio"}]';

        // Exercise
        GraphCollectionMgtContact.GetRadioPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetRadioPhoneNoRadioPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business","Number":"10123456789"},{"Type":"Mobile","Number":"20123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetRadioPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetRadioPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Radio","Number":"90123456789"},{"Type":"Other","Number":"30123456789"}]';

        // Exercise
        GraphCollectionMgtContact.GetRadioPhone(PhonesString, Contact."Phone No.");

        // Verify
        Contact.TestField("Phone No.", '90123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomePhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateHomePhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetHomePhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomePhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateHomePhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetHomePhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateBusinessPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetBusinessPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Business","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateBusinessPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetBusinessPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateMobilePhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateMobilePhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetMobilePhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateMobilePhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Mobile","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateMobilePhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetMobilePhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateOtherPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetOtherPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Other","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateOtherPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetOtherPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateAssistantPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateAssistantPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetAssistantPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateAssistantPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Assistant","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateAssistantPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetAssistantPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeFaxPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateHomeFaxPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetHomeFaxPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"HomeFax","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateHomeFaxPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetHomeFaxPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessFaxPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateBusinessFaxPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetBusinessFaxPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBusinessFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"BusinessFax","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateBusinessFaxPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetBusinessFaxPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherFaxPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateOtherFaxPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetOtherFaxPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateOtherFaxPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"OtherFax","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateOtherFaxPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetOtherFaxPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatePagerPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdatePagerPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetPagerPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatePagerPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Pager","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdatePagerPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetPagerPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateRadioPhoneEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateRadioPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetRadioPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateRadioPhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PhonesString: Text;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Radio","Number":"987654321"}]';

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateRadioPhone(PhonesString, '0123456789');

        // Verify
        GraphCollectionMgtContact.GetRadioPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '0123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatePhone()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        JSONManagement: Codeunit "JSON Management";
        PhonesString: Text;
        "Count": Integer;
    begin
        Initialize;

        // Setup
        PhonesString := '[{"Type":"Home","Number":"00123456789"},{"Type":"Business","Number":"10123456789"},{"Type":"Other","Number":"20123456789"}]';
        GraphCollectionMgtContact.InitializeCollection(PhonesString);
        JSONManagement.InitializeCollection(PhonesString);

        Count := JSONManagement.GetCollectionCount;

        // Exercise
        PhonesString := GraphCollectionMgtContact.UpdateBusinessPhone(PhonesString, '98765432101');
        JSONManagement.InitializeCollection(PhonesString);

        // Verify
        GraphCollectionMgtContact.InitializeCollection(PhonesString);
        Assert.AreEqual(Count, JSONManagement.GetCollectionCount, 'Incorrect number of Phone Numbers in Collection');
        GraphCollectionMgtContact.GetHomePhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '00123456789');
        GraphCollectionMgtContact.GetBusinessPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '98765432101');
        GraphCollectionMgtContact.GetOtherPhone(PhonesString, Contact."Phone No.");
        Contact.TestField("Phone No.", '20123456789');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeWebsiteEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetHomeWebsite(WebsitesString, Contact."Home Page");

        // Verify
        Contact.TestField("Home Page", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeWebsiteMissingAddress()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[{"Type":"Home"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomeWebsite(WebsitesString, Contact."Home Page");

        // Verify
        Contact.TestField("Home Page", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeWebsiteNoHomeWebsite()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[{"Type":"Work","Address":"http://www.microsoft.com"},{"Type":"Blog","Address":"http://www.bing.com"},{"Type":"Other","Address":"http://www.office.com"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomeWebsite(WebsitesString, Contact."Home Page");

        // Verify
        Contact.TestField("Home Page", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetHomeWebsite()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[{"Type":"Home","Address":"http://www.microsoft.com"},{"Type":"Work","Address":"http://www.bing.com"},{"Type":"Other","Address":"http://www.office.com"}]';

        // Exercise
        GraphCollectionMgtContact.GetHomeWebsite(WebsitesString, Contact."Home Page");

        // Verify
        Contact.TestField("Home Page", 'http://www.microsoft.com');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetWorkWebsiteEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[ ]';

        // Exercise
        GraphCollectionMgtContact.GetWorkWebsite(WebsitesString, Contact."Home Page");

        // Verify
        Contact.TestField("Home Page", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetWorkWebsiteMissingAddress()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[{"Type":"Work"}]';

        // Exercise
        GraphCollectionMgtContact.GetWorkWebsite(WebsitesString, Contact."Home Page");

        // Verify
        Contact.TestField("Home Page", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetWorkWebsiteNoHomeWebsite()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[{"Type":"Home","Address":"http://www.microsoft.com"},{"Type":"Blog","Address":"http://www.bing.com"},{"Type":"Other","Address":"http://www.office.com"}]';

        // Exercise
        GraphCollectionMgtContact.GetWorkWebsite(WebsitesString, Contact."Home Page");

        // Verify
        Contact.TestField("Home Page", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetWorkWebsite()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[{"Type":"Home","Address":"http://www.microsoft.com"},{"Type":"Work","Address":"http://www.bing.com"},{"Type":"Other","Address":"http://www.office.com"}]';

        // Exercise
        GraphCollectionMgtContact.GetWorkWebsite(WebsitesString, Contact."Home Page");

        // Verify
        Contact.TestField("Home Page", 'http://www.bing.com');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeWebsiteEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[]';

        // Exercise
        WebsitesString := GraphCollectionMgtContact.UpdateHomeWebsite(WebsitesString, 'http://www.microsoft.com');

        // Verify
        GraphCollectionMgtContact.GetHomeWebsite(WebsitesString, Contact."Home Page");
        asserterror Contact.TestField("Home Page", 'http://www.microsoft.com');
        Assert.KnownFailure('Home Page must be equal to', 194567)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateHomeWebsite()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[{"Type":"Home","Address":"http://www.bing.com"}]';

        // Exercise
        WebsitesString := GraphCollectionMgtContact.UpdateHomeWebsite(WebsitesString, 'http://www.microsoft.com');

        // Verify
        GraphCollectionMgtContact.GetHomeWebsite(WebsitesString, Contact."Home Page");
        asserterror Contact.TestField("Home Page", 'http://www.microsoft.com');
        Assert.KnownFailure('Home Page must be equal to', 194567)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateWorkWebsiteEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[]';

        // Exercise
        WebsitesString := GraphCollectionMgtContact.UpdateWorkWebsite(WebsitesString, 'http://www.microsoft.com');

        // Verify
        GraphCollectionMgtContact.GetWorkWebsite(WebsitesString, Contact."Home Page");
        asserterror Contact.TestField("Home Page", 'http://www.microsoft.com');
        Assert.KnownFailure('Home Page must be equal to', 194567)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateWorkWebsite()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesString: Text;
    begin
        Initialize;

        // Setup
        WebsitesString := '[{"Type":"Work","Address":"http://www.bing.com"}]';

        // Exercise
        WebsitesString := GraphCollectionMgtContact.UpdateWorkWebsite(WebsitesString, 'http://www.microsoft.com');

        // Verify
        GraphCollectionMgtContact.GetWorkWebsite(WebsitesString, Contact."Home Page");
        asserterror Contact.TestField("Home Page", 'http://www.microsoft.com');
        Assert.KnownFailure('Home Page must be equal to', 194567)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressEmpty()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        Address: Text;
        Name: Text;
    begin
        // Setup
        EmailAddressesString := '';

        // Exercise
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'info@contoso.com');

        // Verify
        GraphCollectionMgtContact.InitializeCollection(EmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('info@contoso.com', Address, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressReplace()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        Address: Text;
        Name: Text;
    begin
        // Setup
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'info@contoso.com');

        // Exercise
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'support@contoso.com');

        // Verify
        GraphCollectionMgtContact.InitializeCollection(EmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('support@contoso.com', Address, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressAddSecond()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        Address: Text;
        Name: Text;
    begin
        // Setup
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'info@contoso.com');

        // Exercise
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 1, 'support@contoso.com');

        // Verify
        GraphCollectionMgtContact.InitializeCollection(EmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('info@contoso.com', Address, '');
        GraphCollectionMgtContact.GetEmailAddress(1, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('support@contoso.com', Address, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressAddSecondEmpty()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        Address: Text;
        Name: Text;
    begin
        // Setup
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'info@contoso.com');

        // Exercise
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 1, '');

        // Verify
        GraphCollectionMgtContact.InitializeCollection(EmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('info@contoso.com', Address, '');
        GraphCollectionMgtContact.GetEmailAddress(1, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('', Address, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressReplaceFirst()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        Address: Text;
        Name: Text;
    begin
        // Setup
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'info@contoso.com');
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 1, 'support@contoso.com');

        // Exercise
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'no.reply@contoso.com');

        // Verify
        GraphCollectionMgtContact.InitializeCollection(EmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('no.reply@contoso.com', Address, '');
        GraphCollectionMgtContact.GetEmailAddress(1, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('support@contoso.com', Address, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressReplaceSecond()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        Address: Text;
        Name: Text;
    begin
        // Setup
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'info@contoso.com');
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 1, 'support@contoso.com');

        // Exercise
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 1, 'no.reply@contoso.com');

        // Verify
        GraphCollectionMgtContact.InitializeCollection(EmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('info@contoso.com', Address, '');
        GraphCollectionMgtContact.GetEmailAddress(1, Name, Address);
        Assert.AreEqual('', Name, '');
        Assert.AreEqual('no.reply@contoso.com', Address, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressReplaceFirstNoNameChange()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        Address: Text;
        Name: Text;
    begin
        // Setup
        EmailAddressesString := BuildTwoEmailAddressesString('Contoso Info', 'info@contoso.com', 'Contoso Support', 'support@contoso.com');

        // Exercise
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, 'no.reply@contoso.com');

        // Verify
        GraphCollectionMgtContact.InitializeCollection(EmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, Name, Address);
        Assert.AreEqual('', Name, ''); // Name is set to blank when Address changes
        Assert.AreEqual('no.reply@contoso.com', Address, '');
        GraphCollectionMgtContact.GetEmailAddress(1, Name, Address);
        Assert.AreEqual('Contoso Support', Name, '');
        Assert.AreEqual('support@contoso.com', Address, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEmailAddressReplaceSecondNoNameChange()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        Address: Text;
        Name: Text;
    begin
        // Setup
        EmailAddressesString := BuildTwoEmailAddressesString('Contoso Info', 'info@contoso.com', 'Contoso Support', 'support@contoso.com');

        // Exercise
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 1, 'no.reply@contoso.com');

        // Verify
        GraphCollectionMgtContact.InitializeCollection(EmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, Name, Address);
        Assert.AreEqual('Contoso Info', Name, '');
        Assert.AreEqual('info@contoso.com', Address, '');
        GraphCollectionMgtContact.GetEmailAddress(1, Name, Address);
        Assert.AreEqual('', Name, ''); // Name is set to blank when Address changes
        Assert.AreEqual('no.reply@contoso.com', Address, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessTypeEmptyString()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        BusinessTypeString: Text;
    begin
        Initialize;

        // Setup
        BusinessTypeString := '{}';

        // Exercise
        GraphCollectionMgtContact.GetBusinessType(BusinessTypeString, Contact.Type);

        // Verify
        Contact.TestField(Type, Contact.Type::Person);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessTypePerson()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        BusinessTypeString: Text;
    begin
        Initialize;

        // Setup
        BusinessTypeString := '{"PropertyId":"String {bdba944b-fc2b-47a1-8ba4-cafc4ae13ea2} Name BusinessType","Value":"Individual"}';

        // Exercise
        GraphCollectionMgtContact.GetBusinessType(BusinessTypeString, Contact.Type);

        // Verify
        Contact.TestField(Type, Contact.Type::Person);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetBusinessTypeCompany()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        BusinessTypeString: Text;
    begin
        Initialize;

        // Setup
        BusinessTypeString := '{"PropertyId":"String {bdba944b-fc2b-47a1-8ba4-cafc4ae13ea2} Name BusinessType","Value":"Company"}';

        // Exercise
        GraphCollectionMgtContact.GetBusinessType(BusinessTypeString, Contact.Type);

        // Verify
        Contact.TestField(Type, Contact.Type::Company);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddBusinessTypePerson()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        BusinessTypeString: Text;
        NewBusinessTypeString: Text;
    begin
        Initialize;

        // Setup
        BusinessTypeString := '{  "PropertyId": "String {bdba944b-fc2b-47a1-8ba4-cafc4ae13ea2} Name BusinessType",  "Value": "Individual"}';
        // Exercise
        NewBusinessTypeString := GraphCollectionMgtContact.AddBusinessType(Contact.Type::Person.AsInteger());

        // Verify
        Assert.AreEqual(BusinessTypeString, DelChr(NewBusinessTypeString, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddBusinessTypeCompany()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        BusinessTypeString: Text;
        NewBusinessTypeString: Text;
    begin
        Initialize;

        // Setup
        BusinessTypeString := '{  "PropertyId": "String {bdba944b-fc2b-47a1-8ba4-cafc4ae13ea2} Name BusinessType",  "Value": "Company"}';

        // Exercise
        NewBusinessTypeString := GraphCollectionMgtContact.AddBusinessType(Contact.Type::Company);

        // Verify
        Assert.AreEqual(BusinessTypeString, DelChr(NewBusinessTypeString, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsCustomerEmptyString()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsCustomerString: Text;
        IsCustomer: Boolean;
    begin
        Initialize;

        // Setup
        IsCustomerString := '{}';

        // Exercise
        IsCustomer := GraphCollectionMgtContact.GetIsCustomer(IsCustomerString);

        // Verify
        Assert.IsFalse(IsCustomer, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsCustomerFalseOnWrongProperty()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsCustomerString: Text;
        IsCustomer: Boolean;
    begin
        Initialize;

        // Setup
        IsCustomerString := '{"PropertyId":"Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor","Value":"1"}';

        // Exercise
        IsCustomer := GraphCollectionMgtContact.GetIsCustomer(IsCustomerString);

        // Verify
        Assert.IsFalse(IsCustomer, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsCustomerFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsCustomerString: Text;
        IsCustomer: Boolean;
    begin
        Initialize;

        // Setup
        IsCustomerString := '{"PropertyId":"Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer","Value":"0"}';

        // Exercise
        IsCustomer := GraphCollectionMgtContact.GetIsCustomer(IsCustomerString);

        // Verify
        Assert.IsFalse(IsCustomer, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsCustomerTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsCustomerString: Text;
        IsCustomer: Boolean;
    begin
        Initialize;

        // Setup
        IsCustomerString := '{"PropertyId":"Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer","Value":"1"}';

        // Exercise
        IsCustomer := GraphCollectionMgtContact.GetIsCustomer(IsCustomerString);

        // Verify
        Assert.IsTrue(IsCustomer, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddIsCustomerFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsCustomerString: Text;
        IsCustomerStringNew: Text;
    begin
        Initialize;

        // Setup
        IsCustomerString := '{  "PropertyId": "Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer",  "Value": "0"}';

        // Exercise
        IsCustomerStringNew := GraphCollectionMgtContact.AddIsCustomer(false);

        // Verify
        Assert.AreEqual(IsCustomerString, DelChr(IsCustomerStringNew, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddIsCustomerTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsCustomerString: Text;
        IsCustomerStringNew: Text;
    begin
        Initialize;

        // Setup
        IsCustomerString := '{  "PropertyId": "Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer",  "Value": "1"}';

        // Exercise
        IsCustomerStringNew := GraphCollectionMgtContact.AddIsCustomer(true);

        // Verify
        Assert.AreEqual(IsCustomerString, DelChr(IsCustomerStringNew, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsVendorEmptyString()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsVendorString: Text;
        IsVendor: Boolean;
    begin
        Initialize;

        // Setup
        IsVendorString := '{}';

        // Exercise
        IsVendor := GraphCollectionMgtContact.GetIsVendor(IsVendorString);

        // Verify
        Assert.IsFalse(IsVendor, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsVendorFalseOnWrongProperty()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsVendorString: Text;
        IsVendor: Boolean;
    begin
        Initialize;

        // Setup
        IsVendorString := '{"PropertyId":"Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer","Value":"1"}';

        // Exercise
        IsVendor := GraphCollectionMgtContact.GetIsVendor(IsVendorString);

        // Verify
        Assert.IsFalse(IsVendor, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsVendorFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsVendorString: Text;
        IsVendor: Boolean;
    begin
        Initialize;

        // Setup
        IsVendorString := '{"PropertyId":"Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor","Value":"0"}';

        // Exercise
        IsVendor := GraphCollectionMgtContact.GetIsVendor(IsVendorString);

        // Verify
        Assert.IsFalse(IsVendor, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsVendorTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsVendorString: Text;
        IsVendor: Boolean;
    begin
        Initialize;

        // Setup
        IsVendorString := '{"PropertyId":"Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor","Value":"1"}';

        // Exercise
        IsVendor := GraphCollectionMgtContact.GetIsVendor(IsVendorString);

        // Verify
        Assert.IsTrue(IsVendor, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddIsVendorFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsVendorString: Text;
        IsVendorStringNew: Text;
    begin
        Initialize;

        // Setup
        IsVendorString := '{  "PropertyId": "Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor",  "Value": "0"}';

        // Exercise
        IsVendorStringNew := GraphCollectionMgtContact.AddIsVendor(false);

        // Verify
        Assert.AreEqual(IsVendorString, DelChr(IsVendorStringNew, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddIsVendorTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsVendorString: Text;
        IsVendorStringNew: Text;
    begin
        Initialize;

        // Setup
        IsVendorString := '{  "PropertyId": "Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor",  "Value": "1"}';

        // Exercise
        IsVendorStringNew := GraphCollectionMgtContact.AddIsVendor(true);

        // Verify
        Assert.AreEqual(IsVendorString, DelChr(IsVendorStringNew, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsBankEmptyString()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
        IsBank: Boolean;
    begin
        Initialize;

        // Setup
        IsBankString := '{}';

        // Exercise
        IsBank := GraphCollectionMgtContact.GetIsBank(IsBankString);

        // Verify
        Assert.IsFalse(IsBank, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsBankFalseOnWrongProperty()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
        IsBank: Boolean;
    begin
        Initialize;

        // Setup
        IsBankString := '{"PropertyId":"Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer","Value":"1"}';

        // Exercise
        IsBank := GraphCollectionMgtContact.GetIsBank(IsBankString);

        // Verify
        Assert.IsFalse(IsBank, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsBankFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
        IsBank: Boolean;
    begin
        Initialize;

        // Setup
        IsBankString := '{"PropertyId":"Integer {a8ef117a-16d9-4cc6-965a-d2fbe0177e61} Name IsBank","Value":"0"}';

        // Exercise
        IsBank := GraphCollectionMgtContact.GetIsBank(IsBankString);

        // Verify
        Assert.IsFalse(IsBank, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsBankTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
        IsBank: Boolean;
    begin
        Initialize;

        // Setup
        IsBankString := '{"PropertyId":"Integer {a8ef117a-16d9-4cc6-965a-d2fbe0177e61} Name IsBank","Value":"1"}';

        // Exercise
        IsBank := GraphCollectionMgtContact.GetIsBank(IsBankString);

        // Verify
        Assert.IsTrue(IsBank, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddIsBankFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
        IsBankStringNew: Text;
    begin
        Initialize;

        // Setup
        IsBankString := '{  "PropertyId": "Integer {a8ef117a-16d9-4cc6-965a-d2fbe0177e61} Name IsBank",  "Value": "0"}';

        // Exercise
        IsBankStringNew := GraphCollectionMgtContact.AddIsBank(false);

        // Verify
        Assert.AreEqual(IsBankString, DelChr(IsBankStringNew, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddIsBankTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
        IsBankStringNew: Text;
    begin
        Initialize;

        // Setup
        IsBankString := '{  "PropertyId": "Integer {a8ef117a-16d9-4cc6-965a-d2fbe0177e61} Name IsBank",  "Value": "1"}';

        // Exercise
        IsBankStringNew := GraphCollectionMgtContact.AddIsBank(true);

        // Verify
        Assert.AreEqual(IsBankString, DelChr(IsBankStringNew, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsContactEmptyString()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsContactString: Text;
        IsContact: Boolean;
    begin
        Initialize;

        // Setup
        IsContactString := '{}';

        // Exercise
        IsContact := GraphCollectionMgtContact.GetIsContact(IsContactString);

        // Verify
        Assert.IsFalse(IsContact, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsContactFalseOnWrongProperty()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsContactString: Text;
        IsContact: Boolean;
    begin
        Initialize;

        // Setup
        IsContactString := '{"PropertyId":"Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor","Value":"1"}';

        // Exercise
        IsContact := GraphCollectionMgtContact.GetIsContact(IsContactString);

        // Verify
        Assert.IsFalse(IsContact, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsContactFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsContactString: Text;
        IsContact: Boolean;
    begin
        Initialize;

        // Setup
        IsContactString := '{"PropertyId":"Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact","Value":"0"}';

        // Exercise
        IsContact := GraphCollectionMgtContact.GetIsContact(IsContactString);

        // Verify
        Assert.IsFalse(IsContact, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsContactTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsContactString: Text;
        IsContact: Boolean;
    begin
        Initialize;

        // Setup
        IsContactString := '{"PropertyId":"Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact","Value":"1"}';

        // Exercise
        IsContact := GraphCollectionMgtContact.GetIsContact(IsContactString);

        // Verify
        Assert.IsTrue(IsContact, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddIsContactFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsContactString: Text;
        IsContactStringNew: Text;
    begin
        Initialize;

        // Setup
        IsContactString := '{  "PropertyId": "Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact",  "Value": "0"}';

        // Exercise
        IsContactStringNew := GraphCollectionMgtContact.AddIsContact(false);

        // Verify
        Assert.AreEqual(IsContactString, DelChr(IsContactStringNew, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddIsContactTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsContactString: Text;
        IsContactStringNew: Text;
    begin
        Initialize;

        // Setup
        IsContactString := '{  "PropertyId": "Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact",  "Value": "1"}';

        // Exercise
        IsContactStringNew := GraphCollectionMgtContact.AddIsContact(true);

        // Verify
        Assert.AreEqual(IsContactString, DelChr(IsContactStringNew, '=', CrLf), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsLeadEmptyString()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsLeadString: Text;
        IsLead: Boolean;
    begin
        Initialize;

        // Setup
        IsLeadString := '{}';

        // Exercise
        IsLead := GraphCollectionMgtContact.GetIsLead(IsLeadString);

        // Verify
        Assert.IsFalse(IsLead, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsLeadFalseOnWrongProperty()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsLeadString: Text;
        IsLead: Boolean;
    begin
        Initialize;

        // Setup
        IsLeadString := '{"PropertyId":"Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor","Value":"1"}';

        // Exercise
        IsLead := GraphCollectionMgtContact.GetIsLead(IsLeadString);

        // Verify
        Assert.IsFalse(IsLead, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsLeadFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsLeadString: Text;
        IsLead: Boolean;
    begin
        Initialize;

        // Setup
        IsLeadString := '{"PropertyId":"Integer {37829b75-e5e4-4582-ae12-36f754e4bd7b} Name IsLead","Value":"0"}';

        // Exercise
        IsLead := GraphCollectionMgtContact.GetIsLead(IsLeadString);

        // Verify
        Assert.IsFalse(IsLead, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsLeadTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsLeadString: Text;
        IsLead: Boolean;
    begin
        Initialize;

        // Setup
        IsLeadString := '{"PropertyId":"Integer {37829b75-e5e4-4582-ae12-36f754e4bd7b} Name IsLead","Value":"1"}';

        // Exercise
        IsLead := GraphCollectionMgtContact.GetIsLead(IsLeadString);

        // Verify
        Assert.IsTrue(IsLead, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsPartnerEmptyString()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsPartnerString: Text;
        IsPartner: Boolean;
    begin
        Initialize;

        // Setup
        IsPartnerString := '{}';

        // Exercise
        IsPartner := GraphCollectionMgtContact.GetIsPartner(IsPartnerString);

        // Verify
        Assert.IsFalse(IsPartner, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsPartnerFalseOnWrongProperty()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsPartnerString: Text;
        IsPartner: Boolean;
    begin
        Initialize;

        // Setup
        IsPartnerString := '{"PropertyId":"Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor","Value":"1"}';

        // Exercise
        IsPartner := GraphCollectionMgtContact.GetIsPartner(IsPartnerString);

        // Verify
        Assert.IsFalse(IsPartner, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsPartnerFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsPartnerString: Text;
        IsPartner: Boolean;
    begin
        Initialize;

        // Setup
        IsPartnerString := '{"PropertyId":"Integer {65ebabde-6946-455f-b918-a88ee36182a9} Name IsPartner","Value":"0"}';

        // Exercise
        IsPartner := GraphCollectionMgtContact.GetIsPartner(IsPartnerString);

        // Verify
        Assert.IsFalse(IsPartner, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIsPartnerTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsPartnerString: Text;
        IsPartner: Boolean;
    begin
        Initialize;

        // Setup
        IsPartnerString := '{"PropertyId":"Integer {65ebabde-6946-455f-b918-a88ee36182a9} Name IsPartner","Value":"1"}';

        // Exercise
        IsPartner := GraphCollectionMgtContact.GetIsPartner(IsPartnerString);

        // Verify
        Assert.IsTrue(IsPartner, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetContactCommentLineEmpty()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        Contact.Insert(true);

        // Exercise
        PersonalNotesString := GraphCollectionMgtContact.GetContactComments(Contact);

        // Verify
        Assert.AreEqual('', PersonalNotesString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetContactCommentLineEmptyLine()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        Contact.Insert(true);
        InsertContactCommentLine(Contact."No.", '');

        // Exercise
        PersonalNotesString := GraphCollectionMgtContact.GetContactComments(Contact);

        // Verify
        Assert.AreEqual(CrLf, PersonalNotesString, '');
        AssertPersonContactComments(Contact, PersonalNotesString, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetContactCommentLineOneLine()
    var
        Contact: Record Contact;
        DummyRlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        Contact.Insert(true);
        InsertContactCommentLine(Contact."No.",
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyRlshpMgtCommentLine.Comment)),
            1, MaxStrLen(DummyRlshpMgtCommentLine.Comment)));

        // Exercise
        PersonalNotesString := GraphCollectionMgtContact.GetContactComments(Contact);

        // Verify;
        AssertPersonContactComments(Contact, PersonalNotesString, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetContactCommentLineMultiLine()
    var
        Contact: Record Contact;
        DummyRlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        Contact.Insert(true);
        InsertContactCommentLine(Contact."No.",
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyRlshpMgtCommentLine.Comment)),
            1, MaxStrLen(DummyRlshpMgtCommentLine.Comment)));
        InsertContactCommentLine(Contact."No.", CopyStr(LibraryUtility.GenerateRandomText(79), 1, 79));
        InsertContactCommentLine(Contact."No.", '');
        InsertContactCommentLine(Contact."No.", '');
        InsertContactCommentLine(Contact."No.",
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyRlshpMgtCommentLine.Comment)),
            1, MaxStrLen(DummyRlshpMgtCommentLine.Comment)));
        InsertContactCommentLine(Contact."No.", '');
        InsertContactCommentLine(Contact."No.",
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyRlshpMgtCommentLine.Comment)),
            1, MaxStrLen(DummyRlshpMgtCommentLine.Comment)));

        // Exercise
        PersonalNotesString := GraphCollectionMgtContact.GetContactComments(Contact);

        // Verify;
        AssertPersonContactComments(Contact, PersonalNotesString, 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetContactCommentLineEmpty()
    var
        Contact: Record Contact;
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        Contact.Insert(true);

        // Exercise
        GraphCollectionMgtContact.SetContactComments(Contact, '');

        // Verify
        RlshpMgtCommentLine.SetRange("Table Name", RlshpMgtCommentLine."Table Name"::Contact);
        RlshpMgtCommentLine.SetRange("No.", Contact."No.");
        Assert.RecordIsEmpty(RlshpMgtCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetContactCommentLineEmptyLine()
    var
        Contact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        Contact.Insert(true);

        // Exercise
        PersonalNotesString := CrLf;
        GraphCollectionMgtContact.SetContactComments(Contact, PersonalNotesString);

        // Verify
        AssertPersonContactComments(Contact, PersonalNotesString, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetContactCommentLineOneLine()
    var
        Contact: Record Contact;
        DummyRlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        Contact.Insert(true);

        // Exercise
        PersonalNotesString := LibraryUtility.GenerateRandomText(MaxStrLen(DummyRlshpMgtCommentLine.Comment));
        GraphCollectionMgtContact.SetContactComments(Contact, PersonalNotesString);

        // Verify
        AssertPersonContactComments(Contact, PersonalNotesString, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetContactCommentLineMultiLine()
    var
        Contact: Record Contact;
        DummyRlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        PersonalNotesString: Text;
    begin
        Initialize;

        // Setup
        Contact.Insert(true);

        // Exercise
        PersonalNotesString := LibraryUtility.GenerateRandomText(MaxStrLen(DummyRlshpMgtCommentLine.Comment));
        PersonalNotesString += CrLf + LibraryUtility.GenerateRandomText(79);
        PersonalNotesString += CrLf;
        PersonalNotesString += CrLf;
        PersonalNotesString += CrLf + LibraryUtility.GenerateRandomText(MaxStrLen(DummyRlshpMgtCommentLine.Comment));
        PersonalNotesString += CrLf;
        PersonalNotesString += CrLf + LibraryUtility.GenerateRandomText(MaxStrLen(DummyRlshpMgtCommentLine.Comment));
        GraphCollectionMgtContact.SetContactComments(Contact, PersonalNotesString);

        // Verify
        AssertPersonContactComments(Contact, PersonalNotesString, 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactGivenNameInitValueSpace()
    var
        GraphContact: Record "Graph Contact";
    begin
        Initialize;

        // Setup

        // Exercise
        GraphContact.Insert(true);

        // Verify
        Assert.AreEqual(' ', GraphContact.GivenName, 'GivenName is required and initial value must be equal to a space');
        Assert.AreNotEqual('', GraphContact.GivenName, 'GivenName is required and initial value must be equal to a space');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasBusinessTypeFalse()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsFalse(GraphCollectionMgtContact.HasBusinessType(GraphContact.GetBusinessTypeString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasBusinessTypeTrue()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.SetBusinessTypeString(GraphCollectionMgtContact.AddBusinessType(BusinessType::Individual));
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsTrue(GraphCollectionMgtContact.HasBusinessType(GraphContact.GetBusinessTypeString),
          'BusinessType is a required field and must be present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetContactBusinessTypeIndividual()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
    begin
        Initialize;

        // Setup
        GraphContact.SetBusinessTypeString(GraphCollectionMgtContact.AddBusinessType(BusinessType::Individual));
        GraphContact.Insert(true);

        // Exercise
        GraphCollectionMgtContact.TryGetBusinessTypeValue(GraphContact.GetBusinessTypeString, Value);

        // Verify
        Assert.AreEqual(Format(BusinessType::Individual, 0, 0), Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetContactBusinessTypeCompany()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
    begin
        Initialize;

        // Setup
        GraphContact.SetBusinessTypeString(GraphCollectionMgtContact.AddBusinessType(BusinessType::Company));
        GraphContact.Insert(true);

        // Exercise
        GraphCollectionMgtContact.TryGetBusinessTypeValue(GraphContact.GetBusinessTypeString, Value);

        // Verify
        Assert.AreEqual(Format(BusinessType::Company, 0, 0), Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetContactBusinessTypeBlank()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        BusinessTypeString: Text;
    begin
        // Setup
        BusinessTypeString := '{  "PropertyId": "String {bdba944b-fc2b-47a1-8ba4-cafc4ae13ea2} Name BusinessType",  "Value": ""}';

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetBusinessTypeValue(BusinessTypeString, Value);

        // Verify
        Assert.ExpectedError(''''' is not an option. The existing options are: Company,Individual');
        Assert.AreEqual('', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetContactBusinessTypeNone()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        BusinessTypeString: Text;
    begin
        // Setup
        BusinessTypeString := '{  "PropertyId": "String {bdba944b-fc2b-47a1-8ba4-cafc4ae13ea2} Name BusinessType",  "Value": "None"}';

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetBusinessTypeValue(BusinessTypeString, Value);

        // Verify
        Assert.ExpectedError('''None'' is not an option. The existing options are: Company,Individual');
        Assert.AreEqual('None', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetContactBusinessTypeWrongPropertyId()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        BusinessTypeString: Text;
    begin
        // Setup
        BusinessTypeString := StrSubstNo('{  "PropertyId": "String %1 Name BusinessType",  "Value": "Company"}', CreateGuid);

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetBusinessTypeValue(BusinessTypeString, Value);

        // Verify
        Assert.ExpectedError('The PropertyId is not correct.');
        Assert.AreEqual('', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsCustomerFalse()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsFalse(GraphCollectionMgtContact.HasIsCustomer(GraphContact.GetIsCustomerString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsCustomerTrue()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.SetIsCustomerString(GraphCollectionMgtContact.AddIsCustomer(true));
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsTrue(GraphCollectionMgtContact.HasIsCustomer(GraphContact.GetIsCustomerString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsVendorFalse()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsFalse(GraphCollectionMgtContact.HasIsVendor(GraphContact.GetIsVendorString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsVendorTrue()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.SetIsVendorString(GraphCollectionMgtContact.AddIsVendor(true));
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsTrue(GraphCollectionMgtContact.HasIsVendor(GraphContact.GetIsVendorString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsBankFalse()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsFalse(GraphCollectionMgtContact.HasIsBank(GraphContact.GetIsBankString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsBankTrue()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.SetIsBankString(GraphCollectionMgtContact.AddIsBank(true));
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsTrue(GraphCollectionMgtContact.HasIsBank(GraphContact.GetIsBankString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsContactFalse()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsFalse(GraphCollectionMgtContact.HasIsContact(GraphContact.GetIsContactString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsLeadFalse()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsFalse(GraphCollectionMgtContact.HasIsLead(GraphContact.GetIsLeadString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGraphContactHasIsPartnerFalse()
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        Initialize;

        // Setup
        GraphContact.Insert(true);

        // Exercise

        // Verify
        Assert.IsFalse(GraphCollectionMgtContact.HasIsPartner(GraphContact.GetIsPartnerString), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsCustomerWrongPropertyId()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsCustomerString: Text;
    begin
        // Setup
        IsCustomerString := StrSubstNo('{  "PropertyId": "String %1 Name IsCustomer",  "Value": "1"}', CreateGuid);

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsCustomerValue(IsCustomerString, Value);

        // Verify
        Assert.ExpectedError('The PropertyId is not correct.');
        Assert.AreEqual('', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsVendorWrongPropertyId()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsVendorString: Text;
    begin
        // Setup
        IsVendorString := StrSubstNo('{  "PropertyId": "String %1 Name IsVendor",  "Value": "1"}', CreateGuid);

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsVendorValue(IsVendorString, Value);

        // Verify
        Assert.ExpectedError('The PropertyId is not correct.');
        Assert.AreEqual('', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsBankWrongPropertyId()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsBankString: Text;
    begin
        // Setup
        IsBankString := StrSubstNo('{  "PropertyId": "String %1 Name IsBank",  "Value": "1"}', CreateGuid);

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsBankValue(IsBankString, Value);

        // Verify
        Assert.ExpectedError('The PropertyId is not correct.');
        Assert.AreEqual('', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsContactWrongPropertyId()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsContactString: Text;
    begin
        // Setup
        IsContactString := StrSubstNo('{  "PropertyId": "String %1 Name IsContact",  "Value": "1"}', CreateGuid);

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsContactValue(IsContactString, Value);

        // Verify
        Assert.ExpectedError('The PropertyId is not correct.');
        Assert.AreEqual('', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsLeadWrongPropertyId()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsLeadString: Text;
    begin
        // Setup
        IsLeadString := StrSubstNo('{  "PropertyId": "String %1 Name IsLead",  "Value": "1"}', CreateGuid);

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsLeadValue(IsLeadString, Value);

        // Verify
        Assert.ExpectedError('The PropertyId is not correct.');
        Assert.AreEqual('', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsPartnerWrongPropertyId()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsPartnerString: Text;
    begin
        // Setup
        IsPartnerString := StrSubstNo('{  "PropertyId": "String %1 Name IsPartner",  "Value": "1"}', CreateGuid);

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsPartnerValue(IsPartnerString, Value);

        // Verify
        Assert.ExpectedError('The PropertyId is not correct.');
        Assert.AreEqual('', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsCustomerTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsCustomerString: Text;
    begin
        // Setup
        IsCustomerString := GraphCollectionMgtContact.AddIsCustomer(true);

        // Exercise
        GraphCollectionMgtContact.TryGetIsCustomerValue(IsCustomerString, Value);

        // Verify
        Assert.AreEqual('1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsVendorTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsVendorString: Text;
    begin
        // Setup
        IsVendorString := GraphCollectionMgtContact.AddIsVendor(true);

        // Exercise
        GraphCollectionMgtContact.TryGetIsVendorValue(IsVendorString, Value);

        // Verify
        Assert.AreEqual('1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsBankTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsBankString: Text;
    begin
        // Setup
        IsBankString := GraphCollectionMgtContact.AddIsBank(true);

        // Exercise
        GraphCollectionMgtContact.TryGetIsBankValue(IsBankString, Value);

        // Verify
        Assert.AreEqual('1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsContactTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsContactString: Text;
    begin
        // Setup
        IsContactString := '{  "PropertyId": "Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact",  "Value": "1"}';

        // Exercise
        GraphCollectionMgtContact.TryGetIsContactValue(IsContactString, Value);

        // Verify
        Assert.AreEqual('1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsLeadTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsLeadString: Text;
    begin
        // Setup
        IsLeadString := '{  "PropertyId": "Integer {37829b75-e5e4-4582-ae12-36f754e4bd7b} Name IsLead",  "Value": "1"}';

        // Exercise
        GraphCollectionMgtContact.TryGetIsLeadValue(IsLeadString, Value);

        // Verify
        Assert.AreEqual('1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsPartnerTrue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsPartnerString: Text;
    begin
        // Setup
        IsPartnerString := '{  "PropertyId": "Integer {65ebabde-6946-455f-b918-a88ee36182a9} Name IsPartner",  "Value": "1"}';

        // Exercise
        GraphCollectionMgtContact.TryGetIsPartnerValue(IsPartnerString, Value);

        // Verify
        Assert.AreEqual('1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsCustomerFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsCustomerString: Text;
    begin
        // Setup
        IsCustomerString := GraphCollectionMgtContact.AddIsCustomer(false);

        // Exercise
        GraphCollectionMgtContact.TryGetIsCustomerValue(IsCustomerString, Value);

        // Verify
        Assert.AreEqual('0', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsVendorFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsVendorString: Text;
    begin
        // Setup
        IsVendorString := GraphCollectionMgtContact.AddIsVendor(false);

        // Exercise
        GraphCollectionMgtContact.TryGetIsVendorValue(IsVendorString, Value);

        // Verify
        Assert.AreEqual('0', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsBankFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsBankString: Text;
    begin
        // Setup
        IsBankString := GraphCollectionMgtContact.AddIsBank(false);

        // Exercise
        GraphCollectionMgtContact.TryGetIsBankValue(IsBankString, Value);

        // Verify
        Assert.AreEqual('0', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsContactFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsContactString: Text;
    begin
        // Setup
        IsContactString := '{  "PropertyId": "Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact",  "Value": "0"}';

        // Exercise
        GraphCollectionMgtContact.TryGetIsContactValue(IsContactString, Value);

        // Verify
        Assert.AreEqual('0', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsLeadFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsLeadString: Text;
    begin
        // Setup
        IsLeadString := '{  "PropertyId": "Integer {37829b75-e5e4-4582-ae12-36f754e4bd7b} Name IsLead",  "Value": "0"}';

        // Exercise
        GraphCollectionMgtContact.TryGetIsLeadValue(IsLeadString, Value);

        // Verify
        Assert.AreEqual('0', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsPartnerFalse()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsPartnerString: Text;
    begin
        // Setup
        IsPartnerString := '{  "PropertyId": "Integer {65ebabde-6946-455f-b918-a88ee36182a9} Name IsPartner",  "Value": "0"}';

        // Exercise
        GraphCollectionMgtContact.TryGetIsPartnerValue(IsPartnerString, Value);

        // Verify
        Assert.AreEqual('0', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsCustomerWrongValue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsCustomerString: Text;
    begin
        // Setup
        IsCustomerString := '{  "PropertyId": "Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer",  "Value": "-1"}';

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsCustomerValue(IsCustomerString, Value);

        // Verify
        Assert.ExpectedError('The value "-1" can''t be evaluated into type Boolean.');
        Assert.AreEqual('-1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsVendorWrongValue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsVendorString: Text;
    begin
        // Setup
        IsVendorString := '{  "PropertyId": "Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor",  "Value": "-1"}';

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsVendorValue(IsVendorString, Value);

        // Verify
        Assert.ExpectedError('The value "-1" can''t be evaluated into type Boolean.');
        Assert.AreEqual('-1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsBankWrongValue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsBankString: Text;
    begin
        // Setup
        IsBankString := '{  "PropertyId": "Integer {a8ef117a-16d9-4cc6-965a-d2fbe0177e61} Name IsBank",  "Value": "-1"}';

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsBankValue(IsBankString, Value);

        // Verify
        Assert.ExpectedError('The value "-1" can''t be evaluated into type Boolean.');
        Assert.AreEqual('-1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsContactWrongValue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsContactString: Text;
    begin
        // Setup
        IsContactString := '{  "PropertyId": "Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact",  "Value": "-1"}';

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsContactValue(IsContactString, Value);

        // Verify
        Assert.ExpectedError('The value "-1" can''t be evaluated into type Boolean.');
        Assert.AreEqual('-1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsLeadWrongValue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsLeadString: Text;
    begin
        // Setup
        IsLeadString := '{  "PropertyId": "Integer {37829b75-e5e4-4582-ae12-36f754e4bd7b} Name IsLead",  "Value": "-1"}';

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsLeadValue(IsLeadString, Value);

        // Verify
        Assert.ExpectedError('The value "-1" can''t be evaluated into type Boolean.');
        Assert.AreEqual('-1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetIsPartnerWrongValue()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        IsPartnerString: Text;
    begin
        // Setup
        IsPartnerString := '{  "PropertyId": "Integer {65ebabde-6946-455f-b918-a88ee36182a9} Name IsPartner",  "Value": "-1"}';

        // Exercise
        asserterror GraphCollectionMgtContact.TryGetIsPartnerValue(IsPartnerString, Value);

        // Verify
        Assert.ExpectedError('The value "-1" can''t be evaluated into type Boolean.');
        Assert.AreEqual('-1', Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDecimalDifferentRegionalSettings()
    var
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        SalesLineRecordRef: RecordRef;
        AmountFieldRef: FieldRef;
        ExpectedDecimal: Decimal;
        PropertyName: Text;
        Success: Boolean;
        CurrentGlobalLanguage: Integer;
    begin
        // Setup
        ExpectedDecimal := LibraryUtility.GenerateRandomFraction;
        PropertyName := 'testDecimal';
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, PropertyName, ExpectedDecimal);

        SalesLineRecordRef.Open(DATABASE::"Sales Line");
        AmountFieldRef := SalesLineRecordRef.Field(SalesLine.FieldNo(Amount));

        CurrentGlobalLanguage := GlobalLanguage;

        // Switch to Danish to get a comma decimal separator
        GlobalLanguage(1030);

        // Exercise
        Success := JSONManagement.GetPropertyValueFromJObjectByPathSetToFieldRef(JsonObject, PropertyName, AmountFieldRef);
        GlobalLanguage(CurrentGlobalLanguage);

        // Verify
        Assert.AreEqual(Format(AmountFieldRef.Value, 0, 9), Format(ExpectedDecimal, 0, 9), 'Value was parsed in a wrong way');
        Assert.IsTrue(Success, 'Function should return true for success');
    end;

    local procedure VerifyContactAddress(Contact: Record Contact; Address: Text[50]; Address2: Text[50]; City: Text[30]; State: Text[30]; CountryOrRegion: Code[10]; PostalCode: Code[10])
    begin
        Contact.TestField(Address, Address);
        Contact.TestField("Address 2", Address2);
        Contact.TestField(City, City);
        Contact.TestField(County, State);
        Contact.TestField("Country/Region Code", CountryOrRegion);
        Contact.TestField("Post Code", PostalCode);
    end;

    local procedure VerifyContactAltAddress(ContactAltAddress: Record "Contact Alt. Address"; Address: Text[50]; Address2: Text[50]; City: Text[30]; State: Text[30]; CountryOrRegion: Code[10]; PostalCode: Code[10])
    begin
        ContactAltAddress.TestField(Address, Address);
        ContactAltAddress.TestField("Address 2", Address2);
        ContactAltAddress.TestField(City, City);
        ContactAltAddress.TestField(County, State);
        ContactAltAddress.TestField("Country/Region Code", CountryOrRegion);
        ContactAltAddress.TestField("Post Code", PostalCode);
    end;

    local procedure InsertContactCommentLine(ContactNo: Code[20]; Comment: Text[80])
    var
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        RlshpMgtCommentLine.SetRange("Table Name", RlshpMgtCommentLine."Table Name"::Contact);
        RlshpMgtCommentLine.SetRange("No.", ContactNo);
        if RlshpMgtCommentLine.FindLast then;
        RlshpMgtCommentLine."Table Name" := RlshpMgtCommentLine."Table Name"::Contact;
        RlshpMgtCommentLine."No." := ContactNo;
        RlshpMgtCommentLine."Line No." += 10000;
        RlshpMgtCommentLine.Comment := Comment;
        RlshpMgtCommentLine.Insert(true);
    end;

    local procedure AssertPersonContactComments(Contact: Record Contact; PersonalNotesString: Text; ExpectedNoOfLines: Integer)
    var
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        PNLine: Text;
        FromPos: Integer;
        ActualNoOfLines: Integer;
    begin
        FromPos := 1;
        RlshpMgtCommentLine.SetRange("Table Name", RlshpMgtCommentLine."Table Name"::Contact);
        RlshpMgtCommentLine.SetRange("No.", Contact."No.");
        RlshpMgtCommentLine.FindSet;
        repeat
            PNLine := CopyStr(PersonalNotesString, FromPos, StrLen(RlshpMgtCommentLine.Comment));
            Assert.AreEqual(StrLen(RlshpMgtCommentLine.Comment), StrLen(PNLine), '');
            Assert.AreEqual(RlshpMgtCommentLine.Comment, PNLine, '');
            FromPos += StrLen(RlshpMgtCommentLine.Comment) + StrLen(CrLf);
            ActualNoOfLines += 1;
        until RlshpMgtCommentLine.Next = 0;
        Assert.AreEqual(ExpectedNoOfLines, ActualNoOfLines, 'wrong number of lines');
    end;

    local procedure BuildTwoEmailAddressesString(Name1: Text; Address1: Text; Name2: Text; Address2: Text): Text
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        GraphCollectionMgtContact.InitializeCollection('');
        GraphCollectionMgtContact.AddEmailAddress(Name1, Address1);
        GraphCollectionMgtContact.AddEmailAddress(Name2, Address2);
        exit(GraphCollectionMgtContact.WriteCollectionToString);
    end;
}

