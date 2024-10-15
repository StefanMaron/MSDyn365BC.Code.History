// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Projects.TimeSheet;

page 9043 "Team Member Activities No Msgs"
{
    Caption = 'Self-Service';
    PageType = CardPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Team Member Cue";

    layout
    {
        area(content)
        {
            cuegroup("Current Time Sheet")
            {
                Caption = 'Current Time Sheet';
                actions
                {
                    action(OpenCurrentTimeSheet)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Open My Current Time Sheet';
                        Image = TileBrickCalendar;
                        ToolTip = 'Open the time sheet for the current period. Current period is based on work date set in my settings.';
#if not CLEAN22
                        Visible = TimeSheetV2Enabled;
#endif
                        trigger OnAction()
                        var
                            TimeSheetHeader: Record "Time Sheet Header";
                            TimeSheetCard: Page "Time Sheet Card";
                        begin
                            TimeSheetManagement.FilterTimeSheets(TimeSheetHeader, TimeSheetHeader.FieldNo("Owner User ID"));
                            TimeSheetCard.SetTableView(TimeSheetHeader);
                            if TimeSheetHeader.Get(TimeSheetHeader.FindCurrentTimeSheetNo(TimeSheetHeader.FieldNo("Owner User ID"))) then
                                TimeSheetCard.SetRecord(TimeSheetHeader);
                            TimeSheetCard.Run();
                        end;
                    }
                }
            }
            cuegroup("Time Sheets")
            {
                Caption = 'Time Sheets';
                field("New Time Sheets"; Rec."New Time Sheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Time Sheet List";
                    ToolTip = 'Specifies the number of time sheets that are currently assigned to you, without lines.';
                }
                field("Open Time Sheets"; Rec."Open Time Sheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Time Sheet List";
                    ToolTip = 'Specifies the number of time sheets that are currently assigned to you, have open lines and not submitted for approval.';
                }
            }
            cuegroup("Pending Time Sheets")
            {
                Caption = 'Pending Time Sheets';
                field("Submitted Time Sheets"; Rec."Submitted Time Sheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Time Sheet List";
                    ToolTip = 'Specifies the number of time sheets that you have submitted for approval but are not yet approved.';
                }
                field("Rejected Time Sheets"; Rec."Rejected Time Sheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Time Sheet List";
                    ToolTip = 'Specifies the number of time sheets that you submitted for approval but were rejected.';
                }
                field("Approved Time Sheets"; Rec."Approved Time Sheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Time Sheet List";
                    ToolTip = 'Specifies the number of time sheets that have been approved.';
                }
            }
            cuegroup(Approvals)
            {
                Caption = 'Approvals';
                field("Time Sheets to Approve"; Rec."Time Sheets to Approve")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Manager Time Sheet List";
                    ToolTip = 'Specifies the number of time sheets that need to be approved.';
                    Visible = ShowTimeSheetsToApprove;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        TimeSheetHeader.SetRange("Approver User ID", UserId);
        if not TimeSheetHeader.IsEmpty() then begin
            Rec.SetRange("Approve ID Filter", UserId);
            Rec.SetRange("User ID Filter", UserId);
            ShowTimeSheetsToApprove := true;
        end else begin
            Rec.SetRange("User ID Filter", UserId);
            ShowTimeSheetsToApprove := false;
        end;
#if not CLEAN22
        TimeSheetV2Enabled := TimeSheetManagement.TimeSheetV2Enabled();
#endif
    end;

    var
        TimeSheetManagement: Codeunit "Time Sheet Management";
#if not CLEAN22
        TimeSheetV2Enabled: Boolean;
#endif
        ShowTimeSheetsToApprove: Boolean;
}

