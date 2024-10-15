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
        ProgressMsg: Label 'Processing line no. #1######.';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        PaymentExportMgt: Codeunit "Payment Export Mgt";

    [Scope('OnPrem')]
    procedure ExportJournalPaymentFileYN(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if GenJnlLine.IsExportedToPaymentFile then
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
        GenJnlLine.DeletePaymentFileBatchErrors;
        GenJnlLine2.CopyFilters(GenJnlLine);
        if GenJnlLine2.FindSet then
            repeat
                CODEUNIT.Run(CODEUNIT::"Payment Export Gen. Jnl Check", GenJnlLine2);
                OnCheckGenJnlLine(GenJnlLine2);
            until GenJnlLine2.Next() = 0;

        if GenJnlLine2.HasPaymentFileErrorsInBatch then begin
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
              GenJnlLine2."Account Type", GenJnlLine2."Account No.", GenJnlLine2.GetAppliesToDocEntryNo,
              GenJnlLine2."Posting Date", GenJnlLine2."Currency Code", GenJnlLine2.Amount, '',
              GenJnlLine2."Recipient Bank Account", GenJnlLine2."Message to Recipient");
        until GenJnlLine2.Next() = 0;
        Window.Close;

        OnBeforePaymentExport(GenJnlLine."Bal. Account No.", DataExch."Entry No.", LineNo, TotalAmount, TransferDate, HandledPaymentExport);
        if not HandledPaymentExport then
            PaymentExportMgt.ExportToFile(DataExch."Entry No.");

        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Gen. Jnl.", DataExch);
    end;

    local procedure CreateGenJnlDataExchLine(DataExchEntryNo: Integer; GenJnlLine: Record "Gen. Journal Line"; LineNo: Integer)
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
    begin
        with GenJnlLine do begin
            DataExch.Get(DataExchEntryNo);
            DataExchDef.Get(DataExch."Data Exch. Def Code");
            if DataExchDef."Columns as Rows" then
                UpdatePmtExportData(TempPaymentExportData, GenJnlLine, DataExchEntryNo, LineNo)
            else
                PreparePaymentExportDataJnl(TempPaymentExportData, GenJnlLine, DataExchEntryNo, LineNo);
            PaymentExportMgt.CreatePaymentLines(TempPaymentExportData);
        end;
    end;

    local procedure UpdatePmtExportData(var TempPaymentExportData: Record "Payment Export Data" temporary; GenJnlLine: Record "Gen. Journal Line"; DataExchEntryNo: Integer; LineNo: Integer)
    var
        BankAcc: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        PaymentMethod: Record "Payment Method";
    begin
        CompanyInfo.Get();
        BankAcc.Get(GenJnlLine."Bal. Account No.");
        with TempPaymentExportData do begin
            Init;
            "Data Exch Entry No." := DataExchEntryNo;
            "Document No." := GenJnlLine."Document No.";
            "Transfer Date" := GenJnlLine."Posting Date";
            Amount := GenJnlLine.Amount;
            "Currency Code" := GenJnlLine."Currency Code";
            if PaymentMethod.Get(GenJnlLine."Payment Method Code") then
                "Data Exch. Line Def Code" := PaymentMethod."Pmt. Export Line Definition";
            "Line No." := LineNo;
            "Sender Name" := CompanyInfo.Name;
            "Sender VAT Reg. No." := CompanyInfo."VAT Registration No.";
            "Sender Bank Account No." := BankAcc."Bank Account No.";
            "Sender Bank Name" := BankAcc.Name;
            "Sender Bank City" := BankAcc.City;
            "Sender Bank BIC" := BankAcc."Bank BIC";
            "Sender Transit No." := BankAcc."Bank Corresp. Account No.";
            "Payment Method" := GenJnlLine."Payment Method";
            "Payment Variant" := GenJnlLine."Payment Type";
            "Payment Subsequence" := GenJnlLine."Payment Subsequence";
            "Payment Purpose" := GenJnlLine."Payment Purpose";
            "Payment Code" := GenJnlLine."Payment Code";
            "Message to Recipient 1" := CopyStr(GenJnlLine."Cash Order Including", 1, MaxStrLen("Message to Recipient 1"));
            "Message to Recipient 2" := CopyStr(GenJnlLine."Cash Order Supplement", 1, MaxStrLen("Message to Recipient 2"));
            "Creation Date" := Today;
            "Creation Time" := Format(Time);
            "Starting Date" := GenJnlLine."Posting Date";
            "Ending Date" := GenJnlLine."Posting Date";
            Insert;
        end;
        with GenJnlLine do
            case "Account Type" of
                "Account Type"::Vendor:
                    UpdatePmtExportDataFromVend(TempPaymentExportData, "Account No.", "Beneficiary Bank Code");
                "Account Type"::Customer:
                    UpdatePmtExportDataFromCust(TempPaymentExportData, "Account No.", "Beneficiary Bank Code");
                "Account Type"::"G/L Account":
                    UpdatePmtExportDataFromGLAcc(TempPaymentExportData, "Beneficiary Bank Code");
            end;
    end;

    local procedure UpdatePmtExportDataFromVend(var TempPaymentExportData: Record "Payment Export Data" temporary; VendorNo: Code[20]; VendorBankAccNo: Code[20])
    var
        VendorBankAcc: Record "Vendor Bank Account";
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        VendorBankAcc.Get(VendorNo, VendorBankAccNo);
        with TempPaymentExportData do begin
            "Recipient VAT Reg. No." := Vendor."VAT Registration No.";
            "Recipient Name" := Vendor.Name;
            "Recipient Bank Acc. No." := VendorBankAcc."Bank Account No.";
            "Recipient Bank Name" := VendorBankAcc.Name;
            "Recipient Bank City" := VendorBankAcc.City;
            "Recipient Bank BIC" := VendorBankAcc.BIC;
            "Recipient Transit No." := VendorBankAcc."Bank Corresp. Account No.";
            Modify;
        end;
    end;

    local procedure UpdatePmtExportDataFromCust(var TempPaymentExportData: Record "Payment Export Data" temporary; CustomerNo: Code[20]; CustomerBankAccNo: Code[20])
    var
        CustomerBankAcc: Record "Customer Bank Account";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        CustomerBankAcc.Get(CustomerNo, CustomerBankAccNo);
        with TempPaymentExportData do begin
            "Recipient VAT Reg. No." := Customer."VAT Registration No.";
            "Recipient Name" := Customer.Name;
            "Recipient Bank Acc. No." := CustomerBankAcc."Bank Account No.";
            "Recipient Bank Name" := CustomerBankAcc.Name;
            "Recipient Bank City" := CustomerBankAcc.City;
            "Recipient Bank BIC" := CustomerBankAcc.BIC;
            "Recipient Transit No." := CustomerBankAcc."Bank Corresp. Account No.";
            Modify;
        end;
    end;

    local procedure UpdatePmtExportDataFromGLAcc(var TempPaymentExportData: Record "Payment Export Data" temporary; BankAccDetailsCode: Code[20])
    var
        BankAccDetails: Record "Bank Account Details";
    begin
        BankAccDetails.Get(BankAccDetailsCode);
        with TempPaymentExportData do begin
            "Recipient VAT Reg. No." := BankAccDetails."VAT Registration No.";
            "Recipient Name" := BankAccDetails."G/L Account Name";
            "Recipient Bank Acc. No." := BankAccDetails."Bank Account No.";
            "Recipient Bank Name" := BankAccDetails."Bank Name";
            "Recipient Bank City" := BankAccDetails."Bank City";
            "Recipient Bank BIC" := BankAccDetails."Bank BIC";
            "Recipient Transit No." := BankAccDetails."Transit No.";
            Modify;
        end;
    end;

    procedure PreparePaymentExportDataJnl(var TempPaymentExportData: Record "Payment Export Data" temporary; GenJnlLine: Record "Gen. Journal Line"; DataExchEntryNo: Integer; LineNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GeneralLedgerSetup.Get();
        Vendor.Get(GenJnlLine."Account No.");

        with TempPaymentExportData do begin
            BankAccount.Get(GenJnlLine."Bal. Account No.");
            BankAccount.GetBankExportImportSetup(BankExportImportSetup);
            SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");

            Init;
            "Data Exch Entry No." := DataExchEntryNo;
            "Sender Bank Account Code" := GenJnlLine."Bal. Account No.";
            "Sender Bank Name" := BankAccount.Name;

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
        exit(PaymentExportMgt.GetServerTempFileName);
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

