codeunit 134334 "ERM Vendor Statistics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Vendor] [Statistics] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        OverDueBalanceErr: Label 'Vendor OverDue Balance is not correct';
        FieldIsNotHiddenErr: Label 'Field is hidden';

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BalanceLCY: Decimal;
        OutstandingOrdersLCY: Decimal;
        AmtRcdNotInvoicedLCY: Decimal;
        TotalAmountLCY: Decimal;
        BalanceDueLCY: Decimal;
    begin
        // [SCENARIO] Create Purchase Order and Verify Vendor Statistics before Release and Post.
        Initialize();

        // [WHEN] Create Purchase Header and Line.
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine);
        BalanceLCY := 0;  // Value is important here.
        OutstandingOrdersLCY := PurchaseLine."Outstanding Amount (LCY)";
        AmtRcdNotInvoicedLCY := 0;
        TotalAmountLCY := PurchaseLine."Outstanding Amount (LCY)";
        BalanceDueLCY := 0;

        // [THEN] Check Balance (LCY), Outstanding Orders (LCY), TotalAmountLCY, BalanceLCY, BalanceDueLCY on Vendor Statistics page.
        VerifyVendorStatistics(
          PurchaseHeader."Buy-from Vendor No.", BalanceLCY, OutstandingOrdersLCY, AmtRcdNotInvoicedLCY, TotalAmountLCY, BalanceDueLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatisticsAfterRelease()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BalanceLCY: Decimal;
        OutstandingOrdersLCY: Decimal;
        AmtRcdNotInvoicedLCY: Decimal;
        TotalAmountLCY: Decimal;
        BalanceDueLCY: Decimal;
    begin
        // [SCENARIO] Create Purchase Order and Verify Vendor Statistics after Release.
        Initialize();

        // [GIVEN] Create Purchase Header and Line.
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine);

        // [WHEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        BalanceLCY := 0;   // Value is important here.
        OutstandingOrdersLCY := PurchaseLine."Outstanding Amount (LCY)";
        AmtRcdNotInvoicedLCY := 0;
        TotalAmountLCY := PurchaseLine."Outstanding Amount (LCY)";
        BalanceDueLCY := 0;

        // [THEN] Check Balance (LCY), Outstanding Orders (LCY), TotalAmountLCY, BalanceLCY, BalanceDueLCY on Vendor Statistics page.
        VerifyVendorStatistics(
          PurchaseHeader."Buy-from Vendor No.", BalanceLCY, OutstandingOrdersLCY, AmtRcdNotInvoicedLCY, TotalAmountLCY, BalanceDueLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatisticsAfterReceive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BalanceLCY: Decimal;
        OutstandingOrdersLCY: Decimal;
        AmtRcdNotInvoicedLCY: Decimal;
        TotalAmountLCY: Decimal;
        BalanceDueLCY: Decimal;
    begin
        // [SCENARIO] Create Purchase Order and Verify Vendor Statistics after only Receive.
        Initialize();

        // [GIVEN] Create Purchase Header and Line.
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Receive Purchase Order as Receive.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        BalanceLCY := 0;   // Value is important here.
        OutstandingOrdersLCY := 0;
        AmtRcdNotInvoicedLCY := PurchaseLine."Outstanding Amount (LCY)";
        TotalAmountLCY := PurchaseLine."Outstanding Amount (LCY)";
        BalanceDueLCY := 0;

        // [THEN] Check Balance (LCY), Outstanding Orders (LCY), TotalAmountLCY, BalanceLCY, BalanceDueLCY on Vendor Statistics page.
        VerifyVendorStatistics(
          PurchaseHeader."Buy-from Vendor No.", BalanceLCY, OutstandingOrdersLCY, AmtRcdNotInvoicedLCY, TotalAmountLCY, BalanceDueLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatisticsAfterPost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BalanceLCY: Decimal;
        OutstandingOrdersLCY: Decimal;
        AmtRcdNotInvoicedLCY: Decimal;
        TotalAmountLCY: Decimal;
        BalanceDueLCY: Decimal;
        OldWorkDate: Date;
    begin
        // [SCENARIO] Create Purchase Order and Verify Vendor Statistics after Post.
        Initialize();

        // [GIVEN] Create Purchase Header and Line.
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine);

        // [GIVEN] Release Purchase Order.
        OldWorkDate := WorkDate();  // Need to preserve Old WorkDate.
        WorkDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        BalanceLCY := PurchaseLine."Outstanding Amount (LCY)";
        OutstandingOrdersLCY := 0;   // Value is important here.
        AmtRcdNotInvoicedLCY := 0;
        TotalAmountLCY := PurchaseLine."Outstanding Amount (LCY)";
        BalanceDueLCY := PurchaseLine."Outstanding Amount (LCY)";

        // [WHEN] Post Purchase Order as Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check Balance (LCY), Outstanding Orders (LCY), TotalAmountLCY, BalanceLCY, BalanceDueLCY on Vendor Statistics page.
        VerifyVendorStatistics(
          PurchaseHeader."Buy-from Vendor No.", BalanceLCY, OutstandingOrdersLCY, AmtRcdNotInvoicedLCY, TotalAmountLCY, BalanceDueLCY);

        // Tear Down: Restore Old WorkDate.
        WorkDate := OldWorkDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFilterOnVendStatsByCurrLinesFromVendList()
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
        VendStatsByCurrLines: TestPage "Vend. Stats. by Curr. Lines";
        BalanceLCY: Decimal;
        BalanceFCY: Decimal;
    begin
        // [SCENARIO] Test that while opening the page VendStatsByCurrLines from the Vendor list, proper filter can be applied on that page.
        Initialize();

        // [GIVEN] Create Vendor and Purchase Document with or without currency and post it.
        LibraryPurchase.CreateVendor(Vendor);
        BalanceLCY := CreateAndPostPurchaseDocument(Vendor."No.", '');
        FindCurrency(Currency);
        BalanceFCY := CreateAndPostPurchaseDocument(Vendor."No.", Currency.Code);

        // [WHEN] Invoke page VendStatsByCurrLines from Vendor list page.
        InvokeVendStatsByCurrLinesFromVendorList(VendStatsByCurrLines, Vendor."No.");

        // [THEN] Verfiy that proper filter can be applied on the page VendStatsByCurrLines and also verified the field Vendor Balance.
        VerifyFiltersOnVendStatsByCurrLinesPage(VendStatsByCurrLines, '', BalanceLCY);
        VerifyFiltersOnVendStatsByCurrLinesPage(VendStatsByCurrLines, Currency.Code, BalanceFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFilterOnVendStatsByCurrLinesFromVendCard()
    var
        Vendor: Record Vendor;
        Currency: Record Currency;
        VendStatsByCurrLines: TestPage "Vend. Stats. by Curr. Lines";
        BalanceLCY: Decimal;
        BalanceFCY: Decimal;
    begin
        // [SCENARIO] Test that while opening the page VendStatsByCurrLines from the Vendor card, proper filter can be applied on that page.
        Initialize();

        // [GIVEN] Create Vendor and Purchase Document with or without currency and post it.
        LibraryPurchase.CreateVendor(Vendor);
        BalanceLCY := CreateAndPostPurchaseDocument(Vendor."No.", '');
        FindCurrency(Currency);
        BalanceFCY := CreateAndPostPurchaseDocument(Vendor."No.", Currency.Code);

        // [WHEN] Invoke page VendStatsByCurrLines from Vendor card page.
        InvokeVendStatsByCurrLinesFromVendorCard(VendStatsByCurrLines, Vendor."No.");

        // [THEN] Verfiy that proper filter can be applied on the page VendStatsByCurrLines and also verified the field Vendor Balance.
        VerifyFiltersOnVendStatsByCurrLinesPage(VendStatsByCurrLines, '', BalanceLCY);
        VerifyFiltersOnVendStatsByCurrLinesPage(VendStatsByCurrLines, Currency.Code, BalanceFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckOverDueBalanceForVendor()
    var
        Vendor: Record Vendor;
        OldWorkDate: Date;
        InvoiceAmountLCY: Decimal;
        PaymentAmountLCY: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 210533] Check Over Due Balance on Customer after changing Work date greater than Payment Date.
        Initialize();

        // [GIVEN] Post Sales Invoice and make partial payment.
        LibraryPurchase.CreateVendor(Vendor);
        InvoiceAmountLCY := CreateAndPostPurchaseDocument(Vendor."No.", '');
        PaymentAmountLCY := PostPartialPaymentForVendor(Vendor."No.", InvoiceAmountLCY);

        // [WHEN] Change Work date after Posting Payment.
        OldWorkDate := WorkDate();
        WorkDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate());

        // [THEN] Verifing Over Due Balance on Vendor Statistics.
        Assert.AreEqual(Vendor.CalcOverDueBalance(), Round(InvoiceAmountLCY - PaymentAmountLCY), OverDueBalanceErr);

        // Tear Down: Restore Old WorkDate.
        WorkDate := OldWorkDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatisticsFactBoxWithPayToVendorNoBlank()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderCard: TestPage "Purchase Order";
    begin
        // [SCENARIO 122259] Vendor Statistics Fact Box shows "Vendor.No." data in Purchase Order Card if Pay-to Vendor No. is blank
        Initialize();

        // [GIVEN] Vendor "X" with blank "Pay-to Vendor No."
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Pay-to Vendor No.", '');
        Vendor.Modify(true);

        // [GIVEN] Purchase Order for Vendor "X"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] Open Purchase Order Card
        PurchaseOrderCard.OpenView();
        PurchaseOrderCard.GotoRecord(PurchaseHeader);

        // [THEN] Vendor Statistics Fact Box is opened for "Vendor.No." = 'X'
        PurchaseOrderCard.Control1904651607."No.".AssertEquals(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatisticsFactBoxWithPayToVendorNoNotBlank()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderCard: TestPage "Purchase Order";
    begin
        // [SCENARIO 122259] Vendor Statistics Fact Box shows "Pay-to Vendor No." data in Purchase Order Card if Pay-to Vendor No. is not blank
        Initialize();

        // [GIVEN] Vendor "X" with "Pay-to Vendor No." = Y
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo());
        Vendor.Modify(true);

        // [GIVEN] Purchase Order for Vendor "X"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] Open Purchase Order Card
        PurchaseOrderCard.OpenView();
        PurchaseOrderCard.GotoRecord(PurchaseHeader);

        // [THEN] Vendor Statistics Fact Box is opened for "Pay-to Vendor No." = 'Y'
        PurchaseOrderCard.Control1904651607."No.".AssertEquals(Vendor."Pay-to Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnBalanceFromList()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorList: TestPage "Vendor List";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        Initialize();

        // [GIVEN] Setup new Vendor with a vendor ledger entry
        LibraryPurchase.CreateVendor(Vendor);
        CreateBasicVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");

        // [WHEN] The user drills down on Balance (LCY) field from Vendor List
        VendorList.OpenView();
        VendorList.GotoRecord(Vendor);
        VendorLedgerEntries.Trap();
        VendorList."Balance (LCY)".DrillDown();

        // [THEN] Vendor Ledger Entries window opens, showing the ledger entries for the selected vendor
        VendorLedgerEntries.First();
        Assert.AreEqual(VendorLedgerEntry."Entry No.", VendorLedgerEntries."Entry No.".AsInteger(), '');
        Assert.IsFalse(VendorLedgerEntries.Next(), '');
        VendorLedgerEntries.Close();
        VendorList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnBalanceFromCard()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorCard: TestPage "Vendor Card";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        Initialize();

        // [GIVEN] Setup new Customer with a customer ledger entry
        LibraryPurchase.CreateVendor(Vendor);
        CreateBasicVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");

        // [WHEN] The user drills down on Balance (LCY) field from Vendor Card
        VendorCard.OpenView();
        VendorCard.GotoRecord(Vendor);
        VendorLedgerEntries.Trap();
        VendorCard."Balance (LCY)".DrillDown();

        // [THEN] Vendor Ledger Entries window opens, showing the ledger entries for the selected vendor
        VendorLedgerEntries.First();
        Assert.AreEqual(VendorLedgerEntry."Entry No.", VendorLedgerEntries."Entry No.".AsInteger(), '');
        Assert.IsFalse(VendorLedgerEntries.Next(), '');
        VendorLedgerEntries.Close();
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnBalanceDueFromList()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorList: TestPage "Vendor List";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [SCENARIO 258948] When Drill Down on Balance Due (LCY) is called from Vendor List, Due Date filter on opened Vendor Ledger Entries Page = Date Filter.
        Initialize();

        // [GIVEN] Setup new Vendor with a vendor ledger entry
        LibraryPurchase.CreateVendor(Vendor);
        CreateBasicVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");
        VendorLedgerEntry.Validate("Due Date", LibraryRandom.RandDate(100));
        VendorLedgerEntry.Modify(true);

        // [WHEN] The user drills down on Balance Due (LCY) field from Vendor List
        VendorList.OpenView();
        VendorLedgerEntries.Trap();
        VendorList.FILTER.SetFilter("Date Filter", Format(VendorLedgerEntry."Due Date"));
        VendorList.GotoRecord(Vendor);
        VendorList."Balance Due (LCY)".DrillDown();

        // [THEN] Vendor Ledger Entries window opens, Due Date filter = Date Filter from Customer List.
        Assert.AreEqual(VendorList.FILTER.GetFilter("Date Filter"), VendorLedgerEntries.FILTER.GetFilter("Due Date"), '');

        // [THEN] Vendor Ledger Entries window opens, showing the ledger entries for the selected vendor
        VendorLedgerEntries.First();
        Assert.AreEqual(VendorLedgerEntry."Entry No.", VendorLedgerEntries."Entry No.".AsInteger(), '');
        Assert.IsFalse(VendorLedgerEntries.Next(), '');

        // Tear down.
        VendorLedgerEntries.Close();
        VendorList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnBalanceDueFromCard()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorCard: TestPage "Vendor Card";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [SCENARIO 258948] When Drill Down on Balance Due (LCY) is called from Vendor Card, Due Date filter on opened Vendor Ledger Entries Page = Date Filter.
        Initialize();

        // [GIVEN] Setup new Customer with a customer ledger entry
        LibraryPurchase.CreateVendor(Vendor);
        CreateBasicVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");
        VendorLedgerEntry.Validate("Due Date", LibraryRandom.RandDate(100));
        VendorLedgerEntry.Modify(true);

        // [WHEN] The user drills down on Balance Due (LCY) field from Vendor Card
        VendorCard.OpenView();
        VendorLedgerEntries.Trap();
        VendorCard.FILTER.SetFilter("Date Filter", Format(VendorLedgerEntry."Due Date"));
        VendorCard.GotoRecord(Vendor);
        VendorCard."Balance Due (LCY)".DrillDown();

        // [THEN] Vendor Ledger Entries window opens, Due Date filter = Date Filter from Customer List.
        Assert.AreEqual(VendorCard.FILTER.GetFilter("Date Filter"), VendorLedgerEntries.FILTER.GetFilter("Due Date"), '');

        // [THEN] Vendor Ledger Entries window opens, showing the ledger entries for the selected vendor
        VendorLedgerEntries.First();
        Assert.AreEqual(VendorLedgerEntry."Entry No.", VendorLedgerEntries."Entry No.".AsInteger(), '');
        Assert.IsFalse(VendorLedgerEntries.Next(), '');

        // Tear down.
        VendorLedgerEntries.Close();
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VendBalanceByDateFilter()
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        NewDate: Date;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217425] Flow field "Balance" of Vendor does not depend on flow filter "Date Filter"

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        MockDtldVendLedgEntry(DetailedVendorLedgEntry, Vendor."No.", WorkDate(), WorkDate());
        TotalAmount += DetailedVendorLedgEntry.Amount;
        NewDate := WorkDate() + 1;
        MockDtldVendLedgEntry(DetailedVendorLedgEntry, Vendor."No.", NewDate, NewDate);
        TotalAmount += DetailedVendorLedgEntry.Amount;

        Vendor.SetFilter("Date Filter", Format(NewDate));
        Vendor.CalcFields(Balance);

        Vendor.TestField(Balance, -TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VendBalanceLCYByDateFilter()
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        NewDate: Date;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217425] Flow field "Balance (LCY)" of Vendor does not depend on flow filter "Date Filter"

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        MockDtldVendLedgEntry(DetailedVendorLedgEntry, Vendor."No.", WorkDate(), WorkDate());
        TotalAmount += DetailedVendorLedgEntry."Amount (LCY)";
        NewDate := WorkDate() + 1;
        MockDtldVendLedgEntry(DetailedVendorLedgEntry, Vendor."No.", NewDate, NewDate);
        TotalAmount += DetailedVendorLedgEntry."Amount (LCY)";

        Vendor.SetFilter("Date Filter", Format(NewDate));
        Vendor.CalcFields("Balance (LCY)");

        Vendor.TestField("Balance (LCY)", -TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_BalanceDueCalcOnMaxLimitOfDateFilter()
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DueDate: Date;
        NewDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO 210354] Flow field "Balance Due" calculates given maximum limit of flow filter "Date Filter"

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        DueDate := CalcDate('<1M>', WorkDate());
        MockDtldVendLedgEntry(DetailedVendorLedgEntry, Vendor."No.", WorkDate(), DueDate);
        ExpectedAmount := -DetailedVendorLedgEntry.Amount;
        NewDate := DueDate + 1;
        MockDtldVendLedgEntry(DetailedVendorLedgEntry, Vendor."No.", NewDate, CalcDate('<1M>', NewDate));

        Vendor.SetFilter("Date Filter", Format(NewDate));
        Vendor.CalcFields("Balance Due");

        Vendor.TestField("Balance Due", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_BalanceDueLCYCalcOnMaxLimitOfDateFilter()
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DueDate: Date;
        NewDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO 210354] Flow field "Balance Due (LCY)" calculates given maximum limit of flow filter "Date Filter"

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        DueDate := CalcDate('<1M>', WorkDate());
        MockDtldVendLedgEntry(DetailedVendorLedgEntry, Vendor."No.", WorkDate(), DueDate);
        ExpectedAmount := -DetailedVendorLedgEntry."Amount (LCY)";
        NewDate := DueDate + 1;
        MockDtldVendLedgEntry(DetailedVendorLedgEntry, Vendor."No.", NewDate, CalcDate('<1M>', NewDate));

        Vendor.SetFilter("Date Filter", Format(NewDate));
        Vendor.CalcFields("Balance Due (LCY)");

        Vendor.TestField("Balance Due (LCY)", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatNotEditable()
    var
        VendorStatistics: TestPage "Vendor Statistics";
        VendorList: TestPage "Vendor List";
        VendorNo: Code[20];
    begin
        // [SCENARIO 223267] Page Vendor Statistic must be not editable
        Initialize();

        // [GIVEN] Vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [WHEN] Open "Vendor Statistics"
        VendorList.OpenView();
        VendorList.FILTER.SetFilter("No.", VendorNo);
        VendorStatistics.Trap();
        VendorList.Statistics.Invoke();

        // [THEN] Page "Customer Statistics" is not editable
        Assert.IsFalse(VendorStatistics.Editable(), 'Page "Vendor Statistics" must be not editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactboxStatFieldsNotAffectedByDateFilterShowTheirValues()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        VendorList: TestPage "Vendor List";
        OrderOutstandingAmtLCY: Decimal;
        InvOutstandingAmtLCY: Decimal;
        AmtRcdNotInvoiced: Decimal;
    begin
        // [SCENARIO 253431] The fields on page "Vendor Statistics Factbox" which are not affected by "Date Filter" must show their values

        Initialize();

        // [GIVEN] Purchase Order with "Outstanding Amount (LCY)" = 100, "Amt. Rcd. Not Invoiced" = 40
        LibraryPurchase.CreateVendor(Vendor);
        OrderOutstandingAmtLCY := LibraryRandom.RandDec(100, 2);
        AmtRcdNotInvoiced := LibraryRandom.RandDec(100, 2);
        MockPurchLine(Vendor."No.", PurchaseLine."Document Type"::Order, OrderOutstandingAmtLCY, AmtRcdNotInvoiced);

        // [GIVEN] Purchase Invoice with "Outstanding Amount (LCY)" = 60
        InvOutstandingAmtLCY := LibraryRandom.RandDec(100, 2);
        MockPurchLine(Vendor."No.", PurchaseLine."Document Type"::Invoice, InvOutstandingAmtLCY, 0);

        // [WHEN] Open "Vendor Statistics Factbox"
        VendorList.OpenView();
        VendorList.GotoRecord(Vendor);

        // [THEN] Page "Vendor Statistics Factbox" has "Outstanding Orders (LCY)" = 100, "Amt. Rcd. Not Invoiced" = 40, "Outstanding Invoices (LCY)" = 60,
        VendorList.VendorStatisticsFactBox."Outstanding Orders (LCY)".AssertEquals(OrderOutstandingAmtLCY);
        Assert.IsFalse(VendorList.VendorStatisticsFactBox."Outstanding Orders (LCY)".HideValue(), FieldIsNotHiddenErr);
        VendorList.VendorStatisticsFactBox."Amt. Rcd. Not Invoiced (LCY)".AssertEquals(AmtRcdNotInvoiced);
        Assert.IsFalse(VendorList.VendorStatisticsFactBox."Amt. Rcd. Not Invoiced (LCY)".HideValue(), FieldIsNotHiddenErr);
        VendorList.VendorStatisticsFactBox."Outstanding Invoices (LCY)".AssertEquals(InvOutstandingAmtLCY);
        Assert.IsFalse(VendorList.VendorStatisticsFactBox."Outstanding Invoices (LCY)".HideValue(), FieldIsNotHiddenErr);
        VendorList.VendorStatisticsFactBox.TotalAmountLCY.AssertEquals(
          OrderOutstandingAmtLCY + AmtRcdNotInvoiced + InvOutstandingAmtLCY);
        Assert.IsFalse(VendorList.VendorStatisticsFactBox.TotalAmountLCY.HideValue(), FieldIsNotHiddenErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBalanceDueIsCalculatedConsideringDueDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: array[2] of Record "Detailed Vendor Ledg. Entry";
    begin
        // [SCENARIO 258948] Vendor "Balance Due" is calculated based on Detailed Vendor Ledger Entries with Initial Entries Due Date < Date Filter.
        Initialize();

        // [GIVEN] Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Detailed Vendor Ledger Entry "DVLE1" with Due Date > WORKDATE and Amount = 100.
        CreateVendorLedgerEntryWithDueDate(VendorLedgerEntry[1], Vendor."No.", LibraryRandom.RandDate(100));
        MockDetailedVendorLedgerEntryWithDueDate(DetailedVendorLedgEntry[1], VendorLedgerEntry[1]);

        // [GIVEN] Detailed Vendor Ledger Entry "DVLE2" with Due Date < WORKDATE and Amount = 200.
        CreateVendorLedgerEntryWithDueDate(VendorLedgerEntry[2], Vendor."No.", LibraryRandom.RandDate(-100));
        MockDetailedVendorLedgerEntryWithDueDate(DetailedVendorLedgEntry[2], VendorLedgerEntry[2]);

        // [WHEN] Set "Date Filter" = WORKDATE.
        Vendor.SetFilter("Date Filter", Format(WorkDate()));

        // [THEN] "Balance Due" = 200.
        Vendor.CalcFields("Balance Due");
        Vendor.TestField("Balance Due", -DetailedVendorLedgEntry[2].Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBalanceDueSumsDetailedLedgerEntriesAnyPostingDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: array[2] of Record "Detailed Vendor Ledg. Entry";
    begin
        // [SCENARIO 258948] Vendor "Balance Due" is calculated based on Detailed Vendor Ledger Entries with any posting date.
        Initialize();

        // [GIVEN] Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Detailed Vendor Ledger Entry "DVLE1" with Posting Date > WORKDATE and Amount = 100.
        CreateBasicVendorLedgerEntry(VendorLedgerEntry, Vendor."No.");
        MockDetailedVendorLedgerEntryWithPostingDate(DetailedVendorLedgEntry[1], VendorLedgerEntry, LibraryRandom.RandDate(100));

        // [GIVEN] Detailed Vendor Ledger Entry "DVLE2" with Posting Date < WORKDATE and Amount = 200.
        MockDetailedVendorLedgerEntryWithPostingDate(DetailedVendorLedgEntry[2], VendorLedgerEntry, LibraryRandom.RandDate(-100));

        // [WHEN] Set "Date Filter" = WORKDATE.
        Vendor.SetFilter("Date Filter", Format(WorkDate()));

        // [THEN] "Balance Due" = 300.
        Vendor.CalcFields("Balance Due");
        Vendor.TestField("Balance Due", -(DetailedVendorLedgEntry[1].Amount + DetailedVendorLedgEntry[2].Amount));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorStatisticsFactboxLastPaymentDate()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PaymentDate: array[3] of Date;
    begin
        // [SCENARIO 264555] Vendor statistics factbox shows last payment date
        Initialize();

        // [GIVEN] Create new Vendor "VEND"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Post payment "PAYM1" on 01.01
        PaymentDate[1] := CalcDate('<-CM>', WorkDate());
        PostPaymentForVendor(Vendor."No.", PaymentDate[1]);
        // [GIVEN] Post payment "PAYM2" on 15.01
        PaymentDate[2] := CalcDate('<-CM+14D>', WorkDate());
        PostPaymentForVendor(Vendor."No.", PaymentDate[2]);
        // [GIVEN] Post payment "PAYM3" on 31.01
        PaymentDate[3] := CalcDate('<CM>', WorkDate());
        PostPaymentForVendor(Vendor."No.", PaymentDate[3]);
        // [GIVEN] Reverse payment "PAYM3"
        ReversePayment(Vendor."No.", PaymentDate[3]);

        // [WHEN] Vendor card page is being opened for "VEND"
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", Vendor."No.");

        // [THEN] Vendor statistics factbox shows Last Payment Date = 15.01
        VendorCard.VendorStatisticsFactBox.LastPaymentDate.AssertEquals(PaymentDate[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorStatisticsFactboxDrillDownLastPaymentDate()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PaymentDate: array[3] of Date;
    begin
        // [SCENARIO 264555] DrillDown of Last Payment Date of customer statistics factbox opens vendor payments with cursor on last payment
        Initialize();

        // [GIVEN] Create new Vendor "VEND"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Post payment "PAYM1" on 01.01
        PaymentDate[1] := CalcDate('<-CM>', WorkDate());
        PostPaymentForVendor(Vendor."No.", PaymentDate[1]);
        // [GIVEN] Post payment "PAYM2" on 15.01
        PaymentDate[2] := CalcDate('<-CM+14D>', WorkDate());
        PostPaymentForVendor(Vendor."No.", PaymentDate[2]);
        // [GIVEN] Post payment "PAYM3" on 31.01
        PaymentDate[3] := CalcDate('<CM>', WorkDate());
        PostPaymentForVendor(Vendor."No.", PaymentDate[3]);
        // [GIVEN] Reverse payment "PAYM3"
        ReversePayment(Vendor."No.", PaymentDate[3]);

        // [GIVEN] Open vendor card page for "VEND"
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", Vendor."No.");

        // [WHEN] Last Payment Date drill down is being invoked
        VendorLedgerEntries.Trap();
        VendorCard.VendorStatisticsFactBox.LastPaymentDate.DrillDown();

        // [THEN] Opened list of payments has cursor on payment "PAYM2"
        VendorLedgerEntries."Posting Date".AssertEquals(PaymentDate[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintainSIFTIndexForVendorPaymentLCYEnagled()
    var
        "Key": Record "Key";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 292660] MaintainSIFTIndex should be enabled for Detailed Vendor Ledg. Entry key responsible for calculation Vendor.Payments (LCY)
        Key.SetRange(TableNo, DATABASE::"Detailed Vendor Ledg. Entry");
        Key.SetFilter(
          Key,
          'Vendor No.,Currency Code,Initial Entry Global Dim. 1,Initial Entry Global Dim. 2,Initial Entry Due Date,*');
        Key.FindFirst();
        Key.TestField(MaintainSIFTIndex, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatisticsNoPlaceholderText()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorStatistics: TestPage "Vendor Statistics";
        VisibleValue: Boolean;
    begin
        // [SCENARIO 369640] Vendor Statistics card does not contain 'Placeholder' texts
        Initialize();

        // [GIVEN] Create new Vendor "VEND"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Open vendor card page for "VEND"
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", Vendor."No.");

        // [WHEN] Open Vendor Statistics
        VendorStatistics.Trap();
        VendorCard.Statistics.Invoke();

        // [THEN] 'Placeholder' text is not present under 'This Year', 'Last Year', 'To Date' fields
        ClearLastError();
        asserterror VisibleValue := VendorStatistics.Text001.Visible();
        Assert.ExpectedError('is not found on the page');
        ClearLastError();
        asserterror VisibleValue := VendorStatistics.Control81.Visible();
        Assert.ExpectedError('is not found on the page');
        ClearLastError();
        asserterror VisibleValue := VendorStatistics.Control82.Visible();
        Assert.ExpectedError('is not found on the page');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Vendor Statistics");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Vendor Statistics");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Vendor Statistics");
    end;

    local procedure VerifyVendorStatistics(VendorNo: Code[20]; BalanceLCY: Decimal; OutstandingOrdersLCY: Decimal; AmtRcdNotInvoicedLCY: Decimal; TotalAmountLCY: Decimal; BalanceDueLCY: Decimal)
    var
        VendorStatistics: TestPage "Vendor Statistics";
    begin
        VendorStatistics.OpenView();
        VendorStatistics.FILTER.SetFilter("No.", VendorNo);
        VendorStatistics."Balance (LCY)".AssertEquals(BalanceLCY);
        VendorStatistics."Outstanding Orders (LCY)".AssertEquals(OutstandingOrdersLCY);
        VendorStatistics."Amt. Rcd. Not Invoiced (LCY)".AssertEquals(AmtRcdNotInvoicedLCY);
        VendorStatistics.GetTotalAmountLCY.AssertEquals(TotalAmountLCY);
        VendorStatistics."Balance Due (LCY)".AssertEquals(BalanceDueLCY);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        VendorNo: Code[20];
    begin
        if PurchaseHeader."Buy-from Vendor No." = '' then
            VendorNo := CreateVendorWithCurrency()
        else
            VendorNo := PurchaseHeader."Buy-from Vendor No.";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(20, 1));

        // Use random value, because value is not important here.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseDocument(VendorNo: Code[20]; CurrencyCode: Code[10]): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader."Buy-from Vendor No." := VendorNo;
        CreatePurchaseHeader(PurchaseHeader);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure CreateVendorWithCurrency(): Code[20]
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
    begin
        // Filter Currency to Avoid Invoice Rounding Issues
        FindCurrency(Currency);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateBasicVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntryWithDueDate(var VendorLedgEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DueDate: Date)
    begin
        CreateBasicVendorLedgerEntry(VendorLedgEntry, VendorNo);
        VendorLedgEntry.Validate("Due Date", DueDate);
        VendorLedgEntry.Modify(true);
    end;

    local procedure MockDetailedVendorLedgerEntryWithDueDate(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Initial Entry Due Date" := VendorLedgerEntry."Due Date";
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(1000, 2);
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure MockDetailedVendorLedgerEntryWithPostingDate(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"; PostingDate: Date)
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(1000, 2);
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure FindCurrency(var Currency: Record Currency)
    begin
        Currency.SetRange("Invoice Rounding Precision", LibraryERM.GetAmountRoundingPrecision());
        LibraryERM.FindCurrency(Currency);
    end;

    local procedure FindDocumentNo(VendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure InvokeVendStatsByCurrLinesFromVendorList(var VendStatsByCurrLines: TestPage "Vend. Stats. by Curr. Lines"; VendorNo: Code[20])
    var
        VendorList: TestPage "Vendor List";
    begin
        VendorList.OpenView();
        VendorList.FILTER.SetFilter("No.", VendorNo);
        VendStatsByCurrLines.Trap();
        VendorList."Statistics by C&urrencies".Invoke();
    end;

    local procedure InvokeVendStatsByCurrLinesFromVendorCard(var VendStatsByCurrLines: TestPage "Vend. Stats. by Curr. Lines"; VendorNo: Code[20])
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenView();
        VendorCard.FILTER.SetFilter("No.", VendorNo);
        VendStatsByCurrLines.Trap();
        VendorCard."Statistics by C&urrencies".Invoke();
    end;

    local procedure PostPartialPaymentForVendor(VendorNo: Code[20]; InvoiceAmountLCY: Decimal): Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, InvoiceAmountLCY / LibraryRandom.RandIntInRange(2, 4));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", FindDocumentNo(VendorNo));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine.Amount);
    end;

    local procedure PostPaymentForVendor(VendorNo: Code[20]; PostingDate: Date): Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(-GenJournalLine.Amount);
    end;

    local procedure ReversePayment(VendorNo: Code[20]; PostingDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Posting Date", PostingDate);
        VendorLedgerEntry.FindFirst();
        LibraryERM.ReverseTransaction(VendorLedgerEntry."Transaction No.");
    end;

    local procedure MockDtldVendLedgEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendNo: Code[20]; PostingDate: Date; InitialEntryDueDate: Date)
    begin
        DetailedVendorLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor No." := VendNo;
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Initial Entry Due Date" := InitialEntryDueDate;
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure MockPurchLine(VendNo: Code[20]; DocType: Enum "Purchase Document Type"; OutstandingAmountLCY: Decimal; AmtRcdNotInvoicedLCY: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := DocType;
        PurchaseLine."Document No." :=
          LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo("Document No."), DATABASE::"Purchase Line");
        PurchaseLine."Pay-to Vendor No." := VendNo;
        PurchaseLine."Outstanding Amount (LCY)" := OutstandingAmountLCY;
        PurchaseLine."Amt. Rcd. Not Invoiced (LCY)" := AmtRcdNotInvoicedLCY;
        PurchaseLine.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text; var Response: Boolean)
    begin
        Response := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    local procedure VerifyFiltersOnVendStatsByCurrLinesPage(VendStatsByCurrLines: TestPage "Vend. Stats. by Curr. Lines"; CurrencyCode: Code[10]; VendorBalance: Decimal)
    begin
        VendStatsByCurrLines.FILTER.SetFilter(Code, CurrencyCode);
        VendStatsByCurrLines."Vendor Balance".AssertEquals(VendorBalance);
    end;
}

