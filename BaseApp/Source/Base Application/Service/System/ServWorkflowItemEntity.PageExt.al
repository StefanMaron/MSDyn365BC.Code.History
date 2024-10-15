namespace System.Automation;

pageextension 6493 "Serv. Workflow Item Entity" extends "Workflow - Item Entity"
{
    layout
    {
        addafter(qtyPicked)
        {
            field(serviceItemGroup; Rec."Service Item Group")
            {
                ApplicationArea = All;
                Caption = 'Service Item Group', Locked = true;
            }
            field(qtyOnServiceOrder; Rec."Qty. on Service Order")
            {
                ApplicationArea = All;
                Caption = 'Qty. on Service Order', Locked = true;
            }
            field(resQtyOnServiceOrders; Rec."Res. Qty. on Service Orders")
            {
                ApplicationArea = All;
                Caption = 'Res. Qty. on Service Orders', Locked = true;
            }
        }
    }
}
