﻿namespace Microsoft.Service.Document;

using Microsoft.Service.History;

codeunit 5932 "Service-Get Shipment"
{
    TableNo = "Service Line";

    trigger OnRun()
    begin
        ServiceHeader.Get(Rec."Document Type", Rec."Document No.");
        ServiceHeader.TestField("Document Type", ServiceHeader."Document Type"::Invoice);

        Clear(ServiceShptLine);
        ServiceShptLine.SetCurrentKey("Bill-to Customer No.");
        ServiceShptLine.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        ServiceShptLine.SetRange("Currency Code", ServiceHeader."Currency Code");
        OnAfterSetServiceShptLineFilters(ServiceShptLine, ServiceHeader);
        ServiceShptLine.FilterGroup(2);

        GetServiceShipments.SetTableView(ServiceShptLine);
        GetServiceShipments.SetServiceHeader(ServiceHeader);
        GetServiceShipments.LookupMode(true);
        GetServiceShipments.RunModal();
    end;

    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceShptLine: Record "Service Shipment Line";
        GetServiceShipments: Page "Get Service Shipment Lines";

        Text001: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';

    procedure CreateInvLines(var ServiceShptLine2: Record "Service Shipment Line")
    var
        TransferLine: Boolean;
    begin
        with ServiceShptLine2 do begin
            SetFilter("Qty. Shipped Not Invoiced", '<>0');
            if Find('-') then begin
                ServiceLine.LockTable();
                ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
                ServiceLine.SetRange("Document No.", ServiceHeader."No.");
                ServiceLine."Document Type" := ServiceHeader."Document Type";
                ServiceLine."Document No." := ServiceHeader."No.";
                repeat
                    if ServiceShptHeader."No." <> "Document No." then begin
                        ServiceShptHeader.Get("Document No.");
                        TransferLine := true;
                        if ServiceShptHeader."Currency Code" <> ServiceHeader."Currency Code" then begin
                            Message(
                              Text001,
                              ServiceHeader.FieldCaption("Currency Code"),
                              ServiceHeader.TableCaption(), ServiceHeader."No.",
                              ServiceShptHeader.TableCaption, ServiceShptHeader."No.");
                            TransferLine := false;
                        end;
                        if ServiceShptHeader."Bill-to Customer No." <> ServiceHeader."Bill-to Customer No." then begin
                            Message(
                              Text001,
                              ServiceHeader.FieldCaption("Bill-to Customer No."),
                              ServiceHeader.TableCaption(), ServiceHeader."No.",
                              ServiceShptHeader.TableCaption, ServiceShptHeader."No.");
                            TransferLine := false;
                        end;
                    end;
                    if TransferLine then begin
                        ServiceShptLine := ServiceShptLine2;
                        CheckServiceShipmentLineVATBusPostingGroup(ServiceShptLine, ServiceHeader);
                        ServiceShptLine.InsertInvLineFromShptLine(ServiceLine);
                        OnCreateInvLinesOnAfterServiceShptLineInsertInvLineFromShptLine(ServiceShptLine, ServiceShptLine2, ServiceShptHeader, ServiceLine, ServiceHeader);
                    end;
                until Next() = 0;
                OnAfterCreateInvLines(ServiceHeader);
            end;
        end;
    end;

    local procedure CheckServiceShipmentLineVATBusPostingGroup(ServiceShipmentLine: Record "Service Shipment Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServiceShipmentLineVATBusPostingGroup(ServiceShipmentLine, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        ServiceShipmentLine.TestField("VAT Bus. Posting Group", ServiceHeader."VAT Bus. Posting Group");
    end;

    procedure GetServiceOrderInvoices(var TempServiceInvoiceHeader: Record "Service Invoice Header" temporary; OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoicesByOrder: Query "Service Invoices By Order";
    begin
        TempServiceInvoiceHeader.Reset();
        TempServiceInvoiceHeader.DeleteAll();

        ServiceInvoicesByOrder.SetRange(Order_No_, OrderNo);
        ServiceInvoicesByOrder.SetFilter(Quantity, '<>0');
        ServiceInvoicesByOrder.Open();

        while ServiceInvoicesByOrder.Read() do begin
            ServiceInvoiceHeader.Get(ServiceInvoicesByOrder.Document_No_);
            TempServiceInvoiceHeader := ServiceInvoiceHeader;
            TempServiceInvoiceHeader.Insert();
        end;
    end;

    procedure SetServiceHeader(var ServiceHeader2: Record "Service Header")
    begin
        ServiceHeader.Get(ServiceHeader2."Document Type", ServiceHeader2."No.");
        ServiceHeader.TestField("Document Type", ServiceHeader."Document Type"::Invoice);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvLines(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServiceShptLineFilters(var ServiceShipmentLine: Record "Service Shipment Line"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterServiceShptLineInsertInvLineFromShptLine(var ServiceShptLine: Record "Service Shipment Line"; var ServiceShptLine2: Record "Service Shipment Line"; var ServiceShptHeader: Record "Service Shipment Header"; var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServiceShipmentLineVATBusPostingGroup(ServiceShipmentLine: Record "Service Shipment Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}

