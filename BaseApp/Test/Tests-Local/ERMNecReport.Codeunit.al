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
