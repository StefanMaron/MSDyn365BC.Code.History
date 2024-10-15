codeunit 134282 "Non-Deductible UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non-Deductible VAT] [UT]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        DifferentNonDedVATRatesSameVATIdentifierErr: Label 'You cannot set different Non-Deductible VAT % for the combinations of business and product groups with the same VAT identifier.\The following combination with the same VAT identifier has different Non-Deductible VAT %: business group %1, product group %2', Comment = '%1, %2 - codes';

    [Test]
    procedure NonDeductibleAmountsInPurchLineEndToEnd()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        NonDeductibleVATPct: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 456471] Non-Deductible VAT data is correct in purchase line
        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT %" = 20, "Non-Deductible %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with item connected to Non-Deductible VAT Posting Setup
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        // [WHEN] Set Amount = 1000 in purcahse line
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        // [THEN] "Non-Deductible VAT %" is 10 in purchase line
        // [THEN] "Non-Deductible VAT Base" is 1000 in purchase line
        // [THEN] "Non-Deductible VAT Amount" is 20 in purchase line
        NonDeductibleVATPct := LibraryNonDeductibleVAT.GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup);
        LibraryNonDeductibleVAT.VerifyNonDeductibleAmountsInPurchLine(
            PurchLine, NonDeductibleVATPct,
            Round(PurchLine.Amount * NonDeductibleVATPct / 100),
            Round((PurchLine."Amount Including VAT" - PurchLine.Amount) * NonDeductibleVATPct / 100));
    end;

    [Test]
    procedure NonDeductibleVATInVATAmountLineOnCalcVATFields()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [VAT Amount Line]
        // [SCENARIO 456471] The CalcVATFields function of the VAT Amount Line table calculates Non-Deductible VAT
        Initialize();
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] "VAT Base" is 1000 in the VAT Amount Line
        VATAmountLine."VAT Base" := LibraryRandom.RandDec(100, 2);
        // [GIVEN] "Amount Including VAT" is 1250 in the VAT Amount Line
        VATAmountLine."Amount Including VAT" := VATAmountLine."VAT Base" + LibraryRandom.RandDec(100, 2);
        VATAmountLine."Non-Deductible VAT %" := VATPostingSetup."Non-Deductible VAT %";
        // [WHEN] Call CalcVATFields of the VAT Amount Line table
        VATAmountLine.CalcVATFields('', false, 0);
        // [THEN] Non-Deductible VAT Base is
        VATAmountLine.TestField("Non-Deductible VAT Base", Round(VATAmountLine."VAT Base" * VATAmountLine."Non-Deductible VAT %" / 100));
        VATAmountLine.TestField(
            "Non-Deductible VAT Amount",
            Round((VATAmountLine."Amount Including VAT" - VATAmountLine."VAT Base") * VATAmountLine."Non-Deductible VAT %" / 100));
    end;

    [Test]
    procedure NonDedVATAmountRecalcWhenUpdateNonDedVATPctInPurchaseLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        NonDeductibleVATPct: Decimal;
    begin
        // [SCENARIO 456471] Non-Deductible VAT amount is updated when Stan changes the Non-Deductible VAT % in purchase line

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT %" = 20, "Non-Deductible %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with item connected to Non-Deductible VAT Posting Setup
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        // [GIVEN] Purchase line with amount = 1000
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        NonDeductibleVATPct := Round(LibraryNonDeductibleVAT.GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 2);
        // [WHEN] Change "Non-Deductible VAT %" to 20 in purchase line
        PurchLine.Validate("Non-Deductible VAT %", NonDeductibleVATPct);
        // [THEN] "Non-Deductible VAT Amount" is 40 in purchase line
        LibraryNonDeductibleVAT.VerifyNonDeductibleAmountsInPurchLine(
            PurchLine, NonDeductibleVATPct,
            Round(PurchLine.Amount * NonDeductibleVATPct / 100),
            Round((PurchLine."Amount Including VAT" - PurchLine.Amount) * NonDeductibleVATPct / 100));
    end;

    [Test]
    procedure SetDiffNonDedVATPercentInVATPostingSetupWithDiffVATIdentifiers()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        NonDedVATPercent: Decimal;
    begin
        // [SCENARIO 474024] Stan can create VAT Posting Setup with the different Non-Deductible VAT percents and different VAT identifiers

        Initialize();
        // [GIVEN] VAT Posting Setup "V1" with "VAT Identifier" = "X", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        NonDedVATPercent := VATPostingSetup."Non-Deductible VAT %";
        // [GIVEN] VAT Posting Setup "V2" with "VAT Identifier" = "Y", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [WHEN] Set "Non-Deductible VAT %" = 11 in "V2"
        NonDedVATPercent += 1;
        VATPostingSetup.Validate("Non-Deductible VAT %", NonDedVATPercent);
        VATPostingSetup.Modify(true);
        // [THEN] The changes are saved in V2 without error
        VATPostingSetup.Find();
        VATPostingSetup.TestField("Non-Deductible VAT %", NonDedVATPercent);
    end;

    [Test]
    procedure CannotSetDiffNonDedVATPercentInVATPostingSetupWithSameVATIdentifiers()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupCopy: Record "VAT Posting Setup";
    begin
        // [SCENARIO 474024] Stan cannot create VAT Posting Setup with the different Non-Deductible VAT percents and same VAT identifiers

        Initialize();
        // [GIVEN] VAT Posting Setup "V1" with "VAT Identifier" = "X", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetupCopy := VATPostingSetup;
        // [GIVEN] VAT Posting Setup "V2" with "VAT Identifier" = "Y", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 20
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Set "VAT Identifier" = "X" to "V1"
        asserterror VATPostingSetup.Validate("VAT Identifier", VATPostingSetupCopy."VAT Identifier");
        // [THEN] An error message thrown that it is not possible and the same setup exists for "V1"
        Assert.ExpectedError(StrSubstNo(DifferentNonDedVATRatesSameVATIdentifierErr, VATPostingSetupCopy."VAT Bus. Posting Group", VATPostingSetupCopy."VAT Prod. Posting Group"));
    end;

    [Test]
    procedure CannotSetDiffNonDedVATPercentInPurchaseLineWithSameVATIdentifiers()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 475903] Stan cannot set different Non-Deductible VAT percents for the same VAT identifiers in purchase line

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Identifier" = "X", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with two lines, each with VAT Posting Setup with Non-Deductible VAT
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));

        // [WHEN] Change "Non-Deductible VAT %" to 15 in the second purchase line
        asserterror PurchaseLine.Validate("Non-Deductible VAT %", VATPostingSetup."Non-Deductible VAT %" + 1);
        // [THEN] An error message thrown that it is not possible to set different Non-Deductible VAT percents for the same VAT identifiers
        Assert.ExpectedError(StrSubstNo(DifferentNonDedVATRatesSameVATIdentifierErr, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
    end;

    [Test]
    procedure ChangingDirectUnitCostToZeroChangesNonDeductibleVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 546032] Changeing the direct unit cost to zero also changes the Non-Deductible VAT of the purchase document

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Identifier" = "X", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" is specified
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with Non-Deductible VAT posting setup and a single line with direct unit cost
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));

        // [WHEN] Change "Direct Unit Cost" to 0 in the purchase line
        PurchaseLine.Validate("Direct Unit Cost", 0);
        // [THEN] "Non-Deductible VAT Base" and "Non-Deductible VAT Amount" are 0 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Base", 0);
        PurchaseLine.TestField("Non-Deductible VAT Amount", 0);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible UT");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible UT");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible UT");
    end;
}