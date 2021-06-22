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
        RecordRef: RecordRef;
        RecordRefVariant: Variant;
        PageID: Integer;
    begin
        if not GuiAllowed then
            exit(false);

        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecordRef) then
            exit(false);

        PageID := GetPageID(RecordRef);

        if PageID <> 0 then begin
            RecordRefVariant := RecordRef;
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
        RecordRef: RecordRef;
        EmptyRecRef: RecordRef;
        PageID: Integer;
    begin
        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecordRef) then
            exit;

        EmptyRecRef.Open(RecordRef.Number);
        PageID := GetConditionalCardPageID(RecordRef);
        // Choose default card only if record exists
        if RecordRef.RecordId <> EmptyRecRef.RecordId then
            if PageID = 0 then
                PageID := GetDefaultCardPageID(RecordRef.Number);

        if PageID = 0 then
            PageID := GetDefaultLookupPageID(RecordRef.Number);

        OnAfterGetPageID(RecordRef, PageID);

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
        RecordRef: RecordRef;
        PageID: Integer;
        TableID: Integer;
    begin
        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecordRef) then
            exit;

        TableID := RecordRef.Number;
        PageID := 0;
        OnBeforeGetDefaultLookupPageID(TableID, PageID);
        if PageID <> 0 then
            exit(PageID);

        TableMetadata.Get(TableID);
        exit(TableMetadata.LookupPageID);
    end;

    procedure GetConditionalCardPageID(RecordRef: RecordRef): Integer
    var
        CardPageID: Integer;
    begin
        case RecordRef.Number of
            DATABASE::"Gen. Journal Template":
                exit(PAGE::"General Journal Templates");
            DATABASE::"Company Information":
                exit(PAGE::"Company Information");
            DATABASE::"Sales Header":
                exit(GetSalesHeaderPageID(RecordRef));
            DATABASE::"Purchase Header":
                exit(GetPurchaseHeaderPageID(RecordRef));
            DATABASE::"Service Header":
                exit(GetServiceHeaderPageID(RecordRef));
            DATABASE::"Gen. Journal Batch":
                exit(GetGenJournalBatchPageID(RecordRef));
            DATABASE::"Gen. Journal Line":
                exit(GetGenJournalLinePageID(RecordRef));
            DATABASE::"User Setup":
                exit(PAGE::"User Setup");
            DATABASE::"General Ledger Setup":
                exit(PAGE::"General Ledger Setup");
            DATABASE::"Sales Header Archive":
                exit(GetSalesHeaderArchivePageID(RecordRef));
            DATABASE::"Purchase Header Archive":
                exit(GetPurchaseHeaderArchivePageID(RecordRef));
            DATABASE::"Res. Journal Line":
                exit(PAGE::"Resource Journal");
            DATABASE::"Job Journal Line":
                exit(PAGE::"Job Journal");
            DATABASE::"Item Analysis View":
                exit(GetAnalysisViewPageID(RecordRef));
            DATABASE::"Purchases & Payables Setup":
                exit(PAGE::"Purchases & Payables Setup");
            DATABASE::"Approval Entry":
                exit(GetApprovalEntryPageID(RecordRef));
            DATABASE::"Doc. Exch. Service Setup":
                exit(PAGE::"Doc. Exch. Service Setup");
            DATABASE::"Incoming Documents Setup":
                exit(PAGE::"Incoming Documents Setup");
            DATABASE::"Text-to-Account Mapping":
                exit(PAGE::"Text-to-Account Mapping Wksh.");
            DATABASE::"Cash Flow Setup":
                exit(PAGE::"Cash Flow Setup");
            DATABASE::"Production Order":
                exit(GetProductionOrderPageID(RecordRef));
            else begin
                    OnConditionalCardPageIDNotFound(RecordRef, CardPageID);
                    exit(CardPageID);
                end;
        end;
        exit(0);
    end;

    procedure GetConditionalListPageID(RecordRef: RecordRef): Integer
    begin
        case RecordRef.Number of
            DATABASE::"Sales Header":
                exit(GetSalesHeaderListPageID(RecordRef));
            DATABASE::"Purchase Header":
                exit(GetPurchaseHeaderListPageID(RecordRef));
        end;
        exit(0);
    end;

    local procedure GetSalesHeaderPageID(RecordRef: RecordRef): Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        RecordRef.SetTable(SalesHeader);
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

    local procedure GetPurchaseHeaderPageID(RecordRef: RecordRef): Integer
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecordRef.SetTable(PurchaseHeader);
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Quote:
                exit(PAGE::"Purchase Quote");
            PurchaseHeader."Document Type"::Order:
                exit(PAGE::"Purchase Order");
            PurchaseHeader."Document Type"::Invoice:
                exit(PAGE::"Purchase Invoice");
            PurchaseHeader."Document Type"::"Credit Memo":
                exit(PAGE::"Purchase Credit Memo");
            PurchaseHeader."Document Type"::"Blanket Order":
                exit(PAGE::"Blanket Purchase Order");
            PurchaseHeader."Document Type"::"Return Order":
                exit(PAGE::"Purchase Return Order");
        end;
    end;

    local procedure GetServiceHeaderPageID(RecordRef: RecordRef): Integer
    var
        ServiceHeader: Record "Service Header";
    begin
        RecordRef.SetTable(ServiceHeader);
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Quote:
                exit(PAGE::"Service Quote");
            ServiceHeader."Document Type"::Order:
                exit(PAGE::"Service Order");
            ServiceHeader."Document Type"::Invoice:
                exit(PAGE::"Service Invoice");
            ServiceHeader."Document Type"::"Credit Memo":
                exit(PAGE::"Service Credit Memo");
        end;
    end;

    local procedure GetGenJournalBatchPageID(RecordRef: RecordRef): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        RecordRef.SetTable(GenJournalBatch);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if not GenJournalLine.FindFirst then begin
            GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
            GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
            RecordRef.GetTable(GenJournalLine);
            exit(PAGE::"General Journal");
        end;

        RecordRef.GetTable(GenJournalLine);
        exit(GetGenJournalLinePageID(RecordRef));
    end;

    local procedure GetGenJournalLinePageID(RecordRef: RecordRef): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        RecordRef.SetTable(GenJournalLine);
        GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
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
            GenJournalTemplate.Type::Assets:
                exit(PAGE::"Fixed Asset G/L Journal");
            GenJournalTemplate.Type::Intercompany:
                exit(PAGE::"IC General Journal");
            GenJournalTemplate.Type::Jobs:
                exit(PAGE::"Job G/L Journal");
        end;
    end;

    local procedure GetSalesHeaderArchivePageID(RecordRef: RecordRef): Integer
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        RecordRef.SetTable(SalesHeaderArchive);
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

    local procedure GetPurchaseHeaderArchivePageID(RecordRef: RecordRef): Integer
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        RecordRef.SetTable(PurchaseHeaderArchive);
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

    local procedure GetAnalysisViewPageID(RecordRef: RecordRef): Integer
    var
        ItemAnalysisView: Record "Item Analysis View";
    begin
        RecordRef.SetTable(ItemAnalysisView);
        case ItemAnalysisView."Analysis Area" of
            ItemAnalysisView."Analysis Area"::Sales:
                exit(PAGE::"Sales Analysis View Card");
            ItemAnalysisView."Analysis Area"::Purchase:
                exit(PAGE::"Purchase Analysis View Card");
            ItemAnalysisView."Analysis Area"::Inventory:
                exit(PAGE::"Invt. Analysis View Card");
        end;
    end;

    local procedure GetApprovalEntryPageID(RecordRef: RecordRef): Integer
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        RecordRef.SetTable(ApprovalEntry);
        case ApprovalEntry.Status of
            ApprovalEntry.Status::Open:
                exit(PAGE::"Requests to Approve");
            else
                exit(PAGE::"Approval Entries");
        end;
    end;

    local procedure GetProductionOrderPageID(RecordRef: RecordRef): Integer
    var
        ProductionOrder: Record "Production Order";
    begin
        RecordRef.SetTable(ProductionOrder);
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

    local procedure GetSalesHeaderListPageID(RecordRef: RecordRef): Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        RecordRef.SetTable(SalesHeader);
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

    local procedure GetPurchaseHeaderListPageID(RecordRef: RecordRef): Integer
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecordRef.SetTable(PurchaseHeader);
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
            RecRef.SetRecFilter;

        if not VerifyPageID(RecRef.Number, PageID) then
            PageID := GetPageID(RecRef);

        exit(GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, PageID, RecRef, false));
    end;

    local procedure VerifyPageID(TableID: Integer; PageID: Integer): Boolean
    var
        PageMetadata: Record "Page Metadata";
    begin
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
    local procedure OnAfterGetPageID(RecordRef: RecordRef; var PageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultLookupPageID(TableID: Integer; var PageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConditionalCardPageIDNotFound(RecordRef: RecordRef; var CardPageID: Integer)
    begin
    end;
}

