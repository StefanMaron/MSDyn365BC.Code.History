codeunit 130510 "Library - Price Calculation"
{
    // Contains all utility functions related to price calculation.
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LastHandlerId: Integer;

    procedure AddSetup(var PriceCalculationSetup: Record "Price Calculation Setup"; NewMethod: Enum "Price Calculation Method"; PriceType: Enum "Price Type"; AssetType: Enum "Price Asset Type"; NewImplementation: Integer; NewDefault: Boolean): Code[100];
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

    procedure EnableExtendedPriceCalculation()
    begin
        // turn on ExtendedPriceCalculationEnabledHandler
        BindSubscription(LibraryPriceCalculation);
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

    procedure SetupDefaultHandler(NewImplementation: Integer) xImplementation: Enum "Price Calculation Handler";
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Mgt.", 'OnIsExtendedPriceCalculationEnabled', '', false, false)]
    procedure ExtendedPriceCalculationEnabledHandler(var Result: Boolean);
    begin
        Result := true;
    end;
}