codeunit 10610 "E-Invoice Document Encode"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        WrongLengthErr: Label 'should be %1 characters long';
        CompanyInfoRead: Boolean;
        GLSetupRead: Boolean;

    [Scope('OnPrem')]
    procedure DateToText(VarDate: Date): Text[20]
    begin
        if VarDate = 0D then
            exit('1753-01-01');
        exit(Format(VarDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    [Scope('OnPrem')]
    procedure BooleanToText(VarBoolean: Boolean): Text[5]
    begin
        case VarBoolean of
            true:
                exit('true');
            false:
                exit('false');
        end;
    end;

    [Scope('OnPrem')]
    procedure DecimalToText(VarDecimal: Decimal): Text[30]
    begin
        exit(Format(VarDecimal, 0, '<Precision,2:2><Sign><Integer><Decimals><Comma,.>'));
    end;

    [Scope('OnPrem')]
    procedure DecimalExtToText(VarDecimal: Decimal): Text[30]
    begin
        exit(Format(VarDecimal, 0, '<Precision,2:5><Sign><Integer><Decimals><Comma,.>'));
    end;

    [Scope('OnPrem')]
    procedure IntegerToText(VarInteger: Integer): Text[250]
    begin
        exit(Format(VarInteger, 0, '<Sign><Integer,2><Filler Character,0>'));
    end;

    [Scope('OnPrem')]
    procedure IsValidEANNo(EAN: Code[13]; AllowEmpty: Boolean): Boolean
    begin
        case true of
            EAN = '':
                exit(AllowEmpty);
            StrLen(EAN) <> 13:
                exit(false);
            Format(StrCheckSum(CopyStr(EAN, 1, 12), '131313131313')) <> Format(EAN[13]):
                exit(false);
            else
                exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckCurrencyCode(CurrencyCode: Code[10]): Boolean
    begin
        exit(StrLen(CurrencyCode) = 3);
    end;

    [Scope('OnPrem')]
    procedure DecimalToPromille(Decimal: Decimal): Text[4]
    begin
        exit(Format(Abs(Decimal * 10), 0, '<Integer,4><Filler Character,0>'));
    end;

    [Scope('OnPrem')]
    procedure GetEInvoiceCountryRegionCode(CountryRegionCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegionCode = '' then begin
            ReadCompanyInfo;
            CompanyInfo.TestField("Country/Region Code");
            CountryRegionCode := CompanyInfo."Country/Region Code";
        end;

        CountryRegion.Get(CountryRegionCode);
        if StrLen(CountryRegion.Code) <> 2 then
            CountryRegion.FieldError(Code, StrSubstNo(WrongLengthErr, 2));
        exit(CountryRegion.Code);
    end;

    [Scope('OnPrem')]
    procedure GetEInvoiceCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then begin
            ReadGLSetup;
            GLSetup.TestField("LCY Code");
            CurrencyCode := GLSetup."LCY Code";
        end;

        if not Currency.Get(CurrencyCode) then begin
            if StrLen(CurrencyCode) <> 3 then
                GLSetup.FieldError("LCY Code", StrSubstNo(WrongLengthErr, 3));
            exit(CurrencyCode);
        end;

        if StrLen(Currency.Code) <> 3 then
            Currency.FieldError(Code, StrSubstNo(WrongLengthErr, 3));
        exit(Currency.Code);
    end;

    [Scope('OnPrem')]
    procedure ReadCompanyInfo()
    begin
        if not CompanyInfoRead then begin
            CompanyInfo.Get();
            CompanyInfoRead := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetBBANNo(BBANNo: Text[50]): Text[50]
    begin
        if BBANNo = '' then
            exit('');

        BBANNo := DelChr(BBANNo, '=', DelChr(BBANNo, '=', '0123456789'));

        exit(BBANNo);
    end;

    [Scope('OnPrem')]
    procedure GetVATRegNo(VATRegNo: Text[20]; PartyTaxScheme: Boolean): Text[30]
    begin
        if VATRegNo = '' then
            exit('');

        VATRegNo := DelChr(VATRegNo, '=', DelChr(VATRegNo, '=', '0123456789'));
        if PartyTaxScheme then
            VATRegNo += 'MVA';

        exit(VATRegNo);
    end;
}

