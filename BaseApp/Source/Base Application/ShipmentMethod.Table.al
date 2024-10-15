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
        }
        field(12100; "Intra Shipping Code"; Code[10])
        {
            Caption = 'Intra Shipping Code';
            TableRelation = "Entry/Exit Point";
        }
        field(12101; "3rd-Party Loader"; Boolean)
        {
            Caption = '3rd-Party Loader';
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
    begin
        SetLastModifiedDateTime;
    end;

    procedure TranslateDescription(var ShipmentMethod: Record "Shipment Method"; Language: Code[10])
    var
        ShipmentMethodTranslation: Record "Shipment Method Translation";
    begin
        if ShipmentMethodTranslation.Get(ShipmentMethod.Code, Language) then
            ShipmentMethod.Description := ShipmentMethodTranslation.Description;
    end;

    [Scope('OnPrem')]
    procedure ThirdPartyLoader(ShipmentMethodCode: Code[10]): Boolean
    begin
        exit(
          Get(ShipmentMethodCode) and
          "3rd-Party Loader")
    end;

    [Scope('OnPrem')]
    procedure CheckShipMethod3rdPartyLoader(ShipmentMethodCode: Code[10])
    begin
        if not ThirdPartyLoader(ShipmentMethodCode) then
            FieldError("3rd-Party Loader");
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;
}

