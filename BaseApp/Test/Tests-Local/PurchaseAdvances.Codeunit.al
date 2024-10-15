codeunit 144400 "Purchase Advances"
{
    // // [FEATURE] [Purchase]
    // Test Cases for Purchase Advance
    // 1. Test if the system allows to create a new Purchase Advance Letter.
    // 2. Test if the system allows to create a new Purchase Advance Letter from Purchase order.
    // 3. Test the release of Purchase Advance Letter.
    // 4. Test the payment of Purchase Advance Letter.
    // 5. Test if the system allows to create a new Purchase Advance Invoice from Purchase Advance Letter.
    // 6. Test the posting of Purchase Order from which Purchase Advance Letter was creation.
    // 7. Test the posting of Purchase Invoice which was created from Purchase Advance Letter.
    // 8. Test the posting refund and close Purchase Advance Letter.
    // 9. Test if the system allows to create a new Purchase Advance Invoice from Purchase Advance Letter with foreign currency.
    //   Test the changing exchange rate on Purchase Advance Letter.
    // 10. Test the creation and posting Purchase Invoice from Purchase Advance Letter with foreign currency.
    // 11. Test the posting refund and close Purchase Advance Letter with foreign currency.
    // 12. Test the creation Purchase Advance Letter with refund VAT.
    // 13. Test the canceling Purchase Advance Letter.
    // 14. Test the canceling Purchase Advance Letter with payment.
    // 15. Test the canceling Purchase Advance Letter with payment and Advance Invoice.
    // 16. Test the storno Purchase Advance Letter which was payment and a re-creation Purchase Advance Invoice.
    // 17. Test the creation Purchase Advance Invoice after change VAT amount of VAT Amount Line and test the
    //   correcting VAT by deducted VAT.
    // 18. Test the posting Purchase Advance Letter over two Purchase Invoice
    // 19. Test the posting two Purchase Advance Letter over one Purchase Invoice
    // 20. Test the posting Purchase Advance Letter over two Payments
    // 21. Test the creation Purchase Advance Invoice after change VAT amount of VAT Amount Line.

    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryAdvance: Codeunit "Library - Advance";
        LibraryAdvanceStatistics: Codeunit "Library - Advance Statistics";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        PurchAdvLetterEntryExistsErr: Label 'Purchase Advance Letter Entry Exist.';
        StatusErr: Label 'Status must be %1', Comment = '%1=Status';

    [Test]
    [Scope('OnPrem')]
    procedure CreationPurchAdvLetter()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
    begin
        // Test if the system allows to create a new Purchase Advance Letter.

        // 1.Setup:
        Initialize;

        // 2.Exercise:

        // create purchase advance letter
        CreatePurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        // 3.Verify:

        // verify creation purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationPurchAdvLetterFromPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
    begin
        // Test if the system allows to create a new Purchase Advance Letter from Purchase order.

        // 1.Setup:
        Initialize;

        // create purchase order
        CreatePurchOrder(PurchHeader, PurchLine);

        // 2.Exercise:

        // create purchase advance letter from purchase order
        CreatePurchAdvLetterFromPurchDoc(PurchAdvLetterHeader, PurchHeader);

        // 3.Verify:

        // verify creation purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckReleasePurchAdvLetter()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
    begin
        // Test the release of Purchase Advance Letter.

        // 1.Setup:
        Initialize;

        // create purchase advance letter from purchase order
        CreatePurchOrder(PurchHeader, PurchLine);
        CreatePurchAdvLetterFromPurchDoc(PurchAdvLetterHeader, PurchHeader);

        // 2.Exercise:
        ReleasePurchAdvLetter(PurchAdvLetterHeader);

        // 3.Verify:

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::"Pending Payment");
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvLetterStatisticsHandler,PurchAdvPaymSelectionHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentPurchAdvLetter()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Test the payment of Purchase Advance Letter.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndReleasePurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // 2.Exercise:

        // create and post payment
        CreateAndPostPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine."Amount Including VAT");

        // 3.Verify:

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::"Pending Invoice");

        PurchAdvLetterLine.Get(PurchAdvLetterLine."Letter No.", PurchAdvLetterLine."Line No.");
        PurchAdvLetterLine.TestField("Amount To Invoice", AmountIncVAT);
        PurchAdvLetterLine.TestField("Amount Invoiced", 0);

        // verify statistics
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);
        Assert.AreNearlyEqual(Amount, LibraryAdvanceStatistics.GetInvoicingAmount, 0.01, '');
        Assert.AreNearlyEqual(VATAmount, LibraryAdvanceStatistics.GetInvoicingVATAmount, 0.01, '');
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler')]
    [Scope('OnPrem')]
    procedure CreationAdvanceInvoice()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Test if the system allows to create a new Purchase Advance Invoice from Purchase Advance Letter.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // 2.Exercise:

        // post advance invoce
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // 3.Verify:

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::"Pending Final Invoice");

        PurchAdvLetterLine.Get(PurchAdvLetterLine."Letter No.", PurchAdvLetterLine."Line No.");
        PurchAdvLetterLine.TestField("Amount Linked", AmountIncVAT);
        PurchAdvLetterLine.TestField("Amount Invoiced", AmountIncVAT);
        PurchAdvLetterLine.TestField("Amount To Deduct", AmountIncVAT);

        // verify creation purchase advance invoice
        PurchInvHeader.SetCurrentKey("Letter No.");
        PurchInvHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchInvHeader.FindFirst;
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvHeader.TestField(Amount, VATAmount);
        PurchInvHeader.TestField("Amount Including VAT", VATAmount);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::VAT);
        PurchAdvLetterEntry.FindFirst;
        PurchAdvLetterEntry.TestField("VAT Base Amount", Amount);
        PurchAdvLetterEntry.TestField("VAT Amount", VATAmount);
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler,PurchOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PostPurchAdvLetterFromPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedDocNo: Code[20];
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        PurchOrderStatAmounts: array[20] of Decimal;
    begin
        // Test the posting of Purchase Order from which Purchase Advance Letter was creation.

        // 1.Setup:
        Initialize;

        // create purchase advance letter from purchase order
        CreatePurchOrder(PurchHeader, PurchLine);
        CreatePurchAdvLetterFromPurchDoc(PurchAdvLetterHeader, PurchHeader);
        ReleasePurchAdvLetter(PurchAdvLetterHeader);

        Amount := PurchLine.Amount;
        AmountIncVAT := PurchLine."Amount Including VAT";
        VATAmount := AmountIncVAT - Amount;

        // create and post payment
        PurchAdvLetterLine.Init;
        CreateAndPostPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine."Amount Including VAT");

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);

        // post advance invoce
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // modify purchase order
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        PurchHeader.Validate("Posting Date", CalcDate('<+10D>', WorkDate));
        PurchHeader.Modify(true);

        // get amounts from statistics of purchase order
        GetPurchOrderStatistics(PurchHeader, PurchOrderStatAmounts);

        // 2.Exercise:

        // post purchase order
        PostedDocNo := PostPurchaseDocument(PurchHeader);

        // 3.Verify:

        // verify statistics of purchase advance letter
        Assert.AreNearlyEqual(Amount, LibraryAdvanceStatistics.GetInvoicingAmount, 0.01, '');
        Assert.AreNearlyEqual(VATAmount, LibraryAdvanceStatistics.GetInvoicingVATAmount, 0.01, '');

        // verify statistics of purchase order
        Assert.AreNearlyEqual(-AmountIncVAT, PurchOrderStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount, PurchOrderStatAmounts[2], 0.01, '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount Deducted", PurchLine."Amount Including VAT");

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::Deduction);
        PurchAdvLetterEntry.FindFirst;
        PurchAdvLetterEntry.TestField(Amount, -PurchLine."Amount Including VAT");

        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::"VAT Deduction");
        PurchAdvLetterEntry.FindFirst;
        PurchAdvLetterEntry.TestField("VAT Base Amount", -PurchLine."VAT Base Amount");
        PurchAdvLetterEntry.TestField("VAT Amount", -(PurchLine."Amount Including VAT" - PurchLine."VAT Base Amount"));

        // verify creation advance invoice
        PurchInvHeader.Get(PostedDocNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvHeader.TestField(Amount, 0);
        PurchInvHeader.TestField("Amount Including VAT", 0);
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler,MessageHandler,PurchStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PostPurchAdvLetterWithConnectedPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedDocNo: Code[20];
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        PurchInvStatAmounts: array[20] of Decimal;
    begin
        // Test the posting of Purchase Invoice which was created from Purchase Advance Letter.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // post advance invoce
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create purchase invoice
        CreatePurchInvoiceFromPurchAdvLetter(PurchHeader, PurchLine, PurchAdvLetterHeader, PurchAdvLetterLine, '', 0);

        // link advance letter to purchase invoice
        LinkAdvanceLetterToPurchDocument(PurchHeader, PurchAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of purchase invoice
        GetPurchInvoiceStatistics(PurchHeader, PurchInvStatAmounts);

        // 2.Exercise:
        PostedDocNo := PostPurchaseDocument(PurchHeader);

        // 3.Verify:

        // verify statistics of purchase order
        Assert.AreNearlyEqual(-AmountIncVAT, PurchInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount, PurchInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount, PurchInvStatAmounts[3], 0.01, '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount Deducted", AmountIncVAT);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::Deduction);
        PurchAdvLetterEntry.FindFirst;
        PurchAdvLetterEntry.TestField(Amount, -AmountIncVAT);

        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::"VAT Deduction");
        PurchAdvLetterEntry.FindFirst;
        PurchAdvLetterEntry.TestField("VAT Base Amount", -Amount);
        PurchAdvLetterEntry.TestField("VAT Amount", -VATAmount);

        // verify creation advance invoice
        PurchInvHeader.Get(PostedDocNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvHeader.TestField(Amount, 0);
        PurchInvHeader.TestField("Amount Including VAT", 0);
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler,MessageHandler,YesConfirmHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler,PurchStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOverpayment()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        Amount: array[2] of Decimal;
        AmountIncVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        PurchInvStatAmounts: array[20] of Decimal;
    begin
        // Test the posting refund and close Purchase Advance Letter.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        Amount[1] := PurchAdvLetterLine.Amount;
        AmountIncVAT[1] := PurchAdvLetterLine."Amount Including VAT";
        VATAmount[1] := PurchAdvLetterLine."VAT Amount";

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create purchase invoice
        CreatePurchInvoiceFromPurchAdvLetter(PurchHeader, PurchLine, PurchAdvLetterHeader, PurchAdvLetterLine, '', 0);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(Round(Amount[1], 1, '<') - 1, 2));
        PurchLine.Modify(true);

        Amount[2] := PurchLine.Amount;
        AmountIncVAT[2] := PurchLine."Amount Including VAT";
        VATAmount[2] := AmountIncVAT[2] - Amount[2];

        // link advance letter to purchase invoice
        LinkAdvanceLetterToPurchDocument(PurchHeader, PurchAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of purchase invoice
        GetPurchInvoiceStatistics(PurchHeader, PurchInvStatAmounts);

        // post purchase invoice
        PostPurchaseDocument(PurchHeader);

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(PurchAdvLetterHeader);

        // 3.Verify:

        // verify statistics of purchase advance letter
        Assert.AreNearlyEqual(Amount[1], LibraryAdvanceStatistics.GetInvoicingAmount, 0.01, '');
        Assert.AreNearlyEqual(VATAmount[1], LibraryAdvanceStatistics.GetInvoicingVATAmount, 0.01, '');

        // verify statistics of purchase invoice
        Assert.AreNearlyEqual(-AmountIncVAT[2], PurchInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount[2], PurchInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount[2], PurchInvStatAmounts[3], 0.01, '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Document Type", PurchAdvLetterEntry."Document Type"::"Credit Memo");
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Base Amount", -(Amount[1] - Amount[2]), 0.01, '');
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Amount", -(VATAmount[1] - VATAmount[2]), 0.01, '');

        // verify creation purchase credit memo
        PurchCrMemoHeader.SetCurrentKey("Letter No.");
        PurchCrMemoHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchCrMemoHeader.FindFirst;
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,ChangeExchangeRateHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchAdvLetterWithForeignCurrency()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrExchangeRate: Record "Currency Exchange Rate";
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Test if the system allows to create a new Purchase Advance Invoice from Purchase Advance Letter with foreign currency.
        // Test the changing exchange rate on Purchase Advance Letter.

        // 1.Setup:
        Initialize;

        // find foreign currency
        FindForeignCurrency(Currency);

        // create purchase advance letter
        CreatePurchAdvLetterWithCurrency(PurchAdvLetterHeader, PurchAdvLetterLine, Currency.Code);
        ReleasePurchAdvLetter(PurchAdvLetterHeader);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // create payment
        CreateGenJournalLine(GenJournalLine, PurchAdvLetterHeader."Pay-to Vendor No.", PurchAdvLetterLine."Amount Including VAT");
        GenJournalLine.Validate("Currency Code", Currency.Code);
        GenJournalLine.Modify(true);
        ChangeExchangeRateOnGenJnlLine(GenJournalLine, 0.6);
        GenJournalLine.Modify(true);

        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, PurchAdvLetterHeader."No.");

        // post payment
        PostGenJournalLine(GenJournalLine);

        // change exchange rate on purchase advance letter
        ChangeExchangeRateOnPurchAdvLetterHeader(PurchAdvLetterHeader, 0.6);
        PurchAdvLetterHeader.Modify(true);

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);

        // 2.Exercise:

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // 3.Verify:

        // verify statistics of purchase advance letter
        Assert.AreNearlyEqual(
          Amount, LibraryAdvanceStatistics.GetInvoicingAmount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          VATAmount, LibraryAdvanceStatistics.GetInvoicingVATAmount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              Amount, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          LibraryAdvanceStatistics.GetInvoicingVATBaseLCY, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              VATAmount, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          LibraryAdvanceStatistics.GetInvoicingVATAmountLCY, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              AmountIncVAT, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          LibraryAdvanceStatistics.GetInvoicingAmountIncludingVATLCY, Currency."Amount Rounding Precision", '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::"Pending Final Invoice");

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount Linked", AmountIncVAT);
        PurchAdvLetterLine.TestField("Amount Invoiced", AmountIncVAT);
        PurchAdvLetterLine.TestField("Amount To Deduct", AmountIncVAT);

        // verify creation advance invoice
        PurchInvHeader.SetCurrentKey("Letter No.");
        PurchInvHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchInvHeader.FindFirst;
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvHeader.TestField(Amount, VATAmount);
        PurchInvHeader.TestField("Amount Including VAT", VATAmount);
        PurchInvHeader.TestField("Currency Code", Currency.Code);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::VAT);
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", Amount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", VATAmount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Base Amount (LCY)",
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              Amount, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Amount (LCY)",
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              VATAmount, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          Currency."Amount Rounding Precision", '');
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,ChangeExchangeRateHandler,PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler,MessageHandler,PurchStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PostPurchAdvLetterWithConnectedPurchInvoiceInForeignCurrency()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
        PostedDocNo: Code[20];
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        PurchInvStatAmounts: array[20] of Decimal;
    begin
        // Test the creation and posting Purchase Invoice from Purchase Advance Letter with foreign currency.

        // 1.Setup:
        Initialize;

        // find foreign currency
        FindForeignCurrency(Currency);

        // create purchase advance letter
        CreatePurchAdvLetterWithCurrency(PurchAdvLetterHeader, PurchAdvLetterLine, Currency.Code);
        ReleasePurchAdvLetter(PurchAdvLetterHeader);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // create payment
        CreateGenJournalLine(GenJournalLine, PurchAdvLetterHeader."Pay-to Vendor No.", PurchAdvLetterLine."Amount Including VAT");
        GenJournalLine.Validate("Currency Code", Currency.Code);
        ChangeExchangeRateOnGenJnlLine(GenJournalLine, 0.6);
        GenJournalLine.Modify(true);

        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, PurchAdvLetterHeader."No.");

        // post payment
        PostGenJournalLine(GenJournalLine);

        // change exchange rate on purchase advance letter
        ChangeExchangeRateOnPurchAdvLetterHeader(PurchAdvLetterHeader, 0.6);
        PurchAdvLetterHeader.Modify(true);

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create purchase invoice
        CreatePurchInvoiceFromPurchAdvLetter(PurchHeader, PurchLine, PurchAdvLetterHeader, PurchAdvLetterLine, Currency.Code, 0.7);

        // link advance letter to purchase invoice
        LinkAdvanceLetterToPurchDocument(PurchHeader, PurchAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of purchase invoice
        GetPurchInvoiceStatistics(PurchHeader, PurchInvStatAmounts);

        // 2.Exercise:
        PostedDocNo := PostPurchaseDocument(PurchHeader);

        // 3.Verify:

        // verify statistics of purchase invoice
        Assert.AreNearlyEqual(-AmountIncVAT, PurchInvStatAmounts[1], Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(-VATAmount, PurchInvStatAmounts[2], Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(-Amount, PurchInvStatAmounts[3], Currency."Amount Rounding Precision", '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount Deducted", AmountIncVAT);

        // verify creation purchase invoice
        PurchInvHeader.Get(PostedDocNo);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::Deduction);
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry.Amount, -AmountIncVAT, 0.01, '');

        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::"VAT Deduction");
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -Amount, 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -VATAmount, 0.01, '');
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Base Amount (LCY)",
          -Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchInvHeader."Posting Date", PurchInvHeader."Currency Code",
              Amount, PurchInvHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection), 0.01, '');
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Amount (LCY)",
          -Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchInvHeader."Posting Date", PurchInvHeader."Currency Code",
              VATAmount, PurchInvHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection), 0.01, '');

        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", PurchInvHeader."No.");
        GLEntry.SetRange("Posting Date", PurchInvHeader."Posting Date");
        GLEntry.SetRange("G/L Account No.", Currency."Realized Gains Acc.");
        GLEntry.FindFirst;
        Assert.AreNearlyEqual(
          GLEntry.Amount,
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              AmountIncVAT, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection) -
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchInvHeader."Posting Date", PurchInvHeader."Currency Code",
              AmountIncVAT, PurchInvHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection), 0.01, '');
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,ChangeExchangeRateHandler,PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler,MessageHandler,YesConfirmHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOverpaymentWithForeignCurrency()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        CurrExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Test the posting refund and close Purchase Advance Letter with foreign currency.

        // 1.Setup:
        Initialize;

        // find foreign currency
        FindForeignCurrency(Currency);

        // create purchase advance letter
        CreatePurchAdvLetterWithCurrency(PurchAdvLetterHeader, PurchAdvLetterLine, Currency.Code);
        ReleasePurchAdvLetter(PurchAdvLetterHeader);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // create payment
        CreateGenJournalLine(GenJournalLine, PurchAdvLetterHeader."Pay-to Vendor No.", PurchAdvLetterLine."Amount Including VAT");
        GenJournalLine.Validate("Currency Code", Currency.Code);
        ChangeExchangeRateOnGenJnlLine(GenJournalLine, 0.6);
        GenJournalLine.Modify(true);

        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, PurchAdvLetterHeader."No.");

        // post payment
        PostGenJournalLine(GenJournalLine);

        // change exchange rate on purchase letter
        ChangeExchangeRateOnPurchAdvLetterHeader(PurchAdvLetterHeader, 0.6);
        PurchAdvLetterHeader.Modify(true);

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create purchase invoice
        CreatePurchInvoiceFromPurchAdvLetter(PurchHeader, PurchLine, PurchAdvLetterHeader, PurchAdvLetterLine, Currency.Code, 0.7);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(Round(Amount, 1, '<') - 1, 2));
        PurchLine.Modify(true);

        // link advance letter to purchase invoice
        LinkAdvanceLetterToPurchDocument(PurchHeader, PurchAdvLetterHeader."No.", '', true, 1);

        // post purchase invoice
        PostPurchaseDocument(PurchHeader);

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(PurchAdvLetterHeader);

        // 3.Verify:

        // verify statistics of purchase advance letter
        Assert.AreNearlyEqual(
          Amount, LibraryAdvanceStatistics.GetInvoicingAmount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          VATAmount, LibraryAdvanceStatistics.GetInvoicingVATAmount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              Amount, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          LibraryAdvanceStatistics.GetInvoicingVATBaseLCY, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              VATAmount, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          LibraryAdvanceStatistics.GetInvoicingVATAmountLCY, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              AmountIncVAT, PurchAdvLetterHeader."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection),
          LibraryAdvanceStatistics.GetInvoicingAmountIncludingVATLCY, Currency."Amount Rounding Precision", '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Document Type", PurchAdvLetterEntry."Document Type"::"Credit Memo");
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Base Amount", -(Amount - PurchLine.Amount), Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Amount", -(VATAmount - (PurchLine."Amount Including VAT" - PurchLine.Amount)),
          Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Base Amount (LCY)",
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              PurchAdvLetterEntry."VAT Base Amount", CurrExchangeRate.GetCurrentCurrencyFactor(PurchAdvLetterHeader."Currency Code")),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection), Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          PurchAdvLetterEntry."VAT Amount (LCY)",
          Round(
            CurrExchangeRate.ExchangeAmtFCYToLCY(
              PurchAdvLetterHeader."Posting Date", PurchAdvLetterHeader."Currency Code",
              PurchAdvLetterEntry."VAT Amount", CurrExchangeRate.GetCurrentCurrencyFactor(PurchAdvLetterHeader."Currency Code")),
            Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection), Currency."Amount Rounding Precision", '');

        // verify creation purchase credit memo
        PurchCrMemoHeader.SetCurrentKey("Letter No.");
        PurchCrMemoHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchCrMemoHeader.FindFirst;
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchAdvLetterWithRefundVAT()
    var
        PurchAdvPmntTemp: Record "Purchase Adv. Payment Template";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        Currency: Record Currency;
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Test the creation Purchase Advance Letter with refund VAT.

        // 1.Setup:
        Initialize;

        Currency.InitRoundingPrecision;

        // create purchase advance letter
        CreatePurchAdvPmntTemp(PurchAdvPmntTemp);
        FindVATPostingSetupEU(VATPostingSetup);
        CreatePurchAdvLetterWithVATPostingSetup(
          PurchAdvLetterHeader, PurchAdvLetterLine, PurchAdvPmntTemp.Code, VATPostingSetup);
        ReleasePurchAdvLetter(PurchAdvLetterHeader);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // create and post payment
        CreateAndPostPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine."Amount Including VAT");

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);

        // 2.Exercise:

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // 3.Verify:

        // verify statistics of purchase advance letter
        Assert.AreNearlyEqual(
          Amount, LibraryAdvanceStatistics.GetInvoicingAmount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(
          VATAmount, LibraryAdvanceStatistics.GetInvoicingVATAmount, Currency."Amount Rounding Precision", '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::"Pending Final Invoice");

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Deduct", AmountIncVAT);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::VAT);
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", Amount, Currency."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount",
          Round(Amount * VATPostingSetup."VAT %" / 100,
            Currency."Amount Rounding Precision", Currency.VATRoundingDirection),
          Currency."Amount Rounding Precision", '');

        VATEntry.SetCurrentKey("Document No.", "Posting Date");
        VATEntry.SetRange("Document No.", PurchAdvLetterEntry."Document No.");
        VATEntry.SetRange("Posting Date", PurchAdvLetterEntry."Posting Date");
        VATEntry.FindFirst;
        VATEntry.TestField(Base, 0);
        Assert.AreNearlyEqual(VATEntry.Amount,
          Round(Amount * VATPostingSetup."VAT %" / 100,
            Currency."Amount Rounding Precision", Currency.VATRoundingDirection),
          Currency."Amount Rounding Precision", '');

        // verify creation advance invoice
        PurchInvHeader.SetCurrentKey("Letter No.");
        PurchInvHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchInvHeader.FindFirst;
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvHeader.TestField(Amount, 0);
        PurchInvHeader.TestField("Amount Including VAT", 0);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelPurchAdvLetter()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
    begin
        // Test the canceling Purchase Advance Letter.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndReleasePurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(PurchAdvLetterHeader);

        // 3.Verify:

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Link", 0);
        PurchAdvLetterLine.TestField("Amount Linked", 0);
        PurchAdvLetterLine.TestField("Amount To Invoice", 0);
        PurchAdvLetterLine.TestField("Amount Invoiced", 0);
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);
        PurchAdvLetterLine.TestField("Amount Deducted", 0);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        Assert.IsTrue(PurchAdvLetterEntry.IsEmpty, PurchAdvLetterEntryExistsErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelPurchAdvLetterWithPayment()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
    begin
        // Test the canceling Purchase Advance Letter with payment.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(PurchAdvLetterHeader);

        // 3.Verify:

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Link", 0);
        PurchAdvLetterLine.TestField("Amount Linked", 0);
        PurchAdvLetterLine.TestField("Amount To Invoice", 0);
        PurchAdvLetterLine.TestField("Amount Invoiced", 0);
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);
        PurchAdvLetterLine.TestField("Amount Deducted", 0);
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,YesConfirmHandler,MessageHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CancelPurchAdvLetterWithPaymentAndAdvInvoice()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // Test the canceling Purchase Advance Letter with payment and Advance Invoice.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        Amount := PurchAdvLetterLine.Amount;
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // 2.Exercise:

        // post refund and close letter
        PostRefundAndCloseLetter(PurchAdvLetterHeader);

        // 3.Verify:

        // verify statistics of purchase advance letter
        Assert.AreNearlyEqual(
          Amount, LibraryAdvanceStatistics.GetInvoicingAmount, 0.01, '');
        Assert.AreNearlyEqual(
          VATAmount, LibraryAdvanceStatistics.GetInvoicingVATAmount, 0.01, '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Link", 0);
        PurchAdvLetterLine.TestField("Amount Linked", 0);
        PurchAdvLetterLine.TestField("Amount To Invoice", 0);
        PurchAdvLetterLine.TestField("Amount Invoiced", 0);
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);
        PurchAdvLetterLine.TestField("Amount Deducted", 0);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::VAT);
        PurchAdvLetterEntry.FindSet;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -Amount, 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -VATAmount, 0.01, '');
        PurchAdvLetterEntry.Next;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", Amount, 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", VATAmount, 0.01, '');

        // verify creation advance invoice
        PurchInvHeader.SetCurrentKey("Letter No.");
        PurchInvHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchInvHeader.FindFirst;
        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount, VATAmount);

        // verify creation purchase credit memo
        PurchCrMemoHeader.SetCurrentKey("Letter No.");
        PurchCrMemoHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchCrMemoHeader.FindFirst;
        PurchCrMemoHeader.CalcFields(Amount);
        PurchCrMemoHeader.TestField(Amount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvPaymSelectionHandler2,VATAmountLinesHandler,PurchAdvLetterStatisticsHandler2')]
    [Scope('OnPrem')]
    procedure StornoAndCreateAdvanceInvoice()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Test the storno Purchase Advance Letter which was payment and a re-creation Purchase Advance Invoice.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // post advance credit memo
        PostAdvanceCrMemo(PurchAdvLetterHeader);

        // change VAT Amount in VAT amount line
        ChangeVATAmountLine(PurchAdvLetterHeader."Template Code", PurchAdvLetterHeader."No.", Round(VATAmount, 1));

        // change external document no.
        PurchAdvLetterHeader.Validate("External Document No.", IncStr(PurchAdvLetterHeader."External Document No."));
        PurchAdvLetterHeader.Modify;

        // 2.Exercise:

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // 3.Verify:

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::"Pending Final Invoice");

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Deduct", AmountIncVAT);
        PurchAdvLetterLine.TestField("Amount Deducted", 0);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::VAT);
        PurchAdvLetterEntry.FindSet;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", Amount, 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", VATAmount, 0.01, '');
        PurchAdvLetterEntry.Next;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -Amount, 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -VATAmount, 0.01, '');
        PurchAdvLetterEntry.Next;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", AmountIncVAT - Round(VATAmount, 1), 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", Round(VATAmount, 1), 0.01, '');

        // verify creation advance invoice
        PurchInvHeader.SetCurrentKey("Letter No.");
        PurchInvHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchInvHeader.FindSet;
        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount, VATAmount);
        PurchInvHeader.Next;
        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount, Round(VATAmount, 1));

        // verify creation purchase credit memo
        PurchCrMemoHeader.SetCurrentKey("Letter No.");
        PurchCrMemoHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchCrMemoHeader.FindFirst;
        PurchCrMemoHeader.CalcFields(Amount);
        PurchCrMemoHeader.TestField(Amount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvPaymSelectionHandler2,VATAmountLinesHandler,PurchAdvLetterStatisticsHandler2,PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler,MessageHandler,PurchStatisticsHandler')]
    [Scope('OnPrem')]
    procedure AdjustVATByAdvPaymentDeduction()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        PurchInvStatAmounts: array[20] of Decimal;
    begin
        // Test the creation Purchase Advance Invoice after change VAT amount of VAT Amount Line and test the
        // correcting VAT by deducted VAT.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // change VAT Amount in VAT amount line
        ChangeVATAmountLine(PurchAdvLetterHeader."Template Code", PurchAdvLetterHeader."No.", Round(VATAmount, 1));

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create purchase invoice
        CreatePurchInvoiceFromPurchAdvLetter(PurchHeader, PurchLine, PurchAdvLetterHeader, PurchAdvLetterLine, '', 0);

        // link advance letter to purchase invoice
        LinkAdvanceLetterToPurchDocument(PurchHeader, PurchAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of purchase invoice
        GetPurchInvoiceStatistics(PurchHeader, PurchInvStatAmounts);

        // 2.Exercise:

        // correct VAT by deduct VAT
        CorrectVATbyDeductedVAT(PurchHeader);

        // post purchase invoice
        PostPurchaseDocument(PurchHeader);

        // 3.Verify:

        // verify statistics of purchase invoice
        Assert.AreNearlyEqual(-AmountIncVAT, PurchInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-Round(VATAmount, 1), PurchInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-(AmountIncVAT - Round(VATAmount, 1)), PurchInvStatAmounts[3], 0.01, '');
        Assert.AreNearlyEqual(0, PurchInvStatAmounts[4], 0.01, '');
        Assert.AreNearlyEqual(VATAmount - Round(VATAmount, 1), PurchInvStatAmounts[5], 0.01, '');
        Assert.AreNearlyEqual(Round(VATAmount, 1) - VATAmount, PurchInvStatAmounts[6], 0.01, '');

        // verify purchase advance letter
        VerifyPurchAdvLetter(PurchAdvLetterHeader."No.", PurchAdvLetterHeader.Status::Closed, 0, AmountIncVAT);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::VAT);
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", AmountIncVAT - Round(VATAmount, 1), 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", Round(VATAmount, 1), 0.01, '');
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler,MessageHandler,PurchStatisticsHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PartialPostingPurchAdvLetter()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchHeader: array[2] of Record "Purchase Header";
        PurchLine: array[2] of Record "Purchase Line";
        Amount: array[3] of Decimal;
        AmountIncVAT: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        PurchInvStatAmounts: array[2, 20] of Decimal;
    begin
        // Test the posting Purchase Advance Letter over two Purchase Invoice

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        Amount[1] := PurchAdvLetterLine.Amount;
        AmountIncVAT[1] := PurchAdvLetterLine."Amount Including VAT";
        VATAmount[1] := PurchAdvLetterLine."VAT Amount";

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create purchase invoice 1
        CreatePurchInvoice(
          PurchHeader[1], PurchLine[1],
          PurchAdvLetterHeader."Pay-to Vendor No.",
          PurchAdvLetterHeader."Posting Date",
          PurchAdvLetterLine."VAT Bus. Posting Group",
          PurchAdvLetterLine."VAT Prod. Posting Group",
          '', 0, false,
          LibraryRandom.RandDec(Round(Amount[1], 1, '<'), 2));

        Amount[2] := PurchLine[1].Amount;
        AmountIncVAT[2] := PurchLine[1]."Amount Including VAT";
        VATAmount[2] := AmountIncVAT[2] - Amount[2];

        // link advance letter to purchase invoice 1
        LinkAdvanceLetterToPurchDocument(PurchHeader[1], PurchAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of purchase invoice 1
        GetPurchInvoiceStatistics(PurchHeader[1], PurchInvStatAmounts[1]);

        // create purchase invoice 2
        CreatePurchInvoice(
          PurchHeader[2], PurchLine[2],
          PurchAdvLetterHeader."Pay-to Vendor No.",
          PurchAdvLetterHeader."Posting Date",
          PurchAdvLetterLine."VAT Bus. Posting Group",
          PurchAdvLetterLine."VAT Prod. Posting Group",
          '', 0, false,
          Amount[1] - PurchLine[1].Amount);

        Amount[3] := PurchLine[2].Amount;
        AmountIncVAT[3] := PurchLine[2]."Amount Including VAT";
        VATAmount[3] := AmountIncVAT[3] - Amount[3];

        // link advance letter to purchase invoice 2
        LinkAdvanceLetterToPurchDocument(PurchHeader[2], PurchAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of purchase invoice 2
        GetPurchInvoiceStatistics(PurchHeader[2], PurchInvStatAmounts[2]);

        // 2.Exercise:

        // post purchase invoice 1
        PostPurchaseDocument(PurchHeader[1]);

        // post purchase invoice 2
        PostPurchaseDocument(PurchHeader[2]);

        // 3.Verify:

        // verify statistics of purchase advance letter
        Assert.AreNearlyEqual(Amount[1], LibraryAdvanceStatistics.GetInvoicingAmount, 0.01, '');
        Assert.AreNearlyEqual(VATAmount[1], LibraryAdvanceStatistics.GetInvoicingVATAmount, 0.01, '');

        // verify statistics of purchase invoice 1
        Assert.AreNearlyEqual(-AmountIncVAT[2], PurchInvStatAmounts[1] [1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount[2], PurchInvStatAmounts[1] [2], 0.01, '');
        Assert.AreNearlyEqual(-Amount[2], PurchInvStatAmounts[1] [3], 0.01, '');

        // verify statistics of purchase invoice 2
        Assert.AreNearlyEqual(-AmountIncVAT[3], PurchInvStatAmounts[2] [1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount[3], PurchInvStatAmounts[2] [2], 0.01, '');
        Assert.AreNearlyEqual(-Amount[3], PurchInvStatAmounts[2] [3], 0.01, '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);
        PurchAdvLetterLine.TestField("Amount Deducted", AmountIncVAT[1]);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::"VAT Deduction");
        PurchAdvLetterEntry.FindSet;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -Amount[2], 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -VATAmount[2], 0.01, '');
        PurchAdvLetterEntry.Next;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -Amount[3], 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -VATAmount[3], 0.01, '');
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler,PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler,MessageHandler,PurchStatisticsHandler')]
    [Scope('OnPrem')]
    procedure MultiplePurchAdvLettersInOnePurchInvoice()
    var
        PurchAdvPmntTemp: Record "Purchase Adv. Payment Template";
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Amount: array[3] of Decimal;
        AmountIncVAT: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        PurchAdvStatAmounts: array[2, 20] of Decimal;
        PurchInvStatAmounts: array[20] of Decimal;
        PurchAdvLetterNo: array[2] of Code[20];
    begin
        // Test the posting two Purchase Advance Letter over one Purchase Invoice

        // 1.Setup:
        Initialize;

        // create purchase advance payment template
        CreatePurchAdvPmntTemp(PurchAdvPmntTemp);

        // find VAT posting setup
        FindVATPostingSetup(VATPostingSetup);

        // create vendor
        CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        // create purchase advance letter 1
        CreatePurchAdvLetterBase(
          PurchAdvLetterHeader, PurchAdvLetterLine,
          PurchAdvPmntTemp.Code, VATPostingSetup."VAT Prod. Posting Group",
          Vendor."No.", LibraryRandom.RandInt(1000));
        ReleasePurchAdvLetter(PurchAdvLetterHeader);

        PurchAdvLetterNo[1] := PurchAdvLetterHeader."No.";
        Amount[1] := PurchAdvLetterLine.Amount;
        AmountIncVAT[1] := PurchAdvLetterLine."Amount Including VAT";
        VATAmount[1] := PurchAdvLetterLine."VAT Amount";

        // create and post payment
        CreateAndPostPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine."Amount Including VAT");

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);
        PurchAdvStatAmounts[1] [1] := LibraryAdvanceStatistics.GetInvoicingAmount;
        PurchAdvStatAmounts[1] [2] := LibraryAdvanceStatistics.GetInvoicingVATAmount;

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        Clear(PurchAdvLetterHeader);
        Clear(PurchAdvLetterLine);

        // create purchase advance letter 2
        CreatePurchAdvLetterBase(
          PurchAdvLetterHeader, PurchAdvLetterLine,
          PurchAdvPmntTemp.Code, VATPostingSetup."VAT Prod. Posting Group",
          Vendor."No.", LibraryRandom.RandInt(1000));
        ReleasePurchAdvLetter(PurchAdvLetterHeader);

        PurchAdvLetterNo[2] := PurchAdvLetterHeader."No.";
        Amount[2] := PurchAdvLetterLine.Amount;
        AmountIncVAT[2] := PurchAdvLetterLine."Amount Including VAT";
        VATAmount[2] := PurchAdvLetterLine."VAT Amount";

        // create and post payment
        CreateAndPostPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine."Amount Including VAT");

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);
        PurchAdvStatAmounts[2] [1] := LibraryAdvanceStatistics.GetInvoicingAmount;
        PurchAdvStatAmounts[2] [2] := LibraryAdvanceStatistics.GetInvoicingVATAmount;

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create purchase invoice
        CreatePurchInvoice(
          PurchHeader, PurchLine,
          Vendor."No.",
          PurchAdvLetterHeader."Posting Date",
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group",
          '', 0, true,
          AmountIncVAT[1] + AmountIncVAT[2]);

        Amount[3] := PurchLine.Amount;
        AmountIncVAT[3] := PurchLine."Amount Including VAT";
        VATAmount[3] := AmountIncVAT[3] - Amount[3];

        // link advance letter to purchase invoice
        LinkAdvanceLetterToPurchDocument(PurchHeader, PurchAdvLetterNo[1], PurchAdvLetterNo[2], true, 1);

        // get amounts from statistics of purchase invoice
        GetPurchInvoiceStatistics(PurchHeader, PurchInvStatAmounts);

        // 2.Exercise:
        PostPurchaseDocument(PurchHeader);

        // 3.Verify:

        // verify statistics of purchase advance letter 1
        Assert.AreNearlyEqual(Amount[1], PurchAdvStatAmounts[1] [1], 0.1, '');
        Assert.AreNearlyEqual(VATAmount[1], PurchAdvStatAmounts[1] [2], 0.1, '');

        // verify statistics of purchase advance letter 2
        Assert.AreNearlyEqual(Amount[2], PurchAdvStatAmounts[2] [1], 0.1, '');
        Assert.AreNearlyEqual(VATAmount[2], PurchAdvStatAmounts[2] [2], 0.1, '');

        // verify statistics of purchase invoice
        Assert.AreNearlyEqual(-AmountIncVAT[3], PurchInvStatAmounts[1], 0.1, '');
        Assert.AreNearlyEqual(-VATAmount[3], PurchInvStatAmounts[2], 0.1, '');
        Assert.AreNearlyEqual(-Amount[3], PurchInvStatAmounts[3], 0.1, '');

        // verify purchase advance letter 1
        PurchAdvLetterHeader.Get(PurchAdvLetterNo[1]);
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);
        PurchAdvLetterLine.TestField("Amount Deducted", AmountIncVAT[1]);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::"VAT Deduction");
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -Amount[1], 0.1, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -VATAmount[1], 0.1, '');

        // verify purchase advance letter 2
        PurchAdvLetterHeader.Get(PurchAdvLetterNo[2]);
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);
        PurchAdvLetterLine.TestField("Amount Deducted", AmountIncVAT[2]);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::"VAT Deduction");
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -Amount[2], 0.1, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -VATAmount[2], 0.1, '');
    end;

    [Test]
    [HandlerFunctions('SetAdvanceLinkHandler,PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler,MessageHandler,PurchStatisticsHandler,PurchAdvPaymSelectionHandler,PurchAdvLetterStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PartialPayments()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        Amount: Decimal;
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        VATCoeficient: Decimal;
        PaymentAmount: array[2] of Decimal;
        PurchAdvStatAmounts: array[2, 2] of Decimal;
        PurchInvStatAmounts: array[20] of Decimal;
        AmountToInvoice: array[2] of Decimal;
        AmountInvoiced: array[2] of Decimal;
        Status: array[2] of Option;
    begin
        // Test the posting Purchase Advance Letter over two Payments

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndReleasePurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        Amount := PurchAdvLetterLine.Amount;
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";

        // split to two payment
        PaymentAmount[1] := Round(AmountIncVAT / 3);
        PaymentAmount[2] := Round(AmountIncVAT - (AmountIncVAT / 3));

        // create and post payment 1
        CreateGenJournalLine(GenJournalLine, PurchAdvLetterHeader."Pay-to Vendor No.", PaymentAmount[1]);
        LinkAdvanceLettersToGenJnlLine(GenJournalLine, PurchAdvLetterLine."Letter No.", PurchAdvLetterLine."Line No.");
        PostGenJournalLine(GenJournalLine);

        PurchAdvLetterHeader.CalcFields(Status);
        Status[1] := PurchAdvLetterHeader.Status;
        PurchAdvLetterLine.Get(PurchAdvLetterLine."Letter No.", PurchAdvLetterLine."Line No.");
        AmountToInvoice[1] := PurchAdvLetterLine."Amount To Invoice";
        AmountInvoiced[1] := PurchAdvLetterLine."Amount Invoiced";

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);
        PurchAdvStatAmounts[1] [1] := LibraryAdvanceStatistics.GetInvoicingAmount;
        PurchAdvStatAmounts[1] [2] := LibraryAdvanceStatistics.GetInvoicingVATAmount;

        // post advance invoice to payment 1
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create and post payment 2
        CreateGenJournalLine(GenJournalLine, PurchAdvLetterHeader."Pay-to Vendor No.", PaymentAmount[2]);
        LinkAdvanceLettersToGenJnlLine(GenJournalLine, PurchAdvLetterLine."Letter No.", PurchAdvLetterLine."Line No.");
        PostGenJournalLine(GenJournalLine);

        PurchAdvLetterHeader.CalcFields(Status);
        Status[2] := PurchAdvLetterHeader.Status;
        PurchAdvLetterLine.Get(PurchAdvLetterLine."Letter No.", PurchAdvLetterLine."Line No.");
        AmountToInvoice[2] := PurchAdvLetterLine."Amount To Invoice";
        AmountInvoiced[2] := PurchAdvLetterLine."Amount Invoiced";

        // get amounts from statistics of purchase advance letter
        LibraryAdvanceStatistics.SetPurchAdvLetter(PurchAdvLetterHeader);
        PurchAdvStatAmounts[2] [1] := LibraryAdvanceStatistics.GetInvoicingAmount;
        PurchAdvStatAmounts[2] [2] := LibraryAdvanceStatistics.GetInvoicingVATAmount;

        // change external document no.
        PurchAdvLetterHeader.Validate("External Document No.", IncStr(PurchAdvLetterHeader."External Document No."));
        PurchAdvLetterHeader.Modify;

        // post advance invoice to payment 2
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // create purchase invoice
        CreatePurchInvoiceFromPurchAdvLetter(PurchHeader, PurchLine, PurchAdvLetterHeader, PurchAdvLetterLine, '', 0);

        // link advance letter to purchase invoice
        LinkAdvanceLetterToPurchDocument(PurchHeader, PurchAdvLetterHeader."No.", '', true, 1);

        // get amounts from statistics of purchase invoice
        GetPurchInvoiceStatistics(PurchHeader, PurchInvStatAmounts);

        // 2.Exercise:

        // post purchase invoice
        PostPurchaseDocument(PurchHeader);

        // 3.Verify:

        // verify status
        Assert.AreNearlyEqual(
          PurchAdvLetterHeader.Status::"Pending Payment", Status[1], 0.01,
          StrSubstNo(StatusErr, PurchAdvLetterHeader.Status::"Pending Payment"));
        Assert.AreNearlyEqual(
          PurchAdvLetterHeader.Status::"Pending Invoice", Status[2], 0.01,
          StrSubstNo(StatusErr, PurchAdvLetterHeader.Status::"Pending Invoice"));

        // verify purchase advance letter amounts with payment 1
        VATCoeficient := 1 + PurchAdvLetterLine."VAT %" / 100;
        Assert.AreNearlyEqual(PaymentAmount[1], AmountToInvoice[1], 0.01, '');
        Assert.AreNearlyEqual(0, AmountInvoiced[1], 0.01, '');
        Assert.AreNearlyEqual(Round(PaymentAmount[1] / VATCoeficient), PurchAdvStatAmounts[1] [1], 0.01, '');
        Assert.AreNearlyEqual(
          Round(PaymentAmount[1] - PaymentAmount[1] / VATCoeficient),
          PurchAdvStatAmounts[1] [2], 0.01, '');

        // verify purchase advance letter amounts with payment 2
        Assert.AreNearlyEqual(PaymentAmount[2], AmountToInvoice[2], 0.01, '');
        Assert.AreNearlyEqual(PaymentAmount[1], AmountInvoiced[2], 0.01, '');
        Assert.AreNearlyEqual(Round(PaymentAmount[2] / VATCoeficient), PurchAdvStatAmounts[2] [1], 0.01, '');
        Assert.AreNearlyEqual(
          Round(PaymentAmount[2] - PaymentAmount[2] / VATCoeficient),
          PurchAdvStatAmounts[2] [2], 0.01, '');

        // verify statistics of purchase invoice
        Assert.AreNearlyEqual(-AmountIncVAT, PurchInvStatAmounts[1], 0.01, '');
        Assert.AreNearlyEqual(-VATAmount, PurchInvStatAmounts[2], 0.01, '');
        Assert.AreNearlyEqual(-Amount, PurchInvStatAmounts[3], 0.01, '');

        // verify purchase advance letter
        PurchAdvLetterHeader.Get(PurchAdvLetterHeader."No.");
        PurchAdvLetterHeader.CalcFields(Status);
        PurchAdvLetterHeader.TestField(Status, PurchAdvLetterHeader.Status::Closed);

        PurchAdvLetterLine.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterLine.FindFirst;
        PurchAdvLetterLine.TestField("Amount To Deduct", 0);
        PurchAdvLetterLine.TestField("Amount Deducted", AmountIncVAT);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::VAT);
        PurchAdvLetterEntry.FindSet;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", PurchAdvStatAmounts[1] [1], 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", PurchAdvStatAmounts[1] [2], 0.01, '');
        PurchAdvLetterEntry.Next;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", PurchAdvStatAmounts[2] [1], 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", PurchAdvStatAmounts[2] [2], 0.01, '');

        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::"VAT Deduction");
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -PurchAdvStatAmounts[1] [1], 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -PurchAdvStatAmounts[1] [2], 0.01, '');
        PurchAdvLetterEntry.Next;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", -PurchAdvStatAmounts[2] [1], 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", -PurchAdvStatAmounts[2] [2], 0.01, '');

        // verify creation purchase invoice
        PurchInvHeader.SetCurrentKey("Letter No.");
        PurchInvHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchInvHeader.FindFirst;
    end;

    [Test]
    [HandlerFunctions('PurchaseAdvLettersHandler,PurchAdvPaymSelectionHandler2,VATAmountLinesHandler,PurchAdvLetterStatisticsHandler2')]
    [Scope('OnPrem')]
    procedure AdjustVATInAdvanceInvoice()
    var
        PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvLetterEntry: Record "Purch. Advance Letter Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
        AmountToInvoice: Decimal;
        AmountInvoiced: Decimal;
        AdjustedVATAmount: Decimal;
    begin
        // Test the creation Purchase Advance Invoice after change VAT amount of VAT Amount Line.

        // 1.Setup:
        Initialize;

        // create and payment purchase advance letter
        CreateAndPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);

        PurchAdvLetterLine.Get(PurchAdvLetterLine."Letter No.", PurchAdvLetterLine."Line No.");
        AmountIncVAT := PurchAdvLetterLine."Amount Including VAT";
        VATAmount := PurchAdvLetterLine."VAT Amount";
        AmountToInvoice := PurchAdvLetterLine."Amount To Invoice";
        AmountInvoiced := PurchAdvLetterLine."Amount Invoiced";
        AdjustedVATAmount := Round(VATAmount, 1);

        // change VAT Amount in VAT amount line
        ChangeVATAmountLine(PurchAdvLetterHeader."Template Code", PurchAdvLetterHeader."No.", AdjustedVATAmount);

        // 2.Exercise:

        // post advance invoice
        PostAdvanceInvoice(PurchAdvLetterHeader);

        // 3.Verify:

        // verify purchase advance letter amounts
        Assert.AreNearlyEqual(AmountIncVAT, AmountToInvoice, 0.01, '');
        Assert.AreNearlyEqual(0, AmountInvoiced, 0.01, '');

        // verify purchase advance letter
        VerifyPurchAdvLetter(PurchAdvLetterHeader."No.", PurchAdvLetterHeader.Status::"Pending Final Invoice", AmountIncVAT, 0);

        // verify entries
        PurchAdvLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
        PurchAdvLetterEntry.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchAdvLetterEntry.SetRange("Entry Type", PurchAdvLetterEntry."Entry Type"::VAT);
        PurchAdvLetterEntry.FindFirst;
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Base Amount", AmountIncVAT - AdjustedVATAmount, 0.01, '');
        Assert.AreNearlyEqual(PurchAdvLetterEntry."VAT Amount", AdjustedVATAmount, 0.01, '');

        // verify creation purchase invoice
        PurchInvHeader.SetCurrentKey("Letter No.");
        PurchInvHeader.SetRange("Letter No.", PurchAdvLetterHeader."No.");
        PurchInvHeader.FindFirst;
        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount, AdjustedVATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetLineDiscountOnPagePurchaseInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207109] Values of "Amount" and "Amount Including VAT" of Purchase Line have to equal to 0 when setting value "Line Discount %" = 100 on the page "Purchase Invoice"
        Initialize;

        // [GIVEN] "Purchases & Payables Setup"."Allow VAT Difference" = TRUE
        UpdatePurchaseSetupAllowVATDifference;

        // [GIVEN] Purchase invoice with line with Amount = 200 and Line discount % < 100
        CreatePurchInvoiceWithVATPostingSetup(PurchaseLine);

        // [GIVEN] Open page Purchase Invoice
        PurchaseInvoice.OpenEdit;
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseInvoice.PurchLines.GotoRecord(PurchaseLine);

        // [WHEN] Set "Line Discount %" = 100 on the page
        PurchaseInvoice.PurchLines."Line Discount %".SetValue(100);
        PurchaseInvoice.PurchLines.Next; // SETVALUE does not MODIFY record on server, we need move out line

        // [THEN] "Purchase Line"."Amount" = 0
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField(Amount, 0);

        // [THEN] "Purchase Line"."Amount Including VAT" = 0
        PurchaseLine.TestField("Amount Including VAT", 0);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdateGLSetup;
        UpdatePurchaseSetup;

        isInitialized := true;
        Commit;
    end;

    local procedure CreateVendorPostingGroup(var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        LibraryAdvance.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup.Validate("Advance Account", GetNewGLAccountNo);
        VendorPostingGroup.Validate("Payables Account", GetNewGLAccountNo);
        VendorPostingGroup.Validate("Invoice Rounding Account", GetNewGLAccountNo);
        VendorPostingGroup.Validate("Debit Rounding Account", GetNewGLAccountNo);
        VendorPostingGroup.Modify(true);
    end;

    local procedure CreatePurchAdvPmntTemp(var PurchaseAdvPaymentTemplate: Record "Purchase Adv. Payment Template")
    begin
        LibraryAdvance.CreatePurchAdvPmntTemplate(PurchaseAdvPaymentTemplate);
        PurchaseAdvPaymentTemplate.Validate("Post Advance VAT Option", PurchaseAdvPaymentTemplate."Post Advance VAT Option"::Always);
        PurchaseAdvPaymentTemplate.Validate("Amounts Including VAT", true);
        PurchaseAdvPaymentTemplate.Modify(true);
    end;

    local procedure CreateAndPaymentPurchAdvLetter(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvLetterLine: Record "Purch. Advance Letter Line")
    begin
        CreateAndReleasePurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);
        CreateAndPostPaymentPurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine."Amount Including VAT")
    end;

    local procedure CreateAndReleasePurchAdvLetter(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvLetterLine: Record "Purch. Advance Letter Line")
    begin
        CreatePurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);
        ReleasePurchAdvLetter(PurchAdvLetterHeader);
    end;

    local procedure CreatePurchAdvLetter(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvLetterLine: Record "Purch. Advance Letter Line")
    var
        PurchAdvPmntTemp: Record "Purchase Adv. Payment Template";
    begin
        CreatePurchAdvPmntTemp(PurchAdvPmntTemp);
        CreatePurchAdvLetterWithTemplate(
          PurchAdvLetterHeader, PurchAdvLetterLine, PurchAdvPmntTemp.Code);
    end;

    local procedure CreatePurchAdvLetterWithTemplate(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvLetterLine: Record "Purch. Advance Letter Line"; PurchAdvPmntTempCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchAdvLetterWithVATPostingSetup(
          PurchAdvLetterHeader, PurchAdvLetterLine, PurchAdvPmntTempCode, VATPostingSetup);
    end;

    local procedure CreatePurchAdvLetterWithVATPostingSetup(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvLetterLine: Record "Purch. Advance Letter Line"; PurchAdvPmntTempCode: Code[10]; VATPostingSetup: Record "VAT Posting Setup")
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        CreatePurchAdvLetterBase(
          PurchAdvLetterHeader, PurchAdvLetterLine,
          PurchAdvPmntTempCode, VATPostingSetup."VAT Prod. Posting Group",
          Vendor."No.", LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreatePurchAdvLetterWithCurrency(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvLetterLine: Record "Purch. Advance Letter Line"; CurrencyCode: Code[10])
    begin
        CreatePurchAdvLetter(PurchAdvLetterHeader, PurchAdvLetterLine);
        PurchAdvLetterHeader.Validate("Currency Code", CurrencyCode);
        PurchAdvLetterHeader.Modify(true);

        PurchAdvLetterLine.Validate("Currency Code", CurrencyCode);
        PurchAdvLetterLine.Modify(true);
    end;

    local procedure CreatePurchAdvLetterBase(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvLetterLine: Record "Purch. Advance Letter Line"; PurchAdvPmntTempCode: Code[10]; VATProdPostingGroupCode: Code[20]; VendorNo: Code[20]; Amount: Decimal)
    begin
        LibraryAdvance.CreatePurchAdvLetterHeader(PurchAdvLetterHeader, PurchAdvPmntTempCode, VendorNo);
        LibraryAdvance.CreatePurchAdvLetterLine(PurchAdvLetterLine, PurchAdvLetterHeader, VATProdPostingGroupCode, Amount);
    end;

    local procedure CreatePurchAdvLetterFromPurchDoc(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; PurchHeader: Record "Purchase Header")
    var
        PurchAdvPmntTemp: Record "Purchase Adv. Payment Template";
    begin
        CreatePurchAdvPmntTemp(PurchAdvPmntTemp);
        LibraryAdvance.CreatePurchAdvLetterFromPurchDoc(PurchAdvLetterHeader, PurchHeader, PurchAdvPmntTemp.Code);
    end;

    local procedure CreateAndPostPaymentPurchAdvLetter(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(GenJournalLine, PurchAdvLetterHeader."Pay-to Vendor No.", Amount);
        LinkWholeAdvanceLetterToGenJnlLine(GenJournalLine, PurchAdvLetterHeader."No.");
        PostGenJournalLine(GenJournalLine);
    end;

    local procedure CreatePurchInvoiceWithVATPostingSetup(var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        DummyGLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandIntInRange(10, 50));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 50));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CreatePurchOrder(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        Vend: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        FindVATPostingSetup(VATPostingSetup);

        CreateVendor(Vend);
        Vend.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vend.Modify(true);

        CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vend."No.");
        PurchHeader.Validate("Posting Date", WorkDate);
        PurchHeader.Validate("VAT Date", WorkDate);
        PurchHeader.Validate("Prepayment %", 100);
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchInvoice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; VendorNo: Code[20]; PostingDate: Date; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; CurrencyCode: Code[10]; ExchangeRate: Decimal; PricesIncVAT: Boolean; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        GLAccount.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Validate("Prepayment %", 100);
        PurchHeader.Validate("Prices Including VAT", PricesIncVAT);
        if CurrencyCode <> '' then
            PurchHeader.Validate("Currency Code", CurrencyCode);
        if ExchangeRate <> 0 then
            ChangeExchangeRateOnPurchDocument(PurchHeader, ExchangeRate);
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchInvoiceFromPurchAdvLetter(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; PurchAdvLetterLine: Record "Purch. Advance Letter Line"; CurrencyCode: Code[10]; ExchangeRate: Decimal)
    begin
        CreatePurchInvoice(
          PurchHeader, PurchLine,
          PurchAdvLetterHeader."Pay-to Vendor No.",
          PurchAdvLetterHeader."Posting Date",
          PurchAdvLetterLine."VAT Bus. Posting Group",
          PurchAdvLetterLine."VAT Prod. Posting Group",
          CurrencyCode,
          ExchangeRate,
          true,
          PurchAdvLetterLine."Amount Including VAT");
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    var
        VendPostingGroup: Record "Vendor Posting Group";
    begin
        CreateVendorPostingGroup(VendPostingGroup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Vendor Posting Group", VendPostingGroup.Code);
        Vendor.Modify(true);
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

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; Amount: Decimal)
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
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
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
        VATPostingSetup."VAT %" := LibraryRandom.RandIntInRange(10, 50);
        VATPostingSetup.Modify;
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Purch. Advance VAT Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Purch. Advance Offset VAT Acc.", GetNewGLAccountNo);
        VATPostingSetup.Modify(true);
    end;

    local procedure FindVATPostingSetupEU(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Purch. Advance VAT Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Purch. Advance Offset VAT Acc.", GetNewGLAccountNo);
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

    local procedure GetPurchInvoiceStatistics(PurchHeader: Record "Purchase Header"; var Amounts: array[20] of Decimal)
    var
        VariantAmount: Variant;
    begin
        OpenPurchInvoiceStatistics(PurchHeader);
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

    local procedure GetPurchOrderStatistics(PurchHeader: Record "Purchase Header"; var Amounts: array[20] of Decimal)
    var
        VariantAmount: Variant;
    begin
        OpenPurchOrderStatistics(PurchHeader);
        LibraryVariableStorage.Dequeue(VariantAmount);
        Amounts[1] := VariantAmount;
        LibraryVariableStorage.Dequeue(VariantAmount);
        Amounts[2] := VariantAmount;
    end;

    local procedure UpdateGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        GLSetup.Validate("Prepayment Type", GLSetup."Prepayment Type"::Advances);
        GLSetup.Validate("Correction As Storno", true);
        GLSetup.Validate("Max. VAT Difference Allowed", 5);
        GLSetup.Modify(true);
    end;

    local procedure UpdatePurchaseSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get;
        PurchSetup.Validate("Automatic Adv. Invoice Posting", false);
        PurchSetup.Validate("Allow VAT Difference", true);
        PurchSetup.Modify(true);
    end;

    local procedure UpdatePurchaseSetupAllowVATDifference()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup."Allow VAT Difference" := true;
        PurchasesPayablesSetup.Modify;
    end;

    local procedure ReleasePurchAdvLetter(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    begin
        LibraryAdvance.ReleasePurchAdvLetter(PurchAdvLetterHeader);
    end;

    local procedure PostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAdvanceInvoice(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    begin
        LibraryAdvance.PostPurchAdvInvoice(PurchAdvLetterHeader);
    end;

    local procedure PostAdvanceCrMemo(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    begin
        LibraryAdvance.PostPurchAdvCrMemo(PurchAdvLetterHeader);
    end;

    local procedure PostPurchaseDocument(var PurchHeader: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure PostRefundAndCloseLetter(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header")
    begin
        LibraryAdvance.PostRefundAndClosePurchAdvLetter(PurchAdvLetterHeader);
    end;

    local procedure VerifyPurchAdvLetter(LetterNo: Code[20]; Status: Option; AmountToDeduct: Decimal; AmountDeducted: Decimal)
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterHeader.Get(LetterNo);
        PurchAdvanceLetterHeader.CalcFields(Status);
        PurchAdvanceLetterHeader.TestField(Status, Status);

        PurchAdvanceLetterLine.SetRange("Letter No.", LetterNo);
        PurchAdvanceLetterLine.FindFirst;
        PurchAdvanceLetterLine.TestField("Amount To Deduct", AmountToDeduct);
        PurchAdvanceLetterLine.TestField("Amount Deducted", AmountDeducted);
    end;

    local procedure ChangeExchangeRateOnGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; NewExchangeRate: Decimal)
    begin
        // required ChangeExchangeRateHandler

        LibraryVariableStorage.Enqueue(NewExchangeRate);
        GenJournalLine.Validate("Currency Factor",
          LibraryAdvance.ChangeExchangeRate(
            GenJournalLine."Currency Code", GenJournalLine."Currency Factor", GenJournalLine."Posting Date"));
    end;

    local procedure ChangeExchangeRateOnPurchAdvLetterHeader(var PurchAdvLetterHeader: Record "Purch. Advance Letter Header"; NewExchangeRate: Decimal)
    begin
        // required ChangeExchangeRateHandler

        LibraryVariableStorage.Enqueue(NewExchangeRate);
        PurchAdvLetterHeader.Validate("Currency Factor",
          LibraryAdvance.ChangeExchangeRate(
            PurchAdvLetterHeader."Currency Code", PurchAdvLetterHeader."Currency Factor", PurchAdvLetterHeader."Posting Date"));
    end;

    local procedure ChangeExchangeRateOnPurchDocument(var PurchHeader: Record "Purchase Header"; NewExchangeRate: Decimal)
    begin
        // required ChangeExchangeRateHandler

        LibraryVariableStorage.Enqueue(NewExchangeRate);
        PurchHeader.Validate("Currency Factor",
          LibraryAdvance.ChangeExchangeRate(
            PurchHeader."Currency Code", PurchHeader."Currency Factor", PurchHeader."Posting Date"));
    end;

    local procedure LinkAdvanceLetterToPurchDocument(var PurchHeader: Record "Purchase Header"; PurchAdvLetterNo1: Code[20]; PurchAdvLetterNo2: Code[20]; ApplyByVATGroups: Boolean; LinkAmount: Option)
    begin
        // required PurchAdvLetterLinkCardHandler,PurchLetHeaderAdvLinkHandler

        LibraryVariableStorage.Enqueue(ApplyByVATGroups);
        LibraryVariableStorage.Enqueue(LinkAmount); // 1 - Invocing, 2 - Remaining
        LibraryVariableStorage.Enqueue(PurchAdvLetterNo1);
        LibraryVariableStorage.Enqueue(PurchAdvLetterNo2);
        LibraryAdvance.LinkAdvanceLetterToPurchDocument(PurchHeader);
    end;

    local procedure LinkWholeAdvanceLetterToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchAdvLetterNo: Code[20])
    begin
        // required PurchaseAdvLettersHandler

        LibraryVariableStorage.Enqueue(PurchAdvLetterNo);
        LibraryAdvance.LinkWholeAdvanceLetterToGenJnlLine(GenJnlLine);
    end;

    local procedure LinkAdvanceLettersToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchAdvLetterNo: Code[20]; LineNo: Integer)
    begin
        // required SetAdvanceLinkHandler

        LibraryVariableStorage.Enqueue(2); // 2 - letter line
        LibraryVariableStorage.Enqueue(PurchAdvLetterNo);
        LibraryVariableStorage.Enqueue(LineNo);
        LibraryAdvance.LinkAdvanceLettersToGenJnlLine(GenJnlLine);
    end;

    local procedure CorrectVATbyDeductedVAT(var PurchHeader: Record "Purchase Header")
    begin
        LibraryAdvance.CorrectVATByPurchDeductedVAT(PurchHeader);
    end;

    local procedure ChangeVATAmountLine(PurchAdvPmntTempCode: Code[10]; PurchAdvLetterNo: Code[20]; NewVATAmount: Decimal)
    var
        PurchAdvLetters: TestPage "Purchase Advance Letters";
        PurchAdvLetter: TestPage "Purchase Advance Letter";
    begin
        // required PurchAdvPaymSelectionHandler2,PurchAdvLetterStatisticsHandler2,VATAmountLinesHandler

        LibraryVariableStorage.Enqueue(PurchAdvPmntTempCode);

        PurchAdvLetters.OpenView;
        PurchAdvLetters.GotoKey(PurchAdvLetterNo);
        PurchAdvLetter.Trap;
        PurchAdvLetters.View.Invoke;

        LibraryVariableStorage.Enqueue(NewVATAmount);
        PurchAdvLetter.Statistics.Invoke;
        PurchAdvLetter.OK.Invoke;
        PurchAdvLetters.OK.Invoke;
    end;

    local procedure OpenPurchOrderStatistics(var PurchHeader: Record "Purchase Header")
    var
        PurchOrder: TestPage "Purchase Order";
    begin
        // required PurchOrderStatisticsHandler

        PurchOrder.OpenView;
        PurchOrder.GotoKey(PurchHeader."Document Type", PurchHeader."No.");
        PurchOrder.Statistics.Invoke;
        PurchOrder.OK.Invoke;
    end;

    local procedure OpenPurchInvoiceStatistics(var PurchHeader: Record "Purchase Header")
    var
        PurchInvoice: TestPage "Purchase Invoice";
    begin
        // required PurchStatisticsHandler

        PurchInvoice.OpenView;
        PurchInvoice.GotoKey(PurchHeader."Document Type", PurchHeader."No.");
        PurchInvoice.Statistics.Invoke;
        PurchInvoice.OK.Invoke;
    end;

    local procedure IsVariantNull(Variant: Variant): Boolean
    begin
        exit(Format(Variant) = '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdvLettersHandler(var PurchaseAdvLetters: TestPage "Purchase Adv. Letters")
    var
        PurchAdvLetterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PurchAdvLetterNo);
        PurchaseAdvLetters.GotoKey(PurchAdvLetterNo);
        PurchaseAdvLetters.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchAdvLetterStatisticsHandler(var PurchAdvLetterStatistics: TestPage "Purch. Adv. Letter Statistics")
    begin
        LibraryAdvanceStatistics.SetPurchAdvLetterStatistics(PurchAdvLetterStatistics);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchAdvLetterStatisticsHandler2(var PurchAdvLetterStatistics: TestPage "Purch. Adv. Letter Statistics")
    begin
        PurchAdvLetterStatistics."TempVATAmountLine2.COUNT".DrillDown;
        PurchAdvLetterStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchAdvPaymSelectionHandler(var PurchAdvPaymSelection: TestPage "Purchase Adv. Paym. Selection")
    begin
        PurchAdvPaymSelection.GotoKey(LibraryAdvanceStatistics.GetTemplateCode);
        PurchAdvPaymSelection.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchAdvPaymSelectionHandler2(var PurchAdvPaymSelection: TestPage "Purchase Adv. Paym. Selection")
    var
        TemplateCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateCode);
        PurchAdvPaymSelection.GotoKey(TemplateCode);
        PurchAdvPaymSelection.OK.Invoke;
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
    procedure PurchAdvLetterLinkCardHandler(var PurchAdvLetterLinkCard: TestPage "Purch. Adv. Letter Link. Card")
    var
        ApplyByVATGroups: Variant;
        LinkAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ApplyByVATGroups);
        LibraryVariableStorage.Dequeue(LinkAmount);

        PurchAdvLetterLinkCard.ApplyByVATGroups.SetValue(ApplyByVATGroups);
        PurchAdvLetterLinkCard.QtyType.SetValue(LinkAmount);
        PurchAdvLetterLinkCard.LetterNo.DrillDown;
        PurchAdvLetterLinkCard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchLetHeaderAdvLinkHandler(var PurchLetHeaderAdvLink: TestPage "Purch.Let.Head. - Adv.Link.")
    var
        PurchAdvLetterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PurchAdvLetterNo);

        if not IsVariantNull(PurchAdvLetterNo) then begin
            PurchLetHeaderAdvLink.GotoKey(PurchAdvLetterNo);
            PurchLetHeaderAdvLink.Mark.Invoke;
        end;

        LibraryVariableStorage.Dequeue(PurchAdvLetterNo);

        if not IsVariantNull(PurchAdvLetterNo) then begin
            PurchLetHeaderAdvLink.GotoKey(PurchAdvLetterNo);
            PurchLetHeaderAdvLink.Mark.Invoke;
        end;

        PurchLetHeaderAdvLink."Link Selected Advance Letters".Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    var
        VATAmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmountLCY);
        VATAmountLines."VAT Amount (LCY)".SetValue(VATAmountLCY);
        VATAmountLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsHandler(var PurchOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(PurchOrderStatistics."-""Adv.Letter Link.Amt. to Deduct""".Value);
        LibraryVariableStorage.Enqueue(PurchOrderStatistics."TempTotVATAmountLinePrep.""VAT Amount""".Value);
        PurchOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchStatisticsHandler(var PurchInvStatistics: TestPage "Purchase Statistics")
    begin
        LibraryVariableStorage.Enqueue(PurchInvStatistics."-""Adv.Letter Link.Amt. to Deduct""".Value);
        LibraryVariableStorage.Enqueue(PurchInvStatistics."TempTotVATAmountLinePrep.""VAT Amount""".Value);
        LibraryVariableStorage.Enqueue(PurchInvStatistics."TempTotVATAmountLinePrep.""VAT Base""".Value);
        LibraryVariableStorage.Enqueue(PurchInvStatistics."TotalPurchLine.""Amount Including VAT""-""Adv.Letter Link.Amt. to Deduct""".Value);
        LibraryVariableStorage.Enqueue(PurchInvStatistics."TempTotVATAmountLineTot.""VAT Amount""".Value);
        LibraryVariableStorage.Enqueue(PurchInvStatistics."TempTotVATAmountLineTot.""VAT Base""".Value);
        PurchInvStatistics.OK.Invoke;
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

