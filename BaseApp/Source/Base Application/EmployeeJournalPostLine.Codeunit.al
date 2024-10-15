codeunit 17382 "Employee Journal - Post Line"
{
    Permissions = TableData "Employee Ledger Entry" = imd,
                  TableData "Payroll Register" = imd;

    trigger OnRun()
    begin
    end;

    var
        EmplJnlLine: Record "Employee Journal Line";
        Employee: Record Employee;
        EmplLedgEntry: Record "Employee Ledger Entry";
        PayrollElement: Record "Payroll Element";
        PayrollReg: Record "Payroll Register";
        EmplJnlCheckLine: Codeunit "Employee Journal - Check Line";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        NextEntryNo: Integer;

    [Scope('OnPrem')]
    procedure RunWithCheck(var EmplJnlLine2: Record "Employee Journal Line"): Integer
    var
        EntryNo: Integer;
    begin
        EmplJnlLine.Copy(EmplJnlLine2);
        EntryNo := Code;
        EmplJnlLine2 := EmplJnlLine;
        exit(EntryNo);
    end;

    local procedure "Code"(): Integer
    begin
        with EmplJnlLine do begin
            if EmptyLine then
                exit;

            EmplJnlCheckLine.Run(EmplJnlLine);

            if NextEntryNo = 0 then begin
                EmplLedgEntry.LockTable;
                if EmplLedgEntry.FindLast then
                    NextEntryNo := EmplLedgEntry."Entry No." + 1
                else
                    NextEntryNo := 1;
            end;

            if "Document Date" = 0D then
                "Document Date" := "Posting Date";
            if "HR Order Date" = 0D then
                "HR Order Date" := "Document Date";

            if PayrollReg."No." = 0 then begin
                PayrollReg.LockTable;
                if PayrollReg.FindLast then
                    PayrollReg."No." := PayrollReg."No." + 1
                else
                    PayrollReg."No." := 1;
                PayrollReg.Init;
                PayrollReg."From Entry No." := NextEntryNo;
                PayrollReg."To Entry No." := NextEntryNo;
                PayrollReg."Creation Date" := Today;
                PayrollReg."Source Code" := "Source Code";
                PayrollReg."Journal Batch Name" := "Journal Batch Name";
                PayrollReg."User ID" := UserId;
                PayrollReg.Insert;
            end;

            Employee.Get("Employee No.");
            Employee.TestField(Blocked, false);

            case "Post Action" of
                "Post Action"::Add:
                    begin
                        // close wage elements if any
                        PayrollElement.Get("Element Code");
                        if PayrollElement.Type = PayrollElement.Type::Wage then begin
                            EmplLedgEntry.Reset;
                            EmplLedgEntry.SetCurrentKey("Element Code");
                            EmplLedgEntry.SetRange("Element Code", "Element Code");
                            EmplLedgEntry.SetRange("Employee No.", "Employee No.");
                            EmplLedgEntry.SetRange("Contract No.", "Contract No.");
                            EmplLedgEntry.SetFilter("Action Starting Date", '<%1', "Starting Date");
                            EmplLedgEntry.SetRange("Action Ending Date", 0D);
                            if EmplLedgEntry.FindSet then
                                repeat
                                    EmplLedgEntry."Action Ending Date" := CalcDate('<-1D>', "Starting Date");
                                    EmplLedgEntry.Modify;
                                until EmplLedgEntry.Next = 0;
                        end;

                        // insert new entry
                        EmplLedgEntry.Init;
                        EmplLedgEntry."Entry No." := NextEntryNo;
                        NextEntryNo := NextEntryNo + 1;
                        EmplLedgEntry."Employee No." := "Employee No.";
                        EmplLedgEntry."Position No." := "Position No.";
                        EmplLedgEntry."Contract No." := "Contract No.";
                        EmplLedgEntry."Element Code" := "Element Code";
                        EmplLedgEntry."Action Starting Date" := "Starting Date";
                        EmplLedgEntry."Action Ending Date" := "Ending Date";
                        EmplLedgEntry."Period Code" := "Period Code";
                        EmplLedgEntry."Wage Period From" := "Wage Period From";
                        EmplLedgEntry."Wage Period To" := "Wage Period To";
                        EmplLedgEntry."Time Activity Code" := "Time Activity Code";
                        EmplLedgEntry.Description := Description;
                        EmplLedgEntry.Amount := Amount;
                        EmplLedgEntry.Quantity := Quantity;
                        EmplLedgEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
                        EmplLedgEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
                        EmplLedgEntry."Posting Group" := "Posting Group";
                        EmplLedgEntry."Currency Code" := "Currency Code";
                        EmplLedgEntry."Calendar Code" := "Calendar Code";
                        EmplLedgEntry."Payroll Calc Group" := "Payroll Calc Group";
                        EmplLedgEntry."Document Type" := "Document Type";
                        EmplLedgEntry."Document No." := "Document No.";
                        EmplLedgEntry."Document Date" := "Document Date";
                        EmplLedgEntry."HR Order No." := "HR Order No.";
                        EmplLedgEntry."HR Order Date" := "HR Order Date";
                        EmplLedgEntry."Sick Leave Type" := "Sick Leave Type";
                        EmplLedgEntry."Vacation Type" := "Vacation Type";
                        EmplLedgEntry."Payment Days" := "Payment Days";
                        EmplLedgEntry."Payment Percent" := "Payment Percent";
                        EmplLedgEntry."Payment Source" := "Payment Source";
                        EmplLedgEntry."Days Not Paid" := "Days Not Paid";
                        EmplLedgEntry."Relative Person No." := "Relative Person No.";
                        EmplLedgEntry."AE Period From" := "AE Period From";
                        EmplLedgEntry."AE Period To" := "AE Period To";
                        EmplLedgEntry."Salary Indexation" := "Salary Indexation";
                        EmplLedgEntry."Depends on Salary Element" := "Depends on Salary Element";
                        EmplLedgEntry."Related to Entry No." := "Applies-to Entry";
                        EmplLedgEntry.Terminated := Terminated;
                        EmplLedgEntry."External Document No." := "External Document No.";
                        EmplLedgEntry."External Document Date" := "External Document Date";
                        EmplLedgEntry."External Document Issued By" := "External Document Issued By";
                        EmplLedgEntry."Dimension Set ID" := "Dimension Set ID";
                        EmplLedgEntry.Insert;

                        PayrollReg."To Entry No." := NextEntryNo - 1;
                        PayrollReg.Modify;

                        if ("Time Activity Code" <> '') and (not Terminated) then
                            TimesheetMgt.CreateFromLine(
                              "Employee No.", "Time Activity Code",
                              "Starting Date", "Ending Date",
                              "Document Type", "Document No.", "Document Date");
                    end;
                "Post Action"::Update:
                    begin
                        EmplLedgEntry.Get("Applies-to Entry");
                        EmplLedgEntry.Amount := Amount;
                        EmplLedgEntry.Quantity := Quantity;
                        EmplLedgEntry."Payment Days" := "Payment Days";
                        EmplLedgEntry.Modify;
                    end;
                "Post Action"::Close:
                    begin
                        EmplLedgEntry.Get("Applies-to Entry");
                        if "Ending Date" >= EmplLedgEntry."Action Starting Date" then begin
                            EmplLedgEntry."Action Ending Date" := "Ending Date";
                            EmplLedgEntry.Modify;
                        end;
                    end;
            end;
        end;

        exit(EmplLedgEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure CancelRegister(PayrollRegNo: Integer)
    var
        PayrollStatus: Record "Payroll Status";
    begin
        PayrollReg.Get(PayrollRegNo);
        EmplLedgEntry.SetRange("Entry No.", PayrollReg."From Entry No.", PayrollReg."To Entry No.");
        if EmplLedgEntry.FindSet then begin
            repeat
                PayrollStatus.CheckPayrollStatus(EmplLedgEntry."Period Code", EmplLedgEntry."Employee No.");
                EmplLedgEntry.Delete;
            until EmplLedgEntry.Next = 0;
        end;

        PayrollReg."From Entry No." := 0;
        PayrollReg."To Entry No." := 0;
        PayrollReg.Modify;
    end;
}

