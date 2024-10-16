namespace Microsoft.Finance.Consolidation;

page 245 "Consolidations in Progress"
{
    ApplicationArea = All;
    Caption = 'Consolidation status';
    SourceTable = "Consolidation Process";
    SourceTableView = order(descending);
    PageType = List;
    InsertAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Consolidations)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Status of the consolidation process';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Starting Date';
                    ToolTip = 'Starting date for the entries in the consolidation';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Ending Date';
                    ToolTip = 'Ending date for the entries in the consolidation';
                }
                field(ScheduledAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Scheduled At';
                    ToolTip = 'Date and time when the consolidation was scheduled';
                }
            }
        }
    }
}