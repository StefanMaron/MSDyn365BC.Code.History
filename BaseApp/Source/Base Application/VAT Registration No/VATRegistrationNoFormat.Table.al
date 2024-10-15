table 381 "VAT Registration No. Format"
{
    Caption = 'VAT Registration No. Format';

    fields
    {
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Country/Region";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Format; Text[20])
        {
            Caption = 'Format';
        }
    }

    keys
    {
        key(Key1; "Country/Region Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label 'The entered VAT Registration number is not in agreement with the format specified for Country/Region Code %1.\';
        Text001: Label 'The following formats are acceptable: %1', Comment = '1 - format list';
        Text002: Label 'This VAT registration number has already been entered for the following customers:\ %1';
        Text003: Label 'This VAT registration number has already been entered for the following vendors:\ %1';
        Text004: Label 'This VAT registration number has already been entered for the following contacts:\ %1';
        Text005: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        Text11400: Label 'The entered VAT Registration number is not in agreement with the format specified for electronic tax declaration: ';
        Text11401: Label 'The VAT Registration number should not start with ''''000''''.';
        Text11402: Label 'The last two characters of the VAT Registration number must be digits, but not equal to ''''00''''.';
        Text11403: Label 'The VAT Registration number is not valid according to the Modulus-11 checksum algorithm.';
        InvalidVatNumberErr: Label 'Enter a valid VAT number, for example ''GB123456789''.';

    procedure Test(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option): Boolean
    var
        CompanyInfo: Record "Company Information";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        Check: Boolean;
        Finish: Boolean;
        TextString: Text;
        IsHandled: Boolean;
    begin
        VATRegNo := UpperCase(VATRegNo);
        if VATRegNo = '' then
            exit;

        Check := true;
        IsHandled := false;
        OnBeforeTest(VATRegNo, CountryCode, Number, TableID, Check, IsHandled);
        if IsHandled then
            exit(true);

        if CountryCode = '' then begin
            if not CompanyInfo.Get then
                exit;
            SetRange("Country/Region Code", CompanyInfo."Country/Region Code");
        end else
            SetRange("Country/Region Code", CountryCode);
        SetFilter(Format, '<> %1', '');
        if FindSet then
            repeat
                AppendString(TextString, Finish, Format);
                Check := Compare(VATRegNo, Format);
            until Check or (Next() = 0);

        if not Check then begin
            if EnvInfoProxy.IsInvoicing then
                Error(InvalidVatNumberErr);
            Error(StrSubstNo('%1%2', StrSubstNo(Text000, "Country/Region Code"), StrSubstNo(Text001, TextString)));
        end;

        case TableID of
            DATABASE::Customer:
                if not CheckCust(VATRegNo, Number) then
                    exit(false);
            DATABASE::Vendor:
                if not CheckVendor(VATRegNo, Number) then
                    exit(false);
            DATABASE::Contact:
                if not CheckContact(VATRegNo, Number) then
                    exit(false);
            DATABASE::"Company Information":
                CheckCompanyInfo(VATRegNo);
            else
                OnTestTable(VATRegNo, CountryCode, Number, TableID);
        end;
        exit(true);
    end;

    local procedure CheckCust(VATRegNo: Text[20]; Number: Code[20]): Boolean
    var
        Cust: Record Customer;
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        Check: Boolean;
        Finish: Boolean;
        TextString: Text;
        CustomerIdentification: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCust(VATRegNo, Number, IsHandled);
        if IsHandled then
            exit;

        Check := true;
        TextString := '';
        Cust.SetCurrentKey("VAT Registration No.");
        Cust.SetRange("VAT Registration No.", VATRegNo);
        Cust.SetFilter("No.", '<>%1', Number);
        if Cust.FindSet then begin
            Check := false;
            Finish := false;
            repeat
                if EnvInfoProxy.IsInvoicing then
                    CustomerIdentification := Cust.Name
                else
                    CustomerIdentification := Cust."No.";

                AppendString(TextString, Finish, CustomerIdentification);
            until (Cust.Next() = 0) or Finish;
        end;
        if not Check then begin
            Message(StrSubstNo(Text002, TextString));
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckVendor(VATRegNo: Text[20]; Number: Code[20]): Boolean
    var
        Vend: Record Vendor;
        Check: Boolean;
        Finish: Boolean;
        TextString: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVend(VATRegNo, Number, IsHandled);
        if IsHandled then
            exit;

        Check := true;
        TextString := '';
        Vend.SetCurrentKey("VAT Registration No.");
        Vend.SetRange("VAT Registration No.", VATRegNo);
        Vend.SetFilter("No.", '<>%1', Number);
        if Vend.FindSet then begin
            Check := false;
            Finish := false;
            repeat
                AppendString(TextString, Finish, Vend."No.");
            until (Vend.Next() = 0) or Finish;
        end;
        if not Check then begin
            Message(StrSubstNo(Text003, TextString));
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckContact(VATRegNo: Text[20]; Number: Code[20]): Boolean
    var
        Cont: Record Contact;
        Check: Boolean;
        Finish: Boolean;
        TextString: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContact(VATRegNo, Number, IsHandled);
        if IsHandled then
            exit;

        Check := true;
        TextString := '';
        Cont.SetCurrentKey("VAT Registration No.");
        Cont.SetRange("VAT Registration No.", VATRegNo);
        Cont.SetFilter("No.", '<>%1', Number);
        if Cont.FindSet then begin
            Check := false;
            Finish := false;
            repeat
                AppendString(TextString, Finish, Cont."No.");
            until (Cont.Next() = 0) or Finish;
        end;
        if not Check then begin
            Message(StrSubstNo(Text004, TextString));
            exit(false);
        end;

        exit(true);
    end;

    procedure Compare(VATRegNo: Text[20]; Format: Text[20]): Boolean
    var
        i: Integer;
        Cf: Text[1];
        Ce: Text[1];
        Check: Boolean;
    begin
        Check := true;
        if StrLen(VATRegNo) = StrLen(Format) then
            for i := 1 to StrLen(VATRegNo) do begin
                Cf := CopyStr(Format, i, 1);
                Ce := CopyStr(VATRegNo, i, 1);
                case Cf of
                    '#':
                        if not ((Ce >= '0') and (Ce <= '9')) then
                            Check := false;
                    '@':
                        if StrPos(Text005, UpperCase(Ce)) = 0 then
                            Check := false;
                    else
                        if not ((Cf = Ce) or (Cf = '?')) then
                            Check := false
                end;
            end
        else
            Check := false;
        exit(Check);
    end;

    local procedure AppendString(var String: Text; var Finish: Boolean; AppendText: Text)
    begin
        case true of
            Finish:
                exit;
            String = '':
                String := AppendText;
            StrLen(String) + StrLen(AppendText) + 5 <= 250:
                String += ', ' + AppendText;
            else begin
                    String += '...';
                    Finish := true;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckCompanyInfo(VATRegNo: Text[20])
    var
        CompanyInformation: Record "Company Information";
        i: Integer;
        Digit: Integer;
        Weight: Integer;
        Total: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCompanyInfo(VATRegNo, IsHandled);
        if IsHandled then
            exit;

        if not CompanyInformation.Get then
            exit;

        if UpperCase(CopyStr(VATRegNo, 1, 2)) = 'NL' then
            VATRegNo := DelStr(VATRegNo, 1, 2)
        else
            if CompanyInformation."Country/Region Code" <> 'NL' then
                exit  // Not an NL VAT Registration No.
            else
                if not Evaluate(Digit, CopyStr(VATRegNo, 1, 2)) then
                    exit; // Not an NL VAT Registration No.

        if CopyStr(VATRegNo, 1, 3) = '000' then
            Error(Text11400 + Text11401);

        if CopyStr(VATRegNo, StrLen(VATRegNo) - 1) = '00' then
            Error(Text11400 + Text11402);

        for i := 1 to 8 do begin
            Evaluate(Digit, SYSTEM.Format(VATRegNo[i]));
            Weight := 10 - i;
            Total := Total + Digit * Weight;
        end;

        Evaluate(Digit, SYSTEM.Format(VATRegNo[9]));
        Total := Total mod 11;

        if Digit <> Total then
            Error(Text11400 + Text11403);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCompanyInfo(VATRegNo: Text[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCust(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVend(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContact(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTest(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option; Check: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestTable(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option)
    begin
    end;
}

