codeunit 238 "G/L Reg.-VAT Entries"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        VATEntry.SetRange("Entry No.", "From VAT Entry No.", "To VAT Entry No.");
        PAGE.Run(PAGE::"VAT Entries", VATEntry);
    end;

    var
        VATEntry: Record "VAT Entry";
}

