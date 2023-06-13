codeunit 7324 "Whse.-Activity-Post"
{
    Permissions = TableData "Warehouse Setup" = rm,
                  TableData "Warehouse Journal Batch" = rimd,
                  TableData "Posted Invt. Put-away Header" = ri,
                  TableData "Posted Invt. Put-away Line" = ri,
                  TableData "Posted Invt. Pick Header" = ri,
                  TableData "Posted Invt. Pick Line" = ri;
    TableNo = "Warehouse Activity Line";

    trigger OnRun()
    begin
        WhseActivLine.Copy(Rec);
        Code();
        Rec := WhseActivLine;
    end;

    var
        Text000: Label 'Warehouse Activity    #1##########\\';
        Text001: Label 'Checking lines        #2######\';
        Text002: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
        Location: Record Location;
        Item: Record Item;
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        WhseSetup: Record "Warehouse Setup";
        WhseRequest: Record "Warehouse Request";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        SourceCodeSetup: Record "Source Code Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        PurchPostPrint: Codeunit "Purch.-Post + Print";
        SalesPostPrint: Codeunit "Sales-Post + Print";
        Window: Dialog;
        PostedSourceNo: Code[20];
        PostedSourceType: Integer;
        PostedSourceSubType: Integer;
        NoOfRecords: Integer;
        LineCount: Integer;
        PostingReference: Integer;
        HideDialog: Boolean;
        Text005: Label 'The source document %1 %2 is not released.';
        InvoiceSourceDoc: Boolean;
        PrintDoc: Boolean;
        SuppressCommit: Boolean;
        IsPreview: Boolean;
        PostingDateErr: Label 'is before the posting date';
        InventoryNotAvailableErr: Label '%1 %2 is not available on inventory or it has already been reserved for another document.', Comment = '%1 = Item Tracking ID, %2 = Item Tracking No."';

    local procedure "Code"()
    var
        TransferOrderPostPrint: Codeunit "TransferOrder-Post + Print";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ItemTrackingRequired: Boolean;
        Selection: Option " ",Shipment,Receipt;
        ForceDelete: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseActivLine, SuppressCommit, IsHandled);
        IF IsHandled then
            exit;

        GetPostingReference();

        with WhseActivHeader do begin
            WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
            WhseActivLine.SetRange("No.", WhseActivLine."No.");
            WhseActivLine.SetFilter("Qty. to Handle", '<>0');
            if not WhseActivLine.Find('-') then
                Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

            Get(WhseActivLine."Activity Type", WhseActivLine."No.");
            GetLocation("Location Code");

            if Type = Type::"Invt. Put-away" then
                WhseRequest.Get(
                  WhseRequest.Type::Inbound, "Location Code",
                  "Source Type", "Source Subtype", "Source No.")
            else
                WhseRequest.Get(
                  WhseRequest.Type::Outbound, "Location Code",
                  "Source Type", "Source Subtype", "Source No.");
            if WhseRequest."Document Status" <> WhseRequest."Document Status"::Released then
                Error(Text005, "Source Document", "Source No.");

            if not HideDialog then begin
                Window.Open(
                  Text000 +
                  Text001 +
                  Text002);
                Window.Update(1, "No.");
            end;

            // Check Lines
            OnBeforeCheckLines(WhseActivHeader);
            LineCount := 0;
            if WhseActivLine.Find('-') then begin
                TempWhseActivLine.SetCurrentKey(
                  "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                repeat
                    LineCount := LineCount + 1;
                    if not HideDialog then
                        Window.Update(2, LineCount);

                    CheckWarehouseActivityLine(WhseActivLine, WhseActivHeader, Location);

                    ItemTrackingRequired := CheckItemTracking(WhseActivLine);
                    if ItemTrackingRequired then
                        CheckAvailability(WhseActivLine);
                    InsertTempWhseActivLine(WhseActivLine, ItemTrackingRequired);
                until WhseActivLine.Next() = 0;
                CheckWhseItemTrackingAgainstSource();
            end;
            NoOfRecords := LineCount;

            // Posting lines
            SourceCodeSetup.Get();
            LineCount := 0;
            WhseActivLine.LockTable();
            if WhseActivLine.Find('-') then begin
                LockPostedTables(WhseActivHeader);

                PostWhseActivityLine(WhseActivHeader, WhseActivLine);

                OnCodeOnAfterCreatePostedWhseActivDocument(WhseActivHeader);
            end;

            if IsPreview then
                GenJnlPostPreview.ThrowError();

            // Modify/delete activity header and activity lines
            TempWhseActivLine.DeleteAll();

            WhseActivLine.SetCurrentKey(
              "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.");
            if WhseActivLine.Find('-') then
                repeat
                    ForceDelete := false;
                    OnBeforeWhseActivLineDelete(WhseActivLine, ForceDelete, HideDialog);
                    if (WhseActivLine."Qty. Outstanding" = WhseActivLine."Qty. to Handle") or ForceDelete then
                        WhseActivLine.Delete()
                    else begin
                        WhseActivLine.Validate(
                          "Qty. Outstanding", WhseActivLine."Qty. Outstanding" - WhseActivLine."Qty. to Handle");
                        if HideDialog then
                            WhseActivLine.Validate("Qty. to Handle", 0);
                        WhseActivLine.Validate(
                          "Qty. Handled", WhseActivLine.Quantity - WhseActivLine."Qty. Outstanding");
                        WhseActivLine.Modify();
                        OnAfterWhseActivLineModify(WhseActivLine);
                    end;
                until WhseActivLine.Next() = 0;

            WhseActivLine.Reset();
            WhseActivLine.SetRange("Activity Type", Type);
            WhseActivLine.SetRange("No.", "No.");
            WhseActivLine.SetFilter("Qty. Outstanding", '<>%1', 0);
            IsHandled := false;
            OnCodeOnAfterWhseActivLineSetFilters(WhseActivHeader, WhseActivLine, IsHandled);
            if not IsHandled then
                if not WhseActivLine.Find('-') then
                    Delete(true);

            if not HideDialog then
                Window.Close();

            if PrintDoc then
                case "Source Document" of
                    "Source Document"::"Purchase Order",
                  "Source Document"::"Purchase Return Order":
                        PurchPostPrint.GetReport(PurchHeader);
                    "Source Document"::"Sales Order",
                  "Source Document"::"Sales Return Order":
                        SalesPostPrint.GetReport(SalesHeader);
                    "Source Document"::"Inbound Transfer":
                        TransferOrderPostPrint.PrintReport(TransHeader, Selection::Receipt);
                    "Source Document"::"Outbound Transfer":
                        TransferOrderPostPrint.PrintReport(TransHeader, Selection::Shipment);
                end;

            OnAfterCode(WhseActivLine, SuppressCommit, PrintDoc);
            if not SuppressCommit then
                Commit();
            OnAfterPostWhseActivHeader(WhseActivHeader, PurchHeader, SalesHeader, TransHeader);

            Clear(WhseJnlRegisterLine);
        end;
    end;

    local procedure CheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location)
    begin
        WarehouseActivityLine.TestField("Item No.");
        if Location."Bin Mandatory" then begin
            WarehouseActivityLine.TestField("Unit of Measure Code");
            WarehouseActivityLine.TestField("Bin Code");
            if WarehouseActivityLine."Activity Type" in [WarehouseActivityLine."Activity Type"::"Invt. Movement", WarehouseActivityLine."Activity Type"::"Invt. Put-away", WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Activity Type"::"Put-away"] then
                WarehouseActivityLine.CheckIncreaseCapacity(false, true);
        end;

        OnAfterCheckWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, Location);
    end;

    local procedure InsertTempWhseActivLine(WhseActivLine: Record "Warehouse Activity Line"; ItemTrackingRequired: Boolean)
    begin
        OnBeforeInsertTempWhseActivLine(WhseActivLine, ItemTrackingRequired);

        with WhseActivLine do begin
            TempWhseActivLine.SetSourceFilter(
              "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", false);
            if "Source Document" = "Source Document"::"Job Usage" then
                TempWhseActivLine.SetRange("Bin Code", "Bin Code"); // Split the lines based on bin for jobs.
            if TempWhseActivLine.Find('-') then begin
                TempWhseActivLine."Qty. to Handle" += "Qty. to Handle";
                TempWhseActivLine."Qty. to Handle (Base)" += "Qty. to Handle (Base)";
                OnBeforeTempWhseActivLineModify(TempWhseActivLine, WhseActivLine);
                TempWhseActivLine.Modify();
            end else begin
                TempWhseActivLine.Init();
                TempWhseActivLine := WhseActivLine;
                OnBeforeTempWhseActivLineInsert(TempWhseActivLine, WhseActivLine);
                TempWhseActivLine.Insert();
                if ItemTrackingRequired and
                   ("Activity Type" in ["Activity Type"::"Invt. Pick", "Activity Type"::"Invt. Put-away"])
                then
                    ItemTrackingMgt.SynchronizeWhseActivItemTrkg(WhseActivLine, IsPreview);
            end;
        end;
    end;

    local procedure GetPostingReference()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPostingReference(PostingReference, IsHandled);
        if IsHandled then
            exit;

        PostingReference := WhseSetup.GetNextReference();
    end;

    local procedure InitSourceDocument()
    var
        SalesLine: Record "Sales Line";
        ModifyHeader: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeInitSourceDocument(WhseActivHeader);

        with WhseActivHeader do
            case "Source Type" of
                DATABASE::"Purchase Line":
                    begin
                        PurchHeader.Get("Source Subtype", "Source No.");
                        PurchLine.SetRange("Document Type", "Source Subtype");
                        PurchLine.SetRange("Document No.", "Source No.");
                        OnInitSourceDocumentOnAfterSetPurchaseLineFilters(PurchLine, PurchHeader, WhseActivHeader);
                        if PurchLine.Find('-') then
                            repeat
                                IsHandled := false;
                                OnInitSourceDocumentOnBeforePurchLineLoopIteration(PurchHeader, PurchLine, WhseActivHeader, IsHandled);
                                if not IsHandled then begin
                                    if "Source Document" = "Source Document"::"Purchase Order" then
                                        PurchLine.Validate("Qty. to Receive", 0)
                                    else
                                        PurchLine.Validate("Return Qty. to Ship", 0);
                                    PurchLine.Validate("Qty. to Invoice", 0);
                                    ModifyPurchaseLine(PurchLine);
                                    OnAfterPurchLineModify(PurchLine);
                                end;
                            until PurchLine.Next() = 0;

                        ReleasePurchDocument(ModifyHeader);

                        if "External Document No." <> '' then begin
                            PurchHeader."Vendor Shipment No." := "External Document No.";
                            ModifyHeader := true;
                        end;
                        if "External Document No.2" <> '' then begin
                            if "Source Document" = "Source Document"::"Purchase Order" then
                                PurchHeader."Vendor Invoice No." := "External Document No.2"
                            else
                                PurchHeader."Vendor Cr. Memo No." := "External Document No.2";
                            ModifyHeader := true;
                        end;
                        ModifyPurchaseHeader(PurchHeader, WhseActivHeader, ModifyHeader);
                    end;
                DATABASE::"Sales Line":
                    begin
                        SalesHeader.Get("Source Subtype", "Source No.");
                        SalesLine.SetRange("Document Type", "Source Subtype");
                        SalesLine.SetRange("Document No.", "Source No.");
                        if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Complete then
                            SalesLine.SetRange(Type, SalesLine.Type::Item);
                        OnInitSourceDocumentOnAfterSetSalesLineFilters(SalesLine, SalesHeader, WhseActivHeader);
                        if SalesLine.Find('-') then
                            repeat
                                IsHandled := false;
                                OnInitSourceDocumentOnBeforeSalesLineLoopIteration(SalesHeader, SalesLine, WhseActivHeader, IsHandled);
                                if not IsHandled then begin
                                    if "Source Document" = "Source Document"::"Sales Order" then
                                        SalesLine.Validate("Qty. to Ship", 0)
                                    else
                                        SalesLine.Validate("Return Qty. to Receive", 0);
                                    SalesLine.Validate("Qty. to Invoice", 0);
                                    ModifySalesLine(SalesLine);
                                    OnAfterSalesLineModify(SalesLine);
                                end;
                            until SalesLine.Next() = 0;

                        ReleaseSalesDocument(ModifyHeader);

                        if "External Document No." <> '' then begin
                            SalesHeader."External Document No." := "External Document No.";
                            ModifyHeader := true;
                        end;
                        ModifySalesHeader(SalesHeader, WhseActivHeader, ModifyHeader);
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransHeader.Get("Source No.");
                        TransLine.SetRange("Document No.", TransHeader."No.");
                        TransLine.SetRange("Derived From Line No.", 0);
                        TransLine.SetFilter("Item No.", '<>%1', '');
                        OnInitSourceDocumentOnAfterTransLineSetFilters(TransLine, TransHeader, WhseActivHeader);
                        if TransLine.Find('-') then
                            repeat
                                IsHandled := false;
                                OnInitSourceDocumentOnBeforeTransLineLoopIteration(TransHeader, TransLine, WhseActivHeader, IsHandled);
                                if not IsHandled then begin
                                    TransLine.Validate("Qty. to Ship", 0);
                                    TransLine.Validate("Qty. to Receive", 0);
                                    ModifyTransferLine(TransLine);
                                    OnAfterTransLineModify(TransLine);
                                end;
                            until TransLine.Next() = 0;

                        OnInitSourceDocumentOnAfterTransferLineLoopIteration(TransLine, TransHeader, WhseActivHeader, ModifyHeader);

                        if (TransHeader."Posting Date" <> "Posting Date") and ("Posting Date" <> 0D) then begin
                            TransHeader.CalledFromWarehouse(true);
                            TransHeader.Validate("Posting Date", "Posting Date");
                            ModifyHeader := true;
                        end;
                        if "External Document No." <> '' then begin
                            TransHeader."External Document No." := "External Document No.";
                            ModifyHeader := true;
                        end;
                        ModifyTransferHeader(TransHeader, WhseActivHeader, ModifyHeader);
                    end;
            end;

        OnAfterInitSourceDocument(WhseActivHeader);
    end;

    local procedure ReleasePurchDocument(var ModifyHeader: Boolean)
    var
        PurchRelease: Codeunit "Release Purchase Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReleasePurchDocument(PurchHeader, WhseActivHeader, ModifyHeader, IsHandled);
        if IsHandled then
            exit;

        if (PurchHeader."Posting Date" <> WhseActivHeader."Posting Date") and (WhseActivHeader."Posting Date" <> 0D) then begin
            PurchRelease.SetSkipWhseRequestOperations(true);
            PurchRelease.Reopen(PurchHeader);
            PurchRelease.SetSkipCheckReleaseRestrictions();
            PurchHeader.SetHideValidationDialog(true);
            PurchHeader.Validate("Posting Date", WhseActivHeader."Posting Date");
            OnReleasePurchDocumentOnBeforePurchReleaseRun(PurchHeader, WhseActivHeader);
            PurchRelease.Run(PurchHeader);
            OnReleasePurchDocumentOnAfterPurchReleaseRun(PurchHeader, WhseActivHeader);
            ModifyHeader := true;
        end;
    end;

    local procedure ReleaseSalesDocument(var ModifyHeader: Boolean)
    var
        SalesRelease: Codeunit "Release Sales Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReleaseSalesDocument(SalesHeader, WhseActivHeader, ModifyHeader, IsHandled);
        if not IsHandled then
            if (SalesHeader."Posting Date" <> WhseActivHeader."Posting Date") and (WhseActivHeader."Posting Date" <> 0D) then begin
                SalesRelease.SetSkipWhseRequestOperations(true);
                SalesRelease.Reopen(SalesHeader);
                SalesRelease.SetSkipCheckReleaseRestrictions();
                SalesHeader.SetHideValidationDialog(true);
                SalesHeader.Validate("Posting Date", WhseActivHeader."Posting Date");
                OnReleaseSalesDocumentOnBeforeSalesReleaseRun(SalesHeader, WhseActivHeader);
                SalesRelease.Run(SalesHeader);
                OnReleaseSalesDocumentOnAfterSalesReleaseRun(SalesHeader, WhseActivHeader);
                ModifyHeader := true;
            end;
        OnAfterReleaseSalesDocument(SalesHeader, WhseActivHeader, ModifyHeader);
    end;

    local procedure ModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ModifyHeader: Boolean)
    begin
        OnBeforeModifyPurchaseHeader(PurchaseHeader, WarehouseActivityHeader, ModifyHeader);
        if ModifyHeader then
            PurchaseHeader.Modify();
    end;

    local procedure ModifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        OnBeforeModifyPurchaseLine(PurchaseLine);
        PurchaseLine.Modify();
    end;

    local procedure ModifySalesHeader(var SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ModifyHeader: Boolean)
    begin
        OnBeforeModifySalesHeader(SalesHeader, WarehouseActivityHeader, ModifyHeader);
        if ModifyHeader then
            SalesHeader.Modify();
    end;

    local procedure ModifySalesLine(var SalesLine: Record "Sales Line")
    begin
        OnBeforeModifySalesLine(SalesLine);
        SalesLine.Modify();
    end;

    local procedure ModifyTransferHeader(var TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ModifyHeader: Boolean)
    begin
        OnBeforeModifyTransferHeader(TransferHeader, WarehouseActivityHeader, ModifyHeader);
        if ModifyHeader then
            TransferHeader.Modify();
    end;

    local procedure ModifyTransferLine(var TransferLine: Record "Transfer Line")
    begin
        OnBeforeModifyTransferLine(TransferLine);
        TransferLine.Modify();
    end;

    local procedure UpdateSourceDocument()
    var
        SalesLine: Record "Sales Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        OnBeforeUpdateSourceDocument(TempWhseActivLine);

        with TempWhseActivLine do
            case "Source Type" of
                DATABASE::"Purchase Line":
                    begin
                        if "Activity Type" = "Activity Type"::"Invt. Pick" then begin
                            "Qty. to Handle" := -"Qty. to Handle";
                            "Qty. to Handle (Base)" := -"Qty. to Handle (Base)";
                        end;
                        PurchLine.Get("Source Subtype", "Source No.", "Source Line No.");
                        OnUpdateSourceDocumentOnAfterGetPurchLine(PurchLine, TempWhseActivLine);
                        if "Source Document" = "Source Document"::"Purchase Order" then begin
                            if (PurchLine."Outstanding Quantity" <> 0) and ("Qty. to Handle" > PurchLine."Outstanding Quantity") then
                                "Qty. to Handle" := PurchLine."Outstanding Quantity";
                            PurchLine.Validate("Qty. to Receive", "Qty. to Handle");
                            PurchLine."Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                            if InvoiceSourceDoc then
                                PurchLine.Validate("Qty. to Invoice", "Qty. to Handle");
                        end else begin
                            if (PurchLine."Outstanding Quantity" <> 0) and (-"Qty. to Handle" > PurchLine."Outstanding Quantity") then
                                "Qty. to Handle" := -PurchLine."Outstanding Quantity";
                            PurchLine.Validate("Return Qty. to Ship", -"Qty. to Handle");
                            PurchLine."Return Qty. to Ship (Base)" := -"Qty. to Handle (Base)";
                            if InvoiceSourceDoc then
                                PurchLine.Validate("Qty. to Invoice", -"Qty. to Handle");
                        end;
                        PurchLine."Bin Code" := "Bin Code";
                        OnUpdateSourceDocumentOnBeforePurchLineModify(PurchLine, TempWhseActivLine);
                        PurchLine.Modify();
                        OnAfterPurchLineModify(PurchLine);
                        OnUpdateSourceDocumentOnAfterPurchLineModify(PurchLine, TempWhseActivLine);
                        UpdateAttachedLines(PurchLine);
                    end;
                DATABASE::"Sales Line":
                    begin
                        if "Activity Type" = "Activity Type"::"Invt. Pick" then begin
                            "Qty. to Handle" := -"Qty. to Handle";
                            "Qty. to Handle (Base)" := -"Qty. to Handle (Base)";
                        end;
                        SalesLine.Get("Source Subtype", "Source No.", "Source Line No.");
                        OnUpdateSourceDocumentOnAfterGetSalesLine(SalesLine, TempWhseActivLine);
                        if "Source Document" = "Source Document"::"Sales Order" then begin
                            SalesLine.Validate("Qty. to Ship", -"Qty. to Handle");
                            SalesLine."Qty. to Ship (Base)" := -"Qty. to Handle (Base)";
                            if InvoiceSourceDoc then
                                SalesLine.Validate("Qty. to Invoice", -"Qty. to Handle");
                        end else begin
                            SalesLine.Validate("Return Qty. to Receive", "Qty. to Handle");
                            SalesLine."Return Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                            if InvoiceSourceDoc then
                                SalesLine.Validate("Qty. to Invoice", "Qty. to Handle");
                        end;
                        SalesLine."Bin Code" := "Bin Code";
                        SalesLine.Modify();
                        if "Assemble to Order" then begin
                            ATOLink.UpdateQtyToAsmFromInvtPickLine(TempWhseActivLine);
                            ATOLink.UpdateAsmBinCodeFromInvtPickLine(TempWhseActivLine);
                        end;
                        OnUpdateSourceDocumentOnBeforeSalesLineModify(SalesLine, TempWhseActivLine);
                        OnAfterSalesLineModify(SalesLine);
                        OnUpdateSourceDocumentOnAfterSalesLineModify(SalesLine, TempWhseActivLine);
                        UpdateAttachedLines(SalesLine);
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransHeader.Get("Source No.");
                        TransLine.Get("Source No.", "Source Line No.");
                        OnUpdateSourceDocumentOnAfterGetTransLine(TransLine, TempWhseActivLine);
                        if "Activity Type" = "Activity Type"::"Invt. Put-away" then begin
                            TransLine."Transfer-To Bin Code" := "Bin Code";
                            TransLine.Validate("Qty. to Receive", "Qty. to Handle");
                            TransLine."Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                        end else begin
                            TransLine."Transfer-from Bin Code" := "Bin Code";
                            TransLine.Validate("Qty. to Ship", "Qty. to Handle");
                            TransLine."Qty. to Ship (Base)" := "Qty. to Handle (Base)";
                            if TransHeader."Direct Transfer" then begin
                                TransLine.Validate("Qty. to Receive", "Qty. to Handle");
                                TransLine."Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                            end;
                        end;
                        OnUpdateSourceDocumentOnBeforeTransLineModify(TransLine, TempWhseActivLine);
                        TransLine.Modify();
                        OnUpdateSourceDocumentOnAfterTransLineModify(TransLine, TempWhseActivLine);
                    end;
            end;
    end;

    local procedure UpdateUnhandledTransLine(TransHeaderNo: Code[20])
    var
        TransLine: Record "Transfer Line";
    begin
        with TransLine do begin
            SetRange("Document No.", TransHeaderNo);
            SetRange("Derived From Line No.", 0);
            SetRange("Qty. to Ship", 0);
            SetRange("Qty. to Receive", 0);
            if FindSet() then
                repeat
                    if "Qty. in Transit" <> 0 then
                        Validate("Qty. to Receive", "Qty. in Transit");
                    if "Outstanding Quantity" <> 0 then
                        Validate("Qty. to Ship", "Outstanding Quantity");
                    OnBeforeUnhandledTransLineModify(TransLine);
                    Modify();
                until Next() = 0;
        end;
    end;

    local procedure PostSourceDocument(WhseActivHeader: Record "Warehouse Activity Header")
    var
        InventorySetup: Record "Inventory Setup";
        PurchPost: Codeunit "Purch.-Post";
        SalesPost: Codeunit "Sales-Post";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferPostShip: Codeunit "TransferOrder-Post Shipment";
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        OnBeforePostSourceDocument(WhseActivHeader, PostedSourceType, PostedSourceNo, PostedSourceSubType, HideDialog, SuppressCommit);

        with WhseActivHeader do
            case "Source Type" of
                DATABASE::"Purchase Line":
                    begin
                        Clear(PurchPost);
                        if not (SuppressCommit or IsPreview) then
                            Commit();
                        if "Source Document" = "Source Document"::"Purchase Order" then
                            PurchHeader.Receive := true
                        else
                            PurchHeader.Ship := true;
                        PurchHeader.Invoice := InvoiceSourceDoc;
                        PurchHeader."Posting from Whse. Ref." := PostingReference;
                        OnPostSourceDocumentOnBeforePurchPostRun(WhseActivHeader, PurchHeader);
                        PurchPost.SetSuppressCommit(IsPreview or SuppressCommit);
                        PurchPost.Run(PurchHeader);
                        if "Source Document" = "Source Document"::"Purchase Order" then begin
                            PostedSourceType := DATABASE::"Purch. Rcpt. Header";
                            PostedSourceNo := PurchHeader."Last Receiving No.";
                        end else begin
                            PostedSourceType := DATABASE::"Return Shipment Header";
                            PostedSourceNo := PurchHeader."Last Return Shipment No.";
                        end;
                        PostedSourceSubType := 0;
                    end;
                DATABASE::"Sales Line":
                    begin
                        Clear(SalesPost);
                        if not (SuppressCommit or IsPreview) then
                            Commit();
                        if "Source Document" = "Source Document"::"Sales Order" then
                            SalesHeader.Ship := true
                        else
                            SalesHeader.Receive := true;
                        SalesHeader.Invoice := InvoiceSourceDoc;
                        SalesHeader."Posting from Whse. Ref." := PostingReference;
                        SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
                        OnPostSourceDocumentOnBeforeSalesPostRun(WhseActivHeader, SalesHeader);
                        SalesPost.SetSuppressCommit(SuppressCommit or IsPreview);
                        SalesPost.Run(SalesHeader);
                        if "Source Document" = "Source Document"::"Sales Order" then begin
                            PostedSourceType := DATABASE::"Sales Shipment Header";
                            PostedSourceNo := SalesHeader."Last Shipping No.";
                        end else begin
                            PostedSourceType := DATABASE::"Return Receipt Header";
                            PostedSourceNo := SalesHeader."Last Return Receipt No.";
                        end;
                        PostedSourceSubType := 0;
                    end;
                DATABASE::"Transfer Line":
                    begin
                        Clear(TransferPostReceipt);
                        if not (SuppressCommit or IsPreview) then
                            Commit();
                        if Type = Type::"Invt. Put-away" then begin
                            if HideDialog then
                                TransferPostReceipt.SetHideValidationDialog(HideDialog);
                            TransHeader."Posting from Whse. Ref." := PostingReference;
                            OnPostSourceDocumentOnBeforeTransferPostReceiptRun(TransHeader, WhseActivHeader);
                            TransferPostReceipt.Run(TransHeader);
                            PostedSourceType := DATABASE::"Transfer Receipt Header";
                            PostedSourceNo := TransHeader."Last Receipt No.";
                        end else begin
                            if HideDialog then
                                TransferPostShip.SetHideValidationDialog(HideDialog);
                            TransHeader."Posting from Whse. Ref." := PostingReference;
                            if not TransHeader."Direct Transfer" then begin
                                TransferPostShip.Run(TransHeader);
                                PostedSourceType := DATABASE::"Transfer Shipment Header";
                                PostedSourceNo := TransHeader."Last Shipment No.";
                            end else begin
                                InventorySetup.Get();
                                InventorySetup.TestField("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Direct Transfer");
                                TransferPostTransfer.Run(TransHeader);
                                PostedSourceType := DATABASE::"Direct Trans. Header";
                                PostedSourceNo := TransHeader."Last Shipment No.";
                            end;
                        end;

                        OnPostSourceDocumentOnBeforeUpdateUnhandledTransLine(TransHeader, WhseActivHeader, PostingReference, HideDialog);
                        UpdateUnhandledTransLine(TransHeader."No.");
                        PostedSourceSubType := 0;
                    end;
            end;

        OnAfterPostSourceDocument(WhseActivHeader, PurchHeader, SalesHeader, TransHeader, PostingReference, HideDialog);
    end;

    local procedure PostJobUsage(PostingDate: Date)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJnlLine: Record "Job Journal Line";
        JobJnlLineReservationEntry: Record "Reservation Entry";
        JobTransferLine: Codeunit "Job Transfer Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000GQT', 'Picks on jobs', 'post picks');
        TempWhseActivLine.Reset();
        if TempWhseActivLine.FindSet() then begin
            repeat
                JobPlanningLine.SetRange("Job Contract Entry No.", TempWhseActivLine."Source Line No.");
                JobPlanningLine.SetFilter(Type, '<>%1', JobPlanningLine.Type::Text);

                if JobPlanningLine.FindFirst() then begin
                    JobPlanningLine.Validate("Qty. to Transfer to Journal", TempWhseActivLine."Qty. to Handle");

                    JobTransferLine.FromWarehouseActivityLineToJnlLine(TempWhseActivLine, PostingDate, '', '', JobJnlLine);
                end;

                JobJnlPostLine.SetCalledFromInvtPutawayPick(true);
                JobJnlPostLine.RunWithCheck(JobJnlLine);

                //Delete the temporary job journal line and the linked item tracking after posting.
                JobJnlLineReservationEntry.SetSourceFilter(Database::"Job Journal Line", JobJnlLine."Entry Type".AsInteger(), JobJnlLine."Journal Template Name", JobJnlLine."Line No.", true);
                JobJnlLineReservationEntry.SetRange("Source Batch Name", JobJnlLine."Journal Batch Name");
                JobJnlLineReservationEntry.DeleteAll();
                JobJnlLine.Delete();
            until TempWhseActivLine.Next() = 0;

            PostedSourceType := TempWhseActivLine."Source Type";
            PostedSourceSubType := TempWhseActivLine."Source Subtype";
            PostedSourceNo := TempWhseActivLine."Source No.";
        end;
    end;

    local procedure PostWhseActivityLine(WhseActivHeader: Record "Warehouse Activity Header"; var WhseActivLine: Record "Warehouse Activity Line")
    var
        ProdOrder: Record "Production Order";
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseActivLine(WhseActivHeader, WhseActivLine, PostedSourceNo, PostedSourceType, PostedSourceSubType, IsHandled);
        if IsHandled then
            exit;

        with WhseActivHeader do begin
            IsHandled := false;
            OnPostWhseActivityLineOnBeforePosting(WhseActivHeader, WhseActivLine, PostedSourceNo, PostedSourceType, PostedSourceSubType, IsHandled);
            if not IsHandled then
                if "Source Document" = "Source Document"::"Prod. Consumption" then begin
                    PostConsumption(ProdOrder);
                    WhseProdRelease.Release(ProdOrder);
                end else
                    if (Type = Type::"Invt. Put-away") and ("Source Document" = "Source Document"::"Prod. Output") then begin
                        PostOutput(ProdOrder);
                        WhseOutputProdRelease.Release(ProdOrder);
                    end else
                        if (Type = Type::"Invt. Pick") and ("Source Document" = "Source Document"::"Job Usage") then
                            PostJobUsage(WhseActivHeader."Posting Date")
                        else
                            PostSourceDoc();

            CreatePostedActivHeader(WhseActivHeader, PostedInvtPutAwayHeader, PostedInvtPickHeader);

            repeat
                LineCount := LineCount + 1;
                if not HideDialog then begin
                    Window.Update(3, LineCount);
                    Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                end;

                UpdateWhseActivityLine(WhseActivLine);

                if Location."Bin Mandatory" and ("Source Document" <> "Source Document"::"Job Usage") then
                    PostWhseJnlLine(WhseActivLine);

                CreatePostedActivLine(WhseActivLine, PostedInvtPutAwayHeader, PostedInvtPickHeader);
            until WhseActivLine.Next() = 0;
        end;

        OnAfterPostWhseActivityLine(WhseActivHeader, WhseActivLine, PostedSourceNo, PostedSourceType, PostedSourceSubType);
    end;

    local procedure UpdateWhseActivityLine(var WhseActivLine: Record "Warehouse Activity Line")
    var
        EntriesExist: Boolean;
    begin
        with WhseActivLine do
            if CheckItemTracking(WhseActivLine) and ("Activity Type" = "Activity Type"::"Invt. Put-away") then
                "Expiration Date" := ItemTrackingMgt.ExistingExpirationDate(WhseActivLine, false, EntriesExist);
    end;

    local procedure PostWhseJnlLine(WhseActivLine: Record "Warehouse Activity Line")
    var
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        WMSMgt: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        OnBeforePostWhseJnlLine(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        CreateWhseJnlLine(TempWhseJnlLine, WhseActivLine);
        if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Negative Adjmt." then
            WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 4, TempWhseJnlLine."Qty. (Base)", false); // 4 = Whse. Journal
        WhseJnlRegisterLine.Run(TempWhseJnlLine);
    end;

    procedure CreateWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; WhseActivLine: Record "Warehouse Activity Line")
    var
        WMSMgt: Codeunit "WMS Management";
    begin
        with WhseActivLine do begin
            WhseJnlLine.Init();
            WhseJnlLine."Location Code" := "Location Code";
            WhseJnlLine."Item No." := "Item No.";
            WhseJnlLine."Registering Date" := WhseActivHeader."Posting Date";
            WhseJnlLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(WhseJnlLine."User ID"));
            WhseJnlLine."Variant Code" := "Variant Code";
            if "Action Type" = "Action Type"::Take then begin
                WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
                WhseJnlLine."From Bin Code" := "Bin Code";
                WhseJnlLine.Quantity := "Qty. to Handle (Base)";
                WhseJnlLine."Qty. (Base)" := "Qty. to Handle (Base)";
            end else begin
                WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
                WhseJnlLine."To Bin Code" := "Bin Code";
                WhseJnlLine.Quantity := -"Qty. to Handle (Base)";
                WhseJnlLine."Qty. (Base)" := -"Qty. to Handle (Base)";
            end;
            WhseJnlLine."Qty. (Absolute)" := "Qty. to Handle (Base)";
            WhseJnlLine."Qty. (Absolute, Base)" := "Qty. to Handle (Base)";
            WhseJnlLine."Unit of Measure Code" := WMSMgt.GetBaseUOM("Item No.");
            WhseJnlLine."Qty. per Unit of Measure" := 1;
            WhseJnlLine."Source Type" := PostedSourceType;
            WhseJnlLine."Source Subtype" := PostedSourceSubType;
            WhseJnlLine."Source No." := PostedSourceNo;
            WhseJnlLine."Reference No." := PostedSourceNo;
            case "Source Document" of
                "Source Document"::"Purchase Order":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rcpt.";
                    end;
                "Source Document"::"Sales Order":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Shipment";
                    end;
                "Source Document"::"Purchase Return Order":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
                    end;
                "Source Document"::"Sales Return Order":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
                    end;
                "Source Document"::"Outbound Transfer":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Shipment";
                    end;
                "Source Document"::"Inbound Transfer":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Receipt";
                    end;
                "Source Document"::"Prod. Consumption":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup."Consumption Journal";
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Prod.";
                    end;
                "Source Document"::"Prod. Output":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup."Output Journal";
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Prod.";
                    end;
            end;

            if "Activity Type" in ["Activity Type"::"Invt. Put-away", "Activity Type"::"Invt. Pick",
                                   "Activity Type"::"Invt. Movement"]
            then
                WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";

            WhseJnlLine.CopyTrackingFromWhseActivityLine(WhseActivLine);
            WhseJnlLine."Warranty Date" := "Warranty Date";
            WhseJnlLine."Expiration Date" := "Expiration Date";
        end;

        OnAfterCreateWhseJnlLine(WhseJnlLine, WhseActivLine);
    end;

    local procedure CreatePostedActivHeader(WhseActivHeader: Record "Warehouse Activity Header"; var PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header"; var PostedInvtPickHeader: Record "Posted Invt. Pick Header")
    var
        WhseComment: Record "Warehouse Comment Line";
        WhseComment2: Record "Warehouse Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" then begin
            PostedInvtPutAwayHeader.Init();
            PostedInvtPutAwayHeader.TransferFields(WhseActivHeader);
            PostedInvtPutAwayHeader."No." := '';
            PostedInvtPutAwayHeader."Invt. Put-away No." := WhseActivHeader."No.";
            PostedInvtPutAwayHeader."Source No." := PostedSourceNo;
            PostedInvtPutAwayHeader."Source Type" := PostedSourceType;
            OnBeforePostedInvtPutAwayHeaderInsert(PostedInvtPutAwayHeader, WhseActivHeader);
            PostedInvtPutAwayHeader.Insert(true);
            RecordLinkManagement.CopyLinks(WhseActivHeader, PostedInvtPutAwayHeader);
            OnAfterPostedInvtPutAwayHeaderInsert(PostedInvtPutAwayHeader, WhseActivHeader);
        end else begin
            PostedInvtPickHeader.Init();
            PostedInvtPickHeader.TransferFields(WhseActivHeader);
            PostedInvtPickHeader."No." := '';
            PostedInvtPickHeader."Invt Pick No." := WhseActivHeader."No.";
            PostedInvtPickHeader."Source No." := PostedSourceNo;
            PostedInvtPickHeader."Source Type" := PostedSourceType;
            OnBeforePostedInvtPickHeaderInsert(PostedInvtPickHeader, WhseActivHeader);
            PostedInvtPickHeader.Insert(true);
            RecordLinkManagement.CopyLinks(WhseActivHeader, PostedInvtPickHeader);
            OnAfterPostedInvtPickHeaderInsert(PostedInvtPickHeader, WhseActivHeader);
        end;

        WhseComment.SetRange("Table Name", WhseComment."Table Name"::"Whse. Activity Header");
        WhseComment.SetRange(Type, WhseActivHeader.Type);
        WhseComment.SetRange("No.", WhseActivHeader."No.");
        WhseComment.LockTable();
        if WhseComment.Find('-') then
            repeat
                WhseComment2.Init();
                WhseComment2 := WhseComment;
                if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" then begin
                    WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Invt. Put-Away";
                    WhseComment2."No." := PostedInvtPutAwayHeader."No.";
                end else begin
                    WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Invt. Pick";
                    WhseComment2."No." := PostedInvtPickHeader."No.";
                end;
                WhseComment2.Type := WhseComment2.Type::" ";
                WhseComment2.Insert();
            until WhseComment.Next() = 0;
    end;

    local procedure CreatePostedActivLine(WhseActivLine: Record "Warehouse Activity Line"; PostedInvtPutAwayHdr: Record "Posted Invt. Put-away Header"; PostedInvtPickHeader: Record "Posted Invt. Pick Header")
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" then begin
            PostedInvtPutAwayLine.Init();
            PostedInvtPutAwayLine.TransferFields(WhseActivLine);
            PostedInvtPutAwayLine."No." := PostedInvtPutAwayHdr."No.";
            PostedInvtPutAwayLine.Validate(Quantity, WhseActivLine."Qty. to Handle");
            OnBeforePostedInvtPutAwayLineInsert(PostedInvtPutAwayLine, WhseActivLine);
            PostedInvtPutAwayLine.Insert();
        end else begin
            PostedInvtPickLine.Init();
            PostedInvtPickLine.TransferFields(WhseActivLine);
            PostedInvtPickLine."No." := PostedInvtPickHeader."No.";
            PostedInvtPickLine.Validate(Quantity, WhseActivLine."Qty. to Handle");
            OnBeforePostedInvtPickLineInsert(PostedInvtPickLine, WhseActivLine);
            PostedInvtPickLine.Insert();
        end;
    end;

    local procedure PostSourceDoc()
    begin
        OnBeforePostSourceDoc(WhseActivHeader, HideDialog, SuppressCommit);

        TempWhseActivLine.Reset();
        TempWhseActivLine.Find('-');
        InitSourceDocument();
        repeat
            UpdateSourceDocument();
        until TempWhseActivLine.Next() = 0;
        UpdateItemChargeLines();
        UpdateNonInventoryLines();

        PostSourceDocument(WhseActivHeader);
    end;

    local procedure PostConsumption(var ProdOrder: Record "Production Order")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        with TempWhseActivLine do begin
            Reset();
            Find('-');
            ProdOrder.Get("Source Subtype", "Source No.");
            repeat
                ProdOrderComp.Get("Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                PostConsumptionLine(ProdOrder, ProdOrderComp);
            until Next() = 0;

            PostedSourceType := "Source Type";
            PostedSourceSubType := "Source Subtype";
            PostedSourceNo := "Source No.";
        end;
    end;

    local procedure PostConsumptionLine(ProdOrder: Record "Production Order"; ProdOrderComp: Record "Prod. Order Component")
    var
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        with TempWhseActivLine do begin
            ProdOrderLine.Get("Source Subtype", "Source No.", "Source Line No.");
            ItemJnlLine.Init();
            OnPostConsumptionLineOnAfterInitItemJournalLine(ItemJnlLine, SourceCodeSetup);
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
            ItemJnlLine.Validate("Posting Date", WhseActivHeader."Posting Date");
            ItemJnlLine."Source No." := ProdOrderLine."Item No.";
            ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
            ItemJnlLine."Document No." := ProdOrder."No.";
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", ProdOrder."No.");
            ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
            ItemJnlLine.Validate("Item No.", "Item No.");
            if ItemJnlLine."Unit of Measure Code" <> "Unit of Measure Code" then
                ItemJnlLine.Validate("Unit of Measure Code", "Unit of Measure Code");
            ItemJnlLine.Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Qty. Rounding Precision" := "Qty. Rounding Precision";
            ItemJnlLine."Qty. Rounding Precision (Base)" := "Qty. Rounding Precision (Base)";
            ItemJnlLine.Description := Description;
            if "Activity Type" = "Activity Type"::"Invt. Pick" then
                ItemJnlLine.Validate(Quantity, "Qty. to Handle")
            else
                ItemJnlLine.Validate(Quantity, -"Qty. to Handle");
            ItemJnlLine.Validate("Unit Cost", ProdOrderComp."Unit Cost");
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Source Code" := SourceCodeSetup."Consumption Journal";
            ItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
            GetItem("Item No.");
            ItemJnlLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
            OnPostConsumptionLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine, WhseActivLine, SourceCodeSetup);
            ProdOrderCompReserve.TransferPOCompToItemJnlLineCheckILE(ProdOrderComp, ItemJnlLine, ItemJnlLine."Quantity (Base)", true);
            ItemJnlPostLine.SetCalledFromInvtPutawayPick(true);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            ProdOrderCompReserve.UpdateItemTrackingAfterPosting(ProdOrderComp);
        end;
    end;

    local procedure PostOutput(var ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with TempWhseActivLine do begin
            Reset();
            Find('-');
            ProdOrder.Get("Source Subtype", "Source No.");
            repeat
                ProdOrderLine.Get("Source Subtype", "Source No.", "Source Line No.");
                PostOutputLine(ProdOrder, ProdOrderLine);
            until Next() = 0;
            PostedSourceType := "Source Type";
            PostedSourceSubType := "Source Subtype";
            PostedSourceNo := "Source No.";
        end;
    end;

    local procedure PostOutputLine(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line")
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ReservProdOrderLine: Codeunit "Prod. Order Line-Reserve";
    begin
        with TempWhseActivLine do begin
            ItemJnlLine.Init();
            OnPostOutputLineOnAfterItemJournalLineInit(ItemJnlLine, SourceCodeSetup);
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
            ItemJnlLine.Validate("Posting Date", WhseActivHeader."Posting Date");
            ItemJnlLine."Document No." := ProdOrder."No.";
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", ProdOrder."No.");
            ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
            ItemJnlLine.Validate("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            ItemJnlLine.Validate("Routing No.", ProdOrderLine."Routing No.");
            ItemJnlLine.Validate("Item No.", ProdOrderLine."Item No.");
            if ItemJnlLine."Unit of Measure Code" <> "Unit of Measure Code" then
                ItemJnlLine.Validate("Unit of Measure Code", "Unit of Measure Code");
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Qty. Rounding Precision" := "Qty. Rounding Precision";
            ItemJnlLine."Qty. Rounding Precision (Base)" := "Qty. Rounding Precision (Base)";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine.Description := Description;
            if ProdOrderLine."Routing No." <> '' then
                ItemJnlLine.Validate("Operation No.", CalcLastOperationNo(ProdOrderLine));
            ItemJnlLine.Validate("Output Quantity", "Qty. to Handle");
            ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
            ItemJnlLine."Dimension Set ID" := ProdOrderLine."Dimension Set ID";
            OnPostOutputLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine, TempWhseActivLine, SourceCodeSetup);
            ReservProdOrderLine.TransferPOLineToItemJnlLine(
              ProdOrderLine, ItemJnlLine, ItemJnlLine."Quantity (Base)");
            ItemJnlPostLine.SetCalledFromInvtPutawayPick(true);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            ReservProdOrderLine.UpdateItemTrackingAfterPosting(ProdOrderLine);
        end;
    end;

    local procedure CalcLastOperationNo(ProdOrderLine: Record "Prod. Order Line"): Code[10]
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderRouteManagement: Codeunit "Prod. Order Route Management";
    begin
        with ProdOrderLine do begin
            ProdOrderRtngLine.SetRange(Status, Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRtngLine.SetRange("Routing Reference No.", "Routing Reference No.");
            ProdOrderRtngLine.SetRange("Routing No.", "Routing No.");
            if not ProdOrderRtngLine.IsEmpty() then begin
                ProdOrderRouteManagement.Check(ProdOrderLine);
                ProdOrderRtngLine.SetRange("Next Operation No.", '');
                ProdOrderRtngLine.FindLast();
                exit(ProdOrderRtngLine."Operation No.");
            end;

            exit('');
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
    end;

    local procedure LockPostedTables(WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        if WarehouseActivityHeader.Type = WarehouseActivityHeader.Type::"Invt. Put-away" then begin
            PostedInvtPutAwayHeader.LockTable();
            PostedInvtPutAwayLine.LockTable();
        end else begin
            PostedInvtPickHeader.LockTable();
            PostedInvtPickLine.LockTable();
        end;
    end;

    procedure ShowHideDialog(HideDialog2: Boolean)
    begin
        HideDialog := HideDialog2;
    end;

    procedure SetInvoiceSourceDoc(Invoice: Boolean)
    begin
        InvoiceSourceDoc := Invoice;
        OnAfterSetInvoiceSourceDoc(InvoiceSourceDoc);
    end;

    procedure PrintDocument(SetPrint: Boolean)
    begin
        PrintDoc := SetPrint;
    end;

    local procedure CheckItemTracking(WhseActivLine2: Record "Warehouse Activity Line"): Boolean
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        Result: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCheckItemTracking(WhseActivLine2, Result, IsHandled, WhseActivHeader);
        if IsHandled then
            exit(Result);

        with WhseActivLine2 do begin
            ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
            WhseActivLine2.TestTrackingIfRequired(WhseItemTrackingSetup);
            if ("Expiration Date" <> 0D) and ItemTrackingMgt.StrictExpirationPosting("Item No.") then
                if WhseActivHeader."Posting Date" > "Expiration Date" then
                    FieldError("Expiration Date", PostingDateErr);
        end;

        exit(WhseItemTrackingSetup.TrackingRequired());
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetIsPreview(NewIsPreview: Boolean)
    begin
        IsPreview := NewIsPreview;
    end;

    local procedure CheckWhseItemTrackingAgainstSource()
    var
        TrackingSpecification: Record "Tracking Specification";
        JobPlanningLine: Record "Job Planning Line";
    begin
        with TempWhseActivLine do begin
            Reset();
            if FindSet() then
                repeat
                    case "Source Type" of
                        Database::"Prod. Order Component":
                            TrackingSpecification.CheckItemTrackingQuantity("Source Type", "Source Subtype", "Source No.", "Source Subline No.", "Source Line No.", "Qty. to Handle (Base)", "Qty. to Handle (Base)", true, InvoiceSourceDoc);
                        Database::Job:
                            begin
                                // Checking tracking specification for Job by mapping Temporary warehouse activity line to Job planning line item tracking.
                                JobPlanningLine.SetLoadFields(Status);
                                JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
                                JobPlanningLine.SetRange("Job Contract Entry No.", "Source Line No.");
                                JobPlanningLine.FindFirst();

                                TrackingSpecification.CheckItemTrackingQuantity(Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(), "Source No.", "Source Line No.", "Qty. to Handle (Base)", "Qty. to Handle (Base)", true, InvoiceSourceDoc);
                            end;
                        else
                            TrackingSpecification.CheckItemTrackingQuantity("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Qty. to Handle (Base)", "Qty. to Handle (Base)", true, InvoiceSourceDoc);
                    end;
                until Next() = 0;
        end;
    end;

    local procedure CheckAvailability(WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAvailability(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        if WhseActivLine."Activity Type" <> WhseActivLine."Activity Type"::"Invt. Pick" then
            exit;

        if WhseActivLine."Assemble to Order" and not WhseActivLine."ATO Component" then
            exit;

        if not WhseActivLine.CheckItemTrackingAvailability() then
            AvailabilityError(WhseActivLine);
    end;

    local procedure AvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
        if WhseActivLine."Serial No." <> '' then
            Error(InventoryNotAvailableErr, WhseActivLine.FieldCaption("Serial No."), WhseActivLine."Serial No.");
        if WhseActivLine."Lot No." <> '' then
            Error(InventoryNotAvailableErr, WhseActivLine.FieldCaption("Lot No."), WhseActivLine."Lot No.");

        OnAfterAvailabilityError(WhseActivLine);
    end;

    local procedure UpdateAttachedLines(PurchaseLine: Record "Purchase Line")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        AttachedPurchLine: Record "Purchase Line";
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit;

        AttachedPurchLine.SetRange("Document Type", PurchaseLine."Document Type");
        AttachedPurchLine.SetRange("Document No.", PurchaseLine."Document No.");
        AttachedPurchLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        AttachedPurchLine.SetFilter(Type, '<>%1', AttachedPurchLine.Type::"Charge (Item)");
        if AttachedPurchLine.FindSet() then
            repeat
                UpdateQtyToHandleOnPurchaseLine(AttachedPurchLine, AttachedPurchLine."Outstanding Quantity");
            until AttachedPurchLine.Next() = 0;
    end;

    local procedure UpdateAttachedLines(SalesLine: Record "Sales Line")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        AttachedSalesLine: Record "Sales Line";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
            exit;

        AttachedSalesLine.SetRange("Document Type", SalesLine."Document Type");
        AttachedSalesLine.SetRange("Document No.", SalesLine."Document No.");
        AttachedSalesLine.SetRange("Attached to Line No.", SalesLine."Line No.");
        AttachedSalesLine.SetFilter(Type, '<>%1', AttachedSalesLine.Type::"Charge (Item)");
        if AttachedSalesLine.FindSet() then
            repeat
                UpdateQtyToHandleOnSalesLine(AttachedSalesLine, AttachedSalesLine."Outstanding Quantity");
            until AttachedSalesLine.Next() = 0;
    end;

    local procedure UpdateItemChargeLines()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ItemChargePurchLine: Record "Purchase Line";
        ItemChargeSalesLine: Record "Sales Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        QtyToHandle: Decimal;
    begin
        case WhseActivHeader."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchasesPayablesSetup.Get();
                    if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
                        exit;
                    ItemChargePurchLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    ItemChargePurchLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    ItemChargePurchLine.SetRange(Type, ItemChargePurchLine.Type::"Charge (Item)");
                    if not ItemChargePurchLine.FindSet() then
                        exit;
                    repeat
                        QtyToHandle := 0;
                        ItemChargeAssignmentPurch.SetRange("Document Type", ItemChargePurchLine."Document Type");
                        ItemChargeAssignmentPurch.SetRange("Document No.", ItemChargePurchLine."Document No.");
                        ItemChargeAssignmentPurch.SetRange("Document Line No.", ItemChargePurchLine."Line No.");
                        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", ItemChargePurchLine."Document Type");
                        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", ItemChargePurchLine."Document No.");
                        ItemChargeAssignmentPurch.SetFilter("Qty. to Handle", '<>0');
                        if ItemChargeAssignmentPurch.FindSet() then
                            repeat
                                TempWhseActivLine.SetRange("Source Line No.", ItemChargeAssignmentPurch."Applies-to Doc. Line No.");
                                if not TempWhseActivLine.IsEmpty() then
                                    QtyToHandle += ItemChargeAssignmentPurch."Qty. to Handle";
                            until ItemChargeAssignmentPurch.Next() = 0;

                        UpdateQtyToHandleOnPurchaseLine(ItemChargePurchLine, QtyToHandle);
                    until ItemChargePurchLine.Next() = 0;
                end;
            Database::"Sales Line":
                begin
                    SalesReceivablesSetup.Get();
                    if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned" then
                        exit;
                    ItemChargeSalesLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    ItemChargeSalesLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    ItemChargeSalesLine.SetRange(Type, ItemChargeSalesLine.Type::"Charge (Item)");
                    if not ItemChargeSalesLine.FindSet() then
                        exit;
                    repeat
                        QtyToHandle := 0;
                        ItemChargeAssignmentSales.SetRange("Document Type", ItemChargeSalesLine."Document Type");
                        ItemChargeAssignmentSales.SetRange("Document No.", ItemChargeSalesLine."Document No.");
                        ItemChargeAssignmentSales.SetRange("Document Line No.", ItemChargeSalesLine."Line No.");
                        ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", ItemChargeSalesLine."Document Type");
                        ItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", ItemChargeSalesLine."Document No.");
                        ItemChargeAssignmentSales.SetFilter("Qty. to Handle", '<>0');
                        if ItemChargeAssignmentSales.FindSet() then
                            repeat
                                TempWhseActivLine.SetRange("Source Line No.", ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                                if not TempWhseActivLine.IsEmpty() then
                                    QtyToHandle += ItemChargeAssignmentSales."Qty. to Handle";
                            until ItemChargeAssignmentSales.Next() = 0;

                        UpdateQtyToHandleOnSalesLine(ItemChargeSalesLine, QtyToHandle);
                    until ItemChargeSalesLine.Next() = 0;
                end;
        end;
    end;

    local procedure UpdateNonInventoryLines()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        case WhseActivHeader."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchasesPayablesSetup.Get();
                    if PurchasesPayablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::All then
                        exit;

                    PurchaseLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    PurchaseLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    if PurchaseLine.FindSet() then
                        repeat
                            if not PurchaseLine.IsInventoriableItem() then
                                UpdateQtyToHandleOnPurchaseLine(PurchaseLine, PurchaseLine."Outstanding Quantity");
                        until PurchaseLine.Next() = 0;
                end;
            Database::"Sales Line":
                begin
                    SalesReceivablesSetup.Get();
                    if SalesReceivablesSetup."Auto Post Non-Invt. via Whse." <> PurchasesPayablesSetup."Auto Post Non-Invt. via Whse."::All then
                        exit;

                    SalesLine.SetRange("Document Type", WhseActivHeader."Source Subtype");
                    SalesLine.SetRange("Document No.", WhseActivHeader."Source No.");
                    if SalesLine.FindSet() then
                        repeat
                            if not SalesLine.IsInventoriableItem() then
                                UpdateQtyToHandleOnSalesLine(SalesLine, SalesLine."Outstanding Quantity");
                        until SalesLine.Next() = 0;
                end;
        end;
    end;

    local procedure UpdateQtyToHandleOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToHandle: Decimal)
    var
        ModifyLine: Boolean;
    begin
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then begin
            ModifyLine := PurchaseLine."Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                PurchaseLine.Validate("Qty. to Receive", QtyToHandle);
        end else begin
            ModifyLine := PurchaseLine."Return Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                PurchaseLine.Validate("Return Qty. to Ship", QtyToHandle);
        end;
        OnUpdateQtyToHandleOnPurchaseLineOnBeforePurchLineModify(PurchaseLine, ModifyLine);
        if ModifyLine then
            ModifyPurchaseLine(PurchaseLine);
    end;

    local procedure UpdateQtyToHandleOnSalesLine(var SalesLine: Record "Sales Line"; QtyToHandle: Decimal)
    var
        ModifyLine: Boolean;
    begin
        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            ModifyLine := SalesLine."Qty. to Ship" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Qty. to Ship", QtyToHandle);
        end else begin
            ModifyLine := SalesLine."Return Qty. to Receive" <> QtyToHandle;
            if ModifyLine then
                SalesLine.Validate("Return Qty. to Receive", QtyToHandle);
        end;
        OnUpdateQtyToHandleOnSalesLineOnBeforeSalesLineModify(SalesLine, ModifyLine);
        if ModifyLine then
            ModifySalesLine(SalesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SuppressCommit: Boolean; PrintDoc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocument(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSalesDocument(var SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineModify(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetInvoiceSourceDoc(var InvoiceSourceDocument: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseActivHeader(WhseActivHeader: Record "Warehouse Activity Header"; var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSourceDocument(WarehouseActivityHeader: Record "Warehouse Activity Header"; var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var TransferHeader: Record "Transfer Header"; PostingReference: Integer; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedInvtPickHeaderInsert(var PostedInvtPickHeader: Record "Posted Invt. Pick Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedInvtPutAwayHeaderInsert(var PostedInvtPutAwayHeader: Record "Posted Invt. Put-Away Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseActivityLine(WhseActivHeader: Record "Warehouse Activity Header"; var WhseActivLine: Record "Warehouse Activity Line"; PostedSourceNo: Code[20]; PostedSourceType: Integer; PostedSourceSubType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineModify(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineModify(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseActivLineModify(var WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCreatePostedWhseActivDocument(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempWhseActivLine(var WhseActivLine: Record "Warehouse Activity Line"; ItemTrackingRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSourceDocument(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAvailability(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLines(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Result: Boolean; var IsHandled: Boolean; WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingReference(var PostReference: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesHeader(var SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTransferHeader(var TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTransferLine(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedInvtPickHeaderInsert(var PostedInvtPickHeader: Record "Posted Invt. Pick Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedInvtPickLineInsert(var PostedInvtPickLine: Record "Posted Invt. Pick Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedInvtPutAwayHeaderInsert(var PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedInvtPutAwayLineInsert(var PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDocument(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var PostedSourceType: Integer; var PostedSourceNo: Code[20]; var PostedSourceSubType: Integer; HideDialog: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseActivLine(WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var PostedSourceNo: Code[20]; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDoc(WhseActivHeader: Record "Warehouse Activity Header"; HideDialog: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleasePurchDocument(var PurchaseHeader: Record "Purchase Header"; WhseActivHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSalesDocument(var SalesHeader: Record "Sales Header"; WhseActivHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSourceDocument(var TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseActivLineInsert(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseActivLineModify(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnhandledTransLineModify(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineDelete(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ForceDelete: Boolean; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterWhseActivLineSetFilters(var WhseActivHeader: Record "Warehouse Activity Header"; var WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforeSalesLineLoopIteration(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforePurchLineLoopIteration(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; WhseActivHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnBeforeTransLineLoopIteration(TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnAfterSetPurchaseLineFilters(var PurchaseLine: record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeTransferPostReceiptRun(var TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnAfterTransLineSetFilters(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentOnAfterTransferLineLoopIteration(var TransLine: Record "Transfer Line"; TransHeader: Record "Transfer Header"; WhseActivHeader: Record "Warehouse Activity Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionLineOnAfterInitItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePurchPostRun(WarehouseActivityHeader: Record "Warehouse Activity Header"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeSalesPostRun(WarehouseActivityHeader: Record "Warehouse Activity Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforeUpdateUnhandledTransLine(var TransHeader: Record "Transfer Header"; WhseActivHeader: Record "Warehouse Activity Header"; PostingReference: Integer; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseActivityLineOnBeforePosting(var WhseActivityHeader: Record "Warehouse Activity Header"; var WhseActivityLine: Record "Warehouse Activity Line"; var PostedSourceNo: Code[20]; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleasePurchDocumentOnAfterPurchReleaseRun(PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleasePurchDocumentOnBeforePurchReleaseRun(var PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseSalesDocumentOnAfterSalesReleaseRun(SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseSalesDocumentOnBeforeSalesReleaseRun(var SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterGetPurchLine(var PurchaseLine: Record "Purchase Line"; TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterPurchLineModify(var PurchaseLine: Record "Purchase Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterSalesLineModify(var SalesLine: Record "Sales Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterTransLineModify(var TransferLine: Record "Transfer Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnBeforeTransLineModify(var TransferLine: Record "Transfer Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterGetSalesLine(var SalesLine: Record "Sales Line"; TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputLineOnAfterItemJournalLineInit(var ItemJournalLine: Record "Item Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyToHandleOnPurchaseLineOnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyToHandleOnSalesLineOnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceDocumentOnAfterGetTransLine(var TransferLine: Record "Transfer Line"; TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;
}

