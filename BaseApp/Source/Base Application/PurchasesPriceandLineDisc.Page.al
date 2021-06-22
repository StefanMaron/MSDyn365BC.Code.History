page 1346 "Purchases Price and Line Disc."
{
    Caption = 'Purchase Prices';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Purch. Price Line Disc. Buff.";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line Type"; "Line Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the line is for a purchase price or a purchase line discount.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; "Minimum Quantity")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity that must be entered on the purchase document to warrant the purchase price or discount.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the unit price that is granted on purchase documents if certain criteria are met, such as purchase code, currency code, and date.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date from which the purchase line discount is valid.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date to which the purchase line discount is valid.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that must be used on the purchase document line to warrant the purchase price or discount.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the variant that must be used on the purchase document line to warrant the purchase price or discount.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the vendor who offers the line discount on the item.';
                }
            }
        }
    }

    actions
    {
    }

    procedure LoadItem(Item: Record Item)
    begin
        Clear(Rec);

        LoadDataForItem(Item);
    end;
}

