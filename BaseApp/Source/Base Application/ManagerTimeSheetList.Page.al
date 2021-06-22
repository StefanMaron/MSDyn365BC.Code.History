page 953 "Manager Time Sheet List"
{
    ApplicationArea = Jobs;
    Caption = 'Manager Time Sheets';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Time Sheet Header";
    SourceTableView = SORTING("Resource No.", "Starting Date");
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the starting date for a time sheet.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ending date for a time sheet.';
                }
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                }
                field("Open Exists"; "Open Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies if there are time sheet lines with the status Open.';
                }
                field("Submitted Exists"; "Submitted Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies if there are time sheet lines with the status Submitted.';
                }
                field("Rejected Exists"; "Rejected Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies whether there are time sheet lines with the status Rejected.';
                }
                field("Approved Exists"; "Approved Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies whether there are time sheet lines with the status Approved.';
                }
                field("Posted Exists"; "Posted Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies whether there are time sheet lines with the status Posted.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    DrillDown = false;
                    ToolTip = 'Specifies that a comment about this document has been entered.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Edit Time Sheet")
            {
                ApplicationArea = Jobs;
                Caption = '&Edit Time Sheet';
                Image = OpenJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ToolTip = 'Open the time sheet in edit mode.';

                trigger OnAction()
                begin
                    EditTimeSheet;
                end;
            }
            action(MoveTimeSheetsToArchive)
            {
                ApplicationArea = Jobs;
                Caption = 'Move Time Sheets to Archive';
                Image = Archive;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Move Time Sheets to Archive";
                ToolTip = 'Archive time sheets.';
            }
        }
        area(navigation)
        {
            group("&Time Sheet")
            {
                Caption = '&Time Sheet';
                Image = Timesheet;
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Time Sheet Comment Sheet";
                    RunPageLink = "No." = FIELD("No."),
                                  "Time Sheet Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action("Posting E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posting E&ntries';
                    Image = PostingEntries;
                    RunObject = Page "Time Sheet Posting Entries";
                    RunPageLink = "Time Sheet No." = FIELD("No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the resource ledger entries that have been posted in connection with the.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if UserSetup.Get(UserId) then
            CurrPage.Editable := UserSetup."Time Sheet Admin.";
        TimeSheetMgt.FilterTimeSheets(Rec, FieldNo("Approver User ID"));
    end;

    var
        UserSetup: Record "User Setup";
        TimeSheetMgt: Codeunit "Time Sheet Management";

    local procedure EditTimeSheet()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetMgt.SetTimeSheetNo("No.", TimeSheetLine);
        PAGE.Run(PAGE::"Manager Time Sheet", TimeSheetLine);
    end;
}

