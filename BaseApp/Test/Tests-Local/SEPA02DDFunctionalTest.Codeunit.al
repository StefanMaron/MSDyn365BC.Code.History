codeunit 144077 "SEPA.02 DD Functional Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFRLocalization: Codeunit "Library - FR Localization";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLRead: Codeunit "Library - XML Read";
        SEPAPartnerType: Option ,Company,Person;
        UnexpectedEmptyNodeErr: Label 'Unexpected empty value for node <%1> of subtree <%2>.';
        OneToManyNotAllowedErr: Label 'You cannot export a SEPA customer payment that is applied to multiple documents.';
        ErrorsExistErr: Label 'The file export has one or more errors. For each of the lines to be exported, resolve any errors that are displayed in the File Export Errors FactBox.';
        MissingMandateErr: Label 'Mandate ID must have a value in the currently selected record.';
        UnappliedLinesNotAllowedErr: Label 'Payment slip line %1 must be applied to a customer invoice.';
        BankAccErr: Label 'You must use customer bank account, %1, which you specified in the selected direct debit mandate.';
        AccTypeErr: Label 'Only customer transactions are allowed.';
        PartnerTypeErr: Label 'The customer''s Partner Type, Company, must be equal to the Partner Type, Person, specified in the collection.';

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler,SuggestCustPaymentsReqPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestCustPayments()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHeader: Record "Payment Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SuggestCustomerPayments: Report "Suggest Customer Payments";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentHeader(PaymentHeader, SEPAPartnerType::Company);
        CreateDirectDebitMandate(SEPADirectDebitMandate, Customer."No.", '');
        CreateCustomerLedgerEntry(CustLedgerEntry, Customer."No.", SEPADirectDebitMandate.ID);
        CreateCustomerLedgerEntry(CustLedgerEntry, Customer."No.", '');

        // Exercise.
        SuggestCustomerPayments.SetGenPayLine(PaymentHeader);
        Customer.SetRange("No.", Customer."No.");
        SuggestCustomerPayments.SetTableView(Customer);
        SuggestCustomerPayments.RunModal;

        // Verify.
        VerifyPaymentLines(PaymentHeader, Customer);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler,SuggestCustPaymentsReqPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestCustPaymentsDiffPartnerType()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        Customer1: Record Customer;
        SuggestCustomerPayments: Report "Suggest Customer Payments";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreateCustomerWithInvoice(Customer1, CustLedgerEntry, SEPAPartnerType::Person);
        CreatePaymentHeader(PaymentHeader, SEPAPartnerType::Person);

        // Exercise.
        SuggestCustomerPayments.SetGenPayLine(PaymentHeader);
        Customer.SetFilter("No.", '%1|%2', Customer."No.", Customer1."No.");
        Customer.SetRange("Partner Type", Customer."Partner Type");
        Commit();
        SuggestCustomerPayments.SetTableView(Customer);
        SuggestCustomerPayments.RunModal;

        // Verify.
        VerifyPaymentLines(PaymentHeader, Customer);
        PaymentHeader.Find;
        PaymentHeader.TestField("Partner Type", SEPAPartnerType::Company);
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
        PaymentLine.SetRange("Account No.", Customer1."No.");
        Assert.IsTrue(PaymentLine.IsEmpty, 'No payment lines should be created for customer ' + Customer1."No.");
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportPmtLineWithoutApplication()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID", SEPAPartnerType::Company);

        // Exercise.
        asserterror ExportSEPAFile(PaymentHeader);

        // Verify.
        Assert.ExpectedError(ErrorsExistErr);
        VerifyPaymentErrors(DATABASE::"Payment Header", PaymentHeader."No.",
          PaymentLine."Line No.", StrSubstNo(UnappliedLinesNotAllowedErr, PaymentLine."Line No."), 1);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportPmtLineWithAppliesToDocNo()
    var
        Customer: Record Customer;
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SEPAFilePath: Text;
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID", SEPAPartnerType::Company);
        PaymentLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        PaymentLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
        CustLedgerEntry.CalcFields("Remaining Amount");
        PaymentLine.Validate("Credit Amount", CustLedgerEntry."Remaining Amount");
        PaymentLine.Modify();

        // Exercise.
        SEPAFilePath := ExportSEPAFile(PaymentHeader);
        Commit();
        LibraryXMLRead.Initialize(SEPAFilePath);

        // Verify.
        VerifySEPADDXmlFile(PaymentHeader, PaymentLine, GetMessageToRecipient(CustLedgerEntry));
        VerifySEPAMandate(CustLedgerEntry."Direct Debit Mandate ID", 1);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportPmtLineWithAppliesToID()
    var
        Customer: Record Customer;
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SEPAFilePath: Text;
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID", SEPAPartnerType::Company);
        PaymentLine.Validate("Applies-to ID", PaymentLine."Document No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        PaymentLine.Validate("Credit Amount", CustLedgerEntry."Remaining Amount");
        PaymentLine.Modify();
        CustLedgerEntry."Applies-to ID" := PaymentLine."Document No.";
        CustLedgerEntry.Modify();

        // Exercise.
        SEPAFilePath := ExportSEPAFile(PaymentHeader);
        Commit();
        LibraryXMLRead.Initialize(SEPAFilePath);

        // Verify.
        VerifySEPADDXmlFile(PaymentHeader, PaymentLine, GetMessageToRecipient(CustLedgerEntry));
        VerifySEPAMandate(CustLedgerEntry."Direct Debit Mandate ID", 1);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportPmtLineOneToManyNotAllowed()
    var
        Customer: Record Customer;
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID", SEPAPartnerType::Company);
        PaymentLine."Applies-to ID" := PaymentLine."Document No.";
        PaymentLine.Modify();
        CustLedgerEntry."Applies-to ID" := PaymentLine."Document No.";
        CustLedgerEntry.Modify();
        CreateCustomerLedgerEntry(CustLedgerEntry, PaymentLine."Account No.", '');
        CustLedgerEntry."Applies-to ID" := PaymentLine."Document No.";
        CustLedgerEntry.Modify();

        // Exercise.
        asserterror ExportSEPAFile(PaymentHeader);

        // Verify.
        Assert.ExpectedError(ErrorsExistErr);
        VerifyPaymentErrors(DATABASE::"Payment Header", PaymentHeader."No.", PaymentLine."Line No.", OneToManyNotAllowedErr, 0);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportPmtLineDiffThanInvoiceNotAllowed()
    var
        Customer: Record Customer;
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID", SEPAPartnerType::Company);
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::"Credit Memo";
        CustLedgerEntry.Modify();
        PaymentLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        PaymentLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
        PaymentLine.Modify();

        // Exercise.
        asserterror ExportSEPAFile(PaymentHeader);

        // Verify.
        Assert.ExpectedError(ErrorsExistErr);
        VerifyPaymentErrors(DATABASE::"Payment Header", PaymentHeader."No.", PaymentLine."Line No.", UnappliedLinesNotAllowedErr, 0);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportPmtLineDiffThanCustomerNotAllowed()
    var
        Customer: Record Customer;
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID", SEPAPartnerType::Company);
        PaymentLine.Validate("Account Type", PaymentLine."Account Type"::Vendor);
        PaymentLine.Modify();

        // Exercise.
        asserterror ExportSEPAFile(PaymentHeader);

        // Verify.
        Assert.ExpectedError(ErrorsExistErr);
        VerifyPaymentErrors(DATABASE::"Payment Header", PaymentHeader."No.", PaymentLine."Line No.", AccTypeErr, 1);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateBankAccCodeOnPmtLine()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID", SEPAPartnerType::Company);
        CreateCustomerBankAccount(CustomerBankAccount, CustLedgerEntry."Customer No.");

        // Exercise.
        asserterror PaymentLine.Validate("Bank Account Code", CustomerBankAccount.Code);

        // Verify.
        Assert.ExpectedError(StrSubstNo(BankAccErr, PaymentLine."Bank Account Code"));
        VerifyCollectionWasDeleted(PaymentHeader);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateMandateIdOnPmtLineWithBankAcc()
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", '', SEPAPartnerType::Company);
        CreateCustomerBankAccount(CustomerBankAccount, CustLedgerEntry."Customer No.");
        CreateDirectDebitMandate(SEPADirectDebitMandate, CustLedgerEntry."Customer No.", CustomerBankAccount.Code);

        // Exercise.
        PaymentLine.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        PaymentLine.Modify(true);

        // Verify.
        PaymentLine.TestField("Bank Account Code", SEPADirectDebitMandate."Customer Bank Account Code");

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateMandateIdOnPmtLineWithoutBankAcc()
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", '', SEPAPartnerType::Company);
        CreateCustomerBankAccount(CustomerBankAccount, CustLedgerEntry."Customer No.");
        CreateDirectDebitMandate(SEPADirectDebitMandate, CustLedgerEntry."Customer No.", CustomerBankAccount.Code);

        // Exercise.
        PaymentLine.Validate("Bank Account Code", '');
        PaymentLine.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        PaymentLine.Modify(true);

        // Verify.
        PaymentLine.TestField("Bank Account Code", SEPADirectDebitMandate."Customer Bank Account Code");

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckPmtLineExportErrors()
    var
        Customer: Record Customer;
        PaymentStep: Record "Payment Step";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentMgt: Codeunit "Payment Management";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", '', SEPAPartnerType::Company);
        PaymentLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        PaymentLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
        CustLedgerEntry.CalcFields("Remaining Amount");
        PaymentLine.Validate("Credit Amount", CustLedgerEntry."Remaining Amount");
        PaymentLine.Modify();

        // Exercise.
        PaymentStep.SetRange("Action Type", PaymentStep."Action Type"::File);
        asserterror PaymentMgt.ProcessPaymentSteps(PaymentHeader, PaymentStep);

        // Verify.
        Assert.ExpectedError(ErrorsExistErr);
        VerifyPaymentErrors(DATABASE::"Payment Header", PaymentHeader."No.", PaymentLine."Line No.", MissingMandateErr, 1);
        VerifyCollectionWasDeleted(PaymentHeader);
        VerifySEPAMandate(CustLedgerEntry."Direct Debit Mandate ID", 0);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckPmtLineDeleteExportErrors()
    var
        Customer: Record Customer;
        PaymentStep: Record "Payment Step";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentMgt: Codeunit "Payment Management";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", '', SEPAPartnerType::Company);
        PaymentLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        PaymentLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
        CustLedgerEntry.CalcFields("Remaining Amount");
        PaymentLine.Validate("Credit Amount", CustLedgerEntry."Remaining Amount");
        PaymentLine.Modify();

        PaymentStep.SetRange("Action Type", PaymentStep."Action Type"::File);
        asserterror PaymentMgt.ProcessPaymentSteps(PaymentHeader, PaymentStep);
        Assert.ExpectedError(ErrorsExistErr);

        // Exercise.
        PaymentLine.Delete(true);

        // Verify.
        VerifyPaymentErrors(DATABASE::"Payment Header", PaymentHeader."No.", PaymentLine."Line No.", MissingMandateErr, 0);
        VerifyCollectionWasDeleted(PaymentHeader);
        VerifySEPAMandate(CustLedgerEntry."Direct Debit Mandate ID", 0);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckPmtLinePartnerTypeError()
    var
        Customer: Record Customer;
        PaymentStep: Record "Payment Step";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentMgt: Codeunit "Payment Management";
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID",
          SEPAPartnerType::Person);
        PaymentLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        PaymentLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
        CustLedgerEntry.CalcFields("Remaining Amount");
        PaymentLine.Validate("Credit Amount", CustLedgerEntry."Remaining Amount");
        PaymentLine.Modify();

        // Exercise.
        PaymentStep.SetRange("Action Type", PaymentStep."Action Type"::File);
        asserterror PaymentMgt.ProcessPaymentSteps(PaymentHeader, PaymentStep);

        // Verify.
        Assert.ExpectedError(ErrorsExistErr);
        VerifyPaymentErrors(DATABASE::"Payment Header", PaymentHeader."No.", PaymentLine."Line No.",
          PartnerTypeErr, 1);
        VerifyCollectionWasDeleted(PaymentHeader);
        VerifySEPAMandate(CustLedgerEntry."Direct Debit Mandate ID", 0);

        // Clean data
        PaymentHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReplaceClosedMandate()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        Customer: Record Customer;
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SEPAFilePath: Text;
    begin
        // Setup.
        CreateCustomerWithInvoice(Customer, CustLedgerEntry, SEPAPartnerType::Company);
        SEPADirectDebitMandate.Get(CustLedgerEntry."Direct Debit Mandate ID");
        SEPADirectDebitMandate.Validate(Closed, true);
        SEPADirectDebitMandate.Modify(true);
        Clear(SEPADirectDebitMandate);

        CreateDirectDebitMandate(SEPADirectDebitMandate, Customer."No.", Customer."Preferred Bank Account Code");
        CreatePaymentSlip(PaymentHeader, PaymentLine, Customer."No.", CustLedgerEntry."Direct Debit Mandate ID", SEPAPartnerType::Company);
        PaymentLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        PaymentLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
        CustLedgerEntry.CalcFields("Remaining Amount");
        PaymentLine.Validate("Credit Amount", CustLedgerEntry."Remaining Amount");
        PaymentLine.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        PaymentLine.Modify(true);

        // Exercise.
        SEPAFilePath := ExportSEPAFile(PaymentHeader);
        Commit();
        LibraryXMLRead.Initialize(SEPAFilePath);

        // Verify.
        VerifySEPADDXmlFile(PaymentHeader, PaymentLine, GetMessageToRecipient(CustLedgerEntry));
        VerifySEPAMandate(CustLedgerEntry."Direct Debit Mandate ID", 0);
        VerifySEPAMandate(PaymentLine."Direct Debit Mandate ID", 1);
    end;

    local procedure CreateSEPABankAccount(var BankAccount: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        with BankAccount do begin
            Validate(Balance, LibraryRandom.RandIntInRange(100000, 1000000));
            Validate("Bank Account No.", LibraryUtility.GenerateRandomCode(FieldNo("Bank Account No."), DATABASE::"Bank Account"));
            Validate("Country/Region Code", 'FR');
            Validate(IBAN, LibraryUtility.GenerateRandomCode(FieldNo(IBAN), DATABASE::"Bank Account"));
            Validate("SEPA Direct Debit Exp. Format", FindSEPADDPaymentFormat);
            Validate("Direct Debit Msg. Nos.", LibraryERM.CreateNoSeriesCode);
            Validate("SWIFT Code", LibraryUtility.GenerateRandomCode(FieldNo("SWIFT Code"), DATABASE::"Bank Account"));
            Validate("Creditor No.", LibraryUtility.GenerateRandomCode(FieldNo("Creditor No."), DATABASE::"Bank Account"));
            Modify(true);
        end;
    end;

    local procedure CreatePaymentClass(): Code[20]
    var
        PaymentClass: Record "Payment Class";
        PaymentStatus: Record "Payment Status";
        PaymentStep: Record "Payment Step";
    begin
        LibraryFRLocalization.CreatePaymentClass(PaymentClass);
        with PaymentClass do begin
            Validate(Name, '');
            Validate("Header No. Series", LibraryUtility.GetGlobalNoSeriesCode);
            Validate(Enable, true);
            Validate(Suggestions, Suggestions::Customer);
            Validate("SEPA Transfer Type", "SEPA Transfer Type"::"Direct Debit");
            Modify(true);
            LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, Code);
            LibraryFRLocalization.CreatePaymentStep(PaymentStep, Code);
            PaymentStep.Name := 'Export File';
            PaymentStep."Action Type" := PaymentStep."Action Type"::File;
            PaymentStep."Export Type" := PaymentStep."Export Type"::XMLport;
            PaymentStep."Export No." := XMLPORT::"SEPA DD pain.008.001.02";
            PaymentStep.Modify();
        end;
        exit(PaymentClass.Code);
    end;

    local procedure CreatePaymentHeader(var PaymentHeader: Record "Payment Header"; SEPAPartnerType: Option)
    var
        BankAccount: Record "Bank Account";
        PaymentClassCode: Code[30];
    begin
        PaymentClassCode := CreatePaymentClass;
        LibraryVariableStorage.Enqueue(PaymentClassCode);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        with PaymentHeader do begin
            Validate("Account Type", "Account Type"::"Bank Account");
            CreateSEPABankAccount(BankAccount);
            Validate("Account No.", BankAccount."No.");
            Validate("Partner Type", SEPAPartnerType);
            Modify;
        end;
    end;

    local procedure CreatePaymentSlip(var PaymentHeader: Record "Payment Header"; var PaymentLine: Record "Payment Line"; CustomerNo: Code[20]; MandateID: Code[35]; SEPAPartnerType: Option)
    begin
        CreatePaymentHeader(PaymentHeader, SEPAPartnerType);
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");

        with PaymentLine do begin
            Validate("Account Type", "Account Type"::Customer);
            Validate("Account No.", CustomerNo);
            Validate("Credit Amount", LibraryRandom.RandDec(100, 2));
            Validate("Direct Debit Mandate ID", MandateID);
            Modify(true);
        end;
    end;

    local procedure CreateCustomerWithInvoice(var Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; SEPAPartnerType: Option)
    var
        CustomerBankAccount: Record "Customer Bank Account";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerAddress(Customer);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CreateDirectDebitMandate(SEPADirectDebitMandate, Customer."No.", CustomerBankAccount.Code);
        CreateCustomerLedgerEntry(CustLedgerEntry, Customer."No.", SEPADirectDebitMandate.ID);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Validate("Partner Type", SEPAPartnerType);
        Customer.Modify(true);
    end;

    local procedure ExportSEPAFile(var PaymentHeader: Record "Payment Header") ExportedFilePath: Text
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        OutStr: OutStream;
        File: File;
    begin
        DirectDebitCollection.CreateNew(PaymentHeader."No.", PaymentHeader."Account No.", PaymentHeader."Partner Type");
        DirectDebitCollection."Source Table ID" := DATABASE::"Payment Header";
        DirectDebitCollection.Modify();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        ExportedFilePath := TemporaryPath + LibraryUtility.GenerateGUID + '.xml';
        File.Create(ExportedFilePath);
        File.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SEPA DD pain.008.001.02", OutStr, DirectDebitCollectionEntry);
        File.Close;
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.IBAN := LibraryUtility.GenerateGUID;
        CustomerBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID;
        CustomerBankAccount.Modify();
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; SEPADirectDebitMandateID: Code[35])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CustomerNo, LibraryRandom.RandDec(1000, 2));
        GenJournalLine."Direct Debit Mandate ID" := SEPADirectDebitMandateID;
        GenJournalLine."Payment Method Code" := '';
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.FindLast;
    end;

    local procedure CreateCustomerAddress(var Customer: Record Customer)
    begin
        with Customer do begin
            Validate(Address, LibraryUtility.GenerateRandomCode(FieldNo(Address), DATABASE::Customer));
            Validate("Country/Region Code", 'FR');
            Validate(City, LibraryUtility.GenerateRandomCode(FieldNo(City), DATABASE::Customer));
            Validate("Post Code", LibraryUtility.GenerateRandomCode(FieldNo("Post Code"), DATABASE::Customer));
            Modify(true);
        end;
    end;

    local procedure CreateDirectDebitMandate(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CustomerNo: Code[20]; CustomerBankAccountCode: Code[20])
    begin
        with SEPADirectDebitMandate do begin
            Init;
            "Customer No." := CustomerNo;
            "Customer Bank Account Code" := CustomerBankAccountCode;
            "Valid From" := WorkDate;
            "Valid To" := WorkDate + LibraryRandom.RandIntInRange(300, 600);
            "Date of Signature" := WorkDate;
            "Expected Number of Debits" := LibraryRandom.RandInt(10);
            Insert(true);
        end;
    end;

    local procedure FindSEPADDPaymentFormat(): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.SetRange("Processing XMLport ID", XMLPORT::"SEPA DD pain.008.001.02");
        BankExportImportSetup.FindFirst;
        exit(BankExportImportSetup.Code);
    end;

    local procedure GetMessageToRecipient(CustLedgerEntry: Record "Cust. Ledger Entry"): Text
    begin
        exit(CustLedgerEntry.Description + ' ;' + CustLedgerEntry."Document No.");
    end;

    local procedure VerifySEPADDXmlFile(PaymentHeader: Record "Payment Header"; PaymentLine: Record "Payment Line"; MsgToRecipient: Text)
    begin
        VerifyXmlFileDeclarationAndVersion;
        VerifyGroupHeader(PaymentLine);
        VerifyInitiatingParty;
        VerifyPaymentInformationHeader(PaymentLine);
        VerifyCreditor(PaymentHeader, MsgToRecipient);
        VerifyDebitor(PaymentLine);
    end;

    local procedure VerifyXmlFileDeclarationAndVersion()
    begin
        LibraryXMLRead.VerifyXMLDeclaration('1.0', 'UTF-8', 'no');
        LibraryXMLRead.VerifyAttributeValue('Document', 'xmlns', 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.02');
    end;

    local procedure VerifyGroupHeader(PaymentLine: Record "Payment Line")
    begin
        // Mandatory/required elements
        VerifyNodeExistsAndNotEmpty('GrpHdr', 'MsgId');
        VerifyNodeExistsAndNotEmpty('GrpHdr', 'CreDtTm');
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'NbOfTxs', '1');
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'CtrlSum', Format(PaymentLine."Credit Amount", 0, 9));
    end;

    local procedure VerifyInitiatingParty()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        VerifyCompanyNameAndPostalAddress(CompanyInformation, 'InitgPty');
        LibraryXMLRead.VerifyNodeValueInSubtree('InitgPty', 'Id', CompanyInformation."VAT Registration No.");
    end;

    local procedure VerifyCompanyNameAndPostalAddress(CompanyInformation: Record "Company Information"; SubtreeRootNodeName: Text)
    begin
        VerifyNameAndPostalAddress(
          SubtreeRootNodeName, CompanyInformation.Name, CompanyInformation.Address,
          CompanyInformation."Post Code", CompanyInformation.City, CompanyInformation."Country/Region Code");
    end;

    local procedure VerifyPaymentInformationHeader(PaymentLine: Record "Payment Line")
    begin
        // Mandatory elements
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'PmtMtd', 'DD'); // Hardcoded to 'TRF' by the FR SEPA standard

        // Optional element
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'BtchBookg', 'false');
        // PmtTpInf/InstrPrty removed due to BUG: 267559
        LibraryXMLRead.VerifyElementAbsenceInSubtree('PmtTpInf', 'InstrPrty');

        // Mandatory element
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'ReqdColltnDt', PaymentLine."Posting Date");
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'ChrgBr', 'SLEV'); // Hardcoded by FR SEPA standard
    end;

    local procedure VerifyCreditor(PaymentHeader: Record "Payment Header"; MsgToRecipient: Text)
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
    begin
        BankAccount.Get(PaymentHeader."Account No.");
        CompanyInformation.Get();
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', BankAccount.IBAN);
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'BIC', BankAccount."SWIFT Code");
        LibraryXMLRead.VerifyNodeValueInSubtree('Othr', 'Id', BankAccount."Creditor No.");
        LibraryXMLRead.VerifyNodeValueInSubtree('SchmeNm', 'Prtry', 'SEPA');
        LibraryXMLRead.VerifyNodeValueInSubtree('Cdtr', 'Nm', CompanyInformation.Name);
        LibraryXMLRead.VerifyNodeValue('Ustrd', MsgToRecipient);
    end;

    local procedure VerifyDebitor(PaymentLine: Record "Payment Line")
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        Customer.Get(PaymentLine."Account No.");
        CustomerBankAccount.Get(Customer."No.", PaymentLine."Bank Account Code");
        SEPADirectDebitMandate.Get(PaymentLine."Direct Debit Mandate ID");

        VerifyNameAndPostalAddress(
          'DrctDbtTxInf', Customer.Name, Customer.Address, Customer."Post Code", Customer.City, Customer."Country/Region Code");
        // DrctDbtTxInf/PmtTpInf removed due to BUG: 267559
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('DrctDbtTxInf', 'PmtTpInf');
        LibraryXMLRead.VerifyNodeValueInSubtree('DrctDbtTxInf', 'InstdAmt', PaymentLine."Credit Amount");
        LibraryXMLRead.VerifyAttributeValueInSubtree('DrctDbtTxInf', 'InstdAmt', 'Ccy', 'EUR');
        LibraryXMLRead.VerifyNodeValueInSubtree('DrctDbtTx', 'MndtId', SEPADirectDebitMandate.ID);
        LibraryXMLRead.VerifyNodeValueInSubtree('DrctDbtTx', 'DtOfSgntr', SEPADirectDebitMandate."Date of Signature");
        LibraryXMLRead.VerifyNodeValueInSubtree('Dbtr', 'BICOrBEI', CustomerBankAccount."SWIFT Code");
        LibraryXMLRead.VerifyNodeValueInSubtree('DbtrAcct', 'IBAN', CustomerBankAccount.IBAN);
        LibraryXMLRead.VerifyNodeValueInSubtree('DbtrAgt', 'BIC', CustomerBankAccount."SWIFT Code");
    end;

    local procedure VerifyNameAndPostalAddress(SubtreeRootNodeName: Text; Name: Text; Address: Text; PostCode: Text; City: Text; CountryRegionCode: Text)
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree(SubtreeRootNodeName, 'Nm', Name);
        LibraryXMLRead.VerifyNodeValueInSubtree(SubtreeRootNodeName, 'StrtNm', Address);
        LibraryXMLRead.VerifyNodeValueInSubtree(SubtreeRootNodeName, 'PstCd', PostCode);
        LibraryXMLRead.VerifyNodeValueInSubtree(SubtreeRootNodeName, 'TwnNm', City);
        LibraryXMLRead.VerifyNodeValueInSubtree(SubtreeRootNodeName, 'Ctry', CountryRegionCode);
    end;

    local procedure VerifyNodeExistsAndNotEmpty(SubtreeRootName: Text[30]; NodeName: Text[30])
    begin
        Assert.AreNotEqual(
          '', LibraryXMLRead.GetNodeValueInSubtree(SubtreeRootName, NodeName), StrSubstNo(UnexpectedEmptyNodeErr, NodeName, SubtreeRootName));
    end;

    local procedure VerifyPaymentErrors(SourceTableID: Integer; PaymentDocNo: Code[20]; LineNo: Integer; ExpErrorText: Text; ExpCount: Integer)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        with PaymentJnlExportErrorText do begin
            SetRange("Journal Template Name", '');
            SetRange("Journal Batch Name", Format(SourceTableID));
            SetRange("Document No.", PaymentDocNo);
            SetRange("Journal Line No.", LineNo);
            SetRange("Error Text", ExpErrorText);
            Assert.AreEqual(ExpCount, Count, 'Error: ' + ExpErrorText + ', was encountered unexpectedly.');
        end;
    end;

    local procedure VerifyCollectionWasDeleted(PaymentHeader: Record "Payment Header")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        DirectDebitCollection.SetRange(Identifier, PaymentHeader."No.");
        asserterror DirectDebitCollection.FindFirst;
    end;

    local procedure VerifyPaymentLines(PaymentHeader: Record "Payment Header"; Customer: Record Customer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentLine: Record "Payment Line";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        Assert.AreEqual(CustLedgerEntry.Count, PaymentLine.Count, 'Wrong number of payment lines.');

        CustLedgerEntry.FindSet;
        repeat
            PaymentLine.SetRange("Account Type", PaymentLine."Account Type"::Customer);
            PaymentLine.SetRange("Account No.", CustLedgerEntry."Customer No.");
            PaymentLine.SetRange("Applies-to Doc. Type", CustLedgerEntry."Document Type");
            PaymentLine.SetRange("Applies-to Doc. No.", CustLedgerEntry."Document No.");
            PaymentLine.SetRange("Direct Debit Mandate ID", CustLedgerEntry."Direct Debit Mandate ID");
            Assert.AreEqual(1, PaymentLine.Count, PaymentLine.GetFilters);
            PaymentLine.FindFirst;
            if SEPADirectDebitMandate.Get(CustLedgerEntry."Direct Debit Mandate ID") then
                PaymentLine.TestField("Bank Account Code", SEPADirectDebitMandate."Customer Bank Account Code")
            else
                PaymentLine.TestField("Bank Account Code", Customer."Preferred Bank Account Code");
        until CustLedgerEntry.Next = 0;
    end;

    local procedure VerifySEPAMandate(SEPADirectDebitMandateID: Text[35]; ExpCounter: Integer)
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        SEPADirectDebitMandate.Get(SEPADirectDebitMandateID);
        SEPADirectDebitMandate.TestField("Debit Counter", ExpCounter);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentClassHandler(var PaymentClassList: TestPage "Payment Class List")
    var
        PaymentClassCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(PaymentClassCode);
        PaymentClassList.GotoKey(PaymentClassCode);
        PaymentClassList.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestCustPaymentsReqPageHandler(var SuggestCustomerPayments: TestRequestPage "Suggest Customer Payments")
    begin
        SuggestCustomerPayments.LastPaymentDate.SetValue(WorkDate);
        SuggestCustomerPayments.OK.Invoke;
    end;
}

