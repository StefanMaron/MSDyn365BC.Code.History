codeunit 12402 "G/L Reg. - Corresp. Entries"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        GLCorrespEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
        PAGE.Run(0, GLCorrespEntry);
    end;

    var
        GLCorrespEntry: Record "G/L Correspondence Entry";
}

