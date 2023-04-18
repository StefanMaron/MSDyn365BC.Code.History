codeunit 16 "Gen. Jnl.-Show CT Entries"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if not ("Document Type" in ["Document Type"::Payment, "Document Type"::Refund, "Document Type"::" "]) then
            exit;
        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) then
            exit;

        SetFiltersOnCreditTransferEntry(Rec, CreditTransferEntry);

        PAGE.Run(PAGE::"Credit Transfer Reg. Entries", CreditTransferEntry);
    end;

    var
        CreditTransferEntry: Record "Credit Transfer Entry";

    procedure SetFiltersOnCreditTransferEntry(var GenJournalLine: Record "Gen. Journal Line"; var CreditTransferEntry: Record "Credit Transfer Entry")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        FoundCorrespondingLedgerEntry: Boolean;
    begin
        with GenJournalLine do begin
            CreditTransferEntry.Reset();
            FoundCorrespondingLedgerEntry := false;
            case "Account Type" of
                "Account Type"::Vendor:
                    begin
                        CreditTransferEntry.SetRange("Account Type", CreditTransferEntry."Account Type"::Vendor);
                        if ("Applies-to Doc. No." <> '') or ("Applies-to ID" <> '') then begin
                            VendorLedgerEntry.SetRange("Vendor No.", "Account No.");
                            if "Applies-to Doc. No." <> '' then begin
                                VendorLedgerEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                VendorLedgerEntry.SetRange("Document No.", "Applies-to Doc. No.");
                            end;
                            if "Applies-to ID" <> '' then begin
                                VendorLedgerEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
                                VendorLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                            end;
                            if VendorLedgerEntry.FindFirst() then begin
                                CreditTransferEntry.SetRange("Applies-to Entry No.", VendorLedgerEntry."Entry No.");
                                FoundCorrespondingLedgerEntry := true;
                            end;
                        end;
                    end;
                "Account Type"::Customer:
                    begin
                        CreditTransferEntry.SetRange("Account Type", CreditTransferEntry."Account Type"::Customer);
                        if ("Applies-to Doc. No." <> '') or ("Applies-to ID" <> '') then begin
                            CustLedgerEntry.SetRange("Customer No.", "Account No.");
                            if "Applies-to Doc. No." <> '' then begin
                                CustLedgerEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                CustLedgerEntry.SetRange("Document No.", "Applies-to Doc. No.");
                            end;
                            if "Applies-to ID" <> '' then
                                CustLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                            if CustLedgerEntry.FindFirst() then begin
                                CreditTransferEntry.SetRange("Applies-to Entry No.", CustLedgerEntry."Entry No.");
                                FoundCorrespondingLedgerEntry := true;
                            end;
                        end;
                    end;
                "Account Type"::Employee:
                    begin
                        CreditTransferEntry.SetRange("Account Type", CreditTransferEntry."Account Type"::Employee);
                        if ("Applies-to Doc. No." <> '') or ("Applies-to ID" <> '') then begin
                            EmployeeLedgerEntry.SetRange("Employee No.", "Account No.");
                            if "Applies-to Doc. No." <> '' then begin
                                EmployeeLedgerEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                EmployeeLedgerEntry.SetRange("Document No.", "Applies-to Doc. No.");
                            end;
                            if "Applies-to ID" <> '' then
                                EmployeeLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                            if EmployeeLedgerEntry.FindFirst() then begin
                                CreditTransferEntry.SetRange("Applies-to Entry No.", EmployeeLedgerEntry."Entry No.");
                                FoundCorrespondingLedgerEntry := true;
                            end;
                        end;
                    end;
                else
                    OnSetFiltersOnCreditTransferEntryOnCaseElse(GenJournalLine, CreditTransferEntry, FoundCorrespondingLedgerEntry);
            end;
            CreditTransferEntry.SetRange("Account No.", "Account No.");
            if not FoundCorrespondingLedgerEntry then
                CreditTransferEntry.SetRange("Applies-to Entry No.", 0);
            GeneralLedgerSetup.Get();
            CreditTransferEntry.SetFilter(
              "Currency Code", '''%1''|''%2''', "Currency Code", GeneralLedgerSetup.GetCurrencyCode("Currency Code"));
            CreditTransferEntry.SetRange(Canceled, false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnCreditTransferEntryOnCaseElse(var GenJournalLine: Record "Gen. Journal Line"; var CreditTransferEntry: Record "Credit Transfer Entry"; var FoundCorrespondingLedgerEntry: Boolean)
    begin
    end;
}

