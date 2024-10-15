table 2112 "O365 Field Excel Mapping"
{
    Caption = 'O365 Field Excel Mapping';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(2; "Table Name"; Text[30])
        {
            CalcFormula = lookup("Table Metadata".Name where(ID = field("Table ID")));
            Caption = 'Table Name';
            FieldClass = FlowField;
        }
        field(3; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(4; "Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Table ID"),
                                                        "No." = field("Field ID")));
            Caption = 'Field Name';
            FieldClass = FlowField;
        }
        field(5; "Excel Column Name"; Text[30])
        {
            Caption = 'Excel Column Name';
        }
        field(6; "Excel Column No."; Integer)
        {
            Caption = 'Excel Column No.';
        }
    }

    keys
    {
        key(Key1; "Table ID", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

