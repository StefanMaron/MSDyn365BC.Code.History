codeunit 5800 "Item Reg.- Show Value Entries"
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        ValueEntry.SetRange("Entry No.", "From Value Entry No.", "To Value Entry No.");
        PAGE.Run(PAGE::"Value Entries", ValueEntry);
    end;

    var
        ValueEntry: Record "Value Entry";
}

