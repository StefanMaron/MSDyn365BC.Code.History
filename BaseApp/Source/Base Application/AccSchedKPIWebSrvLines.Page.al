page 196 "Acc. Sched. KPI Web Srv. Lines"
{
    Caption = 'Account Schedule KPI Web Service Setup';
    PageType = ListPart;
    SourceTable = "Acc. Sched. KPI Web Srv. Line";

    layout
    {
        area(content)
        {
            repeater(Control13)
            {
                ShowCaption = false;
                field("Acc. Schedule Name"; "Acc. Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account schedule that the KPI web service is based on. To view or edit the selected account schedule, choose the Edit Account Schedule button.';
                }
                field("Acc. Schedule Description"; "Acc. Schedule Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the account schedule that the KPI web service is based on.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(EditAccSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Account Schedule';
                ToolTip = 'Opens the Account Schedule window so that you can modify the account schedule.';

                trigger OnAction()
                var
                    AccSchedule: Page "Account Schedule";
                begin
                    AccSchedule.SetAccSchedName("Acc. Schedule Name");
                    AccSchedule.Run;
                end;
            }
        }
    }
}

