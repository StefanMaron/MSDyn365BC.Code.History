// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using System.Text;

codeunit 341 "VAT CaptionClass Mgmt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ExclVATTxt: Label 'Excl. VAT';
        InclVATTxt: Label 'Incl. VAT';
        VATECPercTxt: Label 'VAT+EC %', Comment = 'EC stands for Equivalence Charge';
        VATECBaseTxt: Label 'VAT+EC Base', Comment = 'EC stands for Equivalence Charge';
        AmountInclVATECTxt: Label 'Amount Including VAT+EC', Comment = 'EC stands for Equivalence Charge';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure ResolveCaptionClass(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea = '2' then
            Caption := VATCaptionClassTranslate(CaptionArea, CaptionExpr, Language, Resolved);
    end;

    local procedure VATCaptionClassTranslate(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Resolved: Boolean): Text
    var
        VATCaptionType: Text;
        VATCaptionRef: Text;
        CommaPosition: Integer;
        Caption: Text;
    begin
        OnBeforeVATCaptionClassTranslate(CaptionArea, CaptionExpr, Language, Caption, Resolved);
        if Resolved then
            exit(Caption);

        // VATCAPTIONTYPE
        // <DataType>   := [SubString]
        // <Length>     =  1
        // <DataValue>  :=
        // '0' -> <field caption + 'Excl. VAT'>
        // '1' -> <field caption + 'Incl. VAT'>
        // '2' -> <'VAT+EC %'>
        // '3' -> <'VAT+EC Base'>
        // '4' -> <'Amount Including VAT+EC'>

        CommaPosition := StrPos(CaptionExpr, ',');
        if CommaPosition > 0 then begin
            Resolved := true;
            VATCaptionType := CopyStr(CaptionExpr, 1, CommaPosition - 1);
            VATCaptionRef := CopyStr(CaptionExpr, CommaPosition + 1);
            case VATCaptionType of
                '0':
                    exit(StrSubstNo('%1 %2', VATCaptionRef, ExclVATTxt));
                '1':
                    exit(StrSubstNo('%1 %2', VATCaptionRef, InclVATTxt));
                '2':
                    exit(VATECPercTxt);
                '3':
                    exit(VATECBaseTxt);
                '4':
                    exit(AmountInclVATECTxt);
            end;
        end;
        Resolved := false;
        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATCaptionClassTranslate(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var IsHandled: Boolean)
    begin
    end;
}

