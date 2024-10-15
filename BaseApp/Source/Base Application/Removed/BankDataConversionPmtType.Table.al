table 1281 "Bank Data Conversion Pmt. Type"
{
    Caption = 'Bank Data Conversion Pmt. Type';
    ObsoleteState = Removed;
    ObsoleteReason = 'Changed to AMC Banking 365 Fundamentals Extension';
    ObsoleteTag = '15.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Text[50])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
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
