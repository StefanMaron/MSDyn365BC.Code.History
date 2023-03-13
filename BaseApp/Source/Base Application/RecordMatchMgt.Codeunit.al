codeunit 1251 "Record Match Mgt."
{
    var
        RespectThresholdForNumbers: Boolean;

    trigger OnRun()
    begin
    end;

    procedure GetLongestCommonSubstring(FirstString: Text; SecondString: Text): Text
    var
        Result: Text;
        Buffer: Text;
        i: Integer;
        j: Integer;
    begin
        FirstString := UpperCase(FirstString);
        SecondString := UpperCase(SecondString);
        Result := '';

        i := 1;
        while i + StrLen(Result) - 1 <= StrLen(FirstString) do begin
            j := 1;
            while (j + i - 1 <= StrLen(FirstString)) and (j <= StrLen(SecondString)) do begin
                if StrPos(SecondString, CopyStr(FirstString, i, j)) > 0 then
                    Buffer := CopyStr(FirstString, i, j);

                if StrLen(Buffer) > StrLen(Result) then
                    Result := Buffer;
                Buffer := '';
                j += 1;
            end;
            i += 1;
        end;

        exit(Result);
    end;

    procedure SetRespectThresholdForNumbers(NewValue: Boolean)
    begin
        RespectThresholdForNumbers := NewValue;
    end;

    /// <summary>
    /// Computes a nearness score between strings. Nearness is based on the longest common substrings.
    /// Substring matches below Threshold are not considered unless they are numeric.
    /// Normalizing factor is the max value returned by this procedure.
    /// </summary>
    /// <param name="FirstString">First string to match</param>
    /// <param name="SecondString">Second string to match</param>
    /// <param name="Threshold">Substring matches below Threshold are not considered</param>
    /// <param name="NormalizingFactor">Max value returned by this procedure</param>
    /// <returns>A number between 0 and NormalizingFactor, representing how much of the strings was matched</returns>
    procedure CalculateStringNearness(FirstString: Text; SecondString: Text; Threshold: Integer; NormalizingFactor: Integer): Integer
    var
        Result: Text;
        TotalMatchedChars: Integer;
        MinLength: Integer;
        ShouldContinue: Boolean;
    begin
        if (FirstString = '') or (SecondString = '') then
            exit(0);

        FirstString := UpperCase(FirstString);
        SecondString := UpperCase(SecondString);

        // The max length that can be matched is the length of the shortest string: (this is a Min)
        MinLength := (StrLen(FirstString) + StrLen(SecondString) - Abs(StrLen(FirstString) - StrLen(SecondString))) / 2;
        if MinLength = 0 then
            MinLength := 1;

        TotalMatchedChars := 0;
        Result := GetLongestCommonSubstring(FirstString, SecondString);
        ShouldContinue := IsSubstringConsideredForNearness(Result, Threshold);
        while ShouldContinue do begin
            TotalMatchedChars += StrLen(Result);
            FirstString := DelStr(FirstString, StrPos(FirstString, Result), StrLen(Result));
            SecondString := DelStr(SecondString, StrPos(SecondString, Result), StrLen(Result));
            Result := GetLongestCommonSubstring(FirstString, SecondString);
            ShouldContinue := IsSubstringConsideredForNearness(Result, Threshold);
        end;

        exit(NormalizingFactor * TotalMatchedChars div MinLength);
    end;

    local procedure IsSubstringConsideredForNearness(Substring: Text; Threshold: Integer): Boolean
    var
        Length: Integer;
    begin
        Length := StrLen(Substring);
        if Length <= 1 then
            exit(false);

        if Length >= Threshold then
            exit(true);

        // Matches smaller than threshold are only considered when the values are numeric
        if AllNumeric(Substring) and (not RespectThresholdForNumbers) then
            exit(true);
    end;

    local procedure AllNumeric(String: Text): Boolean
    var
        WithoutNumeric: Text;
    begin
        WithoutNumeric := Text.DelChr(String, '=', '0123456789');
        exit(WithoutNumeric = '');
    end;

    procedure Trim(InputString: Text): Text
    begin
        exit(DelChr(DelChr(InputString, '<'), '>'));
    end;
}

