Codeunit 1267 "Password Helper"
{
    var
        InsufficientPassLengthErr: Label 'The password must contain at least 8 characters.';
        CharacterSetOption: Option Uppercase,Lowercase,Number,SpecialCharacter;

    procedure GeneratePassword(Length: Integer): Text;
    var
        RNGCryptoServiceProvider: DotNet RNGCryptoServiceProvider;
        DotNetArray: DotNet DotNet_Array;
        DotNetType: DotNet DotNet_Type;
        Result: Text;
        I: Integer;
        Step: Integer;
        CharacterIndex: Integer;
        CharacterModValue: Integer;
        CharacterSet: Integer;
        UpercaseCharacterIncluded: Boolean;
        LowercaseCharacterIncluded: Boolean;
        NumericCharacterIncluded: Boolean;
        SpecialCharacterIncluded: Boolean;
        ByteValue: Byte;
    begin
        if Length < 8 then
            ERROR(InsufficientPassLengthErr);

        Result := '';

        // RNGCryptoServiceProvider ensures randomness of data
        RNGCryptoServiceProvider := RNGCryptoServiceProvider.RNGCryptoServiceProvider();
        DotNetType := DotNetType.GetType('System.Byte', FALSE);
        DotNetArray := DotNetArray.CreateInstance(DotNetType, Length * 2);
        RNGCryptoServiceProvider.GetNonZeroBytes(DotNetArray);

        I := 0;
        Step := 2;
        repeat
            CharacterSet := DotNetArray.GetValue(I);
            CharacterSet := CharacterSet MOD 4;

            // We must ensure we have included all types of character.
            // if we are within the last 4 characters of the string we will check.
            // if we are missing one, use that set instead.
            if STRLEN(Result) >= Length - 4 then begin
                if NOT LowercaseCharacterIncluded then
                    CharacterSet := CharacterSetOption::Lowercase;

                if NOT UpercaseCharacterIncluded then
                    CharacterSet := CharacterSetOption::Uppercase;

                if NOT NumericCharacterIncluded then
                    CharacterSet := CharacterSetOption::Number;

                if NOT SpecialCharacterIncluded then
                    CharacterSet := CharacterSetOption::SpecialCharacter;

                // Write back updated character set
                ByteValue := CharacterSet;
                DotNetArray.SetValue(ByteValue, I);
            end;

            case CharacterSet of
                CharacterSetOption::Lowercase:
                    LowercaseCharacterIncluded := TRUE;
                CharacterSetOption::Uppercase:
                    UpercaseCharacterIncluded := TRUE;
                CharacterSetOption::Number:
                    NumericCharacterIncluded := TRUE;
                CharacterSetOption::SpecialCharacter:
                    SpecialCharacterIncluded := TRUE;
            end;

            CharacterIndex := DotNetArray.GetValue(I + 1);
            CharacterModValue := GetCharacterSetSize(CharacterSet);

            // We must ensure we meet certain complexity requirements used by several online services.
            // if the previous 2 characters are also the same type as this one
            // and the previous 2 characters are sequential from (or the same as) the current value.
            // We will pick the next character instead.
            if STRLEN(Result) >= 2 then
                if IsCharacterSetEqual(CharacterSet, DotNetArray.GetValue(I - Step), DotNetArray.GetValue(I - 2 * Step)) then
                    if IsCharacterValuesEqualOrSequential(
                         CharacterIndex, DotNetArray.GetValue(I - Step + 1), DotNetArray.GetValue(I - 2 * Step + 1), CharacterSet)
                    then begin
                        CharacterIndex := (CharacterIndex + 1) MOD CharacterModValue;

                        // Write back updated character index
                        ByteValue := CharacterIndex;
                        DotNetArray.SetValue(ByteValue, I + 1);
                    end;

            CharacterIndex := CharacterIndex MOD CharacterModValue;

            Result += GetCharacterFromCharacterSet(CharacterSet, CharacterIndex);

            I += Step;
        UNTIL I >= DotNetArray.Length() - 1;

        exit(Result);
    end;

    local procedure GetCharacterSetSize(CharacterSet: Integer): Integer;
    begin
        case CharacterSet OF
            CharacterSetOption::Lowercase:
                exit(STRLEN(GetCharacterPool()));
            CharacterSetOption::Uppercase:
                exit(STRLEN(GetCharacterPool()));
            CharacterSetOption::Number:
                exit(10);
            CharacterSetOption::SpecialCharacter:
                exit(STRLEN(GetSpecialCharacterPool()));
        end;
    end;

    local procedure GetCharacterPool(): Text;
    begin
        exit('ABCDEFGHIJKLNOPQRSTUVWXYZ');
    end;

    local procedure GetSpecialCharacterPool(): Text;
    begin
        exit('!@#$*');
    end;

    local procedure GetCharacterFromCharacterSet(CharacterSet: Integer; CharacterIndex: Integer): Text;
    begin
        case CharacterSet of
            CharacterSetOption::Lowercase:
                exit(LOWERcase(FORMAT(GetCharacterPool() [CharacterIndex + 1])));
            CharacterSetOption::Uppercase:
                exit(UPPERcase(FORMAT(GetCharacterPool() [CharacterIndex + 1])));
            CharacterSetOption::Number:
                exit(FORMAT(CharacterIndex));
            CharacterSetOption::SpecialCharacter:
                exit(FORMAT(GetSpecialCharacterPool() [CharacterIndex + 1]));
        end;
    end;

    local procedure IsCharacterSetEqual(Type1: Integer; Type2: Integer; Type3: Integer): Boolean;
    var
        NumberOfSets: Integer;
    begin
        NumberOfSets := 4;
        Type1 := Type1 mod NumberOfSets;
        Type2 := Type2 mod NumberOfSets;
        Type3 := Type3 mod NumberOfSets;

        if (Type1 = Type2) and (Type1 = Type3) then
            exit(true);

        exit(false);
    end;

    local procedure IsCharacterValuesEqualOrSequential(Character1: Integer; Character2: Integer; Character3: Integer; CharacterSet: Integer): Boolean;
    var
        CharacterModValue: Integer;
    begin
        CharacterModValue := GetCharacterSetSize(CharacterSet);
        Character1 := Character1 mod CharacterModValue;
        Character2 := Character2 mod CharacterModValue;
        Character3 := Character3 mod CharacterModValue;

        // e.g. 'aaa'
        if (Character1 = Character2) and (Character1 = Character3) then
            exit(true);

        // e.g. 'cba'
        if (Character1 = Character2 + 1) and (Character1 = Character3 + 2) then
            exit(true);

        // e.g. 'abc'
        if (Character1 = Character2 - 1) and (Character1 = Character3 - 2) then
            exit(true);

        exit(false);
    end;
}

