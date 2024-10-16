namespace Microsoft.Inventory.Requisition;

enum 99000905 "Requisition Ref. Order Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Purchase") { Caption = 'Purchase'; }
    value(2; "Prod. Order") { Caption = 'Prod. Order'; }
    value(3; "Transfer") { Caption = 'Transfer'; }
    value(4; "Assembly") { Caption = 'Assembly'; }
}
