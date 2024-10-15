namespace Microsoft.Projects.Project.Ledger;

codeunit 1025 "Job Reg.-Show Ledger"
{
    TableNo = "Job Register";

    trigger OnRun()
    begin
        JobLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        PAGE.Run(PAGE::"Job Ledger Entries", JobLedgEntry);
    end;

    var
        JobLedgEntry: Record "Job Ledger Entry";
}

