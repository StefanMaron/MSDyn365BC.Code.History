table 5106 "Interaction Merge Data"
{
    fields
    {
        field(1; ID; Guid)
        {
            DataClassification = SystemMetadata;
        }

        field(2; "Contact No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Contact."No.";
        }

        field(3; "Salesperson Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser".Code;
        }

        field(4; "Log Entry Number"; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Interaction Log Entry"."Entry No.";
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

}