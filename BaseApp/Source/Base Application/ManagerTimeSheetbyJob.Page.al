page 954 "Manager Time Sheet by Job"
{
    ApplicationArea = Jobs;
    AutoSplitKey = true;
    Caption = 'Manager Time Sheet by Job';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Navigate,Show';
    SourceTable = "Time Sheet Line";
    SourceTableView = WHERE(Type = CONST(Job));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control10)
            {
                ShowCaption = false;
                field(StartingDate; StartingDate)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Starting Date';
                    Editable = false;
                    ToolTip = 'Specifies the date from which the report or batch job processes information.';
                }
                field(EndingDate; EndingDate)
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
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Editable = WorkTypeCodeAllowEdit;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        TestField(Status, Status::Submitted);
                    end;
                }
                field(Chargeable; Chargeable)
                {
                    ApplicationArea = Jobs;
                    Editable = ChargeableAllowEdit;
                    ToolTip = 'Specifies if the usage that you are posting is chargeable.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        TestField(Status, Status::Submitted);
                    end;
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
                    ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
                    Visible = false;
                }
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
                action("&Previous Period")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Previous Period';
                    Image = PreviousSet;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                    trigger OnAction()
                    begin
                        FindPeriod(SetWanted::Previous);
                    end;
                }
                action("&Next Period")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Next Period';
                    Image = NextSet;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'View information for the next period.';

                    trigger OnAction()
                    begin
                        FindPeriod(SetWanted::Next);
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Time Sheet Comment Sheet";
                    RunPageLink = "No." = FIELD("Time Sheet No."),
                                  "Time Sheet Line No." = FIELD("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Posting E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posting E&ntries';
                    Image = PostingEntries;
                    Promoted = true;
                    PromotedCategory = Category5;
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
                    PromotedCategory = Category5;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the quantity of hours for each time sheet status.';

                    trigger OnAction()
                    begin
                        ShowLineDetails(true);
                    end;
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
                    Image = Approve;
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
                        ReopenLines;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord;
    end;

    trigger OnOpenPage()
    begin
        FindPeriod(SetWanted::Initial);
    end;

    var
        ResourcesSetup: Record "Resources Setup";
        TimeSheetDetail: Record "Time Sheet Detail";
        ColumnRecords: array[32] of Record Date;
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        NoOfColumns: Integer;
        CellData: array[32] of Decimal;
        ColumnCaption: array[32] of Text[1024];
        SetWanted: Option Initial,Previous,Next;
        StartingDate: Date;
        EndingDate: Date;
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

        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", StartingDate, EndingDate);
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
        WorkTypeCodeAllowEdit := GetAllowEdit(FieldNo("Work Type Code"), true);
        ChargeableAllowEdit := GetAllowEdit(FieldNo(Chargeable), true);
    end;

    local procedure FindPeriod(Which: Option Initial,Previous,Next)
    begin
        ResourcesSetup.Get();
        case Which of
            Which::Initial:
                if Date2DWY(WorkDate, 1) = ResourcesSetup."Time Sheet First Weekday" + 1 then
                    StartingDate := WorkDate
                else
                    StartingDate := CalcDate(StrSubstNo('<WD%1-7D>', ResourcesSetup."Time Sheet First Weekday" + 1), WorkDate);
            Which::Previous:
                StartingDate := CalcDate('<-1W>', StartingDate);
            Which::Next:
                StartingDate := CalcDate('<1W>', StartingDate);
        end;
        EndingDate := CalcDate('<1W>', StartingDate) - 1;
        FilterGroup(2);
        SetRange("Time Sheet Starting Date", StartingDate, EndingDate);
        SetRange("Approver ID", UserId);
        FilterGroup(0);
        SetColumns;
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

    local procedure ReopenLines()
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
        TimeSheetLine.CopyFilters(Rec);
        TimeSheetLine.FilterGroup(2);
        TimeSheetLine.SetRange("Time Sheet Starting Date", StartingDate, EndingDate);
        TimeSheetLine.SetRange("Approver ID", UserId);
        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
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

