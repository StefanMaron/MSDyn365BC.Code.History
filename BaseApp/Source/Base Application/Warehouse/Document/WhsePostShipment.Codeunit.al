namespace Microsoft.Warehouse.Document;

using Microsoft.Assembly.Document;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using Microsoft.Utilities;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Tracking;
using System.Utilities;

codeunit 5763 "Whse.-Post Shipment"
{
    Permissions = TableData "Whse. Item Tracking Line" = r,
                  TableData "Posted Whse. Shipment Header" = rim,
                  TableData "Posted Whse. Shipment Line" = ri;
    TableNo = "Warehouse Shipment Line";

    trigger OnRun()
    begin
        OnBeforeRun(Rec, SuppressCommit, PreviewMode);

        WhseShptLine.Copy(Rec);
        Code();
        Rec := WhseShptLine;

        OnAfterRun(Rec);
    end;

    var
        Text000: Label 'The source document %1 %2 is not released.';
        Text003: Label 'Number of source documents posted: %1 out of a total of %2.';
        Text004: Label 'Ship lines have been posted.';
        Text005: Label 'Some ship lines remain.';
        WhseRqst: Record "Warehouse Request";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        TransHeader: Record "Transfer Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        ReturnShptHeader: Record "Return Shipment Header";
        PurchCrMemHeader: Record "Purch. Cr. Memo Hdr.";
        TransShptHeader: Record "Transfer Shipment Header";
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceInvHeader: Record "Service Invoice Header";
        InventorySetup: Record "Inventory Setup";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        WMSMgt: Codeunit "WMS Management";
        LastShptNo: Code[20];
        PostingDate: Date;
        CounterSourceDocOK: Integer;
        CounterSourceDocTotal: Integer;
        Print: Boolean;
        Invoice: Boolean;
        Text006: Label '%1, %2 %3: you cannot ship more than have been picked for the item tracking lines.';
        Text007: Label 'is not within your range of allowed posting dates';
        InvoiceService: Boolean;
        FullATONotPostedErr: Label 'Warehouse shipment %1, Line No. %2 cannot be posted, because the full assemble-to-order quantity on the source document line must be shipped first.';
        SuppressCommit: Boolean;
        PreviewMode: Boolean;

    local procedure "Code"()
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        WhseShptLine.SetCurrentKey(WhseShptLine."No.");
        WhseShptLine.SetRange("No.", WhseShptLine."No.");
        IsHandled := false;
        OnBeforeCheckWhseShptLines(WhseShptLine, WhseShptHeader, Invoice, SuppressCommit, IsHandled);
        if IsHandled then
            exit;
        WhseShptLine.SetFilter("Qty. to Ship", '>0');
        OnRunOnAfterWhseShptLineSetFilters(WhseShptLine);
        if WhseShptLine.Find('-') then
            repeat
                WhseShptLine.TestField("Unit of Measure Code");
                CheckShippingAdviceComplete();
                WhseRqst.Get(
                  WhseRqst.Type::Outbound, WhseShptLine."Location Code", WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.");
                CheckDocumentStatus();
                GetLocation(WhseShptLine."Location Code");
                if Location."Require Pick" and (WhseShptLine."Shipping Advice" = WhseShptLine."Shipping Advice"::Complete) then
                    CheckItemTrkgPicked(WhseShptLine);
                if Location."Bin Mandatory" then
                    WhseShptLine.TestField("Bin Code");
                if not WhseShptLine."Assemble to Order" then
                    if not WhseShptLine.FullATOPosted() then
                        Error(FullATONotPostedErr, WhseShptLine."No.", WhseShptLine."Line No.");

                OnAfterCheckWhseShptLine(WhseShptLine);
            until WhseShptLine.Next() = 0
        else
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        CounterSourceDocOK := 0;
        CounterSourceDocTotal := 0;

        GetLocation(WhseShptLine."Location Code");
        WhseShptHeader.Get(WhseShptLine."No.");
        OnCodeOnAfterGetWhseShptHeader(WhseShptHeader);
        WhseShptHeader.TestField("Posting Date");
        OnAfterCheckWhseShptLines(WhseShptHeader, WhseShptLine, Invoice, SuppressCommit);
        if WhseShptHeader."Shipping No." = '' then begin
            WhseShptHeader.TestField("Shipping No. Series");
            WhseShptHeader."Shipping No." :=
              NoSeries.GetNextNo(WhseShptHeader."Shipping No. Series", WhseShptHeader."Posting Date");
        end;

        if not (SuppressCommit or PreviewMode) then
            Commit();

        WhseShptHeader."Create Posted Header" := true;
        WhseShptHeader.Modify();
        OnCodeOnAfterWhseShptHeaderModify(WhseShptHeader, Print);

        ClearRecordsToPrint();

        WhseShptLine.SetCurrentKey(WhseShptLine."No.", WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.", WhseShptLine."Source Line No.");
        OnAfterSetCurrentKeyForWhseShptLine(WhseShptLine);
        WhseShptLine.FindSet(true);
        repeat
            WhseShptLine.SetSourceFilter(WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.", -1, false);
            IsHandled := false;
            OnAfterSetSourceFilterForWhseShptLine(WhseShptLine, IsHandled);
            if not IsHandled then begin
                GetSourceDocument();
                MakePreliminaryChecks();

                InitSourceDocumentLines(WhseShptLine);
                InitSourceDocumentHeader();
                if not (SuppressCommit or PreviewMode) then
                    Commit();

                CounterSourceDocTotal := CounterSourceDocTotal + 1;

                OnBeforePostSourceDocument(WhseShptLine, PurchHeader, SalesHeader, TransHeader, ServiceHeader, SuppressCommit);
                PostSourceDocument(WhseShptLine);
                WhseJnlRegisterLine.LockTables();

                if WhseShptLine.FindLast() then;
                WhseShptLine.SetRange(WhseShptLine."Source Type");
                WhseShptLine.SetRange(WhseShptLine."Source Subtype");
                WhseShptLine.SetRange(WhseShptLine."Source No.");
            end;
            OnAfterReleaseSourceForFilterWhseShptLine(WhseShptLine);
        until WhseShptLine.Next() = 0;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        IsHandled := false;
        OnAfterPostWhseShipment(WhseShptHeader, SuppressCommit, IsHandled);
        if not IsHandled then begin
            if not SuppressCommit or Print then
                Commit();
            PrintDocuments();
        end;

        Clear(WMSMgt);
        Clear(WhseJnlRegisterLine);

        WhseShptLine.Reset();
    end;

    local procedure CheckDocumentStatus()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocumentStatus(WhseShptLine, IsHandled);
        if IsHandled then
            exit;

        if WhseRqst."Document Status" <> WhseRqst."Document Status"::Released then
            Error(Text000, WhseShptLine."Source Document", WhseShptLine."Source No.");
    end;

    local procedure GetSourceDocument()
    var
        SourceHeader: Variant;
    begin
        case WhseShptLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesHeader.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.");
                    SourceHeader := SalesHeader;
                end;
            Database::"Purchase Line": // Return Order
                begin
                    PurchHeader.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.");
                    SourceHeader := PurchHeader;
                end;
            Database::"Transfer Line":
                begin
                    TransHeader.Get(WhseShptLine."Source No.");
                    SourceHeader := TransHeader;
                end;
            Database::"Service Line":
                begin
                    ServiceHeader.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.");
                    SourceHeader := ServiceHeader;
                end;
            else
                OnGetSourceDocumentOnElseCase(SourceHeader);
        end;
        OnAfterGetSourceDocument(SourceHeader);
    end;

    local procedure MakePreliminaryChecks()
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(WhseShptHeader."Posting Date") then
            WhseShptHeader.FieldError("Posting Date", Text007);
    end;

    local procedure InitSourceDocumentHeader()
    var
        SalesRelease: Codeunit "Release Sales Document";
        PurchRelease: Codeunit "Release Purchase Document";
        ReleaseServiceDocument: Codeunit "Release Service Document";
        ModifyHeader: Boolean;
        ValidatePostingDate: Boolean;
        IsHandled: Boolean;
        NewCalledFromWhseDoc: Boolean;
    begin
        OnBeforeInitSourceDocumentHeader(WhseShptLine);

        case WhseShptLine."Source Type" of
            Database::"Sales Line":
                begin
                    IsHandled := false;
                    OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(SalesHeader, WhseShptLine, ValidatePostingDate, IsHandled, ModifyHeader, WhseShptHeader);
                    if not IsHandled then
                        if (SalesHeader."Posting Date" = 0D) or
                        (SalesHeader."Posting Date" <> WhseShptHeader."Posting Date") or ValidatePostingDate
                        then begin
                            NewCalledFromWhseDoc := true;
                            OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(SalesHeader, Invoice, NewCalledFromWhseDoc);
                            SalesRelease.SetSkipWhseRequestOperations(true);
                            SalesRelease.Reopen(SalesHeader);
                            SalesRelease.SetSkipCheckReleaseRestrictions();
                            SalesHeader.SetHideValidationDialog(true);
                            SalesHeader.SetCalledFromWhseDoc(NewCalledFromWhseDoc);
                            SalesHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            OnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(SalesHeader, WhseShptHeader, WhseShptLine);
                            SalesRelease.Run(SalesHeader);
                            ModifyHeader := true;
                        end;
                    if (WhseShptHeader."Shipment Date" <> 0D) and
                       (WhseShptHeader."Shipment Date" <> SalesHeader."Shipment Date")
                    then begin
                        SalesHeader."Shipment Date" := WhseShptHeader."Shipment Date";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."External Document No." <> '') and
                       (WhseShptHeader."External Document No." <> SalesHeader."External Document No.")
                    then begin
                        SalesHeader."External Document No." := WhseShptHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Code" <> '') and
                       (WhseShptHeader."Shipping Agent Code" <> SalesHeader."Shipping Agent Code")
                    then begin
                        SalesHeader."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
                        SalesHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Service Code" <> '') and
                       (WhseShptHeader."Shipping Agent Service Code" <>
                        SalesHeader."Shipping Agent Service Code")
                    then begin
                        SalesHeader."Shipping Agent Service Code" :=
                          WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipment Method Code" <> '') and
                       (WhseShptHeader."Shipment Method Code" <> SalesHeader."Shipment Method Code")
                    then begin
                        SalesHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(SalesHeader, WhseShptHeader, ModifyHeader, Invoice, WhseShptLine);
                    if ModifyHeader then
                        SalesHeader.Modify();
                end;
            Database::"Purchase Line": // Return Order
                begin
                    IsHandled := false;
                    OnInitSourceDocumentHeaderOnBeforePurchaseHeaderUpdatePostingDate(PurchHeader, WhseShptHeader, WhseShptLine, ValidatePostingDate, ModifyHeader, IsHandled);
                    if not IsHandled then
                        if (PurchHeader."Posting Date" = 0D) or
                           (PurchHeader."Posting Date" <> WhseShptHeader."Posting Date")
                        then begin
                            OnInitSourceDocumentHeaderOnBeforeReopenPurchHeader(WhseShptLine, PurchHeader);
                            PurchRelease.SetSkipWhseRequestOperations(true);
                            PurchRelease.Reopen(PurchHeader);
                            PurchRelease.SetSkipCheckReleaseRestrictions();
                            PurchHeader.SetHideValidationDialog(true);
                            PurchHeader.SetCalledFromWhseDoc(true);
                            PurchHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            PurchRelease.Run(PurchHeader);
                            ModifyHeader := true;
                        end;
                    if (WhseShptHeader."Shipment Date" <> 0D) and
                       (WhseShptHeader."Shipment Date" <> PurchHeader."Expected Receipt Date")
                    then begin
                        PurchHeader."Expected Receipt Date" := WhseShptHeader."Shipment Date";
                        ModifyHeader := true;
                    end;
                    if WhseShptHeader."External Document No." <> '' then begin
                        PurchHeader."Vendor Authorization No." := WhseShptHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipment Method Code" <> '') and
                       (WhseShptHeader."Shipment Method Code" <> PurchHeader."Shipment Method Code")
                    then begin
                        PurchHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(PurchHeader, WhseShptHeader, ModifyHeader);
                    if ModifyHeader then
                        PurchHeader.Modify();
                end;
            Database::"Transfer Line":
                begin
                    IsHandled := false;
                    OnInitSourceDocumentHeaderOnBeforeTransferHeaderUpdatePostingDate(TransHeader, WhseShptHeader, WhseShptLine, ValidatePostingDate, ModifyHeader, IsHandled);
                    if not IsHandled then
                        if (TransHeader."Posting Date" = 0D) or
                           (TransHeader."Posting Date" <> WhseShptHeader."Posting Date")
                        then begin
                            TransHeader.CalledFromWarehouse(true);
                            TransHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            ModifyHeader := true;
                        end;
                    if (WhseShptHeader."Shipment Date" <> 0D) and
                       (TransHeader."Shipment Date" <> WhseShptHeader."Shipment Date")
                    then begin
                        TransHeader."Shipment Date" := WhseShptHeader."Shipment Date";
                        ModifyHeader := true;
                    end;
                    if WhseShptHeader."External Document No." <> '' then begin
                        TransHeader."External Document No." := WhseShptHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Code" <> '') and
                       (WhseShptHeader."Shipping Agent Code" <> TransHeader."Shipping Agent Code")
                    then begin
                        TransHeader."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
                        TransHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Service Code" <> '') and
                       (WhseShptHeader."Shipping Agent Service Code" <>
                        TransHeader."Shipping Agent Service Code")
                    then begin
                        TransHeader."Shipping Agent Service Code" :=
                          WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipment Method Code" <> '') and
                       (WhseShptHeader."Shipment Method Code" <> TransHeader."Shipment Method Code")
                    then begin
                        TransHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(TransHeader, WhseShptHeader, ModifyHeader);
                    if ModifyHeader then
                        TransHeader.Modify();
                end;
            Database::"Service Line":
                begin
                    IsHandled := false;
                    OnInitSourceDocumentHeaderOnBeforeServiceHeaderUpdatePostingDate(ServiceHeader, WhseShptHeader, WhseShptLine, ValidatePostingDate, ModifyHeader, IsHandled);
                    if not IsHandled then
                        if (ServiceHeader."Posting Date" = 0D) or (ServiceHeader."Posting Date" <> WhseShptHeader."Posting Date") then begin
                            ReleaseServiceDocument.SetSkipWhseRequestOperations(true);
                            ReleaseServiceDocument.Reopen(ServiceHeader);
                            ServiceHeader.SetHideValidationDialog(true);
                            ServiceHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
                            ReleaseServiceDocument.Run(ServiceHeader);
                            ServiceHeader.Modify();
                        end;
                    if (WhseShptHeader."Shipping Agent Code" <> '') and
                       (WhseShptHeader."Shipping Agent Code" <> ServiceHeader."Shipping Agent Code")
                    then begin
                        ServiceHeader."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
                        ServiceHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipping Agent Service Code" <> '') and
                       (WhseShptHeader."Shipping Agent Service Code" <> ServiceHeader."Shipping Agent Service Code")
                    then begin
                        ServiceHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."Shipment Method Code" <> '') and
                       (WhseShptHeader."Shipment Method Code" <> ServiceHeader."Shipment Method Code")
                    then begin
                        ServiceHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
                        ModifyHeader := true;
                    end;
                    if (WhseShptHeader."External Document No." <> '') and
                       (WhseShptHeader."External Document No." <> ServiceHeader."External Document No.")
                    then begin
                        ServiceHeader."External Document No." := WhseShptHeader."External Document No.";
                        ModifyHeader := true;
                    end;
                    OnInitSourceDocumentHeaderOnBeforeServiceHeaderModify(ServiceHeader, WhseShptHeader, ModifyHeader);
                    if ModifyHeader then
                        ServiceHeader.Modify();
                end;
            else
                OnInitSourceDocumentHeader(WhseShptHeader, WhseShptLine);
        end;

        OnAfterInitSourceDocumentHeader(WhseShptLine);
    end;

    local procedure InitSourceDocumentLines(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        WhseShptLine2: Record "Warehouse Shipment Line";
    begin
        WhseShptLine2.Copy(WhseShptLine);
        case WhseShptLine2."Source Type" of
            Database::"Sales Line":
                HandleSalesLine(WhseShptLine2);
            Database::"Purchase Line": // Return Order
                HandlePurchaseLine(WhseShptLine2);
            Database::"Transfer Line":
                HandleTransferLine(WhseShptLine2);
            Database::"Service Line":
                HandleServiceLine(WhseShptLine2);
            else
                OnAfterInitSourceDocumentLines(WhseShptLine2);
        end;

        WhseShptLine2.SetRange("Source Line No.");
    end;

    local procedure PostSourceDocument(WhseShptLine: Record "Warehouse Shipment Line")
    var
        WhseSetup: Record "Warehouse Setup";
        WhseShptHeader: Record "Warehouse Shipment Header";
        SalesPost: Codeunit "Sales-Post";
        PurchPost: Codeunit "Purch.-Post";
        ServicePost: Codeunit "Service-Post";
        IsHandled: Boolean;
    begin
        WhseSetup.Get();
        WhseShptHeader.Get(WhseShptLine."No.");
        OnPostSourceDocumentAfterGetWhseShptHeader(WhseShptLine, WhseShptHeader);
        case WhseShptLine."Source Type" of
            Database::"Sales Line":
                begin
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Sales Order" then
                        SalesHeader.Ship := true
                    else
                        SalesHeader.Receive := true;
                    SalesHeader.Invoice := Invoice;

                    SalesPost.SetWhseShptHeader(WhseShptHeader);
                    SalesPost.SetPreviewMode(PreviewMode);
                    SalesPost.SetSuppressCommit(SuppressCommit);
                    SalesPost.SetCalledBy(Codeunit::"Whse.-Post Shipment");
                    IsHandled := false;
                    OnPostSourceDocumentOnBeforePostSalesHeader(SalesPost, SalesHeader, WhseShptHeader, CounterSourceDocOK, SuppressCommit, IsHandled, Invoice);
                    if not IsHandled then
                        if PreviewMode then
                            PostSourceSalesDocument(SalesPost)
                        else
                            case WhseSetup."Shipment Posting Policy" of
                                WhseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                    TryPostSourceSalesDocument(SalesPost);
                                WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                    PostSourceSalesDocument(SalesPost);
                            end;

                    OnPostSourceDocumentOnBeforePrintSalesDocuments(SalesHeader."Last Shipping No.");

                    if Print then
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Sales Order" then begin
                            IsHandled := false;
                            OnPostSourceDocumentOnBeforePrintSalesShipment(SalesHeader, IsHandled, SalesShptHeader, WhseShptHeader);
                            if not IsHandled then
                                if SalesShptHeader.Get(SalesHeader."Last Shipping No.") then
                                    SalesShptHeader.Mark(true);
                            if Invoice then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintSalesInvoice(SalesHeader, IsHandled, WhseShptLine);
                                if not IsHandled then
                                    if SalesInvHeader.Get(SalesHeader."Last Posting No.") then
                                        SalesInvHeader.Mark(true);
                            end;
                        end;

                    OnAfterSalesPost(WhseShptLine, SalesHeader, Invoice);
                    Clear(SalesPost);
                end;
            Database::"Purchase Line":
                // Return Order
                begin
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Purchase Order" then
                        PurchHeader.Receive := true
                    else
                        PurchHeader.Ship := true;
                    PurchHeader.Invoice := Invoice;

                    PurchPost.SetWhseShptHeader(WhseShptHeader);
                    PurchPost.SetPreviewMode(PreviewMode);
                    PurchPost.SetSuppressCommit(SuppressCommit);
                    PurchPost.SetCalledBy(Codeunit::"Whse.-Post Shipment");
                    IsHandled := false;
                    OnPostSourceDocumentOnBeforePostPurchHeader(PurchPost, PurchHeader, WhseShptHeader, CounterSourceDocOK, IsHandled, SuppressCommit);
                    if not IsHandled then
                        if PreviewMode then
                            PostSourcePurchDocument(PurchPost)
                        else
                            case WhseSetup."Shipment Posting Policy" of
                                WhseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                    TryPostSourcePurchDocument(PurchPost);
                                WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                    PostSourcePurchDocument(PurchPost);
                            end;

                    if Print then
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Purchase Return Order" then begin
                            IsHandled := false;
                            OnPostSourceDocumentOnBeforePrintPurchReturnShipment(PurchHeader, IsHandled);
                            if not IsHandled then begin
                                ReturnShptHeader.Get(PurchHeader."Last Return Shipment No.");
                                ReturnShptHeader.Mark(true);
                            end;
                            if Invoice then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintPurchCreditMemo(PurchHeader, IsHandled);
                                if not IsHandled then begin
                                    PurchCrMemHeader.Get(PurchHeader."Last Posting No.");
                                    PurchCrMemHeader.Mark(true);
                                end;
                            end;
                        end;

                    OnAfterPurchPost(WhseShptLine, PurchHeader, Invoice, WhseShptHeader);
                    Clear(PurchPost);
                end;
            Database::"Transfer Line":
                begin
                    OnPostSourceDocumentOnBeforeCaseTransferLine(TransHeader, WhseShptLine);
                    if PreviewMode then
                        PostSourceTransferDocument()
                    else
                        case WhseSetup."Shipment Posting Policy" of
                            WhseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                TryPostSourceTransferDocument();

                            WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                PostSourceTransferDocument();
                        end;

                    if Print then begin
                        IsHandled := false;
                        OnPostSourceDocumentOnBeforePrintTransferShipment(TransShptHeader, IsHandled, TransHeader);
                        if not IsHandled then begin
                            TransShptHeader.Get(TransHeader."Last Shipment No.");
                            TransShptHeader.Mark(true);
                        end;
                    end;

                    OnAfterTransferPostShipment(WhseShptLine, TransHeader, SuppressCommit);
                end;
            Database::"Service Line":
                begin
                    ServicePost.SetPostingOptions(true, false, InvoiceService);
                    ServicePost.SetSuppressCommit(SuppressCommit);
                    OnPostSourceDocumentBeforeRunServicePost();
                    case WhseSetup."Shipment Posting Policy" of
                        WhseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                            begin
                                if ServicePost.Run(ServiceHeader) then
                                    CounterSourceDocOK := CounterSourceDocOK + 1;
                            end;
                        WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                            begin
                                ServicePost.Run(ServiceHeader);
                                CounterSourceDocOK := CounterSourceDocOK + 1;
                            end;
                    end;
                    OnPostSourceDocumentAfterRunServicePost();
                    if Print then
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Service Order" then begin
                            IsHandled := false;
                            OnPostSourceDocumentOnBeforePrintServiceShipment(ServiceHeader, IsHandled);
                            if not IsHandled then begin
                                ServiceShptHeader.Get(ServiceHeader."Last Shipping No.");
                                ServiceShptHeader.Mark(true);
                            end;
                            if Invoice then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintServiceInvoice(ServiceHeader, IsHandled);
                                if not IsHandled then begin
                                    ServiceInvHeader.Get(ServiceHeader."Last Posting No.");
                                    ServiceInvHeader.Mark(true);
                                end;
                            end;
                        end;

                    OnAfterServicePost(WhseShptLine, ServiceHeader, Invoice);
                    Clear(ServicePost);
                end;
            else
                OnPostSourceDocument(WhseShptHeader, WhseShptLine, CounterSourceDocOK);
        end;
        OnAfterPostSourceDocument(WhseShptLine, Print);
    end;

    local procedure TryPostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post")
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnPostSourceDocumentOnBeforeSalesPost(CounterSourceDocOK, SalesPost, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if SalesPost.Run(SalesHeader) then begin
            CounterSourceDocOK := CounterSourceDocOK + 1;
            Result := true;
        end;
        OnPostSourceDocumentOnAfterSalesPost(CounterSourceDocOK, SalesPost, SalesHeader, Result);
    end;

    local procedure PostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post")
    begin
        OnBeforePostSourceSalesDocument(SalesPost);

        SalesPost.RunWithCheck(SalesHeader);
        CounterSourceDocOK := CounterSourceDocOK + 1;

        OnAfterPostSourceSalesDocument(CounterSourceDocOK, SalesPost, SalesHeader);
    end;

    local procedure TryPostSourcePurchDocument(var PurchPost: Codeunit "Purch.-Post")
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTryPostSourcePurchDocument(PurchPost, PurchHeader, IsHandled);
        if not IsHandled then
            if PurchPost.Run(PurchHeader) then begin
                CounterSourceDocOK := CounterSourceDocOK + 1;
                Result := true;
            end;

        OnAfterTryPostSourcePurchDocument(CounterSourceDocOK, PurchPost, PurchHeader, Result);
    end;

    local procedure PostSourcePurchDocument(var PurchPost: Codeunit "Purch.-Post")
    begin
        OnBeforePostSourcePurchDocument(PurchPost, PurchHeader);

        PurchPost.RunWithCheck(PurchHeader);
        CounterSourceDocOK := CounterSourceDocOK + 1;

        OnAfterPostSourcePurchDocument(CounterSourceDocOK, PurchPost, PurchHeader);
    end;

    local procedure TryPostSourceTransferDocument()
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        Clear(TransferOrderPostShipment);
        IsHandled := false;
        OnBeforeTryPostSourceTransferDocument(TransferOrderPostShipment, TransHeader, IsHandled);
        if not IsHandled then begin
            Result := false;
            InventorySetup.Get();
            if TransHeader."Direct Transfer" then
                Result := TryPostDirectTransferDocument()
            else begin
                TransferOrderPostShipment.SetWhseShptHeader(WhseShptHeader);
                TransferOrderPostShipment.SetSuppressCommit(SuppressCommit or PreviewMode);
                if TransferOrderPostShipment.Run(TransHeader) then begin
                    CounterSourceDocOK := CounterSourceDocOK + 1;
                    Result := true;
                end;
            end;
        end;

        OnAfterTryPostSourceTransferDocument(CounterSourceDocOK, TransferOrderPostShipment, TransHeader, Result);
    end;

    local procedure TryPostDirectTransferDocument() Posted: Boolean
    begin
        Posted := false;
        case InventorySetup."Direct Transfer Posting" of
            InventorySetup."Direct Transfer Posting"::"Direct Transfer":
                begin
                    Clear(TransferOrderPostTransfer);
                    TransferOrderPostTransfer.SetWhseShptHeader(WhseShptHeader);
                    TransferOrderPostTransfer.SetSuppressCommit(SuppressCommit or PreviewMode);
                    if TransferOrderPostTransfer.Run(TransHeader) then begin
                        CounterSourceDocOK := CounterSourceDocOK + 1;
                        Posted := true;
                    end;
                end;
            InventorySetup."Direct Transfer Posting"::"Receipt and Shipment":
                begin
                    Clear(TransferOrderPostShipment);
                    TransferOrderPostShipment.SetWhseShptHeader(WhseShptHeader);
                    TransferOrderPostShipment.SetSuppressCommit(SuppressCommit);
                    if TransferOrderPostShipment.Run(TransHeader) then begin
                        Clear(TransferOrderPostReceipt);
                        TransferOrderPostReceipt.SetSuppressCommit(SuppressCommit or PreviewMode);
                        if TransferOrderPostReceipt.Run(TransHeader) then begin
                            CounterSourceDocOK := CounterSourceDocOK + 1;
                            Posted := true;
                        end;
                    end;
                end;
        end;
    end;

    local procedure PostSourceTransferDocument()
    var
        IsHandled: Boolean;
    begin
        Clear(TransferOrderPostShipment);
        IsHandled := false;
        OnBeforePostSourceTransferDocument(TransferOrderPostShipment, TransHeader, CounterSourceDocOK, IsHandled);
        if IsHandled then
            exit;

        InventorySetup.Get();
        if TransHeader."Direct Transfer" then
            PostSourceDirectTransferDocument()
        else begin
            TransferOrderPostShipment.SetWhseShptHeader(WhseShptHeader);
            TransferOrderPostShipment.SetSuppressCommit(SuppressCommit or PreviewMode);
            TransferOrderPostShipment.RunWithCheck(TransHeader);
            CounterSourceDocOK := CounterSourceDocOK + 1;
        end;

        OnAfterPostSourceTransferDocument(CounterSourceDocOK, TransferOrderPostShipment, TransHeader);
    end;

    local procedure PostSourceDirectTransferDocument()
    begin
        case InventorySetup."Direct Transfer Posting" of
            InventorySetup."Direct Transfer Posting"::"Direct Transfer":
                begin
                    Clear(TransferOrderPostTransfer);
                    TransferOrderPostTransfer.SetWhseShptHeader(WhseShptHeader);
                    TransferOrderPostTransfer.SetSuppressCommit(SuppressCommit or PreviewMode);
                    TransferOrderPostTransfer.RunWithCheck(TransHeader);
                    CounterSourceDocOK := CounterSourceDocOK + 1;
                end;
            InventorySetup."Direct Transfer Posting"::"Receipt and Shipment":
                begin
                    Clear(TransferOrderPostShipment);
                    TransferOrderPostShipment.SetWhseShptHeader(WhseShptHeader);
                    TransferOrderPostShipment.SetSuppressCommit(SuppressCommit or PreviewMode);
                    TransferOrderPostShipment.RunWithCheck(TransHeader);
                    Clear(TransferOrderPostReceipt);
                    TransferOrderPostReceipt.SetSuppressCommit(SuppressCommit or PreviewMode);
                    TransferOrderPostReceipt.Run(TransHeader);
                    CounterSourceDocOK := CounterSourceDocOK + 1;
                end;
        end;
    end;

    procedure SetPrint(Print2: Boolean)
    begin
        Print := Print2;

        OnAfterSetPrint(Print);
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure ClearRecordsToPrint()
    begin
        Clear(SalesInvHeader);
        Clear(SalesShptHeader);
        Clear(PurchCrMemHeader);
        Clear(ReturnShptHeader);
        Clear(TransShptHeader);
        Clear(ServiceInvHeader);
        Clear(ServiceShptHeader);
    end;

    local procedure PrintDocuments()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintDocuments(SalesInvHeader, SalesShptHeader, PurchCrMemHeader, ReturnShptHeader, TransShptHeader, ServiceInvHeader, ServiceShptHeader, IsHandled);
        if IsHandled then
            exit;

        SalesInvHeader.MarkedOnly(true);
        if not SalesInvHeader.IsEmpty() then
            SalesInvHeader.PrintRecords(false);

        SalesShptHeader.MarkedOnly(true);
        if not SalesShptHeader.IsEmpty() then begin
            SalesShptHeader.PrintRecords(false);
            OnPrintDocumentsOnAfterPrintSalesShipment(SalesShptHeader."No.");
        end;

        PurchCrMemHeader.MarkedOnly(true);
        if not PurchCrMemHeader.IsEmpty() then
            PurchCrMemHeader.PrintRecords(false);

        ReturnShptHeader.MarkedOnly(true);
        if not ReturnShptHeader.IsEmpty() then
            ReturnShptHeader.PrintRecords(false);

        TransShptHeader.MarkedOnly(true);
        if not TransShptHeader.IsEmpty() then
            TransShptHeader.PrintRecords(false);

        ServiceInvHeader.MarkedOnly(true);
        if not ServiceInvHeader.IsEmpty() then
            ServiceInvHeader.PrintRecords(false);

        ServiceShptHeader.MarkedOnly(true);
        if not ServiceShptHeader.IsEmpty() then begin
            ServiceShptHeader.PrintRecords(false);
            OnPrintDocumentsOnAfterPrintServiceShipment(ServiceShptHeader."No.");
        end;
    end;

    procedure PostUpdateWhseDocuments(var WhseShptHeaderParam: Record "Warehouse Shipment Header")
    var
        WhseShptLine2: Record "Warehouse Shipment Line";
        DeleteWhseShptLine: Boolean;
    begin
        OnBeforePostUpdateWhseDocuments(WhseShptHeaderParam);
        if TempWarehouseShipmentLine.Find('-') then begin
            repeat
                WhseShptLine2.Get(TempWarehouseShipmentLine."No.", TempWarehouseShipmentLine."Line No.");
                DeleteWhseShptLine := TempWarehouseShipmentLine."Qty. Outstanding" = TempWarehouseShipmentLine."Qty. to Ship";
                OnBeforeDeleteUpdateWhseShptLine(WhseShptLine2, DeleteWhseShptLine, TempWarehouseShipmentLine);
                if DeleteWhseShptLine then begin
                    ItemTrackingMgt.SetDeleteReservationEntries(true);
                    ItemTrackingMgt.DeleteWhseItemTrkgLines(
                      Database::"Warehouse Shipment Line", 0, TempWarehouseShipmentLine."No.", '', 0, TempWarehouseShipmentLine."Line No.", TempWarehouseShipmentLine."Location Code", true);
                    WhseShptLine2.Delete();
                    OnPostUpdateWhseDocumentsOnAfterWhseShptLine2Delete(WhseShptLine2);
                end else
                    UpdateWhseShptLine(WhseShptLine2, WhseShptHeaderParam);
            until TempWarehouseShipmentLine.Next() = 0;
            TempWarehouseShipmentLine.DeleteAll();

            OnPostUpdateWhseDocumentsOnAfterWhseShptLineBufLoop(WhseShptHeaderParam, WhseShptLine2, TempWarehouseShipmentLine);
        end;

        OnPostUpdateWhseDocumentsOnBeforeUpdateWhseShptHeader(WhseShptHeaderParam);

        WhseShptLine2.SetRange("No.", WhseShptHeaderParam."No.");
        if not WhseShptLine2.FindFirst() then begin
            WhseShptHeaderParam.DeleteRelatedLines();
            WhseShptHeaderParam.Delete();
        end else begin
            WhseShptHeaderParam."Document Status" := WhseShptHeaderParam.GetDocumentStatus(0);
            if WhseShptHeaderParam."Create Posted Header" then begin
                WhseShptHeaderParam."Last Shipping No." := WhseShptHeaderParam."Shipping No.";
                WhseShptHeaderParam."Shipping No." := '';
                WhseShptHeaderParam."Create Posted Header" := false;
            end;
            OnPostUpdateWhseDocumentsOnBeforeWhseShptHeaderParamModify(WhseShptHeaderParam, WhseShptHeader);
            WhseShptHeaderParam.Modify();
        end;

        OnAfterPostUpdateWhseDocuments(WhseShptHeaderParam);
    end;

    local procedure UpdateWhseShptLine(WhseShptLine2: Record "Warehouse Shipment Line"; var WhseShptHeaderParam: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostUpdateWhseShptLine(WhseShptLine2, TempWarehouseShipmentLine, WhseShptHeaderParam, IsHandled);
        if IsHandled then
            exit;

        WhseShptLine2.Validate("Qty. Shipped", TempWarehouseShipmentLine."Qty. Shipped" + TempWarehouseShipmentLine."Qty. to Ship");
        WhseShptLine2."Qty. Shipped (Base)" := TempWarehouseShipmentLine."Qty. Shipped (Base)" + TempWarehouseShipmentLine."Qty. to Ship (Base)";
        WhseShptLine2.Validate("Qty. Outstanding", TempWarehouseShipmentLine."Qty. Outstanding" - TempWarehouseShipmentLine."Qty. to Ship");
        WhseShptLine2."Qty. Outstanding (Base)" := TempWarehouseShipmentLine."Qty. Outstanding (Base)" - TempWarehouseShipmentLine."Qty. to Ship (Base)";
        WhseShptLine2.Status := WhseShptLine2.CalcStatusShptLine();
        OnBeforePostUpdateWhseShptLineModify(WhseShptLine2, TempWarehouseShipmentLine);
        WhseShptLine2.Modify();
        OnAfterPostUpdateWhseShptLine(WhseShptLine2, TempWarehouseShipmentLine);
    end;

    procedure GetResultMessage()
    var
        MessageText: Text[250];
        IsHandled: Boolean;
    begin
        MessageText := Text003;
        if CounterSourceDocOK > 0 then
            MessageText := MessageText + '\\' + Text004;
        if CounterSourceDocOK < CounterSourceDocTotal then
            MessageText := MessageText + '\\' + Text005;
        IsHandled := false;
        OnGetResultMessageOnBeforeShowMessage(CounterSourceDocOK, CounterSourceDocTotal, IsHandled);
        if not IsHandled then
            Message(MessageText, CounterSourceDocOK, CounterSourceDocTotal);
    end;

    procedure SetPostingSettings(PostInvoice: Boolean)
    begin
        Invoice := PostInvoice;
        InvoiceService := PostInvoice;
    end;

    procedure CreatePostedShptHeader(var PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; LastShptNo2: Code[20]; PostingDate2: Date)
    var
        WhseComment: Record "Warehouse Comment Line";
        WhseComment2: Record "Warehouse Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        LastShptNo := LastShptNo2;
        PostingDate := PostingDate2;

        if not WhseShptHeader."Create Posted Header" then begin
            PostedWhseShptHeader.Get(WhseShptHeader."Last Shipping No.");
            exit;
        end;

        PostedWhseShptHeader.Init();
        PostedWhseShptHeader."No." := WhseShptHeader."Shipping No.";
        PostedWhseShptHeader."Location Code" := WhseShptHeader."Location Code";
        PostedWhseShptHeader."Assigned User ID" := WhseShptHeader."Assigned User ID";
        PostedWhseShptHeader."Assignment Date" := WhseShptHeader."Assignment Date";
        PostedWhseShptHeader."Assignment Time" := WhseShptHeader."Assignment Time";
        PostedWhseShptHeader."No. Series" := WhseShptHeader."Shipping No. Series";
        PostedWhseShptHeader."Bin Code" := WhseShptHeader."Bin Code";
        PostedWhseShptHeader."Zone Code" := WhseShptHeader."Zone Code";
        PostedWhseShptHeader."Posting Date" := WhseShptHeader."Posting Date";
        PostedWhseShptHeader."Shipment Date" := WhseShptHeader."Shipment Date";
        PostedWhseShptHeader."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
        PostedWhseShptHeader."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
        PostedWhseShptHeader."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
        PostedWhseShptHeader.Comment := WhseShptHeader.Comment;
        PostedWhseShptHeader."Whse. Shipment No." := WhseShptHeader."No.";
        PostedWhseShptHeader."External Document No." := WhseShptHeader."External Document No.";
        OnBeforePostedWhseShptHeaderInsert(PostedWhseShptHeader, WhseShptHeader);
        PostedWhseShptHeader.Insert();
        RecordLinkManagement.CopyLinks(WhseShptHeader, PostedWhseShptHeader);
        OnAfterPostedWhseShptHeaderInsert(PostedWhseShptHeader, LastShptNo);

        WhseComment.SetRange("Table Name", WhseComment."Table Name"::"Whse. Shipment");
        WhseComment.SetRange(Type, WhseComment.Type::" ");
        WhseComment.SetRange("No.", WhseShptHeader."No.");
        if WhseComment.Find('-') then
            repeat
                WhseComment2.Init();
                WhseComment2 := WhseComment;
                WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Whse. Shipment";
                WhseComment2."No." := PostedWhseShptHeader."No.";
                WhseComment2.Insert();
            until WhseComment.Next() = 0;

        OnAfterCreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader);
    end;

    procedure CreatePostedShptLine(var WhseShptLine: Record "Warehouse Shipment Line"; var PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempHandlingSpecification: Record "Tracking Specification")
    begin
        UpdateWhseShptLineBuf(WhseShptLine);
        PostedWhseShptLine.Init();
        PostedWhseShptLine.TransferFields(WhseShptLine);
        PostedWhseShptLine."No." := PostedWhseShptHeader."No.";
        OnAfterInitPostedShptLine(WhseShptLine, PostedWhseShptLine);
        PostedWhseShptLine.Quantity := WhseShptLine."Qty. to Ship";
        PostedWhseShptLine."Qty. (Base)" := WhseShptLine."Qty. to Ship (Base)";
        if WhseShptHeader."Shipment Date" <> 0D then
            PostedWhseShptLine."Shipment Date" := PostedWhseShptHeader."Shipment Date";
        PostedWhseShptLine."Source Type" := WhseShptLine."Source Type";
        PostedWhseShptLine."Source Subtype" := WhseShptLine."Source Subtype";
        PostedWhseShptLine."Source No." := WhseShptLine."Source No.";
        PostedWhseShptLine."Source Line No." := WhseShptLine."Source Line No.";
        PostedWhseShptLine."Source Document" := WhseShptLine."Source Document";
        case PostedWhseShptLine."Source Document" of
            PostedWhseShptLine."Source Document"::"Purchase Order":
                PostedWhseShptLine."Posted Source Document" := PostedWhseShptLine."Posted Source Document"::"Posted Receipt";
            PostedWhseShptLine."Source Document"::"Service Order",
          PostedWhseShptLine."Source Document"::"Sales Order":
                PostedWhseShptLine."Posted Source Document" := PostedWhseShptLine."Posted Source Document"::"Posted Shipment";
            PostedWhseShptLine."Source Document"::"Purchase Return Order":
                PostedWhseShptLine."Posted Source Document" := PostedWhseShptLine."Posted Source Document"::"Posted Return Shipment";
            PostedWhseShptLine."Source Document"::"Sales Return Order":
                PostedWhseShptLine."Posted Source Document" := PostedWhseShptLine."Posted Source Document"::"Posted Return Receipt";
            PostedWhseShptLine."Source Document"::"Outbound Transfer":
                PostedWhseShptLine."Posted Source Document" := PostedWhseShptLine."Posted Source Document"::"Posted Transfer Shipment";
        end;
        PostedWhseShptLine."Posted Source No." := LastShptNo;
        PostedWhseShptLine."Posting Date" := PostingDate;
        PostedWhseShptLine."Whse. Shipment No." := WhseShptLine."No.";
        PostedWhseShptLine."Whse Shipment Line No." := WhseShptLine."Line No.";
        OnCreatePostedShptLineOnBeforePostedWhseShptLineInsert(PostedWhseShptLine, WhseShptLine);
        PostedWhseShptLine.Insert();

        OnCreatePostedShptLineOnBeforePostWhseJnlLine(PostedWhseShptLine, TempHandlingSpecification, WhseShptLine);
        PostWhseJnlLine(PostedWhseShptLine, TempHandlingSpecification);
        OnAfterPostWhseJnlLine(WhseShptLine);
    end;

    local procedure UpdateWhseShptLineBuf(WhseShptLine2: Record "Warehouse Shipment Line")
    begin
        TempWarehouseShipmentLine."No." := WhseShptLine2."No.";
        TempWarehouseShipmentLine."Line No." := WhseShptLine2."Line No.";
        if not TempWarehouseShipmentLine.Find() then begin
            TempWarehouseShipmentLine.Init();
            TempWarehouseShipmentLine := WhseShptLine2;
            TempWarehouseShipmentLine.Insert();
        end;
    end;

    local procedure PostWhseJnlLine(var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification")
    var
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(PostedWhseShptLine, TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        GetLocation(PostedWhseShptLine."Location Code");
        if Location."Bin Mandatory" then begin
            CreateWhseJnlLine(TempWhseJnlLine, PostedWhseShptLine);
            CheckWhseJnlLine(TempWhseJnlLine);
            OnBeforeRegisterWhseJnlLines(TempWhseJnlLine, PostedWhseShptLine);
            ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, false);
            OnPostWhseJnlLineOnAfterSplitWhseJnlLine(TempWhseJnlLine, PostedWhseShptLine, TempTrackingSpecification, TempWhseJnlLine2);
            if TempWhseJnlLine2.Find('-') then
                repeat
                    WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                until TempWhseJnlLine2.Next() = 0;
        end;

        OnAfterPostWhseJnlLines(TempWhseJnlLine, PostedWhseShptLine, TempTrackingSpecification, WhseJnlRegisterLine);
    end;

    local procedure CheckWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseJnlLine(TempWhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 0, 0, false);
    end;

    procedure CreateWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        WhseJnlLine.Init();
        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
        WhseJnlLine."Location Code" := PostedWhseShptLine."Location Code";
        WhseJnlLine."From Zone Code" := PostedWhseShptLine."Zone Code";
        WhseJnlLine."From Bin Code" := PostedWhseShptLine."Bin Code";
        WhseJnlLine."Item No." := PostedWhseShptLine."Item No.";
        WhseJnlLine.Description := PostedWhseShptLine.Description;
        WhseJnlLine."Qty. (Absolute)" := PostedWhseShptLine.Quantity;
        WhseJnlLine."Qty. (Absolute, Base)" := PostedWhseShptLine."Qty. (Base)";
        WhseJnlLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(WhseJnlLine."User ID"));
        WhseJnlLine."Variant Code" := PostedWhseShptLine."Variant Code";
        WhseJnlLine."Unit of Measure Code" := PostedWhseShptLine."Unit of Measure Code";
        WhseJnlLine."Qty. per Unit of Measure" := PostedWhseShptLine."Qty. per Unit of Measure";
        WhseJnlLine.SetSource(
            PostedWhseShptLine."Source Type", PostedWhseShptLine."Source Subtype", PostedWhseShptLine."Source No.",
            PostedWhseShptLine."Source Line No.", 0);
        WhseJnlLine."Source Document" := PostedWhseShptLine."Source Document";
        WhseJnlLine.SetWhseDocument(
            WhseJnlLine."Whse. Document Type"::Shipment, PostedWhseShptLine."No.", PostedWhseShptLine."Line No.");
        GetItemUnitOfMeasure2(PostedWhseShptLine."Item No.", PostedWhseShptLine."Unit of Measure Code");
        WhseJnlLine.Cubage := WhseJnlLine."Qty. (Absolute)" * ItemUnitOfMeasure.Cubage;
        WhseJnlLine.Weight := WhseJnlLine."Qty. (Absolute)" * ItemUnitOfMeasure.Weight;
        WhseJnlLine."Reference No." := LastShptNo;
        WhseJnlLine."Registering Date" := PostingDate;
        WhseJnlLine."Registering No. Series" := WhseShptHeader."Shipping No. Series";
        SourceCodeSetup.Get();
        case PostedWhseShptLine."Source Document" of
            PostedWhseShptLine."Source Document"::"Purchase Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rcpt.";
                end;
            PostedWhseShptLine."Source Document"::"Sales Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Shipment";
                end;
            PostedWhseShptLine."Source Document"::"Service Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup."Service Management";
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Shipment";
                end;
            PostedWhseShptLine."Source Document"::"Purchase Return Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
                end;
            PostedWhseShptLine."Source Document"::"Sales Return Order":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
                end;
            PostedWhseShptLine."Source Document"::"Outbound Transfer":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Shipment";
                end;
        end;

        OnAfterCreateWhseJnlLine(WhseJnlLine, PostedWhseShptLine);
    end;

    local procedure GetItemUnitOfMeasure2(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init()
        else
            if LocationCode <> Location.Code then
                Location.Get(LocationCode);
    end;

    local procedure CheckItemTrkgPicked(WhseShptLine: Record "Warehouse Shipment Line")
    var
        ReservationEntry: Record "Reservation Entry";
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        QtyPickedBase: Decimal;
        IsHandled: Boolean;
    begin
        if WhseShptLine."Assemble to Order" then
            exit;

        IsHandled := false;
        OnCheckItemTrkgPickedOnBeforeGetWhseItemTrkgSetup(WhseShptLine, IsHandled);
        if IsHandled then
            exit;

        if not ItemTrackingMgt.GetWhseItemTrkgSetup(WhseShptLine."Item No.") then
            exit;

        ReservationEntry.SetSourceFilter(
          WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.", WhseShptLine."Source Line No.", true);
        if ReservationEntry.Find('-') then
            repeat
                if ReservationEntry.TrackingExists() then begin
                    QtyPickedBase := 0;
                    WhseItemTrkgLine.SetTrackingKey();
                    WhseItemTrkgLine.SetTrackingFilterFromReservEntry(ReservationEntry);
                    WhseItemTrkgLine.SetSourceFilter(Database::"Warehouse Shipment Line", -1, WhseShptLine."No.", WhseShptLine."Line No.", false);
                    if WhseItemTrkgLine.Find('-') then
                        repeat
                            QtyPickedBase := QtyPickedBase + WhseItemTrkgLine."Qty. Registered (Base)";
                        until WhseItemTrkgLine.Next() = 0;
                    if QtyPickedBase < Abs(ReservationEntry."Qty. to Handle (Base)") then
                        Error(Text006,
                          WhseShptLine."No.", WhseShptLine.FieldCaption("Line No."), WhseShptLine."Line No.");
                end;
            until ReservationEntry.Next() = 0;
    end;

    local procedure CheckShippingAdviceComplete()
    var
        IsHandled: Boolean;
    begin
        // shipping advice check is performed when posting a source document
        IsHandled := false;
        OnBeforeCheckShippingAdviceComplete(WhseShptLine, IsHandled);
        if IsHandled then
            exit;
    end;

    local procedure HandleSalesLine(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        SalesLine: Record "Sales Line";
        ATOWhseShptLine: Record "Warehouse Shipment Line";
        NonATOWhseShptLine: Record "Warehouse Shipment Line";
        ATOLink: Record "Assemble-to-Order Link";
        AsmHeader: Record "Assembly Header";
        ModifyLine: Boolean;
        ATOLineFound: Boolean;
        NonATOLineFound: Boolean;
        SumOfQtyToShip: Decimal;
        SumOfQtyToShipBase: Decimal;
        IsHandled: Boolean;
        ShouldModifyShipmentDate: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleSalesLine(WhseShptLine, SalesLine, SalesHeader, WhseShptHeader, ModifyLine, IsHandled, Invoice);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", WhseShptLine."Source Subtype");
        SalesLine.SetRange("Document No.", WhseShptLine."Source No.");
        OnHandleSalesLineOnBeforeSalesLineFind(SalesLine);
        if SalesLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", SalesLine."Line No.");
                if WhseShptLine.Find('-') then begin
                    OnAfterFindWhseShptLineForSalesLine(WhseShptLine, SalesLine);
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Sales Order" then begin
                        SumOfQtyToShip := 0;
                        SumOfQtyToShipBase := 0;
                        WhseShptLine.GetATOAndNonATOLines(ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound);
                        if ATOLineFound then begin
                            SumOfQtyToShip += ATOWhseShptLine."Qty. to Ship";
                            SumOfQtyToShipBase += ATOWhseShptLine."Qty. to Ship (Base)";
                        end;
                        if NonATOLineFound then begin
                            SumOfQtyToShip += NonATOWhseShptLine."Qty. to Ship";
                            SumOfQtyToShipBase += NonATOWhseShptLine."Qty. to Ship (Base)";
                        end;

                        OnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(SalesLine, WhseShptLine, Invoice);
                        ModifyLine := SalesLine."Qty. to Ship" <> SumOfQtyToShip;
                        if ModifyLine then begin
                            UpdateSaleslineQtyToShip(SalesLine, WhseShptLine, ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound, SumOfQtyToShip, SumOfQtyToShipBase);
                            if ATOLineFound then
                                ATOLink.UpdateQtyToAsmFromWhseShptLine(ATOWhseShptLine);
                            if Invoice then
                                SalesLine.Validate(
                                  "Qty. to Invoice",
                                  SalesLine."Qty. to Ship" + SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced");
                        end;
                    end else begin
                        ModifyLine := SalesLine."Return Qty. to Receive" <> -WhseShptLine."Qty. to Ship";
                        if ModifyLine then begin
                            SalesLine.Validate("Return Qty. to Receive", -WhseShptLine."Qty. to Ship");
                            OnHandleSalesLineOnAfterValidateRetQtytoReceive(SalesLine, WhseShptLine);
                            if Invoice then
                                SalesLine.Validate(
                                  "Qty. to Invoice",
                                  -WhseShptLine."Qty. to Ship" + SalesLine."Return Qty. Received" - SalesLine."Quantity Invoiced");
                        end;
                    end;
                    ShouldModifyShipmentDate := (WhseShptHeader."Shipment Date" <> 0D) and (SalesLine."Shipment Date" <> WhseShptHeader."Shipment Date") and (WhseShptLine."Qty. to Ship" = WhseShptLine."Qty. Outstanding");
                    OnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WhseShptHeader, WhseShptLine, SalesLine, ShouldModifyShipmentDate);
                    if ShouldModifyShipmentDate then begin
                        SalesLine."Shipment Date" := WhseShptHeader."Shipment Date";
                        ModifyLine := true;
                        if ATOLineFound then
                            if AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No.") then begin
                                AsmHeader."Due Date" := WhseShptHeader."Shipment Date";
                                AsmHeader.Modify(true);
                            end;
                    end;
                    if SalesLine."Bin Code" <> WhseShptLine."Bin Code" then begin
                        SalesLine."Bin Code" := WhseShptLine."Bin Code";
                        ModifyLine := true;
                        if ATOLineFound then
                            ATOLink.UpdateAsmBinCodeFromWhseShptLine(ATOWhseShptLine);
                    end;
                end else
                    if not UpdateAllNonInventoryLines(SalesLine, ModifyLine) then
                        if not UpdateAttachedLine(SalesLine, WhseShptLine, ModifyLine) then
                            ClearSalesLineQtyToShipReceive(SalesLine, WhseShptLine, ModifyLine);
                OnBeforeSalesLineModify(SalesLine, WhseShptLine, ModifyLine, Invoice, WhseShptHeader);
                if ModifyLine then
                    SalesLine.Modify();
                OnHandleSalesLineOnAfterSalesLineModify(SalesLine, ModifyLine, WhseShptHeader);
            until SalesLine.Next() = 0;

        OnAfterHandleSalesLine(WhseShptLine, SalesHeader, Invoice, WhseShptHeader);
    end;

    local procedure UpdateSaleslineQtyToShip(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean; SumOfQtyToShip: Decimal; SumOfQtyToShipBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSaleslineQtyToShip(SalesLine, WhseShptLine, ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound, SumOfQtyToShip, SumOfQtyToShipBase, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate("Qty. to Ship", SumOfQtyToShip);
        SalesLine."Qty. to Ship (Base)" := SalesLine.MaxQtyToShipBase(SumOfQtyToShipBase);
    end;

    local procedure HandlePurchaseLine(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        PurchLine: Record "Purchase Line";
        ModifyLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandlePurchaseLine(WhseShptLine, PurchLine, WhseShptHeader, ModifyLine, IsHandled, Invoice);
        if IsHandled then
            exit;

        PurchLine.SetRange("Document Type", WhseShptLine."Source Subtype");
        PurchLine.SetRange("Document No.", WhseShptLine."Source No.");
        if PurchLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", PurchLine."Line No.");
                if WhseShptLine.Find('-') then begin
                    OnAfterFindWhseShptLineForPurchLine(WhseShptLine, PurchLine);
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Purchase Order" then begin
                        ModifyLine := PurchLine."Qty. to Receive" <> -WhseShptLine."Qty. to Ship";
                        if ModifyLine then begin
                            PurchLine.Validate("Qty. to Receive", -WhseShptLine."Qty. to Ship");
                            OnHandlePurchaseLineOnAfterValidateQtytoReceive(PurchLine, WhseShptLine);
                            if Invoice then
                                PurchLine.Validate(
                                  "Qty. to Invoice",
                                  -WhseShptLine."Qty. to Ship" + PurchLine."Quantity Received" - PurchLine."Quantity Invoiced");
                        end;
                    end else begin
                        ModifyLine := PurchLine."Return Qty. to Ship" <> WhseShptLine."Qty. to Ship";
                        if ModifyLine then begin
                            PurchLine.Validate("Return Qty. to Ship", WhseShptLine."Qty. to Ship");
                            OnHandlePurchaseLineOnAfterValidateRetQtytoShip(PurchLine, WhseShptLine);
                            if Invoice then
                                PurchLine.Validate(
                                  "Qty. to Invoice",
                                  WhseShptLine."Qty. to Ship" + PurchLine."Return Qty. Shipped" - PurchLine."Quantity Invoiced");
                        end;
                    end;
                    if (WhseShptHeader."Shipment Date" <> 0D) and
                       (PurchLine."Expected Receipt Date" <> WhseShptHeader."Shipment Date") and
                       (WhseShptLine."Qty. to Ship" = WhseShptLine."Qty. Outstanding")
                    then begin
                        PurchLine."Expected Receipt Date" := WhseShptHeader."Shipment Date";
                        ModifyLine := true;
                    end;
                    if PurchLine."Bin Code" <> WhseShptLine."Bin Code" then begin
                        PurchLine."Bin Code" := WhseShptLine."Bin Code";
                        ModifyLine := true;
                    end;
                end else
                    if not UpdateAllNonInventoryLines(PurchLine, ModifyLine) then
                        if not UpdateAttachedLine(PurchLine, WhseShptLine, ModifyLine) then
                            ClearPurchLineQtyToShipReceive(PurchLine, WhseShptLine, ModifyLine);
                OnBeforePurchLineModify(PurchLine, WhseShptLine, ModifyLine, Invoice);
                if ModifyLine then
                    PurchLine.Modify();
            until PurchLine.Next() = 0;

        OnAfterHandlePurchaseLine(WhseShptLine, PurchHeader, Invoice);
    end;

    local procedure HandleTransferLine(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        TransLine: Record "Transfer Line";
        ModifyLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleTransferLine(WhseShptLine, TransLine, WhseShptHeader, ModifyLine, IsHandled);
        if IsHandled then
            exit;

        TransLine.SetRange("Document No.", WhseShptLine."Source No.");
        TransLine.SetRange("Derived From Line No.", 0);
        if TransLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", TransLine."Line No.");
                if WhseShptLine.Find('-') then begin
                    IsHandled := false;
                    OnAfterFindWhseShptLineForTransLine(WhseShptLine, TransLine, IsHandled, ModifyLine);
                    if not IsHandled then begin
                        ModifyLine := TransLine."Qty. to Ship" <> WhseShptLine."Qty. to Ship";
                        if ModifyLine then
                            ValidateTransferLineQtyToShip(TransLine, WhseShptLine);
                    end;
                    if (WhseShptHeader."Shipment Date" <> 0D) and
                       (TransLine."Shipment Date" <> WhseShptHeader."Shipment Date") and
                       (WhseShptLine."Qty. to Ship" = WhseShptLine."Qty. Outstanding")
                    then begin
                        TransLine."Shipment Date" := WhseShptHeader."Shipment Date";
                        ModifyLine := true;
                    end;
                    if TransLine."Transfer-from Bin Code" <> WhseShptLine."Bin Code" then begin
                        TransLine."Transfer-from Bin Code" := WhseShptLine."Bin Code";
                        ModifyLine := true;
                    end;
                end else begin
                    ModifyLine := TransLine."Qty. to Ship" <> 0;
                    if ModifyLine then begin
                        TransLine.Validate("Qty. to Ship", 0);
                        TransLine.Validate("Qty. to Receive", 0);
                    end;
                end;
                OnBeforeTransLineModify(TransLine, WhseShptLine, ModifyLine);
                if ModifyLine then
                    TransLine.Modify();
            until TransLine.Next() = 0;
    end;

    local procedure ValidateTransferLineQtyToShip(var TransferLine: Record "Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateTransferLineQtyToShip(TransferLine, WarehouseShipmentLine, IsHandled);
        if IsHandled then
            exit;

        TransferLine.Validate("Qty. to Ship", WarehouseShipmentLine."Qty. to Ship");
    end;

    local procedure HandleServiceLine(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        ServLine: Record "Service Line";
        ModifyLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleServiceLine(WhseShptLine, ServLine, ModifyLine, IsHandled);
        if IsHandled then
            exit;

        ServLine.SetRange("Document Type", WhseShptLine."Source Subtype");
        ServLine.SetRange("Document No.", WhseShptLine."Source No.");
        if ServLine.Find('-') then
            repeat
                WhseShptLine.SetRange(WhseShptLine."Source Line No.", ServLine."Line No.");
                // Whse Shipment Line
                if WhseShptLine.Find('-') then begin
                    // Whse Shipment Line
                    if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Service Order" then begin
                        ModifyLine := ServLine."Qty. to Ship" <> WhseShptLine."Qty. to Ship";
                        if ModifyLine then begin
                            ServLine.Validate("Qty. to Ship", WhseShptLine."Qty. to Ship");
                            ServLine."Qty. to Ship (Base)" := WhseShptLine."Qty. to Ship (Base)";
                            OnHandleServiceLineOnSourceDocumentServiceOrderOnBeforeModifyLine(ServLine, WhseShptLine, InvoiceService);
                            if InvoiceService then begin
                                ServLine.Validate("Qty. to Consume", 0);
                                ServLine.Validate(
                                  "Qty. to Invoice",
                                  WhseShptLine."Qty. to Ship" + ServLine."Quantity Shipped" - ServLine."Quantity Invoiced" -
                                  ServLine."Quantity Consumed");
                            end;
                        end;
                    end;
                    if ServLine."Bin Code" <> WhseShptLine."Bin Code" then begin
                        ServLine."Bin Code" := WhseShptLine."Bin Code";
                        ModifyLine := true;
                    end;
                end else begin
                    ModifyLine :=
                      ((ServiceHeader."Shipping Advice" = ServiceHeader."Shipping Advice"::Partial) or
                       (ServLine.Type = ServLine.Type::Item)) and
                      ((ServLine."Qty. to Ship" <> 0) or
                       (ServLine."Qty. to Consume" <> 0) or
                       (ServLine."Qty. to Invoice" <> 0));
                    OnHandleServiceLineOnNonWhseLineOnAfterCalcModifyLine(ServLine, ModifyLine, WhseShptLine);

                    if ModifyLine then begin
                        if WhseShptLine."Source Document" = WhseShptLine."Source Document"::"Service Order" then
                            ServLine.Validate("Qty. to Ship", 0);
                        ServLine.Validate("Qty. to Invoice", 0);
                        ServLine.Validate("Qty. to Consume", 0);
                    end;
                end;
                OnBeforeServiceLineModify(ServLine, WhseShptLine, ModifyLine, Invoice, InvoiceService);
                if ModifyLine then
                    ServLine.Modify();
            until ServLine.Next() = 0;
    end;

    local procedure ClearSalesLineQtyToShipReceive(var SalesLine: Record "Sales Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean)
    begin
        ModifyLine :=
            ((SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Partial) or
            (SalesLine.Type = SalesLine.Type::Item)) and
            ((SalesLine."Qty. to Ship" <> 0) or
            (SalesLine."Return Qty. to Receive" <> 0) or
            (SalesLine."Qty. to Invoice" <> 0));
        OnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(SalesLine, ModifyLine, WhseShptLine);

        if ModifyLine then begin
            if WarehouseShipmentLine."Source Document" = WarehouseShipmentLine."Source Document"::"Sales Order" then
                SalesLine.Validate("Qty. to Ship", 0)
            else
                SalesLine.Validate("Return Qty. to Receive", 0);
            SalesLine.Validate("Qty. to Invoice", 0);
        end;
    end;

    local procedure ClearPurchLineQtyToShipReceive(var PurchLine: Record "Purchase Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean)
    begin
        ModifyLine :=
            (PurchLine."Qty. to Receive" <> 0) or
            (PurchLine."Return Qty. to Ship" <> 0) or
            (PurchLine."Qty. to Invoice" <> 0);
        OnHandlePurchLineOnNonWhseLineOnAfterCalcModifyLine(PurchLine, ModifyLine);

        if ModifyLine then begin
            if WarehouseShipmentLine."Source Document" = WarehouseShipmentLine."Source Document"::"Purchase Order" then
                PurchLine.Validate("Qty. to Receive", 0)
            else
                PurchLine.Validate("Return Qty. to Ship", 0);
            PurchLine.Validate("Qty. to Invoice", 0);
        end;
    end;

    local procedure UpdateAttachedLine(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        WhseShptLine2: Record "Warehouse Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        QtyToHandle: Decimal;
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit(false);

        if SalesLine.Type = SalesLine.Type::"Charge (Item)" then begin
            ItemChargeAssignmentSales.SetRange("Document Type", SalesLine."Document Type");
            ItemChargeAssignmentSales.SetRange("Document No.", SalesLine."Document No.");
            ItemChargeAssignmentSales.SetRange("Document Line No.", SalesLine."Line No.");
            ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", SalesLine."Document Type");
            ItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", SalesLine."Document No.");
            ItemChargeAssignmentSales.SetFilter("Qty. to Handle", '<>0');
            if not ItemChargeAssignmentSales.FindSet() then
                exit(false);
            repeat
                WhseShptLine2.Copy(WarehouseShipmentLine);
                WhseShptLine2.SetRange("Source Line No.", ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                if not WhseShptLine2.IsEmpty() then
                    QtyToHandle += ItemChargeAssignmentSales."Qty. to Handle";
            until ItemChargeAssignmentSales.Next() = 0;
        end else begin
            if SalesLine."Attached to Line No." = 0 then
                exit(false);
            WhseShptLine2.Copy(WarehouseShipmentLine);
            WhseShptLine2.SetRange("Source Line No.", SalesLine."Attached to Line No.");
            if WhseShptLine2.IsEmpty() then
                exit(false);
            QtyToHandle := SalesLine."Outstanding Quantity";
        end;

        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            ModifyLine := SalesLine."Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Qty. to Ship", QtyToHandle);
        end else begin
            ModifyLine := SalesLine."Return Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Return Qty. to Receive", QtyToHandle);
        end;

        exit(true);
    end;

    local procedure UpdateAttachedLine(var PurchLine: Record "Purchase Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        WhseShptLine2: Record "Warehouse Shipment Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        QtyToHandle: Decimal;
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit(false);

        if PurchLine.Type = PurchLine.Type::"Charge (Item)" then begin
            ItemChargeAssignmentPurch.SetRange("Document Type", PurchLine."Document Type");
            ItemChargeAssignmentPurch.SetRange("Document No.", PurchLine."Document No.");
            ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchLine."Line No.");
            ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", PurchLine."Document Type");
            ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", PurchLine."Document No.");
            ItemChargeAssignmentPurch.SetFilter("Qty. to Handle", '<>0');
            if not ItemChargeAssignmentPurch.FindSet() then
                exit(false);
            repeat
                WhseShptLine2.Copy(WarehouseShipmentLine);
                WhseShptLine2.SetRange("Source Line No.", ItemChargeAssignmentPurch."Applies-to Doc. Line No.");
                if not WhseShptLine2.IsEmpty() then
                    QtyToHandle += ItemChargeAssignmentPurch."Qty. to Handle";
            until ItemChargeAssignmentPurch.Next() = 0;
        end else begin
            if PurchLine."Attached to Line No." = 0 then
                exit(false);
            WhseShptLine2.Copy(WarehouseShipmentLine);
            WhseShptLine2.SetRange("Source Line No.", PurchLine."Attached to Line No.");
            if WhseShptLine2.IsEmpty() then
                exit(false);
            QtyToHandle := PurchLine."Outstanding Quantity";
        end;

        if PurchLine."Document Type" = PurchLine."Document Type"::Order then begin
            ModifyLine := PurchLine."Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                PurchLine.Validate("Qty. to Receive", QtyToHandle);
        end else begin
            ModifyLine := PurchLine."Return Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                PurchLine.Validate("Return Qty. to Ship", QtyToHandle);
        end;

        exit(true);
    end;

    local procedure UpdateAllNonInventoryLines(var SalesLine: Record "Sales Line"; var ModifyLine: Boolean): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if SalesLine.IsInventoriableItem() then
            exit(false);

        SalesReceivablesSetup.Get();
        if (SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::All) and
           (SalesHeader."Shipping Advice" <> SalesHeader."Shipping Advice"::Complete)
        then
            exit(false);

        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            ModifyLine := SalesLine."Qty. to Ship" <> SalesLine."Outstanding Quantity";
            if ModifyLine then
                SalesLine.Validate("Qty. to Ship", SalesLine."Outstanding Quantity");
        end else begin
            ModifyLine := SalesLine."Return Qty. to Receive" <> SalesLine."Outstanding Quantity";
            if ModifyLine then
                SalesLine.Validate("Return Qty. to Receive", SalesLine."Outstanding Quantity");
        end;

        exit(true);
    end;

    local procedure UpdateAllNonInventoryLines(var PurchaseLine: Record "Purchase Line"; var ModifyLine: Boolean): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        if PurchaseLine.IsInventoriableItem() then
            exit(false);

        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::All then
            exit(false);

        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then begin
            ModifyLine := PurchaseLine."Qty. to Receive" <> PurchaseLine."Outstanding Quantity";
            if ModifyLine then
                PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Outstanding Quantity");
        end else begin
            ModifyLine := PurchaseLine."Return Qty. to Ship" <> PurchaseLine."Outstanding Quantity";
            if ModifyLine then
                PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine."Outstanding Quantity");
        end;

        exit(true);
    end;

    procedure SetWhseJnlRegisterCU(var NewWhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        WhseJnlRegisterLine := NewWhseJnlRegisterLine;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure GetCounterSourceDocTotal(): Integer;
    begin
        exit(CounterSourceDocTotal);
    end;

    procedure GetCounterSourceDocOK(): Integer;
    begin
        exit(CounterSourceDocOK);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceDocument(SourceHeader: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceDocument(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Print: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SuppressCommit: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferLineQtyToShip(var TransferLine: Record "Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseShptLines(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; Invoice: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedShptHeader(var PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseShptLineForTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentHeader(var WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedShptLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandlePurchaseLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; PurchHeader: Record "Purchase Header"; var Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleSalesLine(var WhseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header"; var Invoice: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseShptHeaderInsert(PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; LastShptNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLines(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; WhseJnlRegisterLine: codeunit "Whse. Jnl.-Register Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentLineBuf: Record "Warehouse Shipment Line"; var WhseShptHeaderParam: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseShptLineModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WhseShptLineBuf: Record "Warehouse Shipment Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TempWarehouseShipmentLineBuffer: Record "Warehouse Shipment Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseDocuments(var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PurchaseHeader: Record "Purchase Header"; Invoice: Boolean; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header"; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServicePost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; ServiceHeader: Record "Service Header"; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPostShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TransferHeader: Record "Transfer Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShippingAdviceComplete(var WhseShptLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; Invoice: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineModify(var TransferLine: Record "Transfer Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(var PurchaseHeader: Record "Purchase Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean; Invoice: Boolean; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeServiceHeaderModify(var ServiceHeader: Record "Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(var TransferHeader: Record "Transfer Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchaseHeaderUpdatePostingDate(var PurchaseHeader: Record "Purchase Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeTransferHeaderUpdatePostingDate(var TransferHeader: Record "Transfer Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeServiceHeaderUpdatePostingDate(var ServiceHeader: Record "Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyHeader: Boolean; var ValidatePostingDate: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocument(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var CounterDocOK: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeCaseTransferLine(TransferHeader: Record "Transfer Header"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteUpdateWhseShptLine(WhseShptLine: Record "Warehouse Shipment Line"; var DeleteWhseShptLine: Boolean; var WhseShptLineBuf: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSourceDocumentHeader(var WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseShptHeaderInsert(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocumentStatus(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Invoice: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandlePurchaseLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PurchLine: Record "Purchase Line"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleTransferLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransLine: Record "Transfer Line"; WhseShptHeader: Record "Warehouse Shipment Header"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDocument(var WhseShptLine: Record "Warehouse Shipment Line"; var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var TransferHeader: Record "Transfer Header"; var ServiceHeader: Record "Service Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseDocuments(var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourcePurchDocument(var PurchPost: Codeunit "Purch.-Post"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceTransferDocument(var TransferPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransHeader: Record "Transfer Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterWhseJnlLines(var TempWhseJnlLine: Record "Warehouse Journal Line"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryPostSourcePurchDocument(var PurchPost: Codeunit "Purch.-Post"; var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryPostSourceTransferDocument(var TransferPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSaleslineQtyToShip(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean; SumOfQtyToShip: Decimal; SumOfQtyToShipBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedShptLineOnBeforePostWhseJnlLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedShptLineOnBeforePostedWhseShptLineInsert(var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGetWhseShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterWhseShptHeaderModify(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Print: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(var SalesHeader: Record "Sales Header"; Invoice: Boolean; var NewCalledFromWhseDoc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReleaseSalesHeader(var SalesHeader: Record "Sales Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(var SalesHeader: Record "Sales Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ValidatePostingDate: Boolean; var IsHandled: Boolean; var ModifyHeader: Boolean; var WhseShptHeader: Record "Warehouse Shipment Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterValidateRetQtytoReceive(var SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterCalcShouldModifyShipmentDate(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line"; var ShouldModifyShipmentDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnAfterSalesLineModify(var SalesLine: Record "Sales Line"; ModifyLine: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchLineOnNonWhseLineOnAfterCalcModifyLine(var PurchLine: Record "Purchase Line"; var ModifyLine: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchaseLineOnAfterValidateQtytoReceive(var PurchLine: Record "Purchase Line"; var WhseShptLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandlePurchaseLineOnAfterValidateRetQtytoShip(var PurchLine: Record "Purchase Line"; var WhseShptLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesInvoice(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesShipment(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesShptHeader: Record "Sales Shipment Header"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintPurchReturnShipment(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintPurchCreditMemo(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintTransferShipment(var Transfer: Record "Transfer Shipment Header"; var IsHandled: Boolean; var TransHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintServiceInvoice(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintServiceShipment(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnAfterWhseShptLine2Delete(var WhseShptLine2: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeUpdateWhseShptHeader(var WhseShptHeaderParam: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrentKeyForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrint(var Print: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilterForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSourceForFilterWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnAfterSalesPost(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeSalesPost(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesDocuments(LastShippingNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintDocumentsOnAfterPrintSalesShipment(ShipmentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintDocumentsOnAfterPrintServiceShipment(ServiceShipmentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReopenPurchHeader(var WhseShptLine: Record "Warehouse Shipment Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostSalesHeader(var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var CounterSourceDocOK: Integer; SuppressCommit: Boolean; var IsHandled: Boolean; var Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeWhseShptHeaderParamModify(var WhseShptHeaderParam: Record "Warehouse Shipment Header"; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetResultMessageOnBeforeShowMessage(var CounterSourceDocOK: Integer; var CounterSourceDocTotal: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocumentOnElseCase(var SourceHeader: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnNonWhseLineOnAfterCalcModifyLine(var SalesLine: Record "Sales Line"; var ModifyLine: Boolean; WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnBeforeSalesLineFind(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleSalesLineOnSourceDocumentSalesOrderOnBeforeModifyLine(var SalesLine: Record "Sales Line"; WhseShptLine: Record "Warehouse Shipment Line"; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseShptLine2: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentAfterGetWhseShptHeader(WhseShptLine: Record "Warehouse Shipment Line"; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnAfterWhseShptLineBufLoop(var WhseShptHeaderParam: Record "Warehouse Shipment Header"; WhseShptLine2: Record "Warehouse Shipment Line"; WhseShptLineBuf: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceSalesDocument(var CounterSourceDocOK: Integer; var SalesPost: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTryPostSourcePurchDocument(var CounterSourceDocOK: Integer; var PurchPost: Codeunit "Purch.-Post"; var PurchHeader: Record "Purchase Header"; Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourcePurchDocument(var CounterSourceDocOK: Integer; var PurchPost: Codeunit "Purch.-Post"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTryPostSourceTransferDocument(var CounterSourceDocOK: Integer; var TransferPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransHeader: Record "Transfer Header"; Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceTransferDocument(var CounterSourceDocOK: Integer; var TransferPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnAfterSplitWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification"; var TempWhseJnlLine2: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrkgPickedOnBeforeGetWhseItemTrkgSetup(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePostPurchHeader(var PurchPost: Codeunit "Purch.-Post"; var PurchHeader: Record "Purchase Header"; WhseShptHeader: Record "Warehouse Shipment Header"; var CounterSourceDocOK: Integer; var IsHandled: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineModify(var ServiceLine: Record "Service Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; Invoice: Boolean; var InvoiceService: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentBeforeRunServicePost()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentAfterRunServicePost()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleServiceLineOnNonWhseLineOnAfterCalcModifyLine(var ServiceLine: Record "Service Line"; var ModifyLine: Boolean; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocuments(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; var TransferShipmentHeader: Record "Transfer Shipment Header"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceShipmentHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleServiceLineOnSourceDocumentServiceOrderOnBeforeModifyLine(var ServiceLine: Record "Service Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var InvoiceService: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterWhseShptLineSetFilters(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ServiceLine: Record "Service Line"; var ModifyLine: Boolean; var IsHandled: Boolean)
    begin
    end;
}

