page 197 "Acc. Sched. KPI Web Service"
{
    AdditionalSearchTerms = 'financial report,business intelligence,bi,odata';
    ApplicationArea = Basic, Suite;
    Caption = 'Account Schedule KPI Web Service';
    Editable = false;
    PageType = List;
    SourceTable = "Acc. Sched. KPI Buffer";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account-schedule KPI web service.';
                    Visible = false;
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date that the account-schedule KPI data is based on.';
                }
                field("Closed Period"; "Closed Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Period';
                    ToolTip = 'Specifies if the accounting period is closed or locked.';
                }
                field("Account Schedule Name"; "Account Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Schedule Name';
                    ToolTip = 'Specifies the name of the account schedule that the KPI web service is based on.';
                }
                field("KPI Code"; "KPI Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'KPI Code';
                    ToolTip = 'Specifies a code for the account-schedule KPI web service.';
                }
                field("KPI Name"; "KPI Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'KPI Name';
                    ToolTip = 'Specifies the name that will be shown on the KPI as a user-friendly name for the account schedule values.';
                }
                field("Net Change Actual"; "Net Change Actual")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Change Actual';
                    ToolTip = 'Specifies changes in the actual general ledger amount, for closed accounting periods, up until the date in the Date field.';
                }
                field("Balance at Date Actual"; "Balance at Date Actual")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance at Date Actual';
                    ToolTip = 'Specifies the actual general ledger balance, based on closed accounting periods, on the date in the Date field.';
                }
                field("Net Change Budget"; "Net Change Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Net Change Budget';
                    ToolTip = 'Specifies changes in the budgeted general ledger amount, based on the general ledger budget, up until the date in the Date field.';
                }
                field("Balance at Date Budget"; "Balance at Date Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Balance at Date Budget';
                    ToolTip = 'Specifies the budgeted general ledger balance, based on the general ledger budget, on the date in the Date field.';
                }
                field("Net Change Actual Last Year"; "Net Change Actual Last Year")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Change Actual Last Year';
                    ToolTip = 'Specifies actual changes in the general ledger amount, based on closed accounting periods, through the previous accounting year.';
                }
                field("Balance at Date Actual Last Year"; "Balance at Date Act. Last Year")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance at Date Actual Last Year';
                    ToolTip = 'Specifies the actual general ledger balance, based on closed accounting periods, on the date in the Date field in the previous accounting year.';
                }
                field("Net Change Budget Last Year"; "Net Change Budget Last Year")
                {
                    ApplicationArea = Suite;
                    Caption = 'Net Change Budget Last Year';
                    ToolTip = 'Specifies budgeted changes in the general ledger amount, up until the date in the Date field in the previous year.';
                }
                field("Balance at Date Budget Last Year"; "Balance at Date Bud. Last Year")
                {
                    ApplicationArea = Suite;
                    Caption = 'Balance at Date Budget Last Year';
                    ToolTip = 'Specifies the budgeted general ledger balance, based on the general ledger budget, on the date in the Date field in the previous accounting year.';
                }
                field("Net Change Forecast"; "Net Change Forecast")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Change Forecast';
                    ToolTip = 'Specifies forecasted changes in the general ledger amount, based on open accounting periods, up until the date in the Date field.';
                }
                field("Balance at Date Forecast"; "Balance at Date Forecast")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance at Date Forecast';
                    ToolTip = 'Specifies the forecasted general ledger balance, based on open accounting periods, on the date in the Date field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CODEUNIT.Run(CODEUNIT::"Update Acc. Sched. KPI Data");
    end;
}

