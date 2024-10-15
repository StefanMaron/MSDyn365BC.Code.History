namespace Microsoft.Service.Document;

using Microsoft.Service.Comment;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using Microsoft.Warehouse.Request;
using System.Automation;

report 5914 "Delete Invoiced Service Orders"
{
    AccessByPermission = TableData "Service Header" = RD;
    ApplicationArea = Service;
    Caption = 'Delete Invoiced Service Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Service Order';

            trigger OnAfterGetRecord()
            var
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeServiceHeaderOnAfterGetRecord("Service Header", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    Window.Update(1, "No.");

                ServiceOrderLine.Reset();
                ServiceOrderLine.SetRange("Document Type", "Document Type");
                ServiceOrderLine.SetRange("Document No.", "No.");
                ServiceOrderLine.SetFilter("Quantity Invoiced", '<>0');
                if ServiceOrderLine.Find('-') then begin
                    ServiceOrderLine.SetRange("Quantity Invoiced");
                    ServiceOrderLine.SetFilter("Outstanding Quantity", '<>0');
                    if not ServiceOrderLine.Find('-') then begin
                        ServiceOrderLine.SetRange("Outstanding Quantity");
                        ServiceOrderLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                        if not ServiceOrderLine.Find('-') then begin
                            ServiceOrderLine.LockTable();
                            if not ServiceOrderLine.Find('-') then begin
                                ServiceOrderLine.SetRange("Qty. Shipped Not Invoiced");
                                if ServiceOrderLine.Find('-') then
                                    repeat
                                        OnBeforeDeleteServiceOrderLine(ServiceOrderLine);
                                        ServiceOrderLine.Delete();
                                    until ServiceOrderLine.Next() = 0;

                                ServiceOrderItemLine.Reset();
                                ServiceOrderItemLine.SetRange("Document Type", "Document Type");
                                ServiceOrderItemLine.SetRange("Document No.", "No.");
                                if ServiceOrderItemLine.FindSet() then
                                    repeat
                                        OnBeforeDeleteServiceOrderItemLine(ServiceOrderItemLine);
                                        ServiceOrderItemLine.Delete();
                                    until ServiceOrderItemLine.Next() = 0;

                                ServicePost.DeleteHeader("Service Header", ServiceShptHeader, ServiceInvHeader, ServiceCrMemoHeader);

                                ServiceLineReserve.DeleteInvoiceSpecFromHeader("Service Header");

                                ServiceCommentLine.SetRange("No.", "No.");
                                ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
                                ServiceCommentLine.SetRange("Table Subtype", "Document Type");
                                ServiceCommentLine.DeleteAll();

                                WhseRequest.SetRange("Source Type", DATABASE::"Service Line");
                                WhseRequest.SetRange("Source Subtype", "Document Type");
                                WhseRequest.SetRange("Source No.", "No.");
                                if not WhseRequest.IsEmpty() then
                                    WhseRequest.DeleteAll(true);

                                ServOrderAlloc.Reset();
                                ServOrderAlloc.SetCurrentKey("Document Type");
                                ServOrderAlloc.SetRange("Document Type", "Document Type");
                                ServOrderAlloc.SetRange("Document No.", "No.");
                                ServOrderAlloc.SetRange(Posted, false);
                                ServOrderAlloc.DeleteAll();
                                ServAllocMgt.SetServOrderAllocStatus("Service Header");

                                ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                                OnBeforeDeleteServiceHeader("Service Header");

                                Delete();
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
        ServiceOrderItemLine: Record "Service Item Line";
        ServiceOrderLine: Record "Service Line";
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCommentLine: Record "Service Comment Line";
        WhseRequest: Record "Warehouse Request";
        ServOrderAlloc: Record "Service Order Allocation";
        ServicePost: Codeunit "Service-Post";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        ServAllocMgt: Codeunit ServAllocationManagement;
        Window: Dialog;

        Text000Txt: Label 'Processing Service orders #1##########';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServiceHeader(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServiceOrderLine(ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServiceOrderItemLine(ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderOnAfterGetRecord(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}

