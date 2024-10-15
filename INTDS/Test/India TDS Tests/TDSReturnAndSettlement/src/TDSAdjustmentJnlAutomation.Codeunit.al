codeunit 18797 "TDS Adjustment Jnl Automation"
{
    Subtype = Test;
    //Scenario 354001- Check If system is allowing to reverse the TDS entry and G/L Entry if entries posted using journals.
    [Test]

    [HandlerFunctions('TaxRatePageHandler,ConfirmHandler,ReverseSuccessHandler')]
    procedure PostFromGenerallJournalandVerifyTDSEntryandGLEntryReversal()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        TDSSection: Record "TDS Section";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted GenJournalLine TDS Invoice
        CreateGeneralJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";

        //[THEN]G/L Entries Verified and Reversed
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, Round(-GenJournalLine.Amount, 1, '='), true, true, true);
        LibraryERM.ReverseTransaction(GetTransactionNo(DocumentNo));
    end;

    //Scenario 354003-Check if system is allowing to pay TDS amount to government which is already deducted using Payment Journal.
    [TEST]

    [HandlerFunctions('TaxRatePageHandler,PayTDS')]
    procedure PostPayTDSEntriesUsingPaymentJournalAlreadyDeducted()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Create and Post TDS Invoice 
        CreateGeneralJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified and Created Payment Journal For Pay TDS
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, Round(-GenJournalLine.Amount, 1, '='), true, true, true);
        CreatePaymentJournalFOrPayTDS(GenJournalLine, TDSPostingSetup."TDS Account", LibraryTDS.GetTDSAmount(DocumentNo));
    end;

    //Scenario 354006- Check if system is marking TDS entries as paid which have been paid  to government using Payment Journal.
    [TEST]

    [HandlerFunctions('TaxRatePageHandler,PayTDS')]
    procedure PostPayTDSEntriesUsingPaymentJournalAlreadyPaid()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Create and Post TDS Invoice 
        CreateGeneralJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified and Created Payment Journal For Pay TDS
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, Round(-GenJournalLine.Amount, 1, '='), true, true, true);
        CreatePaymentJournalFOrPayTDS(GenJournalLine, TDSPostingSetup."TDS Account", LibraryTDS.GetTDSAmount(DocumentNo));
        Assert.IsTrue(VerifyTDSPaid(DocumentNo), TDSNotPaidMsg);
    end;

    //Scenario 354010- Check if system is allowing to pay TDS amount to government which is already deducted using General Journal.
    [TEST]
    [HandlerFunctions('TaxRatePageHandler,PayTDS')]
    procedure PostPayTDSEntriesUsingGeneralJournalAlreadyDeducted()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Create and Post TDS Invoice 
        CreateGeneralJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified and Created Payment Journal For Pay TDS
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, Round(-GenJournalLine.Amount, 1, '='), true, true, true);
        CreatePaymentJournalFOrPayTDS(GenJournalLine, TDSPostingSetup."TDS Account", LibraryTDS.GetTDSAmount(DocumentNo));
    end;

    //Scenario 353921- Check if system is allowing to do the adjustment increase for TDS Entries which has already deducted but paid to government authorities.
    [TEST]
    [HandlerFunctions('TaxRatePageHandler,PayTDS')]
    procedure PostTDSAdjustmentForTDSEntriesAlreadyDeductedandPaid()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        EntryNo: Integer;
        PaidErr: Label 'TDS Paid must be equal to No before Adjustment';
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Create and Post TDS Invoice 
        CreateGeneralJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified and Created Payment Journal For Pay TDS
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, Round(-GenJournalLine.Amount, 1, '='), true, true, true);
        CreatePaymentJournalFOrPayTDS(GenJournalLine, TDSPostingSetup."TDS Account", LibraryTDS.GetTDSAmount(DocumentNo));
        Assert.IsTrue(GetPaidStatus(DocumentNo), PaidErr);
    end;

    procedure CreatePaymentJournalFOrPayTDS(var GenJournalLine: Record "Gen. Journal Line"; TDSAccount: Code[20]; TDSAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        CompanyInfo: Record "Company Information";
        Payment: Codeunit "TDS Pay";
        TDSPay: TestPage "Pay TDS";
        Amount: Decimal;
        TDSSectionCode: Code[10];
    begin
        CompanyInfo.Get();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryJournals.CreateGenJournalLine(GenJournalLine,
                            GenJournalBatch."Journal Template Name",
                            GenJournalBatch.Name,
                            GenJournalLine."Document Type"::Payment,
                            GenJournalLine."Account Type"::"G/L Account",
                            TDSAccount,
                            GenJournalLine."Bal. Account Type"::"Bank Account",
                            LibraryERM.CreateBankAccountNo(), TDSAmount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        TDSSectionCode := CopyStr(Storage.Get('SectionCode'), 1, 10);
        GenJournalLine.Validate("TDS Section Code", TDSSectionCode);
        GenJournalLine.Validate("T.A.N. No.", CompanyInfo."T.A.N. No.");
        GenJournalLine.Modify(true);
        Payment.PayTDS(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalforTDSInvoice(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; PostingDate: Date)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
        TDSSectionCode: Code[10];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        Amount := LibraryRandom.RandDecInRange(1000, 10000, 0);
        LibraryJournals.CreateGenJournalLine(GenJournalLine,
                            GenJournalBatch."Journal Template Name",
                            GenJournalBatch.Name,
                            GenJournalLine."Document Type"::Invoice,
                            GenJournalLine."Account Type"::Vendor,
                            Vendor."No.",
                            GenJournalLine."Bal. Account Type"::"G/L Account",
                            LibraryERM.CreateGLAccountNoWithDirectPosting(),
                            -Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        TDSSectionCode := CopyStr(Storage.Get('SectionCode'), 1, 10);
        GenJournalLine.Validate("TDS Section Code", TDSSectionCode);
        GenJournalLine.Validate(Amount, -Amount);
        GenJournalLine.Modify(true);
    END;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; VAR Reply: Boolean)
    begin
        Reply := TRUE;
    end;

    [MessageHandler]
    procedure SuccessHandler(SuccessMessage: Text[1024])
    begin
        if SuccessMessage <> SuccessMsg then
            Error('Not Posted');
    end;

    [MessageHandler]
    procedure ReverseSuccessHandler(ReverseMessage: Text[1024])
    begin
        if ReverseMsg <> ReverseMessage then
            Error('Not Posted');
    end;

    [PageHandler]
    procedure PayTDS(var PayTDSPage: TestPage "Pay TDS")
    begin
        PayTDSPage."&Pay".Invoke();
    end;

    procedure VerifyTDSPaid(DocumentNo: Code[20]): Boolean
    var
        TDSEntry: Record "TDS Entry";
    begin
        TDSEntry.SetRange("Document No.", DocumentNo);
        TDSEntry.SetRange("TDS Paid", true);
        if not TDSEntry.IsEmpty() then
            exit(true);
    end;

    procedure GetTDSEntryNo(DocumentNo: Code[20]): Integer
    var
        TDSEntry: Record "TDS Entry";
    begin
        TDSEntry.SetRange("Document No.", DocumentNo);
        if not TDSEntry.IsEmpty() then
            exit(TDSEntry."Entry No.")
        else
            exit(0);
    end;

    procedure GetPaidStatus(DocumentNo: Code[20]): Boolean
    var
        TDSEntry: Record "TDS Entry";
    begin
        TDSEntry.SetRange("Document No.", DocumentNo);
        TDSEntry.SetRange("TDS Paid", true);
        if TDSEntry.FindFirst() then
            exit(true)
        else
            exit(false);
    end;

    local procedure GetTransactionNo(DocumentNo: Code[20]): Integer
    var
        TDSEntry: Record "TDS Entry";
    begin
        TDSEntry.SetRange("Document No.", DocumentNo);
        if TDSEntry.FindFirst() then
            exit(TDSEntry."Transaction No.")
        else
            exit(0);
    end;

    local procedure VerifyTDSEntry(DocumentNo: Code[20]; TDSBaseAmount: Decimal; WithPAN: Boolean; SurchargeOverlook: Boolean; TDSThresholdOverlook: Boolean)
    var
        TDSEntry: Record "TDS Entry";
        ExpectdTDSAmount: Decimal;
        ExpectedSurchargeAmount: Decimal;
        ExpectedEcessAmount: Decimal;
        ExpectedSHEcessAmount: Decimal;
        TDSPercentage: Decimal;
        NonPANTDSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        TDSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
        CurrencyFactor: Decimal;
    begin
        Evaluate(TDSPercentage, Storage.Get('TDSPercentage'));
        Evaluate(NonPANTDSPercentage, Storage.Get('NonPANTDSPercentage'));
        Evaluate(SurchargePercentage, Storage.Get('SurchargePercentage'));
        Evaluate(eCessPercentage, Storage.Get('eCessPercentage'));
        Evaluate(SHECessPercentage, Storage.Get('SHECessPercentage'));
        Evaluate(TDSThresholdAmount, Storage.Get('TDSThresholdAmount'));
        Evaluate(SurchargeThresholdAmount, Storage.Get('SurchargeThresholdAmount'));

        if (TDSBaseAmount < TDSThresholdAmount) and (TDSThresholdOverlook = false) then
            ExpectdTDSAmount := 0
        else
            if WithPAN then
                ExpectdTDSAmount := TDSBaseAmount * TDSPercentage / 100
            else
                ExpectdTDSAmount := TDSBaseAmount * NonPANTDSPercentage / 100;

        if (TDSBaseAmount < SurchargeThresholdAmount) and (SurchargeOverlook = false) then
            ExpectedSurchargeAmount := 0
        else
            ExpectedSurchargeAmount := ExpectdTDSAmount * SurchargePercentage / 100;
        ExpectedEcessAmount := (ExpectdTDSAmount + ExpectedSurchargeAmount) * eCessPercentage / 100;
        ExpectedSHEcessAmount := (ExpectdTDSAmount + ExpectedSurchargeAmount) * SHECessPercentage / 100;
        TDSEntry.SETRANGE("Document No.", DocumentNo);
        TDSEntry.FINDFIRST();
        Assert.AreNearlyEqual(
         TDSBaseAmount, TDSEntry."TDS Base Amount", LibraryTDS.GetTDSRoundingPrecision(),
          StrSubstNo(AmountErr, TDSEntry.FieldName("TDS Base Amount"), TDSEntry.TableCaption()));
        if WithPAN then
            Assert.AreEqual(
              TDSPercentage, TDSEntry."TDS %",
              StrSubstNo(AmountErr, TDSEntry.FieldName("TDS %"), TDSEntry.TableCaption()))
        else
            Assert.AreEqual(
            NonPANTDSPercentage, TDSEntry."TDS %",
            StrSubstNo(AmountErr, TDSEntry.FieldName("TDS %"), TDSEntry.TableCaption()));
        Assert.AreNearlyEqual(
          ExpectdTDSAmount, TDSEntry."TdS Amount", LibraryTdS.GetTDSRoundingPrecision(),
          StrSubstNo(AmountErr, TDSEntry.FieldName("TDS Amount"), TDSEntry.TableCaption()));
        Assert.AreEqual(
          SurchargePercentage, TDSEntry."Surcharge %",
          StrSubstNo(AmountErr, TDSEntry.FieldName("Surcharge %"), TDSEntry.TableCaption()));
        Assert.AreNearlyEqual(
          ExpectedSurchargeAmount, TDSEntry."Surcharge Amount", LibraryTDS.GetTDSRoundingPrecision(),
          StrSubstNo(AmountErr, TDSEntry.FieldName("Surcharge Amount"), TDSEntry.TableCaption()));
        Assert.AreEqual(
          eCessPercentage, TDSEntry."eCESS %",
          StrSubstNo(AmountErr, TDSEntry.FieldName("eCESS %"), TDSEntry.TableCaption()));
        Assert.AreNearlyEqual(
          ExpectedEcessAmount, TDSEntry."eCESS Amount", LibraryTDS.GetTDSRoundingPrecision(),
          StrSubstNo(AmountErr, TDSEntry.FieldName("eCESS Amount"), TDSEntry.TableCaption()));
        Assert.AreEqual(
          SHECessPercentage, TDSEntry."SHE Cess %",
          StrSubstNo(AmountErr, TDSEntry.FieldName("SHE Cess %"), TDSEntry.TableCaption()));
        Assert.AreNearlyEqual(
          ExpectedSHEcessAmount, TDSEntry."SHE Cess Amount", LibraryTDS.GetTDSRoundingPrecision(),
          StrSubstNo(AmountErr, TDSEntry.FieldName("SHE Cess Amount"), TDSEntry.TableCaption()));
    end;

    local procedure CreateTaxRateSetup(TDSSection: Code[10]; AssesseeCode: Code[10]; ConcessionlCode: Code[10]; EffectiveDate: Date)
    begin
        Storage.Set('SectionCode', TDSSection);
        Storage.Set('TDSAssesseeCode', AssesseeCode);
        Storage.Set('TDSConcessionalCode', ConcessionlCode);
        Storage.Set('EffectiveDate', Format(EffectiveDate));
        GenerateTaxComponentsPercentage();
        CreateTaxRate();
    end;

    local procedure GenerateTaxComponentsPercentage()
    begin
        Storage.Set('TDSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('NonPANTDSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SurchargePercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('eCessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SHECessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('TDSThresholdAmount', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SurchargeThresholdAmount', Format(LibraryRandom.RandIntInRange(2, 4)));
    end;

    procedure CreateTDSAdjJournalTemplate(var TDSJournalTemplate: Record "TDS Journal Template")
    begin
        TDSJournalTemplate.Init();
        TDSJournalTemplate.Validate(
          Name, COPYSTR(
            LibraryUtility.GenerateRandomCode(TDSJournalTemplate.FIELDNO(Name), Database::"TDS Journal Template"), 1,
            LibraryUtility.GetFieldLength(Database::"TDS Journal Template", TDSJournalTemplate.FIELDNO(Name))));
        TDSJournalTemplate.Validate(Description, TDSJournalTemplate.Name);
        TDSJournalTemplate.Insert(true);
        TDSJournalTemplate.Validate(Type, TDSJournalTemplate.Type::"TDS Adjustments");
        TDSJournalTemplate.Validate("Bal. Account Type", TDSJournalTemplate."Bal. Account Type"::"G/L Account");
        TDSJournalTemplate.Modify(true);
    end;

    procedure CreateTDSAdjJournalBatch(VAR TDSJournalBatch: Record "TDS Journal Batch"; JournalTemplateName: Code[10])
    begin
        TDSJournalBatch.Init();
        TDSJournalBatch.Validate("Journal Template Name", JournalTemplateName);
        TDSJournalBatch.Validate(
          Name, COPYSTR(
            LibraryUtility.GenerateRandomCode(TDSJournalBatch.FIELDNO(Name), Database::"TDS Journal Batch"), 1,
            LibraryUtility.GetFieldLength(Database::"TDS Journal Batch", TDSJournalBatch.FIELDNO(Name))));
        TDSJournalBatch.Validate(Description, TDSJournalBatch.Name);
        TDSJournalBatch.Insert(true);
        TDSJournalBatch.Validate("No. Series", CreateNoseries());
        TDSJournalBatch.Validate("Posting No. Series", CreateNoseries());
        TDSJournalBatch.Modify(true);
    end;

    procedure CreateNoseries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, FALSE);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '00001', '99999');
        exit(NoSeries.Code);
    end;

    Local procedure CreateTaxRate()
    var
        TDSSetup: Record "TDS Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TDSSetup.Get() then
            exit;
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TDSSetup."Tax Type");
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates");
    var
        EffectiveDate: Date;
        TDSPercentage: Decimal;
        NonPANTDSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        TDSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
    begin
        Evaluate(EffectiveDate, Storage.Get('EffectiveDate'));
        Evaluate(TDSPercentage, Storage.Get('TDSPercentage'));
        Evaluate(NonPANTDSPercentage, Storage.Get('NonPANTDSPercentage'));
        Evaluate(SurchargePercentage, Storage.Get('SurchargePercentage'));
        Evaluate(eCessPercentage, Storage.Get('eCessPercentage'));
        Evaluate(SHECessPercentage, Storage.Get('SHECessPercentage'));
        Evaluate(TDSThresholdAmount, Storage.Get('TDSThresholdAmount'));
        Evaluate(SurchargeThresholdAmount, Storage.Get('SurchargeThresholdAmount'));

        TaxRate.AttributeValue1.SetValue(Storage.Get('SectionCode'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('TDSAssesseeCode'));
        TaxRate.AttributeValue3.SetValue(EffectiveDate);
        TaxRate.AttributeValue4.SetValue(Storage.Get('TDSConcessionalCode'));
        TaxRate.AttributeValue5.SetValue('');
        TaxRate.AttributeValue6.SetValue('');
        TaxRate.AttributeValue7.SetValue('');
        TaxRate.AttributeValue8.SetValue(TDSPercentage);
        TaxRate.AttributeValue9.SetValue(NonPANTDSPercentage);
        TaxRate.AttributeValue10.SetValue(SurchargePercentage);
        TaxRate.AttributeValue11.SetValue(eCessPercentage);
        TaxRate.AttributeValue12.SetValue(SHECessPercentage);
        TaxRate.AttributeValue13.SetValue(TDSThresholdAmount);
        TaxRate.AttributeValue14.SetValue(SurchargeThresholdAmount);
        TaxRate.AttributeValue15.SetValue('');
        TaxRate.AttributeValue16.SetValue('');
        TaxRate.AttributeValue17.SetValue(0.00);
        TaxRate.OK().Invoke();
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTDS: Codeunit "Library-TDS";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        Storage: Dictionary of [Text, Text];
        TDSNotPaidMsg: Label 'Not paid';
        SuccessMsg: Label 'Journal lines posted successfully.';
        ReverseMsg: Label 'The entries were successfully reversed.';
        AmountErr: Label '%1 is incorrect in %2.', Comment = '%1 and %2 = TCS Amount and TCS field Caption';
}