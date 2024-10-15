namespace Microsoft.Inventory.Costing;

page 5815 "Avg. Cost Adjmt. Entry Points"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Avg. Cost Adjmt. Entry Point";
    Caption = 'Avg. Cost Adjmt. Entry Points';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Item No."; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item number.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                    ToolTip = 'Specifies the variant code.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    Caption = 'Location Code';
                    ToolTip = 'Specifies the location code.';
                }
                field("Valuation Date"; Rec."Valuation Date")
                {
                    Caption = 'Valuation Date';
                    ToolTip = 'Specifies the valuation date from which the entry is included in the average cost calculation.';
                }
                field("Cost Is Adjusted"; Rec."Cost Is Adjusted")
                {
                    Caption = 'Cost Is Adjusted';
                    ToolTip = 'Specifies whether the cost is adjusted on the valuation date';
                }
            }
        }
    }
}