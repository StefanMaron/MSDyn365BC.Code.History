table 1259 "Bank Data Conv. Bank"
{
    Caption = 'Bank Data Conv. Bank';
    ObsoleteState = Removed;
    ObsoleteReason = 'Changed to AMC Banking 365 Fundamentals Extension';
    ObsoleteTag = '15.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Bank; Text[50])
        {
            Caption = 'Bank';
            Editable = false;
        }
        field(2; "Bank Name"; Text[50])
        {
            Caption = 'Bank Name';
            Editable = false;
        }
        field(3; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
        }
        field(4; "Last Update Date"; Date)
        {
            Caption = 'Last Update Date';
            Editable = false;
        }
        field(5; Index; Integer)
        {
            AutoIncrement = true;
            Caption = 'Index';
        }
    }

    keys
    {
        key(Key1; Bank, Index)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Bank)
        {
        }
    }
}
