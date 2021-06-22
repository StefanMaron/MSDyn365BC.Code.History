codeunit 1025 "Job Reg.-Show Ledger"
{
    TableNo = "Job Register";

    trigger OnRun()
    begin
        JobLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
        PAGE.Run(PAGE::"Job Ledger Entries", JobLedgEntry);
    end;

    var
        JobLedgEntry: Record "Job Ledger Entry";
}

