codeunit 7317 "Whse. Integration Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label '%1 must not be the Adjustment Bin Code of the location %2.';
        Text001: Label 'The bin %1 is Dedicated.\Do you still want to use this bin?';
        Text002: Label 'The update has been interrupted.';
        Text003: Label 'Location %1 must be set up with Bin Mandatory if the %2 %3 uses it.', Comment = '%2 = Object No., %3 = Object No.';
        Text004: Label 'You cannot enter a bin code of bin type %1, %2, or %3.', Comment = 'You cannot enter a bin code of bin type Receive, Ship, or Pick.';
        Text005: Label 'You cannot enter a bin code of bin type %1 or %2.';

    procedure CheckBinTypeCode(SourceTable: Integer; BinCodeFieldCaption: Text[30]; LocationCode: Code[10]; BinCode: Code[20]; AdditionalIdentifier: Option)
    var
        BinType: Record "Bin Type";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnStartCheckBinTypeCode(SourceTable, BinCodeFieldCaption, LocationCode, BinCode, AdditionalIdentifier, IsHandled);
        if IsHandled then
            exit;

        Location.Get(LocationCode);
        Location.TestField("Bin Mandatory");

        if not Location."Directed Put-away and Pick" then
            exit;

        if BinCode = Location."Adjustment Bin Code" then
            Error(Text000, BinCodeFieldCaption, LocationCode);

        IsHandled := false;
        OnBeforeCheckBinTypeCode(SourceTable, BinCodeFieldCaption, LocationCode, BinCode, AdditionalIdentifier, IsHandled);
        if IsHandled then
            exit;

        Bin.Get(LocationCode, BinCode);
        Bin.TestField("Bin Type Code");
        BinType.Get(Bin."Bin Type Code");
        case SourceTable of
            DATABASE::"Warehouse Shipment Header",
            DATABASE::"Warehouse Shipment Line":
                BinType.TestField(Ship, true);
            DATABASE::"Warehouse Receipt Header",
            DATABASE::"Warehouse Receipt Line":
                BinType.TestField(Receive, true);
            DATABASE::"Production Order",
            DATABASE::"Prod. Order Line",
            DATABASE::"Assembly Header":
                AllowPutawayPickOrQCBinsOnly(BinType);
            DATABASE::"Prod. Order Component",
            DATABASE::"Assembly Line":
                AllowPutawayOrQCBinsOnly(BinType);
            DATABASE::"Machine Center":
                case BinCodeFieldCaption of
                    MachineCenter.FieldCaption("Open Shop Floor Bin Code"),
                    MachineCenter.FieldCaption("To-Production Bin Code"):
                        AllowPutawayOrQCBinsOnly(BinType);
                    MachineCenter.FieldCaption("From-Production Bin Code"):
                        AllowPutawayPickOrQCBinsOnly(BinType);
                end;
            DATABASE::"Work Center":
                case BinCodeFieldCaption of
                    WorkCenter.FieldCaption("Open Shop Floor Bin Code"),
                    WorkCenter.FieldCaption("To-Production Bin Code"):
                        AllowPutawayOrQCBinsOnly(BinType);
                    WorkCenter.FieldCaption("From-Production Bin Code"):
                        AllowPutawayPickOrQCBinsOnly(BinType);
                end;
            DATABASE::Location:
                case BinCodeFieldCaption of
                    Location.FieldCaption("Open Shop Floor Bin Code"),
                    Location.FieldCaption("To-Production Bin Code"),
                    Location.FieldCaption("To-Assembly Bin Code"):
                        AllowPutawayOrQCBinsOnly(BinType);
                    Location.FieldCaption("From-Production Bin Code"),
                    Location.FieldCaption("From-Assembly Bin Code"):
                        AllowPutawayPickOrQCBinsOnly(BinType);
                end;
            DATABASE::"Item Journal Line":
                case AdditionalIdentifier of
                    ItemJournalLine."Entry Type"::Output.AsInteger():
                        AllowPutawayPickOrQCBinsOnly(BinType);
                    ItemJournalLine."Entry Type"::Consumption.AsInteger():
                        AllowPutawayOrQCBinsOnly(BinType);
                end;
            DATABASE::"Service Line":
                if AdditionalIdentifier = ServiceLine."Document Type"::Invoice.AsInteger() then
                    BinType.TestField(Pick, true);
            else
                OnCheckBinTypeCode(Location, Bin, BinType, SourceTable, BinCodeFieldCaption, AdditionalIdentifier);
        end;
    end;

    procedure AllowPutawayOrQCBinsOnly(var BinType: Record "Bin Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAllowPutawayOrQCBinsOnly(BinType, IsHandled);
        if IsHandled then
            exit;

        if BinType.Receive or BinType.Ship or BinType.Pick then
            Error(Text004, BinType.FieldCaption(Receive), BinType.FieldCaption(Ship), BinType.FieldCaption(Pick));
    end;

    procedure AllowPutawayPickOrQCBinsOnly(var BinType: Record "Bin Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAllowPutawayPickOrQCBinsOnly(BinType, IsHandled);
        if IsHandled then
            exit;

        if BinType.Receive or BinType.Ship then
            Error(Text005, BinType.FieldCaption(Receive), BinType.FieldCaption(Ship));
    end;

    procedure CheckIfBinDedicatedOnSrcDoc(LocationCode: Code[10]; var BinCode: Code[20]; IssueWarning: Boolean)
    var
        Bin: Record Bin;
    begin
        if BinCode <> '' then begin
            Bin.Get(LocationCode, BinCode);
            if Bin.Dedicated then
                if IssueWarning then begin
                    if not
                       Confirm(
                         StrSubstNo(Text001, BinCode), false)
                    then
                        Error(Text002)
                end else
                    BinCode := '';
        end;
    end;

    procedure CheckBinCode(LocationCode: Code[10]; BinCode: Code[20]; BinCaption: Text[30]; SourceTable: Integer; Number: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
    begin
        if BinCode <> '' then begin
            Location.Get(LocationCode);
            CheckLocationCode(Location, SourceTable, Number);
            Bin.Get(LocationCode, BinCode);
            CheckBinTypeCode(SourceTable,
              BinCaption,
              LocationCode,
              BinCode, 0);
        end;
    end;

    procedure CheckLocationCode(Location: Record Location; SourceTable: Integer; Number: Code[20])
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        CaptionText: Text[30];
    begin
        case SourceTable of
            DATABASE::"Work Center":
                CaptionText := WorkCenter.TableCaption();
            DATABASE::"Machine Center":
                CaptionText := MachineCenter.TableCaption();
            DATABASE::Location:
                CaptionText := Location.TableCaption();
        end;
        if not Location."Bin Mandatory" then
            Error(Text003,
              Location.Code,
              CaptionText,
              Number);
    end;

    procedure IsOpenShopFloorBin(LocationCode: Code[10]; BinCode: Code[20]): Boolean
    var
        Location: Record Location;
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        Location.Get(LocationCode);
        if BinCode = Location."Open Shop Floor Bin Code" then
            exit(true);

        WorkCenter.SetRange("Location Code", LocationCode);
        WorkCenter.SetRange("Open Shop Floor Bin Code", BinCode);
        if WorkCenter.Count > 0 then
            exit(true);

        MachineCenter.SetRange("Location Code", LocationCode);
        MachineCenter.SetRange("Open Shop Floor Bin Code", BinCode);
        if MachineCenter.Count > 0 then
            exit(true);

        exit(false);
    end;

    procedure CheckLocationOnManufBins(Location: Record Location)
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetRange("Location Code", Location.Code);
        if WorkCenter.FindSet(false) then
            repeat
                CheckLocationCode(Location, DATABASE::"Work Center", WorkCenter."No.");
            until WorkCenter.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAllowPutawayOrQCBinsOnly(var BinType: Record "Bin Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAllowPutawayPickOrQCBinsOnly(var BinType: Record "Bin Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinTypeCode(SourceTable: Integer; BinCodeFieldCaption: Text[30]; LocationCode: Code[10]; BinCode: Code[20]; AdditionalIdentifier: Option; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinTypeCode(Location: Record Location; Bin: Record Bin; BinType: Record "Bin Type"; SourceTable: Integer; BinCodeFieldCaption: Text[30]; AdditionalIdentifier: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartCheckBinTypeCode(SourceTable: Integer; BinCodeFieldCaption: Text[30]; LocationCode: Code[10]; BinCode: Code[20]; AdditionalIdentifier: Option; var IsHandled: Boolean);
    begin
    end;
}

