pageextension 18688 "Source Code Setup" extends "Source Code Setup"
{
    layout
    {
        addlast(General)
        {
            field("TDS Adjustment Journal"; Rec."TDS Adjustment Journal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for TDS Adjustment Journal.';
            }
        }
    }
}