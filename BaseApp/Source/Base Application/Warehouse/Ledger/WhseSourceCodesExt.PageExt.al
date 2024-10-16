namespace Microsoft.Warehouse.Ledger;

using Microsoft.Foundation.AuditCodes;

pageextension 7313 WhseSourceCodesExt extends "Source Codes"
{
    actions
    {
        addafter("G/L Registers")
        {
            action("Warehouse Registers")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Registers';
                Image = WarehouseRegisters;
                RunObject = Page "Warehouse Registers";
                RunPageLink = "Source Code" = field(Code);
                RunPageView = sorting("Source Code");
                ToolTip = 'View all warehouse entries per registration date.';
            }
        }
    }
}