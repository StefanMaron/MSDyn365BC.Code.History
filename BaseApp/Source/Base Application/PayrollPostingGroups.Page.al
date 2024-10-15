page 17402 "Payroll Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Posting Groups';
    PageType = List;
    SourceTable = "Payroll Posting Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number.';
                }
                field("Fund Vendor No."; "Fund Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Future Vacation G/L Acc. No."; "Future Vacation G/L Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Tax Allocation Posting Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Tax Allocation Posting Setup';
                Image = TaxSetup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Tax Allocation Posting Setup";
                RunPageLink = "Main Posting Group" = FIELD(Code);
                ToolTip = 'Set up how tax amounts are allocated during posting.';
            }
        }
    }
}

