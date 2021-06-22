table 1182 "Journal User Preferences"
{
    Caption = 'Journal User Preferences';
    ReplicateData = false;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            Editable = false;
            NotBlank = true;
        }
        field(2; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Page));
        }
        field(3; "User ID"; Guid)
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Security ID" WHERE("License Type" = CONST("Full User"));
        }
        field(4; "Is Simple View"; Boolean)
        {
            Caption = 'Is Simple View';
        }
        field(5; User; Code[50])
        {
            CalcFormula = Lookup (User."User Name" WHERE("User Security ID" = FIELD("User ID"),
                                                         "License Type" = CONST("Full User")));
            Caption = 'User';
            FieldClass = FlowField;
        }
        field(6; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
    }

    keys
    {
        key(Key1; ID, "Page ID", "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "User ID" := UserSecurityId;
    end;
}

