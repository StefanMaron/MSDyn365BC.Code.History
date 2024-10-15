table 11786 "Posting Desc. Parameter"
{
    Caption = 'Posting Desc. Parameter';
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of posting description will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    fields
    {
        field(1; "Posting Desc. Code"; Code[10])
        {
            Caption = 'Posting Desc. Code';
            TableRelation = "Posting Description";
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            InitValue = 1;
            MaxValue = 9;
            MinValue = 1;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Caption,Value,Constant';
            OptionMembers = Caption,Value,Constant;
        }
        field(4; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(5; "Field Name"; Text[30])
        {
            Caption = 'Field Name';

            trigger OnLookup()
            var
                FieldSelection: Codeunit "Field Selection";
            begin
                if Type <> Type::Constant then begin
                    SetFieldRange;
                    if FieldSelection.Open(Field) then begin
                        "Field No." := Field."No.";
                        "Field Name" := Field.FieldName;
                    end;
                end;
            end;

            trigger OnValidate()
            begin
                TestField("Field Name");

                if Type <> Type::Constant then begin
                    SetFieldRange;
                    Field.SetFilter(FieldName, '@' + "Field Name" + '*');
                    if Field.FindFirst then begin
                        "Field No." := Field."No.";
                        "Field Name" := Field.FieldName;
                    end else
                        Error(FieldNotFoundErr, "Field Name");
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Posting Desc. Code", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Field Name");
    end;

    var
        "Field": Record "Field";
        FieldNotFoundErr: Label 'Field %1 is not found.';

    [Scope('OnPrem')]
    [Obsolete('The functionality of posting description will be removed and this function should not be used. (Removed in release 01.2021)','15.3')]
    procedure SetFieldRange()
    var
        PostDescription: Record "Posting Description";
    begin
        Field.Reset;
        PostDescription.Get("Posting Desc. Code");
        case PostDescription.Type of
            PostDescription.Type::"Sales Document":
                Field.SetRange(TableNo, DATABASE::"Sales Header");
            PostDescription.Type::"Purchase Document":
                Field.SetRange(TableNo, DATABASE::"Purchase Header");
            PostDescription.Type::"Post Inventory Cost":
                Field.SetRange(TableNo, DATABASE::"Value Entry");
            PostDescription.Type::"Finance Charge":
                Field.SetRange(TableNo, DATABASE::"Finance Charge Memo Header");
            PostDescription.Type::"Service Document":
                Field.SetRange(TableNo, DATABASE::"Service Header");
        end;
    end;
}

