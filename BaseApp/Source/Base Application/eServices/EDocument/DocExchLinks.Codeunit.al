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
        NewStatus := MapDocExchStatusToSalesCMStatus(
            DocExchServiceMgt.GetDocumentStatus(SalesCrMemoHeader.RecordId, SalesCrMemoHeader."Document Exchange Identifier", SalesCrMemoHeader."Doc. Exch. Original Identifier"));
        if NewStatus <> SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service" then begin
            SalesCrMemoHeader.Validate(SalesCrMemoHeader."Document Exchange Status", NewStatus);
            SalesCrMemoHeader.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchInvoiceStatus(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        NewStatus: Enum "Sales Document Exchange Status";
    begin
        NewStatus := MapDocExchStatusToSalesInvStatus(
            DocExchServiceMgt.GetDocumentStatus(SalesInvoiceHeader.RecordId, SalesInvoiceHeader."Document Exchange Identifier", SalesInvoiceHeader."Doc. Exch. Original Identifier"));
        if NewStatus <> SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service" then begin
            SalesInvoiceHeader.Validate(SalesInvoiceHeader."Document Exchange Status", NewStatus);
            SalesInvoiceHeader.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchServiceInvoiceStatus(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        NewStatus: Enum "Service Document Exchange Status";
    begin
        NewStatus := MapDocExchStatusToServiceInvStatus(
            DocExchServiceMgt.GetDocumentStatus(ServiceInvoiceHeader.RecordId, ServiceInvoiceHeader."Document Exchange Identifier", ServiceInvoiceHeader."Doc. Exch. Original Identifier"));
        if NewStatus <> ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service" then begin
            ServiceInvoiceHeader.Validate(ServiceInvoiceHeader."Document Exchange Status", NewStatus);
            ServiceInvoiceHeader.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchServiceCrMemoStatus(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        NewStatus: Enum "Service Document Exchange Status";
    begin
        NewStatus := MapDocExchStatusToServiceCMStatus(
            DocExchServiceMgt.GetDocumentStatus(ServiceCrMemoHeader.RecordId, ServiceCrMemoHeader."Document Exchange Identifier", ServiceCrMemoHeader."Doc. Exch. Original Identifier"));
        if NewStatus <> ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service" then begin
            ServiceCrMemoHeader.Validate(ServiceCrMemoHeader."Document Exchange Status", NewStatus);
            ServiceCrMemoHeader.Modify(true);
        end;
    end;

    local procedure SetInvoiceDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        DocRecRef.SetTable(SalesInvoiceHeader);
        SalesInvoiceHeader.Validate("Document Exchange Identifier",
          CopyStr(DocIdentifier, 1, MaxStrLen(SalesInvoiceHeader."Document Exchange Identifier")));
        SalesInvoiceHeader.Validate("Doc. Exch. Original Identifier",
          CopyStr(DocOriginalIdentifier, 1, MaxStrLen(SalesInvoiceHeader."Doc. Exch. Original Identifier")));
        SalesInvoiceHeader.Validate("Document Exchange Status", SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        SalesInvoiceHeader.Modify(true);
    end;

    local procedure SetCrMemoDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        DocRecRef.SetTable(SalesCrMemoHeader);
        SalesCrMemoHeader.Validate("Document Exchange Identifier",
          CopyStr(DocIdentifier, 1, MaxStrLen(SalesCrMemoHeader."Document Exchange Identifier")));
        SalesCrMemoHeader.Validate("Doc. Exch. Original Identifier",
          CopyStr(DocOriginalIdentifier, 1, MaxStrLen(SalesCrMemoHeader."Doc. Exch. Original Identifier")));
        SalesCrMemoHeader.Validate("Document Exchange Status", SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        SalesCrMemoHeader.Modify(true);
    end;

    local procedure SetServiceInvoiceDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        DocRecRef.SetTable(ServiceInvoiceHeader);
        ServiceInvoiceHeader.Validate("Document Exchange Identifier",
          CopyStr(DocIdentifier, 1, MaxStrLen(ServiceInvoiceHeader."Document Exchange Identifier")));
        ServiceInvoiceHeader.Validate("Doc. Exch. Original Identifier",
          CopyStr(DocOriginalIdentifier, 1, MaxStrLen(ServiceInvoiceHeader."Doc. Exch. Original Identifier")));
        ServiceInvoiceHeader.Validate("Document Exchange Status", ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        ServiceInvoiceHeader.Modify(true);
    end;

    local procedure SetServiceCrMemoDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        DocRecRef.SetTable(ServiceCrMemoHeader);
        ServiceCrMemoHeader.Validate("Document Exchange Identifier",
          CopyStr(DocIdentifier, 1, MaxStrLen(ServiceCrMemoHeader."Document Exchange Identifier")));
        ServiceCrMemoHeader.Validate("Doc. Exch. Original Identifier",
          CopyStr(DocOriginalIdentifier, 1, MaxStrLen(ServiceCrMemoHeader."Doc. Exch. Original Identifier")));
        ServiceCrMemoHeader.Validate("Document Exchange Status", ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        ServiceCrMemoHeader.Modify(true);
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

