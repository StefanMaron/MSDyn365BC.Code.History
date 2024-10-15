namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 238 "G/L Reg.-VAT Entries"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        VATEntry.SetRange("Entry No.", Rec."From VAT Entry No.", Rec."To VAT Entry No.");
        PAGE.Run(PAGE::"VAT Entries", VATEntry);
    end;

    var
        VATEntry: Record "VAT Entry";
}

