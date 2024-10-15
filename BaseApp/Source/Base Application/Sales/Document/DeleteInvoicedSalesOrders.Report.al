// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Comment;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using Microsoft.Warehouse.Request;
using System.Automation;

report 299 "Delete Invoiced Sales Orders"
{
    AccessByPermission = TableData "Sales Header" = RD;
    ApplicationArea = Basic, Suite;
    Caption = 'Delete Invoiced Sales Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Sales Order';

            trigger OnAfterGetRecord()
            var
                ATOLink: Record "Assemble-to-Order Link";
                SalesLineReserve: Codeunit "Sales Line-Reserve";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                PostSalesDelete: Codeunit "PostSales-Delete";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeSalesHeaderOnAfterGetRecord("Sales Header", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    Window.Update(1, "No.");

                AllLinesDeleted := true;
                ItemChargeAssgntSales.Reset();
                ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
                ItemChargeAssgntSales.SetRange("Document No.", "No.");
                SalesOrderLine.Reset();
                SalesOrderLine.SetRange("Document Type", "Document Type");
                SalesOrderLine.SetRange("Document No.", "No.");
                SalesOrderLine.SetFilter("Quantity Invoiced", '<>0');
                if SalesOrderLine.Find('-') then begin
                    SalesOrderLine.SetRange("Quantity Invoiced");
                    SalesOrderLine.SetFilter("Outstanding Quantity", '<>0');
                    OnAfterSetSalesLineFilters(SalesOrderLine);
                    if not SalesOrderLine.Find('-') then begin
                        SalesOrderLine.SetRange("Outstanding Quantity");
                        SalesOrderLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                        if not SalesOrderLine.Find('-') then begin
                            SalesOrderLine.LockTable();
                            if not SalesOrderLine.Find('-') then begin
                                SalesOrderLine.SetRange("Qty. Shipped Not Invoiced");

                                IsHandled := false;
                                OnSalesHeaderOnAfterGetRecordOnBeforeAutoArchiveSalesDocument(IsHandled, "Sales Header");
                                if not IsHandled then
                                    ArchiveManagement.AutoArchiveSalesDocument("Sales Header");

                                OnBeforeDeleteSalesLinesLoop("Sales Header", SalesOrderLine);
                                if SalesOrderLine.Find('-') then
                                    repeat
                                        SalesOrderLine.CalcFields("Qty. Assigned");
                                        if (SalesOrderLine."Qty. Assigned" = SalesOrderLine."Quantity Invoiced") or
                                           (SalesOrderLine.Type <> SalesOrderLine.Type::"Charge (Item)") or
                                           IsPostedUnassignedItemChargeWithZeroAmount(SalesOrderLine)
                                        then begin
                                            if SalesOrderLine.Type = SalesOrderLine.Type::"Charge (Item)" then begin
                                                ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
                                                ItemChargeAssgntSales.DeleteAll();
                                            end;
                                            if SalesOrderLine.Type = SalesOrderLine.Type::Item then
                                                ATOLink.DeleteAsmFromSalesLine(SalesOrderLine);

                                            IsHandled := false;
                                            OnSalesHeaderOnAfterGetRecordOnBeforeSalesOrderLineDeleteLinks(IsHandled, SalesOrderLine);
                                            if not IsHandled then
                                                if SalesOrderLine.HasLinks then
                                                    SalesOrderLine.DeleteLinks();
                                            SalesOrderLine.Delete();
                                            OnAfterDeleteSalesLine(SalesOrderLine);
                                        end else
                                            AllLinesDeleted := false;
                                        UpdateAssociatedPurchOrder();
                                    until SalesOrderLine.Next() = 0;
                                OnAfterDeleteSalesLinesLoop("Sales Header", AllLinesDeleted);

                                if AllLinesDeleted then begin
                                    PostSalesDelete.DeleteHeader(
                                      "Sales Header", SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader,
                                      PrepmtSalesInvHeader, PrepmtSalesCrMemoHeader);

                                    SalesLineReserve.DeleteInvoiceSpecFromHeader("Sales Header");

                                    SalesCommentLine.SetRange("Document Type", "Document Type");
                                    SalesCommentLine.SetRange("No.", "No.");
                                    SalesCommentLine.DeleteAll();

                                    WhseRequest.SetRange("Source Type", DATABASE::"Sales Line");
                                    WhseRequest.SetRange("Source Subtype", "Document Type");
                                    WhseRequest.SetRange("Source No.", "No.");
                                    if not WhseRequest.IsEmpty() then
                                        WhseRequest.DeleteAll(true);

                                    ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                                    IsHandled := false;
                                    OnSalesHeaderOnAfterGetRecordOnBeforeDeleteLinks(IsHandled, Invoice);
                                    if not IsHandled then
                                        if HasLinks then
                                            DeleteLinks();

                                    OnBeforeDeleteSalesHeader("Sales Header");
                                    Delete();
                                    OnAfterDeleteSalesHeader("Sales Header");
                                end;
                                Commit();
                            end;
                        end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if GuiAllowed() then
                    Window.Open(Text000Txt);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        SalesOrderLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        PrepmtSalesInvHeader: Record "Sales Invoice Header";
        PrepmtSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCommentLine: Record "Sales Comment Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        WhseRequest: Record "Warehouse Request";
        ArchiveManagement: Codeunit ArchiveManagement;
        Window: Dialog;
        AllLinesDeleted: Boolean;

        Text000Txt: Label 'Processing sales orders #1##########';

    local procedure UpdateAssociatedPurchOrder()
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAssociatedPurchOrder(SalesOrderLine, PurchLine, IsHandled);
        if IsHandled then
            exit;

        if SalesOrderLine."Special Order" then
            if PurchLine.Get(
                 PurchLine."Document Type"::Order, SalesOrderLine."Special Order Purchase No.", SalesOrderLine."Special Order Purch. Line No.")
            then begin
                PurchLine."Special Order Sales No." := '';
                PurchLine."Special Order Sales Line No." := 0;
                PurchLine.Modify();
            end;

        if SalesOrderLine."Drop Shipment" then
            if PurchLine.Get(
                 PurchLine."Document Type"::Order, SalesOrderLine."Purchase Order No.", SalesOrderLine."Purch. Order Line No.")
            then begin
                PurchLine."Sales Order No." := '';
                PurchLine."Sales Order Line No." := 0;
                PurchLine.Modify();
            end;
    end;

    local procedure IsPostedUnassignedItemChargeWithZeroAmount(SalesLine: Record "Sales Line"): Boolean
    begin
        SalesLine.CalcFields("Qty. Assigned");
        if (SalesLine.Type = SalesLine.Type::"Charge (Item)") and
           (SalesLine.Quantity = SalesLine."Quantity Invoiced") and
           (SalesLine."Qty. Assigned" = 0) and
           (SalesLine.Amount = 0)
        then
            exit(true);

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteSalesLinesLoop(var SalesHeader: Record "Sales Header"; AllLinesDeleted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesLinesLoop(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderOnAfterGetRecord(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAssociatedPurchOrder(var SalesOrderLine: Record "Sales Line"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnBeforeAutoArchiveSalesDocument(var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnBeforeSalesOrderLineDeleteLinks(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnBeforeDeleteLinks(var IsHandled: Boolean; var Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;
}

