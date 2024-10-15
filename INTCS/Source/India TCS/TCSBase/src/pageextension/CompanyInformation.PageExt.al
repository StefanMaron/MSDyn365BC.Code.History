pageextension 18807 "Company Information" extends "Company Information"
{
    layout
    {
        addafter("Ministry Code")
        {
            field("Circle No."; "Circle No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Circle No.';
                ToolTip = 'Specifies the TAN Circle Number of the address from where TCS return is filed.';
            }

            field("Assessing Officer"; "Assessing Officer")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Assessing Officer';
                ToolTip = 'Specifies the TAN Assessing Officer under whose jurisdiction the company falls.';
            }

            field("Ward No."; "Ward No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Ward No.';
                ToolTip = 'Specifies TAN Ward number which is the identification number of the income tax authority where returns are filed.';
            }
        }
        addlast("Tax Information")
        {
            field("T.C.A.N No."; "T.C.A.N. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the T.C.A.N No of Company';
            }
        }
    }
}