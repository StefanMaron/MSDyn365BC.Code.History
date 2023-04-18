page 974 "Time Sheet Lines Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Time Sheet Line";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies the type of time sheet line.';

                    trigger OnValidate()
                    begin
                        UpdateControls();
                        CurrPage.Update(true);
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies information about the status of a time sheet line.';
                    Width = 4;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies a description of the time sheet line.';

                    trigger OnAssistEdit()
                    begin
                        if "Line No." = 0 then
                            exit;

                        ShowLineDetails(false);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies the number for the job that is associated with the time sheet line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies the number of the related job task.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Cause of Absence Code"; Rec."Cause of Absence Code")
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies a list of standard absence codes, from which you may select one.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field(Chargeable; Chargeable)
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies if the usage that you are posting is chargeable.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Service Order No."; Rec."Service Order No.")
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies the service order number that is associated with the time sheet line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Assembly Order No."; Rec."Assembly Order No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the assembly order number that is associated with the time sheet line.';
                    Visible = false;
                }
                field(Field1; CellData[1])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[1];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Editable = AllowEdit;
                    Width = 3;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        ValidateQuantity(1);
                    end;
                }
                field(Field2; CellData[2])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[2];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Editable = AllowEdit;
                    Width = 3;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        ValidateQuantity(2);
                    end;
                }
                field(Field3; CellData[3])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[3];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Editable = AllowEdit;
                    Width = 3;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        ValidateQuantity(3);
                    end;
                }
                field(Field4; CellData[4])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[4];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Editable = AllowEdit;
                    Width = 3;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        ValidateQuantity(4);
                    end;
                }
                field(Field5; CellData[5])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[5];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Editable = AllowEdit;
                    Width = 3;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        ValidateQuantity(5);
                    end;
                }
                field(Field6; CellData[6])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[6];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Editable = AllowEdit;
                    Width = 3;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        ValidateQuantity(6);
                    end;
                }
                field(Field7; CellData[7])
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaption[7];
                    ToolTip = 'Specifies the number of hours registered for this day.';
                    DecimalPlaces = 0 : 2;
                    Editable = AllowEdit;
                    Width = 3;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        ValidateQuantity(7);
                    end;
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    DrillDown = false;
                    ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
                    DecimalPlaces = 0 : 2;
                    Width = 3;
                }
            }
            group(GroupTotal)
            {
                ShowCaption = false;
                field(UnitOfMeasureCode; UnitOfMeasureCode)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Unit of Measure';
                    ToolTip = 'Specifies the unit of measure for the time sheet.';
                    Editable = false;
                }
                field(TimeSheetTotalQuantity; GetTimeSheetTotalQuantity())
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total number of hours that are registered on the time sheet.';
                    Editable = false;
                    DecimalPlaces = 0 : 2;
                }
            }
        }

    }

    actions
    {
        area(Processing)
        {
            group(Line)
            {
                action(Submit)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Submit';
                    Image = ReleaseDoc;
                    ShortCutKey = 'F9';
                    ToolTip = 'Submit the time sheet line for approval.';
                    Promoted = true;
                    Scope = Repeater;
                    Gesture = RightSwipe;
                    Enabled = SubmitLineEnabled;
                    Visible = not ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        SubmitLines();
                    end;
                }
                action(ReopenSubmitted)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Reopen';
                    Image = ReOpen;
                    Promoted = true;
                    Scope = Repeater;
                    Gesture = LeftSwipe;
                    ToolTip = 'Reopen the time sheet line, for example, after it has been rejected. The approver of a time sheet has permission to approve, reject, or reopen a time sheet. The approver can also submit a time sheet for approval.';
                    Enabled = ReopenSubmittedLineEnabled;
                    Visible = not ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        ReopenSubmittedLines();
                    end;
                }
                action(Approve)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Approve';
                    Ellipsis = true;
                    Image = ReleaseDoc;
                    ToolTip = 'Approve the lines on the time sheet.';
                    Promoted = true;
                    Scope = Repeater;
                    Gesture = RightSwipe;
                    Enabled = ApproveLineEnabled;
                    Visible = ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        ApproveLines();
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the lines on the time sheet.';
                    Promoted = true;
                    Scope = Repeater;
                    Gesture = RightSwipe;
                    Enabled = RejectLineEnabled;
                    Visible = ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        RejectLines();
                    end;
                }
                action(ReopenApproved)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Reopen';
                    Image = ReOpen;
                    Promoted = true;
                    Scope = Repeater;
                    Gesture = LeftSwipe;
                    ToolTip = 'Reopen the approved or rejected time sheet line.';
                    Enabled = ReopenApprovedLineEnabled;
                    Visible = ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        ReopenApprovedLines();
                    end;
                }
                action("Time Sheet Allocation")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Time Sheet Allocation';
                    Image = Allocate;
                    Promoted = true;
                    ToolTip = 'Allocate posted hours among days of the week on a time sheet.';
                    Enabled = Rec.Posted;

                    trigger OnAction()
                    begin
                        TimeAllocation();
                    end;
                }
                action("Activity &Details")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Activity &Details';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the quantity of hours for each time sheet status.';

                    trigger OnAction()
                    begin
                        ShowLineDetails(false);
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    var
                        DimMgt: Codeunit DimensionManagement;
                    begin
                        "Dimension Set ID" := DimMgt.EditDimensionSet("Dimension Set ID", DimensionCaptionTok);
                    end;
                }
                action(LineComments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    Promoted = true;
                    RunObject = Page "Time Sheet Comment Sheet";
                    RunPageLink = "No." = FIELD("Time Sheet No."),
                                  "Time Sheet Line No." = FIELD("Line No.");
                    Scope = Repeater;
                    ToolTip = 'View or create comments.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    var
        TimeSheetDetail: Record "Time Sheet Detail";
        ColumnRecords: array[32] of Record Date;
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        RefActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject;
        NoOfColumns: Integer;
        CellData: array[32] of Decimal;
        ColumnCaption: array[32] of Text[1024];
        UnitOfMeasureCode: Code[10];
        InvalidTypeErr: Label 'The type of time sheet line cannot be empty.';
        DimensionCaptionTok: Label 'Dimensions';

    protected var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheet: Boolean;
        SubmitLineEnabled: Boolean;
        ReopenSubmittedLineEnabled: Boolean;
        ApproveLineEnabled: Boolean;
        RejectLineEnabled: Boolean;
        ReopenApprovedLineEnabled: Boolean;
        AllowEdit: Boolean;

    procedure SetManagerTimeSheetMode()
    begin
        ManagerTimeSheet := true;
    end;

    procedure SetColumns(TimeSheetNo: Code[20])
    var
        Calendar: Record Date;
    begin
        Clear(ColumnCaption);
        Clear(ColumnRecords);
        Clear(Calendar);
        Clear(NoOfColumns);

        GetTimeSheetHeader(TimeSheetNo);
        TimeSheetHeader.CalcFields("Unit of Measure");
        UnitOfMeasureCode := TimeSheetHeader."Unit of Measure";

        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", TimeSheetHeader."Starting Date", TimeSheetHeader."Ending Date");
        if Calendar.FindSet() then
            repeat
                NoOfColumns += 1;
                ColumnRecords[NoOfColumns]."Period Start" := Calendar."Period Start";
                ColumnCaption[NoOfColumns] := TimeSheetMgt.FormatDate(Calendar."Period Start", 1);
            until Calendar.Next() = 0;
    end;

    local procedure GetTimeSheetHeader(TimeSheetNo: Code[20])
    begin
        TimeSheetHeader.Get(TimeSheetNo);

        OnAfterGetTimeSheetHeader(TimeSheetHeader);
    end;

    local procedure UpdateControls()
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
        AllowEdit := Status in [Status::Open, Status::Rejected];

        SubmitLineEnabled := Status = Status::Open;
        ReopenSubmittedLineEnabled := Status in [Status::Submitted, Status::Rejected];
        ApproveLineEnabled := Status = Status::Submitted;
        RejectLineEnabled := Status = Status::Submitted;
        ReopenApprovedLineEnabled := Status in [Status::Approved, Status::Rejected];
    end;

    local procedure ValidateQuantity(ColumnNo: Integer)
    begin
        if (CellData[ColumnNo] <> 0) and (Type = Type::" ") then
            Error(InvalidTypeErr);

        if TimeSheetDetail.Get(
             "Time Sheet No.",
             "Line No.",
             ColumnRecords[ColumnNo]."Period Start")
        then begin
            if CellData[ColumnNo] <> TimeSheetDetail.Quantity then
                TestTimeSheetLineStatus();

            if CellData[ColumnNo] = 0 then
                TimeSheetDetail.Delete()
            else begin
                TimeSheetDetail.Quantity := CellData[ColumnNo];
                TimeSheetDetail.Modify(true);
            end;
        end else
            if CellData[ColumnNo] <> 0 then begin
                TestTimeSheetLineStatus();

                TimeSheetDetail.Init();
                TimeSheetDetail.CopyFromTimeSheetLine(Rec);
                TimeSheetDetail.Date := ColumnRecords[ColumnNo]."Period Start";
                TimeSheetDetail.Quantity := CellData[ColumnNo];
                TimeSheetDetail.Insert(true);
            end;

        CalcFields("Total Quantity");
        CurrPage.Update(false);
    end;

    local procedure GetTimeSheetTotalQuantity(): Decimal
    begin
        TimeSheetHeader.Get("Time Sheet No.");
        TimeSheetHeader.CalcFields(Quantity);
        exit(TimeSheetHeader.Quantity);
    end;

    procedure Process(ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject; ProcessAll: Boolean)
    var
        TimeSheetLine: Record "Time Sheet Line";
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
    begin
        CurrPage.SaveRecord();
        FilterLines(TimeSheetLine, ActionType, ProcessAll);
        TimeSheetMgt.CopyFilteredTimeSheetLinesToBuffer(TimeSheetLine, TempTimeSheetLine);
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetApprovalMgt.ProcessAction(TimeSheetLine, ActionType);
            until TimeSheetLine.Next() = 0;
        OnAfterProcess(TempTimeSheetLine, ActionType, ProcessAll);
        CurrPage.Update(true);
    end;

    local procedure FilterLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject; ProcessAll: Boolean)
    begin
        if not ProcessAll then
            CurrPage.SetSelectionFilter(TimeSheetLine)
        else
            FilterAllLines(TimeSheetLine, ActionType);
        OnAfterFilterLines(TimeSheetLine, ActionType, ProcessAll);
    end;

    local procedure TestTimeSheetLineStatus()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetLine.Get("Time Sheet No.", "Line No.");
        TimeSheetLine.TestStatus();
    end;

    local procedure SubmitLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubmitLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsPhone() then
            TimeSheetApprovalMgt.SubmitIfConfirmed(Rec)
        else
            case ShowDialog(RefActionType::Submit) of
                1:
                    Process(RefActionType::Submit, true);
                2:
                    Process(RefActionType::Submit, false);
            end;
    end;

    local procedure ApproveLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApproveLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsPhone() then
            TimeSheetApprovalMgt.ApproveIfConfirmed(Rec)
        else
            case ShowDialog(RefActionType::Approve) of
                1:
                    Process(RefActionType::Approve, true);
                2:
                    Process(RefActionType::Approve, false);
            end;
    end;

    local procedure RejectLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRejectLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsPhone() then
            TimeSheetApprovalMgt.RejectIfConfirmed(Rec)
        else
            case ShowDialog(RefActionType::Reject) of
                1:
                    Process(RefActionType::Reject, true);
                2:
                    Process(RefActionType::Reject, false);
            end;
    end;

    local procedure ReopenSubmittedLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopenSubmittedLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsPhone() then
            TimeSheetApprovalMgt.ReopenSubmittedIfConfirmed(Rec)
        else
            case ShowDialog(RefActionType::ReopenSubmitted) of
                1:
                    Process(RefActionType::ReopenSubmitted, true);
                2:
                    Process(RefActionType::ReopenSubmitted, false);
            end;
    end;

    local procedure ReopenApprovedLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopenApprovedLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsPhone() then
            TimeSheetApprovalMgt.ReopenApprovedIfConfirmed(Rec)
        else
            case ShowDialog(RefActionType::ReopenApproved) of
                1:
                    Process(RefActionType::ReopenApproved, true);
                2:
                    Process(RefActionType::ReopenApproved, false);
            end;
    end;

    local procedure TimeAllocation()
    var
        TimeSheetAllocation: Page "Time Sheet Allocation";
        AllocatedQty: array[7] of Decimal;
    begin
        TestField(Posted, true);
        CalcFields("Total Quantity");
        TimeSheetAllocation.InitParameters("Time Sheet No.", "Line No.", "Total Quantity");
        if TimeSheetAllocation.RunModal() = ACTION::OK then begin
            TimeSheetAllocation.GetAllocation(AllocatedQty);
            TimeSheetMgt.UpdateTimeAllocation(Rec, AllocatedQty);
        end;
    end;

    local procedure GetDialogText(ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject): Text
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        FilterAllLines(TimeSheetLine, ActionType);
        exit(TimeSheetApprovalMgt.GetCommonTimeSheetDialogText(ActionType, TimeSheetLine.Count));
    end;

    local procedure FilterAllLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
        TimeSheetLine.CopyFilters(Rec);
        TimeSheetMgt.FilterAllTimeSheetLines(TimeSheetLine, ActionType);
    end;

    local procedure IsPhone(): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        exit(ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone);
    end;

    local procedure ShowDialog(ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject): Integer
    begin
        exit(StrMenu(GetDialogText(ActionType), 1, TimeSheetApprovalMgt.GetCommonTimeSheetDialogInstruction(ActionType)));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTimeSheetHeader(var TimeSheetHeader: Record "Time Sheet Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject; ProcessAll: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterProcess(var TimeSheetLine: Record "Time Sheet Line"; "Action": Option "Submit Selected","Submit All","Reopen Selected","Reopen All"; ProcessAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenSubmittedLines(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenApprovedLines(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSubmitLines(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApproveLines(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRejectLines(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean);
    begin
    end;
}