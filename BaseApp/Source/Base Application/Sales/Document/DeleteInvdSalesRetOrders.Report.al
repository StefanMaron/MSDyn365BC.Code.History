// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Comment;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using Microsoft.Warehouse.Request;
using System.Automation;

report 6651 "Delete Invd Sales Ret. Orders"
{
    AccessByPermission = TableData "Sales Header" = RD;
    ApplicationArea = SalesReturnOrder;
    Caption = 'Delete Invoiced Sales Return Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Return Order"));
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Sales Return Order';

            trigger OnAfterGetRecord()
            var
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                PostSalesDelete: Codeunit "PostSales-Delete";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnSalesHeaderOnBeforeOnAfterGetRecord("Sales Header", IsHandled);
                if IsHandled then
                    exit;

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
                        SalesOrderLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
                        if not SalesOrderLine.Find('-') then begin
                            SalesOrderLine.LockTable();
                            if not SalesOrderLine.Find('-') then begin
                                SalesOrderLine.SetRange("Return Qty. Rcd. Not Invd.");
                                ArchiveManagement.AutoArchiveSalesDocument("Sales Header");
                                if SalesOrderLine.Find('-') then
                                    repeat
                                        SalesOrderLine.CalcFields("Qty. Assigned");
                                        if ((SalesOrderLine."Qty. Assigned" = SalesOrderLine."Quantity Invoiced") and
                                            (SalesOrderLine."Qty. Assigned" <> 0)) or
                                           (SalesOrderLine.Type <> SalesOrderLine.Type::"Charge (Item)")
                                        then begin
                                            if SalesOrderLine.Type = SalesOrderLine.Type::"Charge (Item)" then begin
                                                ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
                                                ItemChargeAssgntSales.DeleteAll();
                                            end;
                                            IsHandled := false;
                                            OnBeforeDeleteSalesOrderLine(SalesOrderLine, IsHandled);
                                            if not IsHandled then
                                                if SalesOrderLine.HasLinks then
                                                    SalesOrderLine.DeleteLinks();
                                            SalesOrderLine.Delete();
                                            OnSalesHeaderOnAfterGetRecordOnAfterSalesOrderLineDelete(SalesOrderLine);
                                        end else
                                            AllLinesDeleted := false;

                                    until SalesOrderLine.Next() = 0;

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

                                    OnBeforeDeleteSalesOrderHeader("Sales Header");
                                    Delete();
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
                    Window.Open(Text000);
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
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ArchiveManagement: Codeunit ArchiveManagement;
        Window: Dialog;
        AllLinesDeleted: Boolean;

        Text000: Label 'Processing sales return orders #1##########';

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesOrderHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesOrderLine(var SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnBeforeOnAfterGetRecord(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnAfterSalesOrderLineDelete(var SalesOrderLine: Record "Sales Line")
    begin
    end;
}

