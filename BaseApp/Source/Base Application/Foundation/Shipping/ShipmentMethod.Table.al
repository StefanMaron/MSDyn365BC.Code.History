// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Shipping;

using Microsoft.Integration.Dataverse;

table 10 "Shipment Method"
{
    Caption = 'Shipment Method';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Shipment Methods";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            begin
                if ValidateShipmentMethod() then
                    Message(Text10800);
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dataverse';
            Editable = false;
            ObsoleteReason = 'Replaced by page control Coupled to Dataverse';
#if not CLEAN23
            ObsoleteState = Pending;
            ObsoleteTag = '23.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Removed;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '22.0';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        ShipmentTermsTranslation: Record "Shipment Method Translation";
    begin
        with ShipmentTermsTranslation do begin
            SetRange("Shipment Method", Code);
            DeleteAll();
        end;
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    var
        CRMSyncHelper: Codeunit "CRM Synch. Helper";
    begin
        SetLastModifiedDateTime();
        CRMSyncHelper.UpdateCDSOptionMapping(xRec.RecordId(), RecordId());
    end;

    var
        Text10800: Label 'The French Intrastat feature requires a Shipment Method Code of 3 letters and 1 number.';

    procedure TranslateDescription(var ShipmentMethod: Record "Shipment Method"; Language: Code[10])
    var
        ShipmentMethodTranslation: Record "Shipment Method Translation";
    begin
        if ShipmentMethodTranslation.Get(ShipmentMethod.Code, Language) then
            ShipmentMethod.Description := ShipmentMethodTranslation.Description;
    end;

    [Scope('OnPrem')]
    procedure ValidateShipmentMethod(): Boolean
    var
        I: Integer;
    begin
        if StrLen(Code) <> 4 then
            exit(true);
        for I := 1 to 3 do
            if Code[I] in ['a' .. 'z', 'A' .. 'Z'] = false then
                exit(true);
        if Code[4] in ['0' .. '9'] = false then
            exit(true);
        exit(false);
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;
}

