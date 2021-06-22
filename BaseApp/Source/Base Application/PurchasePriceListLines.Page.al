page 7011 "Purchase Price List Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Price List Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(SourceType; VendorSourceType)
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Type';
                    Visible = IsVendorGroup and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the vendor.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(VendorSourceType.AsInteger());
                    end;
                }
                field(JobSourceType; JobSourceType)
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Type';
                    Visible = IsJobGroup and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the job or job task.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(JobSourceType.AsInteger());
                    end;
                }
                field(ParentSourceNo; Rec."Parent Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Job No.';
                    Importance = Promoted;
                    Editable = IsJobTask;
                    Visible = AllowUpdatingDefaults and IsJobGroup;
                    ToolTip = 'Specifies the job that is the source of the price on the price list line.';
                }
                field(SourceNo; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Enabled = SourceNoEnabled;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the currency that is used for the prices on the price list. The currency can be the same for all prices on the price list, or you can specify a currency for individual lines.';
                }
                field(StartingDate; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the product.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Enabled = ItemAsset;
                    Editable = ItemAsset;
                    ToolTip = 'Specifies the item variant.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    Enabled = ResourceAsset;
                    Editable = ResourceAsset;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Enabled = UOMEditable;
                    Editable = UOMEditable;
                    ToolTip = 'Specifies the unit of measure for the product.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Visible = AmountTypeIsVisible;
                    Editable = AmountTypeIsEditable;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                    trigger OnValidate()
                    begin
                        SetMandatoryAmount();
                    end;
                }
                field(DirectUnitCost; Rec."Direct Unit Cost")
                {
                    AccessByPermission = tabledata "Purchase Price Access" = R;
                    Caption = 'Direct Unit Cost';
                    ApplicationArea = All;
                    Editable = AmountEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    AccessByPermission = tabledata "Purchase Price Access" = R;
                    ApplicationArea = All;
                    Editable = AmountEditable and ResourceAsset;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and ResourceAsset;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit cost of the resource.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Purchase Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory;
                    Style = Subordinate;
                    StyleExpr = not DiscountMandatory;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSourceType();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSourceType();
        SetEditable();
        SetMandatoryAmount();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if PriceListHeader."Allow Updating Defaults" then begin
            Rec.CopySourceFrom(PriceListHeader);
            if Rec."Starting Date" = 0D then
                Rec."Starting Date" := PriceListHeader."Starting Date";
            if Rec."Ending Date" = 0D then
                Rec."Ending Date" := PriceListHeader."Ending Date";
            if Rec."Currency Code" = '' then
                Rec."Currency Code" := PriceListHeader."Currency Code";
        end;
        UpdateSourceType();
        Rec."Amount Type" := ViewAmountType;
    end;

    var
        AmountEditable: Boolean;
        UOMEditable: Boolean;
        ItemAsset: Boolean;
        ResourceAsset: Boolean;
        DiscountMandatory: Boolean;
        DiscountVisible: Boolean;
        PriceMandatory: Boolean;
        PriceVisible: Boolean;
        AmountTypeIsVisible: Boolean;
        AmountTypeIsEditable: Boolean;
        JobSourceType: Enum "Job Price Source Type";
        VendorSourceType: Enum "Purchase Price Source Type";
        IsVendorGroup: Boolean;
        IsJobGroup: Boolean;
        IsJobTask: Boolean;
        SourceNoEnabled: Boolean;
        AllowUpdatingDefaults: Boolean;

    protected var
        PriceListHeader: Record "Price List Header";
        PriceType: Enum "Price Type";
        ViewAmountType: Enum "Price Amount Type";

    local procedure SetEditable()
    begin
        AmountTypeIsEditable := Rec."Asset Type" <> Rec."Asset Type"::"Item Discount Group";
        AmountEditable := Rec.IsAmountSupported();
        UOMEditable := Rec.IsUOMSupported();
        ItemAsset := Rec.IsAssetItem();
        ResourceAsset := Rec.IsAssetResource();
    end;

    local procedure SetMandatoryAmount()
    begin
        DiscountMandatory := Rec.IsAmountMandatory(Rec."Amount Type"::Discount);
        PriceMandatory := Rec.IsAmountMandatory(Rec."Amount Type"::Price);
    end;

    local procedure UpdateColumnVisibility()
    begin
        AllowUpdatingDefaults := PriceListHeader."Allow Updating Defaults";
        AmountTypeIsVisible := ViewAmountType = ViewAmountType::Any;
        DiscountVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Discount];
        PriceVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Price];
    end;

    procedure SetHeader(Header: Record "Price List Header")
    begin
        PriceListHeader := Header;

        SetSubFormLinkFilter(PriceListHeader."Amount Type");
    end;

    procedure SetPriceType(NewPriceType: Enum "Price Type")
    begin
        PriceType := NewPriceType;
        PriceListHeader."Price Type" := NewPriceType;
    end;

    procedure SetSubFormLinkFilter(NewViewAmountType: Enum "Price Amount Type")
    var
        PriceListLine: Record "Price List Line";
        SkipActivate: Boolean;
    begin
        ViewAmountType := NewViewAmountType;
        if ViewAmountType = ViewAmountType::Any then
            PriceListLine.SetRange("Amount Type")
        else
            PriceListLine.SetFilter("Amount Type", '%1|%2', ViewAmountType, ViewAmountType::Any);
        CurrPage.SetTableView(PriceListLine);
        UpdateColumnVisibility();
        CurrPage.Update(false);
        OnAfterSetSubFormLinkFilter(SkipActivate);
        if not SkipActivate then
            CurrPage.Activate(true);
    end;

    local procedure UpdateSourceType()
    begin
        case PriceListHeader."Source Group" of
            "Price Source Group"::Vendor:
                begin
                    IsVendorGroup := true;
                    VendorSourceType := "Purchase Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                end;
            "Price Source Group"::Job:
                begin
                    IsJobGroup := true;
                    JobSourceType := "Job Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                    IsJobTask := JobSourceType = JobSourceType::"Job Task";
                end;
        end;
    end;

    local procedure SetSourceNoEnabled()
    begin
        SourceNoEnabled := Rec.IsSourceNoAllowed();
    end;

    local procedure ValidateSourceType(SourceType: Integer)
    begin
        Rec.Validate("Source Type", SourceType);
        SetSourceNoEnabled();
        CurrPage.Update(true);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetSubFormLinkFilter(var SkipActivate: Boolean)
    begin
    end;
}
