page 12137 "Item Costing Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Costing Setup';
    PageType = Card;
    SourceTable = "Item Costing Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Components Valuation"; "Components Valuation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary value of the item, based on inventory valuation methods.';
                }
                field("Estimated WIP Consumption"; "Estimated WIP Consumption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the item costs are calculated using production order component costs and production order routing costs.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

