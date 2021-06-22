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
        field(3; "Transformation Type"; Option)
        {
            Caption = 'Transformation Type';
            OptionCaption = 'Uppercase,Lowercase,Title Case,Trim,Substring,Replace,Regular Expression - Replace,Remove Non-Alphanumeric Characters,Date Formatting,Decimal Formatting,Regular Expression - Match,Custom,Date and Time Formatting';
            OptionMembers = Uppercase,Lowercase,"Title Case",Trim,Substring,Replace,"Regular Expression - Replace","Remove Non-Alphanumeric Characters","Date Formatting","Decimal Formatting","Regular Expression - Match",Custom,"Date and Time Formatting";

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
                if not IsDataFormatUpdateAllowed then begin
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
            begin
                if "Transformation Type" = "Transformation Type"::Substring then
                    if Length < 0 then
                        Error(MustBeGreaterThanZeroErr);

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
                if not IsDataFormatUpdateAllowed then
                    TestField("Data Format", '');
            end;
        }
        field(20; "Data Formatting Culture"; Text[10])
        {
            Caption = 'Data Formatting Culture';

            trigger OnValidate()
            begin
                if not IsDataFormatUpdateAllowed then
                    TestField("Data Formatting Culture", '');
            end;
        }
        field(30; "Next Transformation Rule"; Code[20])
        {
            Caption = 'Next Transformation Rule';
            TableRelation = "Transformation Rule".Code;
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
        CheckMandatoryFields;
    end;

    trigger OnModify()
    begin
        CheckMandatoryFields;
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
        InsertRec(UPPERCASETxt, UpperCaseDescTxt, "Transformation Type"::Uppercase, 0, 0, '', '');
        InsertRec(LOWERCASETxt, LowerCaseDescTxt, "Transformation Type"::Lowercase, 0, 0, '', '');
        InsertRec(TITLECASETxt, TitleCaseDescTxt, "Transformation Type"::"Title Case", 0, 0, '', '');
        InsertRec(TRIMTxt, TrimDescTxt, "Transformation Type"::Trim, 0, 0, '', '');
        InsertRec(FOURTH_TO_SIXTH_CHARTxt, FourthToSixthCharactersDescTxt, "Transformation Type"::Substring, 4, 3, '', '');
        InsertRec(YYYYMMDDDateTxt, YYYYMMDDDateDescTxt, "Transformation Type"::"Date Formatting", 0, 0, 'yyyyMMdd', '');
        InsertRec(YYYYMMDDHHMMSSTxt, YYYYMMDDHHMMSSDescTxt, "Transformation Type"::"Date and Time Formatting", 0, 0, 'yyyyMMddHHmmss', '');
        InsertRec(ALPHANUMERIC_ONLYTxt, AlphaNumericDescTxt, "Transformation Type"::"Remove Non-Alphanumeric Characters", 0, 0, '', '');
        InsertRec(DKNUMBERFORMATTxt, DKNUMBERFORMATDescTxt, "Transformation Type"::"Decimal Formatting", 0, 0, '', 'da-DK');
        InsertRec(USDATEFORMATTxt, USDATEFORMATDescTxt, "Transformation Type"::"Date Formatting", 0, 0, '', 'en-US');
        InsertRec(USDATETIMEFORMATTxt, USDATETIMEFORMATDescTxt, "Transformation Type"::"Date and Time Formatting", 0, 0, '', 'en-US');
        OnCreateTransformationRules;
        InsertFindAndReplaceRule(
          DeleteNOTPROVIDEDTxt, DeleteNOTPROVIDEDDescriptionTxt, "Transformation Type"::"Regular Expression - Replace", 'NOTPROVIDED', '');
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
        with TransformationRule do begin
            Init;
            Validate(Code, NewCode);
            Validate(Description, NewDescription);
            Validate("Transformation Type", NewTransformationType);
            Validate("Start Position", NewStartPosition);
            Validate(Length, NewLength);
            Validate("Data Format", NewDataFormat);
            Validate("Data Formatting Culture", NewDataFormattingCulture);
            if Insert(true) then;
        end;
    end;

    local procedure InsertFindAndReplaceRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Option; NewFindValue: Text[250]; NewReplaceValue: Text[250])
    var
        TransformationRule: Record "Transformation Rule";
    begin
        with TransformationRule do begin
            Init;
            Validate(Code, NewCode);
            Validate(Description, NewDescription);
            Validate("Transformation Type", NewTransformationType);
            Validate("Find Value", NewFindValue);
            Validate("Replace Value", NewReplaceValue);
            if Insert(true) then;
        end;
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
        DotNet_Regex: Codeunit DotNet_Regex;
    begin
        DotNet_Regex.RegexIgnoreCase(Pattern);
        Result := DotNet_Regex.Replace(StringToReplace, NewValue);
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
            foreach Group in Match.Groups do begin
                if WholeExpressionGroup then
                    WholeExpressionGroup := false
                else
                    foreach Capture in Group.Captures do
                        NewString += Capture.Value;
            end;

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
        DotNetDateTime: DotNet DateTime;
        CultureInfo: DotNet CultureInfo;
        DotNetDateTimeStyles: DotNet DateTimeStyles;
        DateTimeValue: DateTime;
    begin
        DateTimeValue := 0DT;
        DotNetDateTime := DotNetDateTime.DateTime(1);

        DotNetDateTimeStyles := DotNetDateTimeStyles.None;

        if "Data Formatting Culture" = '' then begin
            CultureInfo := CultureInfo.InvariantCulture;
            if not DotNetDateTime.TryParseExact(
                 TextValue,
                 "Data Format",
                 CultureInfo,
                 DotNetDateTimeStyles,
                 DotNetDateTime)
            then
                exit(DateTimeValue);
        end else begin
            CultureInfo := CultureInfo.GetCultureInfo("Data Formatting Culture");
            if not DotNetDateTime.TryParse(
                 TextValue,
                 CultureInfo,
                 DotNetDateTimeStyles,
                 DotNetDateTime)
            then
                exit(DateTimeValue);
        end;

        if SuppresTimeZone then
            DateTimeValue := CreateDateTime(DMY2Date(DotNetDateTime.Day, DotNetDateTime.Month, DotNetDateTime.Year), 0T)
        else
            DateTimeValue := DotNetDateTime;

        exit(DateTimeValue);
    end;

    local procedure DateTimeFormatting(OldValue: Text): Text
    var
        DateTimeValue: DateTime;
        NewValue: Text;
    begin
        DateTimeValue := GetDateTime(OldValue, false);
        if DateTimeValue <> 0DT then
            NewValue := Format(DateTimeValue, 0, XmlFormat)
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
            NewValue := Format(DateValue, 0, XmlFormat)
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
        NewDecimalVariant := DummyDecimal;
        TypeHelper.Evaluate(NewDecimalVariant, OldValue, '', "Data Formatting Culture");

        NewValue := Format(NewDecimalVariant, 0, XmlFormat);
        exit(NewValue);
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDataFormatUpdateAllowed(FieldNumber: Integer; var DataFormatUpdateAllowed: Boolean; var IsHandled: Boolean)
    begin
    end;

    local procedure XmlFormat(): Integer
    begin
        exit(9);
    end;
}

