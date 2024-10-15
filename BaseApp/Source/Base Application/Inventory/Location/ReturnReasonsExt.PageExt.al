namespace Microsoft.Inventory.Location;

using Microsoft.Foundation.AuditCodes;

pageextension 6635 ReturnReasonsExt extends "Return Reasons"
{
    layout
    {
        addafter(Description)
        {
            field("Default Location Code"; Rec."Default Location Code")
            {
                ApplicationArea = SalesReturnOrder;
                ToolTip = 'Specifies the location where items that are returned for the reason in question are always placed.';
            }
            field("Inventory Value Zero"; Rec."Inventory Value Zero")
            {
                ApplicationArea = SalesReturnOrder;
                ToolTip = 'Specifies that items that are returned for the reason in question do not increase the inventory value.';
            }
        }
    }
}