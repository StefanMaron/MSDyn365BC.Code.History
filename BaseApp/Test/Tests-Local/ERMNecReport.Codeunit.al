#if not CLEAN25
codeunit 142087 "ERM Nec Report"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        IRS1099CodeNec01Lbl: Label 'NEC-01';
        IRS1099CodeNec04Lbl: Label 'NEC-04';
        SuggestedVendorPaymentLinesCreatedMsg: Label 'You have created suggested vendor payment lines for all currencies.';

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,Vendor1099NecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Vendor1099NecReportHasNec01Amount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 374401] A "Vendor 1099 NEC" report has NEC-01 amount

        // [GIVEN] Purchase invoice with NEC-01 code
        Initialize();
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, IRS1099CodeNec01Lbl);
        PostGenJournalLineAfterSuggestVendorPaymentMsg(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Run Vendor 1099 NEC Report
        REPORT.Run(REPORT::"Vendor 1099 Nec");

        // [THEN] "NEC-01" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GetAmtNEC01', PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,Vendor1099NecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Vendor1099NecReportHasNec04Amount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 374401] A "Vendor 1099 NEC" report has NEC-04 amount

        // [GIVEN] Purchase invoice with NEC-04 code
        Initialize();
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, IRS1099CodeNec04Lbl);
        PostGenJournalLineAfterSuggestVendorPaymentMsg(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Run Vendor 1099 NEC Report
        REPORT.Run(REPORT::"Vendor 1099 Nec");

        // [THEN] "NEC-04" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GetAmtNEC04', PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,Vendor1099NecChangeCurrYearRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeYearInNecReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OldWorkDate: Date;
    begin
        // [SCENARIO 389400] Stan can change the year on the NEC report's request page to see the actual data

        // [GIVEN] Purchase invoice with NEC-01 code with Date = 01.01.2021
        Initialize();
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, IRS1099CodeNec01Lbl);
        PostGenJournalLineAfterSuggestVendorPaymentMsg(PurchaseHeader."Buy-from Vendor No.");

        // [GIVEN] Work date is "01.01.2022"
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [WHEN] Run Vendor 1099 NEC Report and set year = 2021
        LibraryVariableStorage.Enqueue(Date2DMY(OldWorkDate, 3));
        REPORT.Run(REPORT::"Vendor 1099 Nec");

        // [THEN] "NEC-01" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GetAmtNEC01', PurchaseLine."Line Amount");
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        Workdate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('Vendor1099NecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnlyPositiveValuesGeneratedInMISC2020Report()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VendNo: Code[20];
    begin
        // [SCENARIO 399767] Only positive values are generated in the NEC report

        Initialize();

        // [GIVEN] Vendor "X"
        VendNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase invoice with "MISC-01" code and amount = 100
        CreateAndPostPurchDocWithVendorAndIRS1099Code(
          PurchaseHeader, PurchaseLine[1], PurchaseHeader."Document Type"::Order, VendNo, IRS1099CodeNec01Lbl);

        // [GIVEN] Purchase credit memo with "MISC-04" code and amount = 50
        CreateAndPostPurchDocWithVendorAndIRS1099Code(
          PurchaseHeader, PurchaseLine[2], PurchaseHeader."Document Type"::"Credit Memo", VendNo, IRS1099CodeNec04Lbl);
        LibraryVariableStorage.Enqueue(VendNo);

        // [WHEN] Run Vendor 1099 NEC Report
        REPORT.Run(REPORT::"Vendor 1099 Nec");

        LibraryReportDataset.LoadDataSetFile();
        // [THEN] "MISC-01" has value of 100
        LibraryReportDataset.AssertElementWithValueNotExist('GetAmtNEC01', PurchaseLine[1]."Line Amount");
        // [THEN] "MISC-50" has value of 50
        LibraryReportDataset.AssertElementWithValueNotExist('GetAmtNEC04', PurchaseLine[2]."Line Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099NecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustmentAmountOfPerviousFisalYearShouldNotBeShown()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VendNo: Code[20];
        WorkDates: array[2] of Date;
        Amount: array[2] of Decimal;
    begin
        // [SCENARIO 504572]  The 1099-NEC (or other) Report will not include a 1099 Forms Box Adjustment from a prior year when the Vendor also has a 1099 Invoice posted at the end of the prior year but paid in the current year.
        Initialize();

        // [GIVEN] Create a Vendor and Assign to Variable.
        VendNo := LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Calculate Work Date making it two different years.
        WorkDates[1] := CalcDate('<+1Y>', WorkDate());
        WorkDates[2] := CalcDate('<-1Y>', WorkDate());

        // [GIVEN] Get Two Amount into Variables.
        Amount[1] := LibraryRandom.RandIntInRange(5000, 10000);
        Amount[2] := LibraryRandom.RandIntInRange(10001, 15000);

        // [GIVEN] Create VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Create Gen. Product Posting Group.
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);

        // [GIVEN] Create GL Account and validate VAT Product Posting Group and Gen. Product Posting Group.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount.Modify(true);

        // [GIVEN] VAT Posting Setup of VAT Bus. Posting Group from Vendor and Vat Prod. Posting Group is made.
        VATPostingSetup.Rename(Vendor."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create a Purchase Order and Validate IRS 1099 Code ad Posting Date.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendNo);
        PurchaseHeader.Validate("IRS 1099 Code", IRS1099CodeNec01Lbl);
        PurchaseHeader.Validate("Posting Date", WorkDates[2]);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a Purchase Line with GL Account and Validate Amount
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", Amount[1]);
        PurchaseLine.Modify(true);

        // [GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create a Journal With Payment and With Vendor.
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor,
            VendNo,
            0);

        // [GIVEN] Validate Posting Date, Balancing Account Type, Balancing Account No. and Amount.
        GenJournalLine.Validate("Posting Date", WorkDates[1]);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJournalLine.Validate(Amount, Amount[2]);
        GenJournalLine.Modify(true);

        // [GIVEN] Post the General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Insert Value into IRS1099 Adjustment.
        IRS1099Adjustment.Init();
        IRS1099Adjustment.Validate("Vendor No.", VendNo);
        IRS1099Adjustment.Validate("IRS 1099 Code", IRS1099CodeNec01Lbl);
        IRS1099Adjustment.Validate(Year, Date2DMY(WorkDates[2], 3));
        IRS1099Adjustment.Validate(Amount, Amount[2]);
        IRS1099Adjustment.Insert(true);

        // [GIVEN] Store Vendor No. into LibraryVariableStorage.
        LibraryVariableStorage.Enqueue(VendNo);
        Commit();

        // [GIVEN] Run Vendor 1099 NEC Report
        REPORT.Run(REPORT::"Vendor 1099 Nec");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Amount from previous year should not be included.
        LibraryReportDataset.AssertElementWithValueNotExist('GetAmtNEC01', Amount[1]);
    end;


    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Clear(LibraryReportDataset);
        LibraryVariableStorage.Clear();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; IRS1099Code: Code[10])
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithNECCode(IRS1099Code));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("VAT %", 0);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchDocWithVendorAndIRS1099Code(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendNo: Code[20]; IRS1099Code: Code[10])
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        PurchaseHeader.Validate("IRS 1099 Code", IRS1099Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("VAT %", 0);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostGenJournalLineAfterSuggestVendorPaymentMsg(VendorNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(WorkDate());
        SuggestVendorPaymentUsingPageMsg(GenJournalLine);
        FindAndPostGenJourLineAfterSuggestVendorPayment(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
    end;

    local procedure SuggestVendorPaymentUsingPageMsg(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        Commit();
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();
    end;

    local procedure FindAndPostGenJourLineAfterSuggestVendorPayment(GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVendorWithNECCode(IRS1099Code: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("IRS 1099 Code", IRS1099Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(SuggestedVendorPaymentLinesCreatedMsg, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        BankAccount: Record "Bank Account";
        No: Variant;
        LastPaymentDate: Variant;
        BalAccountType: Option "G/L Account",Customer,Vendor,"Bank Account";
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(LastPaymentDate);
        LibraryERM.FindBankAccount(BankAccount);
        SuggestVendorPayments.LastPaymentDate.SetValue(LastPaymentDate);
        SuggestVendorPayments.FindPaymentDiscounts.SetValue(true);
        SuggestVendorPayments.PostingDate.SetValue(SuggestVendorPayments.LastPaymentDate.Value);
        SuggestVendorPayments.NewDocNoPerLine.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"Bank Account");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccount."No.");
        SuggestVendorPayments.Vendor.SetFilter("No.", No);
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099NecRequestPageHandler(var Vendor1099Nec: TestRequestPage "Vendor 1099 Nec")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Vendor1099Nec.Vendor.SetFilter("No.", No);
        Vendor1099Nec.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099NecChangeCurrYearRequestPageHandler(var Vendor1099Nec: TestRequestPage "Vendor 1099 Nec")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Vendor1099Nec.Vendor.SetFilter("No.", No);
        Vendor1099Nec.Year.SetValue(LibraryVariableStorage.DequeueText());
        Vendor1099Nec.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
#endif
