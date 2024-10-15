codeunit 14963 "Insert Payroll Analysis Line"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure InsertPayrollElements(var PayrollAnalysisLine: Record "Payroll Analysis Line")
    var
        PayrollElement: Record "Payroll Element";
        PayrollElementList: Page "Payroll Element List";
        PayrollElementCount: Integer;
        AnalysisLineNo: Integer;
    begin
        PayrollElementList.LookupMode(true);
        if PayrollElementList.RunModal = ACTION::LookupOK then begin
            PayrollElementList.SetSelection(PayrollElement);
            PayrollElementCount := PayrollElement.Count();
            if PayrollElementCount > 0 then begin
                MoveAnalysisLines(PayrollAnalysisLine, AnalysisLineNo, PayrollElementCount);

                if PayrollElement.FindSet then
                    repeat
                        InsertAnalysisLine(
                          PayrollAnalysisLine, AnalysisLineNo,
                          PayrollElement.Description, PayrollElement.Code, PayrollAnalysisLine.Type::"Payroll Element", false, 0);
                    until PayrollElement.Next() = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertPayrollElementGroups(var PayrollAnalysisLine: Record "Payroll Analysis Line")
    var
        PayrollElementGroup: Record "Payroll Element Group";
        PayrollElementGroups: Page "Payroll Element Groups";
        "Count": Integer;
        AnalysisLineNo: Integer;
    begin
        PayrollElementGroups.LookupMode(true);
        if PayrollElementGroups.RunModal = ACTION::LookupOK then begin
            PayrollElementGroups.SetSelection(PayrollElementGroup);
            Count := PayrollElementGroup.Count();
            if Count > 0 then begin
                MoveAnalysisLines(PayrollAnalysisLine, AnalysisLineNo, Count);

                if PayrollElementGroup.FindSet then
                    repeat
                        InsertAnalysisLine(
                          PayrollAnalysisLine, AnalysisLineNo,
                          PayrollElementGroup.Name, PayrollElementGroup.Code, PayrollAnalysisLine.Type::"Payroll Element Group", false, 0);
                    until PayrollElementGroup.Next() = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertEmployees(var PayrollAnalysisLine: Record "Payroll Analysis Line")
    var
        Employee: Record Employee;
        EmployeeList: Page "Employee List";
        "Count": Integer;
        AnalysisLineNo: Integer;
    begin
        EmployeeList.LookupMode(true);
        if EmployeeList.RunModal = ACTION::LookupOK then begin
            EmployeeList.SetSelection(Employee);
            Count := Employee.Count();
            if Count > 0 then begin
                MoveAnalysisLines(PayrollAnalysisLine, AnalysisLineNo, Count);

                if Employee.FindSet then
                    repeat
                        InsertAnalysisLine(
                          PayrollAnalysisLine, AnalysisLineNo,
                          Employee."Short Name", Employee."No.", PayrollAnalysisLine.Type::Employee, false, 0);
                    until Employee.Next() = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertOrgUnits(var PayrollAnalysisLine: Record "Payroll Analysis Line")
    var
        OrgUnit: Record "Organizational Unit";
        OrgUnits: Page "Organizational Units";
        "Count": Integer;
        AnalysisLineNo: Integer;
    begin
        OrgUnits.LookupMode(true);
        if OrgUnits.RunModal = ACTION::LookupOK then begin
            OrgUnits.SetSelection(OrgUnit);
            Count := OrgUnit.Count();
            if Count > 0 then begin
                MoveAnalysisLines(PayrollAnalysisLine, AnalysisLineNo, Count);

                if OrgUnit.FindSet then
                    repeat
                        InsertAnalysisLine(
                          PayrollAnalysisLine, AnalysisLineNo,
                          OrgUnit.Name, OrgUnit.Code, PayrollAnalysisLine.Type::"Org. Unit", false, 0);
                    until OrgUnit.Next() = 0;
            end;
        end;
    end;

    local procedure MoveAnalysisLines(var PayrollAnalysisLine: Record "Payroll Analysis Line"; var AnalysisLineNo: Integer; NewLineCount: Integer)
    var
        i: Integer;
    begin
        with PayrollAnalysisLine do begin
            AnalysisLineNo := "Line No.";
            SetRange("Analysis Line Template Name", "Analysis Line Template Name");
            if FindLast then
                repeat
                    i := "Line No.";
                    if i >= AnalysisLineNo then begin
                        Delete;
                        "Line No." := i + 10000 * NewLineCount;
                        Insert(true);
                    end;
                until (i <= AnalysisLineNo) or (Next(-1) = 0);

            if AnalysisLineNo = 0 then
                AnalysisLineNo := 10000;
        end;
    end;

    local procedure InsertAnalysisLine(var PayrollAnalysisLine: Record "Payroll Analysis Line"; var AnalysisLineNo: Integer; Text: Text[50]; No: Code[20]; Type2: Integer; Bold2: Boolean; Indent: Integer)
    var
        RecRef: RecordRef;
        ChangeLogMgt: Codeunit "Change Log Management";
    begin
        with PayrollAnalysisLine do begin
            Init;
            "Line No." := AnalysisLineNo;
            AnalysisLineNo := AnalysisLineNo + 10000;
            Description := Text;
            Expression := No;
            "Row No." := CopyStr(No, 1, MaxStrLen("Row No."));
            Type := Type2;
            Bold := Bold2;
            Indentation := Indent;
            Insert(true);
            RecRef.GetTable(PayrollAnalysisLine);
            ChangeLogMgt.LogInsertion(RecRef);
        end;
    end;
}

