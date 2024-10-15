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
        field(4; "Non-Taxable Income Type"; Option)
        {
            Caption = 'Non-Taxable Income Type';
            NotBlank = true;
            OptionMembers = " ","1","2","5","6","7","8","9","10","11","12","13","4","14","21","22","23","24";
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
}

