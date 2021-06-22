page 680 "Report Inbox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Inbox';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Report Inbox";
    SourceTableView = SORTING("User ID", "Created Date-Time")
                      ORDER(Descending);
    UsageCategory = Lists;

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
                }
                field("Created Date-Time"; "Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time that the scheduled report was processed from the job queue.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Name"; "Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the report.';

                    trigger OnDrillDown()
                    begin
                        ShowReport;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
    }
}

