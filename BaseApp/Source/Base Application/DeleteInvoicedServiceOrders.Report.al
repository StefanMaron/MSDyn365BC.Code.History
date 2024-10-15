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
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.", "Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Service Order';

            trigger OnAfterGetRecord()
            var
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
            begin
                OnBeforeServiceHeaderOnAfterGetRecord("Service Header");

                Window.Update(1, "No.");

                ItemChargeAssgntService.Reset;
                ItemChargeAssgntService.SetRange("Document Type", "Document Type");
                ItemChargeAssgntService.SetRange("Document No.", "No.");

                ServiceOrderLine.Reset;
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
                            ServiceOrderLine.LockTable;
                            if not ServiceOrderLine.Find('-') then begin
                                ServiceOrderLine.SetRange("Qty. Shipped Not Invoiced");
                                if ServiceOrderLine.Find('-') then
                                    repeat
                                        OnBeforeDeleteServiceOrderLine(ServiceOrderLine);
                                        ServiceOrderLine.Delete;
                                    until ServiceOrderLine.Next = 0;

                                ServiceOrderItemLine.Reset;
                                ServiceOrderItemLine.SetRange("Document Type", "Document Type");
                                ServiceOrderItemLine.SetRange("Document No.", "No.");
                                if ServiceOrderItemLine.FindSet then
                                    repeat
                                        OnBeforeDeleteServiceOrderItemLine(ServiceOrderItemLine);
                                        ServiceOrderItemLine.Delete;
                                    until ServiceOrderItemLine.Next = 0;

                                ServicePost.DeleteHeader("Service Header", ServiceShptHeader, ServiceInvHeader, ServiceCrMemoHeader);

                                ReserveServiceLine.DeleteInvoiceSpecFromHeader("Service Header");

                                ServiceCommentLine.SetRange("No.", "No.");
                                ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
                                ServiceCommentLine.SetRange("Table Subtype", "Document Type");
                                ServiceCommentLine.DeleteAll;

                                WhseRequest.SetRange("Source Type", DATABASE::"Service Line");
                                WhseRequest.SetRange("Source Subtype", "Document Type");
                                WhseRequest.SetRange("Source No.", "No.");
                                if not WhseRequest.IsEmpty then
                                    WhseRequest.DeleteAll(true);

                                ServOrderAlloc.Reset;
                                ServOrderAlloc.SetCurrentKey("Document Type");
                                ServOrderAlloc.SetRange("Document Type", "Document Type");
                                ServOrderAlloc.SetRange("Document No.", "No.");
                                ServOrderAlloc.SetRange(Posted, false);
                                ServOrderAlloc.DeleteAll;
                                ServAllocMgt.SetServOrderAllocStatus("Service Header");

                                ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                                OnBeforeDeleteServiceHeader("Service Header");

                                Delete;
                                Commit;
                            end;
                        end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
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
        Text000: Label 'Processing Service orders #1##########';
        ServiceOrderItemLine: Record "Service Item Line";
        ServiceOrderLine: Record "Service Line";
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCommentLine: Record "Service Comment Line";
        ItemChargeAssgntService: Record "Item Charge Assignment (Sales)";
        WhseRequest: Record "Warehouse Request";
        ServOrderAlloc: Record "Service Order Allocation";
        ServicePost: Codeunit "Service-Post";
        ReserveServiceLine: Codeunit "Service Line-Reserve";
        ServAllocMgt: Codeunit ServAllocationManagement;
        Window: Dialog;

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
    local procedure OnBeforeServiceHeaderOnAfterGetRecord(var ServiceHeader: Record "Service Header")
    begin
    end;
}

