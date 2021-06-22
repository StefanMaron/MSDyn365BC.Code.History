table 5303 "Outlook Synch. Filter"
{
    Caption = 'Outlook Synch. Filter';
    DataCaptionFields = "Filter Type";
    PasteIsValid = false;
    ReplicateData = false;

    fields
    {
        field(1; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
            NotBlank = true;
        }
        field(2; "Filter Type"; Option)
        {
            Caption = 'Filter Type';
            OptionCaption = 'Condition,Table Relation';
            OptionMembers = Condition,"Table Relation";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(5; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table No."));

            trigger OnLookup()
            var
                FieldNo: Integer;
            begin
                if "Table No." <> 0 then
                    FieldNo := OSynchSetupMgt.ShowTableFieldsList("Table No.")
                else
                    FieldNo := OSynchSetupMgt.ShowTableFieldsList("Master Table No.");

                if FieldNo > 0 then
                    Validate("Field No.", FieldNo);
            end;

            trigger OnValidate()
            var
                RecRef: RecordRef;
            begin
                if "Field No." = 0 then begin
                    Clear(RecRef);
                    RecRef.Open("Table No.", true);
                    Error(Text005, RecRef.Caption);
                end;

                if "Field No." <> xRec."Field No." then
                    if Type <> Type::FIELD then
                        Value := '';
            end;
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'CONST,FILTER,FIELD';
            OptionMembers = "CONST","FILTER","FIELD";

            trigger OnValidate()
            begin
                if ("Filter Type" = "Filter Type"::Condition) and (Type = Type::FIELD) then
                    Error(Text001, Format(Type), FieldCaption("Filter Type"), Format("Filter Type"));

                if Type <> xRec.Type then
                    Value := '';
            end;
        }
        field(8; Value; Text[250])
        {
            Caption = 'Value';

            trigger OnLookup()
            var
                OSynchTypeConversion: Codeunit "Outlook Synch. Type Conv";
                RecRef: RecordRef;
                FldRef: FieldRef;
                MasterTableFieldNo: Integer;
            begin
                if Type <> Type::FIELD then begin
                    RecRef.GetTable(Rec);
                    FldRef := RecRef.Field(FieldNo(Type));
                    Error(Text003, FieldCaption(Type), OSynchTypeConversion.GetSubStrByNo(Type::FIELD + 1, FldRef.OptionCaption));
                end;

                MasterTableFieldNo := OSynchSetupMgt.ShowTableFieldsList("Master Table No.");

                if MasterTableFieldNo <> 0 then
                    Validate("Master Table Field No.", MasterTableFieldNo);
            end;

            trigger OnValidate()
            begin
                ValidateFieldValuePair;
            end;
        }
        field(9; "Master Table No."; Integer)
        {
            Caption = 'Master Table No.';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(10; "Master Table Field No."; Integer)
        {
            Caption = 'Master Table Field No.';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Master Table No."));

            trigger OnValidate()
            begin
                if TypeHelper.GetField("Master Table No.", "Master Table Field No.", Field) then
                    Validate(Value, Field."Field Caption");
            end;
        }
        field(99; FilterExpression; Text[250])
        {
            Caption = 'FilterExpression';
        }
    }

    keys
    {
        key(Key1; "Record GUID", "Filter Type", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.", "Field No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Field No.");
        Validate(Value);
        UpdateFilterExpression;
    end;

    trigger OnModify()
    begin
        Validate(Value);
        UpdateFilterExpression;
    end;

    var
        "Field": Record "Field";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        OSynchTypeConversion: Codeunit "Outlook Synch. Type Conv";
        Text001: Label 'You cannot select the %1 option when %2 is %3.';
        Text002: Label 'This value cannot be converted to the selected field datatype.';
        Text003: Label 'You can only open a lookup table when the %1 field contains the %2 value.';
        Text004: Label 'This is not a valid option for the %1 field. The possible options are: ''%2''.';
        Text005: Label 'Choose a valid field in the %1 table.';
        Text006: Label 'The value in this field cannot be longer than %1.';
        TypeHelper: Codeunit "Type Helper";

    procedure SetTablesNo(TableLeftNo: Integer; TableRightNo: Integer)
    begin
        "Table No." := TableLeftNo;
        "Master Table No." := TableRightNo;
    end;

    procedure ValidateFieldValuePair()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        NameString: Text[250];
        TempBool: Boolean;
    begin
        TestField("Table No.");

        Clear(RecRef);
        Clear(FldRef);
        RecRef.Open("Table No.", true);

        if ("Field No." = 0) or not TypeHelper.GetField("Table No.", "Field No.", Field) then
            Error(Text005, RecRef.Caption);

        FldRef := RecRef.Field("Field No.");

        case Type of
            Type::CONST:
                case Field.Type of
                    Field.Type::Option:
                        if not OSynchTypeConversion.EvaluateOptionField(FldRef, Value) then
                            Error(Text004, Field."Field Caption", FldRef.OptionMembers);
                    Field.Type::Code, Field.Type::Text:
                        begin
                            if StrLen(Value) > Field.Len then
                                Error(Text006, Field.Len);
                            if not Evaluate(FldRef, Value) then
                                Error(Text002);
                        end;
                    Field.Type::Boolean:
                        begin
                            if not Evaluate(TempBool, Value) then
                                Error(Text002);
                            Value := Format(TempBool);
                        end;
                    else
                        if not Evaluate(FldRef, Value) then
                            Error(Text002);
                end;
            Type::FILTER:
                begin
                    if Field.Type = Field.Type::Option then begin
                        if not OSynchTypeConversion.EvaluateFilterOptionField(FldRef, Value, false) then
                            Error(Text004, Field."Field Caption", FldRef.OptionMembers);
                    end;
                    FldRef.SetFilter(Value);
                end;
            Type::FIELD:
                begin
                    NameString := Value;
                    if not OSynchSetupMgt.ValidateFieldName(NameString, "Master Table No.") then begin
                        RecRef.Close;
                        RecRef.Open("Master Table No.", true);
                        Error(Text005, RecRef.Caption);
                    end;

                    Value := NameString;
                end;
        end;
        RecRef.Close;
    end;

    procedure RecomposeFilterExpression() FilterExpression: Text[250]
    begin
        FilterExpression := OSynchSetupMgt.ComposeFilterExpression("Record GUID", "Filter Type");
    end;

    procedure GetFieldCaption(): Text
    begin
        if Field.Get("Table No.", "Field No.") then
            exit(Field."Field Caption");
        exit('');
    end;

    procedure GetFilterExpressionValue(): Text[250]
    var
        ValueStartIndex: Integer;
    begin
        ValueStartIndex := StrPos(FilterExpression, '(');
        exit(CopyStr(FilterExpression, ValueStartIndex + 1, StrLen(FilterExpression) - ValueStartIndex - 1));
    end;

    procedure UpdateFilterExpression()
    var
        TempRecordRef: RecordRef;
        ViewExpression: Text;
        WhereIndex: Integer;
        TempBoolean: Boolean;
    begin
        FilterExpression := '';
        if Type <> Type::FIELD then
            if "Table No." <> 0 then begin
                TempRecordRef.Open("Table No.");

                ViewExpression := GetFieldCaption + StrSubstNo('=FILTER(%1)', Value);

                ViewExpression := StrSubstNo('WHERE(%1)', ViewExpression);
                TempRecordRef.SetView(ViewExpression);

                ViewExpression := TempRecordRef.GetView(false);
                WhereIndex := StrPos(ViewExpression, 'WHERE(') + 6;
                FilterExpression := CopyStr(ViewExpression, WhereIndex, StrLen(ViewExpression) - WhereIndex);

                if Field.Get("Table No.", "Field No.") then
                    if Field.Type = Field.Type::Boolean then begin
                        Evaluate(TempBoolean, Value);
                        if TempBoolean then
                            FilterExpression := CopyStr(StringReplace(FilterExpression, Value, '1'), 1, 250)
                        else
                            FilterExpression := CopyStr(StringReplace(FilterExpression, Value, '0'), 1, 250);
                    end;
            end;
    end;

    local procedure StringReplace(Input: Text; Find: Text; Replace: Text): Text
    var
        Pos: Integer;
    begin
        Pos := StrPos(Input, Find);
        while Pos <> 0 do begin
            Input := DelStr(Input, Pos, StrLen(Find));
            Input := InsStr(Input, Replace, Pos);
            Pos := StrPos(Input, Find);
        end;
        exit(Input);
    end;
}

