codeunit 18807 "TCS Management"
{
    procedure OpenTCSEntries(FromEntry: Integer; ToEntry: Integer)
    var
        TCSEntries: Record "TCS Entry";
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Entry No.", FromEntry, ToEntry);
        if GLEntry.FindFirst() then begin
            TCSEntries.SetRange("Transaction No.", GLEntry."Transaction No.");
            PAGE.RUN(0, TCSEntries);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnbeforePostGenJnlLine', '', false, false)]
    local procedure CheckTCSValidation(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."TCS Nature of Collection" <> '' then begin
            CheckPANValidatins(GenJournalLine);
            CheckCompInfoDetails();
            CheckTaxAccountingPeriod(GenJournalLine);
        END;
    end;

    local procedure CheckPANValidatins(GenJournalLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
    begin
        GenJournalLine.TestField("T.C.A.N. No.");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer then
            Customer.get(GenJournalLine."Account No.")
        else
            Customer.get(GenJournalLine."Bal. Account No.");
        IF STRLEN(Customer."P.A.N. No.") <> 10 then
            ERROR(PANNOErr);
        IF (Customer."P.A.N. No." = '') OR (Customer."P.A.N. Status" <> Customer."P.A.N. Status"::" ") then
            IF (Customer."P.A.N. Status" <> Customer."P.A.N. Status"::" ") AND (Customer."P.A.N. Reference No." = '') then
                ERROR(PANReferenceEmptyErr);
    end;

    local procedure CheckCompInfoDetails()
    var
        CompanyInfo: Record "Company Information";
        DeductorCategory: Record "Deductor Category";
    begin
        CompanyInfo.get();
        CompanyInfo.TestField("Deductor Category");
        CompanyInfo.TestField("T.C.A.N. No.");
        CompanyInfo.TestField("P.A.N. No.");
        CompanyInfo.TestField("State Code");
        CompanyInfo.TestField("Post Code");
        DeductorCategory.GET(CompanyInfo."Deductor Category");
        IF DeductorCategory."DDO Code Mandatory" then begin
            CompanyInfo.TestField("DDO Code");
            CompanyInfo.TestField("DDO Registration No.");
        END;
        IF DeductorCategory."PAO Code Mandatory" then begin
            CompanyInfo.TestField("PAO Code");
            CompanyInfo.TestField("PAO Registration No.");
        END;
        IF DeductorCategory."Ministry Details Mandatory" then begin
            CompanyInfo.TestField("Ministry Type");
            CompanyInfo.TestField("Ministry Code");
        END
    end;

    local procedure CheckTaxAccountingPeriod(GeneralJnlLine: Record "Gen. Journal Line")
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        TCSSetup: Record "TCS Setup";
        TaxType: Record "Tax Type";
        AccountingStartDate: Date;
        AccountingEndDate: Date;
    begin
        if not TCSSetup.Get() then
            exit;
        TCSSetup.TestField("Tax Type");

        TaxType.Get(TCSSetup."Tax Type");

        TaxAccountingPeriod.SetCurrentKey("Starting Date");
        TaxAccountingPeriod.SetRange("Tax Type Code", TaxType."Accounting Period");
        TaxAccountingPeriod.SetRange(Closed, false);
        if TaxAccountingPeriod.FindFirst() then
            AccountingStartDate := TaxAccountingPeriod."Starting Date";

        if TaxAccountingPeriod.FindLast() then
            AccountingEndDate := TaxAccountingPeriod."Ending Date";

        if (GeneralJnlLine."Posting Date" < AccountingStartDate) or (GeneralJnlLine."Posting Date" > AccountingEndDate) then
            Error(AccountingPeriodErr);
    end;

    procedure ConvertTCSAmountToLCY(
       CurrencyCode: Code[10];
       Amount: Decimal;
       CurrencyFactor: Decimal;
       PostingDate: Date): Decimal
    var
        CurrExchRate: record "Currency Exchange Rate";
        TaxComponent: Record "Tax Component";
        TCSSetup: Record "TCS Setup";
    begin
        if not TCSSetup.get() then
            exit;
        TCSSetup.TestField("Tax Type");

        TaxComponent.SetRange("Tax Type", TCSSetup."Tax Type");
        TaxComponent.SetRange(Name, TCSSetup."Tax Type");
        TaxComponent.FindFirst();
        exit(ROUND(
        CurrExchRate.ExchangeAmtFCYToLCY(
        PostingDate, CurrencyCode, Amount, CurrencyFactor), TaxComponent."Rounding Precision"));
    end;

    procedure RoundTCSAmount(TCSAmount: Decimal): Decimal
    var
        TaxComponent: Record "Tax Component";
        TCSSetup: Record "TCS Setup";
        TCSRoundingDirection: Text;
    begin
        if not TCSSetup.get() then
            exit;
        TCSSetup.TestField("Tax Type");

        TaxComponent.SetRange("Tax Type", TCSSetup."Tax Type");
        TaxComponent.SetRange(Name, TCSSetup."Tax Type");
        TaxComponent.FindFirst();
        case TaxComponent.Direction of
            TaxComponent.Direction::Nearest:
                TCSRoundingDirection := '=';
            TaxComponent.Direction::Up:
                TCSRoundingDirection := '>';
            TaxComponent.Direction::Down:
                TCSRoundingDirection := '<';
        end;
        exit(ROUND(TCSAmount, TaxComponent."Rounding Precision", TCSRoundingDirection));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Account No.', false, false)]
    local procedure AssignNOCGenJnlLine(var Rec: Record "Gen. Journal Line")
    var
        AllowedNOC: Record "Allowed NOC";
    begin
        if Rec."Account Type" <> Rec."Account Type"::Customer then
            exit;
        AllowedNOC.SetRange("Customer No.", Rec."Account No.");
        AllowedNOC.SetRange(AllowedNOC."Default Noc", true);
        if not AllowedNOC.FindFirst() then
            Rec.Validate("TCS Nature of Collection", '')
        else
            if Rec."Account Type" = Rec."Account Type"::Customer then
                Rec.Validate("TCS Nature of Collection", AllowedNOC."TCS Nature of Collection");
    end;

    [EventSubscriber(ObjectType::Table, database::"Gen. Journal Line", 'OnAfterValidateEvent', 'TCS Nature of Collection', false, false)]
    local procedure ChecKDefinedNOC(var Rec: Record "Gen. Journal Line")
    var
        AllowedNOC: Record "Allowed NOC";
        CompanyInfo: Record "Company Information";
        Location: Record Location;
        TCSNOC: Record "TCS Nature Of Collection";
    begin
        if Rec."TCS Nature of Collection" <> '' then begin
            if Rec."Account Type" <> Rec."Account Type"::Customer then
                Error(NOCAccountTypeErr, Rec.FieldCaption("TCS Nature of Collection"), Rec.FieldCaption("Account Type"), Rec."Account Type");

            if not TCSNOC.Get(Rec."TCS Nature of Collection") then
                Error(NOCTypeErr, Rec."TCS Nature of Collection", TCSNOC.TableCaption());

            if not AllowedNOC.Get(Rec."Account No.", Rec."TCS Nature of Collection") then
                Error(TCSNOCErr, Rec."TCS Nature of Collection", Rec."Account No.");

            CompanyInfo.GET();
            Rec.Validate("T.C.A.N. No.", CompanyInfo."T.C.A.N. No.");
            IF Rec."Location Code" <> '' then begin
                Location.GET(Rec."Location Code");
                Rec.Validate("T.C.A.N. No.", Location."T.C.A.N. No.");
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Account Type', false, false)]
    local procedure ClearTCSFields(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line")
    begin
        if xRec."Account Type" = xRec."Account Type"::Customer then
            Rec.Validate("TCS Nature of Collection", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Tax Document GL Posting", 'OnPrepareTransValueToPost', '', false, false)]
    local procedure SetTotalTCSInclSHECessAmount(var TempTransValue: Record "Tax Transaction Value")
    var
        TCSSetup: Record "TCS Setup";
        TaxComponent: Record "Tax Component";
        TaxBaseSubscribers: Codeunit "Tax Base Subscribers";
        ComponenetNameLbl: Label 'Total TCS';
    begin
        if TempTransValue."Value Type" <> TempTransValue."Value Type"::COMPONENT then
            exit;

        if not TCSSetup.Get() then
            exit;
        if TempTransValue."Tax Type" <> TCSSetup."Tax Type" then
            exit;
        TaxComponent.SetRange("Tax Type", TCSSetup."Tax Type");
        TaxComponent.SetRange(Name, ComponenetNameLbl);
        if not TaxComponent.FindFirst() then
            exit;

        if TempTransValue."Value ID" <> TaxComponent.Id then
            exit;
        TaxBaseSubscribers.OnAfterGetTCSAmount(TempTransValue.Amount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Tax Base Subscribers", 'OnAfterGetTCSAmountFromTransNo', '', false, false)]
    local procedure OnAfterGetTCSAmountFromTransNo(TransactionNo: Integer; var Amount: Decimal)
    var
        TCSEntry: Record "TCS Entry";
    begin
        TCSEntry.SetRange("Transaction No.", TransactionNo);
        if TCSEntry.FindSet() then begin
            TCSEntry.CalcSums("Total TCS Including SHE CESS");
            Amount := TCSEntry."Total TCS Including SHE CESS";
        end;
    end;

    var
        AccountingPeriodErr: Label 'Posting Date doesn''t lie in Tax Accounting Period', Locked = true;
        PANNOErr: Label 'The Customer P.A.N. is invalid.';
        PANReferenceEmptyErr: Label 'The P.A.N. Reference No. field must be filled for the customer.';
        NOCAccountTypeErr: label '%1 cannot be entered for %2 %3.', Comment = '%1=TCS Nature of Collection Caption., %2= Account type Field Caption. %3=Value of Account Type.';
        NOCTypeErr: Label '%1 does not exist in table %2.', Comment = '%1=TCS Nature of Collection Value, %2=TCS NOC Table Caption';
        TCSNOCErr: Label 'TCS Nature of Collection %1 is not defined for Customer no. %2.', Comment = '%1= TCS Nature of Collection, %2= Customer No.';
}