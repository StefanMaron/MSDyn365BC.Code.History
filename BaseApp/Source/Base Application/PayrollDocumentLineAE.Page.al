page 17480 "Payroll Document Line AE"
{
    Caption = 'Payroll Document Line AE';
    Editable = false;
    LinksAllowed = false;
    PageType = Document;
    SourceTable = "Payroll Document Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("AE Period From"; "AE Period From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the average-earnings period. The period length is typically one year. ';
                }
                field("AE Period To"; "AE Period To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the average-earnings period. The period length is typically one year. ';
                }
                field("AE Total Earnings Indexed"; "AE Total Earnings Indexed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total average earnings, shown according to an index value. ';
                }
                field("AE Total FSI Earnings"; "AE Total FSI Earnings")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total average earnings that is related to the Federal Social Insurance fund.';
                }
                field("AE Total Days"; "AE Total Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total number of days that are based the average-earnings setup. ';
                }
                field("AE Daily Earnings"; "AE Daily Earnings")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the daily salary expressed as average earnings.';
                }
            }
            part(Control1210008; "Payroll Doc. Line AE Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("Document No."),
                              "Document Line No." = FIELD("Line No.");
            }
        }
    }

    actions
    {
    }
}

