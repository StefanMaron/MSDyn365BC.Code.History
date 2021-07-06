page 7024 "Prices Overview"
{
    Caption = 'Prices Overview';
    DataCaptionExpression = PageCaption;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    RefreshOnActivate = true;
    SourceTable = "Price List Line";
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PriceType; PriceSource."Price Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Type Filter';
                    ToolTip = 'Specifies a filter for which prices to display: sale, purchase or both.';
                    trigger OnValidate()
                    begin
                        PriceSource.Validate("Price Type");
                        SetRecFilters();
                        SetCaption();
                    end;
                }
                group(SourceFilters)
                {
                    ShowCaption = false;
                    field(SourceType; PriceSource."Source Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Applies-to Type Filter';
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnValidate()
                        begin
                            PriceSource.Validate("Source Type");
                            ParentSourceNoFilter := '';
                            SourceNoFilter := '';
                            SetRecFilters();
                            SetCaption();
                        end;
                    }
                    field(ParentSourceNo; ParentSourceNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Applies-to Parent No. Filter';
                        Visible = ParentSourceNoFilterEditable;
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            JobPriceSource: Record "Price Source";
                        begin
                            if not PriceSource.IsParentSourceAllowed() then
                                exit;
                            JobPriceSource."Source Group" := JobPriceSource."Source Group"::Job;
                            JobPriceSource."Source Type" := "Price Source Type"::Job;
                            if JobPriceSource.LookupNo() then begin
                                ParentSourceNoFilter := JobPriceSource."Source No.";
                                SourceNoFilter := '';
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            PriceSource.Validate("Parent Source No.");
                        end;
                    }
                    field(SourceNo; SourceNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Applies-to No. Filter';
                        Enabled = SourceNoFilterEditable;
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PriceSource.LookupNo() then begin
                                Text := PriceSource."Source No.";
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            SetRecFilters();
                            SetCaption();
                        end;
                    }
                }
                group(AssetFilters)
                {
                    ShowCaption = false;
                    field(AssetType; PriceAsset."Asset Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Product Type Filter';
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnValidate()
                        begin
                            PriceAsset.Validate("Asset Type");
                            AssetNoFilter := '';
                            SetRecFilters();
                            SetCaption();
                        end;
                    }
                    field(AssetNo; AssetNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Product No. Filter';
                        Enabled = AssetNoFilterEditable;
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PriceAsset.LookupNo() then begin
                                Text := PriceAsset."Asset No.";
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            SetRecFilters();
                            SetCaption();
                        end;
                    }
                }
                field(AmountType; AmountTypeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Defines Filter';
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';

                    trigger OnValidate()
                    begin
                        SetRecFilters();
                        SetCaption();
                    end;
                }
                group(DateFilters)
                {
                    ShowCaption = false;
                    field(StartingDateFilter; StartingDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date Filter';
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnValidate()
                        var
                            FilterTokens: Codeunit "Filter Tokens";
                        begin
                            FilterTokens.MakeDateFilter(StartingDateFilter);
                            SetRecFilters();
                        end;
                    }
                    field(EndingDateFilter; EndingDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date Filter';
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnValidate()
                        var
                            FilterTokens: Codeunit "Filter Tokens";
                        begin
                            FilterTokens.MakeDateFilter(EndingDateFilter);
                            SetRecFilters();
                        end;
                    }
                }
                field(CurrencyCodeFilterCtrl; CurrencyCodeFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code Filter';
                    ToolTip = 'Specifies a filter for which prices to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CurrencyList: Page Currencies;
                    begin
                        CurrencyList.LookupMode := true;
                        if CurrencyList.RunModal() = ACTION::LookupOK then
                            Text := CurrencyList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        SetRecFilters();
                    end;
                }
            }
            repeater(Lines)
            {
                ShowCaption = false;
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies the unique identifier of the price list.';

                    trigger OnDrillDown()
                    begin
                        PriceUXManagement.EditPriceList(Rec."Price List Code");
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies whether the price list line is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                }
                field("Price Type"; Rec."Price Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceTypeVisible;
                    Editable = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the price type: sale or purchase price.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and SourceTypeEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the customer or customer price group.';

                    trigger OnValidate()
                    begin
                        CalcSourceNoEditable()
                    end;
                }
                field("Parent Source No."; Rec."Parent Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and ParentSourceNoEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the unique identifier of the job on the price list line.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and SourceNoEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and AssetTypeEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies the type of the product.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies the number of the product.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = ItemAssetVisible;
                    Editable = PriceLineEditable and ItemAsset;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Visible = ResourceAssetVisible;
                    Editable = PriceLineEditable and ResourceAsset;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Editable = PriceLineEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the currency code of the price list line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = ItemAssetVisible or ResourceAssetVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AmountTypeIsVisible;
                    Editable = PriceLineEditable and AmountTypeIsEditable;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and SalesVisible and not DiscountOnlyVisible;
                    Editable = PriceLineEditable and PriceEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and SalesPriceLine and PriceEditable;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Cost Factor"; Rec."Cost Factor")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and SalesVisible and not DiscountOnlyVisible;
                    Editable = PriceLineEditable and PriceEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and SalesPriceLine and PriceEditable;
                    ToolTip = 'Specifies the unit cost factor, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and PurchVisible and not DiscountOnlyVisible;
                    Editable = PriceLineEditable and PriceEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and PurchPriceLine and PriceEditable;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and PurchVisible and not DiscountOnlyVisible;
                    Editable = PriceLineEditable and PriceEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and PurchPriceLine and PriceEditable;
                    ToolTip = 'Specifies the unit cost of the resource.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = DiscountVisible;
                    Editable = PriceLineEditable and DiscountEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and DiscountEditable;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and not DiscountOnlyVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and not DiscountOnlyVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the VAT business posting group for customers for whom you want the price (which includes VAT) to apply.';
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if the price includes VAT.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenPriceList)
            {
                ApplicationArea = All;
                Caption = 'Open Price List';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                Visible = LineExists;
                ToolTip = 'View or edit the price list.';

                trigger OnAction()
                begin
                    PriceUXManagement.EditPriceList(Rec."Price List Code");
                end;
            }

        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(VerifyLines)
                {
                    ApplicationArea = Basic, Suite;
                    Ellipsis = true;
                    Image = CheckDuplicates;
                    Promoted = true;
                    PromotedCategory = Process;
                    Caption = 'Verify Lines';
                    ToolTip = 'Checks data consistency in the new and modified price list lines. Finds the duplicate price lines and suggests the resolution of the line conflicts.';

                    trigger OnAction()
                    var
                        PriceListLine: Record "Price List Line";
                    begin
                        PriceListLine.Copy(Rec);
                        PriceListManagement.ActivateDraftLines(PriceListLine);
                        CurrPage.Update(false);
                    end;
                }
                action(AddLines)
                {
                    ApplicationArea = Basic, Suite;
                    Ellipsis = true;
                    Image = NewRow;
                    Promoted = true;
                    PromotedCategory = Process;
                    Caption = 'Add New Lines';
                    ToolTip = 'Opens the page where you can add new lines manually or copy them from the existing price lists or suggest new lines based on data in the product cards.';

                    trigger OnAction()
                    var
                        PriceWorksheet: Page "Price Worksheet";
                    begin
                        CurrPage.SaveRecord();
                        PriceWorksheet.SetPriceType(PriceSource."Price Type");
                        PriceWorksheet.RunModal();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureDisabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditableFields();
        LineExists := Rec."Price List Code" <> '';
    end;

    trigger OnAfterGetRecord()
    begin
        SetFieldsStyle();
    end;

    trigger OnOpenPage()
    begin
        PriceUXManagement.InitSmartListDesigner();
        GetRecFilters();
        SetRecFilters();
        SetCaption();
    end;

    var
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";
        CurrPriceListHeader: Record "Price List Header";
        PriceListManagement: Codeunit "Price List Management";
        PriceUXManagement: Codeunit "Price UX Management";
        FilterRecordRef: RecordRef;
        AmountTypeFilter: Enum "Price Amount Type";
        ParentSourceNoEditable: Boolean;
        SourceTypeEditable: Boolean;
        SourceNoEditable: Boolean;
        ParentSourceNoFilter: Text;
        ParentSourceNoFilterEditable: Boolean;
        SourceNoFilter: Text;
        SourceNoFilterEditable: Boolean;
        AssetNoFilter: Text;
        AssetNoFilterEditable: Boolean;
        CurrencyCodeFilter: Text;
        StartingDateFilter: Text;
        EndingDateFilter: Text;
        PageCaption: Text;
        Description3Lbl: Label '%1 %2 %3', Locked = true;
        Description5Lbl: Label '%1 %2 %3 %4 %5', Locked = true;
        WithinFilterLbl: Label 'No %1 within the filter %2.', Comment = '%1 - the unique entity id, %2 - the filter string ';
        PriceTypeVisible: Boolean;
        AmountTypeIsEditable: Boolean;
        AmountTypeIsVisible: Boolean;
        PriceVisible: Boolean;
        DiscountVisible: Boolean;
        DiscountOnlyVisible: Boolean;
        SalesVisible: Boolean;
        PurchVisible: Boolean;
        ItemAssetVisible: Boolean;
        ResourceAssetVisible: Boolean;
        ItemAsset: Boolean;
        ResourceAsset: Boolean;
        PriceLineEditable: Boolean;
        AssetTypeEditable: Boolean;
        DiscountEditable: Boolean;
        PriceEditable: Boolean;
        LineToVerify: Boolean;
        SalesPriceLine: Boolean;
        PurchPriceLine: Boolean;
        AllowUpdatingDefaults: Boolean;
        LineExists: Boolean;

    procedure SetRecFilters()
    begin
        CurrPage.SaveRecord();

        RefreshSourceNoFilter();
        RefreshAssetNoFilter();
        SetFilters();
        CheckRecFilters();
        SetVisibleFields();

        CurrPage.Update(false);
    end;

    local procedure CalcSourceNoEditable()
    begin
        SourceNoEditable := Rec.IsSourceNoAllowed();
    end;

    local procedure CheckFilters(TableNo: Integer; FilterTxt: Text)
    var
        FilterFieldRef: FieldRef;
    begin
        if (FilterTxt = '') or (TableNo = 0) then
            exit;
        Clear(FilterFieldRef);
        if FilterRecordRef.Number <> TableNo then begin
            Clear(FilterRecordRef);
            FilterRecordRef.Open(TableNo);
        end;
        FilterFieldRef := FilterRecordRef.Field(1);
        FilterFieldRef.SetFilter(FilterTxt);
        if FilterRecordRef.IsEmpty() then
            Error(WithinFilterLbl, FilterRecordRef.Caption, FilterTxt);
    end;

    local procedure CheckRecFilters()
    begin
        case PriceSource."Source Type" of
            PriceSource."Source Type"::Customer:
                CheckFilters(DATABASE::Customer, SourceNoFilter);
            PriceSource."Source Type"::"Customer Price Group":
                CheckFilters(DATABASE::"Customer Price Group", SourceNoFilter);
            PriceSource."Source Type"::Campaign:
                CheckFilters(DATABASE::Campaign, SourceNoFilter);
            PriceSource."Source Type"::Contact:
                CheckFilters(DATABASE::Contact, SourceNoFilter);
        end;

        CheckFilters(PriceAsset."Table Id", AssetNoFilter);
        CheckFilters(DATABASE::Currency, CurrencyCodeFilter);
    end;

    local procedure GetFilterDescription(): Text
    var
        Cust: Record Customer;
        CustPriceGr: Record "Customer Price Group";
        Campaign: Record Campaign;
        ObjTranslation: Record "Object Translation";
        SourceTableName: Text;
        SalesSrcTableName: Text;
        Description: Text;
    begin
        GetRecFilters();

        SourceTableName := '';
        if PriceAsset."Table Id" <> 0 then
            SourceTableName :=
                ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, PriceAsset."Table Id");

        SalesSrcTableName := '';
        Description := '';
        case PriceSource."Source Type" of
            PriceSource."Source Type"::Customer:
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 18);
                    Cust."No." := CopyStr(SourceNoFilter, 1, MaxStrLen(Cust."No."));
                    if Cust.FindFirst() then
                        Description := Cust.Name;
                end;
            PriceSource."Source Type"::"Customer Price Group":
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 6);
                    CustPriceGr.Code := CopyStr(SourceNoFilter, 1, MaxStrLen(CustPriceGr.Code));
                    if CustPriceGr.FindFirst() then
                        Description := CustPriceGr.Description;
                end;
            PriceSource."Source Type"::Campaign:
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 5071);
                    Campaign."No." := CopyStr(SourceNoFilter, 1, MaxStrLen(Campaign."No."));
                    if Campaign.FindFirst() then
                        Description := Campaign.Description;
                end;
            PriceSource."Source Type"::"All Customers":
                begin
                    SalesSrcTableName := Format(PriceSource."Source Type");
                    exit(StrSubstNo(Description3Lbl, SalesSrcTableName, SourceTableName, AssetNoFIlter));
                end;
        end;

        exit(StrSubstNo(Description5Lbl, SalesSrcTableName, SourceNoFilter, Description, SourceTableName, PriceAsset."Asset No."));
    end;

    local procedure GetRecFilters()
    begin
        Rec.FilterGroup(2);
        if Rec.GetFilters() <> '' then
            UpdateBasicRecFilters();

        Evaluate(StartingDateFilter, Rec.GetFilter("Starting Date"));
        Rec.FilterGroup(0);
    end;

    local procedure RefreshAssetNoFilter()
    begin
        AssetNoFilterEditable := PriceAsset.IsAssetNoRequired();
        if not AssetNoFilterEditable then
            AssetNoFilter := '';
    end;

    local procedure RefreshSourceNoFilter()
    begin
        SourceNoFilterEditable := PriceSource.IsSourceNoAllowed();
        ParentSourceNoFilterEditable := PriceSource.IsParentSourceAllowed();
        if not SourceNoFilterEditable then begin
            ParentSourceNoFilter := '';
            SourceNoFilter := '';
        end;
    end;

    local procedure SetCaption()
    begin
        PageCaption := GetFilterDescription();
    end;

    local procedure SetEditableFields()
    begin
        if Rec."Price List Code" <> CurrPriceListHeader.Code then begin
            AllowUpdatingDefaults := true;
            if CurrPriceListHeader.Get(Rec."Price List Code") then
                AllowUpdatingDefaults := CurrPriceListHeader."Allow Updating Defaults";
        end;

        ParentSourceNoEditable := PriceSource.IsParentSourceAllowed();
        AmountTypeIsEditable := Rec."Asset Type" <> Rec."Asset Type"::"Item Discount Group";
        ItemAsset := Rec.IsAssetItem();
        ResourceAsset := Rec.IsAssetResource();
        PriceLineEditable := Rec.IsEditable();
        CalcSourceNoEditable();
        SetFieldsStyle();
    end;

    local procedure SetFieldsStyle()
    begin
        LineToVerify := Rec.IsLineToVerify();
        SalesPriceLine := Rec."Price Type" = Rec."Price Type"::Sale;
        PurchPriceLine := Rec."Price Type" = Rec."Price Type"::Purchase;
        PriceEditable := Rec."Amount Type" in [Rec."Amount Type"::Any, Rec."Amount Type"::Price];
        DiscountEditable := Rec."Amount Type" in [Rec."Amount Type"::Any, Rec."Amount Type"::Discount];
    end;

    local procedure SetFilters()
    begin
        Rec.FilterGroup(2);
        if PriceSource."Price Type" <> PriceSource."Price Type"::Any then
            Rec.SetRange("Price Type", PriceSource."Price Type")
        else
            Rec.SetRange("Price Type");

        if PriceSource."Source Type" <> PriceSource."Source Type"::All then
            Rec.SetRange("Source Type", PriceSource."Source Type")
        else
            Rec.SetRange("Source Type");

        if SourceNoFilter <> '' then
            Rec.SetFilter("Source No.", SourceNoFilter)
        else
            Rec.SetRange("Source No.");

        if PriceAsset."Asset Type" <> "Price Asset Type"::" " then
            Rec.SetRange("Asset Type", PriceAsset."Asset Type")
        else
            Rec.SetRange("Asset Type");

        if AssetNoFilter <> '' then
            Rec.SetFilter("Asset No.", AssetNoFilter)
        else
            Rec.SetRange("Asset No.");

        if AmountTypeFilter <> AmountTypeFilter::Any then
            Rec.SetRange("Amount Type", AmountTypeFilter)
        else
            Rec.SetRange("Amount Type");

        if CurrencyCodeFilter <> '' then
            Rec.SetFilter("Currency Code", CurrencyCodeFilter)
        else
            Rec.SetRange("Currency Code");

        if StartingDateFilter <> '' then
            Rec.SetFilter("Starting Date", StartingDateFilter)
        else
            Rec.SetRange("Starting Date");

        if EndingDateFilter <> '' then
            Rec.SetFilter("Ending Date", EndingDateFilter)
        else
            Rec.SetRange("Ending Date");
        Rec.FilterGroup(0);
    end;

    local procedure SetVisibleFields()
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceTypeVisible := PriceSource."Price Type" = PriceSource."Price Type"::Any;
        AmountTypeIsVisible := AmountTypeFilter = AmountTypeFilter::Any;
        PriceVisible := AmountTypeFilter in [AmountTypeFilter::Any, AmountTypeFilter::Price];
        DiscountVisible := AmountTypeFilter in [AmountTypeFilter::Any, AmountTypeFilter::Discount];
        DiscountOnlyVisible := PriceAsset."Asset Type" = PriceAsset."Asset Type"::"Item Discount Group";
        SalesVisible := PriceSource."Price Type" in [PriceSource."Price Type"::Any, PriceSource."Price Type"::Sale];
        PurchVisible := PriceSource."Price Type" in [PriceSource."Price Type"::Any, PriceSource."Price Type"::Purchase];

        PriceListLine."Asset Type" := PriceAsset."Asset Type";
        ItemAssetVisible := (PriceAsset."Asset Type" = "Price Asset Type"::" ") or PriceListLine.IsAssetItem();
        ResourceAssetVisible := (PriceAsset."Asset Type" = "Price Asset Type"::" ") or PriceListLine.IsAssetResource();

        SourceTypeEditable := PriceSource."Source Type" = PriceSource."Source Type"::All;
        AssetTypeEditable := PriceAsset."Asset Type" = PriceAsset."Asset Type"::" ";
    end;

    local procedure UpdateBasicRecFilters()
    begin
        if Rec.GetFilter("Source Type") <> '' then
            Evaluate(PriceSource."Source Type", Rec.GetFilter("Source Type"))
        else
            PriceSource."Source Type" := PriceSource."Source Type"::All;

        SourceNoFilter := Rec.GetFilter("Source No.");
        AssetNoFilter := Rec.GetFilter("Asset No.");
        CurrencyCodeFilter := Rec.GetFilter("Currency Code");
    end;
}

