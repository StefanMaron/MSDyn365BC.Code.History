codeunit 1206 "Pmt Export Mgt Gen. Jnl Line"
{
    Permissions = TableData "Vendor Ledger Entry" = rm,
                  TableData "Gen. Journal Line" = rm,
                  TableData "Payment Export Data" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        ExportJournalPaymentFile(Rec);
    end;

    var
        ExportAgainQst: Label 'One or more of the selected lines has already been exported. Do you want to export it again?';
        ProgressMsg: Label 'Processing line no. #1######.', Comment = '#1 - Line no.';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        PaymentExportMgt: Codeunit "Payment Export Mgt";
        EmployeeMustHaveBankAccountNoErr: Label 'You must specify either Bank Account No. or IBAN for employee %1.', Comment = '%1 - Employee name';

    [Scope('OnPrem')]
    procedure ExportJournalPaymentFileYN(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if GenJnlLine.IsExportedToPaymentFile() then
            if not Confirm(ExportAgainQst) then
                exit;
        ExportJournalPaymentFile(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ExportJournalPaymentFile(var GenJnlLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        DataExchDef: Record "Data Exch. Def";
    begin
        BankAccount.Get(GenJnlLine."Bal. Account No.");
        BankAccount.GetDataExchDefPaymentExport(DataExchDef);
        CreditTransferRegister.CreateNew(DataExchDef.Code, GenJnlLine."Bal. Account No.");
        Commit();

        CheckGenJnlLine(GenJnlLine);
        ExportGenJnlLine(GenJnlLine, CreditTransferRegister);
    end;

    local procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine.DeletePaymentFileBatchErrors();
        GenJnlLine2.CopyFilters(GenJnlLine);
        if GenJnlLine2.FindSet() then
            repeat
                CODEUNIT.Run(CODEUNIT::"Payment Export Gen. Jnl Check", GenJnlLine2);
                OnCheckGenJnlLine(GenJnlLine2);
            until GenJnlLine2.Next() = 0;

        if GenJnlLine2.HasPaymentFileErrorsInBatch() then begin
            Commit();
            Error(HasErrorsErr);
        end;
    end;

    [Scope('OnPrem')]
    procedure ExportGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var CreditTransferRegister: Record "Credit Transfer Register")
    var
        GenJnlLine2: Record "Gen. Journal Line";
        DataExch: Record "Data Exch.";
        CreditTransferEntry: Record "Credit Transfer Entry";
        Window: Dialog;
        LineNo: Integer;
        LineAmount: Decimal;
        TransferDate: Date;
        TotalAmount: Decimal;
        HandledGenJnlDataExchLine: Boolean;
        HandledPaymentExport: Boolean;
    begin
        GenJnlLine2.CopyFilters(GenJnlLine);
        GenJnlLine2.FindSet();

        PaymentExportMgt.CreateDataExch(DataExch, GenJnlLine2."Bal. Account No.");
        GenJnlLine2.ModifyAll("Data Exch. Entry No.", DataExch."Entry No.");

        Window.Open(ProgressMsg);
        repeat
            LineNo += 1;
            Window.Update(1, LineNo);

            OnBeforeCreateGenJnlDataExchLine(DataExch, GenJnlLine2, LineNo, LineAmount, TotalAmount, TransferDate, HandledGenJnlDataExchLine);
            if not HandledGenJnlDataExchLine then
                CreateGenJnlDataExchLine(DataExch."Entry No.", GenJnlLine2, LineNo);

            CreditTransferEntry.CreateNew(CreditTransferRegister."No.", LineNo,
              GenJnlLine2."Account Type", GenJnlLine2."Account No.", GenJnlLine2.GetAppliesToDocEntryNo(),
              GenJnlLine2."Posting Date", GenJnlLine2."Currency Code", GenJnlLine2.Amount, '',
              GenJnlLine2."Recipient Bank Account", GenJnlLine2."Message to Recipient");
        until GenJnlLine2.Next() = 0;
        Window.Close();

        OnBeforePaymentExport(GenJnlLine."Bal. Account No.", DataExch."Entry No.", LineNo, TotalAmount, TransferDate, HandledPaymentExport);
        if not HandledPaymentExport then
            PaymentExportMgt.ExportToFile(DataExch."Entry No.");

        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Gen. Jnl.", DataExch);
    end;

    local procedure CreateGenJnlDataExchLine(DataExchEntryNo: Integer; GenJnlLine: Record "Gen. Journal Line"; LineNo: Integer)
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
    begin
        with GenJnlLine do begin
            PreparePaymentExportDataJnl(TempPaymentExportData, GenJnlLine, DataExchEntryNo, LineNo);
            PaymentExportMgt.CreatePaymentLines(TempPaymentExportData);
        end;
    end;

    procedure PreparePaymentExportDataJnl(var TempPaymentExportData: Record "Payment Export Data" temporary; GenJnlLine: Record "Gen. Journal Line"; DataExchEntryNo: Integer; LineNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Employee: Record Employee;
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        IsEmployee: Boolean;
    begin
        GeneralLedgerSetup.Get();
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee then begin
            Employee.Get(GenJnlLine."Account No.");
            IsEmployee := true;
        end else begin
            GenJnlLine.TestField("Account Type", GenJnlLine."Account Type"::Vendor);
            Vendor.Get(GenJnlLine."Account No.");
        end;

        with TempPaymentExportData do begin
            BankAccount.Get(GenJnlLine."Bal. Account No.");
            BankAccount.GetBankExportImportSetup(BankExportImportSetup);
            SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");

            Init();
            "Data Exch Entry No." := DataExchEntryNo;
            "Sender Bank Account Code" := GenJnlLine."Bal. Account No.";
            "Sender Bank Name" := BankAccount.Name;

            if IsEmployee then begin
                Amount := GenJnlLine.Amount;
                "Currency Code" := GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code");
                FillPaymentExportDataFromEmployee(TempPaymentExportData, Employee);
            end else begin
                if VendorBankAccount.Get(GenJnlLine."Account No.", GenJnlLine."Recipient Bank Account") then begin
                    Amount := GenJnlLine.Amount;
                    "Currency Code" := GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code");
                    "Recipient Bank Acc. No." :=
                      CopyStr(VendorBankAccount.GetBankAccountNo(), 1, MaxStrLen("Recipient Bank Acc. No."));
                    "Recipient Reg. No." := VendorBankAccount."Bank Branch No.";
                    "Recipient Acc. No." := VendorBankAccount."Bank Account No.";
                    "Recipient Bank Country/Region" := VendorBankAccount."Country/Region Code";
                    "Recipient Bank Name" := CopyStr(VendorBankAccount.Name, 1, 35);
                    "Recipient Bank Address" := CopyStr(VendorBankAccount.Address, 1, 35);
                    "Recipient Bank City" := CopyStr(VendorBankAccount."Post Code" + VendorBankAccount.City, 1, 35);
                    "Recipient Bank BIC" := VendorBankAccount."SWIFT Code";
                    "Recipient Bank County" := VendorBankAccount.County;
                    "Recipient Bank Post Code" := VendorBankAccount."Post Code";
                end else
                    if GenJnlLine."Creditor No." <> '' then begin
                        Amount := GenJnlLine."Amount (LCY)";
                        "Currency Code" := GeneralLedgerSetup."LCY Code";
                    end;

                "Recipient Name" := CopyStr(Vendor.Name, 1, 35);
                "Recipient Address" := CopyStr(Vendor.Address, 1, 35);
                "Recipient City" := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 35);
                "Recipient Email Address" := Vendor."E-Mail";
            end;

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
            OnBeforeInsertPmtExportDataJnlFromGenJnlLine(TempPaymentExportData, GenJnlLine, GeneralLedgerSetup);
            Insert(true);
        end;
    end;

    procedure EnableExportToServerTempFile(SilentServerMode: Boolean; ServerFileExtension: Text[3])
    begin
        PaymentExportMgt.EnableExportToServerTempFile(SilentServerMode, ServerFileExtension);
    end;

    procedure GetServerTempFileName(): Text[1024]
    begin
        exit(PaymentExportMgt.GetServerTempFileName());
    end;

    local procedure FillPaymentExportDataFromEmployee(var TempPaymentExportData: Record "Payment Export Data" temporary; Employee: Record Employee)
    var
        EmployeeBankAccNo: Text;
    begin
        EmployeeBankAccNo := Employee.GetBankAccountNo();
        if EmployeeBankAccNo = '' then
            Error(EmployeeMustHaveBankAccountNoErr, Employee.FullName());

        with TempPaymentExportData do begin
            "Recipient Name" := Employee.FullName();
            "Recipient Address" := Employee.Address;
            "Recipient City" := Employee.City;
            "Recipient County" := Employee.County;
            "Recipient Post Code" := Employee."Post Code";
            "Recipient Country/Region Code" := Employee."Country/Region Code";
            "Recipient Email Address" := Employee."E-Mail";
            "Recipient Bank Acc. No." := CopyStr(EmployeeBankAccNo, 1, MaxStrLen("Recipient Bank Acc. No."));
            "Recipient Reg. No." := Employee."Bank Branch No.";
            "Recipient Acc. No." := Employee."Bank Account No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeInsertPmtExportDataJnlFromGenJnlLine(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeCreateGenJnlDataExchLine(DataExch: Record "Data Exch."; GenJournalLine: Record "Gen. Journal Line"; LineNo: Integer; var LineAmount: Decimal; var TotalAmount: Decimal; var TransferDate: Date; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforePaymentExport(BalAccountNo: Code[20]; DataExchEntryNo: Integer; LineCount: Integer; TotalAmount: Decimal; TransferDate: Date; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJnlLine(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

