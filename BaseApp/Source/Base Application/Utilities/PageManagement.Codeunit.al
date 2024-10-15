namespace Microsoft.Utilities;

using Microsoft.Bank.Reconciliation;
using Microsoft.CashFlow.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Journal;
using Microsoft.Inventory.Analysis;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Analysis;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using System.Automation;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

codeunit 700 "Page Management"
{

    trigger OnRun()
    begin
    end;

    var
        DataTypeManagement: Codeunit "Data Type Management";

    procedure PageRun(RecRelatedVariant: Variant): Boolean
    begin
        exit(PageRunAtField(RecRelatedVariant, 0, false));
    end;

    procedure PageRunModal(RecRelatedVariant: Variant): Boolean
    begin
        exit(PageRunAtField(RecRelatedVariant, 0, true));
    end;

    procedure PageRunAtField(RecRelatedVariant: Variant; FieldNumber: Integer; Modal: Boolean): Boolean
    var
        RecRef: RecordRef;
        RecordRefVariant: Variant;
        PageID: Integer;
    begin
        if not GuiAllowed then
            exit(false);

        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecRef) then
            exit(false);

        PageID := GetPageID(RecRef);

        OnPageRunAtFieldOnBeforeRunPage(RecRef, PageID);
        if PageID <> 0 then begin
            RecordRefVariant := RecRef;
            if Modal then
                PAGE.RunModal(PageID, RecordRefVariant, FieldNumber)
            else
                PAGE.Run(PageID, RecordRefVariant, FieldNumber);
            exit(true);
        end;

        exit(false);
    end;

    procedure GetPageID(RecRelatedVariant: Variant): Integer
    var
        RecRef: RecordRef;
        EmptyRecRef: RecordRef;
        PageID: Integer;
    begin
        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecRef) then
            exit;

        EmptyRecRef.Open(RecRef.Number);
        PageID := GetConditionalCardPageID(RecRef);
        // Choose default card only if record exists
        if RecRef.RecordId <> EmptyRecRef.RecordId then
            if PageID = 0 then
                PageID := GetDefaultCardPageID(RecRef.Number);

        if PageID = 0 then
            PageID := GetDefaultLookupPageID(RecRef.Number);

        OnAfterGetPageID(RecRef, PageID);

        exit(PageID);
    end;

    procedure GetDefaultCardPageID(TableID: Integer): Integer
    var
        PageMetadata: Record "Page Metadata";
        LookupPageID: Integer;
    begin
        if TableID = 0 then
            exit(0);

        LookupPageID := GetDefaultLookupPageID(TableID);
        if LookupPageID <> 0 then begin
            PageMetadata.Get(LookupPageID);
            if PageMetadata.CardPageID <> 0 then
                exit(PageMetadata.CardPageID);
        end;
        exit(0);
    end;

    procedure GetDefaultLookupPageID(TableID: Integer): Integer
    var
        TableMetadata: Record "Table Metadata";
        PageID: Integer;
    begin
        if TableID = 0 then
            exit(0);

        PageID := 0;
        OnBeforeGetDefaultLookupPageID(TableID, PageID);
        if PageID <> 0 then
            exit(PageID);

        TableMetadata.Get(TableID);
        exit(TableMetadata.LookupPageID);
    end;

    procedure GetDefaultLookupPageIDByVar(RecRelatedVariant: Variant): Integer
    var
        TableMetadata: Record "Table Metadata";
        RecRef: RecordRef;
        PageID: Integer;
        TableID: Integer;
    begin
        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecRef) then
            exit;

        TableID := RecRef.Number;
        PageID := 0;
        OnBeforeGetDefaultLookupPageIDByVar(TableID, PageID, RecRef);
        if PageID <> 0 then
            exit(PageID);

        TableMetadata.Get(TableID);
        exit(TableMetadata.LookupPageID);
    end;

    procedure GetConditionalCardPageID(RecRef: RecordRef): Integer
    var
        CardPageID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetConditionalCardPageID(RecRef, CardPageID, IsHandled);
        if IsHandled then
            exit(CardPageID);

        case RecRef.Number of
            Database::"Gen. Journal Template":
                exit(PAGE::"General Journal Templates");
            Database::"Company Information":
                exit(PAGE::"Company Information");
            Database::"Sales Header":
                exit(GetSalesHeaderPageID(RecRef));
            Database::"Purchase Header":
                exit(GetPurchaseHeaderPageID(RecRef));
            Database::"Service Header":
                exit(GetServiceHeaderPageID(RecRef));
            Database::"Service Contract Header":
                exit(GetServiceContractHeaderPageID(RecRef));
            Database::"Gen. Journal Batch":
                exit(GetGenJournalBatchPageID(RecRef));
            Database::"Gen. Journal Line":
                exit(GetGenJournalLinePageID(RecRef));
            Database::"User Setup":
                exit(PAGE::"User Setup");
            Database::"General Ledger Setup":
                exit(PAGE::"General Ledger Setup");
            Database::"Sales Header Archive":
                exit(GetSalesHeaderArchivePageID(RecRef));
            Database::"Purchase Header Archive":
                exit(GetPurchaseHeaderArchivePageID(RecRef));
            Database::"Res. Journal Line":
                exit(PAGE::"Resource Journal");
            Database::"Job Journal Line":
                exit(PAGE::"Job Journal");
            Database::"Item Analysis View":
                exit(GetAnalysisViewPageID(RecRef));
            Database::"Purchases & Payables Setup":
                exit(PAGE::"Purchases & Payables Setup");
            Database::"Approval Entry":
                exit(GetApprovalEntryPageID(RecRef));
            Database::"Doc. Exch. Service Setup":
                exit(PAGE::"Doc. Exch. Service Setup");
            Database::"Incoming Documents Setup":
                exit(PAGE::"Incoming Documents Setup");
            Database::"Text-to-Account Mapping":
                exit(PAGE::"Text-to-Account Mapping Wksh.");
            Database::"Cash Flow Setup":
                exit(PAGE::"Cash Flow Setup");
            Database::"Sales Invoice Header":
                exit(PAGE::"Posted Sales Invoice");
            Database::"Production Order":
                exit(GetProductionOrderPageID(RecRef));
            Database::User:
                exit(Page::"User Card");
            Database::Employee:
                exit(Page::"Employee Card");
            else begin
                OnConditionalCardPageIDNotFound(RecRef, CardPageID);
                exit(CardPageID);
            end;
        end;
        exit(0);
    end;

    procedure GetConditionalListPageID(RecRef: RecordRef): Integer
    var
        PageID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetConditionalListPageID(RecRef, PageID, IsHandled);
        if IsHandled then
            exit(PageID);

        case RecRef.Number of
            Database::"Sales Header":
                exit(GetSalesHeaderListPageID(RecRef));
            Database::"Purchase Header":
                exit(GetPurchaseHeaderListPageID(RecRef));
        end;
        exit(0);
    end;

    local procedure GetSalesHeaderPageID(RecRef: RecordRef): Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                exit(PAGE::"Sales Quote");
            SalesHeader."Document Type"::Order:
                exit(PAGE::"Sales Order");
            SalesHeader."Document Type"::Invoice:
                exit(PAGE::"Sales Invoice");
            SalesHeader."Document Type"::"Credit Memo":
                exit(PAGE::"Sales Credit Memo");
            SalesHeader."Document Type"::"Blanket Order":
                exit(PAGE::"Blanket Sales Order");
            SalesHeader."Document Type"::"Return Order":
                exit(PAGE::"Sales Return Order");
        end;
    end;

    local procedure GetPurchaseHeaderPageID(RecRef: RecordRef) Result: Integer
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecRef.SetTable(PurchaseHeader);
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Quote:
                Result := PAGE::"Purchase Quote";
            PurchaseHeader."Document Type"::Order:
                Result := PAGE::"Purchase Order";
            PurchaseHeader."Document Type"::Invoice:
                Result := PAGE::"Purchase Invoice";
            PurchaseHeader."Document Type"::"Credit Memo":
                Result := PAGE::"Purchase Credit Memo";
            PurchaseHeader."Document Type"::"Blanket Order":
                Result := PAGE::"Blanket Purchase Order";
            PurchaseHeader."Document Type"::"Return Order":
                Result := PAGE::"Purchase Return Order";
        end;
        OnAfterGetPurchaseHeaderPageID(RecRef, PurchaseHeader, Result);
    end;

    local procedure GetServiceHeaderPageID(RecRef: RecordRef) Result: Integer
    var
        ServiceHeader: Record "Service Header";
    begin
        RecRef.SetTable(ServiceHeader);
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Quote:
                Result := PAGE::"Service Quote";
            ServiceHeader."Document Type"::Order:
                Result := PAGE::"Service Order";
            ServiceHeader."Document Type"::Invoice:
                Result := PAGE::"Service Invoice";
            ServiceHeader."Document Type"::"Credit Memo":
                Result := PAGE::"Service Credit Memo";
        end;
        OnAfterGetServiceHeaderPageID(RecRef, ServiceHeader, Result);
    end;

    local procedure GetServiceContractHeaderPageID(RecRef: RecordRef): Integer
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        RecRef.SetTable(ServiceContractHeader);
        case ServiceContractHeader."Contract Type" of
            ServiceContractHeader."Contract Type"::Contract:
                exit(PAGE::"Service Contract");
            ServiceContractHeader."Contract Type"::Quote:
                exit(PAGE::"Service Contract Quote");
            ServiceContractHeader."Contract Type"::Template:
                exit(PAGE::"Service Contract Template");
        end;
    end;

    local procedure GetGenJournalBatchPageID(RecRef: RecordRef): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        RecRef.SetTable(GenJournalBatch);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if not GenJournalLine.FindFirst() then begin
            GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
            GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
            RecRef.GetTable(GenJournalLine);
            exit(PAGE::"General Journal");
        end;

        RecRef.GetTable(GenJournalLine);
        exit(GetGenJournalLinePageID(RecRef));
    end;

    local procedure GetGenJournalLinePageID(RecRef: RecordRef): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        RecRef.SetTable(GenJournalLine);
        GenJournalTemplate.Get(GenJournalLine."Journal Template Name");

        if GenJournalTemplate."Page ID" <> 0 then
            exit(GenJournalTemplate."Page ID");

        if GenJournalTemplate.Recurring then
            exit(PAGE::"Recurring General Journal");
        case GenJournalTemplate.Type of
            GenJournalTemplate.Type::General:
                exit(PAGE::"General Journal");
            GenJournalTemplate.Type::Sales:
                exit(PAGE::"Sales Journal");
            GenJournalTemplate.Type::Purchases:
                exit(PAGE::"Purchase Journal");
            GenJournalTemplate.Type::"Cash Receipts":
                exit(PAGE::"Cash Receipt Journal");
            GenJournalTemplate.Type::Payments:
                exit(PAGE::"Payment Journal");
            GenJournalTemplate.Type::Intercompany:
                exit(PAGE::"IC General Journal");
            GenJournalTemplate.Type::Jobs:
                exit(PAGE::"Job G/L Journal");
        end;
    end;

    local procedure GetSalesHeaderArchivePageID(RecRef: RecordRef): Integer
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        RecRef.SetTable(SalesHeaderArchive);
        case SalesHeaderArchive."Document Type" of
            SalesHeaderArchive."Document Type"::Quote:
                exit(PAGE::"Sales Quote Archive");
            SalesHeaderArchive."Document Type"::Order:
                exit(PAGE::"Sales Order Archive");
            SalesHeaderArchive."Document Type"::"Return Order":
                exit(PAGE::"Sales Return Order Archive");
            SalesHeaderArchive."Document Type"::"Blanket Order":
                exit(PAGE::"Blanket Sales Order Archive");
        end;
    end;

    local procedure GetPurchaseHeaderArchivePageID(RecRef: RecordRef): Integer
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        RecRef.SetTable(PurchaseHeaderArchive);
        case PurchaseHeaderArchive."Document Type" of
            PurchaseHeaderArchive."Document Type"::Quote:
                exit(PAGE::"Purchase Quote Archive");
            PurchaseHeaderArchive."Document Type"::Order:
                exit(PAGE::"Purchase Order Archive");
            PurchaseHeaderArchive."Document Type"::"Return Order":
                exit(PAGE::"Purchase Return Order Archive");
            PurchaseHeaderArchive."Document Type"::"Blanket Order":
                exit(PAGE::"Blanket Purchase Order Archive");
        end;
    end;

    local procedure GetAnalysisViewPageID(RecRef: RecordRef): Integer
    var
        ItemAnalysisView: Record "Item Analysis View";
    begin
        RecRef.SetTable(ItemAnalysisView);
        case ItemAnalysisView."Analysis Area" of
            ItemAnalysisView."Analysis Area"::Sales:
                exit(PAGE::"Sales Analysis View Card");
            ItemAnalysisView."Analysis Area"::Purchase:
                exit(PAGE::"Purchase Analysis View Card");
            ItemAnalysisView."Analysis Area"::Inventory:
                exit(PAGE::"Invt. Analysis View Card");
        end;
    end;

    local procedure GetApprovalEntryPageID(RecRef: RecordRef): Integer
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        RecRef.SetTable(ApprovalEntry);
        case ApprovalEntry.Status of
            ApprovalEntry.Status::Open:
                exit(PAGE::"Requests to Approve");
            else
                exit(PAGE::"Approval Entries");
        end;
    end;

    local procedure GetProductionOrderPageID(RecRef: RecordRef): Integer
    var
        ProductionOrder: Record "Production Order";
    begin
        RecRef.SetTable(ProductionOrder);
        case ProductionOrder.Status of
            ProductionOrder.Status::Simulated:
                exit(PAGE::"Simulated Production Order");
            ProductionOrder.Status::Planned:
                exit(PAGE::"Planned Production Order");
            ProductionOrder.Status::"Firm Planned":
                exit(PAGE::"Firm Planned Prod. Order");
            ProductionOrder.Status::Released:
                exit(PAGE::"Released Production Order");
            ProductionOrder.Status::Finished:
                exit(PAGE::"Finished Production Order");
        end;
    end;

    local procedure GetSalesHeaderListPageID(RecRef: RecordRef): Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                exit(PAGE::"Sales Quotes");
            SalesHeader."Document Type"::Order:
                exit(PAGE::"Sales List");
            SalesHeader."Document Type"::Invoice:
                exit(PAGE::"Sales Invoice List");
            SalesHeader."Document Type"::"Credit Memo":
                exit(PAGE::"Sales Credit Memos");
            SalesHeader."Document Type"::"Blanket Order":
                exit(PAGE::"Blanket Sales Orders");
            SalesHeader."Document Type"::"Return Order":
                exit(PAGE::"Sales Return Order List");
        end;
    end;

    local procedure GetPurchaseHeaderListPageID(RecRef: RecordRef): Integer
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecRef.SetTable(PurchaseHeader);
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Quote:
                exit(PAGE::"Purchase Quotes");
            PurchaseHeader."Document Type"::Order:
                exit(PAGE::"Purchase Order List");
            PurchaseHeader."Document Type"::Invoice:
                exit(PAGE::"Purchase Invoices");
            PurchaseHeader."Document Type"::"Credit Memo":
                exit(PAGE::"Purchase Credit Memos");
            PurchaseHeader."Document Type"::"Blanket Order":
                exit(PAGE::"Blanket Purchase Orders");
            PurchaseHeader."Document Type"::"Return Order":
                exit(PAGE::"Purchase Return Order List");
        end;
    end;

    procedure GetWebUrl(var RecRef: RecordRef; PageID: Integer): Text
    begin
        if not RecRef.HasFilter then
            RecRef.SetRecFilter();

        if not VerifyPageID(RecRef.Number, PageID) then
            PageID := GetPageID(RecRef);

        exit(GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, PageID, RecRef, false));
    end;

    local procedure VerifyPageID(TableID: Integer; PageID: Integer): Boolean
    var
        PageMetadata: Record "Page Metadata";
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyPageID(TableID, PageID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(PageMetadata.Get(PageID) and (PageMetadata.SourceTable = TableID));
    end;

    procedure GetPageCaption(PageID: Integer): Text
    var
        PageMetadata: Record "Page Metadata";
    begin
        if not PageMetadata.Get(PageID) then
            exit('');

        exit(PageMetadata.Caption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetConditionalListPageID(RecRef: RecordRef; var PageID: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetConditionalCardPageID(RecRef: RecordRef; var CardPageID: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPageID(var RecordRef: RecordRef; var PageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchaseHeaderPageID(RecRef: RecordRef; PurchaseHeader: Record "Purchase Header"; var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceHeaderPageID(RecRef: RecordRef; ServiceHeader: Record "Service Header"; var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultLookupPageID(TableID: Integer; var PageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultLookupPageIDByVar(TableID: Integer; var PageID: Integer; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConditionalCardPageIDNotFound(RecordRef: RecordRef; var CardPageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPageRunAtFieldOnBeforeRunPage(var RecordRef: RecordRef; var PageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyPageID(TableID: Integer; PageID: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

