codeunit 114 "Empl. Entry-Edit"
{
    Permissions = TableData "Employee Ledger Entry" = m,
                  TableData "Detailed Employee Ledger Entry" = m;
    TableNo = "Employee Ledger Entry";

    trigger OnRun()
    begin
        EmplLedgEntry := Rec;
        EmplLedgEntry.LockTable();
        EmplLedgEntry.Find;
        if EmplLedgEntry.Open then begin
            EmplLedgEntry."Applies-to ID" := "Applies-to ID";
            EmplLedgEntry.Validate("Payment Method Code", "Payment Method Code");
            EmplLedgEntry.Validate("Amount to Apply", "Amount to Apply");
            EmplLedgEntry.Validate("Applying Entry", "Applying Entry");
            EmplLedgEntry.Validate("Message to Recipient", "Message to Recipient");
        end;
        EmplLedgEntry.Validate("Exported to Payment File", "Exported to Payment File");
        EmplLedgEntry.Validate("Creditor No.", "Creditor No.");
        EmplLedgEntry.Validate("Payment Reference", "Payment Reference");
        OnBeforeEmplLedgEntryModify(EmplLedgEntry, Rec);
        EmplLedgEntry.TestField("Entry No.", "Entry No.");
        EmplLedgEntry.Modify();
        Rec := EmplLedgEntry;
    end;

    var
        EmplLedgEntry: Record "Employee Ledger Entry";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmplLedgEntryModify(var EmplLedgEntry: Record "Employee Ledger Entry"; FromEmplLedgEntry: Record "Employee Ledger Entry")
    begin
    end;
}

