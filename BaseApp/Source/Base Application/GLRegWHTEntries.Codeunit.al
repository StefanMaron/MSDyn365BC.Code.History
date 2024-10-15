codeunit 28041 "G/L Reg.-WHT Entries"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        WHTEntry.SetRange("Entry No.", "From WHT Entry No.", "To WHT Entry No.");
        PAGE.Run(PAGE::"WHT Entry", WHTEntry);
    end;

    var
        WHTEntry: Record "WHT Entry";
}

