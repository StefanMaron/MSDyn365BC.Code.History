codeunit 1251 "Record Match Mgt."
{

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

    procedure CalculateStringNearness(FirstString: Text; SecondString: Text; Threshold: Integer; NormalizingFactor: Integer): Integer
    var
        Result: Text;
        TotalMatchedChars: Integer;
        MinLength: Integer;
        ResultLength: Integer;
    begin
        if (FirstString = '') or (SecondString = '') then
            exit(0);

        FirstString := UpperCase(FirstString);
        SecondString := UpperCase(SecondString);

        MinLength := (StrLen(FirstString) + StrLen(SecondString) - Abs(StrLen(FirstString) - StrLen(SecondString))) / 2;
        if MinLength = 0 then
            MinLength := 1;

        TotalMatchedChars := 0;
        Result := GetLongestCommonSubstring(FirstString, SecondString);
        ResultLength := StrLen(Result);
        while (ResultLength <> 0) and (ResultLength >= Threshold) do begin
            TotalMatchedChars += StrLen(Result);
            FirstString := DelStr(FirstString, StrPos(FirstString, Result), StrLen(Result));
            SecondString := DelStr(SecondString, StrPos(SecondString, Result), StrLen(Result));
            Result := GetLongestCommonSubstring(FirstString, SecondString);
            ResultLength := StrLen(Result);
        end;

        exit(NormalizingFactor * TotalMatchedChars div MinLength);
    end;

    procedure Trim(InputString: Text): Text
    begin
        exit(DelChr(DelChr(InputString, '<'), '>'));
    end;
}

