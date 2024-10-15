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
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dataverse';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(31060; "Include Item Charges (Amount)"; Boolean)
        {
            Caption = 'Include Item Charges (Amount)';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(31061; "Intrastat Delivery Group Code"; Code[10])
        {
            Caption = 'Intrastat Delivery Group Code';
#if CLEAN18
            ObsoleteState = Removed;
#else
            TableRelation = "Intrastat Delivery Group".Code;
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(31062; "Incl. Item Charges (Stat.Val.)"; Boolean)
        {
            Caption = 'Incl. Item Charges (Stat.Val.)';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
#if not CLEAN18
            trigger OnValidate()
            begin
                if "Incl. Item Charges (Stat.Val.)" then begin
                    TestField("Adjustment %", 0);
                    CheckIncludeIntrastat;
                end;
            end;
#endif
        }
        field(31063; "Adjustment %"; Decimal)
        {
            Caption = 'Adjustment %';
            MaxValue = 100;
            MinValue = -100;
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
#if not CLEAN18

            trigger OnValidate()
            begin
                if "Adjustment %" <> 0 then begin
                    TestField("Incl. Item Charges (Stat.Val.)", false);
                    TestField("Include Item Charges (Amount)", false); // NAVCZ
                end;
            end;
#endif
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

#if not CLEAN18
    [Scope('OnPrem')]
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    procedure CheckIncludeIntrastat()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        // NAVCZ
        StatReportingSetup.Get();
        StatReportingSetup.TestField("No Item Charges in Intrastat", false);
    end;

#endif    
    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;
}

