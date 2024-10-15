pageextension 18547 "Location Card IN" extends "Location Card"
{
    layout
    {
        addafter("Bin Policies")
        {
            group("Tax Information")
            {
                field("T.A.N. No."; "T.A.N. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the T.A.N No of Location';
                }
                field("State Code"; "State Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the State Code of Location';
                }
            }
        }
    }
}