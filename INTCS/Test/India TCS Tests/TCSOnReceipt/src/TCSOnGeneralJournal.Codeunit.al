codeunit 18927 "TCS On General Journal"
{
    Subtype = Test;
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PosteFromGenJnlWithoutAccountingPeriod()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
    begin
        // [Scenario 354371] Check if the program is allowing the posting of Invoice using the General Journal with TCS  where Accounting Year has not been specified
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup without Accounting Period
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithConcessional(Customer, false, false);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Created General Journal with TCS
        GenJnlLineForTCSWithoutAccPeriod(GenJournalLine, Customer);
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Expected Error : Income Tax accounting period is not defined
        Assert.ExpectedError(IncomeTaxAccountingErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGenJnlWithoutTCAN()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
    begin
        // [Scenario 354373] Check if the program is allowing the posting of Invoice using the General Journal with TCS calculation where TCAN No. has not been defined
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup and TCAN No. not Defined in Company Informarion
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, false, false);
        LibraryTCS.RemoveTCANOnCompInfo();
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Created General Journal with TCS
        CreateGenJnlLineWithTCS(GenJournalLine, Customer);
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Expected Error : TCAN No. is not defined
        Assert.ExpectedError(StrSubstNo(TCANNoErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;


    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGenJnlWithThresholdAndSurchargeOverlook()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [Scenario 354374] -Check if the program is calculating TCS using General Journal with threshold and surcharge overlook for NOC lines of a particular customer.
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup with Threshold and Surcharge Overlook
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        CreateGenJnlLineWithTCS(GenJournalLine, Customer);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", true, true, true);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGenJnlWithThresholdOverlook()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [Scenario 354375] -Check if the program is calculating TCS in case an invoice is raised to the Customer using General Journal and Threshold Overlook is selected.
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup with Threshold Overlook
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, false);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        CreateGenJnlLineWithTCS(GenJournalLine, Customer);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", true, false, true);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGenJnlWithCurrency()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [Scenario 354429] -Check if the program is calculating TCS using General Journal in case of Foreign Currency.
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup and Concessional code
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithOutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line with Currency 
        GenJnlLineForTCSWithCurrency(GenJournalLine, Customer, Currency);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", true, true, true);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGenJnlWithoutPAN()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [Scenario 354440] - Check if the program is calculating TCS on higher rate in case an invoice is raised to the Customer which is not having PAN No. using General Journal.
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer without PAN, TCS Setup and Concessional code
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithoutPANWithoutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line
        CreateGenJnlLineWithTCS(GenJournalLine, Customer);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, true, true);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGenJnlWithConcessional()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        // [Scenario 354441] - Check if the program is calculating TCS on Lower rate/zero rate in case an invoice is raised to the Customer is having a certificate using General Journal.
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer with Concessional Setup, TCS Setup
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithoutPANWithConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create & Post General Journal Line
        CreateGenJnlLineWithTCS(GenJournalLine, Customer);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, true, true);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGenJnlWithMultiLine()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // [Scenario 354442] - Check if the program is calculating TCS while creating a single invoice with multiple expenses using General Journal
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup and Concessional code
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithoutPANWithoutConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line with Multi Line
        CreateGenJnlLineWithTCS(GenJournalLine, Customer);
        DocumentNo := GenJournalLine."Document No.";
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
        TCSJournalLibrary.CalculateTCS(GenJournalLine);
        DocumentNo2 := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] GL Entry, TCS Entry created and posted
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        LibraryTCS.VerifyGLEntryCount(DocumentNo2, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo2, TCSPostingSetup."TCS Account No.");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGenJnlWithCurrencyWithSurchargeOverlook()
    var
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        Customer: Record Customer;
        DocumentNo: Code[20];
    begin
        // [Scenario 354378] -Check if the program is calculating TCS in case an invoice is raised to the foreign Customer using General Journal and Surcharge Overlook is selected.
        // [GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup, Concessional code and Surcharge overlook for Customer
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithoutPANWithoutConcessional(Customer, false, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create & Post General Journal Line with Currency
        GenJnlLineForTCSWithCurrency(GenJournalLine, Customer, Currency);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS Entry Created and Verified
        VerifyTCSEntry(DocumentNo, GenJournalLine.Amount, GenJournalLine."Currency Factor", false, true, false);
    end;

    procedure CreateGenJnlLineWithTCS(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
        GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(10000, 2));
        TCSJournalLibrary.CalculateTCS(GenJournalLine);
        GenJournalLine.Modify();
    end;

    local procedure GenJnlLineForTCSWithCurrency(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; Currency: Record Currency);
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
        GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Validate("Posting Date", WorkDate());
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 100, LibraryRandom.RandDecInDecimalRange(70, 80, 2));
        GenJournalLine.Validate("Currency Code", Currency.Code);
        GenJournalLine.Modify(true);
        TCSJournalLibrary.CalculateTCS(GenJournalLine);
    end;

    local procedure GenJnlLineForTCSWithoutAccPeriod(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
        GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Validate("Posting Date", CalcDate('<-1Y>', TCSJournalLibrary.FindStartDateOnAccountingPeriod()));
        GenJournalLine.Modify(true);
    end;

    LOCAL procedure VerifyTCSEntry(DocumentNo: Code[20]; TCSBaseAmount: Decimal; CurrencyFactor: Decimal;
     WithPAN: Boolean; SurchargeOverlook: Boolean; TCSThresholdOverlook: Boolean)
    var
        TCSEntry: Record "TCS Entry";
        ExpectedTCSAmount, ExpectedSurchargeAmount, ExpectedEcessAmount, ExpectedSHEcessAmount : Decimal;
        TCSPercentage, NonPANTCSPercentage, SurchargePercentage, SurchargeThresholdAmount : Decimal;
        eCessPercentage, SHECessPercentage, TCSThresholdAmount : Decimal;
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

    Local procedure CreateTaxRate()
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

    local procedure GenerateTaxComponentsPercentage()
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
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        TCSJournalLibrary: Codeunit "TCS Journal - Library";
        Storage: Dictionary of [Text, Text];
        IncomeTaxAccountingErr: Label 'Posting Date doesn''t lie in Tax Accounting Period', Locked = true;
        TCANNoErr: Label 'T.C.A.N. No. must have a value in Gen. Journal Line: Journal Template Name=%1, Journal Batch Name=%2, Line No.=%3. It cannot be zero or empty.', Comment = '%1= Template Name,%2= Batch Name,%3= Line No';
        AmountErr: Label '%1 is incorrect in %2.', Comment = '%1 and %2 = TCS Amount and TCS field Caption';
}