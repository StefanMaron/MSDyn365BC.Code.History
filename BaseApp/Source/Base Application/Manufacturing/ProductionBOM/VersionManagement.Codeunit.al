namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Manufacturing.Routing;

codeunit 99000756 VersionManagement
{
    Permissions = TableData "Production BOM Header" = r;

    trigger OnRun()
    begin
    end;

    procedure GetBOMVersion(BOMHeaderNo: Code[20]; Date: Date; OnlyCertified: Boolean) VersionCode: Code[20]
    var
        ProdBOMVersion: Record "Production BOM Version";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBOMVersion(BOMHeaderNo, Date, OnlyCertified, VersionCode, IsHandled);
        if IsHandled then
            exit(VersionCode);

        ProdBOMVersion.SetCurrentKey("Production BOM No.", "Starting Date");
        ProdBOMVersion.SetRange("Production BOM No.", BOMHeaderNo);
        ProdBOMVersion.SetFilter("Starting Date", '%1|..%2', 0D, Date);
        if OnlyCertified then
            ProdBOMVersion.SetRange(Status, ProdBOMVersion.Status::Certified)
        else
            ProdBOMVersion.SetFilter(Status, '<>%1', ProdBOMVersion.Status::Closed);
        if not ProdBOMVersion.FindLast() then
            Clear(ProdBOMVersion);

        exit(ProdBOMVersion."Version Code");
    end;

    procedure GetBOMUnitOfMeasure(BOMHeaderNo: Code[20]; VersionCode: Code[20]) UoMCode: Code[10]
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBOMUnitOfMeasure(BOMHeaderNo, VersionCode, UoMCode, IsHandled);
        if IsHandled then
            exit(UoMCode);

        if BOMHeaderNo = '' then
            exit('');

        if VersionCode = '' then begin
            ProdBOMHeader.Get(BOMHeaderNo);
            exit(ProdBOMHeader."Unit of Measure Code");
        end;

        ProdBOMVersion.Get(BOMHeaderNo, VersionCode);
        exit(ProdBOMVersion."Unit of Measure Code");
    end;

    procedure GetRtngVersion(RoutingNo: Code[20]; Date: Date; OnlyCertified: Boolean) VersionCode: Code[20]
    var
        RtngVersion: Record "Routing Version";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRtngVersion(RoutingNo, Date, OnlyCertified, VersionCode, IsHandled);
        if IsHandled then
            exit(VersionCode);

        RtngVersion.SetCurrentKey("Routing No.", "Starting Date");
        RtngVersion.SetRange("Routing No.", RoutingNo);
        RtngVersion.SetFilter("Starting Date", '%1|..%2', 0D, Date);
        if OnlyCertified then
            RtngVersion.SetRange(Status, RtngVersion.Status::Certified)
        else
            RtngVersion.SetFilter(Status, '<>%1', RtngVersion.Status::Closed);

        if not RtngVersion.FindLast() then
            Clear(RtngVersion);

        exit(RtngVersion."Version Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBOMVersion(BOMHeaderNo: Code[20]; Date: Date; OnlyCertified: Boolean; var VersionCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBOMUnitOfMeasure(BOMHeaderNo: Code[20]; VersionCode: Code[20]; var UoMCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRtngVersion(RoutingNo: Code[20]; Date: Date; OnlyCertified: Boolean; var VersionCode: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

