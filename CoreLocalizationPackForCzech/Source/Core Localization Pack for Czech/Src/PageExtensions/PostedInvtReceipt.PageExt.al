pageextension 31177 "Posted Invt. Receipt CZL" extends "Posted Invt. Receipt"
{
    layout
    {
        addbefore("Gen. Bus. Posting Group")
        {
            field("Invt. Movement Template CZL"; Rec."Invt. Movement Template CZL")
            {
                ApplicationArea = Basic, Suite;
                Tooltip = 'Specifies the template for item movement.';
                Editable = false;
            }
        }
    }
}