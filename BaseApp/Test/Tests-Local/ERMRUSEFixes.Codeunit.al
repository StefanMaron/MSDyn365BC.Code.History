codeunit 144004 "ERM RU SE Fixes"
{
    TestPermissions = NonRestrictive;
    Permissions = tabledata "G/L Correspondence Entry" = rimd,
                  tabledata "G/L Correspondence" = rimd,
                  tabledata "G/L Entry" = rimd,
                  tabledata "FA Ledger Entry" = rimd,
                  tabledata "Vendor Ledger Entry" = rimd,
                  tabledata "Detailed Vendor Ledg. Entry" = rimd;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
#if not CLEAN22
        LibraryDimension: Codeunit "Library - Dimension";
#endif
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        IsInitialized: Boolean;
        GenJnlLineArchiveErr: Label 'General Journal Line Archive must be exist.';
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        CorrectDateNotFoundErr: Label 'Appropriate date has not been taken into account.';
        WrongDateFoundErr: Label 'Inappropriate date has been taken into account.';
        TotalingTypeErr: Label 'Incosistent Totaling Type option in Acc. Shedule Expession Buffer';

    [Test]
    [Scope('OnPrem')]
    procedure VSE30251_SalesInvAddCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        AddRepCurrencyCode: Code[10];
        OldAddRepCurrencyCode: Code[10];
        CurrencyCode: Code[10];
        CustNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountLCY: Decimal;
        AddCurrAmount: Decimal;
    begin
        // Verify amounts in G/L Register and Customer Ledger Entries in case of using ACY and FCY
        Initialize();
        OldAddRepCurrencyCode := CreateTwoCurrenciesAndUpdateAddRepCurrency(CurrencyCode, AddRepCurrencyCode);

        CustNo := LibrarySales.CreateCustomerNo();
        InvoiceDocNo := CreateAndPostSalesInvoice(Amount, CustNo, CurrencyCode);
        CreateAndApplyPaymentToInvoice(GenJournalLine, GenJournalLine."Account Type"::Customer, CustNo, InvoiceDocNo, CurrencyCode, -Amount);
        AmountLCY := LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate());
        AddCurrAmount := LibraryERM.ConvertCurrency(AmountLCY, '', AddRepCurrencyCode, WorkDate());

        VerifyGLEntryAmount(InvoiceDocNo, GetCustReceivAccNo(CustNo), AmountLCY, AddCurrAmount);
        VerifyClosedCustLedgEntry(CustNo, CustLedgEntry."Document Type"::Invoice, InvoiceDocNo, Amount, AmountLCY);
        VerifyClosedCustLedgEntry(CustNo, CustLedgEntry."Document Type"::Payment, GenJournalLine."Document No.", -Amount, -AmountLCY);

        UpdateAddnlReportingCurrency(OldAddRepCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE30251_PurchInvAddCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AddRepCurrencyCode: Code[10];
        OldAddRepCurrencyCode: Code[10];
        CurrencyCode: Code[10];
        VendNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountLCY: Decimal;
        AddCurrAmount: Decimal;
    begin
        // Verify amounts in G/L Register and Customer Ledger Entries in case of using ACY and FCY
        Initialize();
        OldAddRepCurrencyCode := CreateTwoCurrenciesAndUpdateAddRepCurrency(CurrencyCode, AddRepCurrencyCode);

        VendNo := LibraryPurchase.CreateVendorNo();
        InvoiceDocNo := CreateAndPostPurchInvWithItem(Amount, VendNo, CurrencyCode);
        CreateAndApplyPaymentToInvoice(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendNo, InvoiceDocNo, CurrencyCode, Amount);
        AmountLCY := LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate());
        AddCurrAmount := LibraryERM.ConvertCurrency(AmountLCY, '', AddRepCurrencyCode, WorkDate());

        VerifyGLEntryAmount(InvoiceDocNo, GetVendPayAccNo(VendNo), -AmountLCY, -AddCurrAmount);
        VerifyClosedVendLedgEntry(VendNo, VendLedgEntry."Document Type"::Invoice, InvoiceDocNo, -Amount, -AmountLCY);
        VerifyClosedVendLedgEntry(VendNo, VendLedgEntry."Document Type"::Payment, GenJournalLine."Document No.", Amount, AmountLCY);

        UpdateAddnlReportingCurrency(OldAddRepCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE30294_SalesInvoiceShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShipmentDocNo: array[2] of Code[20];
        InvoiceDocNo: array[2] of Code[20];
        TotalQty: Decimal;
        QtyToShip: array[2] of Decimal;
        QtyToInvoice: array[2] of Decimal;
        i: Integer;
    begin
        // Create Sales Order, make two Shipments, two Invoices, check Qty in Posted Documents
        Initialize();

        VSE30294_InitQuantities(TotalQty, QtyToShip, QtyToInvoice);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), TotalQty);

        for i := 1 to ArrayLen(QtyToShip) do begin
            SalesLine.Find();
            SalesLine.Validate("Qty. to Ship", QtyToShip[i]);
            SalesLine.Modify(true);
            ShipmentDocNo[i] := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        for i := 1 to ArrayLen(QtyToInvoice) do begin
            SalesLine.Find();
            SalesLine.Validate("Qty. to Invoice", QtyToInvoice[i]);
            SalesLine.Modify(true);
            InvoiceDocNo[i] := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        end;

        for i := 1 to ArrayLen(QtyToInvoice) do begin
            VerifyPostedShipmentDocument(ShipmentDocNo[i], SalesHeader."Sell-to Customer No.", QtyToShip[i]);
            VerifyPostedSalesInvoiceDocument(InvoiceDocNo[i], SalesHeader."Sell-to Customer No.", QtyToInvoice[i]);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE30294_PurchInvoiceShipment()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReceiptDocNo: array[2] of Code[20];
        InvoiceDocNo: array[2] of Code[20];
        TotalQty: Decimal;
        QtyToReceive: array[2] of Decimal;
        QtyToInvoice: array[2] of Decimal;
        i: Integer;
    begin
        // Create Purch Order, make two Receipts, two Invoices, check Qty in Posted Documents
        Initialize();

        VSE30294_InitQuantities(TotalQty, QtyToReceive, QtyToInvoice);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(), TotalQty);

        for i := 1 to ArrayLen(QtyToReceive) do begin
            PurchLine.Find();
            PurchLine.Validate("Qty. to Receive", QtyToReceive[i]);
            PurchLine.Modify(true);
            ReceiptDocNo[i] := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        end;

        for i := 1 to ArrayLen(QtyToInvoice) do begin
            PurchLine.Find();
            PurchLine.Validate("Qty. to Invoice", QtyToInvoice[i]);
            PurchLine.Modify(true);
            PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
            InvoiceDocNo[i] := LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);
        end;

        for i := 1 to ArrayLen(QtyToInvoice) do begin
            VerifyPostedReceiptDocument(ReceiptDocNo[i], PurchLine."Buy-from Vendor No.", QtyToReceive[i]);
            VerifyPostedPurchInvoiceDocument(InvoiceDocNo[i], PurchLine."Buy-from Vendor No.", QtyToInvoice[i]);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE32045_SourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        SourceCodeVATCustAdj: Code[10];
        SourceCodeVATVendAdj: Code[10];
    begin
        // Verify assignment of RU Source Code fields in Source Code Setup
        SourceCodeVATCustAdj := CreateNewSourceCode();
        SourceCodeVATVendAdj := CreateNewSourceCode();

        SourceCodeSetup.Get();
        SourceCodeSetup.Validate("VAT for Customer Adjustment", SourceCodeVATCustAdj);
        SourceCodeSetup.Validate("VAT for Vendor Adjustment", SourceCodeVATVendAdj);

        SourceCodeSetup.TestField("VAT for Customer Adjustment", SourceCodeVATCustAdj);
        SourceCodeSetup.TestField("VAT for Vendor Adjustment", SourceCodeVATVendAdj);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure VSE34697_SalesInvStat()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoicePage: TestPage "Sales Invoice";
        SalesInvoiceStatisticsPage: TestPage "Sales Invoice Statistics";
        PostedSalesDocNo: Code[20];
        Qty: Decimal;
        UnitPrice: Decimal;
        LineDiscPct: Decimal;
    begin
        // Verify Sales Statistics is shown correctly in case of low-cost Item
        Initialize();

        // use hard-coded values for rounding test
        Qty := LibraryRandom.RandInt(5);
        UnitPrice := 1 / (1000 * LibraryRandom.RandInt(5)); // get rand in range 0.0002..0.001
        LineDiscPct := LibraryRandom.RandIntInRange(10, 20);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", LineDiscPct);
        SalesLine.Modify(true);

        // Check Sales Invoice Statistics
        SalesInvoicePage.OpenView();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoicePage.Statistics.Invoke();
        // Verify is done in Statistics Page Handler

        // Check Posted Sales Invoice Statistics
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceStatisticsPage.OpenView();
        SalesInvoiceStatisticsPage.FILTER.SetFilter("No.", PostedSalesDocNo);
        SalesInvoiceStatisticsPage."CustAmount + InvDiscAmount".AssertEquals(0); // "Amount" field
    end;

    [Test]
    [HandlerFunctions('SalesShipmentsHandler')]
    [Scope('OnPrem')]
    procedure VSE35747_SalesShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedSalesInvoicePage: TestPage "Posted Sales Invoice";
        CustNo: Code[20];
        PostedSalesDocNo: Code[20];
    begin
        // Verify Posted Sales Shipments is shown correctly
        Initialize();

        CustNo := LibrarySales.CreateCustomerNo();
        LibraryVariableStorage.Enqueue(CustNo);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        PostedSalesInvoicePage.OpenView();
        PostedSalesInvoicePage.FILTER.SetFilter("No.", PostedSalesDocNo);
        PostedSalesInvoicePage.Shipments.Invoke(); // Shipments
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE30260_FADisposalTaxLedger()
    var
        FA: Record "Fixed Asset";
        Vendor: Record Vendor;
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Check FA Disposal is posted after FA WriteOff
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FA);

        CreateAndPostPurchInvWithFA(Vendor."No.", FA."No.");
        CreateAndPostFAReleaseDoc(FA."No.", CalcDate('<10D>', WorkDate()));
        CreateAndPostFAWriteOffDoc(FA."No.", CalcDate('<1M>', WorkDate()));

        FindFALedgerEntry(
          FALedgerEntry, CalcDate('<1M>', WorkDate()), FA."No.",
          FALedgerEntry."FA Posting Type"::"Proceeds on Disposal", GetFADisposalDeprBookCode());
        Assert.AreEqual(0, FALedgerEntry.Quantity, FALedgerEntry.FieldCaption(Quantity));
        Assert.AreEqual(0, FALedgerEntry.Amount, FALedgerEntry.FieldCaption(Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE33744_FAReleaseAct()
    var
        FA: Record "Fixed Asset";
        Vendor: Record Vendor;
        PostedFADocHeader: Record "Posted FA Doc. Header";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Check FA Release Act Document is posted
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FA);

        CreateAndPostPurchInvWithFA(Vendor."No.", FA."No.");
        CreateAndPostFAReleaseDoc(FA."No.", WorkDate());

        FindFALedgerEntry(
          FALedgerEntry, WorkDate(), FA."No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost", GetFAReleaseDeprBookCode());
        PostedFADocHeader.SetRange("Document Type", PostedFADocHeader."Document Type"::Release);
        PostedFADocHeader.FindLast();
        Assert.AreEqual(FALedgerEntry."Document No.", PostedFADocHeader."No.", PostedFADocHeader.FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE35578_FAReclassification()
    var
        FA: Record "Fixed Asset";
        Vendor: Record Vendor;
        PurchInvAmount: Decimal;
        GenJnlAmount: Decimal;
    begin
        // Verify FA Reclass. Entry
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FA);

        PurchInvAmount := CreateAndPostPurchInvWithFA(Vendor."No.", FA."No.");

        GenJnlAmount := CreateAndPostFAAcqCost(FA."No.");

        CreateAndPostFAReleaseDoc(FA."No.", WorkDate());

        VerifyFAReclassificationLedgerEntry(FA."No.", GetFAReleaseDeprBookCode(), PurchInvAmount + GenJnlAmount);
        VerifyFAReclassificationLedgerEntry(FA."No.", GetFATaxDeprBookCode(), PurchInvAmount + GenJnlAmount);
    end;

    [Test]
    [HandlerFunctions('MessagesHandler')]
    [Scope('OnPrem')]
    procedure FAMovement()
    var
        FA: Record "Fixed Asset";
        Vendor: Record Vendor;
        FADocHeader: Record "FA Document Header";
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 362831] FA Movement Act (DeprBook1 -> DeprBook2) doesn't change DeprBook2."Depreciation Starting Date"
        Initialize();
        // [GIVEN] Fixed Asset released to DeprBook2, "Depreciation Starting Date" = D
        PrepareFixedAsset(Vendor, FA);
        CreateFAMovementAct(FADocHeader, Vendor, FA."No.");
        // [WHEN] Post FA Movement Act with "Posting Date" = D + 1
        LibraryFixedAsset.PostFADocument(FADocHeader);
        // [THEN] DeprBook2."Depreciation Starting Date" = D
        VerifyDeprStartingDate(FA."No.", GetFAReleaseDeprBookCode(), CalcDate('<CM+1D>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalLineArchive()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // SETUP
        Initialize();
        CreateGenJnlLine(GenJnlLine);
        // EXERCISE
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        // VERIFY
        VerifyGenJnlLineArchive(GenJnlLine);
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure RunAccountScheduleOverviewWithComparisionFormula()
    var
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        AccountScheduleNames: TestPage "Account Schedule Names";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        GLAccountNo: Code[20];
        ColumnLayoutName: Code[10];
        AccScheduleName: Code[10];
        ComparisionDateFormula: DateFormula;
    begin
        // [FEATURE] [Account Schedule Overview]
        // [SCENARIO 122555] Account Schedule Overview shows G/L Corr. Entry Amount when Comparision Formula defined
        // [GIVEN] Column Layout = 'C' with Comparision Formula = '-1Y'
        Evaluate(ComparisionDateFormula, '<-1Y>');
        ColumnLayoutName := CreateColumnLayoutWithComparisionDateFormula(ComparisionDateFormula);

        // [GIVEN] Account Schedule with Default Column Layout = 'C' and Totaling for G/L Account = 'A'
        GLAccountNo := LibraryUtility.GenerateGUID();
        AccScheduleName := CreateAccScheduleWithDefaultColumnName(ColumnLayoutName, GLAccountNo);

        // [GIVEN] G/L Corr. Entry for G/L Account = 'A' within period for Comparision Formula = '-1Y'
        CreateGLCorrEntry(GLCorrespondenceEntry, CalcDate(ComparisionDateFormula, WorkDate()), GLAccountNo);

        // [WHEN] Open Acc. Schedule Overview Page
        AccountScheduleNames.OpenView();
        AccountScheduleNames.FILTER.SetFilter(Name, AccScheduleName);
        AccScheduleOverview.Trap();
        AccountScheduleNames.Overview.Invoke();

        // [THEN] Amount = 'X' is shown for ColumnLayout = 'C'
        AccScheduleOverview.CurrentColumnName.AssertEquals(ColumnLayoutName);
        AccScheduleOverview.ColumnValues1.AssertEquals(GLCorrespondenceEntry.Amount);
    end;
#endif

    [Test]
    [HandlerFunctions('AccSchedFormulaDrillDownPageHandler')]
    [Scope('OnPrem')]
    procedure DrillDownAccountScheduleWithFormulaTotalingType()
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleLineConst: Record "Acc. Schedule Line";
        AccSchedManagement: Codeunit AccSchedManagement;
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Account Schedule Overview]
        // [SCENARIO 362478] Account Schedule Overview shows Acc. Sched. Formula Drill-Down when "Totaling Type" = "Formula"

        Initialize();
        // [GIVEN] Account Schedule Line "X" with "Totaling Type" = "Constant" and "Totaling" = 100
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        ExpectedAmount := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(ExpectedAmount);
        CreateAccScheduleWithTotalingTypeForDrillDown(
          AccScheduleLineConst, AccScheduleName.Name, AccScheduleLine."Totaling Type"::Constant, Format(ExpectedAmount));
        // [GIVEN] Account Schedule Line "Y" with "Totaling Type" = "Formula" and "Totaling" = "X"
        CreateAccScheduleWithTotalingTypeForDrillDown(
          AccScheduleLine, AccScheduleName.Name, AccScheduleLine."Totaling Type"::Formula, AccScheduleLineConst."Row No.");
        // [GIVEN] Calculated cell buffer for DrillDown with Account Schedule Line "Y" and default Column Layout
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // [WHEN] Run DrillDown with Account Schedule Line "Y" and default Column Layout
        AccSchedManagement.DrillDown(ColumnLayout, AccScheduleLine, PeriodType::Year);

        // [THEN] "Acc. Sched. Formula Drill-Down" page shows and Amount = 100
        // Verification done in AccSchedFormulaDrillDownPageHandler
    end;

    [Test]
    [HandlerFunctions('GLCorrespondenceEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure DrillDownAccountScheduleWithCorrEntriesLedgEntryType()
    var
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        ColumnLayout: Record "Column Layout";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedManagement: Codeunit AccSchedManagement;
    begin
        // [FEATURE] [Account Schedule Overview] [G/L Correspondence Entry]
        // [SCENARIO 362478] Account Schedule Overview shows Acc. Sched. Formula Drill-Down when "Corr. Entries" Ledger Entry Type used and formula defined

        Initialize();
        // [GIVEN] G/L Correspondence Entry with "Debit Account No." = "X" and Amount = 100
        CreateGLCorrEntry(GLCorrespondenceEntry, WorkDate(), LibraryERM.CreateGLAccountNo());

        // [GIVEN] Account Schedule Line "A" with "Totaling Type" = "Total Accounts" and "Totaling" = "X"
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryVariableStorage.Enqueue(GLCorrespondenceEntry.Amount);
        CreateAccScheduleWithTotalingTypeForDrillDown(
          AccScheduleLine, AccScheduleName.Name, AccScheduleLine."Totaling Type"::"Total Accounts",
          GLCorrespondenceEntry."Debit Account No.");

        // [GIVEN] Column Layout "B" with "Ledger Entry Type" = "Corr. Entries"
        CreateColumnLayoutWithCorrEntriesLedgEntryType(ColumnLayout);

        // [GIVEN] Calculated cell buffer for DrillDown with Account Schedule Line "A" and Column Layout "B"
        AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // [WHEN] Run DrillDown with Account Schedule Line "A" and Column Layout "B"
        AccSchedManagement.DrillDown(ColumnLayout, AccScheduleLine, PeriodType::Year);

        // [THEN] "G/L Correspondence Entries" page shows and Amount = 100
        // Verification done in GLCorrespondenceEntriesPageHandler
    end;

    [Test]
    [HandlerFunctions('VendLedgEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure DrillDownAccountScheduleWithCustomVendLedgEntryTotalingType()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedManagement: Codeunit AccSchedManagement;
        AccSchedExtensionCode: Code[20];
    begin
        // [FEATURE] [Account Schedule Overview] [Account Schedule Extension]
        // [SCENARIO 362095] Account Schedule Overview shows "Vend. Ledger Entries" when "Totaling Type" = "Custom" and "Acc. Schedule Ext. Source Table" = "Vend. Ledg. Entry"

        Initialize();
        // [GIVEN] Vendor Ledger Entry with new Vendor Posting Group "X" and Amount = 100
        CreateVendLedgEntryWithNewPostingGroup(VendLedgEntry);
        LibraryVariableStorage.Enqueue(VendLedgEntry.Amount);

        // [GIVEN] Account Schedule Extension "A" with "Source Table" = "Vendor Entry" and "Posting Group" = "X"
        AccSchedExtensionCode := CreateAccSchedExtensionWithVendLedgEntry(VendLedgEntry."Vendor Posting Group");

        // [GIVEN] Account Schedule Line "B" with "Totaling Type" = "Customer" and "Totaling" = "A"
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccScheduleWithTotalingTypeForDrillDown(
          AccScheduleLine, AccScheduleName.Name, AccScheduleLine."Totaling Type"::Custom, AccSchedExtensionCode);

        // [GIVEN] Calculated cell buffer for DrillDown with Account Schedule Line "B" and default Column Layout
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // [WHEN] Run DrillDown with Account Schedule Line "B" and default Column Layout
        AccSchedManagement.DrillDown(ColumnLayout, AccScheduleLine, PeriodType::Year);

        // [THEN] "Vendor Ledger Entries Entries" page shows and Amount = 100
        // Verification done in VendLedgEntriesPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnGLCorrespGLEndBalanceDrillDown()
    var
        GLEntryBeforeReportingDate: Record "G/L Entry";
        GLEntryAfterReportingDate: Record "G/L Entry";
        GLCorresp: TestPage "G/L Corresp. General Ledger";
        GLEntriesList: TestPage "General Ledger Entries";
        ReportingDate: Date;
        EarlierThanReportingDate: Date;
        LaterThanReportingDate: Date;
        GLAccountNo: Code[20];
        WithinReportingPeriodEntryNo: Integer;
        OutOfReportingPeriodEntryNo: Integer;
    begin
        // [FEATURE] [G/L Correspondence]
        // [SCENARIO 362820] Ending balance for G/L Correspondence is calculated up to the closing date of the calculation period:
        // IF 01.01.2017 is the end of the calculation period, there should be no G/L Entries posted after 01.01.2017 23:59:59 and taken into account.

        Initialize();
        // [GIVEN] GL Account "X"
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Reporting Date 01.01.2017
        ReportingDate := LibraryUtility.GenerateRandomDate(20170101D, 20171231D);

        // [GIVEN] GL Entry with GL Account "X" and Posting Date earlier than Reporting Date (C010117D).
        EarlierThanReportingDate := ClosingDate(ReportingDate);
        WithinReportingPeriodEntryNo :=
          CreateGLEntryWithAccountAndPostingDate(
            GLEntryBeforeReportingDate,
            GLAccountNo,
            EarlierThanReportingDate);

        // [GIVEN] GL Entry with GL Account "X" and Posting Date later than Reporting Date (020117D).
        LaterThanReportingDate := ReportingDate + 1;
        OutOfReportingPeriodEntryNo :=
          CreateGLEntryWithAccountAndPostingDate(
            GLEntryAfterReportingDate,
            GLAccountNo,
            LaterThanReportingDate);

        // [GIVEN] GL Corresp. Page filtered by Reporting Date, GL Account No.; Period Type = Day.
        GLCorresp.OpenEdit();
        GLCorresp."Date Filter".SetValue(ReportingDate);
        GLCorresp.PeriodType.SetValue('Day');
        GLCorresp."G/L Account Filter".SetValue(GLAccountNo);

        // [WHEN] DrillDown on Ending Balance for G/L Correspondance line with G/L Account "X"
        GLEntriesList.Trap();
        GLCorresp.EndingBalance.DrillDown();

        // [THEN] G/L Entries List contains G/L Entry posted on C010117D and does not contain G/L Entry posted on 020117D.
        GLEntriesList.First();
        Assert.AreEqual(WithinReportingPeriodEntryNo, GLEntriesList."Entry No.".AsDecimal(), CorrectDateNotFoundErr);
        GLEntriesList.Next();
        Assert.AreNotEqual(OutOfReportingPeriodEntryNo, GLEntriesList."Entry No.".AsDecimal(), WrongDateFoundErr);
        GLEntriesList.Last();
        Assert.AreEqual(WithinReportingPeriodEntryNo, GLEntriesList."Entry No.".AsDecimal(), WrongDateFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalingTypeOptionStringUT()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedExpressionBuffer: Record "Acc. Sched. Expression Buffer";
        "Field": Record "Field";
        i: Integer;
        NumOfOptions: Integer;
    begin
        // [FEATURE] [Account Schedule] [Acc. Sched. Expression Buffer] [UT]
        // [SCENARIO 372302] OptionString of the field "Totaling Type" should be equal in tables 85 Acc. Schedule Line and 26585 Acc. Sched. Expression Buffer
        Field.Get(DATABASE::"Acc. Schedule Line", AccScheduleLine.FieldNo("Totaling Type"));
        NumOfOptions := StrLen(DelChr(Field.OptionString, '=', DelChr(Field.OptionString, '=', ','))) + 1;

        for i := 1 to NumOfOptions do begin
            AccScheduleLine."Totaling Type" := "Acc. Schedule Line Totaling Type".FromInteger(i);
            AccSchedExpressionBuffer."Totaling Type" := AccScheduleLine."Totaling Type";
            Assert.AreEqual(Format(AccScheduleLine."Totaling Type"), Format(AccSchedExpressionBuffer."Totaling Type"), TotalingTypeErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseWithSkipPostingVendor()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376660] Post Purchase Invoice with "Skip Posting" setup
        Initialize();

        // [GIVEN] Vendor "X" with Vendor Posting Group having "Skip Posting" = TRUE;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Vendor Posting Group", CopyVendorPostingGroup(Vendor."Vendor Posting Group", true));
        Vendor.Modify(true);

        // [GIVEN] Purchase Invoice with Vendor "X"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Vendor Ledger Entry is not created
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        Assert.RecordIsEmpty(VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnGLCorrespForceRecalculation()
    var
        GLCorrespGeneralLedger: TestPage "G/L Corresp. General Ledger";
        ReportingDate: Date;
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [G/L Correspondence]
        // [SCENARIO 379024] New record appears in the page G/L Corresp. General Ledger on action "Force Recalculation" when G/L Corr. Entry was created after page opened

        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        ReportingDate := LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate() + 10);

        // [GIVEN] GL Corresp. Page filtered by Reporting Date, GL Account No.; Period Type = Day.
        GLCorrespGeneralLedger.OpenEdit();
        GLCorrespGeneralLedger."Date Filter".SetValue(ReportingDate);
        GLCorrespGeneralLedger.PeriodType.SetValue('Day');
        GLCorrespGeneralLedger."G/L Account Filter".SetValue(GLAccountNo);

        // [GIVEN] New G/L Correspondence entry created after page was opened
        CreateGLCorrespondenceAndGLCorrEntry(GLAccountNo, ReportingDate);

        // [WHEN] Action "Force Recalculation" pushed
        GLCorrespGeneralLedger.ForceRecalculation.Invoke();

        // [THEN] Created entry appeared in the page as expanded line
        GLCorrespGeneralLedger.Expand(true);
        GLCorrespGeneralLedger.FILTER.SetFilter("Debit Account No.", GLAccountNo);
        GLCorrespGeneralLedger."Debit Account No.".AssertEquals(GLAccountNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CountryRegionGetLocalNameReturnsLocalName()
    var
        CountryRegion: Record "Country/Region";
        Result: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 219041] TAB9.GetLocalName function should return correct value of Name up to 50 chars

        // [GIVEN] Country Region with Name = "A..Z" filled with 50 symbols, Local Name = ''
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryUtility.FillFieldMaxText(CountryRegion, CountryRegion.FieldNo(Name));
        CountryRegion.Get(CountryRegion.Code);

        // [WHEN] Run GetLocalName function
        Result := CountryRegion.GetLocalName(CountryRegion.Code);

        // [THEN] Result equals to the value of Name
        Assert.AreEqual(CountryRegion.Name, Result, '');
    end;

    [Test]
    [HandlerFunctions('MessagesHandler')]
    [Scope('OnPrem')]
    procedure CalcFADeprNextPeriodAfterMovement()
    var
        Vendor: Record Vendor;
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        DeprDate: Date;
    begin
        // [FEATURE] [Fixed Asset] [Depreciation]
        // [SCENARIO 257967] Depreciation can be calculated on 31-01-2021 after last Depreciation on 31-12-2020 and FA Movement on 31-01-2021
        Initialize();

        // [GIVEN] Fixed Asset with Depreciation calculated till 31-12-2020
        PrepareFixedAsset(Vendor, FixedAsset);
        CalcDeprTillDate(FixedAsset."No.", CalcDate('<-CM+2M+CM>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [GIVEN] Post FA Movement to a new FA Location on "Posting Date" = 31-01-2021
        DeprDate := CalcDate('<1Y+CM>', WorkDate());
        CreatePostFAMovementToNewLocation(FixedAsset."No.", DeprDate, CreateFALocation());

        // [WHEN] Calculate Dpreciation on 31-01-2021
        LibraryFixedAsset.CalcDepreciation(FixedAsset."No.", GetFAReleaseDeprBookCode(), DeprDate, true, false);

        // [THEN] The Depreciation has been calculated
        FindFALedgerEntry(
          FALedgerEntry, DeprDate, FixedAsset."No.", FALedgerEntry."FA Posting Type"::Depreciation, GetFAReleaseDeprBookCode());
        FALedgerEntry.TestField(Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFirstDeprDateFiltersByReclassFALSE()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
    begin
        // [FEATURE] [Fixed Asset] [Depreciation] [UT]
        // [SCENARIO 257967] COD 5616 "Depreciation Calculation".GetFirstDeprDate() filters Depreciation Entry by "Reclassification Entry" = FALSE
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);

        MockFALedgerEntry(FixedAsset."No.", DepreciationBook.Code, 20191231D, FALedgerEntry."FA Posting Type"::Depreciation, false);
        MockFALedgerEntry(FixedAsset."No.", DepreciationBook.Code, 20200131D, FALedgerEntry."FA Posting Type"::Depreciation, true);

        Assert.AreEqual(20200101D, DepreciationCalculation.GetFirstDeprDate(FixedAsset."No.", DepreciationBook.Code, false), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullApplyPurchInvInCurrencyWithHighExchangeRateToPaymentInLCY()
    var
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        PaymentNo: Code[20];
        InvoiceNo: Code[20];
        PaymentDate: Date;
        InvoiceDate: Date;
    begin
        // [FEATURE] [Purchase] [Apply] [Currency]
        // [SCENARIO 284519] Invoice in foreign currency with very high exchange rate can be fully applied to payment in local currency
        Initialize();

        // [GIVEN] Currency USD has exchange rates 01.01 2435.35, 02.01 2500
        PaymentDate := WorkDate();
        InvoiceDate := WorkDate() + 1;
        CurrencyCode := CreateCurrencyWithSpecificExchangeRate(PaymentDate, InvoiceDate);

        // [GIVEN] Create and post payment 01.01, 600 USD
        VendorNo := LibraryPurchase.CreateVendorNo();
        PaymentNo := CreatePostVendCurrencyPayment(VendorNo, CurrencyCode, PaymentDate, 600);
        // [GIVEN] Create and post invoice 02.01, 15000000 RUB
        InvoiceNo := CreatePostVendLCYInvoice(VendorNo, InvoiceDate, -1500000);

        // [WHEN] Payment is being applied to invoice
        PostApplyPurchPaymentToInvoice(PaymentNo, InvoiceNo);

        // [THEN] Invoice is fully applied
        VerifyPaymentAndInvoiceFullyApplied(PaymentNo, InvoiceNo);
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure CorrDimFilterOnColumnLayoutAppliedToAccountSchedule()
    var
        DimensionValue: Record "Dimension Value";
        ColumnLayout: Record "Column Layout";
        GLCorrespondenceEntry: array[2] of Record "G/L Correspondence Entry";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedManagement: Codeunit AccSchedManagement;
        GLAccountNo: Code[20];
        AccScheduleName: Code[10];
        Amt: Decimal;
    begin
        // [FEATURE] [Account Schedule] [Column Layout] [G/L Correspondence] [Dimension]
        // [SCENARIO 311073] "Dimension 1/2 Corr. Totaling" filter set on column layout with "G/L Correspondence" entry type is applied to account schedule.
        Initialize();

        // [GIVEN] G/L Account "X".
        GLAccountNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Global dimension 2 value "DIM2".
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Column layout, set "Dimension 2 Corr. Totaling" = "DIM2".
        CreateColumnLayoutWithCorrEntriesLedgEntryType(ColumnLayout);
        ColumnLayout.Validate("Dimension 2 Corr. Totaling", DimensionValue.Code);
        ColumnLayout.Modify(true);

        // [GIVEN] Account schedule with one line for g/l account "X" and just created column layout.
        AccScheduleName := CreateAccScheduleWithDefaultColumnName(ColumnLayout."Column Layout Name", GLAccountNo);

        // [GIVEN] Generate two g/l correspondence entries with g/l account "X" -
        // [GIVEN] The first entry has blank "Credit Global Dimension 2 Code", Amount = "A1";
        // [GIVEN] The second entry has "Credit Global Dimension 2 Code" = "DIM2", Amount = "A2".
        CreateGLCorrEntry(GLCorrespondenceEntry[1], WorkDate(), GLAccountNo);
        CreateGLCorrEntry(GLCorrespondenceEntry[2], WorkDate(), GLAccountNo);
        GLCorrespondenceEntry[2].Validate("Credit Global Dimension 2 Code", DimensionValue.Code);
        GLCorrespondenceEntry[2].Modify(true);

        // [WHEN] Calculate the account schedule.
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName);
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.FindFirst();
        Amt := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // [THEN] The value in the only cell in the account schedule = "A2".
        Assert.AreEqual(GLCorrespondenceEntry[2].Amount, Amt, '');
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure DrillDownAccountScheduleCellConsidersCorrDimFilterOnColumnLayout()
    var
        DimensionValue: Record "Dimension Value";
        ColumnLayout: Record "Column Layout";
        GLCorrespondenceEntry: array[2] of Record "G/L Correspondence Entry";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedManagement: Codeunit AccSchedManagement;
        GLCorrespondenceEntries: TestPage "G/L Correspondence Entries";
        GLAccountNo: Code[20];
        AccScheduleName: Code[10];
    begin
        // [FEATURE] [Account Schedule] [Column Layout] [G/L Correspondence] [Dimension]
        // [SCENARIO 311073] Drilling down the cell in the account schedule shows only records that meet "Dimension 1/2 Corr. Totaling" filter set on column layout with "G/L Correspondence" entry type.
        Initialize();

        // [GIVEN] G/L Account "X".
        GLAccountNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Global dimension 2 value "DIM2".
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Column layout, set "Dimension 2 Corr. Totaling" = "DIM2".
        CreateColumnLayoutWithCorrEntriesLedgEntryType(ColumnLayout);
        ColumnLayout.Validate("Dimension 2 Corr. Totaling", DimensionValue.Code);
        ColumnLayout.Modify(true);

        // [GIVEN] Account schedule with one line for g/l account "X" and just created column layout.
        AccScheduleName := CreateAccScheduleWithDefaultColumnName(ColumnLayout."Column Layout Name", GLAccountNo);

        // [GIVEN] Generate two g/l correspondence entries with g/l account "X" -
        // [GIVEN] The first entry has blank "Credit Global Dimension 2 Code".
        // [GIVEN] The second entry has "Credit Global Dimension 2 Code" = "DIM2".
        CreateGLCorrEntry(GLCorrespondenceEntry[1], WorkDate(), GLAccountNo);
        CreateGLCorrEntry(GLCorrespondenceEntry[2], WorkDate(), GLAccountNo);
        GLCorrespondenceEntry[2].Validate("Credit Global Dimension 2 Code", DimensionValue.Code);
        GLCorrespondenceEntry[2].Modify(true);

        // [WHEN] Drill down the only cell in the account schedule.
        GLCorrespondenceEntries.Trap();
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName);
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.FindFirst();
        AccSchedManagement.SetDateParameters(WorkDate(), WorkDate());
        AccSchedManagement.DrillDown(ColumnLayout, AccScheduleLine, PeriodType::Day);

        // [THEN] Only the g/l correspondence entry with "Credit Global Dimension 2 Code" = "DIM2" is shown.
        Assert.IsFalse(GLCorrespondenceEntries.GotoKey(GLCorrespondenceEntry[1]."Entry No."), '');
        Assert.IsTrue(GLCorrespondenceEntries.GotoKey(GLCorrespondenceEntry[2]."Entry No."), '');
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TotalingDimValueCanBeUsedOnCorrDimFilterOnColumnLayout()
    var
        DimensionValue: Record "Dimension Value";
        TotalingDimensionValue: Record "Dimension Value";
        ColumnLayout: Record "Column Layout";
        GLCorrespondenceEntry: array[2] of Record "G/L Correspondence Entry";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedManagement: Codeunit AccSchedManagement;
        GLAccountNo: Code[20];
        AccScheduleName: Code[10];
        Amt: Decimal;
    begin
        // [FEATURE] [Account Schedule] [Column Layout] [G/L Correspondence] [Dimension]
        // [SCENARIO 311073] Dimension value of totaling type can be used in "Dimension 2 Corr. Totaling" filter on column layout in account schedule.
        Initialize();

        // [GIVEN] G/L Account "X".
        GLAccountNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Global dimension 2 value "DIM2".
        // [GIVEN] Totaling global dimension 2 value "DIM2_TOTAL" that includes "DIM2".
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(2));
        LibraryDimension.CreateDimensionValue(TotalingDimensionValue, LibraryERM.GetGlobalDimensionCode(2));
        TotalingDimensionValue.Validate("Dimension Value Type", TotalingDimensionValue."Dimension Value Type"::"End-Total");
        TotalingDimensionValue.Validate(Totaling, DimensionValue.Code);
        TotalingDimensionValue.Modify(true);

        // [GIVEN] Column layout, set "Dimension 2 Corr. Totaling" = "DIM2_TOTAL".
        CreateColumnLayoutWithCorrEntriesLedgEntryType(ColumnLayout);
        ColumnLayout.Validate("Dimension 2 Corr. Totaling", TotalingDimensionValue.Code);
        ColumnLayout.Modify(true);

        // [GIVEN] Account schedule with one line for g/l account "X" and just created column layout.
        AccScheduleName := CreateAccScheduleWithDefaultColumnName(ColumnLayout."Column Layout Name", GLAccountNo);

        // [GIVEN] Generate two g/l correspondence entries with g/l account "X" -
        // [GIVEN] The first entry has blank "Credit Global Dimension 2 Code", Amount = "A1";
        // [GIVEN] The second entry has "Credit Global Dimension 2 Code" = "DIM2", Amount = "A2".
        CreateGLCorrEntry(GLCorrespondenceEntry[1], WorkDate(), GLAccountNo);
        CreateGLCorrEntry(GLCorrespondenceEntry[2], WorkDate(), GLAccountNo);
        GLCorrespondenceEntry[2].Validate("Credit Global Dimension 2 Code", DimensionValue.Code);
        GLCorrespondenceEntry[2].Modify(true);

        // [WHEN] Calculate the account schedule.
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName);
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.FindFirst();
        Amt := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // [THEN] The value in the only cell in the account schedule = "A2".
        Assert.AreEqual(GLCorrespondenceEntry[2].Amount, Amt, '');
    end;
#endif

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
    end;

    local procedure VSE30294_InitQuantities(var TotalQty: Decimal; var QtyToShipReceive: array[2] of Decimal; var QtyToInvoice: array[2] of Decimal)
    begin
        TotalQty := 10 + LibraryRandom.RandInt(10);
        QtyToShipReceive[1] := LibraryRandom.RandIntInRange(1, TotalQty - 1);
        QtyToShipReceive[2] := TotalQty - QtyToShipReceive[1];
        QtyToInvoice[1] := LibraryRandom.RandIntInRange(1, TotalQty - 1);
        QtyToInvoice[2] := TotalQty - QtyToInvoice[1];
    end;

    local procedure CreateGLEntryWithAccountAndPostingDate(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; PostingDate: Date): Integer
    var
        RecRef: RecordRef;
    begin
        with GLEntry do begin
            Init();
            "G/L Account No." := GLAccountNo;
            "Posting Date" := PostingDate;
            RecRef.GetTable(GLEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            Insert();
        end;

        exit(GLEntry."Entry No.");
    end;

    local procedure CreateNewSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        with SourceCode do begin
            Init();
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Source Code");
            Insert();
            exit(Code);
        end;
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        with Currency do begin
            Validate("Residual Gains Account", FindGLAccountNo());
            Validate("Residual Losses Account", "Residual Gains Account");
            Validate("Realized G/L Gains Account", FindGLAccountNo());
            Validate("Realized G/L Losses Account", "Realized G/L Gains Account");
            Modify(true);

            LibraryERM.CreateRandomExchangeRate(Code);
            exit(Code);
        end;
    end;

    local procedure CreateCurrencyWithSpecificExchangeRate(PaymentDate: Date; InvoiceDate: Date): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        with Currency do begin
            Validate("Residual Gains Account", FindGLAccountNo());
            Validate("Residual Losses Account", "Residual Gains Account");
            Validate("Realized G/L Gains Account", FindGLAccountNo());
            Validate("Realized G/L Losses Account", "Realized G/L Gains Account");
            Validate("Realized Gains Acc.", FindGLAccountNo());
            Modify(true);

            CreateExchangeRate(Code, PaymentDate, 2435.35, 2435.35);
            CreateExchangeRate(Code, InvoiceDate, 2500, 2500);
            exit(Code);
        end;
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; RelationalExchRateAmount: Decimal; RelationalAdjmtExchRateAmt: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        with CurrencyExchangeRate do begin
            Init();
            Validate("Currency Code", CurrencyCode);
            Validate("Starting Date", StartingDate);
            Insert(true);

            Validate("Exchange Rate Amount", 1);
            Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
            Validate("Adjustment Exch. Rate Amount", 1);
            Validate("Relational Adjmt Exch Rate Amt", RelationalAdjmtExchRateAmt);
            Modify(true);
        end;
    end;

    local procedure CreateTwoCurrenciesAndUpdateAddRepCurrency(var CurrencyCode: Code[10]; var AddRepCurrencyCode: Code[10]): Code[10]
    begin
        AddRepCurrencyCode := CreateCurrencyAndExchangeRate();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        exit(UpdateAddnlReportingCurrency(AddRepCurrencyCode));
    end;

    local procedure CreateAndPostSalesInvoice(var Amount: Decimal; CustNo: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateFCYSalesInvoiceWithGLAcc(SalesHeader, SalesLine, CustNo, '', WorkDate(), CurrencyCode);
        Amount := SalesLine."Amount Including VAT";
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchInvWithItem(var Amount: Decimal; VendNo: Code[20]; CurrencyCode: Code[10]) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateFCYPurchInvoiceWithGLAcc(PurchaseHeader, PurchLine, VendNo, '', WorkDate(), CurrencyCode);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Amount := PurchLine."Amount Including VAT";
    end;

    local procedure CreateAndPostPurchInvWithFA(VendNo: Code[20]; FANo: Code[20]): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchaseLine, VendNo, FANo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreateAndPostPurchInvWithDeprBook(VendNo: Code[20]; FANo: Code[20]; PostingDate: Date; DeprBookCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchaseLine, VendNo, FANo);
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Depreciation Book Code", DeprBookCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndApplyPaymentToInvoice(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliestoDocNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostFAAcqCost(FANo: Code[20]): Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FANo, -LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("FA Reclassification Entry", true);
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine.Amount);
    end;

    local procedure CreateColumnLayoutWithComparisionDateFormula(ComparisionDateFormula: DateFormula): Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout.Validate("Ledger Entry Type", ColumnLayout."Ledger Entry Type"::"Corr. Entries");
        ColumnLayout.Validate("Amount Type", ColumnLayout."Amount Type"::Amount);
        ColumnLayout.Validate("Comparison Date Formula", ComparisionDateFormula);
        ColumnLayout.Modify(true);
        exit(ColumnLayoutName.Name);
    end;

    local procedure CreateColumnLayoutWithCorrEntriesLedgEntryType(var ColumnLayout: Record "Column Layout")
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout.Validate("Ledger Entry Type", ColumnLayout."Ledger Entry Type"::"Corr. Entries");
        ColumnLayout.Validate("Amount Type", ColumnLayout."Amount Type"::Amount);
        ColumnLayout.Modify(true);
    end;

#if not CLEAN22
    local procedure CreateAccScheduleWithDefaultColumnName(ColumnName: Code[10]; GLAccountNo: Code[20]): Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleName.Validate("Default Column Layout", ColumnName);
        AccScheduleName.Modify(true);

        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Row No.", LibraryUtility.GenerateGUID());
        AccScheduleLine.Validate(Totaling, GLAccountNo);
        AccScheduleLine.Modify(true);

        exit(AccScheduleName.Name);
    end;
#endif

    local procedure CreateAccScheduleWithTotalingTypeForDrillDown(var AccScheduleLine: Record "Acc. Schedule Line"; AccScheduleName: Code[10]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; PassedTotaling: Text[250])
    begin
        with AccScheduleLine do begin
            LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName);
            Validate("Row No.", LibraryUtility.GenerateGUID());
            Validate("Totaling Type", TotalingType);
            Validate(Totaling, PassedTotaling);
            SetFilter("Date Filter", Format(WorkDate()));
            Modify(true);
        end;
    end;

    local procedure CreateGLCorrEntry(var GLCorrespondenceEntry: Record "G/L Correspondence Entry"; PostingDate: Date; DebitGlAccountNo: Code[20])
    var
        RecRef: RecordRef;
    begin
        with GLCorrespondenceEntry do begin
            Init();
            RecRef.GetTable(GLCorrespondenceEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Debit Account No." := DebitGlAccountNo;
            "Posting Date" := PostingDate;
            Amount := LibraryRandom.RandDec(100, 2);
            Insert();
        end;
    end;

    local procedure CreateGLCorrespondenceAndGLCorrEntry(DebitAccountNo: Code[20]; PostingDate: Date)
    var
        GLCorrespondence: Record "G/L Correspondence";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrespondence.Init();
        GLCorrespondence."Debit Account No." := DebitAccountNo;
        GLCorrespondence.Insert();

        CreateGLCorrEntry(GLCorrespondenceEntry, PostingDate, DebitAccountNo);
    end;

    local procedure CreateVendLedgEntryWithNewPostingGroup(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        RecRef: RecordRef;
    begin
        with VendLedgEntry do begin
            Init();
            RecRef.GetTable(VendLedgEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
            "Vendor Posting Group" := VendorPostingGroup.Code;
            Insert();
        end;
        CreateDtldVendLedgEntry(VendLedgEntry."Entry No.", VendLedgEntry."Vendor Posting Group");
        VendLedgEntry.CalcFields(Amount);
    end;

    local procedure CreateDtldVendLedgEntry(VendLedgEntryNo: Integer; VendorPostingGroupCode: Code[20])
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        RecRef: RecordRef;
    begin
        with DtldVendLedgEntry do begin
            Init();
            RecRef.GetTable(DtldVendLedgEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Entry Type" := "Entry Type"::"Initial Entry";
            "Vendor Ledger Entry No." := VendLedgEntryNo;
            "Posting Date" := WorkDate();
            "Vendor Posting Group" := VendorPostingGroupCode;
            Amount := LibraryRandom.RandDec(100, 2);
            Insert();
        end;
    end;

    local procedure CopyVendorPostingGroup(SourceVendorPostingGroupCode: Code[20]; SkipPosting: Boolean): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        with VendorPostingGroup do begin
            Get(SourceVendorPostingGroupCode);
            Validate(
              Code,
              CopyStr(LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Vendor Posting Group"),
                1, LibraryUtility.GetFieldLength(DATABASE::"Vendor Posting Group", FieldNo(Code))));
            Validate("Skip Posting", SkipPosting);
            Insert(true);
            exit(Code);
        end;
    end;

    local procedure CreateAccSchedExtensionWithVendLedgEntry(VendPostingGroupCode: Code[20]): Code[20]
    var
        AccSchedExtension: Record "Acc. Schedule Extension";
    begin
        AccSchedExtension.Init();
        AccSchedExtension.Code :=
          LibraryUtility.GenerateRandomCode(AccSchedExtension.FieldNo(Code), DATABASE::"Acc. Schedule Extension");
        AccSchedExtension."Source Table" := AccSchedExtension."Source Table"::"Vendor Entry";
        AccSchedExtension."Posting Group Filter" := VendPostingGroupCode;
        AccSchedExtension.Insert();
        exit(AccSchedExtension.Code);
    end;

    local procedure CreateFAMovementAct(var FADocHeader: Record "FA Document Header"; Vendor: Record Vendor; FANo: Code[20])
    var
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        ModernDeprBookCode: Code[10];
        PostingDate: Date;
    begin
        LibraryFixedAsset.CreateDepreciationBook(DeprBook);
        DeprBook.Validate("G/L Integration - Acq. Cost", true);
        DeprBook.Modify(true);
        LibraryFixedAsset.CreateFAJournalSetup(FAJnlSetup, DeprBook.Code, '');
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        FAJnlSetup.Validate("Gen. Jnl. Template Name", GenJnlTemplate.Name);
        FAJnlSetup.Validate("Gen. Jnl. Batch Name", GenJnlBatch.Name);
        FAJnlSetup.Modify(true);
        LibraryFixedAsset.CreateFADepreciationBook(FADeprBook, FANo, DeprBook.Code);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryFixedAsset.UpdateFAPostingGroupGLAccounts(FAPostingGroup, VATPostingSetup);
        FADeprBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADeprBook.Modify(true);
        ModernDeprBookCode := DeprBook.Code;
        PostingDate := CalcDate('<+1M>', WorkDate());
        CreateAndPostPurchInvWithDeprBook(Vendor."No.", FANo, PostingDate, ModernDeprBookCode);
        LibraryFixedAsset.CreateFAMovementDoc(FADocHeader, FANo, PostingDate, ModernDeprBookCode);
    end;

    local procedure CreatePostFAMovementToNewLocation(FANo: Code[20]; PostingDate: Date; NewFALocationCode: Code[10])
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAMovementDoc(FADocumentHeader, FANo, PostingDate, GetFAReleaseDeprBookCode());
        FADocumentHeader.Validate("New FA Location Code", NewFALocationCode);
        FADocumentHeader.Modify(true);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    local procedure CreatePostVendCurrencyPayment(VendorNo: Code[20]; CurrencyCode: Code[10]; PostingDate: Date; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, 0);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostVendLCYInvoice(VendorNo: Code[20]; PostingDate: Date; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateFALocation(): Code[10]
    var
        FALocation: Record "FA Location";
    begin
        with FALocation do begin
            Init();
            Code := LibraryUtility.GenerateGUID();
            Name := Code;
            Insert();
            exit(Code);
        end;
    end;

    local procedure MockFALedgerEntry(FANo: Code[20]; DeprBookCode: Code[10]; FAPostingDate: Date; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; ReclassificationEntry: Boolean)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        with FALedgerEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(FALedgerEntry, FieldNo("Entry No."));
            "FA No." := FANo;
            "Depreciation Book Code" := DeprBookCode;
            "FA Posting Date" := FAPostingDate;
            "FA Posting Type" := FAPostingType;
            "Reclassification Entry" := ReclassificationEntry;
            Insert();
        end;
    end;

    local procedure CalcDeprTillDate(FANo: Code[20]; DeprDate: Date; FinishDate: Date)
    begin
        repeat
            LibraryFixedAsset.CalcDepreciation(FANo, GetFAReleaseDeprBookCode(), DeprDate, true, false);
            DeprDate := CalcDate('<1D+CM>', DeprDate);
        until DeprDate > FinishDate;
    end;

    local procedure FindGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure FindFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FAPostingDate: Date; FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; DeprBookCode: Code[10])
    begin
        with FALedgerEntry do begin
            SetRange("FA Posting Date", FAPostingDate);
            SetRange("FA No.", FANo);
            SetRange("FA Posting Type", FAPostingType);
            SetRange("Depreciation Book Code", DeprBookCode);
            FindLast();
        end;
    end;

    local procedure UpdateAddnlReportingCurrency(AdditionalReportingCurrency: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure GetCustReceivAccNo(CustNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustNo);
        CustPostingGroup.Get(Customer."Gen. Bus. Posting Group");
        exit(CustPostingGroup."Receivables Account");
    end;

    local procedure GetVendPayAccNo(VendNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendNo);
        VendPostingGroup.Get(Vendor."Gen. Bus. Posting Group");
        exit(VendPostingGroup."Payables Account");
    end;

    local procedure GetFADisposalDeprBookCode(): Code[10]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        exit(FASetup."Disposal Depr. Book");
    end;

    local procedure GetFAReleaseDeprBookCode(): Code[10]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        exit(FASetup."Release Depr. Book");
    end;

    local procedure GetFATaxDeprBookCode(): Code[10]
    var
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        TaxRegisterSetup.Get();
        exit(TaxRegisterSetup."Tax Depreciation Book");
    end;

    local procedure PostApplyPurchPaymentToInvoice(PaymentNo: Code[20]; InvoiceNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure PrepareFixedAsset(var Vendor: Record Vendor; var FA: Record "Fixed Asset")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FA);

        CreateAndPostPurchInvWithFA(Vendor."No.", FA."No.");
        CreateAndPostFAReleaseDoc(FA."No.", WorkDate());
        LibraryFixedAsset.CalcDepreciation(
          FA."No.", GetFAReleaseDeprBookCode(), CalcDate('<-CM+2M-1D>', WorkDate()), true, false);
    end;

    local procedure VerifyFAReclassificationLedgerEntry(FANo: Code[20]; DeprBookCode: Code[10]; ExpectedAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FindFALedgerEntry(FALedgerEntry, WorkDate(), FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost", DeprBookCode);
        Assert.AreEqual(ExpectedAmount, FALedgerEntry.Amount, FALedgerEntry.FieldCaption(Amount));
        Assert.IsTrue(FALedgerEntry."Reclassification Entry", FALedgerEntry.FieldCaption("Reclassification Entry"));
    end;

    local procedure VerifyGLEntryAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedAddCurrAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("G/L Account No.", GLAccountNo);
            FindFirst();
            Assert.AreEqual(ExpectedAmount, Amount, FieldCaption(Amount));
            Assert.AreEqual(ExpectedAddCurrAmount, "Additional-Currency Amount", FieldCaption("Additional-Currency Amount"));
        end;
    end;

    local procedure VerifyClosedCustLedgEntry(CustNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgEntry do begin
            SetRange("Customer No.", CustNo);
            SetRange("Document No.", DocumentNo);
            SetRange("Document Type", DocumentType);
            FindFirst();
            CalcFields(Amount, "Amount (LCY)");
            Assert.AreEqual(ExpectedAmount, Amount, FieldCaption(Amount));
            Assert.AreEqual(ExpectedAmountLCY, "Amount (LCY)", FieldCaption("Amount (LCY)"));
            Assert.IsFalse(Open, FieldCaption(Open));
        end;
    end;

    local procedure VerifyClosedVendLedgEntry(VendNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            SetRange("Vendor No.", VendNo);
            SetRange("Document No.", DocumentNo);
            SetRange("Document Type", DocumentType);
            FindFirst();
            CalcFields(Amount, "Amount (LCY)");
            Assert.AreEqual(ExpectedAmount, Amount, FieldCaption(Amount));
            Assert.AreEqual(ExpectedAmountLCY, "Amount (LCY)", FieldCaption("Amount (LCY)"));
            Assert.IsFalse(Open, FieldCaption(Open));
        end;
    end;

    local procedure VerifyPostedShipmentDocument(DocumentNo: Code[20]; CustNo: Code[20]; ExpectedQty: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        with SalesShipmentLine do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Sell-to Customer No.", CustNo);
            FindFirst();
            Assert.AreEqual(ExpectedQty, Quantity, FieldCaption(Quantity));
        end;
    end;

    local procedure VerifyPostedSalesInvoiceDocument(DocumentNo: Code[20]; CustNo: Code[20]; ExpectedQty: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        with SalesInvoiceLine do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Sell-to Customer No.", CustNo);
            FindFirst();
            Assert.AreEqual(ExpectedQty, Quantity, FieldCaption(Quantity));
        end;
    end;

    local procedure VerifyPostedReceiptDocument(DocumentNo: Code[20]; VendNo: Code[20]; ExpectedQty: Decimal)
    var
        PurchReceiptLine: Record "Purch. Rcpt. Line";
    begin
        with PurchReceiptLine do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Buy-from Vendor No.", VendNo);
            FindFirst();
            Assert.AreEqual(ExpectedQty, Quantity, FieldCaption(Quantity));
        end;
    end;

    local procedure VerifyPostedPurchInvoiceDocument(DocumentNo: Code[20]; VendNo: Code[20]; ExpectedQty: Decimal)
    var
        PurchInvoiceLine: Record "Purch. Inv. Line";
    begin
        with PurchInvoiceLine do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Buy-from Vendor No.", VendNo);
            FindFirst();
            Assert.AreEqual(ExpectedQty, Quantity, FieldCaption(Quantity));
        end;
    end;

    local procedure VerifyDeprStartingDate(FANo: Code[20]; DeprBookCode: Code[10]; DeprStartingDate: Date)
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook.Get(FANo, DeprBookCode);
        Assert.AreEqual(
          DeprStartingDate, FADeprBook."Depreciation Starting Date",
          FADeprBook.FieldCaption("Depreciation Starting Date"));
    end;

    local procedure VerifyPaymentAndInvoiceFullyApplied(PaymentNo: Code[20]; InvoiceNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.TestField(Open, false);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VendorLedgerEntry2.TestField(Open, false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        SalesStatistics.Amount.AssertEquals(0);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentsHandler(var SalesShipments: TestPage "Posted Sales Shipments")
    var
        CustNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustNo);
        SalesShipments."Sell-to Customer No.".AssertEquals(CustNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccSchedFormulaDrillDownPageHandler(var AccSchedFormulaDrillDown: TestPage "Acc. Sched. Formula Drill-Down")
    var
        ExpectedAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAmount);
        AccSchedFormulaDrillDown.Amount.AssertEquals(ExpectedAmount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLCorrespondenceEntriesPageHandler(var GLCorrespondenceEntries: TestPage "G/L Correspondence Entries")
    var
        ExpectedAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAmount);
        GLCorrespondenceEntries.Amount.AssertEquals(ExpectedAmount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendLedgEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    var
        ExpectedAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAmount);
        VendorLedgerEntries.Amount.AssertEquals(ExpectedAmount);
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalTemplateName: Code[10];
        GenJournalBatchName: Code[10];
    begin
        CreateGenJournalBatchWithBalAccount(GenJournalTemplateName, GenJournalBatchName);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine, GenJournalTemplateName, GenJournalBatchName,
          GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure VerifyGenJnlLineArchive(GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLineArchive: Record "Gen. Journal Line Archive";
    begin
        with GenJnlLineArchive do begin
            SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
            SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
            SetRange("Account No.", GenJnlLine."Account No.");
            SetRange("Bal. Account No.", GenJnlLine."Bal. Account No.");
            Assert.IsFalse(IsEmpty, GenJnlLineArchiveErr);
        end;
    end;

    local procedure CreateGenJournalBatchWithBalAccount(var GenJournalTemplateName: Code[10]; var GenJournalBatchName: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Archive, true);
        GenJournalTemplate.Modify();
        GenJournalTemplateName := GenJournalTemplate.Name;
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify();
        GenJournalBatchName := GenJournalBatch.Name;
    end;

    local procedure CreateAndPostFAReleaseDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    local procedure CreateAndPostFAWriteOffDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAWriteOffDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessagesHandler(Message: Text)
    begin
    end;
}

