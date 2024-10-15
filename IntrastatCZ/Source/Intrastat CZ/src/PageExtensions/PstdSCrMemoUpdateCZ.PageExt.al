pageextension 31370 "Pstd. S. Cr.Memo - Update CZ" extends "Pstd. Sales Cr. Memo - Update"
{
    layout
    {
        addlast(Shipping)
        {
            field("Physical Transfer CZ"; Rec."Physical Transfer CZ")
            {
                ApplicationArea = Suite;
                Editable = true;
                ToolTip = 'Specifies if there is physical transfer of the item.';
            }
        }
    }
}