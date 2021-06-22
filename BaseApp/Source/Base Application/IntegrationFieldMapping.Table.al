table 5336 "Integration Field Mapping"
{
    Caption = 'Integration Field Mapping';

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Integration Table Mapping Name"; Code[20])
        {
            Caption = 'Integration Table Mapping Name';
            TableRelation = "Integration Table Mapping".Name;
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(4; "Integration Table Field No."; Integer)
        {
            Caption = 'Integration Table Field No.';
        }
        field(6; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;
        }
        field(7; "Constant Value"; Text[100])
        {
            Caption = 'Constant Value';
        }
        field(8; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';
        }
        field(9; "Validate Integration Table Fld"; Boolean)
        {
            Caption = 'Validate Integration Table Fld';
        }
        field(10; "Clear Value on Failed Sync"; Boolean)
        {
            Caption = 'Clear Value on Failed Sync';

            trigger OnValidate()
            begin
                TestField("Not Null", false)
            end;
        }
        field(11; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Enabled,Disabled';
            OptionMembers = Enabled,Disabled;
        }
        field(12; "Not Null"; Boolean)
        {
            Caption = 'Not Null';

            trigger OnValidate()
            begin
                TestField("Clear Value on Failed Sync", false);
                if not IsGUIDField then
                    Error(NotNullIsApplicableForGUIDErr);
            end;
        }
        field(13; "Transformation Rule"; Code[20])
        {
            Caption = 'Transformation Rule';
            DataClassification = SystemMetadata;
            TableRelation = "Transformation Rule";
        }
        field(14; "Transformation Direction"; Enum "CDS Transformation Direction")
        {
            Caption = 'Transformation Direction';

            trigger OnValidate()
            begin
                PutTransferDirection();
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NotNullIsApplicableForGUIDErr: Label 'The Not Null value is applicable for GUID fields only.';

    trigger OnInsert()
    begin
        PutTransferDirection();
    end;

    trigger OnModify()
    begin
        PutTransferDirection();
    end;

    procedure CreateRecord(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    begin
        Init;
        "No." := 0;
        "Integration Table Mapping Name" := IntegrationTableMappingName;
        "Field No." := TableFieldNo;
        "Integration Table Field No." := IntegrationTableFieldNo;
        Direction := SynchDirection;
        "Constant Value" := CopyStr(ConstValue, 1, MaxStrLen("Constant Value"));
        "Validate Field" := ValidateField;
        "Validate Integration Table Fld" := ValidateIntegrationTableField;
        Insert;
    end;

    local procedure IsGUIDField(): Boolean
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        TypeHelper: Codeunit "Type Helper";
    begin
        IntegrationTableMapping.Get("Integration Table Mapping Name");
        if TypeHelper.GetField(IntegrationTableMapping."Integration Table ID", "Integration Table Field No.", Field) then
            exit(Field.Type = Field.Type::GUID);
    end;

    local procedure PutTransferDirection()
    begin
        if Direction <> Direction::Bidirectional then
            case Direction of
                Direction::ToIntegrationTable:
                    "Transformation Direction" := "Transformation Direction"::ToIntegrationTable;
                Direction::FromIntegrationTable:
                    "Transformation Direction" := "Transformation Direction"::FromIntegrationTable;
            end;
    end;
}

