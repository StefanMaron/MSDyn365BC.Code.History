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
                field(SourceType; SourceType)
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Type';
                    Visible = not IsJobGroup and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the vendor.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(SourceType.AsInteger());
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
                    Editable = IsParentAllowed;
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
                    Style = Attention;
                    StyleExpr = LineToVerify;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the product.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
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
                    Style = Attention;
                    StyleExpr = not PriceMandatory or LineToVerify;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    AccessByPermission = tabledata "Purchase Price Access" = R;
                    ApplicationArea = All;
                    Editable = AmountEditable and ResourceAsset;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and ResourceAsset;
                    Style = Attention;
                    StyleExpr = not PriceMandatory or LineToVerify;
                    ToolTip = 'Specifies the unit cost of the resource.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory;
                    Style = Attention;
                    StyleExpr = not PriceMandatory or LineToVerify;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Purchase Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory;
                    Style = Attention;
                    StyleExpr = not DiscountMandatory or LineToVerify;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory;
                    Style = Attention;
                    StyleExpr = not PriceMandatory or LineToVerify;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
                field(PriceIncludesVAT; Rec."Price Includes VAT")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the if prices include VAT.';
                }
                field(VATBusPostingGrPrice; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the default VAT business posting group code.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSourceType();
        LineToVerify := Rec.IsLineToVerify();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSourceType();
        SetEditable();
        SetMandatoryAmount();
        LineToVerify := Rec.IsLineToVerify();
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
        SourceType: Enum "Purchase Price Source Type";
        IsJobGroup: Boolean;
        IsParentAllowed: Boolean;
        LineToVerify: Boolean;
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
    begin
        ViewAmountType := NewViewAmountType;
        Rec.FilterGroup(2);
        if ViewAmountType = ViewAmountType::Any then
            Rec.SetRange("Amount Type")
        else
            Rec.SetFilter("Amount Type", '%1|%2', ViewAmountType, ViewAmountType::Any);
        Rec.FilterGroup(0);
        UpdateColumnVisibility();
        CurrPage.Update(false);
        CurrPage.Activate(true);
    end;

    local procedure UpdateSourceType()
    var
        PriceSource: Record "Price Source";
    begin
        case PriceListHeader."Source Group" of
            "Price Source Group"::Vendor:
                begin
                    IsJobGroup := false;
                    SourceType := "Purchase Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                end;
            "Price Source Group"::Job:
                begin
                    IsJobGroup := true;
                    JobSourceType := "Job Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                end;
        end;
        PriceSource."Source Type" := Rec."Source Type";
        IsParentAllowed := PriceSource.IsParentSourceAllowed();
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

#if not CLEAN18
    [Obsolete('Used to be a workaround for now fixed bug 374742.', '18.0')]
    procedure RunOnAfterSetSubFormLinkFilter()
    var
        SkipActivate: Boolean;
    begin
        OnAfterSetSubFormLinkFilter(SkipActivate);
    end;

    [Obsolete('Used to be a workaround for now fixed bug 374742.', '18.0')]
    [IntegrationEvent(true, false)]
    local procedure OnAfterSetSubFormLinkFilter(var SkipActivate: Boolean)
    begin
    end;
#endif
}