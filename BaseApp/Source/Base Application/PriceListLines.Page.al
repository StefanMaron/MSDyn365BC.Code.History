page 7001 "Price List Lines"
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
                field("Asset Type"; Rec."Asset Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the prodcut.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the product.';
                    trigger OnValidate()
                    begin
                        SetEditable();
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
                    ToolTip = 'Specifies the data that is defined in the price list line. It can be either price or discount, or both';
                    trigger OnValidate()
                    begin
                        SetMandatoryAmount();
                    end;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    AccessByPermission = tabledata "Sales Price Access" = R;
                    ApplicationArea = All;
                    Editable = AmountEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Cost Factor"; Rec."Cost Factor")
                {
                    AccessByPermission = tabledata "Sales Price Access" = R;
                    ApplicationArea = All;
                    Editable = AmountEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit cost factor, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    Visible = false;
                    ToolTip = 'Specifies the unit cost of the product.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Purchase price field is in the Purchase Price List Lines page.';
                    ObsoleteTag = '18.0';
                }
                field(DirectUnitCost; Rec."Direct Unit Cost")
                {
                    Visible = false;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Purchase price field is in the Purchase Price List Lines page.';
                    ObsoleteTag = '18.0';
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
                    AccessByPermission = tabledata "Sales Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory;
                    Style = Subordinate;
                    StyleExpr = not DiscountMandatory;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetEditable();
        SetMandatoryAmount();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditable();
        SetMandatoryAmount();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
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

    protected var
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
        AmountTypeIsVisible := ViewAmountType = ViewAmountType::Any;
        DiscountVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Discount];
        PriceVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Price];
    end;

    procedure SetPriceType(NewPriceType: Enum "Price Type")
    begin
        PriceType := NewPriceType;
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

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetSubFormLinkFilter(var SkipActivate: Boolean)
    begin
    end;
}
