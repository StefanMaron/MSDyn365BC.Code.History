codeunit 18918 "TCS On Sales Journal"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithRoundOff()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354495 - Check if the system is calculating TCS rounded off on each component (TCS amount, surcharge amount, eCess amount) while raising invoice or receiving advance from the customer using Sales Journal
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithoutPANWithoutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, True, True);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithoutAccountingPeriod()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TCSPostingSetup: Record "TCS Posting Setup";
    begin
        //Scenario 354496 -Check if the program is allowing the posting of Invoice using the Sales Journal with TCS  where Accounting Year has not been specified
        //Scenario 354497 -Check if the program is allowing the posting of Invoice using the Sales Journal with TCS information where Accounting Period has been specified but Quarter for the period is not specified.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Created General Journal with TCS
        SalesJnlLineForTCS(GenJournalLine, Customer, CalcDate('<-1Y>', TCSSalesLibrary.FindStartDateOnAccountingPeriod()));
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Show expected error
        Assert.ExpectedError(IncomeTaxAccountingErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithoutTCAN()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TCSPostingSetup: Record "TCS Posting Setup";
    begin
        // [Scenario 354498] -Check if the program is allowing the posting of Invoice using the Sales Journal with TCS calculation where TCAN No. has not been defined
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());
        LibraryTCS.RemoveTCANOnCompInfo();

        // [WHEN] Created General Journal with TCS
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Expected erro: TCAN No. not defined
        Assert.ExpectedError(StrSubstNo(TCANNoErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithThresholdAndSurchargeOverlook()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354499 -Check if the program is calculating TCS using Sales Journal with threshold and surcharge overlook for NOC lines of a particular customer.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, True, True);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithThresholdOverlook()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354500 - Check if the program is calculating TCS in case an invoice is raised to the Customer using Sales Journal and Threshold Overlook is selected.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, false);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, True, false);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithoutThresholdOverlook()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354501 - Check if the program is gcalculating TCS in case an invoice is raised to the Customer using Sales Journal and Threshold Overlook is not selected.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, false, false);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, false, false);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithoutThresholdAndSurchargeOverlook()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354502 -Check if the program is calculating TCS in Sales Journal with no threshold and surcharge overlook for NOD lines of a particular Customer
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, false, false);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, false, false);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithConcessional()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354504 - Check if the program is calculating TCS using Sales Journal with concessional codes.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, True, True);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithMultiTaxRateEffectiveDate()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354505 -Check if the program is calculating TCS using Sales Journal in case of different rates for same NOC with different effective dates.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithConcessional(Customer, false, false);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, false, false);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithCurrency()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        DocumentNo: Code[20];
    begin
        //[Scenario] 354507 -Check if the program is calculating TCS using Sales Journal in case of Foreign Currency.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCSWithCurrency(GenJournalLine, Customer, Currency);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, True, True);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithoutPAN()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354510 - Check if the program is calculating TCS on higher rate in case an invoice is raised to the Customer which is not having PAN No. using Sales Journal.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithoutPANWithoutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, True, True);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithConcessionalCode()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354511 - Check if the program is calculating TCS on Lower rate/zero rate in case an invoice is raised to the Customer is having a certificate using Sales Journal.
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, True, True);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromSalesJnlWithMultiLine()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[Scenario] 354442 - Check if the program is calculating TCS while creating a single invoice with multiple expenses using Sales Journal
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        SalesJnlLineForTCS(GenJournalLine, Customer, WorkDate());
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine,
            GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name",
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            20000);
        TCSSalesLibrary.CalculateTCS(GenJournalLine);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", True, True, True);
    end;

    local procedure SalesJnlLineForTCS(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateSalesJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
        GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        TCSSalesLibrary.CalculateTCS(GenJournalLine);
    end;

    local procedure SalesJnlLineForTCSWithCurrency(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; Currency: Record Currency);
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateSalesJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
        GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Validate("Posting Date", WorkDate());
        CreateCurrencyWithExchangeRate(Currency);
        GenJournalLine.Validate("Currency Code", Currency.Code);
        TCSSalesLibrary.CalculateTCS(GenJournalLine);
        GenJournalLine.Modify(true);
    end;

    LOCAL procedure VerifyTCSEntry(DocumentNo: Code[20]; TCSBaseAmount: Decimal; CurrencyFactor: Decimal; WithPAN: Boolean; TCSThresholdOverlook: Boolean; SurchargeOverlook: Boolean)
    var
        TCSEntry: Record "TCS Entry";
        ExpectedTCSAmount, ExpectedSurchargeAmount, ExpectedEcessAmount, ExpectedSHEcessAmount : Decimal;
        TCSPercentage, NonPANTCSPercentage, SurchargePercentage, eCessPercentage, SHECessPercentage : Decimal;
        TCSThresholdAmount, SurchargeThresholdAmount : Decimal;
    begin
        Evaluate(TCSPercentage, Storage.Get('TCSPercentage'));
        Evaluate(NonPANTCSPercentage, Storage.Get('NonPANTCSPercentage'));
        Evaluate(SurchargePercentage, Storage.Get('SurchargePercentage'));
        Evaluate(eCessPercentage, Storage.Get('eCessPercentage'));
        Evaluate(SHECessPercentage, Storage.Get('SHECessPercentage'));
        Evaluate(TCSThresholdAmount, Storage.Get('TCSThresholdAmount'));
        Evaluate(SurchargeThresholdAmount, Storage.Get('SurchargeThresholdAmount'));

        if CurrencyFactor = 0 then
            CurrencyFactor := 1;
        if (TCSBaseAmount < TCSThresholdAmount) and (TCSThresholdOverlook = false) then
            ExpectedTCSAmount := 0
        else
            if WithPAN then
                ExpectedTCSAmount := TCSBaseAmount * TCSPercentage / 100 / CurrencyFactor
            else
                ExpectedTCSAmount := TCSBaseAmount * NonPANTCSPercentage / 100 / CurrencyFactor;

        if (TCSBaseAmount < SurchargeThresholdAmount) and (SurchargeOverlook = false) then
            ExpectedSurchargeAmount := 0
        else
            ExpectedSurchargeAmount := ExpectedTCSAmount * SurchargePercentage / 100;
        ExpectedEcessAmount := (ExpectedTCSAmount + ExpectedSurchargeAmount) * eCessPercentage / 100;
        ExpectedSHEcessAmount := (ExpectedTCSAmount + ExpectedSurchargeAmount) * SHECessPercentage / 100;
        TCSEntry.SETRANGE("Document No.", DocumentNo);
        TCSEntry.FINDFIRST();

        Assert.AreNearlyEqual(
          TCSBaseAmount / CurrencyFactor, TCSEntry."TCS Base Amount", LibraryTCS.GetTCSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("TCS Base Amount"), TCSEntry.TABLECAPTION()));
        if WithPAN then
            Assert.AreEqual(
              TCSPercentage, TCSEntry."TCS %",
              STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("TCS %"), TCSEntry.TABLECAPTION()))
        else
            Assert.AreEqual(
            NonPANTCSPercentage, TCSEntry."TCS %",
            STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("TCS %"), TCSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedTCSAmount, TCSEntry."TCS Amount", LibraryTCS.GetTCSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("TCS Amount"), TCSEntry.TABLECAPTION()));
        Assert.AreEqual(
          SurchargePercentage, TCSEntry."Surcharge %",
          STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("Surcharge %"), TCSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedSurchargeAmount, TCSEntry."Surcharge Amount", LibraryTCS.GetTCSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("Surcharge Amount"), TCSEntry.TABLECAPTION()));
        Assert.AreEqual(
          eCessPercentage, TCSEntry."eCESS %",
          STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("eCESS %"), TCSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedEcessAmount, TCSEntry."eCESS Amount", LibraryTCS.GetTCSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("eCESS Amount"), TCSEntry.TABLECAPTION()));
        Assert.AreEqual(
          SHECessPercentage, TCSEntry."SHE Cess %",
          STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("SHE Cess %"), TCSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedSHEcessAmount, TCSEntry."SHE Cess Amount", LibraryTCS.GetTCSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TCSEntry.FIELDNAME("SHE Cess Amount"), TCSEntry.TABLECAPTION()));
    end;

    local procedure CreateSalesJournalTemplate(Var GenJournalTemplate: Record "Gen. Journal Template")
    var
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Sales);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate(var Currency: Record Currency)
    var
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 100, LibraryRandom.RandDecInDecimalRange(70, 80, 2));
    end;

    local procedure VerifyGLEntryWithTCS(DocumentNo: Code[20]; TCSAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, TCSAccountNo);
        GLEntry.TESTFIELD(Amount, GetTCSAmount(DocumentNo));
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; TCSAccountNo: Code[20])
    begin
        GLEntry.SETRANGE("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", TCSAccountNo);
        if GLEntry.FindFirst() then;
    end;

    local procedure GetTCSAmount(DocumentNo: Code[20]): Decimal
    var
        TCSEntry: Record "TCS Entry";
        TCSAmount: Decimal;
    begin
        TCSEntry.SetRange("Document No.", DocumentNo);
        if TCSEntry.FindSet() then
            repeat
                TCSAmount += TCSEntry."Total TCS Including SHE CESS";
            until TCSEntry.Next() = 0;
        exit(-TCSAmount);
    end;

    local procedure CreateTaxRate()
    var
        TCSSetup: Record "TCS Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TCSSetup.Get() then
            exit;

        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TCSSetup."Tax Type");
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates");
    var
        TCSPercentage: Decimal;
        NonPANTCSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        EffectiveDate: Date;
        TCSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
    begin
        Evaluate(EffectiveDate, Storage.Get('EffectiveDate'));
        Evaluate(TCSPercentage, Storage.Get('TCSPercentage'));
        Evaluate(NonPANTCSPercentage, Storage.Get('NonPANTCSPercentage'));
        Evaluate(SurchargePercentage, Storage.Get('SurchargePercentage'));
        Evaluate(eCessPercentage, Storage.Get('eCessPercentage'));
        Evaluate(SHECessPercentage, Storage.Get('SHECessPercentage'));
        Evaluate(TCSThresholdAmount, Storage.Get('TCSThresholdAmount'));
        Evaluate(SurchargeThresholdAmount, Storage.Get('SurchargeThresholdAmount'));

        TaxRate.AttributeValue1.SetValue(Storage.Get('TCSNOCType'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('TCSAssesseeCode'));
        TaxRate.AttributeValue3.SetValue(Storage.Get('TCSConcessionalCode'));
        TaxRate.AttributeValue4.SetValue(EffectiveDate);
        TaxRate.AttributeValue5.SetValue(TCSPercentage);
        TaxRate.AttributeValue6.SetValue(SurchargePercentage);
        TaxRate.AttributeValue7.SetValue(NonPANTCSPercentage);
        TaxRate.AttributeValue8.SetValue(eCessPercentage);
        TaxRate.AttributeValue9.SetValue(SHECessPercentage);
        TaxRate.AttributeValue10.SetValue(TCSThresholdAmount);
        TaxRate.AttributeValue11.SetValue(SurchargeThresholdAmount);
        TaxRate.OK().Invoke();
    end;

    local procedure CreateTaxRateSetup(TCSNOC: Code[10]; AssesseeCode: Code[10]; ConcessionalCode: Code[10]; EffectiveDate: Date)
    begin
        Storage.Set('TCSNOCType', TCSNOC);
        Storage.Set('TCSAssesseeCode', AssesseeCode);
        Storage.Set('TCSConcessionalCode', ConcessionalCode);
        Storage.Set('EffectiveDate', Format(EffectiveDate));
        GenerateTaxComponentsPercentage();
        CreateTaxRate();
    end;

    local procedure GenerateTaxComponentsPercentage()
    var
    begin
        Storage.Set('TCSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('NonPANTCSPercentage', Format(LibraryRandom.RandIntInRange(6, 10)));
        Storage.Set('SurchargePercentage', Format(LibraryRandom.RandIntInRange(6, 10)));
        Storage.Set('eCessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SHECessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('TCSThresholdAmount', Format(LibraryRandom.RandIntInRange(4000, 6000)));
        Storage.Set('SurchargeThresholdAmount', Format(LibraryRandom.RandIntInRange(4000, 6000)));
    end;

    var
        LibraryTCS: Codeunit "TCS - Library";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        TCSSalesLibrary: Codeunit "TCS Sales - Library";
        Assert: Codeunit Assert;
        Storage: Dictionary of [Text, Text];
        IncomeTaxAccountingErr: Label 'Posting Date doesn''t lie in Tax Accounting Period', Locked = true;
        TCANNoErr: Label 'T.C.A.N. No. must have a value in Gen. Journal Line: Journal Template Name=%1, Journal Batch Name=%2, Line No.=%3. It cannot be zero or empty.', Comment = '%1= Template Name, %2= Batch Name,%3= Line No';
        AmountErr: Label '%1 is incorrect in %2.', Comment = '%1 and %2 = TCS Amount and TCS field Caption';
}