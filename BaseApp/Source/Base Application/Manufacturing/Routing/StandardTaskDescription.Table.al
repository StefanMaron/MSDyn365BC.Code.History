namespace Microsoft.Manufacturing.Routing;

table 99000783 "Standard Task Description"
{
    Caption = 'Standard Task Description';

    fields
    {
        field(1; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            NotBlank = true;
            TableRelation = "Standard Task";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; Text; Text[50])
        {
            Caption = 'Text';
        }
    }

    keys
    {
        key(Key1; "Standard Task Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

