codeunit 134406 "ERM SEPA Direct Debit Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Direct Debit]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryRandom: Codeunit "Library - Random";
        ServerFileName: Text;
        IsInitialized: Boolean;
        NoEntriesErr: Label 'No entries have been created.', Comment = '%1=Field;%2=Table;%3=Field;%4=Table';
        EntryCountErr: Label 'Actual %1 is different than expected.', Comment = '%1=TableCaption';
        NoDataToExportErr: Label 'There is no data to export. Make sure the %1 field is not set to %2 or %3.', Comment = '%1=Field;%2=Value;%3=Value';
        Found: Boolean;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDueDateOutRange()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
    begin
        Initialize;

        // Setup
        PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate, WorkDate, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        asserterror
          RunCreateDirectDebitCollectionReport(
            WorkDate - 10, WorkDate - 10, Customer."Partner Type"::Company, BankAccount."No.", false, false);

        // Verify
        Assert.ExpectedError(NoEntriesErr);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDueDateInRange()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocNo := PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate, WorkDate, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        RunCreateDirectDebitCollectionReport(
          WorkDate - 5, WorkDate + 5, Customer."Partner Type"::Company, BankAccount."No.", false, false);

        // Verify
        VerifyDirectDebitMandateID(Customer."No.", PostedDocNo, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo, 1);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceOnlyValidMandateOnCustomer()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
        PostedDocNo2: Code[20];
    begin
        Initialize;

        // Setup
        PostTwoWorkdateSalesInvoicesSEPADirectDebit(Customer, Customer2, PostedDocNo, PostedDocNo2);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        RunCreateDirectDebitCollectionReport(
          WorkDate - 5, WorkDate + 5, Customer."Partner Type"::Company, BankAccount."No.", true, false);

        // Verify
        VerifyTwoSalesInvoiceValidMandate(Customer."No.", PostedDocNo, Customer2."No.", PostedDocNo2);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceInvalidMandatePositive()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocNo := PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate - 30, WorkDate - 30, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        RunCreateDirectDebitCollectionReport(
          WorkDate - 5, WorkDate + 5, Customer."Partner Type"::Company, BankAccount."No.", false, false);

        // Verify
        VerifyDirectDebitMandateID(Customer."No.", PostedDocNo, not Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo, 1);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceInvalidMandateNegative()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
    begin
        Initialize;

        // Setup
        PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate - 30, WorkDate - 30, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute
        asserterror
          RunCreateDirectDebitCollectionReport(
            WorkDate - 5, WorkDate + 5, Customer."Partner Type"::Company, BankAccount."No.", true, true);

        // Verify
        Assert.ExpectedError(NoEntriesErr);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceOnlyValidMandateOnInvoice()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
        PostedDocNo2: Code[20];
    begin
        Initialize;

        // Setup
        PostTwoWorkdateSalesInvoicesSEPADirectDebit(Customer, Customer2, PostedDocNo, PostedDocNo2);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        RunCreateDirectDebitCollectionReport(
          WorkDate - 5, WorkDate + 5, Customer."Partner Type"::Company, BankAccount."No.", false, true);

        // Verify
        VerifyTwoSalesInvoiceValidMandate(Customer."No.", PostedDocNo, Customer2."No.", PostedDocNo2);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePartnerType()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
        PostedDocNo2: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocNo := PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate - 30, WorkDate + 30, Customer."Partner Type"::Company);
        PostedDocNo2 := PostWorkdateSalesInvoiceSEPADirectDebit(Customer2, WorkDate - 30, WorkDate + 30, Customer."Partner Type"::Person);
        CreateSEPABankAccount(BankAccount);

        // Execute
        RunCreateDirectDebitCollectionReport(
          WorkDate - 5, WorkDate + 5, Customer."Partner Type"::Person, BankAccount."No.", false, false);

        // Verify
        VerifyDirectDebitMandateID(Customer."No.", PostedDocNo, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo, 0);

        VerifyDirectDebitMandateID(Customer2."No.", PostedDocNo2, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo2, 1);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyXMLTags()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollectionEntry2: Record "Direct Debit Collection Entry";
        PostedDocNo: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocNo := PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate - 30, WorkDate + 30, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute
        RunCreateDirectDebitCollectionReport(
          WorkDate - 5, WorkDate + 5, Customer."Partner Type"::Company, BankAccount."No.", false, false);
        DirectDebitCollectionEntry.SetFilter("Applies-to Entry Document No.", '<>%1', PostedDocNo);
        DirectDebitCollectionEntry.DeleteAll(true);
        DirectDebitCollectionEntry.SetRange("Applies-to Entry Document No.", PostedDocNo);
        DirectDebitCollectionEntry.FindFirst;
        DirectDebitCollectionEntry2.SetRange("Direct Debit Collection No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
        ExportToServerTempFile(DirectDebitCollectionEntry2);

        // Verify
        LibraryXMLRead.Initialize(ServerFileName);
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtTpInf', 'LclInstrm', 'B2B');
        LibraryXMLRead.VerifyNodeValue('ChrgBr', 'SLEV');
        // PmtTpInf/InstrPrty removed due to BUG: 267559
        LibraryXMLRead.VerifyElementAbsenceInSubtree('PmtTpInf', 'InstrPrty');
        LibraryXMLRead.VerifyNodeValueInSubtree('MndtRltdInf', 'MndtId', DirectDebitCollectionEntry."Mandate ID");
        LibraryXMLRead.VerifyNodeValueInSubtree('DrctDbtTxInf', 'InstdAmt', DirectDebitCollectionEntry."Transfer Amount");
        LibraryXMLRead.VerifyAttributeValueInSubtree('DrctDbtTxInf', 'InstdAmt', 'Ccy', 'EUR');
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', BankAccount.IBAN);
        LibraryXMLRead.VerifyNodeValueInSubtree('FinInstnId', 'BIC', BankAccount."SWIFT Code");
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ExportCancelledDDCollectionWithEntry()
    var
        BankAcc: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        Initialize;

        // Pre-Setup
        PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate, WorkDate, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAcc);
        RunCreateDirectDebitCollectionReport(
          WorkDate - 5, WorkDate + 5, Customer."Partner Type"::Company, BankAcc."No.", false, false);

        // Setup
        DirectDebitCollection.SetRange("Partner Type", Customer."Partner Type"::Company);
        DirectDebitCollection.SetRange("To Bank Account No.", BankAcc."No.");
        DirectDebitCollection.FindLast;
        DirectDebitCollection.CloseCollection;

        // Exercise
        asserterror DirectDebitCollection.Export;

        // Verify
        Assert.ExpectedError(
          StrSubstNo(NoDataToExportErr, DirectDebitCollectionEntry.FieldCaption(Status),
            DirectDebitCollectionEntry.Status::Rejected, DirectDebitCollection.Status::Canceled));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportClosedDDCollectionWithEntry()
    var
        BankAcc: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        LastDirectDebitCollectionNo: Integer;
    begin
        Initialize;

        // Pre-Setup
        BankExportImportSetup.SetRange("Processing XMLport ID", XMLPORT::"SEPA DD pain.008.001.02");
        BankExportImportSetup.FindFirst;
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAcc.IBAN := LibraryUtility.GenerateGUID;
        BankAcc."SWIFT Code" := LibraryUtility.GenerateGUID;
        BankAcc.Modify;
        if DirectDebitCollection.FindLast then begin
            LastDirectDebitCollectionNo := DirectDebitCollection."No.";
            Clear(DirectDebitCollection);
        end;

        // Setup
        DirectDebitCollection."No." := LastDirectDebitCollectionNo + 1000;
        DirectDebitCollection."To Bank Account No." := BankAcc."No.";
        DirectDebitCollection.Status := DirectDebitCollection.Status::Closed;
        DirectDebitCollection.Insert;
        DirectDebitCollectionEntry."Direct Debit Collection No." := DirectDebitCollection."No.";
        DirectDebitCollectionEntry."Entry No." := 1;
        DirectDebitCollectionEntry.Status := DirectDebitCollectionEntry.Status::Posted;
        DirectDebitCollectionEntry.Insert;

        // Exercise
        asserterror DirectDebitCollection.Export;

        // Verify
        Assert.ExpectedError(
          StrSubstNo(NoDataToExportErr, DirectDebitCollectionEntry.FieldCaption(Status),
            DirectDebitCollectionEntry.Status::Rejected, DirectDebitCollection.Status::Canceled));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStandardCustSalesCodeWithInvalidDDMandate()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SEPADirectDebitMandate1: Record "SEPA Direct Debit Mandate";
        SEPADirectDebitMandate2: Record "SEPA Direct Debit Mandate";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
    begin
        Initialize;

        // Setup
        LibrarySales.CreateCustomer(Customer1);
        LibrarySales.CreateCustomer(Customer2);

        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate1, Customer1."No.", '', 0D, 0D);
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate2, Customer2."No.", '', 0D, 0D);

        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer1."No.", '');

        // Execute
        asserterror StandardCustomerSalesCode.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate2.ID);

        // Verify
        Assert.ExpectedErrorCode('DB:NothingInsideFilter');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear;
        Found := true;

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData;
        Commit;
        IsInitialized := true;
    end;

    local procedure CreateCustomerWithBankAccount(var Customer: Record Customer; var CustomerBankAccount: Record "Customer Bank Account"; PaymentMethodCode: Code[10]; PartnerType: Option)
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.IBAN := Format(LibraryRandom.RandIntInRange(11111111, 99999999));
        CustomerBankAccount."SWIFT Code" := Format(LibraryRandom.RandIntInRange(1111, 9999));
        CustomerBankAccount.Modify;
        Customer.Validate("Partner Type", PartnerType);
        Customer.Validate("Currency Code", LibraryERM.GetCurrencyCode('EUR'));
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Modify;
    end;

    local procedure CreateDirectDebitPaymentMethod(var PaymentMethod: Record "Payment Method")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Direct Debit", true);
        PaymentMethod.Validate("Direct Debit Pmt. Terms Code", PaymentTerms.Code);
        PaymentMethod.Modify;
    end;

    local procedure CreateSEPABankAccount(var BankAccount: Record "Bank Account")
    var
        NoSeries: Record "No. Series";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        NoSeries.FindFirst;
        BankExportImportSetup.SetRange("Processing Codeunit ID", CODEUNIT::"SEPA DD-Export File");
        BankExportImportSetup.FindFirst;

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Account No." := Format(LibraryRandom.RandIntInRange(111, 999));
        BankAccount.IBAN := Format(LibraryRandom.RandIntInRange(11111111, 99999999));
        BankAccount."SWIFT Code" := Format(LibraryRandom.RandIntInRange(1111, 9999));
        BankAccount."Creditor No." := Format(LibraryRandom.RandIntInRange(11111111, 99999999));
        BankAccount."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAccount.Validate("Direct Debit Msg. Nos.", NoSeries.Code);
        BankAccount.Modify;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateDirectDebitCollectionHandler(var CreateDirectDebitCollection: TestRequestPage "Create Direct Debit Collection")
    var
        FromDate: Variant;
        ToDate: Variant;
        ValidCustMandate: Variant;
        ValidInvMandate: Variant;
        BankAccNo: Variant;
        PartnerType: Variant;
    begin
        LibraryVariableStorage.Dequeue(FromDate);
        LibraryVariableStorage.Dequeue(ToDate);
        LibraryVariableStorage.Dequeue(PartnerType);
        LibraryVariableStorage.Dequeue(ValidCustMandate);
        LibraryVariableStorage.Dequeue(ValidInvMandate);
        LibraryVariableStorage.Dequeue(BankAccNo);
        CreateDirectDebitCollection.FromDueDate.SetValue(FromDate);
        CreateDirectDebitCollection.ToDueDate.SetValue(ToDate);
        CreateDirectDebitCollection.PartnerType.SetValue(PartnerType);
        CreateDirectDebitCollection.OnlyCustomerValidMandate.SetValue(ValidCustMandate);
        CreateDirectDebitCollection.OnlyInvoiceValidMandate.SetValue(ValidInvMandate);
        CreateDirectDebitCollection.BankAccNo.SetValue(BankAccNo);
        CreateDirectDebitCollection.OK.Invoke;
    end;

    local procedure EnqueueRequestPage(FromDate: Date; ToDate: Date; PartnerType: Option; BankAccNo: Code[20]; ValidCustMandate: Boolean; ValidInvMandate: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FromDate);
        LibraryVariableStorage.Enqueue(ToDate);
        LibraryVariableStorage.Enqueue(PartnerType);
        LibraryVariableStorage.Enqueue(ValidCustMandate);
        LibraryVariableStorage.Enqueue(ValidInvMandate);
        LibraryVariableStorage.Enqueue(BankAccNo);
    end;

    local procedure ExportToServerTempFile(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        OutStream: OutStream;
    begin
        ServerFileName := FileManagement.ServerTempFileName('.xml');
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"SEPA DD pain.008.001.02", OutStream, DirectDebitCollectionEntry);
        ExportFile.Close;
    end;

    local procedure PostWorkdateSalesInvoiceSEPADirectDebit(var Customer: Record Customer; MandateFromDate: Date; MandateToDate: Date; Partnertype: Option): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentMethod: Record "Payment Method";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        CreateDirectDebitPaymentMethod(PaymentMethod);
        CreateCustomerWithBankAccount(Customer, CustomerBankAccount, PaymentMethod.Code, Partnertype);
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate, CustomerBankAccount."Customer No.",
          CustomerBankAccount.Code, MandateFromDate, MandateToDate);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true))
    end;

    local procedure PostTwoWorkdateSalesInvoicesSEPADirectDebit(var Customer: Record Customer; var Customer2: Record Customer; var PostedDocNo: Code[20]; var PostedDocNo2: Code[20])
    begin
        PostedDocNo :=
          PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate - 30, WorkDate - 30, Customer."Partner Type"::Company);
        PostedDocNo2 :=
          PostWorkdateSalesInvoiceSEPADirectDebit(Customer2, WorkDate - 30, WorkDate + 30, Customer."Partner Type"::Company);
    end;

    local procedure RunCreateDirectDebitCollectionReport(FromDate: Date; ToDate: Date; PartnerType: Option; BankAccNo: Code[20]; ValidCustMandate: Boolean; ValidInvMandate: Boolean)
    begin
        EnqueueRequestPage(FromDate, ToDate, PartnerType, BankAccNo, ValidCustMandate, ValidInvMandate);
        Commit;
        REPORT.Run(REPORT::"Create Direct Debit Collection");
    end;

    local procedure VerifyDirectDebitMandateID(CustomerNo: Code[20]; DocumentNo: Code[20]; MandateIsFound: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        SEPADirectDebitMandate.SetRange("Customer No.", CustomerNo);
        SEPADirectDebitMandate.FindFirst;

        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        Assert.AreEqual(MandateIsFound, not CustLedgerEntry.IsEmpty, StrSubstNo(EntryCountErr, CustLedgerEntry.TableCaption));
    end;

    local procedure VerifyDirectDebitCollectionEntryCount(DocNo: Code[20]; ExpectedCount: Integer)
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.SetRange("Applies-to Entry Document No.", DocNo);
        Assert.AreEqual(ExpectedCount, DirectDebitCollectionEntry.Count,
          StrSubstNo(EntryCountErr, DirectDebitCollectionEntry.TableCaption));
    end;

    local procedure VerifyTwoSalesInvoiceValidMandate(CustomerNo1: Code[20]; PostedDocNo1: Code[20]; CustomerNo2: Code[20]; PostedDocNo2: Code[20])
    begin
        VerifyDirectDebitMandateID(CustomerNo1, PostedDocNo1, not Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo1, 0);

        VerifyDirectDebitMandateID(CustomerNo2, PostedDocNo2, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo2, 1);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

