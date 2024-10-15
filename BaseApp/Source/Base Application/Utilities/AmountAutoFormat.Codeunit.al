// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

codeunit 347 "Amount Auto Format"
{
    Permissions = tabledata "General Ledger Setup" = r;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        GLSetupRead: Boolean;
        FormatTxt: Label '<Precision,%1><Standard Format,0>', Locked = true;
        CurrFormatTxt: Label '%3%2<Precision,%1><Standard Format,0>', Locked = true;
        EnumType: Enum "Auto Format";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnResolveAutoFormat', '', false, false)]
    local procedure ResolveAutoFormatTranslateCase1(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    begin
        // Amount
        if not Resolved and GetGLSetup() then
            if AutoFormatType = EnumType::AmountFormat then begin
                Result := GetAmountPrecisionFormat(AutoFormatExpr);
                Resolved := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnResolveAutoFormat', '', false, false)]
    local procedure ResolveAutoFormatTranslateCase2(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    begin
        // Unit Amount
        if not Resolved and GetGLSetup() then
            if AutoFormatType = EnumType::UnitAmountFormat then begin
                Result := GetUnitAmountPrecisionFormat(AutoFormatExpr);
                Resolved := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnResolveAutoFormat', '', false, false)]
    local procedure ResolveAutoFormatTranslateCase10(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    begin
        // Custom or AutoFormatExpr = '1[,<curr>[,<PrefixedText>]]' or '2[,<curr>[,<PrefixedText>]]'
        if not Resolved and GetGLSetup() then
            if AutoFormatType = EnumType::CurrencySymbolFormat then begin
                Result := GetCustomFormat(AutoFormatExpr);
                Resolved := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnReadRounding', '', false, false)]
    local procedure ReadRounding(var AmountRoundingPrecision: Decimal)
    begin
        GetGLSetup();
        AmountRoundingPrecision := GLSetup."Amount Rounding Precision";
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ResetGLSetupReadOnGLSetupDelete()
    begin
        GLSetupRead := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterInsertEvent', '', false, false)]
    local procedure ResetGLSetupReadOnGLSetupInsert()
    begin
        GLSetupRead := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure ResetGLSetupReadOnGLSetupModify()
    begin
        GLSetupRead := false;
    end;

    local procedure GetGLSetup(): Boolean
    begin
        if not GLSetupRead then
            GLSetupRead := GLSetup.Get();
        exit(GLSetupRead);
    end;

    local procedure GetAmountPrecisionFormat(AutoFormatExpr: Text[80]): Text[80]
    begin
        if AutoFormatExpr = '' then
            exit(StrSubstNo(FormatTxt, GLSetup."Amount Decimal Places"));
        if GetCurrencyAndAmount(AutoFormatExpr) then
            exit(StrSubstNo(FormatTxt, Currency."Amount Decimal Places"));
        exit(StrSubstNo(FormatTxt, GLSetup."Amount Decimal Places"));
    end;

    local procedure GetUnitAmountPrecisionFormat(AutoFormatExpr: Text[80]): Text[80]
    begin
        if AutoFormatExpr = '' then
            exit(StrSubstNo(FormatTxt, GLSetup."Unit-Amount Decimal Places"));
        if GetCurrencyAndUnitAmount(AutoFormatExpr) then
            exit(StrSubstNo(FormatTxt, Currency."Unit-Amount Decimal Places"));
        exit(StrSubstNo(FormatTxt, GLSetup."Unit-Amount Decimal Places"));
    end;

    local procedure GetCustomFormat(AutoFormatExpr: Text[80]): Text[80]
    var
        FormatSubtype: Text;
        AutoFormatCurrencyCode: Text[80];
        AutoFormatPrefixedText: Text[80];
    begin
        FormatSubtype := SelectStr(1, AutoFormatExpr);
        if FormatSubtype in ['1', '2'] then begin
            GetCurrencyCodeAndPrefixedText(AutoFormatExpr, AutoFormatCurrencyCode, AutoFormatPrefixedText);
            case FormatSubtype of
                '1':
                    exit(GetCustomAmountFormat(AutoFormatCurrencyCode, AutoFormatPrefixedText));
                '2':
                    exit(GetCustomUnitAmountFormat(AutoFormatCurrencyCode, AutoFormatPrefixedText));
            end;
        end else
            exit(AutoFormatExpr);
    end;

    local procedure GetCustomAmountFormat(AutoFormatCurrencyCode: Text[80]; AutoFormatPrefixedText: Text[80]): Text[80]
    begin
        if AutoFormatCurrencyCode = '' then
            exit(StrSubstNo(CurrFormatTxt, GLSetup."Amount Decimal Places", GLSetup.GetCurrencySymbol(), AutoFormatPrefixedText));
        if GetCurrencyAndAmount(AutoFormatCurrencyCode) then
            exit(StrSubstNo(CurrFormatTxt, Currency."Amount Decimal Places", Currency.GetCurrencySymbol(), AutoFormatPrefixedText));
        exit(StrSubstNo(CurrFormatTxt, GLSetup."Amount Decimal Places", GLSetup.GetCurrencySymbol(), AutoFormatPrefixedText));
    end;

    local procedure GetCustomUnitAmountFormat(AutoFormatCurrencyCode: Text[80]; AutoFormatPrefixedText: Text[80]): Text[80]
    begin
        if AutoFormatCurrencyCode = '' then
            exit(StrSubstNo(CurrFormatTxt, GLSetup."Unit-Amount Decimal Places", GLSetup.GetCurrencySymbol(), AutoFormatPrefixedText));
        if GetCurrencyAndUnitAmount(AutoFormatCurrencyCode) then
            exit(StrSubstNo(CurrFormatTxt, Currency."Unit-Amount Decimal Places", Currency.GetCurrencySymbol(), AutoFormatPrefixedText));
        exit(StrSubstNo(CurrFormatTxt, GLSetup."Unit-Amount Decimal Places", GLSetup.GetCurrencySymbol(), AutoFormatPrefixedText));
    end;

    local procedure GetCurrency(CurrencyCode: Code[10]): Boolean
    begin
        if CurrencyCode = Currency.Code then
            exit(true);
        if CurrencyCode = '' then begin
            CLEAR(Currency);
            Currency.InitRoundingPrecision();
            exit(true);
        end;
        exit(Currency.GET(CurrencyCode));
    end;

    local procedure GetCurrencyAndAmount(AutoFormatValue: Text[80]): Boolean
    begin
        if GetCurrency(CopyStr(AutoFormatValue, 1, 10)) and
           (Currency."Amount Decimal Places" <> '')
        then
            exit(true);
        exit(false);
    end;

    local procedure GetCurrencyAndUnitAmount(AutoFormatValue: Text[80]): Boolean
    begin
        if GetCurrency(CopyStr(AutoFormatValue, 1, 10)) and
           (Currency."Unit-Amount Decimal Places" <> '')
        then
            exit(true);
        exit(false);
    end;

    local procedure GetCurrencyCodeAndPrefixedText(AutoFormatExpr: Text[80]; var AutoFormatCurrencyCode: Text; var AutoFormatPrefixedText: Text)
    var
        NumCommasInAutoFormatExpr: Integer;
    begin
        NumCommasInAutoFormatExpr := StrLen(AutoFormatExpr) - StrLen(DelChr(AutoFormatExpr, '=', ','));
        if NumCommasInAutoFormatExpr >= 1 then
            AutoFormatCurrencyCode := SelectStr(2, AutoFormatExpr);
        if NumCommasInAutoFormatExpr >= 2 then
            AutoFormatPrefixedText := SelectStr(3, AutoFormatExpr);
        if AutoFormatPrefixedText <> '' then
            AutoFormatPrefixedText := AutoFormatPrefixedText + ' ';
    end;
}
