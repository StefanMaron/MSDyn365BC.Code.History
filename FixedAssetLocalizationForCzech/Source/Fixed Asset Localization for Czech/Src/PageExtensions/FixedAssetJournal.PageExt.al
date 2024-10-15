pageextension 31213 "Fixed Asset Journal CZF" extends "Fixed Asset Journal"
{
    layout
    {
        addbefore(Amount)
        {
            field("Correction CZF"; Rec.Correction)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the entry as a corrective entry. You can use the field if you need to post a corrective entry to an account.';
                Visible = false;
            }
        }
        addafter("Maintenance Code")
        {
            field("Reason Code CZF"; Rec."Reason Code")
            {
                ApplicationArea = FixedAssets;
                ToolTip = 'Specifies the reason code on the entry.';
            }
        }
    }
}
