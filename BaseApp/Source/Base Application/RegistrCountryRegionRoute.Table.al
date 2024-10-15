table 11763 "Registr. Country/Region Route"
{
    Caption = 'Registr. Country/Region Route';
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';

    fields
    {
        field(5; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            TableRelation = "Registration Country/Region"."Country/Region Code" WHERE("Account Type" = CONST("Company Information"),
                                                                                       "Account No." = FILTER(''));
        }
        field(10; "Final Country/Region Code"; Code[10])
        {
            Caption = 'Final Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(15; "Old VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Old VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(20; "New VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'New VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
    }

    keys
    {
        key(Key1; "Perform. Country/Region Code", "Final Country/Region Code", "Old VAT Bus. Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

