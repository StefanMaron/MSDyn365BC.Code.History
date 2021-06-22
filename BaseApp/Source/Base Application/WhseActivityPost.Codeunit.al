codeunit 7324 "Whse.-Activity-Post"
{
    Permissions = TableData "Warehouse Setup" = m,
                  TableData "Warehouse Journal Batch" = imd,
                  TableData "Posted Invt. Put-away Header" = i,
                  TableData "Posted Invt. Put-away Line" = i,
                  TableData "Posted Invt. Pick Header" = i,
                  TableData "Posted Invt. Pick Line" = i;
    TableNo = "Warehouse Activity Line";

    trigger OnRun()
    begin
        WhseActivLine.Copy(Rec);
        Code;
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
        Text003: Label 'There is nothing to post.';
        Text005: Label 'The source document %1 %2 is not released.';
        InvoiceSourceDoc: Boolean;
        PrintDoc: Boolean;
        SuppressCommit: Boolean;
        PostingDateErr: Label 'is before the posting date';

    local procedure "Code"()
    var
        TransferOrderPostPrint: Codeunit "TransferOrder-Post + Print";
        ItemTrackingRequired: Boolean;
        Selection: Option " ",Shipment,Receipt;
        ForceDelete: Boolean;
    begin
        OnBeforeCode(WhseActivLine, SuppressCommit);

        PostingReference := WhseSetup.GetNextReference;

        with WhseActivHeader do begin
            WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
            WhseActivLine.SetRange("No.", WhseActivLine."No.");
            WhseActivLine.SetFilter("Qty. to Handle", '<>0');
            if not WhseActivLine.Find('-') then
                Error(Text003);

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
                    WhseActivLine.TestField("Item No.");
                    if Location."Bin Mandatory" then begin
                        WhseActivLine.TestField("Unit of Measure Code");
                        WhseActivLine.TestField("Bin Code");
                    end;
                    ItemTrackingRequired := CheckItemTracking(WhseActivLine);
                    InsertTempWhseActivLine(WhseActivLine, ItemTrackingRequired);
                until WhseActivLine.Next = 0;
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

            // Modify/delete activity header and activity lines
            TempWhseActivLine.DeleteAll();

            WhseActivLine.SetCurrentKey(
              "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.");
            if WhseActivLine.Find('-') then
                repeat
                    ForceDelete := false;
                    OnBeforeWhseActivLineDelete(WhseActivLine, ForceDelete);
                    if (WhseActivLine."Qty. Outstanding" = WhseActivLine."Qty. to Handle") or ForceDelete then
                        WhseActivLine.Delete
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
                until WhseActivLine.Next = 0;

            WhseActivLine.Reset();
            WhseActivLine.SetRange("Activity Type", Type);
            WhseActivLine.SetRange("No.", "No.");
            WhseActivLine.SetFilter("Qty. Outstanding", '<>%1', 0);
            if not WhseActivLine.Find('-') then
                Delete(true);

            if not HideDialog then
                Window.Close;

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
            OnAfterPostWhseActivHeader(WhseActivHeader);

            Clear(WhseJnlRegisterLine);
        end;
    end;

    local procedure InsertTempWhseActivLine(WhseActivLine: Record "Warehouse Activity Line"; ItemTrackingRequired: Boolean)
    begin
        OnBeforeInsertTempWhseActivLine(WhseActivLine, ItemTrackingRequired);

        with WhseActivLine do begin
            TempWhseActivLine.SetSourceFilter(
              "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", false);
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
                    ItemTrackingMgt.SynchronizeWhseActivItemTrkg(WhseActivLine);
            end;
        end;
    end;

    local procedure InitSourceDocument()
    var
        SalesLine: Record "Sales Line";
        SalesRelease: Codeunit "Release Sales Document";
        PurchRelease: Codeunit "Release Purchase Document";
        ModifyHeader: Boolean;
    begin
        OnBeforeInitSourceDocument(WhseActivHeader);

        with WhseActivHeader do
            case "Source Type" of
                DATABASE::"Purchase Line":
                    begin
                        PurchHeader.Get("Source Subtype", "Source No.");
                        PurchLine.SetRange("Document Type", "Source Subtype");
                        PurchLine.SetRange("Document No.", "Source No.");
                        if PurchLine.Find('-') then
                            repeat
                                if "Source Document" = "Source Document"::"Purchase Order" then
                                    PurchLine.Validate("Qty. to Receive", 0)
                                else
                                    PurchLine.Validate("Return Qty. to Ship", 0);
                                PurchLine.Validate("Qty. to Invoice", 0);
                                PurchLine.Modify();
                                OnAfterPurchLineModify(PurchLine);
                            until PurchLine.Next = 0;

                        if (PurchHeader."Posting Date" <> "Posting Date") and ("Posting Date" <> 0D) then begin
                            PurchRelease.Reopen(PurchHeader);
                            PurchRelease.SetSkipCheckReleaseRestrictions;
                            PurchHeader.SetHideValidationDialog(true);
                            PurchHeader.Validate("Posting Date", "Posting Date");
                            PurchRelease.Run(PurchHeader);
                            ModifyHeader := true;
                        end;
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
                        if ModifyHeader then
                            PurchHeader.Modify();
                    end;
                DATABASE::"Sales Line":
                    begin
                        SalesHeader.Get("Source Subtype", "Source No.");
                        SalesLine.SetRange("Document Type", "Source Subtype");
                        SalesLine.SetRange("Document No.", "Source No.");
                        if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Complete then
                            SalesLine.SetRange(Type, SalesLine.Type::Item);
                        if SalesLine.Find('-') then
                            repeat
                                if "Source Document" = "Source Document"::"Sales Order" then
                                    SalesLine.Validate("Qty. to Ship", 0)
                                else
                                    SalesLine.Validate("Return Qty. to Receive", 0);
                                SalesLine.Validate("Qty. to Invoice", 0);
                                SalesLine.Modify();
                                OnAfterSalesLineModify(SalesLine);
                            until SalesLine.Next = 0;

                        if (SalesHeader."Posting Date" <> "Posting Date") and ("Posting Date" <> 0D) then begin
                            SalesRelease.Reopen(SalesHeader);
                            SalesRelease.SetSkipCheckReleaseRestrictions;
                            SalesHeader.SetHideValidationDialog(true);
                            SalesHeader.Validate("Posting Date", "Posting Date");
                            SalesRelease.Run(SalesHeader);
                            ModifyHeader := true;
                        end;
                        if "External Document No." <> '' then begin
                            SalesHeader."External Document No." := "External Document No.";
                            ModifyHeader := true;
                        end;
                        if ModifyHeader then
                            SalesHeader.Modify();
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransHeader.Get("Source No.");
                        TransLine.SetRange("Document No.", TransHeader."No.");
                        TransLine.SetRange("Derived From Line No.", 0);
                        TransLine.SetFilter("Item No.", '<>%1', '');
                        if TransLine.Find('-') then
                            repeat
                                TransLine.Validate("Qty. to Ship", 0);
                                TransLine.Validate("Qty. to Receive", 0);
                                TransLine.Modify();
                                OnAfterTransLineModify(TransLine);
                            until TransLine.Next = 0;

                        if (TransHeader."Posting Date" <> "Posting Date") and ("Posting Date" <> 0D) then begin
                            TransHeader.CalledFromWarehouse(true);
                            TransHeader.Validate("Posting Date", "Posting Date");
                            ModifyHeader := true;
                        end;
                        if "External Document No." <> '' then begin
                            TransHeader."External Document No." := "External Document No.";
                            ModifyHeader := true;
                        end;
                        if ModifyHeader then
                            TransHeader.Modify();
                    end;
            end;

        OnAfterInitSourceDocument(WhseActivHeader);
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
                            PurchLine.Validate("Qty. to Receive", "Qty. to Handle");
                            PurchLine."Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                            if InvoiceSourceDoc then
                                PurchLine.Validate("Qty. to Invoice", "Qty. to Handle");
                        end else begin
                            PurchLine.Validate("Return Qty. to Ship", -"Qty. to Handle");
                            PurchLine."Return Qty. to Ship (Base)" := -"Qty. to Handle (Base)";
                            if InvoiceSourceDoc then
                                PurchLine.Validate("Qty. to Invoice", -"Qty. to Handle");
                        end;
                        PurchLine."Bin Code" := "Bin Code";
                        PurchLine.Modify();
                        OnAfterPurchLineModify(PurchLine);
                        OnUpdateSourceDocumentOnAfterPurchLineModify(PurchLine, TempWhseActivLine);
                    end;
                DATABASE::"Sales Line":
                    begin
                        if "Activity Type" = "Activity Type"::"Invt. Pick" then begin
                            "Qty. to Handle" := -"Qty. to Handle";
                            "Qty. to Handle (Base)" := -"Qty. to Handle (Base)";
                        end;
                        SalesLine.Get("Source Subtype", "Source No.", "Source Line No.");
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
                        OnAfterSalesLineModify(SalesLine);
                        OnUpdateSourceDocumentOnAfterSalesLineModify(SalesLine, TempWhseActivLine);
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransLine.Get("Source No.", "Source Line No.");
                        if "Activity Type" = "Activity Type"::"Invt. Put-away" then begin
                            TransLine."Transfer-To Bin Code" := "Bin Code";
                            TransLine.Validate("Qty. to Receive", "Qty. to Handle");
                            TransLine."Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                        end else begin
                            TransLine."Transfer-from Bin Code" := "Bin Code";
                            TransLine.Validate("Qty. to Ship", "Qty. to Handle");
                            TransLine."Qty. to Ship (Base)" := "Qty. to Handle (Base)";
                        end;
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
            if FindSet then
                repeat
                    if "Qty. in Transit" <> 0 then
                        Validate("Qty. to Receive", "Qty. in Transit");
                    if "Outstanding Quantity" <> 0 then
                        Validate("Qty. to Ship", "Outstanding Quantity");
                    OnBeforeUnhandledTransLineModify(TransLine);
                    Modify;
                until Next = 0;
        end;
    end;

    local procedure PostSourceDocument(WhseActivHeader: Record "Warehouse Activity Header")
    var
        PurchPost: Codeunit "Purch.-Post";
        SalesPost: Codeunit "Sales-Post";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferPostShip: Codeunit "TransferOrder-Post Shipment";
    begin
        OnBeforePostSourceDocument(WhseActivHeader, PostedSourceType, PostedSourceNo, PostedSourceSubType);

        with WhseActivHeader do
            case "Source Type" of
                DATABASE::"Purchase Line":
                    begin
                        Clear(PurchPost);
                        if not SuppressCommit then
                            Commit();
                        if "Source Document" = "Source Document"::"Purchase Order" then
                            PurchHeader.Receive := true
                        else
                            PurchHeader.Ship := true;
                        PurchHeader.Invoice := InvoiceSourceDoc;
                        PurchHeader."Posting from Whse. Ref." := PostingReference;
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
                        if not SuppressCommit then
                            Commit();
                        if "Source Document" = "Source Document"::"Sales Order" then
                            SalesHeader.Ship := true
                        else
                            SalesHeader.Receive := true;
                        SalesHeader.Invoice := InvoiceSourceDoc;
                        SalesHeader."Posting from Whse. Ref." := PostingReference;
                        SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
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
                        if not SuppressCommit then
                            Commit();
                        if Type = Type::"Invt. Put-away" then begin
                            if HideDialog then
                                TransferPostReceipt.SetHideValidationDialog(HideDialog);
                            TransHeader."Posting from Whse. Ref." := PostingReference;
                            TransferPostReceipt.Run(TransHeader);
                            PostedSourceType := DATABASE::"Transfer Receipt Header";
                            PostedSourceNo := TransHeader."Last Receipt No.";
                        end else begin
                            if HideDialog then
                                TransferPostShip.SetHideValidationDialog(HideDialog);
                            TransHeader."Posting from Whse. Ref." := PostingReference;
                            TransferPostShip.Run(TransHeader);
                            PostedSourceType := DATABASE::"Transfer Shipment Header";
                            PostedSourceNo := TransHeader."Last Shipment No.";
                        end;
                        UpdateUnhandledTransLine(TransHeader."No.");
                        PostedSourceSubType := 0;
                    end;
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
                        PostSourceDoc;

            CreatePostedActivHeader(WhseActivHeader, PostedInvtPutAwayHeader, PostedInvtPickHeader);

            repeat
                LineCount := LineCount + 1;
                if not HideDialog then begin
                    Window.Update(3, LineCount);
                    Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                end;

                UpdateWhseActivityLine(WhseActivLine);

                if Location."Bin Mandatory" then
                    PostWhseJnlLine(WhseActivLine);

                CreatePostedActivLine(WhseActivLine, PostedInvtPutAwayHeader, PostedInvtPickHeader);
            until WhseActivLine.Next = 0;
        end;
    end;

    local procedure UpdateWhseActivityLine(var WhseActivLine: Record "Warehouse Activity Line")
    var
        EntriesExist: Boolean;
    begin
        with WhseActivLine do
            if CheckItemTracking(WhseActivLine) and
                ("Activity Type" = "Activity Type"::"Invt. Put-away")
            then
                "Expiration Date" := ItemTrackingMgt.ExistingExpirationDate(
                    "Item No.", "Variant Code", "Lot No.", "Serial No.", false, EntriesExist);
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

    local procedure CreateWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; WhseActivLine: Record "Warehouse Activity Line")
    var
        WMSMgt: Codeunit "WMS Management";
    begin
        with WhseActivLine do begin
            WhseJnlLine.Init();
            WhseJnlLine."Location Code" := "Location Code";
            WhseJnlLine."Item No." := "Item No.";
            WhseJnlLine."Registering Date" := WhseActivHeader."Posting Date";
            WhseJnlLine."User ID" := UserId;
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
            until WhseComment.Next = 0;
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
        TempWhseActivLine.Reset();
        TempWhseActivLine.Find('-');
        InitSourceDocument;
        repeat
            UpdateSourceDocument;
        until TempWhseActivLine.Next = 0;

        PostSourceDocument(WhseActivHeader);
    end;

    local procedure PostConsumption(var ProdOrder: Record "Production Order")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        with TempWhseActivLine do begin
            Reset;
            Find('-');
            ProdOrder.Get("Source Subtype", "Source No.");
            repeat
                ProdOrderComp.Get("Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                PostConsumptionLine(ProdOrder, ProdOrderComp);
            until Next = 0;

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
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
    begin
        with TempWhseActivLine do begin
            ProdOrderLine.Get("Source Subtype", "Source No.", "Source Line No.");
            ItemJnlLine.Init();
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
            OnPostConsumptionLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine, WhseActivLine);
            ReserveProdOrderComp.TransferPOCompToItemJnlLineCheckILE(ProdOrderComp, ItemJnlLine, ItemJnlLine."Quantity (Base)", true);
            ItemJnlPostLine.SetCalledFromInvtPutawayPick(true);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            ReserveProdOrderComp.UpdateItemTrackingAfterPosting(ProdOrderComp);
        end;
    end;

    local procedure PostOutput(var ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with TempWhseActivLine do begin
            Reset;
            Find('-');
            ProdOrder.Get("Source Subtype", "Source No.");
            repeat
                ProdOrderLine.Get("Source Subtype", "Source No.", "Source Line No.");
                PostOutputLine(ProdOrder, ProdOrderLine);
            until Next = 0;
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
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine.Description := Description;
            if ProdOrderLine."Routing No." <> '' then
                ItemJnlLine.Validate("Operation No.", CalcLastOperationNo(ProdOrderLine));
            ItemJnlLine.Validate("Output Quantity", "Qty. to Handle");
            ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
            ItemJnlLine."Dimension Set ID" := ProdOrderLine."Dimension Set ID";
            OnPostOutputLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine, TempWhseActivLine);
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
            if not ProdOrderRtngLine.IsEmpty then begin
                ProdOrderRouteManagement.Check(ProdOrderLine);
                ProdOrderRtngLine.SetRange("Next Operation No.", '');
                ProdOrderRtngLine.FindLast;
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
        OnBeforeCheckItemTracking(WhseActivLine2, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with WhseActivLine2 do begin
            ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
            if WhseItemTrackingSetup."Serial No. Required" then
                TestField("Serial No.");
            if WhseItemTrackingSetup."Lot No. Required" then
                TestField("Lot No.");
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SuppressCommit: Boolean; PrintDoc: Boolean)
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
    local procedure OnAfterSalesLineModify(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseActivHeader(WhseActivHeader: Record "Warehouse Activity Header")
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
    local procedure OnBeforeCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SuppressCommit: Boolean)
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
    local procedure OnBeforeCheckLines(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Result: Boolean; var IsHandled: Boolean)
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
    local procedure OnBeforePostSourceDocument(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var PostedSourceType: Integer; var PostedSourceNo: Code[20]; var PostedSourceSubType: Integer)
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
    local procedure OnBeforeWhseActivLineDelete(WarehouseActivityLine: Record "Warehouse Activity Line"; var ForceDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseActivityLineOnBeforePosting(var WhseActivityHeader: Record "Warehouse Activity Header"; var WhseActivityLine: Record "Warehouse Activity Line"; var PostedSourceNo: Code[20]; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var IsHandled: Boolean)
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
}

