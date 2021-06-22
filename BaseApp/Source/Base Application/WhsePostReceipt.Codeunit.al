codeunit 5760 "Whse.-Post Receipt"
{
    Permissions = TableData "Whse. Item Entry Relation" = i,
                  TableData "Posted Whse. Receipt Header" = i,
                  TableData "Posted Whse. Receipt Line" = i;
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    begin
        OnBeforeRun(Rec);

        WhseRcptLine.Copy(Rec);
        Code;
        Rec := WhseRcptLine;

        OnAfterRun(Rec);
    end;

    var
        Text000: Label 'The source document %1 %2 is not released.';
        Text001: Label 'There is nothing to post.';
        Text002: Label 'Number of source documents posted: %1 out of a total of %2.';
        Text003: Label 'Number of put-away activities created: %3.';
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseRcptLineBuf: Record "Warehouse Receipt Line" temporary;
        TransHeader: Record "Transfer Header";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WhseRqst: Record "Warehouse Request";
        TempWhseItemEntryRelation: Record "Whse. Item Entry Relation" temporary;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgt: Codeunit "WMS Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        CreatePutAway: Codeunit "Create Put-away";
        PostingDate: Date;
        CounterSourceDocOK: Integer;
        CounterSourceDocTotal: Integer;
        CounterPutAways: Integer;
        PutAwayRequired: Boolean;
        HideValidationDialog: Boolean;
        ReceivingNo: Code[20];
        ItemEntryRelationCreated: Boolean;
        Text004: Label 'is not within your range of allowed posting dates';
        SuppressCommit: Boolean;

    local procedure "Code"()
    var
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        with WhseRcptLine do begin
            SetCurrentKey("No.");
            SetRange("No.", "No.");
            SetFilter("Qty. to Receive", '>0');
            if Find('-') then
                repeat
                    TestField("Unit of Measure Code");
                    WhseRqst.Get(
                      WhseRqst.Type::Inbound, "Location Code", "Source Type", "Source Subtype", "Source No.");
                    if WhseRqst."Document Status" <> WhseRqst."Document Status"::Released then
                        Error(Text000, "Source Document", "Source No.");
                    OnAfterCheckWhseRcptLine(WhseRcptLine);
                until Next = 0
            else
                Error(Text001);

            CounterSourceDocOK := 0;
            CounterSourceDocTotal := 0;
            CounterPutAways := 0;
            Clear(CreatePutAway);

            WhseRcptHeader.Get("No.");
            WhseRcptHeader.TestField("Posting Date");
            OnAfterCheckWhseRcptLines(WhseRcptHeader, WhseRcptLine);
            if WhseRcptHeader."Receiving No." = '' then begin
                WhseRcptHeader.TestField("Receiving No. Series");
                WhseRcptHeader."Receiving No." :=
                  NoSeriesMgt.GetNextNo(
                    WhseRcptHeader."Receiving No. Series", WhseRcptHeader."Posting Date", true);
            end;
            WhseRcptHeader."Create Posted Header" := true;
            OnCodeOnBeforeWhseRcptHeaderModify(WhseRcptHeader, WhseRcptLine);
            WhseRcptHeader.Modify();
            if not SuppressCommit then
                Commit();

            SetCurrentKey("No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
            FindSet(true, true);
            repeat
                WhseManagement.SetSourceFilterForWhseRcptLine(WhseRcptLine, "Source Type", "Source Subtype", "Source No.", -1, false);
                GetSourceDocument;
                MakePreliminaryChecks;
                InitSourceDocumentLines(WhseRcptLine);
                InitSourceDocumentHeader;
                if not SuppressCommit then
                    Commit();

                CounterSourceDocTotal := CounterSourceDocTotal + 1;

                IsHandled := false;
                OnBeforePostSourceDocument(
                    WhseRcptLine, PurchHeader, SalesHeader, TransHeader, CounterSourceDocOK, HideValidationDialog, IsHandled);
                if not IsHandled then
                    PostSourceDocument(WhseRcptLine);

                if FindLast then;
                SetRange("Source Type");
                SetRange("Source Subtype");
                SetRange("Source No.");
            until Next = 0;

            OnCodeOnAfterPostSourceDocuments(WhseRcptHeader, WhseRcptLine);

            GetLocation("Location Code");
            PutAwayRequired := Location.RequirePutaway("Location Code");
            if PutAwayRequired and not Location."Use Put-away Worksheet" then begin
                CreatePutAwayDoc(WhseRcptHeader);
                if not SuppressCommit then
                    Commit();
            end;

            Clear(WMSMgt);
            Clear(WhseJnlRegisterLine);
        end;

        OnAfterCode(WhseRcptHeader);
    end;

    local procedure GetSourceDocument()
    begin
        with WhseRcptLine do
            case "Source Type" of
                DATABASE::"Purchase Line":
                    PurchHeader.Get("Source Subtype", "Source No.");
                DATABASE::"Sales Line": // Return Order
                    SalesHeader.Get("Source Subtype", "Source No.");
                DATABASE::"Transfer Line":
                    TransHeader.Get("Source No.");
            end;
    end;

    local procedure MakePreliminaryChecks()
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        with WhseRcptHeader do begin
            if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                FieldError("Posting Date", Text004);
        end;
    end;

    local procedure InitSourceDocumentHeader()
    var
        SalesRelease: Codeunit "Release Sales Document";
        PurchRelease: Codeunit "Release Purchase Document";
        ModifyHeader: Boolean;
    begin
        with WhseRcptLine do
            case "Source Type" of
                DATABASE::"Purchase Line":
                    begin
                        if (PurchHeader."Posting Date" = 0D) or
                           (PurchHeader."Posting Date" <> WhseRcptHeader."Posting Date")
                        then begin
                            PurchRelease.Reopen(PurchHeader);
                            PurchRelease.SetSkipCheckReleaseRestrictions;
                            PurchHeader.SetHideValidationDialog(true);
                            PurchHeader.Validate("Posting Date", WhseRcptHeader."Posting Date");
                            PurchRelease.Run(PurchHeader);
                            ModifyHeader := true;
                        end;
                        if WhseRcptHeader."Vendor Shipment No." <> '' then begin
                            PurchHeader."Vendor Shipment No." := WhseRcptHeader."Vendor Shipment No.";
                            ModifyHeader := true;
                        end;
                        OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(PurchHeader, WhseRcptHeader, ModifyHeader);
                        if ModifyHeader then
                            PurchHeader.Modify();
                    end;
                DATABASE::"Sales Line": // Return Order
                    begin
                        if (SalesHeader."Posting Date" = 0D) or
                           (SalesHeader."Posting Date" <> WhseRcptHeader."Posting Date")
                        then begin
                            SalesRelease.Reopen(SalesHeader);
                            SalesRelease.SetSkipCheckReleaseRestrictions;
                            SalesHeader.SetHideValidationDialog(true);
                            SalesHeader.Validate("Posting Date", WhseRcptHeader."Posting Date");
                            SalesRelease.Run(SalesHeader);
                            ModifyHeader := true;
                        end;
                        OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(SalesHeader, WhseRcptHeader, ModifyHeader);
                        if ModifyHeader then
                            SalesHeader.Modify();
                    end;
                DATABASE::"Transfer Line":
                    begin
                        if (TransHeader."Posting Date" = 0D) or
                           (TransHeader."Posting Date" <> WhseRcptHeader."Posting Date")
                        then begin
                            TransHeader.CalledFromWarehouse(true);
                            TransHeader.Validate("Posting Date", WhseRcptHeader."Posting Date");
                            ModifyHeader := true;
                        end;
                        if WhseRcptHeader."Vendor Shipment No." <> '' then begin
                            TransHeader."External Document No." := WhseRcptHeader."Vendor Shipment No.";
                            ModifyHeader := true;
                        end;
                        OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(TransHeader, WhseRcptHeader, ModifyHeader);
                        if ModifyHeader then
                            TransHeader.Modify();
                    end;
                else
                    OnInitSourceDocumentHeader(WhseRcptHeader, WhseRcptLine);
            end;
    end;

    local procedure InitSourceDocumentLines(var WhseRcptLine: Record "Warehouse Receipt Line")
    var
        WhseRcptLine2: Record "Warehouse Receipt Line";
        TransLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ModifyLine: Boolean;
    begin
        WhseRcptLine2.Copy(WhseRcptLine);
        with WhseRcptLine2 do begin
            case "Source Type" of
                DATABASE::"Purchase Line":
                    begin
                        PurchLine.SetRange("Document Type", "Source Subtype");
                        PurchLine.SetRange("Document No.", "Source No.");
                        if PurchLine.Find('-') then
                            repeat
                                SetRange("Source Line No.", PurchLine."Line No.");
                                if FindFirst then begin
                                    OnAfterFindWhseRcptLineForPurchLine(WhseRcptLine2, PurchLine);
                                    if "Source Document" = "Source Document"::"Purchase Order" then begin
                                        ModifyLine := PurchLine."Qty. to Receive" <> "Qty. to Receive";
                                        if ModifyLine then
                                            PurchLine.Validate("Qty. to Receive", "Qty. to Receive")
                                    end else begin
                                        ModifyLine := PurchLine."Return Qty. to Ship" <> -"Qty. to Receive";
                                        if ModifyLine then
                                            PurchLine.Validate("Return Qty. to Ship", -"Qty. to Receive");
                                    end;
                                    if PurchLine."Bin Code" <> "Bin Code" then begin
                                        PurchLine."Bin Code" := "Bin Code";
                                        ModifyLine := true;
                                    end;
                                    OnInitSourceDocumentLinesOnAfterSourcePurchLineFound(PurchLine, WhseRcptLine2, ModifyLine);
                                end else
                                    if "Source Document" = "Source Document"::"Purchase Order" then begin
                                        ModifyLine := PurchLine."Qty. to Receive" <> 0;
                                        if ModifyLine then
                                            PurchLine.Validate("Qty. to Receive", 0);
                                    end else begin
                                        ModifyLine := PurchLine."Return Qty. to Ship" <> 0;
                                        if ModifyLine then
                                            PurchLine.Validate("Return Qty. to Ship", 0);
                                    end;
                                OnBeforePurchLineModify(PurchLine, WhseRcptLine2, ModifyLine);
                                if ModifyLine then
                                    PurchLine.Modify();
                            until PurchLine.Next = 0;
                    end;
                DATABASE::"Sales Line": // Return Order
                    begin
                        SalesLine.SetRange("Document Type", "Source Subtype");
                        SalesLine.SetRange("Document No.", "Source No.");
                        if SalesLine.Find('-') then
                            repeat
                                SetRange("Source Line No.", SalesLine."Line No.");
                                if FindFirst then begin
                                    OnAfterFindWhseRcptLineForSalesLine(WhseRcptLine2, SalesLine);
                                    if "Source Document" = "Source Document"::"Sales Order" then begin
                                        ModifyLine := SalesLine."Qty. to Ship" <> -"Qty. to Receive";
                                        if ModifyLine then
                                            SalesLine.Validate("Qty. to Ship", -"Qty. to Receive");
                                    end else begin
                                        ModifyLine := SalesLine."Return Qty. to Receive" <> "Qty. to Receive";
                                        if ModifyLine then
                                            SalesLine.Validate("Return Qty. to Receive", "Qty. to Receive");
                                    end;
                                    if SalesLine."Bin Code" <> "Bin Code" then begin
                                        SalesLine."Bin Code" := "Bin Code";
                                        ModifyLine := true;
                                    end;
                                    OnInitSourceDocumentLinesOnAfterSourceSalesLineFound(SalesLine, WhseRcptLine2, ModifyLine);
                                end else
                                    if "Source Document" = "Source Document"::"Sales Order" then begin
                                        ModifyLine := SalesLine."Qty. to Ship" <> 0;
                                        if ModifyLine then
                                            SalesLine.Validate("Qty. to Ship", 0);
                                    end else begin
                                        ModifyLine := SalesLine."Return Qty. to Receive" <> 0;
                                        if ModifyLine then
                                            SalesLine.Validate("Return Qty. to Receive", 0);
                                    end;
                                OnBeforeSalesLineModify(SalesLine, WhseRcptLine2, ModifyLine);
                                if ModifyLine then
                                    SalesLine.Modify();
                            until SalesLine.Next = 0;
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransLine.SetRange("Document No.", "Source No.");
                        TransLine.SetRange("Derived From Line No.", 0);
                        if TransLine.Find('-') then
                            repeat
                                SetRange("Source Line No.", TransLine."Line No.");
                                if FindFirst then begin
                                    OnAfterFindWhseRcptLineForTransLine(WhseRcptLine2, TransLine);
                                    ModifyLine := TransLine."Qty. to Receive" <> "Qty. to Receive";
                                    if ModifyLine then
                                        TransLine.Validate("Qty. to Receive", "Qty. to Receive");
                                    if TransLine."Transfer-To Bin Code" <> "Bin Code" then begin
                                        TransLine."Transfer-To Bin Code" := "Bin Code";
                                        ModifyLine := true;
                                    end;
                                    OnInitSourceDocumentLinesOnAfterSourceTransLineFound(TransLine, WhseRcptLine2, ModifyLine);
                                end else begin
                                    ModifyLine := TransLine."Qty. to Receive" <> 0;
                                    if ModifyLine then
                                        TransLine.Validate("Qty. to Receive", 0);
                                end;
                                OnBeforeTransLineModify(TransLine, WhseRcptLine2, ModifyLine);
                                if ModifyLine then
                                    TransLine.Modify();
                            until TransLine.Next = 0;
                    end;
                else
                    OnInitSourceDocumentLines(WhseRcptLine2);
            end;
            SetRange("Source Line No.");
        end;

        OnAfterInitSourceDocumentLines(WhseRcptLine2);
    end;

    local procedure PostSourceDocument(WhseRcptLine: Record "Warehouse Receipt Line")
    var
        WhseSetup: Record "Warehouse Setup";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        PurchPost: Codeunit "Purch.-Post";
        SalesPost: Codeunit "Sales-Post";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        IsHandled: Boolean;
    begin
        WhseSetup.Get();
        with WhseRcptLine do begin
            WhseRcptHeader.Get("No.");
            case "Source Type" of
                DATABASE::"Purchase Line":
                    begin
                        if "Source Document" = "Source Document"::"Purchase Order" then
                            PurchHeader.Receive := true
                        else
                            PurchHeader.Ship := true;
                        PurchHeader.Invoice := false;

                        PurchPost.SetWhseRcptHeader(WhseRcptHeader);
                        case WhseSetup."Receipt Posting Policy" of
                            WhseSetup."Receipt Posting Policy"::"Posting errors are not processed":
                                begin
                                    if PurchPost.Run(PurchHeader) then
                                        CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                            WhseSetup."Receipt Posting Policy"::"Stop and show the first posting error":
                                begin
                                    PurchPost.Run(PurchHeader);
                                    CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                        end;
                        Clear(PurchPost);
                    end;
                DATABASE::"Sales Line": // Return Order
                    begin
                        if "Source Document" = "Source Document"::"Sales Order" then
                            SalesHeader.Ship := true
                        else
                            SalesHeader.Receive := true;
                        SalesHeader.Invoice := false;

                        SalesPost.SetWhseRcptHeader(WhseRcptHeader);
                        case WhseSetup."Receipt Posting Policy" of
                            WhseSetup."Receipt Posting Policy"::"Posting errors are not processed":
                                begin
                                    if SalesPost.Run(SalesHeader) then
                                        CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                            WhseSetup."Receipt Posting Policy"::"Stop and show the first posting error":
                                begin
                                    SalesPost.Run(SalesHeader);
                                    CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                        end;
                        Clear(SalesPost);
                    end;
                DATABASE::"Transfer Line":
                    begin
                        if HideValidationDialog then
                            TransferPostReceipt.SetHideValidationDialog(HideValidationDialog);
                        TransferPostReceipt.SetWhseRcptHeader(WhseRcptHeader);
                        case WhseSetup."Receipt Posting Policy" of
                            WhseSetup."Receipt Posting Policy"::"Posting errors are not processed":
                                begin
                                    if TransferPostReceipt.Run(TransHeader) then
                                        CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                            WhseSetup."Receipt Posting Policy"::"Stop and show the first posting error":
                                begin
                                    TransferPostReceipt.Run(TransHeader);
                                    CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                        end;
                        Clear(TransferPostReceipt);
                    end;
                else
                    OnPostSourceDocument(WhseRcptHeader, WhseRcptLine);
            end;
        end;
    end;

    procedure GetResultMessage()
    var
        MessageText: Text[250];
    begin
        MessageText := Text002;
        if CounterPutAways > 0 then
            MessageText := MessageText + '\\' + Text003;
        Message(MessageText, CounterSourceDocOK, CounterSourceDocTotal, CounterPutAways);
    end;

    procedure PostUpdateWhseDocuments(var WhseRcptHeader: Record "Warehouse Receipt Header")
    var
        WhseRcptLine2: Record "Warehouse Receipt Line";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        DeleteWhseRcptLine: Boolean;
    begin
        OnBeforePostUpdateWhseDocuments(WhseRcptHeader);
        with WhseRcptLineBuf do
            if Find('-') then begin
                repeat
                    WhseRcptLine2.Get("No.", "Line No.");
                    DeleteWhseRcptLine := "Qty. Outstanding" = "Qty. to Receive";
                    OnBeforePostUpdateWhseRcptLine(WhseRcptLine2, WhseRcptLineBuf, DeleteWhseRcptLine, WhseRcptHeader);
                    if DeleteWhseRcptLine then
                        WhseRcptLine2.Delete
                    else begin
                        WhseRcptLine2.Validate("Qty. Received", "Qty. Received" + "Qty. to Receive");
                        WhseRcptLine2.Validate("Qty. Outstanding", "Qty. Outstanding" - "Qty. to Receive");
                        WhseRcptLine2."Qty. to Cross-Dock" := 0;
                        WhseRcptLine2."Qty. to Cross-Dock (Base)" := 0;
                        WhseRcptLine2.Status := WhseRcptLine2.GetLineStatus;
                        WhseRcptLine2.Modify();
                        OnAfterPostUpdateWhseRcptLine(WhseRcptLine2);
                    end;
                until Next = 0;
                OnPostUpdateWhseDocumentsOnBeforeDeleteAll(WhseRcptHeader, WhseRcptLineBuf);
                DeleteAll();
            end;

        if WhseRcptHeader."Create Posted Header" then begin
            WhseRcptHeader."Last Receiving No." := WhseRcptHeader."Receiving No.";
            WhseRcptHeader."Receiving No." := '';
            WhseRcptHeader."Create Posted Header" := false;
        end;

        WhseRcptLine2.SetRange("No.", WhseRcptHeader."No.");
        if WhseRcptLine2.FindFirst then begin
            WhseRcptHeader."Document Status" := WhseRcptHeader.GetHeaderStatus(0);
            WhseRcptHeader.Modify();
        end else begin
            WhseRcptHeader.DeleteRelatedLines(false);
            WhseRcptHeader.Delete();
        end;

        GetLocation(WhseRcptHeader."Location Code");
        if Location."Require Put-away" then begin
            WhsePutAwayRequest."Document Type" := WhsePutAwayRequest."Document Type"::Receipt;
            WhsePutAwayRequest."Document No." := WhseRcptHeader."Last Receiving No.";
            WhsePutAwayRequest."Location Code" := WhseRcptHeader."Location Code";
            WhsePutAwayRequest."Zone Code" := WhseRcptHeader."Zone Code";
            WhsePutAwayRequest."Bin Code" := WhseRcptHeader."Bin Code";
            if WhsePutAwayRequest.Insert() then;
        end;

        OnAfterPostUpdateWhseDocuments(WhseRcptHeader, WhsePutAwayRequest);
    end;

    procedure CreatePostedRcptHeader(var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var WhseRcptHeader: Record "Warehouse Receipt Header"; ReceivingNo2: Code[20]; PostingDate2: Date)
    var
        WhseComment: Record "Warehouse Comment Line";
        WhseComment2: Record "Warehouse Comment Line";
    begin
        ReceivingNo := ReceivingNo2;
        PostingDate := PostingDate2;

        if not WhseRcptHeader."Create Posted Header" then begin
            PostedWhseRcptHeader.Get(WhseRcptHeader."Last Receiving No.");
            exit;
        end;

        PostedWhseRcptHeader.Init();
        PostedWhseRcptHeader.TransferFields(WhseRcptHeader);
        PostedWhseRcptHeader."No." := WhseRcptHeader."Receiving No.";
        PostedWhseRcptHeader."Whse. Receipt No." := WhseRcptHeader."No.";
        PostedWhseRcptHeader."No. Series" := WhseRcptHeader."Receiving No. Series";

        GetLocation(PostedWhseRcptHeader."Location Code");
        if not Location."Require Put-away" then
            PostedWhseRcptHeader."Document Status" := PostedWhseRcptHeader."Document Status"::"Completely Put Away";
        OnBeforePostedWhseRcptHeaderInsert(PostedWhseRcptHeader, WhseRcptHeader);
        PostedWhseRcptHeader.Insert();

        WhseComment.SetRange("Table Name", WhseComment."Table Name"::"Whse. Receipt");
        WhseComment.SetRange(Type, WhseComment.Type::" ");
        WhseComment.SetRange("No.", WhseRcptHeader."No.");
        if WhseComment.Find('-') then
            repeat
                WhseComment2.Init();
                WhseComment2 := WhseComment;
                WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Whse. Receipt";
                WhseComment2."No." := PostedWhseRcptHeader."No.";
                WhseComment2.Insert();
            until WhseComment.Next = 0;
    end;

    procedure CreatePostedRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempHandlingSpecification: Record "Tracking Specification")
    begin
        UpdateWhseRcptLineBuf(WhseRcptLine);
        with PostedWhseRcptLine do begin
            Init;
            TransferFields(WhseRcptLine);
            "No." := PostedWhseRcptHeader."No.";
            OnAfterInitPostedRcptLine(WhseRcptLine, PostedWhseRcptLine);
            Quantity := WhseRcptLine."Qty. to Receive";
            "Qty. (Base)" := WhseRcptLine."Qty. to Receive (Base)";
            case WhseRcptLine."Source Document" of
                WhseRcptLine."Source Document"::"Purchase Order":
                    "Posted Source Document" := "Posted Source Document"::"Posted Receipt";
                WhseRcptLine."Source Document"::"Sales Order":
                    "Posted Source Document" := "Posted Source Document"::"Posted Shipment";
                WhseRcptLine."Source Document"::"Purchase Return Order":
                    "Posted Source Document" := "Posted Source Document"::"Posted Return Shipment";
                WhseRcptLine."Source Document"::"Sales Return Order":
                    "Posted Source Document" := "Posted Source Document"::"Posted Return Receipt";
                WhseRcptLine."Source Document"::"Inbound Transfer":
                    "Posted Source Document" := "Posted Source Document"::"Posted Transfer Receipt";
            end;

            GetLocation("Location Code");
            if not Location."Require Put-away" then begin
                "Qty. Put Away" := Quantity;
                "Qty. Put Away (Base)" := "Qty. (Base)";
                Status := Status::"Completely Put Away";
            end;
            "Posted Source No." := ReceivingNo;
            "Posting Date" := PostingDate;
            "Whse. Receipt No." := WhseRcptLine."No.";
            "Whse Receipt Line No." := WhseRcptLine."Line No.";
            OnBeforePostedWhseRcptLineInsert(PostedWhseRcptLine, WhseRcptLine);
            Insert;
            OnAfterPostedWhseRcptLineInsert(PostedWhseRcptLine, WhseRcptLine);
        end;

        PostWhseJnlLine(PostedWhseRcptHeader, PostedWhseRcptLine, TempHandlingSpecification);
    end;

    local procedure UpdateWhseRcptLineBuf(WhseRcptLine2: Record "Warehouse Receipt Line")
    begin
        with WhseRcptLine2 do begin
            WhseRcptLineBuf."No." := "No.";
            WhseRcptLineBuf."Line No." := "Line No.";
            if not WhseRcptLineBuf.Find then begin
                WhseRcptLineBuf.Init();
                WhseRcptLineBuf := WhseRcptLine2;
                WhseRcptLineBuf.Insert();
            end;
        end;
    end;

    local procedure PostWhseJnlLine(var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary)
    var
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(PostedWhseRcptHeader, PostedWhseRcptLine, WhseRcptLine, TempWhseSplitSpecification, IsHandled);
        if IsHandled then
            exit;

        with PostedWhseRcptLine do begin
            GetLocation("Location Code");
            InsertWhseItemEntryRelation(PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);

            if Location."Bin Mandatory" then begin
                InsertTempWhseJnlLine(PostedWhseRcptLine);

                TempWhseJnlLine.Get('', '', "Location Code", "Line No.");
                TempWhseJnlLine."Line No." := 0;
                TempWhseJnlLine."Reference No." := ReceivingNo;
                TempWhseJnlLine."Registering Date" := PostingDate;
                TempWhseJnlLine."Whse. Document Type" := TempWhseJnlLine."Whse. Document Type"::Receipt;
                TempWhseJnlLine."Whse. Document No." := "No.";
                TempWhseJnlLine."Whse. Document Line No." := "Line No.";
                TempWhseJnlLine."Registering No. Series" := PostedWhseRcptHeader."No. Series";
                OnBeforeRegisterWhseJnlLines(TempWhseJnlLine, PostedWhseRcptHeader, PostedWhseRcptLine);

                ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempWhseSplitSpecification, false);
                if TempWhseJnlLine2.Find('-') then
                    repeat
                        WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                    until TempWhseJnlLine2.Next = 0;
            end;
        end;

        OnAfterPostWhseJnlLine(WhseRcptLine);
    end;

    local procedure InsertWhseItemEntryRelation(var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary)
    var
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
    begin
        if ItemEntryRelationCreated then begin
            if TempWhseItemEntryRelation.Find('-') then begin
                repeat
                    WhseItemEntryRelation := TempWhseItemEntryRelation;
                    WhseItemEntryRelation.SetSource(
                      DATABASE::"Posted Whse. Receipt Line", 0, PostedWhseRcptHeader."No.", PostedWhseRcptLine."Line No.");
                    WhseItemEntryRelation.Insert();
                until TempWhseItemEntryRelation.Next = 0;
                ItemEntryRelationCreated := false;
            end;
            exit;
        end;
        TempWhseSplitSpecification.Reset();
        if TempWhseSplitSpecification.Find('-') then
            repeat
                WhseItemEntryRelation.InitFromTrackingSpec(TempWhseSplitSpecification);
                WhseItemEntryRelation.SetSource(
                  DATABASE::"Posted Whse. Receipt Line", 0, PostedWhseRcptHeader."No.", PostedWhseRcptLine."Line No.");
                WhseItemEntryRelation.Insert();
            until TempWhseSplitSpecification.Next = 0;
    end;

    procedure GetFirstPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header"): Boolean
    begin
        exit(CreatePutAway.GetFirstPutAwayDocument(WhseActivHeader));
    end;

    procedure GetNextPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header"): Boolean
    begin
        exit(CreatePutAway.GetNextPutAwayDocument(WhseActivHeader));
    end;

    local procedure InsertTempWhseJnlLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        with PostedWhseRcptLine do begin
            TempWhseJnlLine.Init();
            TempWhseJnlLine."Entry Type" := TempWhseJnlLine."Entry Type"::"Positive Adjmt.";
            TempWhseJnlLine."Line No." := "Line No.";
            TempWhseJnlLine."Location Code" := "Location Code";
            TempWhseJnlLine."To Zone Code" := "Zone Code";
            TempWhseJnlLine."To Bin Code" := "Bin Code";
            TempWhseJnlLine."Item No." := "Item No.";
            TempWhseJnlLine.Description := Description;
            GetLocation("Location Code");
            if Location."Directed Put-away and Pick" then begin
                TempWhseJnlLine."Qty. (Absolute)" := Quantity;
                TempWhseJnlLine."Unit of Measure Code" := "Unit of Measure Code";
                TempWhseJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                GetItemUnitOfMeasure2("Item No.", "Unit of Measure Code");
                TempWhseJnlLine.Cubage := Abs(TempWhseJnlLine."Qty. (Absolute)") * ItemUnitOfMeasure.Cubage;
                TempWhseJnlLine.Weight := Abs(TempWhseJnlLine."Qty. (Absolute)") * ItemUnitOfMeasure.Weight;
            end else begin
                TempWhseJnlLine."Qty. (Absolute)" := "Qty. (Base)";
                TempWhseJnlLine."Unit of Measure Code" := WMSMgt.GetBaseUOM("Item No.");
                TempWhseJnlLine."Qty. per Unit of Measure" := 1;
            end;

            TempWhseJnlLine."Qty. (Absolute, Base)" := "Qty. (Base)";
            TempWhseJnlLine."User ID" := UserId;
            TempWhseJnlLine."Variant Code" := "Variant Code";
            TempWhseJnlLine.SetSource("Source Type", "Source Subtype", "Source No.", "Source Line No.", 0);
            TempWhseJnlLine."Source Document" := "Source Document";
            SourceCodeSetup.Get();
            case "Source Document" of
                "Source Document"::"Purchase Order":
                    begin
                        TempWhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                        TempWhseJnlLine."Reference Document" :=
                          TempWhseJnlLine."Reference Document"::"Posted Rcpt.";
                    end;
                "Source Document"::"Sales Order":
                    begin
                        TempWhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                        TempWhseJnlLine."Reference Document" :=
                          TempWhseJnlLine."Reference Document"::"Posted Shipment";
                    end;
                "Source Document"::"Purchase Return Order":
                    begin
                        TempWhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                        TempWhseJnlLine."Reference Document" :=
                          TempWhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
                    end;
                "Source Document"::"Sales Return Order":
                    begin
                        TempWhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                        TempWhseJnlLine."Reference Document" :=
                          TempWhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
                    end;
                "Source Document"::"Inbound Transfer":
                    begin
                        TempWhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                        TempWhseJnlLine."Reference Document" :=
                          TempWhseJnlLine."Reference Document"::"Posted T. Receipt";
                    end;
            end;

            OnBeforeInsertTempWhseJnlLine(TempWhseJnlLine, PostedWhseRcptLine);

            ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
            if WhseItemTrackingSetup."Serial No. Required" then
                TestField("Qty. per Unit of Measure", 1);

            WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 0, 0, false);
            TempWhseJnlLine.Insert();
        end;
    end;

    local procedure CreatePutAwayDoc(WhseRcptHeader: Record "Warehouse Receipt Header")
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary;
        TempPostedWhseRcptLine2: Record "Posted Whse. Receipt Line" temporary;
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        RemQtyToHandleBase: Decimal;
        IsHandled: Boolean;
    begin
        PostedWhseRcptLine.SetRange("No.", WhseRcptHeader."Receiving No.");
        if not PostedWhseRcptLine.Find('-') then
            exit;

        repeat
            RemQtyToHandleBase := PostedWhseRcptLine."Qty. (Base)";
            IsHandled := false;
            OnBeforeCreatePutAwayDoc(WhseRcptHeader, PostedWhseRcptLine, IsHandled);
            if not IsHandled then begin
                CreatePutAway.SetValues('', 0, false, false);
                CreatePutAway.SetCrossDockValues(true);

                if ItemTrackingMgt.GetWhseItemTrkgSetup(PostedWhseRcptLine."Item No.") then
                    ItemTrackingMgt.InitItemTrkgForTempWkshLine(
                      WhseWkshLine."Whse. Document Type"::Receipt,
                      PostedWhseRcptLine."No.", PostedWhseRcptLine."Line No.",
                      PostedWhseRcptLine."Source Type", PostedWhseRcptLine."Source Subtype",
                      PostedWhseRcptLine."Source No.", PostedWhseRcptLine."Source Line No.", 0);

                ItemTrackingMgt.SplitPostedWhseRcptLine(PostedWhseRcptLine, TempPostedWhseRcptLine);

                TempPostedWhseRcptLine.Reset();
                if TempPostedWhseRcptLine.Find('-') then
                    repeat
                        TempPostedWhseRcptLine2 := TempPostedWhseRcptLine;
                        TempPostedWhseRcptLine2."Line No." := PostedWhseRcptLine."Line No.";
                        WhseSourceCreateDocument.SetQuantity(TempPostedWhseRcptLine2, DATABASE::"Posted Whse. Receipt Line", RemQtyToHandleBase);
                        OnCreatePutAwayDocOnBeforeCreatePutAwayRun(TempPostedWhseRcptLine2, CreatePutAway);
                        CreatePutAway.Run(TempPostedWhseRcptLine2);
                    until TempPostedWhseRcptLine.Next = 0;
            end;
        until PostedWhseRcptLine.Next = 0;

        if GetFirstPutAwayDocument(WhseActivHeader) then
            repeat
                CreatePutAway.DeleteBlankBinContent(WhseActivHeader);
                OnAfterCreatePutAwayDeleteBlankBinContent(WhseActivHeader);
                CounterPutAways := CounterPutAways + 1;
            until not GetNextPutAwayDocument(WhseActivHeader);

        OnAfterCreatePutAwayDoc(WhseRcptHeader);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if not Location.Get(LocationCode) then;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetItemUnitOfMeasure2(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    procedure SetItemEntryRelation(PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var ItemEntryRelation: Record "Item Entry Relation")
    begin
        if ItemEntryRelation.Find('-') then begin
            TempWhseItemEntryRelation.DeleteAll();
            repeat
                TempWhseItemEntryRelation.Init();
                TempWhseItemEntryRelation.TransferFields(ItemEntryRelation);
                TempWhseItemEntryRelation.SetSource(
                  DATABASE::"Posted Whse. Receipt Line", 0, PostedWhseRcptHeader."No.", PostedWhseRcptLine."Line No.");
                TempWhseItemEntryRelation.Insert();
            until ItemEntryRelation.Next = 0;
            ItemEntryRelationCreated := true;
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutAwayDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutAwayDeleteBlankBinContent(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseRcptLineForPurchLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseRcptLineForSalesLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseRcptLineForTransLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhsePutAwayRequest: Record "Whse. Put-away Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptLineBuf: Record "Warehouse Receipt Line"; var DeleteWhseRcptLine: Boolean; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WhseReceiptLine: Record "Warehouse Receipt Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterWhseJnlLines(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterPostSourceDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseRcptLineInsert(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSourceDocumentLines(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseRcptLines(var WhseRcptHeader: Record "Warehouse Receipt Header"; var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempWhseJnlLine(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineModify(var TransferLine: Record "Transfer Line"; WhseRcptLine: Record "Warehouse Receipt Line"; var ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDocument(var WhseRcptLine: Record "Warehouse Receipt Line"; PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; TransferHeader: Record "Transfer Header"; var CounterSourceDocOK: Integer; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseDocuments(var WhseRcptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseRcptHeaderInsert(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseRcptLineInsert(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeWhseRcptHeaderModify(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutAwayDocOnBeforeCreatePutAwayRun(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var CreatePutAway: Codeunit "Create Put-away")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeader(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforePurchHeaderModify(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeTransHeaderModify(var TransferHeader: Record "Transfer Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLines(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterSourceSalesLineFound(var SalesLine: Record "Sales Line"; WhseRcptLine: Record "Warehouse Receipt Line"; ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterSourcePurchLineFound(var PurchaseLine: Record "Purchase Line"; WhseRcptLine: Record "Warehouse Receipt Line"; ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentLinesOnAfterSourceTransLineFound(var TransferLine: Record "Transfer Line"; WhseRcptLine: Record "Warehouse Receipt Line"; ModifyLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocument(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateWhseDocumentsOnBeforeDeleteAll(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;
}

