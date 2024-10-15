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
        LocalVATRegNoCheckSumErr: Label 'The entered VAT registration number is incorrect (checksum error).';

    procedure Test(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option): Boolean
    var
        CompanyInfo: Record "Company Information";
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
        if FindSet() then
            repeat
                AppendString(TextString, Finish, Format);
                Check := Compare(VATRegNo, Format);
            until Check or (Next() = 0);

        if not Check then
            Error(StrSubstNo('%1%2', StrSubstNo(Text000, "Country/Region Code"), StrSubstNo(Text001, TextString)));

        case TableID of
            DATABASE::Customer:
                CheckCust(VATRegNo, Number);
            DATABASE::Vendor:
                CheckVendor(VATRegNo, Number);
            DATABASE::Contact:
                CheckContact(VATRegNo, Number);
            else
                OnTestTable(VATRegNo, CountryCode, Number, TableID);
        end;

        if CountryCode = '' then
            if CompanyInfo."Country/Region Code" = 'RU' then
                TestLocalVATRegNo(VATRegNo);
        exit(true);
    end;

    local procedure CheckCust(VATRegNo: Text[20]; Number: Code[20])
    var
        Cust: Record Customer;
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
        OnCheckCustOnBeforeCustFindSet(Cust);
        if Cust.FindSet() then begin
            Check := false;
            Finish := false;
            repeat
                CustomerIdentification := Cust."No.";
                AppendString(TextString, Finish, CustomerIdentification);
            until (Cust.Next() = 0) or Finish;
        end;
        OnCheckCustOnBeforeCheck(VATRegNo, Number, TextString, Check);
        if not Check then
            ShowCheckCustMessage(TextString);
    end;

    local procedure ShowCheckCustMessage(TextString: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCheckCustMessage(TextString, IsHandled);
        if IsHandled then
            exit;

        Message(StrSubstNo(Text002, TextString));
    end;

    local procedure CheckVendor(VATRegNo: Text[20]; Number: Code[20])
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
        OnCheckVendOnBeforeVendFindSet(Vend);
        if Vend.FindSet() then begin
            Check := false;
            Finish := false;
            repeat
                AppendString(TextString, Finish, Vend."No.");
            until (Vend.Next() = 0) or Finish;
        end;
        OnCheckVendorOnBeforeCheck(VATRegNo, Number, TextString, Check);
        if not Check then
            ShowCheckVendMessage(TextString);
    end;

    local procedure ShowCheckVendMessage(TextString: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCheckVendMessage(TextString, IsHandled);
        if IsHandled then
            exit;

        Message(StrSubstNo(Text003, TextString));
    end;

    local procedure CheckContact(VATRegNo: Text[20]; Number: Code[20])
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
        if Cont.FindSet() then begin
            Check := false;
            Finish := false;
            repeat
                AppendString(TextString, Finish, Cont."No.");
            until (Cont.Next() = 0) or Finish;
        end;
        OnCheckContactOnBeforeCheck(VATRegNo, Number, TextString, Check);
        if not Check then
            Message(StrSubstNo(Text004, TextString));
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
    procedure TestLocalVATRegNo(var VATRegistrationNo: Text[12])
    var
        VATMultiplier: array[3, 11] of Integer;
        VATRegistNo: array[12] of Integer;
        I: Integer;
        TotalAmount: Integer;
        CheckAmount: Integer;
    begin
        if (StrLen(VATRegistrationNo) <> 10) and (StrLen(VATRegistrationNo) <> 12) then
            Error(Text001);

        Clear(VATRegistNo);

        // 10-digit TIN
        VATMultiplier[1, 1] := 2;
        VATMultiplier[1, 2] := 4;
        VATMultiplier[1, 3] := 10;
        VATMultiplier[1, 4] := 3;
        VATMultiplier[1, 5] := 5;
        VATMultiplier[1, 6] := 9;
        VATMultiplier[1, 7] := 4;
        VATMultiplier[1, 8] := 6;
        VATMultiplier[1, 9] := 8;

        // 12-digit TIN - 1 digit
        VATMultiplier[2, 1] := 7;
        VATMultiplier[2, 2] := 2;
        VATMultiplier[2, 3] := 4;
        VATMultiplier[2, 4] := 10;
        VATMultiplier[2, 5] := 3;
        VATMultiplier[2, 6] := 5;
        VATMultiplier[2, 7] := 9;
        VATMultiplier[2, 8] := 4;
        VATMultiplier[2, 9] := 6;
        VATMultiplier[2, 10] := 8;

        // 12-digit TIN - 2 digit
        VATMultiplier[3, 1] := 3;
        VATMultiplier[3, 2] := 7;
        VATMultiplier[3, 3] := 2;
        VATMultiplier[3, 4] := 4;
        VATMultiplier[3, 5] := 10;
        VATMultiplier[3, 6] := 3;
        VATMultiplier[3, 7] := 5;
        VATMultiplier[3, 8] := 9;
        VATMultiplier[3, 9] := 4;
        VATMultiplier[3, 10] := 6;
        VATMultiplier[3, 11] := 8;

        TotalAmount := 0;
        CheckAmount := 0;
        if StrLen(VATRegistrationNo) = 10 then begin
            for I := 1 to 10 do begin
                Evaluate(VATRegistNo[I], CopyStr(VATRegistrationNo, I, 1));
            end;

            for I := 1 to 9 do begin
                TotalAmount := TotalAmount + VATRegistNo[I] * VATMultiplier[1, I];
            end;

            CheckAmount := TotalAmount mod 11;
            CheckAmount := CheckAmount mod 10;

            if CheckAmount <> VATRegistNo[10] then
                Error(LocalVATRegNoCheckSumErr);
        end;

        TotalAmount := 0;
        CheckAmount := 0;
        if StrLen(VATRegistrationNo) = 12 then begin
            for I := 1 to 12 do begin
                Evaluate(VATRegistNo[I], CopyStr(VATRegistrationNo, I, 1));
            end;

            for I := 1 to 10 do begin
                TotalAmount := TotalAmount + VATRegistNo[I] * VATMultiplier[2, I];
            end;

            CheckAmount := TotalAmount mod 11;
            CheckAmount := CheckAmount mod 10;

            if CheckAmount <> VATRegistNo[11] then
                Error(LocalVATRegNoCheckSumErr);
        end;

        CheckAmount := 0;
        TotalAmount := 0;
        if StrLen(VATRegistrationNo) = 12 then begin
            for I := 1 to 11 do begin
                TotalAmount := TotalAmount + VATRegistNo[I] * VATMultiplier[3, I];
            end;

            CheckAmount := TotalAmount mod 11;
            CheckAmount := CheckAmount mod 10;

            if CheckAmount <> VATRegistNo[12] then
                Error(LocalVATRegNoCheckSumErr);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCust(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCheckCustMessage(TextString: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCheckVendMessage(TextString: Text; var IsHandled: Boolean)
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
    local procedure OnCheckContactOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustOnBeforeCustFindSet(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckVendOnBeforeVendFindSet(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckVendorOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestTable(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option)
    begin
    end;
}

