page 951 "Time Sheet List"
{
    ApplicationArea = Jobs;
    Caption = 'Time Sheets';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    CardPageID = "Time Sheet Card";
    SourceTable = "Time Sheet Header";
    SourceTableView = SORTING("Resource No.", "Starting Date");
    UsageCategory = Tasks;
    Editable = false;
    RefreshOnActivate = true;

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
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description for a time sheet.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                }
                field("Resource Name"; "Resource Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the resource for the time sheet.';
                    Visible = false;
                }
                field("Quantity"; "Quantity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total number of hours that are registered on the time sheet.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Quantity Open"; "Quantity Open")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Open';
                    ToolTip = 'Specifies the number of hours for the time sheet with status Open.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Quantity Submitted"; "Quantity Submitted")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Submitted';
                    ToolTip = 'Specifies the number of hours for the time sheet with status Submitted.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Quantity Approved"; "Quantity Approved")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Approved';
                    ToolTip = 'Specifies the number of hours for the time sheet with status Approved.';
                    Visible = TimeSheetV2Enabled;
                }
                field("Quantity Rejected"; "Quantity Rejected")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Rejected';
                    ToolTip = 'Specifies the number of hours for the time sheet with status Rejected.';
                    Visible = TimeSheetV2Enabled;
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that a comment about this document has been entered.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Create Time Sheets")
            {
                ApplicationArea = Jobs;
                Caption = 'Create Time Sheets';
                Image = NewTimesheet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                RunObject = Report "Create Time Sheets";
                ToolTip = 'Create new time sheets for resources.';
                Visible = TimeSheetAdminActionsVisible;
            }
            action(EditTimeSheet)
            {
                ApplicationArea = Jobs;
                Caption = '&Edit Time Sheet';
                Image = OpenJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ShortCutKey = 'Return';
                ToolTip = 'Open the time sheet in edit mode.';
                Visible = not TimeSheetV2Enabled;

                trigger OnAction()
                begin
                    OpenTimeSheetPage;
                end;
            }
            action(MoveTimeSheetsToArchive)
            {
                ApplicationArea = Jobs;
                Caption = 'Move Time Sheets to Archive';
                Image = Archive;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
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

        TimeSheetMgt.FilterTimeSheets(Rec, FieldNo("Owner User ID"));
    end;

    var
        UserSetup: Record "User Setup";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetV2Enabled: Boolean;
        TimeSheetAdminActionsVisible: Boolean;

    local procedure OpenTimeSheetPage()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if TimeSheetV2Enabled then
            Page.Run(Page::"Time Sheet Card", Rec)
        else begin
            TimeSheetMgt.SetTimeSheetNo("No.", TimeSheetLine);
            Page.Run(Page::"Time Sheet", TimeSheetLine);
        end;
    end;
}

