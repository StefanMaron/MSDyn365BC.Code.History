table 8611 "Config. Question Area"
{
    Caption = 'Config. Question Area';
    LookupPageID = "Config. Question Areas";
    ReplicateData = false;

    fields
    {
        field(1; "Questionnaire Code"; Code[10])
        {
            Caption = 'Questionnaire Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Config. Questionnaire";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            var
                TestValue: Integer;
            begin
                if Evaluate(TestValue, CopyStr(Code, 1, 1)) then
                    Error(Text002);
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = FILTER(Table));

            trigger OnLookup()
            var
                ConfigValidateMgt: Codeunit "Config. Validate Management";
            begin
                ConfigValidateMgt.LookupTable("Table ID");
                Validate("Table ID");
            end;

            trigger OnValidate()
            var
                ConfigQuestion: Record "Config. Question";
                ConfigQuestionArea: Record "Config. Question Area";
            begin
                if (xRec."Table ID" <> "Table ID") and (xRec."Table ID" > 0) then begin
                    ConfigQuestion.SetRange("Questionnaire Code", "Questionnaire Code");
                    ConfigQuestion.SetRange("Question Area Code", Code);
                    if not ConfigQuestion.IsEmpty then
                        Error(Text000, Code);
                    ConfigQuestionArea.SetRange("Questionnaire Code", "Questionnaire Code");
                    ConfigQuestionArea.SetRange("Table ID", "Table ID");
                    if not ConfigQuestionArea.IsEmpty then
                        Error(Text001, "Table ID");
                end;
                CalcFields("Table Name", "Table Caption");
            end;
        }
        field(5; "Table Name"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Name" WHERE("Object Type" = CONST(Table),
                                                                        "Object ID" = FIELD("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "No. of Questions"; Integer)
        {
            CalcFormula = Count ("Config. Question" WHERE("Questionnaire Code" = FIELD("Questionnaire Code"),
                                                          "Question Area Code" = FIELD(Code)));
            Caption = 'No. of Questions';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Questionnaire Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Table ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfigQuestion: Record "Config. Question";
    begin
        ConfigQuestion.Reset();
        ConfigQuestion.SetRange("Questionnaire Code", "Questionnaire Code");
        ConfigQuestion.SetRange("Question Area Code", Code);
        ConfigQuestion.DeleteAll();
    end;

    trigger OnRename()
    begin
        Error(Text003);
    end;

    var
        Text000: Label 'Delete questions for question area %1 to change the table relationship.';
        Text001: Label 'A question area already exists for table %1.';
        Text002: Label 'The first character cannot be a numeric value.';
        Text003: Label 'You cannot rename a question area.';
}

