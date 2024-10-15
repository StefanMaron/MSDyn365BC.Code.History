codeunit 141021 "ERM Electronic - Banking"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic - Banking] [GST] [WHT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        EFTTypeBlankErr: Label 'EFT Type must not be blank';
        ValueMustBeSameMsg: Label 'Value must be same.';
        ValueMustExistMsg: Label 'Value must be exist.';
        WrongRegNoErr: Label 'Wrong Company Registration Number';
        WrongRegNoLblErr: Label 'Wrong "ABN" field caption';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryJournals: Codeunit "Library - Journals";
        ERMElectronicBanking: Codeunit "ERM Electronic - Banking";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        NothingToExportErr: Label 'There is nothing to export.';
        CancelExportRequiredErr: Label 'You cannot delete line number %3 in journal template name %1, journal batch name %2 because it has been exported. You must cancel the export first.', Comment = '%1 - journal template name, %2 - journal batch name, %3 - line number';
        InvalidWHTRealizedTypeErr: Label 'Line number %3 in journal template name %1, journal batch name %2 cannot be exported because it must be applied to an invoice when the WHT Realized Type field contains Payment.', Comment = '%1 - journal template name, %2 - journal batch name, %3 - line number';
        PaymentAlreadyExportedErr: Label 'Line number %3 in journal template name %1, journal batch name %2 has been already exported.', Comment = '%1 - journal template name, %2 - journal batch name, %3 - line number';

    [Test]
    [Scope('OnPrem')]
    procedure VendorWithEFTPayment()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO] EFT Payment and EFT Vendor Bank Account Code on the vendor card.

        // Setup.
        Initialize;
        CreateVendor(Vendor, '', '');  // WHT Business Posting Group, VAT Bus. Posting Group - Blank.

        // Exercise.
        VendorCard.OpenEdit;
        VendorCard.FILTER.SetFilter("No.", Vendor."No.");

        // [THEN] Verify EFT Payment and EFT Bank Account No on Vendor Card.
        VendorCard."EFT Payment".AssertEquals(true);
        VendorCard."EFT Bank Account No.".AssertEquals(Vendor."EFT Bank Account No.");
        VendorCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplePostedPurchaseInvoiceWithWHT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        DocumentNo: array[4] of Code[20];
        OldGSTProdPostingGroup: Code[20];
    begin
        // Verify WHT Amount after posting multiple Purchase Orders.

        // Setup.
        Initialize;
        GeneralLedgerSetup.Get();
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreateMultipleWHTPostingSetup(WHTPostingSetup);

        // Exercise.
        CreateAndPostMultiplePurchaseOrder(
          DocumentNo, WHTPostingSetup."WHT Business Posting Group", WHTPostingSetup."WHT Product Posting Group",
          VATPostingSetup."VAT Bus. Posting Group");

        // [THEN] Verify Remaining WHT Prepaid Amount in Posted Purchase Invoice and new created General Journal Line after running Suggest Vendor Payment.
        VerifyRemWHTPrepaidAmountOnPurchInvHeader(DocumentNo[1], '');  // WHT Product Posting Group - Blank.
        VerifyRemWHTPrepaidAmountOnPurchInvHeader(DocumentNo[2], WHTPostingSetup."WHT Product Posting Group");
        VerifyRemWHTPrepaidAmountOnPurchInvHeader(DocumentNo[3], '');  // WHT Product Posting Group - Blank.
        VerifyRemWHTPrepaidAmountOnPurchInvHeader(DocumentNo[4], '');  // WHT Product Posting Group - Blank.

        // Tear down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithEFTPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: array[4] of Code[20];
        OldGSTProdPostingGroup: Code[20];
        BankAccountNo: Code[20];
        VendorFilter: Text;
    begin
        // [SCENARIO] Payment Journal Line after running SuggestVendorPayments with EFT Payment as True.

        // [GIVEN] Create multiple WHT Posting Setup, Bank Account. Create and Post multiple Purchase Orders.
        Initialize;
        GeneralLedgerSetup.Get();
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreateMultipleWHTPostingSetup(WHTPostingSetup);
        BankAccountNo :=
          CreateBankAccount(true, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', WorkDate));  // EFT Payment -TRUE, Last Payment Date before WORKDATE.
        CreateGenJournalBatch(GenJournalBatch, BankAccountNo);
        VendorFilter :=
          CreateAndPostMultiplePurchaseOrder(
            DocumentNo, WHTPostingSetup."WHT Business Posting Group", WHTPostingSetup."WHT Product Posting Group",
            VATPostingSetup."VAT Bus. Posting Group");

        // Exercise.
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, VendorFilter, false);

        // [THEN] Verify Remaining WHT Prepaid Amount in Posted Purchase Invoice and new created General Journal Line after running Suggest Vendor Payment.
        VerifyWHTAmountAndGenJournalLine(DocumentNo[1], '');  // WHT Product Posting Group - Blank.
        VerifyWHTAmountAndGenJournalLine(DocumentNo[2], WHTPostingSetup."WHT Product Posting Group");
        VerifyWHTAmountAndGenJournalLine(DocumentNo[3], '');  // WHT Product Posting Group - Blank.
        VerifyWHTAmountAndGenJournalLine(DocumentNo[4], '');  // WHT Product Posting Group - Blank.

        // Tear down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsAndCreateEFTFile()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        WHTPostingSetup: Record "WHT Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: array[4] of Code[20];
        BankAccountNo: Code[20];
        RemWHTPrepaidAmountTxt: Text;
        OldGSTProdPostingGroup: Code[20];
        FilePath: Text;
        VendorFilter: Text;
    begin
        // [SCENARIO] EFT Text file, Payment Journal Line after running SuggestVendorPayments with EFT Payment as True and create File.

        // [GIVEN] Create multiple WHT Posting Setup, Bank Account. Create and Post multiple Purchase Orders.
        Initialize;
        GeneralLedgerSetup.Get();
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        BankAccountNo :=
          CreateBankAccount(true, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', WorkDate));  // EFT Payment -TRUE, Last Payment Date before WORKDATE.
        CreateGenJournalBatch(GenJournalBatch, BankAccountNo);
        CreateMultipleWHTPostingSetup(WHTPostingSetup);
        VendorFilter :=
          CreateAndPostMultiplePurchaseOrder(
            DocumentNo, WHTPostingSetup."WHT Business Posting Group", WHTPostingSetup."WHT Product Posting Group",
            VATPostingSetup."VAT Bus. Posting Group");
        FindPurchInvHeader(PurchInvHeader, DocumentNo[4]);
        RemWHTPrepaidAmountTxt := ConvertWHTPrepaidAmountInText(PurchInvHeader."Rem. WHT Prepaid Amount (LCY)");
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, VendorFilter, false);

        // Exercise.
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Verify WHT Amount in generated text file. Hardcode value use for position in text file.
        Assert.IsTrue(
          LibraryTextFileValidation.FindLineWithValue(FilePath, 121 - StrLen(RemWHTPrepaidAmountTxt),
            StrLen(RemWHTPrepaidAmountTxt), RemWHTPrepaidAmountTxt) > '', ValueMustExistMsg);

        // Tear down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalAndCreateFileEFTTypeBlankError()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        OldGSTProdPostingGroup: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Error on Suggest Vendor Payment when EFT Type blank on Vendor.

        // [GIVEN] Create and Post Purchase Order with WHT Posting Setup.
        Initialize;
        GeneralLedgerSetup.Get();
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        BankAccountNo :=
          CreateBankAccount(false, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', WorkDate));  // EFT Payment - FALSE, Last Payment Date before WORKDATE.
        CreateGenJournalBatch(GenJournalBatch, BankAccountNo);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        // [GIVEN] Set "EFT Payment" = No
        Vendor.Validate("EFT Payment", false);
        Vendor.Modify();
        CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), false);  // Price Including VAT - FALSE.
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);

        // [WHEN] Create EFT File.
        asserterror EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Verify expected error - EFT Type must not be blank for Vendor.
        Assert.ExpectedError(EFTTypeBlankErr);

        // Tear down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler,PaymentToleranceWarningModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalAndCreateFileWithPaymentTolerance()
    begin
        // [SCENARIO] EFT Text file, Payment Journal Line with Maximum Payment Tolerance Amount after running SuggestVendorPayments with EFT Payment as True and create File.
        PaymentJournalAndCreateFileWithPayment(true);  // Payment Tolerance Warning - TRUE.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalAndCreateFileWithPartialPayment()
    begin
        // [SCENARIO] EFT Text file, Payment Journal Line with Partial payment after running SuggestVendorPayments with EFT Payment as True and create File.
        PaymentJournalAndCreateFileWithPayment(false);  // Payment Tolerance Warning - FALSE.
    end;

    local procedure PaymentJournalAndCreateFileWithPayment(PaymentToleranceWarning: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        OldGSTProdPostingGroup: Code[20];
        FilePath: Text;
        AmountTxt: Text;
        Amount: Decimal;
        PaymentJournalAmount: Decimal;
        MaxPaymentToleranceAmount: Decimal;
        BankAccountNo: Code[20];
    begin
        // [GIVEN] Create and Post Purchase Order with WHT Posting Setup. Suggest Vendor Payment and reduce Amount on Payment Journal.
        Initialize;
        GeneralLedgerSetup.Get();
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        MaxPaymentToleranceAmount := LibraryRandom.RandDec(10, 2);
        UpdateGLSetupPaymentToleranceWarning(PaymentToleranceWarning, MaxPaymentToleranceAmount);
        BankAccountNo :=
          CreateBankAccount(true, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', WorkDate));  // EFT Payment -TRUE, Last Payment Date before WORKDATE.
        CreateGenJournalBatch(GenJournalBatch, BankAccountNo);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), false);  // Price Including VAT - FALSE.
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);
        PaymentJournalAmount := UpdateGenJournalLineAmount(Vendor."No.", MaxPaymentToleranceAmount);

        // Calculation of Partial Amount without WHT on Payment journal.
        Amount :=
          PaymentJournalAmount - CalculateWHTAmount(
            WHTPostingSetup."WHT Business Posting Group", WHTPostingSetup."WHT Product Posting Group", PaymentJournalAmount);
        AmountTxt := ConvertWHTPrepaidAmountInText(Amount);

        // Exercise: Create EFT File.
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Verify Amount with Maximum Payment Tolerance Amount or Partial Amount on generated text file. Hardcode value use for position in text file.
        Assert.IsTrue(
          LibraryTextFileValidation.FindLineWithValue(FilePath, 31 - StrLen(AmountTxt),
            StrLen(AmountTxt), AmountTxt) > '', ValueMustExistMsg);

        // Tear down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
        UpdateGLSetupPaymentToleranceWarning(GeneralLedgerSetup."Payment Tolerance Warning", GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalAndCreateFileWithPriceIncludingVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        OldGSTProdPostingGroup: Code[20];
        BankAccountNo: Code[20];
        FilePath: Text;
        AmountTxt: Text;
    begin
        // [SCENARIO] EFT Text file, Payment Journal Line with Prices Including VAT after running SuggestVendorPayments with EFT Payment as True and create File.

        // [GIVEN] Create and Post multiple Purchase Orders with WHT Posting Setup and Prices Including VAT - TRUE. Suggest Vendor Payment.
        Initialize;
        GeneralLedgerSetup.Get();
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        BankAccountNo :=
          CreateBankAccount(true, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', WorkDate));  // EFT Payment -TRUE, Last Payment Date before WORKDATE.
        CreateGenJournalBatch(GenJournalBatch, BankAccountNo);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, Item."No.", true);  // Price Including VAT - TRUE.
        CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, Item."No.", true);  // Price Including VAT - TRUE.
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);
        AmountTxt := CalculateAmountWithoutWHTOnMultipleGenJournalLine(Vendor."No.");

        // Exercise: Create EFT File.
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Verify Amount of Payment on generated text file. Hardcode value use for position in text file.
        Assert.IsTrue(
          LibraryTextFileValidation.FindLineWithValue(FilePath, 31 - StrLen(AmountTxt),
            StrLen(AmountTxt), AmountTxt) > '', ValueMustExistMsg);

        // Tear down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCompanyRegistationNoWithDivisionPartNo()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [Company Information] [UT]
        // [SCENARIO 375887] If "ABN Division Part No." is not empty then GetRegistrationNumber and GetRegistrationNumberLbl should return "ABN" and "ABN Division Part No." and its caption
        CompanyInformation.Get();
        CompanyInformation.Validate(ABN, '53001003000');
        CompanyInformation.Validate(
          "ABN Division Part No.",
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("ABN Division Part No."), DATABASE::"Company Information"));
        CompanyInformation.Modify();
        Assert.AreEqual(
          StrSubstNo('%1 %2', CompanyInformation.ABN, CompanyInformation."ABN Division Part No."),
          CompanyInformation.GetRegistrationNumber,
          WrongRegNoErr);
        Assert.AreEqual(CompanyInformation.FieldCaption(ABN), CompanyInformation.GetRegistrationNumberLbl, WrongRegNoLblErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCompanyRegistationNoWithoutDivisionPartNo()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [Company Information] [UT]
        // [SCENARIO 375887] If "ABN Division Part No." is empty then GetRegistrationNumber and GetRegistrationNumberLbl should return "ABN" and its caption
        CompanyInformation.Get();
        CompanyInformation.Validate(ABN, '53001003000');
        CompanyInformation.Validate("ABN Division Part No.", '');
        CompanyInformation.Modify();
        Assert.AreEqual(CompanyInformation.ABN, CompanyInformation.GetRegistrationNumber, WrongRegNoErr);
        Assert.AreEqual(CompanyInformation.FieldCaption(ABN), CompanyInformation.GetRegistrationNumberLbl, WrongRegNoLblErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatBranchNumberWtihHyphen()
    var
        EFTMgt: Codeunit "EFT Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function FormatBranchNumber for value with hyphen does not creates extra hyphen
        Assert.AreEqual('111-222', EFTMgt.FormatBranchNumber('111-222'), 'Invalid formatted branch number');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatBranchNumberWtihoutHyphen()
    var
        EFTMgt: Codeunit "EFT Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Function FormatBranchNumber for value without hyphen returns value with hyphen
        Assert.AreEqual('111-222', EFTMgt.FormatBranchNumber('111222'), 'Invalid formatted branch number');
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FileLineLength()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        OldGSTProdPostingGroup: Code[20];
        BankAccountNo: Code[20];
        FilePath: Text;
        i: Integer;
    begin
        // [SCENARIO 272097] EFT Text file must contain lines with 120 symbols

        // [GIVEN] Create and Post multipl Purchase Order
        Initialize;
        GeneralLedgerSetup.Get();
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        BankAccountNo :=
          CreateBankAccount(true, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', WorkDate));  // EFT Payment -TRUE, Last Payment Date before WORKDATE.
        CreateGenJournalBatch(GenJournalBatch, BankAccountNo);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, Item."No.", true);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);

        // [WHEN] EFT File is being created
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] All 3 lines have 120 simbols length
        for i := 1 to 3 do
            VerifyFileLineLength(FilePath, i);

        // Tear down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentVendLedgerEntryLinkedWithEFTRegister()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EFTRegister: Record "EFT Register";
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Posted payment which where exported has a link to EFT register
        Initialize;

        // [GIVEN] Create and post invoice for vendor VEND
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Create payment journal line to bank BANK applied to posted invoice
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);

        // [GIVEN] Run EFT export for created payment
        EFTPaymentCreateFile(GenJournalLine);
        FindEFTRegister(EFTRegister, GenJournalBatch."Bal. Account No.");

        // [WHEN] Exported payment journal line is being posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment vendor ledger entry has a link to EFT register
        FindPaymentVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");
        VendorLedgerEntry.TestField("EFT Register No.", EFTRegister."No.");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportSummarizedPerVendorPayment()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
        FilePath: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Summarized per vendor payment can be exported to EFT file
        Initialize;

        // [GIVEN] Post 3 invoices for vendor VEND
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to 3 do
            CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, true);

        // [GIVEN] Run suggest payment with EFT Payment = Yes, Summarize per Vendor = Yes
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", true);
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);

        // [WHEN] EFT File is being created
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] EFT file contains line with payment Document No.
        VerifyDocumentNoEFTFile(FilePath, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportNotAppliedPaymentWithSkipWHTNo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Export payment with Skip WHT = No without applying it to invoice leads to error
        Initialize;

        // [GIVEN] Payment journal line without applying to invoice
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreateVendor(Vendor, '', VATPostingSetup."VAT Bus. Posting Group");
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        CreatePaymentJournalLine(GenJournalBatch, GenJournalLine, Vendor);

        // [GIVEN] Set journal line Skip WHT = No
        UpdateGenJournalLineSkipWHT(GenJournalLine, false);

        // [WHEN] EFT File is being created
        asserterror EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Expected error "Cannot export payment because line XXX must be applied to an invoice line when the WHT Realized Type Payment"
        Assert.ExpectedError(
          StrSubstNo(
            InvalidWHTRealizedTypeErr,
            GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name",
            GenJournalLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportNotAppliedPaymentWithSkipWHTYes()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        FilePath: Text;
        TextLine: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Export payment with Skip WHT = Yes without applying it to invoice
        Initialize;

        // [GIVEN] Payment journal line without applying to invoice
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreateVendor(Vendor, '', VATPostingSetup."VAT Bus. Posting Group");
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        CreatePaymentJournalLine(GenJournalBatch, GenJournalLine, Vendor);

        // [GIVEN] Set journal line Skip WHT = Yes
        UpdateGenJournalLineSkipWHT(GenJournalLine, true);

        // [WHEN] EFT File is being created
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Payment exported with WHT Amount = 0
        TextLine := LibraryTextFileValidation.ReadLine(FilePath, 2);
        VerifyPaymentFileLineAmountAndWHTAmount(TextLine, GenJournalLine.Amount, 0);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportSeveralPayments()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        Vendor: array[3] of Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
        FilePath: Text;
    begin
        // [SCENARIO] EFT file can be created for several payments with same balancing bank account
        Initialize;

        // [GIVEN] Create and post 3 invoices for 3 vendors with names VEND1, VEND2 and VEND3
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        FindWHTPostingSetup(WHTPostingSetup);
        for i := 1 to 3 do begin
            CreateVendor(Vendor[i], WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            CreateAndPostPurchaseOrder(Vendor[i]."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, true);
        end;

        // [GIVEN] Run suggest payment with EFT Payment = Yes
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, StrSubstNo('%1..%2', Vendor[1]."No.", Vendor[3]."No."), true);

        // [WHEN] EFT File is being created
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Lines for all vendors exist in the file
        for i := 1 to 3 do
            Assert.IsTrue(
              LibraryTextFileValidation.FindLineWithValue(FilePath, 31, 32, Vendor[i].Name) > '', ValueMustExistMsg);
    end;

    [Test]
    [HandlerFunctions('CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentsWithBalancingJournalLine()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        Vendor: array[3] of Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        InvoiceNo: array[3] of Code[20];
        PaymentNo: Code[20];
        i: Integer;
        FilePath: Text;
        TotalAmount: Decimal;
    begin
        // [SCENARIO] EFT file can be created for payments with balancing journal line
        Initialize;

        // create 3 payment lines for different vendors without bal. account
        // create balancing line

        // [GIVEN] Create and post 3 invoices for 3 vendors
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        FindWHTPostingSetup(WHTPostingSetup);
        for i := 1 to 3 do begin
            CreateVendor(Vendor[i], WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            InvoiceNo[i] :=
              CreateAndPostPurchaseOrder(Vendor[i]."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, true);
        end;

        // [GIVEN] Create payment lines applied to invoices without balance account
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        PaymentNo := CopyStr(Format(CreateGuid), 1, MaxStrLen(GenJournalLine."Document No."));
        for i := 1 to 3 do
            TotalAmount +=
              CreatePaymentJournalLineAppliedToInvoice(GenJournalBatch, Vendor[i], PaymentNo, InvoiceNo[i]);

        // [GIVEN] Create balancing bank account journal line
        CreateBalancingJournalLine(GenJournalBatch, PaymentNo, TotalAmount);

        // [WHEN] EFT File is being created
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Lines for all vendors exist in the file
        for i := 1 to 3 do
            Assert.IsTrue(
              LibraryTextFileValidation.FindLineWithValue(FilePath, 31, 32, Vendor[i].Name) > '', ValueMustExistMsg);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteExportedJournalLine()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        EFTRegister: Record "EFT Register";
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Exported payment journal line cannot be deleted
        Initialize;

        // [GIVEN] Create and post invoice for vendor VEND
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Create payment journal line to bank BANK applied to posted invoice
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);

        // [GIVEN] Run EFT export for created payment
        EFTPaymentCreateFile(GenJournalLine);
        FindEFTRegister(EFTRegister, GenJournalBatch."Bal. Account No.");

        // [WHEN] Exported payment journal line is being deleted
        GenJournalLine.SetRange("EFT Register No.", EFTRegister."No.");
        GenJournalLine.FindFirst;
        asserterror GenJournalLine.Delete(true);

        // [THEN] Expected error "You cannot delete line..."
        Assert.ExpectedError(
          StrSubstNo(
            CancelExportRequiredErr,
            GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name",
            GenJournalLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CancelExport()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] User can cancel export for exported journal line
        Initialize;

        // [GIVEN] Create and post invoice for vendor VEND
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Create payment journal line to bank BANK applied to posted invoice
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);

        // [GIVEN] Run EFT export for created payment
        EFTPaymentCreateFile(GenJournalLine);

        // [WHEN] Action Cancel Export is being run for exported journal line
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);
        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.CancelExport.Invoke;

        // [THEN] Exported journal line "EFT Register No." = 0
        GenJournalLine.Find;
        GenJournalLine.TestField("EFT Register No.", 0);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ExportCanceledEFTRegister()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        EFTRegister: Record "EFT Register";
        EFTManagement: Codeunit "EFT Management";
        EFTRegisterPage: TestPage "EFT Register";
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Trying the export canceled EFT register leads to error
        Initialize;

        // [GIVEN] Create and post invoice for vendor VEND
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Create payment journal line to bank BANK applied to posted invoice
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);

        // [GIVEN] Run EFT export for created payment
        EFTPaymentCreateFile(GenJournalLine);

        // [GIVEN] Cancel Export
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);
        EFTRegister.Get(GenJournalLine."EFT Register No.");
        EFTManagement.CancelExport(EFTRegister);

        // [WHEN] Try to export from canceled register
        FindEFTRegister(EFTRegister, GenJournalBatch."Bal. Account No.");
        EFTRegisterPage.OpenView;
        EFTRegisterPage.GotoRecord(EFTRegister);
        asserterror EFTRegisterPage.CreateFile.Invoke;

        // [THEN] Expected error "Canceled must not be Yes..."
        Assert.ExpectedError('Canceled must be equal to ''No''');
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WHTAmountForExportedSummarizedPayment()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        TotalInvoiceAmount: Decimal;
        TotalWHTAmount: Decimal;
        FilePath: Text;
        TextLine: Text;
    begin
        // [SCENARO] WHT Amount calculated and exported correctly for summarized payment
        // scenario with WHT amount calculation for summarized payment
        Initialize;

        // [GIVEN] 3 posted invoices with total amount 100 and total WHT amount 45
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreateVendor(Vendor, '', VATPostingSetup."VAT Bus. Posting Group");
        CreateAndPostMultiplePurchaseOrdersForVendor(
          Vendor."No.", TotalInvoiceAmount, TotalWHTAmount);

        // [GIVEN] Suggest payment for posted invoices
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", true);

        // [WHEN] EFT file is being created
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] EFT file payment line has amount to pay 55 and WHT amount 45
        TextLine := LibraryTextFileValidation.ReadLine(FilePath, 2);
        VerifyPaymentFileLineAmountAndWHTAmount(TextLine, TotalInvoiceAmount, TotalWHTAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportNotPostedSummarizedPaymentFromEFTRegister()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        EFTRegister: Record "EFT Register";
        i: Integer;
        FilePath: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Not posted summarized payment  can be exported to EFT file from EFT register
        Initialize;

        // [GIVEN] Post 3 invoices for vendor VEND
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to 3 do
            CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, true);

        // [GIVEN] Run suggest payment with EFT Payment = Yes, Summarize per Vendor = Yes
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", true);
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);

        // [GIVEN] Export payment
        EFTPaymentCreateFile(GenJournalLine);
        FindEFTRegister(EFTRegister, GenJournalBatch."Bal. Account No.");

        // [WHEN] File is being exported from EFT register
        FilePath := EFTPaymentCreateFileFromEFTRegister(EFTRegister);

        // [THEN] EFT file contains line with payment Document No.
        VerifyDocumentNoEFTFile(FilePath, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPostedSummarizedPaymentFromEFTRegister()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        EFTRegister: Record "EFT Register";
        i: Integer;
        FilePath: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Posted summarized payment can be exported to EFT file from EFT register
        Initialize;

        // [GIVEN] Post 3 invoices for vendor VEND
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to 3 do
            CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, true);

        // [GIVEN] Run suggest payment with EFT Payment = Yes, Summarize per Vendor = Yes
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", true);
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);

        // [GIVEN] Export payment
        EFTPaymentCreateFile(GenJournalLine);
        FindEFTRegister(EFTRegister, GenJournalBatch."Bal. Account No.");

        // [GIVEN] Post payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] File is being exported from EFT register
        FilePath := EFTPaymentCreateFileFromEFTRegister(EFTRegister);

        // [THEN] EFT file contains line with payment Document No.
        VerifyDocumentNoEFTFile(FilePath, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTRegisterIsNotCreatedIfNoPaymentsFound()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [EFT Payment] [UT]
        // [SCENARIO] EFT
        Initialize;

        // [GIVEN] Prepare empty payment journal batch
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;

        // [WHEN] EFT payment export is being run
        asserterror EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Expected error "There is nothing to export"
        Assert.ExpectedError(NothingToExportErr);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportAlreadyExportedJournalLine()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO] Export already exported journal line leads to error
        Initialize;

        // [GIVEN] Create and post invoice for vendor VEND
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Create payment journal line to bank BANK applied to posted invoice
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);

        // [GIVEN] Run EFT export for created payment
        EFTPaymentCreateFile(GenJournalLine);

        // [WHEN] Run EFT export for already exported payment
        asserterror EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Expected error
        Assert.ExpectedError(
          StrSubstNo(
            PaymentAlreadyExportedErr,
            GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name",
            GenJournalLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTFileDocumentNoWrittenAppliedToDocInvoice()
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO 286433] "Document No." is filled in EFT File Created for suggested Vendor Payment
        Initialize;

        // [GIVEN] Create and post Invoice for a created Vendor
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Bank Account "BA01" created and set up for EFT
        // [GIVEN] Create payment journal line to bank "BA01" applied to posted invoice
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);

        // [WHEN] Run EFT export for the created Payment
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] "Document No." is not blank in generated EFT File and is the same as in the Payment Journal Line
        VerifyDocumentNoEFTFile(FilePath, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTFileDocumentNoWrittenAppliedToId()
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO 286433] "Document No." is filled in EFT File Created with Payment applied to ID
        Initialize;

        // [GIVEN] Create and post Invoice for a created Vendor
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Bank Account "BA01" created and set up for EFT
        // [GIVEN] Create payment journal line to bank "BA01" with "Applies-To ID" set
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", true);
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);

        // [WHEN] Run EFT export for the created Payment
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] "Document No." is not blank in generated EFT File and is the same as in the Payment Journal Line
        VerifyDocumentNoEFTFile(FilePath, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTFileDocumentNoWrittenPaymentJournalLine()
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        FilePath: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO 286433] "Document No." is filled in EFT File Created for Payment Journal Line
        Initialize;

        // [GIVEN] Payment journal line without applying to invoice
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreateVendor(Vendor, '', VATPostingSetup."VAT Bus. Posting Group");
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        CreatePaymentJournalLine(GenJournalBatch, GenJournalLine, Vendor);
        UpdateGenJournalLineSkipWHT(GenJournalLine, true);

        // [WHEN] Run EFT export for the created Payment
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] "Document No." is not blank in generated EFT File and is the same as in the Payment Journal Line
        VerifyDocumentNoEFTFile(FilePath, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTFileBalancingRecordLineCount()
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO 286434] Record Count in File Totals Record of EFT File includes Balancing Record
        Initialize;

        // [GIVEN] Create and post Invoice for a created Vendor
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Bank Account "BA01" created and set up for EFT
        // [GIVEN] "EFT Balancing Record Required" = TRUE on Bank Account "BA01"
        // [GIVEN] Create payment journal line to bank "BA01" applied to posted invoice
        CreateGenJournalBatchWithBankAccountEFTBalancingRecordRequired(GenJournalBatch, true);
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, Vendor."No.", false);
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);

        // [WHEN] Run EFT export for the created Payment
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] Record count on File Totals line of the EFT File includes Balancing Record
        VerifyRecordCount(FilePath, 2);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithEFTPaymentCheckingVendorBank()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendBankAcc: Record "Vendor Bank Account";
        DocumentNo: array[4] of Code[20];
        VendorFilter: Text;
    begin
        // [SCENARIO 286435] Payment Journal Line after running SuggestVendorPayments with EFT Payment as True.

        // [GIVEN] Posted Purchase Orders for two vendors with "EFT Bank Account No." having
        // [GIVEN] Customer/Vendor Bank, Bank Branch No., Bank Account No. filled in.
        Initialize;
        CreateMultipleWHTPostingSetup(WHTPostingSetup);
        CreateGenJournalBatch(GenJournalBatch, CreateBankAccount(true, LibraryRandom.RandDate(5)));
        VendorFilter :=
          CreateAndPostMultiplePurchaseOrder(
            DocumentNo, WHTPostingSetup."WHT Business Posting Group", WHTPostingSetup."WHT Product Posting Group",
            VATPostingSetup."VAT Bus. Posting Group");

        // [WHEN] Suggest Vendor Payments for the vendors
        SuggestVendorPayments(GenJournalLine, GenJournalBatch, VendorFilter, false);

        // [THEN] Customer/Vendor Bank, Bank Branch No., Bank Account No. in suggested payments are taken from the vendors respectively.
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet;
        repeat
            GenJournalLine.TestField("Customer/Vendor Bank");
            VendBankAcc.Get(GenJournalLine."Account No.", GenJournalLine."Customer/Vendor Bank");
            Assert.AreEqual(GenJournalLine."Bank Branch No.", VendBankAcc."Bank Branch No.", 'Bank Branch No.');
            Assert.AreEqual(GenJournalLine."Bank Account No.", VendBankAcc."Bank Account No.", 'Bank Account No.');
        until GenJournalLine.Next = 0;
    end;

    [Test]
    [HandlerFunctions('CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTFileAmountTransferredFromCustomPaymentLineWithAppliedDoc()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        FilePath: Text;
        AmountTxt: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO 314855] EFT file Amount is transferred from Gen. Journal Line not applied documents
        Initialize;

        // [GIVEN] Create and post invoice for vendor
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, true);

        // [GIVEN] Create payment line applied to invoice without balance account
        CreateGenJournalBatchWithBankAccount(GenJournalBatch);
        PaymentNo := CopyStr(Format(CreateGuid), 1, MaxStrLen(GenJournalLine."Document No."));

        // [GIVEN] Gen. Journal Line is created with custom amount
        CreateCustomAmountPaymentJournalLineAppliedToInvoice(
          GenJournalBatch, Vendor, PaymentNo, InvoiceNo, LibraryRandom.RandDecInRange(1, 1000, 2));

        // [GIVEN] Create balancing bank account journal line
        CreateBalancingJournalLine(GenJournalBatch, PaymentNo, LibraryRandom.RandDecInRange(1, 1000, 2));

        // [WHEN] EFT File is being created
        FindFirstGenJournalLineFromBatch(GenJournalBatch, GenJournalLine);
        FilePath := EFTPaymentCreateFile(GenJournalLine);

        // [THEN] EFT file Amount is transferred from Gen. Journal Line
        AmountTxt := ConvertWHTPrepaidAmountInText(GenJournalLine.Amount);
        Assert.IsTrue(
          LibraryTextFileValidation.FindLineWithValue(
            FilePath, 31 - StrLen(AmountTxt), StrLen(AmountTxt), AmountTxt) > '', ValueMustExistMsg);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,CreateEFTFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTFileExportedFromEFTRegisterContainsPostedAmount()
    var
        Vendor: Record "Vendor";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        EFTRegister: Record "EFT Register";
        GenJnlLineAmount: Decimal;
        FilePath: Text;
        TextLine: Text;
    begin
        // [FEATURE] [EFT Payment]
        // [SCENARIO 327808] EFT file exported from EFT Register contains posted amount
        Initialize();

        // [GIVEN] Create and post invoice for vendor
        CreateAndPostPurchaseOrderForNewVendor(Vendor);

        // [GIVEN] Create payment journal line to bank BANK applied to posted invoice with Amount = X
        CreateGenJournalBatchWithBankAccount(GenJnlBatch);
        SuggestVendorPayments(GenJnlLine,GenJnlBatch,Vendor."No.",false);
        FindFirstGenJournalLineFromBatch(GenJnlBatch,GenJnlLine);
        GenJnlLineAmount := GenJnlLine.Amount;

        // [GIVEN] Run EFT export for created payment
        EFTPaymentCreateFile(GenJnlLine);
        FindEFTRegister(EFTRegister,GenJnlBatch."Bal. Account No.");

        // [GIVEN] Exported payment journal line is being posted
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [WHEN] File is being exported from EFT register
        FilePath := EFTPaymentCreateFileFromEFTRegister(EFTRegister);
        TextLine := LibraryTextFileValidation.ReadLine(FilePath,2);

        // [THEN] Exported file contains line with Amount = X
        VerifyPaymentFileLineAmountAndWHTAmount(TextLine,GenJnlLineAmount,0);
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;
        Clear(LibraryTextFileValidation);
        GenJournalLine.DeleteAll();

        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(ERMElectronicBanking);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
    end;

    local procedure CalculateWHTAmount(WHTBusinessPostingGroupCode: Code[20]; WHTProductPostingGroupCode: Code[20]; Amount: Decimal): Decimal
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        WHTPostingSetup.Get(WHTBusinessPostingGroupCode, WHTProductPostingGroupCode);
        exit(Amount * WHTPostingSetup."WHT %" / 100);
    end;

    local procedure CalculateInvoiceAndWHTAmount(VendorNo: Code[20]; InvoiceNo: Code[20]; var InvoiceAmount: Decimal; var WHTAmount: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        WHTEntry: Record "WHT Entry";
    begin
        PurchInvHeader.Get(InvoiceNo);
        PurchInvHeader.CalcFields(Amount);
        InvoiceAmount := PurchInvHeader.Amount;

        with WHTEntry do begin
            SetRange("Bill-to/Pay-to No.", VendorNo);
            SetRange("Document No.", InvoiceNo);
            FindFirst;
            WHTAmount := "Unrealized Amount";
        end;
    end;

    local procedure ConvertWHTPrepaidAmountInText(TotalRemWHTPrepaidAmount: Decimal): Text
    var
        TotalRemWHTPrepaidAmountTxt: Text;
    begin
        // Convert Decimal value into text and remove special char.
        TotalRemWHTPrepaidAmountTxt := Format(Round(TotalRemWHTPrepaidAmount) * 100);
        exit(DelChr(TotalRemWHTPrepaidAmountTxt, '=', DelChr(TotalRemWHTPrepaidAmountTxt, '=', '0123456789')));
    end;

    local procedure CreateAndPostPurchaseOrder(VendorNo: Code[20]; Type: Option; No: Code[20]; PricesIncludingVAT: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Posting Date", CalcDate('<-' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'D>', WorkDate));
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(10));  // Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(100, 1000, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostMultiplePurchaseOrder(var DocumentNo: array[4] of Code[20]; WHTBusinessPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Text
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
    begin
        CreateVendor(Vendor, WHTBusinessPostingGroup, VATBusPostingGroup);
        CreateVendor(Vendor2, '', VATBusPostingGroup);  // WHT Business Posting Group - Blank.
        LibraryInventory.CreateItem(Item);
        CreateGLAccount(GLAccount, WHTProductPostingGroup);
        CreateGLAccount(GLAccount2, '');  // WHT Product Posting Group - Blank.
        DocumentNo[1] := CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, Item."No.", false);  // Prices Including VAT - FALSE.
        DocumentNo[2] := CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::"G/L Account", GLAccount."No.", false);
        DocumentNo[3] := CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::"G/L Account", GLAccount2."No.", false);
        DocumentNo[4] := CreateAndPostPurchaseOrder(Vendor2."No.", PurchaseLine.Type::"G/L Account", GLAccount2."No.", false);
        exit(StrSubstNo('%1|%2', Vendor."No.", Vendor2."No."));
    end;

    local procedure CreateAndPostMultiplePurchaseOrdersForVendor(VendorNo: Code[20]; var TotalAmount: Decimal; var TotalWHTAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        InvoiceNo: Code[20];
        i: Integer;
        InvoiceAmount: Decimal;
        WHTAmount: Decimal;
    begin
        CreateGLAccount(GLAccount, '');
        for i := 1 to 3 do begin
            InvoiceNo := CreateAndPostPurchaseOrder(VendorNo, PurchaseLine.Type::"G/L Account", GLAccount."No.", false);
            CalculateInvoiceAndWHTAmount(VendorNo, InvoiceNo, InvoiceAmount, WHTAmount);
            TotalAmount += InvoiceAmount;
            TotalWHTAmount += WHTAmount;
        end;
    end;

    local procedure CreateAndPostPurchaseOrderForNewVendor(var Vendor: Record Vendor)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateVendor(Vendor, WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CreateAndPostPurchaseOrder(Vendor."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, true);
    end;

    local procedure CreateBalancingJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; DocumentNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"Bank Account", GenJournalBatch."Bal. Account No.",
          GenJournalLine."Bal. Account Type"::"Bank Account", '', -Amount);
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine.Validate("EFT Payment", true);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateBankAccount(EFTPayment: Boolean; DueDate: Date): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID);
        BankAccount.Validate("EFT Bank Code", LibraryUtility.GenerateGUID);
        BankAccount.Validate("EFT BSB No.", LibraryUtility.GenerateGUID);
        BankAccount.Validate("EFT Security No.", LibraryUtility.GenerateGUID);
        BankAccount.Modify(true);

        // Required inside SuggestVendorPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(EFTPayment);
        LibraryVariableStorage.Enqueue(DueDate);
        exit(BankAccount."No.");
    end;

    local procedure SetBankAccountEFTBalancingRecordRequired(BankAccountNo: Code[20]; EFTBalancingRecordRequired: Boolean)
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.Validate("EFT Balancing Record Required", EFTBalancingRecordRequired);
        BankAccount.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; WHTProductPostingGroup: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryPaymentExport.SelectPaymentJournalTemplate);
        with GenJournalBatch do begin
            "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := BalAccountNo;
            Modify;
        end;
    end;

    local procedure CreateGenJournalBatchWithBankAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        BankAccountNo: Code[20];
    begin
        BankAccountNo :=
          CreateBankAccount(true, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', WorkDate));  // EFT Payment -TRUE, Last Payment Date before WORKDATE.
        CreateGenJournalBatch(GenJournalBatch, BankAccountNo);
    end;

    local procedure CreateGenJournalBatchWithBankAccountEFTBalancingRecordRequired(var GenJournalBatch: Record "Gen. Journal Batch"; EFTBalancingRecordRequired: Boolean)
    var
        BankAccountNo: Code[20];
    begin
        BankAccountNo :=
          CreateBankAccount(true, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', WorkDate));  // EFT Payment -TRUE, Last Payment Date before WORKDATE.
        SetBankAccountEFTBalancingRecordRequired(BankAccountNo, EFTBalancingRecordRequired);
        CreateGenJournalBatch(GenJournalBatch, BankAccountNo);
    end;

    local procedure CreateMultipleWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup")
    var
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
    begin
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        FindWHTPostingSetup(WHTPostingSetup);
        CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, '', 0);  // WHTProductPostingGroup - blank, WHT Minimum Invoice Amount - 0.
        CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code, 0);  // WHT%, WHT Minimum Invoice Amount - 0.
    end;

    local procedure CreatePaymentJournalLineAppliedToInvoice(GenJournalBatch: Record "Gen. Journal Batch"; Vendor: Record Vendor; DocumentNo: Code[20]; InvoiceNo: Code[20]): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(InvoiceNo);
        PurchInvHeader.CalcFields(Amount);
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"Bank Account", '', 0);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("EFT Bank Account No.", Vendor."EFT Bank Account No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Validate(Amount, PurchInvHeader.Amount);
        GenJournalLine.Validate("EFT Payment", true);
        GenJournalLine.Modify(true);
        exit(GenJournalLine.Amount);
    end;

    local procedure CreateCustomAmountPaymentJournalLineAppliedToInvoice(GenJournalBatch: Record "Gen. Journal Batch"; Vendor: Record Vendor; DocumentNo: Code[20]; InvoiceNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"Bank Account", '', 0);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("EFT Bank Account No.", Vendor."EFT Bank Account No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Validate(Amount, LineAmount);
        GenJournalLine.Validate("EFT Payment", true);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor)
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"Bank Account", GenJournalBatch."Bal. Account No.",
          LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate(
          "Document No.",
          LibraryUtility.GenerateRandomCode20(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("EFT Bank Account No.", Vendor."EFT Bank Account No.");
        GenJournalLine.Validate("EFT Payment", true);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; WHTBusinessPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(ABN, '');
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("WHT Business Posting Group", WHTBusinessPostingGroup);
        Vendor.Validate("EFT Payment", true);
        Vendor.Validate("EFT Bank Account No.", CreateVendorBankAccount(Vendor."No."));
        Vendor.Name := CopyStr(Format(CreateGuid), 1, 32); // Vendor name has 32 symbols in the file
        Vendor.Modify(true);
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID);
        VendorBankAccount.Validate("EFT BSB No.", LibraryUtility.GenerateGUID);
        VendorBankAccount.Modify(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup"; WHTBusinessPostingGroupCode: Code[20]; WHTProductPostingGroupCode: Code[20]; WHTMinimumInvoiceAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroupCode, WHTProductPostingGroupCode);
        WHTPostingSetup.Validate("WHT %", WHTMinimumInvoiceAmount);
        WHTPostingSetup.Validate("WHT Minimum Invoice Amount", WHTMinimumInvoiceAmount);
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Payment);
        WHTPostingSetup.Validate("Prepaid WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Payable WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Purch. WHT Adj. Account No.", GLAccount."No.");
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithZeroVATPct(VATBusPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CalculateAmountWithoutWHTOnMultipleGenJournalLine(VendorNo: Code[20]): Text
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        FindGenJournalLine(GenJournalLine, VendorNo);
        Amount := GenJournalLine.Amount;
        GenJournalLine.SetFilter("Applies-to Doc. No.", '<>%1', GenJournalLine."Applies-to Doc. No.");
        FindGenJournalLine(GenJournalLine, VendorNo);
        Amount := Amount + GenJournalLine.Amount;
        Amount := Amount - CalculateWHTAmount('', '', Amount);  // WHT Business Posting Group,WHT Product Posting Group - Blank.
        exit(ConvertWHTPrepaidAmountInText(Amount));
    end;

    local procedure EFTPaymentCreateFile(var GenJournalLine: Record "Gen. Journal Line"): Text
    var
        RepCreateEFTFile: Report "Create EFT File";
    begin
        Commit();
        RepCreateEFTFile.SetGenJnlLine(GenJournalLine);
        RepCreateEFTFile.RunModal;
        exit(RepCreateEFTFile.GetServerFileName);
    end;

    local procedure EFTPaymentCreateFileFromEFTRegister(EFTRegister: Record "EFT Register"): Text
    var
        BankAccount: Record "Bank Account";
        EFTManagement: Codeunit "EFT Management";
    begin
        Commit();
        BankAccount.Get(EFTRegister."Bank Account Code");
        EFTManagement.CreateFileFromEFTRegister(EFTRegister, EFTRegister."File Description", BankAccount);
        exit(EFTManagement.GetServerFileName);
    end;

    local procedure FindPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; DocumentNo: Code[20])
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields(Amount, "Rem. WHT Prepaid Amount (LCY)", "Paid WHT Prepaid Amount (LCY)");
    end;

    local procedure FindEFTRegister(var EFTRegister: Record "EFT Register"; BankAccountNo: Code[20])
    begin
        EFTRegister.SetRange("Bank Account Code", BankAccountNo);
        EFTRegister.FindFirst;
    end;

    local procedure FindWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup")
    begin
        // Enable test cases in NZ, create WHT Posting Setup.
        if not WHTPostingSetup.Get('', '') then
            CreateWHTPostingSetup(WHTPostingSetup, '', '', LibraryRandom.RandDecInRange(50, 80, 2));  // WHT Product Posting Group, WHT Business Posting Group - blank,WHT Minimum Invoice Amount.
    end;

    local procedure FindGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst;
    end;

    local procedure FindFirstGenJournalLineFromBatch(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst;
    end;

    local procedure FindPaymentVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst;
    end;

    local procedure SuggestVendorPayments(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; VendorNoFilter: Text; SummarizePerVendor: Boolean)
    var
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        LibraryVariableStorage.Enqueue(VendorNoFilter);
        LibraryVariableStorage.Enqueue(SummarizePerVendor);
        GenJnlLine.Init();
        GenJnlLine.Validate("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", GenJnlBatch.Name);
        SuggestVendorPayments.SetGenJnlLine(GenJnlLine);

        Commit();
        SuggestVendorPayments.RunModal;
    end;

    local procedure UpdateGLSetupAndPurchasesPayablesSetup(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // Enable GST (Australia),Enable WHT and GST Report as True.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(UpdateGSTProdPostingGroupOnPurchasesSetup(CreateVATPostingSetupWithZeroVATPct(VATPostingSetup."VAT Bus. Posting Group")));
    end;

    local procedure UpdateGSTProdPostingGroupOnPurchasesSetup(GSTProdPostingGroup: Code[20]) OldGSTProdPostingGroup: Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldGSTProdPostingGroup := PurchasesPayablesSetup."GST Prod. Posting Group";
        PurchasesPayablesSetup.Validate("GST Prod. Posting Group", GSTProdPostingGroup);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateLocalFunctionalitiesOnGeneralLedgerSetup(EnableGST: Boolean; EnableWHT: Boolean; GSTReport: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGST);
        GeneralLedgerSetup.Validate("Enable WHT", EnableWHT);
        GeneralLedgerSetup.Validate("GST Report", GSTReport);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup: Record "General Ledger Setup"; OldGSTProdPostingGroup: Code[20])
    begin
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Enable WHT", GeneralLedgerSetup."GST Report");
        UpdateGSTProdPostingGroupOnPurchasesSetup(OldGSTProdPostingGroup);
    end;

    local procedure UpdateGLSetupPaymentToleranceWarning(PaymentToleranceWarning: Boolean; MaxPaymentToleranceAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", PaymentToleranceWarning);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", MaxPaymentToleranceAmount);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGenJournalLineAmount(AccountNo: Code[20]; Amount: Decimal): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGenJournalLine(GenJournalLine, AccountNo);
        GenJournalLine.Validate(Amount, GenJournalLine.Amount - Amount);  // Partial Amount.
        GenJournalLine.Modify(true);
        exit(GenJournalLine.Amount);
    end;

    local procedure UpdateGenJournalLineSkipWHT(var GenJournalLine: Record "Gen. Journal Line"; SkipWHT: Boolean)
    begin
        GenJournalLine.Validate("Skip WHT", SkipWHT);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyRemWHTPrepaidAmountOnPurchInvHeader(DocumentNo: Code[20]; WHTProductPostingGroupCode: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        RemWHTPrepaidAmountLCY: Decimal;
    begin
        FindPurchInvHeader(PurchInvHeader, DocumentNo);
        RemWHTPrepaidAmountLCY :=
          CalculateWHTAmount(PurchInvHeader."WHT Business Posting Group", WHTProductPostingGroupCode, PurchInvHeader.Amount);
        PurchInvHeader.TestField("Paid WHT Prepaid Amount (LCY)", 0);  // Before posting of Payment journal it should be zero.
        Assert.AreNearlyEqual(
          PurchInvHeader."Rem. WHT Prepaid Amount (LCY)", RemWHTPrepaidAmountLCY, LibraryERM.GetAmountRoundingPrecision,
          ValueMustBeSameMsg);
    end;

    local procedure VerifyWHTAmountAndGenJournalLine(DocumentNo: Code[20]; WHTProductPostingGroupCode: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Verify Remaining WHT Prepaid Amount on Purchase Invoice Header.
        VerifyRemWHTPrepaidAmountOnPurchInvHeader(DocumentNo, WHTProductPostingGroupCode);

        // Verify new created General Journal Line after running Suggest Vendor Payment.
        FindPurchInvHeader(PurchInvHeader, DocumentNo);
        with GenJournalLine do begin
            SetRange("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
            SetRange("Applies-to Doc. No.", DocumentNo);
            FindFirst;
            TestField("Account No.", PurchInvHeader."Buy-from Vendor No.");
            Assert.AreEqual(
              PurchInvHeader."Vendor Invoice No.", "External Document No.", FieldCaption("External Document No."));
            Assert.AreNearlyEqual(PurchInvHeader.Amount, Amount, LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
        end;
    end;

    local procedure VerifyFileLineLength(FilePath: Text; LineNo: Integer)
    var
        LineTxt: Text;
    begin
        LineTxt := LibraryTextFileValidation.ReadLine(FilePath, LineNo);
        Assert.AreEqual(120, StrLen(LineTxt), StrSubstNo('Invalid file line %1 lenght', LineNo));
    end;

    local procedure VerifyPaymentFileLineAmountAndWHTAmount(TextLine: Text; ExpectedTotalAmount: Decimal; ExpectedWHTAmount: Decimal)
    var
        AmountAsText: Text;
        WHTAmountAsText: Text;
        Amount: Decimal;
        WHTAmount: Decimal;
    begin
        AmountAsText := CopyStr(TextLine, 21, 10);
        WHTAmountAsText := CopyStr(TextLine, 113, 8);
        Evaluate(Amount, AmountAsText);
        Evaluate(WHTAmount, WHTAmountAsText);
        Amount := Amount / 100;
        WHTAmount := WHTAmount / 100;
        Assert.AreEqual(ExpectedTotalAmount - ExpectedWHTAmount, Amount, 'Invalid Amount value');
        Assert.AreEqual(ExpectedWHTAmount, WHTAmount, 'Invalid WHT Amount value');
    end;

    local procedure VerifyDocumentNoEFTFile(FilePath: Text; DocumentNo: Code[20])
    var
        LodgementReference: Text[18];
    begin
        LodgementReference := PadStr(DocumentNo, MaxStrLen(LodgementReference));
        Assert.AreEqual(
          LodgementReference,
          CopyStr(
            LibraryTextFileValidation.FindLineWithValue(
              FilePath,
              63,
              MaxStrLen(LodgementReference),
              LodgementReference),
            63,
            MaxStrLen(LodgementReference)),
          ValueMustBeSameMsg);
    end;

    local procedure VerifyRecordCount(FilePath: Text; ExpectedCount: Integer)
    var
        RecordCount: Integer;
        RecordCountText: Text[6];
    begin
        RecordCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FilePath, '1', 1, 1);
        Assert.AreEqual(ExpectedCount, RecordCount, ValueMustBeSameMsg);
        RecordCountText := Format(RecordCount);
        RecordCountText := PadStr('', MaxStrLen(RecordCountText) - StrLen(RecordCountText), '0') + RecordCountText;
        Assert.AreEqual(
          RecordCountText,
          CopyStr(
            LibraryTextFileValidation.FindLineWithValue(FilePath, 1, 8, '7999-999'),
            75,
            MaxStrLen(RecordCountText)),
          ValueMustBeSameMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateEFTFileRequestPageHandler(var CreateEFTFile: TestRequestPage "Create EFT File")
    begin
        CreateEFTFile.EFTFileDescription.SetValue(LibraryRandom.RandInt(5));  // Setting a Random No for File Description.
        CreateEFTFile.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        BankAccountNo: Variant;
        EFTPayment: Variant;
        LastPaymentDate: Variant;
        BalAccountType: Option "G/L Account",,,"Bank Account";
        SummarizePerVendor: Boolean;
        VendorNoFilter: Text;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(EFTPayment);
        LibraryVariableStorage.Dequeue(LastPaymentDate);
        VendorNoFilter := LibraryVariableStorage.DequeueText;
        if VendorNoFilter <> '' then
            SuggestVendorPayments.Vendor.SetFilter("No.", VendorNoFilter);
        SuggestVendorPayments.LastPaymentDate.SetValue(LastPaymentDate);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"Bank Account");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.EFTPayment.SetValue(EFTPayment);
        SummarizePerVendor := LibraryVariableStorage.DequeueBoolean;
        SuggestVendorPayments.SummarizePerVendor.SetValue(SummarizePerVendor);
        SuggestVendorPayments.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningModalPageHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        PaymentToleranceWarning.Posting.SetValue(true);
        PaymentToleranceWarning.Yes.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 11603, 'OnBeforeDownloadFile', '', false, false)]
    [Scope('OnPrem')]
    procedure DisableDownloadFile(var DoNotDownloadFile: Boolean)
    begin
        DoNotDownloadFile := true;
    end;
}

