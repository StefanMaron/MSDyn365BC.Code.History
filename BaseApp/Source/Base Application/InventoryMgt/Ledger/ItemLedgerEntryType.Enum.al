namespace Microsoft.Inventory.Ledger;

enum 78 "Item Ledger Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Purchase") { Caption = 'Purchase'; }
    value(1; "Sale") { Caption = 'Sale'; }
    value(2; "Positive Adjmt.") { Caption = 'Positive Adjmt.'; }
    value(3; "Negative Adjmt.") { Caption = 'Negative Adjmt.'; }
    value(4; "Transfer") { Caption = 'Transfer'; }
    value(5; "Consumption") { Caption = 'Consumption'; }
    value(6; "Output") { Caption = 'Output'; }
    value(7; " ") { Caption = ' '; }
    value(8; "Assembly Consumption") { Caption = 'Assembly Consumption'; }
    value(9; "Assembly Output") { Caption = 'Assembly Output'; }
}