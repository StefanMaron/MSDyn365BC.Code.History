codeunit 18787 "TDS On Purchase Tests"
{
    subtype = test;
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353920- Check if the program is allowing the posting of Invoice with Item using the Purchase Order/Invoice with TDS information where T.A.N No. has not been defined.
    procedure PostFromPurchaseInvoicewithItemWithoutTANNo()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Assert: Codeunit Assert;
        LibraryTDS: Codeunit "Library-TDS";
        TANNoErr: Label 'T.A.N. No. must have a value in Company Information', locked = true;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Validated T.A.N. No. Verified
        LibraryTDS.RemoveTANOnCompInfo();

        //[THEN] Assert Error Verified
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
             PurchaseHeader."Document Type"::Invoice,
             Vendor."No.",
             WorkDate(),
             PurchaseLine.Type::Item, false);

        Assert.ExpectedError(TANNoErr);
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    //Scenario 353919- Check if the program is allowing the posting of Invoice with Item using the Purchase Order/Invoice with TDS information where Accounting Period has not been specified.
    procedure PostFromPurchaseInvoicewithItemWithoutAccountingPeriod()
    var
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Assert: Codeunit Assert;
        LibraryTDS: Codeunit "Library-TDS";
        IncomeTaxAccountingErr: Label 'The Posting Date doesn''t lie in Tax Accounting Period', Locked = true;
    begin
        //[GIVEN] Created Setup for AssesseeCode,TDSPostingSetup,TDSSection,ConcessionalCode with Threshold and Surcharge Overlook
        LibraryTDS.CreateTDSSetup(Vendor, TDSPostingSetup, ConcessionalCode);
        LibraryTDS.UpdateVendorWithPANWithOutConcessional(Vendor, true, true);
        CreateTaxRateSetup(TDSPostingSetup."TDS Section", Vendor."Assessee Code", '', WorkDate());

        //[WHEN] Created and Posted Purchase Invoice with Item without Accounting Period
        asserterror CreateAndPostPurchaseDocument(PurchaseHeader,
             PurchaseHeader."Document Type"::Invoice,
             Vendor."No.",
             CalcDate('<-1Y>', LibraryTDS.FindStartDateOnAccountingPeriod()),
             PurchaseLine.Type::Item,
             false);

        //[WHEN] Expected Error Verified
        Assert.ExpectedError(IncomeTaxAccountingErr);
    end;

    procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header";
             DocumentType: enum "Purchase Document Type";
             VendorNo: Code[20];
             PostingDate: Date;
             LineType: enum "Purchase Line Type"; LineDiscount: Boolean): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineType, LineDiscount);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, TRUE, true))
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line";
    Type: enum "Purchase Line Type"; LineDiscount: Boolean)
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        TDSSectionCode: Code[10];
    begin
        InsertPurchaseLine(PurchaseLine, PurchaseHeader, Type);
        if LineDiscount then
            PurchaseLine.VALIDATE("Line Discount %", LibraryRandom.RandDecInRange(10, 20, 2));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(1000, 1001, 0));
        PurchaseLine.MODIFY(TRUE);
    end;

    local procedure InsertPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: record "Purchase Header"; LineType: enum "Purchase Line Type")
    var
        LibraryUtility: Codeunit "Library - Utility";
        RecRef: RecordRef;
        TDSSectionCode: Code[10];
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        RecRef.GetTable(PurchaseLine);
        PurchaseLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchaseLine.FieldNo("Line No.")));
        PurchaseLine.Validate(Type, LineType);
        PurchaseLine.Validate("No.", GetLineTypeNo(LineType));
        PurchaseLine.Validate(Quantity, LibraryRandom.RandIntInRange(1, 10));
        TDSSectionCode := CopyStr(Storage.Get('SectionCode'), 1, 10);
        PurchaseLine.Validate("TDS Section Code", TDSSectionCode);
        PurchaseLine.Insert(true);
    end;

    local procedure GetLineTypeNo(Type: enum "Purchase Line Type"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        case Type of
            PurchaseLine.Type::"G/L Account":
                exit(CreateGLAccountWithDirectPostingNoVAT());
            PurchaseLine.Type::Item:
                exit(CreateItemNoWithoutVAT());
            PurchaseLine.Type::"Fixed Asset":
                exit(CreateFixedAsset());
            PurchaseLine.Type::"Charge (Item)":
                exit(CreateChargeItemWithNoVAT());
        end;
    end;

    local procedure CreateItemNoWithoutVAT(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTDS: Codeunit "Library-TDS";
    begin
        LibraryTDS.CreateZeroVATPostingSetup(VATPostingSetup);
        item.GET(LibraryInventory.CreateItemNoWithoutVAT());
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGLAccountWithDirectPostingNoVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryTDS: Codeunit "Library-TDS";
    begin
        LibraryTDS.CreateZeroVATPostingSetup(VATPostingSetup);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateChargeItemWithNoVAT(): Code[20]
    var
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTDS: codeunit "Library-TDS";
    begin
        LibraryTDS.CreateZeroVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemCharge.Modify(true);
        exit(ItemCharge."No.");
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        UpdateFAPostingGroupGLAccounts(FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);
        exit(FixedAsset."No.")
    end;

    procedure UpdateFAPostingGroupGLAccounts(FAPostingGroupCode: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        if FAPostingGroup.Get(FAPostingGroupCode) then begin
            FAPostingGroup.Validate("Acquisition Cost Account", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Acq. Cost Acc. on Disposal", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Accum. Depreciation Account", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Accum. Depr. Acc. on Disposal", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Depreciation Expense Acc.", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Gains Acc. on Disposal", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Losses Acc. on Disposal", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Validate("Sales Bal. Acc.", CreateGLAccountWithDirectPostingNoVAT());
            FAPostingGroup.Modify(true);
        end;
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
        Storage.Set('NonPANTDSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SurchargePercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('eCessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SHECessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('TDSThresholdAmount', Format(LibraryRandom.RandIntInRange(2, 4)));
        Storage.Set('SurchargeThresholdAmount', Format(LibraryRandom.RandIntInRange(2, 4)));
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

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: codeunit "Library - ERM";
        Storage: Dictionary of [Text, Text];
        IsForeignVendor: Boolean;
}