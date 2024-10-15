codeunit 17387 "Absence Order-Post"
{
    Permissions = TableData "Posted Absence Header" = rimd,
                  TableData "Posted Absence Line" = rimd,
                  TableData "Employee Absence Entry" = rimd,
                  TableData "Employee Ledger Entry" = rimd;
    TableNo = "Absence Header";

    trigger OnRun()
    var
        PayrollPeriodFrom: Record "Payroll Period";
        PayrollPeriodTo: Record "Payroll Period";
        RecordLinkManagement: Codeunit "Record Link Management";
        WagePeriodCode: Code[10];
    begin
        ClearAll;
        HRSetup.Get();
        HRSetup.TestField("Change Vacation Accr. By Doc");
        AbsenceHeader := Rec;
        with AbsenceHeader do begin
            TestField("Employee No.");
            TestField("Posting Date");
            CalcFields("Start Date", "End Date", "Calendar Days");

            CheckDim;

            Window.Open(
              '#1#################################\\' +
              Text000);

            Window.Update(1, StrSubstNo('%1 %2', TableCaption, "No."));

            if Status = Status::Open then
                CODEUNIT.Run(CODEUNIT::"Release Absence Order", AbsenceHeader);

            AbsenceLine.LockTable();
            LockTable();
            EmplAbsenceEntry.LockTable();

            SourceCodeSetup.Get();
            case "Document Type" of
                "Document Type"::Vacation:
                    SourceCodeSetup.TestField("Vacation Order");
                "Document Type"::"Sick Leave":
                    SourceCodeSetup.TestField("Sick Leave Order");
                "Document Type"::Travel:
                    SourceCodeSetup.TestField("Travel Order");
                "Document Type"::"Other Absence":
                    SourceCodeSetup.TestField("Other Absence Order");
            end;

            if EmplAbsenceEntry.FindLast then
                NextEntryNo := EmplAbsenceEntry."Entry No."
            else
                NextEntryNo := 0;

            // Insert posted absence header
            PostedAbsenceHeader.LockTable();
            PostedAbsenceHeader.Init();
            PostedAbsenceHeader.TransferFields(AbsenceHeader);
            PostedAbsenceHeader.Insert();

            CopyCommentLines("No.", PostedAbsenceHeader."No.", false);
            RecordLinkManagement.CopyLinks(Rec, PostedAbsenceHeader);

            // Lines
            PostedAbsenceLine.LockTable();

            LineCount := 0;
            AbsenceLine.Reset();
            AbsenceLine.SetRange("Document Type", "Document Type");
            AbsenceLine.SetRange("Document No.", "No.");
            if AbsenceLine.FindSet then
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);
                    PayrollElement.Get(AbsenceLine."Element Code");
                    Employee.Get(AbsenceLine."Employee No.");

                    // insert posted lines
                    PostedAbsenceLine.Init();
                    PostedAbsenceLine.TransferFields(AbsenceLine);
                    PostedAbsenceLine.Insert();

                    ApplyEmplAbsenceEntry(AbsenceLine);

                    CheckVacationPeriodExpand(AbsenceLine);

                    // Insert and post employee journal lines by periods
                    PayrollPeriod.CheckPeriodExistence(AbsenceLine."Start Date");
                    PayrollPeriod.CheckPeriodExistence(AbsenceLine."End Date");
                    PayrollPeriodFrom.Get(PayrollPeriod.PeriodByDate(AbsenceLine."Start Date"));
                    PayrollPeriodTo.Get(PayrollPeriod.PeriodByDate(AbsenceLine."End Date"));

                    if PayrollElement."Distribute by Periods" then begin
                        FirstEntryNo := 0;
                        PayrollPeriod.Reset();
                        PayrollPeriod.SetRange(Code, PayrollPeriodFrom.Code, PayrollPeriodTo.Code);
                        if PayrollPeriod.FindSet then
                            repeat
                                AbsenceLine2 := AbsenceLine;
                                if PayrollPeriodFrom.Code <> PayrollPeriodTo.Code then
                                    case PayrollPeriod.Code of
                                        PayrollPeriodFrom.Code:
                                            begin
                                                AbsenceLine2."Start Date" := AbsenceLine."Start Date";
                                                AbsenceLine2."End Date" := PayrollPeriodFrom."Ending Date";
                                            end;
                                        PayrollPeriodTo.Code:
                                            begin
                                                AbsenceLine2."Start Date" := PayrollPeriodTo."Starting Date";
                                                AbsenceLine2."End Date" := AbsenceLine."End Date";
                                            end;
                                        else begin
                                                AbsenceLine2."Start Date" := PayrollPeriod."Starting Date";
                                                AbsenceLine2."End Date" := PayrollPeriod."Ending Date";
                                            end;
                                    end
                                else begin
                                    AbsenceLine2."Start Date" := AbsenceLine."Start Date";
                                    AbsenceLine2."End Date" := AbsenceLine."End Date";
                                end;
                                WagePeriodCode := PayrollPeriod.PeriodByDate(AbsenceLine2."End Date");

                                if not AbsenceLine2.Terminated then
                                    AbsenceLine2.CalcDays
                                else
                                    AbsenceLine2."Calendar Days" :=
                                      CalendarMgt.GetPeriodInfo(
                                        Employee."Calendar Code", AbsenceLine2."Start Date", AbsenceLine2."End Date", 1);

                                case "Document Type" of
                                    "Document Type"::Vacation:
                                        InsertEmplJnlLine(
                                          WagePeriodCode,
                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                          AbsenceLine2."Calendar Days",
                                          AbsenceLine2."Payment Days", AbsenceLine2."Payment Percent", 0);
                                    "Document Type"::"Sick Leave":
                                        begin
                                            if AbsenceLine."Days Paid by Employer" +
                                               AbsenceLine."Payment Days" + AbsenceLine."Special Payment Days" +
                                               AbsenceLine."Days Not Paid" <> 0
                                            then begin
                                                if AbsenceLine."Days Paid by Employer" > 0 then
                                                    if AbsenceLine."Days Paid by Employer" >= AbsenceLine2."Calendar Days" then begin
                                                        AbsenceLine2."End Date" :=
                                                          NextCalEndDate(AbsenceLine2."Start Date", AbsenceLine2."Calendar Days" - 1);
                                                        InsertEmplJnlLine(
                                                          WagePeriodCode,
                                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                                          AbsenceLine2."Calendar Days",
                                                          AbsenceLine2."Calendar Days", AbsenceLine."Payment Percent", 0);
                                                        AbsenceLine."Days Paid by Employer" -= AbsenceLine2."Calendar Days";
                                                        AbsenceLine2."Calendar Days" := 0;
                                                        AbsenceLine2."Start Date" := NextCalEndDate(AbsenceLine2."End Date", 1);
                                                    end else begin
                                                        AbsenceLine2."End Date" :=
                                                          NextCalEndDate(AbsenceLine2."Start Date", AbsenceLine."Days Paid by Employer" - 1);
                                                        InsertEmplJnlLine(
                                                          WagePeriodCode,
                                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                                          AbsenceLine."Days Paid by Employer",
                                                          AbsenceLine."Days Paid by Employer", AbsenceLine."Payment Percent", 0);
                                                        AbsenceLine2."Calendar Days" -= AbsenceLine."Days Paid by Employer";
                                                        AbsenceLine."Days Paid by Employer" := 0;
                                                        AbsenceLine2."Start Date" := NextCalEndDate(AbsenceLine2."End Date", 1);
                                                    end;
                                                if (AbsenceLine2."Calendar Days" > 0) and (AbsenceLine."Payment Days" > 0) then
                                                    if AbsenceLine."Payment Days" >= AbsenceLine2."Calendar Days" then begin
                                                        AbsenceLine2."End Date" :=
                                                          NextCalEndDate(AbsenceLine2."Start Date", AbsenceLine2."Calendar Days" - 1);
                                                        InsertEmplJnlLine(
                                                          WagePeriodCode,
                                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                                          AbsenceLine2."Calendar Days",
                                                          AbsenceLine2."Calendar Days", AbsenceLine."Payment Percent", 1);
                                                        AbsenceLine."Payment Days" -= AbsenceLine2."Calendar Days";
                                                        AbsenceLine2."Calendar Days" := 0;
                                                        AbsenceLine2."Start Date" := NextCalEndDate(AbsenceLine2."End Date", 1);
                                                    end else begin
                                                        AbsenceLine2."End Date" :=
                                                          NextCalEndDate(AbsenceLine2."Start Date", AbsenceLine2."Payment Days" - 1);
                                                        InsertEmplJnlLine(
                                                          WagePeriodCode,
                                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                                          AbsenceLine."Payment Days",
                                                          AbsenceLine."Payment Days", AbsenceLine."Payment Percent", 1);
                                                        AbsenceLine2."Calendar Days" -= AbsenceLine."Payment Days";
                                                        AbsenceLine."Payment Days" := 0;
                                                        AbsenceLine2."Start Date" := NextCalEndDate(AbsenceLine2."End Date", 1);
                                                    end;
                                                if (AbsenceLine2."Calendar Days" > 0) and (AbsenceLine."Special Payment Days" > 0) then
                                                    if AbsenceLine."Special Payment Days" >= AbsenceLine2."Calendar Days" then begin
                                                        AbsenceLine2."End Date" :=
                                                          NextCalEndDate(AbsenceLine2."Start Date", AbsenceLine2."Calendar Days" - 1);
                                                        InsertEmplJnlLine(
                                                          WagePeriodCode,
                                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                                          AbsenceLine2."Calendar Days",
                                                          AbsenceLine2."Calendar Days", AbsenceLine."Special Payment Percent", 1);
                                                        AbsenceLine."Special Payment Days" -= AbsenceLine2."Calendar Days";
                                                        AbsenceLine2."Calendar Days" := 0;
                                                        AbsenceLine2."Start Date" := NextCalEndDate(AbsenceLine2."End Date", 1);
                                                    end else begin
                                                        AbsenceLine2."End Date" :=
                                                          NextCalEndDate(AbsenceLine2."Start Date", AbsenceLine2."Special Payment Days" - 1);
                                                        InsertEmplJnlLine(
                                                          WagePeriodCode,
                                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                                          AbsenceLine."Special Payment Days",
                                                          AbsenceLine."Special Payment Days", AbsenceLine."Special Payment Percent", 1);
                                                        AbsenceLine2."Calendar Days" -= AbsenceLine."Special Payment Days";
                                                        AbsenceLine."Special Payment Days" := 0;
                                                        AbsenceLine2."Start Date" := NextCalEndDate(AbsenceLine2."End Date", 1);
                                                    end;
                                                if AbsenceLine."Days Not Paid" > 0 then begin
                                                    if AbsenceLine."Days Not Paid" > AbsenceLine2."Calendar Days" then begin
                                                        AbsenceLine2."End Date" := PayrollPeriod."Ending Date";
                                                        AbsenceLine2."Days Not Paid" := AbsenceLine2."Calendar Days";
                                                    end else
                                                        AbsenceLine2."End Date" :=
                                                          NextCalEndDate(AbsenceLine2."Start Date", AbsenceLine2."Days Not Paid" - 1);
                                                    if AbsenceLine2."Days Not Paid" <> 0 then begin
                                                        InsertEmplJnlLine(
                                                          WagePeriodCode,
                                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                                          AbsenceLine2."Days Not Paid",
                                                          AbsenceLine2."Calendar Days", 0, 1);
                                                        AbsenceLine."Days Not Paid" -= AbsenceLine2."Days Not Paid";
                                                    end;
                                                end;
                                            end else
                                                if not AbsenceLine2.Terminated then
                                                    TimesheetMgt.CreateFromLine(
                                                      AbsenceLine2."Employee No.", AbsenceLine2."Time Activity Code",
                                                      AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                                      "Document Type", "No.", "Document Date");
                                        end;
                                    "Document Type"::Travel:
                                        InsertEmplJnlLine(
                                          WagePeriodCode,
                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                          AbsenceLine2."Working Days",
                                          AbsenceLine2."Payment Days", AbsenceLine2."Payment Percent", 0);
                                    "Document Type"::"Other Absence":
                                        InsertEmplJnlLine(
                                          WagePeriodCode,
                                          AbsenceLine2."Start Date", AbsenceLine2."End Date",
                                          AbsenceLine2."Calendar Days",
                                          AbsenceLine2."Payment Days", AbsenceLine2."Payment Percent", 0);
                                end;
                            until PayrollPeriod.Next = 0;
                    end else
                        case "Document Type" of
                            "Document Type"::Vacation,
                          "Document Type"::"Sick Leave",
                          "Document Type"::"Other Absence":
                                InsertEmplJnlLine(
                                  "Period Code",
                                  AbsenceLine."Start Date", AbsenceLine."End Date",
                                  AbsenceLine."Calendar Days",
                                  AbsenceLine."Payment Days", AbsenceLine."Payment Percent", 0);
                            "Document Type"::Travel:
                                InsertEmplJnlLine(
                                  "Period Code",
                                  AbsenceLine."Start Date", AbsenceLine."End Date",
                                  AbsenceLine."Working Days",
                                  AbsenceLine."Payment Days", AbsenceLine."Payment Percent", 0);
                        end;

                    // Update vacation request
                    if VacationRequest.Get(AbsenceLine."Vacation Request No.") then
                        VacationRequest.MarkUsed;

                until AbsenceLine.Next = 0;

            // Delete posted order
            AbsenceLine.DeleteAll();
            Delete;

            Commit();
        end;
    end;

    var
        HRSetup: Record "Human Resources Setup";
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
        AbsenceLine2: Record "Absence Line";
        PostedAbsenceHeader: Record "Posted Absence Header";
        PostedAbsenceLine: Record "Posted Absence Line";
        VacationRequest: Record "Vacation Request";
        EmplAbsenceEntry: Record "Employee Absence Entry";
        Text000: Label 'Posting              #2######';
        SourceCodeSetup: Record "Source Code Setup";
        HROrderComment: Record "HR Order Comment Line";
        PayrollPeriod: Record "Payroll Period";
        PayrollElement: Record "Payroll Element";
        TimeActivityGroup: Record "Time Activity Group";
        Employee: Record Employee;
        EmplJnlPostLine: Codeunit "Employee Journal - Post Line";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        CalendarMgt: Codeunit "Payroll Calendar Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        LineCount: Integer;
        NextEntryNo: Integer;
        FirstEntryNo: Integer;
        Text028: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text029: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked. %4';
        Text030: Label 'The dimensions used in %1 %2 are invalid. %3';
        Text031: Label 'The dimensions used in %1 %2, line no. %3 are invalid. %4';

    [Scope('OnPrem')]
    procedure InsertEmplJnlLine(WagePeriodCode: Code[10]; StartDate: Date; EndDate: Date; CalendarDays: Decimal; PaymentDays: Decimal; PaymentPercent: Decimal; PaymentSource: Option Employer,FSI)
    var
        EmplJnlLine: Record "Employee Journal Line";
        EntryNo: Integer;
    begin
        EmplJnlLine.Init();
        EmplJnlLine."Document Type" := AbsenceLine."Document Type" + 1;
        EmplJnlLine.Validate("Employee No.", AbsenceHeader."Employee No.");
        EmplJnlLine.Validate("Time Activity Code", AbsenceLine."Time Activity Code");
        EmplJnlLine.Validate("Element Code", AbsenceLine."Element Code");
        EmplJnlLine."Posting Date" := AbsenceHeader."Posting Date";
        EmplJnlLine."Vacation Type" := AbsenceLine."Vacation Type";
        EmplJnlLine."Sick Leave Type" := AbsenceLine."Sick Leave Type";
        if EmplJnlLine."Sick Leave Type" in
           [EmplJnlLine."Sick Leave Type"::"Child Care 1.5 years",
            EmplJnlLine."Sick Leave Type"::"Child Care 3 years"]
        then
            EmplJnlLine."Period Code" := WagePeriodCode
        else
            EmplJnlLine."Period Code" := AbsenceHeader."Period Code";
        if AbsenceLine."Previous Document No." = '' then
            EmplJnlLine.Quantity := 1
        else
            EmplJnlLine.Quantity := 0;
        EmplJnlLine."Payment Days" := PaymentDays;
        EmplJnlLine."Payment Percent" := PaymentPercent;
        if AbsenceHeader."Document Type" = AbsenceHeader."Document Type"::"Sick Leave" then begin
            EmplJnlLine."Payment Source" := PaymentSource;
            EmplJnlLine."Relative Person No." := AbsenceLine."Relative Person No.";
            EmplJnlLine."Child Grant Type" := AbsenceLine."Child Grant Type";
        end;
        EmplJnlLine."Starting Date" := StartDate;
        EmplJnlLine."Ending Date" := EndDate;
        EmplJnlLine."Wage Period From" := WagePeriodCode;
        EmplJnlLine."Wage Period To" := WagePeriodCode;

        EmplJnlLine."AE Period From" := AbsenceLine."AE Period From";
        EmplJnlLine."AE Period To" := AbsenceLine."AE Period To";
        EmplJnlLine."Document No." := AbsenceHeader."No.";
        EmplJnlLine."Document Date" := AbsenceHeader."Document Date";
        EmplJnlLine."HR Order No." := AbsenceHeader."HR Order No.";
        EmplJnlLine."HR Order Date" := AbsenceHeader."HR Order Date";
        EmplJnlLine.Description := AbsenceLine.Description;
        EmplJnlLine."Reason Code" := AbsenceHeader."Reason Code";
        EmplJnlLine.Terminated := AbsenceLine.Terminated;
        case AbsenceHeader."Document Type" of
            AbsenceHeader."Document Type"::Vacation:
                EmplJnlLine."Source Code" := SourceCodeSetup."Vacation Order";
            AbsenceHeader."Document Type"::"Sick Leave":
                EmplJnlLine."Source Code" := SourceCodeSetup."Sick Leave Order";
            AbsenceHeader."Document Type"::Travel:
                EmplJnlLine."Source Code" := SourceCodeSetup."Travel Order";
            AbsenceHeader."Document Type"::"Other Absence":
                EmplJnlLine."Source Code" := SourceCodeSetup."Other Absence Order";
        end;
        EmplJnlLine."Dimension Set ID" := AbsenceLine."Dimension Set ID";
        if FirstEntryNo <> 0 then begin
            EmplJnlLine."Applies-to Entry" := FirstEntryNo;
            EmplJnlLine.Quantity := 0;
            EmplJnlPostLine.RunWithCheck(EmplJnlLine);
        end else begin
            EntryNo := EmplJnlPostLine.RunWithCheck(EmplJnlLine);
            FirstEntryNo := EntryNo;
        end;
    end;

    local procedure CheckDim()
    begin
        AbsenceLine2."Line No." := 0;
        CheckDimValuePosting(AbsenceLine2);
        CheckDimComb(AbsenceLine2);

        AbsenceLine2.SetRange("Document Type", AbsenceHeader."Document Type");
        AbsenceLine2.SetRange("Document No.", AbsenceHeader."No.");
        if AbsenceLine2.FindSet then
            repeat
                CheckDimComb(AbsenceLine2);
                CheckDimValuePosting(AbsenceLine2);
            until AbsenceLine2.Next = 0;
    end;

    local procedure CheckDimComb(AbsenceLine: Record "Absence Line")
    begin
        if AbsenceLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(AbsenceHeader."Dimension Set ID") then
                Error(
                  Text028,
                  AbsenceHeader."Document Type", AbsenceHeader."No.", DimMgt.GetDimCombErr);

        if AbsenceLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(AbsenceLine."Dimension Set ID") then
                Error(
                  Text029,
                  AbsenceHeader."Document Type", AbsenceHeader."No.", AbsenceLine."Line No.", DimMgt.GetDimCombErr);
    end;

    local procedure CheckDimValuePosting(var AbsenceLine2: Record "Absence Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        if AbsenceLine2."Line No." = 0 then begin
            TableIDArr[1] := DATABASE::Employee;
            NumberArr[1] := AbsenceHeader."Employee No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, AbsenceHeader."Dimension Set ID") then
                Error(
                  Text030,
                  AbsenceHeader."Document Type", AbsenceHeader."No.", DimMgt.GetDimValuePostingErr);
        end else begin
            TableIDArr[1] := DATABASE::Employee;
            NumberArr[1] := AbsenceLine2."Employee No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, AbsenceLine2."Dimension Set ID") then
                Error(
                  Text031,
                  AbsenceHeader."Document Type", AbsenceHeader."No.", AbsenceLine2."Line No.", DimMgt.GetDimValuePostingErr);
        end;
    end;

    local procedure CopyCommentLines(FromNumber: Code[20]; ToNumber: Code[20]; CancelOrder: Boolean)
    var
        HROrderComment2: Record "HR Order Comment Line";
    begin
        if CancelOrder then
            HROrderComment.SetRange("Table Name", HROrderComment."Table Name"::"P.Absence Order")
        else
            HROrderComment.SetRange("Table Name", HROrderComment."Table Name"::"Absence Order");
        HROrderComment.SetRange("No.", FromNumber);
        if HROrderComment.FindSet then begin
            repeat
                HROrderComment2 := HROrderComment;
                if CancelOrder then
                    HROrderComment2."Table Name" := HROrderComment2."Table Name"::"Absence Order"
                else
                    HROrderComment2."Table Name" := HROrderComment2."Table Name"::"P.Absence Order";
                HROrderComment2."No." := ToNumber;
                HROrderComment2.Insert();
            until HROrderComment.Next = 0;
            HROrderComment.DeleteAll();
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplyEmplAbsenceEntry(AbsenceLine: Record "Absence Line")
    var
        TimeActivity: Record "Time Activity";
        EmplAbsenceEntry2: Record "Employee Absence Entry";
        DaysToUse: Decimal;
        RemainingDays: Decimal;
    begin
        TimeActivity.Get(AbsenceLine."Time Activity Code");
        if TimeActivity."Use Accruals" then begin
            DaysToUse := AbsenceLine."Calendar Days";
            EmplAbsenceEntry2.Reset();
            EmplAbsenceEntry2.SetRange("Employee No.", AbsenceLine."Employee No.");
            EmplAbsenceEntry2.SetRange("Time Activity Code", AbsenceLine."Time Activity Code");
            EmplAbsenceEntry2.SetRange("Entry Type", EmplAbsenceEntry2."Entry Type"::Accrual);
            if EmplAbsenceEntry2.FindSet then begin
                repeat
                    EmplAbsenceEntry2.CalcFields("Used Calendar Days");
                    RemainingDays := EmplAbsenceEntry2."Calendar Days" - EmplAbsenceEntry2."Used Calendar Days";
                    if RemainingDays <> 0 then
                        if RemainingDays >= DaysToUse then begin
                            InsertEmplAbsenceEntry(AbsenceLine, DaysToUse, 0, EmplAbsenceEntry2."Entry No.");
                            DaysToUse := 0;
                        end else begin
                            InsertEmplAbsenceEntry(AbsenceLine, RemainingDays, 0, EmplAbsenceEntry2."Entry No.");
                            DaysToUse := DaysToUse - RemainingDays;
                        end;
                until (EmplAbsenceEntry2.Next = 0) or (DaysToUse = 0);
                if DaysToUse <> 0 then
                    repeat
                        if EmplAbsenceEntry2.Get(InsertVacationAccrual(AbsenceLine)) then begin
                            EmplAbsenceEntry2.CalcFields("Used Calendar Days");
                            RemainingDays := EmplAbsenceEntry2."Calendar Days" - EmplAbsenceEntry2."Used Calendar Days";
                            if RemainingDays >= DaysToUse then begin
                                InsertEmplAbsenceEntry(AbsenceLine, DaysToUse, 0, EmplAbsenceEntry2."Entry No.");
                                DaysToUse := 0;
                            end else begin
                                InsertEmplAbsenceEntry(AbsenceLine, RemainingDays, 0, EmplAbsenceEntry2."Entry No.");
                                DaysToUse := DaysToUse - RemainingDays;
                            end;
                        end;
                    until DaysToUse = 0;
            end;
        end else
            InsertEmplAbsenceEntry(AbsenceLine, AbsenceLine."Calendar Days", AbsenceLine."Working Days", 0);
    end;

    [Scope('OnPrem')]
    procedure InsertEmplAbsenceEntry(AbsenceLine: Record "Absence Line"; CalendarDays: Decimal; WorkingDays: Decimal; AccruedEntryNo: Integer)
    begin
        EmplAbsenceEntry.Init();
        NextEntryNo := NextEntryNo + 1;
        EmplAbsenceEntry."Entry No." := NextEntryNo;
        EmplAbsenceEntry."Employee No." := AbsenceHeader."Employee No.";
        EmplAbsenceEntry."Time Activity Code" := AbsenceLine."Time Activity Code";
        EmplAbsenceEntry."Element Code" := AbsenceLine."Element Code";
        EmplAbsenceEntry.Description := AbsenceLine.Description;
        EmplAbsenceEntry."Entry Type" := EmplAbsenceEntry."Entry Type"::Usage;
        EmplAbsenceEntry."Start Date" := AbsenceLine."Start Date";
        EmplAbsenceEntry."End Date" := AbsenceLine."End Date";
        EmplAbsenceEntry."Calendar Days" := CalendarDays;
        EmplAbsenceEntry."Working Days" := WorkingDays;
        EmplAbsenceEntry."Accrual Entry No." := AccruedEntryNo;
        EmplAbsenceEntry."Document Type" := AbsenceLine."Document Type" + 1;
        EmplAbsenceEntry."Document No." := AbsenceLine."Document No.";
        EmplAbsenceEntry."Document Date" := AbsenceHeader."Document Date";
        EmplAbsenceEntry."HR Order No." := AbsenceHeader."HR Order No.";
        EmplAbsenceEntry."HR Order Date" := AbsenceHeader."HR Order Date";
        EmplAbsenceEntry."Vacation Type" := AbsenceLine."Vacation Type";
        EmplAbsenceEntry."Sick Leave Type" := AbsenceLine."Sick Leave Type";
        EmplAbsenceEntry."Person No." := AbsenceLine."Person No.";
        EmplAbsenceEntry."Relative Code" := AbsenceLine."Relative Person No.";
        EmplAbsenceEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure CheckVacationPeriodExpand(AbsenceLine: Record "Absence Line")
    var
        TimeActivity: Record "Time Activity";
        EmplAbsenceEntry2: Record "Employee Absence Entry";
        LinkedEmplAbsenceEntry: Record "Employee Absence Entry";
        VacExtDays: Decimal;
        EndDate: Date;
    begin
        TimeActivity.Get(AbsenceLine."Time Activity Code");
        if IsTACInVacExpandGroup(AbsenceLine."Time Activity Code", AbsenceLine."End Date") then begin
            EmplAbsenceEntry2.SetRange("Employee No.", AbsenceLine."Employee No.");
            EmplAbsenceEntry2.SetRange("Entry Type", EmplAbsenceEntry2."Entry Type"::Accrual);
            EmplAbsenceEntry2.SetFilter("End Date", '>%1', AbsenceLine."End Date");
            EmplAbsenceEntry2.SetFilter("Start Date", '<%1', AbsenceLine."End Date");
            EmplAbsenceEntry2.SetFilter("Time Activity Code", GetAnnualVacTimeActFilter(AbsenceLine."End Date"));
            if EmplAbsenceEntry2.FindLast then begin
                VacExtDays :=
                  TimesheetMgt.GetTimesheetInfo(
                    AbsenceLine."Employee No.",
                    AbsenceLine."Time Activity Code",
                    EmplAbsenceEntry2."Start Date",
                    EmplAbsenceEntry2."End Date",
                    4) +
                  AbsenceLine."Calendar Days";
                if VacExtDays > TimeActivity."Min Days Allowed per Year" then begin
                    EmplAbsenceEntry.Init();
                    EmplAbsenceEntry.TransferFields(EmplAbsenceEntry2);
                    NextEntryNo := NextEntryNo + 1;
                    LinkedEmplAbsenceEntry.SetRange("Accrual Entry No.", EmplAbsenceEntry2."Entry No.");
                    LinkedEmplAbsenceEntry.SetRange("Entry Type", LinkedEmplAbsenceEntry."Entry Type"::Accrual);
                    if LinkedEmplAbsenceEntry.FindLast then
                        EndDate := LinkedEmplAbsenceEntry."End Date"
                    else
                        EndDate := EmplAbsenceEntry2."End Date";
                    EmplAbsenceEntry."Entry No." := NextEntryNo;
                    EmplAbsenceEntry."Start Date" := EndDate + 1;
                    EmplAbsenceEntry."End Date" :=
                      EmplAbsenceEntry."Start Date" + VacExtDays - TimeActivity."Min Days Allowed per Year" - 1;
                    EmplAbsenceEntry."Calendar Days" := 0;
                    EmplAbsenceEntry."Working Days" := 0;
                    EmplAbsenceEntry."Accrual Entry No." := EmplAbsenceEntry2."Entry No.";
                    EmplAbsenceEntry."Document Type" := AbsenceLine."Document Type" + 1;
                    EmplAbsenceEntry."Document No." := AbsenceLine."Document No.";
                    EmplAbsenceEntry."Document Date" := AbsenceHeader."Document Date";
                    EmplAbsenceEntry.Description := TimeActivity.Description;
                    EmplAbsenceEntry.Insert();
                end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure IsTACInVacExpandGroup(TimeActivityCode: Code[10]; AbsenceEndDate: Date): Boolean
    begin
        TimeActivityGroup.Get(HRSetup."Change Vacation Accr. By Doc");
        exit(TimeActivityGroup.TimeActivityInGroup(TimeActivityCode, AbsenceEndDate));
    end;

    [Scope('OnPrem')]
    procedure NextCalEndDate(StartDate: Date; CalDays: Decimal): Date
    begin
        exit(CalcDate('<' + Format(CalDays) + 'D>', StartDate));
    end;

    [Scope('OnPrem')]
    procedure GetAnnualVacTimeActFilter(StartDate: Date): Code[250]
    var
        TimeActivityFilter: Record "Time Activity Filter";
    begin
        HRSetup.TestField("Annual Vacation Group Code");
        TimesheetMgt.GetTimeGroupFilter(HRSetup."Annual Vacation Group Code", StartDate, TimeActivityFilter);
        exit(TimeActivityFilter."Activity Code Filter");
    end;

    [Scope('OnPrem')]
    procedure CancelOrder(var PostedAbsenceHeader: Record "Posted Absence Header"; var NewDocNo: Code[20])
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        EmplAbsenceEntry: Record "Employee Absence Entry";
        TimesheetLine: Record "Timesheet Line";
        PostedAbsenceLine: Record "Posted Absence Line";
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
        TimeSheetStatus: Record "Timesheet Status";
        PayrollStatus: Record "Payroll Status";
        EmplJnlPostLine: Codeunit "Employee Journal - Post Line";
        CurrentDate: Date;
        PayrollRegNo: Integer;
    begin
        PayrollStatus.CheckPayrollStatus(PostedAbsenceHeader."Period Code", PostedAbsenceHeader."Employee No.");
        TimeSheetStatus.Get(PostedAbsenceHeader."Period Code", PostedAbsenceHeader."Employee No.");
        TimeSheetStatus.TestField(Status, TimeSheetStatus.Status::Open);

        EmplLedgEntry.Reset();
        EmplLedgEntry.SetCurrentKey("Employee No.");
        EmplLedgEntry.SetRange("Employee No.", PostedAbsenceHeader."Employee No.");
        EmplLedgEntry.SetRange("Document Type", PostedAbsenceHeader."Document Type" + 1);
        EmplLedgEntry.SetRange("Document No.", PostedAbsenceHeader."No.");
        if EmplLedgEntry.FindFirst then begin
            PayrollRegNo := GetPayrollReg(EmplLedgEntry);
            EmplLedgEntry.DeleteAll();
            if PayrollRegNo <> 0 then
                EmplJnlPostLine.CancelRegister(PayrollRegNo);
        end;

        EmplAbsenceEntry.Reset();
        EmplAbsenceEntry.SetRange("Employee No.", PostedAbsenceHeader."Employee No.");
        EmplAbsenceEntry.SetRange("Document Type", PostedAbsenceHeader."Document Type" + 1);
        EmplAbsenceEntry.SetRange("Document No.", PostedAbsenceHeader."No.");
        EmplAbsenceEntry.DeleteAll();

        AbsenceHeader.Init();
        AbsenceHeader.TransferFields(PostedAbsenceHeader);
        AbsenceHeader.Insert();
        NewDocNo := AbsenceHeader."No.";

        PostedAbsenceLine.SetRange("Document Type", PostedAbsenceHeader."Document Type");
        PostedAbsenceLine.SetRange("Document No.", PostedAbsenceHeader."No.");
        if PostedAbsenceLine.FindSet then
            repeat
                AbsenceLine.Init();
                AbsenceLine.TransferFields(PostedAbsenceLine);
                AbsenceLine."Document No." := AbsenceHeader."No.";
                AbsenceLine.Insert();

                TimesheetMgt.IsPostedOrderCancellation(true);

                CurrentDate := PostedAbsenceLine."Start Date";
                while CurrentDate <= PostedAbsenceLine."End Date" do begin
                    TimesheetLine.Get(PostedAbsenceHeader."Employee No.", CurrentDate);
                    TimesheetMgt.InsertTimesheetDetails(
                      PostedAbsenceHeader."Employee No.", TimesheetLine.Date, TimesheetLine."Time Activity Code",
                      TimesheetLine."Planned Hours", 0, '', 0, '', 0D);
                    CurrentDate := CalcDate('<1D>', CurrentDate);
                end;

            until PostedAbsenceLine.Next = 0;

        CopyCommentLines(PostedAbsenceHeader."No.", AbsenceHeader."No.", true);

        PostedAbsenceHeader.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure GetPayrollReg(var EmplLedgEntry: Record "Employee Ledger Entry"): Integer
    var
        EmplLedgEntry2: Record "Employee Ledger Entry";
        PayrollReg: Record "Payroll Register";
        FromEntryNo: Integer;
        ToEntryNo: Integer;
    begin
        EmplLedgEntry2.Copy(EmplLedgEntry);
        if EmplLedgEntry2.FindFirst then
            FromEntryNo := EmplLedgEntry2."Entry No.";
        if EmplLedgEntry2.FindLast then
            ToEntryNo := EmplLedgEntry2."Entry No.";
        if (FromEntryNo <> 0) and (ToEntryNo <> 0) then begin
            PayrollReg.SetFilter("From Entry No.", '>=%1', FromEntryNo);
            PayrollReg.SetFilter("To Entry No.", '<=%1', ToEntryNo);
            if PayrollReg.FindFirst then
                exit(PayrollReg."No.")
        end;

        exit(0);
    end;

    [Scope('OnPrem')]
    procedure InsertVacationAccrual(AbsenceLine: Record "Absence Line"): Integer
    var
        VacationAccrualEntry: Record "Employee Absence Entry";
    begin
        EmplAbsenceEntry.Reset();
        EmplAbsenceEntry.SetRange("Employee No.", AbsenceLine."Employee No.");
        EmplAbsenceEntry.SetRange("Entry Type", EmplAbsenceEntry."Entry Type"::Accrual);
        EmplAbsenceEntry.SetRange("Accrual Entry No.", 0);
        EmplAbsenceEntry.SetFilter(
          "Time Activity Code",
          GetAnnualVacTimeActFilter(CalcDate('<CY>', AbsenceLine."End Date")));
        if EmplAbsenceEntry.FindLast then begin
            NextEntryNo := NextEntryNo + 1;
            VacationAccrualEntry.Init();
            VacationAccrualEntry.TransferFields(EmplAbsenceEntry);
            VacationAccrualEntry."Entry No." := NextEntryNo;
            VacationAccrualEntry."Start Date" := CalcDate('<+1D>', EmplAbsenceEntry."End Date");
            VacationAccrualEntry."End Date" := CalcDate('<1Y-1D>', VacationAccrualEntry."Start Date");
            VacationAccrualEntry."Accrual Entry No." := 0;
            VacationAccrualEntry."Calendar Days" := EmplAbsenceEntry."Calendar Days";
            VacationAccrualEntry."Working Days" := 0;
            VacationAccrualEntry.Insert();
            exit(VacationAccrualEntry."Entry No.");
        end;

        exit(0);
    end;
}

