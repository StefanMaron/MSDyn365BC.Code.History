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

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetBankCode(BankAccountNo: Text[30]): Text[4]
    var
        SlashPosition: Integer;
    begin
        SlashPosition := StrPos(BankAccountNo, '/');
        if SlashPosition <> 0 then
            exit(CopyStr(BankAccountNo, SlashPosition + 1, 4));
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure CheckBankAccountNoCharacters(BankAccountNo: Text[30])
    begin
        if not HasBankAccountNoValidCharacters(BankAccountNo) then
            Error(InvalidCharactersErr, GetInvalidCharactersFromBankAccountNo(BankAccountNo));
    end;

    internal procedure CreateVariableSymbol(DocumentNo: Code[35]) VariableSymbol: Code[10]
    begin
        VariableSymbol :=
            CopyStr(
                DelChr(
                    DelChr(DocumentNo, '=', DelChr(DocumentNo, '=', '0123456789')),
                    '<', '0'),
                1, MaxStrLen(VariableSymbol));
    end;

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

    internal procedure CheckBankAccountNo(BankAccountNo: Text[30]; ShowErrorMessages: Boolean): Boolean
    var
        HasErrors: Boolean;
    begin
        OnBeforeCheckBankAccountNo(BankAccountNo, ShowErrorMessages, HasErrors, TempErrorMessage);
        exit(not HasErrors);
    end;

    internal procedure HasBankAccountNoValidCharacters(BankAccountNo: Text[30]): Boolean
    begin
        exit(GetInvalidCharactersFromBankAccountNo(BankAccountNo) = '');
    end;

    internal procedure GetInvalidCharactersFromBankAccountNo(BankAccountNo: Text[30]): Text
    begin
        exit(DelChr(BankAccountNo, '=', GetValidCharactersForBankAccountNo));
    end;

    internal procedure GetValidCharactersForBankAccountNo(): Text
    begin
        exit('0123456789-/');
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBankAccountNo(BankAccountNo: Text[30]; ShowErrorMessages: Boolean; var HasErrors: Boolean; var TempErrorMessage: Record "Error Message")
    begin
    end;
}
#endif