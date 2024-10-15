table 18247 "Journal Bank Charges"
{
    Caption = 'Journal Bank Charges';
    DataCaptionFields = "Bank Charge";

    fields
    {
        field(1; "Journal Template Name"; code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Gen. Journal Template";
            Editable = false;
        }
        field(2; "Journal Batch Name"; code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Gen. Journal Batch".Name WHERE(
                "Journal Template Name" = FIELD("Journal Template Name"));
            Editable = false;
        }
        field(3; "Line No."; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Bank Charge"; code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Bank Charge';
            TableRelation = "Bank Charge";
        }
        field(5; "Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Amount';
        }
        field(6; "External Document No."; code[40])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'External Document No.';
        }
        field(7; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(8; LCY; Boolean)
        {
            Caption = 'LCY';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "GST Document Type"; Enum "BankCharges DocumentType")
        {
            Caption = 'GST Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "GST Credit"; Enum "GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "Foreign Exchange"; Boolean)
        {
            Caption = 'Foreign Exchange';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "GST Group Code"; code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Group" WHERE(
                "GST Group Type" = FILTER(Service),
                "Reverse Charge" = FILTER(false));
        }
        field(13; Exempted; Boolean)
        {
            Caption = 'Exempted';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "GST Inv. Rounding Precision"; Decimal)
        {
            Caption = 'GST Inv. Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "GST Inv. Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Inv. Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "GST Group Type"; Enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(17; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "HSN/SAC".Code WHERE("GST Group Code" = FIELD("GST Group Code"));
        }
        field(18; "GST Bill to/Buy From State"; Code[10])
        {
            Caption = 'GST Bill to/Buy From State';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = State;
        }
        field(19; "GST Registration Status"; Enum "Bank Registration Status")
        {
            Caption = 'GST Registration Status';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }


    }
    keys
    {
        key(PK; "Journal Template Name", "Journal Batch Name", "Line No.", "Bank Charge")
        {
        }
    }
    Procedure GETGSTBaseAmount(BankChargeRecordID: RecordId): Decimal
    var
        TaxTransactionValue: record "Tax Transaction Value";
        TaxTypeSetup: record "Tax Type Setup";
    Begin
        if not TaxTypeSetup.get() then
            exit;
        TaxTypeSetup.Testfield(Code);
        TaxTransactionValue.Reset();
        TaxTransactionValue.SetRange("Tax Type", TaxTypeSetup.Code);
        TaxTransactionValue.SetRange("Tax Record ID", BankChargeRecordID);
        TaxTransactionValue.SetRange("Value ID", 10);
        If TaxTransactionValue.FindFirst() Then
            exit(TaxTransactionValue.Amount)
    end;

    procedure CheckBankChargeAmountSign(GenJournalLine: Record "Gen. Journal Line"; JnlBankCharges: Record "Journal Bank Charges"): Integer
    VAR
        Sign: Integer;
    Begin
        Sign := 1;
        If JnlBankCharges."GST Document Type" = JnlBankCharges."GST Document Type"::Invoice Then
            Sign := 1
        Else
            If JnlBankCharges."GST Document Type" = JnlBankCharges."GST Document Type"::"Credit Memo" Then
                Sign := -1;

        If "GST Document Type" = "GST Document Type"::" " Then Begin
            If ((GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account") AND
                (GenJournalLine.Amount > 0)) OR
               ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account") AND
                (GenJournalLine.Amount < 0))
            Then
                Sign := 1
            Else
                If ((GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account") AND
                    (GenJournalLine.Amount < 0)) OR
                   ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account") AND
                    (GenJournalLine.Amount > 0))
                Then
                    Sign := -1;
            If JnlBankCharges.Amount <> 0 Then
                JnlBankCharges.Testfield(Amount, ABS(JnlBankCharges.Amount) * Sign);
        end;
        exit(Sign);
    end;

    procedure GSTInvoiceRoundingDirection(): Text[1]
    Begin
        Case "GST Inv. Rounding Type" OF
            "GST Inv. Rounding Type"::Nearest:
                EXIT('=');
            "GST Inv. Rounding Type"::Up:
                EXIT('>');
            "GST Inv. Rounding Type"::Down:
                EXIT('<');
        END;
    End;

}

