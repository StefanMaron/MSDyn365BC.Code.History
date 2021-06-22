codeunit 14 "Gen. Jnl.-Show Entries"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                    GLEntry.SetRange("G/L Account No.", "Account No.");
                    if GLEntry.FindLast then;
                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    if CustLedgEntry.FindLast then;
                    PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    if VendLedgEntry.FindLast then;
                    PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
                end;
            "Account Type"::Employee:
                begin
                    EmplLedgEntry.SetCurrentKey("Employee No.", "Posting Date");
                    EmplLedgEntry.SetRange("Employee No.", "Account No.");
                    if EmplLedgEntry.FindLast then;
                    PAGE.Run(PAGE::"Employee Ledger Entries", EmplLedgEntry);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.", "Posting Date");
                    BankAccLedgEntry.SetRange("Bank Account No.", "Account No.");
                    if BankAccLedgEntry.FindLast then;
                    PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccLedgEntry);
                end;
            "Account Type"::"Fixed Asset":
                if "FA Posting Type" <> "FA Posting Type"::Maintenance then begin
                    FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                    FALedgEntry.SetRange("FA No.", "Account No.");
                    if "Depreciation Book Code" <> '' then
                        FALedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                    if FALedgEntry.FindLast then;
                    PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
                end else begin
                    MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                    MaintenanceLedgEntry.SetRange("FA No.", "Account No.");
                    if "Depreciation Book Code" <> '' then
                        MaintenanceLedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                    if MaintenanceLedgEntry.FindLast then;
                    PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
                end;
            "Account Type"::"IC Partner":
                Error(Text001);
        end;

        OnAfterRun(Rec);
    end;

    var
        GLEntry: Record "G/L Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        Text001: Label 'Intercompany partners do not have ledger entries.';

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

