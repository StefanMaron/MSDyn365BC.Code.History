page 7010 "Get Price Line"
{
    Caption = 'Get Price Line';
    Editable = false;
    PageType = List;
    SourceTable = "Price List Line";
    SourceTableTemporary = true;
    DataCaptionExpression = DataCaptionExpr;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Unit Price"; Rec."Unit Price")
                {
                    Visible = PriceVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the price of one unit of the selected product.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    Visible = DiscountVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Direct Unit Cost"; "Unit Cost")
                {
                    Visible = false;
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the cost of one unit of the selected asset.';
                }
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the price list code.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    Visible = false;
                    Caption = 'Defines';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of data, either price or discount, or both.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    Caption = 'Applies-to Type';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the entity that offers the price or the line discount on the product.';
                }
                field("Source No."; Rec."Source No.")
                {
                    Caption = 'Applies-to No.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the entity who offers the price or the line discount on the product.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code of the price.';
                    Visible = false;
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    Visible = false;
                    Caption = 'Product Type';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the product that the price applies to.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    Visible = false;
                    Caption = 'Product No.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the product that the price applies to.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = ItemVariantVisible;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the work type code for the resource.';
                    Visible = WorkTypeCodeVisible;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum quantity of the item that you must buy or sale in order to get the price.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    Visible = PriceVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the if the line discount allowed.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    Visible = PriceVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the if the invoice discount allowed.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which the price or the line discount is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date to which the price or the line discount is valid.';
                }
            }
        }
    }

    var
        DataCaptionExpr: Text;
        DataCaptionExprTok: Label 'Pick %1 for %2 of %3 %4',
            Comment = '%1 - Price or Discount, %2 - Sale or Purchase, %3 - the product type, %4 - the product no., e.g. Pick price for sale of Item 1000.';

    protected var
        AmountType: Enum "Price Amount Type";
        DiscountVisible: Boolean;
        ItemVariantVisible: Boolean;
        WorkTypeCodeVisible: Boolean;
        PriceVisible: Boolean;

    procedure SetForLookup(LineWithPrice: Interface "Line With Price"; NewAmountType: Enum "Price Amount Type"; var TempPriceListLine: Record "Price List Line" temporary)
    var
        AssetType: Enum "Price Asset Type";
    begin
        CurrPage.LookupMode(true);
        Rec.Copy(TempPriceListLine, true);
        AmountType := NewAmountType;
        AssetType := LineWithPrice.GetAssetType();
        DataCaptionExpr := StrSubstNo(DataCaptionExprTok, AmountType, LineWithPrice.GetPriceType(), AssetType, Rec."Asset No.");
        PriceVisible := AmountType in [AmountType::Price, AmountType::Any];
        DiscountVisible := AmountType in [AmountType::Discount, AmountType::Any];
        ItemVariantVisible := AssetType = AssetType::Item;
        WorkTypeCodeVisible := AssetType = AssetType::Resource;
    end;
}

