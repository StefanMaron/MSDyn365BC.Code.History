table 1237 "Transformation Rule"
{
    Caption = 'Transformation Rule';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Transformation Rules";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Transformation Type"; Enum "Transformation Rule Type")
        {
            Caption = 'Transformation Type';

            trigger OnValidate()
            begin
                if not ("Transformation Type" in ["Transformation Type"::Replace,
                                                  "Transformation Type"::"Regular Expression - Replace",
                                                  "Transformation Type"::"Regular Expression - Match"])
                then begin
                    "Find Value" := '';
                    "Replace Value" := '';
                end;
                if not ("Transformation Type" in ["Transformation Type"::Substring]) then begin
                    "Start Position" := 0;
                    Length := 0;
                    "Ending Text" := '';
                    "Starting Text" := '';
                end;
                if not IsDataFormatUpdateAllowed() then begin
                    "Data Format" := '';
                    "Data Formatting Culture" := '';
                end;
            end;
        }
        field(10; "Find Value"; Text[250])
        {
            Caption = 'Find Value';

            trigger OnValidate()
            begin
                if not ("Transformation Type" in ["Transformation Type"::Replace,
                                                  "Transformation Type"::"Regular Expression - Replace",
                                                  "Transformation Type"::"Regular Expression - Match"])
                then
                    TestField("Find Value", '');
            end;
        }
        field(11; "Replace Value"; Text[250])
        {
            Caption = 'Replace Value';

            trigger OnValidate()
            begin
                if not ("Transformation Type" in ["Transformation Type"::Replace, "Transformation Type"::"Regular Expression - Replace"]) then
                    TestField("Replace Value", '');
            end;
        }
        field(12; "Starting Text"; Text[250])
        {
            Caption = 'Starting Text';

            trigger OnValidate()
            begin
                if "Starting Text" <> '' then begin
                    TestField("Transformation Type", "Transformation Type"::Substring);
                    Validate("Start Position", 0);
                end;
            end;
        }
        field(13; "Ending Text"; Text[250])
        {
            Caption = 'Ending Text';

            trigger OnValidate()
            begin
                if "Ending Text" <> '' then begin
                    TestField("Transformation Type", "Transformation Type"::Substring);
                    Validate(Length, 0);
                end;
            end;
        }
        field(15; "Start Position"; Integer)
        {
            BlankZero = true;
            Caption = 'Start Position';

            trigger OnValidate()
            begin
                if "Transformation Type" = "Transformation Type"::Substring then
                    if "Start Position" < 0 then
                        Error(MustBeGreaterThanZeroErr);

                if "Start Position" <> 0 then begin
                    TestField("Transformation Type", "Transformation Type"::Substring);
                    Validate("Starting Text", '');
                end;
            end;
        }
        field(16; Length; Integer)
        {
            BlankZero = true;
            Caption = 'Length';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Transformation Type" = "Transformation Type"::Substring then
                    if Length < 0 then
                        Error(MustBeGreaterThanZeroErr);

                IsHandled := false;
                OnValidateLengthOnBeforeTestTransformationType(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if Length <> 0 then begin
                    TestField("Transformation Type", "Transformation Type"::Substring);
                    Validate("Ending Text", '');
                end;
            end;
        }
        field(18; "Data Format"; Text[100])
        {
            Caption = 'Data Format';

            trigger OnValidate()
            begin
                if not IsDataFormatUpdateAllowed() then
                    TestField("Data Format", '');
            end;
        }
        field(20; "Data Formatting Culture"; Text[10])
        {
            Caption = 'Data Formatting Culture';

            trigger OnValidate()
            begin
                if not IsDataFormatUpdateAllowed() then
                    TestField("Data Formatting Culture", '');
            end;
        }
        field(30; "Next Transformation Rule"; Code[20])
        {
            Caption = 'Next Transformation Rule';
            TableRelation = "Transformation Rule".Code;
        }
        field(50; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            trigger OnLookup()
            var
                ConfigValidateMgt: Codeunit "Config. Validate Management";
            begin
                ConfigValidateMgt.LookupTable("Table ID");
                if "Table ID" <> 0 then
                    Validate("Table ID");
            end;

            trigger OnValidate()
            begin
                CalcFields("Table Caption");
            end;
        }
        field(51; "Table Caption"; Text[250])
        {
            Caption = 'Table ID';
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Source Field ID"; Integer)
        {
            Caption = 'Source Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));

            trigger OnValidate()
            begin
                if ("Source Field ID" <> 0) and ("Target Field ID" = "Source Field ID") then
                    FieldError("Source Field ID");
                CalcFields("Source Field Caption");
            end;
        }
        field(53; "Source Field Caption"; Text[250])
        {
            Caption = 'Source Field Caption';
            CalcFormula = Lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Source Field ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Target Field ID"; Integer)
        {
            Caption = 'Target Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));

            trigger OnValidate()
            begin
                if ("Target Field ID" <> 0) and ("Target Field ID" = "Source Field ID") then
                    FieldError("Target Field ID");
                CalcFields("Target Field Caption");
            end;
        }
        field(55; "Target Field Caption"; Text[250])
        {
            Caption = 'Target Field Caption';
            CalcFormula = Lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Target Field ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Field Lookup Rule"; Option)
        {
            Caption = 'Field Lookup Rule';
            OptionMembers = Target,"Original If Target Is Blank";
        }
        field(57; Precision; Decimal)
        {
            Caption = 'Precision';
        }
        field(58; Direction; Text[1])
        {
            Caption = 'Direction';
        }
        field(70; "Extract From Date Type"; Enum "Extract From Date Type")
        {
            Caption = 'Extract From Date Type';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckMandatoryFields();
    end;

    trigger OnModify()
    begin
        CheckMandatoryFields();
    end;

    var
        MustBeGreaterThanZeroErr: Label 'The Value entered must be greater than zero.';
        UPPERCASETxt: Label 'UPPERCASE', Comment = 'Assigned to Transformation.Code field for Upper case';
        UpperCaseDescTxt: Label 'Upper Case Text';
        LOWERCASETxt: Label 'LOWERCASE', Comment = 'Assigned to Transformation.Code field for Lower case';
        LowerCaseDescTxt: Label 'Lower Case Text';
        TITLECASETxt: Label 'TITLECASE', Comment = 'Assigned to Transformation.Code field for Title case';
        TitleCaseDescTxt: Label 'Title Case Text';
        TRIMTxt: Label 'TRIM', Comment = 'Assigned to Transformation.Code field for Trim';
        TrimDescTxt: Label 'Trim Text';
        FOURTH_TO_SIXTH_CHARTxt: Label 'FOURTH_TO_SIXTH_CHAR', Comment = 'Assigned to Transformation.Code field for getting the 4th to 6th characters in a string';
        FourthToSixthCharactersDescTxt: Label 'Fourth to Sixth Characters Text';
        YYYYMMDDDateTxt: Label 'YYYYMMDD_DATE', Comment = 'Assigned to Transformation.Code field for converting dates from yyyyMMdd format';
        YYYYMMDDDateDescTxt: Label 'yyyyMMdd Date Text';
        YYYYMMDDHHMMSSTxt: Label 'YYYYMMDDHHMMSS_FMT', Comment = 'Assigned to Transformation.Code field for converting dates from yyyyMMdd format';
        YYYYMMDDHHMMSSDescTxt: Label 'yyyyMMddHHmmss Date/Time Format';
        ALPHANUMERIC_ONLYTxt: Label 'ALPHANUMERIC_ONLY', Comment = 'Assigned to Transformation.Code field for getting only the Alphanumeric characters in a string';
        AlphaNumericDescTxt: Label 'Alphanumeric Text Only';
        DKNUMBERFORMATTxt: Label 'DK_DECIMAL_FORMAT', Comment = 'Assigned to Transformation.Code field for getting decimal formatting rule for Danish numbers';
        DKNUMBERFORMATDescTxt: Label 'Danish Decimal Format';
        USDATEFORMATTxt: Label 'US_DATE_FORMAT', Comment = 'Assigned to Transformation.Code field for getting date formatting rule from U.S. dates';
        USDATEFORMATDescTxt: Label 'U.S. Date Format';
        USDATETIMEFORMATTxt: Label 'US_DATETIME_FORMAT', Comment = 'Assigned to Transformation.Code field for getting date formatting rule from U.S. dates';
        USDATETIMEFORMATDescTxt: Label 'U.S. Date/Time Format';
        DeleteNOTPROVIDEDTxt: Label 'DELETE_NOTPROVIDED', Comment = 'NOTPROVIDED should stay in english because it is a constant value. DELETE should be translated.';
        DeleteNOTPROVIDEDDescriptionTxt: Label 'Delete NOTPROVIDED value', Comment = 'NOTPROVIDED should stay in english because it is a constant value. ''Delete'' and ''value'' should be translated.';

    procedure CreateDefaultTransformations()
    begin
        InsertRec(UPPERCASETxt, UpperCaseDescTxt, "Transformation Type"::Uppercase.AsInteger(), 0, 0, '', '');
        InsertRec(LOWERCASETxt, LowerCaseDescTxt, "Transformation Type"::Lowercase.AsInteger(), 0, 0, '', '');
        InsertRec(TITLECASETxt, TitleCaseDescTxt, "Transformation Type"::"Title Case".AsInteger(), 0, 0, '', '');
        InsertRec(TRIMTxt, TrimDescTxt, "Transformation Type"::Trim.AsInteger(), 0, 0, '', '');
        InsertRec(FOURTH_TO_SIXTH_CHARTxt, FourthToSixthCharactersDescTxt, "Transformation Type"::Substring.AsInteger(), 4, 3, '', '');
        InsertRec(YYYYMMDDDateTxt, YYYYMMDDDateDescTxt, "Transformation Type"::"Date Formatting".AsInteger(), 0, 0, 'yyyyMMdd', '');
        InsertRec(YYYYMMDDHHMMSSTxt, YYYYMMDDHHMMSSDescTxt, "Transformation Type"::"Date and Time Formatting".AsInteger(), 0, 0, 'yyyyMMddHHmmss', '');
        InsertRec(ALPHANUMERIC_ONLYTxt, AlphaNumericDescTxt, "Transformation Type"::"Remove Non-Alphanumeric Characters".AsInteger(), 0, 0, '', '');
        InsertRec(DKNUMBERFORMATTxt, DKNUMBERFORMATDescTxt, "Transformation Type"::"Decimal Formatting".AsInteger(), 0, 0, '', 'da-DK');
        InsertRec(USDATEFORMATTxt, USDATEFORMATDescTxt, "Transformation Type"::"Date Formatting".AsInteger(), 0, 0, '', 'en-US');
        InsertRec(USDATETIMEFORMATTxt, USDATETIMEFORMATDescTxt, "Transformation Type"::"Date and Time Formatting".AsInteger(), 0, 0, '', 'en-US');
        OnCreateTransformationRules();
        InsertFindAndReplaceRule(
          DeleteNOTPROVIDEDTxt, DeleteNOTPROVIDEDDescriptionTxt, "Transformation Type"::"Regular Expression - Replace".AsInteger(),
          'NOTPROVIDED', '', '');
    end;

    procedure IsDataFormatUpdateAllowed(): Boolean
    var
        IsHandled: Boolean;
        DataFormatUpdateAllowed: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDataFormatUpdateAllowed(CurrFieldNo, DataFormatUpdateAllowed, IsHandled);
        if IsHandled then
            exit(DataFormatUpdateAllowed);

        exit(
          "Transformation Type" in ["Transformation Type"::"Date Formatting",
                                    "Transformation Type"::"Date and Time Formatting",
                                    "Transformation Type"::"Decimal Formatting"]);
    end;

    procedure InsertRec(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Option; NewStartPosition: Integer; NewLength: Integer; NewDataFormat: Text[100]; NewDataFormattingCulture: Text[10])
    var
        TransformationRule: Record "Transformation Rule";
    begin
        if TransformationRule.Get(NewCode) then
            exit;

        TransformationRule.CreateRule(
            NewCode, NewDescription, NewTransformationType, NewStartPosition, NewLength, NewDataFormat, NewDataFormattingCulture);
    end;

    procedure CreateRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Option; NewStartPosition: Integer; NewLength: Integer; NewDataFormat: Text[100]; NewDataFormattingCulture: Text[10])
    begin
        Init();
        Validate(Code, NewCode);
        Validate(Description, NewDescription);
        Validate("Transformation Type", NewTransformationType);
        Validate("Start Position", NewStartPosition);
        Validate(Length, NewLength);
        Validate("Data Format", NewDataFormat);
        Validate("Data Formatting Culture", NewDataFormattingCulture);
        Insert(true);
    end;

    procedure InsertFindAndReplaceRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Option; NewFindValue: Text[250]; NewReplaceValue: Text[250]; NextTransformationRule: Code[20])
    var
        TransformationRule: Record "Transformation Rule";
    begin
        if TransformationRule.Get(NewCode) then
            exit;

        TransformationRule.ReplaceRule(NewCode, NewDescription, NewTransformationType, NewFindValue, NewReplaceValue, NextTransformationRule);
    end;

    procedure ReplaceRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Option; NewFindValue: Text[250]; NewReplaceValue: Text[250])
    begin
        Init();
        Validate(Code, NewCode);
        Validate(Description, NewDescription);
        Validate("Transformation Type", NewTransformationType);
        Validate("Find Value", NewFindValue);
        Validate("Replace Value", NewReplaceValue);
        Insert(true);
    end;

    procedure ReplaceRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Option; NewFindValue: Text[250]; NewReplaceValue: Text[250]; NextTransformationRule: Code[20])
    begin
        Init();
        Validate(Code, NewCode);
        Validate(Description, NewDescription);
        Validate("Transformation Type", NewTransformationType);
        Validate("Find Value", NewFindValue);
        Validate("Replace Value", NewReplaceValue);
        Validate("Next Transformation Rule", NextTransformationRule);
        Insert(true);
    end;

    procedure TransformText(OldValue: Text): Text
    var
        TransformationRule: Record "Transformation Rule";
        NewValue: Text;
    begin
        NewValue := OldValue;

        case "Transformation Type" of
            "Transformation Type"::Uppercase:
                NewValue := UpperCase(OldValue);
            "Transformation Type"::Lowercase:
                NewValue := LowerCase(OldValue);
            "Transformation Type"::"Title Case":
                NewValue := TextToTitleCase(OldValue);
            "Transformation Type"::Trim:
                NewValue := DelChr(OldValue, '<>');
            "Transformation Type"::Substring:
                NewValue := Substring(OldValue);
            "Transformation Type"::Replace:
                NewValue := StringReplace(OldValue, "Find Value", "Replace Value");
            "Transformation Type"::"Regular Expression - Replace":
                NewValue := RegularExpressionReplace(OldValue, "Find Value", "Replace Value");
            "Transformation Type"::"Regular Expression - Match":
                NewValue := RegularExpressionMatch(OldValue, "Find Value");
            "Transformation Type"::"Remove Non-Alphanumeric Characters":
                NewValue := RemoveNonAlphaNumericCharacters(OldValue);
            "Transformation Type"::"Date Formatting":
                NewValue := DateFormatting(OldValue);
            "Transformation Type"::"Date and Time Formatting":
                NewValue := DateTimeFormatting(OldValue);
            "Transformation Type"::"Decimal Formatting":
                NewValue := DecimalFormatting(OldValue);
            "Transformation Type"::"Field Lookup":
                NewValue := FieldLookup(OldValue);
            "Transformation Type"::Round:
                NewValue := RoundValue(OldValue);
            "Transformation Type"::"Extract From Date":
                NewValue := ExtractFromDate(OldValue);
            "Transformation Type"::Custom:
                OnTransformation(Code, OldValue, NewValue);
        end;

        if "Next Transformation Rule" <> '' then
            if TransformationRule.Get("Next Transformation Rule") then
                exit(TransformationRule.TransformText(NewValue));

        exit(NewValue);
    end;

    local procedure TextToTitleCase(OldValue: Text): Text
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.GetCultureInfo("Data Formatting Culture");
        exit(CultureInfo.TextInfo.ToTitleCase(OldValue));
    end;

    local procedure StringReplace(StringToReplace: Text; OldValue: Text; NewValue: Text): Text
    var
        DotNet_String: Codeunit DotNet_String;
    begin
        if OldValue = '' then
            exit(StringToReplace);
        DotNet_String.Set(StringToReplace);
        exit(DotNet_String.Replace(OldValue, NewValue));
    end;

    local procedure RegularExpressionReplace(StringToReplace: Text; Pattern: Text; NewValue: Text) Result: Text
    var
        RegexOptions: Record "Regex Options";
        Regex: Codeunit Regex;
    begin
        RegexOptions.IgnoreCase := true;
        Result := Regex.Replace(StringToReplace, Pattern, NewValue, RegexOptions);
    end;

    local procedure RegularExpressionMatch(StringToMatch: Text; Pattern: Text): Text
    var
        Regex: DotNet Regex;
        RegexOptions: DotNet RegexOptions;
        MatchCollection: DotNet MatchCollection;
        Match: DotNet Match;
        Group: DotNet Group;
        Capture: DotNet Capture;
        NewString: Text;
        WholeExpressionGroup: Boolean;
    begin
        NewString := '';

        Regex := Regex.Regex(Pattern, RegexOptions.IgnoreCase);
        MatchCollection := Regex.Matches(StringToMatch);
        if IsNull(MatchCollection) then
            exit(NewString);

        if MatchCollection.Count = 0 then
            exit(NewString);

        WholeExpressionGroup := true;
        foreach Match in MatchCollection do
            foreach Group in Match.Groups do
                if WholeExpressionGroup then
                    WholeExpressionGroup := false
                else
                    foreach Capture in Group.Captures do
                        NewString += Capture.Value;

        exit(NewString);
    end;

    local procedure RemoveNonAlphaNumericCharacters(OldValue: Text): Text
    var
        StringConversionManagement: Codeunit StringConversionManagement;
    begin
        exit(StringConversionManagement.RemoveNonAlphaNumericCharacters(OldValue));
    end;

    local procedure GetDateTime(TextValue: Text; SuppresTimeZone: Boolean): DateTime
    var
        DotNet_DateTime: Codeunit DotNet_DateTime;
        DotNet_CultureInfo: Codeunit DotNet_CultureInfo;
        DotNet_DateTimeStyles: Codeunit DotNet_DateTimeStyles;
        DateTimeValue: DateTime;
    begin
        DateTimeValue := 0DT;

        DotNet_DateTimeStyles.None();

        if "Data Formatting Culture" = '' then begin
            DotNet_CultureInfo.InvariantCulture();
            if not DotNet_DateTime.TryParseExact(
                 TextValue,
                 "Data Format",
                 DotNet_CultureInfo,
                 DotNet_DateTimeStyles)
            then
                exit(DateTimeValue);
        end else begin
            DotNet_CultureInfo.GetCultureInfoByName("Data Formatting Culture");
            if not DotNet_DateTime.TryParse(
                 TextValue,
                 DotNet_CultureInfo,
                 DotNet_DateTimeStyles)
            then
                exit(DateTimeValue);
        end;

        if SuppresTimeZone then
            DateTimeValue := CreateDateTime(DMY2Date(DotNet_DateTime.Day(), DotNet_DateTime.Month(), DotNet_DateTime.Year()), 0T)
        else
            DateTimeValue := DotNet_DateTime.ToDateTime();

        exit(DateTimeValue);
    end;

    local procedure DateTimeFormatting(OldValue: Text): Text
    var
        DateTimeValue: DateTime;
        NewValue: Text;
    begin
        DateTimeValue := GetDateTime(OldValue, false);
        if DateTimeValue <> 0DT then
            NewValue := Format(DateTimeValue, 0, XmlFormat())
        else
            NewValue := OldValue;
        exit(NewValue);
    end;

    local procedure DateFormatting(OldValue: Text): Text
    var
        DateTimeValue: DateTime;
        DateValue: Date;
        NewValue: Text;
    begin
        DateTimeValue := GetDateTime(OldValue, true);
        DateValue := DT2Date(DateTimeValue);
        if DateValue <> 0D then
            NewValue := Format(DateValue, 0, XmlFormat())
        else
            NewValue := OldValue;
        exit(NewValue);
    end;

    local procedure DecimalFormatting(OldValue: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        NewDecimalVariant: Variant;
        NewValue: Text;
        DummyDecimal: Decimal;
    begin
        NewValue := OldValue;
        DummyDecimal := 0;
        NewDecimalVariant := DummyDecimal;
        TypeHelper.Evaluate(NewDecimalVariant, OldValue, '', "Data Formatting Culture");

        NewValue := Format(NewDecimalVariant, 0, XmlFormat());
        exit(NewValue);
    end;

    local procedure FieldLookup(OldValue: Text): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        TestField("Table ID");
        TestField("Source Field ID");
        TestField("Target Field ID");
        RecRef.Open("Table ID");
        FieldRef := RecRef.Field("Source Field ID");
        FieldRef.SetRange(OldValue);
        if RecRef.FindFirst then begin
            FieldRef := RecRef.Field("Target Field ID");
            case "Field Lookup Rule" of
                "Field Lookup Rule"::Target:
                    exit(FieldRef.Value);
                "Field Lookup Rule"::"Original If Target Is Blank":
                    begin
                        if Format(FieldRef.Value) = '' then
                            exit(OldValue);
                        exit(FieldRef.Value);
                    end;
            end;
        end;
    end;

    local procedure RoundValue(OldValue: Text): Text
    var
        DecVar: Decimal;
    begin
        Evaluate(DecVar, OldValue);
        TestField(Precision);
        TestField(Direction);
        exit(Format(Round(DecVar, Precision, Direction)));
    end;

    local procedure ExtractFromDate(OldValue: Text): Text
    var
        DateVar: Date;
    begin
        Evaluate(DateVar, OldValue);
        exit(Format(Date2DMY(DateVar, "Extract From Date Type".AsInteger())));
    end;

    local procedure Substring(OldValue: Text): Text
    var
        StartPosition: Integer;
        NewLength: Integer;
    begin
        StartPosition := SubstringGetStartPosition(OldValue);
        if StartPosition <= 0 then
            exit('');

        NewLength := SubstringGetLength(OldValue, StartPosition);

        if NewLength <= 0 then
            exit('');

        exit(CopyStr(OldValue, StartPosition, NewLength));
    end;

    procedure GetFourthToSixthSubstringCode(): Code[20]
    begin
        exit(FOURTH_TO_SIXTH_CHARTxt);
    end;

    procedure GetUSDateFormatCode(): Code[20]
    begin
        exit(USDATEFORMATTxt);
    end;

    procedure GetUSDateTimeFormatCode(): Code[20]
    begin
        exit(USDATETIMEFORMATTxt);
    end;

    procedure GetUppercaseCode(): Code[20]
    begin
        exit(UPPERCASETxt);
    end;

    procedure GetLowercaseCode(): Code[20]
    begin
        exit(LOWERCASETxt);
    end;

    procedure GetTitlecaseCode(): Code[20]
    begin
        exit(TITLECASETxt);
    end;

    procedure GetTrimCode(): Code[20]
    begin
        exit(TRIMTxt);
    end;

    procedure GetAlphanumericCode(): Code[20]
    begin
        exit(ALPHANUMERIC_ONLYTxt);
    end;

    procedure GetDanishDecimalFormatCode(): Code[20]
    begin
        exit(DKNUMBERFORMATTxt);
    end;

    procedure GetYYYYMMDDCode(): Code[20]
    begin
        exit(YYYYMMDDDateTxt);
    end;

    procedure GetYYYYMMDDHHMMSSCode(): Code[20]
    begin
        exit(YYYYMMDDHHMMSSTxt);
    end;

    procedure GetDeleteNOTPROVIDEDCode(): Code[20]
    begin
        exit(DeleteNOTPROVIDEDTxt);
    end;

    local procedure RemoveLeadingAndEndingQuotes(InputText: Text): Text
    var
        QuotedText: Boolean;
        InputTextLength: Integer;
    begin
        InputTextLength := StrLen(InputText);
        if InputTextLength < 2 then
            exit(InputText);

        QuotedText := (InputText[1] = '''') and (InputText[InputTextLength] = '''');
        if not QuotedText then
            QuotedText := (InputText[1] = '"') and (InputText[InputTextLength] = '"');

        if QuotedText then
            exit(CopyStr(InputText, 2, InputTextLength - 2));

        exit(InputText);
    end;

    local procedure SubstringGetLength(OldValue: Text; StartPosition: Integer): Integer
    var
        SearchableText: Text;
    begin
        if (Length <= 0) and ("Ending Text" = '') then
            exit(StrLen(OldValue) - StartPosition + 1);

        if Length > 0 then
            exit(Length);

        if "Ending Text" <> '' then begin
            SearchableText := CopyStr(OldValue, StartPosition, StrLen(OldValue) - StartPosition + 1);
            exit(StrPos(SearchableText, RemoveLeadingAndEndingQuotes("Ending Text")) - 1);
        end;

        exit(-1);
    end;

    local procedure SubstringGetStartPosition(OldValue: Text): Integer
    var
        StartingText: Text;
        StartIndex: Integer;
    begin
        if ("Start Position" <= 0) and ("Starting Text" = '') then
            exit(1);

        if "Start Position" > 0 then
            exit("Start Position");

        StartingText := RemoveLeadingAndEndingQuotes("Starting Text");
        if StartingText <> '' then begin
            StartIndex := StrPos(OldValue, StartingText);
            if StartIndex > 0 then
                exit(StartIndex + StrLen(StartingText));
        end;

        exit(-1);
    end;

    procedure EditNextTransformationRule()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        if "Next Transformation Rule" = '' then
            exit;

        TransformationRule.Get("Next Transformation Rule");
        PAGE.Run(PAGE::"Transformation Rule Card", TransformationRule);
    end;

    local procedure CheckMandatoryFields()
    begin
        if "Transformation Type" in ["Transformation Type"::Replace,
                                     "Transformation Type"::"Regular Expression - Replace",
                                     "Transformation Type"::"Regular Expression - Match"]
        then
            TestField("Find Value");
    end;

    [IntegrationEvent(false, false)]
    procedure OnTransformation(TransformationCode: Code[20]; InputText: Text; var OutputText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCreateTransformationRules()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeIsDataFormatUpdateAllowed(FieldNumber: Integer; var DataFormatUpdateAllowed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnValidateLengthOnBeforeTestTransformationType(var TransformationRule: Record "Transformation Rule"; xTransformationRule: Record "Transformation Rule"; var IsHandled: Boolean)
    begin
    end;

    local procedure XmlFormat(): Integer
    begin
        exit(9);
    end;
}