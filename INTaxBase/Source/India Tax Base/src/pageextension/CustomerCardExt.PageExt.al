pageextension 18544 "CustomerCardExt" extends "Customer Card"
{
    layout
    {
        addlast(General)
        {
            field("State Code"; "State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer''s state code. This state code will appear on all sales documents for the customer.';
            }
        }
        addafter(Shipping)
        {
            group("Tax Information")
            {
                field("Assessee Code"; "Assessee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Assessee Code by whom any tax or sum of money is payable';
                }
                group("PAN Details")
                {
                    field("P.A.N. No."; "P.A.N. No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the Permanent Account No. of Party';
                    }
                    field("P.A.N. Status"; "P.A.N. Status")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the PAN Status as PANAPPLIED,PANNOTAVBL,PANINVALID';
                    }
                    field("P.A.N. Reference No."; "P.A.N. Reference No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the PAN Reference No. in case the PAN is not available or applied by the party';
                    }
                }
            }
        }
    }
}