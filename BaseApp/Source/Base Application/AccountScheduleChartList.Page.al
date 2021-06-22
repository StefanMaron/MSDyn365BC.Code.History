page 767 "Account Schedule Chart List"
{
    Caption = 'Account Schedule Chart List';
    CardPageID = "Account Schedules Chart Setup";
    PageType = List;
    SourceTable = "Account Schedules Chart Setup";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the specific chart.';
                }
                field("Account Schedule Name"; "Account Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the account schedule that is used to generate the chart that is shown in the Finance Performance window.';
                    Visible = false;
                }
                field("Column Layout Name"; "Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the column layout in the account schedule that is used to generate the advanced chart that is shown in the Finance Performance window.';
                    Visible = false;
                }
                field("Base X-Axis on"; "Base X-Axis on")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the values from the selected account schedule are displayed in the specific chart.';
                    Visible = false;
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date on which account schedule values are included in the chart.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which account schedule values are included in the chart.';
                }
                field("Period Length"; "Period Length")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of periods in the chart.';
                    Visible = false;
                }
                field("No. of Periods"; "No. of Periods")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many periods are shown in the chart.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the specific chart.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Start Date" := WorkDate;
    end;
}

