codeunit 147560 "Same Ext. Doc. No. In FY"
{
    Permissions = TableData "Vendor Ledger Entry" = ri,
                  TableData "Purchases & Payables Setup" = rm;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [External Document No.]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IsInitialized: Boolean;
        PurchInvAlreadyExistErr: Label 'Purchase Invoice %1 already exists for this vendor.', Comment = '%1 = purchase invoice no.';
        PurchInvExistsInRepErr: Label 'Purchase Invoice %1 already exists.', Comment = '%1 = external document no.';

    [Test]
    [Scope('OnPrem')]
    procedure SameExtDocNoInDiffFYFieldOnPurchasesPayablesSetupPage()
    var
        PurchasesPayablesSetup: TestPage "Purchases & Payables Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 295702] A field "Same Ext. Doc. No. in Diff. FY" is visible and editable on "Purchases & Payables Setup" page

        Initialize;
        LibraryApplicationArea.EnableFoundationSetup;

        LibraryLowerPermissions.SetAccountPayables;

        PurchasesPayablesSetup.OpenEdit;
        Assert.IsTrue(PurchasesPayablesSetup."Same Ext. Doc. No. in Diff. FY".Visible, 'A field not visible');
        Assert.IsFalse(PurchasesPayablesSetup."Same Ext. Doc. No. in Diff. FY".Editable, 'A field not editable');

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToPostWithSameExtDocNoInCurrFYOptionDisabled()
    var
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [SCENARIO 295702] It is not possible to post document with same "External Document No." in current Fiscal Year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is disabled

        Initialize;

        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);

        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsCreate;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is disabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(false);

        // [GIVEN] Posted Purchase invoice with "Document Date" = 01.01.2018 and "External Doc. No." = "X"
        VendNo := LibraryPurchase.CreateVendorNo;
        PostPurhInvWithExtDocNo(WorkDate, VendNo, ExtDocNo);

        // [WHEN] Post Purchase Invoice with "Document Date" = 01.02.2018 and "External Doc. No." = "X"
        asserterror PostPurhInvWithExtDocNo(CalcDate('<1M>', WorkDate), VendNo, ExtDocNo);

        // [THEN] Error "Purchase Invoice G001 already exists for this vendor"
        Assert.ExpectedError(StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToPostWithSameExtDocNoInDiffFYOptionDisabled()
    var
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [SCENARIO 295702] It is not possible to post document with same "External Document No." in different Fiscal Year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is disabled

        Initialize;

        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);

        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsCreate;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is disabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(false);

        // [GIVEN] Posted Purchase invoice with "Document Date" = 01.01.2018 and "External Doc. No." = "X"
        VendNo := LibraryPurchase.CreateVendorNo;
        PostPurhInvWithExtDocNo(WorkDate, VendNo, ExtDocNo);

        // [WHEN] Post Purchase Invoice with "Document Date" = 01.01.2019 and "External Doc. No." = "X"
        asserterror PostPurhInvWithExtDocNo(CalcDate('<1Y>', WorkDate), VendNo, ExtDocNo);

        // [THEN] Error "Purchase Invoice G001 already exists for this vendor"
        Assert.ExpectedError(StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToPostWithSameExtDocNoInCurrFYOptionEnabled()
    var
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [SCENARIO 295702] It is not possible to post document with same "External Document No." in current Fiscal Year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is enabled

        Initialize;

        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);

        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsCreate;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is enabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(true);

        // [GIVEN] Posted Purchase invoice with "Document Date" = 01.01.2018 and "External Doc. No." = "X"
        VendNo := LibraryPurchase.CreateVendorNo;
        PostPurhInvWithExtDocNo(WorkDate, VendNo, ExtDocNo);

        // [WHEN] Post Purchase Invoice with "Document Date" = 01.02.2018 and "External Doc. No." = "X"
        asserterror PostPurhInvWithExtDocNo(CalcDate('<1M>', WorkDate), VendNo, ExtDocNo);

        // [THEN] Error "Purchase Invoice G001 already exists for this vendor"
        Assert.ExpectedError(StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWithSameExtDocNoInDiffFYOptionEnabled()
    var
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [SCENARIO 295702] Stan can post document with same "External Document No." in different Fiscal Year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is enabled

        Initialize;

        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);

        LibraryLowerPermissions.SetO365Setup;
        LibraryLowerPermissions.AddPurchDocsCreate;
        LibraryLowerPermissions.AddPurchDocsPost;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is enabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(true);

        // [GIVEN] Posted Purchase invoice with "Document Date" = 01.01.2018 and "External Doc. No." = "X"
        VendNo := LibraryPurchase.CreateVendorNo;
        PostPurhInvWithExtDocNo(WorkDate, VendNo, ExtDocNo);

        // [WHEN] Post Purchase Invoice with "Document Date" = 01.01.2019 and "External Doc. No." = "X"
        PostPurhInvWithExtDocNo(CalcDate('<1Y>', WorkDate), VendNo, ExtDocNo);

        // [THEN] Two vendor ledger entries exists for same vendor with "External Doc. No" = "X"
        VerifyTwoVendLedgEntryWithSameExtDocNo(VendNo, UpperCase(ExtDocNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentDateConsidersBySetFilterForExternalDocNoFunction()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorMgt: Codeunit "Vendor Mgt.";
        VendNo: Code[20];
        ExtDocNo: Text;
        EntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 295702] A document Date of Vendor Ledger Entry considers when calling function SetFilterForExternalDocNoFunction

        Initialize;
        SetSameExtDocNoInDiffFY(true);
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        EntryNo := MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);
        MockVendorLedgerEntry(VendNo, CalcDate('<1Y>', WorkDate), ExtDocNo);
        VendorMgt.SetFilterForExternalDocNo(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, CopyStr(ExtDocNo, 1, 35), VendNo, WorkDate);
        Assert.RecordCount(VendorLedgerEntry, 1);
        VendorLedgerEntry.FindFirst;
        Assert.AreEqual(EntryNo, VendorLedgerEntry."Entry No.", 'Incorrect entry no.');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestFailsWithExternalDocNoInDiffYearOptionDisabled()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "General Journal -Test" report fails if there is duplicated External Document No. in different fiscal year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is disabled

        Initialize;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is disabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(false);

        // [GIVEN] Vendor Ledger Entry with "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);

        // [GIVEN] General Journal Line with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreateGenJnlLineInNextFY(GenJournalLine, VendNo, 1, ExtDocNo);
        Commit;
        GenJournalLine.SetRecFilter;

        // [WHEN] Run "General Journal - Test" report against General Journal Line
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] An error "Purchase Invoice X already exists" prints
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(4);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ErrorTextNumber', StrSubstNo(PurchInvExistsInRepErr, UpperCase(ExtDocNo)));
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestDoesNotFailWithExternalDocNoInDiffYearOptionEnabled()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "General Journal -Test" report runs successfully if there is duplicated External Document No. in different fiscal year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is enabled

        Initialize;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is enabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(true);

        // [GIVEN] Vendor Ledger Entry with "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);

        // [GIVEN] General Journal Line with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreateGenJnlLineInNextFY(GenJournalLine, VendNo, 1, ExtDocNo);
        Commit;
        GenJournalLine.SetRecFilter;

        // [WHEN] Run "General Journal - Test" report against General Journal Line
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] No error "Purchase Invoice X already exists." prints
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueNotExist(
          'ErrorTextNumber', StrSubstNo(PurchInvExistsInRepErr, UpperCase(ExtDocNo)));
    end;

    [Test]
    [HandlerFunctions('VendorPrepaymentJnlRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorPrepaymentJnlFailsWithExternalDocNoInDiffYearOptionDisabled()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Vendor Pre-Payment Journal" report fails if there is duplicated External Document No. in different fiscal year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is disabled

        Initialize;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is disabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(false);

        // [GIVEN] Vendor Ledger Entry with "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);

        // [GIVEN] General Journal Line with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreateGenJnlLineInNextFY(GenJournalLine, VendNo, -1, ExtDocNo);
        Commit;
        GenJournalLine.SetRecFilter;

        // [WHEN] Run "Vendor Pre-Payment Journal" report against General Journal Line
        RunVendorPrepaymentJnl(GenJournalLine);

        // [THEN] An error "Purchase Invoice X already exists" prints
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ErrorText_Number_', StrSubstNo(PurchInvExistsInRepErr, UpperCase(ExtDocNo)));
    end;

    [Test]
    [HandlerFunctions('VendorPrepaymentJnlRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorPrepaymentJnlDoesNotFailWithExternalDocNoInDiffYearOptionEnabled()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Vendor Pre-Payment Journal" report runs successfully if there is duplicated External Document No. in different fiscal year

        Initialize;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is enabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(true);

        // [GIVEN] Vendor Ledger Entry with "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);

        // [GIVEN] General Journal Line with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreateGenJnlLineInNextFY(GenJournalLine, VendNo, -1, ExtDocNo);
        Commit;
        GenJournalLine.SetRecFilter;

        // [WHEN] Run "Vendor Pre-Payment Journal" report against General Journal Line
        RunVendorPrepaymentJnl(GenJournalLine);

        // [THEN] No error "Purchase Invoice X already exists." prints
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueNotExist(
          'ErrorText_Number_', StrSubstNo(PurchInvExistsInRepErr, UpperCase(ExtDocNo)));
    end;

    [Test]
    [HandlerFunctions('PurchDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchDocumentTestFailsWithExternalDocNoInDiffYearOptionDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Purchase Document - Test" report fails if there is duplicated External Document No. in different fiscal year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is disabled

        Initialize;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is disabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(false);

        // [GIVEN] Vendor Ledger Entry with "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);

        // [GIVEN] Purchase Invoice with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreatePurchDocInNextFY(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo, ExtDocNo, 0);
        Commit;
        PurchaseHeader.SetRecFilter;

        // [WHEN] Run "Purchase Document - Test" report against Purchase Invoice
        REPORT.Run(REPORT::"Purchase Document - Test", true, false, PurchaseHeader);

        // [THEN] An error "Purchase Invoice X already exists" prints
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ErrorText_Number_', StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('PurchDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchDocumentTestDoesNotFailWithExternalDocNoInDiffYearOptionEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Purchase Document - Test" report runs successfully if there is duplicated External Document No. in different fiscal year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is enabled

        Initialize;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is enabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(true);

        // [GIVEN] Vendor Ledger Entry with "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);

        // [GIVEN] Purchase Invoice with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreatePurchDocInNextFY(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo, ExtDocNo, 0);
        Commit;
        PurchaseHeader.SetRecFilter;

        // [WHEN] Run "Purchase Document - Test" report against Purchase Invoice
        REPORT.Run(REPORT::"Purchase Document - Test", true, false, PurchaseHeader);

        // [THEN] No error "Purchase Invoice X already exists." prints
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueNotExist(
          'ErrorText_Number_', StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));
    end;

    [Test]
    [HandlerFunctions('PurchDocumentPrepmtTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchDocumentPrepmtTestFailsWithExternalDocNoInDiffYearOptionDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Purchase Prepmt. Doc. - Test" report fails if there is duplicated External Document No. in different fiscal year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is disabled

        Initialize;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is disabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(false);

        // [GIVEN] Vendor Ledger Entry with "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);

        // [GIVEN] Purchase Prepayment Order with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreatePurchDocInNextFY(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendNo, ExtDocNo, LibraryRandom.RandDec(50, 2));
        Commit;
        PurchaseHeader.SetRecFilter;

        // [WHEN] Run "Purchase Prepmt. Doc. - Test" report against Purchase Invoice
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test", true, false, PurchaseHeader);

        // [THEN] An error "Purchase Invoice X already exists" prints
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ErrorText_Number_', StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('PurchDocumentPrepmtTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchDocumentPrepmtDoesNotFailWithExternalDocNoInDiffYearOptionEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Purchase Prepmt. Doc. - Test" report runs successfully if there is duplicated External Document No. in different fiscal year
        // [SCENARIO 295702] when option "Same Ext. Doc. No. in Diff. FY" is enabled

        Initialize;

        // [GIVEN] An option "Same Ext. Doc. No. in Diff. FY" is enabled in "Purchases & Payables Setup"
        SetSameExtDocNoInDiffFY(true);

        // [GIVEN] Vendor Ledger Entry with "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo;
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength);
        MockVendorLedgerEntry(VendNo, WorkDate, ExtDocNo);

        // [GIVEN] Purchase Prepayment Order with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreatePurchDocInNextFY(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendNo, ExtDocNo, LibraryRandom.RandDec(50, 2));
        Commit;
        PurchaseHeader.SetRecFilter;

        // [WHEN] Run "Purchase Prepmt. Doc. - Test" report against Purchase Invoice
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test", true, false, PurchaseHeader);

        // [THEN] No error "Purchase Invoice X already exists." prints
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueNotExist(
          'ErrorText_Number_', StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Same Ext. Doc. No. In FY");
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Same Ext. Doc. No. In FY");
        BindSubscription(LibraryJobQueue);
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        IsInitialized := true;
        Commit;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Same Ext. Doc. No. In FY");
    end;

    local procedure SetSameExtDocNoInDiffFY(NewValue: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Same Ext. Doc. No. in Diff. FY", NewValue);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure PostPurhInvWithExtDocNo(DocumentDate: Date; VendorNo: Code[20]; ExtDocNo: Text): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Validate("Vendor Invoice No.", CopyStr(ExtDocNo, 1, MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure GetExtDocNoLength(): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(MaxStrLen(VendorLedgerEntry."External Document No."));
    end;

    local procedure MockVendorLedgerEntry(VendNo: Code[20]; DocumentDate: Date; ExtDocNo: Text): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init;
        VendorLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document Date" := DocumentDate;
        VendorLedgerEntry."Vendor No." := VendNo;
        VendorLedgerEntry."External Document No." :=
          CopyStr(ExtDocNo, 1, MaxStrLen(VendorLedgerEntry."External Document No."));
        VendorLedgerEntry.Insert;
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure CreateGenJnlLineInNextFY(var GenJournalLine: Record "Gen. Journal Line"; VendNo: Code[20]; Sign: Integer; ExtDocNo: Text)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendNo, Sign * LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", CalcDate('<1Y>', WorkDate));
        GenJournalLine.Validate("External Document No.",
          CopyStr(ExtDocNo, 1, MaxStrLen(GenJournalLine."External Document No.")));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePurchDocInNextFY(var PurchaseHeader: Record "Purchase Header"; DocType: Option; VendNo: Code[20]; ExtDocNo: Text; PrepmtPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        PurchaseHeader.Validate("Posting Date", CalcDate('<1Y>', WorkDate));
        PurchaseHeader.Validate("Vendor Invoice No.",
          CopyStr(ExtDocNo, 1, MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
        PurchaseHeader.Validate("Prepayment %", PrepmtPct);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure RunVendorPrepaymentJnl(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorPrePaymentJournal: Report "Vendor Pre-Payment Journal";
    begin
        GenJournalBatch.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalBatch.SetRange(Name, GenJournalLine."Journal Batch Name");
        VendorPrePaymentJournal.SetTableView(GenJournalBatch);
        VendorPrePaymentJournal.SetTableView(GenJournalLine);
        VendorPrePaymentJournal.Run;
    end;

    local procedure VerifyTwoVendLedgEntryWithSameExtDocNo(VendNo: Code[20]; ExtDocNo: Text[35])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendNo);
        VendorLedgerEntry.SetRange("External Document No.", ExtDocNo);
        Assert.RecordCount(VendorLedgerEntry, 2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTestRequestPageHandler(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    begin
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPrepaymentJnlRequestPageHandler(var VendorPrepaymentJnl: TestRequestPage "Vendor Pre-Payment Journal")
    begin
        VendorPrepaymentJnl.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchDocumentPrepmtTestRequestPageHandler(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    begin
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

