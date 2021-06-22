page 952 "Manager Time Sheet"
{
    AutoSplitKey = true;
    Caption = 'Manager Time Sheet';
    DataCaptionFields = "Time Sheet No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Navigate,Show,Line';
    SaveValues = true;
    SourceTable = "Time Sheet Line";

    layout
    {
        area(content)
        {
            group(Control26)
            {
                ShowCaption = false;
                field(CurrTimeSheetNo; CurrTimeSheetNo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Time Sheet No';
                    ToolTip = 'Specifies the number of the time sheet.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord;
                        TimeSheetMgt.LookupApproverTimeSheet(CurrTimeSheetNo, Rec, TimeSheetHeader);
                        UpdateControls;
                    end;

                    trigger OnValidate()
                    begin
                        TimeSheetHeader.Reset();
                        TimeSheetMgt.FilterTimeSheets(TimeSheetHeader, TimeSheetHeader.FieldNo("Approver User ID"));
                        TimeSheetMgt.CheckTimeSheetNo(TimeSheetHeader, CurrTimeSheetNo);
                        CurrPage.SaveRecord;
                        TimeSheetMgt.SetTimeSheetNo(CurrTimeSheetNo, Rec);
                        UpdateControls;
                    end;
                }
                field(ResourceNo; TimeSheetHeader."Resource No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource No.';
                    Editable = false;
                    ToolTip = 'Specifies the number for resource.';
                }
                field(ApproverUserID; TimeSheetHeader."Approver User ID")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Approver User ID';
                    Editable = false;
                    ToolTip = 'Specifies the ID of the time sheet approver.';
                }
                field(StartingDate; TimeSheetHeader."Starting Date")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Starting Date';
                    Editable = false;
                    ToolTip = 'Specifies the date from which the report or batch job processes information.';
                }
                field(EndingDate; TimeSheetHeader."Ending Date")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ending Date';
                    Editable = false;
                    ToolTip = 'Specifies the date to which the report or batch job processes information.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the type of time sheet line.';
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the number for the job that is associated with the time sheet line.';
                    Visible = false;
                }
                field("Job Task No."; "Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related job task.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies a description of the time sheet line.';

                    trigger OnAssistEdit()
                    begin
                        ShowLineDetails(true);
                        CurrPage.Update;
                    end;
                }
                field("Cause of Absence Code"; "Cause of Absence Code")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies a list of standard absence codes, from which you may select one.';
                    Visible = false;
                }
                field(Chargeable; Chargeable)
                {
                    ApplicationArea = Jobs;
                    Editable = ChargeableAllowEdit;
                    ToolTip = 'Specifies if the usage that you are posting is chargeable.';
                    Visible = false;
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Editable = WorkTypeCodeAllowEdit;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                    Visible = false;
                }
                field("Service Order No."; "Service Order No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the service order number that is associated with the time sheet line.';
                    Visible = false;
                }
                field("Assembly Order No."; "Assembly Order No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the assembly order number that is associated with the time sheet line.';
                    Visible = false;
                }
                field(Posted; Posted)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a time sheet line has been posted completely.';
                    Visible = false;
                }
                field(Field1; CellData[1])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[1];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field2; CellData[2])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[2];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field3; CellData[3])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[3];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field4; CellData[4])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[4];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field5; CellData[5])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[5];
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                    Width = 6;
                }
                field(Field6; CellData[6])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[6];
                    Editable = false;
                    Visible = false;
                    Width = 6;
                }
                field(Field7; CellData[7])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[7];
                    Editable = false;
                    Visible = false;
                    Width = 6;
                }
                field(Status; Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies information about the status of a time sheet line.';
                }
                field("Total Quantity"; "Total Quantity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    DrillDown = false;
                    ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(TimeSheetStatusFactBox; "Time Sheet Status FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Time Sheet Status';
            }
            part(ActualSchedSummaryFactBox; "Actual/Sched. Summary FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Actual/Scheduled Summary';
                Visible = true;
            }
            part(ActivityDetailsFactBox; "Activity Details FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Activity Details';
                SubPageLink = "Time Sheet No." = FIELD("Time Sheet No."),
                              "Line No." = FIELD("Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Time Sheet")
            {
                Caption = '&Time Sheet';
                Image = Timesheet;
                action(PreviousPeriod)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Previous Period';
                    Image = PreviousSet;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;                    
                    ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                    trigger OnAction()
                    begin
                        FindTimeSheet(SetWanted::Previous);
                    end;
                }
                action(NextPeriod)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Next Period';
                    Image = NextSet;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View information for the next period.';

                    trigger OnAction()
                    begin
                        FindTimeSheet(SetWanted::Next);
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Posting E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posting E&ntries';
                    Image = PostingEntries;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the resource ledger entries that have been posted in connection with the.';

                    trigger OnAction()
                    begin
                        TimeSheetMgt.ShowPostingEntries("Time Sheet No.", "Line No.");
                    end;
                }
                action("Activity &Details")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Activity &Details';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the quantity of hours for each time sheet status.';

                    trigger OnAction()
                    begin
                        ShowLineDetails(true);
                    end;
                }
            }
            group("Co&mments")
            {
                Caption = 'Co&mments';
                Image = ViewComments;
                action(TimeSheetComment2)
                {
                    ApplicationArea = Comments;
                    Caption = '&Time Sheet Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Time Sheet Comment Sheet";
                    RunPageLink = "No." = FIELD("Time Sheet No."),
                                  "Time Sheet Line No." = CONST(0);
                    ToolTip = 'View comments about the time sheet.';
                }
                action(LineComments)
                {
                    ApplicationArea = Comments;
                    Caption = '&Line Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Time Sheet Comment Sheet";
                    RunPageLink = "No." = FIELD("Time Sheet No."),
                                  "Time Sheet Line No." = FIELD("Line No.");
                    ToolTip = 'View or create comments.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Approve)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Approve';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Approve the lines on the time sheet. Choose All to approve all lines. Choose Selected to approve only selected lines.';

                    trigger OnAction()
                    begin
                        ApproveLines;
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Reject to approve the lines on the time sheet. Choose All to reject all lines. Choose Selected to reject only selected lines.';

                    trigger OnAction()
                    begin
                        RejectLines;
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Reopen the time sheet to change it.';

                    trigger OnAction()
                    begin
                        ReopenLine;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord;
    end;

    trigger OnOpenPage()
    begin
        if "Time Sheet No." <> '' then
            CurrTimeSheetNo := "Time Sheet No."
        else
            CurrTimeSheetNo := TimeSheetHeader.FindLastTimeSheetNo(TimeSheetHeader.FieldNo("Approver User ID"));

        TimeSheetMgt.SetTimeSheetNo(CurrTimeSheetNo, Rec);
        UpdateControls;
    end;

    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        ColumnRecords: array[32] of Record Date;
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        NoOfColumns: Integer;
        CellData: array[32] of Decimal;
        ColumnCaption: array[32] of Text[1024];
        CurrTimeSheetNo: Code[20];
        SetWanted: Option Previous,Next;
        WorkTypeCodeAllowEdit: Boolean;
        ChargeableAllowEdit: Boolean;

    procedure SetColumns()
    var
        Calendar: Record Date;
    begin
        Clear(ColumnCaption);
        Clear(ColumnRecords);
        Clear(Calendar);
        Clear(NoOfColumns);

        TimeSheetHeader.Get(CurrTimeSheetNo);
        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");
        if Calendar.FindSet then
            repeat
                NoOfColumns += 1;
                ColumnRecords[NoOfColumns]."Period Start" := Calendar."Period Start";
                ColumnCaption[NoOfColumns] := TimeSheetMgt.FormatDate(Calendar."Period Start", 1);
            until Calendar.Next = 0;
    end;

    local procedure AfterGetCurrentRecord()
    var
        i: Integer;
    begin
        i := 0;
        while i < NoOfColumns do begin
            i := i + 1;
            if ("Line No." <> 0) and TimeSheetDetail.Get(
                 "Time Sheet No.",
                 "Line No.",
                 ColumnRecords[i]."Period Start")
            then
                CellData[i] := TimeSheetDetail.Quantity
            else
                CellData[i] := 0;
        end;
        UpdateFactBoxes;
        WorkTypeCodeAllowEdit := GetAllowEdit(FieldNo("Work Type Code"), true);
        ChargeableAllowEdit := GetAllowEdit(FieldNo(Chargeable), true);
    end;

    local procedure FindTimeSheet(Which: Option)
    begin
        CurrTimeSheetNo := TimeSheetMgt.FindTimeSheet(TimeSheetHeader, Which);
        TimeSheetMgt.SetTimeSheetNo(CurrTimeSheetNo, Rec);
        UpdateControls;
    end;

    local procedure UpdateFactBoxes()
    begin
        CurrPage.ActualSchedSummaryFactBox.PAGE.UpdateData(TimeSheetHeader);
        CurrPage.TimeSheetStatusFactBox.PAGE.UpdateData(TimeSheetHeader);
        if "Line No." = 0 then
            CurrPage.ActivityDetailsFactBox.PAGE.SetEmptyLine;
    end;

    local procedure UpdateControls()
    begin
        SetColumns;
        UpdateFactBoxes;
        CurrPage.Update(false);
    end;

    local procedure Process("Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All")
    var
        TimeSheetLine: Record "Time Sheet Line";
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
        ActionType: Option Approve,Reopen,Reject;
    begin
        CurrPage.SaveRecord;
        case Action of
            Action::"Approve All",
          Action::"Reject All":
                FilterAllLines(TimeSheetLine, ActionType::Approve);
            Action::"Reopen All":
                FilterAllLines(TimeSheetLine, ActionType::Reopen);
            else
                CurrPage.SetSelectionFilter(TimeSheetLine);
        end;
        OnProcessOnAfterTimeSheetLinesFiltered(TimeSheetLine, Action);
        TimeSheetMgt.CopyFilteredTimeSheetLinesToBuffer(TimeSheetLine, TempTimeSheetLine);
        if TimeSheetLine.FindSet then
            repeat
                case Action of
                    Action::"Approve Selected",
                  Action::"Approve All":
                        TimeSheetApprovalMgt.Approve(TimeSheetLine);
                    Action::"Reopen Selected",
                  Action::"Reopen All":
                        TimeSheetApprovalMgt.ReopenApproved(TimeSheetLine);
                    Action::"Reject Selected",
                  Action::"Reject All":
                        TimeSheetApprovalMgt.Reject(TimeSheetLine);
                end;
            until TimeSheetLine.Next = 0;
        OnAfterProcess(TempTimeSheetLine, Action);
        CurrPage.Update(false);
    end;

    local procedure ApproveLines()
    var
        "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All";
        ActionType: Option Approve,Reopen,Reject;
    begin
        case ShowDialog(ActionType::Approve) of
            1:
                Process(Action::"Approve All");
            2:
                Process(Action::"Approve Selected");
        end;
    end;

    local procedure ReopenLine()
    var
        ActionType: Option Approve,Reopen,Reject;
        "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All";
    begin
        case ShowDialog(ActionType::Reopen) of
            1:
                Process(Action::"Reopen All");
            2:
                Process(Action::"Reopen Selected");
        end;
    end;

    local procedure RejectLines()
    var
        ActionType: Option Approve,Reopen,Reject;
        "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All";
    begin
        case ShowDialog(ActionType::Reject) of
            1:
                Process(Action::"Reject All");
            2:
                Process(Action::"Reject Selected");
        end;
    end;

    local procedure GetDialogText(ActionType: Option Approve,Reopen,Reject): Text[100]
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        FilterAllLines(TimeSheetLine, ActionType);
        exit(TimeSheetApprovalMgt.GetManagerTimeSheetDialogText(ActionType, TimeSheetLine.Count));
    end;

    local procedure FilterAllLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Approve,Reopen,Reject)
    begin
        TimeSheetLine.SetRange("Time Sheet No.", CurrTimeSheetNo);
        TimeSheetLine.CopyFilters(Rec);
        TimeSheetLine.FilterGroup(2);
        TimeSheetLine.SetFilter(Type, '<>%1', TimeSheetLine.Type::" ");
        TimeSheetLine.FilterGroup(0);
        case ActionType of
            ActionType::Approve,
          ActionType::Reject:
                TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Submitted);
            ActionType::Reopen:
                TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Approved);
        end;

        OnAfterFilterAllLines(TimeSheetLine, ActionType);
    end;

    local procedure ShowDialog(ActionType: Option Approve,Reopen,Reject): Integer
    begin
        exit(StrMenu(GetDialogText(ActionType), 1, TimeSheetApprovalMgt.GetManagerTimeSheetDialogInstruction(ActionType)));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterAllLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Approve,Reopen,Reject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessOnAfterTimeSheetLinesFiltered(var TimeSheetLine: Record "Time Sheet Line"; "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcess(var TimeSheetLine: Record "Time Sheet Line"; "Action": Option "Approve Selected","Approve All","Reopen Selected","Reopen All","Reject Selected","Reject All")
    begin
    end;
}

