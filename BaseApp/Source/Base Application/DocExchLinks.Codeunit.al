codeunit 1411 "Doc. Exch. Links"
{
    Permissions = TableData "Sales Invoice Header" = m,
                  TableData "Sales Cr.Memo Header" = m;

    trigger OnRun()
    begin
    end;

    var
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";

    procedure UpdateDocumentRecord(DocRecRef: RecordRef; DocIdentifier: Text; DocOrigIdentifier: Text)
    begin
        DocRecRef.Find;
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
        NewStatus: Option;
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
        NewStatus: Option;
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
        NewStatus: Option;
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
        NewStatus: Option;
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

    local procedure MapDocExchStatusToSalesInvStatus(DocExchStatus: Text): Integer
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit(SalesInvoiceHeader."Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit(SalesInvoiceHeader."Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit(SalesInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit(SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    local procedure MapDocExchStatusToSalesCMStatus(DocExchStatus: Text): Integer
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit(SalesCrMemoHeader."Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit(SalesCrMemoHeader."Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit(SalesCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit(SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    local procedure MapDocExchStatusToServiceInvStatus(DocExchStatus: Text): Integer
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit(ServiceInvoiceHeader."Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit(ServiceInvoiceHeader."Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit(ServiceInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit(ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    local procedure MapDocExchStatusToServiceCMStatus(DocExchStatus: Text): Integer
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit(ServiceCrMemoHeader."Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit(ServiceCrMemoHeader."Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit(ServiceCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit(ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;
}

