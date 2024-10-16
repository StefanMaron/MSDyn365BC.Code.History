// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Foundation.Address;

table 226 "VAT Reg. No. Srv. Template"
{
    Caption = 'VAT Reg. No. Validation Template';
    LookupPageId = "VAT Reg. No. Srv. Templates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(11; "Account Type"; Enum "VAT Reg. No. Srv. Template Account Type")
        {
            Caption = 'Account Type';
        }
        field(12; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(20; "Validate Name"; Boolean)
        {
            Caption = 'Validate Name';
        }
        field(21; "Validate Street"; Boolean)
        {
            Caption = 'Validate Street';
        }
        field(22; "Validate City"; Boolean)
        {
            Caption = 'Validate City';
        }
        field(23; "Validate Post Code"; Boolean)
        {
            Caption = 'Validate Post Code';
        }
        field(24; "Ignore Details"; Boolean)
        {
            Caption = 'Ignore Details';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    var
        DefaultTxt: Label 'Default';

    procedure FindTemplate(VATRegistrationLog: Record "VAT Registration Log") Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindTemplate(VATRegistrationLog, IsHandled, Result, Rec);
        if IsHandled then
            exit(Result);

        SetRange("Country/Region Code", VATRegistrationLog."Country/Region Code");
        SetRange("Account Type", MapVATRegLogAccountType(VATRegistrationLog."Account Type"));
        SetRange("Account No.", VATRegistrationLog."Account No.");
        if FindFirst() then
            exit(Code);

        SetRange("Account No.", '');
        if FindFirst() then
            exit(Code);

        SetRange("Account Type", "Account Type"::None);
        if FindFirst() then
            exit(Code);

        exit(LoadDefaultTempalte());
    end;

    local procedure LoadDefaultTempalte(): Code[20]
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.Get();
        CheckInitDefaultTemplate(VATRegNoSrvConfig);
        VATRegNoSrvConfig.TestField("Default Template Code");
        Get(VATRegNoSrvConfig."Default Template Code");
        exit(Code);
    end;

    procedure CheckInitDefaultTemplate(var VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config")
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
    begin
        if (VATRegNoSrvConfig."Default Template Code" = '') and (VATRegNoSrvTemplate.Count() = 0) then begin
            VATRegNoSrvTemplate.Init();
            VATRegNoSrvTemplate.Code := DefaultTxt;
            if VATRegNoSrvTemplate.Insert() then;

            VATRegNoSrvConfig."Default Template Code" := VATRegNoSrvTemplate.Code;
            VATRegNoSrvConfig.Modify();
        end;
    end;

    local procedure MapVATRegLogAccountType(VATRegLogAccountType: Enum "VAT Registration Log Account Type"): Enum "VAT Reg. No. Srv. Template Account Type"
    var
        DummyVATRegistrationLog: Record "VAT Registration Log";
    begin
        case VATRegLogAccountType of
            DummyVATRegistrationLog."Account Type"::Customer:
                exit("Account Type"::Customer);
            DummyVATRegistrationLog."Account Type"::Vendor:
                exit("Account Type"::Vendor);
            DummyVATRegistrationLog."Account Type"::Contact:
                exit("Account Type"::Contact);
            else
                exit("Account Type"::None);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindTemplate(VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean; var Result: Code[20]; var VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template")
    begin
    end;
}
