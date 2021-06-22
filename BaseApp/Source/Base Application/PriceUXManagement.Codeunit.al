codeunit 7018 "Price UX Management"
{
    var
        MissingAlternateImplementationErr: Label 'You cannot setup exceptions because there is no alternate implementation.';
        EmptyPriceSourceErr: Label 'Price source information is missing.';

    procedure GetFirstSourceFromFilter(var PriceListHeader: Record "Price List Header"; var PriceSource: Record "Price Source"; DefaultSourceType: Enum "Price Source Type")
    var
        SourceType: Enum "Price Source Type";
    begin
        PriceSource.InitSource();
        PriceListHeader.FilterGroup(2);
        if PriceListHeader.GetFilter("Source Type") = '' then
            PriceSource.Validate("Source Type", DefaultSourceType)
        else begin
            Evaluate(SourceType, GetFirstFilterValue(PriceListHeader.GetFilter("Source Type")));
            PriceSource.Validate("Source Type", SourceType);
            PriceSource.Validate(
                "Parent Source No.", GetFirstFilterValue(PriceListHeader.GetFilter("Parent Source No.")));
            PriceSource.Validate(
                "Source No.", GetFirstFilterValue(PriceListHeader.GetFilter("Source No.")));
            if PriceSource."Source Group" = PriceSource."Source Group"::All then
                PriceSource."Source Group" := PriceListHeader."Source Group";
        end;
        Evaluate(PriceSource."Price Type", PriceListHeader.GetFilter("Price Type"));
        PriceListHeader.FilterGroup(0);
    end;

    procedure IsAmountTypeFiltered(var PriceListHeader: Record "Price List Header") AmountTypeIsFiltered: Boolean;
    var
        Dummy: Enum "Price Amount Type";
    begin
        exit(IsAmountTypeFiltered(PriceListHeader, Dummy))
    end;

    procedure IsAmountTypeFiltered(var PriceListHeader: Record "Price List Header"; var FirstFilterValue: Enum "Price Amount Type") AmountTypeIsFiltered: Boolean;
    var
        AmountTypeFilterText: Text;
    begin
        PriceListHeader.FilterGroup(2);
        AmountTypeFilterText := PriceListHeader.GetFilter("Amount Type");
        PriceListHeader.FilterGroup(0);

        if AmountTypeFilterText <> '' then
            AmountTypeIsFiltered := Evaluate(FirstFilterValue, GetFirstFilterValue(AmountTypeFilterText));
        if not AmountTypeIsFiltered then
            FirstFilterValue := FirstFilterValue::Any;
    end;

    local procedure GetFirstFilterValue(FilterValue: Text) FirstValue: Text;
    var
        Pos: Integer;
    begin
        if FilterValue = '' then
            exit('');
        Pos := StrPos(FilterValue, '|');
        if Pos = 0 then
            FirstValue := FilterValue
        else
            FirstValue := CopyStr(FilterValue, 1, Pos - 1);
    end;

    procedure GetSupportedMethods(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary; var ImplementationsPerMethod: Dictionary of [Integer, Integer])
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        Implementations: List of [Integer];
        CurrMethod: Enum "Price Calculation Method";
    begin
        PriceCalculationSetup.SetCurrentKey(Method);
        if PriceCalculationSetup.FindSet() then begin
            repeat
                if CurrMethod <> PriceCalculationSetup.Method then begin
                    if CurrMethod.AsInteger() <> 0 then begin
                        ImplementationsPerMethod.Add(CurrMethod.AsInteger(), Implementations.Count());
                        Clear(Implementations);
                    end;

                    CurrMethod := PriceCalculationSetup.Method;
                    TempPriceCalculationSetup.Validate(Method, CurrMethod);
                    TempPriceCalculationSetup.Insert(true);
                end;
                if not Implementations.Contains(PriceCalculationSetup.Implementation.AsInteger()) then
                    Implementations.Add(PriceCalculationSetup.Implementation.AsInteger());
            until PriceCalculationSetup.Next() = 0;

            ImplementationsPerMethod.Add(CurrMethod.AsInteger(), Implementations.Count());
            if TempPriceCalculationSetup.FindFirst() then;
        end;
    end;

    procedure PickImplementation(var CurrPriceCalculationSetup: Record "Price Calculation Setup")
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        TempPriceCalculationSetup: Record "Price Calculation Setup" temporary;
        PriceCalcImplementations: Page "Price Calc. Implementations";
    begin
        CollectAvailableImplementations(CurrPriceCalculationSetup, TempPriceCalculationSetup);

        PriceCalcImplementations.SetData(TempPriceCalculationSetup);
        PriceCalcImplementations.LookupMode := true;
        if PriceCalcImplementations.RunModal() = Action::LookupOK then begin
            PriceCalcImplementations.GetRecord(TempPriceCalculationSetup);

            if CurrPriceCalculationSetup.Code <> TempPriceCalculationSetup.Code then begin
                PriceCalculationSetup.Get(TempPriceCalculationSetup.Code);
                PriceCalculationSetup.Validate(Default, true);
                PriceCalculationSetup.Modify();

                CurrPriceCalculationSetup.Delete();
                CurrPriceCalculationSetup := PriceCalculationSetup;
                CurrPriceCalculationSetup.Insert();
            end;
        end;
    end;

    local procedure CollectAvailableImplementations(CurrPriceCalculationSetup: Record "Price Calculation Setup"; var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        DefaultCode: Code[100];
    begin
        PriceCalculationSetup.SetRange("Group Id", CurrPriceCalculationSetup."Group Id");
        PriceCalculationSetup.SetRange(Enabled, true);
        if PriceCalculationSetup.FindSet() then begin
            repeat
                TempPriceCalculationSetup := PriceCalculationSetup;
                TempPriceCalculationSetup.Insert();
                if PriceCalculationSetup.Default then
                    DefaultCode := PriceCalculationSetup.Code;
            until PriceCalculationSetup.Next() = 0;

            if DefaultCode <> '' then
                TempPriceCalculationSetup.Get(DefaultCode)
            else
                TempPriceCalculationSetup.FindFirst();
        end;
    end;

    local procedure LookupJobPriceLists(var PriceListHeader: Record "Price List Header"; var PriceListCode: Code[20]) IsPicked: Boolean;
    var
        PurchaseJobPriceLists: Page "Purchase Job Price Lists";
        SalesJobPriceLists: Page "Sales Job Price Lists";
    begin
        PriceListCode := '';
        case PriceListHeader."Price Type" of
            "Price Type"::Sale:
                begin
                    SalesJobPriceLists.LookupMode(true);
                    SalesJobPriceLists.SetRecordFilter(PriceListHeader);
                    if SalesJobPriceLists.RunModal() = Action::LookupOK then
                        SalesJobPriceLists.GetRecord(PriceListHeader);
                end;
            "Price Type"::Purchase:
                begin
                    PurchaseJobPriceLists.LookupMode(true);
                    PurchaseJobPriceLists.SetRecordFilter(PriceListHeader);
                    if PurchaseJobPriceLists.RunModal() = Action::LookupOK then
                        PurchaseJobPriceLists.GetRecord(PriceListHeader);
                end;
        end;
        PriceListCode := PriceListHeader.Code;
        IsPicked := PriceListCode <> '';
    end;

    local procedure LookupPriceLists(var PriceListHeader: Record "Price List Header"; var PriceListCode: Code[20]) IsPicked: Boolean;
    var
        PurchasePriceLists: Page "Purchase Price Lists";
        SalesPriceLists: Page "Sales Price Lists";
    begin
        PriceListCode := '';
        case PriceListHeader."Price Type" of
            "Price Type"::Sale:
                begin
                    SalesPriceLists.LookupMode(true);
                    SalesPriceLists.SetRecordFilter(PriceListHeader);
                    if SalesPriceLists.RunModal() = Action::LookupOK then
                        SalesPriceLists.GetRecord(PriceListHeader);
                end;
            "Price Type"::Purchase:
                begin
                    PurchasePriceLists.LookupMode(true);
                    PurchasePriceLists.SetRecordFilter(PriceListHeader);
                    if PurchasePriceLists.RunModal() = Action::LookupOK then
                        PurchasePriceLists.GetRecord(PriceListHeader);
                end;
        end;
        PriceListCode := PriceListHeader.Code;
        IsPicked := PriceListCode <> '';
    end;

    procedure LookupPriceLists(SourceGroup: Enum "Price Source Group"; PriceType: Enum "Price Type"; var PriceListCode: Code[20]): Boolean;
    var
        PriceListHeader: Record "Price List Header";
    begin
        if PriceListCode <> '' then begin
            PriceListHeader.Get(PriceListCode);
            PriceListHeader.SetFilter(Code, '<>%1', PriceListCode);
        end else begin
            PriceListHeader."Source Group" := SourceGroup;
            PriceListHeader."Price Type" := PriceType;
        end;
        case SourceGroup of
            SourceGroup::Job:
                exit(LookupJobPriceLists(PriceListHeader, PriceListCode));
            SourceGroup::Customer,
            SourceGroup::Vendor:
                exit(LookupPriceLists(PriceListHeader, PriceListCode));
        end;
    end;

    procedure ShowExceptions(CurrPriceCalculationSetup: Record "Price Calculation Setup")
    var
        DtldPriceCalculationSetup: Page "Dtld. Price Calculation Setup";
    begin
        DtldPriceCalculationSetup.Set(CurrPriceCalculationSetup);
        DtldPriceCalculationSetup.RunModal();
    end;

    procedure ShowPriceLists(Campaign: Record Campaign; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Campaign, PriceType, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Campaign, PriceType, PriceSourceList);
        ShowPriceLists(PriceSourceList, AmountType);
    end;

    procedure ShowPriceLists(Contact: Record Contact; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Contact, PriceType, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Contact, PriceType, PriceSourceList);
        ShowPriceLists(PriceSourceList, AmountType);
    end;

    procedure ShowPriceLists(Customer: Record Customer; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Customer, "Price Type"::Sale, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Customer, PriceSourceList);
        ShowPriceLists(PriceSourceList, AmountType);
    end;

    procedure ShowPriceLists(CustomerDiscountGroup: Record "Customer Discount Group")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(CustomerDiscountGroup, "Price Type"::Sale, "Price Amount Type"::Discount, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(CustomerDiscountGroup, PriceSourceList);
        ShowPriceLists(PriceSourceList, "Price Amount Type"::Discount);
    end;

    procedure ShowPriceLists(CustomerPriceGroup: Record "Customer Price Group")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(CustomerPriceGroup, "Price Type"::Sale, "Price Amount Type"::Price, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(CustomerPriceGroup, PriceSourceList);
        ShowPriceLists(PriceSourceList, "Price Amount Type"::Price);
    end;

    procedure ShowPriceLists(Vendor: Record Vendor; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Vendor, "Price Type"::Purchase, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Vendor, PriceSourceList);
        ShowPriceLists(PriceSourceList, AmountType);
    end;

    procedure ShowPriceLists(Job: Record Job; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Job, PriceType, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Job, PriceType, PriceSourceList);
        ShowJobPriceLists(PriceSourceList, AmountType);
    end;

    local procedure ShowJobPriceLists(PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    var
        PurchaseJobPriceLists: Page "Purchase Job Price Lists";
        SalesJobPriceLists: Page "Sales Job Price Lists";
        PriceType: Enum "Price Type";
    begin
        PriceType := PriceSourceList.GetPriceType();
        case PriceType of
            PriceType::Sale:
                begin
                    SalesJobPriceLists.SetSource(PriceSourceList, AmountType);
                    SalesJobPriceLists.Run();
                end;
            PriceType::Purchase:
                begin
                    PurchaseJobPriceLists.SetSource(PriceSourceList, AmountType);
                    PurchaseJobPriceLists.Run();
                end;
        end
    end;

    procedure ShowPriceListLines(PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        DummyPriceSource: Record "Price Source";
        PriceAssetList: Codeunit "Price Asset List";
        PriceListLineReview: Page "Price List Line Review";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceListLines(DummyPriceSource, PriceAsset, PriceType, AmountType, IsHandled);
        if IsHandled then
            exit;
        PriceAssetList.Init();
        PriceAssetList.Add(PriceAsset);
        PriceListLineReview.Set(PriceAssetList, PriceType, AmountType);
        PriceListLineReview.Run();
    end;

    procedure ShowPriceListLines(PriceSource: Record "Price Source"; PriceAsset: Record "Price Asset"; AmountType: Enum "Price Amount Type")
    var
        PriceAssetList: Codeunit "Price Asset List";
        PriceListLineReview: Page "Price List Line Review";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceListLines(PriceSource, PriceAsset, PriceSource."Price Type", AmountType, IsHandled);
        if IsHandled then
            exit;
        PriceAssetList.Init();
        PriceAssetList.Add(PriceAsset);
        PriceListLineReview.Set(PriceSource, PriceAssetList, AmountType);
        PriceListLineReview.Run();
    end;

    procedure ShowPriceLists(PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    var
        PurchasePriceLists: Page "Purchase Price Lists";
        SalesPriceLists: Page "Sales Price Lists";
        PriceType: Enum "Price Type";
    begin
        PriceType := PriceSourceList.GetPriceType();
        case PriceType of
            PriceType::Sale:
                begin
                    SalesPriceLists.SetSource(PriceSourceList, AmountType);
                    SalesPriceLists.Run();
                end;
            PriceType::Purchase:
                begin
                    PurchasePriceLists.SetSource(PriceSourceList, AmountType);
                    PurchasePriceLists.Run();
                end;
        end;
    end;

    local procedure GetPriceSource(Campaign: Record Campaign; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Campaign, Campaign."No.");
        PriceSourceList.SetPriceType(PriceType);
    end;

    local procedure GetPriceSource(Contact: Record Contact; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Contact, Contact."No.");
        PriceSourceList.SetPriceType(PriceType);
    end;

    local procedure GetPriceSource(Customer: Record Customer; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Customer, Customer."No.");
        PriceSourceList.Add(PriceSourceType::"All Customers");
        if Customer."Customer Price Group" <> '' then
            PriceSourceList.Add(PriceSourceType::"Customer Price Group", Customer."Customer Price Group");
        if Customer."Customer Disc. Group" <> '' then
            PriceSourceList.Add(PriceSourceType::"Customer Disc. Group", Customer."Customer Disc. Group");
    end;

    local procedure GetPriceSource(CustomerPriceGroup: Record "Customer Price Group"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::"Customer Price Group", CustomerPriceGroup.Code);
    end;

    local procedure GetPriceSource(CustomerDiscountGroup: Record "Customer Discount Group"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::"Customer Disc. Group", CustomerDiscountGroup.Code);
    end;

    local procedure GetPriceSource(Vendor: Record Vendor; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Vendor, Vendor."No.");
        PriceSourceList.Add(PriceSourceType::"All Vendors");
    end;

    local procedure GetPriceSource(Job: Record Job; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Job, Job."No.");
        PriceSourceList.Add(PriceSourceType::"All Jobs");
        PriceSourceList.SetPriceType(PriceType);
    end;

    procedure SetPriceListsFilters(var PriceListHeader: Record "Price List Header"; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    begin
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Price Type", PriceType);
        if AmountType <> AmountType::Any then
            PriceListHeader.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);
        PriceListHeader.FilterGroup(0);
    end;

    procedure SetPriceListsFilters(var PriceListHeader: Record "Price List Header"; PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListHeader.FilterGroup(2);
        if AmountType <> AmountType::Any then
            PriceListHeader.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);
        SetSourceFilters(PriceSourceList, PriceListHeader);
        PriceListHeader.FilterGroup(0);
    end;

    procedure SetPriceListLineFilters(var PriceListLine: Record "Price List Line"; PriceAssetList: Codeunit "Price Asset List"; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceSource: Record "Price Source";
    begin
        PriceSource."Price Type" := PriceType;
        SetPriceListLineFilters(PriceListLine, PriceSource, PriceAssetList, AmountType);
    end;

    procedure SetPriceListLineFilters(var PriceListLine: Record "Price List Line"; PriceSource: Record "Price Source"; PriceAssetList: Codeunit "Price Asset List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListLine.FilterGroup(2);
        PriceListLine.SetRange("Price Type", PriceSource."Price Type");
        if AmountType = AmountType::Any then
            PriceListLine.SetRange("Amount Type")
        else
            PriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);

        if PriceSource."Source Type" <> PriceSource."Source Type"::All then begin
            PriceListLine.SetRange("Source Type", PriceSource."Source Type");
            PriceListLine.SetRange("Source No.", PriceSource."Source No.");
        end;
        BuildAssetFilters(PriceListLine, PriceAssetList);
        PriceListLine.MarkedOnly(true);
        PriceListLine.FilterGroup(0);
    end;

    local procedure BuildAssetFilters(var PriceListLine: Record "Price List Line"; PriceAssetList: Codeunit "Price Asset List")
    var
        PriceAsset: Record "Price Asset";
    begin
        if PriceAssetList.First(PriceAsset, 0) then
            repeat
                PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
                PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.");
                if PriceAsset."Variant Code" <> '' then
                    PriceListLine.SetRange("Variant Code", PriceAsset."Variant Code")
                else
                    PriceListLine.SetRange("Variant Code");
                if PriceListLine.FindSet() then
                    repeat
                        PriceListLine.Mark(true);
                    until PriceListLine.Next() = 0;
            until not PriceAssetList.Next(PriceAsset);

        PriceListLine.SetRange("Asset Type");
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange("Variant Code");
    end;

    local procedure SetSourceFilters(PriceSourceList: Codeunit "Price Source List"; var PriceListHeader: Record "Price List Header")
    var
        PriceSource: Record "Price Source";
        SourceFilter: array[3] of Text;
    begin
        PriceSourceList.GetList(PriceSource);
        if not PriceSource.FindSet() then
            Error(EmptyPriceSourceErr);

        PriceListHeader.SetRange("Price Type", PriceSource."Price Type");
        PriceListHeader.SetRange("Source Group", PriceSource."Source Group");

        BuildSourceFilters(PriceSource, SourceFilter);
        if SourceFilter[3] <> '' then
            PriceListHeader.SetFilter("Filter Source No.", SourceFilter[3])
        else begin
            PriceListHeader.SetFilter("Source Type", SourceFilter[1]);
            PriceListHeader.SetFilter("Source No.", SourceFilter[2]);
        end;
    end;

    local procedure BuildSourceFilters(var PriceSource: Record "Price Source"; var SourceFilter: array[3] of Text)
    var
        OrSeparator: Text[1];
    begin
        repeat
            if PriceSource."Source Group" = PriceSource."Source Group"::Job then
                SourceFilter[3] += OrSeparator + GetFilterText(PriceSource."Filter Source No.")
            else begin
                SourceFilter[1] += OrSeparator + Format(PriceSource."Source Type");
                SourceFilter[2] += OrSeparator + GetFilterText(PriceSource."Source No.");
            end;
            OrSeparator := '|';
        until PriceSource.Next() = 0;
    end;

    local procedure GetFilterText(SourceNo: Code[20]): Text;
    begin
        if SourceNo = '' then
            exit('''''');
        exit(SourceNo);
    end;

    procedure GetFirstAlternateSetupCode(CurrPriceCalculationSetup: Record "Price Calculation Setup"): Code[100];
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if CurrPriceCalculationSetup."Group Id" = '' then
            exit('');
        PriceCalculationSetup.SetRange("Group Id", CurrPriceCalculationSetup."Group Id");
        PriceCalculationSetup.SetRange(Default, false);
        if PriceCalculationSetup.FindFirst() then
            exit(PriceCalculationSetup.Code)
    end;

    procedure PickAlternateImplementation(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup");
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange("Group Id", DtldPriceCalculationSetup."Group Id");
        PriceCalculationSetup.SetRange(Default, false);
        if Page.RunModal(Page::"Price Calc. Implementations", PriceCalculationSetup) = ACTION::LookupOK then
            DtldPriceCalculationSetup.Validate(Implementation, PriceCalculationSetup.Implementation);
    end;

    procedure TestAlternateImplementation(CurrPriceCalculationSetup: Record "Price Calculation Setup")
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange("Group Id", CurrPriceCalculationSetup."Group Id");
        PriceCalculationSetup.SetRange(Default, false);
        if PriceCalculationSetup.IsEmpty() then
            Error(MissingAlternateImplementationErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPriceLists(FromRecord: Variant; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPriceListLines(PriceSource: Record "Price Source"; PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean)
    begin
    end;
}
