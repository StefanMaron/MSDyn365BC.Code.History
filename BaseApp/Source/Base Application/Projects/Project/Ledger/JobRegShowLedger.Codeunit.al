namespace Microsoft.Projects.Project.Ledger;

codeunit 1025 "Job Reg.-Show Ledger"
{
    TableNo = "Job Register";

    trigger OnRun()
    begin
        JobLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        JobLedgEntry.SetFilter("Job Register No.", '0|%1', Rec."No.");
        Page.Run(Page::"Job Ledger Entries", JobLedgEntry);
    end;

    var
        JobLedgEntry: Record "Job Ledger Entry";
}

