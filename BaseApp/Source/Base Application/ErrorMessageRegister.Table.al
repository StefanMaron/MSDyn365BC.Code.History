table 701 "Error Message Register"
{
    Caption = 'Error Message Register';

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Created On"; DateTime)
        {
            Caption = 'Created On';
            DataClassification = SystemMetadata;
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(5; Errors; Integer)
        {
            CalcFormula = Count ("Error Message" WHERE("Register ID" = FIELD(ID),
                                                       "Message Type" = CONST(Error)));
            Caption = 'Errors';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Warnings; Integer)
        {
            CalcFormula = Count ("Error Message" WHERE("Register ID" = FIELD(ID),
                                                       "Message Type" = CONST(Warning)));
            Caption = 'Warnings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; Information; Integer)
        {
            CalcFormula = Count ("Error Message" WHERE("Register ID" = FIELD(ID),
                                                       "Message Type" = CONST(Information)));
            Caption = 'Information';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Created On")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Register ID", ID);
        ErrorMessage.DeleteAll(true);
    end;

    procedure New(NewDescription: Text[250]): Guid
    begin
        Init;
        ID := CreateGuid;
        "Created On" := CurrentDateTime;
        "User ID" := UserId;
        Description := NewDescription;
        Insert;
        exit(ID);
    end;
}

