codeunit 130510 "Library - Price Calculation"
{
    // Contains all utility functions related to price calculation.
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LastHandlerId: Enum "Price Calculation Handler";

    procedure AddSetup(var PriceCalculationSetup: Record "Price Calculation Setup"; NewMethod: Enum "Price Calculation Method"; PriceType: Enum "Price Type"; AssetType: Enum "Price Asset Type"; NewImplementation: Enum "Price Calculation Handler"; NewDefault: Boolean): Code[100];
    begin
        with PriceCalculationSetup do begin
            Init();
            Method := NewMethod;
            Type := PriceType;
            "Asset Type" := AssetType;
            Implementation := NewImplementation;
            Default := NewDefault;
            Enabled := true;
            Insert(true);
            exit(Code)
        end;
    end;

    procedure AddDtldSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"; PriceType: Enum "Price Type"; AssetType: Enum "Price Asset Type"; AssetNo: code[20]; SourceGroup: Enum "Price Source Group"; SourceNo: Code[20])
    begin
        with DtldPriceCalculationSetup do begin
            if IsTemporary then
                "Line No." += 1
            else
                "Line No." := 0;
            Type := PriceType;
            "Asset Type" := AssetType;
            "Asset No." := AssetNo;
            Validate("Source Group", SourceGroup);
            "Source No." := SourceNo;
            Enabled := true;
            Insert(true);
        end;
    end;

    procedure AddDtldSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"; SetupCode: Code[100]; AssetNo: code[20]; SourceGroup: Enum "Price Source Group"; SourceNo: Code[20])
    begin
        with DtldPriceCalculationSetup do begin
            if IsTemporary then
                "Line No." += 1
            else
                "Line No." := 0;
            Validate("Setup Code", SetupCode);
            "Asset No." := AssetNo;
            Validate("Source Group", SourceGroup);
            "Source No." := SourceNo;
            Enabled := true;
            Insert(true);
        end;
    end;

    procedure DisableSetup(var PriceCalculationSetup: Record "Price Calculation Setup")
    begin
        PriceCalculationSetup.Enabled := false;
        PriceCalculationSetup.Modify();
    end;

    procedure DisableDtldSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup")
    begin
        DtldPriceCalculationSetup.Enabled := false;
        DtldPriceCalculationSetup.Modify();
    end;

    procedure DisableExtendedPriceCalculation()
    begin
        // turn off ExtendedPriceCalculationEnabledHandler
        UnbindSubscription(LibraryPriceCalculation);
    end;

    procedure EnableExtendedPriceCalculation()
    begin
        // turn on ExtendedPriceCalculationEnabledHandler
        UnbindSubscription(LibraryPriceCalculation);
        BindSubscription(LibraryPriceCalculation);
    end;

    procedure EnableExtendedPriceCalculation(Enable: Boolean)
    begin
        // turn on/off ExtendedPriceCalculationEnabledHandler
        UnbindSubscription(LibraryPriceCalculation);
        if Enable then
            BindSubscription(LibraryPriceCalculation);
    end;

    procedure SetupDefaultHandler(NewImplementation: Enum "Price Calculation Handler") xImplementation: Enum "Price Calculation Handler";
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if LastHandlerId = NewImplementation then
            exit;
        PriceCalculationSetup.SetRange(Default, true);
        if PriceCalculationSetup.FindFirst() then
            xImplementation := PriceCalculationSetup.Implementation
        else
            xImplementation := NewImplementation;

        PriceCalculationSetup.Reset();
        PriceCalculationSetup.DeleteAll();
        PriceCalculationMgt.Run();
        PriceCalculationSetup.Modifyall(Default, false);

        PriceCalculationSetup.SetRange(Implementation, NewImplementation);
        PriceCalculationSetup.Modifyall(Default, true, true);

        LastHandlerId := NewImplementation;
    end;

    procedure AllowEditingActiveSalesPrice()
    begin
        AllowEditingActiveSalesPrice(true);
    end;

    local procedure AllowEditingActiveSalesPrice(AllowEditingActivePrice: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Editing Active Price" := AllowEditingActivePrice;
        SalesReceivablesSetup.Modify();
    end;

    procedure AllowEditingActivePurchPrice()
    begin
        AllowEditingActivePurchPrice(true);
    end;

    local procedure AllowEditingActivePurchPrice(AllowEditingActivePrice: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Editing Active Price" := AllowEditingActivePrice;
        PurchasesPayablesSetup.Modify();
    end;

    procedure DisallowEditingActiveSalesPrice()
    begin
        AllowEditingActiveSalesPrice(false);
    end;

    procedure DisallowEditingActivePurchPrice()
    begin
        AllowEditingActivePurchPrice(false);
    end;

    procedure SetDefaultPriceList(PriceType: Enum "Price Type"; SourceGroup: Enum "Price Source Group"): Code[20];
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        exit(FeaturePriceCalculation.DefineDefaultPriceList(PriceType, SourceGroup));
    end;

    procedure ClearDefaultPriceList(PriceType: Enum "Price Type"; SourceGroup: Enum "Price Source Group")
    var
        JobsSetup: Record "Jobs Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case SourceGroup of
            SourceGroup::Job:
                begin
                    JobsSetup.Get();
                    case PriceType of
                        PriceType::Purchase:
                            JobsSetup."Default Purch Price List Code" := '';
                        PriceType::Sale:
                            JobsSetup."Default Sales Price List Code" := '';
                    end;
                    JobsSetup.Modify();
                end;
            SourceGroup::Vendor:
                begin
                    PurchasesPayablesSetup.Get();
                    PurchasesPayablesSetup."Default Price List Code" := '';
                    PurchasesPayablesSetup.Modify();
                end;
            SourceGroup::Customer:
                begin
                    SalesReceivablesSetup.Get();
                    SalesReceivablesSetup."Default Price List Code" := '';
                    SalesReceivablesSetup.Modify();
                end;
        end;
    end;

    procedure SetMethodInSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Price Calculation Method" := SalesReceivablesSetup."Price Calculation Method"::"Lowest Price";
        SalesReceivablesSetup.Modify();
    end;

    procedure SetMethodInPurchSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Price Calculation Method" := PurchasesPayablesSetup."Price Calculation Method"::"Lowest Price";
        PurchasesPayablesSetup.Modify();
    end;

    procedure CreatePriceHeader(var PriceListHeader: Record "Price List Header"; PriceType: Enum "Price Type"; SourceType: Enum "Price Source Type"; SourceNo: code[20])
    begin
        PriceListHeader.Init();
        PriceListHeader.Code := LibraryUtility.GenerateGUID();
        PriceListHeader."Price Type" := PriceType;
        PriceListHeader.Validate("Source Type", SourceType);
        PriceListHeader.Validate("Source No.", SourceNo);
        PriceListHeader.Insert(true);
    end;

    procedure CreatePriceHeader(var PriceListHeader: Record "Price List Header"; PriceType: Enum "Price Type"; SourceType: Enum "Price Source Type"; ParentSourceNo: code[20]; SourceNo: code[20])
    begin
        PriceListHeader.Init();
        PriceListHeader.Code := LibraryUtility.GenerateGUID();
        PriceListHeader."Price Type" := PriceType;
        PriceListHeader.Validate("Source Type", SourceType);
        PriceListHeader.Validate("Parent Source No.", ParentSourceNo);
        PriceListHeader.Validate("Source No.", SourceNo);
        PriceListHeader.Insert(true);
    end;

    procedure CreatePriceListLine(var PriceListLine: Record "Price List Line"; PriceListHeader: Record "Price List Header"; AmountType: Enum "Price Amount Type"; AssetType: enum "Price Asset Type"; AssetNo: Code[20])
    begin
        CreatePriceListLine(
            PriceListLine,
            PriceListHeader.Code, PriceListHeader."Price Type",
            PriceListHeader."Source Type", PriceListHeader."Parent Source No.", PriceListHeader."Source No.",
            AmountType, AssetType, AssetNo);
    end;

    procedure CreatePriceListLine(var PriceListLine: Record "Price List Line"; PriceListCode: Code[20]; PriceType: Enum "Price Type"; SourceType: Enum "Price Source Type"; SourceNo: Code[20]; AmountType: Enum "Price Amount Type"; AssetType: enum "Price Asset Type"; AssetNo: Code[20])
    begin
        // to skip blank "Parent Source No."
        CreatePriceListLine(
            PriceListLine, PriceListCode, PriceType, SourceType, '', SourceNo, AmountType, AssetType, AssetNo);
    end;

    procedure CreatePriceListLine(var PriceListLine: Record "Price List Line"; PriceListCode: Code[20]; PriceType: Enum "Price Type"; SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; SourceNo: Code[20]; AmountType: Enum "Price Amount Type"; AssetType: enum "Price Asset Type"; AssetNo: Code[20])
    begin
        PriceListLine.Init();
        PriceListLine."Line No." := 0;
        PriceListLine."Price List Code" := PriceListCode;
        PriceListLine."Price Type" := PriceType;
        PriceListLine.Validate("Source Type", SourceType);
        PriceListLine.Validate("Parent Source No.", ParentSourceNo);
        PriceListLine.Validate("Source No.", SourceNo);
        PriceListLine.Validate("Asset Type", AssetType);
        PriceListLine.Validate("Asset No.", AssetNo);
        PriceListLine.Validate("Amount Type", AmountType);
        if AmountType in [AmountType::Discount, AmountType::Any] then
            PriceListLine.Validate("Line Discount %", LibraryRandom.RandDec(100, 2));
        if AmountType in [AmountType::Price, AmountType::Any] then
            case PriceType of
                PriceType::Sale:
                    PriceListLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
                PriceType::Purchase:
                    PriceListLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
            end;
        PriceListLine.Insert(true);
    end;

    procedure CreatePurchDiscountLine(var PriceListLine: Record "Price List Line"; PriceListCode: Code[20]; SourceType: Enum "Price Source Type"; SourceNo: code[20];
                                                                                                                            AssetType: enum "Price Asset Type";
                                                                                                                            AssetNo: Code[20])
    begin
        CreatePriceListLine(
            PriceListLine, PriceListCode, PriceListLine."Price Type"::Purchase, SourceType, SourceNo,
            PriceListLine."Amount Type"::Discount, AssetType, AssetNo);
    end;

    procedure CreatePurchPriceLine(var PriceListLine: Record "Price List Line"; PriceListCode: Code[20]; SourceType: Enum "Price Source Type"; SourceNo: code[20];
                                                                                                                         AssetType: enum "Price Asset Type";
                                                                                                                         AssetNo: Code[20])
    begin
        CreatePriceListLine(
            PriceListLine, PriceListCode, PriceListLine."Price Type"::Purchase, SourceType, SourceNo,
            PriceListLine."Amount Type"::Price, AssetType, AssetNo);
    end;

    procedure CreateSalesDiscountLine(var PriceListLine: Record "Price List Line"; PriceListCode: Code[20]; SourceType: Enum "Price Source Type"; SourceNo: code[20];
                                                                                                                            AssetType: enum "Price Asset Type";
                                                                                                                            AssetNo: Code[20])
    begin
        CreatePriceListLine(
            PriceListLine, PriceListCode, PriceListLine."Price Type"::Sale, SourceType, SourceNo,
            PriceListLine."Amount Type"::Discount, AssetType, AssetNo);
    end;

    procedure CreateSalesPriceLine(var PriceListLine: Record "Price List Line"; PriceListCode: Code[20]; SourceType: Enum "Price Source Type"; SourceNo: code[20];
                                                                                                                         AssetType: enum "Price Asset Type";
                                                                                                                         AssetNo: Code[20])
    begin
        CreatePriceListLine(
            PriceListLine, PriceListCode, PriceListLine."Price Type"::Sale, SourceType, SourceNo,
            PriceListLine."Amount Type"::Price, AssetType, AssetNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Mgt.", 'OnIsExtendedPriceCalculationEnabled', '', false, false)]
    procedure ExtendedPriceCalculationEnabledHandler(var Result: Boolean);
    begin
        Result := true;
    end;
}
