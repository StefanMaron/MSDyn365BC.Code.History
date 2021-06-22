codeunit 134231 "ERM Bank Account"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Account] [UT]
        IsInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        WrongIBANErr: Label 'Wrong number in the field IBAN.';
        BankAccDeleteErr: Label 'You cannot delete this bank account because it is associated with one or more open ledger entries.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        IBANConfirmationMsg: Label 'The number %1 that you entered may not be a valid International Bank Account Number (IBAN). Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure CRUDBankAccount()
    var
        BankAccount: Record "Bank Account";
        AccountNo: Code[20];
        AccountName: Text[50];
    begin
        Initialize();
        // Create a new bank account
        Evaluate(AccountNo, LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("No."), DATABASE::"Bank Account"));
        Evaluate(AccountName, LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(Name), DATABASE::"Bank Account"));

        LibraryLowerPermissions.SetBanking;
        with BankAccount do begin
            "No." := AccountNo;
            Name := AccountNo;
            IBAN := FindIBAN;  // Value important for IT.
            Insert(true);
        end;

        LibraryLowerPermissions.SetFinancialReporting;
        // Verify it exists
        Assert.IsTrue(BankAccount.Get(AccountNo), 'Failed to find newly created bank account');

        // Update the bank account
        BankAccount.Validate(Name, AccountName);
        BankAccount.Modify(true);

        // Verify it got changed
        Assert.AreEqual(BankAccount.Name, AccountName, 'Bank account information did not get updated');

        LibraryLowerPermissions.SetOutsideO365Scope;
        // Delete the bank account
        BankAccount.Get(AccountNo);
        BankAccount.Delete(true);

        // Verify it no longer exists
        Assert.IsFalse(BankAccount.Get(AccountNo), 'Bank account still exists after deletion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRUDSWIFT()
    var
        SWIFTCode: Record "SWIFT Code";
        "Code": Code[20];
        Name: Text[100];
    begin
        Initialize();
        // Create a new SWIFT code
        Evaluate(Code, LibraryUtility.GenerateRandomCode(SWIFTCode.FieldNo(Code), DATABASE::"SWIFT Code"));
        Evaluate(Name, LibraryUtility.GenerateRandomCode(SWIFTCode.FieldNo(Name), DATABASE::"SWIFT Code"));

        LibraryLowerPermissions.SetBanking;
        SWIFTCode.Code := Code;
        SWIFTCode.Name := Code;
        SWIFTCode.Insert(true);

        // Verify it exists
        Assert.IsTrue(SWIFTCode.Get(Code), 'Failed to find newly created SWIFT Code');

        // Update record
        SWIFTCode.Validate(Name, Name);
        SWIFTCode.Modify(true);

        // Verify it got changed
        Assert.AreEqual(SWIFTCode.Name, Name, 'SWIFT code information did not get updated');

        LibraryLowerPermissions.SetOutsideO365Scope;
        // Delete record
        SWIFTCode.Get(Code);
        SWIFTCode.Delete(true);

        // Verify it no longer exists
        Assert.IsFalse(SWIFTCode.Get(Code), 'SWIFT code still exists after deletion');
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckBankAccIBANConfirmYes()
    begin
        // Purpose of the test is to modify IBAN field of table Bank Account and confirm Yes.
        LibraryLowerPermissions.SetO365Full;
        AssignBankAccIBANnumber(true);
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckBankAccIBANConfirmNo()
    begin
        // Purpose of the test is to modify IBAN field of table Bank Account and confirm No.
        LibraryLowerPermissions.SetO365Full;
        AssignBankAccIBANnumber(false);
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckVendBankAccIBANConfirmYes()
    begin
        // Purpose of the test is to modify IBAN field of table Vendor Bank Account and confirm Yes.
        LibraryLowerPermissions.SetO365Full;
        AssignVendBankAccIBANnumber(true);
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckVendBankAccIBANConfirmNo()
    begin
        // Purpose of the test is to modify IBAN field of table Vendor Bank Account and confirm No.
        LibraryLowerPermissions.SetO365Full;
        AssignVendBankAccIBANnumber(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendBankAccWithAssociatedOpenEntry()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [Vendor Bank Account] [UT] [Purchase]
        // [SCENARIO 378203] Vendor Bank Account cannot be deleted when it has associated open entries
        Initialize();

        // [GIVEN] Vendor with Vendor Bank Account "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        // [GIVEN] Opened Vendor Ledger Entry with "Recipient Bank Account" = "X"
        CreateVendLedgEntry(VendorBankAccount, true);

        // [WHEN] Delete Vendor Bank Account "X"
        LibraryLowerPermissions.SetBanking;
        asserterror VendorBankAccount.Delete(true);

        // [THEN] Error Message: You cannot delete this bank account because it is associated with one or more open ledger entries.
        Assert.ExpectedError(BankAccDeleteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustBankAccWithAssociatedOpenEntry()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [Customer Bank Account] [UT] [Sales]
        // [SCENARIO 378203] Customer Bank Account cannot be deleted when it has associated open entries
        Initialize();

        // [GIVEN] Customer with Customer Bank Account "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // [GIVEN] Opened Customer Ledger Entry with "Recipient Bank Account" = "X"
        CreateCustLedgEntry(CustomerBankAccount, true);

        // [WHEN] Delete Customer Bank Account "X"
        LibraryLowerPermissions.SetBanking;
        asserterror CustomerBankAccount.Delete(true);

        // [THEN] Error Message: You cannot delete this bank account because it is associated with one or more open ledger entries.
        Assert.ExpectedError(BankAccDeleteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendBankAccWithAssociatedClosedEntry()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorBankAccountCode: Code[20];
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 378203] Vendor Bank Account can be deleted when it has associated closed entries
        Initialize();

        // [GIVEN] Vendor with Vendor Bank Account "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccountCode := VendorBankAccount.Code;

        // [GIVEN] Closed Vendor Ledger Entry with "Recipient Bank Account" = "X"
        CreateVendLedgEntry(VendorBankAccount, false);

        // [WHEN] Delete Vendor Bank Account "X"
        VendorBankAccount.Delete(true);

        // [THEN] Closed entries are not deleted
        VendorLedgerEntry.Init;
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Recipient Bank Account", VendorBankAccountCode);
        VendorLedgerEntry.SetRange(Open, false);
        Assert.RecordIsNotEmpty(VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustBankAccWithAssociatedClosedEntry()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerBankAccountCode: Code[20];
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 378203] Customer Bank Account can be deleted when it has associated closed entries
        Initialize();

        // [GIVEN] Customer with Customer Bank Account "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccountCode := CustomerBankAccount.Code;

        // [GIVEN] Closed Customer Ledger Entry with "Recipient Bank Account" = "X"
        CreateCustLedgEntry(CustomerBankAccount, false);

        // [WHEN] Delete Customer Bank Account "X"
        CustomerBankAccount.Delete(true);

        // [THEN] Closed entries are not deleted
        CustLedgerEntry.Init;
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Recipient Bank Account", CustomerBankAccountCode);
        CustLedgerEntry.SetRange(Open, false);
        Assert.RecordIsNotEmpty(CustLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToBankAccount()
    var
        BankAccount: Record "Bank Account";
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Bank Account and new SWIFT Code created
        LibraryERM.CreateBankAccount(BankAccount);

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        CreateSWIFTCode(SWIFTCode);
        BankAccount.Validate("SWIFT Code", SWIFTCode.Code);
        BankAccount.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToCustBankAccount()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Customer with Customer Bank Account "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        CreateSWIFTCode(SWIFTCode);
        CustomerBankAccount.Validate("SWIFT Code", SWIFTCode.Code);
        CustomerBankAccount.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToVendAccount()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Vendor with Vendor Bank Account "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        VendorBankAccount.Validate("SWIFT Code", SWIFTCode.Code);
        VendorBankAccount.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToCompBankAccount()
    var
        CompanyInformation: Record "Company Information";
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Company Information
        CompanyInformation.Get;

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        CreateSWIFTCode(SWIFTCode);
        CompanyInformation.Validate("SWIFT Code", SWIFTCode.Code);
        CompanyInformation.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToEmplBankAccount()
    var
        Employee: Record Employee;
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Employee
        LibraryHumanResource.CreateEmployee(Employee);

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        CreateSWIFTCode(SWIFTCode);
        Employee.Validate("SWIFT Code", SWIFTCode.Code);
        Employee.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountPageBasicSetup()
    var
        BankAccountBalance: TestPage "Bank Account Balance";
    begin
        // [FEATURE] [UI] [Application Area]
        // [SCENARIO 203033] Balance lines page part musst be visible in Basic application area setup.
        LibraryApplicationArea.EnableBasicSetup;
        BankAccountBalance.OpenView;

        Assert.IsTrue(
          BankAccountBalance.BankAccBalanceLines."Period Start".Visible, 'BankAccBalanceLines."Period Start" must be visible');
        Assert.IsTrue(
          BankAccountBalance.BankAccBalanceLines."Period Name".Visible, 'BankAccBalanceLines."Period Name" must be visible');
        Assert.IsTrue(
          BankAccountBalance.BankAccBalanceLines.NetChange.Visible, 'BankAccBalanceLines.NetChange  must be visible');
        Assert.IsTrue(
          BankAccountBalance.BankAccBalanceLines."BankAcc.""Net Change (LCY)""".Visible, 'BankAccBalanceLines.NetChangeLCY must be visible');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure IBANWithoutPrefixValidation()
    var
        CompanyInformation: Record "Company Information";
        IBANCode: Code[100];
    begin
        // [SCENARIO 337588] IBAN '60050777122' does not pass validation since it does not have country code as prefix
        Initialize();

        IBANCode := '60050777122';

        LibraryVariableStorage.Enqueue(StrSubstNo(IBANConfirmationMsg, IBANCode));
        LibraryVariableStorage.Enqueue(false); // do not confirm invalid IBAN
        asserterror CompanyInformation.CheckIBAN(IBANCode);

        Assert.ExpectedError('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure IBANWithPrefixValidation()
    var
        CompanyInformation: Record "Company Information";
        IBANCode: Code[100];
    begin
        // [SCENARIO 337588] IBAN 'IT60050777122' does not pass checksum validation.
        Initialize();

        IBANCode := 'IT60050777122';

        LibraryVariableStorage.Enqueue(StrSubstNo(IBANConfirmationMsg, IBANCode));
        LibraryVariableStorage.Enqueue(false); // do not confirm invalid IBAN
        asserterror CompanyInformation.CheckIBAN(IBANCode);

        Assert.ExpectedError('');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Bank Account");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Bank Account");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Bank Account");
    end;

    local procedure FindIBAN(): Code[50]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation.IBAN);
    end;

    local procedure AssignBankAccIBANnumber(ConfirmReply: Boolean)
    var
        BankAccount: Record "Bank Account";
        IBANNumber: Code[50];
        OldIBAN: Code[50];
    begin
        BankAccount.Init;
        OldIBAN := BankAccount.IBAN;
        IBANNumber := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(StrSubstNo(IBANConfirmationMsg, IBANNumber));
        LibraryVariableStorage.Enqueue(ConfirmReply);

        if ConfirmReply then
            BankAccount.Validate(IBAN, IBANNumber)
        else begin
            asserterror BankAccount.Validate(IBAN, IBANNumber);
            IBANNumber := OldIBAN;
        end;

        VerifyIBAN(BankAccount.IBAN, IBANNumber);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure AssignVendBankAccIBANnumber(ConfirmReply: Boolean)
    var
        VendBankAccount: Record "Vendor Bank Account";
        IBANNumber: Code[50];
        OldIBAN: Code[50];
    begin
        VendBankAccount.Init;
        OldIBAN := VendBankAccount.IBAN;
        IBANNumber := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(StrSubstNo(IBANConfirmationMsg, IBANNumber));
        LibraryVariableStorage.Enqueue(ConfirmReply);

        if ConfirmReply then
            VendBankAccount.Validate(IBAN, IBANNumber)
        else begin
            asserterror VendBankAccount.Validate(IBAN, IBANNumber);
            IBANNumber := OldIBAN;
        end;

        VerifyIBAN(VendBankAccount.IBAN, IBANNumber);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateVendLedgEntry(VendorBankAccount: Record "Vendor Bank Account"; IsOpen: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
    begin
        with VendLedgEntry do begin
            Init();
            RecRef.GetTable(VendLedgEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Vendor No." := VendorBankAccount."Vendor No.";
            "Recipient Bank Account" := VendorBankAccount.Code;
            Open := IsOpen;
            Insert();
        end;
    end;

    local procedure CreateCustLedgEntry(CustomerBankAccount: Record "Customer Bank Account"; IsOpen: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
    begin
        with CustLedgEntry do begin
            Init();
            RecRef.GetTable(CustLedgEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Customer No." := CustomerBankAccount."Customer No.";
            "Recipient Bank Account" := CustomerBankAccount.Code;
            Open := IsOpen;
            Insert();
        end;
    end;

    local procedure CreateSWIFTCode(var SWIFTCode: Record "SWIFT Code")
    begin
        SWIFTCode.Init();
        SWIFTCode.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(SWIFTCode.FieldNo(Code), DATABASE::"SWIFT Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"SWIFT Code", SWIFTCode.FieldNo(Code))));
        SWIFTCode.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(SWIFTCode.Name)));
        SWIFTCode.Insert(true);
    end;

    local procedure VerifyIBAN(CurrentIBAN: Code[50]; CheckIBAN: Code[50])
    begin
        Assert.AreEqual(CurrentIBAN, CheckIBAN, WrongIBANErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure IBANConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

