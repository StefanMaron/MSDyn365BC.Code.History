page 17438 "Posted Payr. Doc. Line AE Per."
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Posted Payroll Period AE";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("AEPeriodFrom.""Starting Date"""; AEPeriodFrom."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AE Start Date';
                }
                field("AEPeriodTo.""Ending Date"""; AEPeriodTo."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AE End Date';
                }
                field(AETotalAmount; AETotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Earnings Indexed';
                }
                field(AETotalFSIAmount; AETotalFSIAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total FSI Earnings';
                }
                field(AETotalDays; AETotalDays)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Days';
                }
                field(AEDailyAmount; AEDailyAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Average Earnings';
                    ToolTip = 'Specifies the calculated average salary.';
                }
            }
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Period No."; "Period No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Start Date"; "Period Start Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period End Date"; "Period End Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Salary"; "Base Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Extra Salary"; "Extra Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Salary Amount"; "Salary Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bonus Amount"; "Bonus Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount for FSI"; "Amount for FSI")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that applies to the Federal Social Insurance fund.';
                }
                field("Indexation Factor"; "Indexation Factor")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Planned Calendar Days"; "Planned Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Actual Calendar Days"; "Actual Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the available days the employee actually worked. ';
                }
                field("Planned Work Days"; "Planned Work Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Actual Work Days"; "Actual Work Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the employee''s planned work days the employee actually worked. ';
                }
                field("Average Days"; "Average Days")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    var
        AEPeriodFrom: Record "Payroll Period";
        AEPeriodTo: Record "Payroll Period";
        SourceType: Option Document,"Posted Document","Ledger Entry";
        AETotalAmount: Decimal;
        AEDailyAmount: Decimal;
        AETotalDays: Decimal;
        AETotalFSIAmount: Decimal;

    [Scope('OnPrem')]
    procedure SetDocLine(NewDocLine: Record "Posted Payroll Document Line")
    begin
        SourceType := SourceType::Document;
        with NewDocLine do begin
            if not AEPeriodFrom.Get("AE Period From") then
                exit;
            if not AEPeriodTo.Get("AE Period To") then
                exit;
            CalcFields("AE Total Earnings Indexed", "AE Total FSI Earnings", "AE Total Days");
            AETotalAmount := "AE Total Earnings Indexed";
            AETotalFSIAmount := "AE Total FSI Earnings";
            AETotalDays := "AE Total Days";
            AEDailyAmount := "AE Daily Earnings";
        end;
        SetRange("Document No.", NewDocLine."Document No.");
        SetRange("Line No.", NewDocLine."Line No.");
    end;
}

