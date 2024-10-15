namespace Microsoft.Finance.Dimension;

table 481 "Dimension Set Tree Node"
{
    Caption = 'Dimension Set Tree Node';

    fields
    {
        field(1; "Parent Dimension Set ID"; Integer)
        {
            Caption = 'Parent Dimension Set ID';
        }
        field(2; "Dimension Value ID"; Integer)
        {
            Caption = 'Dimension Value ID';
        }
        field(3; "Dimension Set ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Dimension Set ID';
        }
        field(4; "In Use"; Boolean)
        {
            Caption = 'In Use';
        }
    }

    keys
    {
        key(Key1; "Parent Dimension Set ID", "Dimension Value ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

