codeunit 1273 "Exp. Pre-Mapping Gen. Jnl."
{
    Permissions = TableData "Payment Export Data" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Window: Dialog;
        LineNo: Integer;
    begin
        GenJnlLine.SetRange("Data Exch. Entry No.", "Entry No.");
        GenJnlLine.FindSet();

        Window.Open(ProgressMsg);

        repeat
            LineNo += 1;
            Window.Update(1, LineNo);

            PreparePaymentExportDataJnl(GenJnlLine, GenJnlLine."Data Exch. Entry No.", LineNo);
        until GenJnlLine.Next() = 0;

        Window.Close;
    end;

    var
        ProgressMsg: Label 'Pre-processing line no. #1######.';

    local procedure PreparePaymentExportDataJnl(GenJnlLine: Record "Gen. Journal Line"; DataExchEntryNo: Integer; LineNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GeneralLedgerSetup.Get();
        GenJnlLine.TestField("Account Type", GenJnlLine."Account Type"::Vendor);
        Vendor.Get(GenJnlLine."Account No.");

        with PaymentExportData do begin
            BankAccount.Get(GenJnlLine."Bal. Account No.");
            BankAccount.GetBankExportImportSetup(BankExportImportSetup);
            SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");

            Init;
            "Data Exch Entry No." := DataExchEntryNo;
            "Sender Bank Account Code" := GenJnlLine."Bal. Account No.";
            BankAccount.Get("Sender Bank Account Code");
            "Sender Bank Account No." := CopyStr(BankAccount.GetBankAccountNo, 1, MaxStrLen("Sender Bank Account No."));

            if VendorBankAccount.Get(GenJnlLine."Account No.", GenJnlLine."Recipient Bank Account") then begin
                Amount := GenJnlLine.Amount;
                "Currency Code" := GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code");
                "Recipient Bank Acc. No." :=
                  CopyStr(VendorBankAccount.GetBankAccountNo, 1, MaxStrLen("Recipient Bank Acc. No."));
                "Recipient Reg. No." := VendorBankAccount."Bank Branch No.";
                "Recipient Acc. No." := VendorBankAccount."Bank Account No.";
                "Recipient Bank Country/Region" := VendorBankAccount."Country/Region Code";
                "Recipient Bank Name" := CopyStr(VendorBankAccount.Name, 1, 35);
                "Recipient Bank Address" := CopyStr(VendorBankAccount.Address, 1, 35);
                "Recipient Bank City" := CopyStr(VendorBankAccount."Post Code" + VendorBankAccount.City, 1, 35);
                "Recipient Bank BIC" := VendorBankAccount."SWIFT Code";
            end else
                if GenJnlLine."Creditor No." <> '' then begin
                    Amount := GenJnlLine."Amount (LCY)";
                    "Currency Code" := GeneralLedgerSetup."LCY Code";
                end;

            "Recipient Name" := CopyStr(Vendor.Name, 1, 35);
            "Recipient Address" := CopyStr(Vendor.Address, 1, 35);
            "Recipient City" := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 35);
            "Transfer Date" := GenJnlLine."Posting Date";
            "Message to Recipient 1" := CopyStr(GenJnlLine."Message to Recipient", 1, 35);
            "Message to Recipient 2" := CopyStr(GenJnlLine."Message to Recipient", 36, 70);
            "Document No." := GenJnlLine."Document No.";
            "Applies-to Ext. Doc. No." := GenJnlLine."Applies-to Ext. Doc. No.";
            "Short Advice" := GenJnlLine."Applies-to Ext. Doc. No.";
            "Line No." := LineNo;
            "Payment Reference" := GenJnlLine."Payment Reference";
            if PaymentMethod.Get(GenJnlLine."Payment Method Code") then
                "Data Exch. Line Def Code" := PaymentMethod."Pmt. Export Line Definition";
            "Recipient Creditor No." := GenJnlLine."Creditor No.";

            OnBeforeInsertPaymentExoprtData(PaymentExportData, GenJnlLine, GeneralLedgerSetup);

            Insert(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPaymentExoprtData(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;
}

