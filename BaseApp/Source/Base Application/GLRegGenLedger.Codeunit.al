codeunit 235 "G/L Reg.-Gen. Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRun(Rec, IsHandled);
        if IsHandled then
            exit;

        // GLEntry.SETRANGE("Entry No.","From Entry No.","To Entry No.");
        if "From Entry No." > 0 then
            GLEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.")
        else
            GLEntry.SetRange("Entry No.", "To Entry No.", "From Entry No.");
        PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
    end;

    var
        GLEntry: Record "G/L Entry";


    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(GLRegister: Record "G/L Register"; var IsHandled: Boolean)
    begin
    end;
}

