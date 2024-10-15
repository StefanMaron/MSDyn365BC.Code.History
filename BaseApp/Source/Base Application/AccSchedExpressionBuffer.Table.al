table 26585 "Acc. Sched. Expression Buffer"
{
    Caption = 'Acc. Sched. Expression Buffer';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Totaling; Text[250])
        {
            Caption = 'Totaling';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Row No."; Code[20])
        {
            Caption = 'Row No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Totaling Type"; Option)
        {
            Caption = 'Totaling Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Posting Accounts,Total Accounts,Formula,Constant,Custom,Set Base For Percent,Cost Type,Cost Type Total,Cash Flow Entry Accounts,Cash Flow Total Accounts';
            OptionMembers = "Posting Accounts","Total Accounts",Formula,Constant,Custom,"Set Base For Percent","Cost Type","Cost Type Total","Cash Flow Entry Accounts","Cash Flow Total Accounts";
        }
        field(6; Description; Text[250])
        {
            CalcFormula = Lookup ("Acc. Schedule Line".Description WHERE("Schedule Name" = FIELD("Schedule Name"),
                                                                         "Line No." = FIELD("Acc. Schedule Line No.")));
            Caption = 'Description';
            FieldClass = FlowField;
        }
        field(10; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            DataClassification = SystemMetadata;
            TableRelation = "Acc. Schedule Name";
        }
        field(11; "Acc. Schedule Line No."; Integer)
        {
            Caption = 'Acc. Schedule Line No.';
            DataClassification = SystemMetadata;
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

