// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Attachment;

using Microsoft.Finance.VAT.Reporting;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Posting;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Utilities;

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
        RelatedAttachmentsFilterTxt: Label '%1|%2', Comment = '%1 = Source Table ID, %2 = Related Table ID', Locked = true;

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
        AttachmentDocumentType: Enum "Attachment Document Type";
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
            AttachmentDocumentType := FieldRef.Value();
            TransformAttachmentDocumentTypeValue(RecRef.Number(), AttachmentDocumentType);
            DocumentAttachment.SetRange("Document Type", AttachmentDocumentType);
        end;

        if TableHasLineNumberPrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            LineNo := FieldRef.Value();
            DocumentAttachment.SetRange("Line No.", LineNo);
        end;

        if TableHasVATReportConfigCodePrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
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
            Database::"Service Header":
                RelatedTable := Database::"Service Line";
            Database::"Service Invoice Header":
                RelatedTable := Database::"Service Invoice Line";
            Database::"Service Cr.Memo Header":
                RelatedTable := Database::"Service Cr.Memo Line";
            Database::"Service Contract Header":
                RelatedTable := Database::"Service Contract Line";
        end;
        OnSetRelatedAttachmentsFilterOnBeforeSetTableIdFilter(TableNo, RelatedTable);
        if RelatedTable = 0 then begin
            DocumentAttachment.SetFilter("Table ID", '%1', TableNo);
            exit;
        end;
        DocumentAttachment.SetFilter("Table ID", RelatedAttachmentsFilterTxt, TableNo, RelatedTable);
    end;

    internal procedure IsSalesDocumentFlow(TableNo: Integer): Boolean
    begin
        exit(TableNo in
            [Database::Customer,
             Database::"Sales Header",
             Database::"Sales Line",
             Database::"Sales Invoice Header",
             Database::"Sales Invoice Line",
             Database::"Sales Cr.Memo Header",
             Database::"Sales Cr.Memo Line",
             Database::Item]);
    end;

    internal procedure IsPurchaseDocumentFlow(TableNo: Integer): Boolean
    begin
        exit(TableNo in
            [Database::Vendor,
             Database::"Purchase Header",
             Database::"Purchase Line",
             Database::"Purch. Inv. Header",
             Database::"Purch. Inv. Line",
             Database::"Purch. Cr. Memo Hdr.",
             Database::"Purch. Cr. Memo Line",
             Database::Item]);
    end;

    internal procedure IsServiceDocumentFlow(TableNo: Integer): Boolean
    begin
        exit(TableNo in
            [Database::Customer,
             Database::"Service Header",
             Database::"Service Line",
             Database::"Service Invoice Header",
             Database::"Service Invoice Line",
             Database::"Service Cr.Memo Header",
             Database::"Service Cr.Memo Line",
             Database::"Service Contract Header",
             Database::"Service Contract Line",
             Database::Item,
             Database::"Service Item"]);
    end;

    internal procedure IsFlowFieldsEditable(TableNo: Integer): Boolean
    begin
        exit(not (TableNo in
            [Database::"Sales Header",
             Database::"Sales Line",
             Database::"Purchase Header",
             Database::"Purchase Line",
             Database::"Sales Invoice Header",
             Database::"Sales Cr.Memo Header",
             Database::"Purch. Inv. Header",
             Database::"Purch. Cr. Memo Hdr.",
             Database::"Sales Invoice Line",
             Database::"Sales Cr.Memo Line",
             Database::"Purch. Inv. Line",
             Database::"Purch. Cr. Memo Line",
             Database::"Service Header",
             Database::"Service Line",
             Database::"Service Invoice Header",
             Database::"Service Invoice Line",
             Database::"Service Cr.Memo Header",
             Database::"Service Cr.Memo Line",
             Database::"Service Contract Header",
             Database::"Service Contract Line"]));
    end;

    internal procedure TableHasNumberFieldPrimayKey(TableNo: Integer; var FieldNo: Integer): Boolean
    var
        Result: Boolean;
    begin
        case TableNo of
            Database::Customer,
            Database::Vendor,
            Database::Item,
            Database::Employee,
            Database::"Fixed Asset",
            Database::Job,
            Database::Resource,
            Database::"VAT Report Header",
            Database::"Service Item",
            Database::"Service Contract Header":
                begin
                    FieldNo := 1;
                    exit(true);
                end;
            Database::"Sales Header",
            Database::"Sales Line",
            Database::"Purchase Header",
            Database::"Purchase Line",
            Database::"Sales Invoice Header",
            Database::"Sales Cr.Memo Header",
            Database::"Purch. Inv. Header",
            Database::"Purch. Cr. Memo Hdr.",
            Database::"Sales Invoice Line",
            Database::"Sales Cr.Memo Line",
            Database::"Purch. Inv. Line",
            Database::"Purch. Cr. Memo Line",
            Database::"Service Header",
            Database::"Service Line",
            Database::"Service Invoice Header",
            Database::"Service Invoice Line",
            Database::"Service Cr.Memo Header",
            Database::"Service Cr.Memo Line":
                begin
                    FieldNo := 3;
                    exit(true);
                end;
            Database::"Service Contract Line":
                begin
                    FieldNo := 2;
                    exit(true);
                end;
        end;

        Result := false;
        OnAfterTableHasNumberFieldPrimaryKey(TableNo, Result, FieldNo);
        exit(Result);
    end;

    internal procedure TableHasDocTypePrimaryKey(TableNo: Integer; var FieldNo: Integer): Boolean
    var
        Result: Boolean;
    begin
        case TableNo of
            Database::"Sales Header",
            Database::"Sales Line",
            Database::"Purchase Header",
            Database::"Purchase Line",
            Database::"Service Header",
            Database::"Service Line",
            Database::"Service Contract Line":
                begin
                    FieldNo := 1;
                    exit(true);
                end;
            Database::"Service Contract Header":
                begin
                    FieldNo := 2;
                    exit(true);
                end;
        end;

        Result := false;
        OnAfterTableHasDocTypePrimaryKey(TableNo, Result, FieldNo);
        exit(Result);
    end;

    internal procedure TableHasLineNumberPrimaryKey(TableNo: Integer; var FieldNo: Integer): Boolean
    var
        Result: Boolean;
    begin
        case TableNo of
            Database::"Sales Line",
            Database::"Purchase Line",
            Database::"Sales Invoice Line",
            Database::"Sales Cr.Memo Line",
            Database::"Purch. Inv. Line",
            Database::"Purch. Cr. Memo Line",
            Database::"Service Line",
            Database::"Service Invoice Line",
            Database::"Service Cr.Memo Line":
                begin
                    FieldNo := 4;
                    exit(true);
                end;
            Database::"Service Contract Line":
                begin
                    FieldNo := 3;
                    exit(true);
                end;
        end;

        Result := false;
        OnAfterTableHasLineNumberPrimaryKey(TableNo, Result, FieldNo);
        exit(Result);
    end;

    internal procedure TableHasVATReportConfigCodePrimaryKey(TableNo: Integer; var FieldNo: Integer): Boolean
    begin
        if TableNo in
            [Database::"VAT Report Header"]
        then begin
            FieldNo := 2;
            exit(true);
        end;

        exit(false);
    end;

    internal procedure TransformAttachmentDocumentTypeValue(TableNo: Integer; var AttachmentDocumentType: Enum "Attachment Document Type")
    begin
        case TableNo of
            Database::"Service Contract Header", Database::"Service Contract Line":
                case AttachmentDocumentType of
                    AttachmentDocumentType::Quote:
                        AttachmentDocumentType := AttachmentDocumentType::"Service Contract Quote";
                    AttachmentDocumentType::Order:
                        AttachmentDocumentType := AttachmentDocumentType::"Service Contract";
                end;
        end;
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
    local procedure DocAttachFlowFromSalesQuoteToSalesOrder(var QuoteSalesHeader: Record "Sales Header"; var OrderSalesHeader: Record "Sales Header")
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
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
        // Need to delete docs that came from customer to sales header and copy docs from blanket sales header
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
        // Copying purchase line items from quote to an order
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
        // Invoked when a purchase order is created from blanket purchase order
        // Need to delete docs that came from vendor to purchase header and copy docs from blanket purchase header
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

        // Copy docs for purchase header from blanket order to purchase order
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

    #region [Service Management event subscribers]
    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceItem(var Rec: Record "Service Item"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameServiceItem(var Rec: Record "Service Item"; var xRec: Record "Service Item"; RunTrigger: Boolean)
    var
        MoveFromRecordRef: RecordRef;
        MoveToRecordRef: RecordRef;
    begin
        // Moves attached docs when an Service Item record is renamed [When service item no. is changed] from old to new rec
        MoveFromRecordRef.GetTable(xRec);
        MoveToRecordRef.GetTable(Rec);

        MoveAttachmentsWithinSameRecordType(MoveFromRecordRef, MoveToRecordRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceHeader(var Rec: Record "Service Header"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceLine(var Rec: Record "Service Line"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceInvoiceHeader(var Rec: Record "Service Invoice Header"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceInvoiceLine(var Rec: Record "Service Invoice Line"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceCreditMemoHeader(var Rec: Record "Service Cr.Memo Header"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceCreditMemoLine(var Rec: Record "Service Cr.Memo Line"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceContractHeader(var Rec: Record "Service Contract Header"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceContractLine(var Rec: Record "Service Contract Line"; RunTrigger: Boolean)
    begin
        DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceItemInsert(var Rec: Record "Service Item"; RunTrigger: Boolean)
    var
        Item: Record Item;
    begin
        if (Rec."No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Item No." = '' then
            exit;
        if not Item.Get(Rec."Item No.") then
            exit;

        CopyAttachments(Item, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterValidateEvent', 'Item No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceItemItemNoChange(var Rec: Record "Service Item"; var xRec: Record "Service Item"; CurrFieldNo: Integer)
    begin
        if (Rec."No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Item No." <> xRec."Item No.") and (xRec."Item No." <> '') then
            DeleteAttachedDocuments(Rec, false);

        DocumentAttachmentFlow_ForServiceItemInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceHeaderInsert(var Rec: Record "Service Header"; RunTrigger: Boolean)
    var
        Customer: Record Customer;
    begin
        if (Rec."No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Customer No." = '' then
            exit;
        if not Customer.Get(Rec."Customer No.") then
            exit;

        CopyAttachments(Customer, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateEvent', 'Customer No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceHeaderCustomerNoChange(var Rec: Record "Service Header"; var xRec: Record "Service Header"; CurrFieldNo: Integer)
    begin
        if (Rec."No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then
            DeleteAttachedDocuments(Rec, true);

        DocumentAttachmentFlow_ForServiceHeaderInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnCreateServHeaderOnAfterCopyFromCustomer', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceHeaderCustomerChange_OnCreateServHeaderOnAfterCopyFromCustomer(var ServiceHeader: Record "Service Header"; ServiceContract: Record "Service Contract Header"; Customer: Record Customer)
    begin
        if (ServiceHeader."No." = '') or IsNullGuid(ServiceHeader.SystemId) then
            exit;

        if ServiceHeader."Customer No." = '' then
            exit;

        if ServiceHeader.IsTemporary() then
            exit;

        DeleteAttachedDocuments(ServiceHeader, false);

        DocumentAttachmentFlow_ForServiceHeaderInsert(ServiceHeader, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnCreateOrGetCreditHeaderOnAfterCopyFromCustomer', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceHeaderCustomerChange_OnCreateOrGetCreditHeaderOnAfterCopyFromCustomer(var ServiceHeader: Record "Service Header"; ServiceContract: Record "Service Contract Header"; Customer: Record Customer)
    begin
        DocumentAttachmentFlow_ForServiceHeaderCustomerChange_OnCreateServHeaderOnAfterCopyFromCustomer(ServiceHeader, ServiceContract, Customer);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceLineInsert(var Rec: Record "Service Line"; RunTrigger: Boolean)
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Service Item No." <> '' then
            if ServiceItem.Get(Rec."Service Item No.") then
                CopyAttachments(ServiceItem, Rec);

        if (Rec.Type = Rec.Type::Item) and (Rec."No." <> '') then
            if Item.Get(Rec."No.") then
                CopyAttachments(Item, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Service Item No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceLineServiceItemNoChange(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Service Item No." <> xRec."Service Item No.") and (xRec."Service Item No." <> '') then
            DeleteAttachedDocuments(xRec, false);

        DocumentAttachmentFlow_ForServiceLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Service Item Line No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceLineServiceItemLineNoChange(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Service Item Line No." <> xRec."Service Item Line No.") and (xRec."Service Item Line No." <> 0) then
            DeleteAttachedDocuments(xRec, false);

        if Rec."Service Item No." <> '' then
            DocumentAttachmentFlow_ForServiceLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceLineNoChange(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."No." <> xRec."No.") and (xRec."No." <> '') then
            DeleteAttachedDocuments(xRec, false);

        DocumentAttachmentFlow_ForServiceLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Quote to Order", 'OnBeforeServiceHeaderOrderModify', '', false, false)]
    local procedure DocumentAttachmentFlow_FromServiceQuoteHeaderToServiceOrderHeader(var ServiceOrderHeader: Record "Service Header"; ServiceQuoteHeader: Record "Service Header")
    begin
        if (ServiceQuoteHeader."No." = '') or IsNullGuid(ServiceQuoteHeader.SystemId) then
            exit;

        if ServiceQuoteHeader.IsTemporary() then
            exit;

        if (ServiceOrderHeader."No." = '') or IsNullGuid(ServiceOrderHeader.SystemId) then
            exit;

        if ServiceOrderHeader.IsTemporary() then
            exit;

        DeleteAttachedDocuments(ServiceOrderHeader, false);

        CopyAttachments(ServiceQuoteHeader, ServiceOrderHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Quote to Order", 'OnAfterServOrderLineInsert', '', false, false)]
    local procedure DocumentAttachmentFlow_FromServiceQuoteLineToServiceOrderLine(var ServiceOrderLine2: Record "Service Line"; ServiceOrderLine: Record "Service Line")
    begin
        // ServiceOrderLine - quote line
        // ServiceOrderLine2 - order line
        if (ServiceOrderLine2."No." = '') or IsNullGuid(ServiceOrderLine2.SystemId) then
            exit;

        if ServiceOrderLine2.IsTemporary() then
            exit;

        DeleteAttachedDocuments(ServiceOrderLine2, false);

        CopyAttachments(ServiceOrderLine, ServiceOrderLine2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnFinalizeOnBeforeDeleteHeaderAndLines', '', false, false)]
    local procedure CopyDocumentAttachmentsToPostedServiceDocument(var ServiceHeader: Record "Service Header")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        FromRecordRef: RecordRef;
        ToRecordRef: RecordRef;
    begin
        // Triggered when a last posted service invoice / cr. memo is created
        if ServiceHeader.IsTemporary() then
            exit;

        if (ServiceHeader."Last Posting No." = '') and (ServiceHeader."No." = '') then
            exit;

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::"Order", ServiceHeader."Document Type"::"Invoice":
                begin
                    if ServiceHeader."Last Posting No." = '' then begin
                        if not ServiceInvoiceHeader.Get(ServiceHeader."No.") then
                            exit;
                    end else
                        if not ServiceInvoiceHeader.Get(ServiceHeader."Last Posting No.") then
                            exit;
                    FromRecordRef.GetTable(ServiceHeader);
                    ToRecordRef.GetTable(ServiceInvoiceHeader);
                    CopyAttachmentsForPostedDocs(FromRecordRef, ToRecordRef);
                end;
            ServiceHeader."Document Type"::"Credit Memo":
                begin
                    if ServiceHeader."Last Posting No." = '' then begin
                        if not ServiceCrMemoHeader.Get(ServiceHeader."No.") then
                            exit;
                    end else
                        if not ServiceCrMemoHeader.Get(ServiceHeader."Last Posting No.") then
                            exit;
                    FromRecordRef.GetTable(ServiceHeader);
                    ToRecordRef.GetTable(ServiceCrMemoHeader);
                    CopyAttachmentsForPostedDocs(FromRecordRef, ToRecordRef);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractHeaderInsert(var Rec: Record "Service Contract Header"; RunTrigger: Boolean)
    var
        Customer: Record Customer;
    begin
        if (Rec."Contract No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Customer No." = '' then
            exit;
        if not Customer.Get(Rec."Customer No.") then
            exit;

        CopyAttachments(Customer, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterValidateEvent', 'Customer No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractHeaderCustomerNoChange(var Rec: Record "Service Contract Header"; var xRec: Record "Service Contract Header"; CurrFieldNo: Integer)
    begin
        if (Rec."Contract No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then
            DeleteAttachedDocuments(Rec, true);

        DocumentAttachmentFlow_ForServiceContractHeaderInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnChangeCustNoOnServContractOnAfterGetCust', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractHeaderCustomerChange_OnChangeCustNoOnServContractOnAfterGetCust(Customer: Record Customer; var ServiceContractHeader: Record "Service Contract Header"; var CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit"; var IsHandled: Boolean)
    begin
        if (ServiceContractHeader."Contract No." = '') or IsNullGuid(ServiceContractHeader.SystemId) then
            exit;

        if ServiceContractHeader.IsTemporary() then
            exit;

        DeleteAttachedDocuments(ServiceContractHeader, true);

        if ServiceContractHeader."Customer No." = '' then
            exit;

        DocumentAttachmentFlow_ForServiceContractHeaderInsert(ServiceContractHeader, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractLineInsert(var Rec: Record "Service Contract Line"; RunTrigger: Boolean)
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Service Item No." <> '' then
            if ServiceItem.Get(Rec."Service Item No.") then
                CopyAttachments(ServiceItem, Rec);

        if Rec."Item No." <> '' then
            if Item.Get(Rec."Item No.") then
                CopyAttachments(Item, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnAfterValidateEvent', 'Service Item No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractLineServiceItemNoChange(var Rec: Record "Service Contract Line"; var xRec: Record "Service Contract Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Service Item No." <> xRec."Service Item No.") and (xRec."Service Item No." <> '') then
            DeleteAttachedDocuments(xRec, false);

        DocumentAttachmentFlow_ForServiceContractLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnAfterValidateEvent', 'Item No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractLineItemNoChange(var Rec: Record "Service Contract Line"; var xRec: Record "Service Contract Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Item No." <> xRec."Item No.") and (xRec."Item No." <> '') then
            DeleteAttachedDocuments(xRec, false);

        DocumentAttachmentFlow_ForServiceContractLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SignServContractDoc", 'OnAfterToServContractHeaderInsert', '', false, false)]
    local procedure DocumentAttachmentFlow_FromServiceContractQuoteHeaderToServiceContractHeader(var ToServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header")
    begin
        if (FromServiceContractHeader."Contract No." = '') or IsNullGuid(FromServiceContractHeader.SystemId) then
            exit;

        if FromServiceContractHeader.IsTemporary() then
            exit;

        if (ToServiceContractHeader."Contract No." = '') or IsNullGuid(ToServiceContractHeader.SystemId) then
            exit;

        if ToServiceContractHeader.IsTemporary() then
            exit;

        DeleteAttachedDocuments(ToServiceContractHeader, false);

        CopyAttachments(FromServiceContractHeader, ToServiceContractHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SignServContractDoc", 'OnAfterToServContractLineInsert', '', false, false)]
    local procedure DocumentAttachmentFlow_FromServiceContractQuoteLineToServiceContractLine(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
        if (ToServiceContractLine."Contract No." = '') or IsNullGuid(ToServiceContractLine.SystemId) then
            exit;

        if ToServiceContractLine.IsTemporary() then
            exit;

        DeleteAttachedDocuments(ToServiceContractLine, false);

        CopyAttachments(FromServiceContractLine, ToServiceContractLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Service Contract Mgt.", 'OnAfterProcessServiceContractLine', '', false, false)]
    local procedure DocumentAttachmentFlow_OnServiceContractLineCopy(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
        DocumentAttachmentFlow_FromServiceContractQuoteLineToServiceContractLine(ToServiceContractLine, FromServiceContractLine);
    end;
    #endregion [Service Management event subscribers]

#if not CLEAN24
    [Obsolete('Replaced with the same procedure with enum instead of option.', '24.0')]
    procedure IsDuplicateFile(TableID: Integer; DocumentNo: Code[20]; RecDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; RecLineNo: Integer; FileName: Text; FileExtension: Text): Boolean
    begin
        exit(IsDuplicateFile(TableID, DocumentNo, Enum::"Attachment Document Type".FromInteger(RecDocType), RecLineNo, FileName, FileExtension));
    end;
#endif

    procedure IsDuplicateFile(TableID: Integer; DocumentNo: Code[20]; AttachmentDocumentType: Enum "Attachment Document Type"; RecLineNo: Integer; FileName: Text; FileExtension: Text): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", TableID);
        DocumentAttachment.SetRange("No.", DocumentNo);
        DocumentAttachment.SetRange("Document Type", AttachmentDocumentType);
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
        ToDocumentAttachment2: Record "Document Attachment";
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        FromAttachmentDocumentType: Enum "Attachment Document Type";
        FromLineNo: Integer;
        FromNo: Code[20];
        ToNo: Code[20];
        ToAttachmentDocumentType: Enum "Attachment Document Type";
        ToLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyAttachments(FromRecRef, ToRecRef, IsHandled);
        if IsHandled then
            exit;

        FromDocumentAttachment.SetRange("Table ID", FromRecRef.Number);
        if FromDocumentAttachment.IsEmpty() then
            exit;
        case FromRecRef.Number() of
            Database::Customer,
            Database::Vendor,
            Database::Item,
            Database::"Service Item":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                end;
            Database::"Sales Header",
            Database::"Purchase Header",
            Database::"Service Header":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromAttachmentDocumentType := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);
                    FromFieldRef := FromRecRef.Field(3);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                end;
            Database::"Sales Line",
            Database::"Purchase Line",
            Database::"Service Line":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromAttachmentDocumentType := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);
                    FromFieldRef := FromRecRef.Field(3);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                    FromFieldRef := FromRecRef.Field(4);
                    FromLineNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Line No.", FromLineNo);
                end;
            Database::"Service Contract Header":
                begin
                    FromFieldRef := FromRecRef.Field(2);
                    FromAttachmentDocumentType := FromFieldRef.Value();
                    TransformAttachmentDocumentTypeValue(FromRecRef.Number(), FromAttachmentDocumentType);
                    FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);
                    FromFieldRef := FromRecRef.Field(1);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                end;
            Database::"Service Contract Line":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromAttachmentDocumentType := FromFieldRef.Value();
                    TransformAttachmentDocumentTypeValue(FromRecRef.Number(), FromAttachmentDocumentType);
                    FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);
                    FromFieldRef := FromRecRef.Field(2);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                    FromFieldRef := FromRecRef.Field(3);
                    FromLineNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Line No.", FromLineNo);
                end;
        end;

        case ToRecRef.Number() of
            Database::"Sales Line":
                if FromRecRef.Number() <> Database::"Sales Line" then
                    FromDocumentAttachment.SetRange("Document Flow Sales", true);
            Database::"Sales Header":
                if FromRecRef.Number() <> Database::"Sales Header" then
                    FromDocumentAttachment.SetRange("Document Flow Sales", true);
            Database::"Purchase Line":
                if FromRecRef.Number() <> Database::"Purchase Line" then
                    FromDocumentAttachment.SetRange("Document Flow Purchase", true);
            Database::"Purchase Header":
                if FromRecRef.Number() <> Database::"Purchase Header" then
                    FromDocumentAttachment.SetRange("Document Flow Purchase", true);
            Database::"Service Line":
                if FromRecRef.Number() <> Database::"Service Line" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
            Database::"Service Header":
                if FromRecRef.Number() <> Database::"Service Header" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
            Database::"Service Contract Line":
                if FromRecRef.Number() <> Database::"Service Contract Line" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
            Database::"Service Contract Header":
                if FromRecRef.Number() <> Database::"Service Contract Header" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
            Database::"Service Item":
                if FromRecRef.Number() <> Database::"Service Item" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
        end;

        if FromDocumentAttachment.FindSet() then begin
            case ToRecRef.Number() of
                Database::"Sales Header",
                Database::"Purchase Header",
                Database::"Service Header":
                    begin
                        ToFieldRef := ToRecRef.Field(1);
                        ToAttachmentDocumentType := ToFieldRef.Value();

                        ToFieldRef := ToRecRef.Field(3);
                        ToNo := ToFieldRef.Value();
                    end;
                Database::"Sales Line",
                Database::"Purchase Line",
                Database::"Service Line":
                    begin
                        ToFieldRef := ToRecRef.Field(1);
                        ToAttachmentDocumentType := ToFieldRef.Value();

                        ToFieldRef := ToRecRef.Field(3);
                        ToNo := ToFieldRef.Value();

                        ToFieldRef := ToRecRef.Field(4);
                        ToLineNo := ToFieldRef.Value();
                    end;
                Database::"Service Contract Header":
                    begin
                        ToFieldRef := ToRecRef.Field(2);
                        ToAttachmentDocumentType := ToFieldRef.Value();
                        TransformAttachmentDocumentTypeValue(ToRecRef.Number(), ToAttachmentDocumentType);

                        ToFieldRef := ToRecRef.Field(1);
                        ToNo := ToFieldRef.Value();
                    end;
                Database::"Service Contract Line":
                    begin
                        ToFieldRef := ToRecRef.Field(1);
                        ToAttachmentDocumentType := ToFieldRef.Value();
                        TransformAttachmentDocumentTypeValue(ToRecRef.Number(), ToAttachmentDocumentType);

                        ToFieldRef := ToRecRef.Field(2);
                        ToNo := ToFieldRef.Value();

                        ToFieldRef := ToRecRef.Field(3);
                        ToLineNo := ToFieldRef.Value();
                    end;
                Database::"Service Item":
                    begin
                        ToFieldRef := ToRecRef.Field(1);
                        ToNo := ToFieldRef.Value();
                    end;
            end;

            repeat
                if not SkipDuplicateToDocumentAttachmentIDOnCopyFromOrderToInvoice(ToRecRef, FromDocumentAttachment, FromAttachmentDocumentType, ToAttachmentDocumentType, ToNo, ToLineNo) then begin
                    Clear(ToDocumentAttachment);
                    ToDocumentAttachment.Init();
                    ToDocumentAttachment.TransferFields(FromDocumentAttachment);

                    ToDocumentAttachment.Validate("Table ID", ToRecRef.Number);
                    ToDocumentAttachment.Validate("No.", ToNo);

                    case ToRecRef.Number() of
                        Database::"Sales Header",
                        Database::"Purchase Header",
                        Database::"Service Header",
                        Database::"Service Contract Header":
                            ToDocumentAttachment.Validate("Document Type", ToAttachmentDocumentType);
                        Database::"Sales Line",
                        Database::"Purchase Line",
                        Database::"Service Line",
                        Database::"Service Contract Line":
                            begin
                                ToDocumentAttachment.Validate("Document Type", ToAttachmentDocumentType);
                                ToDocumentAttachment.Validate("Line No.", ToLineNo);
                            end;
                    end;

                    if not ToDocumentAttachment.Insert(true) then begin
                        ToDocumentAttachment2 := ToDocumentAttachment;
                        ToDocumentAttachment.Find('=');
                        ToDocumentAttachment.TransferFields(ToDocumentAttachment2, false);
                    end;

                    ToDocumentAttachment."Attached Date" := FromDocumentAttachment."Attached Date";
                    ToDocumentAttachment.Modify();
                end;

            until FromDocumentAttachment.Next() = 0;
        end;

        // Copies attachments for header and then calls CopyAttachmentsForPostedDocsLines to copy attachments for lines.
    end;

    local procedure SkipDuplicateToDocumentAttachmentIDOnCopyFromOrderToInvoice(var ToRecordRef: RecordRef; FromDocumentAttachment: Record "Document Attachment"; FromAttachmentDocumentType: Enum "Attachment Document Type"; ToAttachmentDocumentType: Enum "Attachment Document Type"; ToNo: Code[20]; ToLineNo: Integer): Boolean;
    var
        ToDocumentAttachment: Record "Document Attachment";
    begin
        if (FromAttachmentDocumentType <> FromAttachmentDocumentType::Order) or (ToAttachmentDocumentType <> ToAttachmentDocumentType::Invoice) then
            exit(false);

        case ToRecordRef.Number() of
            Database::"Sales Header",
            Database::"Purchase Header",
            Database::"Service Header":
                begin
                    ToDocumentAttachment.SetRange("Table ID", ToRecordRef.Number());
                    ToDocumentAttachment.SetRange("Document Type", ToAttachmentDocumentType);
                    ToDocumentAttachment.SetRange("No.", ToNo);
                    ToDocumentAttachment.SetRange(ID, FromDocumentAttachment.ID);
                    if not ToDocumentAttachment.IsEmpty() then
                        exit(true);
                end;
            Database::"Sales Line",
            Database::"Purchase Line",
            Database::"Service Line":
                begin
                    ToDocumentAttachment.SetRange("Table ID", ToRecordRef.Number());
                    ToDocumentAttachment.SetRange("Document Type", ToAttachmentDocumentType);
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
        FromAttachmentDocumentType: Enum "Attachment Document Type";
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
        FromAttachmentDocumentType := FromFieldRef.Value();
        TransformAttachmentDocumentTypeValue(FromRecRef.Number(), FromAttachmentDocumentType);
        FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);

        FromFieldRef := FromRecRef.Field(3);
        FromNo := FromFieldRef.Value();
        FromDocumentAttachment.SetRange("No.", FromNo);

        // Find any attached docs for headers (sales / purchase / service)
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
        FromAttachmentDocumentType: Enum "Attachment Document Type";
        FromNo: Code[20];
        ToNo: Code[20];
    begin
        FromFieldRef := FromRecRef.Field(3);
        FromNo := FromFieldRef.Value();
        FromDocumentAttachmentLines.Reset();

        FromFieldRef := FromRecRef.Field(1);
        FromAttachmentDocumentType := FromFieldRef.Value();
        TransformAttachmentDocumentTypeValue(FromRecRef.Number(), FromAttachmentDocumentType);
        FromDocumentAttachmentLines.SetRange("Document Type", FromAttachmentDocumentType);

        ToFieldRef := ToRecRef.Field(3);
        ToNo := ToFieldRef.Value();

        case FromRecRef.Number() of
            Database::"Sales Header":
                FromDocumentAttachmentLines.SetRange("Table ID", Database::"Sales Line");
            Database::"Purchase Header":
                FromDocumentAttachmentLines.SetRange("Table ID", Database::"Purchase Line");
            Database::"Service Header":
                FromDocumentAttachmentLines.SetRange("Table ID", Database::"Service Line");
        end;
        FromDocumentAttachmentLines.SetRange("No.", FromNo);
        FromDocumentAttachmentLines.SetRange("Document Type", FromAttachmentDocumentType);

        if FromDocumentAttachmentLines.FindSet() then
            repeat
                ToDocumentAttachmentLines.TransferFields(FromDocumentAttachmentLines);
                case ToRecRef.Number of
                    Database::"Sales Invoice Header":
                        ToDocumentAttachmentLines.Validate("Table ID", Database::"Sales Invoice Line");
                    Database::"Sales Cr.Memo Header":
                        ToDocumentAttachmentLines.Validate("Table ID", Database::"Sales Cr.Memo Line");
                    Database::"Purch. Inv. Header":
                        ToDocumentAttachmentLines.Validate("Table ID", Database::"Purch. Inv. Line");
                    Database::"Purch. Cr. Memo Hdr.":
                        ToDocumentAttachmentLines.Validate("Table ID", Database::"Purch. Cr. Memo Line");
                    Database::"Service Invoice Header":
                        ToDocumentAttachmentLines.Validate("Table ID", Database::"Service Invoice Line");
                    Database::"Service Cr.Memo Header":
                        ToDocumentAttachmentLines.Validate("Table ID", Database::"Service Cr.Memo Line");
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
            Database::Customer,
            Database::Vendor,
            Database::Job,
            Database::Employee,
            Database::"Fixed Asset",
            Database::Resource,
            Database::Item,
            Database::"Service Item":
                begin
                    MoveFromFieldRef := MoveFromRecRef.Field(1);
                    MoveFromRecNo := MoveFromFieldRef.Value();
                    MoveToFieldRef := MoveToRecRef.Field(1);
                    MoveToRecNo := MoveToFieldRef.Value();
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

    procedure ShowDocumentAttachments(Notification: Notification);
    var
        DocumentAttachment: Record "Document Attachment";
        TableId: Integer;
        DocumentNo: Code[20];
    begin
        Evaluate(TableId, Notification.GetData(DocumentAttachment.FieldName("Table ID")));
        Evaluate(DocumentAttachment."Document Type", Notification.GetData(DocumentAttachment.FieldName("Document Type")));
        Evaluate(DocumentNo, Notification.GetData(DocumentAttachment.FieldName("No.")));

        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type");
        DocumentAttachment.SetRange("No.", DocumentNo);
        Page.RunModal(Page::"Document Attachment Details", DocumentAttachment);
    end;

    local procedure DeleteAttachedDocuments(ForVariantRec: Variant; WithConfirm: Boolean)
    var
        ForRecordRef: RecordRef;
    begin
        ForRecordRef.GetTable(ForVariantRec);
        if WithConfirm then
            DeleteAttachedDocumentsWithConfirm(ForRecordRef)
        else
            DeleteAttachedDocuments(ForRecordRef);
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnSetRelatedAttachmentsFilterOnBeforeSetTableIdFilter(TableNo: Integer; var RelatedTable: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyAttachments(var FromRecRef: RecordRef; var ToRecRef: RecordRef; var Handled: Boolean)
    begin
    end;
}

