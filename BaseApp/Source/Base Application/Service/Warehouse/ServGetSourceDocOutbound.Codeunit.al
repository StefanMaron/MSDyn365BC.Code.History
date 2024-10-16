namespace Microsoft.Warehouse.Request;

using Microsoft.Service.Document;

codeunit 6491 "Serv. Get Source Doc. Outbound"
{
    var
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";

    procedure CreateFromServiceOrder(ServiceHeader: Record "Service Header")
    begin
        OnBeforeCreateFromServiceOrder(ServiceHeader);
        GetSourceDocOutbound.ShowResult(CreateFromServiceOrderHideDialog(ServiceHeader));
    end;

    procedure CreateFromServiceOrderHideDialog(ServiceHeader: Record Microsoft.Service.Document."Service Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        FindWarehouseRequestForServiceOrder(WhseRqst, ServiceHeader);
        exit(GetSourceDocOutbound.CreateWhseShipmentHeaderFromWhseRequest(WhseRqst));
    end;

    local procedure FindWarehouseRequestForServiceOrder(var WhseRqst: Record "Warehouse Request"; ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.TestField("Release Status", ServiceHeader."Release Status"::"Released to Ship");
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetSourceFilter(Database::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        OnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(WhseRqst, ServiceHeader);
#if not CLEAN25
        GetSourceDocOutbound.RunOnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(WhseRqst, ServiceHeader);
#endif
        GetSourceDocOutbound.GetRequireShipRqst(WhseRqst);

        OnAfterFindWarehouseRequestForServiceOrder(WhseRqst, ServiceHeader);
#if not CLEAN25
        GetSourceDocOutbound.RunOnAfterFindWarehouseRequestForServiceOrder(WhseRqst, ServiceHeader);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromServiceOrder(var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(var WarehouseRequest: Record "Warehouse Request"; var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForServiceOrder(var WarehouseRequest: Record "Warehouse Request"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
}