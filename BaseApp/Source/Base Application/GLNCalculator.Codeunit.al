codeunit 1607 "GLN Calculator"
{

    trigger OnRun()
    begin
    end;

    var
        GLNLengthErr: Label 'The GLN length should be %1 and not %2.';
        GLNCheckDigitErr: Label 'The GLN %1 is not valid.';

    procedure AssertValidCheckDigit13(GLNValue: Code[20])
    begin
        if not IsValidCheckDigit(GLNValue, 13) then
            Error(GLNCheckDigitErr, GLNValue);
    end;

    procedure IsValidCheckDigit13(GLNValue: Code[20]): Boolean
    begin
        exit(IsValidCheckDigit(GLNValue, 13));
    end;

    local procedure IsValidCheckDigit(GLNValue: Code[20]; ExpectedSize: Integer): Boolean
    begin
        if GLNValue = '' then
            exit(false);

        if StrLen(GLNValue) <> ExpectedSize then
            Error(GLNLengthErr, ExpectedSize, StrLen(GLNValue));

        exit(Format(StrCheckSum(CopyStr(GLNValue, 1, ExpectedSize - 1), '131313131313')) = Format(GLNValue[ExpectedSize]));
    end;
}

