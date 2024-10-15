namespace Microsoft.Finance.Dimension;

table 8383 "Dimensions Field Map"
{
    Caption = 'Dimensions Field Map';

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Global Dim.1 Field No."; Integer)
        {
            Caption = 'Global Dim.1 Field No.';
        }
        field(3; "Global Dim.2 Field No."; Integer)
        {
            Caption = 'Global Dim.2 Field No.';
        }
        field(4; "ID Field No."; Integer)
        {
            Caption = 'ID Field No.';
        }
    }

    keys
    {
        key(Key1; "Table No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

