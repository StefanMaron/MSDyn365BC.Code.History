codeunit 10 "Type Helper"
{

    trigger OnRun()
    begin
    end;

    var
        UnsupportedTypeErr: Label 'The Type is not supported by the Evaluate function.';
        KeyDoesNotExistErr: Label 'The requested key does not exist.';
        InvalidMonthErr: Label 'An invalid month was specified.';
        StringTooLongErr: Label 'This function only allows strings of length up to %1.', Comment = '%1=a number, e.g. 1024';
        UnsupportedNegativesErr: Label 'Negative parameters are not supported by bitwise function %1.', Comment = '%1=function name';
        BitwiseAndTxt: Label 'BitwiseAnd', Locked = true;
        BitwiseOrTxt: Label 'BitwiseOr', Locked = true;
        BitwiseXorTxt: Label 'BitwiseXor', Locked = true;
        ObsoleteFieldErr: Label 'The field %1 of %2 table is obsolete and cannot be used.', Comment = '%1 - field name, %2 - table name';

    procedure Evaluate(var Variable: Variant; String: Text; Format: Text; CultureName: Text): Boolean
    begin
        // Variable is return type containing the string value
        // String is input to evaluate
        // Format is in format "MM/dd/yyyy" only supported on date, search MSDN for more details ("CultureInfo.Name Property")
        // CultureName is in format "en-US", search MSDN for more details ("Custom Date and Time Format Strings")
        case true of
            Variable.IsDate:
                exit(TryEvaluateDate(String, Format, CultureName, Variable));
            Variable.IsDateTime:
                exit(TryEvaluateDateTime(String, Format, CultureName, Variable));
            Variable.IsDecimal:
                exit(TryEvaluateDecimal(String, CultureName, Variable));
            Variable.IsInteger:
                exit(TryEvaluateInteger(String, CultureName, Variable));
            else
                Error(UnsupportedTypeErr);
        end;
    end;

    local procedure TryEvaluateDate(DateText: Text; Format: Text; CultureName: Text; var EvaluatedDate: Date): Boolean
    var
        DotNet_CultureInfo: Codeunit DotNet_CultureInfo;
        DotNet_DateTime: Codeunit DotNet_DateTime;
        DotNet_DateTimeStyles: Codeunit DotNet_DateTimeStyles;
        DotNet_XMLConvert: Codeunit DotNet_XMLConvert;
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
    begin
        if (Format = '') and (CultureName = '') then begin
            DotNet_XMLConvert.ToDateTimeOffset(DateText, DotNet_DateTimeOffset);
            DotNet_DateTimeOffset.DateTime(DotNet_DateTime);
        end else begin
            DotNet_CultureInfo.GetCultureInfoByName(CultureName);
            DotNet_DateTimeStyles.None;
            case Format of
                '':
                    if not DotNet_DateTime.TryParse(DateText, DotNet_CultureInfo, DotNet_DateTimeStyles) then
                        exit(false);
                else
                    if not DotNet_DateTime.TryParseExact(DateText, Format, DotNet_CultureInfo, DotNet_DateTimeStyles) then
                        exit(false);
            end;
        end;

        EvaluatedDate := DMY2Date(DotNet_DateTime.Day, DotNet_DateTime.Month, DotNet_DateTime.Year);
        exit(true);
    end;

    local procedure TryEvaluateDateTime(DateTimeText: Text; Format: Text; CultureName: Text; var EvaluatedDateTime: DateTime): Boolean
    var
        DotNet_CultureInfo: Codeunit DotNet_CultureInfo;
        DotNet_DateTime: Codeunit DotNet_DateTime;
        DotNet_DateTimeStyles: Codeunit DotNet_DateTimeStyles;
        EvaluatedTime: Time;
    begin
        if CultureName = '' then
            DotNet_CultureInfo.InvariantCulture
        else
            DotNet_CultureInfo.GetCultureInfoByName(CultureName);
        DotNet_DateTimeStyles.None;
        case Format of
            '':
                if not DotNet_DateTime.TryParse(DateTimeText, DotNet_CultureInfo, DotNet_DateTimeStyles) then
                    exit(false);
            else
                if not DotNet_DateTime.TryParseExact(DateTimeText, Format, DotNet_CultureInfo, DotNet_DateTimeStyles) then
                    exit(false);
        end;

        if not SYSTEM.Evaluate(
             EvaluatedTime,
             StrSubstNo(
               '%1:%2:%3.%4',
               DotNet_DateTime.Hour,
               DotNet_DateTime.Minute,
               DotNet_DateTime.Second,
               DotNet_DateTime.Millisecond))
        then
            exit(false);
        EvaluatedDateTime :=
          CreateDateTime(
            DMY2Date(DotNet_DateTime.Day, DotNet_DateTime.Month, DotNet_DateTime.Year), EvaluatedTime);
        exit(true);
    end;

    local procedure TryEvaluateDecimal(DecimalText: Text; CultureName: Text; var EvaluatedDecimal: Decimal): Boolean
    var
        CultureInfo: DotNet CultureInfo;
        DotNetDecimal: DotNet Decimal;
        NumberStyles: DotNet NumberStyles;
    begin
        EvaluatedDecimal := 0;
        if DotNetDecimal.TryParse(DecimalText, NumberStyles.Number, CultureInfo.GetCultureInfo(CultureName), EvaluatedDecimal) then
            exit(true);
        exit(false)
    end;

    local procedure TryEvaluateInteger(IntegerText: Text; CultureName: Text; var EvaluatedInteger: Integer): Boolean
    var
        CultureInfo: DotNet CultureInfo;
        DotNetInteger: DotNet Int32;
        NumberStyles: DotNet NumberStyles;
    begin
        EvaluatedInteger := 0;
        if DotNetInteger.TryParse(IntegerText, NumberStyles.Number, CultureInfo.GetCultureInfo(CultureName), EvaluatedInteger) then
            exit(true);
        exit(false)
    end;

    procedure GetLocalizedMonthToInt(Month: Text): Integer
    var
        TestMonth: Text;
        Result: Integer;
    begin
        Month := LowerCase(Month);

        for Result := 1 to 12 do begin
            TestMonth := LowerCase(Format(CalcDate(StrSubstNo('<CY+%1M>', Result)), 0, '<Month Text>'));
            if Month = TestMonth then
                exit(Result);
        end;

        Error(InvalidMonthErr);
    end;

    procedure CompareDateTime(DateTimeA: DateTime; DateTimeB: DateTime): Integer
    begin
        // Compares the specified DateTime values for equality within a small threshold.
        // Returns 1 if DateTimeA > DateTimeB, -1 if DateTimeB > DateTimeA, and 0 if they
        // are equal.

        // The threshold must be used to compensate for the varying levels of precision
        // when storing DateTime values. An example of this is the T-SQL datetime type,
        // which has a precision that goes down to the nearest 0, 3, or 7 milliseconds.

        case true of
            DateTimeA = DateTimeB:
                exit(0);
            DateTimeA = 0DT:
                exit(-1);
            DateTimeB = 0DT:
                exit(1);
            Abs(DateTimeA - DateTimeB) < 10:
                exit(0);
            DateTimeA > DateTimeB:
                exit(1);
            else
                exit(-1);
        end;
    end;

    procedure FormatDate(DateToFormat: Date; LanguageId: Integer): Text
    var
        DotNet_CultureInfo: Codeunit DotNet_CultureInfo;
        DotNet_DateTimeFormatInfo: Codeunit DotNet_DateTimeFormatInfo;
        DotNet_DateTime: Codeunit DotNet_DateTime;
    begin
        DotNet_CultureInfo.GetCultureInfoById(LanguageId);
        DotNet_CultureInfo.DateTimeFormat(DotNet_DateTimeFormatInfo);
        DotNet_DateTime.DateTime(Date2DMY(DateToFormat, 3), Date2DMY(DateToFormat, 2), Date2DMY(DateToFormat, 1));
        exit(DotNet_DateTime.ToString(DotNet_DateTimeFormatInfo));
    end;

    procedure FormatDateWithCurrentCulture(DateToFormat: Date): Text
    var
        DotNet_CultureInfo: Codeunit DotNet_CultureInfo;
        DotNet_DateTimeFormatInfo: Codeunit DotNet_DateTimeFormatInfo;
        DotNet_DateTime: Codeunit DotNet_DateTime;
    begin
        DotNet_CultureInfo.GetCultureInfoByName(GetCultureName);
        DotNet_CultureInfo.DateTimeFormat(DotNet_DateTimeFormatInfo);
        DotNet_DateTime.DateTime(Date2DMY(DateToFormat, 3), Date2DMY(DateToFormat, 2), Date2DMY(DateToFormat, 1));
        exit(DotNet_DateTime.ToString(DotNet_DateTimeFormatInfo));
    end;

    procedure GetHMSFromTime(var Hour: Integer; var Minute: Integer; var Second: Integer; TimeSource: Time)
    var
        Milliseconds: Integer;
    begin
        Milliseconds := TimeSource - 000000T;
        Hour := Milliseconds div 1000 div 60 div 60;

        Milliseconds -= (Hour * 1000 * 60 * 60);
        Minute := Milliseconds div 1000 div 60;

        Milliseconds -= (Minute * 1000 * 60);
        Second := Milliseconds div 1000;
    end;

    procedure IsLeapYear(Date: Date): Boolean
    var
        DateTime: DotNet DateTime;
    begin
        exit(DateTime.IsLeapYear(Date2DMY(Date, 3)));
    end;

    procedure LanguageIDToCultureName(LanguageID: Integer): Text
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.GetCultureInfo(LanguageID);
        exit(CultureInfo.Name);
    end;

    procedure GetCultureName(): Text
    var
        CultureInfo: DotNet CultureInfo;
    begin
        exit(CultureInfo.CurrentCulture.Name);
    end;

    procedure GetOptionNo(Value: Text; OptionString: Text): Integer
    var
        OptionNo: Integer;
        OptionsQty: Integer;
    begin
        Value := UpperCase(Value);
        OptionString := UpperCase(OptionString);

        if (Value = '') and (StrPos(OptionString, ' ') = 1) then
            exit(0);
        if (Value <> '') and (StrPos(OptionString, Value) = 0) then
            exit(-1);

        OptionsQty := GetNumberOfOptions(OptionString);
        if OptionsQty > 0 then begin
            for OptionNo := 0 to OptionsQty - 1 do begin
                if OptionsAreEqual(Value, CopyStr(OptionString, 1, StrPos(OptionString, ',') - 1)) then
                    exit(OptionNo);
                OptionString := DelStr(OptionString, 1, StrPos(OptionString, ','));
            end;
            OptionNo += 1;
        end;

        if OptionsAreEqual(Value, OptionString) then
            exit(OptionNo);

        exit(-1);
    end;

    procedure GetOptionNoFromTableField(Value: Text; TableNo: Integer; FieldNo: Integer): Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        exit(GetOptionNo(Value, FieldRef.OptionCaption));
    end;

    procedure GetNumberOfOptions(OptionString: Text): Integer
    begin
        exit(StrLen(OptionString) - StrLen(DelChr(OptionString, '=', ',')));
    end;

    procedure OptionsAreEqual(Value: Text; CurrentOption: Text): Boolean
    begin
        exit(((Value <> '') and (Value = CurrentOption)) or ((Value = '') and (CurrentOption = ' ')));
    end;

    procedure IsNumeric(Text: Text): Boolean
    var
        Decimal: Decimal;
    begin
        exit(SYSTEM.Evaluate(Decimal, Text));
    end;

    procedure GetField(TableNo: Integer; FieldNo: Integer; var "Field": Record "Field"): Boolean
    begin
        exit(Field.Get(TableNo, FieldNo) and (Field.ObsoleteState <> Field.ObsoleteState::Removed));
    end;

    procedure GetFieldLength(TableNo: Integer; FieldNo: Integer): Integer
    var
        "Field": Record "Field";
    begin
        if GetField(TableNo, FieldNo, Field) then
            exit(Field.Len);

        exit(0);
    end;

    procedure TestFieldIsNotObsolete("Field": Record "Field")
    begin
        if Field.ObsoleteState = Field.ObsoleteState::Removed then
            Error(ObsoleteFieldErr, Field."Field Caption", Field.TableName);
    end;

    procedure IsPhoneNumber(Input: Text): Boolean
    var
        DotNet_Regex: Codeunit DotNet_Regex;
    begin
        DotNet_Regex.Regex('^[\(\)\-\+0-9 ]*$');
        exit(DotNet_Regex.IsMatch(Input));
    end;

    [TryFunction]
    procedure GetUserTimezoneOffset(var Duration: Duration)
    var
        UserPersonalization: Record "User Personalization";
        TimeZoneInfo: DotNet TimeZoneInfo;
        TimeZone: Text;
    begin
        UserPersonalization.Get(UserSecurityId);
        TimeZone := UserPersonalization."Time Zone";
        TimeZoneInfo := TimeZoneInfo.FindSystemTimeZoneById(TimeZone);

        Duration := TimeZoneInfo.BaseUtcOffset;
    end;

    procedure GetUserClientTypeOffset(var Duration: Duration)
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        Duration := 0;
        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Web then
            GetUserTimezoneOffset(Duration);
    end;

    procedure GetTimezoneOffset(var Duration: Duration; TimeZoneID: Text)
    var
        TimeZoneInfo: DotNet TimeZoneInfo;
    begin
        if TimeZoneID = '' then
            Duration := 0;
        TimeZoneInfo := TimeZoneInfo.FindSystemTimeZoneById(TimeZoneID);
        Duration := TimeZoneInfo.BaseUtcOffset;
    end;

    procedure EvaluateUnixTimestamp(Timestamp: BigInteger): DateTime
    var
        ResultDateTime: DateTime;
        EpochDateTime: DateTime;
        TimezoneOffset: Duration;
        TimestampInMilliseconds: BigInteger;
    begin
        if not GetUserTimezoneOffset(TimezoneOffset) then
            TimezoneOffset := 0;

        EpochDateTime := CreateDateTime(DMY2Date(1, 1, 1970), 0T);

        TimestampInMilliseconds := Timestamp * 1000;

        ResultDateTime := EpochDateTime + TimestampInMilliseconds + TimezoneOffset;

        exit(ResultDateTime);
    end;

    procedure EvaluateUTCDateTime(DateTimeText: Text) EvaluatedDateTime: DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
    begin
        Value := EvaluatedDateTime;
        if TypeHelper.Evaluate(Value, DateTimeText, 'R', '') then
            EvaluatedDateTime := Value;
    end;

    procedure FormatDateTime(FormattingDateTime: DateTime; Format: Text; CultureName: Text): Text
    var
        CultureInfo: DotNet CultureInfo;
        DateTimeOffset: DotNet DateTimeOffset;
    begin
        if CultureName = '' then
            CultureInfo := CultureInfo.InvariantCulture
        else
            CultureInfo := CultureInfo.GetCultureInfo(CultureName);

        DateTimeOffset := DateTimeOffset.DateTimeOffset(FormattingDateTime);
        DateTimeOffset := DateTimeOffset.ToLocalTime;

        exit(DateTimeOffset.ToString(Format, CultureInfo));
    end;

    procedure FormatUtcDateTime(DateTime: DateTime; DataFormat: Text; DataFormattingCulture: Text) String: Text
    var
        CultureInfo: DotNet CultureInfo;
        DotNetString: DotNet String;
    begin
        if DataFormattingCulture = '' then
            CultureInfo := CultureInfo.CurrentCulture
        else
            CultureInfo := CultureInfo.CultureInfo(DataFormattingCulture);

        String := DotNetString.Format(CultureInfo, '{0:' + DataFormat + '}', DateTime);
    end;

    procedure GetCurrUTCDateTime(): DateTime
    var
        DotNetDateTime: DotNet DateTime;
    begin
        DotNetDateTime := DotNetDateTime.UtcNow;
        exit(DotNetDateTime)
    end;

    procedure GetCurrUTCDateTimeAsText(): Text
    begin
        exit(FormatDateTime(GetCurrUTCDateTime, 'R', ''));
    end;

    procedure AddHoursToDateTime(SourceDateTime: DateTime; NoOfHours: Integer): DateTime
    var
        MillisecondsToAdd: BigInteger;
    begin
        MillisecondsToAdd := NoOfHours * 3600000; // 60 * 60 * 1000
        exit(SourceDateTime + MillisecondsToAdd);
    end;

    procedure FormatDecimal(Decimal: Decimal; DataFormat: Text; DataFormattingCulture: Text) String: Text
    var
        CultureInfo: DotNet CultureInfo;
        DotNetString: DotNet String;
    begin
        if DataFormattingCulture = '' then
            CultureInfo := CultureInfo.CurrentCulture
        else
            CultureInfo := CultureInfo.CultureInfo(DataFormattingCulture);

        String := DotNetString.Format(CultureInfo, '{0:' + DataFormat + '}', Decimal);
    end;

    procedure UrlEncode(var Value: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        Value := HttpUtility.UrlEncode(Value);
        exit(Value);
    end;

    procedure UrlDecode(var Value: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        Value := HttpUtility.UrlDecode(Value);
        exit(Value);
    end;

    procedure HtmlEncode(var Value: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        Value := HttpUtility.HtmlEncode(Value);
        exit(Value);
    end;

    procedure HtmlDecode(var Value: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        Value := HttpUtility.HtmlDecode(Value);
        exit(Value);
    end;

    procedure UriEscapeDataString(Value: Text): Text
    var
        Uri: DotNet Uri;
    begin
        exit(Uri.EscapeDataString(Value));
    end;

    procedure UriGetAuthority(Value: Text): Text
    var
        Uri: DotNet Uri;
        UriPartial: DotNet UriPartial;
    begin
        Uri := Uri.Uri(Value);
        exit(Uri.GetLeftPart(UriPartial.Authority));
    end;

    procedure GetKeyAsString(RecordVariant: Variant; KeyIndex: Integer): Text
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        SelectedKeyRef: KeyRef;
        KeyFieldRef: FieldRef;
        I: Integer;
        KeyString: Text;
        Separator: Text;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecRef);

        if RecRef.KeyCount < KeyIndex then
            Error(KeyDoesNotExistErr);

        SelectedKeyRef := RecRef.KeyIndex(KeyIndex);

        for I := 1 to SelectedKeyRef.FieldCount do begin
            KeyFieldRef := SelectedKeyRef.FieldIndex(I);
            KeyString += Separator + KeyFieldRef.Name;
            Separator := ',';
        end;

        exit(KeyString);
    end;

    procedure ReadAsTextWithSeparator(InStream: InStream; LineSeparator: Text) Content: Text
    var
        ContentLine: Text;
    begin
        InStream.ReadText(Content);
        while not InStream.EOS do begin
            InStream.ReadText(ContentLine);
            Content += LineSeparator + ContentLine;
        end;
    end;

    procedure CRLFSeparator(): Text[2]
    var
        CRLF: Text[2];
    begin
        CRLF[1] := 13; // Carriage return, '\r'
        CRLF[2] := 10; // Line feed, '\n'
        exit(CRLF);
    end;

    procedure LFSeparator(): Text[1]
    var
        LF: Text[1];
    begin
        LF[1] := 10; // Line feed, '\n'
        exit(LF);
    end;

    procedure SortRecordRef(var RecRef: RecordRef; CommaSeparatedFieldsToSort: Text; "Ascending": Boolean)
    var
        OrderString: Text;
    begin
        if Ascending then
            OrderString := 'ORDER(Ascending)'
        else
            OrderString := 'ORDER(Descending)';

        RecRef.SetView(StrSubstNo('SORTING(%1) %2', CommaSeparatedFieldsToSort, OrderString));
        if RecRef.FindSet then;
    end;

    procedure TextDistance(Text1: Text; Text2: Text): Integer
    var
        Array1: array[1026] of Integer;
        Array2: array[1026] of Integer;
        i: Integer;
        j: Integer;
        Cost: Integer;
        MaxLen: Integer;
    begin
        // Returns the number of edits to get from Text1 to Text2
        // Reference: https://en.wikipedia.org/wiki/Levenshtein_distance
        if (StrLen(Text1) + 2 > ArrayLen(Array1)) or (StrLen(Text2) + 2 > ArrayLen(Array1)) then
            Error(StringTooLongErr, ArrayLen(Array1) - 2);
        if Text1 = Text2 then
            exit(0);
        if Text1 = '' then
            exit(StrLen(Text2));
        if Text2 = '' then
            exit(StrLen(Text1));

        if StrLen(Text1) >= StrLen(Text2) then
            MaxLen := StrLen(Text1)
        else
            MaxLen := StrLen(Text2);

        for i := 0 to MaxLen + 1 do
            Array1[i + 1] := i;

        for i := 0 to StrLen(Text1) - 1 do begin
            Array2[1] := i + 1;
            for j := 0 to StrLen(Text2) - 1 do begin
                if Text1[i + 1] = Text2[j + 1] then
                    Cost := 0
                else
                    Cost := 1;
                Array2[j + 2] := MinimumInt3(Array2[j + 1] + 1, Array1[j + 2] + 1, Array1[j + 1] + Cost);
            end;
            for j := 1 to MaxLen + 2 do
                Array1[j] := Array2[j];
        end;
        exit(Array2[StrLen(Text2) + 1]);
    end;

    procedure NewLine(): Text
    var
        Environment: DotNet Environment;
    begin
        exit(Environment.NewLine);
    end;

    local procedure MinimumInt3(i1: Integer; i2: Integer; i3: Integer): Integer
    begin
        if (i1 <= i2) and (i1 <= i3) then
            exit(i1);
        if (i2 <= i1) and (i2 <= i3) then
            exit(i2);
        exit(i3);
    end;

    procedure GetGuidAsString(GuidValue: Guid): Text[36]
    begin
        // Converts guid to string
        // Example: Converts {21EC2020-3AEA-4069-A2DD-08002B30309D} to 21ec2020-3aea-4069-a2dd-08002b30309d
        exit(LowerCase(CopyStr(Format(GuidValue), 2, 36)));
    end;

    procedure GetMaxNumberOfParametersInSQLQuery(): Integer
    begin
        exit(2100);
    end;

    procedure BitwiseAnd(A: Integer; B: Integer): Integer
    var
        Result: Integer;
        BitMask: Integer;
        BitIndex: Integer;
        MaxBitIndex: Integer;
    begin
        if (A < 0) or (B < 0) then
            Error(UnsupportedNegativesErr, BitwiseAndTxt);
        BitMask := 1;
        Result := 0;
        MaxBitIndex := 31; // 1st bit is ignored as it is always equals to 0 for positive Int32 numbers
        for BitIndex := 1 to MaxBitIndex do begin
            if ((A mod 2) = 1) and ((B mod 2) = 1) then
                Result += BitMask;
            A := A div 2;
            B := B div 2;
            if BitIndex < MaxBitIndex then
                BitMask += BitMask;
        end;
        exit(Result);
    end;

    procedure BitwiseOr(A: Integer; B: Integer): Integer
    var
        Result: Integer;
        BitMask: Integer;
        BitIndex: Integer;
        MaxBitIndex: Integer;
    begin
        if (A < 0) or (B < 0) then
            Error(UnsupportedNegativesErr, BitwiseOrTxt);
        BitMask := 1;
        Result := 0;
        MaxBitIndex := 31; // 1st bit is ignored as it is always equals to 0 for positive Int32 numbers
        for BitIndex := 1 to MaxBitIndex do begin
            if ((A mod 2) = 1) or ((B mod 2) = 1) then
                Result += BitMask;
            A := A div 2;
            B := B div 2;
            if BitIndex < MaxBitIndex then
                BitMask += BitMask;
        end;
        exit(Result);
    end;

    procedure BitwiseXor(A: Integer; B: Integer): Integer
    var
        Result: Integer;
        BitMask: Integer;
        BitIndex: Integer;
        MaxBitIndex: Integer;
    begin
        if (A < 0) or (B < 0) then
            Error(UnsupportedNegativesErr, BitwiseXorTxt);
        BitMask := 1;
        Result := 0;
        MaxBitIndex := 31; // 1st bit is ignored as it is always equals to 0 for positive Int32 numbers
        for BitIndex := 1 to MaxBitIndex do begin
            if (A mod 2) <> (B mod 2) then
                Result += BitMask;
            A := A div 2;
            B := B div 2;
            if BitIndex < MaxBitIndex then
                BitMask += BitMask;
        end;
        exit(Result);
    end;

    procedure GetFormattedCurrentDateTimeInUserTimeZone(StringFormat: Text): Text
    var
        DateTime: DotNet DateTime;
        TimezoneOffset: Duration;
    begin
        if not GetUserTimezoneOffset(TimezoneOffset) then
            TimezoneOffset := 0;
        DateTime := DateTime.Now;
        DateTime := DateTime.ToUniversalTime + TimezoneOffset;
        exit(DateTime.ToString(StringFormat));
    end;

    procedure GetCurrentDateTimeInUserTimeZone() Result: DateTime
    var
        DateTime: DotNet DateTime;
        TimezoneOffset: Duration;
    begin
        if not GetUserTimezoneOffset(TimezoneOffset) then
            TimezoneOffset := 0;
        DateTime := DateTime.Now;
        DateTime := DateTime.ToUniversalTime + TimezoneOffset;
        System.Evaluate(Result, DateTime.ToString);
        exit(Result);
    end;

    procedure ConvertDateTimeFromUTCToTimeZone(InputDateTime: DateTime; TimeZoneTxt: Text): DateTime
    var
        TimeZoneInfo: DotNet TimeZoneInfo;
        Offset: Duration;
    begin
        if TimeZoneTxt = '' then
            exit(InputDateTime);

        GetUserClientTypeOffset(Offset);
        InputDateTime := InputDateTime - Offset;

        TimeZoneInfo := TimeZoneInfo.FindSystemTimeZoneById(TimeZoneTxt);
        exit(TimeZoneInfo.ConvertTimeFromUtc(InputDateTime, TimeZoneInfo));
    end;

    procedure IntToHex(IntValue: Integer): Text
    var
        DotNetIntPtr: DotNet IntPtr;
    begin
        DotNetIntPtr := DotNetIntPtr.IntPtr(IntValue);
        exit(DotNetIntPtr.ToString('X'));
    end;

    procedure Maximum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 > Value2 then
            exit(Value1);
        exit(Value2);
    end;

    procedure Minimum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 < Value2 then
            exit(Value1);
        exit(Value2);
    end;

    procedure TransferFieldsWithValidate(var TempFieldBuffer: Record "Field Buffer" temporary; RecordVariant: Variant; var TargetTableRecRef: RecordRef)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, SourceRecRef);

        TempFieldBuffer.Reset();
        if not TempFieldBuffer.FindFirst then
            exit;

        repeat
            if TargetTableRecRef.FieldExist(TempFieldBuffer."Field ID") then begin
                SourceFieldRef := SourceRecRef.Field(TempFieldBuffer."Field ID");
                TargetFieldRef := TargetTableRecRef.Field(TempFieldBuffer."Field ID");
                if TargetFieldRef.Class = FieldClass::Normal then
                    if TargetFieldRef.Value <> SourceFieldRef.Value then
                        TargetFieldRef.Validate(SourceFieldRef.Value);
            end;
        until TempFieldBuffer.Next = 0;
    end;

    procedure CalculateLog(Number: Decimal): Decimal
    var
        Math: DotNet Math;
    begin
        exit(Math.Log10(Number));
    end;

    procedure GetAmountFormatLCYWithUserLocale(): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencySymbol: Text[10];
    begin
        GeneralLedgerSetup.Get();
        CurrencySymbol := GeneralLedgerSetup.GetCurrencySymbol;

        exit(GetAmountFormatWithUserLocale(CurrencySymbol));
    end;

    procedure GetAmountFormatWithUserLocale(CurrencySymbol: Text[10]): Text
    var
        UserPersonalization: Record "User Personalization";
    begin
        if not UserPersonalization.Get(UserSecurityId) then
            exit('<Precision,0:0><Standard Format,0>');

        exit(GetAmountFormat(UserPersonalization."Locale ID", CurrencySymbol));
    end;

    procedure GetAmountFormat(LocaleId: Integer; CurrencySymbol: Text[10]): Text
    var
        CurrencyPositivePattern: Integer;
    begin
        // set position of cyrrency symbol based on the locale
        if not GetCurrencyStyle(LocaleId, CurrencyPositivePattern) then
            exit('<Precision,0:0><Standard Format,0>');

        case CurrencyPositivePattern of
            0: // $n
                exit(CurrencySymbol + '<Precision,0:0><Standard Format,0>');
            1: // n$
                exit('<Precision,0:0><Standard Format,0>' + CurrencySymbol);
            2: // $ n
                exit(CurrencySymbol + ' <Precision,0:0><Standard Format,0>');
            3: // n $
                exit('<Precision,0:0><Standard Format,0> ' + CurrencySymbol);
            else
                exit('<Precision,0:0><Standard Format,0>');
        end
    end;

    procedure GetXMLAmountFormatWithTwoDecimalPlaces(): Text
    begin
        exit('<Precision,2:2><Standard Format,9>');
    end;

    procedure GetXMLDateFormat(): Text
    begin
        exit('<Standard Format,9>');
    end;

    [TryFunction]
    local procedure GetCurrencyStyle(LocaleId: Integer; var CurrencyPositivePattern: Integer)
    var
        CultureInfo: DotNet CultureInfo;
        NumberFormat: DotNet NumberFormatInfo;
    begin
        CultureInfo := CultureInfo.GetCultureInfo(LocaleId);
        NumberFormat := CultureInfo.NumberFormat;
        CurrencyPositivePattern := NumberFormat.CurrencyPositivePattern;
    end;
}

