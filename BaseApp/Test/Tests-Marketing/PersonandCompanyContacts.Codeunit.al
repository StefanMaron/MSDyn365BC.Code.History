codeunit 134626 "Person and Company Contacts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Contact] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        CompanyNameMissingErr: Label 'Company No. must have a value in Contact: No.=%1. It cannot be zero or empty.', Comment = 'Company No. must have a value in Contact: No.=CT000258. It cannot be zero or empty.';
        CreateCustomerFromContactQst: Label 'Do you want to create a contact as a customer using a customer template?';
        RelatedRecordIsCreatedMsg: Label 'The %1 record has been created.', Comment = 'The Customer record has been created.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        BusinessRelationsNotZeroErr: Label 'No. of Business Relations must be equal to ''0''  in Contact: No.=%1. Current value is ''1''.';
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure CreatePersonContactNotCreateCustomerAutomatically()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Setup
        Initialize;

        // Exercise
        CreateContactUsingContactCard(Contact);

        // Verify
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        Assert.RecordIsEmpty(ContactBusinessRelation);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesAtCreatingCustomerFromContact,CustomerTemplateListModalPageHandler,DismissMessageAboutCreatingCustomer')]
    [Scope('OnPrem')]
    procedure CreateCustomerForPersonContactWithSameDetails()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        Initialize;

        // Setup
        CreateContactUsingContactCard(Contact);
        LibraryGraphSync.EditContactBasicDetails(Contact);
        LibraryGraphSync.EditContactAddressDetails(Contact);

        // Exercise
        CreateCustomerFromContactUsingContactCard(Contact);

        // Verify
        AssertContactBusinessRelationExists(ContactBusinessRelation, Contact."No.");
        AssertCustomerDeailsAreEqualToContactDetails(ContactBusinessRelation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorForPersonContactFails()
    var
        Contact: Record Contact;
    begin
        Initialize;

        // Setup
        CreateContactUsingContactCard(Contact);

        // Exercise
        asserterror CreateVendorFromContactUsingContactCard(Contact);

        // Verify
        Assert.ExpectedError(StrSubstNo(CompanyNameMissingErr, Contact."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateBankForPersonContactFails()
    var
        Contact: Record Contact;
    begin
        Initialize;

        // Setup
        CreateContactUsingContactCard(Contact);

        // Exercise
        asserterror CreateBankAccountFromContactUsingContactCard(Contact);

        // Verify
        Assert.ExpectedError(StrSubstNo(CompanyNameMissingErr, Contact."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetCompanyWithSameNameAsContactToCompanyName()
    var
        PersContact: Record Contact;
        CompContact: Record Contact;
    begin
        // [SCENARIO 382416] If there are Personal and Company Contact with the same name, it should be possible to set this name as Company Name in Personal Contact
        Initialize;

        // [GIVEN] Personal Contact with the name "Stan"
        LibraryMarketing.CreatePersonContact(PersContact);
        PersContact.Validate(Name, CopyStr(PersContact.Name, 1, 1));
        PersContact.Modify(true);

        // [GIVEN] Company Contact with the name "Stan"
        LibraryMarketing.CreateCompanyContact(CompContact);
        CompContact.Validate(Name, CopyStr(CompContact.Name, 1, 1));
        CompContact.Modify(true);

        // [WHEN] "Stan" is specified as "Company Name" in Personal Contact
        PersContact.Validate("Company Name", CompContact.Name);

        // [THEN] "Stan" Company is set as Company Name in Personal Contact
        PersContact.TestField("Company Name", CompContact.Name);
    end;

    [Test]
    [HandlerFunctions('DismissMessageAboutCreatingCustomer')]
    [Scope('OnPrem')]
    procedure UpdateQuotesOnlyUpdatesForCorrectContact()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 221218] When creating a Customer from a Contact not tied to a company, only that contact's quotes should be updated
        Initialize;

        // Setup
        // [GIVEN] A Quote for a Customer created from a person Contact not linked to a Company
        SetUpCustomerTemplate;
        CreateContactAndCustomer(Contact, Customer);
        Contact.TestField("Company No.", '');
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, Customer."No.");

        // Exercise
        // [WHEN] A second Customer is created from a person Contact not linked to a Company
        CreateContactAndCustomer(Contact2, Customer2);
        Contact2.TestField("Company No.", '');

        // Verify
        // [THEN] The Quote is still assigned to the first Customer
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.TestField("Sell-to Customer No.", Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ConfigTemplatesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyContactOfCustomerCreatedFromTepmplate()
    var
        MiniCustomerTemplate: Record "Mini Customer Template";
        Customer: Record Customer;
        ConfigTemplateHeader: Record "Config. Template Header";
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [Rapid Start]
        // [SCENARIO 287941] Customer's Contact field "Type" is equal to Company when Customer created from template
        Initialize;

        // [GIVEN] Customer template with field's "Contact Type" Default Value set to Person
        CreateConfigTemplate(ConfigTemplateHeader);

        // [WHEN] Customer with contact "C" created from template
        LibraryVariableStorage.Enqueue(ConfigTemplateHeader.Code);
        MiniCustomerTemplate.NewCustomerFromTemplate(Customer);

        // [THEN] Contact's "C" field "Type" is equal to Company
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");
        Contact.TestField(Type, Contact.Type::Company);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CutomerCreatedFromContactWitNoEqualToNoOfExistingCustomer()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        CustomerTemplate: Record "Customer Template";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 285903] Stan creates new Customer from Contact with "No." equal to existing Customer "No."
        Initialize;

        // [GIVEN] Customer and Contact with No. "X"
        CustomerNo := LibrarySales.CreateCustomerNo;
        Contact.Init();
        Contact."No." := CustomerNo;
        Contact.Insert(true);

        // [WHEN] Stan tries to create Customer from Contact
        Contact.SetHideValidationDialog(true);
        LibrarySales.CreateCustomerTemplate(CustomerTemplate);
        Contact.CreateCustomer(CustomerTemplate.Code);

        // [THEN] Customer is created
        ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Customer, Contact."No.");
        Customer.Get(ContactBusinessRelation."No.");
    end;

    [Test]
    [HandlerFunctions('NameDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PersonNameAssistEditForNewContact()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        FirstName: Text;
        MiddleName: Text;
        Surname: Text;
    begin
        // [SCENARIO 285982] Name fields are populated on Name details page when opened from newly created Contact
        Initialize;

        // [GIVEN] New Contact Card page opened with "Type" set to 'Person' and "Name" field set to 'X Y Z'
        FirstName := LibraryUtility.GenerateGUID;
        MiddleName := LibraryUtility.GenerateGUID;
        Surname := LibraryUtility.GenerateGUID;

        ContactCard.OpenNew;
        ContactCard.Type.SetValue(Contact.Type::Person);
        ContactCard.Name.SetValue(StrSubstNo('%1 %2 %3', FirstName, MiddleName, Surname));

        // [WHEN] Name details page opened by pressing AssitEdit near "Name" field
        ContactCard.Name.AssistEdit;

        // [THEN] Name details page Name fields are equal to X, Y, Z respectively
        Assert.AreEqual(LibraryVariableStorage.DequeueText, FirstName, '');
        Assert.AreEqual(LibraryVariableStorage.DequeueText, MiddleName, '');
        Assert.AreEqual(LibraryVariableStorage.DequeueText, Surname, '');
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyNameAssistEditForNewContact()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        CompanyName: Text;
    begin
        // [SCENARIO 285982] Name field is populated on Company details page when opened from newly created Contact
        Initialize;

        // [GIVEN] New Contact Card page opened with "Type" set to 'Company' and "Name" field set to 'X'
        CompanyName := LibraryUtility.GenerateGUID;

        ContactCard.OpenNew;
        ContactCard.Type.SetValue(Contact.Type::Company);
        ContactCard.Name.SetValue(CompanyName);

        // [WHEN] Company details page opened by pressing AssitEdit near "Name" field
        ContactCard.Name.AssistEdit;

        // [THEN] Company details page Name field is equal to X
        Assert.AreEqual(LibraryVariableStorage.DequeueText, CompanyName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeTypeOfNewContactLinkedToCustomer()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 288436] Error is raised when trying to change Contact Type to Person, when Contact has Business relation with Customer
        Initialize;

        // [GIVEN] Newly inserted Contact, Customer and BusinessRelation between them
        CustomerNo := LibrarySales.CreateCustomerNo;

        Contact.Init();
        Contact.Validate(Name, CustomerNo);
        Contact.Insert(true);

        LibraryMarketing.CreateBusinessRelationBetweenContactAndCustomer(ContactBusinessRelation, Contact."No.", CustomerNo);

        // [WHEN] Type of Contact changed to Person
        Contact.Type := Contact.Type::Person;
        asserterror Contact.TypeChange;

        // [THEN] Error is raised
        Assert.AreEqual('TestField', GetLastErrorCode, '');
        Assert.AreEqual(StrSubstNo(BusinessRelationsNotZeroErr, Contact."No."), GetLastErrorText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyCompanyNameAssistEditDoesntOpen()
    var
        PersonContact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 299595] After invoking Assist Edit on an empty Company Name field, Company Details page doesn't open
        // [GIVEN] Created Person Contact without associating it to any Company No., and opened its Card
        LibraryMarketing.CreatePersonContact(PersonContact);
        ContactCard.OpenEdit;
        ContactCard.FILTER.SetFilter("No.", PersonContact."No.");

        // [WHEN] Invoke Assist Edit on a 'Company Name' field
        ContactCard."Company Name".AssistEdit;

        // [THEN] Company Details page hasn't been opened
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ExistingCompanyNameAssistEditShowsProperly()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 299595] After invoking Assist Edit on a filled Company Name field, proper Company Details page is shown
        Initialize;

        // [GIVEN] Created Person Contact with associated Company, and opened its Card
        LibraryMarketing.CreateCompanyContact(CompanyContact);
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Modify();
        ContactCard.OpenEdit;
        ContactCard.FILTER.SetFilter("No.", PersonContact."No.");

        // [WHEN] Invoke Assist Edit on a 'Company Name' field
        ContactCard."Company Name".AssistEdit;

        // [THEN] 'Name' field on Company Details page equals Company's Name
        Assert.AreEqual(LibraryVariableStorage.DequeueText, CompanyContact.Name, '');
    end;

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    [Scope('OnPrem')]
    procedure NameAssistEditOnContactCardWithoutPermissions()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 285982] [Permissions] Name assist edit won't be opened when user don't have MODIFY permissions to Contact table
        Initialize;

        // [GIVEN] New contact with "First Name" = "Name", "Middle Name" = <blank> and "Last Name" = <blank>
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] User without Contact editing permisions
        LibraryLowerPermissions.SetO365Basic;
        LibraryLowerPermissions.SetRead;

        // [WHEN] User open Name Details assist edit dialog
        ContactCard.OpenEdit;
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        asserterror ContactCard.Name.AssistEdit;

        // [THEN] Error is raised, Name Details won't open
        // [THEN] Contact's "Name" = "First Name"
        Assert.ExpectedError('You do not have the following permissions on TableData Contact: Modify.');
        Assert.ExpectedErrorCode('TestWrapped:Permission');
    end;

    [Test]
    [HandlerFunctions('NameDetailsOnChangeModalPageHandler')]
    [TestPermissions(TestPermissions::Restrictive)]
    [Scope('OnPrem')]
    procedure NameAssistEditOnContactCardWithPermissions()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        FirstName: Text;
        MiddleName: Text;
        Surname: Text;
    begin
        // [SCENARIO 285982] [Permissions] Name assist edit will be opened when user don't have MODIFY permissions to Contact table
        Initialize();

        // [GIVEN] User setup with "First Name" = "F", "Middle Name" = "M" and "Last Name" = "L"
        FirstName := LibraryUtility.GenerateGUID();
        MiddleName := LibraryUtility.GenerateGUID();
        Surname := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(FirstName);
        LibraryVariableStorage.Enqueue(MiddleName);
        LibraryVariableStorage.Enqueue(Surname);

        // [GIVEN] New contact with "First Name" = "Name", "Middle Name" = <blank> and "Last Name" = <blank>
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] User with Contact editing permisions
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetCustomerEdit();

        // [WHEN] User sets "First Name" = "F", "Middle Name" = "M" and "Last Name" = "L" on Name Details assist edit dialog
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        ContactCard.Name.AssertEquals(Contact.Name);
        ContactCard.Name.AssistEdit();
        ContactCard.Name.AssertEquals(FirstName + ' ' + MiddleName + ' ' + Surname);
        ContactCard.Close();

        // [THEN] Contact's "Name" becomes "F M L"
        // [THEN] Contact's "First Name" = "F", "Middle Name" = "M" and "Last Name" = "L"
        Contact.Find();
        Contact.TestField("First Name", FirstName);
        Contact.TestField("Middle Name", MiddleName);
        Contact.TestField(Surname, Surname);
    end;

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    [Scope('OnPrem')]
    procedure CompanyNameAssistEditOnContactCardWithoutPermissions()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 285982] [Permissions] Company Name assist edit won't be opened when user don't have MODIFY permissions to Contact table
        Initialize();

        // [GIVEN] New contact with "Company Name" = "Name"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] User without Contact editing permisions
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetRead();

        // [WHEN] User open Name Details assist edit dialog
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        asserterror ContactCard."Company Name".AssistEdit();

        // [THEN] Error is raised, Name Details won't be open
        // [THEN] Contact's "Name" = "Company Name"
        Assert.ExpectedError('You do not have the following permissions on TableData Contact: Modify.');
        Assert.ExpectedErrorCode('TestWrapped:Permission');
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsOnChangeModalPageHandler')]
    [TestPermissions(TestPermissions::Restrictive)]
    [Scope('OnPrem')]
    procedure CompanyNameAssistEditOnContactCardWithPermissions()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        CompanyName: Text;
    begin
        // [SCENARIO 285982] [Permissions] Company Name assist edit will be opened when user don't have MODIFY permissions to Contact table
        Initialize();

        // [GIVEN] User setup with "Company Name" = "C"
        CompanyName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(CompanyName);

        // [GIVEN] New contact with "Company Name" = "Name"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] User with Contact editing permisions
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetCustomerEdit();

        // [WHEN] User sets "Company Name" = "C" on Name Details assist edit dialog
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        ContactCard."Company Name".AssertEquals(Contact."Company Name");
        ContactCard."Company Name".AssistEdit();
        ContactCard."Company Name".AssertEquals(CompanyName);
        ContactCard.Close();

        // [THEN] Contact's "Name" becomes "C"
        // [THEN] Contact's "Company Name" = "C"
        Contact.Find();
        Contact.TestField("Company Name", CompanyName);
    end;

    local procedure Initialize()
    begin
        LibraryGraphSync.DisableGraphSync;
    end;

    local procedure SetUpCustomerTemplate()
    var
        PaymentTerms: Record "Payment Terms";
        CustomerTemplate: Record "Customer Template";
        MarketingSetup: Record "Marketing Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PaymentTerms.FindFirst;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerTemplate.SetRange("Contact Type", CustomerTemplate."Contact Type"::Person);
        CustomerTemplate.FindFirst;
        CustomerTemplate."Payment Terms Code" := PaymentTerms.Code;
        CustomerTemplate."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        CustomerTemplate.Modify();
        MarketingSetup.Get();
        MarketingSetup."Cust. Template Person Code" := CustomerTemplate.Code;
        MarketingSetup.Modify();
    end;

    local procedure CreateConfigTemplate(var ConfigTemplateHeader: Record "Config. Template Header")
    var
        Customer: Record Customer;
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader.Validate("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.Modify(true);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        ConfigTemplateLine.Validate("Field ID", Customer.FieldNo("Contact Type"));
        ConfigTemplateLine.Validate("Default Value", 'Person');
        ConfigTemplateLine.Modify(true);
    end;

    local procedure CreateContactUsingContactCard(var Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
        ContactName: Text[50];
    begin
        ContactName := LibraryUtility.GenerateGUID;

        ContactCard.OpenNew;
        ContactCard.Type.SetValue(Contact.Type::Person);
        ContactCard.Name.SetValue(ContactName);
        ContactCard.Close;

        Contact.SetRange(Name, ContactName);
        Contact.FindFirst;
    end;

    local procedure CreateCustomerFromContactUsingContactCard(Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit;
        ContactCard.GotoRecord(Contact);
        ContactCard.CreateCustomer.Invoke;
        ContactCard.Close;
    end;

    local procedure CreateVendorFromContactUsingContactCard(Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit;
        ContactCard.GotoRecord(Contact);
        ContactCard.CreateVendor.Invoke;
        ContactCard.Close;
    end;

    local procedure CreateBankAccountFromContactUsingContactCard(Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit;
        ContactCard.GotoRecord(Contact);
        ContactCard.CreateBank.Invoke;
        ContactCard.Close;
    end;

    local procedure CreateContactAndCustomer(var Contact: Record Contact; var Customer: Record Customer)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        MarketingSetup.Get();
        Contact.CreateCustomer(MarketingSetup."Cust. Template Person Code");
        GetCustomerFromContact(Contact, Customer);
    end;

    local procedure GetCustomerFromContact(Contact: Record Contact; var Customer: Record Customer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        ContactBusinessRelation.Get(Contact."No.", MarketingSetup."Bus. Rel. Code for Customers");
        Customer.Get(ContactBusinessRelation."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesAtCreatingCustomerFromContact(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(CreateCustomerFromContactQst, Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateListModalPageHandler(var CustomerTemplateList: TestPage "Customer Template List")
    begin
        CustomerTemplateList.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DismissMessageAboutCreatingCustomer(Message: Text[1024])
    var
        Customer: Record Customer;
    begin
        Assert.ExpectedMessage(StrSubstNo(RelatedRecordIsCreatedMsg, Customer.TableCaption), Message);
    end;

    local procedure AssertContactBusinessRelationExists(var ContactBusinessRelation: Record "Contact Business Relation"; ContactNo: Code[20])
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "Contact No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.FindFirst;
    end;

    local procedure AssertCustomerDeailsAreEqualToContactDetails(ContactBusinessRelation: Record "Contact Business Relation")
    var
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        Contact.Get(ContactBusinessRelation."Contact No.");
        Customer.Get(ContactBusinessRelation."No.");
        AssertCustomerBasicDetailsAreEqualToContactBasicDetails(Customer, Contact);
        AssertCustomerAddressDetailsAreEqualToContactAddressDetails(Customer, Contact);
    end;

    local procedure AssertCustomerBasicDetailsAreEqualToContactBasicDetails(Customer: Record Customer; Contact: Record Contact)
    begin
        Customer.TestField(Name, Contact.Name);
        Customer.TestField("Name 2", Contact."Name 2");
        Customer.TestField("E-Mail", Contact."E-Mail");
        Customer.TestField("Home Page", Contact."Home Page");
    end;

    local procedure AssertCustomerAddressDetailsAreEqualToContactAddressDetails(Customer: Record Customer; Contact: Record Contact)
    begin
        Customer.TestField(Address, Contact.Address);
        Customer.TestField("Address 2", Contact."Address 2");
        Customer.TestField("Post Code", Contact."Post Code");
        Customer.TestField("Phone No.", Contact."Phone No.");
        Customer.TestField("Fax No.", Contact."Fax No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplatesModalPageHandler(var ConfigTemplates: TestPage "Config Templates")
    begin
        ConfigTemplates.GotoKey(LibraryVariableStorage.DequeueText);
        ConfigTemplates.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NameDetailsModalPageHandler(var NameDetails: TestPage "Name Details")
    begin
        LibraryVariableStorage.Enqueue(NameDetails."First Name".Value);
        LibraryVariableStorage.Enqueue(NameDetails."Middle Name".Value);
        LibraryVariableStorage.Enqueue(NameDetails.Surname.Value);
        NameDetails.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CompanyDetailsModalPageHandler(var CompanyDetails: TestPage "Company Details")
    begin
        LibraryVariableStorage.Enqueue(CompanyDetails.Name.Value);
        CompanyDetails.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NameDetailsOnChangeModalPageHandler(var NameDetails: TestPage "Name Details")
    begin
        NameDetails."First Name".SetValue(LibraryVariableStorage.DequeueText);
        NameDetails."Middle Name".SetValue(LibraryVariableStorage.DequeueText);
        NameDetails.Surname.SetValue(LibraryVariableStorage.DequeueText);
        NameDetails.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CompanyDetailsOnChangeModalPageHandler(var CompanyDetails: TestPage "Company Details")
    begin
        LibraryVariableStorage.Enqueue(CompanyDetails.Name.Value);
        CompanyDetails.Name.SetValue(LibraryVariableStorage.DequeueText);
        CompanyDetails.OK.Invoke();
    end;
}

