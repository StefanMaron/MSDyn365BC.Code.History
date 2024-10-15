codeunit 18688 "TDS Validations"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostGenJnlLine', '', false, false)]
    local procedure CheckPANNoValidations(var GenJournalLine: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Location: Record Location;
        CompanyInfo: Record "Company Information";
    begin
        if GenJournalLine."TDS Section Code" <> '' then begin
            if GenJournalLine."T.A.N. No." = '' then
                Error(TANNoErr);

            CompanyInfo.GET();
            CompanyInfo.TestField("T.A.N. No.");
            if GenJournalLine."Location Code" <> '' then begin
                Location.Get(GenJournalLine."Location Code");
                if Location."T.A.N. No." = '' then
                    Location.TestField("T.A.N. No.");
            end;

            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor then begin
                Vendor.get(GenJournalLine."Account No.");
                if (Vendor."P.A.N. No." = '') and (Vendor."P.A.N. Status" = Vendor."P.A.N. Status"::" ") and (Vendor."P.A.N. Reference No." = '') then
                    ERROR(PANNOErr);
                if (Vendor."P.A.N. No." = '') OR (Vendor."P.A.N. Status" <> Vendor."P.A.N. Status"::" ") then
                    if (Vendor."P.A.N. Status" <> Vendor."P.A.N. Status"::" ") and (Vendor."P.A.N. Reference No." = '') then
                        ERROR(PANReferenceNoErr, Vendor."No.");
            end
            else
                if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer then begin
                    Customer.get(GenJournalLine."Account No.");
                    if (Customer."P.A.N. No." = '') and (Customer."P.A.N. Status" = Customer."P.A.N. Status"::" ") and (Customer."P.A.N. Reference No." = '') then
                        ERROR(PANNOErr);
                    if (Customer."P.A.N. No." = '') OR (Customer."P.A.N. Status" <> Customer."P.A.N. Status"::" ") then
                        if (Customer."P.A.N. Status" <> Customer."P.A.N. Status"::" ") and (Customer."P.A.N. Reference No." = '') then
                            ERROR(PANReferenceCustomerErr, Customer."No.");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostGenJnlLine', '', false, false)]
    local procedure CheckCompanyInforDetails(var GenJournalLine: Record "Gen. Journal Line")
    var
        CompanyInfo: Record "Company Information";
        DeductorCategory: Record "Deductor Category";
    begin
        if GenJournalLine."TDS Section Code" <> '' then begin
            CompanyInfo.get();
            CompanyInfo.TestField("Deductor Category");
            DeductorCategory.GET(CompanyInfo."Deductor Category");
            if DeductorCategory."DDO Code Mandatory" then begin
                CompanyInfo.TestField("DDO Code");
                CompanyInfo.TestField("DDO Registration No.");
            end;
            if DeductorCategory."PAO Code Mandatory" then begin
                CompanyInfo.TestField("PAO Code");
                CompanyInfo.TestField("PAO Registration No.");
            end;
            if DeductorCategory."Ministry Details Mandatory" then begin
                CompanyInfo.TestField("Ministry Type");
                CompanyInfo.TestField("Ministry Code");
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostGenJnlLine', '', false, false)]
    local procedure CheckTaxAccountingPeriod(var GenJournalLine: Record "Gen. Journal Line")
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        TDSSetup: Record "TDS Setup";
        TaxType: Record "Tax Type";
        AccountingStartDate: Date;
        AccountingEndDate: Date;
    begin
        if GenJournalLine."TDS Section Code" <> '' then begin
            if not TDSSetup.Get() then
                exit;
            TDSSetup.TestField("Tax Type");

            TaxType.Get(TDSSetup."Tax Type");

            TaxAccountingPeriod.SetCurrentKey("Starting Date");
            TaxAccountingPeriod.SetRange("Tax Type Code", TaxType."Accounting Period");
            TaxAccountingPeriod.SetRange(Closed, false);
            if TaxAccountingPeriod.FindFirst() then
                AccountingStartDate := TaxAccountingPeriod."Starting Date";

            if TaxAccountingPeriod.FindLast() then
                AccountingEndDate := TaxAccountingPeriod."Ending Date";

            if (GenJournalLine."Posting Date" < AccountingStartDate) or (GenJournalLine."Posting Date" > AccountingEndDate) then
                Error(AccountingPeriodErr);
        end;
    end;

    procedure RoundTDSAmount(TDSAmount: Decimal): Decimal
    var
        TaxComponent: Record "Tax Component";
        TDSSetup: Record "TDS Setup";
        TDSRoundingDirection: Text;
    begin
        if not TDSSetup.get() then
            exit;
        TDSSetup.TestField("Tax Type");

        TaxComponent.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxComponent.SetRange(Name, TDSSetup."Tax Type");
        TaxComponent.FindFirst();
        case TaxComponent.Direction of
            TaxComponent.Direction::Nearest:
                TDSRoundingDirection := '=';
            TaxComponent.Direction::Up:
                TDSRoundingDirection := '>';
            TaxComponent.Direction::Down:
                TDSRoundingDirection := '<';
        end;
        exit(Round(TDSAmount, TaxComponent."Rounding Precision", TDSRoundingDirection));
    end;

    procedure ConvertTDSAmountToLCY(
      CurrencyCode: Code[10];
      Amount: Decimal;
      CurrencyFactor: Decimal;
      PostingDate: Date): Decimal
    var
        CurrExchRate: record "Currency Exchange Rate";
        TaxComponent: Record "Tax Component";
        TDSSetup: Record "TDS Setup";
    begin
        if not TDSSetup.Get() then
            exit;
        TDSSetup.TestField("Tax Type");
        TaxComponent.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxComponent.SetRange(Name, TDSSetup."Tax Type");
        TaxComponent.FindFirst();
        exit(Round(
        CurrExchRate.ExchangeAmtFCYToLCY(
        PostingDate, CurrencyCode, Amount, CurrencyFactor), TaxComponent."Rounding Precision"));
    end;

    var
        TANNoErr: Label 'T.A.N. No must have a value in TDS Entry';
        PANNOErr: Label 'The deductee P.A.N. No. is invalid.';
        PANReferenceNoErr: Label 'The P.A.N. Reference No. field must be filled for the Vendor No. %1', Comment = '%1 = Vendor No.';
        PANReferenceCustomerErr: Label 'The P.A.N. Reference No. field must be filled for the Customer No. %1', Comment = '%1 = Customer No.';
        AccountingPeriodErr: Label 'The Posting Date doesn''t lie in Tax Accounting Period', Locked = true;
}