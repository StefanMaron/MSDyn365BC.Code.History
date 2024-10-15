page 10017 "GIFI Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'GIFI Codes';
    PageType = List;
    SourceTable = "GIFI Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1020000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = BasicCA;
                    ToolTip = 'Specifies a General Index of Financial Information (GIFI) code. This code can be associated with records in the G/L Account table.';
                }
                field(Name; Name)
                {
                    ApplicationArea = BasicCA;
                    ToolTip = 'Specifies the name (or description) of a General Index of Financial Information (GIFI) code.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Export GIFI Info. to Excel")
            {
                ApplicationArea = BasicCA;
                Caption = 'Export GIFI Info. to Excel';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Export GIFI Info. to Excel";
                ToolTip = 'Export balance information using General Index of Financial Information (GIFI) codes and save the exported file in Excel. You can use the file to transfer information to your tax preparation software.';
            }
        }
        area(reporting)
        {
            action("Account Balances by GIFI Code")
            {
                ApplicationArea = BasicCA;
                Caption = 'Account Balances by GIFI Code';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Account Balances by GIFI Code";
                ToolTip = 'Review your account balances by General Index of Financial Information (GIFI) code using the Account Balances by GIFI Code report.';
            }
        }
    }
}

