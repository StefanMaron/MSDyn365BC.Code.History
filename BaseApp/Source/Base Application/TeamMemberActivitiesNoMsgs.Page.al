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
                        Caption = 'Open Current Time Sheet';
                        Image = TileBrickCalendar;
                        ToolTip = 'Open the time sheet for the current period.';
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
                field("Open Time Sheets"; Rec."Open Time Sheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Time Sheet List";
                    ToolTip = 'Specifies the number of time sheets that are currently assigned to you and not submitted for approval.';
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
        Reset();
        if not Get() then begin
            Init();
            Insert();
        end;

        TimeSheetHeader.SetRange("Approver User ID", UserId);
        if not TimeSheetHeader.IsEmpty() then begin
            SetRange("Approve ID Filter", UserId);
            SetRange("User ID Filter", UserId);
            ShowTimeSheetsToApprove := true;
        end else begin
            SetRange("User ID Filter", UserId);
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

