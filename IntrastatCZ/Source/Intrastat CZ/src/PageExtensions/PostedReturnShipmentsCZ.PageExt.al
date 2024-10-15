pageextension 31371 "Posted Return Shipments CZ" extends "Posted Return Shipments"
{
    layout
    {
        addlast(Control1)
        {
            field("Physical Transfer CZ"; Rec."Physical Transfer CZ")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Physical Transfer';
                ToolTip = 'Specifies if there is physical transfer of the item.';
                Visible = false;
            }
        }
    }
}