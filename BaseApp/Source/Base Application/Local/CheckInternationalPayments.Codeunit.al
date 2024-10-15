codeunit 2000003 "Check International Payments"
{
    TableNo = "Payment Journal Line";

    trigger OnRun()
    var
        CheckDomesticPmt: Codeunit "Check Domestic Payments";
    begin
        TempBankAcc.DeleteAll();
        CheckPaymJnlLine.ClearErrorLog;

        // Check if there is anything to export and exit if not
        if Count = 0 then begin
            CheckPaymJnlLine.InsertErrorLog(Text003);
            CheckPaymJnlLine.ShowErrorLog;
        end;

        if FindSet() then
            repeat
                CheckDomesticPmt.CheckOwnBankAccount(Rec);
                CheckBenBankAccountNumber(Rec);
                if "Bank Account" <> '' then
                    if not TempBankAcc.Get("Bank Account") then begin
                        TempBankAcc."No." := "Bank Account";
                        TempBankAcc.Insert();
                    end;
                OnAfterCheckPaymJnlLine(Rec);
            until Next() = 0;

        // Check if exactly one bank account is used
        CheckForOnlyOneBankAcc;

        CheckPaymJnlLine.ShowErrorLog;
    end;

    var
        Country: Record "Country/Region";
        TempBankAcc: Record "Bank Account" temporary;
        BankAcc: Record "Bank Account";
        CheckPaymJnlLine: Codeunit CheckPaymJnlLine;
        Text000: Label 'Beneficiary bank account number %1 did not pass the MOD97 test in payment journal line number %2.';
        Text001: Label 'The beneficiary bank account number cannot be blank in payment journal line number %1.';
        Text002: Label 'Only one valid bank account should appear within the filter for this export protocol. ';
        Text003: Label 'There are no payment records to be processed.';
        PmtJnlManagement: Codeunit PmtJrnlManagement;
        Text005: Label 'Bank account number %1 for bank code %2 did not satisfy MOD97 test in payment journal line number %3.', Comment = 'Parameter 1 - bank account number, 2 - bank code, 3 - integer number.';

    [Scope('OnPrem')]
    procedure CheckBenBankAccountNumber(var PmtJnlLine: Record "Payment Journal Line")
    var
        CompanyInfo: Record "Company Information";
        IbanTransfer: Boolean;
    begin
        GetCountry(PmtJnlLine."Bank Country/Region Code");
        CompanyInfo.Get();
        IbanTransfer := (PmtJnlLine."Beneficiary IBAN" <> '') and Country."IBAN Country/Region";
        if not IbanTransfer then begin
            // Check if BBAN is blank
            if PmtJnlLine."Beneficiary Bank Account No." = '' then
                CheckPaymJnlLine.InsertErrorLog(StrSubstNo(Text001, PmtJnlLine."Line No."))
            else
                // MOD97 test for BBAN for Domestic Banks
                if CompanyInfo."Country/Region Code" = PmtJnlLine."Bank Country/Region Code" then
                    if not PmtJnlManagement.Mod97Test(PmtJnlLine."Beneficiary Bank Account No.") then
                        CheckPaymJnlLine.InsertErrorLog(
                          StrSubstNo(Text000, PmtJnlLine."Beneficiary Bank Account No.", PmtJnlLine."Line No."));
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckForOnlyOneBankAcc()
    begin
        if TempBankAcc.Count <> 1 then
            CheckPaymJnlLine.InsertErrorLog(Text002);
    end;

    [Scope('OnPrem')]
    procedure GetCountry(CountryCode: Code[10])
    begin
        if (Country.Code <> CountryCode) and (CountryCode <> '') then
            Country.Get(CountryCode);
    end;

    [Scope('OnPrem')]
    procedure GetBankAccount(BankAccCode: Code[20])
    begin
        if (BankAcc."No." <> BankAccCode) and (BankAccCode <> '') then
            BankAcc.Get(BankAccCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPaymJnlLine(var PaymentJournalLine: Record "Payment Journal Line")
    begin
    end;
}

