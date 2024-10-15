codeunit 18921 "TCS Pay Adjustment"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,ConfirmHandler,MsgHandler')]
    procedure PostAndReverseTCSEntries()
    var
        ConcessionalCode: Record "Concessional Code";
        TCSPostingSetup: Record "TCS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
    begin
        //[Senerio 355284] [Check If system is allowing to reverse the TCS entry and G/L Entry if entries posted using journals]
        //[GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup and Concessional code
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create & Post General Journal Line
        CreateGenJnlLineForTCS(GenJournalLine, Customer);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        LibraryTCS.VerifyTCSEntry(DocumentNo, GenJournalLine."Document Type"::Invoice, GenJournalLine.Amount);
        LibraryERM.ReverseTransaction(GetTransactionNo(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,PayTax')]
    procedure PostAndReverseTDSEntriesWhichIsPaidToGovernment()
    var
        ConcessionalCode: Record "Concessional Code";
        TCSPostingSetup: Record "TCS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
        EntryNo: Integer;
    begin
        //[Senerio 355283] [Check If system is not allowing to reverse the TCS entry and G/L Entry if TCS amount paid to government]
        //[GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup and Concessional code
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create & Post General Journal Line
        CreateGenJnlLineForTCS(GenJournalLine, Customer);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        LibraryTCS.VerifyTCSEntry(DocumentNo, GenJournalLine."Document Type"::Invoice, GenJournalLine.Amount);
        CreateTCSPayment(TCSPostingSetup."TCS Account No.");
        EntryNo := GetEntryNo(DocumentNo);
        asserterror LibraryERM.ReverseTransaction(GetTransactionNo(DocumentNo));
        Assert.ExpectedError(StrSubstNo(PaidReverseErr, EntryNo));
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,PayTax')]
    procedure PostAdjustedTCSEntriedWhichIsAlreadyPaidToGovernment()
    var
        ConcessionalCode: Record "Concessional Code";
        TCSPostingSetup: Record "TCS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
        PaidErr: Label 'TCS Paid must be equal to No before Adjustment';
    begin
        //[Senerio 355277] [Check if system is not allowing to do the adjustment for TCS Entries which has already deducted and paid to government authorities.]
        //[GIVEN] Created Setup for NOC, Assessee Code, Customer, TCS Setup and Concessional code
        LibraryTCS.CreateTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LibraryTCS.UpdateCustomerWithPANWithConcessional(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create & Post General Journal Line
        CreateGenJnlLineForTCS(GenJournalLine, Customer);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] TCS and G/L Entry Created and Verified
        LibraryTCS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTCS.VerifyGLEntryWithTCS(DocumentNo, TCSPostingSetup."TCS Account No.");
        LibraryTCS.VerifyTCSEntry(DocumentNo, GenJournalLine."Document Type"::Invoice, GenJournalLine.Amount);
        CreateTCSPayment(TCSPostingSetup."TCS Account No.");
        Assert.IsTrue(GetPaidStatus(DocumentNo), PaidErr);
    end;

    procedure CreateTCSPayment(TCSAccount: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        CompanyInformation: Record "Company Information";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryJournals: Codeunit "Library - Journals";
        Payment: Codeunit "Pay-TCS";
    begin
        CompanyInformation.get();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", TCSAccount,
        GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), 0);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("T.C.A.N. No.", CompanyInformation."T.C.A.N. No.");
        GenJournalLine.Modify(true);
        Payment.PayTCS(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure GetTransactionNo(DocumentNo: Code[20]): Integer
    var
        TCSEntry: Record "TCS Entry";
    begin
        TCSEntry.SetRange("Document No.", DocumentNo);
        if TCSEntry.FindFirst() then
            exit(TCSEntry."Transaction No.")
        else
            exit(0);
    end;

    procedure GetEntryNo(DocumentNo: Code[20]): Integer
    var
        TCSEntry: Record "TCS Entry";
    begin
        TCSEntry.SetRange("Document No.", DocumentNo);
        if TCSEntry.FindFirst() then
            exit(TCSEntry."Entry No.")
        else
            exit(0);
    end;

    procedure GetPaidStatus(DocumentNo: Code[20]): Boolean
    var
        TCSEntry: Record "TCS Entry";
    begin
        TCSEntry.SetRange("Document No.", DocumentNo);
        TCSEntry.SetRange("TCS Paid", true);
        if not TCSEntry.IsEmpty then
            exit(true)
        else
            exit(false);
    end;

    local procedure CreateGenJnlLineForTCS(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
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
        CalculateTCS(GenJournalLine);
        GenJournalLine.Modify();
    end;

    local procedure CalculateTCS(GeneralJnlLine: Record "Gen. Journal Line")
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CalculateTax.CallTaxEngineOnGenJnlLine(GeneralJnlLine, GeneralJnlLine);
    end;

    [PageHandler]
    procedure PayTax(var PayTCS: TestPage "Pay TCS")
    begin
        PayTCS."&Pay".Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; VAR Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MsgHandler(MsgText: Text)
    begin
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
    begin
        Storage.Set('TCSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('NonPANTCSPercentage', Format(LibraryRandom.RandIntInRange(6, 10)));
        Storage.Set('SurchargePercentage', Format(LibraryRandom.RandIntInRange(6, 10)));
        Storage.Set('eCessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SHECessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('TCSThresholdAmount', Format(LibraryRandom.RandIntInRange(4000, 6000)));
        Storage.Set('SurchargeThresholdAmount', Format(LibraryRandom.RandIntInRange(4000, 6000)));
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

    var
        LibraryTCS: Codeunit "TCS - Library";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Storage: Dictionary of [Text, Text];
        PaidReverseErr: Label 'You cannot reverse TCS Entry No. %1 because the entry is closed.', Comment = '%1=Entry No.';
}