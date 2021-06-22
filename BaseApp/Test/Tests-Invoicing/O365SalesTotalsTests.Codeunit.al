codeunit 138904 "O365 Sales Totals Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Sales] [Statistics]
    end;

    var
        Assert: Codeunit Assert;
        InvalidMonthErr: Label 'An invalid month was specified.';
        OutsideFYErr: Label 'The date is outside of the current accounting period.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        APIMockEvents: Codeunit "API Mock Events";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // Ensure WORKDATE does not drift too far from the accounting period start date
        AccountingPeriod.SetRange("New Fiscal Year", true);
        if not AccountingPeriod.FindLast then begin
            AccountingPeriod.Init;
            AccountingPeriod."Starting Date" := CalcDate('<CY+1D>', WorkDate);
            AccountingPeriod."New Fiscal Year" := true;
            AccountingPeriod.Insert;
        end;

        WorkDate(AccountingPeriod."Starting Date");

        if IsInitialized then
            exit;

        APIMockEvents.SetIsAPIEnabled(true);
        BindSubscription(LibraryJobQueue);
        BindSubscription(APIMockEvents);
        IsInitialized := true;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestLocalizedMonth()
    var
        TypeHelper: Codeunit "Type Helper";
        MonthText: Text;
        Month: Integer;
    begin
        // Test each month
        LibraryLowerPermissions.SetInvoiceApp;
        for Month := 1 to 12 do begin
            // Setup
            MonthText := UpperCase(Format(CalcDate(StrSubstNo('<CY+%1M>', Month)), 0, '<Month Text>'));

            // Exercise and Verify
            Assert.AreEqual(Month, TypeHelper.GetLocalizedMonthToInt(MonthText), '');
        end;

        // Verify error handling
        asserterror TypeHelper.GetLocalizedMonthToInt('Invalid Month');
        Assert.ExpectedError(InvalidMonthErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestLocalCurrencySymbolCodeOnly()
    var
        GLSetup: Record "General Ledger Setup";
        Symbol: Text[10];
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp;
        SetGLSetupCurrency('CODE', '');
        GLSetup.Get;

        // Exercise
        Symbol := GLSetup.GetCurrencySymbol;

        // Verify
        Assert.AreEqual(GLSetup."LCY Code", Symbol, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestLocalCurrencySymbol()
    var
        GLSetup: Record "General Ledger Setup";
        Symbol: Text[10];
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp;
        SetGLSetupCurrency('CODE', 'Sym');
        GLSetup.Get;

        // Exercise
        Symbol := GLSetup.GetCurrencySymbol;

        // Verify
        Assert.AreEqual(GLSetup."Local Currency Symbol", Symbol, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCurrencySymbolCodeOnly()
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
        Symbol: Text[10];
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryERM.CreateCurrency(Currency);
        Currency.Symbol := '';
        Currency.Modify;

        // Exercise
        Symbol := Currency.GetCurrencySymbol;

        // Verify
        Assert.AreEqual(Currency.Code, Symbol, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCurrencySymbol()
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
        Symbol: Text[10];
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryERM.CreateCurrency(Currency);
        Currency.Symbol := 'Sym';
        Currency.Modify;

        // Exercise
        Symbol := Currency.GetCurrencySymbol;

        // Verify
        Assert.AreEqual(Currency.Symbol, Symbol, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestValidSymbolLookup()
    var
        Currency: Record Currency;
        Result: Text[10];
    begin
        // Initialize
        LibraryLowerPermissions.SetInvoiceApp;
        if Currency.Get('USD') then
            Currency.Delete; // ensure it does not exist

        // Exercise
        Result := Currency.ResolveCurrencySymbol('USD');

        // Verify
        Assert.AreEqual('$', Result, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestInvalidSymbolLookup()
    var
        Currency: Record Currency;
        Result: Text[10];
    begin
        // Initialize
        LibraryLowerPermissions.SetInvoiceApp;
        if Currency.Get('Invalid') then
            Currency.Delete; // ensure it does not exist

        // Exercise
        Result := Currency.ResolveCurrencySymbol('Invalid');

        // Verify
        Assert.AreEqual('', Result, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestOverridenSymbolLookup()
    var
        Currency: Record Currency;
        Result: Text[10];
    begin
        // Initialize
        LibraryLowerPermissions.SetInvoiceApp;
        if not Currency.Get('USD') then begin
            Currency.Init;
            Currency.Code := 'USD';
            Currency.Insert;
        end;

        Currency.Symbol := 'kr.';
        Currency.Modify;

        // Exercise
        Result := Currency.ResolveCurrencySymbol('USD');

        // Verify
        Assert.AreEqual('kr.', Result, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestMonthlyOverviewGeneratesCorrectNumberOfMonths()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        AccountingPeriod: Record "Accounting Period";
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
        Month: Integer;
    begin
        // Setup for WORKDATE
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;
        O365SalesStatistics.GetCurrentAccountingPeriod(AccountingPeriod);

        // Verify the correct accounting period was selected
        Assert.AreEqual(WorkDate, AccountingPeriod."Starting Date", 'The incorrect starting period was chosen.');

        for Month := 1 to 12 do begin
            // Setup
            WorkDate(CalcDate(StrSubstNo('<%1M>', Month - 1), AccountingPeriod."Starting Date"));

            // Exercise
            O365SalesStatistics.GenerateMonthlyOverview(TempNameValueBuffer);

            // Verify
            Assert.AreEqual(Month, TempNameValueBuffer.Count, '');

            TempNameValueBuffer.DeleteAll; // Cleanup
        end;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestMonthlyOverviewAfterFY()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;
        WorkDate(CalcDate('<1Y>', WorkDate)); // 1 year later

        // Exercise
        asserterror O365SalesStatistics.GenerateMonthlyOverview(TempNameValueBuffer);

        // Verify
        Assert.ExpectedError(OutsideFYErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestMonthlyOverviewBeforeFY()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        AccountingPeriod: Record "Accounting Period";
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        AccountingPeriod.FindFirst;
        WorkDate(CalcDate('<-1Y>', AccountingPeriod."Starting Date")); // 1 year before first accounting period

        // Exercise
        asserterror O365SalesStatistics.GenerateMonthlyOverview(TempNameValueBuffer);

        // Verify
        Assert.ExpectedError(OutsideFYErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestMonthlyOverviewData()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
        TotalThisMonth: Decimal;
    begin
        // Setup
        Initialize;
        GLSetup.Get;

        LibraryLowerPermissions.SetOutsideO365Scope;

        // We create customer ledger entries as well to verify these do not interfere with result.
        CreateDemoCustLedgerEntries('');
        TotalThisMonth := CreatePostedSalesInvoices('');
        CreateDraftSalesInvoice('');
        GraphMgtGeneralTools.ApiSetup;

        // Exercise
        LibraryLowerPermissions.SetInvoiceApp;
        O365SalesStatistics.GenerateMonthlyOverview(TempNameValueBuffer);
        TempNameValueBuffer.Get(Date2DMY(WorkDate, 2));

        // Verify
        Assert.AreEqual(StrSubstNo('%1 %2', GLSetup.GetCurrencySymbol, TotalThisMonth), TempNameValueBuffer.Value, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestWeeklyOverviewGenerateCorrectNumberOfWeeks()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        AccountingPeriod: Record "Accounting Period";
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
        Month: Integer;
        Weeks: Integer;
    begin
        // Setup for WORKDATE
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;
        O365SalesStatistics.GetCurrentAccountingPeriod(AccountingPeriod);

        // Verify the correct accounting period was selected
        Assert.AreEqual(WorkDate, AccountingPeriod."Starting Date", 'The incorrect starting period was chosen.');

        for Month := 1 to 12 do begin
            // Exercise
            O365SalesStatistics.GenerateWeeklyOverview(TempNameValueBuffer, Month);

            // Verify
            Weeks := Date2DMY(CalcDate(StrSubstNo('<%1M-1D>', Month), WorkDate), 1) div 7;
            if Date2DMY(CalcDate(StrSubstNo('<%1M-1D>', Month), WorkDate), 1) mod 7 <> 0 then
                Weeks += 1;

            Assert.AreEqual(
              Weeks, TempNameValueBuffer.Count, StrSubstNo('Expected %1 weeks in month %2, actual %3.', Weeks, Month, TempNameValueBuffer.Count));

            TempNameValueBuffer.DeleteAll; // Cleanup
        end;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestWeeklyOverviewData()
    var
        GLSetup: Record "General Ledger Setup";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
        TotalThisWeek: Decimal;
    begin
        // Setup
        Initialize;
        GLSetup.Get;

        LibraryLowerPermissions.SetOutsideO365Scope;
        // We create customer ledger entries as well to verify these do not interfere with result.
        CreateDemoCustLedgerEntries('');
        TotalThisWeek := CreatePostedSalesInvoices('');
        CreateDraftSalesInvoice('');
        GraphMgtGeneralTools.ApiSetup;

        // Exercise
        LibraryLowerPermissions.SetInvoiceApp;
        O365SalesStatistics.GenerateWeeklyOverview(TempNameValueBuffer, Date2DMY(WorkDate, 2));

        // Verify
        TempNameValueBuffer.FindSet;

        // The first week should have data, the remaining should be empty
        Assert.AreNotEqual(StrSubstNo('%1 %2', GLSetup.GetCurrencySymbol, TotalThisWeek), TempNameValueBuffer.Value, '');
        TempNameValueBuffer.Next;

        repeat
            Assert.AreEqual(StrSubstNo('%1 %2', GLSetup.GetCurrencySymbol, 0), TempNameValueBuffer.Value, '');
        until TempNameValueBuffer.Next = 0;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestMonthlyCustomerData()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        ResultCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
    begin
        // Setup
        Initialize;
        SalesInvoiceHeader.DeleteAll;
        LibrarySales.CreateCustomer(Customer);
        LibraryLowerPermissions.SetOutsideO365Scope;
        CreatePostedSalesInvoices(Customer."No.");
        CreateDraftSalesInvoice(Customer."No.");
        GraphMgtGeneralTools.ApiSetup;

        // Exercise
        LibraryLowerPermissions.SetInvoiceApp;
        Assert.IsTrue(O365SalesStatistics.GenerateMonthlyCustomers(Date2DMY(WorkDate, 2), ResultCustomer), 'did not mark any customers');

        // Verify
        ResultCustomer.FindFirst;
        Assert.AreEqual(1, ResultCustomer.Count, 'Incorrect number of customers');
        Assert.AreEqual(Customer."No.", ResultCustomer."No.", 'Incorrect customer selected');
    end;

    local procedure SetGLSetupCurrency("Code": Code[10]; Symbol: Text[5])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        GLSetup."LCY Code" := Code;

        GLSetup."Local Currency Symbol" := Symbol;
        GLSetup.Modify;
    end;

    local procedure CreatePostedSalesInvoices(CustomerCode: Code[20]): Decimal
    var
        OtherCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        OriginalWorkDate: Date;
        Amount: Decimal;
    begin
        LibrarySales.CreateCustomer(OtherCustomer);

        // WORKDATE determines posting date
        OriginalWorkDate := WorkDate;
        Amount += CreatePostedSalesInvoice(CustomerCode); // "today"

        WorkDate(CalcDate('<CM-1M+1D>', OriginalWorkDate)); // this month
        Amount += CreatePostedSalesInvoice(CustomerCode);

        WorkDate(CalcDate('<CM-1M+7D>', OriginalWorkDate)); // first week
        Amount += CreatePostedSalesInvoice(CustomerCode);

        // We create two invoices not in the current month as well
        // these should not be in the sales totals for this month.
        WorkDate(CalcDate('<CM-1M>', OriginalWorkDate)); // previous month
        CreatePostedSalesInvoice(OtherCustomer."No.");

        WorkDate(CalcDate('<CM+1D>', OriginalWorkDate)); // next month
        CreatePostedSalesInvoice(OtherCustomer."No.");

        WorkDate(OriginalWorkDate);
        exit(Amount);
    end;

    [Scope('OnPrem')]
    procedure CreatePostedSalesInvoice(CustomerCode: Code[20]): Decimal
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CustomerCode, Item."No.", LibraryRandom.RandInt(10), '', WorkDate);

        SalesInvoiceHeader.SetAutoCalcFields("Amount Including VAT");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        exit(SalesInvoiceHeader."Amount Including VAT");
    end;

    [Scope('OnPrem')]
    procedure CreateDraftSalesInvoice(CustomerCode: Code[20]): Decimal
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CustomerCode, Item."No.", LibraryRandom.RandInt(10), '', WorkDate);

        exit(SalesHeader."Amount Including VAT");
    end;

    local procedure CreateDemoCustLedgerEntries(CustomerCode: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        OtherCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        OriginalWorkDate: Date;
    begin
        DetailedCustLedgEntry.DeleteAll;
        LibrarySales.CreateCustomer(OtherCustomer);

        // WORKDATE determines posting date
        OriginalWorkDate := WorkDate;

        LibrarySales.MockCustLedgerEntryWithAmount(CustLedgerEntry, CustomerCode); // "today"

        WorkDate(CalcDate('<CM-1M>', OriginalWorkDate)); // previous month
        LibrarySales.MockCustLedgerEntryWithAmount(CustLedgerEntry, OtherCustomer."No.");

        WorkDate(CalcDate('<CM-1M+1D>', OriginalWorkDate)); // this month
        LibrarySales.MockCustLedgerEntryWithAmount(CustLedgerEntry, CustomerCode);

        WorkDate(CalcDate('<CM+1D>', OriginalWorkDate)); // next month
        LibrarySales.MockCustLedgerEntryWithAmount(CustLedgerEntry, OtherCustomer."No.");

        WorkDate(CalcDate('<CM-1M+7D>', OriginalWorkDate)); // first week
        LibrarySales.MockCustLedgerEntryWithAmount(CustLedgerEntry, CustomerCode);

        DetailedCustLedgEntry.SetRange("Posting Date", OriginalWorkDate, CalcDate('<CM>', OriginalWorkDate));
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.CalcSums("Amount (LCY)");

        WorkDate(OriginalWorkDate);
        exit(DetailedCustLedgEntry."Amount (LCY)");
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.AreNotEqual(
            Format(SalesHeader.GetLineInvoiceDiscountResetNotificationId),
            Format(TheNotification.ID),
            StrSubstNo('Unexpected notification: %1',TheNotification.Message));
    end;
}

