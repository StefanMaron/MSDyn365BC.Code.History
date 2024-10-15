namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.History;
using Microsoft.Service.History;

codeunit 1411 "Doc. Exch. Links"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;

    trigger OnRun()
    begin
    end;

    var
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";

        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';

    procedure UpdateDocumentRecord(DocRecRef: RecordRef; DocIdentifier: Text; DocOrigIdentifier: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDocumentRecord(DocRecRef, DocIdentifier, DocOrigIdentifier, IsHandled);
        if IsHandled then
            exit;

        DocRecRef.Find();
        case DocRecRef.Number of
            DATABASE::"Sales Invoice Header":
                SetInvoiceDocSent(DocRecRef, DocIdentifier, DocOrigIdentifier);
            DATABASE::"Sales Cr.Memo Header":
                SetCrMemoDocSent(DocRecRef, DocIdentifier, DocOrigIdentifier);
            DATABASE::"Service Invoice Header":
                SetServiceInvoiceDocSent(DocRecRef, DocIdentifier, DocOrigIdentifier);
            DATABASE::"Service Cr.Memo Header":
                SetServiceCrMemoDocSent(DocRecRef, DocIdentifier, DocOrigIdentifier);
            else
                Error(UnSupportedTableTypeErr, DocRecRef.Number);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchCrMemoStatus(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        NewStatus: Enum "Sales Document Exchange Status";
    begin
        with SalesCrMemoHeader do begin
            NewStatus := MapDocExchStatusToSalesCMStatus(
                DocExchServiceMgt.GetDocumentStatus(RecordId, "Document Exchange Identifier", "Doc. Exch. Original Identifier"));
            if NewStatus <> "Document Exchange Status"::"Sent to Document Exchange Service" then begin
                Validate("Document Exchange Status", NewStatus);
                Modify(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchInvoiceStatus(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        NewStatus: Enum "Sales Document Exchange Status";
    begin
        with SalesInvoiceHeader do begin
            NewStatus := MapDocExchStatusToSalesInvStatus(
                DocExchServiceMgt.GetDocumentStatus(RecordId, "Document Exchange Identifier", "Doc. Exch. Original Identifier"));
            if NewStatus <> "Document Exchange Status"::"Sent to Document Exchange Service" then begin
                Validate("Document Exchange Status", NewStatus);
                Modify(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchServiceInvoiceStatus(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        NewStatus: Enum "Service Document Exchange Status";
    begin
        with ServiceInvoiceHeader do begin
            NewStatus := MapDocExchStatusToServiceInvStatus(
                DocExchServiceMgt.GetDocumentStatus(RecordId, "Document Exchange Identifier", "Doc. Exch. Original Identifier"));
            if NewStatus <> "Document Exchange Status"::"Sent to Document Exchange Service" then begin
                Validate("Document Exchange Status", NewStatus);
                Modify(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchServiceCrMemoStatus(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        NewStatus: Enum "Service Document Exchange Status";
    begin
        with ServiceCrMemoHeader do begin
            NewStatus := MapDocExchStatusToServiceCMStatus(
                DocExchServiceMgt.GetDocumentStatus(RecordId, "Document Exchange Identifier", "Doc. Exch. Original Identifier"));
            if NewStatus <> "Document Exchange Status"::"Sent to Document Exchange Service" then begin
                Validate("Document Exchange Status", NewStatus);
                Modify(true);
            end;
        end;
    end;

    local procedure SetInvoiceDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        DocRecRef.SetTable(SalesInvoiceHeader);
        with SalesInvoiceHeader do begin
            Validate("Document Exchange Identifier",
              CopyStr(DocIdentifier, 1, MaxStrLen("Document Exchange Identifier")));
            Validate("Doc. Exch. Original Identifier",
              CopyStr(DocOriginalIdentifier, 1, MaxStrLen("Doc. Exch. Original Identifier")));
            Validate("Document Exchange Status", "Document Exchange Status"::"Sent to Document Exchange Service");
            Modify(true);
        end;
    end;

    local procedure SetCrMemoDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        DocRecRef.SetTable(SalesCrMemoHeader);
        with SalesCrMemoHeader do begin
            Validate("Document Exchange Identifier",
              CopyStr(DocIdentifier, 1, MaxStrLen("Document Exchange Identifier")));
            Validate("Doc. Exch. Original Identifier",
              CopyStr(DocOriginalIdentifier, 1, MaxStrLen("Doc. Exch. Original Identifier")));
            Validate("Document Exchange Status", "Document Exchange Status"::"Sent to Document Exchange Service");
            Modify(true);
        end;
    end;

    local procedure SetServiceInvoiceDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        DocRecRef.SetTable(ServiceInvoiceHeader);
        with ServiceInvoiceHeader do begin
            Validate("Document Exchange Identifier",
              CopyStr(DocIdentifier, 1, MaxStrLen("Document Exchange Identifier")));
            Validate("Doc. Exch. Original Identifier",
              CopyStr(DocOriginalIdentifier, 1, MaxStrLen("Doc. Exch. Original Identifier")));
            Validate("Document Exchange Status", "Document Exchange Status"::"Sent to Document Exchange Service");
            Modify(true);
        end;
    end;

    local procedure SetServiceCrMemoDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        DocRecRef.SetTable(ServiceCrMemoHeader);
        with ServiceCrMemoHeader do begin
            Validate("Document Exchange Identifier",
              CopyStr(DocIdentifier, 1, MaxStrLen("Document Exchange Identifier")));
            Validate("Doc. Exch. Original Identifier",
              CopyStr(DocOriginalIdentifier, 1, MaxStrLen("Doc. Exch. Original Identifier")));
            Validate("Document Exchange Status", "Document Exchange Status"::"Sent to Document Exchange Service");
            Modify(true);
        end;
    end;

    local procedure MapDocExchStatusToSalesInvStatus(DocExchStatus: Text): Enum "Sales Document Exchange Status"
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit("Sales Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit("Sales Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit("Sales Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit("Sales Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    local procedure MapDocExchStatusToSalesCMStatus(DocExchStatus: Text): Enum "Sales Document Exchange Status"
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit("Sales Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit("Sales Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit("Sales Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit("Sales Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    local procedure MapDocExchStatusToServiceInvStatus(DocExchStatus: Text): Enum "Service Document Exchange Status"
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit("Service Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit("Service Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit("Service Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit("Service Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    local procedure MapDocExchStatusToServiceCMStatus(DocExchStatus: Text): Enum "Service Document Exchange Status"
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit("Service Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit("Service Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit("Service Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit("Service Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocumentRecord(DocRecRef: RecordRef; DocIdentifier: Text; DocOrigIdentifier: Text; var IsHandled: Boolean)
    begin
    end;
}

