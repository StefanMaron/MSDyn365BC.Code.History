codeunit 134284 "Non Ded. VAT Misc."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non Deductible VAT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFA: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IncorrectGLEntryAmtErr: Label 'Incorect amount in G/L Entry.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineWithNonDeductNormalVATFromPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        JobJnlLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        DeductiblePercent: Decimal;
        NonDeductiblePercent: Decimal;
    begin
        // [FEATURE] [Normal VAT]
        // [SCENARIO 416091] Job journal line built from purchase line includes non deductible VAT in "Unit Cost"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup, where "Tax Calculation Type"::"Normal VAT", 'Deductible %' is '60'
        DeductiblePercent := LibraryRandom.RandInt(90);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT", '', DeductiblePercent);
        NonDeductiblePercent := VATPostingSetup."VAT %" * (100 - DeductiblePercent) / 100;
        // [GIVEN] Purch Invoice, where line contains "Job No." = 'J', "Job Task No." = 'JT', "Job Line Type" = 'Billable'
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, VATPostingSetup);
        // [GIVEN] "Direct Unit Cost" is 100
        SetJobForPurchaseLine(PurchaseLine);

        // [WHEN] Run FromPurchaseLineToJnlLine
        JobTransferLine.FromPurchaseLineToJnlLine(PurchaseHeader, PurchInvHeader, PurchCrMemoHeader, PurchaseLine, '', JobJnlLine);

        // [THEN] JobJnlLine, where "Unit Cost" is 108
        Assert.AreEqual(
            Round(JobJnlLine."Unit Cost (LCY)"),
            Round(PurchaseLine."Unit Cost (LCY)" * (100 + NonDeductiblePercent) / 100),
            'Unit Cost (LCY) with Non-Deductible VAT amount is not correct in Job Journal Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineWithNonDeductReverseChargeVATFromPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        JobJnlLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        DeductiblePercent: Decimal;
        NonDeductiblePercent: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 416091] Job journal line built from purchase line includes non deductible VAT in "Unit Cost"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup, where "Tax Calculation Type"::"Reverse Charge VAT", 'Deductible %' is '60'
        DeductiblePercent := LibraryRandom.RandInt(90);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Reverse Charge VAT", '', DeductiblePercent);
        NonDeductiblePercent := VATPostingSetup."VAT %" * (100 - DeductiblePercent) / 100;
        // [GIVEN] Purch Invoice, where line contains "Job No." = 'J', "Job Task No." = 'JT', "Job Line Type" = 'Billable'
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, VATPostingSetup);
        // [GIVEN] "Direct Unit Cost" is 100
        SetJobForPurchaseLine(PurchaseLine);

        // [WHEN] Run FromPurchaseLineToJnlLine
        JobTransferLine.FromPurchaseLineToJnlLine(PurchaseHeader, PurchInvHeader, PurchCrMemoHeader, PurchaseLine, '', JobJnlLine);

        // [THEN] JobJnlLine, where "Unit Cost" is 108
        Assert.AreEqual(
            Round(JobJnlLine."Unit Cost (LCY)"),
            Round(PurchaseLine."Unit Cost (LCY)" * (100 + NonDeductiblePercent) / 100), 'Unit Cost (LCY)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineWithNonDeductReverseChargeVATFromPurchLineFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        JobJnlLine: Record "Job Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
        JobTransferLine: Codeunit "Job Transfer Line";
        DeductiblePercent: Decimal;
        NonDeductiblePercent: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [FCY]
        // [SCENARIO 416091] Job journal line built from purchase line (in FCY) includes non deductible VAT in "Unit Cost"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup, where "Tax Calculation Type"::"Reverse Charge VAT", 'Deductible %' is '60'
        DeductiblePercent := LibraryRandom.RandInt(90);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Reverse Charge VAT", '', DeductiblePercent);
        NonDeductiblePercent := VATPostingSetup."VAT %" * (100 - DeductiblePercent) / 100;
        // [GIVEN] Purch Invoice in FCY, where line contains "Job No." = 'J', "Job Task No." = 'JT', "Job Line Type" = 'Billable'
        PurchaseHeader."Currency Code" := LibraryERM.CreateCurrencyWithRandomExchRates();
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, VATPostingSetup);
        // [GIVEN] "Direct Unit Cost" is 100
        SetJobForPurchaseLine(PurchaseLine);
        // [GIVEN] Exchange amounts in the purchase line to local currency
        PurchaseLine.Amount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                PurchaseLine.Amount, PurchaseHeader."Currency Factor"));
        PurchaseLine."Amount Including VAT" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                PurchaseLine."Amount Including VAT", PurchaseHeader."Currency Factor"));

        // [WHEN] Run FromPurchaseLineToJnlLine
        JobTransferLine.FromPurchaseLineToJnlLine(PurchaseHeader, PurchInvHeader, PurchCrMemoHeader, PurchaseLine, '', JobJnlLine);

        // [THEN] JobJnlLine, where "Unit Cost" is 108
        // Work item id 521514: Non-Deductible VAT is correctly added to the job ledger entry for the purchase invoice with FCY
        Assert.AreEqual(
            Round(JobJnlLine."Unit Cost (LCY)"),
            Round(PurchaseLine."Unit Cost (LCY)" * (100 + NonDeductiblePercent) / 100), 'Unit Cost (LCY)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleVATInPurchaseInvoice()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        DeductiblePercent: Decimal;
        LineAmount: Decimal;
        NonDeductibleBase: Decimal;
        NonDeductibleAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Post a purchase invoice and verify Non Deductible VAT in posted entries.
        Initialize();
        // Setup.
        DeductiblePercent := UpdateVATPostingSetup(VATPostingSetup);

        // Exercise: Post a Purchase Invoice and calculate Non-Deductible Base and Amount.
        LineAmount := CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLSetup.Get();
        NonDeductibleBase :=
          Round(LineAmount * (100 - GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) / 100, GLSetup."Amount Rounding Precision");
        VATAmount := Round(LineAmount * VATPostingSetup."VAT %" / 100, GLSetup."Amount Rounding Precision");

        // As Non Deductible Amount = VAT Amount - Deductible Amount.
        NonDeductibleAmount :=
          VATAmount - Round(VATAmount * GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 100, GLSetup."Amount Rounding Precision");

        // Verify: Verify posted entries.
        VerifyGLEntry(DocumentNo, VATPostingSetup."Non-Ded. Purchase VAT Account", NonDeductibleAmount);
        VerifyVATEntry(DocumentNo, NonDeductibleBase, NonDeductibleAmount);

        // Tear Down.
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnAcqAccountWhenZeroDedPctAndBlankNDVATAccount()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        NonDeductGLAccountNo: Code[20];
        FAAccountNo: Code[20];
        LineAmount: Decimal;
        TotalAmount: Decimal;
        OldDeductiblePercent: Decimal;
    begin
        // [SCENARIO 118209] VAT amount is posted to FA's Acquisition Account when 'Deductible %' = 0 and 'Non. Deductible VAT Account' is blank
        // [GIVEN] VAT Posting Setup with "Deductible %" = 0 and blank "Non. Deductible VAT Account"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        OldDeductiblePercent := GetZeroNonDeductibleVATPostingSetup(VATPostingSetup, NonDeductGLAccountNo, "Tax Calculation Type"::"Normal VAT");
        // [GIVEN] Purchase Invoice with Fixed Asset which Acquisition Account No. = "X" and Non Deductible VAT Amount = "Y"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        GLSetup.Get();
        TotalAmount := Round(LineAmount * (1 + VATPostingSetup."VAT %" / 100), GLSetup."Amount Rounding Precision");

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry posted with G/L Account No. = "X" and Non Deductible VAT Amount = "Y"
        FAAccountNo := GetAcquisitionAccFromPurchLine(PurchLine);
        VerifyGLAccountBalance(DocumentNo, FAAccountNo, TotalAmount);

        // [THEN] There are 2 G/L Entries with linked Fixed Asset Ledger entries (TFS 409121)
        GLEntry.SetRange("G/L Account No.", FAAccountNo);
        Assert.RecordCount(GLEntry, 2);
        GLEntry.FindFirst();
        VerifyGLEntryFAEntryLinedPair(GLEntry);
        GLEntry.Next();
        VerifyGLEntryFAEntryLinedPair(GLEntry);

        // Tear Down.
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVATAmtOnAcqAccountWhenZeroDedPctAndBlankNDVATAccount()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        NonDeductGLAccountNo: Code[20];
        FAAccountNo: Code[20];
        LineAmount: Decimal;
        TotalAmount: Decimal;
        OldDeductiblePercent: Decimal;
    begin
        // [SCENARIO 409121] VAT amount is posted to FA's Acquisition Account when 'Deductible %' = 0 and 'Non. Deductible VAT Account' is blank
        // [GIVEN] Reverse Charge VAT Posting Setup with "Deductible %" = 0 and blank "Non. Deductible VAT Account"

        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        OldDeductiblePercent := GetZeroNonDeductibleVATPostingSetup(VATPostingSetup, NonDeductGLAccountNo, "Tax Calculation Type"::"Reverse Charge VAT");
        // [GIVEN] Purchase Invoice with Fixed Asset which Acquisition Account No. = "X" and Non Deductible VAT Amount = "Y"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        GLSetup.Get();
        TotalAmount := Round(LineAmount * (1 + VATPostingSetup."VAT %" / 100), GLSetup."Amount Rounding Precision");

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry posted with G/L Account No. = "X" and Non Deductible VAT Amount = "Y"
        FAAccountNo := GetAcquisitionAccFromPurchLine(PurchLine);
        VerifyGLAccountBalance(DocumentNo, FAAccountNo, TotalAmount);

        // [THEN] There are 2 G/L Entries with linked Fixed Asset Ledger entries
        GLEntry.SetRange("G/L Account No.", FAAccountNo);
        Assert.RecordCount(GLEntry, 2);
        GLEntry.FindFirst();
        VerifyGLEntryFAEntryLinedPair(GLEntry);
        GLEntry.Next();
        VerifyGLEntryFAEntryLinedPair(GLEntry);

        // Tear Down.
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnRevChargeVATAcctWhenZeroDedPctAndBlankNDVATAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        LineAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Fixed Assets] [Reverse Charge VAT]
        // [SCENARIO 371652] VAT amount is posted to Reverse Charge VAT. Account when "Reverse Charge VAT", Deductible %" = 0 and "Non-Deductible VAT Account" is blank
        // [GIVEN] Reverse Charge VAT Posting Setup with "Reverse Charge VAT Acc." = "X", "Deductible %" = 0 and blank "Non-Deductible VAT Account"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", '', 0);
        // [GIVEN] Purchase Invoice with Fixed Asset, "Non-Deductible VAT Amount" = "Y1", "Amount Including VAT" = "Y2"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        VATAmount :=
          Round(LineAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry created with "G/L Account No." = "X" and "Amount" = "Y1"
        VerifyGLEntry(DocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -VATAmount);
        // [THEN] Total Amount in FA Ledger Entries = "Y2"
        VerifyFALedgEntry(DocumentNo, PurchLine."No.", LineAmount + VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnRevChargeVATAcctWhenZeroDedPctAndNDVATAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        LineAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Fixed Assets] [Reverse Charge VAT]
        // [SCENARIO 372201] VAT amount is posted to Reverse Charge VAT. Account when "Reverse Charge VAT", Deductible %" = 0 and "Non-Deductible VAT Account" is set up
        // [GIVEN] Reverse Charge VAT Posting Setup with "Reverse Charge VAT Acc." = "X", "Deductible %" = 0 and "Non-Deductible VAT Account"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryERM.CreateGLAccountNo(), 0);
        // [GIVEN] Purchase Invoice with Fixed Asset, "Non-Deductible VAT Amount" = "Y1", "Amount Including VAT" = "Y2"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        VATAmount :=
          Round(LineAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry created with "G/L Account No." = "X" and "Amount" = "Y1"
        VerifyGLEntry(DocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -VATAmount);
        // [THEN] Total Amount in FA Ledger Entries = "Y2"
        VerifyFALedgEntry(DocumentNo, PurchLine."No.", LineAmount + VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleReverseChargeVATInPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        LineAmount: Decimal;
        NonDeductibleBase: Decimal;
        NonDeductibleAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 378347] Non-Deductible VAT with Reverse Charge VAT when "Non-Deductible VAT Account" is not defined
        Initialize();
        // [GIVEN] Reverse Charge VAT Posting Setup where "Reverse Chrg. VAT Acc." = "R" and "Non-Deductible VAT Account" = ''
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", '', LibraryRandom.RandInt(99));

        // [GIVEN] Purchase Invoice with VAT Amount = "X", Non-Deductible VAT Amount = "Y",
        LineAmount := CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        NonDeductibleBase := Round(LineAmount * (100 - GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) / 100);
        VATAmount := Round(LineAmount * VATPostingSetup."VAT %" / 100);
        NonDeductibleAmount := VATAmount - Round(VATAmount * GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 100);

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry created with "G/L Account No." = "R" and "Non-Deductible VAT Amount" = -"Y"
        VerifyGLEntry(DocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -NonDeductibleAmount);
        // [THEN] G/L Entry balance for "G/L Account No." = "R" is equal to "VAT Amount" = -"X"
        VerifyGLAccountBalance(DocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -VATAmount);
        // [THEN] VAT Entry created with "Non-Deductible VAT Amount" = "Y"
        VerifyVATEntry(DocumentNo, NonDeductibleBase, NonDeductibleAmount);
    end;


    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure JobLedgerEntryAfterPostPurchCrMemoWithNonDeductibleVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        JobLedgerEntry: Record "Job Ledger Entry";
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Non-Deductible] [VAT] [Job]
        // [SCENARIO 348104] When you post Non-deductible VAT Credit Memo the Job Ledger Entry gets correct amounts
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup with Non-deductible VAT
        LibraryNonDeductibleVAT.CreatVATPostingSetupAllowedForNonDeductibleVAT(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDec(40, 2));
        AssignDeductibleVATPct(VATPostingSetup, 0);
        VATPostingSetup.Modify(true);

        // [WHEN] Credit Memo posted with this VAT Setup and Job No.
        PostedCrMemoNo := CreateAndPostCrMemoWithJobAndVATPostingSetup(PurchaseLine, VATPostingSetup);

        // [THEN] Unit Cost on Job Ledger Entry is Amount Including VAT for original purchase line
        JobLedgerEntry.SetRange("Document No.", PostedCrMemoNo);
        JobLedgerEntry.FindFirst();
        JobLedgerEntry.TestField("Total Cost", -PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndDeductibleVATBlankNonDeductibleVATAcc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible]
        // [SCENARIO 277884] Non-deductible VAT Amount posted to account of purchase line and deferred to account of purchase line
        // [SCENARIO 277884] when VAT Posting Setup."Non-Deductible VAT Account" is blank
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = <blank>
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          '', 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, WorkDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "GLA"
        // [THEN] G/L Entries for "GLA" = 1000, 120 and balanced with deferall account -1000, -120, 500, 60, 500, 60.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndDeductibleVATWithNonDeductibleVATAcc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible]
        // [SCENARIO 277884] Non-deductible VAT Amount posted to account specified setup and deferred to account specified in setup
        // [SCENARIO 277884] when VAT Posting Setup."Non-Deductible VAT Account" is specified
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = "NDVA"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryERM.CreateGLAccountNo(), 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, WorkDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "NDVA"
        // [THEN] G/L Entries for "NDVA" = 120 and balanced with deferall account -120, 60, 60.

        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndZeroDeductibleVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible]
        // [SCENARIO 285131] 100 % non-deductible VAT Amount should be deferred (border case)
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 0%
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', 0);

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, WorkDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Non-Deductible VAT Amount to defer = 200
        // [THEN] G/L Entries for "GLA" = 1000, 200 and balanced with deferall account -1000, -200, 500, 100, 500, 100.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    procedure NonDedRevChrgVATRoundingOnPurchInvWithCustomLinesAndDimensions()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Reverse Charge VAT] [Dimension] [Rounding]
        // [SCENARIO 384393] Purchase invoice non-deductible VAT rounding in case of reverse charge VAT, several custom lines with different dimensions
        Initialize();
        // [GIVEN] Reverse charge VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 22, 40);
        // [GIVEN] Purchase invoice with several custom lines with different dimensions having in total Amount Excl. VAT = 1675.71, VAT Amount = 368.66
        CreatePurchaseInvoiceTFS384393(PurchaseHeader, VATPostingSetup);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several VAT entries having in total: Base = 670.28, Amount = 147.46, Nondeductible Base = 1005.43, Nondeductible Amount = 221.20
        FindVATEntry(VATEntry, PostedInvoiceNo);
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField(Base, 670.28);
        VATEntry.TestField(Amount, 147.46);
        VATEntry.TestField("Non-Deductible VAT Base", 1005.43);
        VATEntry.TestField("Non-Deductible VAT Amount", 221.2);
    end;

    [Test]
    procedure NonDedNormalVATRoundingOnPurchInvWithCustomLinesAndDimensions()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Normal VAT] [Dimension] [Rounding]
        // [SCENARIO 384393] Purchase invoice non-deductible VAT rounding in case of normal VAT, several custom lines with different dimensions
        Initialize();
        // [GIVEN] Normal VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 22, 40);
        // [GIVEN] Purchase invoice with several custom lines with different dimensions having in total Amount Excl. VAT = 1675.71, VAT Amount = 368.66
        CreatePurchaseInvoiceTFS384393(PurchaseHeader, VATPostingSetup);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several VAT entries having in total: Base = 670.28, Amount = 147.46, Nondeductible Base = 1005.43, Nondeductible Amount = 221.20
        FindVATEntry(VATEntry, PostedInvoiceNo);
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField(Base, 670.28);
        VATEntry.TestField(Amount, 147.46);
        VATEntry.TestField("Non-Deductible VAT Base", 1005.43);
        VATEntry.TestField("Non-Deductible VAT Amount", 221.2);
    end;

    [Test]
    procedure NonDedRevChrgVATRoundingOnPurchInvWith6LinesAndDimensions()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Reverse Charge VAT] [Dimension] [Rounding]
        // [SCENARIO 384393] Purchase invoice non-deductible VAT rounding in case of reverse charge VAT, several custom lines with different dimensions (384393 case 2)
        Initialize();
        // [GIVEN] Reverse charge VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 22, 40);
        // [GIVEN] Purchase invoice with 6 lines different dimensions each having Amount = 151.53, having in total Amount Excl. VAT = 909.18, VAT Amount = 200.02
        CreatePurchaseInvoiceTFS384393_2(PurchaseHeader, VATPostingSetup);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several VAT entries having in total: Base = 363.67, Amount = 80.01, Nondeductible Base = 545.51, Nondeductible Amount = 120.01
        FindVATEntry(VATEntry, PostedInvoiceNo);
        Assert.RecordCount(VATEntry, 6);
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField(Base, 363.67);
        VATEntry.TestField(Amount, 80.01);
        VATEntry.TestField("Non-Deductible VAT Base", 545.51);
        VATEntry.TestField("Non-Deductible VAT Amount", 120.01);
    end;

    [Test]
    procedure NonDedNormalVATRoundingOnPurchInvWith6LinesAndDimensions()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Normal VAT] [Dimension] [Rounding]
        // [SCENARIO 384393] Purchase invoice non-deductible VAT rounding in case of normal VAT, several custom lines with different dimensions (384393 case 2)
        Initialize();
        // [GIVEN] Normal VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 22, 40);
        // [GIVEN] Purchase invoice with 6 lines different dimensions each having Amount = 151.53, having in total Amount Excl. VAT = 909.18, VAT Amount = 200.02
        CreatePurchaseInvoiceTFS384393_2(PurchaseHeader, VATPostingSetup);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several VAT entries having in total: Base = 363.67, Amount = 80.01, Nondeductible Base = 545.51, Nondeductible Amount = 120.01
        FindVATEntry(VATEntry, PostedInvoiceNo);
        Assert.RecordCount(VATEntry, 6);
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField(Base, 363.67);
        VATEntry.TestField(Amount, 80.01);
        VATEntry.TestField("Non-Deductible VAT Base", 545.51);
        VATEntry.TestField("Non-Deductible VAT Amount", 120.01);
    end;

    [Test]
    procedure DeferralNonDedVATRounding()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Deferral] [Rounding]
        // [SCENARIO 394920] Purchase invoice non-deductible VAT rounding in case of deferrals with several periods
        Initialize();
        // [GIVEN] VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 22, 60);
        // [GIVEN] Deferral Template 6 periods
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", 6);
        // [GIVEN] Purchase Invoice with Amount = 426.5, Posting Date = 30-06-2021
        CreatePurchInvoiceWithDeferralAndDedVAT(
          PurchaseHeader, PurchaseLine, WorkDate(), VATPostingSetup, DeferralTemplate."Deferral Code", 426.5);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several deferral non-deductible G/L entries with total amount 37.53
        FindGLEntry(GLEntry, PostedInvoiceNo, VATPostingSetup."Non-Ded. Purchase VAT Account");
        Assert.RecordCount(GLEntry, 9);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 37.53);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndDeductibleVATBlankNonDeductibleVATAccReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible] [Reverse Charge VAT]
        // [SCENARIO 427120] Non-deductible VAT Amount posted to account of purchase line and deferred to account of purchase line
        // [SCENARIO 427120] when Reverse Charge VAT Posting Setup."Non-Deductible VAT Account" is blank
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = <blank>, "VAT Calculation Type" = "Reverse Charge VAAT"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          '', 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, GetPostingDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "GLA"
        // [THEN] G/L Entries for "GLA" = 1000, 120 and balanced with deferall account -1000, -120, 500, 60, 500, 60.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate, GetPostingDate());

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndDeductibleVATWithNonDeductibleVATAccReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible] [Reverse Charge VAT]
        // [SCENARIO 427120] Non-deductible VAT Amount posted to account specified setup and deferred to account specified in setup
        // [SCENARIO 427120] when Reverse Charge VAT Posting Setup."Non-Deductible VAT Account" is specified
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = "NDVA", "VAT Calculation Type" = "Reverse Charge VAAT"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          LibraryERM.CreateGLAccountNo(), 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, GetPostingDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "NDVA"
        // [THEN] G/L Entries for "NDVA" = 120 and balanced with deferall account -120, 60, 60.

        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate, GetPostingDate());

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndZeroDeductibleVATReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible] [Reverse Charge VAT]
        // [SCENARIO 427120] 100 % non-deductible Reverse Charge VAT Amount should be deferred (border case)
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 0%, "VAT Calculation Type" = "Reverse Charge VAAT"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", '', 0);

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, GetPostingDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Non-Deductible VAT Amount to defer = 200
        // [THEN] G/L Entries for "GLA" = 1000, 200 and balanced with deferall account -1000, -200, 500, 100, 500, 100.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate, GetPostingDate());

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralNonDedVATRoundingReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Deferral] [Rounding]
        // [SCENARIO 427120] Purchase invoice non-deductible Reverse Charge VAT rounding in case of deferrals with several periods 
        Initialize();
        // [GIVEN] VAT posting setup with VAT = 22% and Deductible VAT = 40%, "VAT Calculation Type" = "Reverse Charge VAAT"
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 22, 60);
        // [GIVEN] Deferral Template 6 periods
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", 6);
        // [GIVEN] Purchase Invoice with Amount = 426.5, Posting Date = 30-06-2021
        CreatePurchInvoiceWithDeferralAndDedVAT(
          PurchaseHeader, PurchaseLine, GetPostingDate(), VATPostingSetup, DeferralTemplate."Deferral Code", 426.5);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several deferral non-deductible G/L entries with total amount 37.53
        FindGLEntry(GLEntry, PostedInvoiceNo, VATPostingSetup."Non-Ded. Purchase VAT Account");
        Assert.RecordCount(GLEntry, 9);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 37.53);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineWithDeferralAndNonDeductibleVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 475879] Posting results are correct for journal line with deferrals and Non-Deductible VAT

        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = <blank>
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          '', 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] General journal line with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreateGenJnlLineWithDeferralAndDedVATCustom(
            GenJournalLine, WorkDate(), VATPostingSetup, '',
            DeferralTemplate."Deferral Code");

        // [WHEN] Post purchase invoice
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "GLA"
        // [THEN] G/L Entries for "GLA" = 1000, 120 and balanced with deferall account -1000, -120, 500, 60, 500, 60.
        VerifyGLEntryDeferrals(
            DeferralTemplate."Deferral Account", GenJournalLine."Account No.", GenJournalLine."VAT Base Amount (LCY)", VATPostingSetup, DeferralTemplate, GenJournalLine."Posting Date");

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non Ded. VAT Misc.");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non Ded. VAT Misc.");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non Ded. VAT Misc.");
    end;

    local procedure CreatePurchaseInvoiceTFS384393(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        DimensionValue: array[7] of Record "Dimension Value";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        GeneralPostingType: Enum "General Posting Type";
    begin
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GeneralPostingType::Purchase);
        Create7DimensionValues(DimensionValue);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 1.42, DimensionValue[1]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 88.97, DimensionValue[2]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 48.94, DimensionValue[3]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 90.44, DimensionValue[3]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 60.27, DimensionValue[4]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 52.29, DimensionValue[3]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 64.12, DimensionValue[1]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 107.87, DimensionValue[5]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 48.03, DimensionValue[6]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 219.05, DimensionValue[5]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 132.73, DimensionValue[2]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 50.82, DimensionValue[2]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 68.85, DimensionValue[4]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 222.95, DimensionValue[5]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 58.9, DimensionValue[7]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 65.2, DimensionValue[2]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 232.63, DimensionValue[5]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 62.23, DimensionValue[1]);
    end;

    local procedure CreatePurchaseInvoiceTFS384393_2(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        DimensionValue: array[7] of Record "Dimension Value";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        GeneralPostingType: Enum "General Posting Type";
        i: Integer;
    begin
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GeneralPostingType::Purchase);
        Create7DimensionValues(DimensionValue);
        for i := 1 to 6 do
            CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 151.53, DimensionValue[i]);
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateFixedAsset(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFA.CreateFixedAsset(FixedAsset);
        FASetup.Get();
        LibraryFA.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.Validate("FA Posting Group", FindFAPostingGroup(GenProdPostingGroup, VATProductPostingGroup));
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        exit(CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, VATPostingSetup));
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        GeneralPostingSetup: Record "General Posting Setup";
        CurrencyCode: Code[20];
        VendNo: Code[20];
        GLAccNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VendNo :=
          CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccNo :=
          CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CurrencyCode := PurchaseHeader."Currency Code";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        if CurrencyCode <> '' then begin
            PurchaseHeader.Validate("Currency Code", CurrencyCode);
            PurchaseHeader.Modify();
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreatePurchaseInvoiceWithFixedAsset(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VendNo: Code[20];
        FANo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VendNo :=
          CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        FANo :=
          CreateFixedAsset(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]; VATBusinessPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchInvoiceWithDeferralAndDedVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; DeferralCode: Code[10]; DirectUnitCost: Decimal)
    begin
        CreatePurchInvoiceWithDeferralAndDedVATCustom(PurchaseHeader, PurchaseLine, PostingDate, VATPostingSetup, '', DeferralCode, DirectUnitCost);
    end;

    local procedure CreatePurchInvoiceWithDeferralAndDedVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; DeferralCode: Code[10]; DirectUnitCost: Decimal)
    begin
        CreatePurchInvoiceWithDeferralAndDedVATCustom(PurchaseHeader, PurchaseLine, PostingDate, VATPostingSetup, CurrencyCode, DeferralCode, DirectUnitCost);
    end;

    local procedure CreatePurchInvoiceWithDeferralAndDedVATCustom(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; DeferralCode: Code[10]; DirectUnitCost: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGenJnlLineWithDeferralAndDedVATCustom(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; DeferralCode: Code[10])
    var
        GLAccount: Record "G/L Account";
    begin
        //q1
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Deferral Code", DeferralCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePurchaseLineGL(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; DirectUnitCost: Decimal; DimensionValue: Record "Dimension Value")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(PurchaseLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        PurchaseLine.Modify(true);
    end;

    local procedure FindFAPostingGroup(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.FindFirst();
        FAPostingGroup.Validate("Acquisition Cost Account",
          CreateGLAccount(GenProdPostingGroup, VATProductPostingGroup));
        FAPostingGroup.Modify(true);
        exit(FAPostingGroup.Code);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindLast();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindLast();
    end;

    local procedure GetPostingDate(): Date
    begin
        exit(DMY2Date(30, 6, Date2DMY(WorkDate(), 3)));
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(UpdateVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT"));
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: enum "Tax Calculation Type") DeductiblePercent: Decimal
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalculationType);
        DeductiblePercent := GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        AssignNonDeductibleVATAccount(VATPostingSetup, GLAccount."No.");
        AssignDeductibleVATPct(VATPostingSetup, LibraryRandom.RandInt(99));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateNonDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; NonDeductibleGLAccount: Code[20]; DeductiblePct: Decimal)
    begin
        LibraryNonDeductibleVAT.CreatVATPostingSetupAllowedForNonDeductibleVAT(
            VATPostingSetup, VATCalculationType, LibraryRandom.RandDecInRange(10, 25, 2));
        AssignNonDeductibleVATAccount(VATPostingSetup, NonDeductibleGLAccount);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        AssignDeductibleVATPct(VATPostingSetup, DeductiblePct);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithPct(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATPct: Decimal; DeductiblePct: Decimal)
    begin
        LibraryNonDeductibleVAT.CreatVATPostingSetupAllowedForNonDeductibleVAT(VATPostingSetup, VATCalculationType, VATPct);
        AssignNonDeductibleVATAccount(VATPostingSetup, LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        AssignDeductibleVATPct(VATPostingSetup, DeductiblePct);
        VATPostingSetup.Modify(true);
    end;

    local procedure Create7DimensionValues(var DimensionValue: array[7] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        for i := 1 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[i], Dimension.Code);
    end;

    local procedure CreateAndPostCrMemoWithJobAndVATPostingSetup(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateJobWithJobsUtil(JobTask);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateJobWithJobsUtil(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure GetNonDeductibleVATAccountNo(VATPostingSetup: Record "VAT Posting Setup"; PostingGLAccountNo: Code[20]): Code[20]
    begin
        if VATPostingSetup."Non-Ded. Purchase VAT Account" = '' then
            exit(PostingGLAccountNo);

        VATPostingSetup.TestField("Non-Ded. Purchase VAT Account");
        exit(VATPostingSetup."Non-Ded. Purchase VAT Account");
    end;

    local procedure GetNonDeductibleVATExpectedAmount(VATPostingSetup: Record "VAT Posting Setup"; Amount: Decimal): Decimal
    var
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := Round(Amount * VATPostingSetup."VAT %" / 100);
        NonDeductibleVATAmount := Round(NonDeductibleVATAmount * (100 - GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) / 100);

        if VATPostingSetup."Non-Ded. Purchase VAT Account" = '' then
            exit(Amount + NonDeductibleVATAmount);

        exit(NonDeductibleVATAmount);
    end;

    local procedure GetZeroNonDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var NonDeductGLAccountNo: Code[20]; VATCalcType: Enum "Tax Calculation Type") DeductiblePercent: Decimal
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalcType);
        DeductiblePercent := GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup);
        NonDeductGLAccountNo := VATPostingSetup."Non-Ded. Purchase VAT Account";
        AssignNonDeductibleVATAccount(VATPostingSetup, '');
        AssignDeductibleVATPct(VATPostingSetup, 0);
        VATPostingSetup.Modify(true);
    end;

    local procedure GetAcquisitionAccFromPurchLine(PurchLine: Record "Purchase Line"): Code[20]
    var
        FADeprBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FADeprBook.Get(PurchLine."No.", PurchLine."Depreciation Book Code");
        FAPostingGroup.Get(FADeprBook."FA Posting Group");
        exit(FAPostingGroup."Acquisition Cost Account");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccNo);
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, IncorrectGLEntryAmtErr);
    end;

    local procedure VerifyGLAccountBalance(DocumentNo: Code[20]; GLAccNo: Code[20]; ExpectedGLAccBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetCurrentKey("Transaction No.", "G/L Account No.", "Document No.", "Source Type", "Source No.");
            SetRange("Document No.", DocumentNo);
            SetRange("G/L Account No.", GLAccNo);
            CalcSums(Amount);
            Assert.AreEqual(ExpectedGLAccBalance, Amount, IncorrectGLEntryAmtErr);
        end;
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; NonDeductibleBase: Decimal; NonDeductibleAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentNo);
        VATEntry.TestField("Non-Deductible VAT Base", NonDeductibleBase);
        VATEntry.TestField("Non-Deductible VAT Amount", NonDeductibleAmount);
    end;

    local procedure VerifyFALedgEntry(DocNo: Code[20]; FANo: Code[20]; ExpectedAmount: Decimal)
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Document No.", DocNo);
        FALedgEntry.CalcSums(Amount);
        FALedgEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntryDeferrals(DeferralAccountNo: Code[20]; PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplate: Record "Deferral Template")
    begin
        VerifyGLEntryDeferrals(DeferralAccountNo, PurchaseLine."No.", PurchaseLine.Amount, VATPostingSetup, DeferralTemplate, WorkDate());
    end;

    local procedure VerifyGLEntryDeferrals(DeferralAccountNo: Code[20]; PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplate: Record "Deferral Template"; PostingDate: Date)
    begin
        VerifyGLEntryDeferrals(DeferralAccountNo, PurchaseLine."No.", PurchaseLine.Amount, VATPostingSetup, DeferralTemplate, PostingDate);
    end;

    local procedure VerifyGLEntryDeferrals(DeferralAccountNo: Code[20]; PostingGLAccNo: Code[20]; Amount: Decimal; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplate: Record "Deferral Template"; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        // We post to "Posting G/Account" + "Non-Ded. Purchase VAT Account" = 2
        // We post 1 balancing deferral entry + period deferral entries per each = 1 + CountOfPeriod
        GLEntry.SetRange("G/L Account No.", DeferralAccountNo);
        Assert.RecordCount(GLEntry, (DeferralTemplate."No. of Periods" + 1) * 2);

        Clear(GLEntry);
        GLEntry.SetRange("G/L Account No.", GetNonDeductibleVATAccountNo(VATPostingSetup, PostingGLAccNo));
        GLEntry.SetFilter(Amount, '<%1', 0);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -GetNonDeductibleVATExpectedAmount(VATPostingSetup, Amount));
        if VATPostingSetup."Non-Ded. Purchase VAT Account" <> '' then
            Assert.RecordCount(GLEntry, 1)
        else
            Assert.RecordCount(GLEntry, 2);

        Clear(GLEntry);
        GLEntry.SetRange("G/L Account No.", GetNonDeductibleVATAccountNo(VATPostingSetup, PostingGLAccNo));
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 0);
        if VATPostingSetup."Non-Ded. Purchase VAT Account" <> '' then
            Assert.RecordCount(GLEntry, 2)
        else
            Assert.RecordCount(GLEntry, 4);
    end;

    local procedure VerifyGLEntriesDeferralsAmount(PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GetNonDeductibleVATAccountNo(VATPostingSetup, PurchaseLine."No."));
        GLEntry.SetFilter(Amount, '<%1', 0);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -GetNonDeductibleVATExpectedAmount(VATPostingSetup, PurchaseLine.Amount));
    end;

    local procedure VerifyGLEntryFAEntryLinedPair(GLEntry: Record "G/L Entry")
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        GLEntry.TestField("FA Entry Type");
        GLEntry.TestField("FA Entry No.");
        FALedgerEntry.Get(GLEntry."FA Entry No.");
        FALedgerEntry.TestField("G/L Entry No.", GLEntry."Entry No.");
        FALedgerEntry.TestField(Amount, GLEntry.Amount);
    end;

    local procedure SetJobForPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        PurchaseLine.Validate("Job Line Type", "Job Line Type"::Billable);
        LibraryJob.CreateJob(Job);
        PurchaseLine.Validate("Job No.", Job."No.");
        LibraryJob.CreateJobTask(Job, JobTask);
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate(Quantity, LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Modify(true);
    end;

    local procedure TearDownLastUsedDateInPurchInvoiceNoSeries()
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
    begin
        PurchPayablesSetup.Get();
        NoSeriesLine.SetRange("Series Code", PurchPayablesSetup."Posted Invoice Nos.");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    local procedure GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(100 - VATPostingSetup."Non-Deductible VAT %");
    end;

    local procedure AssignDeductiblePctToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; DeductiblePct: Decimal)
    begin
        VATAmountLine."Non-Deductible VAT %" := 100 - DeductiblePct;
    end;

    local procedure AssignDeductibleVATPct(var VATPostingSetup: Record "VAT Posting Setup"; DedVATPct: Decimal)
    begin
        LibraryNonDeductibleVAT.SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", 100 - DedVATPct);
    end;

    local procedure AssignNonDeductibleVATAccount(var VATPostingSetup: Record "VAT Posting Setup"; GLAccNo: Code[20])
    begin
        VATPostingSetup.Validate("Non-Ded. Purchase VAT Account", GLAccNo);
    end;

    local procedure GetDeductibleVATPctFromVATAmountLine(VATAmountLine: Record "VAT Amount Line"): Decimal
    begin
        exit(100 - VATAmountLine."Non-Deductible VAT %");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

