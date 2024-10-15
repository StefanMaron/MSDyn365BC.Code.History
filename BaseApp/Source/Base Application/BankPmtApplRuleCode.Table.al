table 11702 "Bank Pmt. Appl. Rule Code"
{
    Caption = 'Bank Pmt. Appl. Rule Code';
    LookupPageID = "Bank Pmt. Appl. Rule Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "Match Related Party Only"; Boolean)
        {
            Caption = 'Match Related Party Only';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", Code);
        BankPmtApplRule.DeleteAll();
    end;
}

