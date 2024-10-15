codeunit 131000 "Library - Utility"
{
    // Contains all generic utility functions.

    Permissions = TableData "FA Setup" = m;

    trigger OnRun()
    begin
    end;

    var
        KeyNotFoundError: Label 'Field "%1" must be part of the primary key in the Table "%2".';
        ControlForFieldNotFoundError: Label 'Control for field %1 does not exist in Page %2.';
        FieldNotFoundError: Label 'Field %1 does not exist in Table %2.';
        PropertyValueUndefinedError: Label 'Property value is not defined.';
        ERR_NotCompatible: Label 'The two records are not compatible to compare. Field number %1 has a type mismatch. Type %2 cannot be compared with type %3.';
        PrimaryKeyNotCodeFieldErr: Label 'The primary key must be a sinlge field of type Code to use this function.';
        LibraryRandom: Codeunit "Library - Random";
        FieldOptionTypeErr: Label 'Field %1 in Table %2 must be option type.', Comment = '%1 - Field Name, %2 - Table Name';

    procedure CreateNoSeries(var NoSeries: Record "No. Series"; Default: Boolean; Manual: Boolean; DateOrder: Boolean)
    begin
        NoSeries.Init();
        NoSeries.Validate(Code, NoSeries.Code + GenerateRandomCode(NoSeries.FieldNo(Code), DATABASE::"No. Series"));
        NoSeries.Validate("Default Nos.", Default);
        NoSeries.Validate("Manual Nos.", Manual);
        NoSeries.Validate("Date Order", DateOrder);
        NoSeries.Insert(true);
    end;

    procedure CreateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; SeriesCode: Code[20]; StartingNo: Code[20]; EndingNo: Code[20])
    var
        RecRef: RecordRef;
    begin
        NoSeriesLine.Init();
        NoSeriesLine.Validate("Series Code", SeriesCode);
        RecRef.GetTable(NoSeriesLine);
        NoSeriesLine.Validate("Line No.", GetNewLineNo(RecRef, NoSeriesLine.FieldNo("Line No.")));

        if StartingNo = '' then
            NoSeriesLine.Validate("Starting No.", PadStr(InsStr(SeriesCode, '00000000', 3), 10))
        else
            NoSeriesLine.Validate("Starting No.", StartingNo);

        if EndingNo = '' then
            NoSeriesLine.Validate("Ending No.", PadStr(InsStr(SeriesCode, '99999999', 3), 10))
        else
            NoSeriesLine.Validate("Ending No.", EndingNo);

        NoSeriesLine.Insert(true)
    end;

    procedure CreateNoSeriesRelationship("Code": Code[20]; SeriesCode: Code[20])
    var
        NoSeriesRelationship: Record "No. Series Relationship";
    begin
        NoSeriesRelationship.Init();
        NoSeriesRelationship.Validate(Code, Code);
        NoSeriesRelationship.Validate("Series Code", SeriesCode);
        NoSeriesRelationship.Insert(true);
    end;

    procedure CreateRecordLink(RecVar: Variant): Integer
    var
        RecordLink: Record "Record Link";
    begin
        exit(CreateRecordLink(RecVar, RecordLink.Type::Note));
    end;

    procedure CreateRecordLink(RecVar: Variant; LinkType: Option): Integer
    var
        RecordLink: Record "Record Link";
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        RecordLink."Record ID" := RecRef.RecordId();
        RecordLink.URL1 := GetUrl(DefaultClientType, CompanyName, OBJECTTYPE::Page, PageManagement.GetPageID(RecVar), RecRef);
        RecordLink.Type := LinkType;
        RecordLink.Notify := true;
        RecordLink.Company := CompanyName();
        RecordLink."User ID" := UserId();
        RecordLink."To User ID" := UserId();
        RecordLink.Insert();
        exit(RecordLink."Link ID");
    end;

    procedure CheckFieldExistenceInTable(TableNo: Integer; FieldName: Text[30]): Boolean
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(FieldName, FieldName);
        exit(Field.FindFirst())
    end;

    procedure CheckFileNotEmpty(FileName: Text): Boolean
    var
        File: File;
    begin
        // The parameter FileName should contain the full File Name including path.
        if FileName = '' then
            exit(false);
        if File.Open(FileName) then
            if File.Len > 0 then
                exit(true);
        exit(false);
    end;

    procedure CompareTwoRecords(RecRef1: RecordRef; RecRef2: RecordRef; FieldCountsToBeIgnored: Integer; DiscardDateTimeFields: Boolean; var FieldNumbersNotMatched: array[200] of Integer; var Value1: array[200] of Variant; var Value2: array[200] of Variant; var MismatchCount: Integer): Boolean
    var
        FieldRef1: FieldRef;
        FieldRef2: FieldRef;
        index1: Integer;
        index2: Integer;
        FldCount: Integer;
        continue: Boolean;
    begin
        index1 := RecRef1.KeyIndex(1).FieldCount + 1;
        index2 := RecRef2.KeyIndex(1).FieldCount + 1;
        FldCount := RecRef1.FieldCount;
        if RecRef2.FieldCount < RecRef1.FieldCount then
            FldCount := RecRef2.FieldCount;
        Clear(FieldNumbersNotMatched);
        Clear(Value1);
        Clear(Value2);
        MismatchCount := 0;
        while (index1 <= FldCount) and (index2 <= FldCount) do begin
            if RecRef1.FieldIndex(index1).Number > RecRef2.FieldIndex(index2).Number then begin
                index2 := index2 + 1;
                continue := true;
            end else
                if RecRef2.FieldIndex(index2).Number > RecRef1.FieldIndex(index1).Number then begin
                    index1 := index1 + 1;
                    continue := true;
                end;
            if not continue then begin
                FieldRef1 := RecRef1.FieldIndex(index1);
                FieldRef2 := RecRef2.FieldIndex(index2);
                if FieldRef1.Type <> FieldRef2.Type then
                    Error(ERR_NotCompatible, FieldRef1.Number, FieldRef1.Type, FieldRef2.Type);
                if DiscardDateTimeFields and (FieldRef1.Type in [FieldType::Date, FieldType::Time, FieldType::DateTime]) then
                    continue := true;
                if not continue then
                    if FieldRef1.Value <> FieldRef2.Value then begin
                        MismatchCount := MismatchCount + 1;
                        FieldNumbersNotMatched[MismatchCount] := FieldRef1.Number;
                        Value1[MismatchCount] := FieldRef1.Value();
                        Value2[MismatchCount] := FieldRef2.Value();
                    end;
                index1 := index1 + 1;
                index2 := index2 + 1;
            end;
            continue := false;
        end;
        if MismatchCount > FieldCountsToBeIgnored then
            exit(false);
        exit(true);
    end;

    procedure ConvertMilliSecToHours(TimePeriod: Decimal): Decimal
    begin
        exit(TimePeriod / 3600000);
    end;

    procedure ConvertHoursToMilliSec(TimePeriod: Decimal): Decimal
    begin
        exit(TimePeriod * 3600000);
    end;

    procedure ConvertNumericToText(NumericCode: Text): Text
    begin
        exit(ConvertStr(NumericCode, '0123456789', 'ABCDEFGHIJ'));
    end;

    procedure ConvertCRLFToBackSlash(TextIn: Text): Text
    var
        CRLF: Text;
        Position: Integer;
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        Position := StrPos(TextIn, CRLF);
        while Position <> 0 do begin
            TextIn := DelStr(TextIn, Position, StrLen(CRLF));
            TextIn := InsStr(TextIn, '\', Position);
            Position := StrPos(TextIn, CRLF);
        end;
        exit(TextIn);
    end;

    procedure FindControl(ObjectNo: Integer; FieldNo: Integer): Boolean
    var
        AppObjectMetadata: Record "Application Object Metadata";
        AllObj: Record AllObj;
        MetaDataInstream: InStream;
        TestString: Text[1024];
    begin
        TestString := '';

        AllObj.Get(AllObj."Object Type"::Page, ObjectNo);
        AppObjectMetadata.Get(AllObj."App Runtime Package ID", AppObjectMetadata."Object Type"::Page, ObjectNo);
        AppObjectMetadata.CalcFields(Metadata);
        if AppObjectMetadata.Metadata.HasValue() then
            AppObjectMetadata.Metadata.CreateInStream(MetaDataInstream);

        while not MetaDataInstream.EOS do begin
            MetaDataInstream.ReadText(TestString);
            if StrPos(TestString, 'DataColumnName="' + Format(FieldNo) + '"') <> 0 then
                exit(true);
        end;
        exit(false);
    end;

    procedure FindEditable(ObjectNo: Integer; FieldNo: Integer): Boolean
    var
        Editable: Text[30];
    begin
        // Find and return the Editable property for a page control. Generate an error if page control does not exists.
        Editable := GetPropertyValueForControl(ObjectNo, FieldNo, 'Editable="', true);
        if Editable = 'FALSE' then
            exit(false);
        if (Editable = '') or (Editable = 'TRUE') then
            exit(true);
    end;

    procedure FindFieldNoInTable(TableNo: Integer; FieldName: Text[30]): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(FieldName, FieldName);
        Field.FindFirst();
        exit(Field."No.");
    end;

    procedure FindMaxValueForField(ObjectNo: Integer; FieldNo: Integer) MaximumValue: Integer
    begin
        Evaluate(MaximumValue, GetPropertyValueForField(ObjectNo, FieldNo, 'MaxValue="', false));
        exit(MaximumValue);
    end;

    procedure FindMinValueForField(ObjectNo: Integer; FieldNo: Integer) MinimumValue: Integer
    begin
        Evaluate(MinimumValue, GetPropertyValueForField(ObjectNo, FieldNo, 'MinValue="', false));
        exit(MinimumValue);
    end;

    procedure FindVisible(ObjectNo: Integer; FieldNo: Integer): Boolean
    var
        Visible: Text[30];
    begin
        Visible := GetPropertyValueForControl(ObjectNo, FieldNo, 'Visible="', true);
        if Visible = 'FALSE' then
            exit(false);
        if (Visible = '') or (Visible = 'TRUE') then
            exit(true);
    end;

    procedure GetFieldLength(TableNo: Integer; FieldNo: Integer): Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        exit(FieldRef.Length);
    end;

    procedure GetLastTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast() then
            exit(GLEntry."Transaction No.");

        exit(0);
    end;

    procedure GetNewRecNo(RecVariant: Variant; FieldNo: Integer): Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVariant);
        exit(GetNewLineNo(RecRef, FieldNo));
    end;

    procedure GetNewLineNo(RecRef: RecordRef; FieldNo: Integer): Integer
    var
        RecRef2: RecordRef;
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
        KeyRef: KeyRef;
        FieldCount: Integer;
        LineNumberFound: Boolean;
    begin
        // Find the value of Line No. for a new line in the Record passed as Record Ref.
        // 1. It is assumed that the field passed is part of the primary key.
        // 2. It is assumed that all the primary key fields except Line No. field are already validated on the record.
        RecRef2.Open(RecRef.Number, false, CompanyName);
        KeyRef := RecRef.KeyIndex(1);  // The Primary Key always has index as 1.
        for FieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(FieldCount);
            if FieldRef.Number <> FieldNo then begin
                FieldRef2 := RecRef2.Field(FieldRef.Number);
                FieldRef2.SetRange(FieldRef.Value);  // Set filter on fields other than Line No with value as filled in on RecRef.
            end else
                LineNumberFound := true;
        end;

        if not LineNumberFound then begin
            FieldRef := RecRef2.Field(FieldNo);
            Error(KeyNotFoundError, FieldRef.Name, RecRef2.Name);
        end;

        if RecRef2.FindLast() then begin
            FieldRef := RecRef2.Field(FieldNo);
            FieldCount := FieldRef.Value();
        end else
            FieldCount := 0;
        exit(FieldCount + 10000);  // Add 10000 to the last Line No.
    end;

    procedure GetGlobalNoSeriesCode(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesCode: Code[20];
    begin
        // Init, get the global no series
        NoSeriesCode := GlobalNoSeriesCode();
        if not NoSeries.Get(NoSeriesCode) then begin
            NoSeries.Init();
            NoSeries.Validate(Code, NoSeriesCode);
            NoSeries.Validate("Default Nos.", true);
            NoSeries.Validate("Manual Nos.", true);
            NoSeries.Insert(true);
            CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        end;

        exit(NoSeries.Code)
    end;

    procedure GetNextNoSeriesSalesDate(NoSeriesCode: Code[20]): Date
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeriesCode <> '' then begin
            NoSeries.Get(NoSeriesCode);
            NoSeries.TestField("Date Order", false); // Use of Date Order is only tested on IT
        end;
        exit(WorkDate());
    end;

    procedure GetNextNoSeriesPurchaseDate(NoSeriesCode: Code[20]): Date
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeriesCode <> '' then begin
            NoSeries.Get(NoSeriesCode);
            NoSeries.TestField("Date Order", false); // Use of Date Order is only tested on IT
        end;
        exit(WorkDate());
    end;

    local procedure GetPropertyValue(ObjectType: Option; ObjectNo: Integer; FieldNo: Integer; PropertyName: Text[30]; SuppressError: Boolean): Text[30]
    var
        AppObjectMetadata: Record "Application Object Metadata";
        AllObj: Record AllObj;
        MetaDataInstream: InStream;
        ControlFound: Boolean;
        TestString: Text[1024];
    begin
        AllObj.Get(ObjectType, ObjectNo);
        AppObjectMetadata.Get(AllObj."App Runtime Package ID", ObjectType, ObjectNo);
        AppObjectMetadata.CalcFields(Metadata);
        if AppObjectMetadata.Metadata.HasValue() then
            AppObjectMetadata.Metadata.CreateInStream(MetaDataInstream);

        while not MetaDataInstream.EOS do begin
            MetaDataInstream.ReadText(TestString);
            if StrPos(TestString, GetTextValue(ObjectType) + Format(FieldNo) + '"') <> 0 then begin
                ControlFound := true;
                if StrPos(TestString, PropertyName) <> 0 then begin
                    TestString := CopyStr(TestString, StrPos(TestString, PropertyName) + StrLen(PropertyName), 10);
                    exit(CopyStr(TestString, 1, StrPos(TestString, '"') - 1));
                end;
                if (StrPos(TestString, '/>') <> 0) and not SuppressError then
                    Error(PropertyValueUndefinedError);
            end;
        end;
        if not ControlFound then begin
            if ObjectType = AppObjectMetadata."Object Type"::Page then
                Error(ControlForFieldNotFoundError, FieldNo, ObjectNo);
            Error(FieldNotFoundError, FieldNo, ObjectNo);
        end;
        exit('');
    end;

    procedure GetPropertyValueForControl(ObjectNo: Integer; FieldNo: Integer; PropertyName: Text[30]; SuppressError: Boolean): Text[30]
    var
        AppObjectMetadata: Record "Application Object Metadata";
    begin
        exit(GetPropertyValue(AppObjectMetadata."Object Type"::Page, ObjectNo, FieldNo, PropertyName, SuppressError));
    end;

    procedure GetPropertyValueForField(ObjectNo: Integer; FieldNo: Integer; PropertyName: Text[30]; SuppressError: Boolean): Text[30]
    var
        AppObjectMetadata: Record "Application Object Metadata";
    begin
        exit(GetPropertyValue(AppObjectMetadata."Object Type"::Table, ObjectNo, FieldNo, PropertyName, SuppressError));
    end;

    procedure GetNextNoFromNoSeries(NoSeriesCode: Code[20]; PostingDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode, PostingDate));
    end;

    procedure GenerateRandomCode(FieldNo: Integer; TableNo: Integer): Code[10]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Create a random and unique code for the any code field.
        RecRef.Open(TableNo, true, CompanyName);
        Clear(FieldRef);
        FieldRef := RecRef.Field(FieldNo);

        repeat
            if FieldRef.Length < 10 then
                FieldRef.SetRange(CopyStr(GenerateGUID(), 10 - FieldRef.Length + 1)) // Cut characters on the left side.
            else
                FieldRef.SetRange(GenerateGUID());
        until RecRef.IsEmpty();

        exit(FieldRef.GetFilter)
    end;

    procedure GenerateRandomCodeWithLength(FieldNo: Integer; TableNo: Integer; CodeLength: Integer): Code[10]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        NewCode: Code[10];
    begin
        // Create a random and unique code for the any code field.
        RecRef.Open(TableNo, false, CompanyName);
        Clear(FieldRef);
        FieldRef := RecRef.Field(FieldNo);
        repeat
            NewCode := CopyStr(GenerateRandomXMLText(CodeLength), 1, MaxStrLen(NewCode));
            FieldRef.SetRange(NewCode);
        until RecRef.IsEmpty();

        exit(NewCode);
    end;

    procedure GenerateRandomCode20(FieldNo: Integer; TableNo: Integer): Code[20]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Create a random and unique 20 code for the any code field.
        RecRef.Open(TableNo, false, CompanyName);
        Clear(FieldRef);
        FieldRef := RecRef.Field(FieldNo);
        repeat
            FieldRef.SetRange(PadStr(GenerateGUID(), FieldRef.Length, '0'));
        until RecRef.IsEmpty();

        exit(FieldRef.GetFilter);
    end;

    procedure GenerateRandomText(Length: Integer) String: Text
    var
        i: Integer;
    begin
        // Create a random string of length <length>.
        for i := 1 to Length do
            String[i] := LibraryRandom.RandIntInRange(33, 126); // ASCII: ! (33) to ~ (126)

        exit(String)
    end;

    procedure GenerateRandomUnicodeText(Length: Integer) String: Text
    var
        i: Integer;
    begin
        // Create a random string of length <Length> with Unicode characters.
        for i := 1 to Length do
            String[i] := LibraryRandom.RandIntInRange(1072, 1103); // Cyrillic alphabet (to guarantee only printable chars)

        exit(String)
    end;

    procedure GenerateRandomXMLText(Length: Integer) String: Text
    var
        i: Integer;
        Number: Integer;
    begin
        // Create a random string of length <length> containing characters allowed by XML
        for i := 1 to Length do begin
            Number := LibraryRandom.RandIntInRange(0, 1000) mod 61;
            case Number of
                0 .. 9:
                    Number += 48; // 0-9
                10 .. 35:
                    Number += 65 - 10; // A-Z
                36 .. 61:
                    Number += 97 - 36; // a-z
            end;
            String[i] := Number;
        end;
    end;

    procedure GenerateRandomNumericText(Length: Integer) String: Text
    var
        i: Integer;
    begin
        for i := 1 to Length do
            String[i] := LibraryRandom.RandIntInRange(48, 57);
    end;

    procedure GenerateRandomAlphabeticText(Length: Integer; Option: Option Capitalized,Literal) String: Text
    var
        ASCIICodeFrom: Integer;
        ASCIICodeTo: Integer;
        Number: Integer;
        i: Integer;
    begin
        case Option of
            Option::Capitalized:
                begin
                    ASCIICodeFrom := 65;
                    ASCIICodeTo := 90;
                end;
            Option::Literal:
                begin
                    ASCIICodeFrom := 97;
                    ASCIICodeTo := 122;
                end;
            else
                exit;
        end;
        for i := 1 to Length do begin
            Number := LibraryRandom.RandIntInRange(ASCIICodeFrom, ASCIICodeTo);
            String[i] := Number;
        end;
    end;

    procedure GenerateRandomEmail(): Text[45]
    begin
        exit(GenerateRandomAlphabeticText(20, 1) + '@' + GenerateRandomAlphabeticText(20, 1) + '.' + GenerateRandomAlphabeticText(3, 1));
    end;

    procedure GenerateRandomEmails(): Text[80]
    begin
        exit(
            StrSubstNo('%1@%2.%3; ', GenerateRandomXMLText(10), GenerateRandomXMLText(10), GenerateRandomXMLText(3)) +
            StrSubstNo('%1@%2.%3; ', GenerateRandomXMLText(10), GenerateRandomXMLText(10), GenerateRandomXMLText(3)) +
            StrSubstNo('%1@%2.%3', GenerateRandomXMLText(10), GenerateRandomXMLText(10), GenerateRandomXMLText(3)));
    end;

    procedure GenerateRandomPhoneNo(): Text[20]
    var
        PlusSign: Text[1];
        OpenBracket: Text[1];
        CloseBracket: Text[1];
        Delimiter: Text[1];
    begin
        // +123 (456) 1234-1234
        // 123 456 12341234
        if LibraryRandom.RandInt(100) > 50 then begin
            PlusSign := '+';
            OpenBracket := '(';
            CloseBracket := ')';
            Delimiter := '-';
        end;
        exit(
            PlusSign + GenerateRandomNumericText(3) + ' ' +
            OpenBracket + GenerateRandomNumericText(3) + CloseBracket + ' ' +
            GenerateRandomNumericText(4) + Delimiter + GenerateRandomNumericText(4));
    end;

    procedure GenerateRandomFraction(): Decimal
    begin
        exit(LibraryRandom.RandInt(99) / 100);  // Generate any fraction between 0.01 to .99.
    end;

    procedure GenerateRandomDate(MinDate: Date; MaxDate: Date): Date
    var
        DateFormulaRandomDate: DateFormula;
        DateFormulaMinDate: DateFormula;
    begin
        Evaluate(DateFormulaMinDate, '<-1D>');
        Evaluate(DateFormulaRandomDate, '<' + Format(LibraryRandom.RandInt(MaxDate - MinDate + 1)) + 'D>');
        exit(CalcDate(DateFormulaRandomDate, CalcDate(DateFormulaMinDate, MinDate)));
    end;

    procedure GenerateGUID(): Code[10]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        if not NoSeries.Get('GUID') then begin
            NoSeries.Init();
            NoSeries.Validate(Code, 'GUID');
            NoSeries.Validate("Default Nos.", true);
            NoSeries.Validate("Manual Nos.", true);
            NoSeries.Insert(true);

            CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        end;

        exit(NoSeriesCodeunit.GetNextNo(NoSeries.Code));
    end;

    procedure GetEmptyGuid(): Guid
    var
        EmptyGuid: Guid;
    begin
        exit(EmptyGuid);
    end;

    procedure GenerateRandomRec(var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Class = FieldClass::Normal then
                case FieldRef.Type of
                    FieldType::Text:
                        FieldRef.Value := GenerateRandomXMLText(FieldRef.Length);
                    FieldType::Date:
                        FieldRef.Value := GenerateRandomDate(Today, CalcDate('<1Y>'));
                    FieldType::Decimal:
                        FieldRef.Value := LibraryRandom.RandDec(9999999, 2);
                end;
        end;
    end;

    procedure GenerateMOD97CompliantCode() CodeMod97Compliant: Code[10]
    var
        CompliantCodeBody: Integer;
    begin
        CompliantCodeBody := LibraryRandom.RandIntInRange(1, 100000000);
        CodeMod97Compliant := ConvertStr(Format(CompliantCodeBody, 8, '<Integer>'), ' ', '0');
        CodeMod97Compliant += ConvertStr(Format(97 - CompliantCodeBody mod 97, 2, '<Integer>'), ' ', '0');
    end;

    procedure ExistsDecimalValueInArray(RowValueSet: array[250] of Text[250]; Value: Decimal): Boolean
    var
        Counter: Integer;
        CurrentValue: Decimal;
    begin
        repeat
            Counter += 1;
            if Evaluate(CurrentValue, RowValueSet[Counter]) then;
        until (CurrentValue = Value) or (Counter = ArrayLen(RowValueSet));
        exit(CurrentValue = Value);
    end;

    procedure FindRecord(var RecRef: RecordRef)
    begin
        RecRef.FindFirst();
    end;

    local procedure GetTextValue(ObjectType: Option): Text[30]
    var
        AppObjectMetadata: Record "Application Object Metadata";
    begin
        if ObjectType = AppObjectMetadata."Object Type"::Page then
            exit('DataColumnName="');
        exit('Field ID="');
    end;

    procedure LineBreak(): Text
    var
        NewLine: Char;
    begin
        NewLine := 10;
        exit(Format(NewLine));
    end;

    procedure FindOrCreateCodeRecord(TableID: Integer): Code[10]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        VerifyRecordHasCodeKey(TableID, RecRef, FieldRef);
        if not RecRef.FindFirst() then begin
            FieldRef.Validate(GenerateRandomCode(FieldRef.Number, TableID));
            RecRef.Insert(true);
        end;
        exit(FieldRef.Value);
    end;

    procedure CreateCodeRecord(TableID: Integer): Code[10]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        VerifyRecordHasCodeKey(TableID, RecRef, FieldRef);
        FieldRef.Validate(GenerateRandomCode(FieldRef.Number, TableID));
        RecRef.Insert(true);
        exit(FieldRef.Value);
    end;

    procedure UpdateSetupNoSeriesCode(TableID: Integer; FieldID: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        NoSeriesCode: Code[20];
    begin
        RecRef.Open(TableID);
        RecRef.Find();
        FieldRef := RecRef.Field(FieldID);
        NoSeriesCode := GetGlobalNoSeriesCode();
        if Format(FieldRef.Value) <> NoSeriesCode then begin
            FieldRef.Value(NoSeriesCode);
            RecRef.Modify();
        end;
    end;

    procedure AddTempField(var TempField: Record "Field" temporary; FieldNo: Integer; TableNo: Integer)
    var
        "Field": Record "Field";
    begin
        Clear(TempField);
        Field.Get(TableNo, FieldNo);
        TempField.TransferFields(Field, true);
        TempField.Insert();
    end;

    local procedure VerifyRecordHasCodeKey(TableID: Integer; var RecRef: RecordRef; var FieldRef: FieldRef)
    var
        "Field": Record "Field";
        KeyRef: KeyRef;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);

        Field.Get(TableID, FieldRef.Number);
        if (KeyRef.FieldCount <> 1) or (Field.Type <> Field.Type::Code) then
            Error(PrimaryKeyNotCodeFieldErr);
    end;

    procedure GetMaxOptionIndex(OptionString: Text): Integer
    begin
        exit(StrLen(DelChr(OptionString, '=', DelChr(OptionString, '=', ','))));
    end;

    procedure GetMaxFieldOptionIndex(TableNo: Integer; FieldNo: Integer): Integer
    var
        "Field": Record "Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);

        Field.Get(TableNo, FieldNo);
        if Field.Type <> Field.Type::Option then
            Error(FieldOptionTypeErr, FieldRef.Name, RecRef.Name);
        exit(GetMaxOptionIndex(FieldRef.OptionCaption));
    end;

    procedure FillFieldMaxText(RecVar: Variant; FieldNo: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecVar);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Value := GenerateRandomText(FieldRef.Length);
        RecRef.Modify();
    end;

    procedure GlobalNoSeriesCode(): Code[20]
    begin
        // FI Registration No functionality: Only numeric characters allowed in No from number series
        exit('123');
    end;

    procedure GetInetRoot(): Text
    begin
        exit(ApplicationPath + '\..\..\');
    end;

    // Does the opposite of IncStr, i.e. decrements the last number in a string.
    // NOTE: Expects the string actually contains a number.
    // NOTE: The implementation is not guaranteed to be correcet. Works for most common cases. 
    //  Verify the result like shown here:
    //      decStr := DecStr(str); 
    //      Assert.AreEqual(str, IncStr(decStr)), 'DecStr not working.');
    procedure DecStr(str: Text): Text
    var
        Index: Integer;
        StartIndex: Integer;
        EndIndex: Integer;
        Number: Integer;
        Digits: Text;
        ZeroPadding: Text;
        NewStr: Text;
    begin

        StartIndex := 1;

        // Find integer suffix.
        for Index := StrLen(str) downto 1 do begin
            if Evaluate(Number, str.Substring(Index, 1)) then begin
                Digits := str.Substring(Index, 1) + Digits;
                if EndIndex = 0 then
                    EndIndex := Index;
            end else begin
                if StrLen(Digits) > 0 then begin
                    StartIndex := Index + 1;
                    break;
                end;
            end;
        end;

        // Get zero padding in the digits.
        for Index := 1 to StrLen(Digits) do begin
            if Digits.Substring(Index, 1) = '0' then
                ZeroPadding := ZeroPadding + '0'
            else
                break;
        end;

        Evaluate(Number, Digits);
        Number := Number - 1;

        // Replace old integer suffix with new.
        NewStr := Str.Substring(1, StartIndex - 1) + ZeroPadding + Format(Number);
        if EndIndex < StrLen(str) then
            NewStr := NewStr + Str.Substring(EndIndex + 1, StrLen(str) - EndIndex);

        exit(NewStr);
    end;

    procedure GetNoSeriesLine(noSeriesCode: Code[20]; var noSeriesLine: Record "No. Series Line"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.GetNoSeriesLine(noSeriesLine, noSeriesCode, WorkDate(), true));
    end;
}
