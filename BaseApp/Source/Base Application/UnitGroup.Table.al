table 5400 "Unit Group"
{
    DataClassification = SystemMetadata;
    Caption = 'Unit Group';

    fields
    {
        field(1; "Source Type"; Enum "Unit Group Source Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Type';
            Editable = false;
            NotBlank = true;
        }
        field(2; "Source Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Id';
            Editable = false;
            NotBlank = true;

            TableRelation = if ("Source Type" = const(Item)) Item.SystemId
            else
            "Resource".SystemId;
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Source No.';
            Editable = false;
            NotBlank = true;

            TableRelation = if ("Source Type" = const(Item)) Item."No."
            else
            "Resource"."No.";
        }
        field(4; "Code"; Code[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Code';
            Editable = false;
            NotBlank = true;
        }
        field(5; "Source Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Name';
            Editable = false;

            TableRelation = if ("Source Type" = const(Item)) Item.Description
            else
            "Resource".Name;
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source Id")
        {
            Clustered = true;
        }
        key(Key2; "Code")
        {
        }
    }
}