table 1670 "Option Lookup Buffer"
{
    Caption = 'Option Lookup Buffer';
    LookupPageID = "Option Lookup List";
    ReplicateData = false;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Option Caption"; Text[30])
        {
            Caption = 'Option Values';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Lookup Type"; Option)
        {
            Caption = 'Lookup Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = 'Sales,Purchases,Permissions';
            OptionMembers = Sales,Purchases,Permissions;
        }
    }

    keys
    {
        key(Key1; "Option Caption")
        {
            Clustered = true;
        }
        key(Key2; ID)
        {
        }
    }

    fieldgroups
    {
    }

    var
        UnsupportedTypeErr: Label 'Unsupported Lookup Type.';
        InvalidTypeErr: Label '''%1'' is not a valid type for this document.', Comment = '%1 = Type caption. Fx. Item';
        CurrentType: Text[30];

    [Scope('OnPrem')]
    procedure FillBuffer(LookupType: Option)
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Permission: Record Permission;
    begin
        case LookupType of
            "Lookup Type"::Sales:
                FillBufferInternal(DATABASE::"Sales Line", SalesLine.FieldNo(Type), SalesLine.FieldNo("No."), LookupType);
            "Lookup Type"::Purchases:
                FillBufferInternal(DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type), PurchaseLine.FieldNo("No."), LookupType);
            "Lookup Type"::Permissions:
                FillBufferInternal(DATABASE::Permission, Permission.FieldNo("Read Permission"), 0, LookupType);
            else
                Error(UnsupportedTypeErr);
        end;
    end;

    [Scope('OnPrem')]
    procedure AutoCompleteOption(var Option: Text[30]; LookupType: Option): Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Permission: Record Permission;
    begin
        Option := DelChr(Option, '<>');
        if Option = '' then
            case LookupType of
                "Lookup Type"::Sales:
                    Option := SalesLine.FormatType;
                "Lookup Type"::Purchases:
                    Option := PurchaseLine.FormatType;
                "Lookup Type"::Permissions:
                    Option := Format(Permission."Read Permission");
                else
                    exit(false);
            end;

        SetRange("Option Caption");
        if IsEmpty then
            FillBuffer(LookupType);

        SetRange("Option Caption", Option);
        if FindFirst then
            exit(true);

        SetFilter("Option Caption", '%1', '@' + Option + '*');
        if FindFirst then begin
            Option := "Option Caption";
            exit(true);
        end;

        SetFilter("Option Caption", '%1', '@*' + Option + '*');
        if FindFirst then begin
            Option := "Option Caption";
            exit(true);
        end;

        SetRange("Option Caption", CurrentType);
        if FindFirst then begin
            Option := "Option Caption";
            exit(true);
        end;

        exit(false);
    end;

    procedure ValidateOption(Option: Text[30])
    begin
        SetRange("Option Caption", Option);
        if IsEmpty then
            Error(InvalidTypeErr, Option);

        SetRange("Option Caption");
    end;

    procedure FormatOption(FieldRef: FieldRef): Text[30]
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Option: Option;
    begin
        Option := FieldRef.Value;
        case FieldRef.Record.Number of
            DATABASE::"Sales Line", DATABASE::"Standard Sales Line":
                if Option = SalesLine.Type::" ".AsInteger() then
                    exit(SalesLine.FormatType);
            DATABASE::"Purchase Line", DATABASE::"Standard Purchase Line":
                if Option = PurchaseLine.Type::" ".AsInteger() then
                    exit(PurchaseLine.FormatType);
        end;

        exit(Format(FieldRef));
    end;

    local procedure CreateNew(OptionID: Integer; OptionText: Text[30]; LookupType: Option)
    begin
        Init;
        ID := OptionID;
        "Option Caption" := OptionText;
        "Lookup Type" := LookupType;
        Insert;
    end;

    local procedure FillBufferInternal(TableNo: Integer; FieldNo: Integer; RelationFieldNo: Integer; LookupType: Option)
    var
        RecRef: RecordRef;
        RelatedRecRef: RecordRef;
        FieldRef: FieldRef;
        FieldRefRelation: FieldRef;
        OptionIndex: Integer;
        RelatedTableNo: Integer;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        for OptionIndex := 0 to (FieldRef.EnumValueCount() - 1) do begin
            FieldRef.Value(FieldRef.GetEnumValueOrdinal(OptionIndex + 1));
            if IncludeOption(LookupType, OptionIndex) then begin
                FieldRefRelation := RecRef.Field(RelationFieldNo);
                RelatedTableNo := FieldRefRelation.Relation();
                if RelatedTableNo = 0 then
                    CreateNew(OptionIndex, FormatOption(FieldRef), LookupType)
                else begin
                    RelatedRecRef.Open(RelatedTableNo);
                    RelatedRecRef.SetPermissionFilter();
                    if RelatedRecRef.ReadPermission then
                        CreateNew(OptionIndex, FormatOption(FieldRef), LookupType);
                    RelatedRecRef.Close;
                end;
            end;
        end;
    end;

    local procedure IncludeOption(LookupType: Option; Option: Integer): Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeIncludeOption(Rec, LookupType, Option, IsHandled, Result);
        if IsHandled then
            Exit(Result);

        case LookupType of
            "Lookup Type"::Sales:
                case Option of
                    SalesLine.Type::" ".AsInteger(), SalesLine.Type::"G/L Account".AsInteger(), SalesLine.Type::Item.AsInteger():
                        exit(true);
                    SalesLine.Type::"Charge (Item)".AsInteger():
                        if ApplicationAreaMgmtFacade.IsItemChargesEnabled then
                            exit(true);
                    SalesLine.Type::"Fixed Asset".AsInteger():
                        if ApplicationAreaMgmtFacade.IsFixedAssetEnabled then
                            exit(true);
                    SalesLine.Type::Resource.AsInteger():
                        if ApplicationAreaMgmtFacade.IsJobsEnabled then
                            exit(true);
                end;
            "Lookup Type"::Purchases:
                case Option of
                    PurchaseLine.Type::" ".AsInteger(), PurchaseLine.Type::"G/L Account".AsInteger(), PurchaseLine.Type::Item.AsInteger():
                        exit(true);
                    PurchaseLine.Type::"Charge (Item)".AsInteger():
                        if ApplicationAreaMgmtFacade.IsItemChargesEnabled then
                            exit(true);
                    PurchaseLine.Type::"Fixed Asset".AsInteger():
                        if ApplicationAreaMgmtFacade.IsFixedAssetEnabled then
                            exit(true);
                    PurchaseLine.Type::Resource.AsInteger():
                        if ApplicationAreaMgmtFacade.IsJobsEnabled() then
                            exit(true);
                end;
            "Lookup Type"::Permissions:
                exit(true);
        end;
    end;

    procedure SetCurrentType(LineType: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)")
    begin
        CurrentType := Format(LineType::Item); // Default value
        if LineType = LineType::" " then
            exit;
        CurrentType := Format(LineType);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncludeOption(OptionLookupBuffer: Record "Option Lookup Buffer"; LookupType: Option; Option: Integer; var Handled: Boolean; var Result: Boolean)
    begin
    end;
}

