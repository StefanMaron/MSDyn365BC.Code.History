namespace Microsoft.Service.Document;

using Microsoft.Service.History;

codeunit 10059 "Serv. Event Subscribers NA"
{
    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnOpenStatisticsOnAfterSetStatPageID', '', false, false)]
    local procedure ServiceHeaderOnOpenStatisticsOnAfterSetStatPageID(var ServiceHeader: Record "Service Header"; var StatPageID: Integer)
    begin
        if ServiceHeader."Tax Area Code" <> '' then
            StatPageID := Page::"Service Stats.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnOpenOrderStatisticsOnAfterSetStatPageID', '', false, false)]
    local procedure ServiceHeaderOnOpenOrderStatisticsOnAfterSetStatPageID(var ServiceHeader: Record "Service Header"; var StatPageID: Integer)
    begin
        if ServiceHeader."Tax Area Code" <> '' then
            StatPageID := Page::"Service Order Stats.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnOpenStatisticsOnAfterSetStatPageID', '', false, false)]
    local procedure ServiceCrMemoHeaderOnOpenStatisticsOnAfterSetStatPageID(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var StatPageID: Integer)
    begin
        if ServiceCrMemoHeader."Tax Area Code" <> '' then
            StatPageID := Page::"Service Credit Memo Stats.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnOpenStatisticsOnAfterSetStatPageID', '', false, false)]
    local procedure ServiceInvoiceHeaderOnOpenStatisticsOnAfterSetStatPageID(var ServiceInvoiceHeader: Record "Service Invoice Header"; var StatPageID: Integer)
    begin
        if ServiceInvoiceHeader."Tax Area Code" <> '' then
            StatPageID := Page::"Service Invoice Stats.";
    end;
}