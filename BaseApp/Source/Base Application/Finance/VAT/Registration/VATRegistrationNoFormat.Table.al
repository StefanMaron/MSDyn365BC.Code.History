﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;

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
        VatLengthErr: Label 'The VAT registration number must be 14 characters long.';
        VatFirstTwoCharsErr: Label 'The first two characters of the VAT registration number must be ''NL''.';
        VatMod11NotAllowedCharErr: Label 'The VAT registration number must have the format NLdddddddddBdd where d is a digit.';
        VatMod97NotAllowedCharErr: Label 'The VAT registration number for a natural person must have the format NLXXXXXXXXXXdd where d is a digit, and x can be a digit, an uppercase letter, ''+'', or ''*''.';
        VatMod11Err: Label 'The VAT registration number is not valid according to the Modulus-11 checksum algorithm.';
        VatMod97Err: Label 'The VAT registration number is not valid according to the Modulus-97 checksum algorithm.';
        SummaryTwoErr: Label '%1%2', Comment = '%1, %2 - error text';
        SummaryThreeErr: Label '%1%2 %3', Comment = '%1, %2, %3 - error text';

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
            if not CompanyInfo.Get() then
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
            Error('%1%2', StrSubstNo(Text000, "Country/Region Code"), StrSubstNo(Text001, TextString));

        case TableID of
            DATABASE::Customer:
                CheckCust(VATRegNo, Number);
            DATABASE::Vendor:
                CheckVendor(VATRegNo, Number);
            DATABASE::Contact:
                CheckContact(VATRegNo, Number);
            DATABASE::"Company Information":
                CheckCompanyInfo(VATRegNo);
            else
                OnTestTable(VATRegNo, CountryCode, Number, TableID);
        end;
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
    procedure CheckCompanyInfo(VATRegNo: Text[20])
    var
        CompanyInformation: Record "Company Information";
        Mod11ErrorText: Text;
        Mod97ErrorText: Text;
        Number: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCompanyInfo(VATRegNo, IsHandled);
        if IsHandled then
            exit;

        if not CompanyInformation.Get() then
            exit;

        if UpperCase(CopyStr(VATRegNo, 1, 2)) <> 'NL' then
            if CompanyInformation."Country/Region Code" <> 'NL' then
                exit  // Not an NL VAT Registration No.
            else
                if not Evaluate(Number, CopyStr(VATRegNo, 1, 2)) then
                    exit; // Not an NL VAT Registration No.

        // last two chars must be digits
        Number := 0;
        if not Evaluate(Number, CopyStr(VATRegNo, StrLen(VATRegNo) - 1)) then
            Error(SummaryTwoErr, Text11400, Text11402);
        if Number = 0 then
            Error(SummaryTwoErr, Text11400, Text11402);

        Mod11ErrorText := ValidateVatMod11Algorithm(VATRegNo);
        Mod97ErrorText := ValidateVatMod97Algorithm(VATRegNo);
        if (Mod11ErrorText <> '') and (Mod97ErrorText <> '') then
            Error(SummaryThreeErr, Text11400, Mod11ErrorText, Mod97ErrorText);
    end;

    local procedure ValidateVatMod11Algorithm(VATRegNo: Text[20]): Text;
    var
        TypeHelper: Codeunit "Type Helper";
        i: Integer;
        Digit: Integer;
        Weight: Integer;
        Total: Integer;
    begin
        if UpperCase(CopyStr(VATRegNo, 1, 2)) = 'NL' then
            VATRegNo := DelStr(VATRegNo, 1, 2);

        if CopyStr(VATRegNo, 1, 3) = '000' then
            exit(Text11401);

        for i := 1 to 8 do begin
            if TypeHelper.IsDigit(VATRegNo[i]) then
                Evaluate(Digit, Format(VATRegNo[i]))
            else
                exit(VatMod11NotAllowedCharErr);
            Weight := 10 - i;
            Total := Total + Digit * Weight;
        end;

        if TypeHelper.IsDigit(VATRegNo[9]) then
            Evaluate(Digit, Format(VATRegNo[9]))
        else
            exit(VatMod11NotAllowedCharErr);
        Total := Total mod 11;

        if Digit <> Total then
            exit(VatMod11Err);
    end;

    local procedure ValidateVatMod97Algorithm(VATRegNo: Text[20]): Text
    var
        TypeHelper: Codeunit "Type Helper";
        VatDigitTextBuilder: TextBuilder;
        VatDigitString: Text;
        CurrChar: Char;
        CurrNumber: Integer;
        Remainder: Integer;
        i: Integer;
    begin
        // Valid from January 1, 2020 for natural persons who are VAT entrepreneurs.
        // Positions 1-2 must be NL, positions 13-14 must be digits. Positions 3-12 can contain digits, uppercase letters, '+' and '*'.
        // Each letter is replaced by two-digit number, where 'A' = 10, 'B' = 11, ..., 'Z' = 35; '+' = 36, '*' = 37.
        // Remainder of division the converted VAT number by 97 must be equal to 1.
        // Example: NL123456789B13 is converted to 2321 123456789 11 13, i.e. to 23211234567891113 integer number. 23211234567891113 mod 97 = 1, it is a valid VAT number.
        if CopyStr(VATRegNo, 1, 2) <> 'NL' then
            exit(VatFirstTwoCharsErr);

        if StrLen(VATRegNo) <> 14 then
            exit(VatLengthErr);

        for i := 1 to StrLen(VATRegNo) do begin
            CurrChar := VATRegNo[i];
            case true of
                TypeHelper.IsDigit(CurrChar):
                    CurrNumber := CurrChar - '0';   // convert char digit to int, '1' -> 1 etc.
                TypeHelper.IsUpper(CurrChar):
                    CurrNumber := CurrChar - 55;    // convert uppercase letter to int, 'A' -> 10 etc.
                CurrChar = '+':
                    CurrNumber := 36;               // special case for '+' and '*'
                CurrChar = '*':
                    CurrNumber := 37;
                else
                    exit(VatMod97NotAllowedCharErr);
            end;
            VatDigitTextBuilder.Append(Format(CurrNumber));
        end;

        // string is used instead of integer to avoid Integer/BigInteger overflow.
        VatDigitString := VatDigitTextBuilder.ToText();
        for i := 1 to StrLen(VatDigitString) do begin
            CurrChar := VatDigitString[i];
            CurrNumber := CurrChar - '0';
            Remainder := (Remainder * 10 + CurrNumber) mod 97;
        end;

        if Remainder <> 1 then
            exit(VatMod97Err);
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

