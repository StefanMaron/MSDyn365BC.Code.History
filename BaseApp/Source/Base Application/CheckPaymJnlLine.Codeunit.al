codeunit 2000001 CheckPaymJnlLine
{
    TableNo = "Payment Journal Line";

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'There are payment journal lines with different posting dates.';
        Text002: Label ' is not within your range of allowed posting dates';
        GLSetup: Record "General Ledger Setup";
        ExportCheckErrorLog: Record "Export Check Error Log" temporary;
        TempGroupPmtJnlLine: Record "Payment Journal Line" temporary;
        Country: Record "Country/Region";
        BankAcc: Record "Bank Account";
        ErrorId: Integer;
        Text003: Label 'The export number series cannot be blank in export protocol %1.';
        Text004: Label 'There are no payment records to be processed.';
        Text005: Label 'The amount must be positive for %1 %2 and beneficiary bank account %3.', Comment = 'Parameter 1 - account type (,Customer,Vendor), 2 - account number, 3 - beneficiary bank account number.';
        Text006: Label 'The currency must be euro in payment journal line number %1.';
        Text007: Label 'The currency cannot be euro in payment journal line number %1.';
        Text010: Label 'The %1 field cannot be blank in payment journal line number %2.';
        Text011: Label 'The %1 field cannot be blank for bank account number %2 in payment journal line number %3.';
        Text012: Label 'The SEPA Allowed field cannot be %1 for country/region code %2 in payment journal line number %3.', Comment = 'Parameter 1 - boolean value, 2 - country\region code, 3 - integer number.';
        Text013: Label 'Company name cannot be blank.';
        Text014: Label 'The Name field cannot be blank for customer %1 in payment journal line number %2.';
        Text015: Label 'The Name field cannot be blank for vendor %1 in payment journal line number %2.';

    [Scope('OnPrem')]
    procedure CheckPostingDate(var PaymentJnlLine: Record "Payment Journal Line"; TemplateName: Code[20])
    var
        PaymJnlLine: Record "Payment Journal Line";
        CheckJnlLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        with PaymJnlLine do begin
            Reset;
            CopyFilters(PaymentJnlLine);
            if Find('-') then
                SetRange("Posting Date", "Posting Date");
            if Count <> PaymentJnlLine.Count then
                Error(Text001);
            SetRange("Posting Date");
            if Find('-') then
                repeat
                    TestField("Posting Date");
                    if CheckJnlLine.DateNotAllowed("Posting Date", TemplateName) then
                        FieldError("Posting Date", Text002);
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure Init()
    begin
        GLSetup.Get;
        ClearErrorLog;
        TempGroupPmtJnlLine.Reset;
        TempGroupPmtJnlLine.DeleteAll;
    end;

    [Scope('OnPrem')]
    procedure ClearErrorLog()
    begin
        ExportCheckErrorLog.Reset;
        ExportCheckErrorLog.DeleteAll;
    end;

    procedure InsertErrorLog(ErrorMessage: Text[250])
    begin
        if ExportCheckErrorLog.FindLast then
            ErrorId := ExportCheckErrorLog."Entry No." + 1
        else
            ErrorId := 1;

        ExportCheckErrorLog.Init;
        ExportCheckErrorLog."Entry No." := ErrorId;
        ExportCheckErrorLog."Error Message" := ErrorMessage;
        ExportCheckErrorLog.Insert;
    end;

    [Scope('OnPrem')]
    procedure ShowErrorLog()
    begin
        if not ExportCheckErrorLog.IsEmpty then begin
            PAGE.Run(PAGE::"Export Check Error Logs", ExportCheckErrorLog);
            Error('');
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckExportProtocol(ExportProtocolCode: Code[20])
    var
        ExportProtocol: Record "Export Protocol";
    begin
        ExportProtocol.Get(ExportProtocolCode);
        if ExportProtocol."Export No. Series" = '' then
            InsertErrorLog(StrSubstNo(Text003, ExportProtocol.Code));
    end;

    [Scope('OnPrem')]
    procedure ErrorNoPayments()
    begin
        InsertErrorLog(Text004);
    end;

    [Scope('OnPrem')]
    procedure FillGroupLineAmountBuf(PmtJnlLine: Record "Payment Journal Line")
    var
        LastLineNo: Integer;
    begin
        with TempGroupPmtJnlLine do begin
            Reset;
            if FindLast then
                LastLineNo := "Line No.";

            SetRange("Account Type", PmtJnlLine."Account Type");
            SetRange("Account No.", PmtJnlLine."Account No.");
            SetRange("Bank Account", PmtJnlLine."Bank Account");
            SetRange("Beneficiary Bank Account", PmtJnlLine."Beneficiary Bank Account");
            SetRange("Separate Line", PmtJnlLine."Separate Line");
            OnFillGroupLineAmountBufOnAfterApplyFilters(TempGroupPmtJnlLine, PmtJnlLine);
            if not FindFirst or PmtJnlLine."Separate Line" then begin
                Init;
                "Line No." := LastLineNo + 1;
                "Account Type" := PmtJnlLine."Account Type";
                "Account No." := PmtJnlLine."Account No.";
                "Bank Account" := PmtJnlLine."Bank Account";
                "Beneficiary Bank Account" := PmtJnlLine."Beneficiary Bank Account";
                "Separate Line" := PmtJnlLine."Separate Line";
                OnFillGroupLineAmountBufOnBeforeInsert(TempGroupPmtJnlLine, PmtJnlLine);
                Insert;
            end;
            Amount := Amount + PmtJnlLine.Amount;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckTotalLineAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTotalLineAmounts(TempGroupPmtJnlLine, IsHandled);
        if IsHandled then
            exit;

        with TempGroupPmtJnlLine do begin
            Reset;
            SetFilter(Amount, '<=%1', 0);
            if FindSet then
                repeat
                    InsertErrorLog(
                      StrSubstNo(Text005, "Account Type", "Account No.", "Beneficiary Bank Account"));
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ErrorIfCurrencyNotEuro(PmtJnlLine: Record "Payment Journal Line")
    begin
        if PmtJnlLine."Currency Code" <> GLSetup."Currency Euro" then
            InsertErrorLog(StrSubstNo(Text006, PmtJnlLine."Line No."));
    end;

    [Scope('OnPrem')]
    procedure ErrorIfCurrencyEuro(PmtJnlLine: Record "Payment Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeErrorIfCurrencyEuro(PmtJnlLine, IsHandled);
        if IsHandled then
            exit;

        if PmtJnlLine."Currency Code" = GLSetup."Currency Euro" then
            InsertErrorLog(StrSubstNo(Text007, PmtJnlLine."Line No."));
    end;

    [Scope('OnPrem')]
    procedure CheckBankForSEPA(PmtJnlLine: Record "Payment Journal Line")
    begin
        with PmtJnlLine do
            if not ErrorEmptyFieldInLine("Line No.", "Bank Account", FieldCaption("Bank Account")) then begin
                GetBankAccount("Bank Account");
                ErrorEmptyFieldInBank(PmtJnlLine, BankAcc.IBAN, BankAcc.FieldCaption(IBAN));
                ErrorEmptyFieldInBank(PmtJnlLine, BankAcc."SWIFT Code", BankAcc.FieldCaption("SWIFT Code"));

                if not ErrorEmptyFieldInBank(PmtJnlLine, BankAcc."Country/Region Code", BankAcc.FieldCaption("Country/Region Code")) then
                    CheckSEPAAllowed(true, "Line No.", BankAcc."Country/Region Code");
            end;
    end;

    [Scope('OnPrem')]
    procedure CheckBeneficiaryBankForSEPA(PmtJnlLine: Record "Payment Journal Line"; EuroSEPA: Boolean)
    begin
        with PmtJnlLine do begin
            CheckIBANForSEPA(PmtJnlLine, EuroSEPA);
            ErrorEmptyFieldInLine("Line No.", "SWIFT Code", FieldCaption("SWIFT Code"));

            if not ErrorEmptyFieldInLine("Line No.", "Bank Country/Region Code", FieldCaption("Bank Country/Region Code")) then
                CheckSEPAAllowed(EuroSEPA, "Line No.", "Bank Country/Region Code");
        end;
    end;

    local procedure CheckIBANForSEPA(PmtJnlLine: Record "Payment Journal Line"; EuroSEPA: Boolean)
    var
        IBANTransfer: Boolean;
    begin
        with PmtJnlLine do
            if EuroSEPA then
                ErrorEmptyFieldInLine("Line No.", "Beneficiary IBAN", FieldCaption("Beneficiary IBAN"))
            else begin
                GetCountry("Bank Country/Region Code");
                IBANTransfer := ("Beneficiary IBAN" <> '') and Country."IBAN Country/Region";
                if not IBANTransfer then
                    ErrorEmptyFieldInLine("Line No.", "Beneficiary Bank Account No.", FieldCaption("Beneficiary Bank Account No."));
            end;
    end;

    local procedure CheckSEPAAllowed(RequiredSEPAAllowed: Boolean; PmtJnlLineNo: Integer; CountryRegionCode: Code[10])
    begin
        GetCountry(CountryRegionCode);
        if not Country."SEPA Allowed" and RequiredSEPAAllowed then
            InsertErrorLog(StrSubstNo(Text012, Country."SEPA Allowed", CountryRegionCode, PmtJnlLineNo));
    end;

    local procedure ErrorEmptyFieldInLine(PmtJnlLineNo: Integer; Value: Text[50]; Caption: Text[30]): Boolean
    begin
        if Value = '' then begin
            InsertErrorLog(StrSubstNo(Text010, Caption, PmtJnlLineNo));
            exit(true);
        end;
    end;

    local procedure ErrorEmptyFieldInBank(PmtJnlLine: Record "Payment Journal Line"; Value: Text[50]; Caption: Text[30]): Boolean
    begin
        if Value = '' then begin
            InsertErrorLog(StrSubstNo(Text011, Caption, PmtJnlLine."Bank Account", PmtJnlLine."Line No."));
            exit(true);
        end;
    end;

    local procedure GetCountry(CountryCode: Code[10])
    begin
        if (Country.Code <> CountryCode) and (CountryCode <> '') then
            Country.Get(CountryCode);
    end;

    local procedure GetBankAccount(BankAccCode: Code[20])
    begin
        if (BankAcc."No." <> BankAccCode) and (BankAccCode <> '') then
            BankAcc.Get(BankAccCode);
    end;

    [Scope('OnPrem')]
    procedure CheckCompanyName()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get;
        if DelChr(CompanyInfo.Name) = '' then
            InsertErrorLog(Text013);
    end;

    [Scope('OnPrem')]
    procedure CheckCustVendName(var PmtJnlLine: Record "Payment Journal Line")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case PmtJnlLine."Account Type" of
            PmtJnlLine."Account Type"::Vendor:
                if Vendor.Get(PmtJnlLine."Account No.") then
                    if DelChr(Vendor.Name) = '' then
                        InsertErrorLog(StrSubstNo(Text015, Vendor."No.", PmtJnlLine."Line No."));
            PmtJnlLine."Account Type"::Customer:
                if Customer.Get(PmtJnlLine."Account No.") then
                    if DelChr(Customer.Name) = '' then
                        InsertErrorLog(StrSubstNo(Text014, Customer."No.", PmtJnlLine."Line No."));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTotalLineAmounts(var PaymentJournalLine: Record "Payment Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfCurrencyEuro(var PaymentJnlLine: Record "Payment Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillGroupLineAmountBufOnAfterApplyFilters(var TempGroupPaymentJournalLine: Record "Payment Journal Line" temporary; PaymentJournalLine: Record "Payment Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillGroupLineAmountBufOnBeforeInsert(var TempGroupPaymentJournalLine: Record "Payment Journal Line" temporary; PaymentJournalLine: Record "Payment Journal Line")
    begin
    end;
}

