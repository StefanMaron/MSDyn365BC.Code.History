pageextension 18158 "GST Ship-to Address" extends "Ship-to Address"
{
    layout
    {
        addlast(General)
        {
            field(State; State)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the state code of Ship to Address';

            }
            field("GST Registration No."; "GST Registration No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Vendors GST Reg. No. issues by Authorized body for Ship to Address.';
            }
            field("ARN No."; "ARN No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the ARN No. of the Ship to Address until the GST Registration No. is not assigned.';

            }
            field(Consignee; Consignee)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the Ship to Address is defiened as consignee.';

            }
        }

    }
}