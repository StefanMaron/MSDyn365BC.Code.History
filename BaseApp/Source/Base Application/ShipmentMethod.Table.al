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
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
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
            DeleteAll
        end;
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnRename()
    var
        CRMSyncHelper: Codeunit "CRM Synch. Helper";
    begin
        SetLastModifiedDateTime;
        CRMSyncHelper.UpdateCDSOptionMapping(xRec.RecordId(), RecordId());
    end;

    procedure TranslateDescription(var ShipmentMethod: Record "Shipment Method"; Language: Code[10])
    var
        ShipmentMethodTranslation: Record "Shipment Method Translation";
    begin
        if ShipmentMethodTranslation.Get(ShipmentMethod.Code, Language) then
            ShipmentMethod.Description := ShipmentMethodTranslation.Description;
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;
}

