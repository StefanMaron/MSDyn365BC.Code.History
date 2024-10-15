// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using System.Security.User;

page 951 "Time Sheet List"
{
    ApplicationArea = Jobs;
    Caption = 'Time Sheets';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    CardPageID = "Time Sheet Card";
    SourceTable = "Time Sheet Header";
    SourceTableView = sorting("Resource No.", "Starting Date") order(descending);
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
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description for a time sheet.';
#if not CLEAN22
                    Visible = TimeSheetV2Enabled;
#endif
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
#if not CLEAN22
                    Visible = TimeSheetV2Enabled;
#endif
                }
                field("Quantity Open"; Rec."Quantity Open")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Open';
                    ToolTip = 'Specifies the number of hours for the time sheet with status Open.';
#if not CLEAN22
                    Visible = TimeSheetV2Enabled;
#endif
                }
                field("Quantity Submitted"; Rec."Quantity Submitted")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Submitted';
                    ToolTip = 'Specifies the number of hours for the time sheet with status Submitted.';
#if not CLEAN22
                    Visible = TimeSheetV2Enabled;
#endif
                }
                field("Quantity Approved"; Rec."Quantity Approved")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Approved';
                    ToolTip = 'Specifies the number of hours for the time sheet with status Approved.';
#if not CLEAN22
                    Visible = TimeSheetV2Enabled;
#endif
                }
                field("Quantity Rejected"; Rec."Quantity Rejected")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Rejected';
                    ToolTip = 'Specifies the number of hours for the time sheet with status Rejected.';
#if not CLEAN22
                    Visible = TimeSheetV2Enabled;
#endif
                }
                field(Comment; Rec.Comment)
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
                RunObject = Report "Create Time Sheets";
                ToolTip = 'Create new time sheets for resources.';
                Visible = TimeSheetAdminActionsVisible;
            }
#if not CLEAN22
            action(EditTimeSheet)
            {
                ApplicationArea = Jobs;
                Caption = '&Edit Time Sheet';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open the time sheet in edit mode.';
                Visible = not TimeSheetV2Enabled;
                ObsoleteReason = 'Removed as part of old Time Sheet UI.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';

                trigger OnAction()
                begin
                    OpenTimeSheetPage();
                end;
            }
#endif
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
                    RunPageLink = "No." = field("No."),
                                  "Time Sheet Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

#if not CLEAN22
                actionref(EditTimeSheet_Promoted; EditTimeSheet)
                {
                    ObsoleteReason = 'Removed as part of old Time Sheet UI.';
                    ObsoleteState = Pending;
#pragma warning disable AS0072
                    ObsoleteTag = '22.0';
#pragma warning restore AS0072
                }
#endif
                actionref("Create Time Sheets_Promoted"; "Create Time Sheets")
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
#if not CLEAN22
        TimeSheetV2Enabled := TimeSheetMgt.TimeSheetV2Enabled();
#endif
        TimeSheetAdminActionsVisible := true;
        if UserSetup.Get(UserId) then
            CurrPage.Editable := UserSetup."Time Sheet Admin.";
#if not CLEAN22
        if TimeSheetV2Enabled then
#endif
        TimeSheetAdminActionsVisible := UserSetup."Time Sheet Admin.";

        TimeSheetMgt.FilterTimeSheets(Rec, Rec.FieldNo("Owner User ID"));
        OnAfterOnOpenPage(Rec);
    end;

    var
        UserSetup: Record "User Setup";
        TimeSheetMgt: Codeunit "Time Sheet Management";
#if not CLEAN22
        TimeSheetV2Enabled: Boolean;
#endif
        TimeSheetAdminActionsVisible: Boolean;

#if not CLEAN22
    local procedure OpenTimeSheetPage()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if not TimeSheetV2Enabled then begin
            TimeSheetMgt.SetTimeSheetNo(Rec."No.", TimeSheetLine);
            Page.Run(Page::"Time Sheet", TimeSheetLine);
            exit;
        end;
        Page.Run(Page::"Time Sheet Card", Rec)
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var TimeSheetHeader: Record "Time Sheet Header")
    begin
    end;
}

