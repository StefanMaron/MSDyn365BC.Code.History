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
        isInitialized: Boolean;

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
