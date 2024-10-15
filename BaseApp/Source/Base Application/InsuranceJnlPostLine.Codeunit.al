codeunit 5652 "Insurance Jnl.-Post Line"
{
    Permissions = TableData "Ins. Coverage Ledger Entry" = rimd,
                  TableData "Insurance Register" = rimd;
    TableNo = "Insurance Journal Line";

    trigger OnRun()
    begin
        GLSetup.Get;
        RunWithCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        FA: Record "Fixed Asset";
        Insurance: Record Insurance;
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        InsCoverageLedgEntry2: Record "Ins. Coverage Ledger Entry";
        InsuranceReg: Record "Insurance Register";
        InsuranceJnlCheckLine: Codeunit "Insurance Jnl.-Check Line";
        MakeInsCoverageLedgEntry: Codeunit "Make Ins. Coverage Ledg. Entry";
        NextEntryNo: Integer;

    procedure RunWithCheck(var InsuranceJnlLine2: Record "Insurance Journal Line")
    begin
        InsuranceJnlLine.Copy(InsuranceJnlLine2);
        Code(true);
        InsuranceJnlLine2 := InsuranceJnlLine;
    end;

    procedure RunWithOutCheck(var InsuranceJnlLine2: Record "Insurance Journal Line")
    begin
        InsuranceJnlLine.Copy(InsuranceJnlLine2);
        Code(false);
        InsuranceJnlLine2 := InsuranceJnlLine;
    end;

    local procedure "Code"(CheckLine: Boolean)
    begin
        with InsuranceJnlLine do begin
            if "Insurance No." = '' then
                exit;
            if CheckLine then
                InsuranceJnlCheckLine.RunCheck(InsuranceJnlLine);
            Insurance.Get("Insurance No.");
            Insurance.TestField(Blocked, false);
            FA.Get("FA No.");
            FA.TestField("Budgeted Asset", false);
            FA.TestField(Blocked, false);
            FA.TestField(Inactive, false);
            MakeInsCoverageLedgEntry.CopyFromJnlLine(InsCoverageLedgEntry, InsuranceJnlLine);
            MakeInsCoverageLedgEntry.CopyFromInsuranceCard(InsCoverageLedgEntry, Insurance);
        end;
        if NextEntryNo = 0 then begin
            InsCoverageLedgEntry.LockTable;
            if InsCoverageLedgEntry2.FindLast then
                NextEntryNo := InsCoverageLedgEntry2."Entry No.";
            InsuranceReg.LockTable;
            if InsuranceReg.FindLast then
                InsuranceReg."No." := InsuranceReg."No." + 1
            else
                InsuranceReg."No." := 1;
            InsuranceReg.Init;
            InsuranceReg."From Entry No." := NextEntryNo + 1;
            InsuranceReg."Creation Date" := Today;
            InsuranceReg."Creation Time" := Time;
            InsuranceReg."Source Code" := InsuranceJnlLine."Source Code";
            InsuranceReg."Journal Batch Name" := InsuranceJnlLine."Journal Batch Name";
            InsuranceReg."User ID" := UserId;
        end;
        NextEntryNo := NextEntryNo + 1;
        InsCoverageLedgEntry."Entry No." := NextEntryNo;
        InsCoverageLedgEntry."Dimension Set ID" := InsuranceJnlLine."Dimension Set ID";
        InsCoverageLedgEntry.Insert;
        if InsuranceReg."To Entry No." = 0 then begin
            InsuranceReg."To Entry No." := NextEntryNo;
            InsuranceReg.Insert;
        end else begin
            InsuranceReg."To Entry No." := NextEntryNo;
            InsuranceReg.Modify;
        end;
    end;
}

