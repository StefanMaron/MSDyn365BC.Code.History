page 12106 "Contribution Codes-INPS"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Social Security Codes';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Contribution Code";
    SourceTableView = WHERE("Contribution Type" = FILTER(INPS));
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
                    ApplicationArea = All;
                    ToolTip = 'Specifies a contribution code that you want the program to attach to the entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of what the code stands for.';
                }
                field("Social Security Payable Acc."; "Social Security Payable Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post the Social Security tax that is payable for the purchase.';
                }
                field("Social Security Charges Acc."; "Social Security Charges Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post Social Security contributions.';
                }
                field("Contribution Type"; "Contribution Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the type of contribution tax.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Soc. Sec. Rates")
            {
                Caption = '&Soc. Sec. Rates';
                Image = SocialSecurityPercentage;
                action("Soc. Sec. Code Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Soc. Sec. Code Lines';
                    Image = SocialSecurityLines;
                    RunObject = Page "Contribution Code Lines";
                    RunPageLink = Code = FIELD(Code),
                                  "Contribution Type" = FIELD("Contribution Type");
                    ToolTip = 'View the social security code lines.';
                }
            }
        }
    }
}

