namespace Microsoft.Sales.History;

codeunit 391 "Shipment Header - Edit"
{
    Permissions = TableData "Sales Shipment Header" = rm;
    TableNo = "Sales Shipment Header";

    trigger OnRun()
    begin
        SalesShptHeader := Rec;
        SalesShptHeader.LockTable();
        SalesShptHeader.Find();
        SalesShptHeader."Shipping Agent Code" := Rec."Shipping Agent Code";
        SalesShptHeader."Shipping Agent Service Code" := Rec."Shipping Agent Service Code";
        SalesShptHeader."Package Tracking No." := Rec."Package Tracking No.";
        SalesShptHeader."Promised Delivery Date" := Rec."Promised Delivery Date";
        SalesShptHeader."Outbound Whse. Handling Time" := Rec."Outbound Whse. Handling Time";
        SalesShptHeader."Shipping Time" := Rec."Shipping Time";
        OnBeforeSalesShptHeaderModify(SalesShptHeader, Rec);
        SalesShptHeader.TestField("No.", Rec."No.");
        SalesShptHeader.Modify();
        Rec := SalesShptHeader;

        OnRunOnAfterSalesShptHeaderEdit(Rec);
    end;

    var
        SalesShptHeader: Record "Sales Shipment Header";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptHeaderModify(var SalesShptHeader: Record "Sales Shipment Header"; FromSalesShptHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesShptHeaderEdit(var SalesShptHeader: Record "Sales Shipment Header")
    begin
    end;
}

