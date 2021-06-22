table 5909 "Service Shipment Buffer"
{
    Caption = 'Service Shipment Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
            TableRelation = "Service Invoice Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(5; Type; Enum "Service Line Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST(Item)) Item WHERE(Type = FILTER(Inventory | "Non-Inventory"),
                                                                   Blocked = CONST(false))
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST(Cost)) "Service Cost";
        }
        field(7; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Line No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }
}

