table 870 "Social Listening Setup"
{
    Caption = 'Social Engagement Setup';
    ObsoleteState = Removed;
    ObsoleteReason = 'Microsoft Social Engagement has been discontinued.';
    ObsoleteTag = '20.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Solution ID"; Text[250])
        {
            Caption = 'Solution ID';
            Editable = false;
        }
        field(3; "Show on Items"; Boolean)
        {
            Caption = 'Show on Items';
        }
        field(4; "Show on Customers"; Boolean)
        {
            Caption = 'Show on Customers';
        }
        field(5; "Show on Vendors"; Boolean)
        {
            Caption = 'Show on Vendors';
        }
        field(6; "Accept License Agreement"; Boolean)
        {
            Caption = 'Accept License Agreement';
        }
        field(7; "Terms of Use URL"; Text[250])
        {
            Caption = 'Terms of Use URL';
            ExtendedDatatype = URL;
            NotBlank = true;
        }
        field(8; "Signup URL"; Text[250])
        {
            Caption = 'Signup URL';
            ExtendedDatatype = URL;
            NotBlank = true;
        }
        field(9; "Social Listening URL"; Text[250])
        {
            Caption = 'Social Engagement URL';
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

