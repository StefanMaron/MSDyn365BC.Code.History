codeunit 136210 "Contact Employee"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Contact] [Employee]
    end;

    var
        Assert: Codeunit Assert;
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        TypePersonTestFieldErr: Label 'Type must be equal to ''Person''';
        PrivactBlockedTestFieldErr: Label 'they are marked as blocked due to privacy';
        ShownEmployeeCardErr: Label 'Wrong employee card is shown';
        ShownContactCardErr: Label 'Wrong contact card is shown';

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeFromPersonContactUT()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 353436] Employee was successfully created from the "Person" contact
        Initialize();

        // [GIVEN] Contact
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Create employee from contact
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [THEN] Employee created
        VerifyEmployeeUT(Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeFromPersonContactWithEmpty()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 353436] Employee was successfully created from the "Person" contact
        Initialize();

        // [GIVEN] Contact
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Create employee from contact
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [THEN] Employee created
        VerifyEmployeeUT(Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('EmployeeCreatedMessageHandler')]
    procedure EmployeeFromPersonContactWithMessage()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 353436] Information message is shown after employee was successfully created from contact
        Initialize();

        // [GIVEN] Contact
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Create employee from contact
        Contact.CreateEmployee();

        // [THEN] Employee created
        // [THEN] Information message is shown (verified in EmployeeCreatedMessageHandler)
        VerifyEmployeeUT(Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeFromPersonContactWithPrivacyBlockedUT()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 353436] Employee was not created from the "Person" contact with "Privacy Blocked" = true
        Initialize();

        // [GIVEN] Contact with "Privacy Blocked" = true
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Privacy Blocked", true);
        Contact.Modify(true);

        // [WHEN] Create employee from contact
        Contact.SetHideValidationDialog(true);
        asserterror Contact.CreateEmployee();

        // [THEN] Employee was not created
        Assert.ExpectedError(PrivactBlockedTestFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeFromCompanyContactUT()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 353436] Employee was not created from "Company" contact
        Initialize();

        // [GIVEN] Contact
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create employee from contact
        Contact.SetHideValidationDialog(true);
        asserterror Contact.CreateEmployee();

        // [THEN] Employee was not created
        Assert.ExpectedError(TypePersonTestFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('EmployeeLinkPageHandler')]
    procedure LinkEmployeeWithPersonContact()
    var
        Contact: Record Contact;
        Employee: Record Employee;
    begin
        // [SCENARIO 353436] Employee was successfully linked with the "Person" contact
        Initialize();

        // [GIVEN] Contact
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Employee
        LibraryHumanResource.CreateEmployee(Employee);
        LibraryVariableStorage.Enqueue(Employee."No.");

        // [WHEN] Link contact with employee (EmployeeLinkPageHandler)
        Contact.CreateEmployeeLink();

        // [THEN] Employee linked with contact
        VerifyEmployeeUT(Contact);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkEmployeeWithPersonContactWithPrivacyBlocked()
    var
        Contact: Record Contact;
        Employee: Record Employee;
    begin
        // [SCENARIO 353436] Employee was not linked with the "Person" contact with "Privacy Blocked" = true
        Initialize();

        // [GIVEN] Contact with "Privacy Blocked" = true
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Privacy Blocked", true);
        Contact.Modify(true);

        // [GIVEN] Employee
        LibraryHumanResource.CreateEmployee(Employee);

        // [WHEN] Link contact with employee
        asserterror Contact.CreateEmployeeLink();

        // [THEN] Employee was not linked with contact
        Assert.ExpectedError(PrivactBlockedTestFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkEmployeeWithCompanyContact()
    var
        Contact: Record Contact;
        Employee: Record Employee;
    begin
        // [SCENARIO 353436] Employee was not linked with the "Company" contact
        Initialize();

        // [GIVEN] Contact
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Employee
        LibraryHumanResource.CreateEmployee(Employee);

        // [WHEN] Link contact with employee
        asserterror Contact.CreateEmployeeLink();

        // [THEN] Employee was not linked with contact
        Assert.ExpectedError(TypePersonTestFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowEmployeeFromContactCardRelatedInformation()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        EmployeeCard: TestPage "Employee Card";
    begin
        // [SCENARIO 353436] Linked with contact employee card is shown through the "Navigate->Related Information->Customer/Vendor/Bank Acc./Employee" menu
        Initialize();

        // [GIVEN] Contact with linked employee
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [WHEN] Invoke "Navigate->Related Information->Customer/Vendor/Bank Acc./Employee"
        ContactCard.OpenView();
        ContactCard.GoToRecord(Contact);
        EmployeeCard.Trap();
        ContactCard."C&ustomer/Vendor/Bank Acc.".Invoke();

        // [THEN] Linked employee card is opened
        Assert.IsTrue(EmployeeCard."First Name".Value.Contains(Contact."First Name"), ShownEmployeeCardErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowEmployeeFromContactListRelatedInformation()
    var
        Contact: Record Contact;
        ContactList: TestPage "Contact List";
        EmployeeCard: TestPage "Employee Card";
    begin
        // [SCENARIO 353436] Linked with contact employee card is shown through the "Navigate->Related Information->Customer/Vendor/Bank Acc./Employee" menu
        Initialize();

        // [GIVEN] Contact with linked employee
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [WHEN] Invoke "Navigate->Related Information->Customer/Vendor/Bank Acc./Employee"
        ContactList.OpenView();
        ContactList.GoToRecord(Contact);
        EmployeeCard.Trap();
        ContactList."C&ustomer/Vendor/Bank Acc.".Invoke();

        // [THEN] Linked employee card is opened
        Assert.IsTrue(EmployeeCard."First Name".Value.Contains(Contact."First Name"), ShownEmployeeCardErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowContactFromEmployeeList()
    var
        Contact: Record Contact;
        Employee: Record Employee;
        ContBusRel: Record "Contact Business Relation";
        EmployeeList: TestPage "Employee List";
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 353436] Linked with employee contact card is shown from the employee list
        Initialize();

        // [GIVEN] Contact with linked employee
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [WHEN] Invoke "Contact" action on the employee list page
        ContBusRel.FindByContact(ContBusRel."Link to Table"::Employee, Contact."No.");
        Employee.Get(ContBusRel."No.");
        EmployeeList.OpenView();
        EmployeeList.GoToRecord(Employee);
        ContactCard.Trap();
        EmployeeList.Contact.Invoke();

        // [THEN] Linked contact card is opened
        Assert.IsTrue(ContactCard.Name.Value.Contains(Employee."First Name"), ShownContactCardErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowContactFromEmployeeCard()
    var
        Contact: Record Contact;
        Employee: Record Employee;
        ContBusRel: Record "Contact Business Relation";
        EmployeeCard: TestPage "Employee Card";
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 353436] Linked with employee contact card is shown from the employee card
        Initialize();

        // [GIVEN] Contact with linked employee
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.SetHideValidationDialog(true);
        Contact.CreateEmployee();

        // [WHEN] Invoke "Contact" action on the employee card page
        ContBusRel.FindByContact(ContBusRel."Link to Table"::Employee, Contact."No.");
        Employee.Get(ContBusRel."No.");
        EmployeeCard.OpenView();
        EmployeeCard.GoToRecord(Employee);
        ContactCard.Trap();
        EmployeeCard.Contact.Invoke();

        // [THEN] Linked contact card is opened
        Assert.IsTrue(ContactCard.Name.Value.Contains(Employee."First Name"), ShownContactCardErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTemplates.DisableTemplatesFeature();
        LibrarySetupStorage.Save(Database::"Marketing Setup");

        IsInitialized := true;
        Commit();
    end;

    local procedure VerifyEmployeeUT(Contact: Record Contact)
    var
        ContBusRel: Record "Contact Business Relation";
        Employee: Record Employee;
        MarketingSetup: Record "Marketing Setup";
    begin
        ContBusRel.FindByContact(ContBusRel."Link to Table"::Employee, Contact."No.");
        MarketingSetup.Get();
        Assert.AreEqual(MarketingSetup."Bus. Rel. Code for Employees", ContBusRel."Business Relation Code", 'Business relation code is wrong');
        Employee.Get(ContBusRel."No.");
        Assert.AreEqual(Contact."First Name", Employee."First Name", 'Employee contains wrong data');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeLinkPageHandler(var EmployeeLink: TestPage "Employee Link")
    begin
        EmployeeLink."No.".SetValue(LibraryVariableStorage.DequeueText());
        EmployeeLink.OK().Invoke();
    end;

    [MessageHandler]
    procedure EmployeeCreatedMessageHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(Msg = 'The Employee record has been created.', 'Wrong message after employee was created.');
    end;
}