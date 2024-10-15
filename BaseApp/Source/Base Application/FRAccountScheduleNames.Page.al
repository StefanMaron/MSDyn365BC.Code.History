page 10800 "FR Account Schedule Names"
{
    Caption = 'Balance Sheet & Income Statement';
    PageType = List;
    SourceTable = "FR Acc. Schedule Name";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the account schedule.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the account schedule.';
                }
                field("Caption Column 1"; "Caption Column 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a column description for the current year''s total balance of the account schedule.';
                }
                field("Caption Column 2"; "Caption Column 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a column description for the current year''s total balance of the account schedule.';
                }
                field("Caption Column 3"; "Caption Column 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a column description for the current year''s total balance of the account schedule.';
                }
                field("Caption Column Previous Year"; "Caption Column Previous Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the column of the previous year''s total balance on the account schedule.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(EditAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Account Schedule';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Return';
                ToolTip = 'Open the Account Schedule window so that you can modify the account schedule.';

                trigger OnAction()
                var
                    AccSchedule: Page "FR Account Schedule";
                begin
                    AccSchedule.SetAccSchedName(Name);
                    AccSchedule.Run;
                end;
            }
        }
    }
}

