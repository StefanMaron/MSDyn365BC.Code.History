page 28043 "WHT Posting Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Posting Setup';
    PageType = List;
    SourceTable = "WHT Posting Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1500000)
            {
                ShowCaption = false;
                field("WHT Business Posting Group"; "WHT Business Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a WHT Business Posting group code.';
                }
                field("WHT Product Posting Group"; "WHT Product Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a WHT Product Posting group code.';
                }
                field("WHT Calculation Rule"; "WHT Calculation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the WHT calculation rule.';
                }
                field("WHT Minimum Invoice Amount"; "WHT Minimum Invoice Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the threshold amount for WHT, below which there will not be any WHT deduction.';
                }
                field("WHT %"; "WHT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relevant WHT rate for the particular combination of WHT Business Posting group and WHT Product Posting group.';
                }
                field("Realized WHT Type"; "Realized WHT Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how WHT is calculated for purchases or sales of items with this particular combination of WHT business and product posting groups.';
                }
                field("Prepaid WHT Account Code"; "Prepaid WHT Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number to which you want to post sales WHT for the particular combination of WHT business and product posting groups.';
                }
                field("Payable WHT Account Code"; "Payable WHT Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number to which you want to post Purchase WHT for the particular combination of WHT business and product posting groups.';
                }
                field("WHT Report"; "WHT Report")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the WHT report type for a particular Business and Product Posting group combination.';
                }
                field("Bal. Prepaid Account Type"; "Bal. Prepaid Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of Balancing Account type for Sales WHT transaction.';
                }
                field("Bal. Prepaid Account No."; "Bal. Prepaid Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Account No. or Bank name (based on Bal. Prepaid Account Type) as a balancing account for Sales WHT transactions.';
                }
                field("Bal. Payable Account Type"; "Bal. Payable Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of Balancing Account type for Purchase WHT transaction.';
                }
                field("Bal. Payable Account No."; "Bal. Payable Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Account No. or Bank name (based on Bal. Prepaid Account Type) as a balancing account for Purchase WHT transactions.';
                }
                field("WHT Report Line No. Series"; "WHT Report Line No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the no. series for WHT Report Line for a particular WHT Business and Product Posting group combination.';
                }
                field("Revenue Type"; "Revenue Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Revenue Type this combination of WHT Business and Product Posting group belongs to.';
                }
                field("Purch. WHT Adj. Account No."; "Purch. WHT Adj. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account number for Purchase Credit Memo adjustments.';
                }
                field("Sales WHT Adj. Account No."; "Sales WHT Adj. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account number for Sales Credit Memo adjustments.';
                }
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sequence in which the WHT Posting Setup shall be displayed in reports.';
                }
            }
        }
    }

    actions
    {
    }
}

