codeunit 18246 "GST Journal Validations"
{
    //Bank Charge - Definition
    procedure GSTGroupCodeBankCharge(var BankCharge: Record "Bank Charge")
    begin
        BankCharge."HSN/SAC Code" := '';
    end;

    //Bank Charge Deemed Value Setup - Definition
    procedure LowerLimit(var BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup")
    begin
        BankChargeDeemedValueSetup.TestField("Bank Charge Code");
        CheckUpperLowerLimit(BankChargeDeemedValueSetup);
    end;

    procedure Upperlimit(var BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup"; Var XBankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup")
    begin
        if BankChargeDeemedValueSetup."Upper Limit" <> 0 then
            if BankChargeDeemedValueSetup."Upper Limit" <= BankChargeDeemedValueSetup."Lower Limit" then
                ERROR(UpperLimitErr, BankChargeDeemedValueSetup."Lower Limit");
        if BankChargeDeemedValueSetup."Upper Limit" <> xBankChargeDeemedValueSetup."Upper Limit" then
            CheckOtherUpperLowerLimits(BankChargeDeemedValueSetup);
    end;

    procedure BankChargeDeemedDelete(var BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup")
    begin
        UpperLimitCheckOnDelete(BankChargeDeemedValueSetup);
    end;

    procedure DeleteBankValueDeemedSetup(var BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup")
    begin
        UpperLimitCheckOnDelete(BankChargeDeemedValueSetup);
    end;

    local procedure CheckOtherUpperLowerLimits(var BankChargeDeemedValueSetup2: Record "Bank Charge Deemed Value Setup")
    var
        BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup";
        SameLower: Boolean;
        HigherLower: Boolean;
        SmallerLower: Boolean;
    begin
        BankChargeDeemedValueSetup.RESET();
        BankChargeDeemedValueSetup.SETRANGE("Bank Charge Code", BankChargeDeemedValueSetup2."Bank Charge Code");
        BankChargeDeemedValueSetup.SETFILTER("Lower Limit", '>%1', BankChargeDeemedValueSetup2."Upper Limit");
        if not BankChargeDeemedValueSetup.IsEmpty() then
            HigherLower := TRUE;
        BankChargeDeemedValueSetup.SETFILTER("Lower Limit", '%1..%2', BankChargeDeemedValueSetup2."Lower Limit" + 1, BankChargeDeemedValueSetup2."Upper Limit" - 1);
        if not BankChargeDeemedValueSetup.IsEmpty() then
            SmallerLower := TRUE;
        BankChargeDeemedValueSetup.SETRANGE("Lower Limit", BankChargeDeemedValueSetup2."Upper Limit");
        if not BankChargeDeemedValueSetup.IsEmpty() then
            SameLower := TRUE;
        if SmallerLower then
            ERROR(UpperLimitSmallModifyErr, BankChargeDeemedValueSetup2."Bank Charge Code", BankChargeDeemedValueSetup2."Upper Limit");
        if HigherLower and not SameLower then
            ERROR(UpperLimitBigModifyErr, BankChargeDeemedValueSetup2."Bank Charge Code", BankChargeDeemedValueSetup2."Upper Limit");
    end;

    local procedure CheckUpperLowerLimit(var BankChargeDeemedValueSetup2: Record "Bank Charge Deemed Value Setup")
    var
        BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup";
    begin
        if BankChargeDeemedValueSetup2."Lower Limit" <> 0 then begin
            BankChargeDeemedValueSetup.RESET();
            BankChargeDeemedValueSetup.SETRANGE("Bank Charge Code", BankChargeDeemedValueSetup2."Bank Charge Code");
            BankChargeDeemedValueSetup.SETRANGE("Upper Limit", BankChargeDeemedValueSetup2."Lower Limit");
            if BankChargeDeemedValueSetup.ISEMPTY() then
                ERROR(LowerLimitErr, BankChargeDeemedValueSetup2."Lower Limit", BankChargeDeemedValueSetup2."Bank Charge Code");
        end else begin
            BankChargeDeemedValueSetup.RESET();
            BankChargeDeemedValueSetup.SETRANGE("Bank Charge Code", BankChargeDeemedValueSetup2."Bank Charge Code");
            BankChargeDeemedValueSetup.SETRANGE("Lower Limit", 0);
            if not BankChargeDeemedValueSetup.ISEMPTY() then
                ERROR(LowerLimitZeroErr, BankChargeDeemedValueSetup2."Bank Charge Code");
        end;
    end;

    procedure UpperLimitCheckOnDelete(var BankChargeDeemedVal: Record "Bank Charge Deemed Value Setup")
    var
        BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup";
    begin
        BankChargeDeemedValueSetup.RESET();
        BankChargeDeemedValueSetup.SETRANGE("Bank Charge Code", BankChargeDeemedVal."Bank Charge Code");
        BankChargeDeemedValueSetup.SETFILTER("Lower Limit", '>=%1', BankChargeDeemedVal."Upper Limit");
        if not BankChargeDeemedValueSetup.IsEmpty() then
            ERROR(DeleteErr, BankChargeDeemedVal."Upper Limit");
    end;

    //Journal Bank Charges - Definition
    procedure JnlBankCharge(var JnlBankCharges: Record "Journal Bank Charges")
    var
        GenJnlLine: record "Gen. Journal Line";
        BankCharge: Record "Bank Charge";
    begin
        Clearfields(JnlBankCharges);
        GetGenJnlLine(GenJnlLine, JnlBankCharges."Journal Template Name", JnlBankCharges."Journal Batch Name", JnlBankCharges."Line No.");
        if GenJnlLine."Bal. Account No." <> '' then
            GenJnlLine.TestField("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        if GenJnlLine."Bal. Account No." = '' then
            GenJnlLine.TestField("Account Type", GenJnlLine."Account Type"::"Bank Account");
        BankCharge.GET(JnlBankCharges."Bank Charge");
        if BankCharge."Foreign Exchange" then
            GenJnlLine.TestField("Bank Charge", false);
        JnlBankCharges.VALIDATE("GST Group Code", BankCharge."GST Group Code");
        JnlBankCharges.VALIDATE("GST Credit", BankCharge."GST Credit");
        PopulateGSTInformation(JnlBankCharges, false);
    end;

    procedure JnlBankChargeGSTGroupCode(var JnlBankCharges: Record "Journal Bank Charges")
    var
        GstGroup: Record "GST Group";
        bankCharge: Record "Bank Charge";
        genJnlLIne: record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if JnlBankCharges."GST Group Code" <> '' then begin
            PopulateGSTInformation(JnlBankCharges, TRUE);
            GSTGroup.GET(JnlBankCharges."GST Group Code");

            GetGenJnlLine(genJnlLIne, JnlBankCharges."Journal Template Name", JnlBankCharges."Journal Batch Name", JnlBankCharges."Line No.");
            BankCharge.GET(JnlBankCharges."Bank Charge");
            if GenJnlLine."Bank Charge" then
                BankCharge.TestField(Account, GenJnlLine."Account No.")
            else
                BankCharge.TestField(Account);
            JnlBankCharges."GST Inv. Rounding Precision" := GeneralLedgerSetup."GST Inv. Rounding Precision";
            JnlBankCharges."GST Inv. Rounding Type" := GeneralLedgerSetup."GST Inv. Rounding Type";
        end else begin
            JnlBankCharges.TestField("GST Document Type", JnlBankCharges."GST Document Type"::" ");
            JnlBankCharges."GST Inv. Rounding Precision" := 0;
            JnlBankCharges."GST Inv. Rounding Type" := GeneralLedgerSetup."GST Inv. Rounding Type"::Nearest;
        end;
    end;

    procedure JnlBankChargeAmount(var JnlBankCharges: Record "Journal Bank Charges")
    var
        GenJnlLine: Record "Gen. Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        JnlBankCharges.TestField("Foreign Exchange", false);
        GetGenJnlLine(GenJnlLine, JnlBankCharges."Journal Template Name", JnlBankCharges."Journal Batch Name", JnlBankCharges."Line No.");
        CheckBankChargeAmountSign(GenJnlLine, JnlBankCharges);
        GenJnlLine.TestField("Bank Charge", false);
        if (GenJnlLine."Currency Code" <> '') and not JnlBankCharges.LCY then
            JnlBankCharges."Amount (LCY)" := ROUND(CurrExchRate.ExchangeAmtFCYToLCY(GenJnlLine."Posting Date",
                  GenJnlLine."Currency Code", JnlBankCharges.Amount, GenJnlLine."Currency Factor"))
        else
            JnlBankCharges."Amount (LCY)" := JnlBankCharges.Amount;

        if JnlBankCharges."GST Document Type" <> "GST Document Type"::" " then
            if JnlBankCharges.Amount > 0 then
                JnlBankCharges.TestField("GST Document Type", JnlBankCharges."GST Document Type"::Invoice)
            else
                if JnlBankCharges.Amount < 0 then
                    JnlBankCharges.TestField("GST Document Type", JnlBankCharges."GST Document Type"::"Credit Memo");
        if JnlBankCharges."GST Group Code" <> '' then
            JnlBankCharges.TestField("GST Document Type");
    end;

    procedure JnlBankChargeGSTDocumentType(var JnlBankCharges: Record "Journal Bank Charges")
    var
        Genjnlline: Record "Gen. Journal Line";
    begin
        GetGenJnlLine(Genjnlline, JnlBankCharges."Journal Template Name", JnlBankCharges."Journal Batch Name", JnlBankCharges."Line No.");
        GenJnlLine.TestField("Bank Charge", false);
        CheckBankChargeAmountSign(GenJnlLine, JnlBankCharges);
        if JnlBankCharges."GST Document Type" <> "GST Document Type"::" " then
            if JnlBankCharges.Amount > 0 then
                JnlBankCharges.TestField("GST Document Type", JnlBankCharges."GST Document Type"::Invoice)
            else
                if JnlBankCharges.Amount < 0 then
                    JnlBankCharges.TestField("GST Document Type", JnlBankCharges."GST Document Type"::"Credit Memo");

        if JnlBankCharges."GST Document Type" IN [
            JnlBankCharges."GST Document Type"::Invoice,
            JnlBankCharges."GST Document Type"::"Credit Memo"]
        then
            JnlBankCharges.TestField("GST Group Code");
    end;

    procedure Clearfields(var JnlBankCharges: Record "Journal Bank Charges")
    begin
        Clear(JnlBankCharges.Amount);
        Clear(JnlBankCharges."Amount (LCY)");
        Clear(JnlBankCharges."GST Group Code");
        Clear(JnlBankCharges."Foreign Exchange");
        Clear(JnlBankCharges.Exempted);
        Clear(JnlBankCharges."GST Credit");
        Clear(JnlBankCharges."External Document No.");
        Clear(JnlBankCharges.LCY);
    end;

    procedure GetGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; JournalTemplateName: code[10]; journalbatchname: code[10]; LineNo: Integer)
    begin
        if (journalbatchname = '') OR (JournalTemplateName = '') then
            EXIT;

        GenJnlLine.GET(JournalTemplateName, journalbatchname, LineNo);
    end;

    local procedure PopulateGSTInformation(var JnlBankCharge: Record "Journal Bank Charges"; Calculation: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GSTGroup: Record "GST Group";
        BankCharge: Record "Bank Charge";
    begin
        BankCharge.get(JnlBankCharge."Bank Charge");
        GenJnlLine.GET(JnlBankCharge."Journal Template Name", JnlBankCharge."Journal Batch Name", JnlBankCharge."Line No.");
        IF GenJnlLine."Bal. Account No." <> '' THEN
            BankAccount.GET(GenJnlLine."Bal. Account No.")
        ELSE
            BankAccount.GET(GenJnlLine."Account No.");
        IF GSTGroup.GET(JnlBankCharge."GST Group Code") THEN;
        JnlBankCharge."GST Group Type" := GSTGroup."GST Group Type";
        IF NOT Calculation THEN BEGIN
            JnlBankCharge."Foreign Exchange" := BankCharge."Foreign Exchange";
            JnlBankCharge."HSN/SAC Code" := BankCharge."HSN/SAC Code";
            JnlBankCharge.Exempted := BankCharge.Exempted;
        END;
        JnlBankCharge."GST Bill to/Buy From State" := BankAccount."State Code";
        JnlBankCharge."GST Registration Status" := BankAccount."GST Registration Status";

    end;

    local procedure CheckBankChargeAmountSign(GenJournalLine: Record "Gen. Journal Line"; JnlBankCharges: Record "Journal Bank Charges"): Integer
    var
        Sign: Integer;
    begin
        Sign := 1;
        if JnlBankCharges."GST Document Type" = JnlBankCharges."GST Document Type"::Invoice then
            Sign := 1
        else
            if JnlBankCharges."GST Document Type" = JnlBankCharges."GST Document Type"::"Credit Memo" then
                Sign := -1;

        if jnlbankcharges."GST Document Type" = jnlbankcharges."GST Document Type"::" " then begin
            if ((GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account") and
                (GenJournalLine.Amount > 0)) OR
               ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account") and
                (GenJournalLine.Amount < 0))
            then
                Sign := 1
            else
                if ((GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account") and
                    (GenJournalLine.Amount < 0)) OR
                   ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account") and
                    (GenJournalLine.Amount > 0))
                then
                    Sign := -1;
            if JnlBankCharges.Amount <> 0 then
                JnlBankCharges.TestField(Amount, ABS(JnlBankCharges.Amount) * Sign);
        end;
        EXIT(Sign);
    end;

    procedure GSTTDSTCSGSTType(GSTTDSTCSSetup: record "GST TDS/TCS Setup")
    begin
        if GSTTDSTCSSetup.Type = Type::" " then
            GSTTDSTCSSetup.TestField("GST Component Code", '');
    end;


    var
        LowerLimitErr: label 'Lower Limit %1 must be present as an Upper Limit in any Record of Bank Charge Code %2 in Bank Charges Deemed Value Setup.', Comment = '%1 =Lower Limit ,%2 =Bank Charge Code';
        UpperLimitErr: label 'Upper Limit must be greater than Lower Limit %1.', Comment = '%1 = Lower Limit';
        LowerLimitZeroErr: label 'Only one Record for Bank Charge Code %1 can have Zero as Lower Limit.', Comment = '%1 = Bank Charge Code';
        DeleteErr: label 'There is Record having Higher Lower Limit than %1 of Bank Charge', Comment = '%1 =Upper Limit';
        UpperLimitSmallModifyErr: label 'There must not be any Record of Bank Charge Code %1 Where Lower Limit is Smaller than %2.', Comment = '%1 = Bank Charge Code , %2 = Upper Limit';
        UpperLimitBigModifyErr: label 'There is no Record of Bank Charge Code %1 , Where Lower Limit is same as %2 .', Comment = '%1 = Bank Charge Code, %2 = Upper Limit';
}