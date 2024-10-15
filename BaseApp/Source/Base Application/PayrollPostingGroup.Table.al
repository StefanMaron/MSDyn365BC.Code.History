table 17401 "Payroll Posting Group"
{
    Caption = 'Payroll Posting Group';
    LookupPageID = "Payroll Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Vendor';
            OptionMembers = "G/L Account",Vendor;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor;
        }
        field(5; "Fund Vendor No."; Code[20])
        {
            Caption = 'Fund Vendor No.';
            TableRelation = Vendor WHERE("Vendor Type" = CONST("Tax Authority"));
        }
        field(6; "Future Vacation G/L Acc. No."; Code[20])
        {
            Caption = 'Future Vacation G/L Acc. No.';
            TableRelation = "G/L Account";
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
}

