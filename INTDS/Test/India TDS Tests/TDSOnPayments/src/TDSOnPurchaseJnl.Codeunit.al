codeunit 18804 "TDS On Purchase Jnl"
{
    Subtype = Test;

    [TEST]
    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario-39 Check if the program is allowing the posting of Invoice using the Purchase Journal with TDS information where Accounting Period has not been specified.
    //Scenario-40 Check if the program is allowing the posting of Invoice using the Purchase Journal with TDS information where Accounting Period has been specified but Quarter for the period is not specified.
    procedure PostFromPurchaseJornalWithoutAccountingPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        Assert: Codeunit Assert;
        IncomeTaxAccountingErr: Label 'The Posting Date doesn''t lie in Tax Accounting Period', Locked = true;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created Purchase Journal for TDS Without Accounting Period
        CreatePurchaseJournalforTDSWithoutAccPeriod(GenJournalLine, Vendor);
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Assert Error Verified
        Assert.ExpectedError(IncomeTaxAccountingErr);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario-41 Check if the program is allowing the posting of Invoice using the Purchase Journal with TDS information where T.A.N No. has not been defined.
    procedure PostFromPurchaseJournalWithoutTANNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        Assert: Codeunit Assert;
        TANNoErr: Label 'T.A.N. No must have a value in TDS Entry', locked = true;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Create General Journal
        LibraryTDS.RemoveTANOnCompInfo();
        CreatePurchaseGenJnlLineForTDS(GenJournalLine, Vendor, WorkDate());
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Expected Error Verified
        Assert.ExpectedError(TANNoErr);
    end;

    [TEST]
    //Scenario 8 -Check if the program is calculating TDS in case an invoice is raised to the Vendor using Purchase Journal.
    //Scenario 46 - Check if the program is calculating TDS in case an invoice is raised to the Vendor using Purchase Journal and Threshold Overlook is selected.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinJournalsWithPANWithoutConcessional()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", true, true, true);
    end;

    [TEST]
    //Scenario 51 -Check if the program is calculating TDS on Lower rate/zero rate in case an invoice is raised to the Vendor is having a certificate using Purchase Journal.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinJournalsWithPANWithConcessional()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", true, true, true);
    end;

    [TEST]
    //Scenario 50 -CCheck if the program is calculating TDS on higher rate in case an invoice is raised to the Vendor which is not having PAN No. using Purchase Journal.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinJournalsWithoutPANWithoutConcessional()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", false, true, true);
    end;

    [TEST]
    //Scenario 50 -CCheck if the program is calculating TDS on higher rate in case an invoice is raised to the Vendor which is not having PAN No. using Purchase Journal.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinJournalsWithoutPANWithConcessional()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", false, true, true);
    end;

    [TEST]
    //Scenario 353858 - Check if the program is calculating TDS while creating Invoice using the Purchase Journal in case of different rates for same NOD with different effective dates.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinPurchaseJournalWithPANWithoutConcessionalWithDifferentEffectiveDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', CalcDate('<-1D>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<-1D>', WorkDate()), TDSPostingSetup."TDS Account");

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, CalcDate('<-1D>', WorkDate()));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", true, true, true);
    end;

    [TEST]
    //Scenario 353858 - Check if the program is calculating TDS while creating Invoice using the Purchase Journal in case of different rates for same NOD with different effective dates.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinPurchaseJournalWithPANWithConcessionalWithDifferentEffectiveDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, CalcDate('<-1D>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<-1D>', WorkDate()), TDSPostingSetup."TDS Account");

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, CalcDate('<-1D>', WorkDate()));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", true, true, true);
    end;

    [TEST]
    //Scenario 353858 - Check if the program is calculating TDS while creating Invoice using the Purchase Journal in case of different rates for same NOD with different effective dates.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinPurchaseJournalWithoutPANWithoutConcessionalWithDifferentEffectiveDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', CalcDate('<-1D>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<-1D>', WorkDate()), TDSPostingSetup."TDS Account");

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, CalcDate('<-1D>', WorkDate()));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", false, true, true);
    end;

    [TEST]
    //Scenario 353858 - Check if the program is calculating TDS while creating Invoice using the Purchase Journal in case of different rates for same NOD with different effective dates.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinPurchaseJournalWithoutPANWithConcessionalWithDifferentEffectiveDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithoutPANWithConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", ConcessionalCode.Code, CalcDate('<-1D>', WorkDate()));
        LibraryTDS.CreateTDSPostingSetupWithDifferentEffectiveDate(TDSPostingSetup."TDS Section", CalcDate('<-1D>', WorkDate()), TDSPostingSetup."TDS Account");

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, CalcDate('<-1D>', WorkDate()));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", false, true, true);
    end;

    [TEST]
    //Scenario 353887 - Check if the program is calculating TDS while creating a single invoice with multiple expenses using Payment Journal.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinPaymentJournalWithPANWithoutConcessionalWithMultiLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup2: Record "TDS Posting Setup";
        TDSSection2: Record "TDS Section";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.CreateTDSPostingSetupForMultipleSection(TDSPostingSetup2, TDSSection2);
        LibraryTDS.AttachSectionWithVendor(TDSPostingSetup2."TDS Section", Vendor."No.", false, true, true);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());
        CreateTaxRateSetup(TDSPostingSetup2."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted GenJournalLine
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine,
            GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name",
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(100000, 2));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] GL Entry, TCS Entry created and posted
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
    end;

    [TEST]
    //Scenario 353861 - Check if the program is calculating TDS in case an invoice is raised to the Vendor using Purchase Journal and Threshold Overlook is selected.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinPurchaseJournalWithThresholdOverlookandSurchargeOverlook()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Journal
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", true, true, true);
    end;

    [TEST]
    //Scenario 353862 - Check if the program is calculating TDS in case an invoice is raised to the Vendor using Purchase Journal and Threshold Overlook is not selected.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceinPurchaseJournalWithoutThresholdOverlookandSurchargeOverlook()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Journal
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        VerifyTDSEntry(DocumentNo, -Round(GenJournalLine.Amount, 1, '='), GenJournalLine."Currency Factor", true, false, false);
    end;


    [Test]
    //Scenario 353857 -Check if the program is calculating TDS while creating Invoice using the Purchase Journal in case of Foreign Vendor.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceUsingPurchaseJournalOfForeignVendor()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        TDSNatureOfRemittance: Record "TDS Nature of Remittance";
        TDSActApplicable: Record "Act Applicable";
        DocumentNo: Code[20];
    begin
        IsForeignVendor := true;
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        LibraryTDS.CreateForeignVendorWithPANNoandWithoutConcessional(Vendor);
        LibraryTDS.CreateNatureOfRemittance(TDSNatureOfRemittance);
        LibraryTDS.CreateActApplicable(TDSActApplicable);
        LibraryTDS.AttachSectionWithForeignVendor(TDSPostingSetup."TDS Section", Vendor."No.", true, true, true, true, TDSNatureOfRemittance.Code, TDSActApplicable.Code);
        Storage.Set('NatureOfRemittance', TDSNatureOfRemittance.Code);
        Storage.Set('ActApplicable', TDSActApplicable.Code);
        Storage.Set('CountryCode', Vendor."Country/Region Code");
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Foreign Vendor with General Journal
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        IsForeignVendor := false;
    end;

    [Test]
    //Scenario 353863 -Check if the program is calculating TDS in case an invoice is raised to the foreign Vendor using Purchase Journal and Threshold Overlook and Surcharge Overlook is selected.
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromTDSInvoiceUsingPurchaseJournalOfForeignVendorWithThresholdandSurchargeOverlook()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        TDSNatureOfRemittance: Record "TDS Nature of Remittance";
        TDSActApplicable: Record "Act Applicable";
        DocumentNo: Code[20];
    begin
        IsForeignVendor := true;
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook.
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithoutConcessional(Vendor, true, true);
        LibraryTDS.CreateForeignVendorWithPANNoandWithoutConcessional(Vendor);
        LibraryTDS.CreateNatureOfRemittance(TDSNatureOfRemittance);
        LibraryTDS.CreateActApplicable(TDSActApplicable);
        LibraryTDS.AttachSectionWithForeignVendor(TDSPostingSetup."TDS Section", Vendor."No.", true, true, true, true, TDSNatureOfRemittance.Code, TDSActApplicable.Code);
        Storage.Set('NatureOfRemittance', TDSNatureOfRemittance.Code);
        Storage.Set('ActApplicable', TDSActApplicable.Code);
        Storage.Set('CountryCode', Vendor."Country/Region Code");
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Foreign Vendor with General Journal
        CreatePurchaseJournalforTDSInvoice(GenJournalLine, Vendor, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] G/L Entries Verified
        LibraryTDS.VerifyGLEntryCount(DocumentNo, 3);
        LibraryTDS.VerifyGLEntryWithTDS(DocumentNo, TDSPostingSetup."TDS Account");
        IsForeignVendor := false;
    end;

    local procedure CreatePurchaseGenJnlLineForTDS(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.",
        GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountWithDirectPostingNoVAT(), -LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("TDS Section Code");
        GenJournalLine.Validate(Amount, -LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Modify();
    end;

    local procedure CreatePurchaseJournalforTDSInvoice(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; PostingDate: Date)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        TDSSectionCode: Code[10];
        NatureOfRemittance: Code[10];
        ActApplicable: Code[10];
        CountryCode: Code[10];
        Amount: Decimal;
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        Amount := LibraryRandom.RandDec(100000, 2);
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
        GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.",
        GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountWithDirectPostingNoVAT(), -Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        TDSSectionCode := CopyStr(Storage.Get('SectionCode'), 1, 10);
        GenJournalLine.Validate("TDS Section Code", TDSSectionCode);
        if IsForeignVendor then begin
            NatureOfRemittance := CopyStr(Storage.Get('NatureOfRemittance'), 1, 10);
            ActApplicable := CopyStr(Storage.Get('ActApplicable'), 1, 10);
            CountryCode := Copystr(Storage.Get('CountryCode'), 1, 10);
            GenJournalLine.Validate("Nature of Remittance", NatureOfRemittance);
            GenJournalLine.Validate("Act Applicable", ActApplicable);
            GenJournalLine.Validate("Country/Region Code", CountryCode);
        end;
        GenJournalLine.Validate(Amount, -Amount);
        GenJournalLine.Modify(true);
    END;

    local procedure CreatePurchaseJournalforTDSWithoutAccPeriod(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryJournals: Codeunit "Library - Journals";
        Amount: Decimal;
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        Amount := LibraryRandom.RandDec(100000, 2);
        LibraryJournals.CreateGenJournalLine(GenJournalLine,
        GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
                                GenJournalLine."Document Type"::Invoice,
                                GenJournalLine."Account Type"::Vendor,
                                Vendor."No.",
                                GenJournalLine."Bal. Account Type"::"G/L Account",
                                CreateGLAccountWithDirectPostingNoVAT(),
                                -Amount);
        GenJournalLine.Validate("Posting Date", CalcDate('<-1Y>', LibraryTDS.FindStartDateOnAccountingPeriod()));
        GenJournalLine.Validate("TDS Section Code");
        GenJournalLine.Validate(Amount, -Amount);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccountWithDirectPostingNoVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTDS.CreateZeroVATPostingSetup(VATPostingSetup);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; VAR Reply: Boolean)
    begin
        Reply := TRUE;
    end;

    local procedure CreateTaxRateSetup(TDSSection: Code[10]; AssesseeCode: Code[10]; ConcessionlCode: Code[10]; EffectiveDate: Date)
    var
        Section: Code[10];
        TDSAssesseeCode: Code[10];
        TDSConcessionlCode: Code[10];
    begin
        Section := TDSSection;
        Storage.Set('SectionCode', Section);
        TDSAssesseeCode := AssesseeCode;
        Storage.Set('TDSAssesseeCode', TDSAssesseeCode);
        TDSConcessionlCode := ConcessionlCode;
        Storage.Set('TDSConcessionalCode', TDSConcessionlCode);
        Storage.Set('EffectiveDate', Format(EffectiveDate));
        CreateTaxRate();
    end;

    local procedure GenerateTaxComponentsPercentage()
    begin
        Storage.Set('TDSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('NonPANTDSPercentage', Format(LibraryRandom.RandIntInRange(6, 10)));
        Storage.Set('SurchargePercentage', Format(LibraryRandom.RandIntInRange(6, 10)));
        Storage.Set('eCessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SHECessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('TDSThresholdAmount', Format(LibraryRandom.RandIntInRange(4000, 6000)));
        Storage.Set('SurchargeThresholdAmount', Format(LibraryRandom.RandIntInRange(4000, 6000)));
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
        GenerateTaxComponentsPercentage();
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
        if IsForeignVendor then begin
            TaxRate.AttributeValue5.SetValue(Storage.Get('NatureOfRemittance'));
            TaxRate.AttributeValue6.SetValue(Storage.Get('ActApplicable'));
            TaxRate.AttributeValue7.SetValue(Storage.Get('CountryCode'))
        end else begin
            TaxRate.AttributeValue5.SetValue('');
            TaxRate.AttributeValue6.SetValue('');
            TaxRate.AttributeValue7.SetValue('');
        end;
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

    local procedure VerifyTDSEntry(DocumentNo: Code[20]; TDSBaseAmount: Decimal; CurrencyFactor: Decimal; WithPAN: Boolean; SurchargeOverlook: Boolean; TDSThresholdOverlook: Boolean)
    var
        TDSEntry: Record "TDS Entry";
        Assert: Codeunit Assert;
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
        AmountErr: Label '%1 is incorrect in %2.', Comment = '%1 and %2 = TCS Amount and TCS field Caption';
    begin
        Evaluate(TDSPercentage, Storage.Get('TDSPercentage'));
        Evaluate(NonPANTDSPercentage, Storage.Get('NonPANTDSPercentage'));
        Evaluate(SurchargePercentage, Storage.Get('SurchargePercentage'));
        Evaluate(eCessPercentage, Storage.Get('eCessPercentage'));
        Evaluate(SHECessPercentage, Storage.Get('SHECessPercentage'));
        Evaluate(TDSThresholdAmount, Storage.Get('TDSThresholdAmount'));
        Evaluate(SurchargeThresholdAmount, Storage.Get('SurchargeThresholdAmount'));

        if CurrencyFactor = 0 then
            CurrencyFactor := 1;
        if (TDSBaseAmount < TDSThresholdAmount) and (TDSThresholdOverlook = false) then
            ExpectdTDSAmount := 0
        else
            if WithPAN then
                ExpectdTDSAmount := TDSBaseAmount * TDSPercentage / 100 / CurrencyFactor
            else
                ExpectdTDSAmount := TDSBaseAmount * NonPANTDSPercentage / 100 / CurrencyFactor;

        if (TDSBaseAmount < SurchargeThresholdAmount) and (SurchargeOverlook = false) then
            ExpectedSurchargeAmount := 0
        else
            ExpectedSurchargeAmount := ExpectdTDSAmount * SurchargePercentage / 100;
        ExpectedEcessAmount := (ExpectdTDSAmount + ExpectedSurchargeAmount) * eCessPercentage / 100;
        ExpectedSHEcessAmount := (ExpectdTDSAmount + ExpectedSurchargeAmount) * SHECessPercentage / 100;
        TDSEntry.SETRANGE("Document No.", DocumentNo);
        TDSEntry.FINDFIRST();
        Assert.AreNearlyEqual(
         TDSBaseAmount / CurrencyFactor, TDSEntry."TDS Base Amount", LibraryTDS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("TDS Base Amount"), TDSEntry.TABLECAPTION()));
        if WithPAN then
            Assert.AreEqual(
              TDSPercentage, TDSEntry."TDS %",
              STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("TDS %"), TDSEntry.TABLECAPTION()))
        else
            Assert.AreEqual(
            NonPANTDSPercentage, TDSEntry."TDS %",
            STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("TDS %"), TDSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectdTDSAmount, TDSEntry."TdS Amount", LibraryTdS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("TDS Amount"), TDSEntry.TABLECAPTION()));
        Assert.AreEqual(
          SurchargePercentage, TDSEntry."Surcharge %",
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("Surcharge %"), TDSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedSurchargeAmount, TDSEntry."Surcharge Amount", LibraryTDS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("Surcharge Amount"), TDSEntry.TABLECAPTION()));
        Assert.AreEqual(
          eCessPercentage, TDSEntry."eCESS %",
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("eCESS %"), TDSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedEcessAmount, TDSEntry."eCESS Amount", LibraryTDS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("eCESS Amount"), TDSEntry.TABLECAPTION()));
        Assert.AreEqual(
          SHECessPercentage, TDSEntry."SHE Cess %",
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("SHE Cess %"), TDSEntry.TABLECAPTION()));
        Assert.AreNearlyEqual(
          ExpectedSHEcessAmount, TDSEntry."SHE Cess Amount", LibraryTDS.GetTDSRoundingPrecision(),
          STRSUBSTNO(AmountErr, TDSEntry.FIELDNAME("SHE Cess Amount"), TDSEntry.TABLECAPTION()));
    end;

    var
        Vendor: Record Vendor;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTDS: Codeunit "Library-TDS";
        LibraryRandom: Codeunit "Library - Random";
        Storage: Dictionary of [Text, Text];
        IsForeignVendor: Boolean;
}