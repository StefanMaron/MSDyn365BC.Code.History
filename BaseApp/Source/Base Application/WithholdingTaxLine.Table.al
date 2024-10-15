table 12210 "Withholding Tax Line"
{
    Caption = 'Withholding Tax Line';

    fields
    {
        field(1; "Withholding Tax Entry No."; Integer)
        {
            Caption = 'Withholding Tax Entry No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Base - Excluded Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base - Excluded Amount';
            NotBlank = true;
        }
        field(4; "Non-Taxable Income Type"; Enum "Non-Taxable Income Type")
        {
            Caption = 'Non-Taxable Income Type';
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Withholding Tax Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetAmountForEntryNo(EntryNo: Integer): Decimal
    begin
        SetRange("Withholding Tax Entry No.", EntryNo);
        CalcSums("Base - Excluded Amount");
        exit("Base - Excluded Amount");
    end;

    procedure GetNonTaxableIncomeTypeNumber(): Text
    begin
        exit(Rec."Non-Taxable Income Type".Names.Get(Rec."Non-Taxable Income Type".AsInteger() + 1));
    end;

}

