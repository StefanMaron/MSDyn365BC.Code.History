codeunit 144401 "Sales Advances"
{
    // // [FEATURE] [Sales]
    // Test Cases for Sales Advance
    // 1. Test if the system allows to create a new Sales Advance Letter.
    // 2. Test if the system allows to create a new Sales Advance Letter from Sales order.
    // 3. Test the release of Sales Advance Letter.
    // 4. Test if the system allows to automatical create a new Sales Advance Invoice from Sales Advance Letter.
    // 5. Test the posting of Sales Order from which Sales Advance Letter was creation.
    // 6. Test creation Sales Advance Letter with foreign currency and posting payment.
    //   Test the changing exchange rate on Sales Advance Letter.
    // 7. Test the posting Sales Invoice which was created from Sales Advance Letter with foreign currency.
    // 8. Test the posting refund and close Sales Advance Letter with foreign currency.
    // 9. Test the creation Sales Advance Letter with refund VAT.
    // 10. Test if the system allows to manual create a new Sales Advance Invoice from Sales Advance Letter.
    // 11. Test the posting of Sales Invoice which was created from Sales Advance Letter.
    // 12. Test the posting refund and close Sales Advance Letter.
    // 13. Test the posting Sales Advance Letter over two Sales Invoice.
    // 14. Test the posting two Sales Advance Letter over one Sales Invoice.
    // 15. Test the canceling Sales Advance Letter.
    // 16. Test the canceling Sales Advance Letter with payment.
    // 17. Test the posting Sales Advance Letter over two Payments.

    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryAdvance: Codeunit "Library - Advance";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        NotExistEnoughRecErr: Label 'Not exist enough of %1.', Comment = '%1=TABLECAPTION';
        ExistErr: Label '%1 is exist.', Comment = '%1=TABLECAPTION';

    [Test]
    [Scope('OnPrem')]
    procedure CreationSalesAdvLetter()
    var
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
    begin
        // Test if the system allows to create a new Sales Advance Letter.

        // 1.Setup:
        Initialize;

        // 2.Exercise:

        // create Salesase advance letter
        CreateSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        // 3.Verify:

        // verify creation sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationSalesAdvLetterFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
    begin
        // Test if the system allows to create a new Sales Advance Letter from Sales order.

        // 1.Setup:
        Initialize;

        // create sales order
        CreateSalesOrder(SalesHeader, SalesLine);

        // 2.Exercise:

        // crate sales advance letter from sales order
        CreateSalesAdvLetterFromSalesDoc(SalesAdvLetterHeader, SalesHeader);

        // 3.Verify:

        // verify creation sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckReleaseSalesAdvLetter()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
    begin
        // Test the release of Sales Advance Letter.

        // 1.Setup:
        Initialize;

        // create sales advance letter from sales order
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateSalesAdvLetterFromSalesDoc(SalesAdvLetterHeader, SalesHeader);

        // 2.Exercise:
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);

        // 3.Verify:

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::"Pending Payment");
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentAndAutomaticCreationAdvanceInvoice()
    var
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesInvHeader: Record "Sales Invoice Header";
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Test if the system allows to automatical create a new Sales Advance Invoice from Sales Advance Letter.

        // 1.Setup:
        Initialize;

        // create sales advance letter
        CreateAndReleaseSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        AmountIncVAT := SalesAdvLetterLine."Amount Including VAT";
        VATAmount := SalesAdvLetterLine."VAT Amount";

        // 2.Exercise:

        // create and post payment
        CreateAndPostPaymentSalesAdvLetter(SalesAdvLetterHeader, -SalesAdvLetterLine."Amount Including VAT");

        // 3.Verify:

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::"Pending Final Invoice");

        SalesAdvLetterLine.Get(SalesAdvLetterLine."Letter No.", SalesAdvLetterLine."Line No.");
        SalesAdvLetterLine.TestField("Amount Linked", AmountIncVAT);
        SalesAdvLetterLine.TestField("Amount Invoiced", AmountIncVAT);
        SalesAdvLetterLine.TestField("Amount To Deduct", AmountIncVAT);

        // verify creation sales advance invoice
        SalesInvHeader.SetCurrentKey("Letter No.");
        SalesInvHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesInvHeader.FindFirst;
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvHeader.TestField(Amount, VATAmount);
        SalesInvHeader.TestField("Amount Including VAT", VATAmount);
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PostSalesAdvLetterFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        VariantAmount: Variant;
        PostedDocNo: Code[20];
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        SalesOrderStatAmounts: array[3] of Decimal;
    begin
        // Test the posting of Sales Order from which Sales Advance Letter was creation.

        // 1.Setup:
        Initialize;

        // create sales advance letter
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateSalesAdvLetterFromSalesDoc(SalesAdvLetterHeader, SalesHeader);
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);

        Amount := SalesLine.Amount;
        AmountIncVAT := SalesLine."Amount Including VAT";
        VATAmount := AmountIncVAT - Amount;

        // create and post payment
        SalesAdvLetterLine.Init;
        CreateAndPostPaymentSalesAdvLetter(SalesAdvLetterHeader, -SalesAdvLetterLine."Amount Including VAT");

        // get amounts from statistics of sales order
        OpenSalesOrderStatistics(SalesHeader);
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesOrderStatAmounts[1] := VariantAmount; // Amount including VAT
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesOrderStatAmounts[2] := VariantAmount; // VAT Amount
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesOrderStatAmounts[3] := VariantAmount; // Amount

        // 2.Exercise:

        // post sales order
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        PostedDocNo := PostSalesDocument(SalesHeader);

        // 3.Verify:

        // verify statistics of sales order
        Assert.AreNearlyEqual(-AmountIncVAT, SalesOrderStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount, SalesOrderStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount, SalesOrderStatAmounts[3], 0.01, '');

        // verify sales advance letter
        VerifySalesAdvLetter(SalesAdvLetterHeader."No.", SalesAdvLetterHeader.Status::Closed, AmountIncVAT);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::Deduction);
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(SalesAdvLetterEntry.Amount, AmountIncVAT, 0.01, '');

        // verify creation advance invoice
        SalesInvHeader.Get(PostedDocNo);
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvHeader.TestField(Amount, 0);
        SalesInvHeader.TestField("Amount Including VAT", 0);
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,ChangeExchangeRateHandler')]
    [Scope('OnPrem')]
    procedure SalesAdvLetterWithForeignCurrency()
    var
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        SalesInvHeader: Record "Sales Invoice Header";
        CurrExchangeRate: Record "Currency Exchange Rate";
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        CurrencyFactor: Decimal;
    begin
        // Test creation Sales Advance Letter with foreign currency and posting payment.
        // Test the changing exchange rate on Sales Advance Letter.

        // 1.Setup:
        Initialize;

        // find foreign currency
        FindForeignCurrency(Currency);

        // create sales advance letter
        CreateSalesAdvLetterWithCurrency(SalesAdvLetterHeader, SalesAdvLetterLine, Currency.Code);
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);

        Amount := SalesAdvLetterLine.Amount;
        AmountIncVAT := SalesAdvLetterLine."Amount Including VAT";
        VATAmount := SalesAdvLetterLine."VAT Amount";

        // create payment
        CreateGenJournalLine(GenJournalLine, SalesAdvLetterHeader."Bill-to Customer No.", -SalesAdvLetterLine."Amount Including VAT");
        GenJournalLine.Validate("Currency Code", Currency.Code);
        GenJournalLine.Modify(true);
        ChangeExchangeRateOnGenJnlLine(GenJournalLine, 0.6);
        GenJournalLine.Modify(true);
        CurrencyFactor := GenJournalLine."Currency Factor";
        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, SalesAdvLetterHeader."No.");

        // 2.Exercise:

        // post payment
        PostGenJournalLine(GenJournalLine);

        // 3.Verify:

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::"Pending Final Invoice");

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount Linked", AmountIncVAT);
        SalesAdvLetterLine.TestField("Amount Invoiced", AmountIncVAT);
        SalesAdvLetterLine.TestField("Amount To Deduct", AmountIncVAT);

        // verify creation advance invoice
        SalesInvHeader.SetCurrentKey("Letter No.");
        SalesInvHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesInvHeader.FindFirst;
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvHeader.TestField(Amount, VATAmount);
        SalesInvHeader.TestField("Amount Including VAT", VATAmount);
        SalesInvHeader.TestField("Currency Code", Currency.Code);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::VAT);
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount", -Amount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount", -VATAmount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount (LCY)",
          -Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              SalesAdvLetterHeader."Posting Date", SalesAdvLetterHeader."Currency Code",
              Amount, CurrencyFactor),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount (LCY)",
          -Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              SalesAdvLetterHeader."Posting Date", SalesAdvLetterHeader."Currency Code",
              VATAmount, CurrencyFactor),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,ChangeExchangeRateHandler,SalesAdvLetterLinkCardHandler,SalesLetHeaderAdvLinkHandler,MessageHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PostSalesAdvLetterWithForeignCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        SalesInvHeader: Record "Sales Invoice Header";
        CurrExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
        VariantAmount: Variant;
        PostedDocNo: Code[20];
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        CurrencyFactor: array[2] of Decimal;
        SalesInvStatAmounts: array[3] of Decimal;
    begin
        // Test the posting Sales Invoice which was created from Sales Advance Letter with foreign currency.

        // 1.Setup:
        Initialize;

        // find foreign currency
        FindForeignCurrency(Currency);

        // create sales advance letter
        CreateSalesAdvLetterWithCurrency(SalesAdvLetterHeader, SalesAdvLetterLine, Currency.Code);
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);

        Amount := SalesAdvLetterLine.Amount;
        AmountIncVAT := SalesAdvLetterLine."Amount Including VAT";
        VATAmount := SalesAdvLetterLine."VAT Amount";

        // create payment
        CreateGenJournalLine(GenJournalLine, SalesAdvLetterHeader."Bill-to Customer No.", SalesAdvLetterLine."Amount Including VAT");
        GenJournalLine.Validate("Currency Code", Currency.Code);
        ChangeExchangeRateOnGenJnlLine(GenJournalLine, 0.6);
        GenJournalLine.Modify(true);
        CurrencyFactor[1] := GenJournalLine."Currency Factor";
        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, SalesAdvLetterHeader."No.");

        // post payment
        PostGenJournalLine(GenJournalLine);

        // create sales invoice
        CreateSalesInvoiceFromSalesAdvLetter(SalesHeader, SalesLine, SalesAdvLetterHeader, SalesAdvLetterLine, Currency.Code, 0.7);
        CurrencyFactor[2] := SalesHeader."Currency Factor";

        // link advance letter to sales invoice
        LinkAdvanceLetterToSalesDocument(SalesHeader, SalesAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of sales invoice
        OpenSalesInvoiceStatistics(SalesHeader);
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesInvStatAmounts[1] := VariantAmount; // Amount including VAT
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesInvStatAmounts[2] := VariantAmount; // VAT Amount
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesInvStatAmounts[3] := VariantAmount; // Amount

        // 2.Exercise:
        PostedDocNo := PostSalesDocument(SalesHeader);

        // 3.Verify:

        // verify statistics of sales invoice
        Assert.AreNearlyEqual(-AmountIncVAT, SalesInvStatAmounts[1], Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(-VATAmount, SalesInvStatAmounts[2], Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(-Amount, SalesInvStatAmounts[3], Currency."Amount Rounding Precision", '');

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount Deducted", AmountIncVAT);

        // verify creation sales invoice
        SalesInvHeader.Get(PostedDocNo);
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvHeader.TestField(Amount, 0);
        SalesInvHeader.TestField("Amount Including VAT", 0);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::Deduction);
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(SalesAdvLetterEntry.Amount, AmountIncVAT, Currency."Amount Rounding Precision", '');

        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::"VAT Deduction");
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", Amount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", VATAmount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount (LCY)",
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              SalesInvHeader."Posting Date", SalesInvHeader."Currency Code",
              Amount, CurrencyFactor[2]),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount (LCY)",
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              SalesInvHeader."Posting Date", SalesInvHeader."Currency Code",
              VATAmount, CurrencyFactor[2]),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');

        // verify different currency factor
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", SalesInvHeader."No.");
        GLEntry.SetRange("Posting Date", SalesInvHeader."Posting Date");
        GLEntry.SetRange("G/L Account No.", Currency."Realized Losses Acc.");
        GLEntry.FindFirst;
        Assert.AreNearlyEqual(GLEntry.Amount,
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              SalesAdvLetterHeader."Posting Date", SalesAdvLetterHeader."Currency Code",
              AmountIncVAT, CurrencyFactor[2]),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection) -
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              SalesInvHeader."Posting Date", SalesInvHeader."Currency Code",
              AmountIncVAT, CurrencyFactor[1]),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,ChangeExchangeRateHandler,SalesAdvLetterLinkCardHandler,SalesLetHeaderAdvLinkHandler,MessageHandler,YesConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOverpaymentAdvancesWithForeignCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        Currency: Record Currency;
        CurrExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        VariantAmount: Variant;
        Amount: array[2] of Decimal;
        AmountIncVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        SalesInvStatAmounts: array[5] of Decimal;
    begin
        // Test the posting refund and close Sales Advance Letter with foreign currency.

        // 1.Setup:
        Initialize;

        // find foreign currency
        FindForeignCurrency(Currency);

        // create sales advance letter
        CreateSalesAdvLetterWithCurrency(SalesAdvLetterHeader, SalesAdvLetterLine, Currency.Code);
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);

        Amount[1] := SalesAdvLetterLine.Amount;
        AmountIncVAT[1] := SalesAdvLetterLine."Amount Including VAT";
        VATAmount[1] := SalesAdvLetterLine."VAT Amount";

        // create payment
        CreateGenJournalLine(GenJournalLine, SalesAdvLetterHeader."Bill-to Customer No.", -SalesAdvLetterLine."Amount Including VAT");
        GenJournalLine.Validate("Currency Code", Currency.Code);
        ChangeExchangeRateOnGenJnlLine(GenJournalLine, 0.6);
        GenJournalLine.Modify(true);

        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, SalesAdvLetterHeader."No.");

        // post payment
        PostGenJournalLine(GenJournalLine);

        // create sales invoice
        CreateSalesInvoiceFromSalesAdvLetter(SalesHeader, SalesLine, SalesAdvLetterHeader, SalesAdvLetterLine, Currency.Code, 0.7);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(Round(Amount[1], 1, '<') - 1, 2));
        SalesLine.Modify(true);

        Amount[2] := SalesLine.Amount;
        AmountIncVAT[2] := SalesLine."Amount Including VAT";
        VATAmount[2] := AmountIncVAT[2] - Amount[2];

        // link advance letter to sales invoice
        LinkAdvanceLetterToSalesDocument(SalesHeader, SalesAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of sales invoice
        OpenSalesInvoiceStatistics(SalesHeader);
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesInvStatAmounts[1] := VariantAmount; // Amount including VAT
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesInvStatAmounts[2] := VariantAmount; // VAT Amount
        LibraryVariableStorage.Dequeue(VariantAmount);
        SalesInvStatAmounts[3] := VariantAmount; // Amount

        // post sales invoice
        PostSalesDocument(SalesHeader);

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(SalesAdvLetterHeader);

        // 3.Verify:

        // verify statistics of sales invoice
        Assert.AreNearlyEqual(-AmountIncVAT[2], SalesInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount[2], SalesInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount[2], SalesInvStatAmounts[3], 0.01, '');

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Deduct", 0);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Document Type", SalesAdvLetterEntry."Document Type"::"Credit Memo");
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount", Amount[1] - Amount[2], Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount", VATAmount[1] - VATAmount[2], Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount (LCY)",
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              SalesAdvLetterHeader."Posting Date", SalesAdvLetterHeader."Currency Code",
              SalesAdvLetterEntry."VAT Base Amount", CurrExchangeRate.GetCurrentCurrencyFactor(SalesAdvLetterHeader."Currency Code")),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount (LCY)",
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              SalesAdvLetterHeader."Posting Date", SalesAdvLetterHeader."Currency Code",
              SalesAdvLetterEntry."VAT Amount", CurrExchangeRate.GetCurrentCurrencyFactor(SalesAdvLetterHeader."Currency Code")),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');

        // verify creation sales credit memo
        SalesCrMemoHeader.SetCurrentKey("Letter No.");
        SalesCrMemoHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesCrMemoHeader.FindFirst;
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler')]
    [Scope('OnPrem')]
    procedure SalesAdvLetterWithRefundVAT()
    var
        SalesAdvPmntTemp: Record "Sales Adv. Payment Template";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvHeader: Record "Sales Invoice Header";
        Amount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Test the creation Sales Advance Letter with refund VAT.

        // 1.Setup:
        Initialize;

        // create sales advance letter
        CreateSalesAdvPmntTemp(SalesAdvPmntTemp);
        FindVATPostingSetupEU(VATPostingSetup);
        CreateSalesAdvLetterWithVATPostingSetup(
          SalesAdvLetterHeader, SalesAdvLetterLine, SalesAdvPmntTemp.Code, VATPostingSetup);
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);

        Amount := SalesAdvLetterLine.Amount;
        AmountIncVAT := SalesAdvLetterLine."Amount Including VAT";

        // create payment
        CreateGenJournalLine(GenJournalLine, SalesAdvLetterHeader."Bill-to Customer No.", -SalesAdvLetterLine."Amount Including VAT");
        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, SalesAdvLetterHeader."No.");

        // 2.Exercise:

        // post payment
        PostGenJournalLine(GenJournalLine);

        // 3.Verify:

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::"Pending Final Invoice");

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Deduct", AmountIncVAT);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::VAT);
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", -Amount, 0.01, '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", 0, 0.01, '');

        // verify creation advance invoice
        SalesInvHeader.SetCurrentKey("Letter No.");
        SalesInvHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesInvHeader.FindFirst;
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvHeader.TestField(Amount, 0);
        SalesInvHeader.TestField("Amount Including VAT", 0);
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentAndManualCreationAdvanceInvoice()
    var
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesInvHeader: Record "Sales Invoice Header";
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Test if the system allows to automatical create a new Sales Advance Invoice from Sales Advance Letter.

        // 1.Setup:
        Initialize;

        // disable automatic advance invoice posting
        UpdateSalesSetupAutomaticAdvInvPosting(false);

        // create sales advance letter
        CreateAndPaymentSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        AmountIncVAT := SalesAdvLetterLine."Amount Including VAT";
        VATAmount := SalesAdvLetterLine."VAT Amount";

        // 2.Exercise:

        // post advance invoce
        PostAdvanceInvoice(SalesAdvLetterHeader);

        // 3.Verify:

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::"Pending Final Invoice");

        SalesAdvLetterLine.Get(SalesAdvLetterLine."Letter No.", SalesAdvLetterLine."Line No.");
        SalesAdvLetterLine.TestField("Amount Linked", AmountIncVAT);
        SalesAdvLetterLine.TestField("Amount Invoiced", AmountIncVAT);
        SalesAdvLetterLine.TestField("Amount To Deduct", AmountIncVAT);

        // verify creation sales advance invoice
        SalesInvHeader.SetCurrentKey("Letter No.");
        SalesInvHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesInvHeader.FindFirst;
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvHeader.TestField(Amount, VATAmount);
        SalesInvHeader.TestField("Amount Including VAT", VATAmount);

        // 4.Teardown:

        // enable automatic advance invoice posting
        UpdateSalesSetupAutomaticAdvInvPosting(true);
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,SalesAdvLetterLinkCardHandler,SalesLetHeaderAdvLinkHandler,MessageHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PostSalesAdvLetterWithConnectedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        PostedDocNo: Code[20];
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        SalesInvStatAmounts: array[20] of Decimal;
    begin
        // Test the posting of Sales Invoice which was created from Sales Advance Letter.

        // 1.Setup:
        Initialize;

        // create and payment sales advance letter
        CreateAndPaymentSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        Amount := SalesAdvLetterLine.Amount;
        AmountIncVAT := SalesAdvLetterLine."Amount Including VAT";
        VATAmount := SalesAdvLetterLine."VAT Amount";

        // create sales invoice
        CreateSalesInvoiceFromSalesAdvLetter(SalesHeader, SalesLine, SalesAdvLetterHeader, SalesAdvLetterLine, '', 0);

        // link advance letter to sales invoice
        LinkAdvanceLetterToSalesDocument(SalesHeader, SalesAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of sales invoice
        GetSalesInvoiceStatistics(SalesHeader, SalesInvStatAmounts);

        // 2.Exercise:
        PostedDocNo := PostSalesDocument(SalesHeader);

        // 3.Verify:

        // verify statistics of sales order
        Assert.AreNearlyEqual(-AmountIncVAT, SalesInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount, SalesInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount, SalesInvStatAmounts[3], 0.01, '');

        // verify sales advance letter
        VerifySalesAdvLetter(SalesAdvLetterHeader."No.", SalesAdvLetterHeader.Status::Closed, AmountIncVAT);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::Deduction);
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(SalesAdvLetterEntry.Amount, AmountIncVAT, 0.01, '');

        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::"VAT Deduction");
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", Amount, 0.01, '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", VATAmount, 0.01, '');

        // verify creation advance invoice
        SalesInvHeader.Get(PostedDocNo);
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvHeader.TestField(Amount, 0);
        SalesInvHeader.TestField("Amount Including VAT", 0);
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,SalesAdvLetterLinkCardHandler,SalesLetHeaderAdvLinkHandler,MessageHandler,SalesStatisticsHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReturnOverpayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        Amount: array[2] of Decimal;
        AmountIncVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        SalesInvStatAmounts: array[20] of Decimal;
    begin
        // Test the posting refund and close Sales Advance Letter.

        // 1.Setup:
        Initialize;

        // create and payment sales advance letter
        CreateAndPaymentSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        Amount[1] := SalesAdvLetterLine.Amount;
        AmountIncVAT[1] := SalesAdvLetterLine."Amount Including VAT";
        VATAmount[1] := SalesAdvLetterLine."VAT Amount";

        // create sales invoice
        CreateSalesInvoiceFromSalesAdvLetter(SalesHeader, SalesLine, SalesAdvLetterHeader, SalesAdvLetterLine, '', 0);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(Round(Amount[1], 1, '<') - 1, 2));
        SalesLine.Modify(true);

        Amount[2] := SalesLine.Amount;
        AmountIncVAT[2] := SalesLine."Amount Including VAT";
        VATAmount[2] := AmountIncVAT[2] - Amount[2];

        // link advance letter to sales invoice
        LinkAdvanceLetterToSalesDocument(SalesHeader, SalesAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of sales invoice
        GetSalesInvoiceStatistics(SalesHeader, SalesInvStatAmounts);

        // post sales invoice
        PostSalesDocument(SalesHeader);

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(SalesAdvLetterHeader);

        // 3.Verify:

        // verify statistics of sales invoice
        Assert.AreNearlyEqual(-AmountIncVAT[2], SalesInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount[2], SalesInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount[2], SalesInvStatAmounts[3], 0.01, '');

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Deduct", 0);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Document Type", SalesAdvLetterEntry."Document Type"::"Credit Memo");
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount", Amount[1] - Amount[2], 0.01, '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount", VATAmount[1] - VATAmount[2], 0.01, '');

        // verify creation sales credit memo
        SalesCrMemoHeader.SetCurrentKey("Letter No.");
        SalesCrMemoHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesCrMemoHeader.FindFirst;
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,SalesAdvLetterLinkCardHandler,SalesLetHeaderAdvLinkHandler,MessageHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PartialPostingSalesAdvLetter()
    var
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        AdvLetterLineRel: Record "Advance Letter Line Relation";
        Amount: array[3] of Decimal;
        AmountIncVAT: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        SalesInvStatAmounts: array[2, 20] of Decimal;
    begin
        // Test the posting Sales Advance Letter over two Sales Invoice

        // 1.Setup:
        Initialize;

        // create and payment sales advance letter
        CreateAndPaymentSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        Amount[1] := SalesAdvLetterLine.Amount;
        AmountIncVAT[1] := SalesAdvLetterLine."Amount Including VAT";
        VATAmount[1] := SalesAdvLetterLine."VAT Amount";

        // create sales invoice 1
        CreateSalesInvoice(
          SalesHeader[1], SalesLine[1],
          SalesAdvLetterHeader."Bill-to Customer No.",
          SalesAdvLetterHeader."Posting Date",
          SalesAdvLetterLine."VAT Bus. Posting Group",
          SalesAdvLetterLine."VAT Prod. Posting Group",
          '', 0, false,
          LibraryRandom.RandDec(Round(Amount[1], 1, '<'), 2));

        Amount[2] := SalesLine[1].Amount;
        AmountIncVAT[2] := SalesLine[1]."Amount Including VAT";
        VATAmount[2] := AmountIncVAT[2] - Amount[2];

        // link advance letter to Sales invoice 1
        LinkAdvanceLetterToSalesDocument(SalesHeader[1], SalesAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of sales invoice 1
        GetSalesInvoiceStatistics(SalesHeader[1], SalesInvStatAmounts[1]);

        // create sales invoice 2
        CreateSalesInvoice(
          SalesHeader[2], SalesLine[2],
          SalesAdvLetterHeader."Bill-to Customer No.",
          SalesAdvLetterHeader."Posting Date",
          SalesAdvLetterLine."VAT Bus. Posting Group",
          SalesAdvLetterLine."VAT Prod. Posting Group",
          '', 0, true,
          AmountIncVAT[1] - AmountIncVAT[2]);

        Amount[3] := SalesLine[2].Amount;
        AmountIncVAT[3] := SalesLine[2]."Amount Including VAT";
        VATAmount[3] := AmountIncVAT[3] - Amount[3];

        // link advance letter to sales invoice 2
        LinkAdvanceLetterToSalesDocument(SalesHeader[2], SalesAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of sales invoice 2
        GetSalesInvoiceStatistics(SalesHeader[2], SalesInvStatAmounts[2]);

        // 2.Exercise:

        // post sales invoice 1
        PostSalesDocument(SalesHeader[1]);

        // post sales invoice 2
        PostSalesDocument(SalesHeader[2]);

        // 3.Verify:

        // verify statistics of sales invoice 1
        Assert.AreNearlyEqual(-AmountIncVAT[2], SalesInvStatAmounts[1] [1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount[2], SalesInvStatAmounts[1] [2], 0.01, '');
        Assert.AreNearlyEqual(-Amount[2], SalesInvStatAmounts[1] [3], 0.01, '');

        // verify statistics of sales invoice 2
        Assert.AreNearlyEqual(-AmountIncVAT[3], SalesInvStatAmounts[2] [1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount[3], SalesInvStatAmounts[2] [2], 0.01, '');
        Assert.AreNearlyEqual(-Amount[3], SalesInvStatAmounts[2] [3], 0.01, '');

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Deduct", 0);
        SalesAdvLetterLine.TestField("Amount Deducted", AmountIncVAT[1]);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::"VAT Deduction");
        SalesAdvLetterEntry.FindSet;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", Amount[2], 0.01, '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", VATAmount[2], 0.01, '');
        SalesAdvLetterEntry.Next;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", Amount[3], 0.01, '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", VATAmount[3], 0.01, '');

        // verify advance letter line relation
        AdvLetterLineRel.SetCurrentKey(Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.");
        AdvLetterLineRel.SetRange(Type, AdvLetterLineRel.Type::Sale);
        AdvLetterLineRel.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        Assert.AreEqual(2, AdvLetterLineRel.Count, StrSubstNo(NotExistEnoughRecErr, AdvLetterLineRel.TableCaption));
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,SalesAdvLetterLinkCardHandler,SalesLetHeaderAdvLinkHandler,MessageHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure MultipleSalesAdvLettersInOneSalesInvoice()
    var
        SalesAdvPmntTemp: Record "Sales Adv. Payment Template";
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Cust: Record Customer;
        AdvLetterLineRel: Record "Advance Letter Line Relation";
        Amount: array[3] of Decimal;
        AmountIncVAT: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        SalesInvStatAmounts: array[20] of Decimal;
        SalesAdvLetterNo: array[2] of Code[20];
    begin
        // Test the posting two Sales Advance Letter over one Sales Invoice

        // 1.Setup:
        Initialize;

        // create sales advance payment template
        CreateSalesAdvPmntTemp(SalesAdvPmntTemp);

        // find VAT posting setup
        FindVATPostingSetup(VATPostingSetup);

        // create customer
        CreateCustomer(Cust);
        Cust.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Cust.Modify(true);

        // create sales advance letter 1
        CreateSalesAdvLetterBase(
          SalesAdvLetterHeader, SalesAdvLetterLine,
          SalesAdvPmntTemp.Code, VATPostingSetup."VAT Prod. Posting Group",
          Cust."No.", LibraryRandom.RandInt(1000));
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);

        SalesAdvLetterNo[1] := SalesAdvLetterHeader."No.";
        Amount[1] := SalesAdvLetterLine.Amount;
        AmountIncVAT[1] := SalesAdvLetterLine."Amount Including VAT";
        VATAmount[1] := SalesAdvLetterLine."VAT Amount";

        // create and post payment
        CreateAndPostPaymentSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine."Amount Including VAT");

        Clear(SalesAdvLetterHeader);
        Clear(SalesAdvLetterLine);

        // create sales advance letter 2
        CreateSalesAdvLetterBase(
          SalesAdvLetterHeader, SalesAdvLetterLine,
          SalesAdvPmntTemp.Code, VATPostingSetup."VAT Prod. Posting Group",
          Cust."No.", LibraryRandom.RandInt(1000));
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);

        SalesAdvLetterNo[2] := SalesAdvLetterHeader."No.";
        Amount[2] := SalesAdvLetterLine.Amount;
        AmountIncVAT[2] := SalesAdvLetterLine."Amount Including VAT";
        VATAmount[2] := SalesAdvLetterLine."VAT Amount";

        // create and post payment
        CreateAndPostPaymentSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine."Amount Including VAT");

        // create sales invoice
        CreateSalesInvoice(
          SalesHeader, SalesLine,
          Cust."No.",
          SalesAdvLetterHeader."Posting Date",
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group",
          '', 0, true,
          AmountIncVAT[1] + AmountIncVAT[2]);

        Amount[3] := SalesLine.Amount;
        AmountIncVAT[3] := SalesLine."Amount Including VAT";
        VATAmount[3] := AmountIncVAT[3] - Amount[3];

        // link advance letter to sales invoice
        LinkAdvanceLetterToSalesDocument(SalesHeader, SalesAdvLetterNo[1], SalesAdvLetterNo[2], true, 1);

        // get amounts from statistics of sales invoice
        GetSalesInvoiceStatistics(SalesHeader, SalesInvStatAmounts);

        // 2.Exercise:
        PostSalesDocument(SalesHeader);

        // 3.Verify:

        // verify statistics of sales invoice
        Assert.AreNearlyEqual(-AmountIncVAT[3], SalesInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount[3], SalesInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount[3], SalesInvStatAmounts[3], 0.01, '');

        // verify sales advance letter 1
        SalesAdvLetterHeader.Get(SalesAdvLetterNo[1]);
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Deduct", 0);
        SalesAdvLetterLine.TestField("Amount Deducted", AmountIncVAT[1]);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::"VAT Deduction");
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", Amount[1], 0.01, '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", VATAmount[1], 0.01, '');

        // verify advance letter relation
        AdvLetterLineRel.SetCurrentKey(Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.");
        AdvLetterLineRel.SetRange(Type, AdvLetterLineRel.Type::Sale);
        AdvLetterLineRel.SetRange("Letter No.", SalesAdvLetterNo[1]);
        AdvLetterLineRel.FindFirst;

        // verify sales advance letter 2
        SalesAdvLetterHeader.Get(SalesAdvLetterNo[2]);
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Deduct", 0);
        SalesAdvLetterLine.TestField("Amount Deducted", AmountIncVAT[2]);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::"VAT Deduction");
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", Amount[2], 0.01, '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", VATAmount[2], 0.01, '');

        // verify advance letter relation
        AdvLetterLineRel.SetCurrentKey(Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.");
        AdvLetterLineRel.SetRange(Type, AdvLetterLineRel.Type::Sale);
        AdvLetterLineRel.SetRange("Letter No.", SalesAdvLetterNo[2]);
        AdvLetterLineRel.FindFirst;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelSalesAdvLetter()
    var
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        AdvLetterLineRel: Record "Advance Letter Line Relation";
    begin
        // Test the canceling Sales Advance Letter.

        // 1.Setup:
        Initialize;

        // create and payment sales advance letter
        CreateAndReleaseSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(SalesAdvLetterHeader);

        // 3.Verify:

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Link", 0);
        SalesAdvLetterLine.TestField("Amount Linked", 0);
        SalesAdvLetterLine.TestField("Amount To Invoice", 0);
        SalesAdvLetterLine.TestField("Amount Invoiced", 0);
        SalesAdvLetterLine.TestField("Amount To Deduct", 0);
        SalesAdvLetterLine.TestField("Amount Deducted", 0);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        Assert.IsTrue(SalesAdvLetterEntry.IsEmpty, StrSubstNo(ExistErr, SalesAdvLetterEntry.TableCaption));

        // verify advance letter relation
        AdvLetterLineRel.SetCurrentKey(Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.");
        AdvLetterLineRel.SetRange(Type, AdvLetterLineRel.Type::Sale);
        AdvLetterLineRel.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        Assert.AreEqual(0, AdvLetterLineRel.Count, StrSubstNo(ExistErr, AdvLetterLineRel.TableCaption))
    end;

    [Test]
    [HandlerFunctions('SalesAdvLettersHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelSalesAdvLetterWithPayment()
    var
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // Test the canceling Sales Advance Letter with payment.

        // 1.Setup:
        Initialize;

        // create and payment sales advance letter
        CreateAndPaymentSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        Amount := SalesAdvLetterLine.Amount;
        VATAmount := SalesAdvLetterLine."VAT Amount";

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(SalesAdvLetterHeader);

        // 3.Verify:

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Link", 0);
        SalesAdvLetterLine.TestField("Amount Linked", 0);
        SalesAdvLetterLine.TestField("Amount To Invoice", 0);
        SalesAdvLetterLine.TestField("Amount Invoiced", 0);
        SalesAdvLetterLine.TestField("Amount To Deduct", 0);
        SalesAdvLetterLine.TestField("Amount Deducted", 0);

        // verify entries
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::VAT);
        SalesAdvLetterEntry.FindSet;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", Amount, 0.01, '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", VATAmount, 0.01, '');
        SalesAdvLetterEntry.Next;
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Base Amount", -Amount, 0.01, '');
        Assert.AreNearlyEqual(SalesAdvLetterEntry."VAT Amount", -VATAmount, 0.01, '');

        // verify creation advance invoice
        SalesInvHeader.SetCurrentKey("Letter No.");
        SalesInvHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesInvHeader.FindFirst;
        SalesInvHeader.CalcFields(Amount);
        SalesInvHeader.TestField(Amount, VATAmount);

        // verify creation sales credit memo
        SalesCrMemoHeader.SetCurrentKey("Letter No.");
        SalesCrMemoHeader.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesCrMemoHeader.FindFirst;
        SalesCrMemoHeader.CalcFields(Amount);
        SalesCrMemoHeader.TestField(Amount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('SalesAdvLetterLinkCardHandler,SalesLetHeaderAdvLinkHandler,MessageHandler,SalesStatisticsHandler,SetAdvanceLinkHandler')]
    [Scope('OnPrem')]
    procedure PartialPayments()
    var
        SalesAdvLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvLetterLine: Record "Sales Advance Letter Line";
        SalesAdvLetterEntry: Record "Sales Advance Letter Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        AdvLetterLineRel: Record "Advance Letter Line Relation";
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        VATCoeficient: Decimal;
        PaymentAmount: array[2] of Decimal;
        SalesInvStatAmounts: array[20] of Decimal;
    begin
        // Test the posting Sales Advance Letter over two Payments

        // 1.Setup:
        Initialize;

        // create and payment sales advance letter
        CreateAndReleaseSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);

        Amount := SalesAdvLetterLine.Amount;
        AmountIncVAT := SalesAdvLetterLine."Amount Including VAT";
        VATAmount := SalesAdvLetterLine."VAT Amount";

        // split to two payment
        PaymentAmount[1] := Round(AmountIncVAT / 3);
        PaymentAmount[2] := Round(AmountIncVAT - (AmountIncVAT / 3));

        // create and post payment 1
        CreateGenJournalLine(GenJournalLine, SalesAdvLetterHeader."Bill-to Customer No.", -PaymentAmount[1]);
        LinkAdvanceLettersToGenJnlLine(GenJournalLine, SalesAdvLetterLine."Letter No.", SalesAdvLetterLine."Line No.");
        PostGenJournalLine(GenJournalLine);

        // create and post payment 2
        CreateGenJournalLine(GenJournalLine, SalesAdvLetterHeader."Bill-to Customer No.", -PaymentAmount[2]);
        LinkAdvanceLettersToGenJnlLine(GenJournalLine, SalesAdvLetterLine."Letter No.", SalesAdvLetterLine."Line No.");
        PostGenJournalLine(GenJournalLine);

        // create sales invoice
        CreateSalesInvoiceFromSalesAdvLetter(SalesHeader, SalesLine, SalesAdvLetterHeader, SalesAdvLetterLine, '', 0);

        // link advance letter to sales invoice
        LinkAdvanceLetterToSalesDocument(SalesHeader, SalesAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of sales invoice
        GetSalesInvoiceStatistics(SalesHeader, SalesInvStatAmounts);

        // 2.Exercise:

        // post sales invoice
        PostSalesDocument(SalesHeader);

        // 3.Verify:

        // verify statistics of sales invoice
        Assert.AreNearlyEqual(-AmountIncVAT, SalesInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount, SalesInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount, SalesInvStatAmounts[3], 0.01, '');

        // verify sales advance letter
        SalesAdvLetterHeader.Get(SalesAdvLetterHeader."No.");
        SalesAdvLetterHeader.CalcFields(Status);
        SalesAdvLetterHeader.TestField(Status, SalesAdvLetterHeader.Status::Closed);

        SalesAdvLetterLine.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterLine.FindFirst;
        SalesAdvLetterLine.TestField("Amount To Deduct", 0);
        SalesAdvLetterLine.TestField("Amount Deducted", AmountIncVAT);

        // verify entries
        VATCoeficient := 1 + SalesAdvLetterLine."VAT %" / 100;
        SalesAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        SalesAdvLetterEntry.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::VAT);
        SalesAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount", -Round(PaymentAmount[1] / VATCoeficient), 0.01, '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount", -Round(PaymentAmount[1] - PaymentAmount[1] / VATCoeficient), 0.01, '');
        SalesAdvLetterEntry.Next;
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount", -Round(PaymentAmount[2] / VATCoeficient), 0.01, '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount", -Round(PaymentAmount[2] - PaymentAmount[2] / VATCoeficient), 0.01, '');

        SalesAdvLetterEntry.SetRange("Entry Type", SalesAdvLetterEntry."Entry Type"::"VAT Deduction");
        SalesAdvLetterEntry.FindSet;
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount", Round(PaymentAmount[1] / VATCoeficient), 0.01, '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount", Round(PaymentAmount[1] - PaymentAmount[1] / VATCoeficient), 0.01, '');
        SalesAdvLetterEntry.Next;
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Base Amount", Round(PaymentAmount[2] / VATCoeficient), 0.01, '');
        Assert.AreNearlyEqual(
          SalesAdvLetterEntry."VAT Amount", Round(PaymentAmount[2] - PaymentAmount[2] / VATCoeficient), 0.01, '');

        // verify advance letter relation
        AdvLetterLineRel.SetCurrentKey(Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.");
        AdvLetterLineRel.SetRange(Type, AdvLetterLineRel.Type::Sale);
        AdvLetterLineRel.SetRange("Letter No.", SalesAdvLetterHeader."No.");
        Assert.AreEqual(1, AdvLetterLineRel.Count, StrSubstNo(NotExistEnoughRecErr, AdvLetterLineRel.TableCaption))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetLineDiscountOnPageSalesInvoice()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207109] Values of "Amount" and "Amount Including VAT" of Sales Line have to equal to 0 when setting value "Line Discount %" = 100 on the page "Sales Invoice"
        Initialize;

        // [GIVEN] "Sales & Receivables Setup"."Allow VAT Difference" = TRUE
        UpdateSalesSetupAllowVATDifference;

        // [GIVEN] Sales invoice with line with Amount = 200 and Line discount % < 100
        CreateSalesInvoiceWithVATPostingSetup(SalesLine);

        // [GIVEN] Open page Sales Invoice
        SalesInvoice.OpenEdit;
        SalesInvoice.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesInvoice.SalesLines.GotoRecord(SalesLine);

        // [WHEN] Set "Line Discount %" = 100 on the page
        SalesInvoice.SalesLines."Line Discount %".SetValue(100);
        SalesInvoice.SalesLines.Next;
        SalesInvoice.SalesLines.Previous();

        // [THEN] "Sales Line"."Amount" = 0
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField(Amount, 0);

        // [THEN] "Sales Line"."Amount Including VAT" = 0
        SalesLine.TestField("Amount Including VAT", 0);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdateGLSetup;
        UpdateSalesSetup;

        isInitialized := true;
        Commit;
    end;

    local procedure CreateCustomerPostingGroup(var CustPostingGroup: Record "Customer Posting Group")
    begin
        LibraryAdvance.CreateCustomerPostingGroup(CustPostingGroup);
        CustPostingGroup.Validate("Advance Account", GetNewGLAccountNo);
        CustPostingGroup.Validate("Receivables Account", GetNewGLAccountNo);
        CustPostingGroup.Validate("Invoice Rounding Account", GetNewGLAccountNo);
        CustPostingGroup.Validate("Debit Rounding Account", GetNewGLAccountNo);
        CustPostingGroup.Modify(true);
    end;

    local procedure CreateSalesAdvPmntTemp(var SalesAdvPaymentTemplate: Record "Sales Adv. Payment Template")
    begin
        LibraryAdvance.CreateSalesAdvPmntTemplate(SalesAdvPaymentTemplate);
        SalesAdvPaymentTemplate.Validate("Amounts Including VAT", true);
        SalesAdvPaymentTemplate.Modify(true);
    end;

    local procedure CreateAndPaymentSalesAdvLetter(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvLetterLine: Record "Sales Advance Letter Line")
    begin
        CreateAndReleaseSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);
        CreateAndPostPaymentSalesAdvLetter(SalesAdvLetterHeader, -SalesAdvLetterLine."Amount Including VAT")
    end;

    local procedure CreateAndReleaseSalesAdvLetter(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvLetterLine: Record "Sales Advance Letter Line")
    begin
        CreateSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);
        ReleaseSalesAdvLetter(SalesAdvLetterHeader);
    end;

    local procedure CreateSalesAdvLetter(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvLetterLine: Record "Sales Advance Letter Line")
    var
        SalesAdvPmntTemp: Record "Sales Adv. Payment Template";
    begin
        CreateSalesAdvPmntTemp(SalesAdvPmntTemp);
        CreateSalesAdvLetterWithTemplate(
          SalesAdvLetterHeader, SalesAdvLetterLine, SalesAdvPmntTemp.Code);
    end;

    local procedure CreateSalesAdvLetterWithTemplate(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvLetterLine: Record "Sales Advance Letter Line"; SalesAdvPmntTempCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesAdvLetterWithVATPostingSetup(
          SalesAdvLetterHeader, SalesAdvLetterLine, SalesAdvPmntTempCode, VATPostingSetup);
    end;

    local procedure CreateSalesAdvLetterWithVATPostingSetup(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvLetterLine: Record "Sales Advance Letter Line"; SalesAdvPmntTempCode: Code[10]; VATPostingSetup: Record "VAT Posting Setup")
    var
        Cust: Record Customer;
    begin
        CreateCustomer(Cust);
        Cust.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Cust.Modify(true);

        CreateSalesAdvLetterBase(
          SalesAdvLetterHeader, SalesAdvLetterLine,
          SalesAdvPmntTempCode, VATPostingSetup."VAT Prod. Posting Group",
          Cust."No.", LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateSalesAdvLetterWithCurrency(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvLetterLine: Record "Sales Advance Letter Line"; CurrencyCode: Code[10])
    begin
        CreateSalesAdvLetter(SalesAdvLetterHeader, SalesAdvLetterLine);
        SalesAdvLetterHeader.Validate("Currency Code", CurrencyCode);
        SalesAdvLetterHeader.Modify(true);

        SalesAdvLetterLine.Validate("Currency Code", CurrencyCode);
        SalesAdvLetterLine.Modify(true);
    end;

    local procedure CreateSalesAdvLetterBase(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvLetterLine: Record "Sales Advance Letter Line"; SalesAdvPmntTempCode: Code[10]; VATProdPostingGroupCode: Code[20]; CustomerNo: Code[20]; Amount: Decimal)
    begin
        LibraryAdvance.CreateSalesAdvLetterHeader(SalesAdvLetterHeader, SalesAdvPmntTempCode, CustomerNo);
        LibraryAdvance.CreateSalesAdvLetterLine(SalesAdvLetterLine, SalesAdvLetterHeader, VATProdPostingGroupCode, Amount);
    end;

    local procedure CreateSalesAdvLetterFromSalesDoc(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; SalesHeader: Record "Sales Header")
    var
        SalesAdvPmntTemp: Record "Sales Adv. Payment Template";
    begin
        CreateSalesAdvPmntTemp(SalesAdvPmntTemp);
        LibraryAdvance.CreateSalesAdvLetterFromSalesDoc(SalesAdvLetterHeader, SalesHeader, SalesAdvPmntTemp.Code);
    end;

    local procedure CreateAndPostPaymentSalesAdvLetter(var SalesAdvLetterHeader: Record "Sales Advance Letter Header"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(GenJournalLine, SalesAdvLetterHeader."Bill-to Customer No.", Amount);
        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, SalesAdvLetterHeader."No.");
        PostGenJournalLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Cust: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        FindVATPostingSetup(VATPostingSetup);

        CreateCustomer(Cust);
        Cust.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Cust.Modify(true);

        CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        SalesHeader.Validate("Posting Date", WorkDate);
        SalesHeader.Validate("VAT Date", WorkDate);
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; PostingDate: Date; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; CurrencyCode: Code[10]; ExchangeRate: Decimal; PricesIncVAT: Boolean; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        GLAccount.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Validate("Prices Including VAT", PricesIncVAT);
        if CurrencyCode <> '' then
            SalesHeader.Validate("Currency Code", CurrencyCode);
        if ExchangeRate <> 0 then
            ChangeExchangeRateOnSalesDocument(SalesHeader, ExchangeRate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceFromSalesAdvLetter(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesAdvLetterHeader: Record "Sales Advance Letter Header"; SalesAdvLetterLine: Record "Sales Advance Letter Line"; CurrencyCode: Code[10]; ExchangeRate: Decimal)
    begin
        CreateSalesInvoice(
          SalesHeader, SalesLine,
          SalesAdvLetterHeader."Bill-to Customer No.",
          SalesAdvLetterHeader."Posting Date",
          SalesAdvLetterLine."VAT Bus. Posting Group",
          SalesAdvLetterLine."VAT Prod. Posting Group",
          CurrencyCode,
          ExchangeRate,
          true,
          SalesAdvLetterLine."Amount Including VAT");
    end;

    local procedure CreateSalesInvoiceWithVATPostingSetup(var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        DummyGLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandIntInRange(10, 50));
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 50));
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomer(var Cust: Record Customer)
    var
        CustPostingGroup: Record "Customer Posting Group";
    begin
        CreateCustomerPostingGroup(CustPostingGroup);
        LibrarySales.CreateCustomer(Cust);
        Cust.Validate("Customer Posting Group", CustPostingGroup.Code);
        Cust.Modify(true);
    end;

    local procedure CreateGenJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateName);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        FindVATPostingSetup(VATPostingSetup);
        CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 50));
        VATPostingSetup.Modify;
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales Advance VAT Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Sales Advance Offset VAT Acc.", GetNewGLAccountNo);
        VATPostingSetup.Modify(true);
    end;

    local procedure FindVATPostingSetupEU(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Sales Advance VAT Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Sales Advance Offset VAT Acc.", GetNewGLAccountNo);
        VATPostingSetup.Modify(true);
    end;

    local procedure FindForeignCurrency(var Currency: Record Currency)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        Currency.SetFilter(Code, '<>%1', GLSetup."LCY Code");
        LibraryERM.FindCurrency(Currency);
    end;

    local procedure GetNewGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure GetSalesInvoiceStatistics(SalesHeader: Record "Sales Header"; var Amounts: array[20] of Decimal)
    var
        VariantAmount: Variant;
    begin
        OpenSalesInvoiceStatistics(SalesHeader);
        // Prepayment (Deduct)
        LibraryVariableStorage.Dequeue(VariantAmount);
        Amounts[1] := VariantAmount; // Amount including VAT
        LibraryVariableStorage.Dequeue(VariantAmount);
        Amounts[2] := VariantAmount; // VAT Amount
        LibraryVariableStorage.Dequeue(VariantAmount);
        Amounts[3] := VariantAmount; // VAT Base
        // Invoicing (Final)
        LibraryVariableStorage.Dequeue(VariantAmount);
        Amounts[4] := VariantAmount; // Amount including VAT
        LibraryVariableStorage.Dequeue(VariantAmount);
        Amounts[5] := VariantAmount; // VAT Amount
        LibraryVariableStorage.Dequeue(VariantAmount);
        Amounts[6] := VariantAmount; // VAT Base
    end;

    local procedure UpdateGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        GLSetup.Validate("Prepayment Type", GLSetup."Prepayment Type"::Advances);
        GLSetup.Validate("Correction As Storno", true);
        GLSetup.Modify(true);
    end;

    local procedure UpdateSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get;
        SalesSetup.Validate("Automatic Adv. Invoice Posting", true);
        SalesSetup.Modify(true);
    end;

    local procedure UpdateSalesSetupAutomaticAdvInvPosting(NewAutomaticAdvInvPosting: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get;
        SalesSetup.Validate("Automatic Adv. Invoice Posting", NewAutomaticAdvInvPosting);
        SalesSetup.Modify(true);
    end;

    local procedure UpdateSalesSetupAllowVATDifference()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup."Allow VAT Difference" := true;
        SalesReceivablesSetup.Modify;
    end;

    local procedure VerifySalesAdvLetter(LetterNo: Code[20]; Status: Option; AmountDeducted: Decimal)
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterHeader.Get(LetterNo);
        SalesAdvanceLetterHeader.CalcFields(Status);
        SalesAdvanceLetterHeader.TestField(Status, Status);

        SalesAdvanceLetterLine.SetRange("Letter No.", LetterNo);
        SalesAdvanceLetterLine.FindFirst;
        SalesAdvanceLetterLine.TestField("Amount Deducted", AmountDeducted);
    end;

    local procedure ReleaseSalesAdvLetter(var SalesAdvLetterHeader: Record "Sales Advance Letter Header")
    begin
        LibraryAdvance.ReleaseSalesAdvLetter(SalesAdvLetterHeader);
    end;

    local procedure PostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostRefundAndCloseLetter(var SalesAdvLetterHeader: Record "Sales Advance Letter Header")
    begin
        LibraryAdvance.PostRefundAndCloseSalesAdvLetter(SalesAdvLetterHeader);
    end;

    local procedure PostAdvanceInvoice(var SalesAdvLetterHeader: Record "Sales Advance Letter Header")
    begin
        LibraryAdvance.PostSalesAdvInvoice(SalesAdvLetterHeader);
    end;

    local procedure IsVariantNull(Variant: Variant): Boolean
    begin
        exit(Format(Variant) = '');
    end;

    local procedure ChangeExchangeRateOnGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; NewExchangeRate: Decimal)
    begin
        // required ChangeExchangeRateHandler

        LibraryVariableStorage.Enqueue(NewExchangeRate);
        GenJournalLine.Validate("Currency Factor",
          LibraryAdvance.ChangeExchangeRate(
            GenJournalLine."Currency Code", GenJournalLine."Currency Factor", GenJournalLine."Posting Date"));
    end;

    local procedure ChangeExchangeRateOnSalesDocument(var SalesHeader: Record "Sales Header"; NewExchangeRate: Decimal)
    begin
        // required ChangeExchangeRateHandler

        LibraryVariableStorage.Enqueue(NewExchangeRate);
        SalesHeader.Validate("Currency Factor",
          LibraryAdvance.ChangeExchangeRate(
            SalesHeader."Currency Code", SalesHeader."Currency Factor", SalesHeader."Posting Date"));
    end;

    local procedure LinkAdvanceLetterToSalesDocument(var SalesHeader: Record "Sales Header"; SalesAdvLetterNo1: Code[20]; SalesAdvLetterNo2: Code[20]; ApplyByVATGroups: Boolean; LinkAmount: Option)
    begin
        // required SalesAdvLetterLinkCardHandler,SalesLetHeaderAdvLinkHandler

        LibraryVariableStorage.Enqueue(ApplyByVATGroups);
        LibraryVariableStorage.Enqueue(LinkAmount); // 1 - Invocing, 2 - Remaining
        LibraryVariableStorage.Enqueue(SalesAdvLetterNo1);
        LibraryVariableStorage.Enqueue(SalesAdvLetterNo2);
        LibraryAdvance.LinkAdvanceLetterToSalesDocument(SalesHeader);
    end;

    local procedure LinkWholeAdvanceLetterToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesAdvLetterNo: Code[20])
    begin
        // required SalesAdvLettersHandler

        LibraryVariableStorage.Enqueue(SalesAdvLetterNo);
        LibraryAdvance.LinkWholeAdvanceLetterToGenJnlLine(GenJnlLine);
    end;

    local procedure LinkAdvanceLettersToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesAdvLetterNo: Code[20]; LineNo: Integer)
    begin
        // required SetAdvanceLinkHandler

        LibraryVariableStorage.Enqueue(2); // 2 - letter line
        LibraryVariableStorage.Enqueue(SalesAdvLetterNo);
        LibraryVariableStorage.Enqueue(LineNo);
        LibraryAdvance.LinkAdvanceLettersToGenJnlLine(GenJnlLine);
    end;

    local procedure OpenSalesOrderStatistics(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // required SalesOrderStatisticsHandler

        SalesOrder.OpenView;
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesOrder.Statistics.Invoke;
        SalesOrder.OK.Invoke;
    end;

    local procedure OpenSalesInvoiceStatistics(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // required SalesStatisticsHandler

        SalesInvoice.OpenView;
        SalesInvoice.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesInvoice.Statistics.Invoke;
        SalesInvoice.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAdvLettersHandler(var SalesAdvLetters: TestPage "Sales Adv. Letters")
    var
        SalesAdvLetterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesAdvLetterNo);
        SalesAdvLetters.GotoKey(SalesAdvLetterNo);
        SalesAdvLetters.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeExchangeRateHandler(var ChangeExchangeRate: TestPage "Change Exchange Rate")
    var
        RefExchRate: Variant;
    begin
        LibraryVariableStorage.Dequeue(RefExchRate);
        ChangeExchangeRate.RefExchRate.SetValue(RefExchRate);
        ChangeExchangeRate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAdvLetterLinkCardHandler(var SalesAdvLetterLinkCard: TestPage "Sales Adv. Letter Link. Card")
    var
        ApplyByVATGroups: Variant;
        LinkAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ApplyByVATGroups);
        LibraryVariableStorage.Dequeue(LinkAmount);

        SalesAdvLetterLinkCard.ApplyByVATGroups.SetValue(ApplyByVATGroups);
        SalesAdvLetterLinkCard.QtyType.SetValue(LinkAmount);
        SalesAdvLetterLinkCard.LetterNo.DrillDown;
        SalesAdvLetterLinkCard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesLetHeaderAdvLinkHandler(var SalesLetHeaderAdvLink: TestPage "Sales Letter Head. - Adv.Link.")
    var
        SalesAdvLetterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesAdvLetterNo);

        if not IsVariantNull(SalesAdvLetterNo) then begin
            SalesLetHeaderAdvLink.GotoKey(SalesAdvLetterNo);
            SalesLetHeaderAdvLink.Mark.Invoke;
        end;

        LibraryVariableStorage.Dequeue(SalesAdvLetterNo);

        if not IsVariantNull(SalesAdvLetterNo) then begin
            SalesLetHeaderAdvLink.GotoKey(SalesAdvLetterNo);
            SalesLetHeaderAdvLink.Mark.Invoke;
        end;

        SalesLetHeaderAdvLink."Link Selected Advance Letters".Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(SalesOrderStatistics."-""Adv.Letter Link.Amt. to Deduct""".Value);
        LibraryVariableStorage.Enqueue(SalesOrderStatistics."TempTotVATAmountLinePrep.""VAT Amount""".Value);
        LibraryVariableStorage.Enqueue(SalesOrderStatistics."TempTotVATAmountLinePrep.""VAT Base""".Value);
        SalesOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetAdvanceLinkHandler(var SetAdvanceLink: TestPage "Set Advance Link")
    var
        EntryType: Variant;
        DocumentNo: Variant;
        EntryNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryType);
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(EntryNo);

        SetAdvanceLink.GotoKey(EntryType, DocumentNo, EntryNo);
        SetAdvanceLink."Set Link-to &ID".Invoke; // Set Link-to ID
        SetAdvanceLink."Set Link".Invoke; // Set Link
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        // Prepayment (Deduct)
        LibraryVariableStorage.Enqueue(SalesStatistics."-""Adv.Letter Link.Amt. to Deduct""".Value); // Amount Including VAT
        LibraryVariableStorage.Enqueue(SalesStatistics."TempTotVATAmountLinePrep.""VAT Amount""".Value); // VAT Amount
        LibraryVariableStorage.Enqueue(SalesStatistics."TempTotVATAmountLinePrep.""VAT Base""".Value); // VAT Base
        // Invoicing (Deduct)
        LibraryVariableStorage.Enqueue(SalesStatistics."TotalSalesLine.""Amount Including VAT"" - ""Adv.Letter Link.Amt. to Deduct""".Value); // Amount Including VAT
        LibraryVariableStorage.Enqueue(SalesStatistics."TempTotVATAmountLineTot.""VAT Amount""".Value); // VAT Amount
        LibraryVariableStorage.Enqueue(SalesStatistics."TempTotVATAmountLineTot.""VAT Base""".Value); // VAT Base
        SalesStatistics.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        // Message Handler
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

