codeunit 8617 "Config. Validate Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Field %2 in table %1 can only contain %3 characters (%4).';
        Text002: Label '%1 is not a supported data type.';
        Text003: Label '%1 is not a valid %2.';
        Text004: Label '%1 is not a valid option.\Valid options are %2.';
        TypeHelper: Codeunit "Type Helper";

    procedure ValidateFieldValue(var RecRef: RecordRef; var FieldRef: FieldRef; Value: Text; SkipValidation: Boolean; LanguageID: Integer)
    var
        "Field": Record "Field";
        OldValue: Variant;
        NewValue: Variant;
        OptionAsInteger: Integer;
        MainLanguageID: Integer;
    begin
        MainLanguageID := GlobalLanguage;

        if (LanguageID <> 0) and (LanguageID <> GlobalLanguage) then
            GlobalLanguage(LanguageID);

        Field.Get(RecRef.Number, FieldRef.Number);
        TypeHelper.TestFieldIsNotObsolete(Field);

        if Field.Class <> Field.Class::Normal then
            exit;

        if not SkipValidation then
            OldValue := FieldRef.Value;

        if Field.Type <> Field.Type::Option then begin
            if Value <> '' then
                Evaluate(FieldRef, Value)
        end else begin
            OptionAsInteger := GetOptionNo(Value, FieldRef);
            if OptionAsInteger <> -1 then
                FieldRef.Value := OptionAsInteger;
        end;

        if not SkipValidation then begin
            NewValue := FieldRef.Value;
            FieldRef.Value := OldValue;
            FieldRef.Validate(NewValue);
        end;

        if MainLanguageID <> GlobalLanguage then
            GlobalLanguage(MainLanguageID);
    end;

    local procedure GetOptionsNumber(OptionString: Text): Integer
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.GetNumberOfOptions(OptionString));
    end;


    procedure OptionNoExists(var FieldRef: FieldRef; OptionValue: Text): Boolean
    var
        OptionNo: Integer;
    begin
        if Evaluate(OptionNo, OptionValue) then
            exit((FieldRef.GetEnumValueNameFromOrdinalValue(OptionNo) <> '') or ((FieldRef.GetEnumValueNameFromOrdinalValue(OptionNo) = '') and (OptionNo = 0)));

        exit(false);
    end;

    procedure GetOptionNo(Value: Text; FieldRef: FieldRef): Integer
    var
        OptionNo: Integer;
        i: Integer;
    begin
        if (Value = '') and (FieldRef.GetEnumValueName(1) = ' ') then
            exit(0);

        if Evaluate(FieldRef, Value) then
            exit(FieldRef.Value());

        exit(-1);
    end;

    procedure GetRelationInfoByIDs(TableNo: Integer; FieldNo: Integer; var RelationTableNo: Integer; var RelationFieldNo: Integer): Boolean
    var
        "Field": Record "Field";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        FieldRef2: FieldRef;
        FieldRef: FieldRef;
        KeyRef2: KeyRef;
    begin
        Field.Get(TableNo, FieldNo);
        TypeHelper.TestFieldIsNotObsolete(Field);

        if Field.RelationTableNo = 0 then
            exit(false);

        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);

        RecRef2.Open(Field.RelationTableNo);

        if Field.RelationFieldNo <> 0 then
            FieldRef2 := RecRef2.Field(Field.RelationFieldNo)
        else begin
            KeyRef2 := RecRef2.KeyIndex(1);
            if KeyRef2.FieldCount > 1 then
                exit(false);
            FieldRef2 := KeyRef2.FieldIndex(1);
        end;

        if (FieldRef2.Type <> FieldRef.Type) or (FieldRef2.Length <> FieldRef.Length) then
            exit(false);

        RelationTableNo := Field.RelationTableNo;
        RelationFieldNo := FieldRef2.Number;
        exit(true);
    end;

    procedure GetRelationTableID(TableID: Integer; FieldID: Integer): Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableID);
        if RecRef.FieldExist(FieldID) then begin
            FieldRef := RecRef.Field(FieldID);
            exit(FieldRef.Relation);
        end;
    end;

    procedure IsRelationInKeyFields(TableNo: Integer; FieldNo: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        I: Integer;
    begin
        RecRef.Open(TableNo);
        KeyRef := RecRef.KeyIndex(1);

        for I := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(I);
            if FieldRef.Number = FieldNo then
                exit(true);
        end;
    end;

    procedure ValidateFieldRefRelationAgainstCompanyData(FieldRef: FieldRef): Text[250]
    var
        ConfigTryValidate: Codeunit "Config. Try Validate";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        FieldRef2: FieldRef;
    begin
        RecRef := FieldRef.Record;

        RecRef2.Open(RecRef.Number, true);
        CopyRecRefFields(RecRef2, RecRef, FieldRef);
        RecRef2.Insert;

        FieldRef2 := RecRef2.Field(FieldRef.Number);

        ConfigTryValidate.SetValidateParameters(FieldRef2, FieldRef.Value);

        Commit;
        if not ConfigTryValidate.Run then
            exit(CopyStr(GetLastErrorText, 1, 250));

        exit('');
    end;

    local procedure CopyRecRefFields(RecRef: RecordRef; SourceRecRef: RecordRef; FieldRefToExclude: FieldRef)
    var
        FieldRef: FieldRef;
        SourceFieldRef: FieldRef;
        FieldCount: Integer;
    begin
        for FieldCount := 1 to SourceRecRef.FieldCount do begin
            SourceFieldRef := SourceRecRef.FieldIndex(FieldCount);
            if FieldRefToExclude.Name = SourceFieldRef.Name then
                exit;
            FieldRef := RecRef.FieldIndex(FieldCount);
            FieldRef.Value := SourceFieldRef.Value;
        end;
    end;

    procedure EvaluateValue(var FieldRef: FieldRef; Value: Text[250]; XMLValue: Boolean): Text[250]
    begin
        exit(EvaluateValueBase(FieldRef, Value, XMLValue, false));
    end;

    procedure EvaluateValueWithValidate(var FieldRef: FieldRef; Value: Text[250]; XMLValue: Boolean): Text[250]
    begin
        exit(EvaluateValueBase(FieldRef, Value, XMLValue, true));
    end;

    local procedure EvaluateValueBase(var FieldRef: FieldRef; Value: Text[250]; XMLValue: Boolean; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
    begin
        Evaluate(Field.Type, Format(FieldRef.Type));

        if (Value <> '') and not IsNormalField(FieldRef) then
            exit(Text002);

        case Field.Type of
            Field.Type::Text:
                exit(EvaluateValueToText(FieldRef, Value, Validate));
            Field.Type::Code:
                exit(EvaluateValueToCode(FieldRef, Value, Validate));
            Field.Type::Option:
                exit(EvaluateValueToOption(FieldRef, Value, XMLValue, Validate));
            Field.Type::Date:
                exit(EvaluateValueToDate(FieldRef, Value, Validate));
            Field.Type::DateFormula:
                exit(EvaluateValueToDateFormula(FieldRef, Value, Validate));
            Field.Type::DateTime:
                exit(EvaluateValueToDateTime(FieldRef, Value, Validate));
            Field.Type::Time:
                exit(EvaluateValueToTime(FieldRef, Value, Validate));
            Field.Type::Duration:
                exit(EvaluateValueToDuration(FieldRef, Value, Validate));
            Field.Type::Integer:
                exit(EvaluateValueToInteger(FieldRef, Value, Validate));
            Field.Type::BigInteger:
                exit(EvaluateValueToBigInteger(FieldRef, Value, Validate));
            Field.Type::Decimal:
                exit(EvaluateValueToDecimal(FieldRef, Value, Validate));
            Field.Type::Boolean:
                exit(EvaluateValueToBoolean(FieldRef, Value, Validate));
            Field.Type::GUID,
          Field.Type::MediaSet,
          Field.Type::Media:
                exit(EvaluateValueToGuid(FieldRef, Value, Validate));
            Field.Type::TableFilter:
                exit(EvaluateValueToTableFilter(FieldRef, Value));
        end;
    end;

    local procedure EvaluateValueToText(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        RecordRef: RecordRef;
    begin
        RecordRef := FieldRef.Record;
        Field.Get(RecordRef.Number, FieldRef.Number);
        TypeHelper.TestFieldIsNotObsolete(Field);

        if StrLen(Value) > Field.Len then
            exit(CopyStr(StrSubstNo(Text001, FieldRef.Record.Caption, FieldRef.Caption, Field.Len, Value), 1, 250));

        if Validate then
            FieldRef.Validate(Value)
        else
            FieldRef.Value := Value;
    end;

    local procedure EvaluateValueToCode(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        RecordRef: RecordRef;
        "Code": Code[250];
    begin
        Code := Value;
        RecordRef := FieldRef.Record;
        Field.Get(RecordRef.Number, FieldRef.Number);
        TypeHelper.TestFieldIsNotObsolete(Field);

        if StrLen(Value) > Field.Len then
            exit(StrSubstNo(Text001, FieldRef.Record.Caption, FieldRef.Caption, Field.Len, Value));

        if Validate then
            FieldRef.Validate(Code)
        else
            FieldRef.Value := Code;
    end;

    local procedure EvaluateValueToOption(var FieldRef: FieldRef; Value: Text[250]; XMLValue: Boolean; Validate: Boolean): Text[250]
    var
        "Integer": Integer;
    begin
        Integer := -1;
        if XMLValue then begin
            if OptionNoExists(FieldRef, Value) then
                Evaluate(Integer, Value);
        end else
            Integer := GetOptionNo(Value, FieldRef);

        if Integer = -1 then
            exit(CopyStr(StrSubstNo(Text004, Value, FieldRef.OptionCaption), 1, 250));

        if Validate then
            FieldRef.Validate(Integer)
        else
            FieldRef.Value := Integer;
    end;

    local procedure EvaluateValueToDate(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        Date: Date;
        Decimal: Decimal;
    begin
        if not Evaluate(Date, Value) and not Evaluate(Date, Value, XMLFormat) then
            if not Evaluate(Decimal, Value) or not Evaluate(Date, Format(DT2Date(OADateToDateTime(Decimal)))) then
                exit(StrSubstNo(Text003, Value, Format(Field.Type::Date)));

        if Validate then
            FieldRef.Validate(Date)
        else
            FieldRef.Value := Date;
    end;

    local procedure EvaluateValueToDateFormula(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        DateFormula: DateFormula;
    begin
        if not Evaluate(DateFormula, Value) and not Evaluate(DateFormula, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::DateFormula)));

        if Validate then
            FieldRef.Validate(DateFormula)
        else
            FieldRef.Value := DateFormula;
    end;

    local procedure EvaluateValueToDateTime(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        DateTime: DateTime;
    begin
        if not Evaluate(DateTime, Value) and not Evaluate(DateTime, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::DateTime)));

        if Validate then
            FieldRef.Validate(DateTime)
        else
            FieldRef.Value := DateTime;
    end;

    local procedure EvaluateValueToTime(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        Time: Time;
        Decimal: Decimal;
    begin
        if not Evaluate(Time, Value) and not Evaluate(Time, Value, XMLFormat) then
            if not Evaluate(Decimal, Value) or not Evaluate(Time, Format(DT2Time(OADateToDateTime(Decimal)))) then
                exit(StrSubstNo(Text003, Value, Format(Field.Type::Time)));

        if Validate then
            FieldRef.Validate(Time)
        else
            FieldRef.Value := Time;
    end;

    local procedure EvaluateValueToDuration(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        Duration: Duration;
    begin
        if not Evaluate(Duration, Value) and not Evaluate(Duration, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::Duration)));

        if Validate then
            FieldRef.Validate(Duration)
        else
            FieldRef.Value := Duration;
    end;

    local procedure EvaluateValueToInteger(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        "Integer": Integer;
    begin
        if not Evaluate(Integer, Value) and not Evaluate(Integer, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::Integer)));

        if Validate then
            FieldRef.Validate(Integer)
        else
            FieldRef.Value := Integer;
    end;

    local procedure EvaluateValueToBigInteger(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        BigInteger: BigInteger;
    begin
        if not Evaluate(BigInteger, Value) and not Evaluate(BigInteger, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::BigInteger)));

        if Validate then
            FieldRef.Validate(BigInteger)
        else
            FieldRef.Value := BigInteger;
    end;

    local procedure EvaluateValueToDecimal(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        Decimal: Decimal;
    begin
        if not Evaluate(Decimal, Value) and not Evaluate(Decimal, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::Decimal)));

        if Validate then
            FieldRef.Validate(Decimal)
        else
            FieldRef.Value := Decimal;
    end;

    local procedure EvaluateValueToBoolean(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        Boolean: Boolean;
    begin
        if not Evaluate(Boolean, Value) and not Evaluate(Boolean, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::Boolean)));

        if Validate then
            FieldRef.Validate(Boolean)
        else
            FieldRef.Value := Boolean;
    end;

    local procedure EvaluateValueToGuid(var FieldRef: FieldRef; Value: Text[250]; Validate: Boolean): Text[250]
    var
        "Field": Record "Field";
        Guid: Guid;
    begin
        if not Evaluate(Guid, Value) and not Evaluate(Guid, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::GUID)));

        if Validate then
            FieldRef.Validate(Guid)
        else
            FieldRef.Value := Guid;
    end;

    local procedure EvaluateValueToTableFilter(var FieldRef: FieldRef; Value: Text[250]): Text[250]
    var
        "Field": Record "Field";
        TableFilter: Text;
    begin
        if not Evaluate(TableFilter, Value) and not Evaluate(TableFilter, Value, XMLFormat) then
            exit(StrSubstNo(Text003, Value, Format(Field.Type::TableFilter)));

        Evaluate(FieldRef, TableFilter);
    end;

    local procedure IsNormalField(FieldRef: FieldRef): Boolean
    var
        "Field": Record "Field";
    begin
        Evaluate(Field.Type, Format(FieldRef.Type));

        exit(UpperCase(Format(FieldRef.Class)) = 'NORMAL');
    end;

    procedure XMLFormat(): Integer
    begin
        exit(9);
    end;

    procedure IsKeyField(TableID: Integer; FieldID: Integer): Boolean
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        KeyFieldCount: Integer;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            if FieldRef.Number = FieldID then
                exit(true);
        end;

        exit(false);
    end;

    procedure EvaluateTextToFieldRef(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    begin
        if (Format(FieldRef.Class) = 'FlowField') or (Format(FieldRef.Class) = 'FlowFilter') then
            exit(true);

        case Format(FieldRef.Type) of
            'Option':
                exit(EvaluateTextToFieldRefOption(InputText, FieldRef, ToValidate));
            'Integer':
                exit(EvaluateTextToFieldRefInteger(InputText, FieldRef, ToValidate));
            'Decimal':
                exit(EvaluateTextToFieldRefDecimal(InputText, FieldRef, ToValidate));
            'Date':
                exit(EvaluateTextToFieldRefDate(InputText, FieldRef, ToValidate));
            'Time':
                exit(EvaluateTextToFieldRefTime(InputText, FieldRef, ToValidate));
            'DateTime':
                exit(EvaluateTextToFieldRefDateTime(InputText, FieldRef, ToValidate));
            'Boolean':
                exit(EvaluateTextToFieldRefBoolean(InputText, FieldRef, ToValidate));
            'Duration':
                exit(EvaluateTextToFieldRefDuration(InputText, FieldRef, ToValidate));
            'BigInteger':
                exit(EvaluateTextToFieldRefBigInteger(InputText, FieldRef, ToValidate));
            'GUID':
                exit(EvaluateTextToFieldRefGUID(InputText, FieldRef, ToValidate));
            'Code':
                exit(EvaluateTextToFieldRefCodeText(InputText, FieldRef, ToValidate));
            'Text':
                exit(EvaluateTextToFieldRefCodeText(InputText, FieldRef, ToValidate));
            'DateFormula':
                exit(EvaluateTextToFieldRefDateFormula(InputText, FieldRef, ToValidate));
            'TableFilter':
                exit(EvaluateTextToFieldRefTableFilter(InputText, FieldRef));
            else
                exit(false);
        end;

        exit(true);
    end;

    local procedure EvaluateTextToFieldRefOption(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        IntVar: Integer;
        IntVar1: Integer;
    begin
        IntVar := GetOptionNo(InputText, FieldRef);
        if IntVar = -1 then
            exit(false);

        if ToValidate then begin
            IntVar1 := FieldRef.Value;
            if IntVar1 <> IntVar then
                FieldRef.Validate(IntVar);
        end else
            FieldRef.Value := IntVar;

        exit(true);
    end;

    local procedure EvaluateTextToFieldRefInteger(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        IntVar: Integer;
        IntVar1: Integer;
    begin
        if Evaluate(IntVar, InputText) then begin
            if ToValidate then begin
                IntVar1 := FieldRef.Value;
                if IntVar1 <> IntVar then
                    FieldRef.Validate(IntVar);
            end else
                FieldRef.Value := IntVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefDecimal(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DecimalVar: Decimal;
        DecimalVar1: Decimal;
    begin
        if Evaluate(DecimalVar, InputText) then begin
            if ToValidate then begin
                DecimalVar1 := FieldRef.Value;
                if DecimalVar1 <> DecimalVar then
                    FieldRef.Validate(DecimalVar);
            end else
                FieldRef.Value := DecimalVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefDate(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DateVar: Date;
        DateVar1: Date;
    begin
        if Evaluate(DateVar, InputText) then begin
            if ToValidate then begin
                DateVar1 := FieldRef.Value;
                if DateVar1 <> DateVar then
                    FieldRef.Validate(DateVar);
            end else
                FieldRef.Value := DateVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefTime(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        TimeVar: Time;
        TimeVar1: Time;
    begin
        if Evaluate(TimeVar, InputText) then begin
            if ToValidate then begin
                TimeVar1 := FieldRef.Value;
                if TimeVar1 <> TimeVar then
                    FieldRef.Validate(TimeVar);
            end else
                FieldRef.Value := TimeVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefDateTime(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DateTimeVar: DateTime;
        DateTimeVar1: DateTime;
    begin
        if Evaluate(DateTimeVar, InputText) then begin
            if ToValidate then begin
                DateTimeVar1 := FieldRef.Value;
                if DateTimeVar1 <> DateTimeVar then
                    FieldRef.Validate(DateTimeVar);
            end else
                FieldRef.Value := DateTimeVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefBoolean(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        BoolVar: Boolean;
        BoolVar1: Boolean;
    begin
        if Evaluate(BoolVar, InputText) then begin
            if ToValidate then begin
                BoolVar1 := FieldRef.Value;
                if BoolVar1 <> BoolVar then
                    FieldRef.Validate(BoolVar);
            end else
                FieldRef.Value := BoolVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefDuration(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DurationVar: Duration;
        DurationVar1: Duration;
    begin
        if Evaluate(DurationVar, InputText) then begin
            if ToValidate then begin
                DurationVar1 := FieldRef.Value;
                if DurationVar1 <> DurationVar then
                    FieldRef.Validate(DurationVar);
            end else
                FieldRef.Value := DurationVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefBigInteger(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        BigIntVar: BigInteger;
        BigIntVar1: BigInteger;
    begin
        if Evaluate(BigIntVar, InputText) then begin
            if ToValidate then begin
                BigIntVar1 := FieldRef.Value;
                if BigIntVar1 <> BigIntVar then
                    FieldRef.Validate(BigIntVar);
            end else
                FieldRef.Value := BigIntVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefGUID(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        GUIDVar: Guid;
        GUIDVar1: Guid;
    begin
        if Evaluate(GUIDVar, InputText) then begin
            if ToValidate then begin
                GUIDVar1 := FieldRef.Value;
                if GUIDVar1 <> GUIDVar then
                    FieldRef.Validate(GUIDVar);
            end else
                FieldRef.Value := GUIDVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefCodeText(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        TextVar: Text[1024];
        TextVar1: Text[1024];
    begin
        if StrLen(InputText) > FieldRef.Length then begin
            if ToValidate then begin
                TextVar := FieldRef.Value;
                TextVar1 := PadStr(InputText, FieldRef.Length);
                if TextVar <> TextVar1 then
                    FieldRef.Validate(TextVar1);
            end else
                FieldRef.Value := PadStr(InputText, FieldRef.Length);
        end else begin
            if ToValidate then begin
                TextVar := FieldRef.Value;
                if TextVar <> InputText then
                    FieldRef.Validate(InputText);
            end else
                FieldRef.Value := InputText;
        end;

        exit(true);
    end;

    local procedure EvaluateTextToFieldRefDateFormula(InputText: Text[250]; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DateFormulaVar: DateFormula;
        DateFormulaVar1: DateFormula;
    begin
        if Evaluate(DateFormulaVar, InputText) then begin
            if ToValidate then begin
                DateFormulaVar1 := FieldRef.Value;
                if DateFormulaVar1 <> DateFormulaVar then
                    FieldRef.Validate(DateFormulaVar);
            end else
                FieldRef.Value := DateFormulaVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefTableFilter(InputText: Text[250]; var FieldRef: FieldRef): Boolean
    begin
        Evaluate(FieldRef, InputText);
        exit(true);
    end;

    procedure CheckName(FieldName: Text[250]): Text[250]
    var
        FirstChar: Text[1];
    begin
        FirstChar := PadStr(FieldName, 1);

        case FirstChar of
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
                exit('_' + FieldName);
            else
                exit(FieldName);
        end;
    end;

    procedure AddComment(var FieldRef: FieldRef) RowComment: Text
    var
        FieldBuffer: array[250] of Text[250];
        Text10: Text[1];
        Char10: Char;
        StartPos: Integer;
        FieldNo: Integer;
        i: Integer;
    begin
        StartPos := 1;
        FieldNo := 1;
        Char10 := 10;
        Text10 := Format(Char10);

        RowComment := Format(FieldRef.Type);
        case Format(FieldRef.Type) of
            'Text', 'Code':
                RowComment := RowComment + Format(FieldRef.Length);
        end;

        if Format(FieldRef.Type) <> 'Option' then
            exit(RowComment);

        Clear(FieldBuffer);

        while not (StartPos = StrLen(FieldRef.OptionCaption) + 1) do begin
            if CopyStr(FieldRef.OptionCaption, StartPos, 1) <> ',' then
                FieldBuffer[FieldNo] := FieldBuffer[FieldNo] + CopyStr(FieldRef.OptionCaption, StartPos, 1)
            else
                FieldNo := FieldNo + 1;
            StartPos := StartPos + 1;
        end;

        for i := 1 to FieldNo do
            RowComment := RowComment + Text10 + Format(i - 1) + ': ' + FieldBuffer[i];
    end;

    local procedure LookupObject(ObjectType: Integer; var ObjectID: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
    begin
        Clear(Objects);
        AllObjWithCaption.FilterGroup(2);
        AllObjWithCaption.SetRange("Object Type", ObjectType);
        AllObjWithCaption.SetFilter("Object ID", '..%1|%2|%3', 1999999999, DATABASE::"Permission Set", DATABASE::Permission);
        AllObjWithCaption.FilterGroup(0);
        Objects.SetTableView(AllObjWithCaption);
        Objects.LookupMode := true;
        if Objects.RunModal = ACTION::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            ObjectID := AllObjWithCaption."Object ID";
        end;
    end;

    procedure LookupTable(var ObjectID: Integer)
    var
        AllObj: Record AllObj;
    begin
        LookupObject(AllObj."Object Type"::Table, ObjectID);
    end;

    procedure LookupPage(var ObjectID: Integer)
    var
        AllObj: Record AllObj;
    begin
        LookupObject(AllObj."Object Type"::Page, ObjectID);
    end;

    procedure TransferRecordDefaultValues(DataTemplateCode: Code[10]; var RecRef: RecordRef; CurFieldNo: Integer; CurDefaultValue: Text)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        FieldRef: FieldRef;
        DefaultValue: Text;
    begin
        with ConfigTemplateLine do begin
            SetRange("Data Template Code", DataTemplateCode);
            SetRange("Table ID", RecRef.Number);
            SetFilter("Field ID", '<>%1', 0);
            if FindSet then
                repeat
                    FieldRef := RecRef.Field("Field ID");
                    if "Field ID" = CurFieldNo then
                        DefaultValue := CurDefaultValue
                    else
                        DefaultValue := "Default Value";
                    ValidateFieldValue(RecRef, FieldRef, DefaultValue, true, "Language ID");
                until Next = 0;
        end;
    end;

    local procedure OADateToDateTime(DateTimeDecimal: Decimal): DateTime
    var
        DotNetDateTime: DotNet DateTime;
        DotNetDateTimeKind: DotNet DateTimeKind;
    begin
        DotNetDateTime := DotNetDateTime.FromOADate(DateTimeDecimal);
        exit(
          DotNetDateTime.DateTime(DotNetDateTime.Ticks, DotNetDateTimeKind.Local));
    end;
}

