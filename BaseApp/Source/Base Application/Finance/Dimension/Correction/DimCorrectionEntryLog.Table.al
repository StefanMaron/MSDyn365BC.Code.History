namespace Microsoft.Finance.Dimension.Correction;

table 2583 "Dim Correction Entry Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension Correction Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }

        field(2; "Start Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }

        field(3; "End Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }
    }

    keys
    {
        key(Key1; "Dimension Correction Entry No.", "Start Entry No.", "End Entry No.")
        {
        }
    }
}