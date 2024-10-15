pageextension 31372 "Posted Return Shipment CZ" extends "Posted Return Shipment"
{
    layout
    {
        addlast(Shipping)
        {
            field("Physical Transfer CZ"; Rec."Physical Transfer CZ")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Physical Transfer';
                ToolTip = 'Specifies if there is physical transfer of the item.';
                Editable = false;
            }
        }
    }
}