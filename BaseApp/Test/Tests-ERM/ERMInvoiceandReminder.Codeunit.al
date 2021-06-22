codeunit 134907 "ERM Invoice and Reminder"
{
    Permissions = TableData "Issued Reminder Header" = rimd,
                  TableData "Issued Reminder Line" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Sales]
        IsInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ReminderLineError: Label 'The %1 on the %2 and the %3 must be the same.';
        AmountError: Label 'Amount must be %1 in %2.';
        AmtDueLbl: Label 'You are receiving this email to formally notify you that payment owed by you is past due. The payment was due on %1. Enclosed is a copy of invoice with the details of remaining amount.', Comment = '%1 - Due Date';
        ProceedOnIssuingWithInvRoundingQst: Label 'The invoice rounding amount will be added to the reminder when it is posted according to invoice rounding setup.\Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvoiceAndModifyReminder()
    var
        ReminderHeader: Record "Reminder Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Check Reminder Line Error after Post Sales Invoice and Modify Reminder Header.

        // Setup: Create Sales Invoice, Reminder Header and Modify it with New Currency.
        Initialize;
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        CreateReminderHeader(ReminderHeader, SalesLine."Sell-to Customer No.");
        ModifyReminderHeader(ReminderHeader);

        // Exercise: Create Reminder Line After Modify Reminder Header.
        asserterror CreateReminderLine(ReminderHeader."No.", DocumentNo);

        // Verify: Check Reminder Line Currency Error.
        Assert.AreEqual(
          StrSubstNo(ReminderLineError, ReminderHeader.FieldCaption("Currency Code"),
            ReminderHeader.TableCaption, CustLedgerEntry.TableCaption), GetLastErrorText, 'Error must be same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvoiceAndReminder()
    var
        Currency: Record Currency;
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RemainingAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Reminder Line Remaining Amount after Post Sales Invoice.

        // Setup: Create Sales Invoice, Reminder Header and Line.
        Initialize;
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);

        // Exercise: Create Reminder Header and Line.
        CreateReminderHeader(ReminderHeader, SalesLine."Sell-to Customer No.");
        RemainingAmount := CreateReminderLine(ReminderHeader."No.", DocumentNo);

        // Verify: Check Remaining Amount on Reminder Line after Posting Sales Invoice.
        Currency.Get(ReminderHeader."Currency Code");
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Assert.AreNearlyEqual(
          SalesInvoiceHeader."Amount Including VAT", RemainingAmount, Currency."Appln. Rounding Precision",
          StrSubstNo(AmountError, SalesInvoiceHeader."Amount Including VAT",
            ReminderLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesOutOfGracePeriodOverduesOnlyTrue()
    var
        Customer: Record Customer;
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[2] of Code[20];
        ReminderPostingDate: array[2] of Date;
    begin
        // [FEATURE] [Payment Terms]
        Initialize;

        // [GIVEN] Reminder Terms "RT" with 3 levels where summary of "Due Date Calculation" = 3W
        // [GIVEN] Level[1] with "Grace Period" = 1W,"Due Date Calculation" = 1W
        // [GIVEN] Level[2] with "Grace Period" = <blank>,"Due Date Calculation" = 1W
        // [GIVEN] Level[3] with "Grace Period" = <blank>,"Due Date Calculation" = 1W
        // [GIVEN] Payment Terms "PT" where "Due Date Calculation" = 1W
        // [GIVEN] Customer "C" where "Payment Terms Code" = "PT" and "Reminder Terms Code" = "RT"
        Evaluate(WeekDateFormula, '<1W>');
        ReminderPostingDate[1] := CalcDate('<3W+1D>', WorkDate);
        ReminderPostingDate[2] := CalcDate('<1W+1D>', ReminderPostingDate[1]);
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "I[1]" for customer "C" where "Posting Date" = 01/01/17
        InvoiceDocNo[1] := PostSalesInvoice(Customer."No.", WorkDate);

        // [GIVEN] Issued reminder for invoice "I[1]" where "Posting Date" = 22/01/17 (>3W from "I[1]"."Posting Date")
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[1]);
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[1], ReminderLine."Line Type"::"Reminder Line");

        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN] Posted invoice "I[2]" for customer "C" where "Posting Date" = 06/01/17 (>"I[1]"."Posting Date" and <"I[1]"."Postsing Date" + 1W)
        InvoiceDocNo[2] := PostSalesInvoice(Customer."No.", CalcDate(WeekDateFormula, WorkDate) - 1);

        // [GIVEN] Reminder for customer "C" with "Posting Date" = 01/02/2017 (>3W from "I[2]"."Posting Date")
        // [WHEN] Run report "Create Reminders" where "Overdues Only" = TRUE
        RunCreateReminders(Customer, DummyCustLedgerEntry, true, ReminderPostingDate[2]);

        // [THEN] Reminder lines for both invoices created with "Line Type" = "Reminder Line"
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[1], ReminderLine."Line Type"::"Reminder Line");
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[2], ReminderLine."Line Type"::"Reminder Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesOutOfGracePeriodOverduesOnlyFalse()
    var
        Customer: Record Customer;
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[2] of Code[20];
        ReminderPostingDate: array[2] of Date;
    begin
        // [FEATURE] [Payment Terms]
        Initialize;

        // [GIVEN] Reminder Terms "RT" with 3 levels where summary of "Due Date Calculation" = 3W
        // [GIVEN] Level[1] with "Grace Period" = 1W,"Due Date Calculation" = 1W
        // [GIVEN] Level[2] with "Grace Period" = <blank>,"Due Date Calculation" = 1W
        // [GIVEN] Level[3] with "Grace Period" = <blank>,"Due Date Calculation" = 1W
        // [GIVEN] Payment Terms "PT" where "Due Date Calculation" = 1W
        // [GIVEN] Customer "C" where "Payment Terms Code" = "PT" and "Reminder Terms Code" = "RT"
        Evaluate(WeekDateFormula, '<1W>');
        ReminderPostingDate[1] := CalcDate('<3W+1D>', WorkDate);
        ReminderPostingDate[2] := CalcDate('<1W+1D>', ReminderPostingDate[1]);
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "I[1]" for customer "C" where "Posting Date" = 01/01/17
        InvoiceDocNo[1] := PostSalesInvoice(Customer."No.", WorkDate);

        // [GIVEN] Issued reminder for invoice "I[1]" where "Posting Date" = 22/01/17 (>3W from "I[1]"."Posting Date")
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[1]);
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[1], ReminderLine."Line Type"::"Reminder Line");

        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN] Posted invoice "I[2]" for customer "C" where "Posting Date" = 06/01/17 (>"I[1]"."Posting Date" and <"I[1]"."Postsing Date" + 1W)
        InvoiceDocNo[2] := PostSalesInvoice(Customer."No.", CalcDate(WeekDateFormula, WorkDate) - 1);

        // [GIVEN] Reminder for customer "C" with "Posting Date" = 01/02/2017 (>3W from "I[2]"."Posting Date")
        // [WHEN] Run report "Create Reminders" where "Overdues Only" = FALSE
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[2]);

        // [THEN] Reminder lines for both invoices created with "Line Type" = "Reminder Line"
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[1], ReminderLine."Line Type"::"Reminder Line");
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[2], ReminderLine."Line Type"::"Reminder Line");
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AmtDueTextReminderReport()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 254526] "AmtDueText" of report "Reminder" (117) contains text
        Initialize;

        // [GIVEN] Issued reminder with line
        MockIssuedReminder(IssuedReminderHeader);
        IssuedReminderHeader.SetRecFilter;
        Commit();

        // [WHEN] Run report "Reminder"
        REPORT.Run(REPORT::Reminder, true, false, IssuedReminderHeader);

        // [THEN] "AmtDueText" has value
        VerifyAmtDueTextAndRemaininAmt(IssuedReminderHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRemindersWhenLastIssuedReminderLevelIsSpecifiedStartingFromZero()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[3] of Code[20];
        ReminderPostingDate: array[3] of Date;
        InvoicePostingDate: array[3] of Date;
        Index: Integer;
    begin
        // [FEATURE] [Last Issued Reminder Level]
        // [SCENARIO 273651] Report "Create Reminders" respects "Last Issued Reminder Level" filter specified on request page for Cust. Ledger Entry when filter starts from '0'

        // [GIVEN] Customer with Reminder Terms having 3 levels
        PrepareInvoiceAndReminderPostingDates(InvoicePostingDate, ReminderPostingDate);
        Evaluate(WeekDateFormula, '<1W>');
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "Inv1" and issued reminder with level 2
        // [GIVEN] Posted invoice "Inv2" and issued reminder with level 1
        for Index := 1 to ArrayLen(InvoiceDocNo) - 1 do
            PrepareInvoiceAndReminder(Customer, InvoiceDocNo[Index], InvoicePostingDate[Index], ReminderPostingDate[Index]);

        // [GIVEN] Posted invoice "Inv3"
        InvoiceDocNo[3] := PostSalesInvoice(Customer."No.", InvoicePostingDate[3]);

        // [GIVEN] Specified filter "0|2" for "Last Issued Reminder Level" in Cust. Ledger Entry
        CustLedgerEntry.SetFilter("Last Issued Reminder Level", '0|2');

        // [WHEN] Run report "Create Reminders"
        RunCreateReminders(Customer, CustLedgerEntry, true, ReminderPostingDate[3]);

        // [THEN] Reminder lines for Invoices "Inv1" and "Inv3" are created but Reminder Line for "Inv2" is not created
        VerifyReminderLinePresentsForSalesInvoice(InvoiceDocNo[1]);
        VerifyReminderLinePresentsForSalesInvoice(InvoiceDocNo[3]);
        VerifyReminderLineNotPresentForSalesInvoice(InvoiceDocNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRemindersWhenLastIssuedReminderLevelIsSpecifiedNotStartingFromZero()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[3] of Code[20];
        ReminderPostingDate: array[3] of Date;
        InvoicePostingDate: array[3] of Date;
        Index: Integer;
    begin
        // [FEATURE] [Last Issued Reminder Level]
        // [SCENARIO 273651] Report "Create Reminders" respects "Last Issued Reminder Level" filter specified on request page for Cust. Ledger Entry when filter doesn't start from '0'

        // [GIVEN] Customer with Reminder Terms having 3 levels
        PrepareInvoiceAndReminderPostingDates(InvoicePostingDate, ReminderPostingDate);
        Evaluate(WeekDateFormula, '<1W>');
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "Inv1" and issued reminder with level 2
        // [GIVEN] Posted invoice "Inv2" and issued reminder with level 1
        for Index := 1 to ArrayLen(InvoiceDocNo) - 1 do
            PrepareInvoiceAndReminder(Customer, InvoiceDocNo[Index], InvoicePostingDate[Index], ReminderPostingDate[Index]);

        // [GIVEN] Posted invoice "Inv3"
        InvoiceDocNo[3] := PostSalesInvoice(Customer."No.", InvoicePostingDate[3]);

        // [GIVEN] Specified filter "1.." for "Last Issued Reminder Level" in Cust. Ledger Entry
        CustLedgerEntry.SetFilter("Last Issued Reminder Level", '1..');

        // [WHEN] Run report "Create Reminders"
        RunCreateReminders(Customer, CustLedgerEntry, true, ReminderPostingDate[3]);

        // [THEN] Reminder lines for Invoices "Inv1" and "Inv2" are created but Reminder Line for Invoice "Inv3" is not created
        VerifyReminderLinePresentsForSalesInvoice(InvoiceDocNo[1]);
        VerifyReminderLinePresentsForSalesInvoice(InvoiceDocNo[2]);
        VerifyReminderLineNotPresentForSalesInvoice(InvoiceDocNo[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssueReminderForMultipleInvoicesWithDifferentReminderLevels()
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        ReminderHeader: Record "Reminder Header";
        InvoicePostingDate: array[2] of Date;
        ReminderPostingDate: array[2] of Date;
        WeekDateFormula: DateFormula;
        InvoiceDocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 284335] When Invoice "Inv1" posted, Reminder "Rem1" for "Inv1" issued, Invoice "Inv2" posted, Reminder "Rem2" for "Inv1" and "Inv2" issued
        // [SCENARIO 284335] Reminder/Fin. Charge entry for invoice "Inv2" has Interest Posted set to 'FALSE'
        Initialize;
        Evaluate(WeekDateFormula, '<1W>');

        // [GIVEN] Customer with Reminder Terms having 2 levels and "Post Interest" enabled for second level
        CustomerNo := CreateCustomerWithPaymentReminderFinChargeTerms(WeekDateFormula);

        InvoicePostingDate[1] := WorkDate;
        InvoicePostingDate[2] := CalcDate(WeekDateFormula, InvoicePostingDate[1]);
        ReminderPostingDate[1] := CalcDate(WeekDateFormula, InvoicePostingDate[2]);
        ReminderPostingDate[2] := CalcDate(WeekDateFormula, ReminderPostingDate[1]) + 1;

        // [GIVEN] Posted invoice "Inv1" and issued Reminder "Rem1" with level 1
        PostSalesInvoice(CustomerNo, InvoicePostingDate[1]);
        CreateReminderForDate(ReminderHeader, CustomerNo, ReminderPostingDate[1]);
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN]  Posted invoice "Inv2" and created Reminder "Rem2" with level 2 for "Inv1" and level 1 for "Inv2"
        InvoiceDocumentNo := PostSalesInvoice(CustomerNo, InvoicePostingDate[2]);
        CreateReminderForDate(ReminderHeader, CustomerNo, ReminderPostingDate[2]);

        // [WHEN] Reminder issued
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [THEN] Reminder/Fin. Charge entry for invoice "Inv2" has Intereset Posted set to 'FALSE'
        ReminderFinChargeEntry.SetFilter("Document No.", InvoiceDocumentNo);
        ReminderFinChargeEntry.FindFirst;
        ReminderFinChargeEntry.TestField("Interest Posted", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesWithCorrectCalculationReminderLevel()
    var
        Customer: Record Customer;
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[3] of Code[20];
        ReminderPostingDate: array[3] of Date;
    begin
        // [FEATURE] [Payment Terms]
        Initialize;

        // [GIVEN] Reminder Terms "RT" with 3 levels where summary of "Due Date Calculation" = 3W
        // [GIVEN] Level[1] with "Grace Period" = 1W,"Due Date Calculation" = 1W, Fee = "F"
        // [GIVEN] Level[2] with "Grace Period" = <blank>,"Due Date Calculation" = 1W, Fee = 2*"F"
        // [GIVEN] Level[3] with "Grace Period" = <blank>,"Due Date Calculation" = 1W, Fee = 3*"F"
        // [GIVEN] Payment Terms "PT" where "Due Date Calculation" = 1W
        // [GIVEN] Customer "C" where "Payment Terms Code" = "PT" and "Reminder Terms Code" = "RT"
        Evaluate(WeekDateFormula, '<1W>');
        ReminderPostingDate[1] := CalcDate('<1M+5D>', WorkDate);
        ReminderPostingDate[2] := CalcDate('<1W+5D>', ReminderPostingDate[1]);
        ReminderPostingDate[3] := CalcDate('<1W>', ReminderPostingDate[2]);

        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "I[1]" for customer "C" where "Posting Date" = 01/01/17, "Due Date = 18/01/17
        InvoiceDocNo[1] := PostSalesInvoiceWithDueDate(Customer."No.", WorkDate, CalcDate('<2W+4D>', WorkDate));

        // [GIVEN] Posted invoice "I[2]" for customer "C" where "Posting Date" = 01/01/17, "Due Date = 12/02/17
        InvoiceDocNo[2] := PostSalesInvoiceWithDueDate(Customer."No.", WorkDate, CalcDate('<1M+1W+5D>', WorkDate));

        // [GIVEN] Issued reminder for invoice "I[1]" where "Posting Date" = 05/02/17
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[1]);
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN] Issued reminder for invoice "I[2]" where "Posting Date" = 17/02/17
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[2]);
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN] Reminder for customer "C" with "Posting Date" = 24/02/17
        // [WHEN] Run report "Create Reminders" where "Overdues Only" = FALSE
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[3]);

        ReminderLine.SetRange("Document No.", InvoiceDocNo[1]);
        ReminderLine.FindFirst;
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        ReminderHeader.FindFirst;
        ReminderHeader.CalcFields("Additional Fee");

        // [THEN] ReminderHeader."Reminder Level" is equal to 1.
        Assert.AreEqual(ReminderHeader."Reminder Level", 1, 'ReminderHeader."Reminder Level"');
    end;

    [Test]
    [HandlerFunctions('ReminderTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestReminderReportCalculateAmountCorrectly()
    var
        ReminderLine: array[2] of Record "Reminder Line";
        SalesLine: Record "Sales Line";
        ReminderHeader: Record "Reminder Header";
        DocumentNo: Code[20];
        RemainingAmount: Decimal;
        AdditionalFee: Decimal;
        InterestAmount: Decimal;
    begin
        // [SCENARIO 370031] Run report Reminder - Test for Reminder Header with additional fee
        Initialize();

        // [GIVEN] Created and posted Sales Invoice
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        InterestAmount := LibraryRandom.RandInt(10);

        // [GIVEN] Created Reminder Header and Line.
        CreateReminderHeader(ReminderHeader, SalesLine."Sell-to Customer No.");
        LibraryERM.CreateReminderLine(ReminderLine[1], ReminderHeader."No.", ReminderLine[1].Type::"Customer Ledger Entry");
        ReminderLine[1].Validate("Document No.", DocumentNo);
        ReminderLine[1].Validate(Amount, InterestAmount);
        ReminderLine[1].Modify(true);
        RemainingAmount := ReminderLine[1]."Remaining Amount";

        // [GIVEN] Created Reminder Line for additional fee
        LibraryERM.CreateReminderLine(ReminderLine[2], ReminderHeader."No.", ReminderLine[2].Type::"G/L Account");
        AdditionalFee := LibraryRandom.RandInt(10);
        ReminderLine[2].Validate(Amount, AdditionalFee);
        ReminderLine[2].Modify(true);
        Commit();

        // [WHEN] Run report 122 "Reminder - Test"
        ReminderHeader.SetRecFilter();
        ReminderHeader.PrintRecords();

        // [THEN] Check Total is equal to sum of Remaining amount, Interest amount and additional fee
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('NNC_TotalLCY', RemainingAmount + InterestAmount + AdditionalFee);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderInvoiceRoundingStatistics()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReminderStatistics: TestPage "Reminder Statistics";
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Invoice Rounding] [Statistics]
        // [SCENARIO 369814] Reminder Statistics with Invoice Rounding
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Reminder with G/L Accout Line = 1912.41
        CreateReminderHeader(ReminderHeader, CreateCustomer());
        CreateReminderLineForInvRounding(
            ReminderLine, ReminderHeader, GeneralLedgerSetup."Amount Rounding Precision");

        ReminderHeader.CalcFields("Additional Fee", "Interest Amount");
        TotalAmount := ReminderHeader."Additional Fee" + ReminderHeader."Interest Amount";

        // [WHEN] Reminder Statistics is opened
        ReminderStatistics.Trap();
        PAGE.RUN(PAGE::"Reminder Statistics", ReminderHeader);

        // [THEN] Invoice Rounding Amount = -0.01, Total = 1912.41 on Statistics page
        ReminderStatistics.ReminderTotal.AssertEquals(TotalAmount);
        ReminderStatistics.InvoiceRoundingAmount.AssertEquals(
            Round(TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)") - TotalAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyMsg')]
    [Scope('OnPrem')]
    procedure IssueReminderWithInvRoundingConfirmFalse()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 369814] Issue Reminder with Invoice Rounding confirmed No
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Reminder with G/L Account Line = 1912.41
        CreateReminderHeader(ReminderHeader, CreateCustomer());
        CreateReminderLineForInvRounding(
            ReminderLine, ReminderHeader, GeneralLedgerSetup."Amount Rounding Precision");

        // [WHEN] Confirm 'No' when issue Reminder
        LibraryVariableStorage.Enqueue(ProceedOnIssuingWithInvRoundingQst);
        LibraryVariableStorage.Enqueue(False);
        IssueReminder(ReminderHeader."No.");

        // [THEN] Reminder is not issued
        IssuedReminderHeader.SetRange("Customer No.", ReminderHeader."Customer No.");
        AssertError IssuedReminderHeader.FindFirst();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyMsg')]
    [Scope('OnPrem')]
    procedure IssueReminderWithInvRoundingConfirmTrue()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        InvRoundingAmountAmount: Decimal;
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 369814] Issue Finance Charge Memo with Invoice Rounding confirmed Yes
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Finance Charge Memo with G/L Accout Line = 1912.41
        CreateReminderHeader(ReminderHeader, CreateCustomer());
        CreateReminderLineForInvRounding(
            ReminderLine, ReminderHeader, GeneralLedgerSetup."Amount Rounding Precision");

        ReminderHeader.CalcFields("Additional Fee", "Interest Amount");
        InvRoundingAmountAmount := ReminderHeader."Additional Fee" + ReminderHeader."Interest Amount";
        InvRoundingAmountAmount :=
            Round(InvRoundingAmountAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)") - InvRoundingAmountAmount;

        // [WHEN] Confirm 'Yes' when issue Reminder
        LibraryVariableStorage.Enqueue(ProceedOnIssuingWithInvRoundingQst);
        LibraryVariableStorage.Enqueue(true);
        IssueReminder(ReminderHeader."No.");

        // [THEN] Invoice Rounding Amount is posted in issued reminder with Amount = -0.01
        IssuedReminderHeader.SetRange("Customer No.", ReminderHeader."Customer No.");
        IssuedReminderHeader.FindFirst();
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.SetFilter("No.", '<>%1', ReminderLine."No.");
        IssuedReminderLine.FindFirst();
        IssuedReminderLine.TestField(Amount, InvRoundingAmountAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Invoice and Reminder");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Invoice and Reminder");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Invoice and Reminder");
    end;

    local procedure PrepareInvoiceAndReminderPostingDates(var InvoicePostingDate: array[3] of Date; var ReminderPostingDate: array[3] of Date)
    begin
        InvoicePostingDate[1] := WorkDate;
        InvoicePostingDate[2] := CalcDate('<1W>', InvoicePostingDate[1]) - 1;
        InvoicePostingDate[3] := CalcDate('<1W>', InvoicePostingDate[2]) - 1;
        ReminderPostingDate[1] := CalcDate('<3W+1D>', WorkDate);
        ReminderPostingDate[2] := CalcDate('<1W+1D>', ReminderPostingDate[1]);
        ReminderPostingDate[3] := CalcDate('<1W+1D>', ReminderPostingDate[2]);
    end;

    local procedure PrepareInvoiceAndReminder(var Customer: Record Customer; var PostedInvNo: Code[20]; InvoicePostingDate: Date; ReminderPostingDate: Date)
    var
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        PostedInvNo := PostSalesInvoice(Customer."No.", InvoicePostingDate);
        RunCreateReminders(Customer, DummyCustLedgerEntry, true, ReminderPostingDate);
        VerifyReminderLineTypeForDocument(ReminderLine, PostedInvNo, ReminderLine."Line Type"::"Reminder Line");
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // Take Random Quantity for Sales Line.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    [Normal]
    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CreateCurrency);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithPaymentAndReminderTerms(var Customer: Record Customer; WeekDateFormula: DateFormula)
    var
        ReminderTerms: Record "Reminder Terms";
        PaymentTerms: Record "Payment Terms";
        BlankDateFormula: DateFormula;
        FeeAmount: Decimal;
    begin
        FeeAmount := LibraryRandom.RandDecInRange(5, 10, 2);

        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevelDueDateCalculation(ReminderTerms.Code, WeekDateFormula, WeekDateFormula, FeeAmount);
        CreateReminderLevelDueDateCalculation(ReminderTerms.Code, BlankDateFormula, WeekDateFormula, FeeAmount * 2);
        CreateReminderLevelDueDateCalculation(ReminderTerms.Code, BlankDateFormula, WeekDateFormula, FeeAmount * 3);

        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Due Date Calculation", WeekDateFormula);
        PaymentTerms.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Modify(true);

        Customer.SetRecFilter;
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerWithPaymentReminderFinChargeTerms(DueDateFormula: DateFormula): Code[20]
    var
        Customer: Record Customer;
        ReminderTermsCode: Code[10];
        FinanceChargeTermsCode: Code[10];
        PaymentTermsCode: Code[10];
    begin
        FinanceChargeTermsCode := CreateFinanceChargeTerms(DueDateFormula);
        ReminderTermsCode := CreateReminderTermsAndLevels(DueDateFormula);
        PaymentTermsCode := CreatePaymentTerms(DueDateFormula);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateFinanceChargeTerms(DueDateFormula: DateFormula): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandInt(10));
        FinanceChargeTerms.Validate("Interest Period (Days)", 365);
        FinanceChargeTerms.Validate("Due Date Calculation", DueDateFormula);
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentTerms(DueDateFormula: DateFormula): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Due Date Calculation", DueDateFormula);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateReminderForDate(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20]; PostingAndDocumentDate: Date)
    var
        SuggestReminderLines: Report "Suggest Reminder Lines";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Posting Date", PostingAndDocumentDate);
        ReminderHeader.Validate("Document Date", PostingAndDocumentDate);
        ReminderHeader.Modify(true);

        ReminderHeader.SetRange("No.", ReminderHeader."No.");
        SuggestReminderLines.SetTableView(ReminderHeader);
        SuggestReminderLines.UseRequestPage(false);
        SuggestReminderLines.Run;

        ReminderHeader.SetRecFilter;
    end;

    local procedure CreateReminderTerms(): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevel(ReminderTerms.Code);
        exit(ReminderTerms.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateReminderTermsAndLevels(DueDateFormula: DateFormula): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Interest", true);
        ReminderTerms.Modify(true);

        CreateReminderLevelWithCalculateInterest(ReminderTerms.Code, DueDateFormula, false);
        CreateReminderLevelWithCalculateInterest(ReminderTerms.Code, DueDateFormula, true);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateReminderLevel(ReminderTermsCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderLevelDueDateCalculation(ReminderTermsCode: Code[10]; GraceFormula: DateFormula; DueFormula: DateFormula; FeeAmount: Decimal)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        ReminderLevel.Validate("Grace Period", GraceFormula);
        ReminderLevel.Validate("Due Date Calculation", DueFormula);
        ReminderLevel.Validate("Additional Fee (LCY)", FeeAmount);
        ReminderLevel.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateReminderLevelWithCalculateInterest(ReminderTermsCode: Code[10]; DueDateFormula: DateFormula; CalculateInterest: Boolean)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        ReminderLevel.Validate("Due Date Calculation", DueDateFormula);
        ReminderLevel.Validate("Calculate Interest", CalculateInterest);
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderHeader(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Reminder Nos." = '' then
            SalesReceivablesSetup.Validate("Reminder Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup."Issued Reminder Nos." := SalesReceivablesSetup."Reminder Nos.";
        SalesReceivablesSetup.Modify();

        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Modify(true);
    end;

    local procedure CreateReminderLine(ReminderHeaderNo: Code[20]; DocumentNo: Code[20]): Decimal
    var
        ReminderLine: Record "Reminder Line";
    begin
        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeaderNo, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.Validate("Document No.", DocumentNo);
        ReminderLine.Modify(true);
        exit(ReminderLine."Remaining Amount");
    end;

    local procedure CreateReminderLineForInvRounding(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header"; AmountRoundingPrecision: Decimal)
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateReminderLine(
          ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account");

        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup);
        GenProductPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, ReminderHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Prod. Posting Group";
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);

        ReminderLine.Validate("No.", GLAccount."No.");
        ReminderLine.Validate(
          Amount,
          (LibraryRandom.RandIntInRange(10000, 20000) * 10 + 1) * AmountRoundingPrecision);
        ReminderLine.Modify(true);
    end;

    local procedure IssueReminder(ReminderNo: Code[20])
    var
        ReminderHeader: Record "Reminder Header";
        IssueReminders: Report "Issue Reminders";
    begin
        ReminderHeader.SetRange("No.", ReminderNo);
        Clear(IssueReminders);
        IssueReminders.SetTableView(ReminderHeader);
        IssueReminders.UseRequestPage(false);
        IssueReminders.Run();
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedReminderHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedReminderHeader.Insert();
        IssuedReminderLine.Init();
        IssuedReminderLine."Line No." := LibraryUtility.GetNewRecNo(IssuedReminderLine, IssuedReminderLine.FieldNo("Line No."));
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine."Due Date" := IssuedReminderHeader."Due Date";
        IssuedReminderLine."Remaining Amount" := LibraryRandom.RandIntInRange(10, 100);
        IssuedReminderLine.Amount := IssuedReminderLine."Remaining Amount";
        IssuedReminderLine.Type := IssuedReminderLine.Type::"G/L Account";
        IssuedReminderLine.Insert();
    end;

    local procedure ModifyReminderHeader(var ReminderHeader: Record "Reminder Header")
    begin
        ReminderHeader.Validate("Currency Code", CreateCurrency);
        ReminderHeader.Modify(true);
    end;

    local procedure PostSalesInvoice(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure RunCreateReminders(var Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; OverdueEntriesOnly: Boolean; ReminderPostingDate: Date)
    var
        CreateReminders: Report "Create Reminders";
    begin
        CreateReminders.SetTableView(CustLedgerEntry);
        CreateReminders.SetTableView(Customer);
        CreateReminders.InitializeRequest(ReminderPostingDate, ReminderPostingDate, OverdueEntriesOnly, false, false);
        CreateReminders.UseRequestPage(false);
        CreateReminders.Run;
    end;

    local procedure UpdateGLSetupInvRoundingPrecision()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.SetInvRoundingPrecisionLCY(GeneralLedgerSetup."Amount Rounding Precision" * 10);
    end;

    local procedure VerifyReminderLineTypeForDocument(var ReminderLine: Record "Reminder Line"; DocumentNo: Code[20]; ExpectedReminderLineType: Enum "Reminder Line Type")
    begin
        ReminderLine.SetRange("Document No.", DocumentNo);
        ReminderLine.FindFirst;
        ReminderLine.TestField("Line Type", ExpectedReminderLineType);
    end;

    local procedure VerifyReminderLinePresentsForSalesInvoice(DocumentNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.SetRange("Document No.", DocumentNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
        Assert.RecordCount(ReminderLine, 1);
    end;

    local procedure VerifyReminderLineNotPresentForSalesInvoice(DocumentNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.SetRange("Document No.", DocumentNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
        Assert.RecordIsEmpty(ReminderLine);
    end;

    local procedure VerifyAmtDueTextAndRemaininAmt(IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        LibraryReportDataset.LoadDataSetFile;
        IssuedReminderHeader.CalcFields("Remaining Amount");
        LibraryReportDataset.AssertElementWithValueExists('RemainingAmountText', Format(IssuedReminderHeader."Remaining Amount"));
        LibraryReportDataset.AssertElementWithValueExists('AmtDueText', StrSubstNo(AmtDueLbl, IssuedReminderHeader."Due Date"));
    end;

    local procedure PostSalesInvoiceWithDueDate(CustomerNo: Code[20]; PostingDate: Date; DueDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Due Date", DueDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerifyMsg(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    begin
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderTestRequestPageHandler(var ReminderTest: TestRequestPage "Reminder - Test")
    begin
        ReminderTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

