codeunit 11500 BankMgt
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Post account numbers must have a dash on the 3rd and the 2nd last position. i.e. 60-8000-7 or 01-20029-2.';
        Text002: Label 'The post account number must have at least 6 digits.';
        Text003: Label 'The check digit of post account %1 must be %2.';
        Text004: Label 'The check digit for %1 cannot be calculated. The source number may only consist of digits.';

    [Scope('OnPrem')]
    procedure CheckPostAccountNo(_InputAcc: Code[15]) _LongAccNo: Code[20]
    var
        TestString: Code[12];
        SourceCheckDigit: Code[1];
        CalculatedCheckDigit: Code[1];
    begin
        // 30-054703-2

        // CHeck dashes, length and check digit
        if _InputAcc = '' then
            exit;

        // Dash at pos 3 and last - 1
        if (CopyStr(_InputAcc, 3, 1) <> '-') or (CopyStr(_InputAcc, StrLen(_InputAcc) - 1, 1) <> '-') then
            Error(Text000);

        // Too short
        if StrLen(_InputAcc) < 6 then
            Error(Text002);

        // Expand input no. to 11 digits  60-9-9 -> 60-000009-9
        _LongAccNo := CopyStr(_InputAcc, 1, 3) + CopyStr('00000000000', 1, 11 - StrLen(_InputAcc)) + CopyStr(_InputAcc, 4);

        // Prepare no. for check: Remove dashes and check digit. Length 11 -> 9
        TestString := DelChr(_LongAccNo, '=', '-');

        // Last digit as check digit
        SourceCheckDigit := CopyStr(TestString, 9, 1);

        TestString := CopyStr(TestString, 1, 8);

        // Verify check digit
        CalculatedCheckDigit := CalcCheckDigit(TestString);

        if CalculatedCheckDigit <> SourceCheckDigit then
            Error(Text003, _InputAcc, CalculatedCheckDigit);
    end;

    [Scope('OnPrem')]
    procedure CalcCheckDigit(_Input: Text[250]) _Output: Code[1]
    var
        Tabl: array[10] of Integer;
        Carry: Integer;
        Maxlength: Integer;
        Pos: Integer;
        Test: Integer;
        i: Integer;
    begin
        // Verify modul 10 rec. check digit and return it
        if DelChr(_Input, '=', '01234567890') <> '' then
            Error(Text004, _Input);

        Tabl[1] := 0;
        Tabl[2] := 9;
        Tabl[3] := 4;
        Tabl[4] := 6;
        Tabl[5] := 8;
        Tabl[6] := 2;
        Tabl[7] := 7;
        Tabl[8] := 1;
        Tabl[9] := 3;
        Tabl[10] := 5;
        Carry := 0;
        Maxlength := StrLen(_Input);
        Pos := 1;

        while Pos < Maxlength + 1 do begin
            Evaluate(Test, CopyStr(_Input, Pos, 1)); // get 1 testnbr from string
            i := Test + Carry; // add carried to testchar
            if i > 9 then
                i := i - 10;
            Carry := Tabl[i + 1]; // get new carry from table
            Pos := Pos + 1; // set pointer to next char
        end;

        if Carry = 0 then
            Carry := 10; // adjust carry if 0

        _Output := Format(10 - Carry); // calc checkdig. from carry
    end;
}

