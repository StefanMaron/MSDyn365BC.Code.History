// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

tableextension 13645 "OIOUBL-Sales&Receivables Setup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(13630; "OIOUBL-Invoice Path"; Text[250])
        {
            Caption = 'Invoice Path';
        }
        field(13631; "OIOUBL-Cr. Memo Path"; Text[250])
        {
            Caption = 'Cr. Memo Path';
        }
        field(13632; "OIOUBL-Reminder Path"; Text[250])
        {
            Caption = 'Reminder Path';
        }
        field(13633; "OIOUBL-Fin. Chrg. Memo Path"; Text[250])
        {
            Caption = 'Fin. Chrg. Memo Path';
        }
        field(13634; "OIOUBL-Default Profile Code"; Code[10])
        {
            Caption = 'Default Profile Code';
            TableRelation = "OIOUBL-Profile";

            trigger OnValidate()
            var
                OIOUBLProfile: Record "OIOUBL-Profile";
            begin
                OIOUBLProfile.UpdateEmptyOIOUBLProfileCodes("OIOUBL-Default Profile Code", xRec."OIOUBL-Default Profile Code");
            end;
        }
        field(13635; "Document No. as Ext. Doc. No."; Boolean)
        {
            Caption = 'Document No. as External Doc. No.';
        }
    }
    keys
    {
    }

#if not CLEAN20
    var
        SetupOIOUBLQst: Label 'OIOUBL path of the OIOMXL file is missing. Do you want to update it now?';
        MissingSetupOIOUBLErr: Label 'OIOUBL path of the OIOMXL file is missing. Please Correct it.';

    local procedure IsOIOUBLPathSetupAvailble("Document Type": Option Quote,Order,Invoice,"Credit Memo","Blanket Order","Return Order","Finance Charge",Reminder): Boolean;
    begin
        if true then
            exit(TRUE);
        case "Document Type" of
            "Document Type"::Order, "Document Type"::Invoice:
                exit("OIOUBL-Invoice Path" <> '');
            "Document Type"::"Return Order", "Document Type"::"Credit Memo":
                exit("OIOUBL-Cr. Memo Path" <> '');
            "Document Type"::"Finance Charge":
                exit("OIOUBL-Fin. Chrg. Memo Path" <> '');
            "Document Type"::Reminder:
                exit("OIOUBL-Reminder Path" <> '');
            else
                exit(TRUE);
        end;
    end;
#endif

#if not CLEAN20
    [Obsolete('Not used.', '20.0')]
    procedure VerifyAndSetOIOUBLSetupPath("Document Type": Option Quote,Order,Invoice,"Credit Memo","Blanket Order","Return Order","Finance Charge",Reminder);
    var
        OIOUBLsetupPage: Page "OIOUBL-setup";
    begin
        GET();
        if IsOIOUBLPathSetupAvailble("Document Type") then
            EXIT;

        if CONFIRM(SetupOIOUBLQst, TRUE) then begin
            OIOUBLsetupPage.SETRECORD(Rec);
            OIOUBLsetupPage.EDITABLE(TRUE);
            if OIOUBLsetupPage.RUNMODAL() = ACTION::OK then
                OIOUBLsetupPage.GETRECORD(Rec);
        end;

        if NOT IsOIOUBLPathSetupAvailble("Document Type") then
            ERROR(MissingSetupOIOUBLErr);
    end;
#endif
}
