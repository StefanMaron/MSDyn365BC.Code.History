codeunit 144001 "IT - Non Ded. VAT"
{
    // Test that Nondeductable VAT is calculated correctly after posting a Purchase Invoice.
    //   1. Post a purchase invoice and verify Non Deductible VAT in posted entries.
    // 
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                         TFS ID
    // -------------------------------------------------------------------------------------------------------
    // NonDeductibleVATInPurchaseInvoice                                                          152934
    // VATAmtOnAcqAccountWhenZeroDedPctAndBlankNDVATAccount                                       118209

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFA: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IncorrectGLEntryAmtErr: Label 'Incorect amount in G/L Entry.';

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

        // Setup.
        DeductiblePercent := UpdateVATPostingSetup(VATPostingSetup);

        // Exercise: Post a Purchase Invoice and calculate Non-Deductible Base and Amount.
        LineAmount := CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLSetup.Get();
        NonDeductibleBase :=
          Round(LineAmount * (100 - VATPostingSetup."Deductible %") / 100, GLSetup."Amount Rounding Precision");
        VATAmount := Round(LineAmount * VATPostingSetup."VAT %" / 100, GLSetup."Amount Rounding Precision");

        // As Non Deductible Amount = VAT Amount - Deductible Amount.
        NonDeductibleAmount :=
          VATAmount - Round(VATAmount * VATPostingSetup."Deductible %" / 100, GLSetup."Amount Rounding Precision");

        // Verify: Verify posted entries.
        VerifyGLEntry(DocumentNo, VATPostingSetup."Nondeductible VAT Account", NonDeductibleAmount);
        VerifyVATEntry(DocumentNo, NonDeductibleBase, NonDeductibleAmount);

        // Tear Down.
        VATPostingSetup.Validate("Deductible %", DeductiblePercent);
        VATPostingSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnAcqAccountWhenZeroDedPctAndBlankNDVATAccount()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        NonDeductGLAccountNo: Code[20];
        LineAmount: Decimal;
        TotalAmount: Decimal;
        OldDeductiblePercent: Decimal;
    begin
        // [SCENARIO 118209] VAT amount is posted to FA's Acquisition Account when 'Deductible %' = 0 and 'Non. Deductible VAT Account' is blank
        // [GIVEN] VAT Posting Setup with "Deductible %" = 0 and blank "Non. Deductible VAT Account"
        OldDeductiblePercent := GetZeroNonDeductibleVATPostingSetup(VATPostingSetup, NonDeductGLAccountNo);
        // [GIVEN] Purchase Invoice with Fixed Asset which Acquisition Account No. = "X" and Non Deductible VAT Amount = "Y"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        GLSetup.Get();
        TotalAmount := Round(LineAmount * (1 + VATPostingSetup."VAT %" / 100), GLSetup."Amount Rounding Precision");

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry posted with G/L Account No. = "X" and Non Deductible VAT Amount = "Y"
        VerifyGLAccountBalance(DocumentNo, GetAcquisitionAccFromPurchLine(PurchLine), TotalAmount);

        // Tear Down.
        VATPostingSetup.Validate("Deductible %", OldDeductiblePercent);
        VATPostingSetup.Validate("Nondeductible VAT Account", NonDeductGLAccountNo);
        VATPostingSetup.Modify(true);
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
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", '', 0);
        // [GIVEN] Purchase Invoice with Fixed Asset, "Non-Deductible VAT Amount" = "Y1", "Amount Including VAT" = "Y2"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        VATAmount :=
          Round(LineAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision);

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
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryERM.CreateGLAccountNo, 0);
        // [GIVEN] Purchase Invoice with Fixed Asset, "Non-Deductible VAT Amount" = "Y1", "Amount Including VAT" = "Y2"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        VATAmount :=
          Round(LineAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision);

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

        // [GIVEN] Reverse Charge VAT Posting Setup where "Reverse Chrg. VAT Acc." = "R" and "Non-Deductible VAT Account" = ''
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", '', LibraryRandom.RandInt(99));

        // [GIVEN] Purchase Invoice with VAT Amount = "X", Non-Deductible VAT Amount = "Y",
        LineAmount := CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        NonDeductibleBase := Round(LineAmount * (100 - VATPostingSetup."Deductible %") / 100);
        VATAmount := Round(LineAmount * VATPostingSetup."VAT %" / 100);
        NonDeductibleAmount := VATAmount - Round(VATAmount * VATPostingSetup."Deductible %" / 100);

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
    [Scope('OnPrem')]
    procedure VATAmountLineUpdateLineNondedBaseAmountWithDeductiblePct()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 221098] Values of "Nondeductible Base" and "Nondeductible Amount" must be update in "VAT Amount Line"."UpdateLines" with "Deductible %" <> 0

        // [GIVEN] "VAT Amount Line" with:
        // [GIVEN] "Line Amount" = 100, "VAT %" = 20, "Deductible %" = 25
        TempVATAmountLine.Init();
        TempVATAmountLine."Line Amount" := LibraryRandom.RandIntInRange(10, 100);
        TempVATAmountLine."VAT %" := LibraryRandom.RandIntInRange(10, 50);
        TempVATAmountLine."Deductible %" := LibraryRandom.RandIntInRange(10, 50);
        TempVATAmountLine.Insert();

        // [WHEN] Invoke "VAT Amount Line"."UpdateLines"
        TempVATAmountLine.UpdateLines(
          TotalVATAmount, Currency, LibraryRandom.RandIntInRange(10, 50), false, 0, '', true, WorkDate);

        // [THEN] "VAT Amount Line"."Nondeductible Base" = 75
        TempVATAmountLine.TestField("Nondeductible Base", TempVATAmountLine."VAT Base" * (100 - TempVATAmountLine."Deductible %") / 100);

        // [THEN] "VAT Amount Line"."Nondeductible Amount" = 15
        TempVATAmountLine.TestField(
          "Nondeductible Amount", TempVATAmountLine."VAT Amount" * (100 - TempVATAmountLine."Deductible %") / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineUpdateLineNondedBaseAmountWithDeductiblePctZero()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 221098] Values of "Nondeductible Base" and "Nondeductible Amount" must be update in "VAT Amount Line"."UpdateLines" with "Deductible %" = 0

        // [GIVEN] "VAT Amount Line" with:
        // [GIVEN] "Line Amount" = 100, "VAT %" = 20, "Deductible %" = 0
        TempVATAmountLine.Init();
        TempVATAmountLine."Line Amount" := LibraryRandom.RandIntInRange(10, 100);
        TempVATAmountLine."VAT %" := LibraryRandom.RandIntInRange(10, 100);
        TempVATAmountLine."Deductible %" := 0;
        TempVATAmountLine.Insert();

        // [WHEN] Invoke "VAT Amount Line"."UpdateLines"
        TempVATAmountLine.UpdateLines(
          TotalVATAmount, Currency, LibraryRandom.RandIntInRange(10, 50), false, 0, '', true, WorkDate);

        // [THEN] "VAT Amount Line"."Nondeductible Base" = 100
        TempVATAmountLine.TestField("Nondeductible Base", TempVATAmountLine."VAT Base" * (100 - TempVATAmountLine."Deductible %") / 100);

        // [THEN] "VAT Amount Line"."Nondeductible Amount" = 20
        TempVATAmountLine.TestField(
          "Nondeductible Amount", TempVATAmountLine."VAT Amount" * (100 - TempVATAmountLine."Deductible %") / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineUpdateLineNondedBaseAmountWithFullDeductibleVAT()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 221098] Values of "Nondeductible Base" and "Nondeductible Amount" must be update in "VAT Amount Line"."UpdateLines" with "Deductible %" = 100

        // [GIVEN] "VAT Amount Line" with:
        // [GIVEN] "Line Amount" = 100, "VAT %" = 20, "Deductible %" = 100
        TempVATAmountLine.Init();
        TempVATAmountLine."Line Amount" := LibraryRandom.RandIntInRange(10, 100);
        TempVATAmountLine."VAT %" := LibraryRandom.RandIntInRange(10, 100);
        TempVATAmountLine."Deductible %" := 100;
        TempVATAmountLine.Insert();

        // [WHEN] Invoke "VAT Amount Line"."UpdateLines"
        TempVATAmountLine.UpdateLines(
          TotalVATAmount, Currency, LibraryRandom.RandIntInRange(10, 50), false, 0, '', true, WorkDate);

        // [THEN] "VAT Amount Line"."Nondeductible Base" = 0
        TempVATAmountLine.TestField("Nondeductible Base", TempVATAmountLine."VAT Base" * (100 - TempVATAmountLine."Deductible %") / 100);

        // [THEN] "VAT Amount Line"."Nondeductible Amount" = 0
        TempVATAmountLine.TestField(
          "Nondeductible Amount", TempVATAmountLine."VAT Amount" * (100 - TempVATAmountLine."Deductible %") / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineUpdateLineNondedBaseAmountWithoutVAT()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 221098] Values of "Nondeductible Base" and "Nondeductible Amount" must be update in "VAT Amount Line"."UpdateLines" with "Deductible %" = 25 and "VAT %" = 0

        // [GIVEN] "VAT Amount Line" with:
        // [GIVEN] "Line Amount" = 100, "VAT %" = 0, "Deductible %" = 25
        TempVATAmountLine.Init();
        TempVATAmountLine."Line Amount" := LibraryRandom.RandIntInRange(10, 100);
        TempVATAmountLine."VAT %" := 0;
        TempVATAmountLine."Deductible %" := LibraryRandom.RandIntInRange(10, 50);
        TempVATAmountLine.Insert();

        // [WHEN] Invoke "VAT Amount Line"."UpdateLines"
        TempVATAmountLine.UpdateLines(
          TotalVATAmount, Currency, LibraryRandom.RandIntInRange(10, 50), false, 0, '', true, WorkDate);

        // [THEN] "VAT Amount Line"."Nondeductible Base" = 75
        TempVATAmountLine.TestField("Nondeductible Base", TempVATAmountLine."VAT Base" * (100 - TempVATAmountLine."Deductible %") / 100);

        // [THEN] "VAT Amount Line"."Nondeductible Amount" = 0
        TempVATAmountLine.TestField(
          "Nondeductible Amount", TempVATAmountLine."VAT Amount" * (100 - TempVATAmountLine."Deductible %") / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineUpdateLineNondedBaseAmountWithoutLineAmount()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 221098] Values of "Nondeductible Base" and "Nondeductible Amount" must be update in "VAT Amount Line"."UpdateLines" with "Deductible %" = 25, "VAT %" = 20 and "Line Amount" = 0

        // [GIVEN] "VAT Amount Line" with:
        // [GIVEN] "Line Amount" = 0, "VAT %" = 20, "Deductible %" = 25
        TempVATAmountLine.Init();
        TempVATAmountLine."Line Amount" := 0;
        TempVATAmountLine."VAT %" := LibraryRandom.RandIntInRange(10, 50);
        TempVATAmountLine."Deductible %" := LibraryRandom.RandIntInRange(10, 50);
        TempVATAmountLine.Insert();

        // [WHEN] Invoke "VAT Amount Line"."UpdateLines"
        TempVATAmountLine.UpdateLines(
          TotalVATAmount, Currency, LibraryRandom.RandIntInRange(10, 50), false, 0, '', true, WorkDate);

        // [THEN] "VAT Amount Line"."Nondeductible Base" = 0
        TempVATAmountLine.TestField("Nondeductible Base", TempVATAmountLine."VAT Base" * (100 - TempVATAmountLine."Deductible %") / 100);

        // [THEN] "VAT Amount Line"."Nondeductible Amount" = 0
        TempVATAmountLine.TestField(
          "Nondeductible Amount", TempVATAmountLine."VAT Amount" * (100 - TempVATAmountLine."Deductible %") / 100);
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
        CreatePurchInvoiceWithDeferralAndDedVAT(PurchaseHeader, PurchaseLine, VATPostingSetup, DeferralTemplate);

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "GLA"
        // [THEN] G/L Entries for "GLA" = 1000, 120 and balanced with deferall account -1000, -120, 500, 60, 500, 60.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);
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

        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = "NDVA"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryERM.CreateGLAccountNo, 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(PurchaseHeader, PurchaseLine, VATPostingSetup, DeferralTemplate);

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "NDVA"
        // [THEN] G/L Entries for "NDVA" = 120 and balanced with deferall account -120, 60, 60.

        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);
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

        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 0%
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', 0);

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(PurchaseHeader, PurchaseLine, VATPostingSetup, DeferralTemplate);

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Non-Deductible VAT Amount to defer = 200
        // [THEN] G/L Entries for "GLA" = 1000, 200 and balanced with deferall account -1000, -200, 500, 100, 500, 100.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);
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
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendNo: Code[20];
        GLAccNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VendNo :=
          CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccNo :=
          CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
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

    local procedure CreatePurchInvoiceWithDeferralAndDedVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplate: Record "Deferral Template")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Posting Date", WorkDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(200, 300, 2));
        PurchaseLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        PurchaseLine.Modify(true);
    end;

    local procedure FindFAPostingGroup(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.FindFirst;
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
        GLEntry.FindLast;
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindLast;
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup") DeductiblePercent: Decimal
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        DeductiblePercent := VATPostingSetup."Deductible %";
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Nondeductible VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Deductible %", LibraryRandom.RandInt(99));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateNonDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; NonDeductibleGLAccount: Code[20]; DeductiblePct: Decimal)
    begin
        with VATPostingSetup do begin
            LibraryERM.CreateVATPostingSetupWithAccounts(
              VATPostingSetup, VATCalculationType, LibraryRandom.RandDecInRange(10, 25, 2));
            Validate("Nondeductible VAT Account", NonDeductibleGLAccount);
            Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo);
            Validate("Deductible %", DeductiblePct);
            Modify(true);
        end;
    end;

    local procedure GetNonDeductibleVATAccountNo(VATPostingSetup: Record "VAT Posting Setup"; PostingGLAccountNo: Code[20]): Code[20]
    begin
        if VATPostingSetup."Nondeductible VAT Account" = '' then
            exit(PostingGLAccountNo);

        VATPostingSetup.TestField("Nondeductible VAT Account");
        exit(VATPostingSetup."Nondeductible VAT Account");
    end;

    local procedure GetNonDeductibleVATExpectedAmount(VATPostingSetup: Record "VAT Posting Setup"; PurchaseLine: Record "Purchase Line"): Decimal
    var
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := Round(PurchaseLine.Amount * VATPostingSetup."VAT %" / 100);
        NonDeductibleVATAmount := Round(NonDeductibleVATAmount * (100 - VATPostingSetup."Deductible %") / 100);

        if VATPostingSetup."Nondeductible VAT Account" = '' then
            exit(PurchaseLine.Amount + NonDeductibleVATAmount);

        exit(NonDeductibleVATAmount);
    end;

    local procedure GetZeroNonDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var NonDeductGLAccountNo: Code[20]) DeductiblePercent: Decimal
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        DeductiblePercent := VATPostingSetup."Deductible %";
        NonDeductGLAccountNo := VATPostingSetup."Nondeductible VAT Account";
        VATPostingSetup.Validate("Nondeductible VAT Account", '');
        VATPostingSetup.Validate("Deductible %", 0);
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
            SetCurrentKey("Transaction No.", "G/L Account No.", "Document No.", Positive, "Source Type", "Source No.");
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
        VATEntry.TestField("Nondeductible Base", NonDeductibleBase);
        VATEntry.TestField("Nondeductible Amount", NonDeductibleAmount);
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
    var
        GLEntry: Record "G/L Entry";
    begin
        // We post to "Posting G/Account" + "Nondeductible VAT Account" = 2
        // We post 1 balancing deferral entry + period deferral entries per each = 1 + CountOfPeriod
        GLEntry.SetRange("G/L Account No.", DeferralAccountNo);
        Assert.RecordCount(GLEntry, (DeferralTemplate."No. of Periods" + 1) * 2);

        Clear(GLEntry);
        GLEntry.SetRange("G/L Account No.", GetNonDeductibleVATAccountNo(VATPostingSetup, PurchaseLine."No."));
        GLEntry.SetFilter(Amount, '<%1', 0);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -GetNonDeductibleVATExpectedAmount(VATPostingSetup, PurchaseLine));
        if VATPostingSetup."Nondeductible VAT Account" <> '' then
            Assert.RecordCount(GLEntry, 1)
        else
            Assert.RecordCount(GLEntry, 2);

        Clear(GLEntry);
        GLEntry.SetRange("G/L Account No.", GetNonDeductibleVATAccountNo(VATPostingSetup, PurchaseLine."No."));
        GLEntry.SetRange("Posting Date", WorkDate);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 0);
        if VATPostingSetup."Nondeductible VAT Account" <> '' then
            Assert.RecordCount(GLEntry, 2)
        else
            Assert.RecordCount(GLEntry, 4);
    end;
}

