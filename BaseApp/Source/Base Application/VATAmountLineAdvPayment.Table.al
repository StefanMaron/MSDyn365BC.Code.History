table 31027 "VAT Amount Line Adv. Payment"
{
    Caption = 'VAT Amount Line Adv. Payment';
#if not CLEAN19
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(9; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(10; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(15; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(16; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(30; "VAT Base (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base (LCY)';
            Editable = false;
        }
        field(35; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
        }
        field(40; "Amount Including VAT (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Including VAT (LCY)';
            Editable = false;
        }
        field(50; "VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base';
            Editable = false;
        }
        field(55; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(60; "Amount Including VAT"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Prod. Posting Group")
        {
            Clustered = true;
        }
        key(Key2; Positive)
        {
        }
    }

    fieldgroups
    {
    }
#if not CLEAN19

    [Scope('OnPrem')]
    procedure InsertLine()
    var
        VATAmountLineAdvPmt: Record "VAT Amount Line Adv. Payment";
    begin
        if not (("VAT Base (LCY)" = 0) and ("VAT Amount (LCY)" = 0)) then begin
            VATAmountLineAdvPmt := Rec;
            if Find() then begin
                "VAT Base (LCY)" := "VAT Base (LCY)" + VATAmountLineAdvPmt."VAT Base (LCY)";
                "VAT Amount (LCY)" := "VAT Amount (LCY)" + VATAmountLineAdvPmt."VAT Amount (LCY)";
                "Amount Including VAT (LCY)" := "VAT Base (LCY)" + "VAT Amount (LCY)";
                Modify();
            end else begin
                "Amount Including VAT (LCY)" := "VAT Base (LCY)" + "VAT Amount (LCY)";
                Insert();
            end;
        end;
    end;
#endif
}

