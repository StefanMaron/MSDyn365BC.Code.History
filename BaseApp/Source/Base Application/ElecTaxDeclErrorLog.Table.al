table 11412 "Elec. Tax Decl. Error Log"
{
    Caption = 'Elec. Tax Decl. Error Log';
    DrillDownPageID = "Elec. Tax Decl. Error Log";
    LookupPageID = "Elec. Tax Decl. Error Log";

    fields
    {
        field(1; "Declaration Type"; Option)
        {
            Caption = 'Declaration Type';
            OptionCaption = 'VAT Declaration,ICP Declaration';
            OptionMembers = "VAT Declaration","ICP Declaration";
        }
        field(2; "Declaration No."; Code[20])
        {
            Caption = 'Declaration No.';
            NotBlank = true;
            TableRelation = "Elec. Tax Declaration Header"."No." WHERE("Declaration Type" = FIELD("Declaration Type"));
        }
        field(9; "No."; Integer)
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(10; "Error Class"; Text[30])
        {
            Caption = 'Error Class';
            Editable = false;
        }
        field(30; "Error Description"; Text[250])
        {
            Caption = 'Error Description';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Declaration Type", "Declaration No.", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

