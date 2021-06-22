codeunit 951 "Time Sheet Approval Management"
{
    Permissions = TableData Employee = r;

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'There is nothing to submit for line with %1=%2, %3=%4.', Comment = 'There is nothing to submit for line with Time Sheet No.=10, Line No.=10000.';
        Text002: Label 'You are not authorized to approve time sheet lines. Contact your time sheet administrator.';
        Text003: Label 'Time sheet line cannot be reopened because there are linked service lines.';
        Text004: Label '&All open lines [%1 line(s)],&Selected line(s) only';
        Text005: Label '&All submitted lines [%1 line(s)],&Selected line(s) only';
        Text006: Label '&All approved lines [%1 line(s)],&Selected line(s) only';
        Text007: Label 'Submit for approval';
        Text008: Label 'Reopen for editing';
        Text009: Label 'Approve for posting';
        Text010: Label 'Reject for correction';

    procedure Submit(var TimeSheetLine: Record "Time Sheet Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubmit(TimeSheetLine, IsHandled);
        if isHandled then
            exit;

        with TimeSheetLine do begin
            if Status = Status::Submitted then
                exit;
            if Type = Type::" " then
                FieldError(Type);
            TestStatus;
            CalcFields("Total Quantity");
            if "Total Quantity" = 0 then
                Error(
                  Text001, FieldCaption("Time Sheet No."), "Time Sheet No.", FieldCaption("Line No."), "Line No.");
            case Type of
                Type::Job:
                    begin
                        TestField("Job No.");
                        TestField("Job Task No.");
                    end;
                Type::Absence:
                    TestField("Cause of Absence Code");
                Type::Service:
                    TestField("Service Order No.");
            end;
            UpdateApproverID;
            Status := Status::Submitted;
            OnSubmitOnBeforeTimeSheetLineModify(TimeSheetLine);
            Modify(true);
            OnAfterSubmit(TimeSheetLine);
        end;
    end;

    procedure ReopenSubmitted(var TimeSheetLine: Record "Time Sheet Line")
    begin
        with TimeSheetLine do begin
            if Status = Status::Open then
                exit;
            TestField(Status, Status::Submitted);
            Status := Status::Open;
            Modify(true);
            OnReopenSubmittedOnAfterModify(TimeSheetLine);

            OnAfterReopenSubmitted(TimeSheetLine);
        end;
    end;

    procedure ReopenApproved(var TimeSheetLine: Record "Time Sheet Line")
    begin
        with TimeSheetLine do begin
            if Status = Status::Submitted then
                exit;
            TestField(Status, Status::Approved);
            TestField(Posted, false);
            CheckApproverPermissions(TimeSheetLine);
            CheckLinkedServiceDoc(TimeSheetLine);
            UpdateApproverID;
            Status := Status::Submitted;
            OnReopenApprovedOnBeforeTimeSheetLineModify(TimeSheetLine);
            Modify(true);

            OnAfterReopenApproved(TimeSheetLine);
        end;
    end;

    procedure Reject(var TimeSheetLine: Record "Time Sheet Line")
    begin
        with TimeSheetLine do begin
            if Status = Status::Rejected then
                exit;
            TestField(Status, Status::Submitted);
            CheckApproverPermissions(TimeSheetLine);
            Status := Status::Rejected;
            OnRejectOnBeforeTimeSheetLineModify(TimeSheetLine);
            Modify(true);
        end;

        OnAfterReject(TimeSheetLine);
    end;

    procedure Approve(var TimeSheetLine: Record "Time Sheet Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApprove(TimeSheetLine, IsHandled);
        if IsHandled then
            exit;

        with TimeSheetLine do begin
            if Status = Status::Approved then
                exit;
            TestField(Status, Status::Submitted);
            CheckApproverPermissions(TimeSheetLine);
            Status := Status::Approved;
            "Approved By" := UserId;
            "Approval Date" := Today;
            OnApproveOnBeforeTimeSheetLineModify(TimeSheetLine);
            Modify(true);
            case Type of
                Type::Absence:
                    PostAbsence(TimeSheetLine);
                Type::Service:
                    AfterApproveServiceOrderTmeSheetEntries(TimeSheetLine);
            end;
        end;

        OnAfterApprove(TimeSheetLine);
    end;

    local procedure PostAbsence(var TimeSheetLine: Record "Time Sheet Line")
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        TimeSheetHeader.Get(TimeSheetLine."Time Sheet No.");
        Resource.Get(TimeSheetHeader."Resource No.");
        Employee.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        Employee.FindFirst;
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        if TimeSheetDetail.FindSet(true) then
            repeat
                EmployeeAbsence.Init();
                EmployeeAbsence.Validate("Employee No.", Employee."No.");
                EmployeeAbsence.Validate("From Date", TimeSheetDetail.Date);
                EmployeeAbsence.Validate("Cause of Absence Code", TimeSheetDetail."Cause of Absence Code");
                EmployeeAbsence.Validate("Unit of Measure Code", Resource."Base Unit of Measure");
                EmployeeAbsence.Validate(Quantity, TimeSheetDetail.Quantity);
                OnBeforeInsertEmployeeAbsence(EmployeeAbsence, TimeSheetLine, TimeSheetDetail);
                EmployeeAbsence.Insert(true);

                TimeSheetDetail.Posted := true;
                TimeSheetDetail.Modify();
                TimeSheetMgt.CreateTSPostingEntry(
                  TimeSheetDetail,
                  TimeSheetDetail.Quantity,
                  TimeSheetDetail.Date,
                  '',
                  TimeSheetLine.Description);
            until TimeSheetDetail.Next = 0;

        TimeSheetLine.Posted := true;
        TimeSheetLine.Modify();
    end;

    local procedure CheckApproverPermissions(TimeSheetLine: Record "Time Sheet Line")
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(UserId);
        if not UserSetup."Time Sheet Admin." then begin
            if TimeSheetLine."Approver ID" <> UpperCase(UserId) then
                Error(Text002);
        end;
    end;

    local procedure CheckLinkedServiceDoc(TimeSheetLine: Record "Time Sheet Line")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", TimeSheetLine."Service Order No.");
        ServiceLine.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        ServiceLine.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        if not ServiceLine.IsEmpty then
            Error(Text003);
    end;

    procedure GetTimeSheetDialogText(ActionType: Option Submit,Reopen; LinesQty: Integer): Text[100]
    var
        IsHandled: Boolean;
        ReturnText: Text[100];
    begin
        IsHandled := false;
        OnBeforeGetTimeSheetDialogText(ActionType, LinesQty, ReturnText, IsHandled);
        if IsHandled then
            exit(ReturnText);

        case ActionType of
            ActionType::Submit:
                exit(StrSubstNo(Text004, LinesQty));
            ActionType::Reopen:
                exit(StrSubstNo(Text005, LinesQty));
        end;
    end;

    procedure GetManagerTimeSheetDialogText(ActionType: Option Approve,Reopen,Reject; LinesQty: Integer): Text[100]
    var
        IsHandled: Boolean;
        ReturnText: Text[100];
    begin
        IsHandled := false;
        OnBeforeGetManagerTimeSheetDialogText(ActionType, LinesQty, ReturnText, IsHandled);
        if IsHandled then
            exit(ReturnText);

        case ActionType of
            ActionType::Approve,
          ActionType::Reject:
                exit(StrSubstNo(Text005, LinesQty));
            ActionType::Reopen:
                exit(StrSubstNo(Text006, LinesQty));
        end;
    end;

    procedure GetTimeSheetDialogInstruction(ActionType: Option Submit,Reopen): Text[100]
    begin
        case ActionType of
            ActionType::Submit:
                exit(Text007);
            ActionType::Reopen:
                exit(Text008);
        end;
    end;

    procedure GetManagerTimeSheetDialogInstruction(ActionType: Option Approve,Reopen,Reject): Text[100]
    begin
        case ActionType of
            ActionType::Approve:
                exit(Text009);
            ActionType::Reject:
                exit(Text010);
            ActionType::Reopen:
                exit(Text008);
        end;
    end;

    local procedure AfterApproveServiceOrderTmeSheetEntries(var TimeSheetLine: Record "Time Sheet Line")
    var
        ServHeader: Record "Service Header";
        ServMgtSetup: Record "Service Mgt. Setup";
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        if ServMgtSetup.Get and ServMgtSetup."Copy Time Sheet to Order" then begin
            ServHeader.Get(ServHeader."Document Type"::Order, TimeSheetLine."Service Order No.");
            TimeSheetMgt.CreateServDocLinesFromTSLine(ServHeader, TimeSheetLine);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEmployeeAbsence(var EmployeeAbsence: Record "Employee Absence"; TimeSheetLine: Record "Time Sheet Line"; var TimeSheetDetail: Record "Time Sheet Detail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSubmit(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenSubmitted(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenApproved(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReject(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApprove(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApproveOnBeforeTimeSheetLineModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRejectOnBeforeTimeSheetLineModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenApprovedOnBeforeTimeSheetLineModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenSubmittedOnAfterModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSubmitOnBeforeTimeSheetLineModify(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApprove(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSubmit(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTimeSheetDialogText(ActionType: Option; LinesQty: Decimal; var ReturnText: text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetManagerTimeSheetDialogText(ActionType: Option; LinesQty: Decimal; var ReturnText: text[100]; var IsHandled: Boolean)
    begin
    end;
}

