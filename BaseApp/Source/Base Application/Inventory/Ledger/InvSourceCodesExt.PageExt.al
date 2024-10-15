namespace Microsoft.Inventory.Ledger;

using Microsoft.Foundation.AuditCodes;

pageextension 46 InvSourceCodesExt extends "Source Codes"
{
    actions
    {
        addafter("G/L Registers")
        {
            action("Item Registers")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Registers';
                Image = ItemRegisters;
                RunObject = Page "Item Registers";
                RunPageLink = "Source Code" = field(Code);
                RunPageView = sorting("Source Code");
                ToolTip = 'View posted item entries.';
            }
        }
    }
}