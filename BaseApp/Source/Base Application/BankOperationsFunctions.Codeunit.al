#if not CLEAN19
codeunit 11711 "Bank Operations Functions"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        InvalidCharactersErr: Label 'Bank account no. contains invalid characters "%1".', Comment = '%1 = invalid characters';
        BankAccountNoTooLongErr: Label 'Bank account no. is too long.';
        BankAccountNoTooShortErr: Label 'Bank account no. is too short.';
        BankCodeSlashMissingErr: Label 'Bank code must be separated by a slash.';
        BankCodeTooLongErr: Label 'Bank code is too long.';
        BankCodeTooShortErr: Label 'Bank code is too short.';
        PrefixTooLongErr: Label 'Bank account prefix is too long.';
        PrefixIncorrectChecksumErr: Label 'Bank account prefix has incorrect checksum.';
        IdentificationTooLongErr: Label 'Bank account identification is too long.';
        IdentificationTooShortErr: Label 'Bank account identification is too short.';
        IdentificationNonZeroDigitsErr: Label 'Bank account identification must contain at least two non-zero digits.';
        IdentificationIncorrectChecksumErr: Label 'Bank account identification has incorrect checksum.';
        FirstHyphenErr: Label 'Bank account no. must not start with character "-".';

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetBankCode(BankAccountNo: Text[30]): Text[4]
    var
        SlashPosition: Integer;
    begin
        SlashPosition := StrPos(BankAccountNo, '/');
        if SlashPosition <> 0 then
            exit(CopyStr(BankAccountNo, SlashPosition + 1));
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure CheckBankAccountNoCharacters(BankAccountNo: Text[30])
    begin
        if not HasBankAccountNoValidCharacters(BankAccountNo) then
            Error(InvalidCharactersErr, GetInvalidCharactersFromBankAccountNo(BankAccountNo));
    end;

#if not CLEAN18
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure ChopLeftChars(Input: Text[250]; NewChar: Text[1]): Text[250]
    begin
        exit(DelChr(Input, '<', NewChar));
    end;

#endif
#if CLEAN18
    internal procedure CreateVariableSymbol(DocumentNo: Code[35]) VariableSymbol: Code[10]
    begin
        VariableSymbol := DelChr(DocumentNo, '=', DelChr(DocumentNo, '=', '0123456789'));
        VariableSymbol := CopyStr((DelChr(VariableSymbol, '<', '0')), 1, MaxStrLen(VariableSymbol));
    end;
#else
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure CreateVariableSymbol(Input: Code[35]): Code[10]
    begin
        if Input = '' then
            exit('');

        Input := CopyStr(OnlyNumbers(Input), 1, MaxStrLen(Input));
        Input := CopyStr(ChopLeftChars(Input, '0'), 1, MaxStrLen(Input));
        exit(CopyStr(Input, 1, 10));
    end;
#endif

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure IBANBankCode(IBAN: Code[50]): Code[10]
    begin
        case CopyStr(IBAN, 1, 2) of
            'CZ':
                begin
                    if CopyStr(IBAN, 5, 1) = '' then
                        exit(CopyStr(IBAN, 6, 4));
                    exit(CopyStr(IBAN, 5, 4));
                end;
        end;
        exit('');
    end;

#if not CLEAN18
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure OnlyNumbers(Input: Text[250]): Text[250]
    var
        i: Integer;
        Output: Text;
    begin
        for i := 1 to StrLen(Input) do
            if (Input[i] >= '0') and (Input[i] <= '9') then
                Output += Format(Input[i]);
        exit(CopyStr(Output, 1, 250));
    end;

#endif
#if CLEAN18
    internal procedure CheckBankAccountNo(BankAccountNo: Text[30]; ShowErrorMessages: Boolean): Boolean
    var
        HasErrors: Boolean;
    begin
        OnBeforeCheckBankAccountNo(BankAccountNo, ShowErrorMessages, HasErrors, TempErrorMessage);
        exit(not HasErrors);
    end;
#else
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure CheckBankAccountNo(BankAccountNo: Text[30]; ShowErrorMessages: Boolean): Boolean
    var
        HasErrors: Boolean;
    begin
        if BankAccountNo = '' then
            exit(true);

        ClearErrorMessageLog;

        if not HasBankAccountNoValidCharacters(BankAccountNo) then
            LogErrorMessage(StrSubstNo(InvalidCharactersErr, GetInvalidCharactersFromBankAccountNo(BankAccountNo)));

        if StrLen(BankAccountNo) > 22 then
            LogErrorMessage(BankAccountNoTooLongErr);

        if StrLen(BankAccountNo) < 7 then
            LogErrorMessage(BankAccountNoTooShortErr);

        CheckBankCode(BankAccountNo);
        CheckBankAccountIdentification(BankAccountNo);
        CheckBankAccountPrefix(BankAccountNo);

        HasErrors := TempErrorMessage.HasErrors(ShowErrorMessages);
        if ShowErrorMessages then
            TempErrorMessage.ShowErrorMessages(true);

        exit(not HasErrors);
    end;
#endif
#if not CLEAN18

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure CheckBankCode(BankAccountNo: Text[30])
    var
        BankCode: Text;
        SlashPosition: Integer;
    begin
        SlashPosition := StrPos(BankAccountNo, '/');
        if SlashPosition = 0 then begin
            LogErrorMessage(BankCodeSlashMissingErr);
            exit;
        end;

        BankCode := CopyStr(BankAccountNo, SlashPosition + 1);

        if StrLen(BankCode) > 4 then
            LogErrorMessage(BankCodeTooLongErr);

        if StrLen(BankCode) < 4 then
            LogErrorMessage(BankCodeTooShortErr);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure CheckBankAccountIdentification(BankAccountNo: Text[30])
    var
        BankAccountIdentification: Text;
        SlashPosition: Integer;
        HyphenPosition: Integer;
    begin
        SlashPosition := StrPos(BankAccountNo, '/');
        HyphenPosition := StrPos(BankAccountNo, '-');

        if SlashPosition = 0 then
            SlashPosition := StrLen(BankAccountNo) + 1;

        BankAccountIdentification := CopyStr(BankAccountNo, 1, SlashPosition - 1);
        BankAccountIdentification := CopyStr(BankAccountIdentification, HyphenPosition + 1);

        if StrLen(BankAccountIdentification) > 10 then
            LogErrorMessage(IdentificationTooLongErr);

        if StrLen(BankAccountIdentification) < 2 then
            LogErrorMessage(IdentificationTooShortErr);

        if not CheckModulo(BankAccountIdentification) then
            LogErrorMessage(IdentificationIncorrectChecksumErr);

        if DelChr(BankAccountIdentification, '=', '0') = '' then
            LogErrorMessage(IdentificationNonZeroDigitsErr);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure CheckBankAccountPrefix(BankAccountNo: Text[30])
    var
        BankAccountPrefix: Text;
        HyphenPosition: Integer;
    begin
        HyphenPosition := StrPos(BankAccountNo, '-');
        if HyphenPosition = 0 then
            exit;

        BankAccountPrefix := CopyStr(BankAccountNo, 1, HyphenPosition - 1);

        if StrLen(BankAccountPrefix) = 0 then
            LogErrorMessage(FirstHyphenErr);

        if StrLen(BankAccountPrefix) > 6 then
            LogErrorMessage(PrefixTooLongErr);

        if not CheckModulo(BankAccountPrefix) then
            LogErrorMessage(PrefixIncorrectChecksumErr);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure LogErrorMessage(NewDescription: Text)
    begin
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, NewDescription);
    end;

    [Scope('OnPrem')]
    procedure CopyErrorMessageToTemp(var TempErrorMessage2: Record "Error Message" temporary)
    begin
        TempErrorMessage.CopyToTemp(TempErrorMessage2);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure ClearErrorMessageLog()
    begin
        TempErrorMessage.ClearLog;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure CheckModulo(Input: Text): Boolean
    begin
        exit(Modulo(Input) = 0);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure Modulo(Input: Text): Integer
    var
        OutputSum: Integer;
    begin
        while StrLen(Input) < 10 do
            Input := '0' + Input;

        OutputSum :=
          (Input[1] - '0') * 6 +
          (Input[2] - '0') * 3 +
          (Input[3] - '0') * 7 +
          (Input[4] - '0') * 9 +
          (Input[5] - '0') * 10 +
          (Input[6] - '0') * 5 +
          (Input[7] - '0') * 8 +
          (Input[8] - '0') * 4 +
          (Input[9] - '0') * 2 +
          (Input[10] - '0') * 1;

        exit(OutputSum mod 11);
    end;

#endif
#if CLEAN18
    internal procedure HasBankAccountNoValidCharacters(BankAccountNo: Text[30]): Boolean
    begin
        exit(GetInvalidCharactersFromBankAccountNo(BankAccountNo) = '');
    end;

    internal procedure GetInvalidCharactersFromBankAccountNo(BankAccountNo: Text[30]): Text
    begin
        exit(DelChr(BankAccountNo, '=', GetValidCharactersForBankAccountNo));
    end;

#else
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure HasBankAccountNoValidCharacters(BankAccountNo: Text[30]): Boolean
    begin
        exit(GetInvalidCharactersFromBankAccountNo(BankAccountNo) = '');
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure GetInvalidCharactersFromBankAccountNo(BankAccountNo: Text[30]): Text
    begin
        exit(DelChr(BankAccountNo, '=', GetValidCharactersForBankAccountNo));
    end;

#endif
#if CLEAN18
    internal procedure GetValidCharactersForBankAccountNo(): Text
    begin
        exit('0123456789-/');
    end;
#else
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure GetValidCharactersForBankAccountNo(): Text
    begin
        exit('0123456789-/');
    end;

#endif
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetValidCharactersForVariableSymbol(): Text
    begin
        exit('0123456789');
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetValidCharactersForConstantSymbol(): Text
    begin
        exit('0123456789');
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetValidCharactersForSpecificSymbol(): Text
    begin
        exit('0123456789');
    end;
#if CLEAN18

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBankAccountNo(BankAccountNo: Text[30]; ShowErrorMessages: Boolean; var HasErrors: Boolean; var TempErrorMessage: Record "Error Message")
    begin
    end;
#endif
}
#endif