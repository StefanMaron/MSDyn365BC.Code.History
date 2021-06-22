codeunit 5763 "Whse.-Post Shipment"
{
    Permissions = TableData "Whse. Item Tracking Line" = r,
                  TableData "Posted Whse. Shipment Header" = im,
                  TableData "Posted Whse. Shipment Line" = i;
    TableNo = "Warehouse Shipment Line";

    trigger OnRun()
    begin
        OnBeforeRun(Rec);

        WhseShptLine.Copy(Rec);
        Code;
        Rec := WhseShptLine;

        OnAfterRun(Rec);
    end;

    var
        Text000: Label 'The source document %1 %2 is not released.';
        Text001: Label 'There is nothing to post.';
        Text003: Label 'Number of source documents posted: %1 out of a total of %2.';
        Text004: Label 'Ship lines have been posted.';
        Text005: Label 'Some ship lines remain.';
        WhseRqst: Record "Warehouse Request";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseShptLineBuf: Record "Warehouse Shipment Line" temporary;
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
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
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
        WrongQuantityValueErr: Label 'This document cannot be shipped completely. Change the value in the Shipping Advice field to Partial.';
        SuppressCommit: Boolean;

    local procedure "Code"()
    begin
        with WhseShptLine do begin
            SetCurrentKey("No.");
            SetRange("No.", "No.");
            OnBeforeCheckWhseShptLines(WhseShptLine);
            SetFilter("Qty. to Ship", '>0');
            if Find('-') then
                repeat
                    TestField("Unit of Measure Code");
                    if ("Shipping Advice" = "Shipping Advice"::Complete) and
                       ("Qty. (Base)" <> "Qty. to Ship (Base)" + "Qty. Shipped (Base)")
                    then
                        Error(WrongQuantityValueErr);
                    WhseRqst.Get(
                      WhseRqst.Type::Outbound, "Location Code", "Source Type", "Source Subtype", "Source No.");
                    if WhseRqst."Document Status" <> WhseRqst."Document Status"::Released then
                        Error(Text000, "Source Document", "Source No.");
                    GetLocation("Location Code");
                    if Location."Require Pick" and ("Shipping Advice" = "Shipping Advice"::Complete) then
                        CheckItemTrkgPicked(WhseShptLine);
                    if Location."Bin Mandatory" then
                        TestField("Bin Code");
                    if not "Assemble to Order" then
                        if not FullATOPosted then
                            Error(FullATONotPostedErr, "No.", "Line No.");

                    OnAfterCheckWhseShptLine(WhseShptLine);
                until Next = 0
            else
                Error(Text001);

            CounterSourceDocOK := 0;
            CounterSourceDocTotal := 0;

            GetLocation("Location Code");
            WhseShptHeader.Get("No.");
            WhseShptHeader.TestField("Posting Date");
            OnAfterCheckWhseShptLines(WhseShptHeader, WhseShptLine, Invoice, SuppressCommit);
            if WhseShptHeader."Shipping No." = '' then begin
                WhseShptHeader.TestField("Shipping No. Series");
                WhseShptHeader."Shipping No." :=
                  NoSeriesMgt.GetNextNo(
                    WhseShptHeader."Shipping No. Series", WhseShptHeader."Posting Date", true);
            end;

            if not SuppressCommit then
                Commit();

            WhseShptHeader."Create Posted Header" := true;
            WhseShptHeader.Modify();

            SetCurrentKey("No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
            OnAfterSetCurrentKeyForWhseShptLine(WhseShptLine);
            FindSet(true, true);
            repeat
                SetSourceFilter("Source Type", "Source Subtype", "Source No.", -1, false);
                OnAfterSetSourceFilterForWhseShptLine(WhseShptLine);
                GetSourceDocument;
                MakePreliminaryChecks;

                InitSourceDocumentLines(WhseShptLine);
                InitSourceDocumentHeader;
                if not SuppressCommit then
                    Commit();

                CounterSourceDocTotal := CounterSourceDocTotal + 1;

                OnBeforePostSourceDocument(WhseShptLine, PurchHeader, SalesHeader, TransHeader, ServiceHeader);
                PostSourceDocument(WhseShptLine);

                if FindLast then;
                SetRange("Source Type");
                SetRange("Source Subtype");
                SetRange("Source No.");
                OnAfterReleaseSourceForFilterWhseShptLine(WhseShptLine);
            until Next = 0;
        end;

        OnAfterPostWhseShipment(WhseShptHeader);

        Clear(WMSMgt);
        Clear(WhseJnlRegisterLine);

        WhseShptLine.Reset();
    end;

    local procedure GetSourceDocument()
    begin
        with WhseShptLine do
            case "Source Type" of
                DATABASE::"Sales Line":
                    SalesHeader.Get("Source Subtype", "Source No.");
                DATABASE::"Purchase Line": // Return Order
                    PurchHeader.Get("Source Subtype", "Source No.");
                DATABASE::"Transfer Line":
                    TransHeader.Get("Source No.");
                DATABASE::"Service Line":
                    ServiceHeader.Get("Source Subtype", "Source No.");
            end;
    end;

    local procedure MakePreliminaryChecks()
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        with WhseShptHeader do begin
            if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                FieldError("Posting Date", Text007);
        end;
    end;

    local procedure InitSourceDocumentHeader()
    var
        SalesRelease: Codeunit "Release Sales Document";
        PurchRelease: Codeunit "Release Purchase Document";
        ReleaseServiceDocument: Codeunit "Release Service Document";
        ModifyHeader: Boolean;
        ValidatePostingDate: Boolean;
    begin
        OnBeforeInitSourceDocumentHeader(WhseShptLine);

        with WhseShptLine do
            case "Source Type" of
                DATABASE::"Sales Line":
                    begin
                        OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(SalesHeader, WhseShptLine, ValidatePostingDate);
                        if (SalesHeader."Posting Date" = 0D) or
                           (SalesHeader."Posting Date" <> WhseShptHeader."Posting Date") or ValidatePostingDate
                        then begin
                            OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(SalesHeader, Invoice);
                            SalesRelease.Reopen(SalesHeader);
                            SalesRelease.SetSkipCheckReleaseRestrictions;
                            SalesHeader.SetHideValidationDialog(true);
                            SalesHeader.Validate("Posting Date", WhseShptHeader."Posting Date");
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
                DATABASE::"Purchase Line": // Return Order
                    begin
                        if (PurchHeader."Posting Date" = 0D) or
                           (PurchHeader."Posting Date" <> WhseShptHeader."Posting Date")
                        then begin
                            PurchRelease.Reopen(PurchHeader);
                            PurchRelease.SetSkipCheckReleaseRestrictions;
                            PurchHeader.SetHideValidationDialog(true);
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
                DATABASE::"Transfer Line":
                    begin
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
                DATABASE::"Service Line":
                    begin
                        if (ServiceHeader."Posting Date" = 0D) or (ServiceHeader."Posting Date" <> WhseShptHeader."Posting Date") then begin
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
            DATABASE::"Sales Line":
                HandleSalesLine(WhseShptLine2);
            DATABASE::"Purchase Line": // Return Order
                HandlePurchaseLine(WhseShptLine2);
            DATABASE::"Transfer Line":
                HandleTransferLine(WhseShptLine2);
            DATABASE::"Service Line":
                HandleServiceLine(WhseShptLine2);
        end;
        WhseShptLine2.SetRange("Source Line No.");
    end;

    local procedure PostSourceDocument(WhseShptLine: Record "Warehouse Shipment Line")
    var
        WhseSetup: Record "Warehouse Setup";
        WhseShptHeader: Record "Warehouse Shipment Header";
        SalesPost: Codeunit "Sales-Post";
        PurchPost: Codeunit "Purch.-Post";
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        ServicePost: Codeunit "Service-Post";
        IsHandled: Boolean;
    begin
        WhseSetup.Get();
        with WhseShptLine do begin
            WhseShptHeader.Get("No.");
            case "Source Type" of
                DATABASE::"Sales Line":
                    begin
                        if "Source Document" = "Source Document"::"Sales Order" then
                            SalesHeader.Ship := true
                        else
                            SalesHeader.Receive := true;
                        SalesHeader.Invoice := Invoice;

                        SalesPost.SetWhseShptHeader(WhseShptHeader);
                        case WhseSetup."Shipment Posting Policy" of
                            WhseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                begin
                                    if SalesPost.Run(SalesHeader) then
                                        CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                            WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                begin
                                    SalesPost.Run(SalesHeader);
                                    CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                        end;

                        if Print then
                            if "Source Document" = "Source Document"::"Sales Order" then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintSalesShipment(SalesHeader, IsHandled);
                                if not IsHandled then begin
                                    SalesShptHeader."No." := SalesHeader."Last Shipping No.";
                                    SalesShptHeader.SetRecFilter;
                                    SalesShptHeader.PrintRecords(false);
                                end;
                                if Invoice then begin
                                    IsHandled := false;
                                    OnPostSourceDocumentOnBeforePrintSalesInvoice(SalesHeader, IsHandled);
                                    if not IsHandled then begin
                                        SalesInvHeader."No." := SalesHeader."Last Posting No.";
                                        SalesInvHeader.SetRecFilter;
                                        SalesInvHeader.PrintRecords(false);
                                    end;
                                end;
                            end;

                        OnAfterSalesPost(WhseShptLine, SalesHeader, Invoice);
                        Clear(SalesPost);
                    end;
                DATABASE::"Purchase Line": // Return Order
                    begin
                        if "Source Document" = "Source Document"::"Purchase Order" then
                            PurchHeader.Receive := true
                        else
                            PurchHeader.Ship := true;
                        PurchHeader.Invoice := Invoice;

                        PurchPost.SetWhseShptHeader(WhseShptHeader);
                        case WhseSetup."Shipment Posting Policy" of
                            WhseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                begin
                                    if PurchPost.Run(PurchHeader) then
                                        CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                            WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                begin
                                    PurchPost.Run(PurchHeader);
                                    CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                        end;

                        if Print then
                            if "Source Document" = "Source Document"::"Purchase Return Order" then begin
                                IsHandled := false;
                                OnPostSourceDocumentOnBeforePrintPurchReturnShipment(PurchHeader, IsHandled);
                                if not IsHandled then begin
                                    ReturnShptHeader."No." := PurchHeader."Last Return Shipment No.";
                                    ReturnShptHeader.SetRecFilter;
                                    ReturnShptHeader.PrintRecords(false);
                                end;
                                if Invoice then begin
                                    PurchCrMemHeader."No." := PurchHeader."Last Posting No.";
                                    PurchCrMemHeader.SetRecFilter;
                                    PurchCrMemHeader.PrintRecords(false);
                                end;
                            end;

                        OnAfterPurchPost(WhseShptLine, PurchHeader, Invoice);
                        Clear(PurchPost);
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransferPostShipment.SetWhseShptHeader(WhseShptHeader);
                        case WhseSetup."Shipment Posting Policy" of
                            WhseSetup."Shipment Posting Policy"::"Posting errors are not processed":
                                begin
                                    if TransferPostShipment.Run(TransHeader) then
                                        CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                            WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error":
                                begin
                                    TransferPostShipment.Run(TransHeader);
                                    CounterSourceDocOK := CounterSourceDocOK + 1;
                                end;
                        end;

                        if Print then begin
                            IsHandled := false;
                            OnPostSourceDocumentOnBeforePrintTransferShipment(TransShptHeader, IsHandled);
                            if not IsHandled then begin
                                TransShptHeader."No." := TransHeader."Last Shipment No.";
                                TransShptHeader.SetRecFilter;
                                TransShptHeader.PrintRecords(false);
                            end;
                        end;

                        OnAfterTransferPostShipment(WhseShptLine, TransHeader);
                        Clear(TransferPostShipment);
                    end;
                DATABASE::"Service Line":
                    begin
                        ServicePost.SetPostingOptions(true, false, InvoiceService);
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
                        if Print then
                            if "Source Document" = "Source Document"::"Service Order" then begin
                                ServiceShptHeader."No." := ServiceHeader."Last Shipping No.";
                                ServiceShptHeader.SetRecFilter;
                                ServiceShptHeader.PrintRecords(false);
                                if Invoice then begin
                                    ServiceInvHeader."No." := ServiceHeader."Last Posting No.";
                                    ServiceInvHeader.SetRecFilter;
                                    ServiceInvHeader.PrintRecords(false);
                                end;
                            end;

                        OnAfterServicePost(WhseShptLine, ServiceHeader, Invoice);
                        Clear(ServicePost);
                    end;
                else
                    OnPostSourceDocument(WhseShptHeader, WhseShptLine, CounterSourceDocOK);
            end;
        end;
    end;

    procedure SetPrint(Print2: Boolean)
    begin
        Print := Print2;
    end;

    procedure PostUpdateWhseDocuments(var WhseShptHeaderParam: Record "Warehouse Shipment Header")
    var
        WhseShptLine2: Record "Warehouse Shipment Line";
        DeleteWhseShptLine: Boolean;
    begin
        OnBeforePostUpdateWhseDocuments(WhseShptHeaderParam);
        with WhseShptLineBuf do
            if Find('-') then begin
                repeat
                    WhseShptLine2.Get("No.", "Line No.");
                    DeleteWhseShptLine := "Qty. Outstanding" = "Qty. to Ship";
                    OnBeforeDeleteUpdateWhseShptLine(WhseShptLine2, DeleteWhseShptLine);
                    if DeleteWhseShptLine then begin
                        ItemTrackingMgt.SetDeleteReservationEntries(true);
                        ItemTrackingMgt.DeleteWhseItemTrkgLines(
                          DATABASE::"Warehouse Shipment Line", 0, "No.", '', 0, "Line No.", "Location Code", true);
                        WhseShptLine2.Delete();
                    end else begin
                        OnBeforePostUpdateWhseShptLine(WhseShptLine2);
                        WhseShptLine2."Qty. Shipped" := "Qty. Shipped" + "Qty. to Ship";
                        WhseShptLine2.Validate("Qty. Outstanding", "Qty. Outstanding" - "Qty. to Ship");
                        WhseShptLine2."Qty. Shipped (Base)" := "Qty. Shipped (Base)" + "Qty. to Ship (Base)";
                        WhseShptLine2."Qty. Outstanding (Base)" := "Qty. Outstanding (Base)" - "Qty. to Ship (Base)";
                        WhseShptLine2.Status := WhseShptLine2.CalcStatusShptLine;
                        OnBeforePostUpdateWhseShptLineModify(WhseShptLine2);
                        WhseShptLine2.Modify();
                        OnAfterPostUpdateWhseShptLine(WhseShptLine2);
                    end;
                until Next = 0;
                DeleteAll();
            end;

        WhseShptLine2.SetRange("No.", WhseShptHeaderParam."No.");
        if not WhseShptLine2.FindFirst then begin
            WhseShptHeaderParam.DeleteRelatedLines;
            WhseShptHeaderParam.Delete();
        end else begin
            WhseShptHeaderParam."Document Status" := WhseShptHeaderParam.GetDocumentStatus(0);
            if WhseShptHeaderParam."Create Posted Header" then begin
                WhseShptHeaderParam."Last Shipping No." := WhseShptHeaderParam."Shipping No.";
                WhseShptHeaderParam."Shipping No." := '';
                WhseShptHeaderParam."Create Posted Header" := false;
            end;
            WhseShptHeaderParam.Modify();
        end;

        OnAfterPostUpdateWhseDocuments(WhseShptHeaderParam);
    end;

    procedure GetResultMessage()
    var
        MessageText: Text[250];
    begin
        MessageText := Text003;
        if CounterSourceDocOK > 0 then
            MessageText := MessageText + '\\' + Text004;
        if CounterSourceDocOK < CounterSourceDocTotal then
            MessageText := MessageText + '\\' + Text005;
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
            until WhseComment.Next = 0;

        OnAfterCreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader);
    end;

    procedure CreatePostedShptLine(var WhseShptLine: Record "Warehouse Shipment Line"; var PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempHandlingSpecification: Record "Tracking Specification")
    begin
        UpdateWhseShptLineBuf(WhseShptLine);
        with PostedWhseShptLine do begin
            Init;
            TransferFields(WhseShptLine);
            "No." := PostedWhseShptHeader."No.";
            OnAfterInitPostedShptLine(WhseShptLine, PostedWhseShptLine);
            Quantity := WhseShptLine."Qty. to Ship";
            "Qty. (Base)" := WhseShptLine."Qty. to Ship (Base)";
            if WhseShptHeader."Shipment Date" <> 0D then
                "Shipment Date" := PostedWhseShptHeader."Shipment Date";
            "Source Type" := WhseShptLine."Source Type";
            "Source Subtype" := WhseShptLine."Source Subtype";
            "Source No." := WhseShptLine."Source No.";
            "Source Line No." := WhseShptLine."Source Line No.";
            "Source Document" := WhseShptLine."Source Document";
            case "Source Document" of
                "Source Document"::"Purchase Order":
                    "Posted Source Document" := "Posted Source Document"::"Posted Receipt";
                "Source Document"::"Service Order",
              "Source Document"::"Sales Order":
                    "Posted Source Document" := "Posted Source Document"::"Posted Shipment";
                "Source Document"::"Purchase Return Order":
                    "Posted Source Document" := "Posted Source Document"::"Posted Return Shipment";
                "Source Document"::"Sales Return Order":
                    "Posted Source Document" := "Posted Source Document"::"Posted Return Receipt";
                "Source Document"::"Outbound Transfer":
                    "Posted Source Document" := "Posted Source Document"::"Posted Transfer Shipment";
            end;
            "Posted Source No." := LastShptNo;
            "Posting Date" := PostingDate;
            "Whse. Shipment No." := WhseShptLine."No.";
            "Whse Shipment Line No." := WhseShptLine."Line No.";
            Insert;
        end;

        OnCreatePostedShptLineOnBeforePostWhseJnlLine(PostedWhseShptLine, TempHandlingSpecification, WhseShptLine);
        PostWhseJnlLine(PostedWhseShptLine, TempHandlingSpecification);
        OnAfterPostWhseJnlLine(WhseShptLine);
    end;

    local procedure UpdateWhseShptLineBuf(WhseShptLine2: Record "Warehouse Shipment Line")
    begin
        with WhseShptLine2 do begin
            WhseShptLineBuf."No." := "No.";
            WhseShptLineBuf."Line No." := "Line No.";
            if not WhseShptLineBuf.Find then begin
                WhseShptLineBuf.Init();
                WhseShptLineBuf := WhseShptLine2;
                WhseShptLineBuf.Insert();
            end;
        end;
    end;

    local procedure PostWhseJnlLine(var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var TempHandlingSpecification: Record "Tracking Specification")
    var
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(PostedWhseShptLine, TempHandlingSpecification, IsHandled);
        if IsHandled then
            exit;

        GetLocation(PostedWhseShptLine."Location Code");
        if Location."Bin Mandatory" then begin
            CreateWhseJnlLine(TempWhseJnlLine, PostedWhseShptLine);
            WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 0, 0, false);
            OnBeforeRegisterWhseJnlLines(TempWhseJnlLine, PostedWhseShptLine);
            ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, false);
            if TempWhseJnlLine2.Find('-') then
                repeat
                    WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                until TempWhseJnlLine2.Next = 0;
        end;
    end;

    local procedure CreateWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        with PostedWhseShptLine do begin
            WhseJnlLine.Init();
            WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
            WhseJnlLine."Location Code" := "Location Code";
            WhseJnlLine."From Zone Code" := "Zone Code";
            WhseJnlLine."From Bin Code" := "Bin Code";
            WhseJnlLine."Item No." := "Item No.";
            WhseJnlLine.Description := Description;
            WhseJnlLine."Qty. (Absolute)" := Quantity;
            WhseJnlLine."Qty. (Absolute, Base)" := "Qty. (Base)";
            WhseJnlLine."User ID" := UserId;
            WhseJnlLine."Variant Code" := "Variant Code";
            WhseJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            WhseJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            WhseJnlLine.SetSource("Source Type", "Source Subtype", "Source No.", "Source Line No.", 0);
            WhseJnlLine."Source Document" := "Source Document";
            WhseJnlLine.SetWhseDoc(WhseJnlLine."Whse. Document Type"::Shipment, "No.", "Line No.");
            GetItemUnitOfMeasure2("Item No.", "Unit of Measure Code");
            WhseJnlLine.Cubage := WhseJnlLine."Qty. (Absolute)" * ItemUnitOfMeasure.Cubage;
            WhseJnlLine.Weight := WhseJnlLine."Qty. (Absolute)" * ItemUnitOfMeasure.Weight;
            WhseJnlLine."Reference No." := LastShptNo;
            WhseJnlLine."Registering Date" := PostingDate;
            WhseJnlLine."Registering No. Series" := WhseShptHeader."Shipping No. Series";
            SourceCodeSetup.Get();
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
                "Source Document"::"Service Order":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup."Service Management";
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
            Location.Init
        else
            if LocationCode <> Location.Code then
                Location.Get(LocationCode);
    end;

    local procedure CheckItemTrkgPicked(WhseShptLine: Record "Warehouse Shipment Line")
    var
        ReservationEntry: Record "Reservation Entry";
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        QtyPickedBase: Decimal;
    begin
        if WhseShptLine."Assemble to Order" then
            exit;
        if not ItemTrackingMgt.GetWhseItemTrkgSetup(WhseShptLine."Item No.") then
            exit;

        ReservationEntry.SetSourceFilter(
          WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.", WhseShptLine."Source Line No.", true);
        if ReservationEntry.Find('-') then
            repeat
                if ReservationEntry.TrackingExists then begin
                    QtyPickedBase := 0;
                    WhseItemTrkgLine.SetCurrentKey("Serial No.", "Lot No.");
                    WhseItemTrkgLine.SetTrackingFilterFromReservEntry(ReservationEntry);
                    WhseItemTrkgLine.SetSourceFilter(DATABASE::"Warehouse Shipment Line", -1, WhseShptLine."No.", WhseShptLine."Line No.", false);
                    if WhseItemTrkgLine.Find('-') then
                        repeat
                            QtyPickedBase := QtyPickedBase + WhseItemTrkgLine."Qty. Registered (Base)";
                        until WhseItemTrkgLine.Next = 0;
                    if QtyPickedBase < Abs(ReservationEntry."Qty. to Handle (Base)") then
                        Error(Text006,
                          WhseShptLine."No.", WhseShptLine.FieldCaption("Line No."), WhseShptLine."Line No.");
                end;
            until ReservationEntry.Next = 0;
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
    begin
        with WhseShptLine do begin
            SalesLine.SetRange("Document Type", "Source Subtype");
            SalesLine.SetRange("Document No.", "Source No.");
            if SalesLine.Find('-') then
                repeat
                    SetRange("Source Line No.", SalesLine."Line No.");
                    if Find('-') then begin
                        OnAfterFindWhseShptLineForSalesLine(WhseShptLine, SalesLine);
                        if "Source Document" = "Source Document"::"Sales Order" then begin
                            SumOfQtyToShip := 0;
                            SumOfQtyToShipBase := 0;
                            GetATOAndNonATOLines(ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound);
                            if ATOLineFound then begin
                                SumOfQtyToShip += ATOWhseShptLine."Qty. to Ship";
                                SumOfQtyToShipBase += ATOWhseShptLine."Qty. to Ship (Base)";
                            end;
                            if NonATOLineFound then begin
                                SumOfQtyToShip += NonATOWhseShptLine."Qty. to Ship";
                                SumOfQtyToShipBase += NonATOWhseShptLine."Qty. to Ship (Base)";
                            end;

                            ModifyLine := SalesLine."Qty. to Ship" <> SumOfQtyToShip;
                            if ModifyLine then begin
                                SalesLine.Validate("Qty. to Ship", SumOfQtyToShip);
                                SalesLine."Qty. to Ship (Base)" := SumOfQtyToShipBase;
                                if ATOLineFound then
                                    ATOLink.UpdateQtyToAsmFromWhseShptLine(ATOWhseShptLine);
                                if Invoice then
                                    SalesLine.Validate(
                                      "Qty. to Invoice",
                                      SalesLine."Qty. to Ship" + SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced");
                            end;
                        end else begin
                            ModifyLine := SalesLine."Return Qty. to Receive" <> -"Qty. to Ship";
                            if ModifyLine then begin
                                SalesLine.Validate("Return Qty. to Receive", -"Qty. to Ship");
                                if Invoice then
                                    SalesLine.Validate(
                                      "Qty. to Invoice",
                                      -"Qty. to Ship" + SalesLine."Return Qty. Received" - SalesLine."Quantity Invoiced");
                            end;
                        end;
                        if (WhseShptHeader."Shipment Date" <> 0D) and
                           (SalesLine."Shipment Date" <> WhseShptHeader."Shipment Date") and
                           ("Qty. to Ship" = "Qty. Outstanding")
                        then begin
                            SalesLine."Shipment Date" := WhseShptHeader."Shipment Date";
                            ModifyLine := true;
                            if ATOLineFound then
                                if AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No.") then begin
                                    AsmHeader."Due Date" := WhseShptHeader."Shipment Date";
                                    AsmHeader.Modify(true);
                                end;
                        end;
                        if SalesLine."Bin Code" <> "Bin Code" then begin
                            SalesLine."Bin Code" := "Bin Code";
                            ModifyLine := true;
                            if ATOLineFound then
                                ATOLink.UpdateAsmBinCodeFromWhseShptLine(ATOWhseShptLine);
                        end;
                    end else begin
                        ModifyLine :=
                          ((SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Partial) or
                           (SalesLine.Type = SalesLine.Type::Item)) and
                          ((SalesLine."Qty. to Ship" <> 0) or
                           (SalesLine."Return Qty. to Receive" <> 0) or
                           (SalesLine."Qty. to Invoice" <> 0));

                        if ModifyLine then begin
                            if "Source Document" = "Source Document"::"Sales Order" then
                                SalesLine.Validate("Qty. to Ship", 0)
                            else
                                SalesLine.Validate("Return Qty. to Receive", 0);
                            SalesLine.Validate("Qty. to Invoice", 0);
                        end;
                    end;
                    OnBeforeSalesLineModify(SalesLine, WhseShptLine, ModifyLine, Invoice);
                    if ModifyLine then
                        SalesLine.Modify();
                until SalesLine.Next = 0;
        end;
    end;

    local procedure HandlePurchaseLine(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        PurchLine: Record "Purchase Line";
        ModifyLine: Boolean;
    begin
        with WhseShptLine do begin
            PurchLine.SetRange("Document Type", "Source Subtype");
            PurchLine.SetRange("Document No.", "Source No.");
            if PurchLine.Find('-') then
                repeat
                    SetRange("Source Line No.", PurchLine."Line No.");
                    if Find('-') then begin
                        OnAfterFindWhseShptLineForPurchLine(WhseShptLine, PurchLine);
                        if "Source Document" = "Source Document"::"Purchase Order" then begin
                            ModifyLine := PurchLine."Qty. to Receive" <> -"Qty. to Ship";
                            if ModifyLine then begin
                                PurchLine.Validate("Qty. to Receive", -"Qty. to Ship");
                                if Invoice then
                                    PurchLine.Validate(
                                      "Qty. to Invoice",
                                      -"Qty. to Ship" + PurchLine."Quantity Received" - PurchLine."Quantity Invoiced");
                            end;
                        end else begin
                            ModifyLine := PurchLine."Return Qty. to Ship" <> "Qty. to Ship";
                            if ModifyLine then begin
                                PurchLine.Validate("Return Qty. to Ship", "Qty. to Ship");
                                if Invoice then
                                    PurchLine.Validate(
                                      "Qty. to Invoice",
                                      "Qty. to Ship" + PurchLine."Return Qty. Shipped" - PurchLine."Quantity Invoiced");
                            end;
                        end;
                        if (WhseShptHeader."Shipment Date" <> 0D) and
                           (PurchLine."Expected Receipt Date" <> WhseShptHeader."Shipment Date") and
                           ("Qty. to Ship" = "Qty. Outstanding")
                        then begin
                            PurchLine."Expected Receipt Date" := WhseShptHeader."Shipment Date";
                            ModifyLine := true;
                        end;
                        if PurchLine."Bin Code" <> "Bin Code" then begin
                            PurchLine."Bin Code" := "Bin Code";
                            ModifyLine := true;
                        end;
                    end else begin
                        ModifyLine :=
                          (PurchLine."Qty. to Receive" <> 0) or
                          (PurchLine."Return Qty. to Ship" <> 0) or
                          (PurchLine."Qty. to Invoice" <> 0);
                        if ModifyLine then begin
                            if "Source Document" = "Source Document"::"Purchase Order" then
                                PurchLine.Validate("Qty. to Receive", 0)
                            else
                                PurchLine.Validate("Return Qty. to Ship", 0);
                            PurchLine.Validate("Qty. to Invoice", 0);
                        end;
                    end;
                    OnBeforePurchLineModify(PurchLine, WhseShptLine, ModifyLine, Invoice);
                    if ModifyLine then
                        PurchLine.Modify();
                until PurchLine.Next = 0;
        end;
    end;

    local procedure HandleTransferLine(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        TransLine: Record "Transfer Line";
        ModifyLine: Boolean;
    begin
        with WhseShptLine do begin
            TransLine.SetRange("Document No.", "Source No.");
            TransLine.SetRange("Derived From Line No.", 0);
            if TransLine.Find('-') then
                repeat
                    SetRange("Source Line No.", TransLine."Line No.");
                    if Find('-') then begin
                        OnAfterFindWhseShptLineForTransLine(WhseShptLine, TransLine);
                        ModifyLine := TransLine."Qty. to Ship" <> "Qty. to Ship";
                        if ModifyLine then
                            TransLine.Validate("Qty. to Ship", "Qty. to Ship");
                        if (WhseShptHeader."Shipment Date" <> 0D) and
                           (TransLine."Shipment Date" <> WhseShptHeader."Shipment Date") and
                           ("Qty. to Ship" = "Qty. Outstanding")
                        then begin
                            TransLine."Shipment Date" := WhseShptHeader."Shipment Date";
                            ModifyLine := true;
                        end;
                        if TransLine."Transfer-from Bin Code" <> "Bin Code" then begin
                            TransLine."Transfer-from Bin Code" := "Bin Code";
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
                until TransLine.Next = 0;
        end;
    end;

    local procedure HandleServiceLine(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        ServLine: Record "Service Line";
        ModifyLine: Boolean;
    begin
        with WhseShptLine do begin
            ServLine.SetRange("Document Type", "Source Subtype");
            ServLine.SetRange("Document No.", "Source No.");
            if ServLine.Find('-') then
                repeat
                    SetRange("Source Line No.", ServLine."Line No.");  // Whse Shipment Line
                    if Find('-') then begin   // Whse Shipment Line
                        if "Source Document" = "Source Document"::"Service Order" then begin
                            ModifyLine := ServLine."Qty. to Ship" <> "Qty. to Ship";
                            if ModifyLine then begin
                                ServLine.Validate("Qty. to Ship", "Qty. to Ship");
                                ServLine."Qty. to Ship (Base)" := "Qty. to Ship (Base)";
                                if InvoiceService then begin
                                    ServLine.Validate("Qty. to Consume", 0);
                                    ServLine.Validate(
                                      "Qty. to Invoice",
                                      "Qty. to Ship" + ServLine."Quantity Shipped" - ServLine."Quantity Invoiced" -
                                      ServLine."Quantity Consumed");
                                end;
                            end;
                        end;
                        if ServLine."Bin Code" <> "Bin Code" then begin
                            ServLine."Bin Code" := "Bin Code";
                            ModifyLine := true;
                        end;
                    end else begin
                        ModifyLine :=
                          ((ServiceHeader."Shipping Advice" = ServiceHeader."Shipping Advice"::Partial) or
                           (ServLine.Type = ServLine.Type::Item)) and
                          ((ServLine."Qty. to Ship" <> 0) or
                           (ServLine."Qty. to Consume" <> 0) or
                           (ServLine."Qty. to Invoice" <> 0));

                        if ModifyLine then begin
                            if "Source Document" = "Source Document"::"Service Order" then
                                ServLine.Validate("Qty. to Ship", 0);
                            ServLine.Validate("Qty. to Invoice", 0);
                            ServLine.Validate("Qty. to Consume", 0);
                        end;
                    end;
                    if ModifyLine then
                        ServLine.Modify();
                until ServLine.Next = 0;
        end;
    end;

    procedure SetWhseJnlRegisterCU(var NewWhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        WhseJnlRegisterLine := NewWhseJnlRegisterLine;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseShptLines(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; Invoice: Boolean; SuppressCommit: Boolean)
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
    local procedure OnAfterFindWhseShptLineForTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var TransferLine: Record "Transfer Line")
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
    local procedure OnAfterPostWhseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseShptHeaderInsert(PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; LastShptNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateWhseShptLineModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
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
    local procedure OnAfterPurchPost(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PurchaseHeader: Record "Purchase Header"; Invoice: Boolean)
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
    local procedure OnAfterTransferPostShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ModifyLine: Boolean; Invoice: Boolean)
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
    local procedure OnPostSourceDocument(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var CounterDocOK: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteUpdateWhseShptLine(WhseShptLine: Record "Warehouse Shipment Line"; var DeleteWhseShptLine: Boolean)
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
    local procedure OnBeforeCheckWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSourceDocument(var WhseShptLine: Record "Warehouse Shipment Line"; var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var TransferHeader: Record "Transfer Header"; var ServiceHeader: Record "Service Header")
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
    local procedure OnBeforeRegisterWhseJnlLines(var TempWhseJnlLine: Record "Warehouse Journal Line"; var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedShptLineOnBeforePostWhseJnlLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeReopenSalesHeader(var SalesHeader: Record "Sales Header"; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSourceDocumentHeaderOnBeforeValidatePostingDate(var SalesHeader: Record "Sales Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ValidatePostingDate: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesInvoice(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintSalesShipment(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintPurchReturnShipment(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSourceDocumentOnBeforePrintTransferShipment(var Transfer: Record "Transfer Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrentKeyForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilterForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSourceForFilterWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line");
    begin
    end;
}

