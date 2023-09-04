codeunit 1173 "Document Attachment Mgmt"
{
    // // Code unit to manage document attachment to records.


    trigger OnRun()
    begin
    end;

    var
        ConfirmManagement: Codeunit "Confirm Management";
        PrintedToAttachmentTxt: Label 'The document has been printed to attachments.';
        NoSaveToPDFReportTxt: Label 'There are no reports which could be saved to PDF for this document.';
        ShowAttachmentsTxt: Label 'Show Attachments';
        DeleteAttachmentsConfirmQst: Label 'Do you want to delete the attachments for this document?';
        RelatedAttachmentsFilterTxt: Label '%1|%2', Comment = '%1 = Source Table ID, %2 = Related Table ID';

    procedure DeleteAttachedDocuments(RecRef: RecordRef)
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        if RecRef.IsTemporary() then
            exit;
        if DocumentAttachment.IsEmpty() then
            exit;

        SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecRef);
        if AttachedDocumentsExist(RecRef) then
            DocumentAttachment.DeleteAll();
    end;

    procedure DeleteAttachedDocumentsWithConfirm(RecRef: RecordRef)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteAttachedDocumentsWithConfirm(RecRef, IsHandled);
        if IsHandled then
            exit;

        if AttachedDocumentsExist(RecRef) then
            if ConfirmManagement.GetResponseOrDefault(DeleteAttachmentsConfirmQst, true) then
                DeleteAttachedDocuments(RecRef);
    end;

    procedure AttachedDocumentsExist(RecRef: RecordRef): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        if RecRef.IsTemporary() then
            exit(false);
        if DocumentAttachment.IsEmpty() then
            exit(false);

        SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecRef);
        exit(not DocumentAttachment.IsEmpty())
    end;

    procedure SetDocumentAttachmentRelatedFiltersForRecRef(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef)
    begin
        SetDocumentAttachmentFiltersForRecRefInternal(DocumentAttachment, RecRef, true);
        OnAfterSetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecRef);
    end;

    procedure SetDocumentAttachmentFiltersForRecRef(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef)
    begin
        SetDocumentAttachmentFiltersForRecRefInternal(DocumentAttachment, RecRef, false);
        OnAfterSetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecRef);
    end;

    internal procedure SetDocumentAttachmentFiltersForRecRefInternal(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef; GetRelatedAttachments: Boolean)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        LineNo: Integer;
        FieldNo: Integer;
        VATRepConfigType: Enum "VAT Report Configuration";
    begin
        if GetRelatedAttachments then
            SetRelatedAttachmentsFilter(RecRef.Number(), DocumentAttachment)
        else
            DocumentAttachment.SetRange("Table ID", RecRef.Number());

        if TableHasNumberFieldPrimayKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            RecNo := FieldRef.Value();
            DocumentAttachment.SetRange("No.", RecNo);
        end;

        if TableHasDocTypePrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            DocType := FieldRef.Value();
            DocumentAttachment.SetRange("Document Type", DocType);
        end;

        if TableHasLineNumberPrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            LineNo := FieldRef.Value();
            DocumentAttachment.SetRange("Line No.", LineNo);
        end;

        if RecRef.Number = Database::"VAT Report Header" then begin
            FieldRef := RecRef.Field(2);
            VATRepConfigType := FieldRef.Value();
            DocumentAttachment.SetRange("VAT Report Config. Code", VATRepConfigType);
        end;

        OnAfterSetDocumentAttachmentFiltersForRecRefInternal(DocumentAttachment, RecRef, GetRelatedAttachments);
    end;

    local procedure SetRelatedAttachmentsFilter(TableNo: Integer; var DocumentAttachment: Record "Document Attachment")
        RelatedTable: Integer;
    begin
        case TableNo of
            Database::"Sales Header":
                RelatedTable := Database::"Sales Line";
            Database::"Sales Invoice Header":
                RelatedTable := Database::"Sales Invoice Line";
            Database::"Sales Cr.Memo Header":
                RelatedTable := Database::"Sales Cr.Memo Line";
            Database::"Purchase Header":
                RelatedTable := Database::"Purchase Line";
            Database::"Purch. Inv. Header":
                RelatedTable := Database::"Purch. Inv. Line";
            Database::"Purch. Cr. Memo Hdr.":
                RelatedTable := Database::"Purch. Cr. Memo Line";
            else
                DocumentAttachment.SetFilter("Table ID", '%1', TableNo);
                exit;
        end;
        DocumentAttachment.SetFilter("Table ID", RelatedAttachmentsFilterTxt, TableNo, RelatedTable);
    end;

    internal procedure IsSalesDocumentFlow(TableNo: Integer): Boolean
    begin
        exit(TableNo in
            [DATABASE::Customer,
            DATABASE::"Sales Header",
            DATABASE::"Sales Line",
            DATABASE::"Sales Invoice Header",
            DATABASE::"Sales Invoice Line",
            DATABASE::"Sales Cr.Memo Header",
            DATABASE::"Sales Cr.Memo Line",
            DATABASE::Item]);
    end;

    internal procedure IsPurchaseDocumentFlow(TableNo: Integer): Boolean
    begin
        exit(TableNo in
            [DATABASE::Vendor,
            DATABASE::"Purchase Header",
            DATABASE::"Purchase Line",
            DATABASE::"Purch. Inv. Header",
            DATABASE::"Purch. Inv. Line",
            DATABASE::"Purch. Cr. Memo Hdr.",
            DATABASE::"Purch. Cr. Memo Line",
            DATABASE::Item]);
    end;

    internal procedure IsFlowFieldsEditable(TableNo: Integer): Boolean
    begin
        exit(not (TableNo in
            [DATABASE::"Sales Header",
            DATABASE::"Sales Line",
            DATABASE::"Purchase Header",
            DATABASE::"Purchase Line",
            DATABASE::"Sales Invoice Header",
            DATABASE::"Sales Cr.Memo Header",
            DATABASE::"Purch. Inv. Header",
            DATABASE::"Purch. Cr. Memo Hdr.",
            DATABASE::"Sales Invoice Line",
            DATABASE::"Sales Cr.Memo Line",
            DATABASE::"Purch. Inv. Line",
            DATABASE::"Purch. Cr. Memo Line"]));
    end;

    internal procedure TableHasNumberFieldPrimayKey(TableNo: Integer; var FieldNo: Integer): Boolean
    var
        Result: Boolean;
    begin
        if TableNo in
            [DATABASE::Customer,
            DATABASE::Vendor,
            DATABASE::Item,
            DATABASE::Employee,
            DATABASE::"Fixed Asset",
            DATABASE::Job,
            DATABASE::Resource,
            DATABASE::"VAT Report Header"]
        then begin
            FieldNo := 1;
            exit(true);
        end;

        if TableNo in
            [DATABASE::"Sales Header",
            DATABASE::"Sales Line",
            DATABASE::"Purchase Header",
            DATABASE::"Purchase Line",
            DATABASE::"Sales Invoice Header",
            DATABASE::"Sales Cr.Memo Header",
            DATABASE::"Purch. Inv. Header",
            DATABASE::"Purch. Cr. Memo Hdr.",
            DATABASE::"Sales Invoice Line",
            DATABASE::"Sales Cr.Memo Line",
            DATABASE::"Purch. Inv. Line",
            DATABASE::"Purch. Cr. Memo Line"]
        then begin
            FieldNo := 3;
            exit(true);
        end;

        Result := false;
        OnAfterTableHasNumberFieldPrimaryKey(TableNo, Result, FieldNo);
        exit(Result);
    end;

    internal procedure TableHasDocTypePrimaryKey(TableNo: Integer; var FieldNo: Integer): Boolean
    var
        Result: Boolean;
    begin
        if TableNo in
            [DATABASE::"Sales Header",
            DATABASE::"Sales Line",
            DATABASE::"Purchase Header",
            DATABASE::"Purchase Line"]
        then begin
            FieldNo := 1;
            exit(true);
        end;

        Result := false;
        OnAfterTableHasDocTypePrimaryKey(TableNo, Result, FieldNo);
        exit(Result);
    end;

    internal procedure TableHasLineNumberPrimaryKey(TableNo: Integer; var FieldNo: Integer): Boolean
    var
        Result: Boolean;
    begin
        if TableNo in
            [DATABASE::"Sales Line",
            DATABASE::"Purchase Line",
            DATABASE::"Sales Invoice Line",
            DATABASE::"Sales Cr.Memo Line",
            DATABASE::"Purch. Inv. Line",
            DATABASE::"Purch. Cr. Memo Line"]
        then begin
            FieldNo := 4;
            exit(true);
        end;

        Result := false;
        OnAfterTableHasLineNumberPrimaryKey(TableNo, Result, FieldNo);
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteCustomer(var Rec: Record Customer; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Cr.Memo Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteSalesCreditMemoHeader(var Rec: Record "Sales Cr.Memo Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Cr.Memo Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteSalesCreditMemoLine(var Rec: Record "Sales Cr.Memo Line"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteSalesInvoiceHeader(var Rec: Record "Sales Invoice Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteSalesInvoiceLine(var Rec: Record "Sales Invoice Line"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeletePurchInvHeader(var Rec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeletePurchInvLine(var Rec: Record "Purch. Inv. Line"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Hdr.", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeletePurchCreditMemoHeader(var Rec: Record "Purch. Cr. Memo Hdr."; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeletePurchCreditMemoLine(var Rec: Record "Purch. Cr. Memo Line"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Order", 'OnBeforeDeleteSalesQuote', '', false, false)]
    local procedure DocAttachFlowFormSalesQuoteToSalesOrder(var QuoteSalesHeader: Record "Sales Header"; var OrderSalesHeader: Record "Sales Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        // SalesHeader - quote
        // SalesOrderHeader - order
        if QuoteSalesHeader."No." = '' then
            exit;

        if QuoteSalesHeader.IsTemporary() then
            exit;

        if OrderSalesHeader."No." = '' then
            exit;

        if OrderSalesHeader.IsTemporary() then
            exit;

        FromRecRef.GetTable(QuoteSalesHeader);

        ToRecRef.GetTable(OrderSalesHeader);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Sales Order to Order", 'OnBeforeInsertSalesOrderHeader', '', false, false)]
    local procedure DocAttachFlowForSalesHeaderFromBlanketOrderToSalesOrder(var SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesHeader: Record "Sales Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        // Invoked when a sales order is created from blanket sales order
        // Need to delete docs that came from customer to sales header and copy docs form blanket sales header
        if SalesOrderHeader."No." = '' then
            exit;

        if SalesOrderHeader.IsTemporary() then
            exit;

        if BlanketOrderSalesHeader."No." = '' then
            exit;

        if BlanketOrderSalesHeader.IsTemporary() then
            exit;

        RecRef.GetTable(SalesOrderHeader);
        DeleteAttachedDocuments(RecRef);

        // Copy docs for sales header from blanket order to sales order
        FromRecRef.GetTable(BlanketOrderSalesHeader);

        ToRecRef.GetTable(SalesOrderHeader);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Sales Order to Order", 'OnAfterInsertSalesOrderLine', '', false, false)]
    local procedure DocAttachFlowForSalesLinesFromBlanketOrderToSalesOrder(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesLine: Record "Sales Line"; BlanketOrderSalesHeader: Record "Sales Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        // Invoked when a sales order line is created from blanket sales order line
        // Need to delete docs that came from item to sale item for sales order line and copy docs from blanket sales order line

        if SalesOrderLine."No." = '' then
            exit;

        if SalesOrderLine.IsTemporary() then
            exit;

        if BlanketOrderSalesLine."No." = '' then
            exit;

        if BlanketOrderSalesLine.IsTemporary() then
            exit;

        RecRef.GetTable(SalesOrderLine);
        DeleteAttachedDocuments(RecRef);

        FromRecRef.GetTable(BlanketOrderSalesLine);

        ToRecRef.GetTable(SalesOrderLine);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Invoice", 'OnBeforeDeletionOfQuote', '', false, false)]
    local procedure DocAttachFlowForSalesHeaderFromSalesQuoteToSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        if SalesHeader."No." = '' then
            exit;

        if SalesHeader.IsTemporary() then
            exit;

        if SalesInvoiceHeader."No." = '' then
            exit;

        if SalesInvoiceHeader.IsTemporary() then
            exit;

        FromRecRef.GetTable(SalesHeader);

        ToRecRef.GetTable(SalesInvoiceHeader);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Invoice", 'OnBeforeInsertSalesInvoiceLine', '', false, false)]
    local procedure DocAttachFlowForSalesLinesFromSalesQuoteToSalesInvoice(SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header"; var SalesInvoiceLine: Record "Sales Line"; SalesInvoiceHeader: Record "Sales Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        // Copying sales line items from sales quote to a sales invoice

        if SalesInvoiceLine."No." = '' then
            exit;

        if SalesInvoiceLine.IsTemporary() then
            exit;

        FromRecRef.GetTable(SalesQuoteLine);
        ToRecRef.GetTable(SalesInvoiceLine);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocAttachFlowForSalesHeaderInsert(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        Customer: Record Customer;
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        // If quote no. is NOT empty that means this sales header came from an existing quote
        // In this case we need to exit out
        if Rec."Quote No." <> '' then
            exit;

        if Rec."No." = '' then
            exit;

        if Rec.IsTemporary() then
            exit;

        if not Customer.Get(Rec."Sell-to Customer No.") then
            exit;

        FromRecRef.GetTable(Customer);
        ToRecRef.GetTable(Rec);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Order", 'OnAfterInsertSalesOrderLine', '', false, false)]
    local procedure DocAttachFlowForSalesQuoteToSalesOrderSalesLines(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        // Copying sales line items from quote to an order

        if SalesOrderLine."No." = '' then
            exit;

        if SalesOrderLine.IsTemporary() then
            exit;

        FromRecRef.GetTable(SalesQuoteLine);
        ToRecRef.GetTable(SalesOrderLine);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer No.', false, false)]
    local procedure DocAttachFlowForSalesHeaderCustomerChg(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; CurrFieldNo: Integer)
    var
        RecRef: RecordRef;
    begin
        if Rec."No." = '' then
            exit;

        if Rec.IsTemporary() then
            exit;

        RecRef.GetTable(Rec);
        if (Rec."Sell-to Customer No." <> xRec."Sell-to Customer No.") and (xRec."Sell-to Customer No." <> '') then
            DeleteAttachedDocumentsWithConfirm(RecRef);

        DocAttachFlowForSalesHeaderInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesHeader', '', false, false)]
    local procedure DocAttachFlowForCopyDocumentSalesHeader(ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header")
    begin
        DocAttachFlowForSalesHeaderCustomerChg(ToSalesHeader, OldSalesHeader, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocAttachFlowForSalesLineInsert(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        if Rec."Line No." = 0 then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec.Type <> Rec.Type::Item then
            exit;

        // Skipping if the parent sales header came from a quote
        if SalesHeader.Get(Rec."Document Type", Rec."Document No.") then
            if SalesHeader."Quote No." <> '' then
                exit;

        if not Item.Get(Rec."No.") then
            exit;

        FromRecRef.GetTable(Item);
        ToRecRef.GetTable(Rec);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure DocAttachFlowForSalesLineItemChg(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; CurrFieldNo: Integer)
    var
        xRecRef: RecordRef;
    begin
        if Rec."Line No." = 0 then
            exit;

        if Rec.IsTemporary() then
            exit;

        xRecRef.GetTable(xRec);
        if (Rec."No." <> xRec."No.") and (xRec."No." <> '') then
            DeleteAttachedDocuments(xRecRef);

        DocAttachFlowForSalesLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeDeleteAfterPosting', '', false, false)]
    local procedure DocAttachForPostedSalesDocs(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDocAttachForPostedSalesDocs(SalesHeader, SalesInvoiceHeader, SalesCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        // Triggered when a posted sales cr. memo / posted sales invoice is created
        if SalesHeader.IsTemporary() then
            exit;

        if SalesInvoiceHeader.IsTemporary() then
            exit;

        if SalesCrMemoHeader.IsTemporary() then
            exit;

        FromRecRef.GetTable(SalesHeader);

        if SalesInvoiceHeader."No." <> '' then
            ToRecRef.GetTable(SalesInvoiceHeader);

        if SalesCrMemoHeader."No." <> '' then
            ToRecRef.GetTable(SalesCrMemoHeader);

        CopyAttachmentsForPostedDocs(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforeDeleteAfterPosting', '', false, false)]
    local procedure DocAttachForPostedPurchaseDocs(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDocAttachForPostedPurchaseDocs(PurchaseHeader, PurchInvHeader, PurchCrMemoHdr, IsHandled);
        if IsHandled then
            exit;

        // Triggered when a posted purchase cr. memo / posted purchase invoice is created
        if PurchaseHeader.IsTemporary() then
            exit;

        if PurchInvHeader.IsTemporary() then
            exit;

        if PurchCrMemoHdr.IsTemporary() then
            exit;

        FromRecRef.GetTable(PurchaseHeader);

        if PurchInvHeader."No." <> '' then
            ToRecRef.GetTable(PurchInvHeader);

        if PurchCrMemoHdr."No." <> '' then
            ToRecRef.GetTable(PurchCrMemoHdr);

        if ToRecRef.Number > 0 then
            CopyAttachmentsForPostedDocs(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteVendor(var Rec: Record Vendor; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeletePurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeletePurchaseLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocAttachFlowForPurchaseHeaderInsert(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        Vendor: Record Vendor;
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        // If quote no. is NOT empty that means this purchase header came from an existing quote
        // In this case we need to exit out
        if Rec."Quote No." <> '' then
            exit;

        if Rec."No." = '' then
            exit;

        if Rec.IsTemporary() then
            exit;

        if not Vendor.Get(Rec."Buy-from Vendor No.") then
            exit;

        FromRecRef.GetTable(Vendor);
        ToRecRef.GetTable(Rec);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Buy-from Vendor No.', false, false)]
    local procedure DocAttachFlowForPurchaseHeaderVendorChange(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    var
        RecRef: RecordRef;
    begin
        if Rec."No." = '' then
            exit;

        if Rec.IsTemporary() then
            exit;

        RecRef.GetTable(Rec);
        if (Rec."Buy-from Vendor No." <> xRec."Buy-from Vendor No.") and (xRec."Buy-from Vendor No." <> '') then
            DeleteAttachedDocumentsWithConfirm(RecRef);

        DocAttachFlowForPurchaseHeaderInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPurchaseHeader', '', false, false)]
    local procedure DocAttachFlowForCopyDocumentPurchHeader(ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header")
    begin
        DocAttachFlowForPurchaseHeaderVendorChange(ToPurchaseHeader, OldPurchaseHeader, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocAttachFlowForPurchaseLineInsert(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    var
        Item: Record Item;
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        if Rec."Line No." = 0 then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec.Type <> Rec.Type::Item then
            exit;

        if not Item.Get(Rec."No.") then
            exit;

        FromRecRef.GetTable(Item);
        ToRecRef.GetTable(Rec);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure DocAttachFlowForPurchaseLineItemChg(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    var
        xRecRef: RecordRef;
    begin
        if Rec."Line No." = 0 then
            exit;

        if Rec.IsTemporary() then
            exit;

        xRecRef.GetTable(xRec);
        if (Rec."No." <> xRec."No.") and (xRec."No." <> '') then
            DeleteAttachedDocuments(xRecRef);

        DocAttachFlowForPurchaseLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Quote to Order", 'OnBeforeDeletePurchQuote', '', false, false)]
    local procedure DocAttachFlowForPurchQuoteToPurchOrder(var QuotePurchHeader: Record "Purchase Header"; var OrderPurchHeader: Record "Purchase Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        // SalesHeader - quote
        // SalesOrderHeader - order
        if QuotePurchHeader."No." = '' then
            exit;

        if QuotePurchHeader.IsTemporary() then
            exit;

        if OrderPurchHeader."No." = '' then
            exit;

        if OrderPurchHeader.IsTemporary() then
            exit;

        FromRecRef.GetTable(QuotePurchHeader);

        ToRecRef.GetTable(OrderPurchHeader);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Quote to Order", 'OnAfterInsertPurchOrderLine', '', false, false)]
    local procedure DocAttachFlowForPurchQuoteToPurchOrderLines(var PurchaseQuoteLine: Record "Purchase Line"; var PurchaseOrderLine: Record "Purchase Line")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        // Copying sales line items from quote to an order

        if PurchaseOrderLine."No." = '' then
            exit;

        if PurchaseOrderLine.IsTemporary() then
            exit;

        FromRecRef.GetTable(PurchaseQuoteLine);
        ToRecRef.GetTable(PurchaseOrderLine);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Purch. Order to Order", 'OnBeforePurchOrderHeaderModify', '', false, false)]
    local procedure DocAttachFlowForBlanketPurchaseHeader(var PurchOrderHeader: Record "Purchase Header"; BlanketOrderPurchHeader: Record "Purchase Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        // Invoked when a sales order is created from blanket sales order
        // Need to delete docs that came from customer to sales header and copy docs form blanket sales header
        if PurchOrderHeader."No." = '' then
            exit;

        if PurchOrderHeader.IsTemporary() then
            exit;

        if BlanketOrderPurchHeader."No." = '' then
            exit;

        if BlanketOrderPurchHeader.IsTemporary() then
            exit;

        RecRef.GetTable(PurchOrderHeader);
        DeleteAttachedDocuments(RecRef);

        // Copy docs for sales header from blanket order to sales order
        FromRecRef.GetTable(BlanketOrderPurchHeader);

        ToRecRef.GetTable(PurchOrderHeader);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Purch. Order to Order", 'OnBeforeInsertPurchOrderLine', '', false, false)]
    local procedure DocAttachFlowForBlanketPurchaseLine(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; BlanketOrderPurchLine: Record "Purchase Line"; BlanketOrderPurchHeader: Record "Purchase Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        // Invoked when a purch order line is created from blanket purch order line
        // Need to delete docs that came from item to purch item for purch order line and copy docs from blanket purch order line

        if PurchOrderLine."No." = '' then
            exit;

        if PurchOrderLine.IsTemporary() then
            exit;

        if BlanketOrderPurchLine."No." = '' then
            exit;

        if BlanketOrderPurchLine.IsTemporary() then
            exit;

        RecRef.GetTable(PurchOrderLine);
        DeleteAttachedDocuments(RecRef);

        FromRecRef.GetTable(BlanketOrderPurchLine);

        ToRecRef.GetTable(PurchOrderLine);

        CopyAttachments(FromRecRef, ToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteItem(var Rec: Record Item; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Resource", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteResource(var Rec: Record Resource; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteJob(var Rec: Record Job; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Employee", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteEmployee(var Rec: Record Employee; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteFixedAsset(var Rec: Record "Fixed Asset"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        DeleteAttachedDocuments(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameCustomer(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    var
        MoveFromRecRef: RecordRef;
        MoveToRecRef: RecordRef;
    begin
        // Moves attached docs when an Customer record is renamed [When No. is changed] from old to new rec
        MoveFromRecRef.GetTable(xRec);
        MoveToRecRef.GetTable(Rec);

        MoveAttachmentsWithinSameRecordType(MoveFromRecRef, MoveToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameVendor(var Rec: Record Vendor; var xRec: Record Vendor; RunTrigger: Boolean)
    var
        MoveFromRecRef: RecordRef;
        MoveToRecRef: RecordRef;
    begin
        // Moves attached docs when an Vendor record is renamed [When No. is changed] from old to new rec
        MoveFromRecRef.GetTable(xRec);
        MoveToRecRef.GetTable(Rec);

        MoveAttachmentsWithinSameRecordType(MoveFromRecRef, MoveToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameItem(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    var
        MoveFromRecRef: RecordRef;
        MoveToRecRef: RecordRef;
    begin
        // Moves attached docs when an Item record is renamed [When item no. is changed] from old to new rec
        MoveFromRecRef.GetTable(xRec);
        MoveToRecRef.GetTable(Rec);

        MoveAttachmentsWithinSameRecordType(MoveFromRecRef, MoveToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Employee", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameEmployee(var Rec: Record Employee; var xRec: Record Employee; RunTrigger: Boolean)
    var
        MoveFromRecRef: RecordRef;
        MoveToRecRef: RecordRef;
    begin
        // Moves attached docs when an Employee record is renamed [When No. is changed] from old to new rec
        MoveFromRecRef.GetTable(xRec);
        MoveToRecRef.GetTable(Rec);

        MoveAttachmentsWithinSameRecordType(MoveFromRecRef, MoveToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameFixedAsset(var Rec: Record "Fixed Asset"; var xRec: Record "Fixed Asset"; RunTrigger: Boolean)
    var
        MoveFromRecRef: RecordRef;
        MoveToRecRef: RecordRef;
    begin
        // Moves attached docs when an Fixed Asset record is renamed [When No. is changed] from old to new rec
        MoveFromRecRef.GetTable(xRec);
        MoveToRecRef.GetTable(Rec);

        MoveAttachmentsWithinSameRecordType(MoveFromRecRef, MoveToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Resource", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameResource(var Rec: Record Resource; var xRec: Record Resource; RunTrigger: Boolean)
    var
        MoveFromRecRef: RecordRef;
        MoveToRecRef: RecordRef;
    begin
        // Moves attached docs when an Resource record is renamed [When No. is changed] from old to new rec
        MoveFromRecRef.GetTable(xRec);
        MoveToRecRef.GetTable(Rec);

        MoveAttachmentsWithinSameRecordType(MoveFromRecRef, MoveToRecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameJob(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean)
    var
        MoveFromRecRef: RecordRef;
        MoveToRecRef: RecordRef;
    begin
        // Moves attached docs when an Job record is renamed [When No. is changed] from old to new rec
        MoveFromRecRef.GetTable(xRec);
        MoveToRecRef.GetTable(Rec);

        MoveAttachmentsWithinSameRecordType(MoveFromRecRef, MoveToRecRef);
    end;

    procedure IsDuplicateFile(TableID: Integer; DocumentNo: Code[20]; RecDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; RecLineNo: Integer; FileName: Text; FileExtension: Text): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", TableID);
        DocumentAttachment.SetRange("No.", DocumentNo);
        DocumentAttachment.SetRange("Document Type", RecDocType);
        DocumentAttachment.SetRange("Line No.", RecLineNo);
        DocumentAttachment.SetRange("File Name", FileName);
        DocumentAttachment.SetRange("File Extension", FileExtension);
        OnIsDuplicateFileOnAfterSetFilters(DocumentAttachment);

        if not DocumentAttachment.IsEmpty() then
            exit(true);

        exit(false);
    end;

    procedure CopyAttachments(FromRec: Variant; ToRec: Variant)
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        FromRecRef.GetTable(FromRec);
        ToRecRef.GetTable(ToRec);
        CopyAttachments(FromRecRef, ToRecRef);
    end;

    procedure CopyAttachments(var FromRecRef: RecordRef; var ToRecRef: RecordRef)
    var
        FromDocumentAttachment: Record "Document Attachment";
        ToDocumentAttachment: Record "Document Attachment";
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        FromDocumentType: Enum "Incoming Document Type";
        FromLineNo: Integer;
        FromNo: Code[20];
        ToNo: Code[20];
        ToDocumentType: Enum "Incoming Document Type";
        ToLineNo: Integer;
    begin
        FromDocumentAttachment.SetRange("Table ID", FromRecRef.Number);
        if FromDocumentAttachment.IsEmpty() then
            exit;
        case FromRecRef.Number() of
            DATABASE::Customer,
            DATABASE::Vendor,
            DATABASE::Item:
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                end;
            DATABASE::"Sales Header",
            DATABASE::"Purchase Header":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromDocumentType := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Document Type", FromDocumentType);
                    FromFieldRef := FromRecRef.Field(3);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                end;
            DATABASE::"Sales Line",
            DATABASE::"Purchase Line":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromDocumentType := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Document Type", FromDocumentType);
                    FromFieldRef := FromRecRef.Field(3);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                    FromFieldRef := FromRecRef.Field(4);
                    FromLineNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Line No.", FromLineNo);
                end
        end;

        case ToRecRef.Number() of
            DATABASE::"Sales Line":
                if FromRecRef.Number() <> DATABASE::"Sales Line" then
                    FromDocumentAttachment.SetRange("Document Flow Sales", true);
            DATABASE::"Sales Header":
                if FromRecRef.Number() <> DATABASE::"Sales Header" then
                    FromDocumentAttachment.SetRange("Document Flow Sales", true);
            DATABASE::"Purchase Line":
                if FromRecRef.Number() <> DATABASE::"Purchase Line" then
                    FromDocumentAttachment.SetRange("Document Flow Purchase", true);
            DATABASE::"Purchase Header":
                if FromRecRef.Number() <> DATABASE::"Purchase Header" then
                    FromDocumentAttachment.SetRange("Document Flow Purchase", true);
        end;

        if FromDocumentAttachment.FindSet() then begin
            ToFieldRef := ToRecRef.Field(3);
            ToNo := ToFieldRef.Value();

            case ToRecRef.Number() of
                Database::"Sales Header",
                Database::"Purchase Header":
                    begin
                        ToFieldRef := ToRecRef.Field(1);
                        ToDocumentType := ToFieldRef.Value();
                    end;
                Database::"Sales Line",
                Database::"Purchase Line":
                    begin
                        ToFieldRef := ToRecRef.Field(1);
                        ToDocumentType := ToFieldRef.Value();

                        ToFieldRef := ToRecRef.Field(4);
                        ToLineNo := ToFieldRef.Value();
                    end;
            end;

            repeat
                if not SkipDuplicateToDocumentAttachmentIDOnCopyFromOrderToInvoice(ToRecRef, FromDocumentAttachment, FromDocumentType, ToDocumentType, ToNo, ToLineNo) then begin
                    Clear(ToDocumentAttachment);
                    ToDocumentAttachment.Init();
                    ToDocumentAttachment.TransferFields(FromDocumentAttachment);

                    ToDocumentAttachment.Validate("Table ID", ToRecRef.Number);
                    ToDocumentAttachment.Validate("No.", ToNo);

                    case ToRecRef.Number() of
                        DATABASE::"Sales Header",
                        DATABASE::"Purchase Header":
                            ToDocumentAttachment.Validate("Document Type", ToDocumentType);
                        DATABASE::"Sales Line",
                        DATABASE::"Purchase Line":
                            begin
                                ToDocumentAttachment.Validate("Document Type", ToDocumentType);
                                ToDocumentAttachment.Validate("Line No.", ToLineNo);
                            end;
                    end;

                    if not ToDocumentAttachment.Insert(true) then;

                    ToDocumentAttachment."Attached Date" := FromDocumentAttachment."Attached Date";
                    ToDocumentAttachment.Modify();
                end;

            until FromDocumentAttachment.Next() = 0;
        end;

        // Copies attachments for header and then calls CopyAttachmentsForPostedDocsLines to copy attachments for lines.
    end;

    local procedure SkipDuplicateToDocumentAttachmentIDOnCopyFromOrderToInvoice(var ToRecordRef: RecordRef; FromDocumentAttachment: Record "Document Attachment"; FromDocumentType: Enum "Incoming Document Type"; ToDocumentType: Enum "Incoming Document Type"; ToNo: Code[20]; ToLineNo: Integer): Boolean;
    var
        ToDocumentAttachment: Record "Document Attachment";
    begin
        if (FromDocumentType <> FromDocumentType::Order) or (ToDocumentType <> ToDocumentType::Invoice) then
            exit(false);

        case ToRecordRef.Number() of
            Database::"Sales Header",
            Database::"Purchase Header":
                begin
                    ToDocumentAttachment.SetRange("Table ID", ToRecordRef.Number());
                    ToDocumentAttachment.SetRange("Document Type", ToDocumentType);
                    ToDocumentAttachment.SetRange("No.", ToNo);
                    ToDocumentAttachment.SetRange(ID, FromDocumentAttachment.ID);
                    if not ToDocumentAttachment.IsEmpty() then
                        exit(true);
                end;
            Database::"Sales Line",
            Database::"Purchase Line":
                begin
                    ToDocumentAttachment.SetRange("Table ID", ToRecordRef.Number());
                    ToDocumentAttachment.SetRange("Document Type", ToDocumentType);
                    ToDocumentAttachment.SetRange("No.", ToNo);
                    ToDocumentAttachment.SetRange("Line No.", ToLineNo);
                    ToDocumentAttachment.SetRange(ID, FromDocumentAttachment.ID);
                    if not ToDocumentAttachment.IsEmpty() then
                        exit(true);
                end;
            else
                exit(false);
        end;

        exit(false);
    end;

    procedure CopyAttachmentsForPostedDocs(var FromRecRef: RecordRef; var ToRecRef: RecordRef)
    var
        FromDocumentAttachment: Record "Document Attachment";
        ToDocumentAttachment: Record "Document Attachment";
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        FromDocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        FromNo: Code[20];
        ToNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyAttachmentsForPostedDocsLines(FromRecRef, ToRecRef, IsHandled);
        if IsHandled then
            exit;

        FromDocumentAttachment.SetRange("Table ID", FromRecRef.Number);

        FromFieldRef := FromRecRef.Field(1);
        FromDocumentType := FromFieldRef.Value();
        FromDocumentAttachment.SetRange("Document Type", FromDocumentType);

        FromFieldRef := FromRecRef.Field(3);
        FromNo := FromFieldRef.Value();
        FromDocumentAttachment.SetRange("No.", FromNo);

        // Find any attached docs for headers (sales / purch)
        if FromDocumentAttachment.FindSet() then
            repeat
                Clear(ToDocumentAttachment);
                ToDocumentAttachment.Init();
                ToDocumentAttachment.TransferFields(FromDocumentAttachment);
                ToDocumentAttachment.Validate("Table ID", ToRecRef.Number);

                ToFieldRef := ToRecRef.Field(3);
                ToNo := ToFieldRef.Value();
                ToDocumentAttachment.Validate("No.", ToNo);
                Clear(ToDocumentAttachment."Document Type");
                OnCopyAttachmentsForPostedDocsOnBeforeToDocumentAttachmentInsert(FromDocumentAttachment, ToDocumentAttachment);
                ToDocumentAttachment.Insert(true);
                OnCopyAttachmentsForPostedDocsOnAfterToDocumentAttachmentInsert(FromDocumentAttachment, ToDocumentAttachment);
            until FromDocumentAttachment.Next() = 0;

        CopyAttachmentsForPostedDocsLines(FromRecRef, ToRecRef);
    end;

    procedure CopyAttachmentsForPostedDocsLines(var FromRecRef: RecordRef; var ToRecRef: RecordRef)
    var
        FromDocumentAttachmentLines: Record "Document Attachment";
        ToDocumentAttachmentLines: Record "Document Attachment";
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        FromDocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        FromNo: Code[20];
        ToNo: Code[20];
    begin
        FromFieldRef := FromRecRef.Field(3);
        FromNo := FromFieldRef.Value();
        FromDocumentAttachmentLines.Reset();

        FromFieldRef := FromRecRef.Field(1);
        FromDocumentType := FromFieldRef.Value();
        FromDocumentAttachmentLines.SetRange("Document Type", FromDocumentType);

        ToFieldRef := ToRecRef.Field(3);
        ToNo := ToFieldRef.Value();

        case FromRecRef.Number() of
            DATABASE::"Sales Header":
                FromDocumentAttachmentLines.SetRange("Table ID", DATABASE::"Sales Line");
            DATABASE::"Purchase Header":
                FromDocumentAttachmentLines.SetRange("Table ID", DATABASE::"Purchase Line");
        end;
        FromDocumentAttachmentLines.SetRange("No.", FromNo);
        FromDocumentAttachmentLines.SetRange("Document Type", FromDocumentType);

        if FromDocumentAttachmentLines.FindSet() then
            repeat
                ToDocumentAttachmentLines.TransferFields(FromDocumentAttachmentLines);
                case ToRecRef.Number of
                    DATABASE::"Sales Invoice Header":
                        ToDocumentAttachmentLines.Validate("Table ID", DATABASE::"Sales Invoice Line");
                    DATABASE::"Sales Cr.Memo Header":
                        ToDocumentAttachmentLines.Validate("Table ID", DATABASE::"Sales Cr.Memo Line");
                    DATABASE::"Purch. Inv. Header":
                        ToDocumentAttachmentLines.Validate("Table ID", DATABASE::"Purch. Inv. Line");
                    DATABASE::"Purch. Cr. Memo Hdr.":
                        ToDocumentAttachmentLines.Validate("Table ID", DATABASE::"Purch. Cr. Memo Line");
                end;

                Clear(ToDocumentAttachmentLines."Document Type");
                ToDocumentAttachmentLines.Validate("No.", ToNo);

                if ToDocumentAttachmentLines.Insert(true) then;
            until FromDocumentAttachmentLines.Next() = 0;
    end;

    procedure MoveAttachmentsWithinSameRecordType(var MoveFromRecRef: RecordRef; var MoveToRecRef: RecordRef)
    var
        DocumentAttachmentFound: Record "Document Attachment";
        DocumentAttachmentToCreate: Record "Document Attachment";
        MoveFromFieldRef: FieldRef;
        MoveToFieldRef: FieldRef;
        MoveFromRecNo: Code[20];
        MoveToRecNo: Code[20];
    begin
        // Moves attachments from one record to another for same type
        if MoveFromRecRef.Number() <> MoveToRecRef.Number() then
            exit;
        if MoveFromRecRef.IsTemporary() or MoveToRecRef.IsTemporary() then
            exit;

        DocumentAttachmentFound.SetRange("Table ID", MoveFromRecRef.Number);
        case MoveFromRecRef.Number of
            DATABASE::Customer,
            DATABASE::Vendor,
            DATABASE::Job,
            DATABASE::Employee,
            DATABASE::"Fixed Asset",
            DATABASE::Resource,
            DATABASE::Item:
                begin
                    MoveFromFieldRef := MoveFromRecRef.Field(1);
                    MoveFromRecNo := MoveFromFieldRef.Value;
                    MoveToFieldRef := MoveToRecRef.Field(1);
                    MoveToRecNo := MoveToFieldRef.Value;
                    DocumentAttachmentFound.SetRange("No.", MoveFromRecNo);
                end;
        end;

        // Find any attached docs to be moved
        if DocumentAttachmentFound.IsEmpty() then
            exit;

        // Create a copy of all found attachments with new number [MoveToRecNo]
        // Need to do this because MODIFY does not support renaming keys for a record.
        if DocumentAttachmentFound.FindSet() then
            repeat
                Clear(DocumentAttachmentToCreate);
                DocumentAttachmentToCreate.Init();
                DocumentAttachmentToCreate.TransferFields(DocumentAttachmentFound);
                DocumentAttachmentToCreate.Validate("No.", MoveToRecNo);
                DocumentAttachmentToCreate.Insert(true);
            until DocumentAttachmentFound.Next() = 0;

        // Delete orphan attachments
        DocumentAttachmentFound.DeleteAll(true);
    end;

    procedure ShowNotification(Variant: Variant; NumberOfReportsAttached: Integer; ShowAction: Boolean)
    begin
        if NumberOfReportsAttached > 0 then
            ShowDocPrintedToAttachmentNotification(Variant, ShowAction)
        else
            ShowNotFoundPrintableReportsNotification(Variant);
    end;

    procedure ShowDocPrintedToAttachmentNotification(Variant: Variant; ShowAction: Boolean)
    var
        DocumentAttachment: Record "Document Attachment";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        DocumentAttachment.InitFieldsFromRecRef(RecRef);
        Notification.Id := GetNotificationId();
        Notification.Message := PrintedToAttachmentTxt;
        if ShowAction then
            Notification.AddAction(ShowAttachmentsTxt, Codeunit::"Document Attachment Mgmt", 'ShowDocumentAttachments');
        Notification.SetData(DocumentAttachment.FieldName("Table ID"), Format(DocumentAttachment."Table ID"));
        Notification.SetData(DocumentAttachment.FieldName("Document Type"), Format(DocumentAttachment."Document Type"));
        Notification.SetData(DocumentAttachment.FieldName("No."), Format(DocumentAttachment."No."));

        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          Notification, RecRef.RecordId(), GetNotificationId());
    end;

    procedure ShowNotFoundPrintableReportsNotification(Variant: Variant)
    var
        DocumentAttachment: Record "Document Attachment";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        DocumentAttachment.InitFieldsFromRecRef(RecRef);
        Notification.Id := GetNoPritableReportsNotificationId();
        Notification.Message := NoSaveToPDFReportTxt;

        NotificationLifecycleMgt.SendNotification(Notification, RecRef.RecordId());
    end;

    local procedure GetNotificationId(): Guid;
    begin
        exit('7D722415-F630-4ED5-B876-0372C1360C9F');
    end;

    local procedure GetNoPritableReportsNotificationId(): Guid;
    begin
        exit('2E0AD887-8F86-4AD4-ADE9-846002434BFA');
    end;

    PROCEDURE ShowDocumentAttachments(Notification: Notification);
    VAR
        DocumentAttachment: Record "Document Attachment";
        TableId: Integer;
        DocumentNo: Code[20];
    BEGIN
        Evaluate(TableId, Notification.GetData(DocumentAttachment.FieldName("Table ID")));
        Evaluate(DocumentAttachment."Document Type", Notification.GetData(DocumentAttachment.FieldName("Document Type")));
        Evaluate(DocumentNo, Notification.GetData(DocumentAttachment.FieldName("No.")));

        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type");
        DocumentAttachment.SetRange("No.", DocumentNo);
        Page.RunModal(Page::"Document Attachment Details", DocumentAttachment);
    END;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDocumentAttachmentFiltersForRecRef(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyAttachmentsForPostedDocsLines(var FromRecRef: RecordRef; var ToRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAttachedDocumentsWithConfirm(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDocAttachForPostedPurchaseDocs(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDocAttachForPostedSalesDocs(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyAttachmentsForPostedDocsOnBeforeToDocumentAttachmentInsert(var FromDocumentAttachment: Record "Document Attachment"; var ToDocumentAttachment: Record "Document Attachment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyAttachmentsForPostedDocsOnAfterToDocumentAttachmentInsert(var FromDocumentAttachment: Record "Document Attachment"; var ToDocumentAttachment: Record "Document Attachment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsDuplicateFileOnAfterSetFilters(var DocumentAttachment: Record "Document Attachment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTableHasDocTypePrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTableHasLineNumberPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDocumentAttachmentFiltersForRecRefInternal(var DocumentAttachment: Record "Document Attachment"; RecordRef: RecordRef; GetRelatedAttachments: Boolean)
    begin
    end;
}

