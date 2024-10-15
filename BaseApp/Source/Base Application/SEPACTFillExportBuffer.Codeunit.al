codeunit 1221 "SEPA CT-Fill Export Buffer"
{
    Permissions = TableData "Payment Export Data" = rimd;
    TableNo = "Payment Export Data";

    trigger OnRun()
    begin
    end;

    var
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        FieldIsBlankErr: Label 'Field %1 must be specified.', Comment = '%1=field name, e.g. Post Code.';
        SameBankErr: Label 'All lines must have the same bank account as the balancing account.';
        RemitMsg: Label '%1 %2', Comment = '%1=Document type, %2=Document no., e.g. Invoice A123';

    procedure FillExportBuffer(var GenJnlLine: Record "Gen. Journal Line"; var PaymentExportData: Record "Payment Export Data")
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        TempInteger: Record "Integer" temporary;
        VendorBankAccount: Record "Vendor Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferEntry: Record "Credit Transfer Entry";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CHMgt: Codeunit CHMgt;
        MessageID: Code[20];
        SwissExport: Boolean;
        BatchBooking: Boolean;
    begin
        TempGenJnlLine.CopyFilters(GenJnlLine);
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Prepare Source", TempGenJnlLine);

        TempGenJnlLine.Reset();
        TempGenJnlLine.FindSet;
        BankAccount.Get(TempGenJnlLine."Bal. Account No.");
        BankAccount.TestField(IBAN);
        BankAccount.GetBankExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Check Export Codeunit");
        TempGenJnlLine.DeletePaymentFileBatchErrors;
        repeat
            CODEUNIT.Run(BankExportImportSetup."Check Export Codeunit", TempGenJnlLine);
            if TempGenJnlLine."Bal. Account No." <> BankAccount."No." then
                TempGenJnlLine.InsertPaymentFileError(SameBankErr);
        until TempGenJnlLine.Next = 0;

        if TempGenJnlLine.HasPaymentFileErrorsInBatch then begin
            Commit();
            Error(HasErrorsErr);
        end;

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");

        MessageID := BankAccount.GetCreditTransferMessageNo;
        OnFillExportBufferOnAfterGetMessageID(TempGenJnlLine, MessageID);
        CreditTransferRegister.CreateNew(MessageID, BankAccount."No.");
        SwissExport := CHMgt.IsSwissSEPACTExport(TempGenJnlLine);
        if SwissExport then
            BatchBooking := TempGenJnlLine.Count >= CHMgt.NoOfPaymentsForBatchBooking
        else
            BatchBooking := false;

        with PaymentExportData do begin
            Reset;
            if FindLast then;

            TempGenJnlLine.FindSet;
            repeat
                Init;
                "Entry No." += 1;
                SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");
                SetBankAsSenderBank(BankAccount);
                "Transfer Date" := TempGenJnlLine."Posting Date";
                "Document No." := TempGenJnlLine."Document No.";
                "Applies-to Ext. Doc. No." := TempGenJnlLine."Applies-to Ext. Doc. No.";
                "Payment Reference" := TempGenJnlLine."Payment Reference";
                Amount := TempGenJnlLine.Amount;
                if TempGenJnlLine."Currency Code" = '' then
                    "Currency Code" := GeneralLedgerSetup."LCY Code"
                else
                    "Currency Code" := TempGenJnlLine."Currency Code";

                SetSwissExport(SwissExport);
                case TempGenJnlLine."Account Type" of
                    TempGenJnlLine."Account Type"::Customer:
                        begin
                            Customer.Get(TempGenJnlLine."Account No.");
                            CustomerBankAccount.Get(Customer."No.", TempGenJnlLine."Recipient Bank Account");
                            SetCustomerAsRecipient(Customer, CustomerBankAccount);
                        end;
                    TempGenJnlLine."Account Type"::Vendor:
                        begin
                            Vendor.Get(TempGenJnlLine."Account No.");
                            VendorBankAccount.Get(Vendor."No.", TempGenJnlLine."Recipient Bank Account");
                            SetVendorAsRecipient(Vendor, VendorBankAccount);
                        end;
                    TempGenJnlLine."Account Type"::Employee:
                        begin
                            Employee.Get(TempGenJnlLine."Account No.");
                            SetEmployeeAsRecipient(Employee);
                        end;
                    else
                        OnFillExportBufferOnSetAsRecipient(GenJnlLine, PaymentExportData, TempGenJnlLine);
                end;

                Validate("SEPA Instruction Priority", "SEPA Instruction Priority"::NORMAL);
                Validate("SEPA Payment Method", "SEPA Payment Method"::TRF);
                ValidateSEPAChargeBearer(PaymentExportData, TempGenJnlLine, SwissExport);
                "SEPA Batch Booking" := BatchBooking;
                SetCreditTransferIDs(MessageID);

                if SwissExport and ("Swiss Payment Type" = "Swiss Payment Type"::"1") then
                    AddRemittanceText(TempGenJnlLine."Reference No.")
                else begin
                    if "Applies-to Ext. Doc. No." <> '' then
                        AddRemittanceText(StrSubstNo(RemitMsg, TempGenJnlLine."Applies-to Doc. Type", "Applies-to Ext. Doc. No."))
                    else
                        AddRemittanceText(TempGenJnlLine.Description);
                    if TempGenJnlLine."Message to Recipient" <> '' then
                        AddRemittanceText(TempGenJnlLine."Message to Recipient");
                end;

                ValidatePaymentExportData(PaymentExportData, TempGenJnlLine, SwissExport);
                OnFillExportBufferOnBeforeInsertPaymentExportData(PaymentExportData, TempGenJnlLine);
                Insert(true);
                TempInteger.DeleteAll();
                GetAppliesToDocEntryNumbers(TempGenJnlLine, TempInteger);
                if TempInteger.FindSet then
                    repeat
                        CreditTransferEntry.CreateNew(
                          CreditTransferRegister."No.", 0,
                          TempGenJnlLine."Account Type", TempGenJnlLine."Account No.",
                          TempInteger.Number,
                          "Transfer Date", "Currency Code", Amount, CopyStr("End-to-End ID", 1, MaxStrLen("End-to-End ID")),
                          TempGenJnlLine."Recipient Bank Account", TempGenJnlLine."Message to Recipient");
                    until TempInteger.Next = 0
                else
                    CreditTransferEntry.CreateNew(
                      CreditTransferRegister."No.", "Entry No.",
                      TempGenJnlLine."Account Type", TempGenJnlLine."Account No.",
                      TempGenJnlLine.GetAppliesToDocEntryNo,
                      "Transfer Date", "Currency Code", Amount, CopyStr("End-to-End ID", 1, MaxStrLen("End-to-End ID")),
                      TempGenJnlLine."Recipient Bank Account", TempGenJnlLine."Message to Recipient");
            until TempGenJnlLine.Next = 0;
        end;
    end;

    local procedure GetAppliesToDocEntryNumbers(GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record "Integer" temporary)
    var
        AccNo: Code[20];
        AccType: Enum "Gen. Journal Account Type";
    begin
        with GenJournalLine do
            if "Bal. Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee] then begin
                AccType := "Bal. Account Type";
                AccNo := "Bal. Account No.";
            end else begin
                AccType := "Account Type";
                AccNo := "Account No.";
            end;
        case AccType of
            GenJournalLine."Account Type"::Customer:
                GetAppliesToDocCustLedgEntries(GenJournalLine, TempInteger, AccNo);
            GenJournalLine."Account Type"::Vendor:
                GetAppliesToDocVendLedgEntries(GenJournalLine, TempInteger, AccNo);
            GenJournalLine."Account Type"::Employee:
                GetAppliesToDocEmplLedgEntries(GenJournalLine, TempInteger, AccNo);
        end;
    end;

    local procedure GetAppliesToDocCustLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record "Integer" temporary; AccNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgEntry do begin
            SetCurrentKey("Customer No.", "Document No.");
            SetRange("Customer No.", AccNo);
            SetRange(Open, true);
            case true of
                GenJournalLine."Applies-to Doc. No." <> '':
                    begin
                        SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                        SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                    end;
                GenJournalLine."Applies-to ID" <> '':
                    begin
                        SetCurrentKey("Customer No.", "Applies-to ID");
                        SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                    end;
                else
                    exit;
            end;
        end;
        GetEntriesFromSet(TempInteger, CustLedgEntry);
    end;

    local procedure GetAppliesToDocVendLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record "Integer" temporary; AccNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            SetCurrentKey("Vendor No.", "Document No.");
            SetRange("Vendor No.", AccNo);
            SetRange(Open, true);
            case true of
                GenJournalLine."Applies-to Doc. No." <> '':
                    begin
                        SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                        SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                    end;
                GenJournalLine."Applies-to ID" <> '':
                    begin
                        SetCurrentKey("Vendor No.", "Applies-to ID");
                        SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                    end;
                else
                    exit;
            end;
        end;
        GetEntriesFromSet(TempInteger, VendLedgEntry);
    end;

    local procedure GetAppliesToDocEmplLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record "Integer" temporary; AccNo: Code[20])
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
    begin
        with EmplLedgEntry do begin
            SetCurrentKey("Employee No.", "Document No.");
            SetRange("Employee No.", AccNo);
            SetRange(Open, true);
            case true of
                GenJournalLine."Applies-to Doc. No." <> '':
                    begin
                        SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                        SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                    end;
                GenJournalLine."Applies-to ID" <> '':
                    begin
                        SetCurrentKey("Employee No.", "Applies-to ID");
                        SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                    end;
                else
                    exit;
            end;
        end;
        GetEntriesFromSet(TempInteger, EmplLedgEntry);
    end;

    local procedure GetEntriesFromSet(var TempInteger: Record "Integer" temporary; RecVariant: Variant)
    var
        FieldRef: FieldRef;
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(RecVariant);
        FieldRef := RecordRef.FieldIndex(1);
        with RecordRef do begin
            if FindSet then
                repeat
                    TempInteger.Number := FieldRef.Value;
                    TempInteger.Insert();
                until Next = 0;
        end;
    end;

    local procedure ValidatePaymentExportData(var PaymentExportData: Record "Payment Export Data"; var GenJnlLine: Record "Gen. Journal Line"; SwissExport: Boolean)
    begin
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Sender Bank Account No."));
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Recipient Name"));
        ValidateRecipientBankAccNo(PaymentExportData, GenJnlLine, SwissExport);
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Transfer Date"));
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Payment Information ID"));
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("End-to-End ID"));
    end;

    local procedure ValidatePaymentExportDataField(var PaymentExportData: Record "Payment Export Data"; var GenJnlLine: Record "Gen. Journal Line"; FieldName: Text)
    var
        "Field": Record "Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(PaymentExportData);
        Field.SetRange(TableNo, RecRef.Number);
        Field.SetRange(FieldName, FieldName);
        Field.FindFirst;
        FieldRef := RecRef.Field(Field."No.");
        if (Field.Type = Field.Type::Text) and (Format(FieldRef.Value) <> '') then
            exit;
        if (Field.Type = Field.Type::Code) and (Format(FieldRef.Value) <> '') then
            exit;
        if (Field.Type = Field.Type::Decimal) and (Format(FieldRef.Value) <> '0') then
            exit;
        if (Field.Type = Field.Type::Integer) and (Format(FieldRef.Value) <> '0') then
            exit;
        if (Field.Type = Field.Type::Date) and (Format(FieldRef.Value) <> '0D') then
            exit;

        PaymentExportData.AddGenJnlLineErrorText(GenJnlLine, StrSubstNo(FieldIsBlankErr, Field."Field Caption"));
    end;

    local procedure ValidateRecipientBankAccNo(var PaymentExportData: Record "Payment Export Data"; var GenJournalLine: Record "Gen. Journal Line"; SwissExport: Boolean)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if SwissExport and (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) then
            case PaymentExportData."Swiss Payment Type" of
                PaymentExportData."Swiss Payment Type"::"1", PaymentExportData."Swiss Payment Type"::"2.1":
                    ValidatePaymentExportDataField(PaymentExportData, GenJournalLine, PaymentExportData.FieldName("Recipient Acc. No."));
                PaymentExportData."Swiss Payment Type"::"2.2":
                    ValidatePaymentExportDataField(PaymentExportData, GenJournalLine, PaymentExportData.FieldName("Recipient Bank Acc. No."));
                PaymentExportData."Swiss Payment Type"::"6":
                    begin
                        VendorBankAccount.Get(GenJournalLine."Account No.", GenJournalLine."Recipient Bank Account");
                        if VendorBankAccount.IBAN = '' then
                            ValidatePaymentExportDataField(PaymentExportData, GenJournalLine, PaymentExportData.FieldName("Recipient Acc. No."))
                        else
                            ValidatePaymentExportDataField(
                              PaymentExportData, GenJournalLine, PaymentExportData.FieldName("Recipient Bank Acc. No."));
                    end;
            end
        else
            ValidatePaymentExportDataField(PaymentExportData, GenJournalLine, PaymentExportData.FieldName("Recipient Bank Acc. No."));
    end;

    local procedure ValidateSEPAChargeBearer(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line"; SwissExport: Boolean)
    begin
        if SwissExport and (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) and
           (PaymentExportData."Swiss Payment Type" <> PaymentExportData."Swiss Payment Type"::"5")
        then
            case GenJournalLine."Payment Fee Code" of
                GenJournalLine."Payment Fee Code"::" ":
                    PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::SLEV);
                GenJournalLine."Payment Fee Code"::Beneficiary:
                    PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::CRED);
                GenJournalLine."Payment Fee Code"::Own:
                    PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::DEBT);
                GenJournalLine."Payment Fee Code"::Share:
                    PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::SHAR);
            end
        else
            PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::SLEV);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnAfterGetMessageID(var TempGenJnlLine: Record "Gen. Journal Line" temporary; var MessageID: code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnBeforeInsertPaymentExportData(var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnSetAsRecipient(var GenJnlLine: Record "Gen. Journal Line"; var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;
}

