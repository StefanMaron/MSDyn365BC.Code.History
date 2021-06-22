page 4001 "Intelligent Cloud Schedule"
{
    SourceTable = "Intelligent Cloud Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    Permissions = tabledata 4003 = rimd;

    layout
    {
        area(Content)
        {
            group(Schedule)
            {
                field("Replication Enabled"; "Replication Enabled")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Activate Schedule';
                    ToolTip = 'Activate Migration Schedule';
                }
                field(Recurrence; Recurrence)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recurrence';
                }
                group(Days)
                {
                    Caption = 'Select Days';
                    Visible = (Recurrence = Recurrence::Weekly);
                    field(Sunday; Sunday)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(Monday; Monday)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(Tuesday; Tuesday)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(Wednesday; Wednesday)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(Thursday; Thursday)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(Friday; Friday)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(Saturday; Saturday)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                field("Time to Run"; "Time to Run")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start time';
                    ToolTip = 'Specifies the time at which to start the migration.';
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        if "Replication Enabled" and (Format("Time to Run") = '') then
            Error(NoScheduleTimeMsg);
        SetReplicationSchedule();
    end;

    var
        NoScheduleTimeMsg: Label 'You must set a schedule time to continue.';
}