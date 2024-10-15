table 31084 "Acc. Sched. Expression Buffer"
{
    Caption = 'Acc. Sched. Expression Buffer';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Expression; Text[250])
        {
            Caption = 'Expression';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Acc. Sched. Row No."; Code[20])
        {
            Caption = 'Acc. Sched. Row No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Totaling Type"; Option)
        {
            Caption = 'Totaling Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Posting Accounts,Total Accounts,Formula,Constant,,Set Base For Percent,Custom';
            OptionMembers = "Posting Accounts","Total Accounts",Formula,Constant,,"Set Base For Percent",Custom;
        }
        field(6; "Dimension 1 Totaling"; Text[250])
        {
            Caption = 'Dimension 1 Totaling';
            DataClassification = SystemMetadata;
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(7; "Dimension 2 Totaling"; Text[250])
        {
            Caption = 'Dimension 2 Totaling';
            DataClassification = SystemMetadata;
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(8; "Dimension 3 Totaling"; Text[250])
        {
            Caption = 'Dimension 3 Totaling';
            DataClassification = SystemMetadata;
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(9; "Dimension 4 Totaling"; Text[250])
        {
            Caption = 'Dimension 4 Totaling';
            DataClassification = SystemMetadata;
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

