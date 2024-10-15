page 953 "Manager Time Sheet List"
{
    ApplicationArea = Jobs;
    Caption = 'Manager Time Sheets';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    CardPageID = "Time Sheet Card";
    RefreshOnActivate = true;
    SourceTable = "Time Sheet Header";
    SourceTableView = SORTING("Resource No.", "Starting Date") order(descending);
    UsageCategory = Tasks;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the starting date for a time sheet.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ending date for a time sheet.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description for a time sheet.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                }
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the resource for the time sheet.';
                    Visible = false;
                }
                field("Quantity"; Rec."Quantity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total number of hours that are registered on the time sheet.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Quantity Open"; Rec."Quantity Open")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Open';
                    ToolTip = 'Specifies the total number of hours with the status Open on the time sheet.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Quantity Submitted"; Rec."Quantity Submitted")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Submitted';
                    ToolTip = 'Specifies the total number of hours with the status Submitted on the time sheet.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Quantity Approved"; Rec."Quantity Approved")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Approved';
                    ToolTip = 'Specifies the total number of hours with the status Approved on the time sheet.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Quantity Rejected"; Rec."Quantity Rejected")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Rejected';
                    ToolTip = 'Specifies the total number of hours with the status Rejected on the time sheet.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Open Exists"; Rec."Open Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies if there are time sheet lines with the status Open.';
                    Visible = not TimeSheetV2Enabled;
                }
                field("Submitted Exists"; Rec."Submitted Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies if there are time sheet lines with the status Submitted.';
                    Visible = not TimeSheetV2Enabled;
                }
                field("Rejected Exists"; Rec."Rejected Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies whether there are time sheet lines with the status Rejected.';
                    Visible = not TimeSheetV2Enabled;
                }
                field("Approved Exists"; Rec."Approved Exists")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies whether there are time sheet lines with the status Approved.';
                    Visible = not TimeSheetV2Enabled;
                }
                field("Posted Exists"; Rec."Posted Exists")
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
                Caption = '&Review Time Sheet';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open the time sheet to approve its details. This requires that you''re the time sheet owner, administrator, or approver.';
                Visible = not TimeSheetV2Enabled;

                trigger OnAction()
                begin
                    ReviewTimeSheet();
                end;
            }
            action(MoveTimeSheetsToArchive)
            {
                ApplicationArea = Jobs;
                Caption = 'Move Time Sheets to Archive';
                Image = Archive;
                RunObject = Report "Move Time Sheets to Archive";
                ToolTip = 'Archive time sheets.';
                Visible = TimeSheetAdminActionsVisible;
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Edit Time Sheet_Promoted"; "&Edit Time Sheet")
                {
                }
                actionref(MoveTimeSheetsToArchive_Promoted; MoveTimeSheetsToArchive)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        TimeSheetV2Enabled := TimeSheetMgt.TimeSheetV2Enabled();
        TimeSheetAdminActionsVisible := true;
        if UserSetup.Get(UserId) then
            CurrPage.Editable := UserSetup."Time Sheet Admin.";
        if TimeSheetV2Enabled then
            TimeSheetAdminActionsVisible := UserSetup."Time Sheet Admin.";

        TimeSheetMgt.FilterTimeSheets(Rec, FieldNo("Approver User ID"));

        OnAfterOnOpenPage(Rec);
    end;

    var
        UserSetup: Record "User Setup";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetV2Enabled: Boolean;
        TimeSheetAdminActionsVisible: Boolean;

    local procedure ReviewTimeSheet()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetCard: Page "Time Sheet Card";
    begin
        if TimeSheetV2Enabled then begin
            TimeSheetCard.SetManagerTimeSheetMode();
            TimeSheetCard.SetTableView(Rec);
            TimeSheetCard.SetRecord(Rec);
            TimeSheetCard.Run();
        end else begin
            TimeSheetMgt.SetTimeSheetNo("No.", TimeSheetLine);
            Page.Run(Page::"Manager Time Sheet", TimeSheetLine);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var TimeSheetHeader: Record "Time Sheet Header")
    begin
    end;
}

