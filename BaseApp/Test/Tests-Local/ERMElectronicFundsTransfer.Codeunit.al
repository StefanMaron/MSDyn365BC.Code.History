codeunit 142083 "ERM Electronic Funds Transfer"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Payment] [Journal] [EFT]
    end;

    var
        TempACHRBHeader: Record "ACH RB Header" temporary;
        TempACHRBDetail: Record "ACH RB Detail" temporary;
        TempACHRBFooter: Record "ACH RB Footer" temporary;
        TempACHUSHeader: Record "ACH US Header" temporary;
        TempACHUSDetail: Record "ACH US Detail" temporary;
        TempACHCecobanHeader: Record "ACH Cecoban Header" temporary;
        TempACHCecobanDetail: Record "ACH Cecoban Detail" temporary;
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        EntryStatusErr: Label 'Entry Status must be equal to ''Posted''  in Check Ledger Entry: Entry No.';
        MyBalCaptionTxt: Label 'myBal';
        TempPathTxt: Label '.\', Comment = 'Path';
        TransitNoTxt: Label '095021007';
        FederalIDNoErr: Label 'Federal ID No. must have a value in Company Information';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        TempSubDirectoryTxt: Label '142083_Test\';
        "Layout": Option RDLC,Word;
        AmountVerificationMsg: Label 'Amount must be equal.';
        NoOfRecordsErr: Label 'No of records must be same.';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        NoExportDiffCurrencyErr: Label 'You cannot export journal entries if Currency Code is different in Gen. Journal Line and Bank Account.';
        NoDataOutputErr: Label 'No data exists for the specified report filters.';
        ExportVendorBankAccountErr: Label 'The error, You must have exactly one Vendor Bank Account with Use for Electronic Payments checked for Vendor %1., occurred when running report %2 for %3.';
        VendorBankAccountErr: Label 'You must have exactly one Vendor Bank Account with Use for Electronic Payments checked for Vendor %1.';
        CustomerBankAccountErr: Label 'You must have exactly one Customer Bank Account with Use for Electronic Payments checked for Customer %1.';
        EFTExportGenJnlLineErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
        MandatoryDimErr: Label 'Select a %1 for the %2 %3 for %4 %5.';
        RemitAdvFileNotFoundTxt: Label 'Remittance Advice file has not been found';
        ForceDocBalanceFalseQst: Label 'Warning:  Transactions cannot be financially voided when Force Doc. Balance is set to No';

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalAfterPostPurchaseOrder()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify XML Data after Export Electronic Payment Journal.
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Export the Payment
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournalDirect(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN]  Verify XML Data.
        GenJournalLine.Find();

        LibraryReportDataset.LoadDataSetFile;

        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'Gen__Journal_Line___Applies_to_Doc__No__', GenJournalLine."Applies-to Doc. No.");
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalAfterPostPurchaseOrderWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Export the Payment
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] Make sure Exported to Payment File is set in the Gen Journal Line
        GenJournalLine.Find();
        GenJournalLine.TestField("Exported to Payment File", true);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create one payment journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Try and export it twice
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] No message is given they will need to void the trx and reenter
        GenJournalLine.TestField("Exported to Payment File", false);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalTwiceWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create one payment journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Try and export it twice
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] No message is given they will need to void the trx and reenter
        GenJournalLine.TestField("Exported to Payment File", false);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnVoidCheckWithExportedEntryStatus()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Export the Payment Journal try to void the check
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
        asserterror VoidCheckCheckLedgerEntries(GenJournalLine."Bal. Account No.");

        // [THEN] Verify Void Check error and verify Entry Status is Exported.
        GenJournalLine.Find();
        GenJournalLine.TestField("Exported to Payment File", true);
        Assert.ExpectedError(EntryStatusErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnBlankFederalIDNoAfterExportPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify Error after Export Electronic Payment Journal when Federal ID No is blank on Company Information.
        // [GIVEN] Create Electonic Payment Journal and set Federal ID No to blank.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        ModifyFederalIdCompanyInformation('');  // Federal ID No as blank.
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Try to Export Payment Journal
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [THEN] Verify that it did not get exported and we recieved an error from no Federal ID
        GenJournalLine.Find();
        GenJournalLine.TestField("Exported to Payment File", false);
        Assert.ExpectedError(FederalIDNoErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithBalAccountTypeCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        AccountNo: Code[20];
        CustomerBankAccountCode: Code[20];
    begin
        // Verify XML after creating and exporting Electronic Payment Journal with Bal. Account Type as Customer.
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        // [WHEN] Export Payment Journal
        // [THEN] Verify Account No. and Amount Paid on XML file.
        AccountNo := CreateCustomerBankAccountWithCustomer(true, CustomerBankAccountCode);
        ExportPaymentJournalAndVerifyXML(
          AccountNo, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Bal. Account Type"::Customer, CustomerBankAccountCode);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithBalAccountTypeCustomerWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        Amount: Decimal;
        CustomerNo: Code[20];
        CustomerAccountBankCode: Code[10];
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);

        // [WHEN] Export Payment Journal
        // [THEN] Verify XML after creating and exporting Electronic Payment Journal with Bal. Account Type as Customer.
        Amount := LibraryRandom.RandDec(10, 2);  // Random value for Amount.
        CustomerNo := CreateCustomerBankAccountWithCustomer(true, CustomerAccountBankCode);
        CreateAndExportPaymentJournal(GenJournalLine."Document Type"::Payment,
          GenJournalLine."Bal. Account Type"::Customer, CustomerNo,
          Amount, CopyStr(LibraryUtility.GenerateGUID, 1, 3), LibraryUtility.GenerateGUID, false, CustomerAccountBankCode);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithBalAccountTypeVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        FindAndUpdateVendorBankAccount(VendorBankAccount);

        // [WHEN] Export Payment Journal
        // [THEN] Verify XML after creating and exporting Electronic Payment Journal with Bal. Account Type as Vendor.
        ExportPaymentJournalAndVerifyXML(
          VendorBankAccount."Vendor No.", GenJournalLine."Document Type"::Payment,
          GenJournalLine."Bal. Account Type"::Vendor, VendorBankAccount.Code);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithBalAccountTypeVendorWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        Amount: Decimal;
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        FindAndUpdateVendorBankAccount(VendorBankAccount);

        // [WHEN] Export Payment Journal
        // [THEN] Verify Word Layout after creating and exporting Electronic Payment Journal with Bal. Account Type as Customer.
        Amount := LibraryRandom.RandDec(10, 2);  // Random value for Amount.
        CreateAndExportPaymentJournal(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Bal. Account Type"::Vendor, VendorBankAccount."Vendor No.", Amount,
          CopyStr(LibraryUtility.GenerateGUID, 1, 3), LibraryUtility.GenerateGUID, false, VendorBankAccount.Code);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalPostPurchaseOrderVerifyEFTExportWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify the EFT Export record gets created
        // [GIVEN] Create Electonic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Export Payment Journal
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
        Commit();

        // [THEN] Verify Data is created in the EFT Export Table
        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        EFTExport.SetRange("Line No.", GenJournalLine."Line No.");
        EFTExport.FindFirst();
        EFTExport.TestField("Check Exported", true);
        EFTExport.TestField("Check Printed", true);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportTwoPaymentJournalPostPurchaseOrderVerifyEFTExportWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify the EFT Export record gets created
        // [GIVEN] Create 2 Electonic Payment Journals
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        CreateElectronicMultiplePaymentJournals(GenJournalLine);

        // [WHEN] Export Payment Journals
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] Verify 2 records are in the EFT Export Table
        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        Assert.AreEqual(EFTExport.Count, 2, NoOfRecordsErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportTwoPaymentJournalOpenUpGenerateEFT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        "Count": Integer;
    begin
        // [GIVEN] Create 2 Electonic Payment Journals
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        CreateElectronicMultiplePaymentJournals(GenJournalLine);

        // [WHEN] Export Payment Journals and open up the Generate EFT page
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        GenerateEFTFiles.Trap;
        PaymentJournal.GenerateEFT.Invoke;
        PaymentJournal.Close();

        // [THEN] Iterate through each line in the repeater to make sure there is 2 records
        if GenerateEFTFiles.GenerateEFTFileLines.First then
            repeat
                Count += 1;
            until not GenerateEFTFiles.GenerateEFTFileLines.Next;

        Assert.AreEqual(Count, 2, NoOfRecordsErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentPostPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        FileManagement: Codeunit "File Management";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        "Count": Integer;
        FilePath: Text;
    begin
        // [SCENARIO] Verify Entry Status on Check Ledger Entry after Post Electronic Payment Journal.
        // 270132: One check ledger entry creates when export electronic payment journal
        // 286778: Entry Status is "Posted"
        // 377993: Resulting file name = Remittance Advice <Vendor's Name>.pdf

        // [GIVEN] Create and Export Electronic Payment Journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        CreateElectronicPaymentJournal(GenJournalLine);

        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        Vendor.Get(GenJournalLine."Account No.");

        // [WHEN] Post the General Journal Line and open up the Generate EFT Files Page
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GenerateEFTFiles.Trap;
        PaymentJournal.GenerateEFT.Invoke;
        PaymentJournal.Close();

        // [THEN] Iterate through each line in the repeater to make sure there is 1 record
        if GenerateEFTFiles.GenerateEFTFileLines.First then
            repeat
                Count += 1;
            until not GenerateEFTFiles.GenerateEFTFileLines.Next;

        Assert.AreEqual(Count, 1, NoOfRecordsErr);

        // [THEN] One check ledger entry has been created
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        VerifyCheckLedgEntryCount(
          GenJournalLine."Posting Date", BankAccount."Last Remittance Advice No.", CheckLedgerEntry."Entry Status"::Posted, 1);
        // 377993: Resulting file name = Remittance Advice <Vendor's Name>.pdf
        FilePath := FileManagement.CombinePath(TemporaryPath, StrSubstNo('Remittance Advice for %1.pdf', Vendor.Name));
        Assert.IsTrue(File.Exists(FilePath), RemitAdvFileNotFoundTxt);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalPostWithoutTransmit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create Payment Journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Export Electronic payment
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);

        GenJournalLine.TestField("Check Transmitted", false);

        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Line No.", GenJournalLine."Line No.");
        GenJournalLine2.FindFirst();

        // [WHEN] Post the payment journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GL ENTRY is created
        VerifyGLEntry(
          GenJournalLine2."Document Type", GenJournalLine2."Document No.", GenJournalLine2."Bal. Account No.", Abs(GenJournalLine2.Amount));
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalVerifyDeleteEFTExport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        "Count": Integer;
    begin
        // Verify the EFT Export record gets created
        // [GIVEN] Create Electonic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [WHEN] Export Payment Journal
        PrepareEFTExportScenario(GenJournalLine, PaymentJournal);

        // [THEN] Verify Data is created in the EFT Export Table
        GenerateEFTFiles.Trap;
        PaymentJournal.GenerateEFT.Invoke;
        PaymentJournal.Close();

        // [THEN] Verify Data is deleted
        if GenerateEFTFiles.GenerateEFTFileLines.First then
            repeat
                Count += 1;
            until not GenerateEFTFiles.GenerateEFTFileLines.Next;

        Assert.AreEqual(Count, 1, NoOfRecordsErr);

        GenerateEFTFiles.Delete.Invoke;

        EFTExport.SetRange("Bank Account No.", GenJournalLine."Bal. Account No.");
        Count := EFTExport.Count();

        Assert.RecordIsEmpty(EFTExport);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalVerifyVendorErrorNoUseForElectronicPaymentsEFTExport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify the EFT Export record gets created
        // [GIVEN] Create Electonic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        CreateElectronicPaymentJournalNoUseForElecPayment(GenJournalLine);

        // [WHEN] Export Payment Journal
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [THEN] Verify that we get an message error because Vendor Bank account doesn't have Use For Electronic Payments set.
        Assert.ExpectedError(HasErrorsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalVerifyCustomerErrorNoUseForElectronicPaymentsEFTExport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        Amount: Decimal;
        AccountNo: Code[20];
        CustomerBankAccountCode: Code[20];
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);

        // [WHEN] Export Payment Journal
        Amount := LibraryRandom.RandDec(10, 2);  // Random value for Amount.

        AccountNo := CreateCustomerBankAccountWithCustomer(false, CustomerBankAccountCode);

        CreatePaymentJournal(GenJournalLine,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"Bank Account", CreateAndModifyBankAccount,
          GenJournalLine."Applies-to Doc. Type"::" ", '',
          GenJournalLine."Bal. Account Type"::Customer,
          AccountNo, Amount, CustomerBankAccountCode);
        GenJournalLine.Validate("Transaction Type Code", GenJournalLine."Transaction Type Code"::BUS);
        GenJournalLine.Validate("Transaction Code", CopyStr(LibraryUtility.GenerateGUID, 1, 3));
        GenJournalLine.Validate("Company Entry Description", LibraryUtility.GenerateGUID);
        GenJournalLine.Modify(true);
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
        PaymentJournal.OpenEdit();

        asserterror ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [THEN] Verify that we get an message error because Customer Bank account doesn't have Use For Electronic Payments set.
        Assert.ExpectedError(HasErrorsErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournaGenerateEFTFile()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        FileManagement: Codeunit "File Management";
        PaymentJournal: TestPage "Payment Journal";
        ServerDirectoryHelper: DotNet Directory;
        PathToExport: Text;
    begin
        // [SCENARIO 263518] Stan can export Generated EFT File via windows client
        // [SCENARIO 292459,297292] No extra check ledger entries are created
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] EFT export worksheet ready for export
        PrepareEFTExportScenario(GenJournalLine, PaymentJournal);
        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.Description := CopyStr(EFTExport.Description, 1, MaxStrLen(TempEFTExportWorkset.Description));
        TempEFTExportWorkset.TransferFields(EFTExport);
        TempEFTExportWorkset.Include := true;
        TempEFTExportWorkset.Insert();

        // [WHEN] Stan call Generate EFT and selects folder "C:\EFT Generation" on a local machine
        PathToExport := FileManagement.ServerCreateTempSubDirectory;
        GenerateEFT.SetSavePath(PathToExport);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Windows);
        GenerateEFT.ProcessAndGenerateEFTFile(TempEFTExportWorkset."Bank Account No.", WorkDate, TempEFTExportWorkset, EFTValues);

        // [THEN] The generated file "EXPORT001" saved to folder "C:\EFT Generation"
        Assert.AreEqual(1, ServerDirectoryHelper.GetFiles(PathToExport).Length, 'File must be exported');

        // [THEN] No extra check ledger entries have been created
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        VerifyCheckLedgEntryCount(0D, BankAccount."Last Remittance Advice No.", CheckLedgerEntry."Entry Status"::Exported, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnDifferentCurrenciesAfterExportPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 262728] Verify Error after Export Electronic Payment Journal when Journal Line Currency Code <> Bank Account Currency Code.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Create Electonic Payment Journal and Bank Account with empty Currency Code.
        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [GIVEN] Set Journal Line Currency Code.
        GenJournalLine.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, 1.0, 1.0));
        GenJournalLine.Modify(true);

        // [WHEN] Try to Export Payment Journal.
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [THEN] Payment Journal was not exported and a message of Errors existence occurs.
        Assert.ExpectedError(HasErrorsErr);
        GenJournalLine.Find();
        GenJournalLine.TestField("Exported to Payment File", false);

        // [THEN] Payment Journal Export Error contains a Currency Error.
        VerifyPaymentFileError(GenJournalLine, NoExportDiffCurrencyErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalGenerateEFTVerifyNoOfRecords()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExportWorkset: Record "EFT Export Workset";
        EFTExport: Record "EFT Export";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ExpLauncherEFT: Codeunit "Exp. Launcher EFT";
        EFTValues: Codeunit "EFT Values";
        DataCompression: Codeunit "Data Compression";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        ZipFileName: Text;
        "Count": Integer;
    begin
        // [GIVEN] Create 1 Electonic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Export Payment Journals and open up the Generate EFT page
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        GenerateEFTFiles.Trap;
        PaymentJournal.GenerateEFT.Invoke;
        PaymentJournal.Close();

        // [THEN] Iterate through each line in the repeater to make sure there is 1 record
        if GenerateEFTFiles.GenerateEFTFileLines.First then
            repeat
                Count += 1;
            until not GenerateEFTFiles.GenerateEFTFileLines.Next;

        Assert.AreEqual(1, Count, NoOfRecordsErr);

        EFTExportWorkset.DeleteAll();
        EFTExport.SetRange("Bank Account No.", GenJournalLine."Bal. Account No.");
        EFTExport.FindFirst();
        EFTExport.Description := CopyStr(EFTExport.Description, 1, MaxStrLen(EFTExportWorkset.Description));
        EFTExportWorkset.TransferFields(EFTExport);
        EFTExportWorkset.Include := true;
        EFTExportWorkset.UserSettleDate := WorkDate;
        EFTExportWorkset.ProcessOrder := 1;
        EFTExportWorkset.Insert();

        EFTValues.SetNoOfRec := 0;
        ExpLauncherEFT.SetTestMode;
        // [THEN] Start EFT Process and verify the file will have 10 lines.
        ExpLauncherEFT.EFTPaymentProcess(EFTExportWorkset, TempNameValueBuffer, DataCompression, ZipFileName, EFTValues);
        Assert.AreEqual(10, EFTValues.GetNoOfRec, 'Wrong number of Records');
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure ExportSeveralVendorsWithSameNamePDF()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: array[3] of Record "Vendor Bank Account";
        FileManagement: Codeunit "File Management";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        FilesList: List of [Text];
        VendorName: Text;
        i: Integer;
    begin
        // [FEATURE] [Report] [Export]
        // [SCENARIO 401532] Export payment journal Remittance Advice for several vendors with the same name
        // [SCENARIO 401532] produces several pdf files with different names
        Initialize();
        CheckClearAllReportsZip();
        CreateExportReportSelection(Layout::RDLC);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Three vendors with the same name "X"
        VendorName := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(VendorBankAccount) do begin
            FindAndUpdateVendorBankAccount(VendorBankAccount[i]);
            Vendor.Get(VendorBankAccount[i]."Vendor No.");
            Vendor.Validate(Name, CopyStr(VendorName, 1, MaxStrLen(Vendor.Name)));
            Vendor.Modify(true);
        END;

        // [GIVEN] Bank account setup for US EFT DEFAULT export
        CreateBankAccount(BankAccount, VendorBankAccount[1]."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");

        // [GIVEN] Payment journal with 3 lines for different vendors
        for i := 1 to ArrayLen(VendorBankAccount) do begin
            CreatePaymentGLLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
              VendorBankAccount[i]."Vendor No.", GenJournalLine."Document Type"::" ", '',
              GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", 1);
            GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount[i].Code);
            GenJournalLine.Modify(true);
        end;
        LibraryVariableStorage.Enqueue(BankAccount."No.");  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");

        // [WHEN] Export payment journal
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [WHEN] Three files have been exported:
        // [THEN] "Remittance Advice for X_Export Electronic Payments.pdf"
        // [THEN] "Remittance Advice for X_Export Electronic Payments (1).pdf"
        // [THEN] "Remittance Advice for X_Export Electronic Payments (2).pdf"
        GetFilesListFromZip(FilesList);
        Assert.AreEqual(3, FilesList.Count(), '');
        Assert.IsTrue(FilesList.Contains(StrSubstNo('Remittance Advice for %1.pdf', VendorName)), RemitAdvFileNotFoundTxt);
        Assert.IsTrue(FilesList.Contains(StrSubstNo('Remittance Advice for %1 (1).pdf', VendorName)), RemitAdvFileNotFoundTxt);
        Assert.IsTrue(FilesList.Contains(StrSubstNo('Remittance Advice for %1 (2).pdf', VendorName)), RemitAdvFileNotFoundTxt);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneratingEFTFileInCAFormatRollbackAllExportedLinesOnError()
    var
        Vendor: array[2] of Record Vendor;
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
    begin
        // [FEATURE] [Generate EFT File]
        // [SCENARIO 310585] When an error occurs during processing of exported lines in CA format, none of the lines must be marked as transmitted.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Create two vendors - "CA" and "UNDEF", the first one has Country Code = "CA", the country code on another vendor is blank.
        // [GIVEN] Set up Vendor Bank Account for each vendor.
        CreateVendorWithVendorBankAccount(Vendor[1], VendorBankAccount[1], 'CA');
        CreateVendorWithVendorBankAccount(Vendor[2], VendorBankAccount[2], '');

        // [GIVEN] Bank Account set up for "CA" EFT export format.
        CreateBankAccount(BankAccount, VendorBankAccount[1]."Transit No.", BankAccount."Export Format"::CA);
        BankAccount.Validate("Payment Export Format", 'CA EFT DEFAULT');
        BankAccount.Validate("EFT Export Code", 'CA EFT DEFAULT');
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID);
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID);
        BankAccount.Modify(true);

        // [GIVEN] Post an invoice for each vendor.
        // [GIVEN] Generate payment journal line for each invoice, populate an appropriate Vendor Bank Account.
        // [GIVEN] Export the payment journal.
        // [GIVEN] Mark the exported lines as "Include" so they can be processed to EFT file.
        CreateAndExportVendorPayments(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file.
        Commit();
        GenerateEFT.SetSavePath(TemporaryPath);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Windows);
        asserterror GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", WorkDate, TempEFTExportWorkset, EFTValues);

        // [THEN] An error message is thrown, as the country code for vendor "UNDEF" is not populated.
        Assert.ExpectedError('Country must have a value');

        // [THEN] None of the exported lines are marked as Transmitted, since the generating EFT file failed.
        EFTExport.SetRange("Journal Template Name", TempEFTExportWorkset."Journal Template Name");
        EFTExport.SetRange("Journal Batch Name", TempEFTExportWorkset."Journal Batch Name");
        EFTExport.SetRange(Transmitted, false);
        Assert.RecordCount(EFTExport, ArrayLen(Vendor));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneratingEFTFileInCAFormatCustomDateFormat()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        TempACHRBHeader: Record "ACH RB Header" temporary;
        TempACHRBDetail: Record "ACH RB Detail" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        FileManagement: Codeunit "File Management";
        DateFormat: Text[100];
        DateFormatLength: Integer;
        ExpectedDateInt: Integer;
        EFTFilePath: Text;
    begin
        // [FEATURE] [Generate EFT File] [Date Format] [Data Exchange Definition]
        // [SCENARIO 338287] Stan can export payment with export type "CA" to EFT file with custom "Date Format" specified in "Data Exchange Definition"
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Vendor and Bank Accoutn with Country Code = "CA" and setup for EFT export "CA"
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'CA');
        DuplicateDataExchangeDefinition(DataExchDef, BankExportImportSetup, 'CA EFT DEFAULT');
        DateFormat := '<Day,2><Month,2><Year,2>';
        DateFormatLength := 6;

        // [GIVEN] "Data Format" = <Day,2><Month,2><Year,2> for "File Created Date" in header and "Payment Date" in detail lines
        UpdateDateFormatsOnCAEFTDataExchDef(DataExchDef, DateFormat, DateFormatLength);

        // [GIVEN] Bank Account set up for "CA" EFT export format.
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::CA);
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Validate("EFT Export Code", BankExportImportSetup.Code);
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID);
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID);
        BankAccount.Modify(true);

        // [GIVEN] Post an invoice for each vendor.
        // [GIVEN] Generate payment journal line for each invoice, populate an appropriate Vendor Bank Account.
        // [GIVEN] Export the payment journal.
        // [GIVEN] Mark the exported lines as "Include" so they can be processed to EFT file.
        // [GIVEN] TODAY = 23/03/2019, WORKDATE = 20/03/2019
        CreateAndExportVendorPayment(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file.
        Commit();
        EFTFilePath := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName(''));
        GenerateEFT.SetSavePath(EFTFilePath);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", WorkDate, TempEFTExportWorkset, EFTValues);

        // [THEN] Exported lines are marked as Transmitted
        EFTExport.SetRange("Journal Template Name", TempEFTExportWorkset."Journal Template Name");
        EFTExport.SetRange("Journal Batch Name", TempEFTExportWorkset."Journal Batch Name");
        EFTExport.SetRange(Transmitted, true);
        Assert.RecordCount(EFTExport, 1);

        // [THEN] ACHRBHeader."File Created Date" = 230319
        ERMElectronicFundsTransfer.GetTempACHRBHeader(TempACHRBHeader);
        ERMElectronicFundsTransfer.GetTempACHRBDetail(TempACHRBDetail);
        Evaluate(ExpectedDateInt, Format(Today, DateFormatLength, DateFormat));
        TempACHRBHeader.FindLast();
        TempACHRBHeader.TestField("File Creation Date", ExpectedDateInt);

        // [THEN] ACHRBDetail."Payment Date" = 200319
        Evaluate(ExpectedDateInt, Format(WorkDate, DateFormatLength, DateFormat));
        TempACHRBDetail.FindFirst();
        TempACHRBDetail.TestField("Payment Date", ExpectedDateInt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalGenerateEFT_ACH_EntrySequenceNo()
    var
        Vendor: Record Vendor;
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        FileManagement: Codeunit "File Management";
        EFTFilePath: Text;
    begin
        // [FEATURE] [Generate EFT File] [ACH] [Data Exchange Definition]
        // [SCENARIO 336577] Cassie can export payment journal as EFT with "Entry Detail Sequence No" field in Data Exchange Definition mapping.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount[1], 'US');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount[2], 'US');

        DuplicateDataExchangeDefinition(DataExchDef, BankExportImportSetup, 'US EFT DEFAULT');
        InsertEntryDetailSequenceNo(DataExchDef);

        CreateBankAccount(BankAccount, VendorBankAccount[1]."Transit No.", BankAccount."Export Format"::US);
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Validate("EFT Export Code", BankExportImportSetup.Code);
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID);
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID);
        BankAccount.Modify(true);

        CreateAndExportVendorPayments(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file.
        Commit();
        EFTFilePath := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName(''));
        GenerateEFT.SetSavePath(EFTFilePath);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", WorkDate, TempEFTExportWorkset, EFTValues);

        // [THEN] All exported lines are marked as Transmitted
        EFTExport.SetRange("Journal Template Name", TempEFTExportWorkset."Journal Template Name");
        EFTExport.SetRange("Journal Batch Name", TempEFTExportWorkset."Journal Batch Name");
        EFTExport.SetRange(Transmitted, true);
        Assert.RecordCount(EFTExport, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JulianDate()
    var
        ExportEFTRB: Codeunit "Export EFT (RB)";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 303720] Codeunit "Export EFT (RB)".JulianDate() returns integer value "YYDDD"
        Assert.AreEqual(20150, ExportEFTRB.JulianDate(20200529D), 'JulianDate');
        Assert.AreEqual(21001, ExportEFTRB.JulianDate(20210101D), 'JulianDate');
        Assert.AreEqual(22365, ExportEFTRB.JulianDate(20221231D), 'JulianDate');
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTExport_CA()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SettleDate: Date;
    begin
        // [FEATURE] [CA]
        // [SCENARIO 303720] Export EFT CA (RB) with two headers and all business data in payment journal
        // [SCENARIO 362896] Settlement Date is exported via data exchange ACH RB Header "Settlement Date" field
        // [SCENARIO 401126] Settlement Julian Date is exported with the Julian date format of the "Settlement Date" field value
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);

        // [GIVEN] Data Exchange Definition for CA with two headers
        // [GIVEN] Bank account "Last E-Pay File Creation No." = 1
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'CA');
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::CA, CreateBankExportImportSetup(CreateDataExchDefForCA()),
            LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Exported payment journal line with filled in all business data
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file
        SettleDate := LibraryRandom.RandDate(10);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", SettleDate, TempEFTExportWorkset, EFTValues);

        // [THEN] Bank account "Last E-Pay File Creation No." = 2
        // [THEN] Header, Detail, Footer contains "File Creation Number" value
        // [THEN] Detail contains business data from payment journal
        VerifyBankAccountFileCreationNumberIncrement(BankAccount);
        Assert.IsTrue(EFTValues.IsSetFileCreationNumber(), 'EFTValues.IsSetFileCreationNumber()');
        Assert.AreEqual(BankAccount."Last E-Pay File Creation No.", EFTValues.GetFileCreationNumber(), 'EFTValues.GetFileCreationNumber()');
        VerifyEFTExportCA(ERMElectronicFundsTransfer, TempEFTExportWorkset, BankAccount."Last E-Pay File Creation No.", SettleDate);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTExport_US()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SettleDate: Date;
    begin
        // [FEATURE] [US]
        // [SCENARIO 303720] Export EFT US (ACH) with two headers and all business data in payment journal
        // [SCENARIO 362896] Settlement Date is exported via data exchange ACH US Header "Effective Date" field
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);

        // [GIVEN] Data Exchange Definition for US with two headers
        // [GIVEN] Bank account "Last E-Pay File Creation No." = 1
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');

        // [GIVEN] Exported payment journal line with filled in all business data
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file
        SettleDate := LibraryRandom.RandDate(10);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", SettleDate, TempEFTExportWorkset, EFTValues);

        // [THEN] Bank account "Last E-Pay File Creation No." = 2
        // [THEN] Detail contains business data from payment journal
        VerifyBankAccountFileCreationNumberIncrement(BankAccount);
        VerifyEFTExportUS(ERMElectronicFundsTransfer, TempEFTExportWorkset, SettleDate);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTExport_MX()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SettleDate: Date;
    begin
        // [FEATURE] [MX]
        // [SCENARIO 303720] Export EFT MX (Cecoban) with two headers and all business data in payment journal
        // [SCENARIO 362896] Settlement Date is exported via data exchange ACH US Header "Effective Date" field
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);

        // [GIVEN] Data Exchange Definition for MX with two headers
        // [GIVEN] Bank account "Last E-Pay File Creation No." = 1
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'MX');
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::MX, CreateBankExportImportSetup(CreateDataExchDefForMX()), '', '');

        // [GIVEN] Exported payment journal line with filled in all business data
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file
        SettleDate := LibraryRandom.RandDate(10);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", SettleDate, TempEFTExportWorkset, EFTValues);

        // [THEN] Bank account "Last E-Pay File Creation No." = 2
        // [THEN] Detail contains business data from payment journal
        VerifyBankAccountFileCreationNumberIncrement(BankAccount);
        VerifyEFTExportMX(ERMElectronicFundsTransfer, TempEFTExportWorkset, SettleDate);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_CreateExportTransmit()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export and tranmit one line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] A new payment journal line has "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        // [GIVEN] Perform journal "Export" action
        // [GIVEN] EFT Export line is created with "Sequence No." = 1
        // [GIVEN] Payment journal line is updated with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = False
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.TestField("Sequence No.", LastSequenceNo + 1);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);

        // [WHEN] Perform EFT Export (Generate EFT file)
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [THEN] Journal line is updated with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = True
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler,ConfirmHandler')]
    procedure EFTSequenceNo_CreateExportVoid()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export and void one line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] A new payment journal line has "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        // [GIVEN] Perform journal "Export" action
        // [GIVEN] EFT Export line is created with "Sequence No." = 1
        // [GIVEN] Payment journal line is updated with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = False
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.TestField("Sequence No.", LastSequenceNo + 1);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);

        // [WHEN] Perform journal "Void" action
        PerformVoidTransmitElecPayments(GenJournalLine);

        // [THEN] EFT Export line is deleted
        // [THEN] Payment journal line is updated with "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        Assert.RecordIsEmpty(EFTExport);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_CreateExportPostCreateExport()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export, post first line and create, export second line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] A new payment journal line has "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        // [GIVEN] Perform journal "Export" action
        MockExportPayment(GenJournalLine, LastSequenceNo + 1);
        // [GIVEN] Post the payment journal 
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        GenJournalLine.Find();
        GenJournalLine.Delete();

        // [GIVEN] Create a new payment journal line ("EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False)
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);

        // [WHEN] Perform journal "Export" action
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);

        // [THEN] Payment journal line is updated with "EFT Export Sequence No." = 2, "Check Exported" = True, "Check Transmitted" = False
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 2, True, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_CreateExportPostCreateTransmit()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export, post first line, create second line, transmit first line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] A new payment journal line has "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        // [GIVEN] Perform journal "Export" action
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);
        FindEFTExport(EFTExport, GenJournalLine);
        // [GIVEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Line No.", GenJournalLine."Line No.");
        if GenJournalLine.FindFirst() then begin
            GenJournalLine."Recipient Bank Account" := VendorBankAccount.Code;
            GenJournalLine.Modify();
        end;

        // [GIVEN] Create a new payment journal line ("EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False)
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyLastGenJnlLineFields(GenJournalLine, 0, false, false);

        // [WHEN] Perform EFT Export (Generate EFT file)
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [THEN] Journal line remains with "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        VerifyLastGenJnlLineFields(GenJournalLine, 0, false, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_TransmitFirstOfTwoLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export, transmit the first of two lines
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] Two payment journal lines
        // [GIVEN] Perform journal "Export" action
        CreateVendorPaymentLine(GenJournalLine[1], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        ExportPaymentJournalViaAction(GenJournalLine[1], GenJournalBatch, BankAccountNo);
        CreateVendorPaymentLine(GenJournalLine[2], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        MockExportPayment(GenJournalLine[2], LastSequenceNo + 2);

        // [WHEN] Perform EFT Export (Generate EFT file) for the first line
        FindEFTExport(EFTExport, GenJournalLine[1]);
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [THEN] The first journal line is updated with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = True
        // [THEN] The second journal line remains with "EFT Export Sequence No." = 2, "Check Exported" = True, "Check Transmitted" = False
        VerifyGenJnlLineFields(GenJournalLine[1], LastSequenceNo + 1, true, true);
        VerifyGenJnlLineFields(GenJournalLine[2], LastSequenceNo + 2, true, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_TransmitSecondOfTwoLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export, transmit the second of two lines
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] Two payment journal lines
        // [GIVEN] Perform journal "Export" action
        CreateVendorPaymentLine(GenJournalLine[1], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        MockExportPayment(GenJournalLine[1], LastSequenceNo + 1);
        CreateVendorPaymentLine(GenJournalLine[2], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        ExportPaymentJournalViaAction(GenJournalLine[2], GenJournalBatch, BankAccountNo);

        // [WHEN] Perform EFT Export (Generate EFT file) for the second line
        FindEFTExport(EFTExport, GenJournalLine[2]);
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [THEN] The first journal line remains with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = False
        // [THEN] The second journal line is updated with "EFT Export Sequence No." = 2, "Check Exported" = True, "Check Transmitted" = True
        VerifyGenJnlLineFields(GenJournalLine[1], LastSequenceNo + 1, true, false);
        VerifyGenJnlLineFields(GenJournalLine[2], LastSequenceNo + 2, true, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_DeleteEFTExportLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] deletion of EFT Export line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] Payment journal line
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        // [GIVEN] Perform journal "Export" action
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);

        // [WHEN] Delete EFT Export line
        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.Delete(true);

        // [THEN] The journal line is updated with "EFT Export Sequence No." = 0, "Check Exported" = True, "Check Transmitted" = False
        VerifyGenJnlLineFields(GenJournalLine, 0, True, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler,ConfirmHandler')]
    procedure EFTSequenceNo_DeleteEFTExportLineViaPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] deletion of EFT Export line via page
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] Payment journal line
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        // [GIVEN] Perform journal "Export" action
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);

        // [WHEN] Delete EFT Export line via page
        GenerateEFTFiles.OpenEdit();
        GenerateEFTFiles."Bank Account".SetValue(BankAccountNo);
        GenerateEFTFiles.Delete.Invoke();

        // [THEN] The journal line is updated with "EFT Export Sequence No." = 0, "Check Exported" = True, "Check Transmitted" = False
        VerifyGenJnlLineFields(GenJournalLine, 0, True, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintReport_RDLC_RequestPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (RDLC, use request page)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (RDLC, use request page)
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PrintElectronicPaymentsRDLC(GenJournalLine, true);

        // [THEN] Report is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.AssertEmpty();
        DeleteBankAccount(GenJournalLine."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRH')]
    [Scope('OnPrem')]
    procedure PrintReport_RDLC_NoRequestPage_DiffSavedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (RDLC, w\o request page, different saved bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (RDLC, w\o request page, different saved bank account)
        PrintElectronicPaymentsRDLC(GenJournalLine, false);

        // [THEN] Report is printed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintReport_RDLC_RequestPage_BlankBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (RDLC, use request page, blank bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (RDLC, use request page, blank bank account)
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        asserterror PrintElectronicPaymentsRDLC(GenJournalLine, true);

        // [THEN] Report is not printed
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError('Bank Account');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRH')]
    [Scope('OnPrem')]
    procedure PrintReport_RDLC_NoRequestPage_BlankedSavedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (RDLC, w\o request page, blanked saved bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (RDLC, w\o request page, blanked saved bank account)
        PrintElectronicPaymentsRDLC(GenJournalLine, false);

        // [THEN] Report is printed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH')]
    [Scope('OnPrem')]
    procedure PrintReport_Word_RequestPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (Word, use request page)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (Word, use request page)
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PrintElectronicPaymentsWord(GenJournalLine, true);

        // [THEN] Report is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.AssertEmpty();
        DeleteBankAccount(GenJournalLine."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRH')]
    [Scope('OnPrem')]
    procedure PrintReport_Word_NoRequestPage_DiffSavedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (Word, w\o request page, different saved bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (Word, w\o request page, different saved bank account)
        PrintElectronicPaymentsWord(GenJournalLine, false);

        // [THEN] Report is printed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH')]
    [Scope('OnPrem')]
    procedure PrintReport_Word_RequestPage_BlankBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (Word, use request page, blank bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (Word, use request page, blank bank account)
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        asserterror PrintElectronicPaymentsWord(GenJournalLine, true);

        // [THEN] Report is not printed
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError('Bank Account');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRH')]
    [Scope('OnPrem')]
    procedure PrintReport_Word_NoRequestPage_BlankedSavedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (Word, w\o request page, blanked saved bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (Word, w\o request page, blanked saved bank account)
        PrintElectronicPaymentsWord(GenJournalLine, false);

        // [THEN] Report is printed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTExportGenJnlLineDimensionError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        ObjectTranslation: Record "Object Translation";
        ObjectOptions: Record "Object Options";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        ErrorText: Text;
    begin
        // [FEATURE] [Generate EFT File]
        // [SCENARIO 352093] Error when trying to use "Generate EFT File" for exported Gen. Journal line with wrong Dimension setup.
        Initialize();
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", Report::"ExportElecPayments - Word");
        ObjectOptions.DeleteAll();
        ObjectOptions.SetRange("Object ID", Report::"Export Electronic Payments");
        ObjectOptions.DeleteAll();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Gen. Journal Line Payment exported with empty Dimension for Vendor with Default Dimension having "Value Posting"::"Code Mandatory".
        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDimension, DATABASE::Vendor, GenJournalLine."Account No.", DefaultDimension."Value Posting"::"Code Mandatory");

        // [GIVEN] GenerateEFTFiles page is opened from Payment Journal.
        Commit();  // Commit required.
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.ExportPaymentsToFile.Invoke();
        GenerateEFTFiles.Trap();
        PaymentJournal.GenerateEFT.Invoke();

        // [WHEN] "Generate EFT File" action is invoked on GenerateEFTFiles page.
        asserterror GenerateEFTFiles.GenerateEFTFile.Invoke();
        PaymentJournal.Close();

        // [THEN] Error is thrown with Error Code "TestWrapped:Dialog" and 
        // [THEN] text "A dimension used in Gen. Journal Line has caused an error. Select a Dimension Value Code for the Dimension Code for Vendor.".
        Assert.ExpectedErrorCode('TestWrapped:Dialog');
        with DefaultDimension do
            ErrorText :=
                StrSubstNo(
                    MandatoryDimErr, FieldCaption("Dimension Value Code"), FieldCaption("Dimension Code"),
                    "Dimension Code", ObjectTranslation.TranslateTable("Table ID"), "No.");
        with GenJournalLine do
            ErrorText :=
                StrSubstNo(
                    EFTExportGenJnlLineErr, TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.", ErrorText);
        Assert.ExpectedError(ErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleCustomerBankAccountsForElectronicPayment()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        Initialize();

        // [GIVEN] A customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] A customer bank account for the customer we have just created
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // [GIVEN] The customer bank account has "Use for Electronic Payments" set to true 
        CustomerBankAccount.Validate("Use for Electronic Payments", true);
        CustomerBankAccount.Modify(true);

        // [WHEN] Creating a second customer bank account with "Use for Electronic Payments" set to true 
        // for the same customer
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.Validate("Use for Electronic Payments", true);
        CustomerBankAccount.Modify(true);

        // [THEN] No errors occur and the customer has 2 customer bank accounts with 
        // "Use for Electronic Payments" set to true
        CustomerBankAccount.SetRange("Customer No.", Customer."No.");
        CustomerBankAccount.SetRange("Use for Electronic Payments", true);
        Assert.AreEqual(2, CustomerBankAccount.Count,
            'The customer should have 2 bank accounts that have electronic payments enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleVendorBankAccountsForElectronicPayment()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        Initialize();

        // [GIVEN] A vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A vendor bank account for the vendor we have just created
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        // [GIVEN] The vendor bank account has "Use for Electronic Payments" set to true 
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);

        // [WHEN] Creating a second vendor bank account with "Use for Electronic Payments" set to true 
        // for the same vendor
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);

        // [THEN] No errors occur and the vendor has 2 vendor bank accounts with 
        // "Use for Electronic Payments" set to true
        VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
        VendorBankAccount.SetRange("Use for Electronic Payments", true);
        Assert.AreEqual(2, VendorBankAccount.Count,
            'The vendor should have 2 bank accounts that have electronic payments enabled');
    end;

    [Test]
    procedure ACHRBHeaderSettlementJulianDateUT()
    var
        ACHRBHeader: Record "ACH RB Header";
        ExportEFTRB: Codeunit "Export EFT (RB)";
        Date: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 401126] TAB 10303 "ACH RB Header"."Settlement Julian Date" contains a date in the Julian date format
        Date := LibraryRandom.RandDate(1000);
        ACHRBHeader.Validate("Settlement Date", Date);
        ACHRBHeader.TestField("Settlement Date", Date);
        ACHRBHeader.TestField("Settlement Julian Date", ExportEFTRB.JulianDate(Date));

        ACHRBHeader.Validate("Settlement Date", 0D);
        ACHRBHeader.TestField("Settlement Date", 0D);
        ACHRBHeader.TestField("Settlement Julian Date", 0);
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH')]
    procedure RunExportElecPaymentsWordWithRequestPageOnMarkedGenJnlLines()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 400511] Run report "ExportElecPayments - Word" with request page on marked Payment Journal lines.
        Initialize();

        // [GIVEN] Two Payment Journal lines for one Vendor. Both lines are marked.
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Mark(true);
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Mark(true);

        // [WHEN] Run report "ExportElecPayments - Word" with request page on marked General Journal Lines from Payment Journal.
        // [WHEN] On the request page set Bank Account No.; filters for Gen. Journal Batch/Template are empty.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        GenJournalLine.MarkedOnly(true);
        RunReportExportElecPaymentsWord(GenJournalLine, true);

        // [THEN] Report was printed.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH,ConfirmHandlerEnqueueQuestion')]
    procedure RunExportElecPaymentsWordWithRequestPageOnMarkedGenJnlLinesWhenForceDocBalanceFalse()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 400511] Run report "ExportElecPayments - Word" with request page on marked Payment Journal lines when Force Doc. Balance = false.
        Initialize();

        // [GIVEN] General Journal Template with "Forced Doc. Balance" = false.
        // [GIVEN] Two Payment Journal lines for one Vendor. Both lines are marked.
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        UpdateForceDocBalanceOnGenJnlTemplate(GenJournalBatch."Journal Template Name", false);
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Mark(true);
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Mark(true);

        // [WHEN] Run report "ExportElecPayments - Word" with request page on marked General Journal Lines from Payment Journal.
        // [WHEN] On the request page set Bank Account No.; filters for Gen. Journal Batch/Template are empty.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        GenJournalLine.MarkedOnly(true);
        RunReportExportElecPaymentsWord(GenJournalLine, true);

        // [THEN] A confirm dialog "Transactions cannot be financially voided" is shown. Report was printed after user proceeded with confirm.
        Assert.ExpectedConfirm(ForceDocBalanceFalseQst, LibraryVariableStorage.DequeueText());
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        EFTExport: Record "EFT Export";
    begin
        LibraryERMCountryData.CreateVATData();
        LibraryVariableStorage.Clear();
        ModifyFederalIdCompanyInformation(LibraryUtility.GenerateGUID);
        EFTExport.DeleteAll();
    end;

    local procedure DeleteBankAccount(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.Delete();
    end;

    local procedure CreateAndExportPaymentJournal(DocumentType: Option; BalAccountType: Option; AccountNo: Code[20]; Amount: Decimal; TransactionCode: Code[3]; CompanyEntryDescription: Code[10]; ReportDirectRun: Boolean; CustomerBankAccountCode: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        CreatePaymentJournal(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::"Bank Account", CreateAndModifyBankAccount,
          GenJournalLine."Applies-to Doc. Type"::" ", '', BalAccountType, AccountNo, Amount, CustomerBankAccountCode);
        GenJournalLine.Validate("Transaction Type Code", GenJournalLine."Transaction Type Code"::BUS);
        GenJournalLine.Validate("Transaction Code", TransactionCode);
        GenJournalLine.Validate("Company Entry Description", CompanyEntryDescription);
        GenJournalLine.Modify(true);
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PaymentJournal.OpenEdit();
        if ReportDirectRun then
            asserterror ExportPaymentJournalDirect(PaymentJournal, GenJournalLine)
        else
            ExportPaymentJournal(PaymentJournal, GenJournalLine);
    end;

    local procedure CreateAndModifyBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BankAccount, LibraryUtility.GenerateGUID, BankAccount."Export Format"::CA);
        CreateBankAccWithBankStatementSetup(BankAccount, 'CA EFT DEFAULT');
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID);
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID);
        BankAccount.Validate("Input Qualifier", LibraryUtility.GenerateGUID);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomerBankAccountWithCustomer(UseForElectronicPayments: Boolean; var CustomerBankAccountCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustomerBankAccount2: Record "Customer Bank Account";
    begin
        // Need to create Customer Bank Account. Insertion is specific to test and required only once.
        LibrarySales.CreateCustomer(Customer);
        if CustomerBankAccount2.FindFirst() then
            CustomerBankAccount2.Validate("Use for Electronic Payments", true);
        CustomerBankAccount.Init();
        CustomerBankAccount.Validate("Customer No.", Customer."No.");
        CustomerBankAccount.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(Code), DATABASE::"Customer Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Customer Bank Account", CustomerBankAccount.FieldNo(Code))));
        CustomerBankAccount.Insert(true);
        CustomerBankAccount.Validate("Bank Branch No.", CustomerBankAccount2."Bank Branch No.");
        CustomerBankAccount.Validate("Bank Account No.", CustomerBankAccount2."Bank Account No.");
        CustomerBankAccount.Validate(IBAN, CustomerBankAccount2.IBAN);
        CustomerBankAccount.Validate("SWIFT Code", CustomerBankAccount2."SWIFT Code");
        CustomerBankAccount.Validate("Use for Electronic Payments", UseForElectronicPayments);
        CustomerBankAccount.Modify(true);
        CustomerBankAccountCode := CustomerBankAccount.Code;
        exit(CustomerBankAccount."Customer No.");
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; TransitNo: Code[20]; ExportFormat: Option)
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Export Format", ExportFormat);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Remittance Advice No.", LibraryUtility.GenerateGUID);
        BankAccount.Validate("E-Pay Export File Path", TemporaryPath);
        BankAccount.Validate("E-Pay Trans. Program Path", TempPathTxt);
        BankAccount.Validate("Last E-Pay Export File Name", LibraryUtility.GenerateGUID);
        BankAccount.Validate("Transit No.", TransitNo);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankAccountForCountry(var BankAccount: Record "Bank Account"; ExportFormat: Option; BankExportImportSetupCode: Code[20]; ClientNo: Code[10]; ClientName: Code[30])
    begin
        CreateBankAccount(BankAccount, GetTransitNo(ExportFormat), ExportFormat);
        BankAccount.Validate("Payment Export Format", BankExportImportSetupCode);
        BankAccount.Validate("EFT Export Code", BankExportImportSetupCode);
        BankAccount.Validate("Client No.", ClientNo);
        BankAccount.Validate("Client Name", ClientName);
        BankAccount.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        BankAccount.Modify(true);
    end;

    local procedure CreateElectronicPaymentJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        FindAndUpdateVendorBankAccount(VendorBankAccount);
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreatePaymentJournalAfterPostPurchaseOrder(GenJournalLine, VendorBankAccount."Vendor No.", BankAccount."No.");
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJournalLine.Modify();
        Commit();
    end;

    local procedure CreateTestElectronicPaymentJournalWordLayout(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateExportReportSelection(Layout::Word);
        CreateElectronicPaymentJournal(GenJournalLine);
    end;

    local procedure CreateElectronicPaymentJournalNoUseForElecPayment(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        FindAndUpdateVendorBankAccount(VendorBankAccount);
        ModifyUseForElectronicPaymentsVendorBankAccount(VendorBankAccount, false);
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreatePaymentJournalAfterPostPurchaseOrder(GenJournalLine, VendorBankAccount."Vendor No.", BankAccount."No.");
        Commit();
    end;

    local procedure CreateElectronicMultiplePaymentJournals(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        FindAndUpdateVendorBankAccount(VendorBankAccount);
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreateMultiplePaymentJournalsAfterPostPurchaseOrder(GenJournalLine, VendorBankAccount."Vendor No.",
          BankAccount."No.", VendorBankAccount.Code);
        Commit();
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccountNo;
        GenJournalBatch.Modify();
    end;

    local procedure CreatePaymentJournal(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; AccountType: Option; AccountNo: Code[20]; AppliesToDocType: Option; AppliesToDocNo: Code[20]; BalAccountType: Option; BalAccountNo: Code[20]; Amount: Decimal; CustomerBankAccountCode: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, AccountNo);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("Recipient Bank Account", CustomerBankAccountCode);
        GenJournalLine.Modify(true);
    end;

    local procedure ExportPaymentJournalAndVerifyXML(AccountNo: Code[20]; DocumentType: Option; BalAccountType: Option; CustomerBankAccountCode: Code[20])
    var
        Amount: Decimal;
    begin
        // Exercise.
        Amount := LibraryRandom.RandDec(10, 2);  // Random value for Amount.
        CreateAndExportPaymentJournal(
          DocumentType, BalAccountType, AccountNo, -Amount, CopyStr(LibraryUtility.GenerateGUID, 1, 3),
          LibraryUtility.GenerateGUID, true, CustomerBankAccountCode);

        // Verify: Verify Account No. and Amount Paid on XML file.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, AccountNo);
        LibraryReportDataset.AssertElementWithValueExists('AmountPaid', Amount);
    end;

    local procedure CreatePaymentGLLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Payment Reference", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentJournalAfterPostPurchaseOrder(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        CreatePurchaseOrder(PurchaseHeader, VendorNo);
        PurchaseHeader.CalcFields(Amount);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          PurchaseHeader.Amount);
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateMultiplePaymentJournalsAfterPostPurchaseOrder(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; BankAccountNo: Code[20]; BankAccountCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        CreatePurchaseOrder(PurchaseHeader, VendorNo);
        PurchaseHeader.CalcFields(Amount);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          PurchaseHeader.Amount);
        GenJournalLine.Validate("Recipient Bank Account", BankAccountCode);
        GenJournalLine.Modify();
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          PurchaseHeader.Amount);
        GenJournalLine.Validate("Recipient Bank Account", BankAccountCode);
        GenJournalLine.Modify();
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
    end;

    local procedure CreateAndExportVendorPayments(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; VendorBankAccount: array[2] of Record "Vendor Bank Account"; BankAccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        PaymentJournal: TestPage "Payment Journal";
        InvoiceNo: Code[20];
        i: Integer;
    begin
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);
        for i := 1 to ArrayLen(VendorBankAccount) do begin
            CreatePurchaseOrder(PurchaseHeader, VendorBankAccount[i]."Vendor No.");
            PurchaseHeader.CalcFields(Amount);
            InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

            CreatePaymentGLLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
              GenJournalLine."Account Type"::Vendor, VendorBankAccount[i]."Vendor No.",
              GenJournalLine."Applies-to Doc. Type"::Invoice, InvoiceNo,
              GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
              PurchaseHeader.Amount);
            GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount[i].Code);
            GenJournalLine.Modify(true);
        end;

        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        Assert.RecordCount(EFTExport, ArrayLen(VendorBankAccount));
        EFTExport.FindSet;
        repeat
            EFTExport.Description := CopyStr(EFTExport.Description, 1, MaxStrLen(TempEFTExportWorkset.Description));
            TempEFTExportWorkset.TransferFields(EFTExport);
            TempEFTExportWorkset.Include := true;
            TempEFTExportWorkset.Insert();
        until EFTExport.Next = 0;
    end;

    local procedure CreateVendorPaymentLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; VendorBankAccountNo: Code[20]; BankAccountNo: Code[20])
    begin
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::" ", '',
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo, LibraryRandom.RandInt(1000));
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndExportVendorPayment(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; VendorBankAccount: Record "Vendor Bank Account"; BankAccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        PaymentJournal: TestPage "Payment Journal";
        InvoiceNo: Code[20];
    begin
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);

        CreatePurchaseOrder(PurchaseHeader, VendorBankAccount."Vendor No.");
        PurchaseHeader.CalcFields(Amount);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorBankAccount."Vendor No.",
          GenJournalLine."Applies-to Doc. Type"::Invoice, InvoiceNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          PurchaseHeader.Amount);
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        Assert.RecordCount(EFTExport, 1);
        EFTExport.FindFirst();

        EFTExport.TestField("Sequence No.");
        GenJournalLine.Find();
        GenJournalLine.TestField("EFT Export Sequence No.", EFTExport."Sequence No.");

        TempEFTExportWorkset.TransferFields(EFTExport);
        TempEFTExportWorkset.Include := true;
        TempEFTExportWorkset.Insert;
    end;

    local procedure CreateAndExportVendorPaymentWithAllBusinessData(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; VendorBankAccount: Record "Vendor Bank Account"; BankAccountNo: Code[20])
    begin
        CreateAndExportVendorPayment(TempEFTExportWorkset, VendorBankAccount, BankAccountNo);
        TempEFTExportWorkset.TestField("Document No.");
        TempEFTExportWorkset.TestField("External Document No.");
        TempEFTExportWorkset.TestField("Applies-to Doc. No.");
        TempEFTExportWorkset.TestField("Payment Reference");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup."VAT Bus. Posting Group" := PurchaseHeader."VAT Bus. Posting Group";
        VATPostingSetup.Insert();
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item),
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateBankAccWithBankStatementSetup(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20])
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-EFT";
        if DataExchDefCode <> '' then
            BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Insert();

        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify(true);
    end;

    local procedure CreateVendorWithVendorBankAccount(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; CountryCode: Code[10])
    var
        DummyBankAccount: Record "Bank Account";
        ExportFormat: Option;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryCode);
        Vendor.Modify(true);

        case CountryCode of
            'US':
                ExportFormat := DummyBankAccount."Export Format"::US;
            'CA':
                ExportFormat := DummyBankAccount."Export Format"::CA;
            'MX':
                ExportFormat := DummyBankAccount."Export Format"::MX;
        end;

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Transit No.", GetTransitNo(ExportFormat));
        VendorBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID);
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateBankExportImportSetup(DataExchDefCode: Code[20]): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID;
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-EFT");
        BankExportImportSetup.Validate("Processing Codeunit ID", Codeunit::"Exp. Launcher EFT");
        BankExportImportSetup.Validate("Data Exch. Def. Code", DataExchDefCode);
        BankExportImportSetup.Insert();
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateDataExchDefForCA(): Code[20]
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        ACHRBHeader: Record "ACH RB Header";
        ACHRBDetail: Record "ACH RB Detail";
        ACHRBFooter: Record "ACH RB Footer";
        LineDefCode: Code[20];
        ColumnNo: Integer;
    begin
        CreateDataExchDef(DataExchDef);

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH RB Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT CA");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH RB Header", ACHRBHeader.FieldNo("File Creation Number"));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 6, '0', Database::"ACH RB Header", ACHRBHeader.FieldNo("File Creation Date"));
        ColumnNo := CreateDataExchColumnDefForDate(DataExchDef.Code, LineDefCode);
        CreateDataExchFieldMapping(
            DataExchDef.Code, LineDefCode, ColumnNo, Database::"ACH RB Header", ACHRBHeader.FieldNo("Settlement Date"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH RB Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT CA");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH RB Header", ACHRBHeader.FieldNo("File Creation Number"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Detail);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH RB Detail", Codeunit::"Exp. Pre-Mapping Det EFT CA", Codeunit::"Exp. Mapping Det EFT RB");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH RB Detail", ACHRBDetail.FieldNo("File Creation Number"));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH RB Detail", ACHRBDetail.FieldNo("Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 35, '', Database::"ACH RB Detail", ACHRBDetail.FieldNo("External Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH RB Detail", ACHRBDetail.FieldNo("Applies-to Doc. No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 50, '', Database::"ACH RB Detail", ACHRBDetail.FieldNo("Payment Reference"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Footer);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH RB Footer", Codeunit::"Exp. Pre-Mapping Foot EFT", Codeunit::"Exp. Mapping Foot EFT CA");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH RB Footer", ACHRBFooter.FieldNo("File Creation Number"));

        exit(DataExchDef.Code);
    end;

    local procedure CreateDataExchDefForUS(): Code[20]
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        ACHUSHeader: Record "ACH US Header";
        ACHUSDetail: Record "ACH US Detail";
        LineDefCode: Code[20];
        ColumnNo: Integer;
    begin
        CreateDataExchDef(DataExchDef);

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH US Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT US");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 6, '0', Database::"ACH US Header", ACHUSHeader.FieldNo("File Creation Date"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH US Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT US");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH US Header", ACHUSHeader.FieldNo("File Creation Date"));
        ColumnNo := CreateDataExchColumnDefForDate(DataExchDef.Code, LineDefCode);
        CreateDataExchFieldMapping(
            DataExchDef.Code, LineDefCode, ColumnNo, Database::"ACH US Header", ACHUSHeader.FieldNo("Effective Date"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Detail);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH US Detail", Codeunit::"Exp. Pre-Mapping Det EFT US", Codeunit::"Exp. Mapping Det EFT US");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH US Detail", ACHUSDetail.FieldNo("Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 35, '', Database::"ACH US Detail", ACHUSDetail.FieldNo("External Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH US Detail", ACHUSDetail.FieldNo("Applies-to Doc. No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 50, '', Database::"ACH US Detail", ACHUSDetail.FieldNo("Payment Reference"));

        exit(DataExchDef.Code);
    end;

    local procedure CreateDataExchDefForMX(): Code[20]
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        ACHCecobanHeader: Record "ACH Cecoban Header";
        ACHCecobanDetail: Record "ACH Cecoban Detail";
        LineDefCode: Code[20];
        ColumnNo: Integer;
    begin
        CreateDataExchDef(DataExchDef);

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH Cecoban Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT MX");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 6, '0', Database::"ACH Cecoban Header", ACHCecobanHeader.FieldNo("Record Type"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH Cecoban Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT MX");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH Cecoban Header", ACHCecobanHeader.FieldNo("Record Type"));
        ColumnNo := CreateDataExchColumnDefForDate(DataExchDef.Code, LineDefCode);
        CreateDataExchFieldMapping(
            DataExchDef.Code, LineDefCode, ColumnNo, Database::"ACH Cecoban Header", ACHCecobanHeader.FieldNo("Settlement Date"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Detail);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH Cecoban Detail", Codeunit::"Exp. Pre-Mapping Det EFT MX", Codeunit::"Exp. Mapping Det EFT MX");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH Cecoban Detail", ACHCecobanDetail.FieldNo("Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 35, '', Database::"ACH Cecoban Detail", ACHCecobanDetail.FieldNo("External Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH Cecoban Detail", ACHCecobanDetail.FieldNo("Applies-to Doc. No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 50, '', Database::"ACH Cecoban Detail", ACHCecobanDetail.FieldNo("Payment Reference"));

        exit(DataExchDef.Code);
    end;

    local procedure AddDataExchDefColumnWithMapping(DataExchDefCode: Code[20]; LineDefCode: Code[20]; Length: Integer; PadChar: Text[1]; TableID: Integer; FieldID: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        ColumnNo: Integer;
    begin
        ColumnNo := CreateDataExchColumnDefForText(DataExchDefCode, LineDefCode, Length, PadChar, DataExchColumnDef.Justification::Right);
        CreateDataExchFieldMapping(DataExchDefCode, LineDefCode, ColumnNo, TableID, FieldID);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def")
    begin
        DataExchDef.Code := LibraryUtility.GenerateGUID();
        DataExchDef.Validate(Type, DataExchDef.Type::"EFT Payment Export");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Fixed Text");
        DataExchDef.Validate("Validation Codeunit", Codeunit::"Exp. Validation EFT");
        DataExchDef.Validate("Reading/Writing Codeunit", Codeunit::"Exp. Writing EFT");
        DataExchDef.Validate("Reading/Writing XMLport", Xmlport::"Export Generic Fixed Width");
        DataExchDef.Validate("Ext. Data Handling Codeunit", Codeunit::"Exp. External Data EFT");
        DataExchDef.Validate("User Feedback Codeunit", Codeunit::"Exp. User Feedback EFT");
        DataExchDef.Insert(true);
    end;

    local procedure CreateDataExchLineDef(DataExchDefCode: Code[20]; LineType: Option): Code[20]
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchLineDef."Line Type" := LineType;
        DataExchLineDef.Code := LibraryUtility.GenerateGUID();
        DataExchLineDef.Insert(true);
        exit(DataExchLineDef.Code);
    end;

    local procedure CreateDataExchColumnDefForText(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; Length: Integer; PadCharacter: Text[1]; Justification: Option): Integer
    var
        DummyDataExchColumnDef: Record "Data Exch. Column Def";
    begin
        exit(
            CreateDataExchColumnDef(
                DataExchDefCode, DataExchLineDefCode, DummyDataExchColumnDef."Data Type"::Text, '', '', Length, PadCharacter, Justification));
    end;

    local procedure CreateDataExchColumnDefForDate(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]): Integer
    var
        DummyDataExchColumnDef: Record "Data Exch. Column Def";
    begin
        exit(
            CreateDataExchColumnDef(
                DataExchDefCode, DataExchLineDefCode, DummyDataExchColumnDef."Data Type"::Date, 'en-us', '<Year,2><Month,2><Day,2>', 6, '', 0));
    end;

    local procedure CreateDataExchColumnDef(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; DataType: Option; DataFormattingCulture: Text[10]; DataFormat: Text[100]; Length: Integer; PadCharacter: Text[1]; Justification: Option): Integer
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);
        if DataExchColumnDef.FindLast() then;

        DataExchColumnDef.Validate("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchColumnDef."Column No." += 1;
        DataExchColumnDef.Name := LibraryUtility.GenerateGUID();
        DataExchColumnDef.Validate("Data Type", DataType);
        DataExchColumnDef.Validate("Data Formatting Culture", DataFormattingCulture);
        DataExchColumnDef.Validate("Data Format", DataFormat);
        DataExchColumnDef.Validate(Length, Length);
        DataExchColumnDef.Validate("Pad Character", PadCharacter);
        DataExchColumnDef.Validate(Justification, Justification);
        DataExchColumnDef.Insert(true);
        exit(DataExchColumnDef."Column No.")
    end;

    local procedure CreateDataExchMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableID: Integer; PreMappingID: Integer; MappingID: Integer)
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Init();
        DataExchMapping.Validate("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchMapping.Validate("Table ID", TableID);
        DataExchMapping.Validate("Pre-Mapping Codeunit", PreMappingID);
        DataExchMapping.Validate("Mapping Codeunit", MappingID);
        DataExchMapping.Validate("Post-Mapping Codeunit", 0);
        DataExchMapping.Insert(true);
    end;

    local procedure CreateDataExchFieldMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; TableID: Integer; FieldID: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchDefCode);
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchFieldMapping.Validate("Column No.", ColumnNo);
        DataExchFieldMapping.Validate("Table ID", TableID);
        DataExchFieldMapping.Validate("Field ID", FieldID);
        DataExchFieldMapping.Validate(Optional, true);
        DataExchFieldMapping.Insert(true);
    end;

    local procedure MockExportPayment(var GenJournalLine: Record "Gen. Journal Line"; SequenceNo: Integer)
    var
        EFTExport: Record "EFT Export";
    begin
        GenJournalLine.Find();
        GenJournalLine."Check Exported" := true;
        GenJournalLine."Check Printed" := true;
        GenJournalLine."EFT Export Sequence No." := SequenceNo;
        GenJournalLine.Modify();

        EFTExport.Init();
        EFTExport."Journal Template Name" := GenJournalLine."Journal Template Name";
        EFTExport."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        EFTExport."Line No." := GenJournalLine."Line No.";
        EFTExport."Sequence No." := SequenceNo;
        EFTExport."Bank Payment Type" := GenJournalLine."Bank Payment Type";
        EFTExport.Insert();
    end;

    local procedure DuplicateDataExchangeDefinition(var DataExchDef: Record "Data Exch. Def"; var BankExportImportSetupTarget: Record "Bank Export/Import Setup"; DataExchDefCodeSource: Code[20])
    var
        DataExchLineDefSource: Record "Data Exch. Line Def";
        DataExchLineDefTarget: Record "Data Exch. Line Def";
        DataExchColumnDefSource: Record "Data Exch. Column Def";
        DataExchColumnDefTarget: Record "Data Exch. Column Def";
        BankExportImportSetupSource: Record "Bank Export/Import Setup";
        DataExchMappingSource: Record "Data Exch. Mapping";
        DataExchMappingTarget: Record "Data Exch. Mapping";
        DataExchFieldMappingSource: Record "Data Exch. Field Mapping";
        DataExchFieldMappingTarget: Record "Data Exch. Field Mapping";
    begin
        DataExchDef.Get(DataExchDefCodeSource);
        DataExchDef.Code := LibraryUtility.GenerateGUID;
        DataExchDef.Name := LibraryUtility.GenerateGUID;
        DataExchDef.Insert;

        DataExchLineDefSource.SetRange("Data Exch. Def Code", DataExchDefCodeSource);
        DataExchLineDefSource.FindSet;
        repeat
            DataExchLineDefTarget := DataExchLineDefSource;
            DataExchLineDefTarget."Data Exch. Def Code" := DataExchDef.Code;
            DataExchLineDefTarget.Code := LibraryUtility.GenerateGUID;
            DataExchLineDefTarget.Insert;

            DataExchColumnDefSource.SetRange("Data Exch. Def Code", DataExchDefCodeSource);
            DataExchColumnDefSource.SetRange("Data Exch. Line Def Code", DataExchLineDefSource.Code);
            DataExchColumnDefSource.FindSet;
            repeat
                DataExchColumnDefTarget := DataExchColumnDefSource;
                DataExchColumnDefTarget."Data Exch. Def Code" := DataExchDef.Code;
                DataExchColumnDefTarget."Data Exch. Line Def Code" := DataExchLineDefTarget.Code;
                DataExchColumnDefTarget.Insert;
            until DataExchColumnDefSource.Next = 0;

            DataExchMappingSource.SetRange("Data Exch. Def Code", DataExchDefCodeSource);
            DataExchMappingSource.SetRange("Data Exch. Line Def Code", DataExchLineDefSource.Code);
            DataExchMappingSource.FindSet;
            repeat
                DataExchMappingTarget := DataExchMappingSource;
                DataExchMappingTarget."Data Exch. Def Code" := DataExchDef.Code;
                DataExchMappingTarget."Data Exch. Line Def Code" := DataExchLineDefTarget.Code;
                DataExchMappingTarget.Insert;

                DataExchFieldMappingSource.SetRange("Data Exch. Def Code", DataExchDefCodeSource);
                DataExchFieldMappingSource.SetRange("Data Exch. Line Def Code", DataExchLineDefSource.Code);
                DataExchFieldMappingSource.SetRange("Table ID", DataExchMappingSource."Table ID");
                DataExchFieldMappingSource.FindSet;
                repeat
                    DataExchFieldMappingTarget := DataExchFieldMappingSource;
                    DataExchFieldMappingTarget."Data Exch. Def Code" := DataExchDef.Code;
                    DataExchFieldMappingTarget."Data Exch. Line Def Code" := DataExchLineDefTarget.Code;
                    DataExchFieldMappingTarget.Insert;
                until DataExchFieldMappingSource.Next = 0;
            until DataExchMappingSource.Next = 0;
        until DataExchLineDefSource.Next = 0;

        BankExportImportSetupSource.SetRange("Data Exch. Def. Code", DataExchDefCodeSource);
        BankExportImportSetupSource.FindFirst();

        BankExportImportSetupTarget := BankExportImportSetupSource;
        BankExportImportSetupTarget.Validate("Data Exch. Def. Code", DataExchDef.Code);
        BankExportImportSetupTarget.Code := LibraryUtility.GenerateGUID;
        BankExportImportSetupTarget.Insert;
    end;

    local procedure PrepareEFTExportScenario(var GenJournalLine: Record "Gen. Journal Line"; var PaymentJournal: TestPage "Payment Journal")
    var
        EFTExport: Record "EFT Export";
    begin
        CreateExportReportSelection(Layout::Word);
        CreateElectronicPaymentJournal(GenJournalLine);

        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        Commit();

        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.TestField("Check Exported", true);
        EFTExport.TestField("Check Printed", true);
    end;

    local procedure PrepareEFTSequenceNoScenario(var GenJournalBatch: Record "Gen. Journal Batch"; var VendorBankAccount: Record "Vendor Bank Account"; var BankAccountNo: Code[20]; var LastSequenceNo: Integer)
    var
        EFTExport: Record "EFT Export";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        LastSequenceNo := LibraryRandom.RandInt(1000);
        EFTExport."Sequence No." := LastSequenceNo;
        EFTExport.Insert();
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        BankAccountNo := BankAccount."No.";
    end;

    local procedure PrepareGenJournalLineForPrintReport(var GenJournalLine: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine."Check Exported" := true;
        GenJournalLine."Check Printed" := true;
        GenJournalLine."Check Transmitted" := true;
        GenJournalLine.Modify();
    end;

    local procedure PrintElectronicPaymentsRDLC(var GenJournalLine: Record "Gen. Journal Line"; UseRequestPage: Boolean)
    var
        ExportElectronicPayments: Report "Export Electronic Payments";
    begin
        GenJournalLine.SetRecFilter();
        ExportElectronicPayments.SetTableView(GenJournalLine);
        ExportElectronicPayments.UseRequestPage(UseRequestPage);
        Commit();
        ExportElectronicPayments.RunModal();
    end;

    local procedure PrintElectronicPaymentsWord(var GenJournalLine: Record "Gen. Journal Line"; UseRequestPage: Boolean)
    var
        ExportElecPaymentsWord: Report "ExportElecPayments - Word";
    begin
        GenJournalLine.SetRecFilter();
        ExportElecPaymentsWord.SetTableView(GenJournalLine);
        ExportElecPaymentsWord.UseRequestPage(UseRequestPage);
        Commit();
        ExportElecPaymentsWord.RunModal();
    end;

    local procedure RunReportExportElecPaymentsWord(var GenJournalLine: Record "Gen. Journal Line"; UseRequestPage: Boolean)
    var
        ExportElecPaymentsWord: Report "ExportElecPayments - Word";
    begin
        ExportElecPaymentsWord.SetTableView(GenJournalLine);
        ExportElecPaymentsWord.UseRequestPage(UseRequestPage);
        Commit();
        ExportElecPaymentsWord.RunModal();
    end;

    local procedure ProcessAndGenerateEFTFile(EFTExport: Record "EFT Export"; BankAccountNo: Code[20])
    var
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
    begin
        TempEFTExportWorkset.TransferFields(EFTExport);
        TempEFTExportWorkset.Include := true;
        TempEFTExportWorkset.Insert();
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccountNo, WorkDate, TempEFTExportWorkset, EFTValues);
    end;

    local procedure ExportPaymentJournal(var PaymentJournal: TestPage "Payment Journal"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        Commit();  // Commit required.
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.ExportPaymentsToFile.Invoke;  // Invokes action Export.
    end;

    local procedure ExportPaymentJournalViaAction(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
    end;

    local procedure PerformVoidTransmitElecPayments(var GenJournalLine: Record "Gen. Journal Line")
    var
        VoidTransmitElecPayments: Report "Void/Transmit Elec. Payments";
    begin
        Commit();
        VoidTransmitElecPayments.SetUsageType(1);   // Void
        VoidTransmitElecPayments.SetTableView(GenJournalLine);
        VoidTransmitElecPayments.SetBankAccountNo(GenJournalLine."Bal. Account No.");
        VoidTransmitElecPayments.UseRequestPage(false);
        VoidTransmitElecPayments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure ExportPaymentJournalDirect(var PaymentJournal: TestPage "Payment Journal"; GenJournalLine: Record "Gen. Journal Line")
    var
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        GenJnlLineRecRef: RecordRef;
        TempDirectory: Text;
    begin
        Commit();  // Commit required.

        // Functions expect this to be opened and set up
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");

        GenJournalLine.SetFilter("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetFilter("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJnlLineRecRef.GetTable(GenJournalLine);
        GenJnlLineRecRef.SetView(GenJournalLine.GetView);

        TempDirectory := FileManagement.CombinePath(TemporaryPath, TempSubDirectoryTxt);
        if not FileManagement.ServerDirectoryExists(TempDirectory) then
            FileManagement.ServerCreateDirectory(TempDirectory);

        // Handle the layout runs
        CustomLayoutReporting.SetOutputFileBaseName('Test Remittance');
        CustomLayoutReporting.SetSavePath(TempDirectory);
        CustomLayoutReporting.SetOutputOption(CustomLayoutReporting.GetXMLOption);
        CustomLayoutReporting.ProcessReportData(
          ReportSelections.Usage::"V.Remittance", GenJnlLineRecRef, GenJournalLine.FieldName("Account No."), DATABASE::Vendor,
          Vendor.FieldName("No."), false);
    end;

    local procedure FindAndUpdateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate("Transit No.", TransitNoTxt);
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);
        Vendor.Validate(Name, Vendor.Name + '_Name');
        Vendor.Validate("Currency Code", '');
        Vendor.Modify(true);
    end;

    local procedure FindEFTExport(var EFTExport: Record "EFT Export"; GenJournalLine: Record "Gen. Journal Line")
    begin
        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        EFTExport.SetRange("Line No.", GenJournalLine."Line No.");
        EFTExport.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Option; DocumentNo: Code[20]; BalAccountNo: Code[20])
    begin
        GLEntry.SetCurrentKey("Document Type", "Document No.", "Bal. Account No.");
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure GetReportCaption(ReportId: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Report);
        AllObjWithCaption.SetRange("Object ID", ReportId);
        AllObjWithCaption.FindFirst();
        exit(AllObjWithCaption."Object Caption");
    end;

    local procedure GetTransitNo(ExportFormat: Option): Code[20]
    var
        DummyBankAccount: Record "Bank Account";
    begin
        case ExportFormat of
            DummyBankAccount."Export Format"::US:
                exit('123456780');
            DummyBankAccount."Export Format"::MX:
                exit('123456780123456780');
            DummyBankAccount."Export Format"::CA:
                exit(TransitNoTxt);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTempACHRBHeader(var TempACHRBHeaderResult: Record "ACH RB Header" temporary)
    begin
        Clear(TempACHRBHeaderResult);
        TempACHRBHeaderResult.DeleteAll;

        TempACHRBHeaderResult.Copy(TempACHRBHeader, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHRBDetail(var TempACHRBDetailResult: Record "ACH RB Detail" temporary)
    begin
        Clear(TempACHRBDetailResult);
        TempACHRBDetailResult.DeleteAll;

        TempACHRBDetailResult.Copy(TempACHRBDetail, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHRBFooter(var TempACHRBFooterResult: Record "ACH RB Footer" temporary)
    begin
        Clear(TempACHRBFooterResult);
        TempACHRBFooterResult.DeleteAll;

        TempACHRBFooterResult.Copy(TempACHRBFooter, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHUSHeader(var TempACHUSHeaderResult: Record "ACH US Header" temporary)
    begin
        Clear(TempACHUSHeaderResult);
        TempACHUSHeaderResult.DeleteAll();

        TempACHUSHeaderResult.Copy(TempACHUSHeader, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHUSDetail(var TempACHUSDetailResult: Record "ACH US Detail" temporary)
    begin
        Clear(TempACHUSDetailResult);
        TempACHUSDetailResult.DeleteAll;

        TempACHUSDetailResult.Copy(TempACHUSDetail, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHCecobanHeader(var TempACHCecobanHeaderResult: Record "ACH Cecoban Header" temporary)
    begin
        Clear(TempACHCecobanHeaderResult);
        TempACHCecobanHeaderResult.DeleteAll;

        TempACHCecobanHeaderResult.Copy(TempACHCecobanHeader, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHCecobanDetail(var TempACHCecobanDetailResult: Record "ACH Cecoban Detail" temporary)
    begin
        Clear(TempACHCecobanDetailResult);
        TempACHCecobanDetailResult.DeleteAll;

        TempACHCecobanDetailResult.Copy(TempACHCecobanDetail, true);
    end;

    local procedure GetFilesListFromZip(var FilesList: List of [Text])
    var
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        ZipFile: File;
        ZipInStream: InStream;
        ZipPath: Text;
    begin
        ZipPath := FileManagement.CombinePath(TemporaryPath(), 'AllReports.zip');
        Assert.IsTrue(Exists(ZipPath), 'AllReports.zip is not found');
        ZipFile.Open(ZipPath);
        ZipFile.CreateInStream(ZipInStream);
        DataCompression.OpenZipArchive(ZipInStream, false);
        DataCompression.GetEntryList(FilesList);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
        CheckClearAllReportsZip();
    end;

    local procedure CheckClearAllReportsZip()
    var
        FileManagement: Codeunit "File Management";
        ZipPath: Text;
    begin
        ZipPath := FileManagement.CombinePath(TemporaryPath(), 'AllReports.zip');
        if Exists(ZipPath) then
            Erase(ZipPath);
    end;

    local procedure ModifyUseForElectronicPaymentsVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; CheckBoxValue: Boolean)
    begin
        VendorBankAccount.SetFilter("Vendor No.", '<>''''');
        VendorBankAccount.FindFirst();
        VendorBankAccount.Validate("Use for Electronic Payments", CheckBoxValue);
        VendorBankAccount.Modify(true);
    end;

    local procedure ModifyFederalIdCompanyInformation(FederalIDNo: Text[30])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Federal ID No.", FederalIDNo);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateForceDocBalanceOnGenJnlTemplate(GenJournalTemplateName: Code[10]; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJournalTemplateName);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
    end;

    local procedure VoidCheckCheckLedgerEntries(BankAccountNo: Code[20])
    var
        CheckLedgerEntries: TestPage "Check Ledger Entries";
    begin
        CheckLedgerEntries.OpenEdit();
        CheckLedgerEntries.FILTER.SetFilter("Bank Account No.", BankAccountNo);
        CheckLedgerEntries."Void Check".Invoke;  // Invokes action VoidCheck.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsRequestPageHandler(var ExportElectronicPayments: TestRequestPage "Export Electronic Payments")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        ExportElectronicPayments.BankAccountNo.SetValue(BankAccountNo);
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText);
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText);
        ExportElectronicPayments.OutputMethod.SetValue('PDF');
        ExportElectronicPayments.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsXMLRequestPageHandler(var ExportElectronicPayments: TestRequestPage "Export Electronic Payments")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        ExportElectronicPayments.BankAccountNo.SetValue(BankAccountNo);
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText);
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText);
        ExportElectronicPayments.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsWordLayoutRequestPageHandler(var ExportElecPaymentsWord: TestRequestPage "ExportElecPayments - Word")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        ExportElecPaymentsWord.BankAccountNo.SetValue(BankAccountNo);
        ExportElecPaymentsWord.OutputMethod.SetValue('PDF');
        ExportElecPaymentsWord.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_SaveAsXmlRPH(var ExportElecPaymentsWord: TestRequestPage "ExportElecPayments - Word")
    begin
        ExportElecPaymentsWord.BankAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText);
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText);
        ExportElecPaymentsWord.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsRH(var ExportElectronicPayments: Report "Export Electronic Payments")
    begin
        ExportElectronicPayments.SaveAsPdf(LibraryUtility.GenerateGUID());
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWordRH(var ExportElecPaymentsWord: Report "ExportElecPayments - Word")
    begin
        ExportElecPaymentsWord.SaveAsPdf(LibraryUtility.GenerateGUID());
    end;

    [Scope('OnPrem')]
    procedure CreateExportReportSelection("Layout": Option RDLC,Word)
    var
        ReportSelections: Record "Report Selections";
    begin
        // Insert or modify to get the expected remittance report selection
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"V.Remittance";
        case Layout of
            Layout::RDLC:
                ReportSelections."Report ID" := REPORT::"Export Electronic Payments";
            Layout::Word:
                ReportSelections."Report ID" := REPORT::"ExportElecPayments - Word";
        end;
        ReportSelections.Sequence := '1';
        ReportSelections.Insert();
        Commit();
    end;

    local procedure UpdateDateFormatsOnCAEFTDataExchDef(DataExchDef: Record "Data Exch. Def"; DateFormat: Text[100]; DateFormatLength: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ACHRBHeader: Record "ACH RB Header";
        ACHRBDetail: Record "ACH RB Detail";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Header);
        DataExchLineDef.FindFirst();

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.SetRange(Name, ACHRBHeader.FieldName("File Creation Date"));
        DataExchColumnDef.FindFirst();
        DataExchColumnDef."Data Format" := DateFormat;
        DataExchColumnDef.Length := DateFormatLength;
        DataExchColumnDef.Modify(true);

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Detail);
        DataExchLineDef.FindFirst();

        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.SetRange(Name, ACHRBDetail.FieldName("Payment Date"));
        DataExchColumnDef.FindFirst();
        DataExchColumnDef."Data Format" := DateFormat;
        DataExchColumnDef.Length := DateFormatLength;
        DataExchColumnDef.Modify(true);
    end;

    local procedure InsertEntryDetailSequenceNo(DataExchDef: Record "Data Exch. Def")
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        ACHUSHeader: Record "ACH US Header";
        ACHUSDetail: Record "ACH US Detail";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Detail);
        DataExchLineDef.FindFirst();

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.FindLast();
        DataExchColumnDef."Column No." += 1;
        DataExchColumnDef.Name := 'Entry Detail Sequence';
        DataExchColumnDef.Insert(true);

        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchDef.Code;
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchFieldMapping."Column No." := DataExchColumnDef."Column No.";
        DataExchFieldMapping.Validate("Table ID", Database::"ACH US Detail");
        DataExchFieldMapping.Validate("Field ID", ACHUSDetail.FieldNo("Entry Detail Sequence No"));
        DataExchFieldMapping.Insert(true);
    end;

    local procedure VerifyPaymentFileError(GenJournalLine: Record "Gen. Journal Line"; PaymentFileErrorTxt: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        with PaymentJnlExportErrorText do begin
            SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
            SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
            SetRange("Document No.", GenJournalLine."Document No.");
            SetRange("Journal Line No.", GenJournalLine."Line No.");
            FindFirst;
            TestField("Error Text", CopyStr(PaymentFileErrorTxt, 1, MaxStrLen("Error Text")));
        end;
    end;

    local procedure VerifyGLEntry(DocumentType: Option; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentType, DocumentNo, GLAccountNo);
        Assert.AreNearlyEqual(GLEntry.Amount, Round(Amount), LibraryERM.GetAmountRoundingPrecision, AmountVerificationMsg);
    end;

    local procedure VerifyCheckLedgEntryCount(PostingDate: Date; DocNo: Code[20]; EntryStatus: Option; ExpectedCount: Integer)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Document Type", CheckLedgerEntry."Document Type"::Payment);
        CheckLedgerEntry.SetRange("Posting Date", PostingDate);
        CheckLedgerEntry.SetRange("Document No.", DocNo);
        CheckLedgerEntry.SetRange("Entry Status", EntryStatus);
        Assert.RecordCount(CheckLedgerEntry, ExpectedCount);
    end;

    local procedure VerifyBankAccountFileCreationNumberIncrement(var BankAccount: Record "Bank Account")
    var
        LastFileCreationNo: Integer;
    begin
        LastFileCreationNo := BankAccount."Last E-Pay File Creation No.";
        BankAccount.Find();
        BankAccount.TestField("Last E-Pay File Creation No.", LastFileCreationNo + 1);
    end;

    local procedure VerifyEFTExportCA(var ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer"; EFTExportWorkset: Record "EFT Export Workset"; FileCreationNo: Integer; SettleDate: Date)
    var
        ExportEFTRB: Codeunit "Export EFT (RB)";
    begin
        ERMElectronicFundsTransfer.GetTempACHRBHeader(TempACHRBHeader);
        TempACHRBHeader.TestField("File Creation Number", FileCreationNo);
        TempACHRBHeader.TestField("File Creation Date", ExportEFTRB.JulianDate(Today()));
        TempACHRBHeader.TestField("Settlement Date", SettleDate);
        TempACHRBHeader.TestField("Settlement Julian Date", ExportEFTRB.JulianDate(SettleDate)); // TFS 401126

        ERMElectronicFundsTransfer.GetTempACHRBDetail(TempACHRBDetail);
        TempACHRBDetail.TestField("File Creation Number", FileCreationNo);
        TempACHRBDetail.TestField("Document No.", EFTExportWorkset."Document No.");
        TempACHRBDetail.TestField("External Document No.", EFTExportWorkset."External Document No.");
        TempACHRBDetail.TestField("Applies-to Doc. No.", EFTExportWorkset."Applies-to Doc. No.");
        TempACHRBDetail.TestField("Payment Reference", EFTExportWorkset."Payment Reference");

        ERMElectronicFundsTransfer.GetTempACHRBFooter(TempACHRBFooter);
        TempACHRBFooter.TestField("File Creation Number", FileCreationNo);
    end;

    local procedure VerifyEFTExportUS(var ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer"; EFTExportWorkset: Record "EFT Export Workset"; SettleDate: Date)
    begin
        ERMElectronicFundsTransfer.GetTempACHUSHeader(TempACHUSHeader);
        TempACHUSHeader.TestField("Effective Date", SettleDate);

        ERMElectronicFundsTransfer.GetTempACHUSDetail(TempACHUSDetail);
        TempACHUSDetail.TestField("Document No.", EFTExportWorkset."Document No.");
        TempACHUSDetail.TestField("External Document No.", EFTExportWorkset."External Document No.");
        TempACHUSDetail.TestField("Applies-to Doc. No.", EFTExportWorkset."Applies-to Doc. No.");
        TempACHUSDetail.TestField("Payment Reference", EFTExportWorkset."Payment Reference");
    end;

    local procedure VerifyEFTExportMX(var ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer"; EFTExportWorkset: Record "EFT Export Workset"; SettleDate: Date)
    begin
        ERMElectronicFundsTransfer.GetTempACHCecobanHeader(TempACHCecobanHeader);
        TempACHCecobanHeader.TESTFIELD("Settlement Date", SettleDate);

        ERMElectronicFundsTransfer.GetTempACHCecobanDetail(TempACHCecobanDetail);
        TempACHCecobanDetail.TestField("Document No.", EFTExportWorkset."Document No.");
        TempACHCecobanDetail.TestField("External Document No.", EFTExportWorkset."External Document No.");
        TempACHCecobanDetail.TestField("Applies-to Doc. No.", EFTExportWorkset."Applies-to Doc. No.");
        TempACHCecobanDetail.TestField("Payment Reference", EFTExportWorkset."Payment Reference");
    end;

    local procedure VerifyLastGenJnlLineFields(var GenJournalLine: Record "Gen. Journal Line"; EFTSequenceNo: Integer; Exported: Boolean; Transmitted: Boolean)
    begin
        GenJournalLine.FindLast();
        GenJournalLine.TestField("EFT Export Sequence No.", EFTSequenceNo);
        GenJournalLine.TestField("Check Printed", Exported);
        GenJournalLine.TestField("Check Exported", Exported);
        GenJournalLine.TestField("Check Transmitted", Transmitted);
    end;

    local procedure VerifyGenJnlLineFields(var GenJournalLine: Record "Gen. Journal Line"; EFTSequenceNo: Integer; Exported: Boolean; Transmitted: Boolean)
    begin
        GenJournalLine.Find();
        GenJournalLine.TestField("EFT Export Sequence No.", EFTSequenceNo);
        GenJournalLine.TestField("Check Printed", Exported);
        GenJournalLine.TestField("Check Exported", Exported);
        GenJournalLine.TestField("Check Transmitted", Transmitted);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerEnqueueQuestion(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 8800, 'OnIsTestMode', '', false, false)]
    local procedure EnableTestModeOnCustomReportLayout(var TestMode: Boolean)
    begin
        TestMode := true
    end;

    [EventSubscriber(ObjectType::Codeunit, 10098, 'OnIsTestMode', '', false, false)]
    local procedure EnableTestModeOnGenerateEFT(var TestMode: Boolean)
    begin
        TestMode := true
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (RB)", 'OnBeforeACHRBHeaderModify', '', false, false)]
    local procedure StoreTempACHRBHeaderOnBeforeACHRBHeaderModify(var ACHRBHeader: Record "ACH RB Header"; BankAccount: Record "Bank Account")
    begin
        TempACHRBHeader := ACHRBHeader;
        if TempACHRBHeader.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (RB)", 'OnBeforeACHRBDetailModify', '', false, false)]
    local procedure StoreTempACHRBDetailOnBeforeACHRBDetailModify(var ACHRBDetail: Record "ACH RB Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20]; SettleDate: Date)
    begin
        TempACHRBDetail := ACHRBDetail;
        if TempACHRBDetail.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (RB)", 'OnBeforeACHRBFooterModify', '', false, false)]
    local procedure StoreTempACHRBFooterOnBeforeACHUSDetailModify(var ACHRBFooter: Record "ACH RB Footer"; BankAccNo: Code[20])
    begin
        TempACHRBFooter := ACHRBFooter;
        if TempACHRBFooter.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (ACH)", 'OnStartExportBatchOnBeforeACHUSHeaderModify', '', false, false)]
    local procedure StoreTempACHUSHeaderOnBeforeACHUSHeaderModify(var ACHUSHeader: Record "ACH US Header");
    begin
        TempACHUSHeader := ACHUSHeader;
        if TempACHUSHeader.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (ACH)", 'OnBeforeACHUSDetailModify', '', false, false)]
    local procedure StoreTempACHUSDetailOnBeforeACHUSDetailModify(var ACHUSDetail: Record "ACH US Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20])
    begin
        TempACHUSDetail := ACHUSDetail;
        if TempACHUSDetail.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (Cecoban)", 'OnStartExportBatchOnBeforeACHCecobanHeaderModify', '', false, false)]
    local procedure StoreTempACHCecobanHeaderOnBeforeACHCecobanHeaderModify(var ACHCecobanHeader: Record "ACH Cecoban Header")
    begin
        TempACHCecobanHeader := ACHCecobanHeader;
        if TempACHCecobanHeader.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (Cecoban)", 'OnBeforeACHCecobanDetailModify', '', false, false)]
    local procedure StoreTempACHCecobanDetailOnBeforeACHCecobanDetailModify(var ACHCecobanDetail: Record "ACH Cecoban Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20])
    begin
        TempACHCecobanDetail := ACHCecobanDetail;
        if TempACHCecobanDetail.Insert() then;
    end;
}

