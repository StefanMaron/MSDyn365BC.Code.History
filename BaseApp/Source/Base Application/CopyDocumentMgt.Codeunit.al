codeunit 6620 "Copy Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Please enter a Document No.';
        Text001: Label '%1 %2 cannot be copied onto itself.';
        DeleteLinesQst: Label 'The existing lines for %1 %2 will be deleted.\\Do you want to continue?', Comment = '%1=Document type, e.g. Invoice. %2=Document No., e.g. 001';
        Text006: Label 'NOTE: A Payment Discount was Granted by %1 %2.';
        Text007: Label 'Quote,Blanket Order,Order,Invoice,Credit Memo,Posted Shipment,Posted Invoice,Posted Credit Memo,Posted Return Receipt';
        Currency: Record Currency;
        Item: Record Item;
        AsmHeader: Record "Assembly Header";
        PostedAsmHeader: Record "Posted Assembly Header";
        TempAsmHeader: Record "Assembly Header" temporary;
        TempAsmLine: Record "Assembly Line" temporary;
        TempSalesInvLine: Record "Sales Invoice Line" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        GLSetup: Record "General Ledger Setup";
        TranslationHelper: Codeunit "Translation Helper";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        DeferralUtilities: Codeunit "Deferral Utilities";
        UOMMgt: Codeunit "Unit of Measure Management";
        ErrorMessageMgt: Codeunit "Error Message Management";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        InsertCancellationLine: Boolean;
        SalesDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo","Arch. Quote","Arch. Order","Arch. Blanket Order","Arch. Return Order";
        PurchDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo","Arch. Quote","Arch. Order","Arch. Blanket Order","Arch. Return Order";
        ServDocType: Option Quote,Contract;
        QtyToAsmToOrder: Decimal;
        QtyToAsmToOrderBase: Decimal;
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        MoveNegLines: Boolean;
        Text008: Label 'There are no negative sales lines to move.';
        Text009: Label 'NOTE: A Payment Discount was Received by %1 %2.';
        Text010: Label 'There are no negative purchase lines to move.';
        CreateToHeader: Boolean;
        Text011: Label 'Please enter a Vendor No.';
        HideDialog: Boolean;
        Text012: Label 'There are no sales lines to copy.';
        Text013: Label 'Shipment No.,Invoice No.,Return Receipt No.,Credit Memo No.';
        Text014: Label 'Receipt No.,Invoice No.,Return Shipment No.,Credit Memo No.';
        Text015: Label '%1 %2:';
        Text016: Label 'Inv. No. ,Shpt. No. ,Cr. Memo No. ,Rtrn. Rcpt. No. ';
        Text017: Label 'Inv. No. ,Rcpt. No. ,Cr. Memo No. ,Rtrn. Shpt. No. ';
        Text018: Label '%1 - %2:';
        Text019: Label 'Exact Cost Reversing Link has not been created for all copied document lines.';
        Text022: Label 'Copying document lines...\';
        Text023: Label 'Processing source lines      #1######\';
        Text024: Label 'Creating new lines           #2######';
        ExactCostRevMandatory: Boolean;
        ApplyFully: Boolean;
        AskApply: Boolean;
        ReappDone: Boolean;
        Text025: Label 'For one or more return document lines, you chose to return the original quantity, which is already fully applied. Therefore, when you post the return document, the program will reapply relevant entries. Beware that this may change the cost of existing entries. To avoid this, you must delete the affected return document lines before posting.';
        SkippedLine: Boolean;
        Text029: Label 'One or more return document lines were not inserted or they contain only the remaining quantity of the original document line. This is because quantities on the posted document line are already fully or partially applied. If you want to reverse the full quantity, you must select Return Original Quantity before getting the posted document lines.';
        Text030: Label 'One or more return document lines were not copied. This is because quantities on the posted document line are already fully or partially applied, so the Exact Cost Reversing link could not be created.';
        Text031: Label 'Return document line contains only the original document line quantity, that is not already manually applied.';
        SomeAreFixed: Boolean;
        AsmHdrExistsForFromDocLine: Boolean;
        Text032: Label 'The posted sales invoice %1 covers more than one shipment of linked assembly orders that potentially have different assembly components. Select Posted Shipment as document type, and then select a specific shipment of assembled items.';
        FromDocOccurrenceNo: Integer;
        FromDocVersionNo: Integer;
        SkipCopyFromDescription: Boolean;
        SkipTestCreditLimit: Boolean;
        WarningDone: Boolean;
        DiffPostDateOrderQst: Label 'The Posting Date of the copied document is different from the Posting Date of the original document. The original document already has a Posting No. based on a number series with date order. When you post the copied document, you may have the wrong date order in the posted documents.\Do you want to continue?';
        CopyPostedDeferral: Boolean;
        CrMemoCancellationMsg: Label 'Cancellation of credit memo %1.', Comment = '%1 = Document No.';
        CopyExtText: Boolean;
        CopyJobData: Boolean;
        SkipWarningNotification: Boolean;
        IsBlockedErr: Label '%1 %2 is blocked.', Comment = '%1 - type of entity, e.g. Item; %2 - entity''s No.';
        IsSalesBlockedItemErr: Label 'You cannot sell item %1 because the Sales Blocked check box is selected on the item card.', Comment = '%1 - Item No.';
        IsPurchBlockedItemErr: Label 'You cannot purchase item %1 because the Purchasing Blocked check box is selected on the item card.', Comment = '%1 - Item No.';
        FAIsInactiveErr: Label 'Fixed asset %1 is inactive.', Comment = '%1 - fixed asset no.';
        DirectPostingErr: Label 'G/L account %1 does not allow direct posting.', Comment = '%1 - g/l account no.';
        SalesErrorContextMsg: Label 'Copying sales document %1', Comment = '%1 - document no.';
        PurchErrorContextMsg: Label 'Copying purchase document %1', Comment = '%1 - document no.';

    procedure SetProperties(NewIncludeHeader: Boolean; NewRecalculateLines: Boolean; NewMoveNegLines: Boolean; NewCreateToHeader: Boolean; NewHideDialog: Boolean; NewExactCostRevMandatory: Boolean; NewApplyFully: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalculateLines;
        MoveNegLines := NewMoveNegLines;
        CreateToHeader := NewCreateToHeader;
        HideDialog := NewHideDialog;
        ExactCostRevMandatory := NewExactCostRevMandatory;
        ApplyFully := NewApplyFully;
        AskApply := false;
        ReappDone := false;
        SkippedLine := false;
        SomeAreFixed := false;
        SkipCopyFromDescription := false;
        SkipTestCreditLimit := false;
    end;

    procedure SetPropertiesForCreditMemoCorrection()
    begin
        SetProperties(true, false, false, false, true, true, false);
    end;

    procedure SetPropertiesForInvoiceCorrection(NewSkipCopyFromDescription: Boolean)
    begin
        SetProperties(true, false, false, false, true, false, false);
        SkipTestCreditLimit := true;
        SkipCopyFromDescription := NewSkipCopyFromDescription;
    end;

    procedure SalesHeaderDocType(DocType: Option): Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        case DocType of
            SalesDocType::Quote:
                exit(SalesHeader."Document Type"::Quote);
            SalesDocType::"Blanket Order":
                exit(SalesHeader."Document Type"::"Blanket Order");
            SalesDocType::Order:
                exit(SalesHeader."Document Type"::Order);
            SalesDocType::Invoice:
                exit(SalesHeader."Document Type"::Invoice);
            SalesDocType::"Return Order":
                exit(SalesHeader."Document Type"::"Return Order");
            SalesDocType::"Credit Memo":
                exit(SalesHeader."Document Type"::"Credit Memo");
        end;
    end;

    procedure PurchHeaderDocType(DocType: Option): Integer
    var
        FromPurchHeader: Record "Purchase Header";
    begin
        case DocType of
            PurchDocType::Quote:
                exit(FromPurchHeader."Document Type"::Quote);
            PurchDocType::"Blanket Order":
                exit(FromPurchHeader."Document Type"::"Blanket Order");
            PurchDocType::Order:
                exit(FromPurchHeader."Document Type"::Order);
            PurchDocType::Invoice:
                exit(FromPurchHeader."Document Type"::Invoice);
            PurchDocType::"Return Order":
                exit(FromPurchHeader."Document Type"::"Return Order");
            PurchDocType::"Credit Memo":
                exit(FromPurchHeader."Document Type"::"Credit Memo");
        end;
    end;

    procedure CopySalesDocForInvoiceCancelling(FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
        CopyJobData := true;
        SkipWarningNotification := true;
        OnBeforeCopySalesDocForInvoiceCancelling(ToSalesHeader, FromDocNo);

        CopySalesDoc(SalesDocType::"Posted Invoice", FromDocNo, ToSalesHeader);
    end;

    procedure CopySalesDocForCrMemoCancelling(FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
        SkipWarningNotification := true;
        InsertCancellationLine := true;
        OnBeforeCopySalesDocForCrMemoCancelling(ToSalesHeader, FromDocNo, CopyJobData);

        CopySalesDoc(SalesDocType::"Posted Credit Memo", FromDocNo, ToSalesHeader);
        InsertCancellationLine := false;
    end;

    procedure CopySalesDoc(FromDocType: Option; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    var
        ToSalesLine: Record "Sales Line";
        OldSalesHeader: Record "Sales Header";
        FromSalesHeader: Record "Sales Header";
        FromSalesShptHeader: Record "Sales Shipment Header";
        FromSalesInvHeader: Record "Sales Invoice Header";
        FromReturnRcptHeader: Record "Return Receipt Header";
        FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FromSalesHeaderArchive: Record "Sales Header Archive";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        ConfirmManagement: Codeunit "Confirm Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
        ReleaseDocument: Boolean;
        IsHandled: Boolean;
    begin
        with ToSalesHeader do begin
            if not CreateToHeader then begin
                TestField(Status, Status::Open);
                if FromDocNo = '' then
                    Error(Text000);
                Find;
            end;

            OnBeforeCopySalesDocument(FromDocType, FromDocNo, ToSalesHeader);

            TransferOldExtLines.ClearLineNumbers;

            if not InitAndCheckSalesDocuments(
                 FromDocType, FromDocNo, FromSalesHeader, ToSalesHeader, ToSalesLine,
                 FromSalesShptHeader, FromSalesInvHeader, FromReturnRcptHeader, FromSalesCrMemoHeader,
                 FromSalesHeaderArchive)
            then
                exit;

            ToSalesLine.LockTable();

            ToSalesLine.SetRange("Document Type", "Document Type");
            if CreateToHeader then begin
                OnCopySalesDocOnBeforeToSalesHeaderInsert(ToSalesHeader, FromSalesHeader, MoveNegLines);
                Insert(true);
                ToSalesLine.SetRange("Document No.", "No.");
            end else begin
                ToSalesLine.SetRange("Document No.", "No.");
                if IncludeHeader then
                    if not ToSalesLine.IsEmpty then begin
                        Commit();
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(DeleteLinesQst, "Document Type", "No."), true)
                        then
                            exit;
                        ToSalesLine.DeleteAll(true);
                    end;
            end;

            if ToSalesLine.FindLast then
                NextLineNo := ToSalesLine."Line No."
            else
                NextLineNo := 0;

            if IncludeHeader then
                CopySalesDocUpdateHeader(
                    FromDocType, FromDocNo, ToSalesHeader, FromSalesHeader,
                    FromSalesShptHeader, FromSalesInvHeader, FromReturnRcptHeader, FromSalesCrMemoHeader, FromSalesHeaderArchive, ReleaseDocument)
            else
                OnCopySalesDocWithoutHeader(ToSalesHeader, FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo);

            LinesNotCopied := 0;
            ErrorMessageMgt.Activate(ErrorMessageHandler);
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, StrSubstNo(SalesErrorContextMsg, FromDocNo));

            IsHandled := false;
            OnCopySalesDocOnBeforeCopyLines(FromSalesHeader, ToSalesHeader, IsHandled);
            if not IsHandled then
                case FromDocType of
                    SalesDocType::Quote,
                    SalesDocType::"Blanket Order",
                    SalesDocType::Order,
                    SalesDocType::Invoice,
                    SalesDocType::"Return Order",
                    SalesDocType::"Credit Memo":
                        CopySalesDocSalesLine(FromSalesHeader, ToSalesHeader, LinesNotCopied, NextLineNo);
                    SalesDocType::"Posted Shipment":
                        begin
                            FromSalesHeader.TransferFields(FromSalesShptHeader);
                            OnCopySalesDocOnBeforeCopySalesDocShptLine(FromSalesShptHeader, ToSalesHeader);
                            CopySalesDocShptLine(FromSalesShptHeader, ToSalesHeader, LinesNotCopied, MissingExCostRevLink);
                        end;
                    SalesDocType::"Posted Invoice":
                        begin
                            FromSalesHeader.TransferFields(FromSalesInvHeader);
                            OnCopySalesDocOnBeforeCopySalesDocInvLine(FromSalesInvHeader, ToSalesHeader);
                            CopySalesDocInvLine(FromSalesInvHeader, ToSalesHeader, LinesNotCopied, MissingExCostRevLink);
                        end;
                    SalesDocType::"Posted Return Receipt":
                        begin
                            FromSalesHeader.TransferFields(FromReturnRcptHeader);
                            OnCopySalesDocOnBeforeCopySalesDocReturnRcptLine(FromReturnRcptHeader, ToSalesHeader);
                            CopySalesDocReturnRcptLine(FromReturnRcptHeader, ToSalesHeader, LinesNotCopied, MissingExCostRevLink);
                        end;
                    SalesDocType::"Posted Credit Memo":
                        begin
                            FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                            OnCopySalesDocOnBeforeCopySalesDocCrMemoLine(FromSalesCrMemoHeader, ToSalesHeader);
                            CopySalesDocCrMemoLine(FromSalesCrMemoHeader, ToSalesHeader, LinesNotCopied, MissingExCostRevLink);
                        end;
                    SalesDocType::"Arch. Quote",
                    SalesDocType::"Arch. Order",
                    SalesDocType::"Arch. Blanket Order",
                    SalesDocType::"Arch. Return Order":
                        CopySalesDocSalesLineArchive(FromSalesHeaderArchive, ToSalesHeader, LinesNotCopied, NextLineNo);
                end;
        end;

        OnCopySalesDocOnBeforeUpdateSalesInvoiceDiscountValue(
          ToSalesHeader, FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines);

        UpdateSalesInvoiceDiscountValue(ToSalesHeader);

        if MoveNegLines then begin
            OnBeforeDeleteNegSalesLines(FromDocType, FromDocNo, ToSalesHeader);
            DeleteSalesLinesWithNegQty(FromSalesHeader, false);
            LinkJobPlanningLine(ToSalesHeader);
        end;

        OnCopySalesDocOnAfterCopySalesDocLines(
          FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, FromSalesHeader, IncludeHeader, ToSalesHeader);

        if ReleaseDocument then begin
            ToSalesHeader.Status := ToSalesHeader.Status::Released;
            ReleaseSalesDocument.Reopen(ToSalesHeader);
        end else
            if (FromDocType in
                [SalesDocType::Quote,
                 SalesDocType::"Blanket Order",
                 SalesDocType::Order,
                 SalesDocType::Invoice,
                 SalesDocType::"Return Order",
                 SalesDocType::"Credit Memo"])
               and not IncludeHeader and not RecalculateLines
            then
                if FromSalesHeader.Status = FromSalesHeader.Status::Released then begin
                    ReleaseSalesDocument.Run(ToSalesHeader);
                    ReleaseSalesDocument.Reopen(ToSalesHeader);
                end;

        if ShowWarningNotification(ToSalesHeader, MissingExCostRevLink) then
            ErrorMessageHandler.NotifyAboutErrors;

        OnAfterCopySalesDocument(
          FromDocType, FromDocNo, ToSalesHeader, FromDocOccurrenceNo, FromDocVersionNo, IncludeHeader, RecalculateLines, MoveNegLines);
    end;

    local procedure CopySalesDocSalesLine(FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToSalesLine: Record "Sales Line";
        FromSalesLine: Record "Sales Line";
        ItemChargeAssgntNextLineNo: Integer;
    begin
        ItemChargeAssgntNextLineNo := 0;

        with ToSalesHeader do begin
            FromSalesLine.Reset();
            FromSalesLine.SetRange("Document Type", FromSalesHeader."Document Type");
            FromSalesLine.SetRange("Document No.", FromSalesHeader."No.");
            if MoveNegLines then
                FromSalesLine.SetFilter(Quantity, '<=0');
            OnCopySalesDocSalesLineOnAfterSetFilters(FromSalesHeader, FromSalesLine, ToSalesHeader);
            if FromSalesLine.Find('-') then
                repeat
                    if not ExtTxtAttachedToPosSalesLine(FromSalesHeader, MoveNegLines, FromSalesLine."Attached to Line No.") then begin
                        InitAsmCopyHandling(true);
                        ToSalesLine."Document Type" := "Document Type";
                        AsmHdrExistsForFromDocLine := FromSalesLine.AsmToOrderExists(AsmHeader);
                        if AsmHdrExistsForFromDocLine then begin
                            case ToSalesLine."Document Type" of
                                ToSalesLine."Document Type"::Order:
                                    begin
                                        QtyToAsmToOrder := FromSalesLine."Qty. to Assemble to Order";
                                        QtyToAsmToOrderBase := FromSalesLine."Qty. to Asm. to Order (Base)";
                                    end;
                                ToSalesLine."Document Type"::Quote,
                                ToSalesLine."Document Type"::"Blanket Order":
                                    begin
                                        QtyToAsmToOrder := FromSalesLine.Quantity;
                                        QtyToAsmToOrderBase := FromSalesLine."Quantity (Base)";
                                    end;
                            end;
                            GenerateAsmDataFromNonPosted(AsmHeader);
                        end;
                        if CopySalesLine(
                             ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine,
                             NextLineNo, LinesNotCopied, false, DeferralTypeForSalesDoc(FromSalesHeader."Document Type"), CopyPostedDeferral,
                             FromSalesLine."Line No.")
                        then begin
                            if FromSalesLine.Type = FromSalesLine.Type::"Charge (Item)" then
                                CopyFromSalesDocAssgntToLine(
                                  ToSalesLine, FromSalesLine."Document Type", FromSalesLine."Document No.", FromSalesLine."Line No.",
                                  ItemChargeAssgntNextLineNo);
                            OnAfterCopySalesLineFromSalesDocSalesLine(
                              ToSalesHeader, ToSalesLine, FromSalesLine, IncludeHeader, RecalculateLines);
                        end;
                    end;
                until FromSalesLine.Next = 0;
        end;
    end;

    local procedure CopySalesDocShptLine(FromSalesShptHeader: Record "Sales Shipment Header"; ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromSalesShptLine: Record "Sales Shipment Line";
    begin
        with ToSalesHeader do begin
            FromSalesShptLine.Reset();
            FromSalesShptLine.SetRange("Document No.", FromSalesShptHeader."No.");
            if MoveNegLines then
                FromSalesShptLine.SetFilter(Quantity, '<=0');
            OnCopySalesDocShptLineOnAfterSetFilters(ToSalesHeader, FromSalesShptHeader, FromSalesShptLine);
            CopySalesShptLinesToDoc(ToSalesHeader, FromSalesShptLine, LinesNotCopied, MissingExCostRevLink);
        end;
    end;

    local procedure CopySalesDocInvLine(FromSalesInvHeader: Record "Sales Invoice Header"; ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromSalesInvLine: Record "Sales Invoice Line";
    begin
        with ToSalesHeader do begin
            FromSalesInvLine.Reset();
            FromSalesInvLine.SetRange("Document No.", FromSalesInvHeader."No.");
            if MoveNegLines then
                FromSalesInvLine.SetFilter(Quantity, '<=0');
            OnCopySalesDocInvLineOnAfterSetFilters(ToSalesHeader, FromSalesInvHeader, FromSalesInvLine);
            CopySalesInvLinesToDoc(ToSalesHeader, FromSalesInvLine, LinesNotCopied, MissingExCostRevLink);
        end;
    end;

    local procedure CopySalesDocCrMemoLine(FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        with ToSalesHeader do begin
            FromSalesCrMemoLine.Reset();
            FromSalesCrMemoLine.SetRange("Document No.", FromSalesCrMemoHeader."No.");
            if MoveNegLines then
                FromSalesCrMemoLine.SetFilter(Quantity, '<=0');
            OnCopySalesDocCrMemoLineOnAfterSetFilters(ToSalesHeader, FromSalesCrMemoHeader, FromSalesCrMemoLine);
            CopySalesCrMemoLinesToDoc(ToSalesHeader, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
        end;
    end;

    local procedure CopySalesDocReturnRcptLine(FromReturnRcptHeader: Record "Return Receipt Header"; ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromReturnRcptLine: Record "Return Receipt Line";
    begin
        with ToSalesHeader do begin
            FromReturnRcptLine.Reset();
            FromReturnRcptLine.SetRange("Document No.", FromReturnRcptHeader."No.");
            if MoveNegLines then
                FromReturnRcptLine.SetFilter(Quantity, '<=0');
            OnCopySalesDocReturnRcptLineOnAfterSetFilters(ToSalesHeader, FromReturnRcptHeader, FromReturnRcptLine);
            CopySalesReturnRcptLinesToDoc(ToSalesHeader, FromReturnRcptLine, LinesNotCopied, MissingExCostRevLink);
        end;
    end;

    local procedure CopySalesDocSalesLineArchive(FromSalesHeaderArchive: Record "Sales Header Archive"; var ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToSalesLine: Record "Sales Line";
        FromSalesLineArchive: Record "Sales Line Archive";
        ItemChargeAssgntNextLineNo: Integer;
    begin
        ItemChargeAssgntNextLineNo := 0;

        with ToSalesHeader do begin
            FromSalesLineArchive.Reset();
            FromSalesLineArchive.SetRange("Document Type", FromSalesHeaderArchive."Document Type");
            FromSalesLineArchive.SetRange("Document No.", FromSalesHeaderArchive."No.");
            FromSalesLineArchive.SetRange("Doc. No. Occurrence", FromSalesHeaderArchive."Doc. No. Occurrence");
            FromSalesLineArchive.SetRange("Version No.", FromSalesHeaderArchive."Version No.");
            if MoveNegLines then
                FromSalesLineArchive.SetFilter(Quantity, '<=0');
            OnCopySalesDocSalesLineArchiveOnAfterSetFilters(FromSalesHeaderArchive, FromSalesLineArchive, ToSalesHeader);
            if FromSalesLineArchive.Find('-') then
                repeat
                    if CopyArchSalesLine(
                         ToSalesHeader, ToSalesLine, FromSalesHeaderArchive, FromSalesLineArchive, NextLineNo, LinesNotCopied, false)
                    then begin
                        CopyFromArchSalesDocDimToLine(ToSalesLine, FromSalesLineArchive);
                        if FromSalesLineArchive.Type = FromSalesLineArchive.Type::"Charge (Item)" then
                            CopyFromSalesDocAssgntToLine(
                              ToSalesLine, FromSalesLineArchive."Document Type", FromSalesLineArchive."Document No.", FromSalesLineArchive."Line No.",
                              ItemChargeAssgntNextLineNo);
                        OnAfterCopyArchSalesLine(ToSalesHeader, ToSalesLine, FromSalesLineArchive, IncludeHeader, RecalculateLines);
                    end;
                until FromSalesLineArchive.Next = 0;
        end;
    end;

    local procedure CopySalesDocUpdateHeader(FromDocType: Option; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromSalesShptHeader: Record "Sales Shipment Header"; FromSalesInvHeader: Record "Sales Invoice Header"; FromReturnRcptHeader: Record "Return Receipt Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesHeaderArchive: Record "Sales Header Archive"; var ReleaseDocument: Boolean);
    var
        OldSalesHeader: Record "Sales Header";
    begin
        with ToSalesHeader do begin
            CheckCustomer(FromSalesHeader, ToSalesHeader);
            OldSalesHeader := ToSalesHeader;
            OnBeforeCopySalesHeaderDone(ToSalesHeader, FromSalesHeader);
            case FromDocType of
                SalesDocType::Quote,
                SalesDocType::"Blanket Order",
                SalesDocType::Order,
                SalesDocType::Invoice,
                SalesDocType::"Return Order",
                SalesDocType::"Credit Memo":
                    CopySalesHeaderFromSalesHeader(FromDocType, FromSalesHeader, OldSalesHeader, ToSalesHeader);
                SalesDocType::"Posted Shipment":
                    CopySalesHeaderFromPostedShipment(FromSalesShptHeader, ToSalesHeader, OldSalesHeader);
                SalesDocType::"Posted Invoice":
                    CopySalesHeaderFromPostedInvoice(FromSalesInvHeader, ToSalesHeader, OldSalesHeader);
                SalesDocType::"Posted Return Receipt":
                    CopySalesHeaderFromPostedReturnReceipt(FromReturnRcptHeader, ToSalesHeader, OldSalesHeader);
                SalesDocType::"Posted Credit Memo":
                    TransferFieldsFromCrMemoToInv(ToSalesHeader, FromSalesCrMemoHeader);
                SalesDocType::"Arch. Quote",
                SalesDocType::"Arch. Order",
                SalesDocType::"Arch. Blanket Order",
                SalesDocType::"Arch. Return Order":
                    CopySalesHeaderFromSalesHeaderArchive(FromSalesHeaderArchive, ToSalesHeader, OldSalesHeader);
            end;
            OnAfterCopySalesHeaderDone(
                ToSalesHeader, OldSalesHeader, FromSalesHeader, FromSalesShptHeader, FromSalesInvHeader,
                FromReturnRcptHeader, FromSalesCrMemoHeader, FromSalesHeaderArchive);

            Invoice := false;
            Ship := false;
            if Status = Status::Released then begin
                Status := Status::Open;
                ReleaseDocument := true;
            end;
            if MoveNegLines or IncludeHeader then
                Validate("Location Code");
            CopyShiptoCodeFromInvToCrMemo(ToSalesHeader, FromSalesInvHeader, FromDocType);
            CopyFieldsFromOldSalesHeader(ToSalesHeader, OldSalesHeader);
            OnAfterCopyFieldsFromOldSalesHeader(ToSalesHeader, OldSalesHeader, MoveNegLines, IncludeHeader);
            if RecalculateLines then
                CreateDim(
                    DATABASE::"Responsibility Center", "Responsibility Center",
                    DATABASE::Customer, "Bill-to Customer No.",
                    DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                    DATABASE::Campaign, "Campaign No.",
                    DATABASE::"Customer Template", "Bill-to Customer Template Code");
            "No. Printed" := 0;
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
            "Applies-to Doc. No." := '';
            "Applies-to ID" := '';
            "Opportunity No." := '';
            "Quote No." := '';
            OnCopySalesDocUpdateHeaderOnBeforeUpdateCustLedgerEntry(ToSalesHeader, FromDocType, FromDocNo);

            if ((FromDocType = SalesDocType::"Posted Invoice") and
                ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"])) or
                ((FromDocType = SalesDocType::"Posted Credit Memo") and
                not ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]))
            then
                UpdateCustLedgEntry(ToSalesHeader, FromDocType, FromDocNo);

            HandleZeroAmountPostedInvoices(FromSalesInvHeader, ToSalesHeader, FromDocType, FromDocNo);

            if "Document Type" in ["Document Type"::"Blanket Order", "Document Type"::Quote] then
                "Posting Date" := 0D;

            Correction := false;
            if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                UpdateSalesCreditMemoHeader(ToSalesHeader);

            OnBeforeModifySalesHeader(ToSalesHeader, FromDocType, FromDocNo, IncludeHeader, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines);

            if CreateToHeader then begin
                Validate("Payment Terms Code");
                Modify(true);
            end else
                Modify;
            OnCopySalesDocWithHeader(FromDocType, FromDocNo, ToSalesHeader, FromDocOccurrenceNo, FromDocVersionNo);
        end;
    end;

    local procedure CopySalesHeaderFromSalesHeader(FromDocType: Option; FromSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header")
    begin
        FromSalesHeader.CalcFields("Work Description");
        ToSalesHeader.TransferFields(FromSalesHeader, false);
        UpdateSalesHeaderWhenCopyFromSalesHeader(ToSalesHeader, OldSalesHeader, FromDocType);
        OnAfterCopySalesHeader(ToSalesHeader, OldSalesHeader, FromSalesHeader);
    end;

    local procedure CopySalesHeaderFromPostedShipment(FromSalesShptHeader: Record "Sales Shipment Header"; var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader.Validate("Sell-to Customer No.", FromSalesShptHeader."Sell-to Customer No.");
        OnCopySalesDocOnBeforeTransferPostedShipmentFields(ToSalesHeader, FromSalesShptHeader);
        ToSalesHeader.TransferFields(FromSalesShptHeader, false);
        OnAfterCopyPostedShipment(ToSalesHeader, OldSalesHeader, FromSalesShptHeader);
    end;

    local procedure CopySalesHeaderFromPostedInvoice(FromSalesInvHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        FromSalesInvHeader.CalcFields("Work Description");
        ToSalesHeader.Validate("Sell-to Customer No.", FromSalesInvHeader."Sell-to Customer No.");
        OnCopySalesDocOnBeforeTransferPostedInvoiceFields(ToSalesHeader, FromSalesInvHeader, CopyJobData);
        ToSalesHeader.TransferFields(FromSalesInvHeader, false);
        OnCopySalesDocOnAfterTransferPostedInvoiceFields(ToSalesHeader, FromSalesInvHeader, OldSalesHeader);
    end;

    local procedure CopySalesHeaderFromPostedReturnReceipt(FromReturnRcptHeader: Record "Return Receipt Header"; var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader.Validate("Sell-to Customer No.", FromReturnRcptHeader."Sell-to Customer No.");
        OnCopySalesDocOnBeforeTransferPostedReturnReceiptFields(ToSalesHeader, FromReturnRcptHeader);
        ToSalesHeader.TransferFields(FromReturnRcptHeader, false);
        OnAfterCopyPostedReturnReceipt(ToSalesHeader, OldSalesHeader, FromReturnRcptHeader);
    end;

    local procedure CopySalesHeaderFromSalesHeaderArchive(FromSalesHeaderArchive: Record "Sales Header Archive"; var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader.Validate("Sell-to Customer No.", FromSalesHeaderArchive."Sell-to Customer No.");
        ToSalesHeader.TransferFields(FromSalesHeaderArchive, false);
        OnCopySalesDocOnAfterTransferArchSalesHeaderFields(ToSalesHeader, FromSalesHeaderArchive);
        UpdateSalesHeaderWhenCopyFromSalesHeaderArchive(ToSalesHeader);
        CopyFromArchSalesDocDimToHdr(ToSalesHeader, FromSalesHeaderArchive);
        OnAfterCopySalesHeaderArchive(ToSalesHeader, OldSalesHeader, FromSalesHeaderArchive)
    end;

    procedure CheckCustomer(var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header")
    var
        Cust: Record Customer;
    begin
        if Cust.Get(FromSalesHeader."Sell-to Customer No.") then
            Cust.CheckBlockedCustOnDocs(Cust, ToSalesHeader."Document Type", false, false);
        if Cust.Get(FromSalesHeader."Bill-to Customer No.") then
            Cust.CheckBlockedCustOnDocs(Cust, ToSalesHeader."Document Type", false, false);
    end;

    local procedure CheckAsmHdrExistsForFromDocLine(ToSalesHeader: Record "Sales Header"; FromSalesLine2: Record "Sales Line"; var BufferCount: Integer; LineCountsEqual: Boolean)
    begin
        BufferCount += 1;
        AsmHdrExistsForFromDocLine := RetrieveSalesInvLine(FromSalesLine2, BufferCount, LineCountsEqual);
        InitAsmCopyHandling(true);
        if AsmHdrExistsForFromDocLine then begin
            AsmHdrExistsForFromDocLine := GetAsmDataFromSalesInvLine(ToSalesHeader."Document Type");
            if AsmHdrExistsForFromDocLine then begin
                QtyToAsmToOrder := TempSalesInvLine.Quantity;
                QtyToAsmToOrderBase := TempSalesInvLine.Quantity * TempSalesInvLine."Qty. per Unit of Measure";
            end;
        end;
    end;

    local procedure HandleZeroAmountPostedInvoices(var FromSalesInvHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20])
    begin
        // Apply credit memo to invoice in case of Sales Invoices with total amount 0
        FromSalesInvHeader.CalcFields(Amount);
        with ToSalesHeader do
            if ("Applies-to Doc. Type" = "Applies-to Doc. Type"::" ") and ("Applies-to Doc. No." = '') and
               (FromDocType = SalesDocType::"Posted Invoice") and (FromSalesInvHeader.Amount = 0)
            then begin
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
                "Applies-to Doc. No." := FromDocNo;
            end;
    end;

    procedure CopyPurchaseDocForInvoiceCancelling(FromDocNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
        SkipWarningNotification := true;
        OnBeforeCopyPurchaseDocForInvoiceCancelling(ToPurchaseHeader, FromDocNo);

        CopyPurchDoc(PurchDocType::"Posted Invoice", FromDocNo, ToPurchaseHeader);
    end;

    procedure CopyPurchDocForCrMemoCancelling(FromDocNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
        SkipWarningNotification := true;
        InsertCancellationLine := true;
        OnBeforeCopyPurchaseDocForCrMemoCancelling(ToPurchaseHeader, FromDocNo);

        CopyPurchDoc(SalesDocType::"Posted Credit Memo", FromDocNo, ToPurchaseHeader);
        InsertCancellationLine := false;
    end;

    procedure CopyPurchDoc(FromDocType: Option; FromDocNo: Code[20]; var ToPurchHeader: Record "Purchase Header")
    var
        ToPurchLine: Record "Purchase Line";
        OldPurchHeader: Record "Purchase Header";
        FromPurchHeader: Record "Purchase Header";
        FromPurchRcptHeader: Record "Purch. Rcpt. Header";
        FromPurchInvHeader: Record "Purch. Inv. Header";
        FromReturnShptHeader: Record "Return Shipment Header";
        FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        FromPurchHeaderArchive: Record "Purchase Header Archive";
        Vend: Record Vendor;
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        ConfirmManagement: Codeunit "Confirm Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
        ReleaseDocument: Boolean;
    begin
        with ToPurchHeader do begin
            if not CreateToHeader then begin
                TestField(Status, Status::Open);
                if FromDocNo = '' then
                    Error(Text000);
                Find;
            end;

            OnBeforeCopyPurchaseDocument(FromDocType, FromDocNo, ToPurchHeader);

            TransferOldExtLines.ClearLineNumbers;

            if not InitAndCheckPurchaseDocuments(
                 FromDocType, FromDocNo, FromPurchHeader, ToPurchHeader,
                 FromPurchRcptHeader, FromPurchInvHeader, FromReturnShptHeader, FromPurchCrMemoHeader,
                 FromPurchHeaderArchive)
            then
                exit;

            ToPurchLine.LockTable();

            if CreateToHeader then begin
                OnCopyPurchDocOnBeforeToPurchHeaderInsert(ToPurchHeader, FromPurchHeader, MoveNegLines);
                Insert(true);
                ToPurchLine.SetRange("Document Type", "Document Type");
                ToPurchLine.SetRange("Document No.", "No.");
            end else begin
                ToPurchLine.SetRange("Document Type", "Document Type");
                ToPurchLine.SetRange("Document No.", "No.");
                if IncludeHeader then
                    if ToPurchLine.FindFirst then begin
                        Commit();
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(DeleteLinesQst, "Document Type", "No."), true)
                        then
                            exit;
                        ToPurchLine.DeleteAll(true);
                    end;
            end;

            if ToPurchLine.FindLast then
                NextLineNo := ToPurchLine."Line No."
            else
                NextLineNo := 0;

            if IncludeHeader then begin
                CopyPurchDocUpdateHeader(
                    FromDocType, FromDocNo, ToPurchHeader, FromPurchHeader,
                    FromPurchRcptHeader, FromPurchInvHeader, FromReturnShptHeader, FromPurchCrMemoHeader, FromPurchHeaderArchive, ReleaseDocument)
            end else
                OnCopyPurchDocWithoutHeader(ToPurchHeader, FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo);

            LinesNotCopied := 0;
            ErrorMessageMgt.Activate(ErrorMessageHandler);
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, StrSubstNo(PurchErrorContextMsg, FromDocNo));
            case FromDocType of
                PurchDocType::Quote,
              PurchDocType::"Blanket Order",
              PurchDocType::Order,
              PurchDocType::Invoice,
              PurchDocType::"Return Order",
              PurchDocType::"Credit Memo":
                    CopyPurchDocPurchLine(FromPurchHeader, ToPurchHeader, LinesNotCopied, NextLineNo);
                PurchDocType::"Posted Receipt":
                    begin
                        FromPurchHeader.TransferFields(FromPurchRcptHeader);
                        OnCopyPurchDocOnBeforeCopyPurchDocRcptLine(FromPurchRcptHeader, ToPurchHeader);
                        CopyPurchDocRcptLine(FromPurchRcptHeader, ToPurchHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                PurchDocType::"Posted Invoice":
                    begin
                        FromPurchHeader.TransferFields(FromPurchInvHeader);
                        OnCopyPurchDocOnBeforeCopyPurchDocInvLine(FromPurchInvHeader, ToPurchHeader);
                        CopyPurchDocInvLine(FromPurchInvHeader, ToPurchHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                PurchDocType::"Posted Return Shipment":
                    begin
                        FromPurchHeader.TransferFields(FromReturnShptHeader);
                        OnCopyPurchDocOnBeforeCopyPurchDocReturnShptLine(FromReturnShptHeader, ToPurchHeader);
                        CopyPurchDocReturnShptLine(FromReturnShptHeader, ToPurchHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                PurchDocType::"Posted Credit Memo":
                    begin
                        FromPurchHeader.TransferFields(FromPurchCrMemoHeader);
                        OnCopyPurchDocOnBeforeCopyPurchDocCrMemoLine(FromPurchCrMemoHeader, ToPurchHeader);
                        CopyPurchDocCrMemoLine(FromPurchCrMemoHeader, ToPurchHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                PurchDocType::"Arch. Order",
              PurchDocType::"Arch. Quote",
              PurchDocType::"Arch. Blanket Order",
              PurchDocType::"Arch. Return Order":
                    CopyPurchDocPurchLineArchive(FromPurchHeaderArchive, ToPurchHeader, LinesNotCopied, NextLineNo);
            end;
        end;

        OnCopyPurchDocOnBeforeUpdatePurchInvoiceDiscountValue(
          ToPurchHeader, FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines);

        UpdatePurchaseInvoiceDiscountValue(ToPurchHeader);

        if MoveNegLines then
            DeletePurchLinesWithNegQty(FromPurchHeader, false);

        OnCopyPurchDocOnAfterCopyPurchDocLines(FromDocType, FromDocNo, FromPurchHeader, IncludeHeader, ToPurchHeader);

        if ReleaseDocument then begin
            ToPurchHeader.Status := ToPurchHeader.Status::Released;
            ReleasePurchaseDocument.Reopen(ToPurchHeader);
        end else
            if (FromDocType in
                [PurchDocType::Quote,
                 PurchDocType::"Blanket Order",
                 PurchDocType::Order,
                 PurchDocType::Invoice,
                 PurchDocType::"Return Order",
                 PurchDocType::"Credit Memo"])
               and not IncludeHeader and not RecalculateLines
            then
                if FromPurchHeader.Status = FromPurchHeader.Status::Released then begin
                    ReleasePurchaseDocument.Run(ToPurchHeader);
                    ReleasePurchaseDocument.Reopen(ToPurchHeader);
                end;

        if ShowWarningNotification(ToPurchHeader, MissingExCostRevLink) then
            ErrorMessageHandler.NotifyAboutErrors;

        OnAfterCopyPurchaseDocument(
          FromDocType, FromDocNo, ToPurchHeader, FromDocOccurrenceNo, FromDocVersionNo, IncludeHeader, RecalculateLines, MoveNegLines);
    end;

    local procedure CopyPurchDocPurchLine(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToPurchLine: Record "Purchase Line";
        FromPurchLine: Record "Purchase Line";
        ItemChargeAssgntNextLineNo: Integer;
    begin
        ItemChargeAssgntNextLineNo := 0;

        with ToPurchHeader do begin
            FromPurchLine.Reset();
            FromPurchLine.SetRange("Document Type", FromPurchHeader."Document Type");
            FromPurchLine.SetRange("Document No.", FromPurchHeader."No.");
            if MoveNegLines then
                FromPurchLine.SetFilter(Quantity, '<=0');
            OnCopyPurchDocPurchLineOnAfterSetFilters(FromPurchHeader, FromPurchLine, ToPurchHeader);
            if FromPurchLine.Find('-') then
                repeat
                    if not ExtTxtAttachedToPosPurchLine(FromPurchHeader, MoveNegLines, FromPurchLine."Attached to Line No.") then
                        if CopyPurchLine(
                             ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine,
                             NextLineNo, LinesNotCopied, false, DeferralTypeForPurchDoc(FromPurchHeader."Document Type"), CopyPostedDeferral,
                             FromPurchLine."Line No.")
                        then begin
                            if FromPurchLine.Type = FromPurchLine.Type::"Charge (Item)" then
                                CopyFromPurchDocAssgntToLine(
                                    ToPurchLine, FromPurchLine."Document Type", FromPurchLine."Document No.", FromPurchLine."Line No.",
                                    ItemChargeAssgntNextLineNo);
                            OnCopyPurchDocPurchLineOnAfterCopyPurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, IncludeHeader, RecalculateLines);
                        end;
                until FromPurchLine.Next = 0;
        end;
    end;

    local procedure CopyPurchDocRcptLine(FromPurchRcptHeader: Record "Purch. Rcpt. Header"; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        with ToPurchHeader do begin
            FromPurchRcptLine.Reset();
            FromPurchRcptLine.SetRange("Document No.", FromPurchRcptHeader."No.");
            if MoveNegLines then
                FromPurchRcptLine.SetFilter(Quantity, '<=0');
            OnCopyPurchDocRcptLineOnAfterSetFilters(ToPurchHeader, FromPurchRcptHeader, FromPurchRcptLine);
            CopyPurchRcptLinesToDoc(ToPurchHeader, FromPurchRcptLine, LinesNotCopied, MissingExCostRevLink);
        end;
    end;

    local procedure CopyPurchDocInvLine(FromPurchInvHeader: Record "Purch. Inv. Header"; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromPurchInvLine: Record "Purch. Inv. Line";
    begin
        with ToPurchHeader do begin
            FromPurchInvLine.Reset();
            FromPurchInvLine.SetRange("Document No.", FromPurchInvHeader."No.");
            if MoveNegLines then
                FromPurchInvLine.SetFilter(Quantity, '<=0');
            CopyPurchInvLinesToDoc(ToPurchHeader, FromPurchInvLine, LinesNotCopied, MissingExCostRevLink);
        end;
    end;

    local procedure CopyPurchDocCrMemoLine(FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        with ToPurchHeader do begin
            FromPurchCrMemoLine.Reset();
            FromPurchCrMemoLine.SetRange("Document No.", FromPurchCrMemoHeader."No.");
            if MoveNegLines then
                FromPurchCrMemoLine.SetFilter(Quantity, '<=0');
            CopyPurchCrMemoLinesToDoc(ToPurchHeader, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
        end;
    end;

    local procedure CopyPurchDocReturnShptLine(FromReturnShptHeader: Record "Return Shipment Header"; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromReturnShptLine: Record "Return Shipment Line";
    begin
        with ToPurchHeader do begin
            FromReturnShptLine.Reset();
            FromReturnShptLine.SetRange("Document No.", FromReturnShptHeader."No.");
            if MoveNegLines then
                FromReturnShptLine.SetFilter(Quantity, '<=0');
            CopyPurchReturnShptLinesToDoc(ToPurchHeader, FromReturnShptLine, LinesNotCopied, MissingExCostRevLink);
        end;
    end;

    local procedure CopyPurchDocPurchLineArchive(FromPurchHeaderArchive: Record "Purchase Header Archive"; var ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToPurchLine: Record "Purchase Line";
        FromPurchLineArchive: Record "Purchase Line Archive";
        ItemChargeAssgntNextLineNo: Integer;
    begin
        ItemChargeAssgntNextLineNo := 0;

        with ToPurchHeader do begin
            FromPurchLineArchive.Reset();
            FromPurchLineArchive.SetRange("Document Type", FromPurchHeaderArchive."Document Type");
            FromPurchLineArchive.SetRange("Document No.", FromPurchHeaderArchive."No.");
            FromPurchLineArchive.SetRange("Doc. No. Occurrence", FromPurchHeaderArchive."Doc. No. Occurrence");
            FromPurchLineArchive.SetRange("Version No.", FromPurchHeaderArchive."Version No.");
            if MoveNegLines then
                FromPurchLineArchive.SetFilter(Quantity, '<=0');
            if FromPurchLineArchive.Find('-') then
                repeat
                    if CopyArchPurchLine(
                         ToPurchHeader, ToPurchLine, FromPurchHeaderArchive, FromPurchLineArchive, NextLineNo, LinesNotCopied, false)
                    then begin
                        CopyFromArchPurchDocDimToLine(ToPurchLine, FromPurchLineArchive);
                        if FromPurchLineArchive.Type = FromPurchLineArchive.Type::"Charge (Item)" then
                            CopyFromPurchDocAssgntToLine(
                              ToPurchLine, FromPurchLineArchive."Document Type", FromPurchLineArchive."Document No.", FromPurchLineArchive."Line No.",
                              ItemChargeAssgntNextLineNo);
                        OnAfterCopyArchPurchLine(ToPurchHeader, ToPurchLine, FromPurchLineArchive, IncludeHeader, RecalculateLines);
                    end;
                until FromPurchLineArchive.Next = 0;
        end;
    end;

    local procedure CopyPurchDocUpdateHeader(FromDocType: Option; FromDocNo: Code[20]; var ToPurchHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header"; FromPurchRcptHeader: Record "Purch. Rcpt. Header"; FromPurchInvHeader: Record "Purch. Inv. Header"; FromReturnShptHeader: Record "Return Shipment Header"; FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; FromPurchHeaderArchive: Record "Purchase Header Archive"; var ReleaseDocument: Boolean)
    var
        Vend: Record Vendor;
        OldPurchHeader: Record "Purchase Header";
    begin
        with ToPurchHeader do begin
            if Vend.Get(FromPurchHeader."Buy-from Vendor No.") then
                Vend.CheckBlockedVendOnDocs(Vend, false);
            if Vend.Get(FromPurchHeader."Pay-to Vendor No.") then
                Vend.CheckBlockedVendOnDocs(Vend, false);
            OldPurchHeader := ToPurchHeader;
            OnBeforeCopyPurchHeaderDone(ToPurchHeader, FromPurchHeader);
            case FromDocType of
                PurchDocType::Quote,
                PurchDocType::"Blanket Order",
                PurchDocType::Order,
                PurchDocType::Invoice,
                PurchDocType::"Return Order",
                PurchDocType::"Credit Memo":
                    CopyPurchHeaderFromPurchHeader(FromDocType, FromPurchHeader, OldPurchHeader, ToPurchHeader);
                PurchDocType::"Posted Receipt":
                    CopyPurchHeaderFromPostedReceipt(FromPurchRcptHeader, ToPurchHeader, OldPurchHeader);
                PurchDocType::"Posted Invoice":
                    CopyPurchHeaderFromPostedInvoice(FromPurchInvHeader, ToPurchHeader, OldPurchHeader);
                PurchDocType::"Posted Return Shipment":
                    CopyPurchHeaderFromPostedReturnShipment(FromReturnShptHeader, ToPurchHeader, OldPurchHeader);
                PurchDocType::"Posted Credit Memo":
                    CopyPurchHeaderFromPostedCreditMemo(FromPurchCrMemoHeader, ToPurchHeader);
                PurchDocType::"Arch. Order",
                PurchDocType::"Arch. Quote",
                PurchDocType::"Arch. Blanket Order",
                PurchDocType::"Arch. Return Order":
                    CopyPurchHeaderFromPurchHeaderArchive(FromPurchHeaderArchive, ToPurchHeader, OldPurchHeader);
            end;
            OnAfterCopyPurchHeaderDone(
                ToPurchHeader, OldPurchHeader, FromPurchHeader, FromPurchRcptHeader, FromPurchInvHeader,
                FromReturnShptHeader, FromPurchCrMemoHeader, FromPurchHeaderArchive);

            Invoice := false;
            Receive := false;
            if Status = Status::Released then begin
                Status := Status::Open;
                ReleaseDocument := true;
            end;
            if MoveNegLines or IncludeHeader then begin
                Validate("Location Code");
                CopyShippingInfoPurchOrder(ToPurchHeader, FromPurchHeader);
            end;
            if MoveNegLines then
                Validate("Order Address Code");

            CopyFieldsFromOldPurchHeader(ToPurchHeader, OldPurchHeader);
            OnAfterCopyFieldsFromOldPurchHeader(ToPurchHeader, OldPurchHeader, MoveNegLines, IncludeHeader);
            if RecalculateLines then
                CreateDim(
                    DATABASE::Vendor, "Pay-to Vendor No.",
                    DATABASE::"Salesperson/Purchaser", "Purchaser Code",
                    DATABASE::Campaign, "Campaign No.",
                    DATABASE::"Responsibility Center", "Responsibility Center");
            "No. Printed" := 0;
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
            "Applies-to Doc. No." := '';
            "Applies-to ID" := '';
            "Quote No." := '';
            OnCopyPurchDocUpdateHeaderOnBeforeUpdateVendLedgerEntry(ToPurchHeader, FromDocType, FromDocNo);

            if ((FromDocType = PurchDocType::"Posted Invoice") and
                ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"])) or
                ((FromDocType = PurchDocType::"Posted Credit Memo") and
                not ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]))
            then
                UpdateVendLedgEntry(ToPurchHeader, FromDocType, FromDocNo);

            if "Document Type" in ["Document Type"::"Blanket Order", "Document Type"::Quote] then
                "Posting Date" := 0D;

            Correction := false;
            if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                UpdatePurchCreditMemoHeader(ToPurchHeader);

            OnBeforeModifyPurchHeader(ToPurchHeader, FromDocType, FromDocNo, IncludeHeader, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines);

            if CreateToHeader then begin
                Validate("Payment Terms Code");
                Modify(true);
            end else
                Modify;

            OnCopyPurchDocWithHeader(FromDocType, FromDocNo, ToPurchHeader, FromDocOccurrenceNo, FromDocVersionNo);
        end;
    end;

    local procedure CopyPurchHeaderFromPurchHeader(FromDocType: Option; FromPurchHeader: Record "Purchase Header"; OldPurchHeader: Record "Purchase Header"; var ToPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.TransferFields(FromPurchHeader, false);
        UpdatePurchHeaderWhenCopyFromPurchHeader(ToPurchHeader, OldPurchHeader, FromDocType);
        OnAfterCopyPurchaseHeader(ToPurchHeader, OldPurchHeader);
    end;

    local procedure CopyPurchHeaderFromPostedReceipt(FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromPurchRcptHeader."Buy-from Vendor No.");
        ToPurchHeader.TransferFields(FromPurchRcptHeader, false);
        OnAfterCopyPostedReceipt(ToPurchHeader, OldPurchHeader, FromPurchRcptHeader);
    end;

    local procedure CopyPurchHeaderFromPostedInvoice(FromPurchInvHeader: Record "Purch. Inv. Header"; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromPurchInvHeader."Buy-from Vendor No.");
        ToPurchHeader.TransferFields(FromPurchInvHeader, false);
        OnAfterCopyPostedPurchInvoice(ToPurchHeader, OldPurchHeader, FromPurchInvHeader);
    end;

    local procedure CopyPurchHeaderFromPostedReturnShipment(FromReturnShptHeader: Record "Return Shipment Header"; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromReturnShptHeader."Buy-from Vendor No.");
        ToPurchHeader.TransferFields(FromReturnShptHeader, false);
        OnAfterCopyPostedReturnShipment(ToPurchHeader, OldPurchHeader, FromReturnShptHeader);
    end;

    local procedure CopyPurchHeaderFromPostedCreditMemo(FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var ToPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromPurchCrMemoHeader."Buy-from Vendor No.");
        ToPurchHeader.TransferFields(FromPurchCrMemoHeader, false);
    end;

    local procedure CopyPurchHeaderFromPurchHeaderArchive(FromPurchHeaderArchive: Record "Purchase Header Archive"; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromPurchHeaderArchive."Buy-from Vendor No.");
        ToPurchHeader.TransferFields(FromPurchHeaderArchive, false);
        UpdatePurchHeaderWhenCopyFromPurchHeaderArchive(ToPurchHeader);
        CopyFromArchPurchDocDimToHdr(ToPurchHeader, FromPurchHeaderArchive);
        OnAfterCopyPurchHeaderArchive(ToPurchHeader, OldPurchHeader, FromPurchHeaderArchive)
    end;

    procedure ShowSalesDoc(ToSalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSalesDoc(ToSalesHeader, IsHandled);
        IF IsHandled then
            exit;

        with ToSalesHeader do
            case "Document Type" of
                "Document Type"::Order:
                    PAGE.Run(PAGE::"Sales Order", ToSalesHeader);
                "Document Type"::Invoice:
                    PAGE.Run(PAGE::"Sales Invoice", ToSalesHeader);
                "Document Type"::"Return Order":
                    PAGE.Run(PAGE::"Sales Return Order", ToSalesHeader);
                "Document Type"::"Credit Memo":
                    PAGE.Run(PAGE::"Sales Credit Memo", ToSalesHeader);
            end;
    end;

    procedure ShowPurchDoc(ToPurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowPurchDoc(ToPurchHeader, IsHandled);
        IF IsHandled then
            exit;

        with ToPurchHeader do
            case "Document Type" of
                "Document Type"::Order:
                    PAGE.Run(PAGE::"Purchase Order", ToPurchHeader);
                "Document Type"::Invoice:
                    PAGE.Run(PAGE::"Purchase Invoice", ToPurchHeader);
                "Document Type"::"Return Order":
                    PAGE.Run(PAGE::"Purchase Return Order", ToPurchHeader);
                "Document Type"::"Credit Memo":
                    PAGE.Run(PAGE::"Purchase Credit Memo", ToPurchHeader);
            end;
    end;

    local procedure ShowWarningNotification(SourceVariant: Variant; MissingExCostRevLink: Boolean): Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        if MissingExCostRevLink then
            ErrorMessageMgt.LogWarning(0, SourceVariant, Text019, 0, '');

        if ErrorMessageMgt.GetErrors(TempErrorMessage) then begin
            TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Error);
            if TempErrorMessage.FindFirst then begin
                if SkipWarningNotification then
                    Error(TempErrorMessage.Description);
                exit(true);
            end;
            exit(not SkipWarningNotification);
        end;
    end;

    procedure CopyFromSalesToPurchDoc(VendorNo: Code[20]; FromSalesHeader: Record "Sales Header"; var ToPurchHeader: Record "Purchase Header")
    var
        FromSalesLine: Record "Sales Line";
        ToPurchLine: Record "Purchase Line";
        NextLineNo: Integer;
    begin
        if VendorNo = '' then
            Error(Text011);

        with ToPurchLine do begin
            LockTable();
            OnCopyFromSalesToPurchDocOnBeforePurchaseHeaderInsert(ToPurchHeader, FromSalesHeader);
            ToPurchHeader.Insert(true);
            ToPurchHeader.Validate("Buy-from Vendor No.", VendorNo);
            ToPurchHeader.Modify(true);
            FromSalesLine.SetRange("Document Type", FromSalesHeader."Document Type");
            FromSalesLine.SetRange("Document No.", FromSalesHeader."No.");
            OnCopyFromSalesToPurchDocOnAfterSetFilters(FromSalesLine, FromSalesHeader);
            if not FromSalesLine.Find('-') then
                Error(Text012);
            repeat
                NextLineNo := NextLineNo + 10000;
                Clear(ToPurchLine);
                Init;
                "Document Type" := ToPurchHeader."Document Type";
                "Document No." := ToPurchHeader."No.";
                "Line No." := NextLineNo;
                if FromSalesLine.Type = FromSalesLine.Type::" " then
                    Description := FromSalesLine.Description
                else
                    TransfldsFromSalesToPurchLine(FromSalesLine, ToPurchLine);
                OnBeforeCopySalesToPurchDoc(ToPurchLine, FromSalesLine);
                Insert(true);
                if (FromSalesLine.Type <> FromSalesLine.Type::" ") and (Type = Type::Item) and (Quantity <> 0) then
                    CopyItemTrackingEntries(
                      FromSalesLine, ToPurchLine, FromSalesHeader."Prices Including VAT",
                      ToPurchHeader."Prices Including VAT");
                OnAfterCopySalesToPurchDoc(ToPurchLine, FromSalesLine);
            until FromSalesLine.Next = 0;
        end;

        OnAfterCopyFromSalesToPurchDoc(FromSalesHeader, ToPurchHeader);
    end;

    procedure TransfldsFromSalesToPurchLine(var FromSalesLine: Record "Sales Line"; var ToPurchLine: Record "Purchase Line")
    var
        DimMgt: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        OnBeforeTransfldsFromSalesToPurchLine(FromSalesLine, ToPurchLine);

        with ToPurchLine do begin
            Validate(Type, FromSalesLine.Type);
            Validate("No.", FromSalesLine."No.");
            Validate("Variant Code", FromSalesLine."Variant Code");
            Validate("Location Code", FromSalesLine."Location Code");
            Validate("Unit of Measure Code", FromSalesLine."Unit of Measure Code");
            if (Type = Type::Item) and ("No." <> '') then
                UpdateUOMQtyPerStockQty;
            "Expected Receipt Date" := FromSalesLine."Shipment Date";
            "Bin Code" := FromSalesLine."Bin Code";
            if (FromSalesLine."Document Type" = FromSalesLine."Document Type"::"Return Order") and
               ("Document Type" = "Document Type"::"Return Order")
            then
                Validate(Quantity, FromSalesLine.Quantity)
            else
                Validate(Quantity, FromSalesLine."Outstanding Quantity");
            Validate("Return Reason Code", FromSalesLine."Return Reason Code");
            Validate("Direct Unit Cost");
            Description := FromSalesLine.Description;
            "Description 2" := FromSalesLine."Description 2";
            if "Dimension Set ID" <> FromSalesLine."Dimension Set ID" then begin
                DimensionSetIDArr[1] := "Dimension Set ID";
                DimensionSetIDArr[2] := FromSalesLine."Dimension Set ID";
                "Dimension Set ID" :=
                  DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        end;

        OnAfterTransfldsFromSalesToPurchLine(FromSalesLine, ToPurchLine);
    end;

    local procedure DeleteSalesLinesWithNegQty(FromSalesHeader: Record "Sales Header"; OnlyTest: Boolean)
    var
        FromSalesLine: Record "Sales Line";
    begin
        with FromSalesLine do begin
            SetRange("Document Type", FromSalesHeader."Document Type");
            SetRange("Document No.", FromSalesHeader."No.");
            SetFilter(Quantity, '<0');
            OnDeleteSalesLinesWithNegQtyOnAfterSetFilters(FromSalesLine);
            if OnlyTest then begin
                if not Find('-') then
                    Error(Text008);
                repeat
                    TestField("Shipment No.", '');
                    TestField("Return Receipt No.", '');
                    TestField("Quantity Shipped", 0);
                    TestField("Quantity Invoiced", 0);
                until Next = 0;
            end else
                DeleteAll(true);
        end;
    end;

    local procedure DeletePurchLinesWithNegQty(FromPurchHeader: Record "Purchase Header"; OnlyTest: Boolean)
    var
        FromPurchLine: Record "Purchase Line";
    begin
        with FromPurchLine do begin
            SetRange("Document Type", FromPurchHeader."Document Type");
            SetRange("Document No.", FromPurchHeader."No.");
            SetFilter(Quantity, '<0');
            if OnlyTest then begin
                if not Find('-') then
                    Error(Text010);
                repeat
                    TestField("Receipt No.", '');
                    TestField("Return Shipment No.", '');
                    TestField("Quantity Received", 0);
                    TestField("Quantity Invoiced", 0);
                until Next = 0;
            end else
                DeleteAll(true);
        end;
    end;

    procedure CopySalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean; FromSalesDocType: Option; var CopyPostedDeferral: Boolean; DocLineNo: Integer): Boolean
    var
        RoundingLineInserted: Boolean;
        CopyThisLine: Boolean;
        CheckVATBusGroup: Boolean;
        InvDiscountAmount: Decimal;
    begin
        CopyThisLine := true;
        OnBeforeCopySalesLine(ToSalesHeader, FromSalesHeader, FromSalesLine, RecalculateLines, CopyThisLine, MoveNegLines);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        CheckSalesRounding(FromSalesLine, RoundingLineInserted);

        if ((ToSalesHeader."Language Code" <> FromSalesHeader."Language Code") or RecalculateLines) and
           (FromSalesLine."Attached to Line No." <> 0) or
           FromSalesLine."Prepayment Line" or RoundingLineInserted
        then
            exit(false);

        if IsEntityBlocked(Database::"Sales Line", ToSalesHeader.IsCreditDocType(), FromSalesLine.Type, FromSalesLine."No.") then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        ToSalesLine.SetSalesHeader(ToSalesHeader);
        if RecalculateLines and not FromSalesLine."System-Created Entry" then begin
            ToSalesLine.Init();
            OnAfterInitToSalesLine(ToSalesLine);
        end else begin
            ToSalesLine := FromSalesLine;
            ToSalesLine."Returns Deferral Start Date" := 0D;
            OnCopySalesLineOnAfterTransferFieldsToSalesLine(ToSalesLine, FromSalesLine);
            if ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Quote, ToSalesHeader."Document Type"::"Blanket Order"] then
                ToSalesLine."Deferral Code" := '';
            if MoveNegLines and (ToSalesLine.Type <> ToSalesLine.Type::" ") then begin
                ToSalesLine.Amount := -ToSalesLine.Amount;
                ToSalesLine."Amount Including VAT" := -ToSalesLine."Amount Including VAT";
            end
        end;

        CheckVATBusGroup := (not RecalculateLines) and (ToSalesLine."No." <> '');
        OnCopySalesLineOnBeforeCheckVATBusGroup(ToSalesLine, CheckVATBusGroup);
        if CheckVATBusGroup then
            ToSalesLine.TestField("VAT Bus. Posting Group", ToSalesHeader."VAT Bus. Posting Group");

        NextLineNo := NextLineNo + 10000;
        ToSalesLine."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine."Document No." := ToSalesHeader."No.";
        ToSalesLine."Line No." := NextLineNo;
        ToSalesLine."Copied From Posted Doc." := FromSalesLine."Copied From Posted Doc.";
        if (ToSalesLine.Type <> ToSalesLine.Type::" ") and
           (ToSalesLine."Document Type" in [ToSalesLine."Document Type"::"Return Order", ToSalesLine."Document Type"::"Credit Memo"])
        then begin
            ToSalesLine."Job Contract Entry No." := 0;
            if (ToSalesLine.Amount = 0) or
               (ToSalesHeader."Prices Including VAT" <> FromSalesHeader."Prices Including VAT") or
               (ToSalesHeader."Currency Factor" <> FromSalesHeader."Currency Factor")
            then begin
                InvDiscountAmount := ToSalesLine."Inv. Discount Amount";
                ToSalesLine.Validate("Line Discount %");
                ToSalesLine.Validate("Inv. Discount Amount", InvDiscountAmount);
            end;
        end;
        ToSalesLine.Validate("Currency Code", FromSalesHeader."Currency Code");

        UpdateSalesLine(
          ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine,
          CopyThisLine, RecalculateAmount, FromSalesDocType, CopyPostedDeferral);
        ToSalesLine.CheckLocationOnWMS;

        if ExactCostRevMandatory and
           (FromSalesLine.Type = FromSalesLine.Type::Item) and
           (FromSalesLine."Appl.-from Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then begin
                ToSalesLine.Validate("Unit Price", FromSalesLine."Unit Price");
                ToSalesLine.Validate("Line Discount %", FromSalesLine."Line Discount %");
                ToSalesLine.Validate(
                  "Line Discount Amount",
                  Round(FromSalesLine."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToSalesLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromSalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToSalesLine.Validate("Appl.-from Item Entry", FromSalesLine."Appl.-from Item Entry");
            if not CreateToHeader then
                if ToSalesLine."Shipment Date" = 0D then
                    InitShipmentDateInLine(ToSalesHeader, ToSalesLine);
        end;

        if MoveNegLines and (ToSalesLine.Type <> ToSalesLine.Type::" ") then begin
            ToSalesLine.Validate(Quantity, -FromSalesLine.Quantity);
            ToSalesLine.Validate("Unit Price", FromSalesLine."Unit Price");
            ToSalesLine.Validate("Line Discount %", FromSalesLine."Line Discount %");
            ToSalesLine."Appl.-to Item Entry" := FromSalesLine."Appl.-to Item Entry";
            ToSalesLine."Appl.-from Item Entry" := FromSalesLine."Appl.-from Item Entry";
            ToSalesLine."Job No." := FromSalesLine."Job No.";
            ToSalesLine."Job Task No." := FromSalesLine."Job Task No.";
            ToSalesLine."Job Contract Entry No." := FromSalesLine."Job Contract Entry No.";
        end;

        if CopyJobData then
            CopySalesJobFields(ToSalesLine, ToSalesHeader, FromSalesLine);

        CopySalesLineExtText(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, DocLineNo, NextLineNo);

        if not RecalculateLines then begin
            ToSalesLine."Dimension Set ID" := FromSalesLine."Dimension Set ID";
            ToSalesLine."Shortcut Dimension 1 Code" := FromSalesLine."Shortcut Dimension 1 Code";
            ToSalesLine."Shortcut Dimension 2 Code" := FromSalesLine."Shortcut Dimension 2 Code";
            OnCopySalesLineOnAfterSetDimensions(ToSalesLine, FromSalesLine);
        end;

        if CopyThisLine then begin
            OnBeforeInsertToSalesLine(
              ToSalesLine, FromSalesLine, FromSalesDocType, RecalculateLines, ToSalesHeader, DocLineNo, NextLineNo);
            ToSalesLine.Insert();
            HandleAsmAttachedToSalesLine(ToSalesLine);
            if ToSalesLine.Reserve = ToSalesLine.Reserve::Always then
                ToSalesLine.AutoReserve;
            OnAfterInsertToSalesLine(ToSalesLine, FromSalesLine, RecalculateLines, DocLineNo);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    procedure UpdateSalesHeaderWhenCopyFromSalesHeader(var SalesHeader: Record "Sales Header"; OriginalSalesHeader: Record "Sales Header"; FromDocType: Option)
    begin
        ClearSalesLastNoSFields(SalesHeader);
        with SalesHeader do begin
            Status := Status::Open;
            if "Document Type" <> "Document Type"::Order then
                "Prepayment %" := 0;
            if FromDocType = SalesDocType::"Return Order" then begin
                CopySellToAddressToShipToAddress;
                Validate("Ship-to Code");
            end;
            if FromDocType in [SalesDocType::Quote, SalesDocType::"Blanket Order"] then
                if OriginalSalesHeader."Posting Date" = 0D then
                    "Posting Date" := WorkDate
                else
                    "Posting Date" := OriginalSalesHeader."Posting Date";
        end;
    end;

    local procedure UpdateSalesHeaderWhenCopyFromSalesHeaderArchive(var SalesHeader: Record "Sales Header")
    begin
        ClearSalesLastNoSFields(SalesHeader);
        SalesHeader.Status := SalesHeader.Status::Open;
    end;

    procedure ClearSalesLastNoSFields(var SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            "Last Shipping No." := '';
            "Last Posting No." := '';
            "Last Prepayment No." := '';
            "Last Prepmt. Cr. Memo No." := '';
            "Last Return Receipt No." := '';
        end;
    end;

    local procedure UpdateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromSalesDocType: Option; var CopyPostedDeferral: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralDocType: Integer;
    begin
        OnBeforeUpdateSalesLine(
          ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine,
          CopyThisLine, RecalculateAmount, FromSalesDocType, CopyPostedDeferral);

        CopyPostedDeferral := false;
        DeferralDocType := DeferralUtilities.GetSalesDeferralDocType;
        if RecalculateLines and not FromSalesLine."System-Created Entry" then begin
            RecalculateSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CopyThisLine);
            if IsDeferralToBeCopied(DeferralDocType, ToSalesLine."Document Type", FromSalesDocType) then
                ToSalesLine.Validate("Deferral Code", FromSalesLine."Deferral Code");
            OnUpdateSalesLineOnAfterRecalculateSalesLine(ToSalesLine, FromSalesLine);
        end else begin
            SetDefaultValuesToSalesLine(ToSalesLine, ToSalesHeader, FromSalesLine."VAT Difference");
            if IsDeferralToBeCopied(DeferralDocType, ToSalesLine."Document Type", FromSalesDocType) then
                if IsDeferralPosted(DeferralDocType, FromSalesDocType) then
                    CopyPostedDeferral := true
                else
                    ToSalesLine."Returns Deferral Start Date" :=
                      CopyDeferrals(DeferralDocType, FromSalesLine."Document Type", FromSalesLine."Document No.",
                        FromSalesLine."Line No.", ToSalesLine."Document Type", ToSalesLine."Document No.", ToSalesLine."Line No.")
            else
                if IsDeferralToBeDefaulted(DeferralDocType, ToSalesLine."Document Type", FromSalesDocType) then
                    InitSalesDeferralCode(ToSalesLine);

            if ToSalesLine."Document Type" <> ToSalesLine."Document Type"::Order then begin
                ToSalesLine."Drop Shipment" := false;
                ToSalesLine."Special Order" := false;
            end;
            if RecalculateAmount and (FromSalesLine."Appl.-from Item Entry" = 0) then begin
                if (ToSalesLine.Type <> ToSalesLine.Type::" ") and (ToSalesLine."No." <> '') then begin
                    ToSalesLine.Validate("Line Discount %", FromSalesLine."Line Discount %");
                    ToSalesLine.Validate(
                      "Inv. Discount Amount", Round(FromSalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
                end;
                ToSalesLine.Validate("Unit Cost (LCY)", FromSalesLine."Unit Cost (LCY)");
            end;
            if VATPostingSetup.Get(ToSalesLine."VAT Bus. Posting Group", ToSalesLine."VAT Prod. Posting Group") then
                ToSalesLine."VAT Identifier" := VATPostingSetup."VAT Identifier";

            ToSalesLine.UpdateWithWarehouseShip;
            if (ToSalesLine.Type = ToSalesLine.Type::Item) and (ToSalesLine."No." <> '') then begin
                GetItem(ToSalesLine."No.");
                if (Item."Costing Method" = Item."Costing Method"::Standard) and not ToSalesLine.IsShipment then
                    ToSalesLine.GetUnitCost;

                if Item.Reserve = Item.Reserve::Optional then
                    ToSalesLine.Reserve := ToSalesHeader.Reserve
                else
                    ToSalesLine.Reserve := Item.Reserve;
                if ToSalesLine.Reserve = ToSalesLine.Reserve::Always then
                    InitShipmentDateInLine(ToSalesHeader, ToSalesLine);
            end;
        end;

        OnAfterUpdateSalesLine(
          ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine,
          CopyThisLine, RecalculateAmount, FromSalesDocType, CopyPostedDeferral);
    end;

    local procedure RecalculateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean)
    var
        GLAcc: Record "G/L Account";
    begin
        OnBeforeRecalculateSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CopyThisLine);

        ToSalesLine.Validate(Type, FromSalesLine.Type);
        ToSalesLine.Description := FromSalesLine.Description;
        ToSalesLine.Validate("Description 2", FromSalesLine."Description 2");
        OnUpdateSalesLine(ToSalesLine, FromSalesLine);

        if (FromSalesLine.Type <> 0) and (FromSalesLine."No." <> '') then begin
            if ToSalesLine.Type = ToSalesLine.Type::"G/L Account" then begin
                ToSalesLine."No." := FromSalesLine."No.";
                GLAcc.Get(FromSalesLine."No.");
                CopyThisLine := GLAcc."Direct Posting";
                if CopyThisLine then
                    ToSalesLine.Validate("No.", FromSalesLine."No.");
            end else
                ToSalesLine.Validate("No.", FromSalesLine."No.");
            ToSalesLine.Validate("Variant Code", FromSalesLine."Variant Code");
            ToSalesLine.Validate("Location Code", FromSalesLine."Location Code");
            ToSalesLine.Validate("Unit of Measure", FromSalesLine."Unit of Measure");
            ToSalesLine.Validate("Unit of Measure Code", FromSalesLine."Unit of Measure Code");
            ToSalesLine.Validate(Quantity, FromSalesLine.Quantity);
            OnRecalculateSalesLineOnAfterValidateQuantity(ToSalesLine, FromSalesLine);

            if not (FromSalesLine.Type in [FromSalesLine.Type::Item, FromSalesLine.Type::Resource]) then begin
                if (FromSalesHeader."Currency Code" <> ToSalesHeader."Currency Code") or
                   (FromSalesHeader."Prices Including VAT" <> ToSalesHeader."Prices Including VAT")
                then begin
                    ToSalesLine."Unit Price" := 0;
                    ToSalesLine."Line Discount %" := 0;
                end else begin
                    ToSalesLine.Validate("Unit Price", FromSalesLine."Unit Price");
                    ToSalesLine.Validate("Line Discount %", FromSalesLine."Line Discount %");
                end;
                if ToSalesLine.Quantity <> 0 then
                    ToSalesLine.Validate("Line Discount Amount", FromSalesLine."Line Discount Amount");
            end;
            ToSalesLine.Validate("Work Type Code", FromSalesLine."Work Type Code");
            if (ToSalesLine."Document Type" = ToSalesLine."Document Type"::Order) and
               (FromSalesLine."Purchasing Code" <> '')
            then
                ToSalesLine.Validate("Purchasing Code", FromSalesLine."Purchasing Code");
        end;
        if (FromSalesLine.Type = FromSalesLine.Type::" ") and (FromSalesLine."No." <> '') then
            ToSalesLine.Validate("No.", FromSalesLine."No.");

        OnAfterRecalculateSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CopyThisLine);
    end;

    local procedure HandleAsmAttachedToSalesLine(var ToSalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        with ToSalesLine do begin
            if Type <> Type::Item then
                exit;
            if not ("Document Type" in ["Document Type"::Quote, "Document Type"::Order, "Document Type"::"Blanket Order"]) then
                exit;
        end;
        if AsmHdrExistsForFromDocLine then begin
            ToSalesLine."Qty. to Assemble to Order" := QtyToAsmToOrder;
            ToSalesLine."Qty. to Asm. to Order (Base)" := QtyToAsmToOrderBase;
            ToSalesLine.Modify();
            CopyAsmOrderToAsmOrder(TempAsmHeader, TempAsmLine, ToSalesLine, GetAsmOrderType(ToSalesLine."Document Type"), '', true);
        end else begin
            Item.Get(ToSalesLine."No.");
            if (Item."Assembly Policy" = Item."Assembly Policy"::"Assemble-to-Order") and
               (Item."Replenishment System" = Item."Replenishment System"::Assembly)
            then begin
                ToSalesLine.Validate("Qty. to Assemble to Order", ToSalesLine.Quantity);
                ToSalesLine.Modify();
            end;
        end;
    end;

    procedure CopyPurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean; FromPurchDocType: Option; var CopyPostedDeferral: Boolean; DocLineNo: Integer): Boolean
    var
        RoundingLineInserted: Boolean;
        CopyThisLine: Boolean;
        CheckVATBusGroup: Boolean;
        InvDiscountAmount: Decimal;
    begin
        CopyThisLine := true;
        OnBeforeCopyPurchLine(
          ToPurchHeader, FromPurchHeader, FromPurchLine, RecalculateLines, CopyThisLine, ToPurchLine, MoveNegLines,
          RoundingLineInserted);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        CheckPurchRounding(FromPurchLine, RoundingLineInserted);

        if ((ToPurchHeader."Language Code" <> FromPurchHeader."Language Code") or RecalculateLines) and
           (FromPurchLine."Attached to Line No." <> 0) or
           FromPurchLine."Prepayment Line" or RoundingLineInserted
        then
            exit(false);

        if IsEntityBlocked(Database::"Purchase Line", ToPurchHeader.IsCreditDocType(), FromPurchLine.Type, FromPurchLine."No.") then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        if RecalculateLines and not FromPurchLine."System-Created Entry" then begin
            ToPurchLine.Init();
            OnAfterInitToPurchLine(ToPurchLine);
        end else begin
            ToPurchLine := FromPurchLine;
            ToPurchLine."Returns Deferral Start Date" := 0D;
            if ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::Quote, ToPurchHeader."Document Type"::"Blanket Order"] then
                ToPurchLine."Deferral Code" := '';
            if MoveNegLines and (ToPurchLine.Type <> ToPurchLine.Type::" ") then begin
                ToPurchLine.Amount := -ToPurchLine.Amount;
                ToPurchLine."Amount Including VAT" := -ToPurchLine."Amount Including VAT";
            end
        end;

        CheckVATBusGroup := (not RecalculateLines) and (ToPurchLine."No." <> '');
        OnCopyPurchLineOnBeforeCheckVATBusGroup(ToPurchLine, CheckVATBusGroup);
        if CheckVATBusGroup then
            ToPurchLine.TestField("VAT Bus. Posting Group", ToPurchHeader."VAT Bus. Posting Group");

        NextLineNo := NextLineNo + 10000;
        ToPurchLine."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine."Document No." := ToPurchHeader."No.";
        ToPurchLine."Line No." := NextLineNo;
        ToPurchLine."Copied From Posted Doc." := FromPurchLine."Copied From Posted Doc.";
        ToPurchLine.Validate("Currency Code", FromPurchHeader."Currency Code");
        if (ToPurchLine.Type <> ToPurchLine.Type::" ") and
           ((ToPurchLine.Amount = 0) or
            (ToPurchHeader."Prices Including VAT" <> FromPurchHeader."Prices Including VAT") or
            (ToPurchHeader."Currency Factor" <> FromPurchHeader."Currency Factor"))
        then begin
            InvDiscountAmount := ToPurchLine."Inv. Discount Amount";
            ToPurchLine.Validate("Line Discount %");
            ToPurchLine.Validate("Inv. Discount Amount", InvDiscountAmount);
        end;

        UpdatePurchLine(
          ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine,
          CopyThisLine, RecalculateAmount, FromPurchDocType, CopyPostedDeferral);

        ToPurchLine.CheckLocationOnWMS;

        if ExactCostRevMandatory and
           (FromPurchLine.Type = FromPurchLine.Type::Item) and
           (FromPurchLine."Appl.-to Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then begin
                ToPurchLine.Validate("Direct Unit Cost", FromPurchLine."Direct Unit Cost");
                ToPurchLine.Validate("Line Discount %", FromPurchLine."Line Discount %");
                ToPurchLine.Validate(
                  "Line Discount Amount",
                  Round(FromPurchLine."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToPurchLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromPurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToPurchLine.Validate("Appl.-to Item Entry", FromPurchLine."Appl.-to Item Entry");
            if not CreateToHeader then
                if ToPurchLine."Expected Receipt Date" = 0D then begin
                    if ToPurchHeader."Expected Receipt Date" <> 0D then
                        ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date"
                    else
                        ToPurchLine."Expected Receipt Date" := WorkDate;
                end;
        end;

        OnCopyPurchLineOnBeforeValidateQuantity(ToPurchLine, RecalculateLines);

        if MoveNegLines and (ToPurchLine.Type <> ToPurchLine.Type::" ") then begin
            ToPurchLine.Validate(Quantity, -FromPurchLine.Quantity);
            ToPurchLine."Appl.-to Item Entry" := FromPurchLine."Appl.-to Item Entry"
        end;

        CopyPurchLineExtText(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, DocLineNo, NextLineNo);

        if FromPurchLine."Job No." <> '' then
            CopyPurchaseJobFields(ToPurchLine, FromPurchLine);

        if not RecalculateLines then begin
            ToPurchLine."Dimension Set ID" := FromPurchLine."Dimension Set ID";
            ToPurchLine."Shortcut Dimension 1 Code" := FromPurchLine."Shortcut Dimension 1 Code";
            ToPurchLine."Shortcut Dimension 2 Code" := FromPurchLine."Shortcut Dimension 2 Code";
            OnCopyPurchLineOnAfterSetDimensions(ToPurchLine, FromPurchLine);
        end;

        if CopyThisLine then begin
            OnBeforeInsertToPurchLine(
                ToPurchLine, FromPurchLine, FromPurchDocType, RecalculateLines, ToPurchHeader, DocLineNo, NextLineNo);
            ToPurchLine.Insert();
            OnAfterInsertToPurchLine(ToPurchLine, FromPurchLine, RecalculateLines, DocLineNo);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    procedure UpdatePurchHeaderWhenCopyFromPurchHeader(var PurchaseHeader: Record "Purchase Header"; OriginalPurchaseHeader: Record "Purchase Header"; FromDocType: Option)
    begin
        ClearPurchLastNoSFields(PurchaseHeader);
        with PurchaseHeader do begin
            Receive := false;
            Status := Status::Open;
            "IC Status" := "IC Status"::New;
            if "Document Type" <> "Document Type"::Order then
                "Prepayment %" := 0;
            if FromDocType in [PurchDocType::Quote, PurchDocType::"Blanket Order"] then
                if OriginalPurchaseHeader."Posting Date" = 0D then
                    "Posting Date" := WorkDate
                else
                    "Posting Date" := OriginalPurchaseHeader."Posting Date";
        end;
    end;

    local procedure UpdatePurchHeaderWhenCopyFromPurchHeaderArchive(var PurchaseHeader: Record "Purchase Header")
    begin
        ClearPurchLastNoSFields(PurchaseHeader);
        PurchaseHeader.Status := PurchaseHeader.Status::Open;
    end;

    procedure ClearPurchLastNoSFields(var PurchaseHeader: Record "Purchase Header")
    begin
        with PurchaseHeader do begin
            "Last Receiving No." := '';
            "Last Posting No." := '';
            "Last Prepayment No." := '';
            "Last Prepmt. Cr. Memo No." := '';
            "Last Return Shipment No." := '';
        end;
    end;

    local procedure UpdatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromPurchDocType: Option; var CopyPostedDeferral: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralDocType: Integer;
    begin
        OnBeforeUpdatePurchLine(
          ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine,
          CopyThisLine, RecalculateAmount, FromPurchDocType, CopyPostedDeferral);

        CopyPostedDeferral := false;
        DeferralDocType := DeferralUtilities.GetPurchDeferralDocType;
        if RecalculateLines and not FromPurchLine."System-Created Entry" then begin
            RecalculatePurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, CopyThisLine);
            if IsDeferralToBeCopied(DeferralDocType, ToPurchLine."Document Type", FromPurchDocType) then
                ToPurchLine.Validate("Deferral Code", FromPurchLine."Deferral Code");
        end else begin
            SetDefaultValuesToPurchLine(ToPurchLine, ToPurchHeader, FromPurchLine."VAT Difference");
            if IsDeferralToBeCopied(DeferralDocType, ToPurchLine."Document Type", FromPurchDocType) then
                if IsDeferralPosted(DeferralDocType, FromPurchDocType) then
                    CopyPostedDeferral := true
                else
                    ToPurchLine."Returns Deferral Start Date" :=
                      CopyDeferrals(DeferralDocType, FromPurchLine."Document Type", FromPurchLine."Document No.",
                        FromPurchLine."Line No.", ToPurchLine."Document Type", ToPurchLine."Document No.", ToPurchLine."Line No.")
            else
                if IsDeferralToBeDefaulted(DeferralDocType, ToPurchLine."Document Type", FromPurchDocType) then
                    InitPurchDeferralCode(ToPurchLine);

            if FromPurchLine."Drop Shipment" or FromPurchLine."Special Order" then
                ToPurchLine."Purchasing Code" := '';
            ToPurchLine."Drop Shipment" := false;
            ToPurchLine."Special Order" := false;
            if VATPostingSetup.Get(ToPurchLine."VAT Bus. Posting Group", ToPurchLine."VAT Prod. Posting Group") then
                ToPurchLine."VAT Identifier" := VATPostingSetup."VAT Identifier";

            OnBeforeCopyPurchLines(ToPurchLine);

            CopyDocLines(RecalculateAmount, ToPurchLine, FromPurchLine);

            ToPurchLine.UpdateWithWarehouseReceive;
            ToPurchLine."Pay-to Vendor No." := ToPurchHeader."Pay-to Vendor No.";
        end;
        ToPurchLine.Validate("Order No.", FromPurchLine."Order No.");
        ToPurchLine.Validate("Order Line No.", FromPurchLine."Order Line No.");

        OnAfterUpdatePurchLine(
          ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine,
          CopyThisLine, RecalculateAmount, FromPurchDocType, CopyPostedDeferral, RecalculateLines);
    end;

    local procedure RecalculatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean)
    var
        GLAcc: Record "G/L Account";
    begin
        OnBeforeRecalculatePurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, CopyThisLine);

        ToPurchLine.Validate(Type, FromPurchLine.Type);
        ToPurchLine.Description := FromPurchLine.Description;
        ToPurchLine.Validate("Description 2", FromPurchLine."Description 2");
        OnUpdatePurchLine(ToPurchLine, FromPurchLine);

        if (FromPurchLine.Type <> 0) and (FromPurchLine."No." <> '') then begin
            if ToPurchLine.Type = ToPurchLine.Type::"G/L Account" then begin
                ToPurchLine."No." := FromPurchLine."No.";
                GLAcc.Get(FromPurchLine."No.");
                CopyThisLine := GLAcc."Direct Posting";
                if CopyThisLine then
                    ToPurchLine.Validate("No.", FromPurchLine."No.");
            end else
                ToPurchLine.Validate("No.", FromPurchLine."No.");
            ToPurchLine.Validate("Variant Code", FromPurchLine."Variant Code");
            ToPurchLine.Validate("Location Code", FromPurchLine."Location Code");
            ToPurchLine.Validate("Unit of Measure", FromPurchLine."Unit of Measure");
            ToPurchLine.Validate("Unit of Measure Code", FromPurchLine."Unit of Measure Code");
            ToPurchLine.Validate(Quantity, FromPurchLine.Quantity);
            OnRecalculatePurchLineOnAfterValidateQuantity(ToPurchLine, FromPurchLine);

            if not (FromPurchLine.Type in [FromPurchLine.Type::Item, FromPurchLine.Type::Resource]) then begin
                ToPurchHeader.TestField("Currency Code", FromPurchHeader."Currency Code");
                ToPurchLine.Validate("Direct Unit Cost", FromPurchLine."Direct Unit Cost");
                ToPurchLine.Validate("Line Discount %", FromPurchLine."Line Discount %");
                if ToPurchLine.Quantity <> 0 then
                    ToPurchLine.Validate("Line Discount Amount", FromPurchLine."Line Discount Amount");
            end;
            if (ToPurchLine."Document Type" = ToPurchLine."Document Type"::Order) and
               (FromPurchLine."Purchasing Code" <> '') and not FromPurchLine."Drop Shipment" and not FromPurchLine."Special Order"
            then
                ToPurchLine.Validate("Purchasing Code", FromPurchLine."Purchasing Code");
        end;
        if (FromPurchLine.Type = FromPurchLine.Type::" ") and (FromPurchLine."No." <> '') then
            ToPurchLine.Validate("No.", FromPurchLine."No.");

        OnAfterRecalculatePurchLine(ToPurchLine, ToPurchHeader, FromPurchHeader, FromPurchLine, CopyThisLine);
    end;

    local procedure CheckPurchRounding(FromPurchLine: Record "Purchase Line"; var RoundingLineInserted: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if (FromPurchLine.Type <> FromPurchLine.Type::"G/L Account") or (FromPurchLine."No." = '') then
            exit;
        if not FromPurchLine."System-Created Entry" then
            exit;

        PurchSetup.Get();
        if PurchSetup."Invoice Rounding" then begin
            Vendor.Get(FromPurchLine."Pay-to Vendor No.");
            VendorPostingGroup.Get(Vendor."Vendor Posting Group");
            RoundingLineInserted := FromPurchLine."No." = VendorPostingGroup.GetInvRoundingAccount;
        end;
    end;

    local procedure CheckSalesRounding(FromSalesLine: Record "Sales Line"; var RoundingLineInserted: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if (FromSalesLine.Type <> FromSalesLine.Type::"G/L Account") or (FromSalesLine."No." = '') then
            exit;
        if not FromSalesLine."System-Created Entry" then
            exit;

        SalesSetup.Get();
        if SalesSetup."Invoice Rounding" then begin
            Customer.Get(FromSalesLine."Bill-to Customer No.");
            CustomerPostingGroup.Get(Customer."Customer Posting Group");
            RoundingLineInserted := FromSalesLine."No." = CustomerPostingGroup.GetInvRoundingAccount;
        end;
    end;

    local procedure CopyFromSalesDocAssgntToLine(var ToSalesLine: Record "Sales Line"; FromDocType: Option; FromDocNo: Code[20]; FromLineNo: Integer; var ItemChargeAssgntNextLineNo: Integer)
    var
        FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ToItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
        IsHandled: Boolean;
    begin
        FromItemChargeAssgntSales.Reset();
        FromItemChargeAssgntSales.SetRange("Document Type", FromDocType);
        FromItemChargeAssgntSales.SetRange("Document No.", FromDocNo);
        FromItemChargeAssgntSales.SetRange("Document Line No.", FromLineNo);
        FromItemChargeAssgntSales.SetFilter("Applies-to Doc. Type", '<>%1', FromDocType);
        OnCopyFromSalesDocAssgntToLineOnAfterSetFilters(FromItemChargeAssgntSales, RecalculateLines);
        if FromItemChargeAssgntSales.Find('-') then
            repeat
                ToItemChargeAssgntSales.Copy(FromItemChargeAssgntSales);
                ToItemChargeAssgntSales."Document Type" := ToSalesLine."Document Type";
                ToItemChargeAssgntSales."Document No." := ToSalesLine."Document No.";
                ToItemChargeAssgntSales."Document Line No." := ToSalesLine."Line No.";
                IsHandled := false;
                OnCopyFromSalesDocAssgntToLineOnBeforeInsert(FromItemChargeAssgntSales, RecalculateLines, IsHandled);
                if not IsHandled then
                    ItemChargeAssgntSales.InsertItemChargeAssgnt(
                      ToItemChargeAssgntSales, ToItemChargeAssgntSales."Applies-to Doc. Type",
                      ToItemChargeAssgntSales."Applies-to Doc. No.", ToItemChargeAssgntSales."Applies-to Doc. Line No.",
                      ToItemChargeAssgntSales."Item No.", ToItemChargeAssgntSales.Description, ItemChargeAssgntNextLineNo);
            until FromItemChargeAssgntSales.Next = 0;

        OnAfterCopyFromSalesDocAssgntToLine(ToSalesLine, RecalculateLines);
    end;

    local procedure CopyFromPurchDocAssgntToLine(var ToPurchLine: Record "Purchase Line"; FromDocType: Option; FromDocNo: Code[20]; FromLineNo: Integer; var ItemChargeAssgntNextLineNo: Integer)
    var
        FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ToItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        IsHandled: Boolean;
    begin
        FromItemChargeAssgntPurch.Reset();
        FromItemChargeAssgntPurch.SetRange("Document Type", FromDocType);
        FromItemChargeAssgntPurch.SetRange("Document No.", FromDocNo);
        FromItemChargeAssgntPurch.SetRange("Document Line No.", FromLineNo);
        FromItemChargeAssgntPurch.SetFilter("Applies-to Doc. Type", '<>%1', FromDocType);
        OnCopyFromPurchDocAssgntToLineOnAfterSetFilters(FromItemChargeAssgntPurch, RecalculateLines);
        if FromItemChargeAssgntPurch.Find('-') then
            repeat
                ToItemChargeAssgntPurch.Copy(FromItemChargeAssgntPurch);
                ToItemChargeAssgntPurch."Document Type" := ToPurchLine."Document Type";
                ToItemChargeAssgntPurch."Document No." := ToPurchLine."Document No.";
                ToItemChargeAssgntPurch."Document Line No." := ToPurchLine."Line No.";
                IsHandled := false;
                OnCopyFromPurchDocAssgntToLineOnBeforeInsert(FromItemChargeAssgntPurch, RecalculateLines, IsHandled);
                if not IsHandled then
                    ItemChargeAssgntPurch.InsertItemChargeAssgnt(
                      ToItemChargeAssgntPurch, ToItemChargeAssgntPurch."Applies-to Doc. Type",
                      ToItemChargeAssgntPurch."Applies-to Doc. No.", ToItemChargeAssgntPurch."Applies-to Doc. Line No.",
                      ToItemChargeAssgntPurch."Item No.", ToItemChargeAssgntPurch.Description, ItemChargeAssgntNextLineNo);
            until FromItemChargeAssgntPurch.Next = 0;

        OnAfterCopyFromPurchDocAssgntToLine(ToPurchLine, RecalculateLines);
    end;

    local procedure CopyFromPurchLineItemChargeAssign(FromPurchLine: Record "Purchase Line"; ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; var ItemChargeAssgntNextLineNo: Integer)
    var
        TempToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary;
        ToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        Currency: Record Currency;
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        CurrencyFactor: Decimal;
        QtyToAssign: Decimal;
        SumQtyToAssign: Decimal;
        RemainingQty: Decimal;
    begin
        if FromPurchLine."Document Type" = FromPurchLine."Document Type"::"Credit Memo" then
            ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo")
        else
            ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");

        ValueEntry.SetRange("Document No.", FromPurchLine."Document No.");
        ValueEntry.SetRange("Document Line No.", FromPurchLine."Line No.");
        ValueEntry.SetRange("Item Charge No.", FromPurchLine."No.");
        ToItemChargeAssignmentPurch."Document Type" := ToPurchLine."Document Type";
        ToItemChargeAssignmentPurch."Document No." := ToPurchLine."Document No.";
        ToItemChargeAssignmentPurch."Document Line No." := ToPurchLine."Line No.";
        ToItemChargeAssignmentPurch."Item Charge No." := FromPurchLine."No.";
        ToItemChargeAssignmentPurch."Unit Cost" := FromPurchLine."Unit Cost";

        if ValueEntry.FindSet() then begin
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
                    if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Purchase Receipt" then begin
                        Item.Get(ItemLedgerEntry."Item No.");
                        CurrencyFactor := FromPurchHeader."Currency Factor";

                        if not Currency.Get(FromPurchHeader."Currency Code") then begin
                            CurrencyFactor := 1;
                            Currency.InitRoundingPrecision();
                        end;

                        if ToPurchLine."Unit Cost" = 0 then
                            QtyToAssign := 0
                        else
                            QtyToAssign := ValueEntry."Cost Amount (Actual)" * CurrencyFactor / ToPurchLine."Unit Cost";
                        SumQtyToAssign += QtyToAssign;

                        ItemChargeAssgntPurch.InsertItemChargeAssgntWithAssignValuesTo(
                            ToItemChargeAssignmentPurch, ToItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
                            ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.", ItemLedgerEntry."Item No.", Item.Description,
                            QtyToAssign, 0, ItemChargeAssgntNextLineNo, TempToItemChargeAssignmentPurch);
                    end;
                OnCopyFromPurchLineItemChargeAssignOnAfterValueEntryLoop(
                    FromPurchHeader, ToPurchLine, ValueEntry, TempToItemChargeAssignmentPurch, ToItemChargeAssignmentPurch,
                    ItemChargeAssgntNextLineNo, SumQtyToAssign);
            until ValueEntry.Next() = 0;
            ItemChargeAssgntPurch.Summarize(TempToItemChargeAssignmentPurch, ToItemChargeAssignmentPurch);

            // Use 2 passes to correct rounding issues
            ToItemChargeAssignmentPurch.SetRange("Document Type", ToPurchLine."Document Type");
            ToItemChargeAssignmentPurch.SetRange("Document No.", ToPurchLine."Document No.");
            ToItemChargeAssignmentPurch.SetRange("Document Line No.", ToPurchLine."Line No.");
            if ToItemChargeAssignmentPurch.FindSet(true) then begin
                RemainingQty := (FromPurchLine.Quantity - SumQtyToAssign) / ValueEntry.Count();
                SumQtyToAssign := 0;
                repeat
                    AddRemainingQtyToPurchItemCharge(ToItemChargeAssignmentPurch, RemainingQty);
                    SumQtyToAssign += ToItemChargeAssignmentPurch."Qty. to Assign";
                until ToItemChargeAssignmentPurch.Next = 0;

                RemainingQty := FromPurchLine.Quantity - SumQtyToAssign;
                if RemainingQty <> 0 then
                    AddRemainingQtyToPurchItemCharge(ToItemChargeAssignmentPurch, RemainingQty);
            end;
        end;
    end;

    local procedure CopyFromSalesLineItemChargeAssign(FromSalesLine: Record "Sales Line"; ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; var ItemChargeAssgntNextLineNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        Currency: Record Currency;
        TempToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary;
        ToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
        CurrencyFactor: Decimal;
        QtyToAssign: Decimal;
        SumQtyToAssign: Decimal;
        RemainingQty: Decimal;
    begin
        if FromSalesLine."Document Type" = FromSalesLine."Document Type"::"Credit Memo" then
            ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo")
        else
            ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");

        ValueEntry.SetRange("Document No.", FromSalesLine."Document No.");
        ValueEntry.SetRange("Document Line No.", FromSalesLine."Line No.");
        ValueEntry.SetRange("Item Charge No.", FromSalesLine."No.");
        ToItemChargeAssignmentSales."Document Type" := ToSalesLine."Document Type";
        ToItemChargeAssignmentSales."Document No." := ToSalesLine."Document No.";
        ToItemChargeAssignmentSales."Document Line No." := ToSalesLine."Line No.";
        ToItemChargeAssignmentSales."Item Charge No." := FromSalesLine."No.";
        ToItemChargeAssignmentSales."Unit Cost" := FromSalesLine."Unit Price";

        if ValueEntry.FindSet then begin
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
                    if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Sales Shipment" then begin
                        Item.Get(ItemLedgerEntry."Item No.");
                        CurrencyFactor := FromSalesHeader."Currency Factor";

                        if not Currency.Get(FromSalesHeader."Currency Code") then begin
                            CurrencyFactor := 1;
                            Currency.InitRoundingPrecision;
                        end;

                        QtyToAssign := ValueEntry."Cost Amount (Actual)" * CurrencyFactor / ToSalesLine."Unit Price";
                        SumQtyToAssign += QtyToAssign;

                        ItemChargeAssgntSales.InsertItemChargeAssgntWithAssignValuesTo(
                          ToItemChargeAssignmentSales, ToItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
                          ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.", ItemLedgerEntry."Item No.", Item.Description,
                          QtyToAssign, 0, ItemChargeAssgntNextLineNo, TempToItemChargeAssignmentSales);
                    end;
                OnCopyFromSalesLineItemChargeAssignOnAfterValueEntryLoop(
                    FromSalesHeader, ToSalesLine, ValueEntry, TempToItemChargeAssignmentSales, ToItemChargeAssignmentSales,
                    ItemChargeAssgntNextLineNo, SumQtyToAssign);
            until ValueEntry.Next = 0;
            ItemChargeAssgntSales.Summarize(TempToItemChargeAssignmentSales, ToItemChargeAssignmentSales);

            // Use 2 passes to correct rounding issues
            ToItemChargeAssignmentSales.SetRange("Document Type", ToSalesLine."Document Type");
            ToItemChargeAssignmentSales.SetRange("Document No.", ToSalesLine."Document No.");
            ToItemChargeAssignmentSales.SetRange("Document Line No.", ToSalesLine."Line No.");
            if ToItemChargeAssignmentSales.FindSet(true) then begin
                RemainingQty := (FromSalesLine.Quantity - SumQtyToAssign) / ValueEntry.Count();
                SumQtyToAssign := 0;
                repeat
                    AddRemainingQtyToSalesItemCharge(ToItemChargeAssignmentSales, RemainingQty);
                    SumQtyToAssign += ToItemChargeAssignmentSales."Qty. to Assign";
                until ToItemChargeAssignmentSales.Next = 0;

                RemainingQty := FromSalesLine.Quantity - SumQtyToAssign;
                if RemainingQty <> 0 then
                    AddRemainingQtyToSalesItemCharge(ToItemChargeAssignmentSales, RemainingQty);
            end;
        end;
    end;

    local procedure AddRemainingQtyToPurchItemCharge(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; RemainingQty: Decimal)
    begin
        ItemChargeAssignmentPurch.Validate(
          "Qty. to Assign", Round(ItemChargeAssignmentPurch."Qty. to Assign" + RemainingQty, UOMMgt.QtyRndPrecision));
        ItemChargeAssignmentPurch.Modify(true);
    end;

    local procedure AddRemainingQtyToSalesItemCharge(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; RemainingQty: Decimal)
    begin
        ItemChargeAssignmentSales.Validate(
          "Qty. to Assign", Round(ItemChargeAssignmentSales."Qty. to Assign" + RemainingQty, UOMMgt.QtyRndPrecision));
        ItemChargeAssignmentSales.Modify(true);
    end;

    local procedure WarnSalesInvoicePmtDisc(var ToSalesHeader: Record "Sales Header"; var FromSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if HideDialog then
            exit;

        if IncludeHeader and
           (ToSalesHeader."Document Type" in
            [ToSalesHeader."Document Type"::"Return Order", ToSalesHeader."Document Type"::"Credit Memo"])
        then begin
            CustLedgEntry.SetCurrentKey("Document No.");
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            CustLedgEntry.SetRange("Document No.", FromDocNo);
            if CustLedgEntry.FindFirst then begin
                if (CustLedgEntry."Pmt. Disc. Given (LCY)" <> 0) and
                   (CustLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text006, SelectStr(FromDocType, Text007), FromDocNo);
            end;
        end;

        if IncludeHeader and
           (ToSalesHeader."Document Type" in
            [ToSalesHeader."Document Type"::Invoice, ToSalesHeader."Document Type"::Order,
             ToSalesHeader."Document Type"::Quote, ToSalesHeader."Document Type"::"Blanket Order"]) and
           (FromDocType = 9)
        then begin
            CustLedgEntry.SetCurrentKey("Document No.");
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
            CustLedgEntry.SetRange("Document No.", FromDocNo);
            if CustLedgEntry.FindFirst then begin
                if (CustLedgEntry."Pmt. Disc. Given (LCY)" <> 0) and
                   (CustLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text006, SelectStr(FromDocType - 1, Text007), FromDocNo);
            end;
        end;
    end;

    local procedure WarnPurchInvoicePmtDisc(var ToPurchHeader: Record "Purchase Header"; var FromPurchHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if HideDialog then
            exit;

        if IncludeHeader and
           (ToPurchHeader."Document Type" in
            [ToPurchHeader."Document Type"::"Return Order", ToPurchHeader."Document Type"::"Credit Memo"])
        then begin
            VendLedgEntry.SetCurrentKey("Document No.");
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
            VendLedgEntry.SetRange("Document No.", FromDocNo);
            if VendLedgEntry.FindFirst then begin
                if (VendLedgEntry."Pmt. Disc. Rcd.(LCY)" <> 0) and
                   (VendLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text009, SelectStr(FromDocType, Text007), FromDocNo);
            end;
        end;

        if IncludeHeader and
           (ToPurchHeader."Document Type" in
            [ToPurchHeader."Document Type"::Invoice, ToPurchHeader."Document Type"::Order,
             ToPurchHeader."Document Type"::Quote, ToPurchHeader."Document Type"::"Blanket Order"]) and
           (FromDocType = 9)
        then begin
            VendLedgEntry.SetCurrentKey("Document No.");
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
            VendLedgEntry.SetRange("Document No.", FromDocNo);
            if VendLedgEntry.FindFirst then begin
                if (VendLedgEntry."Pmt. Disc. Rcd.(LCY)" <> 0) and
                   (VendLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text006, SelectStr(FromDocType - 1, Text007), FromDocNo);
            end;
        end;
    end;

    local procedure CheckCopyFromSalesHeaderAvail(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
    begin
        with ToSalesHeader do
            if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
                FromSalesLine.SetRange("Document Type", FromSalesHeader."Document Type");
                FromSalesLine.SetRange("Document No.", FromSalesHeader."No.");
                FromSalesLine.SetRange(Type, FromSalesLine.Type::Item);
                FromSalesLine.SetFilter("No.", '<>%1', '');
                FromSalesLine.SetFilter(Quantity, '>0');
                if FromSalesLine.FindSet then
                    repeat
                        if not IsItemBlocked(FromSalesLine."No.") then begin
                            ToSalesLine.CopyFromSalesLine(FromSalesLine);
                            if "Document Type" = "Document Type"::Order then
                                ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity - FromSalesLine."Qty. to Assemble to Order";
                            CheckItemAvailability(ToSalesHeader, ToSalesLine);
                            OnCheckCopyFromSalesHeaderAvailOnAfterCheckItemAvailability(
                              ToSalesHeader, ToSalesLine, FromSalesHeader, IncludeHeader, FromSalesLine);

                            if "Document Type" = "Document Type"::Order then begin
                                ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity;
                                if "Document Type" = "Document Type"::Order then
                                    ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity - FromSalesLine."Qty. to Assemble to Order";
                                ToSalesLine."Qty. to Assemble to Order" := 0;
                                ToSalesLine."Drop Shipment" := FromSalesLine."Drop Shipment";
                                CheckItemAvailability(ToSalesHeader, ToSalesLine);

                                if "Document Type" = "Document Type"::Order then begin
                                    ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity;
                                    ToSalesLine."Qty. to Assemble to Order" := FromSalesLine."Qty. to Assemble to Order";
                                    CheckATOItemAvailable(FromSalesLine, ToSalesLine);
                                end;
                            end;
                        end;
                    until FromSalesLine.Next = 0;
            end;
    end;

    local procedure CheckCopyFromSalesShptAvail(FromSalesShptHeader: Record "Sales Shipment Header"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesShptLine: Record "Sales Shipment Line";
        ToSalesLine: Record "Sales Line";
        FromPostedAsmHeader: Record "Posted Assembly Header";
    begin
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        with ToSalesLine do begin
            FromSalesShptLine.SetRange("Document No.", FromSalesShptHeader."No.");
            FromSalesShptLine.SetRange(Type, FromSalesShptLine.Type::Item);
            FromSalesShptLine.SetFilter("No.", '<>%1', '');
            FromSalesShptLine.SetFilter(Quantity, '>0');
            if FromSalesShptLine.FindSet then
                repeat
                    if not IsItemBlocked(FromSalesShptLine."No.") then begin
                        CopyFromSalesShptLine(FromSalesShptLine);
                        if "Document Type" = "Document Type"::Order then
                            if FromSalesShptLine.AsmToShipmentExists(FromPostedAsmHeader) then
                                "Outstanding Quantity" := FromSalesShptLine.Quantity - FromPostedAsmHeader.Quantity;
                        CheckItemAvailability(ToSalesHeader, ToSalesLine);
                        OnCheckCopyFromSalesShptAvailOnAfterCheckItemAvailability(
                          ToSalesHeader, ToSalesLine, FromSalesShptHeader, IncludeHeader, FromSalesShptLine);

                        if "Document Type" = "Document Type"::Order then
                            if FromSalesShptLine.AsmToShipmentExists(FromPostedAsmHeader) then begin
                                "Qty. to Assemble to Order" := FromPostedAsmHeader.Quantity;
                                CheckPostedATOItemAvailable(FromSalesShptLine, ToSalesLine);
                            end;
                    end;
                until FromSalesShptLine.Next = 0;
        end;
    end;

    local procedure CheckCopyFromSalesInvoiceAvail(FromSalesInvHeader: Record "Sales Invoice Header"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesInvLine: Record "Sales Invoice Line";
        ToSalesLine: Record "Sales Line";
    begin
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        with ToSalesLine do begin
            FromSalesInvLine.SetRange("Document No.", FromSalesInvHeader."No.");
            FromSalesInvLine.SetRange(Type, FromSalesInvLine.Type::Item);
            FromSalesInvLine.SetFilter("No.", '<>%1', '');
            FromSalesInvLine.SetRange("Prepayment Line", false);
            FromSalesInvLine.SetFilter(Quantity, '>0');
            if FromSalesInvLine.FindSet then
                repeat
                    if not IsItemBlocked(FromSalesInvLine."No.") then begin
                        CopyFromSalesInvLine(FromSalesInvLine);
                        CheckItemAvailability(ToSalesHeader, ToSalesLine);
                        OnCheckCopyFromSalesInvoiceAvailOnAfterCheckItemAvailability(
                          ToSalesHeader, ToSalesLine, FromSalesInvHeader, IncludeHeader, FromSalesInvLine);
                    end;
                until FromSalesInvLine.Next = 0;
        end;
    end;

    local procedure CheckCopyFromSalesRetRcptAvail(FromReturnRcptHeader: Record "Return Receipt Header"; ToSalesHeader: Record "Sales Header")
    var
        FromReturnRcptLine: Record "Return Receipt Line";
        ToSalesLine: Record "Sales Line";
    begin
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        with ToSalesLine do begin
            FromReturnRcptLine.SetRange("Document No.", FromReturnRcptHeader."No.");
            FromReturnRcptLine.SetRange(Type, FromReturnRcptLine.Type::Item);
            FromReturnRcptLine.SetFilter("No.", '<>%1', '');
            FromReturnRcptLine.SetFilter(Quantity, '>0');
            if FromReturnRcptLine.FindSet then
                repeat
                    if not IsItemBlocked(FromReturnRcptLine."No.") then begin
                        CopyFromReturnRcptLine(FromReturnRcptLine);
                        CheckItemAvailability(ToSalesHeader, ToSalesLine);
                        OnCheckCopyFromSalesRetRcptAvailOnAfterCheckItemAvailability(
                          ToSalesHeader, ToSalesLine, FromReturnRcptHeader, IncludeHeader, FromReturnRcptLine);
                    end;
                until FromReturnRcptLine.Next = 0;
        end;
    end;

    local procedure CheckCopyFromSalesCrMemoAvail(FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ToSalesLine: Record "Sales Line";
    begin
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        with ToSalesLine do begin
            FromSalesCrMemoLine.SetRange("Document No.", FromSalesCrMemoHeader."No.");
            FromSalesCrMemoLine.SetRange(Type, FromSalesCrMemoLine.Type::Item);
            FromSalesCrMemoLine.SetFilter("No.", '<>%1', '');
            FromSalesCrMemoLine.SetRange("Prepayment Line", false);
            FromSalesCrMemoLine.SetFilter(Quantity, '>0');
            if FromSalesCrMemoLine.FindSet then
                repeat
                    if not IsItemBlocked(FromSalesCrMemoLine."No.") then begin
                        CopyFromSalesCrMemoLine(FromSalesCrMemoLine);
                        CheckItemAvailability(ToSalesHeader, ToSalesLine);
                        OnCheckCopyFromSalesCrMemoAvailOnAfterCheckItemAvailability(
                          ToSalesHeader, ToSalesLine, FromSalesCrMemoHeader, IncludeHeader, FromSalesCrMemoLine);
                    end;
                until FromSalesCrMemoLine.Next = 0;
        end;
    end;

    local procedure CheckCopyFromSalesHeaderArchiveAvail(FromSalesHeaderArchive: Record "Sales Header Archive"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesLineArchive: Record "Sales Line Archive";
        ToSalesLine: Record "Sales Line";
    begin
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        FromSalesLineArchive.SetRange("Document Type", FromSalesHeaderArchive."Document Type");
        FromSalesLineArchive.SetRange("Document No.", FromSalesHeaderArchive."No.");
        FromSalesLineArchive.SetRange("Doc. No. Occurrence", FromSalesHeaderArchive."Doc. No. Occurrence");
        FromSalesLineArchive.SetRange("Version No.", FromSalesHeaderArchive."Version No.");
        FromSalesLineArchive.SetRange(Type, FromSalesLineArchive.Type::Item);
        FromSalesLineArchive.SetFilter("No.", '<>%1', '');
        if FromSalesLineArchive.FindSet() then
            repeat
                if FromSalesLineArchive.Quantity > 0 then begin
                    ToSalesLine."No." := FromSalesLineArchive."No.";
                    ToSalesLine."Variant Code" := FromSalesLineArchive."Variant Code";
                    ToSalesLine."Location Code" := FromSalesLineArchive."Location Code";
                    ToSalesLine."Bin Code" := FromSalesLineArchive."Bin Code";
                    ToSalesLine."Unit of Measure Code" := FromSalesLineArchive."Unit of Measure Code";
                    ToSalesLine."Qty. per Unit of Measure" := FromSalesLineArchive."Qty. per Unit of Measure";
                    ToSalesLine."Outstanding Quantity" := FromSalesLineArchive.Quantity;
                    CheckItemAvailability(ToSalesHeader, ToSalesLine);
                    OnCheckCopyFromSalesHeaderArchiveAvailOnAfterCheckItemAvailability(ToSalesHeader, ToSalesLine,
                    FromSalesHeaderArchive, FromSalesLineArchive, IncludeHeader);
                end;
            until FromSalesLineArchive.Next() = 0;
    end;

    local procedure CheckItemAvailability(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckItemAvailability(ToSalesHeader, ToSalesLine, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if HideDialog then
            exit;

        ToSalesLine."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine."Document No." := ToSalesHeader."No.";
        ToSalesLine.Type := ToSalesLine.Type::Item;
        ToSalesLine."Purchase Order No." := '';
        ToSalesLine."Purch. Order Line No." := 0;
        ToSalesLine."Drop Shipment" :=
          not RecalculateLines and ToSalesLine."Drop Shipment" and
          (ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Order);

        SetShipmentDateInLine(ToSalesHeader, ToSalesLine);

        if ItemCheckAvail.SalesLineCheck(ToSalesLine) then
            ItemCheckAvail.RaiseUpdateInterruptedError;
    end;

    local procedure InitShipmentDateInLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        if SalesHeader."Shipment Date" <> 0D then
            SalesLine."Shipment Date" := SalesHeader."Shipment Date"
        else
            SalesLine."Shipment Date" := WorkDate;
    end;

    local procedure SetShipmentDateInLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        OnBeforeSetShipmentDateInLine(SalesHeader, SalesLine);
        if SalesLine."Shipment Date" = 0D then begin
            InitShipmentDateInLine(SalesHeader, SalesLine);
            SalesLine.Validate("Shipment Date");
        end;
    end;

    local procedure CheckATOItemAvailable(var FromSalesLine: Record "Sales Line"; ToSalesLine: Record "Sales Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
        AsmHeader: Record "Assembly Header";
        TempAsmHeader: Record "Assembly Header" temporary;
        TempAsmLine: Record "Assembly Line" temporary;
    begin
        if HideDialog then
            exit;

        if ATOLink.ATOCopyCheckAvailShowWarning(
             AsmHeader, ToSalesLine, TempAsmHeader, TempAsmLine,
             not FromSalesLine.AsmToOrderExists(AsmHeader))
        then
            if ItemCheckAvail.ShowAsmWarningYesNo(TempAsmHeader, TempAsmLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError;
    end;

    local procedure CheckPostedATOItemAvailable(var FromSalesShptLine: Record "Sales Shipment Line"; ToSalesLine: Record "Sales Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
        PostedAsmHeader: Record "Posted Assembly Header";
        TempAsmHeader: Record "Assembly Header" temporary;
        TempAsmLine: Record "Assembly Line" temporary;
    begin
        if HideDialog then
            exit;

        if ATOLink.PstdATOCopyCheckAvailShowWarn(
             PostedAsmHeader, ToSalesLine, TempAsmHeader, TempAsmLine,
             not FromSalesShptLine.AsmToShipmentExists(PostedAsmHeader))
        then
            if ItemCheckAvail.ShowAsmWarningYesNo(TempAsmHeader, TempAsmLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError;
    end;

    procedure CopyServContractLines(ToServContractHeader: Record "Service Contract Header"; FromDocType: Option; FromDocNo: Code[20]; var FromServContractLine: Record "Service Contract Line") AllLinesCopied: Boolean
    var
        ExistingServContractLine: Record "Service Contract Line";
        LineNo: Integer;
    begin
        if FromDocNo = '' then
            Error(Text000);

        ExistingServContractLine.LockTable();
        ExistingServContractLine.Reset();
        ExistingServContractLine.SetRange("Contract Type", ToServContractHeader."Contract Type");
        ExistingServContractLine.SetRange("Contract No.", ToServContractHeader."Contract No.");
        if ExistingServContractLine.FindLast then
            LineNo := ExistingServContractLine."Line No." + 10000
        else
            LineNo := 10000;

        AllLinesCopied := true;
        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromDocType);
        FromServContractLine.SetRange("Contract No.", FromDocNo);
        if FromServContractLine.Find('-') then
            repeat
                if not ProcessServContractLine(
                     ToServContractHeader,
                     FromServContractLine,
                     LineNo)
                then begin
                    AllLinesCopied := false;
                    FromServContractLine.Mark(true)
                end else
                    LineNo := LineNo + 10000
            until FromServContractLine.Next = 0;

        OnAfterCopyServContractLines(ToServContractHeader, FromDocType, FromDocNo, FromServContractLine);
    end;

    procedure ServContractHeaderDocType(DocType: Option): Integer
    var
        ServContractHeader: Record "Service Contract Header";
    begin
        case DocType of
            ServDocType::Quote:
                exit(ServContractHeader."Contract Type"::Quote);
            ServDocType::Contract:
                exit(ServContractHeader."Contract Type"::Contract);
        end;
    end;

    local procedure ProcessServContractLine(ToServContractHeader: Record "Service Contract Header"; var FromServContractLine: Record "Service Contract Line"; LineNo: Integer): Boolean
    var
        ToServContractLine: Record "Service Contract Line";
        ExistingServContractLine: Record "Service Contract Line";
        ServItem: Record "Service Item";
    begin
        if FromServContractLine."Service Item No." <> '' then begin
            ServItem.Get(FromServContractLine."Service Item No.");
            if ServItem."Customer No." <> ToServContractHeader."Customer No." then
                exit(false);

            ExistingServContractLine.Reset();
            ExistingServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
            ExistingServContractLine.SetRange("Service Item No.", FromServContractLine."Service Item No.");
            ExistingServContractLine.SetRange("Contract Type", ToServContractHeader."Contract Type");
            ExistingServContractLine.SetRange("Contract No.", ToServContractHeader."Contract No.");
            if not ExistingServContractLine.IsEmpty then
                exit(false);
        end;

        ToServContractLine := FromServContractLine;
        ToServContractLine."Last Planned Service Date" := 0D;
        ToServContractLine."Last Service Date" := 0D;
        ToServContractLine."Last Preventive Maint. Date" := 0D;
        ToServContractLine."Invoiced to Date" := 0D;
        ToServContractLine."Contract Type" := ToServContractHeader."Contract Type";
        ToServContractLine."Contract No." := ToServContractHeader."Contract No.";
        ToServContractLine."Line No." := LineNo;
        ToServContractLine."New Line" := true;
        ToServContractLine.Credited := false;
        ToServContractLine.SetupNewLine;
        ToServContractLine.Insert(true);

        OnAfterProcessServContractLine(ToServContractLine, FromServContractLine);
        exit(true);
    end;

    procedure CopySalesShptLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesShptLine: Record "Sales Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromSalesShptHeader: Record "Sales Shipment Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocSalesLine: Record "Sales Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToSalesHeader."Currency Code");
        OpenWindow;

        OnBeforeCopySalesShptLinesToDoc(TempDocSalesLine, ToSalesHeader, FromSalesShptLine);

        with FromSalesShptLine do
            if FindSet then
                repeat
                    FromLineCounter := FromLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(1, FromLineCounter);
                    if FromSalesShptHeader."No." <> "Document No." then begin
                        FromSalesShptHeader.Get("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    end;
                    FromSalesShptHeader.TestField("Prices Including VAT", ToSalesHeader."Prices Including VAT");
                    FromSalesHeader.TransferFields(FromSalesShptHeader);
                    FillExactCostRevLink :=
                      IsSalesFillExactCostRevLink(ToSalesHeader, 0, FromSalesHeader."Currency Code");
                    FromSalesLine.TransferFields(FromSalesShptLine);
                    FromSalesLine."Appl.-from Item Entry" := 0;
                    FromSalesLine."Copied From Posted Doc." := true;

                    if "Document No." <> OldDocNo then begin
                        OldDocNo := "Document No.";
                        InsertDocNoLine := true;
                    end;

                    OnBeforeCopySalesShptLinesToBuffer(FromSalesLine, FromSalesShptLine, ToSalesHeader);

                    SplitLine := true;
                    FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                    if not SplitPstdSalesLinesPerILE(
                         ToSalesHeader, FromSalesHeader, ItemLedgEntry, FromSalesLineBuf,
                         FromSalesLine, TempDocSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                    then
                        if CopyItemTrkg then
                            SplitLine :=
                              SplitSalesDocLinesPerItemTrkg(
                                ItemLedgEntry, TempItemTrkgEntry, FromSalesLineBuf,
                                FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                        else
                            SplitLine := false;

                    if not SplitLine then begin
                        FromSalesLineBuf := FromSalesLine;
                        CopyLine := true;
                    end else
                        CopyLine := FromSalesLineBuf.FindSet and FillExactCostRevLink;

                    Window.Update(1, FromLineCounter);
                    if CopyLine then begin
                        NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                        AsmHdrExistsForFromDocLine := AsmToShipmentExists(PostedAsmHeader);
                        InitAsmCopyHandling(true);
                        if AsmHdrExistsForFromDocLine then begin
                            QtyToAsmToOrder := Quantity;
                            QtyToAsmToOrderBase := "Quantity (Base)";
                            GenerateAsmDataFromPosted(PostedAsmHeader, ToSalesHeader."Document Type");
                        end;
                        if InsertDocNoLine then begin
                            InsertOldSalesDocNoLine(ToSalesHeader, "Document No.", 1, NextLineNo);
                            InsertDocNoLine := false;
                        end;
                        repeat
                            ToLineCounter := ToLineCounter + 1;
                            if IsTimeForUpdate then
                                Window.Update(2, ToLineCounter);

                            OnCopySalesShptLinesToDocOnBeforeCopySalesLine(ToSalesHeader, FromSalesLineBuf);

                            if CopySalesLine(
                                 ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLineBuf, NextLineNo, LinesNotCopied,
                                 false, DeferralTypeForSalesDoc(SalesDocType::"Posted Shipment"), CopyPostedDeferral,
                                 FromSalesLineBuf."Line No.")
                            then begin
                                if CopyItemTrkg then begin
                                    if SplitLine then
                                        ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                          TempItemTrkgEntry, TempTrkgItemLedgEntry, false, FromSalesLineBuf."Document No.", FromSalesLineBuf."Line No.")
                                    else
                                        ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                                    ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                      TempTrkgItemLedgEntry, ToSalesLine,
                                      FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                      FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", true);
                                end;
                                OnAfterCopySalesLineFromSalesShptLineBuffer(
                                  ToSalesLine, FromSalesShptLine, IncludeHeader, RecalculateLines, TempDocSalesLine, ToSalesHeader, FromSalesLineBuf);
                            end;
                        until FromSalesLineBuf.Next = 0;
                    end;
                until Next = 0;

        Window.Close;
    end;

    procedure CopySalesInvLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesInvLine: Record "Sales Invoice Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        FromSalesLine2: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        TempSalesLineBuf: Record "Sales Line" temporary;
        FromSalesInvHeader: Record "Sales Invoice Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocSalesLine: Record "Sales Line" temporary;
        OldInvDocNo: Code[20];
        OldShptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        SalesCombDocLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        SalesInvLineCount: Integer;
        SalesLineCount: Integer;
        BufferCount: Integer;
        FirstLineShipped: Boolean;
        FirstLineText: Boolean;
        ItemChargeAssgntNextLineNo: Integer;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToSalesHeader."Currency Code");
        TempSalesLineBuf.Reset();
        TempSalesLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow;
        InitAsmCopyHandling(true);
        TempSalesInvLine.DeleteAll();

        OnBeforeCopySalesInvLines(TempDocSalesLine, ToSalesHeader, FromSalesInvLine, CopyJobData);

        // Fill sales line buffer
        SalesInvLineCount := 0;
        FirstLineText := false;
        with FromSalesInvLine do
            if FindSet then
                repeat
                    FromLineCounter := FromLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(1, FromLineCounter);
                    SetTempSalesInvLine(FromSalesInvLine, TempSalesInvLine, SalesInvLineCount, NextLineNo, FirstLineText);
                    if FromSalesInvHeader."No." <> "Document No." then begin
                        FromSalesInvHeader.Get("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                        OnCopySalesInvLinesToDocOnAfterGetFromSalesInvHeader(ToSalesHeader, FromSalesInvHeader);
                    end;
                    FromSalesInvHeader.TestField("Prices Including VAT", ToSalesHeader."Prices Including VAT");
                    FromSalesHeader.TransferFields(FromSalesInvHeader);
                    OnCopySalesInvLinesToDocOnAfterFromSalesHeaderTransferFields(FromSalesHeader, FromSalesInvHeader);
                    FillExactCostRevLink := IsSalesFillExactCostRevLink(ToSalesHeader, 1, FromSalesHeader."Currency Code");
                    FromSalesLine.TransferFields(FromSalesInvLine);
                    FromSalesLine."Appl.-from Item Entry" := 0;
                    // Reuse fields to buffer invoice line information
                    FromSalesLine."Shipment No." := "Document No.";
                    FromSalesLine."Shipment Line No." := 0;
                    FromSalesLine."Return Receipt No." := '';
                    FromSalesLine."Return Receipt Line No." := "Line No.";
                    FromSalesLine."Copied From Posted Doc." := true;

                    OnBeforeCopySalesInvLinesToBuffer(FromSalesLine, FromSalesInvLine, ToSalesHeader);

                    SplitLine := true;
                    GetItemLedgEntries(ItemLedgEntryBuf, true);
                    if not SplitPstdSalesLinesPerILE(
                         ToSalesHeader, FromSalesHeader, ItemLedgEntryBuf, TempSalesLineBuf,
                         FromSalesLine, TempDocSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                    then
                        if CopyItemTrkg then
                            SplitLine := SplitSalesDocLinesPerItemTrkg(
                                ItemLedgEntryBuf, TempItemTrkgEntry, TempSalesLineBuf,
                                FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                        else
                            SplitLine := false;

                    if not SplitLine then
                        CopySalesLinesToBuffer(
                          FromSalesHeader, FromSalesLine, FromSalesLine2, TempSalesLineBuf,
                          ToSalesHeader, TempDocSalesLine, "Document No.", NextLineNo);

                    OnAfterCopySalesInvLine(TempDocSalesLine, ToSalesHeader, TempSalesLineBuf, FromSalesInvLine);
                until Next = 0;

        // Create sales line from buffer
        Window.Update(1, FromLineCounter);
        BufferCount := 0;
        FirstLineShipped := true;
        with TempSalesLineBuf do begin
            // Sorting according to Sales Line Document No.,Line No.
            SetCurrentKey("Document Type", "Document No.", "Line No.");
            SalesLineCount := 0;
            if FindSet then
                repeat
                    if Type = Type::Item then
                        SalesLineCount += 1;
                until Next = 0;
            if FindSet then begin
                NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                repeat
                    ToLineCounter := ToLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(2, ToLineCounter);
                    if "Shipment No." <> OldInvDocNo then begin
                        OldInvDocNo := "Shipment No.";
                        OldShptDocNo := '';
                        FirstLineShipped := true;
                        OnCopySalesInvLinesToDocOnBeforeInsertOldSalesDocNoLine(ToSalesHeader, SkipCopyFromDescription);
                        InsertOldSalesDocNoLine(ToSalesHeader, OldInvDocNo, 2, NextLineNo);
                        OnCopySalesInvLinesToDocOnAfterInsertOldSalesDocNoLine(ToSalesHeader, SkipCopyFromDescription);
                    end;
                    CheckFirstLineShipped("Document No.", "Shipment Line No.", SalesCombDocLineNo, NextLineNo, FirstLineShipped);
                    if ("Document No." <> OldShptDocNo) and ("Shipment Line No." > 0) then begin
                        if FirstLineShipped then
                            SalesCombDocLineNo := NextLineNo;
                        OldShptDocNo := "Document No.";
                        InsertOldSalesCombDocNoLine(ToSalesHeader, OldInvDocNo, OldShptDocNo, SalesCombDocLineNo, true);
                        NextLineNo := NextLineNo + 10000;
                        FirstLineShipped := true;
                    end;

                    InitFromSalesLine(FromSalesLine2, TempSalesLineBuf);
                    if GetSalesDocNo(TempDocSalesLine, "Line No.") <> OldBufDocNo then begin
                        OldBufDocNo := GetSalesDocNo(TempDocSalesLine, "Line No.");
                        TransferOldExtLines.ClearLineNumbers;
                    end;

                    OnCopySalesInvLinesToDocOnBeforeCopySalesLine(ToSalesHeader, FromSalesLine2);

                    AsmHdrExistsForFromDocLine := false;
                    if Type = Type::Item then
                        CheckAsmHdrExistsForFromDocLine(ToSalesHeader, FromSalesLine2, BufferCount, SalesLineCount = SalesInvLineCount);

                    if CopySalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine2, NextLineNo, LinesNotCopied,
                         "Return Receipt No." = '', DeferralTypeForSalesDoc(SalesDocType::"Posted Invoice"), CopyPostedDeferral,
                         GetSalesLineNo(TempDocSalesLine, FromSalesLine2."Line No."))
                    then begin
                        if CopyPostedDeferral then
                            CopySalesPostedDeferrals(ToSalesLine, DeferralUtilities.GetSalesDeferralDocType,
                              DeferralTypeForSalesDoc(SalesDocType::"Posted Invoice"), "Shipment No.", "Return Receipt Line No.",
                              ToSalesLine."Document Type", ToSalesLine."Document No.", ToSalesLine."Line No.");
                        FromSalesInvLine.Get("Shipment No.", "Return Receipt Line No.");

                        // copy item charges
                        if Type = Type::"Charge (Item)" then begin
                            FromSalesLine.TransferFields(FromSalesInvLine);
                            FromSalesLine."Document Type" := FromSalesLine."Document Type"::Invoice;
                            CopyFromSalesLineItemChargeAssign(FromSalesLine, ToSalesLine, FromSalesHeader, ItemChargeAssgntNextLineNo);
                        end;

                        // copy item tracking
                        if (Type = Type::Item) and (Quantity <> 0) and SalesDocCanReceiveTracking(ToSalesHeader) then begin
                            FromSalesInvLine."Document No." := OldInvDocNo;
                            FromSalesInvLine."Line No." := "Return Receipt Line No.";
                            FromSalesInvLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                            if IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then
                                CopyItemLedgEntryTrackingToSalesLine(
                                  ItemLedgEntryBuf, TempItemTrkgEntry, TempSalesLineBuf, ToSalesLine, ToSalesHeader."Prices Including VAT",
                                  FromSalesHeader."Prices Including VAT", FillExactCostRevLink, MissingExCostRevLink);
                        end;

                        OnAfterCopySalesLineFromSalesLineBuffer(
                          ToSalesLine, FromSalesInvLine, IncludeHeader, RecalculateLines, TempDocSalesLine, ToSalesHeader, TempSalesLineBuf,
                          FromSalesLine2);
                    end;
                until Next = 0;
            end;
        end;
        Window.Close;
    end;

    procedure CopySalesCrMemoLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        FromSalesLine2: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocSalesLine: Record "Sales Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldCrMemoDocNo: Code[20];
        OldReturnRcptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        ItemChargeAssgntNextLineNo: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToSalesHeader."Currency Code");
        FromSalesLineBuf.Reset();
        FromSalesLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow;

        OnBeforeCopySalesCrMemoLinesToDoc(TempDocSalesLine, ToSalesHeader, FromSalesCrMemoLine, CopyJobData);

        // Fill sales line buffer
        with FromSalesCrMemoLine do
            if FindSet then
                repeat
                    FromLineCounter := FromLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(1, FromLineCounter);
                    if FromSalesCrMemoHeader."No." <> "Document No." then begin
                        FromSalesCrMemoHeader.Get("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    end;
                    FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                    FillExactCostRevLink :=
                      IsSalesFillExactCostRevLink(ToSalesHeader, 3, FromSalesHeader."Currency Code");
                    FromSalesLine.TransferFields(FromSalesCrMemoLine);
                    FromSalesLine."Appl.-from Item Entry" := 0;
                    // Reuse fields to buffer credit memo line information
                    FromSalesLine."Shipment No." := "Document No.";
                    FromSalesLine."Shipment Line No." := 0;
                    FromSalesLine."Return Receipt No." := '';
                    FromSalesLine."Return Receipt Line No." := "Line No.";
                    FromSalesLine."Copied From Posted Doc." := true;

                    OnBeforeCopySalesCrMemoLinesToBuffer(FromSalesLine, FromSalesCrMemoLine, ToSalesHeader);

                    SplitLine := true;
                    GetItemLedgEntries(ItemLedgEntryBuf, true);
                    if not SplitPstdSalesLinesPerILE(
                         ToSalesHeader, FromSalesHeader, ItemLedgEntryBuf, FromSalesLineBuf,
                         FromSalesLine, TempDocSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                    then
                        if CopyItemTrkg then
                            SplitLine :=
                              SplitSalesDocLinesPerItemTrkg(
                                ItemLedgEntryBuf, TempItemTrkgEntry, FromSalesLineBuf,
                                FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                        else
                            SplitLine := false;

                    if not SplitLine then
                        CopySalesLinesToBuffer(
                          FromSalesHeader, FromSalesLine, FromSalesLine2, FromSalesLineBuf,
                          ToSalesHeader, TempDocSalesLine, "Document No.", NextLineNo);
                until Next = 0;

        // Create sales line from buffer
        Window.Update(1, FromLineCounter);
        with FromSalesLineBuf do begin
            // Sorting according to Sales Line Document No.,Line No.
            SetCurrentKey("Document Type", "Document No.", "Line No.");
            if FindSet then begin
                NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                repeat
                    ToLineCounter := ToLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(2, ToLineCounter);
                    if "Shipment No." <> OldCrMemoDocNo then begin
                        OldCrMemoDocNo := "Shipment No.";
                        OldReturnRcptDocNo := '';
                        InsertOldSalesDocNoLine(ToSalesHeader, OldCrMemoDocNo, 4, NextLineNo);
                    end;
                    if ("Document No." <> OldReturnRcptDocNo) and ("Shipment Line No." > 0) then begin
                        OldReturnRcptDocNo := "Document No.";
                        InsertOldSalesCombDocNoLine(ToSalesHeader, OldCrMemoDocNo, OldReturnRcptDocNo, NextLineNo, false);
                    end;

                    // Empty buffer fields
                    FromSalesLine2 := FromSalesLineBuf;
                    FromSalesLine2."Shipment No." := '';
                    FromSalesLine2."Shipment Line No." := 0;
                    FromSalesLine2."Return Receipt No." := '';
                    FromSalesLine2."Return Receipt Line No." := 0;
                    if GetSalesDocNo(TempDocSalesLine, "Line No.") <> OldBufDocNo then begin
                        OldBufDocNo := GetSalesDocNo(TempDocSalesLine, "Line No.");
                        TransferOldExtLines.ClearLineNumbers;
                    end;

                    OnCopySalesCrMemoLinesToDocOnBeforeCopySalesLine(ToSalesHeader, FromSalesLine2);

                    if CopySalesLine(
                         ToSalesHeader, ToSalesLine, FromSalesHeader,
                         FromSalesLine2, NextLineNo, LinesNotCopied, "Return Receipt No." = '',
                         DeferralTypeForSalesDoc(SalesDocType::"Posted Credit Memo"), CopyPostedDeferral,
                         GetSalesLineNo(TempDocSalesLine, FromSalesLine2."Line No."))
                    then begin
                        if CopyPostedDeferral then
                            CopySalesPostedDeferrals(ToSalesLine, DeferralUtilities.GetSalesDeferralDocType,
                              DeferralTypeForSalesDoc(SalesDocType::"Posted Credit Memo"), "Shipment No.",
                              "Return Receipt Line No.", ToSalesLine."Document Type", ToSalesLine."Document No.", ToSalesLine."Line No.");
                        FromSalesCrMemoLine.Get("Shipment No.", "Return Receipt Line No.");

                        // copy item charges
                        if Type = Type::"Charge (Item)" then begin
                            FromSalesLine.TransferFields(FromSalesCrMemoLine);
                            FromSalesLine."Document Type" := FromSalesLine."Document Type"::"Credit Memo";
                            CopyFromSalesLineItemChargeAssign(FromSalesLine, ToSalesLine, FromSalesHeader, ItemChargeAssgntNextLineNo);
                        end;
                        // copy item tracking
                        if (Type = Type::Item) and (Quantity <> 0) then begin
                            FromSalesCrMemoLine."Document No." := OldCrMemoDocNo;
                            FromSalesCrMemoLine."Line No." := "Return Receipt Line No.";
                            FromSalesCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                            if IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then begin
                                if MoveNegLines or not ExactCostRevMandatory then
                                    ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                                else
                                    ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                      TempItemTrkgEntry, TempTrkgItemLedgEntry, false, "Document No.", "Line No.");

                                ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                  TempTrkgItemLedgEntry, ToSalesLine,
                                  FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                  FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", false);
                            end;
                        end;
                        OnAfterCopySalesLineFromSalesCrMemoLineBuffer(
                          ToSalesLine, FromSalesCrMemoLine, IncludeHeader, RecalculateLines, TempDocSalesLine, ToSalesHeader, FromSalesLineBuf);
                    end;
                until Next = 0;
            end;
        end;

        Window.Close;
    end;

    procedure CopySalesReturnRcptLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromReturnRcptLine: Record "Return Receipt Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromReturnRcptHeader: Record "Return Receipt Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocSalesLine: Record "Sales Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToSalesHeader."Currency Code");
        OpenWindow;

        OnBeforeCopySalesReturnRcptLinesToDoc(TempDocSalesLine, ToSalesHeader, FromReturnRcptLine);

        with FromReturnRcptLine do
            if FindSet then
                repeat
                    FromLineCounter := FromLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(1, FromLineCounter);
                    if FromReturnRcptHeader."No." <> "Document No." then begin
                        FromReturnRcptHeader.Get("Document No.");
                        TransferOldExtLines.ClearLineNumbers;
                    end;
                    FromSalesHeader.TransferFields(FromReturnRcptHeader);
                    FillExactCostRevLink :=
                      IsSalesFillExactCostRevLink(ToSalesHeader, 2, FromSalesHeader."Currency Code");
                    FromSalesLine.TransferFields(FromReturnRcptLine);
                    FromSalesLine."Appl.-from Item Entry" := 0;
                    FromSalesLine."Copied From Posted Doc." := true;

                    if "Document No." <> OldDocNo then begin
                        OldDocNo := "Document No.";
                        InsertDocNoLine := true;
                    end;

                    OnBeforeCopySalesReturnRcptLinesToBuffer(FromSalesLine, FromReturnRcptLine, ToSalesHeader);

                    SplitLine := true;
                    FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                    if not SplitPstdSalesLinesPerILE(
                         ToSalesHeader, FromSalesHeader, ItemLedgEntry, FromSalesLineBuf,
                         FromSalesLine, TempDocSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                    then
                        if CopyItemTrkg then
                            SplitLine :=
                              SplitSalesDocLinesPerItemTrkg(
                                ItemLedgEntry, TempItemTrkgEntry, FromSalesLineBuf,
                                FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                        else
                            SplitLine := false;

                    if not SplitLine then begin
                        FromSalesLineBuf := FromSalesLine;
                        CopyLine := true;
                    end else
                        CopyLine := FromSalesLineBuf.FindSet and FillExactCostRevLink;

                    Window.Update(1, FromLineCounter);
                    if CopyLine then begin
                        NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                        if InsertDocNoLine then begin
                            InsertOldSalesDocNoLine(ToSalesHeader, "Document No.", 3, NextLineNo);
                            InsertDocNoLine := false;
                        end;
                        repeat
                            ToLineCounter := ToLineCounter + 1;
                            if IsTimeForUpdate then
                                Window.Update(2, ToLineCounter);
                            if CopySalesLine(
                                 ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLineBuf, NextLineNo, LinesNotCopied,
                                 false, DeferralTypeForSalesDoc(SalesDocType::"Posted Return Receipt"), CopyPostedDeferral,
                                 FromSalesLineBuf."Line No.")
                            then begin
                                if CopyItemTrkg then begin
                                    if SplitLine then
                                        ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                          TempItemTrkgEntry, TempTrkgItemLedgEntry, false, FromSalesLineBuf."Document No.", FromSalesLineBuf."Line No.")
                                    else
                                        ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                                    ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                      TempTrkgItemLedgEntry, ToSalesLine,
                                      FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                      FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", true);
                                end;
                                OnAfterCopySalesLineFromReturnRcptLineBuffer(
                                  ToSalesLine, FromReturnRcptLine, IncludeHeader, RecalculateLines,
                                  TempDocSalesLine, ToSalesHeader, FromSalesLineBuf, CopyItemTrkg);
                            end;
                        until FromSalesLineBuf.Next = 0
                    end;
                until Next = 0;

        Window.Close;
    end;

    local procedure CopySalesLinesToBuffer(FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; var FromSalesLine2: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; var TempDocSalesLine: Record "Sales Line" temporary; DocNo: Code[20]; var NextLineNo: Integer)
    begin
        FromSalesLine2 := TempSalesLineBuf;
        TempSalesLineBuf := FromSalesLine;
        TempSalesLineBuf."Document No." := FromSalesLine2."Document No.";
        TempSalesLineBuf."Shipment Line No." := FromSalesLine2."Shipment Line No.";
        TempSalesLineBuf."Line No." := NextLineNo;
        OnAfterCopySalesLinesToBufferFields(TempSalesLineBuf, FromSalesLine2);

        NextLineNo := NextLineNo + 10000;
        if not IsRecalculateAmount(
             FromSalesHeader."Currency Code", ToSalesHeader."Currency Code",
             FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT")
        then
            TempSalesLineBuf."Return Receipt No." := DocNo;
        ReCalcSalesLine(FromSalesHeader, ToSalesHeader, TempSalesLineBuf);
        OnCopySalesLinesToBufferTransferFields(FromSalesHeader, FromSalesLine, TempSalesLineBuf);
        TempSalesLineBuf.Insert();
        AddSalesDocLine(TempDocSalesLine, TempSalesLineBuf."Line No.", DocNo, FromSalesLine."Line No.");
    end;

    local procedure CopyItemLedgEntryTrackingToSalesLine(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; TempFromSalesLine: Record "Sales Line" temporary; ToSalesLine: Record "Sales Line"; ToSalesPricesInctVAT: Boolean; FromSalesPricesInctVAT: Boolean; FillExactCostRevLink: Boolean; var MissingExCostRevLink: Boolean)
    var
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        AssemblyHeader: Record "Assembly Header";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        if MoveNegLines or not ExactCostRevMandatory then
            ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, TempItemLedgEntry)
        else
            ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
              TempReservationEntry, TempTrkgItemLedgEntry, false, TempFromSalesLine."Document No.", TempFromSalesLine."Line No.");

        if ToSalesLine.AsmToOrderExists(AssemblyHeader) then
            SetTrackingOnAssemblyReservation(AssemblyHeader, TempItemLedgEntry)
        else
            ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
              TempTrkgItemLedgEntry, ToSalesLine, FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
              FromSalesPricesInctVAT, ToSalesPricesInctVAT, false);
    end;

    local procedure SplitPstdSalesLinesPerILE(ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; var ItemLedgEntry: Record "Item Ledger Entry"; var TempSalesLineBuf: Record "Sales Line" temporary; FromSalesLine: Record "Sales Line"; var TempDocSalesLine: Record "Sales Line" temporary; var NextLineNo: Integer; var CopyItemTrkg: Boolean; var MissingExCostRevLink: Boolean; FillExactCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        OrgQtyBase: Decimal;
    begin
        if FromShptOrRcpt then begin
            TempSalesLineBuf.Reset();
            TempSalesLineBuf.DeleteAll();
        end else
            TempSalesLineBuf.Init();

        CopyItemTrkg := false;

        if (FromSalesLine.Type <> FromSalesLine.Type::Item) or (FromSalesLine.Quantity = 0) then
            exit(false);
        if IsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink) or
           not FillExactCostRevLink or MoveNegLines or
           not ExactCostRevMandatory
        then
            exit(false);

        with ItemLedgEntry do begin
            FindSet;
            if Quantity >= 0 then begin
                TempSalesLineBuf."Document No." := "Document No.";
                if GetSalesDocType(ItemLedgEntry) in
                   [TempSalesLineBuf."Document Type"::Order, TempSalesLineBuf."Document Type"::"Return Order"]
                then
                    TempSalesLineBuf."Shipment Line No." := 1;
                exit(false);
            end;
            OrgQtyBase := FromSalesLine."Quantity (Base)";
            repeat
                if "Shipped Qty. Not Returned" = 0 then
                    SkippedLine := true;

                if "Shipped Qty. Not Returned" < 0 then begin
                    TempSalesLineBuf := FromSalesLine;

                    if -"Shipped Qty. Not Returned" < Abs(FromSalesLine."Quantity (Base)") then begin
                        if FromSalesLine."Quantity (Base)" > 0 then
                            TempSalesLineBuf."Quantity (Base)" := -"Shipped Qty. Not Returned"
                        else
                            TempSalesLineBuf."Quantity (Base)" := "Shipped Qty. Not Returned";
                        if TempSalesLineBuf."Qty. per Unit of Measure" = 0 then
                            TempSalesLineBuf.Quantity := TempSalesLineBuf."Quantity (Base)"
                        else
                            TempSalesLineBuf.Quantity :=
                              Round(
                                TempSalesLineBuf."Quantity (Base)" / TempSalesLineBuf."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    end;
                    FromSalesLine."Quantity (Base)" := FromSalesLine."Quantity (Base)" - TempSalesLineBuf."Quantity (Base)";
                    FromSalesLine.Quantity := FromSalesLine.Quantity - TempSalesLineBuf.Quantity;
                    TempSalesLineBuf."Appl.-from Item Entry" := "Entry No.";
                    NextLineNo := NextLineNo + 1;
                    TempSalesLineBuf."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    TempSalesLineBuf."Document No." := "Document No.";
                    if GetSalesDocType(ItemLedgEntry) in
                       [TempSalesLineBuf."Document Type"::Order, TempSalesLineBuf."Document Type"::"Return Order"]
                    then
                        TempSalesLineBuf."Shipment Line No." := 1;

                    if not FromShptOrRcpt then
                        UpdateRevSalesLineAmount(
                          TempSalesLineBuf, OrgQtyBase,
                          FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT");

                    OnSplitPstdSalesLinesPerILETransferFields(FromSalesHeader, FromSalesLine, TempSalesLineBuf, ToSalesHeader);
                    TempSalesLineBuf.Insert();
                    AddSalesDocLine(TempDocSalesLine, TempSalesLineBuf."Line No.", "Document No.", TempSalesLineBuf."Line No.");
                end;
            until (Next = 0) or (FromSalesLine."Quantity (Base)" = 0);

            if (FromSalesLine."Quantity (Base)" <> 0) and FillExactCostRevLink then
                MissingExCostRevLink := true;
            CheckUnappliedLines(SkippedLine, MissingExCostRevLink);
        end;
        exit(true);
    end;

    local procedure SplitSalesDocLinesPerItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var TempSalesLineBuf: Record "Sales Line" temporary; FromSalesLine: Record "Sales Line"; var TempDocSalesLine: Record "Sales Line" temporary; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        SalesLineBuf: array[2] of Record "Sales Line" temporary;
        Tracked: Boolean;
        ReversibleQtyBase: Decimal;
        SignFactor: Integer;
        i: Integer;
    begin
        if FromShptOrRcpt then begin
            TempSalesLineBuf.Reset();
            TempSalesLineBuf.DeleteAll();
            TempItemTrkgEntry.Reset();
            TempItemTrkgEntry.DeleteAll();
        end else
            TempSalesLineBuf.Init();

        if MoveNegLines or not ExactCostRevMandatory then
            exit(false);

        if FromSalesLine."Quantity (Base)" < 0 then
            SignFactor := -1
        else
            SignFactor := 1;

        with ItemLedgEntry do begin
            SetCurrentKey("Document No.", "Document Type", "Document Line No.");
            FindSet;
            repeat
                SalesLineBuf[1] := FromSalesLine;
                SalesLineBuf[1]."Line No." := NextLineNo;
                SalesLineBuf[1]."Quantity (Base)" := 0;
                SalesLineBuf[1].Quantity := 0;
                SalesLineBuf[1]."Document No." := "Document No.";
                if GetSalesDocType(ItemLedgEntry) in
                   [SalesLineBuf[1]."Document Type"::Order, SalesLineBuf[1]."Document Type"::"Return Order"]
                then
                    SalesLineBuf[1]."Shipment Line No." := 1;
                SalesLineBuf[2] := SalesLineBuf[1];
                SalesLineBuf[2]."Line No." := SalesLineBuf[2]."Line No." + 1;

                if not FromShptOrRcpt then begin
                    SetRange("Document No.", "Document No.");
                    SetRange("Document Type", "Document Type");
                    SetRange("Document Line No.", "Document Line No.");
                end;
                repeat
                    i := 1;
                    if not Positive then
                        "Shipped Qty. Not Returned" :=
                          "Shipped Qty. Not Returned" -
                          CalcDistributedQty(TempItemTrkgEntry, ItemLedgEntry, SalesLineBuf[2]."Line No." + 1);
                    if "Shipped Qty. Not Returned" = 0 then
                        SkippedLine := true;

                    if "Document Type" in ["Document Type"::"Sales Return Receipt", "Document Type"::"Sales Credit Memo"] then
                        if "Remaining Quantity" < FromSalesLine."Quantity (Base)" * SignFactor then
                            ReversibleQtyBase := "Remaining Quantity" * SignFactor
                        else
                            ReversibleQtyBase := FromSalesLine."Quantity (Base)"
                    else
                        if Positive then begin
                            ReversibleQtyBase := "Remaining Quantity";
                            if ReversibleQtyBase < FromSalesLine."Quantity (Base)" * SignFactor then
                                ReversibleQtyBase := ReversibleQtyBase * SignFactor
                            else
                                ReversibleQtyBase := FromSalesLine."Quantity (Base)";
                        end else
                            if -"Shipped Qty. Not Returned" < FromSalesLine."Quantity (Base)" * SignFactor then
                                ReversibleQtyBase := -"Shipped Qty. Not Returned" * SignFactor
                            else
                                ReversibleQtyBase := FromSalesLine."Quantity (Base)";

                    if ReversibleQtyBase <> 0 then begin
                        if not Positive then
                            if IsSplitItemLedgEntry(ItemLedgEntry) then
                                i := 2;

                        SalesLineBuf[i]."Quantity (Base)" := SalesLineBuf[i]."Quantity (Base)" + ReversibleQtyBase;
                        if SalesLineBuf[i]."Qty. per Unit of Measure" = 0 then
                            SalesLineBuf[i].Quantity := SalesLineBuf[i]."Quantity (Base)"
                        else
                            SalesLineBuf[i].Quantity :=
                              Round(
                                SalesLineBuf[i]."Quantity (Base)" / SalesLineBuf[i]."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                        FromSalesLine."Quantity (Base)" := FromSalesLine."Quantity (Base)" - ReversibleQtyBase;
                        // Fill buffer with exact cost reversing link
                        InsertTempItemTrkgEntry(
                          ItemLedgEntry, TempItemTrkgEntry, -Abs(ReversibleQtyBase),
                          SalesLineBuf[i]."Line No.", NextItemTrkgEntryNo, true);
                        Tracked := true;
                    end;
                until (Next = 0) or (FromSalesLine."Quantity (Base)" = 0);

                for i := 1 to 2 do
                    if SalesLineBuf[i]."Quantity (Base)" <> 0 then begin
                        TempSalesLineBuf := SalesLineBuf[i];
                        TempSalesLineBuf.Insert();
                        AddSalesDocLine(TempDocSalesLine, TempSalesLineBuf."Line No.", "Document No.", FromSalesLine."Line No.");
                        NextLineNo := SalesLineBuf[i]."Line No." + 1;
                    end;

                if not FromShptOrRcpt then begin
                    SetRange("Document No.");
                    SetRange("Document Type");
                    SetRange("Document Line No.");
                end;
            until (Next = 0) or FromShptOrRcpt;

            if (FromSalesLine."Quantity (Base)" <> 0) and not Tracked then
                MissingExCostRevLink := true;
        end;
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);

        exit(true);
    end;

    procedure CopyPurchRcptLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        OriginalPurchHeader: Record "Purchase Header";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchRcptHeader: Record "Purch. Rcpt. Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocPurchaseLine: Record "Purchase Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        FillExactCostRevLink: Boolean;
        SplitLine: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToPurchHeader."Currency Code");
        OpenWindow;

        with FromPurchRcptLine do
            if FindSet then
                repeat
                    FromLineCounter := FromLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(1, FromLineCounter);
                    if FromPurchRcptHeader."No." <> "Document No." then begin
                        FromPurchRcptHeader.Get("Document No.");
                        if OriginalPurchHeader.Get(OriginalPurchHeader."Document Type"::Order, FromPurchRcptHeader."Order No.") then
                            OriginalPurchHeader.TestField("Prices Including VAT", ToPurchHeader."Prices Including VAT");
                        TransferOldExtLines.ClearLineNumbers;
                    end;
                    FromPurchHeader.TransferFields(FromPurchRcptHeader);
                    FillExactCostRevLink :=
                      IsPurchFillExactCostRevLink(ToPurchHeader, 0, FromPurchHeader."Currency Code");
                    FromPurchLine.TransferFields(FromPurchRcptLine);
                    FromPurchLine."Appl.-to Item Entry" := 0;
                    FromPurchLine."Copied From Posted Doc." := true;

                    OnCopyPurchRcptLinesToDocOnAfterTransferFields(FromPurchLine, FromPurchHeader, ToPurchHeader, FromPurchRcptHeader);

                    if "Document No." <> OldDocNo then begin
                        OldDocNo := "Document No.";
                        InsertDocNoLine := true;
                    end;

                    SplitLine := true;
                    FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                    if not SplitPstdPurchLinesPerILE(
                         ToPurchHeader, FromPurchHeader, ItemLedgEntry, FromPurchLineBuf,
                         FromPurchLine, TempDocPurchaseLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                    then
                        if CopyItemTrkg then
                            SplitLine :=
                              SplitPurchDocLinesPerItemTrkg(
                                ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf,
                                FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                        else
                            SplitLine := false;

                    if not SplitLine then begin
                        FromPurchLineBuf := FromPurchLine;
                        CopyLine := true;
                    end else
                        CopyLine := FromPurchLineBuf.FindSet and FillExactCostRevLink;

                    Window.Update(1, FromLineCounter);
                    if CopyLine then begin
                        NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                        if InsertDocNoLine then begin
                            InsertOldPurchDocNoLine(ToPurchHeader, "Document No.", 1, NextLineNo);
                            InsertDocNoLine := false;
                        end;
                        repeat
                            ToLineCounter := ToLineCounter + 1;
                            if IsTimeForUpdate then
                                Window.Update(2, ToLineCounter);
                            if FromPurchLine."Prod. Order No." <> '' then
                                FromPurchLine."Quantity (Base)" := 0;

                            OnCopyPurchRcptLinesToDocOnBeforeCopyPurchLine(ToPurchHeader, FromPurchLineBuf);

                            if CopyPurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLineBuf, NextLineNo, LinesNotCopied,
                                 false, DeferralTypeForPurchDoc(PurchDocType::"Posted Receipt"), CopyPostedDeferral, FromPurchLineBuf."Line No.")
                            then begin
                                if CopyItemTrkg then begin
                                    if SplitLine then
                                        ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                          TempItemTrkgEntry, TempTrkgItemLedgEntry, true, FromPurchLineBuf."Document No.", FromPurchLineBuf."Line No.")
                                    else
                                        ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                                    ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                      TempTrkgItemLedgEntry, ToPurchLine,
                                      FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                      FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", true);
                                end;
                                OnAfterCopyPurchLineFromPurchRcptLineBuffer(
                                  ToPurchLine, FromPurchRcptLine, IncludeHeader, RecalculateLines,
                                  TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf, CopyItemTrkg);
                            end;
                        until FromPurchLineBuf.Next = 0;
                        OnAfterCopyPurchRcptLine(FromPurchRcptLine, ToPurchLine);
                    end;
                until Next = 0;

        Window.Close;
    end;

    procedure CopyPurchInvLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchInvLine: Record "Purch. Inv. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        FromPurchLine2: Record "Purchase Line";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchInvHeader: Record "Purch. Inv. Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocPurchaseLine: Record "Purchase Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldInvDocNo: Code[20];
        OldRcptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        ItemChargeAssgntNextLineNo: Integer;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToPurchHeader."Currency Code");
        FromPurchLineBuf.Reset();
        FromPurchLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow;

        OnBeforeCopyPurchInvLines(TempDocPurchaseLine, ToPurchHeader, FromPurchInvLine);

        // Fill purchase line buffer
        with FromPurchInvLine do
            if FindSet then
                repeat
                    FromLineCounter := FromLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(1, FromLineCounter);
                    if FromPurchInvHeader."No." <> "Document No." then begin
                        FromPurchInvHeader.Get("Document No.");
                        FromPurchInvHeader.TestField("Prices Including VAT", ToPurchHeader."Prices Including VAT");
                        TransferOldExtLines.ClearLineNumbers;
                    end;
                    FromPurchHeader.TransferFields(FromPurchInvHeader);
                    FillExactCostRevLink := IsPurchFillExactCostRevLink(ToPurchHeader, 1, FromPurchHeader."Currency Code");
                    FromPurchLine.TransferFields(FromPurchInvLine);
                    FromPurchLine."Appl.-to Item Entry" := 0;
                    // Reuse fields to buffer invoice line information
                    FromPurchLine."Receipt No." := "Document No.";
                    FromPurchLine."Receipt Line No." := 0;
                    FromPurchLine."Return Shipment No." := '';
                    FromPurchLine."Return Shipment Line No." := "Line No.";
                    FromPurchLine."Copied From Posted Doc." := true;

                    OnCopyPurchInvLinesToDocOnAfterTransferFields(FromPurchLine, FromPurchHeader, ToPurchHeader);

                    SplitLine := true;
                    GetItemLedgEntries(ItemLedgEntryBuf, true);
                    if not SplitPstdPurchLinesPerILE(
                         ToPurchHeader, FromPurchHeader, ItemLedgEntryBuf, FromPurchLineBuf,
                         FromPurchLine, TempDocPurchaseLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                    then
                        if CopyItemTrkg then
                            SplitLine := SplitPurchDocLinesPerItemTrkg(
                                ItemLedgEntryBuf, TempItemTrkgEntry, FromPurchLineBuf,
                                FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                        else
                            SplitLine := false;

                    if not SplitLine then
                        CopyPurchLinesToBuffer(
                          FromPurchHeader, FromPurchLine, FromPurchLine2, FromPurchLineBuf, ToPurchHeader, TempDocPurchaseLine,
                          "Document No.", NextLineNo);

                    OnAfterCopyPurchInvLines(TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf, FromPurchInvLine);
                until Next = 0;

        // Create purchase line from buffer
        Window.Update(1, FromLineCounter);
        with FromPurchLineBuf do begin
            // Sorting according to Purchase Line Document No.,Line No.
            SetCurrentKey("Document Type", "Document No.", "Line No.");
            if FindSet then begin
                NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                repeat
                    ToLineCounter := ToLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(2, ToLineCounter);
                    if "Receipt No." <> OldInvDocNo then begin
                        OldInvDocNo := "Receipt No.";
                        OldRcptDocNo := '';
                        InsertOldPurchDocNoLine(ToPurchHeader, OldInvDocNo, 2, NextLineNo);
                    end;
                    if ("Document No." <> OldRcptDocNo) and ("Receipt Line No." > 0) then begin
                        OldRcptDocNo := "Document No.";
                        InsertOldPurchCombDocNoLine(ToPurchHeader, OldInvDocNo, OldRcptDocNo, NextLineNo, true);
                    end;

                    // Empty buffer fields
                    FromPurchLine2 := FromPurchLineBuf;
                    FromPurchLine2."Receipt No." := '';
                    FromPurchLine2."Receipt Line No." := 0;
                    FromPurchLine2."Return Shipment No." := '';
                    FromPurchLine2."Return Shipment Line No." := 0;
                    if GetPurchDocNo(TempDocPurchaseLine, "Line No.") <> OldBufDocNo then begin
                        OldBufDocNo := GetPurchDocNo(TempDocPurchaseLine, "Line No.");
                        TransferOldExtLines.ClearLineNumbers;
                    end;

                    OnCopyPurchInvLinesToDocOnBeforeCopyPurchLine(ToPurchHeader, FromPurchLine2);

                    if CopyPurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine2, NextLineNo, LinesNotCopied,
                         "Return Shipment No." = '', DeferralTypeForPurchDoc(PurchDocType::"Posted Invoice"), CopyPostedDeferral,
                         GetPurchLineNo(TempDocPurchaseLine, FromPurchLine2."Line No."))
                    then begin
                        if CopyPostedDeferral then
                            CopyPurchPostedDeferrals(ToPurchLine, DeferralUtilities.GetPurchDeferralDocType,
                              DeferralTypeForPurchDoc(PurchDocType::"Posted Invoice"), "Receipt No.",
                              "Return Shipment Line No.", ToPurchLine."Document Type", ToPurchLine."Document No.", ToPurchLine."Line No.");
                        FromPurchInvLine.Get("Receipt No.", "Return Shipment Line No.");

                        // copy item charges
                        if Type = Type::"Charge (Item)" then begin
                            FromPurchLine.TransferFields(FromPurchInvLine);
                            FromPurchLine."Document Type" := FromPurchLine."Document Type"::Invoice;
                            CopyFromPurchLineItemChargeAssign(FromPurchLine, ToPurchLine, FromPurchHeader, ItemChargeAssgntNextLineNo);
                        end;
                        // copy item tracking
                        if (Type = Type::Item) and (Quantity <> 0) and ("Prod. Order No." = '') and
                           PurchaseDocCanReceiveTracking(ToPurchHeader)
                        then begin
                            FromPurchInvLine."Document No." := OldInvDocNo;
                            FromPurchInvLine."Line No." := "Return Shipment Line No.";
                            FromPurchInvLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                            if IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then begin
                                if "Job No." <> '' then
                                    ItemLedgEntryBuf.SetFilter("Entry Type", '<> %1', ItemLedgEntryBuf."Entry Type"::"Negative Adjmt.");
                                if MoveNegLines or not ExactCostRevMandatory then
                                    ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                                else
                                    ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                      TempItemTrkgEntry, TempTrkgItemLedgEntry, true, "Document No.", "Line No.");

                                ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(TempTrkgItemLedgEntry, ToPurchLine,
                                  FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                  FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", false);
                            end;
                        end;
                        OnAfterCopyPurchLineFromPurchLineBuffer(
                          ToPurchLine, FromPurchInvLine, IncludeHeader, RecalculateLines, TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf);
                    end;
                    OnAfterCopyPurchInvLine(FromPurchInvLine, ToPurchLine);
                until Next = 0;
            end;
        end;

        Window.Close;
    end;

    procedure CopyPurchCrMemoLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        FromPurchLine2: Record "Purchase Line";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocPurchaseLine: Record "Purchase Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldCrMemoDocNo: Code[20];
        OldReturnShptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        ItemChargeAssgntNextLineNo: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToPurchHeader."Currency Code");
        FromPurchLineBuf.Reset();
        FromPurchLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow;

        OnBeforeCopyPurchCrMemoLinesToDoc(TempDocPurchaseLine, ToPurchHeader, FromPurchCrMemoLine);

        // Fill purchase line buffer
        with FromPurchCrMemoLine do
            if FindSet then
                repeat
                    FromLineCounter := FromLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(1, FromLineCounter);
                    if FromPurchCrMemoHeader."No." <> "Document No." then begin
                        FromPurchCrMemoHeader.Get("Document No.");
                        FromPurchCrMemoHeader.TestField("Prices Including VAT", ToPurchHeader."Prices Including VAT");
                        TransferOldExtLines.ClearLineNumbers;
                    end;
                    FromPurchHeader.TransferFields(FromPurchCrMemoHeader);
                    FillExactCostRevLink :=
                      IsPurchFillExactCostRevLink(ToPurchHeader, 3, FromPurchHeader."Currency Code");
                    FromPurchLine.TransferFields(FromPurchCrMemoLine);
                    FromPurchLine."Appl.-to Item Entry" := 0;
                    // Reuse fields to buffer credit memo line information
                    FromPurchLine."Receipt No." := "Document No.";
                    FromPurchLine."Receipt Line No." := 0;
                    FromPurchLine."Return Shipment No." := '';
                    FromPurchLine."Return Shipment Line No." := "Line No.";
                    FromPurchLine."Copied From Posted Doc." := true;

                    OnCopyPurchCrMemoLinesToDocOnAfterTransferFields(FromPurchLine, FromPurchHeader, ToPurchHeader, FromPurchCrMemoHeader);

                    SplitLine := true;
                    GetItemLedgEntries(ItemLedgEntryBuf, true);
                    if not SplitPstdPurchLinesPerILE(
                         ToPurchHeader, FromPurchHeader, ItemLedgEntryBuf, FromPurchLineBuf,
                         FromPurchLine, TempDocPurchaseLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                    then
                        if CopyItemTrkg then
                            SplitLine :=
                              SplitPurchDocLinesPerItemTrkg(
                                ItemLedgEntryBuf, TempItemTrkgEntry, FromPurchLineBuf,
                                FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                        else
                            SplitLine := false;

                    if not SplitLine then
                        CopyPurchLinesToBuffer(
                          FromPurchHeader, FromPurchLine, FromPurchLine2, FromPurchLineBuf, ToPurchHeader, TempDocPurchaseLine,
                          "Document No.", NextLineNo);
                until Next = 0;

        // Create purchase line from buffer
        Window.Update(1, FromLineCounter);
        with FromPurchLineBuf do begin
            // Sorting according to Purchase Line Document No.,Line No.
            SetCurrentKey("Document Type", "Document No.", "Line No.");
            if FindSet then begin
                NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                repeat
                    ToLineCounter := ToLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(2, ToLineCounter);
                    if "Receipt No." <> OldCrMemoDocNo then begin
                        OldCrMemoDocNo := "Receipt No.";
                        OldReturnShptDocNo := '';
                        InsertOldPurchDocNoLine(ToPurchHeader, OldCrMemoDocNo, 4, NextLineNo);
                    end;
                    if "Document No." <> OldReturnShptDocNo then begin
                        OldReturnShptDocNo := "Document No.";
                        InsertOldPurchCombDocNoLine(ToPurchHeader, OldCrMemoDocNo, OldReturnShptDocNo, NextLineNo, false);
                    end;

                    // Empty buffer fields
                    FromPurchLine2 := FromPurchLineBuf;
                    FromPurchLine2."Receipt No." := '';
                    FromPurchLine2."Receipt Line No." := 0;
                    FromPurchLine2."Return Shipment No." := '';
                    FromPurchLine2."Return Shipment Line No." := 0;
                    if GetPurchDocNo(TempDocPurchaseLine, "Line No.") <> OldBufDocNo then begin
                        OldBufDocNo := GetPurchDocNo(TempDocPurchaseLine, "Line No.");
                        TransferOldExtLines.ClearLineNumbers;
                    end;

                    OnCopyPurchCrMemoLinesToDocOnBeforeCopyPurchLine(ToPurchHeader, FromPurchLine2);

                    if CopyPurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine2, NextLineNo, LinesNotCopied,
                         "Return Shipment No." = '', DeferralTypeForPurchDoc(PurchDocType::"Posted Credit Memo"), CopyPostedDeferral,
                         GetPurchLineNo(TempDocPurchaseLine, FromPurchLine2."Line No."))
                    then begin
                        if CopyPostedDeferral then
                            CopyPurchPostedDeferrals(ToPurchLine, DeferralUtilities.GetPurchDeferralDocType,
                              DeferralTypeForPurchDoc(PurchDocType::"Posted Credit Memo"), "Receipt No.",
                              "Return Shipment Line No.", ToPurchLine."Document Type", ToPurchLine."Document No.", ToPurchLine."Line No.");
                        FromPurchCrMemoLine.Get("Receipt No.", "Return Shipment Line No.");

                        // copy item charges
                        if Type = Type::"Charge (Item)" then begin
                            FromPurchLine.TransferFields(FromPurchCrMemoLine);
                            FromPurchLine."Document Type" := FromPurchLine."Document Type"::"Credit Memo";
                            CopyFromPurchLineItemChargeAssign(FromPurchLine, ToPurchLine, FromPurchHeader, ItemChargeAssgntNextLineNo);
                        end;
                        // copy item tracking
                        if (Type = Type::Item) and (Quantity <> 0) and ("Prod. Order No." = '') then begin
                            FromPurchCrMemoLine."Document No." := OldCrMemoDocNo;
                            FromPurchCrMemoLine."Line No." := "Return Shipment Line No.";
                            FromPurchCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                            if IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then begin
                                if "Job No." <> '' then
                                    ItemLedgEntryBuf.SetFilter("Entry Type", '<> %1', ItemLedgEntryBuf."Entry Type"::"Negative Adjmt.");
                                OnCopyPurchCrMemoLinesToDocOnAfterFilterEntryType(FromPurchLineBuf, ItemLedgEntryBuf);
                                if MoveNegLines or not ExactCostRevMandatory then
                                    ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                                else
                                    ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                      TempItemTrkgEntry, TempTrkgItemLedgEntry, true, "Document No.", "Line No.");

                                ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                  TempTrkgItemLedgEntry, ToPurchLine,
                                  FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                  FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", false);
                            end;
                        end;
                        OnAfterCopyPurchLineFromPurchCrMemoLineBuffer(
                          ToPurchLine, FromPurchCrMemoLine, IncludeHeader, RecalculateLines, TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf);
                    end;
                    OnAfterCopyPurchCrMemoLine(FromPurchCrMemoLine, ToPurchLine);
                until Next = 0;
            end;
        end;

        Window.Close;
    end;

    procedure CopyPurchReturnShptLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromReturnShptLine: Record "Return Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        OriginalPurchHeader: Record "Purchase Header";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromReturnShptHeader: Record "Return Shipment Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocPurchaseLine: Record "Purchase Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToPurchHeader."Currency Code");
        OpenWindow;

        OnBeforeCopyPurchReturnShptLinesToDoc(TempDocPurchaseLine, ToPurchHeader, FromReturnShptLine);

        with FromReturnShptLine do
            if FindSet then
                repeat
                    FromLineCounter := FromLineCounter + 1;
                    if IsTimeForUpdate then
                        Window.Update(1, FromLineCounter);
                    if FromReturnShptHeader."No." <> "Document No." then begin
                        FromReturnShptHeader.Get("Document No.");
                        if OriginalPurchHeader.Get(OriginalPurchHeader."Document Type"::"Return Order", FromReturnShptHeader."Return Order No.") then
                            OriginalPurchHeader.TestField("Prices Including VAT", ToPurchHeader."Prices Including VAT");
                        TransferOldExtLines.ClearLineNumbers;
                    end;
                    FromPurchHeader.TransferFields(FromReturnShptHeader);
                    FillExactCostRevLink :=
                      IsPurchFillExactCostRevLink(ToPurchHeader, 2, FromPurchHeader."Currency Code");
                    FromPurchLine.TransferFields(FromReturnShptLine);
                    FromPurchLine.Validate("Order No.", "Return Order No.");
                    FromPurchLine.Validate("Order Line No.", "Return Order Line No.");
                    FromPurchLine."Appl.-to Item Entry" := 0;
                    FromPurchLine."Copied From Posted Doc." := true;

                    OnCopyPurchReturnShptLinesToDocOnAfterTransferFields(
                      FromPurchLine, FromPurchHeader, ToPurchHeader, FromReturnShptHeader);

                    if "Document No." <> OldDocNo then begin
                        OldDocNo := "Document No.";
                        InsertDocNoLine := true;
                    end;

                    SplitLine := true;
                    FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                    if not SplitPstdPurchLinesPerILE(
                         ToPurchHeader, FromPurchHeader, ItemLedgEntry, FromPurchLineBuf,
                         FromPurchLine, TempDocPurchaseLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                    then
                        if CopyItemTrkg then
                            SplitLine :=
                              SplitPurchDocLinesPerItemTrkg(
                                ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf,
                                FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                        else
                            SplitLine := false;

                    if not SplitLine then begin
                        FromPurchLineBuf := FromPurchLine;
                        CopyLine := true;
                    end else
                        CopyLine := FromPurchLineBuf.FindSet and FillExactCostRevLink;

                    Window.Update(1, FromLineCounter);
                    if CopyLine then begin
                        NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                        if InsertDocNoLine then begin
                            InsertOldPurchDocNoLine(ToPurchHeader, "Document No.", 3, NextLineNo);
                            InsertDocNoLine := false;
                        end;
                        repeat
                            ToLineCounter := ToLineCounter + 1;
                            if IsTimeForUpdate then
                                Window.Update(2, ToLineCounter);

                            OnCopyPurchReturnShptLinesToDocOnBeforeCopyPurchLine(ToPurchHeader, FromPurchLineBuf);

                            if CopyPurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLineBuf, NextLineNo, LinesNotCopied,
                                 false, DeferralTypeForPurchDoc(PurchDocType::"Posted Return Shipment"), CopyPostedDeferral,
                                 FromPurchLineBuf."Line No.")
                            then begin
                                if CopyItemTrkg then begin
                                    if SplitLine then
                                        ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                          TempItemTrkgEntry, TempTrkgItemLedgEntry, true, FromPurchLineBuf."Document No.", FromPurchLineBuf."Line No.")
                                    else
                                        ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                                    ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                      TempTrkgItemLedgEntry, ToPurchLine,
                                      FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                      FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", true);
                                end;
                                OnAfterCopyPurchLineFromReturnShptLineBuffer(
                                  ToPurchLine, FromReturnShptLine, IncludeHeader, RecalculateLines,
                                  TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf, CopyItemTrkg);
                            end;
                        until FromPurchLineBuf.Next = 0;
                    end;
                    OnAfterCopyReturnShptLine(FromReturnShptLine, ToPurchLine);
                until Next = 0;

        Window.Close;
    end;

    local procedure CopyPurchLinesToBuffer(FromPurchHeader: Record "Purchase Header"; FromPurchLine: Record "Purchase Line"; var FromPurchLine2: Record "Purchase Line"; var TempPurchLineBuf: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; var TempDocPurchaseLine: Record "Purchase Line" temporary; DocNo: Code[20]; var NextLineNo: Integer)
    begin
        FromPurchLine2 := TempPurchLineBuf;
        TempPurchLineBuf := FromPurchLine;
        TempPurchLineBuf."Document No." := FromPurchLine2."Document No.";
        TempPurchLineBuf."Receipt Line No." := FromPurchLine2."Receipt Line No.";
        TempPurchLineBuf."Line No." := NextLineNo;
        OnAfterCopyPurchLinesToBufferFields(TempPurchLineBuf, FromPurchLine2);

        NextLineNo := NextLineNo + 10000;
        if not IsRecalculateAmount(
             FromPurchHeader."Currency Code", ToPurchHeader."Currency Code",
             FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT")
        then
            TempPurchLineBuf."Return Shipment No." := DocNo;
        ReCalcPurchLine(FromPurchHeader, ToPurchHeader, TempPurchLineBuf);
        TempPurchLineBuf.Insert();
        AddPurchDocLine(TempDocPurchaseLine, TempPurchLineBuf."Line No.", DocNo, FromPurchLine."Line No.");
    end;

    local procedure CreateJobPlanningLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; JobContractEntryNo: Integer): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
        NewJobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateJobPlanningLine(SalesHeader, SalesLine, JobContractEntryNo, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", JobContractEntryNo);
        if JobPlanningLine.FindFirst then begin
            NewJobPlanningLine.InitFromJobPlanningLine(JobPlanningLine, SalesLine.Quantity);

            JobPlanningLineInvoice.InitFromJobPlanningLine(NewJobPlanningLine);
            JobPlanningLineInvoice.InitFromSales(SalesHeader, SalesHeader."Posting Date", SalesLine."Line No.");
            JobPlanningLineInvoice.Insert();

            NewJobPlanningLine.UpdateQtyToTransfer;
            NewJobPlanningLine.Insert();
        end;

        exit(NewJobPlanningLine."Job Contract Entry No.");
    end;

    local procedure SplitPstdPurchLinesPerILE(ToPurchHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header"; var ItemLedgEntry: Record "Item Ledger Entry"; var FromPurchLineBuf: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; var TempDocPurchaseLine: Record "Purchase Line" temporary; var NextLineNo: Integer; var CopyItemTrkg: Boolean; var MissingExCostRevLink: Boolean; FillExactCostRevLink: Boolean; FromShptOrRcpt: Boolean) Result: Boolean
    var
        Item: Record Item;
        ApplyRec: Record "Item Application Entry";
        OrgQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        if FromShptOrRcpt then begin
            FromPurchLineBuf.Reset();
            FromPurchLineBuf.DeleteAll();
        end else
            FromPurchLineBuf.Init();

        CopyItemTrkg := false;

        if (FromPurchLine.Type <> FromPurchLine.Type::Item) or (FromPurchLine.Quantity = 0) or (FromPurchLine."Prod. Order No." <> '')
        then
            exit(false);

        Item.Get(FromPurchLine."No.");
        if Item.IsNonInventoriableType then
            exit(false);

        if IsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink) or
           not FillExactCostRevLink or MoveNegLines or
           not ExactCostRevMandatory
        then
            exit(false);

        IsHandled := false;
        OnSplitPstdPurchLinesPerILEOnBeforeCheckJobNo(FromPurchLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if FromPurchLine."Job No." <> '' then
            exit(false);

        with ItemLedgEntry do begin
            FindSet;
            if Quantity <= 0 then begin
                FromPurchLineBuf."Document No." := "Document No.";
                if GetPurchDocType(ItemLedgEntry) in
                   [FromPurchLineBuf."Document Type"::Order, FromPurchLineBuf."Document Type"::"Return Order"]
                then
                    FromPurchLineBuf."Receipt Line No." := 1;
                exit(false);
            end;
            OrgQtyBase := FromPurchLine."Quantity (Base)";
            repeat
                if not ApplyFully then begin
                    ApplyRec.AppliedOutbndEntryExists("Entry No.", false, false);
                    if ApplyRec.Find('-') then
                        SkippedLine := SkippedLine or ApplyRec.Find('-');
                end;
                if ApplyFully then begin
                    ApplyRec.AppliedOutbndEntryExists("Entry No.", false, false);
                    if ApplyRec.Find('-') then
                        repeat
                            SomeAreFixed := SomeAreFixed or ApplyRec.Fixed;
                        until ApplyRec.Next = 0;
                end;

                if AskApply and ("Item Tracking" = "Item Tracking"::None) then
                    if not ("Remaining Quantity" > 0) or ("Item Tracking" <> "Item Tracking"::None) then
                        ConfirmApply;
                if AskApply then
                    if "Remaining Quantity" < Abs(FromPurchLine."Quantity (Base)") then
                        ConfirmApply;
                if ("Remaining Quantity" > 0) or ApplyFully then begin
                    FromPurchLineBuf := FromPurchLine;
                    if "Remaining Quantity" < Abs(FromPurchLine."Quantity (Base)") then
                        if not ApplyFully then begin
                            if FromPurchLine."Quantity (Base)" > 0 then
                                FromPurchLineBuf."Quantity (Base)" := "Remaining Quantity"
                            else
                                FromPurchLineBuf."Quantity (Base)" := -"Remaining Quantity";
                            ConvertFromBase(
                              FromPurchLineBuf.Quantity, FromPurchLineBuf."Quantity (Base)", FromPurchLineBuf."Qty. per Unit of Measure");
                        end else begin
                            ReappDone := true;
                            FromPurchLineBuf."Quantity (Base)" := Sign(Quantity) * Quantity - ApplyRec.Returned("Entry No.");
                            ConvertFromBase(
                              FromPurchLineBuf.Quantity, FromPurchLineBuf."Quantity (Base)", FromPurchLineBuf."Qty. per Unit of Measure");
                        end;
                    FromPurchLine."Quantity (Base)" := FromPurchLine."Quantity (Base)" - FromPurchLineBuf."Quantity (Base)";
                    FromPurchLine.Quantity := FromPurchLine.Quantity - FromPurchLineBuf.Quantity;
                    FromPurchLineBuf."Appl.-to Item Entry" := "Entry No.";
                    NextLineNo := NextLineNo + 1;
                    FromPurchLineBuf."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    FromPurchLineBuf."Document No." := "Document No.";
                    if GetPurchDocType(ItemLedgEntry) in
                       [FromPurchLineBuf."Document Type"::Order, FromPurchLineBuf."Document Type"::"Return Order"]
                    then
                        FromPurchLineBuf."Receipt Line No." := 1;

                    if not FromShptOrRcpt then
                        UpdateRevPurchLineAmount(
                          FromPurchLineBuf, OrgQtyBase,
                          FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT");
                    if FromPurchLineBuf.Quantity <> 0 then begin
                        FromPurchLineBuf.Insert();
                        AddPurchDocLine(TempDocPurchaseLine, FromPurchLineBuf."Line No.", "Document No.", FromPurchLineBuf."Line No.");
                    end else
                        SkippedLine := true;
                end else
                    if "Remaining Quantity" = 0 then
                        SkippedLine := true;
            until (Next = 0) or (FromPurchLine."Quantity (Base)" = 0);

            if (FromPurchLine."Quantity (Base)" <> 0) and FillExactCostRevLink then
                MissingExCostRevLink := true;
        end;
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);

        exit(true);
    end;

    local procedure SplitPurchDocLinesPerItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var FromPurchLineBuf: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; var TempDocPurchaseLine: Record "Purchase Line" temporary; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        PurchLineBuf: array[2] of Record "Purchase Line" temporary;
        ApplyRec: Record "Item Application Entry";
        Tracked: Boolean;
        RemainingQtyBase: Decimal;
        SignFactor: Integer;
        i: Integer;
    begin
        if FromShptOrRcpt then begin
            FromPurchLineBuf.Reset();
            FromPurchLineBuf.DeleteAll();
            TempItemTrkgEntry.Reset();
            TempItemTrkgEntry.DeleteAll();
        end else
            FromPurchLineBuf.Init();

        if MoveNegLines or not ExactCostRevMandatory then
            exit(false);

        if FromPurchLine."Quantity (Base)" < 0 then
            SignFactor := -1
        else
            SignFactor := 1;

        with ItemLedgEntry do begin
            SetCurrentKey("Document No.", "Document Type", "Document Line No.");
            FindSet;
            repeat
                PurchLineBuf[1] := FromPurchLine;
                PurchLineBuf[1]."Line No." := NextLineNo;
                PurchLineBuf[1]."Quantity (Base)" := 0;
                PurchLineBuf[1].Quantity := 0;
                PurchLineBuf[1]."Document No." := "Document No.";
                if GetPurchDocType(ItemLedgEntry) in
                   [PurchLineBuf[1]."Document Type"::Order, PurchLineBuf[1]."Document Type"::"Return Order"]
                then
                    PurchLineBuf[1]."Receipt Line No." := 1;
                PurchLineBuf[2] := PurchLineBuf[1];
                PurchLineBuf[2]."Line No." := PurchLineBuf[2]."Line No." + 1;

                if not FromShptOrRcpt then begin
                    SetRange("Document No.", "Document No.");
                    SetRange("Document Type", "Document Type");
                    SetRange("Document Line No.", "Document Line No.");
                end;
                repeat
                    i := 1;
                    if Positive then
                        "Remaining Quantity" :=
                          "Remaining Quantity" -
                          CalcDistributedQty(TempItemTrkgEntry, ItemLedgEntry, PurchLineBuf[2]."Line No." + 1);

                    if "Document Type" in ["Document Type"::"Purchase Return Shipment", "Document Type"::"Purchase Credit Memo"] then
                        if -"Shipped Qty. Not Returned" < FromPurchLine."Quantity (Base)" * SignFactor then
                            RemainingQtyBase := -"Shipped Qty. Not Returned" * SignFactor
                        else
                            RemainingQtyBase := FromPurchLine."Quantity (Base)"
                    else
                        if not Positive then begin
                            RemainingQtyBase := -"Shipped Qty. Not Returned";
                            if RemainingQtyBase < FromPurchLine."Quantity (Base)" * SignFactor then
                                RemainingQtyBase := RemainingQtyBase * SignFactor
                            else
                                RemainingQtyBase := FromPurchLine."Quantity (Base)";
                        end else
                            if "Remaining Quantity" < FromPurchLine."Quantity (Base)" * SignFactor then begin
                                if ("Item Tracking" = "Item Tracking"::None) and AskApply then
                                    ConfirmApply;
                                if (not ApplyFully) or ("Item Tracking" <> "Item Tracking"::None) then
                                    RemainingQtyBase := GetQtyOfPurchILENotShipped("Entry No.") * SignFactor
                                else
                                    RemainingQtyBase := FromPurchLine."Quantity (Base)" - ApplyRec.Returned("Entry No.");
                            end else
                                RemainingQtyBase := FromPurchLine."Quantity (Base)";

                    if RemainingQtyBase <> 0 then begin
                        if Positive then
                            if IsSplitItemLedgEntry(ItemLedgEntry) then
                                i := 2;

                        PurchLineBuf[i]."Quantity (Base)" := PurchLineBuf[i]."Quantity (Base)" + RemainingQtyBase;
                        if PurchLineBuf[i]."Qty. per Unit of Measure" = 0 then
                            PurchLineBuf[i].Quantity := PurchLineBuf[i]."Quantity (Base)"
                        else
                            PurchLineBuf[i].Quantity :=
                              Round(
                                PurchLineBuf[i]."Quantity (Base)" / PurchLineBuf[i]."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                        FromPurchLine."Quantity (Base)" := FromPurchLine."Quantity (Base)" - RemainingQtyBase;
                        // Fill buffer with exact cost reversing link for remaining quantity
                        if "Document Type" in ["Document Type"::"Purchase Return Shipment", "Document Type"::"Purchase Credit Memo"] then
                            InsertTempItemTrkgEntry(
                              ItemLedgEntry, TempItemTrkgEntry, -Abs(RemainingQtyBase),
                              PurchLineBuf[i]."Line No.", NextItemTrkgEntryNo, true)
                        else
                            InsertTempItemTrkgEntry(
                              ItemLedgEntry, TempItemTrkgEntry, Abs(RemainingQtyBase),
                              PurchLineBuf[i]."Line No.", NextItemTrkgEntryNo, true);
                        Tracked := true;
                    end else
                        SkippedLine := true;
                until (Next = 0) or (FromPurchLine."Quantity (Base)" = 0);

                for i := 1 to 2 do
                    if PurchLineBuf[i]."Quantity (Base)" <> 0 then begin
                        FromPurchLineBuf := PurchLineBuf[i];
                        FromPurchLineBuf.Insert();
                        AddPurchDocLine(TempDocPurchaseLine, FromPurchLineBuf."Line No.", "Document No.", FromPurchLine."Line No.");
                        NextLineNo := PurchLineBuf[i]."Line No." + 1;
                    end;

                if not FromShptOrRcpt then begin
                    SetRange("Document No.");
                    SetRange("Document Type");
                    SetRange("Document Line No.");
                end;
            until (Next = 0) or FromShptOrRcpt;
            if (FromPurchLine."Quantity (Base)" <> 0) and not Tracked then
                MissingExCostRevLink := true;
        end;
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);

        exit(true);
    end;

    local procedure CalcDistributedQty(var TempItemTrkgEntry: Record "Reservation Entry" temporary; ItemLedgEntry: Record "Item Ledger Entry"; NextLineNo: Integer): Decimal
    begin
        with ItemLedgEntry do begin
            TempItemTrkgEntry.Reset();
            TempItemTrkgEntry.SetCurrentKey("Source ID", "Source Ref. No.");
            TempItemTrkgEntry.SetRange("Source ID", "Document No.");
            TempItemTrkgEntry.SetFilter("Source Ref. No.", '<%1', NextLineNo);
            TempItemTrkgEntry.SetRange("Item Ledger Entry No.", "Entry No.");
            TempItemTrkgEntry.CalcSums("Quantity (Base)");
            TempItemTrkgEntry.Reset();
            exit(TempItemTrkgEntry."Quantity (Base)");
        end;
    end;

    [Scope('OnPrem')]
    procedure IsEntityBlocked(TableNo: Integer; CreditDocType: Boolean; Type: Option; EntityNo: Code[20]): Boolean
    var
        GLAccount: Record "G/L Account";
        FixedAsset: Record "Fixed Asset";
        Item: Record Item;
        Resource: Record Resource;
        DummySalesLine: Record "Sales Line";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        MessageType: Option Error,Warning,Information;
        BlockedForSalesPurch: Boolean;
    begin
        if SkipWarningNotification then
            MessageType := MessageType::Error
        else
            MessageType := MessageType::Warning;
        case Type of
            DummySalesLine.Type::"G/L Account":
                if GLAccount.Get(EntityNo) then begin
                    if not GLAccount."Direct Posting" then
                        ErrorMessageMgt.LogMessage(
                          MessageType, 0, StrSubstNo(DirectPostingErr, GLAccount."No."), GLAccount, GLAccount.FieldNo("Direct Posting"), '')
                    else
                        if GLAccount.Blocked then
                            ErrorMessageMgt.LogMessage(
                              MessageType, 0, StrSubstNo(IsBlockedErr, GLAccount.TableCaption, GLAccount."No.")
                              , GLAccount, GLAccount.FieldNo(Blocked), '');
                    exit(not GLAccount."Direct Posting" or GLAccount.Blocked);
                end;
            DummySalesLine.Type::Item:
                if Item.Get(EntityNo) then begin
                    if Item.Blocked then begin
                        ErrorMessageMgt.LogMessage(
                            MessageType, 0, StrSubstNo(IsBlockedErr, Item.TableCaption, Item."No."),
                            Item, Item.FieldNo(Blocked), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                        exit(true);
                    end;
                    case TableNo of
                        database::"Sales Line":
                            if Item."Sales Blocked" and not CreditDocType then begin
                                BlockedForSalesPurch := true;
                                ErrorMessageMgt.LogMessage(
                                    MessageType, 0, StrSubstNo(IsSalesBlockedItemErr, Item."No."), Item,
                                    Item.FieldNo("Sales Blocked"), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                            end;
                        database::"Purchase Line":
                            if Item."Purchasing Blocked" and not CreditDocType then begin
                                BlockedForSalesPurch := true;
                                ErrorMessageMgt.LogMessage(
                                    MessageType, 0, StrSubstNo(IsPurchBlockedItemErr, Item."No."), Item,
                                    Item.FieldNo("Purchasing Blocked"), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                            end;
                        else
                            BlockedForSalesPurch := false;
                    end;
                    exit(BlockedForSalesPurch);
                end;
            DummySalesLine.Type::Resource:
                if Resource.Get(EntityNo) then begin
                    if Resource.Blocked then
                        ErrorMessageMgt.LogMessage(
                          MessageType, 0, StrSubstNo(IsBlockedErr, Resource.TableCaption, Resource."No."), Resource, Resource.FieldNo(Blocked), '');
                    exit(Resource.Blocked);
                end;
            DummySalesLine.Type::"Fixed Asset":
                if FixedAsset.Get(EntityNo) then begin
                    if FixedAsset.Blocked then
                        ErrorMessageMgt.LogMessage(
                          MessageType, 0, StrSubstNo(IsBlockedErr, FixedAsset.TableCaption, FixedAsset."No."),
                          FixedAsset, FixedAsset.FieldNo(Blocked), '')
                    else
                        if FixedAsset.Inactive then
                            ErrorMessageMgt.LogMessage(
                              MessageType, 0, StrSubstNo(FAIsInactiveErr, FixedAsset."No."), FixedAsset, FixedAsset.FieldNo(Inactive), '');
                    exit(FixedAsset.Blocked or FixedAsset.Inactive);
                end;
        end;
    end;

    local procedure IsItemBlocked(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        exit(Item.Get(ItemNo) and Item.Blocked);
    end;

    local procedure IsSplitItemLedgEntry(OrgItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with OrgItemLedgEntry do begin
            ItemLedgEntry.SetCurrentKey("Document No.");
            ItemLedgEntry.SetRange("Document No.", "Document No.");
            ItemLedgEntry.SetRange("Document Type", "Document Type");
            ItemLedgEntry.SetRange("Document Line No.", "Document Line No.");
            ItemLedgEntry.SetRange("Lot No.", "Lot No.");
            ItemLedgEntry.SetRange("Serial No.", "Serial No.");
            ItemLedgEntry.SetFilter("Entry No.", '<%1', "Entry No.");
            exit(not ItemLedgEntry.IsEmpty);
        end;
    end;

    local procedure IsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var CopyItemTrkg: Boolean; FillExactCostRevLink: Boolean): Boolean
    begin
        with ItemLedgEntry do begin
            if IsEmpty then
                exit(true);
            SetFilter("Lot No.", '<>''''');
            if not IsEmpty then begin
                if FillExactCostRevLink then
                    CopyItemTrkg := true;
                exit(true);
            end;
            SetRange("Lot No.");
            SetFilter("Serial No.", '<>''''');
            if not IsEmpty then begin
                if FillExactCostRevLink then
                    CopyItemTrkg := true;
                exit(true);
            end;
            SetRange("Serial No.");
        end;
        exit(false);
    end;

    local procedure InsertTempItemTrkgEntry(ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry"; QtyBase: Decimal; DocLineNo: Integer; var NextEntryNo: Integer; FillExactCostRevLink: Boolean)
    begin
        if QtyBase = 0 then
            exit;

        with ItemLedgEntry do begin
            TempItemTrkgEntry.Init();
            TempItemTrkgEntry."Entry No." := NextEntryNo;
            NextEntryNo := NextEntryNo + 1;
            if not FillExactCostRevLink then
                TempItemTrkgEntry."Reservation Status" := TempItemTrkgEntry."Reservation Status"::Prospect;
            TempItemTrkgEntry."Source ID" := "Document No.";
            TempItemTrkgEntry."Source Ref. No." := DocLineNo;
            TempItemTrkgEntry."Item Ledger Entry No." := "Entry No.";
            TempItemTrkgEntry."Quantity (Base)" := QtyBase;
            TempItemTrkgEntry.Insert();
        end;
    end;

    local procedure GetLastToSalesLineNo(ToSalesHeader: Record "Sales Header"): Decimal
    var
        ToSalesLine: Record "Sales Line";
    begin
        ToSalesLine.LockTable();
        ToSalesLine.SetRange("Document Type", ToSalesHeader."Document Type");
        ToSalesLine.SetRange("Document No.", ToSalesHeader."No.");
        if ToSalesLine.FindLast then
            exit(ToSalesLine."Line No.");
        exit(0);
    end;

    local procedure GetLastToPurchLineNo(ToPurchHeader: Record "Purchase Header"): Decimal
    var
        ToPurchLine: Record "Purchase Line";
    begin
        ToPurchLine.LockTable();
        ToPurchLine.SetRange("Document Type", ToPurchHeader."Document Type");
        ToPurchLine.SetRange("Document No.", ToPurchHeader."No.");
        if ToPurchLine.FindLast then
            exit(ToPurchLine."Line No.");
        exit(0);
    end;

    local procedure InsertOldSalesDocNoLine(ToSalesHeader: Record "Sales Header"; OldDocNo: Code[20]; OldDocType: Integer; var NextLineNo: Integer)
    var
        ToSalesLine2: Record "Sales Line";
        IsHandled: Boolean;
    begin
        if SkipCopyFromDescription then
            exit;

        NextLineNo := NextLineNo + 10000;
        ToSalesLine2.Init();
        ToSalesLine2."Line No." := NextLineNo;
        ToSalesLine2."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine2."Document No." := ToSalesHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToSalesHeader."Language Code");
        if InsertCancellationLine then
            ToSalesLine2.Description := StrSubstNo(CrMemoCancellationMsg, OldDocNo)
        else
            ToSalesLine2.Description := StrSubstNo(Text015, SelectStr(OldDocType, Text013), OldDocNo);
        TranslationHelper.RestoreGlobalLanguage;

        IsHandled := false;
        OnBeforeInsertOldSalesDocNoLine(ToSalesHeader, ToSalesLine2, OldDocType, OldDocNo, IsHandled);
        if not IsHandled then
            ToSalesLine2.Insert();
    end;

    local procedure InsertOldSalesCombDocNoLine(ToSalesHeader: Record "Sales Header"; OldDocNo: Code[20]; OldDocNo2: Code[20]; var NextLineNo: Integer; CopyFromInvoice: Boolean)
    var
        ToSalesLine2: Record "Sales Line";
    begin
        NextLineNo := NextLineNo + 10000;
        ToSalesLine2.Init();
        ToSalesLine2."Line No." := NextLineNo;
        ToSalesLine2."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine2."Document No." := ToSalesHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToSalesHeader."Language Code");
        if CopyFromInvoice then
            ToSalesLine2.Description :=
              StrSubstNo(
                Text018,
                CopyStr(SelectStr(1, Text016) + OldDocNo, 1, 23),
                CopyStr(SelectStr(2, Text016) + OldDocNo2, 1, 23))
        else
            ToSalesLine2.Description :=
              StrSubstNo(
                Text018,
                CopyStr(SelectStr(3, Text016) + OldDocNo, 1, 23),
                CopyStr(SelectStr(4, Text016) + OldDocNo2, 1, 23));
        TranslationHelper.RestoreGlobalLanguage;

        OnBeforeInsertOldSalesCombDocNoLine(ToSalesHeader, ToSalesLine2, CopyFromInvoice, OldDocNo, OldDocNo2);
        ToSalesLine2.Insert();
    end;

    local procedure InsertOldPurchDocNoLine(ToPurchHeader: Record "Purchase Header"; OldDocNo: Code[20]; OldDocType: Integer; var NextLineNo: Integer)
    var
        ToPurchLine2: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if SkipCopyFromDescription then
            exit;

        NextLineNo := NextLineNo + 10000;
        ToPurchLine2.Init();
        ToPurchLine2."Line No." := NextLineNo;
        ToPurchLine2."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine2."Document No." := ToPurchHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToPurchHeader."Language Code");
        if InsertCancellationLine then
            ToPurchLine2.Description := StrSubstNo(CrMemoCancellationMsg, OldDocNo)
        else
            ToPurchLine2.Description := StrSubstNo(Text015, SelectStr(OldDocType, Text014), OldDocNo);
        TranslationHelper.RestoreGlobalLanguage;

        IsHandled := false;
        OnBeforeInsertOldPurchDocNoLine(ToPurchHeader, ToPurchLine2, OldDocType, OldDocNo, IsHandled);
        if not IsHandled then
            ToPurchLine2.Insert();
    end;

    local procedure InsertOldPurchCombDocNoLine(ToPurchHeader: Record "Purchase Header"; OldDocNo: Code[20]; OldDocNo2: Code[20]; var NextLineNo: Integer; CopyFromInvoice: Boolean)
    var
        ToPurchLine2: Record "Purchase Line";
    begin
        NextLineNo := NextLineNo + 10000;
        ToPurchLine2.Init();
        ToPurchLine2."Line No." := NextLineNo;
        ToPurchLine2."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine2."Document No." := ToPurchHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToPurchHeader."Language Code");
        if CopyFromInvoice then
            ToPurchLine2.Description :=
              StrSubstNo(
                Text018,
                CopyStr(SelectStr(1, Text017) + OldDocNo, 1, 23),
                CopyStr(SelectStr(2, Text017) + OldDocNo2, 1, 23))
        else
            ToPurchLine2.Description :=
              StrSubstNo(
                Text018,
                CopyStr(SelectStr(3, Text017) + OldDocNo, 1, 23),
                CopyStr(SelectStr(4, Text017) + OldDocNo2, 1, 23));
        TranslationHelper.RestoreGlobalLanguage;

        OnBeforeInsertOldPurchCombDocNoLine(ToPurchHeader, ToPurchLine2, CopyFromInvoice, OldDocNo, OldDocNo2);
        ToPurchLine2.Insert();
    end;

    procedure IsSalesFillExactCostRevLink(ToSalesHeader: Record "Sales Header"; FromDocType: Option "Sales Shipment","Sales Invoice","Sales Return Receipt","Sales Credit Memo"; CurrencyCode: Code[10]): Boolean
    begin
        with ToSalesHeader do
            case FromDocType of
                FromDocType::"Sales Shipment":
                    exit("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]);
                FromDocType::"Sales Invoice":
                    exit(
                      ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) and
                      ("Currency Code" = CurrencyCode));
                FromDocType::"Sales Return Receipt":
                    exit("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]);
                FromDocType::"Sales Credit Memo":
                    exit(
                      ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) and
                      ("Currency Code" = CurrencyCode));
            end;
        exit(false);
    end;

    procedure IsPurchFillExactCostRevLink(ToPurchHeader: Record "Purchase Header"; FromDocType: Option "Purchase Receipt","Purchase Invoice","Purchase Return Shipment","Purchase Credit Memo"; CurrencyCode: Code[10]): Boolean
    begin
        with ToPurchHeader do
            case FromDocType of
                FromDocType::"Purchase Receipt":
                    exit("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]);
                FromDocType::"Purchase Invoice":
                    exit(
                      ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) and
                      ("Currency Code" = CurrencyCode));
                FromDocType::"Purchase Return Shipment":
                    exit("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]);
                FromDocType::"Purchase Credit Memo":
                    exit(
                      ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) and
                      ("Currency Code" = CurrencyCode));
            end;
        exit(false);
    end;

    local procedure GetSalesDocType(ItemLedgEntry: Record "Item Ledger Entry"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        with ItemLedgEntry do
            case "Document Type" of
                "Document Type"::"Sales Shipment":
                    exit(SalesLine."Document Type"::Order);
                "Document Type"::"Sales Invoice":
                    exit(SalesLine."Document Type"::Invoice);
                "Document Type"::"Sales Credit Memo":
                    exit(SalesLine."Document Type"::"Credit Memo");
                "Document Type"::"Sales Return Receipt":
                    exit(SalesLine."Document Type"::"Return Order");
            end;
    end;

    local procedure GetPurchDocType(ItemLedgEntry: Record "Item Ledger Entry"): Integer
    var
        PurchLine: Record "Purchase Line";
    begin
        with ItemLedgEntry do
            case "Document Type" of
                "Document Type"::"Purchase Receipt":
                    exit(PurchLine."Document Type"::Order);
                "Document Type"::"Purchase Invoice":
                    exit(PurchLine."Document Type"::Invoice);
                "Document Type"::"Purchase Credit Memo":
                    exit(PurchLine."Document Type"::"Credit Memo");
                "Document Type"::"Purchase Return Shipment":
                    exit(PurchLine."Document Type"::"Return Order");
            end;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            if not Item.Get(ItemNo) then
                Item.Init();
    end;

    local procedure CalcVAT(var Value: Decimal; VATPercentage: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; RndgPrecision: Decimal)
    begin
        if (ToPricesInclVAT = FromPricesInclVAT) or (Value = 0) then
            exit;

        if ToPricesInclVAT then
            Value := Round(Value * (100 + VATPercentage) / 100, RndgPrecision)
        else
            Value := Round(Value * 100 / (100 + VATPercentage), RndgPrecision);
    end;

    local procedure ReCalcSalesLine(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        SalesLineAmount: Decimal;
    begin
        with ToSalesHeader do begin
            if not IsRecalculateAmount(
                 FromSalesHeader."Currency Code", "Currency Code",
                 FromSalesHeader."Prices Including VAT", "Prices Including VAT")
            then
                exit;

            if FromSalesHeader."Currency Code" <> "Currency Code" then begin
                if SalesLine.Quantity <> 0 then
                    SalesLineAmount := SalesLine."Unit Price" * SalesLine.Quantity
                else
                    SalesLineAmount := SalesLine."Unit Price";
                if FromSalesHeader."Currency Code" <> '' then begin
                    SalesLineAmount :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                        SalesLineAmount, FromSalesHeader."Currency Factor");
                    SalesLine."Line Discount Amount" :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                        SalesLine."Line Discount Amount", FromSalesHeader."Currency Factor");
                    SalesLine."Inv. Discount Amount" :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                        SalesLine."Inv. Discount Amount", FromSalesHeader."Currency Factor");
                end;

                if "Currency Code" <> '' then begin
                    SalesLineAmount :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", SalesLineAmount, "Currency Factor");
                    SalesLine."Line Discount Amount" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", SalesLine."Line Discount Amount", "Currency Factor");
                    SalesLine."Inv. Discount Amount" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", SalesLine."Inv. Discount Amount", "Currency Factor");
                end;
            end;

            SalesLine."Currency Code" := "Currency Code";
            if SalesLine.Quantity <> 0 then begin
                SalesLineAmount := Round(SalesLineAmount, Currency."Amount Rounding Precision");
                SalesLine."Unit Price" := Round(SalesLineAmount / SalesLine.Quantity, Currency."Unit-Amount Rounding Precision");
            end else
                SalesLine."Unit Price" := Round(SalesLineAmount, Currency."Unit-Amount Rounding Precision");
            SalesLine."Line Discount Amount" := Round(SalesLine."Line Discount Amount", Currency."Amount Rounding Precision");
            SalesLine."Inv. Discount Amount" := Round(SalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision");

            CalcVAT(
              SalesLine."Unit Price", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Unit-Amount Rounding Precision");
            CalcVAT(
              SalesLine."Line Discount Amount", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Amount Rounding Precision");
            CalcVAT(
              SalesLine."Inv. Discount Amount", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Amount Rounding Precision");
        end;
    end;

    local procedure ReCalcPurchLine(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        PurchLineAmount: Decimal;
    begin
        with ToPurchHeader do begin
            if not IsRecalculateAmount(
                 FromPurchHeader."Currency Code", "Currency Code",
                 FromPurchHeader."Prices Including VAT", "Prices Including VAT")
            then
                exit;

            if FromPurchHeader."Currency Code" <> "Currency Code" then begin
                if PurchLine.Quantity <> 0 then
                    PurchLineAmount := PurchLine."Direct Unit Cost" * PurchLine.Quantity
                else
                    PurchLineAmount := PurchLine."Direct Unit Cost";
                if FromPurchHeader."Currency Code" <> '' then begin
                    PurchLineAmount :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                        PurchLineAmount, FromPurchHeader."Currency Factor");
                    PurchLine."Line Discount Amount" :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                        PurchLine."Line Discount Amount", FromPurchHeader."Currency Factor");
                    PurchLine."Inv. Discount Amount" :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                        PurchLine."Inv. Discount Amount", FromPurchHeader."Currency Factor");
                end;

                if "Currency Code" <> '' then begin
                    PurchLineAmount :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", PurchLineAmount, "Currency Factor");
                    PurchLine."Line Discount Amount" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", PurchLine."Line Discount Amount", "Currency Factor");
                    PurchLine."Inv. Discount Amount" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code", PurchLine."Inv. Discount Amount", "Currency Factor");
                end;
            end;

            PurchLine."Currency Code" := "Currency Code";
            if PurchLine.Quantity <> 0 then begin
                PurchLineAmount := Round(PurchLineAmount, Currency."Amount Rounding Precision");
                PurchLine."Direct Unit Cost" := Round(PurchLineAmount / PurchLine.Quantity, Currency."Unit-Amount Rounding Precision");
            end else
                PurchLine."Direct Unit Cost" := Round(PurchLineAmount, Currency."Unit-Amount Rounding Precision");
            PurchLine."Line Discount Amount" := Round(PurchLine."Line Discount Amount", Currency."Amount Rounding Precision");
            PurchLine."Inv. Discount Amount" := Round(PurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision");

            CalcVAT(
              PurchLine."Direct Unit Cost", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Unit-Amount Rounding Precision");
            CalcVAT(
              PurchLine."Line Discount Amount", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Amount Rounding Precision");
            CalcVAT(
              PurchLine."Inv. Discount Amount", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
              "Prices Including VAT", Currency."Amount Rounding Precision");
        end;
    end;

    local procedure IsRecalculateAmount(FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean): Boolean
    begin
        exit(
          (FromCurrencyCode <> ToCurrencyCode) or
          (FromPricesInclVAT <> ToPricesInclVAT));
    end;

    local procedure UpdateRevSalesLineAmount(var SalesLine: Record "Sales Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        Amount: Decimal;
    begin
        if (OrgQtyBase = 0) or (SalesLine.Quantity = 0) or
           ((FromPricesInclVAT = ToPricesInclVAT) and (OrgQtyBase = SalesLine."Quantity (Base)"))
        then
            exit;

        Amount := SalesLine.Quantity * SalesLine."Unit Price";
        CalcVAT(
          Amount, SalesLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        SalesLine."Unit Price" := Amount / SalesLine.Quantity;
        SalesLine."Line Discount Amount" :=
          Round(
            Round(SalesLine.Quantity * SalesLine."Unit Price", Currency."Amount Rounding Precision") *
            SalesLine."Line Discount %" / 100,
            Currency."Amount Rounding Precision");
        Amount :=
          Round(SalesLine."Inv. Discount Amount" / OrgQtyBase * SalesLine."Quantity (Base)", Currency."Amount Rounding Precision");
        CalcVAT(
          Amount, SalesLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        SalesLine."Inv. Discount Amount" := Amount;
    end;

    procedure CalculateRevSalesLineAmount(var SalesLine: Record "Sales Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        UnitPrice: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        UpdateRevSalesLineAmount(SalesLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);

        UnitPrice := SalesLine."Unit Price";
        LineDiscAmt := SalesLine."Line Discount Amount";
        InvDiscAmt := SalesLine."Inv. Discount Amount";

        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount Amount", LineDiscAmt);
        SalesLine.Validate("Inv. Discount Amount", InvDiscAmt);
    end;

    local procedure UpdateRevPurchLineAmount(var PurchLine: Record "Purchase Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        Amount: Decimal;
    begin
        if (OrgQtyBase = 0) or (PurchLine.Quantity = 0) or
           ((FromPricesInclVAT = ToPricesInclVAT) and (OrgQtyBase = PurchLine."Quantity (Base)"))
        then
            exit;

        Amount := PurchLine.Quantity * PurchLine."Direct Unit Cost";
        CalcVAT(
          Amount, PurchLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        PurchLine."Direct Unit Cost" := Amount / PurchLine.Quantity;
        PurchLine."Line Discount Amount" :=
          Round(
            Round(PurchLine.Quantity * PurchLine."Direct Unit Cost", Currency."Amount Rounding Precision") *
            PurchLine."Line Discount %" / 100,
            Currency."Amount Rounding Precision");
        Amount :=
          Round(PurchLine."Inv. Discount Amount" / OrgQtyBase * PurchLine."Quantity (Base)", Currency."Amount Rounding Precision");
        CalcVAT(
          Amount, PurchLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        PurchLine."Inv. Discount Amount" := Amount;
    end;

    procedure CalculateRevPurchLineAmount(var PurchLine: Record "Purchase Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        DirectUnitCost: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        UpdateRevPurchLineAmount(PurchLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);

        DirectUnitCost := PurchLine."Direct Unit Cost";
        LineDiscAmt := PurchLine."Line Discount Amount";
        InvDiscAmt := PurchLine."Inv. Discount Amount";

        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Validate("Line Discount Amount", LineDiscAmt);
        PurchLine.Validate("Inv. Discount Amount", InvDiscAmt);
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision;

        Currency.TestField("Unit-Amount Rounding Precision");
        Currency.TestField("Amount Rounding Precision");
    end;

    local procedure OpenWindow()
    begin
        Window.Open(
          Text022 +
          Text023 +
          Text024);
        WindowUpdateDateTime := CurrentDateTime;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    local procedure ConfirmApply()
    begin
        AskApply := false;
        ApplyFully := false;
    end;

    local procedure ConvertFromBase(var Quantity: Decimal; QuantityBase: Decimal; QtyPerUOM: Decimal)
    begin
        if QtyPerUOM = 0 then
            Quantity := QuantityBase
        else
            Quantity := Round(QuantityBase / QtyPerUOM, UOMMgt.QtyRndPrecision);
    end;

    local procedure Sign(Quantity: Decimal): Decimal
    begin
        if Quantity < 0 then
            exit(-1);
        exit(1);
    end;

    procedure ShowMessageReapply(OriginalQuantity: Boolean)
    var
        Text: Text[1024];
    begin
        Text := '';
        if SkippedLine then
            Text := Text029;
        if OriginalQuantity and ReappDone then
            if Text = '' then
                Text := Text025;
        if SomeAreFixed then
            Message(Text031);
        if Text <> '' then
            Message(Text);
    end;

    local procedure LinkJobPlanningLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        repeat
            JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
            if JobPlanningLine.FindFirst then begin
                JobPlanningLineInvoice."Job No." := JobPlanningLine."Job No.";
                JobPlanningLineInvoice."Job Task No." := JobPlanningLine."Job Task No.";
                JobPlanningLineInvoice."Job Planning Line No." := JobPlanningLine."Line No.";
                case SalesHeader."Document Type" of
                    SalesHeader."Document Type"::Invoice:
                        begin
                            JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::Invoice;
                            JobPlanningLineInvoice."Quantity Transferred" := SalesLine.Quantity;
                        end;
                    SalesHeader."Document Type"::"Credit Memo":
                        begin
                            JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Credit Memo";
                            JobPlanningLineInvoice."Quantity Transferred" := -SalesLine.Quantity;
                        end;
                    else
                        exit;
                end;
                JobPlanningLineInvoice."Document No." := SalesHeader."No.";
                JobPlanningLineInvoice."Line No." := SalesLine."Line No.";
                JobPlanningLineInvoice."Transferred Date" := SalesHeader."Posting Date";
                JobPlanningLineInvoice.Insert();

                JobPlanningLine.UpdateQtyToTransfer();
                JobPlanningLine.Modify();
                OnLinkJobPlanningLineOnAfterJobPlanningLineModify(JobPlanningLineInvoice, JobPlanningLine);
            end;
        until SalesLine.Next = 0;
    end;

    local procedure GetQtyOfPurchILENotShipped(ItemLedgerEntryNo: Integer): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntryLocal: Record "Item Ledger Entry";
        QtyNotShipped: Decimal;
    begin
        QtyNotShipped := 0;
        with ItemApplicationEntry do begin
            Reset;
            SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
            SetRange("Inbound Item Entry No.", ItemLedgerEntryNo);
            SetRange("Outbound Item Entry No.", 0);
            if not FindFirst then
                exit(QtyNotShipped);
            QtyNotShipped := Quantity;
            SetFilter("Outbound Item Entry No.", '<>0');
            if not FindSet(false, false) then
                exit(QtyNotShipped);
            repeat
                ItemLedgerEntryLocal.Get("Outbound Item Entry No.");
                if (ItemLedgerEntryLocal."Entry Type" in
                    [ItemLedgerEntryLocal."Entry Type"::Sale,
                     ItemLedgerEntryLocal."Entry Type"::Purchase]) or
                   ((ItemLedgerEntryLocal."Entry Type" in
                     [ItemLedgerEntryLocal."Entry Type"::"Positive Adjmt.", ItemLedgerEntryLocal."Entry Type"::"Negative Adjmt."]) and
                    (ItemLedgerEntryLocal."Job No." = ''))
                then
                    QtyNotShipped += Quantity;
            until Next = 0;
        end;
        exit(QtyNotShipped);
    end;

    local procedure CopyAsmOrderToAsmOrder(var TempFromAsmHeader: Record "Assembly Header" temporary; var TempFromAsmLine: Record "Assembly Line" temporary; ToSalesLine: Record "Sales Line"; ToAsmHeaderDocType: Integer; ToAsmHeaderDocNo: Code[20]; InclAsmHeader: Boolean)
    var
        FromAsmHeader: Record "Assembly Header";
        ToAsmHeader: Record "Assembly Header";
        TempToAsmHeader: Record "Assembly Header" temporary;
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        ToAsmLine: Record "Assembly Line";
        BasicAsmOrderCopy: Boolean;
    begin
        if ToAsmHeaderDocType = -1 then
            exit;
        BasicAsmOrderCopy := ToAsmHeaderDocNo <> '';
        if BasicAsmOrderCopy then
            ToAsmHeader.Get(ToAsmHeaderDocType, ToAsmHeaderDocNo)
        else begin
            if ToSalesLine.AsmToOrderExists(FromAsmHeader) then
                exit;
            Clear(ToAsmHeader);
            AssembleToOrderLink.InsertAsmHeader(ToAsmHeader, ToAsmHeaderDocType, '');
            InclAsmHeader := true;
        end;

        if InclAsmHeader then begin
            if BasicAsmOrderCopy then begin
                TempToAsmHeader := ToAsmHeader;
                TempToAsmHeader.Insert();
                ProcessToAsmHeader(TempToAsmHeader, TempFromAsmHeader, ToSalesLine, true, true); // Basic, Availabilitycheck
                CheckAsmOrderAvailability(TempToAsmHeader, TempFromAsmLine, ToSalesLine);
            end;
            ProcessToAsmHeader(ToAsmHeader, TempFromAsmHeader, ToSalesLine, BasicAsmOrderCopy, false);
        end else
            if BasicAsmOrderCopy then
                CheckAsmOrderAvailability(ToAsmHeader, TempFromAsmLine, ToSalesLine);
        CreateToAsmLines(ToAsmHeader, TempFromAsmLine, ToAsmLine, ToSalesLine, BasicAsmOrderCopy, false);
        if not BasicAsmOrderCopy then
            with AssembleToOrderLink do begin
                "Assembly Document Type" := ToAsmHeader."Document Type";
                "Assembly Document No." := ToAsmHeader."No.";
                Type := Type::Sale;
                "Document Type" := ToSalesLine."Document Type";
                "Document No." := ToSalesLine."Document No.";
                "Document Line No." := ToSalesLine."Line No.";
                Insert;
                if ToSalesLine."Document Type" = ToSalesLine."Document Type"::Order then begin
                    if ToSalesLine."Shipment Date" = 0D then begin
                        ToSalesLine."Shipment Date" := ToAsmHeader."Due Date";
                        ToSalesLine.Modify();
                    end;
                    ReserveAsmToSale(ToSalesLine, ToSalesLine.Quantity, ToSalesLine."Quantity (Base)");
                end;
            end;

        ToAsmHeader.ShowDueDateBeforeWorkDateMsg;
    end;

    procedure CopyAsmHeaderToAsmHeader(FromAsmHeader: Record "Assembly Header"; ToAsmHeader: Record "Assembly Header"; IncludeHeader: Boolean)
    var
        EmptyToSalesLine: Record "Sales Line";
    begin
        InitialToAsmHeaderCheck(ToAsmHeader, IncludeHeader);
        GenerateAsmDataFromNonPosted(FromAsmHeader);
        Clear(EmptyToSalesLine);
        EmptyToSalesLine.Init();
        CopyAsmOrderToAsmOrder(TempAsmHeader, TempAsmLine, EmptyToSalesLine, ToAsmHeader."Document Type", ToAsmHeader."No.", IncludeHeader);
    end;

    procedure CopyPostedAsmHeaderToAsmHeader(PostedAsmHeader: Record "Posted Assembly Header"; ToAsmHeader: Record "Assembly Header"; IncludeHeader: Boolean)
    var
        EmptyToSalesLine: Record "Sales Line";
    begin
        InitialToAsmHeaderCheck(ToAsmHeader, IncludeHeader);
        GenerateAsmDataFromPosted(PostedAsmHeader, 0);
        Clear(EmptyToSalesLine);
        EmptyToSalesLine.Init();
        CopyAsmOrderToAsmOrder(TempAsmHeader, TempAsmLine, EmptyToSalesLine, ToAsmHeader."Document Type", ToAsmHeader."No.", IncludeHeader);
    end;

    local procedure GenerateAsmDataFromNonPosted(AsmHeader: Record "Assembly Header")
    var
        AsmLine: Record "Assembly Line";
    begin
        InitAsmCopyHandling(false);
        TempAsmHeader := AsmHeader;
        TempAsmHeader.Insert();
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        if AsmLine.FindSet then
            repeat
                TempAsmLine := AsmLine;
                TempAsmLine.Insert();
            until AsmLine.Next = 0;
    end;

    local procedure GenerateAsmDataFromPosted(PostedAsmHeader: Record "Posted Assembly Header"; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
    var
        PostedAsmLine: Record "Posted Assembly Line";
    begin
        InitAsmCopyHandling(false);
        TempAsmHeader.TransferFields(PostedAsmHeader);
        OnAfterTransferTempAsmHeader(TempAsmHeader, PostedAsmHeader);
        case DocType of
            DocType::Quote:
                TempAsmHeader."Document Type" := TempAsmHeader."Document Type"::Quote;
            DocType::Order:
                TempAsmHeader."Document Type" := TempAsmHeader."Document Type"::Order;
            DocType::"Blanket Order":
                TempAsmHeader."Document Type" := TempAsmHeader."Document Type"::"Blanket Order";
            else
                exit;
        end;
        TempAsmHeader.Insert();
        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
        if PostedAsmLine.FindSet then
            repeat
                TempAsmLine.TransferFields(PostedAsmLine);
                TempAsmLine."Document No." := TempAsmHeader."No.";
                TempAsmLine."Cost Amount" := PostedAsmLine.Quantity * PostedAsmLine."Unit Cost";
                TempAsmLine.Insert();
            until PostedAsmLine.Next = 0;
    end;

    local procedure GetAsmDataFromSalesInvLine(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"): Boolean
    var
        ValueEntry: Record "Value Entry";
        ValueEntry2: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        Clear(PostedAsmHeader);
        if TempSalesInvLine.Type <> TempSalesInvLine.Type::Item then
            exit(false);
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", TempSalesInvLine."Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SetRange("Document Line No.", TempSalesInvLine."Line No.");
        if not ValueEntry.FindFirst then
            exit(false);
        if not ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
            exit(false);
        if ItemLedgerEntry."Document Type" <> ItemLedgerEntry."Document Type"::"Sales Shipment" then
            exit(false);
        SalesShipmentLine.Get(ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.");
        if not SalesShipmentLine.AsmToShipmentExists(PostedAsmHeader) then
            exit(false);
        if ValueEntry.Count > 1 then begin
            ValueEntry2.Copy(ValueEntry);
            ValueEntry2.SetFilter("Item Ledger Entry No.", '<>%1', ValueEntry."Item Ledger Entry No.");
            if ValueEntry2.FindSet then
                repeat
                    ItemLedgerEntry2.Get(ValueEntry2."Item Ledger Entry No.");
                    if (ItemLedgerEntry2."Document Type" <> ItemLedgerEntry."Document Type") or
                       (ItemLedgerEntry2."Document No." <> ItemLedgerEntry."Document No.") or
                       (ItemLedgerEntry2."Document Line No." <> ItemLedgerEntry."Document Line No.")
                    then
                        Error(Text032, TempSalesInvLine."Document No.");
                until ValueEntry2.Next = 0;
        end;
        GenerateAsmDataFromPosted(PostedAsmHeader, DocType);
        exit(true);
    end;

    procedure InitAsmCopyHandling(ResetQuantities: Boolean)
    begin
        if ResetQuantities then begin
            QtyToAsmToOrder := 0;
            QtyToAsmToOrderBase := 0;
        end;
        TempAsmHeader.DeleteAll();
        TempAsmLine.DeleteAll();
    end;

    local procedure RetrieveSalesInvLine(SalesLine: Record "Sales Line"; PosNo: Integer; LineCountsEqual: Boolean): Boolean
    begin
        if not LineCountsEqual then
            exit(false);
        TempSalesInvLine.FindSet;
        if PosNo > 1 then
            TempSalesInvLine.Next(PosNo - 1);
        exit((SalesLine.Type = TempSalesInvLine.Type) and (SalesLine."No." = TempSalesInvLine."No."));
    end;

    procedure InitialToAsmHeaderCheck(ToAsmHeader: Record "Assembly Header"; IncludeHeader: Boolean)
    begin
        ToAsmHeader.TestField("No.");
        if IncludeHeader then begin
            ToAsmHeader.TestField("Item No.", '');
            ToAsmHeader.TestField(Quantity, 0);
        end else begin
            ToAsmHeader.TestField("Item No.");
            ToAsmHeader.TestField(Quantity);
        end;
    end;

    local procedure GetAsmOrderType(SalesLineDocType: Option Quote,"Order",,,"Blanket Order"): Integer
    begin
        if SalesLineDocType in [SalesLineDocType::Quote, SalesLineDocType::Order, SalesLineDocType::"Blanket Order"] then
            exit(SalesLineDocType);
        exit(-1);
    end;

    local procedure ProcessToAsmHeader(var ToAsmHeader: Record "Assembly Header"; TempFromAsmHeader: Record "Assembly Header" temporary; ToSalesLine: Record "Sales Line"; BasicAsmOrderCopy: Boolean; AvailabilityCheck: Boolean)
    begin
        with ToAsmHeader do begin
            if AvailabilityCheck then begin
                "Item No." := TempFromAsmHeader."Item No.";
                "Location Code" := TempFromAsmHeader."Location Code";
                "Variant Code" := TempFromAsmHeader."Variant Code";
                "Unit of Measure Code" := TempFromAsmHeader."Unit of Measure Code";
            end else begin
                Validate("Item No.", TempFromAsmHeader."Item No.");
                Validate("Location Code", TempFromAsmHeader."Location Code");
                Validate("Variant Code", TempFromAsmHeader."Variant Code");
                Validate("Unit of Measure Code", TempFromAsmHeader."Unit of Measure Code");
            end;
            if BasicAsmOrderCopy then begin
                Validate("Due Date", TempFromAsmHeader."Due Date");
                Quantity := TempFromAsmHeader.Quantity;
                "Quantity (Base)" := TempFromAsmHeader."Quantity (Base)";
            end else begin
                if ToSalesLine."Shipment Date" <> 0D then
                    Validate("Due Date", ToSalesLine."Shipment Date");
                Quantity := QtyToAsmToOrder;
                "Quantity (Base)" := QtyToAsmToOrderBase;
            end;
            "Bin Code" := TempFromAsmHeader."Bin Code";
            "Unit Cost" := TempFromAsmHeader."Unit Cost";
            RoundQty(Quantity);
            RoundQty("Quantity (Base)");
            "Cost Amount" := Round(Quantity * "Unit Cost");
            InitRemainingQty;
            InitQtyToAssemble;
            if not AvailabilityCheck then begin
                Validate("Quantity to Assemble");
                Validate("Planning Flexibility", TempFromAsmHeader."Planning Flexibility");
            end;
            CopyFromAsmOrderDimToHdr(ToAsmHeader, TempFromAsmHeader, ToSalesLine);
            Modify;
        end;
    end;

    local procedure CreateToAsmLines(ToAsmHeader: Record "Assembly Header"; var FromAsmLine: Record "Assembly Line"; var ToAssemblyLine: Record "Assembly Line"; ToSalesLine: Record "Sales Line"; BasicAsmOrderCopy: Boolean; AvailabilityCheck: Boolean)
    var
        AssemblyLineMgt: Codeunit "Assembly Line Management";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if FromAsmLine.FindSet then
            repeat
                ToAssemblyLine.Init();
                ToAssemblyLine."Document Type" := ToAsmHeader."Document Type";
                ToAssemblyLine."Document No." := ToAsmHeader."No.";
                ToAssemblyLine."Line No." := AssemblyLineMgt.GetNextAsmLineNo(ToAssemblyLine, AvailabilityCheck);
                ToAssemblyLine.Insert(not AvailabilityCheck);
                if AvailabilityCheck then begin
                    ToAssemblyLine.Type := FromAsmLine.Type;
                    ToAssemblyLine."No." := FromAsmLine."No.";
                    ToAssemblyLine."Resource Usage Type" := FromAsmLine."Resource Usage Type";
                    ToAssemblyLine."Unit of Measure Code" := FromAsmLine."Unit of Measure Code";
                    ToAssemblyLine."Quantity per" := FromAsmLine."Quantity per";
                    ToAssemblyLine.Quantity := GetAppliedQuantityForAsmLine(BasicAsmOrderCopy, ToAsmHeader, FromAsmLine, ToSalesLine);
                end else begin
                    ToAssemblyLine.Validate(Type, FromAsmLine.Type);
                    ToAssemblyLine.Validate("No.", FromAsmLine."No.");
                    ToAssemblyLine.Validate("Resource Usage Type", FromAsmLine."Resource Usage Type");
                    ToAssemblyLine.Validate("Unit of Measure Code", FromAsmLine."Unit of Measure Code");
                    if ToAssemblyLine.Type <> ToAssemblyLine.Type::" " then
                        ToAssemblyLine.Validate("Quantity per", FromAsmLine."Quantity per");
                    ToAssemblyLine.Validate(Quantity, GetAppliedQuantityForAsmLine(BasicAsmOrderCopy, ToAsmHeader, FromAsmLine, ToSalesLine));
                end;
                ToAssemblyLine.ValidateDueDate(ToAsmHeader, ToAsmHeader."Starting Date", false);
                ToAssemblyLine.ValidateLeadTimeOffset(ToAsmHeader, FromAsmLine."Lead-Time Offset", false);
                ToAssemblyLine.Description := FromAsmLine.Description;
                ToAssemblyLine."Description 2" := FromAsmLine."Description 2";
                ToAssemblyLine.Position := FromAsmLine.Position;
                ToAssemblyLine."Position 2" := FromAsmLine."Position 2";
                ToAssemblyLine."Position 3" := FromAsmLine."Position 3";
                if ToAssemblyLine.Type = ToAssemblyLine.Type::Item then
                    if AvailabilityCheck then begin
                        ToAssemblyLine."Location Code" := FromAsmLine."Location Code";
                        ToAssemblyLine."Variant Code" := FromAsmLine."Variant Code";
                    end else begin
                        ToAssemblyLine.Validate("Location Code", FromAsmLine."Location Code");
                        ToAssemblyLine.Validate("Variant Code", FromAsmLine."Variant Code");
                    end;
                if ToAssemblyLine.Type <> ToAssemblyLine.Type::" " then begin
                    if RecalculateLines then
                        ToAssemblyLine."Unit Cost" := ToAssemblyLine.GetUnitCost
                    else
                        ToAssemblyLine."Unit Cost" := FromAsmLine."Unit Cost";
                    ToAssemblyLine."Cost Amount" := ToAssemblyLine.CalcCostAmount(ToAssemblyLine.Quantity, ToAssemblyLine."Unit Cost");
                    if AvailabilityCheck then begin
                        with ToAssemblyLine do begin
                            "Quantity (Base)" :=
                              UOMMgt.CalcBaseQty(
                                "No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");
                            "Remaining Quantity" := "Quantity (Base)";
                            "Quantity to Consume" := ToAsmHeader."Quantity to Assemble" * FromAsmLine."Quantity per";
                            "Quantity to Consume (Base)" :=
                              UOMMgt.CalcBaseQty(
                                "No.", "Variant Code", "Unit of Measure Code", "Quantity to Consume", "Qty. per Unit of Measure");
                        end;
                    end else
                        ToAssemblyLine.Validate("Quantity to Consume", ToAsmHeader."Quantity to Assemble" * FromAsmLine."Quantity per");
                end;
                CopyFromAsmOrderDimToLine(ToAssemblyLine, FromAsmLine, BasicAsmOrderCopy);
                ToAssemblyLine.Modify(not AvailabilityCheck);
            until FromAsmLine.Next = 0;
    end;

    local procedure CheckAsmOrderAvailability(ToAsmHeader: Record "Assembly Header"; var FromAsmLine: Record "Assembly Line"; ToSalesLine: Record "Sales Line")
    var
        TempToAsmHeader: Record "Assembly Header" temporary;
        TempToAsmLine: Record "Assembly Line" temporary;
        AsmLineOnDestinationOrder: Record "Assembly Line";
        AssemblyLineMgt: Codeunit "Assembly Line Management";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        LineNo: Integer;
    begin
        TempToAsmHeader := ToAsmHeader;
        TempToAsmHeader.Insert();
        CreateToAsmLines(TempToAsmHeader, FromAsmLine, TempToAsmLine, ToSalesLine, true, true);
        if TempToAsmLine.FindLast then
            LineNo := TempToAsmLine."Line No.";
        Clear(TempToAsmLine);
        with AsmLineOnDestinationOrder do begin
            SetRange("Document Type", ToAsmHeader."Document Type");
            SetRange("Document No.", ToAsmHeader."No.");
            SetRange(Type, Type::Item);
        end;
        if AsmLineOnDestinationOrder.FindSet then
            repeat
                TempToAsmLine := AsmLineOnDestinationOrder;
                LineNo += 10000;
                TempToAsmLine."Line No." := LineNo;
                TempToAsmLine.Insert();
            until AsmLineOnDestinationOrder.Next = 0;
        if AssemblyLineMgt.ShowAvailability(false, TempToAsmHeader, TempToAsmLine) then
            ItemCheckAvail.RaiseUpdateInterruptedError;
        TempToAsmLine.DeleteAll();
    end;

    local procedure GetAppliedQuantityForAsmLine(BasicAsmOrderCopy: Boolean; ToAsmHeader: Record "Assembly Header"; TempFromAsmLine: Record "Assembly Line" temporary; ToSalesLine: Record "Sales Line"): Decimal
    begin
        if BasicAsmOrderCopy then
            exit(ToAsmHeader.Quantity * TempFromAsmLine."Quantity per");
        case ToSalesLine."Document Type" of
            ToSalesLine."Document Type"::Order:
                exit(ToSalesLine."Qty. to Assemble to Order" * TempFromAsmLine."Quantity per");
            ToSalesLine."Document Type"::Quote,
          ToSalesLine."Document Type"::"Blanket Order":
                exit(ToSalesLine.Quantity * TempFromAsmLine."Quantity per");
        end;
    end;

    procedure ArchSalesHeaderDocType(DocType: Option): Integer
    var
        FromSalesHeaderArchive: Record "Sales Header Archive";
    begin
        case DocType of
            SalesDocType::"Arch. Quote":
                exit(FromSalesHeaderArchive."Document Type"::Quote);
            SalesDocType::"Arch. Order":
                exit(FromSalesHeaderArchive."Document Type"::Order);
            SalesDocType::"Arch. Blanket Order":
                exit(FromSalesHeaderArchive."Document Type"::"Blanket Order");
            SalesDocType::"Arch. Return Order":
                exit(FromSalesHeaderArchive."Document Type"::"Return Order");
        end;
    end;

    local procedure CopyFromArchSalesDocDimToHdr(var ToSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive")
    begin
        ToSalesHeader."Shortcut Dimension 1 Code" := FromSalesHeaderArchive."Shortcut Dimension 1 Code";
        ToSalesHeader."Shortcut Dimension 2 Code" := FromSalesHeaderArchive."Shortcut Dimension 2 Code";
        ToSalesHeader."Dimension Set ID" := FromSalesHeaderArchive."Dimension Set ID";
    end;

    local procedure CopyFromArchSalesDocDimToLine(var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive")
    begin
        if IncludeHeader then begin
            ToSalesLine."Shortcut Dimension 1 Code" := FromSalesLineArchive."Shortcut Dimension 1 Code";
            ToSalesLine."Shortcut Dimension 2 Code" := FromSalesLineArchive."Shortcut Dimension 2 Code";
            ToSalesLine."Dimension Set ID" := FromSalesLineArchive."Dimension Set ID";
        end;
    end;

    procedure ArchPurchHeaderDocType(DocType: Option): Integer
    var
        FromPurchHeaderArchive: Record "Purchase Header Archive";
    begin
        case DocType of
            PurchDocType::"Arch. Quote":
                exit(FromPurchHeaderArchive."Document Type"::Quote);
            PurchDocType::"Arch. Order":
                exit(FromPurchHeaderArchive."Document Type"::Order);
            PurchDocType::"Arch. Blanket Order":
                exit(FromPurchHeaderArchive."Document Type"::"Blanket Order");
            PurchDocType::"Arch. Return Order":
                exit(FromPurchHeaderArchive."Document Type"::"Return Order");
        end;
    end;

    local procedure CopyFromArchPurchDocDimToHdr(var ToPurchHeader: Record "Purchase Header"; FromPurchHeaderArchive: Record "Purchase Header Archive")
    begin
        ToPurchHeader."Shortcut Dimension 1 Code" := FromPurchHeaderArchive."Shortcut Dimension 1 Code";
        ToPurchHeader."Shortcut Dimension 2 Code" := FromPurchHeaderArchive."Shortcut Dimension 2 Code";
        ToPurchHeader."Dimension Set ID" := FromPurchHeaderArchive."Dimension Set ID";
    end;

    local procedure CopyFromArchPurchDocDimToLine(var ToPurchLine: Record "Purchase Line"; FromPurchLineArchive: Record "Purchase Line Archive")
    begin
        if IncludeHeader then begin
            ToPurchLine."Shortcut Dimension 1 Code" := FromPurchLineArchive."Shortcut Dimension 1 Code";
            ToPurchLine."Shortcut Dimension 2 Code" := FromPurchLineArchive."Shortcut Dimension 2 Code";
            ToPurchLine."Dimension Set ID" := FromPurchLineArchive."Dimension Set ID";
        end;
    end;

    local procedure CopyFromAsmOrderDimToHdr(var ToAssemblyHeader: Record "Assembly Header"; FromAssemblyHeader: Record "Assembly Header"; ToSalesLine: Record "Sales Line")
    begin
        if RecalculateLines then begin
            ToAssemblyHeader."Dimension Set ID" := ToSalesLine."Dimension Set ID";
            ToAssemblyHeader."Shortcut Dimension 1 Code" := ToSalesLine."Shortcut Dimension 1 Code";
            ToAssemblyHeader."Shortcut Dimension 2 Code" := ToSalesLine."Shortcut Dimension 2 Code";
        end else begin
            ToAssemblyHeader."Dimension Set ID" := FromAssemblyHeader."Dimension Set ID";
            ToAssemblyHeader."Shortcut Dimension 1 Code" := FromAssemblyHeader."Shortcut Dimension 1 Code";
            ToAssemblyHeader."Shortcut Dimension 2 Code" := FromAssemblyHeader."Shortcut Dimension 2 Code";
        end;
    end;

    local procedure CopyFromAsmOrderDimToLine(var ToAssemblyLine: Record "Assembly Line"; FromAssemblyLine: Record "Assembly Line"; BasicAsmOrderCopy: Boolean)
    begin
        if RecalculateLines or BasicAsmOrderCopy then
            exit;

        ToAssemblyLine."Dimension Set ID" := FromAssemblyLine."Dimension Set ID";
        ToAssemblyLine."Shortcut Dimension 1 Code" := FromAssemblyLine."Shortcut Dimension 1 Code";
        ToAssemblyLine."Shortcut Dimension 2 Code" := FromAssemblyLine."Shortcut Dimension 2 Code";
    end;

    procedure SetArchDocVal(DocOccurrencyNo: Integer; DocVersionNo: Integer)
    begin
        FromDocOccurrenceNo := DocOccurrencyNo;
        FromDocVersionNo := DocVersionNo;
    end;

    local procedure CopyArchSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeaderArchive: Record "Sales Header Archive"; var FromSalesLineArchive: Record "Sales Line Archive"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean): Boolean
    var
        ToSalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        CopyThisLine: Boolean;
    begin
        CopyThisLine := true;
        OnBeforeCopyArchSalesLine(ToSalesHeader, FromSalesHeaderArchive, FromSalesLineArchive, RecalculateLines, CopyThisLine);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        if ((ToSalesHeader."Language Code" <> FromSalesHeaderArchive."Language Code") or RecalculateLines) and
           (FromSalesLineArchive."Attached to Line No." <> 0)
        then
            exit(false);

        ToSalesLine.SetSalesHeader(ToSalesHeader);
        if RecalculateLines and not FromSalesLineArchive."System-Created Entry" then
            ToSalesLine.Init
        else
            ToSalesLine.TransferFields(FromSalesLineArchive);
        NextLineNo := NextLineNo + 10000;
        ToSalesLine."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine."Document No." := ToSalesHeader."No.";
        ToSalesLine."Line No." := NextLineNo;
        ToSalesLine.Validate("Currency Code", FromSalesHeaderArchive."Currency Code");

        if RecalculateLines and not FromSalesLineArchive."System-Created Entry" then begin
            FromSalesHeader.TransferFields(FromSalesHeaderArchive, true);
            FromSalesLine.TransferFields(FromSalesLineArchive, true);
            RecalculateSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CopyThisLine);
        end else begin
            InitSalesLineFields(ToSalesLine);

            ToSalesLine.InitOutstanding;
            if ToSalesLine."Document Type" in
               [ToSalesLine."Document Type"::"Return Order", ToSalesLine."Document Type"::"Credit Memo"]
            then
                ToSalesLine.InitQtyToReceive
            else
                ToSalesLine.InitQtyToShip;
            ToSalesLine."VAT Difference" := FromSalesLineArchive."VAT Difference";
            if not CreateToHeader then
                ToSalesLine."Shipment Date" := ToSalesHeader."Shipment Date";
            ToSalesLine."Appl.-from Item Entry" := 0;
            ToSalesLine."Appl.-to Item Entry" := 0;

            CleanSpecialOrderDropShipmentInSalesLine(ToSalesLine);
            if RecalculateAmount and (FromSalesLineArchive."Appl.-from Item Entry" = 0) then begin
                ToSalesLine.Validate("Line Discount %", FromSalesLineArchive."Line Discount %");
                ToSalesLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromSalesLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
                ToSalesLine.Validate("Unit Cost (LCY)", FromSalesLineArchive."Unit Cost (LCY)");
            end;
            if VATPostingSetup.Get(ToSalesLine."VAT Bus. Posting Group", ToSalesLine."VAT Prod. Posting Group") then
                ToSalesLine."VAT Identifier" := VATPostingSetup."VAT Identifier";

            ToSalesLine.UpdateWithWarehouseShip;
            if (ToSalesLine.Type = ToSalesLine.Type::Item) and (ToSalesLine."No." <> '') then begin
                GetItem(ToSalesLine."No.");
                if (Item."Costing Method" = Item."Costing Method"::Standard) and not ToSalesLine.IsShipment then
                    ToSalesLine.GetUnitCost;
            end;
        end;

        if ExactCostRevMandatory and
           (FromSalesLineArchive.Type = FromSalesLineArchive.Type::Item) and
           (FromSalesLineArchive."Appl.-from Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then begin
                ToSalesLine.Validate("Unit Price", FromSalesLineArchive."Unit Price");
                ToSalesLine.Validate(
                  "Line Discount Amount",
                  Round(FromSalesLineArchive."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToSalesLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromSalesLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToSalesLine.Validate("Appl.-from Item Entry", FromSalesLineArchive."Appl.-from Item Entry");
            if not CreateToHeader then
                if ToSalesLine."Shipment Date" = 0D then
                    InitShipmentDateInLine(ToSalesHeader, ToSalesLine);
        end;

        if MoveNegLines and (ToSalesLine.Type <> ToSalesLine.Type::" ") then begin
            ToSalesLine.Validate(Quantity, -FromSalesLineArchive.Quantity);
            ToSalesLine.Validate("Line Discount %", FromSalesLineArchive."Line Discount %");
            ToSalesLine."Appl.-to Item Entry" := FromSalesLineArchive."Appl.-to Item Entry";
            ToSalesLine."Appl.-from Item Entry" := FromSalesLineArchive."Appl.-from Item Entry";
        end;

        if not ((ToSalesHeader."Language Code" <> FromSalesHeaderArchive."Language Code") or RecalculateLines) then
            ToSalesLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                FromSalesLineArchive."Line No.", NextLineNo, FromSalesLineArchive."Attached to Line No.")
        else
            if TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, false) then begin
                TransferExtendedText.InsertSalesExtText(ToSalesLine);
                ToSalesLine2.SetRange("Document Type", ToSalesLine."Document Type");
                ToSalesLine2.SetRange("Document No.", ToSalesLine."Document No.");
                ToSalesLine2.FindLast;
                NextLineNo := ToSalesLine2."Line No.";
            end;

        if CopyThisLine then begin
            OnCopyArchSalesLineOnBeforeToSalesLineInsert(ToSalesLine, FromSalesLineArchive, RecalculateLines, NextLineNo);
            ToSalesLine.Insert();
            OnCopyArchSalesLineOnAfterToSalesLineInsert(ToSalesLine, FromSalesLineArchive, RecalculateLines);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    local procedure CopyArchPurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeaderArchive: Record "Purchase Header Archive"; var FromPurchLineArchive: Record "Purchase Line Archive"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean): Boolean
    var
        ToPurchLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        CopyThisLine: Boolean;
    begin
        CopyThisLine := true;
        OnBeforeCopyArchPurchLine(ToPurchHeader, FromPurchHeaderArchive, FromPurchLineArchive, RecalculateLines, CopyThisLine);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        if ((ToPurchHeader."Language Code" <> FromPurchHeaderArchive."Language Code") or RecalculateLines) and
           (FromPurchLineArchive."Attached to Line No." <> 0)
        then
            exit(false);

        if RecalculateLines and not FromPurchLineArchive."System-Created Entry" then
            ToPurchLine.Init
        else
            ToPurchLine.TransferFields(FromPurchLineArchive);
        NextLineNo := NextLineNo + 10000;
        ToPurchLine."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine."Document No." := ToPurchHeader."No.";
        ToPurchLine."Line No." := NextLineNo;
        ToPurchLine.Validate("Currency Code", FromPurchHeaderArchive."Currency Code");

        if RecalculateLines and not FromPurchLineArchive."System-Created Entry" then begin
            FromPurchHeader.TransferFields(FromPurchHeaderArchive, true);
            FromPurchLine.TransferFields(FromPurchLineArchive, true);
            RecalculatePurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, CopyThisLine);
        end else begin
            InitPurchLineFields(ToPurchLine);

            ToPurchLine.InitOutstanding;
            if ToPurchLine."Document Type" in
               [ToPurchLine."Document Type"::"Return Order", ToPurchLine."Document Type"::"Credit Memo"]
            then
                ToPurchLine.InitQtyToShip
            else
                ToPurchLine.InitQtyToReceive;
            ToPurchLine."VAT Difference" := FromPurchLineArchive."VAT Difference";
            ToPurchLine."Receipt No." := '';
            ToPurchLine."Receipt Line No." := 0;
            if not CreateToHeader then
                ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date";
            ToPurchLine."Appl.-to Item Entry" := 0;

            if FromPurchLineArchive."Drop Shipment" or FromPurchLineArchive."Special Order" then
                ToPurchLine."Purchasing Code" := '';
            CleanSpecialOrderDropShipmentInPurchLine(ToPurchLine);

            if RecalculateAmount then begin
                ToPurchLine.Validate("Line Discount %", FromPurchLineArchive."Line Discount %");
                ToPurchLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromPurchLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            if VATPostingSetup.Get(ToPurchLine."VAT Bus. Posting Group", ToPurchLine."VAT Prod. Posting Group") then
                ToPurchLine."VAT Identifier" := VATPostingSetup."VAT Identifier";

            ToPurchLine.UpdateWithWarehouseReceive;
            ToPurchLine."Pay-to Vendor No." := ToPurchHeader."Pay-to Vendor No.";
        end;

        if ExactCostRevMandatory and
           (FromPurchLineArchive.Type = FromPurchLineArchive.Type::Item) and
           (FromPurchLineArchive."Appl.-to Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then begin
                ToPurchLine.Validate("Direct Unit Cost", FromPurchLineArchive."Direct Unit Cost");
                ToPurchLine.Validate(
                  "Line Discount Amount",
                  Round(FromPurchLineArchive."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToPurchLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromPurchLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToPurchLine.Validate("Appl.-to Item Entry", FromPurchLineArchive."Appl.-to Item Entry");
            if not CreateToHeader then
                if ToPurchLine."Expected Receipt Date" = 0D then
                    if ToPurchHeader."Expected Receipt Date" <> 0D then
                        ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date"
                    else
                        ToPurchLine."Expected Receipt Date" := WorkDate;
        end;

        if MoveNegLines and (ToPurchLine.Type <> ToPurchLine.Type::" ") then begin
            ToPurchLine.Validate(Quantity, -FromPurchLineArchive.Quantity);
            ToPurchLine."Appl.-to Item Entry" := FromPurchLineArchive."Appl.-to Item Entry"
        end;

        if not ((ToPurchHeader."Language Code" <> FromPurchHeaderArchive."Language Code") or RecalculateLines) then
            ToPurchLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                FromPurchLineArchive."Line No.", NextLineNo, FromPurchLineArchive."Attached to Line No.")
        else
            if TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, false) then begin
                TransferExtendedText.InsertPurchExtText(ToPurchLine);
                ToPurchLine2.SetRange("Document Type", ToPurchLine."Document Type");
                ToPurchLine2.SetRange("Document No.", ToPurchLine."Document No.");
                ToPurchLine2.FindLast;
                NextLineNo := ToPurchLine2."Line No.";
            end;

        if CopyThisLine then begin
            OnCopyArchPurchLineOnBeforeToPurchLineInsert(ToPurchLine, FromPurchLineArchive, RecalculateLines, NextLineNo);
            ToPurchLine.Insert();
            OnCopyArchPurchLineOnAfterToPurchLineInsert(ToPurchLine, FromPurchLineArchive, RecalculateLines);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    local procedure CopyDocLines(RecalculateAmount: Boolean; ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
        if not RecalculateAmount then
            exit;
        if (ToPurchLine.Type <> ToPurchLine.Type::" ") and (ToPurchLine."No." <> '') then begin
            ToPurchLine.Validate("Line Discount %", FromPurchLine."Line Discount %");
            ToPurchLine.Validate(
              "Inv. Discount Amount",
              Round(FromPurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
        end;
    end;

    local procedure CheckCreditLimit(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header")
    begin
        if SkipTestCreditLimit then
            exit;

        if IncludeHeader then
            CustCheckCreditLimit.SalesHeaderCheck(FromSalesHeader)
        else
            CustCheckCreditLimit.SalesHeaderCheck(ToSalesHeader);
    end;

    local procedure CheckUnappliedLines(SkippedLine: Boolean; var MissingExCostRevLink: Boolean)
    begin
        if SkippedLine and MissingExCostRevLink then begin
            if not WarningDone then
                Message(Text030);
            MissingExCostRevLink := false;
            WarningDone := true;
        end;
    end;

    local procedure SetDefaultValuesToSalesLine(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; VATDifference: Decimal)
    begin
        InitSalesLineFields(ToSalesLine);

        if ToSalesLine."Document Type" in
           [ToSalesLine."Document Type"::"Blanket Order",
            ToSalesLine."Document Type"::"Credit Memo",
            ToSalesLine."Document Type"::"Return Order"]
        then begin
            ToSalesLine."Blanket Order No." := '';
            ToSalesLine."Blanket Order Line No." := 0;
        end;
        ToSalesLine.InitOutstanding;
        if ToSalesLine."Document Type" in
           [ToSalesLine."Document Type"::"Return Order", ToSalesLine."Document Type"::"Credit Memo"]
        then
            ToSalesLine.InitQtyToReceive
        else
            ToSalesLine.InitQtyToShip;
        ToSalesLine."VAT Difference" := VATDifference;
        ToSalesLine."Shipment No." := '';
        ToSalesLine."Shipment Line No." := 0;
        if not CreateToHeader and RecalculateLines then
            ToSalesLine."Shipment Date" := ToSalesHeader."Shipment Date";
        ToSalesLine."Appl.-from Item Entry" := 0;
        ToSalesLine."Appl.-to Item Entry" := 0;

        ToSalesLine."Purchase Order No." := '';
        ToSalesLine."Purch. Order Line No." := 0;
        ToSalesLine."Special Order Purchase No." := '';
        ToSalesLine."Special Order Purch. Line No." := 0;

        OnAfterSetDefaultValuesToSalesLine(ToSalesLine, ToSalesHeader);
    end;

    local procedure SetDefaultValuesToPurchLine(var ToPurchLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header"; VATDifference: Decimal)
    begin
        InitPurchLineFields(ToPurchLine);

        if ToPurchLine."Document Type" in
           [ToPurchLine."Document Type"::"Blanket Order",
            ToPurchLine."Document Type"::"Credit Memo",
            ToPurchLine."Document Type"::"Return Order"]
        then begin
            ToPurchLine."Blanket Order No." := '';
            ToPurchLine."Blanket Order Line No." := 0;
        end;

        ToPurchLine.InitOutstanding;
        if ToPurchLine."Document Type" in
           [ToPurchLine."Document Type"::"Return Order", ToPurchLine."Document Type"::"Credit Memo"]
        then
            ToPurchLine.InitQtyToShip
        else
            ToPurchLine.InitQtyToReceive;
        ToPurchLine."VAT Difference" := VATDifference;
        ToPurchLine."Receipt No." := '';
        ToPurchLine."Receipt Line No." := 0;
        if not CreateToHeader then
            ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date";
        ToPurchLine."Appl.-to Item Entry" := 0;

        ToPurchLine."Sales Order No." := '';
        ToPurchLine."Sales Order Line No." := 0;
        ToPurchLine."Special Order Sales No." := '';
        ToPurchLine."Special Order Sales Line No." := 0;

        OnAfterSetDefaultValuesToPurchLine(ToPurchLine);
    end;

    local procedure CopyItemTrackingEntries(SalesLine: Record "Sales Line"; var PurchLine: Record "Purchase Line"; SalesPricesIncludingVAT: Boolean; PurchPricesIncludingVAT: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MissingExCostRevLink: Boolean;
    begin
        PurchasesPayablesSetup.Get();
        FindTrackingEntries(
          TempItemLedgerEntry, DATABASE::"Sales Line", TrackingSpecification."Source Subtype"::"5",
          SalesLine."Document No.", '', 0, SalesLine."Line No.", SalesLine."No.");
        ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
          TempItemLedgerEntry, PurchLine, PurchasesPayablesSetup."Exact Cost Reversing Mandatory", MissingExCostRevLink,
          SalesPricesIncludingVAT, PurchPricesIncludingVAT, true);
    end;

    local procedure FindTrackingEntries(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; ItemNo: Code[20])
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        with TrackingSpecification do begin
            SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
            SetRange("Source ID", ID);
            SetRange("Source Ref. No.", RefNo);
            SetRange("Source Type", Type);
            SetRange("Source Subtype", Subtype);
            SetRange("Source Batch Name", BatchName);
            SetRange("Source Prod. Order Line", ProdOrderLine);
            SetRange("Item No.", ItemNo);
            if FindSet then
                repeat
                    AddItemLedgerEntry(TempItemLedgerEntry, "Lot No.", "Serial No.", "Entry No.");
                until Next = 0;
        end;
    end;

    local procedure AddItemLedgerEntry(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; LotNo: Code[50]; SerialNo: Code[50]; EntryNo: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if (LotNo = '') and (SerialNo = '') then
            exit;

        if not ItemLedgerEntry.Get(EntryNo) then
            exit;

        TempItemLedgerEntry := ItemLedgerEntry;
        if TempItemLedgerEntry.Insert() then;
    end;

    procedure CopyFieldsFromOldSalesHeader(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header")
    begin
        with ToSalesHeader do begin
            "No. Series" := OldSalesHeader."No. Series";
            "Posting Description" := OldSalesHeader."Posting Description";
            "Posting No." := OldSalesHeader."Posting No.";
            "Posting No. Series" := OldSalesHeader."Posting No. Series";
            "Shipping No." := OldSalesHeader."Shipping No.";
            "Shipping No. Series" := OldSalesHeader."Shipping No. Series";
            "Return Receipt No." := OldSalesHeader."Return Receipt No.";
            "Return Receipt No. Series" := OldSalesHeader."Return Receipt No. Series";
            "Prepayment No. Series" := OldSalesHeader."Prepayment No. Series";
            "Prepayment No." := OldSalesHeader."Prepayment No.";
            "Prepmt. Posting Description" := OldSalesHeader."Prepmt. Posting Description";
            "Prepmt. Cr. Memo No. Series" := OldSalesHeader."Prepmt. Cr. Memo No. Series";
            "Prepmt. Cr. Memo No." := OldSalesHeader."Prepmt. Cr. Memo No.";
            "Prepmt. Posting Description" := OldSalesHeader."Prepmt. Posting Description";
            SetSalespersonPurchaserCode("Salesperson Code");
        end
    end;

    procedure CopyFieldsFromOldPurchHeader(var ToPurchHeader: Record "Purchase Header"; OldPurchHeader: Record "Purchase Header")
    begin
        with ToPurchHeader do begin
            "No. Series" := OldPurchHeader."No. Series";
            "Posting Description" := OldPurchHeader."Posting Description";
            "Posting No." := OldPurchHeader."Posting No.";
            "Posting No. Series" := OldPurchHeader."Posting No. Series";
            "Receiving No." := OldPurchHeader."Receiving No.";
            "Receiving No. Series" := OldPurchHeader."Receiving No. Series";
            "Return Shipment No." := OldPurchHeader."Return Shipment No.";
            "Return Shipment No. Series" := OldPurchHeader."Return Shipment No. Series";
            "Prepayment No. Series" := OldPurchHeader."Prepayment No. Series";
            "Prepayment No." := OldPurchHeader."Prepayment No.";
            "Prepmt. Posting Description" := OldPurchHeader."Prepmt. Posting Description";
            "Prepmt. Cr. Memo No. Series" := OldPurchHeader."Prepmt. Cr. Memo No. Series";
            "Prepmt. Cr. Memo No." := OldPurchHeader."Prepmt. Cr. Memo No.";
            "Prepmt. Posting Description" := OldPurchHeader."Prepmt. Posting Description";
            SetSalespersonPurchaserCode("Purchaser Code");
        end;
    end;

    local procedure CheckFromSalesHeader(SalesHeaderFrom: Record "Sales Header"; SalesHeaderTo: Record "Sales Header")
    begin
        with SalesHeaderTo do begin
            SalesHeaderFrom.TestField("Sell-to Customer No.", "Sell-to Customer No.");
            SalesHeaderFrom.TestField("Bill-to Customer No.", "Bill-to Customer No.");
            SalesHeaderFrom.TestField("Customer Posting Group", "Customer Posting Group");
            SalesHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            SalesHeaderFrom.TestField("Currency Code", "Currency Code");
            SalesHeaderFrom.TestField("Prices Including VAT", "Prices Including VAT");
        end;

        OnAfterCheckFromSalesHeader(SalesHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromSalesShptHeader(SalesShipmentHeaderFrom: Record "Sales Shipment Header"; SalesHeaderTo: Record "Sales Header")
    begin
        with SalesHeaderTo do begin
            SalesShipmentHeaderFrom.TestField("Sell-to Customer No.", "Sell-to Customer No.");
            SalesShipmentHeaderFrom.TestField("Bill-to Customer No.", "Bill-to Customer No.");
            SalesShipmentHeaderFrom.TestField("Customer Posting Group", "Customer Posting Group");
            SalesShipmentHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            SalesShipmentHeaderFrom.TestField("Currency Code", "Currency Code");
            SalesShipmentHeaderFrom.TestField("Prices Including VAT", "Prices Including VAT");
        end;

        OnAfterCheckFromSalesShptHeader(SalesShipmentHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromSalesInvHeader(SalesInvoiceHeaderFrom: Record "Sales Invoice Header"; SalesHeaderTo: Record "Sales Header")
    begin
        with SalesHeaderTo do begin
            SalesInvoiceHeaderFrom.TestField("Sell-to Customer No.", "Sell-to Customer No.");
            SalesInvoiceHeaderFrom.TestField("Bill-to Customer No.", "Bill-to Customer No.");
            SalesInvoiceHeaderFrom.TestField("Customer Posting Group", "Customer Posting Group");
            SalesInvoiceHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            SalesInvoiceHeaderFrom.TestField("Currency Code", "Currency Code");
            SalesInvoiceHeaderFrom.TestField("Prices Including VAT", "Prices Including VAT");
        end;

        OnAfterCheckFromSalesInvHeader(SalesInvoiceHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromSalesReturnRcptHeader(ReturnReceiptHeaderFrom: Record "Return Receipt Header"; SalesHeaderTo: Record "Sales Header")
    begin
        with SalesHeaderTo do begin
            ReturnReceiptHeaderFrom.TestField("Sell-to Customer No.", "Sell-to Customer No.");
            ReturnReceiptHeaderFrom.TestField("Bill-to Customer No.", "Bill-to Customer No.");
            ReturnReceiptHeaderFrom.TestField("Customer Posting Group", "Customer Posting Group");
            ReturnReceiptHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            ReturnReceiptHeaderFrom.TestField("Currency Code", "Currency Code");
            ReturnReceiptHeaderFrom.TestField("Prices Including VAT", "Prices Including VAT");
        end;

        OnAfterCheckFromSalesReturnRcptHeader(ReturnReceiptHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromSalesCrMemoHeader(SalesCrMemoHeaderFrom: Record "Sales Cr.Memo Header"; SalesHeaderTo: Record "Sales Header")
    begin
        with SalesHeaderTo do begin
            SalesCrMemoHeaderFrom.TestField("Sell-to Customer No.", "Sell-to Customer No.");
            SalesCrMemoHeaderFrom.TestField("Bill-to Customer No.", "Bill-to Customer No.");
            SalesCrMemoHeaderFrom.TestField("Customer Posting Group", "Customer Posting Group");
            SalesCrMemoHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            SalesCrMemoHeaderFrom.TestField("Currency Code", "Currency Code");
            SalesCrMemoHeaderFrom.TestField("Prices Including VAT", "Prices Including VAT");
        end;

        OnAfterCheckFromSalesCrMemoHeader(SalesCrMemoHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromPurchaseHeader(PurchaseHeaderFrom: Record "Purchase Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
        with PurchaseHeaderTo do begin
            PurchaseHeaderFrom.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");
            PurchaseHeaderFrom.TestField("Pay-to Vendor No.", "Pay-to Vendor No.");
            PurchaseHeaderFrom.TestField("Vendor Posting Group", "Vendor Posting Group");
            PurchaseHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            PurchaseHeaderFrom.TestField("Currency Code", "Currency Code");
        end;

        OnAfterCheckFromPurchaseHeader(PurchaseHeaderFrom, PurchaseHeaderTo);
    end;

    local procedure CheckFromPurchaseRcptHeader(PurchRcptHeaderFrom: Record "Purch. Rcpt. Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
        with PurchaseHeaderTo do begin
            PurchRcptHeaderFrom.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");
            PurchRcptHeaderFrom.TestField("Pay-to Vendor No.", "Pay-to Vendor No.");
            PurchRcptHeaderFrom.TestField("Vendor Posting Group", "Vendor Posting Group");
            PurchRcptHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            PurchRcptHeaderFrom.TestField("Currency Code", "Currency Code");
        end;

        OnAfterCheckFromPurchaseRcptHeader(PurchRcptHeaderFrom, PurchaseHeaderTo);
    end;

    local procedure CheckFromPurchaseInvHeader(PurchInvHeaderFrom: Record "Purch. Inv. Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
        with PurchaseHeaderTo do begin
            PurchInvHeaderFrom.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");
            PurchInvHeaderFrom.TestField("Pay-to Vendor No.", "Pay-to Vendor No.");
            PurchInvHeaderFrom.TestField("Vendor Posting Group", "Vendor Posting Group");
            PurchInvHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            PurchInvHeaderFrom.TestField("Currency Code", "Currency Code");
        end;

        OnAfterCheckFromPurchaseInvHeader(PurchInvHeaderFrom, PurchaseHeaderTo);
    end;

    local procedure CheckFromPurchaseReturnShptHeader(ReturnShipmentHeaderFrom: Record "Return Shipment Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
        with PurchaseHeaderTo do begin
            ReturnShipmentHeaderFrom.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");
            ReturnShipmentHeaderFrom.TestField("Pay-to Vendor No.", "Pay-to Vendor No.");
            ReturnShipmentHeaderFrom.TestField("Vendor Posting Group", "Vendor Posting Group");
            ReturnShipmentHeaderFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            ReturnShipmentHeaderFrom.TestField("Currency Code", "Currency Code");
        end;

        OnAfterCheckFromPurchaseReturnShptHeader(ReturnShipmentHeaderFrom, PurchaseHeaderTo);
    end;

    local procedure CheckFromPurchaseCrMemoHeader(PurchCrMemoHdrFrom: Record "Purch. Cr. Memo Hdr."; PurchaseHeaderTo: Record "Purchase Header")
    begin
        with PurchaseHeaderTo do begin
            PurchCrMemoHdrFrom.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");
            PurchCrMemoHdrFrom.TestField("Pay-to Vendor No.", "Pay-to Vendor No.");
            PurchCrMemoHdrFrom.TestField("Vendor Posting Group", "Vendor Posting Group");
            PurchCrMemoHdrFrom.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            PurchCrMemoHdrFrom.TestField("Currency Code", "Currency Code");
        end;

        OnAfterCheckFromPurchaseCrMemoHeader(PurchCrMemoHdrFrom, PurchaseHeaderTo);
    end;

    local procedure CopyDeferrals(DeferralDocType: Integer; FromDocType: Integer; FromDocNo: Code[20]; FromLineNo: Integer; ToDocType: Integer; ToDocNo: Code[20]; ToLineNo: Integer) StartDate: Date
    var
        FromDeferralHeader: Record "Deferral Header";
        FromDeferralLine: Record "Deferral Line";
        ToDeferralHeader: Record "Deferral Header";
        ToDeferralLine: Record "Deferral Line";
        SalesCommentLine: Record "Sales Comment Line";
    begin
        StartDate := 0D;
        if FromDeferralHeader.Get(
             DeferralDocType, '', '',
             FromDocType, FromDocNo, FromLineNo)
        then begin
            RemoveDefaultDeferralCode(DeferralDocType, ToDocType, ToDocNo, ToLineNo);
            ToDeferralHeader.Init();
            ToDeferralHeader.TransferFields(FromDeferralHeader);
            ToDeferralHeader."Document Type" := ToDocType;
            ToDeferralHeader."Document No." := ToDocNo;
            ToDeferralHeader."Line No." := ToLineNo;
            ToDeferralHeader.Insert();
            FromDeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
            FromDeferralLine.SetRange("Gen. Jnl. Template Name", '');
            FromDeferralLine.SetRange("Gen. Jnl. Batch Name", '');
            FromDeferralLine.SetRange("Document Type", FromDocType);
            FromDeferralLine.SetRange("Document No.", FromDocNo);
            FromDeferralLine.SetRange("Line No.", FromLineNo);
            if FromDeferralLine.FindSet then
                with ToDeferralLine do
                    repeat
                        Init;
                        TransferFields(FromDeferralLine);
                        "Document Type" := ToDocType;
                        "Document No." := ToDocNo;
                        "Line No." := ToLineNo;
                        Insert;
                    until FromDeferralLine.Next = 0;
            if ToDocType = SalesCommentLine."Document Type"::"Return Order" then
                StartDate := FromDeferralHeader."Start Date"
        end;
    end;

    local procedure CopyPostedDeferrals(DeferralDocType: Integer; FromDocType: Integer; FromDocNo: Code[20]; FromLineNo: Integer; ToDocType: Integer; ToDocNo: Code[20]; ToLineNo: Integer) StartDate: Date
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        SalesCommentLine: Record "Sales Comment Line";
        InitialAmountToDefer: Decimal;
    begin
        StartDate := 0D;
        if PostedDeferralHeader.Get(DeferralDocType, '', '',
             FromDocType, FromDocNo, FromLineNo)
        then begin
            RemoveDefaultDeferralCode(DeferralDocType, ToDocType, ToDocNo, ToLineNo);
            InitialAmountToDefer := 0;
            DeferralHeader.Init();
            DeferralHeader.TransferFields(PostedDeferralHeader);
            DeferralHeader."Document Type" := ToDocType;
            DeferralHeader."Document No." := ToDocNo;
            DeferralHeader."Line No." := ToLineNo;
            OnCopyPostedDeferralsOnBeforeDeferralHeaderInsert(DeferralHeader, PostedDeferralHeader);
            DeferralHeader.Insert();
            PostedDeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
            PostedDeferralLine.SetRange("Gen. Jnl. Document No.", '');
            PostedDeferralLine.SetRange("Account No.", '');
            PostedDeferralLine.SetRange("Document Type", FromDocType);
            PostedDeferralLine.SetRange("Document No.", FromDocNo);
            PostedDeferralLine.SetRange("Line No.", FromLineNo);
            if PostedDeferralLine.FindSet then
                with DeferralLine do
                    repeat
                        Init;
                        TransferFields(PostedDeferralLine);
                        "Document Type" := ToDocType;
                        "Document No." := ToDocNo;
                        "Line No." := ToLineNo;
                        if PostedDeferralLine."Amount (LCY)" <> 0.0 then
                            InitialAmountToDefer := InitialAmountToDefer + PostedDeferralLine."Amount (LCY)"
                        else
                            InitialAmountToDefer := InitialAmountToDefer + PostedDeferralLine.Amount;
                        OnCopyPostedDeferralsOnBeforeDeferralLineInsert(DeferralLine, PostedDeferralLine);
                        Insert;
                    until PostedDeferralLine.Next = 0;
            if ToDocType = SalesCommentLine."Document Type"::"Return Order" then
                StartDate := PostedDeferralHeader."Start Date";
            if DeferralHeader.Get(DeferralDocType, '', '', ToDocType, ToDocNo, ToLineNo) then begin
                DeferralHeader."Initial Amount to Defer" := InitialAmountToDefer;
                OnCopyPostedDeferralsOnBeforeDeferralHeaderModify(DeferralHeader);
                DeferralHeader.Modify();
            end;
        end;
    end;

    local procedure IsDeferralToBeCopied(DeferralDocType: Integer; ToDocType: Option; FromDocType: Option): Boolean
    var
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        PurchLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
        DeferralHeader: Record "Deferral Header";
    begin
        if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Sales then
            case ToDocType of
                SalesLine."Document Type"::Order,
              SalesLine."Document Type"::Invoice,
              SalesLine."Document Type"::"Credit Memo",
              SalesLine."Document Type"::"Return Order":
                    case FromDocType of
                        SalesCommentLine."Document Type"::Order,
                      SalesCommentLine."Document Type"::Invoice,
                      SalesCommentLine."Document Type"::"Credit Memo",
                      SalesCommentLine."Document Type"::"Return Order",
                      SalesCommentLine."Document Type"::"Posted Invoice",
                      SalesCommentLine."Document Type"::"Posted Credit Memo":
                            exit(true)
                    end;
            end
        else
            if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Purchase then
                case ToDocType of
                    PurchLine."Document Type"::Order,
                  PurchLine."Document Type"::Invoice,
                  PurchLine."Document Type"::"Credit Memo",
                  PurchLine."Document Type"::"Return Order":
                        case FromDocType of
                            PurchCommentLine."Document Type"::Order,
                          PurchCommentLine."Document Type"::Invoice,
                          PurchCommentLine."Document Type"::"Credit Memo",
                          PurchCommentLine."Document Type"::"Return Order",
                          PurchCommentLine."Document Type"::"Posted Invoice",
                          PurchCommentLine."Document Type"::"Posted Credit Memo":
                                exit(true)
                        end;
                end;

        exit(false);
    end;

    local procedure IsDeferralToBeDefaulted(DeferralDocType: Integer; ToDocType: Option; FromDocType: Option): Boolean
    var
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        PurchLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
        DeferralHeader: Record "Deferral Header";
    begin
        if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Sales then
            case ToDocType of
                SalesLine."Document Type"::Order,
              SalesLine."Document Type"::Invoice,
              SalesLine."Document Type"::"Credit Memo",
              SalesLine."Document Type"::"Return Order":
                    case FromDocType of
                        SalesCommentLine."Document Type"::Quote,
                      SalesCommentLine."Document Type"::"Blanket Order",
                      SalesCommentLine."Document Type"::Shipment,
                      SalesCommentLine."Document Type"::"Posted Return Receipt":
                            exit(true)
                    end;
            end
        else
            if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Purchase then
                case ToDocType of
                    PurchLine."Document Type"::Order,
                  PurchLine."Document Type"::Invoice,
                  PurchLine."Document Type"::"Credit Memo",
                  PurchLine."Document Type"::"Return Order":
                        case FromDocType of
                            PurchCommentLine."Document Type"::Quote,
                          PurchCommentLine."Document Type"::"Blanket Order",
                          PurchCommentLine."Document Type"::Receipt,
                          PurchCommentLine."Document Type"::"Posted Return Shipment":
                                exit(true)
                        end;
                end;

        exit(false);
    end;

    local procedure IsDeferralPosted(DeferralDocType: Integer; FromDocType: Option): Boolean
    var
        SalesCommentLine: Record "Sales Comment Line";
        PurchCommentLine: Record "Purch. Comment Line";
        DeferralHeader: Record "Deferral Header";
    begin
        if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Sales then
            case FromDocType of
                SalesCommentLine."Document Type"::Shipment,
              SalesCommentLine."Document Type"::"Posted Invoice",
              SalesCommentLine."Document Type"::"Posted Credit Memo",
              SalesCommentLine."Document Type"::"Posted Return Receipt":
                    exit(true);
            end
        else
            if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Purchase then
                case FromDocType of
                    PurchCommentLine."Document Type"::Receipt,
                  PurchCommentLine."Document Type"::"Posted Invoice",
                  PurchCommentLine."Document Type"::"Posted Credit Memo",
                  PurchCommentLine."Document Type"::"Posted Return Shipment":
                        exit(true);
                end;

        exit(false);
    end;

    local procedure InitSalesDeferralCode(var ToSalesLine: Record "Sales Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
    begin
        if ToSalesLine."No." = '' then
            exit;

        case ToSalesLine."Document Type" of
            ToSalesLine."Document Type"::Order,
          ToSalesLine."Document Type"::Invoice,
          ToSalesLine."Document Type"::"Credit Memo",
          ToSalesLine."Document Type"::"Return Order":
                case ToSalesLine.Type of
                    ToSalesLine.Type::"G/L Account":
                        begin
                            GLAccount.Get(ToSalesLine."No.");
                            ToSalesLine.Validate("Deferral Code", GLAccount."Default Deferral Template Code");
                        end;
                    ToSalesLine.Type::Item:
                        begin
                            Item.Get(ToSalesLine."No.");
                            ToSalesLine.Validate("Deferral Code", Item."Default Deferral Template Code");
                        end;
                    ToSalesLine.Type::Resource:
                        begin
                            Resource.Get(ToSalesLine."No.");
                            ToSalesLine.Validate("Deferral Code", Resource."Default Deferral Template Code");
                        end;
                end;
        end;
    end;

    local procedure InitFromSalesLine(var FromSalesLine2: Record "Sales Line"; var FromSalesLineBuf: Record "Sales Line")
    begin
        // Empty buffer fields
        FromSalesLine2 := FromSalesLineBuf;
        FromSalesLine2."Shipment No." := '';
        FromSalesLine2."Shipment Line No." := 0;
        FromSalesLine2."Return Receipt No." := '';
        FromSalesLine2."Return Receipt Line No." := 0;

        OnAfterInitFromSalesLine(FromSalesLine2, FromSalesLineBuf);
    end;

    local procedure CleanSpecialOrderDropShipmentInSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine."Purchase Order No." := '';
        SalesLine."Purch. Order Line No." := 0;
        SalesLine."Special Order Purchase No." := '';
        SalesLine."Special Order Purch. Line No." := 0;

        OnAfterCleanSpecialOrderDropShipmentInSalesLine(SalesLine);
    end;

    local procedure CleanSpecialOrderDropShipmentInPurchLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Sales Order No." := '';
        PurchaseLine."Sales Order Line No." := 0;
        PurchaseLine."Special Order Sales No." := '';
        PurchaseLine."Special Order Sales Line No." := 0;
        PurchaseLine."Drop Shipment" := false;
        PurchaseLine."Special Order" := false;
    end;

    local procedure RemoveDefaultDeferralCode(DeferralDocType: Integer; DocType: Integer; DocNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        if DeferralHeader.Get(DeferralDocType, '', '', DocType, DocNo, LineNo) then
            DeferralHeader.Delete();

        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", DocType);
        DeferralLine.SetRange("Document No.", DocNo);
        DeferralLine.SetRange("Line No.", LineNo);
        DeferralLine.DeleteAll();
    end;

    procedure DeferralTypeForSalesDoc(DocType: Option): Integer
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        case DocType of
            SalesDocType::Quote:
                exit(SalesCommentLine."Document Type"::Quote);
            SalesDocType::"Blanket Order":
                exit(SalesCommentLine."Document Type"::"Blanket Order");
            SalesDocType::Order:
                exit(SalesCommentLine."Document Type"::Order);
            SalesDocType::Invoice:
                exit(SalesCommentLine."Document Type"::Invoice);
            SalesDocType::"Return Order":
                exit(SalesCommentLine."Document Type"::"Return Order");
            SalesDocType::"Credit Memo":
                exit(SalesCommentLine."Document Type"::"Credit Memo");
            SalesDocType::"Posted Shipment":
                exit(SalesCommentLine."Document Type"::Shipment);
            SalesDocType::"Posted Invoice":
                exit(SalesCommentLine."Document Type"::"Posted Invoice");
            SalesDocType::"Posted Return Receipt":
                exit(SalesCommentLine."Document Type"::"Posted Return Receipt");
            SalesDocType::"Posted Credit Memo":
                exit(SalesCommentLine."Document Type"::"Posted Credit Memo");
        end;
    end;

    procedure DeferralTypeForPurchDoc(DocType: Option): Integer
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        case DocType of
            PurchDocType::Quote:
                exit(PurchCommentLine."Document Type"::Quote);
            PurchDocType::"Blanket Order":
                exit(PurchCommentLine."Document Type"::"Blanket Order");
            PurchDocType::Order:
                exit(PurchCommentLine."Document Type"::Order);
            PurchDocType::Invoice:
                exit(PurchCommentLine."Document Type"::Invoice);
            PurchDocType::"Return Order":
                exit(PurchCommentLine."Document Type"::"Return Order");
            PurchDocType::"Credit Memo":
                exit(PurchCommentLine."Document Type"::"Credit Memo");
            PurchDocType::"Posted Receipt":
                exit(PurchCommentLine."Document Type"::Receipt);
            PurchDocType::"Posted Invoice":
                exit(PurchCommentLine."Document Type"::"Posted Invoice");
            PurchDocType::"Posted Return Shipment":
                exit(PurchCommentLine."Document Type"::"Posted Return Shipment");
            PurchDocType::"Posted Credit Memo":
                exit(PurchCommentLine."Document Type"::"Posted Credit Memo");
        end;
    end;

    local procedure InitPurchDeferralCode(var ToPurchLine: Record "Purchase Line")
    begin
        if ToPurchLine."No." = '' then
            exit;

        case ToPurchLine."Document Type" of
            ToPurchLine."Document Type"::Order,
          ToPurchLine."Document Type"::Invoice,
          ToPurchLine."Document Type"::"Credit Memo",
          ToPurchLine."Document Type"::"Return Order":
                ToPurchLine.InitDeferralCode();
        end;
    end;

    local procedure CopySalesPostedDeferrals(ToSalesLine: Record "Sales Line"; DeferralDocType: Integer; FromDocType: Integer; FromDocNo: Code[20]; FromLineNo: Integer; ToDocType: Integer; ToDocNo: Code[20]; ToLineNo: Integer)
    begin
        ToSalesLine."Returns Deferral Start Date" :=
          CopyPostedDeferrals(DeferralDocType,
            FromDocType, FromDocNo, FromLineNo,
            ToDocType, ToDocNo, ToLineNo);
        ToSalesLine.Modify();
    end;

    local procedure CopyPurchPostedDeferrals(ToPurchaseLine: Record "Purchase Line"; DeferralDocType: Integer; FromDocType: Integer; FromDocNo: Code[20]; FromLineNo: Integer; ToDocType: Integer; ToDocNo: Code[20]; ToLineNo: Integer)
    begin
        ToPurchaseLine."Returns Deferral Start Date" :=
          CopyPostedDeferrals(DeferralDocType,
            FromDocType, FromDocNo, FromLineNo,
            ToDocType, ToDocNo, ToLineNo);
        ToPurchaseLine.Modify();
    end;

    procedure CheckDateOrder(PostingNo: Code[20]; PostingNoSeries: Code[20]; OldPostingDate: Date; NewPostingDate: Date): Boolean
    var
        NoSeries: Record "No. Series";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if IncludeHeader then
            if (PostingNo <> '') and (OldPostingDate <> NewPostingDate) then
                if NoSeries.Get(PostingNoSeries) then
                    if NoSeries."Date Order" then
                        exit(ConfirmManagement.GetResponseOrDefault(DiffPostDateOrderQst, true));
        exit(true)
    end;

    local procedure CheckSalesDocItselfCopy(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header")
    begin
        if (FromSalesHeader."Document Type" = ToSalesHeader."Document Type") and
           (FromSalesHeader."No." = ToSalesHeader."No.")
        then
            Error(Text001, ToSalesHeader."Document Type", ToSalesHeader."No.");
    end;

    local procedure CheckPurchDocItselfCopy(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header")
    begin
        if (FromPurchHeader."Document Type" = ToPurchHeader."Document Type") and
           (FromPurchHeader."No." = ToPurchHeader."No.")
        then
            Error(Text001, ToPurchHeader."Document Type", ToPurchHeader."No.");
    end;

    local procedure UpdateCustLedgEntry(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        OnBeforeUpdateCustLedgEntry(ToSalesHeader, CustLedgEntry);

        CustLedgEntry.SetCurrentKey("Document No.");
        if FromDocType = SalesDocType::"Posted Invoice" then
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice)
        else
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
        CustLedgEntry.SetRange("Document No.", FromDocNo);
        CustLedgEntry.SetRange("Customer No.", ToSalesHeader."Bill-to Customer No.");
        CustLedgEntry.SetRange(Open, true);
        if CustLedgEntry.FindFirst then begin
            ToSalesHeader."Bal. Account No." := '';
            if FromDocType = SalesDocType::"Posted Invoice" then begin
                ToSalesHeader."Applies-to Doc. Type" := ToSalesHeader."Applies-to Doc. Type"::Invoice;
                ToSalesHeader."Applies-to Doc. No." := FromDocNo;
            end else begin
                ToSalesHeader."Applies-to Doc. Type" := ToSalesHeader."Applies-to Doc. Type"::"Credit Memo";
                ToSalesHeader."Applies-to Doc. No." := FromDocNo;
            end;
            CustLedgEntry.CalcFields("Remaining Amount");
            CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
            CustLedgEntry."Accepted Payment Tolerance" := 0;
            CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
        end;
    end;

    procedure UpdateVendLedgEntry(var ToPurchHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        OnBeforeUpdateVendLedgEntry(ToPurchHeader, VendLedgEntry);

        VendLedgEntry.SetCurrentKey("Document No.");
        if FromDocType = PurchDocType::"Posted Invoice" then
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
        else
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
        VendLedgEntry.SetRange("Document No.", FromDocNo);
        VendLedgEntry.SetRange("Vendor No.", ToPurchHeader."Pay-to Vendor No.");
        VendLedgEntry.SetRange(Open, true);
        if VendLedgEntry.FindFirst then begin
            if FromDocType = PurchDocType::"Posted Invoice" then begin
                ToPurchHeader."Applies-to Doc. Type" := ToPurchHeader."Applies-to Doc. Type"::Invoice;
                ToPurchHeader."Applies-to Doc. No." := FromDocNo;
            end else begin
                ToPurchHeader."Applies-to Doc. Type" := ToPurchHeader."Applies-to Doc. Type"::"Credit Memo";
                ToPurchHeader."Applies-to Doc. No." := FromDocNo;
            end;
            VendLedgEntry.CalcFields("Remaining Amount");
            VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
            VendLedgEntry."Accepted Payment Tolerance" := 0;
            VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
        end;
    end;

    local procedure UpdatePurchCreditMemoHeader(var PurchaseHeader: Record "Purchase Header")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        with PurchaseHeader do begin
            "Expected Receipt Date" := 0D;
            GLSetup.Get();
            Correction := GLSetup."Mark Cr. Memos as Corrections";
            if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then
                PaymentTerms.Get("Payment Terms Code")
            else
                Clear(PaymentTerms);
            if not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                "Payment Discount %" := 0;
                "Pmt. Discount Date" := 0D;
            end;
        end;
    end;

    local procedure UpdateSalesCreditMemoHeader(var SalesHeader: Record "Sales Header")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        with SalesHeader do begin
            "Shipment Date" := 0D;
            GLSetup.Get();
            Correction := GLSetup."Mark Cr. Memos as Corrections";
            if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then
                PaymentTerms.Get("Payment Terms Code")
            else
                Clear(PaymentTerms);
            if not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                "Payment Discount %" := 0;
                "Pmt. Discount Date" := 0D;
            end;
        end;
    end;

    local procedure UpdateSalesInvoiceDiscountValue(var SalesHeader: Record "Sales Header")
    begin
        if IncludeHeader and RecalculateLines then begin
            SalesHeader.CalcFields(Amount);
            if SalesHeader."Invoice Discount Value" > SalesHeader.Amount then begin
                SalesHeader."Invoice Discount Value" := SalesHeader.Amount;
                SalesHeader.Modify();
            end;
        end;
    end;

    local procedure UpdatePurchaseInvoiceDiscountValue(var PurchaseHeader: Record "Purchase Header")
    begin
        if IncludeHeader and RecalculateLines then begin
            PurchaseHeader.CalcFields(Amount);
            if PurchaseHeader."Invoice Discount Value" > PurchaseHeader.Amount then begin
                PurchaseHeader."Invoice Discount Value" := PurchaseHeader.Amount;
                PurchaseHeader.Modify();
            end;
        end;
    end;

    local procedure ExtTxtAttachedToPosSalesLine(SalesHeader: Record "Sales Header"; MoveNegLines: Boolean; AttachedToLineNo: Integer): Boolean
    var
        AttachedToSalesLine: Record "Sales Line";
    begin
        if MoveNegLines then
            if AttachedToLineNo <> 0 then
                if AttachedToSalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", AttachedToLineNo) then
                    if AttachedToSalesLine.Quantity >= 0 then
                        exit(true);

        exit(false);
    end;

    local procedure ExtTxtAttachedToPosPurchLine(PurchHeader: Record "Purchase Header"; MoveNegLines: Boolean; AttachedToLineNo: Integer): Boolean
    var
        AttachedToPurchLine: Record "Purchase Line";
    begin
        if MoveNegLines then
            if AttachedToLineNo <> 0 then
                if AttachedToPurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", AttachedToLineNo) then
                    if AttachedToPurchLine.Quantity >= 0 then
                        exit(true);

        exit(false);
    end;

    local procedure SalesDocCanReceiveTracking(SalesHeader: Record "Sales Header"): Boolean
    begin
        exit(
          (SalesHeader."Document Type" <> SalesHeader."Document Type"::Quote) and
          (SalesHeader."Document Type" <> SalesHeader."Document Type"::"Blanket Order"));
    end;

    local procedure PurchaseDocCanReceiveTracking(PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        exit(
          (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Quote) and
          (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::"Blanket Order"));
    end;

    local procedure CheckFirstLineShipped(DocNo: Code[20]; ShipmentLineNo: Integer; var SalesCombDocLineNo: Integer; var NextLineNo: Integer; var FirstLineShipped: Boolean)
    begin
        if (DocNo = '') and (ShipmentLineNo = 0) and FirstLineShipped then begin
            FirstLineShipped := false;
            SalesCombDocLineNo := NextLineNo;
            NextLineNo := NextLineNo + 10000;
        end;
    end;

    local procedure SetTempSalesInvLine(FromSalesInvLine: Record "Sales Invoice Line"; var TempSalesInvLine: Record "Sales Invoice Line" temporary; var SalesInvLineCount: Integer; var NextLineNo: Integer; var FirstLineText: Boolean)
    begin
        if FromSalesInvLine.Type = FromSalesInvLine.Type::Item then begin
            SalesInvLineCount += 1;
            TempSalesInvLine := FromSalesInvLine;
            TempSalesInvLine.Insert();
            if FirstLineText then begin
                NextLineNo := NextLineNo + 10000;
                FirstLineText := false;
            end;
        end else
            if FromSalesInvLine.Type = FromSalesInvLine.Type::" " then
                FirstLineText := true;
    end;

    procedure InitAndCheckSalesDocuments(FromDocType: Option; FromDocNo: Code[20]; var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesShipmentHeader: Record "Sales Shipment Header"; var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var FromReturnReceiptHeader: Record "Return Receipt Header"; var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var FromSalesHeaderArchive: Record "Sales Header Archive"): Boolean
    begin
        with ToSalesHeader do
            case FromDocType of
                SalesDocType::Quote,
                SalesDocType::"Blanket Order",
                SalesDocType::Order,
                SalesDocType::Invoice,
                SalesDocType::"Return Order",
                SalesDocType::"Credit Memo":
                    begin
                        FromSalesHeader.Get(SalesHeaderDocType(FromDocType), FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromSalesHeader."Posting Date")
                        then
                            exit(false);
                        if MoveNegLines then
                            DeleteSalesLinesWithNegQty(FromSalesHeader, true);
                        CheckSalesDocItselfCopy(ToSalesHeader, FromSalesHeader);

                        if "Document Type" <= "Document Type"::Invoice then begin
                            FromSalesHeader.CalcFields("Amount Including VAT");
                            "Amount Including VAT" := FromSalesHeader."Amount Including VAT";
                            CheckCreditLimit(FromSalesHeader, ToSalesHeader);
                        end;
                        CheckCopyFromSalesHeaderAvail(FromSalesHeader, ToSalesHeader);

                        if not IncludeHeader and not RecalculateLines then
                            CheckFromSalesHeader(FromSalesHeader, ToSalesHeader);
                    end;
                SalesDocType::"Posted Shipment":
                    begin
                        FromSalesShipmentHeader.Get(FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromSalesShipmentHeader."Posting Date")
                        then
                            exit(false);
                        CheckCopyFromSalesShptAvail(FromSalesShipmentHeader, ToSalesHeader);

                        if not IncludeHeader and not RecalculateLines then
                            CheckFromSalesShptHeader(FromSalesShipmentHeader, ToSalesHeader);
                    end;
                SalesDocType::"Posted Invoice":
                    begin
                        FromSalesInvoiceHeader.Get(FromDocNo);
                        FromSalesInvoiceHeader.TestField("Prepayment Invoice", false);
                        WarnSalesInvoicePmtDisc(ToSalesHeader, FromSalesHeader, FromDocType, FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromSalesInvoiceHeader."Posting Date")
                        then
                            exit(false);
                        if "Document Type" <= "Document Type"::Invoice then begin
                            FromSalesInvoiceHeader.CalcFields("Amount Including VAT");
                            "Amount Including VAT" := FromSalesInvoiceHeader."Amount Including VAT";
                            if IncludeHeader then
                                FromSalesHeader.TransferFields(FromSalesInvoiceHeader);
                            CheckCreditLimit(FromSalesHeader, ToSalesHeader);
                        end;
                        CheckCopyFromSalesInvoiceAvail(FromSalesInvoiceHeader, ToSalesHeader);

                        if not IncludeHeader and not RecalculateLines then
                            CheckFromSalesInvHeader(FromSalesInvoiceHeader, ToSalesHeader);
                    end;
                SalesDocType::"Posted Return Receipt":
                    begin
                        FromReturnReceiptHeader.Get(FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromReturnReceiptHeader."Posting Date")
                        then
                            exit(false);
                        CheckCopyFromSalesRetRcptAvail(FromReturnReceiptHeader, ToSalesHeader);

                        if not IncludeHeader and not RecalculateLines then
                            CheckFromSalesReturnRcptHeader(FromReturnReceiptHeader, ToSalesHeader);
                    end;
                SalesDocType::"Posted Credit Memo":
                    begin
                        FromSalesCrMemoHeader.Get(FromDocNo);
                        FromSalesCrMemoHeader.TestField("Prepayment Credit Memo", false);
                        WarnSalesInvoicePmtDisc(ToSalesHeader, FromSalesHeader, FromDocType, FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromSalesCrMemoHeader."Posting Date")
                        then
                            exit(false);
                        if "Document Type" <= "Document Type"::Invoice then begin
                            FromSalesCrMemoHeader.CalcFields("Amount Including VAT");
                            "Amount Including VAT" := FromSalesCrMemoHeader."Amount Including VAT";
                            if IncludeHeader then
                                FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                            CheckCreditLimit(FromSalesHeader, ToSalesHeader);
                        end;
                        CheckCopyFromSalesCrMemoAvail(FromSalesCrMemoHeader, ToSalesHeader);

                        if not IncludeHeader and not RecalculateLines then
                            CheckFromSalesCrMemoHeader(FromSalesCrMemoHeader, ToSalesHeader);
                    end;
                SalesDocType::"Arch. Quote",
                SalesDocType::"Arch. Order",
                SalesDocType::"Arch. Blanket Order",
                SalesDocType::"Arch. Return Order":
                    begin
                        FromSalesHeaderArchive.Get(ArchSalesHeaderDocType(FromDocType), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo);
                        if SalesDocType <= SalesDocType::Invoice then begin
                            FromSalesHeaderArchive.CalcFields("Amount Including VAT");
                            "Amount Including VAT" := FromSalesHeaderArchive."Amount Including VAT";
                            CustCheckCreditLimit.SalesHeaderCheck(ToSalesHeader);
                        end;

                        CheckCopyFromSalesHeaderArchiveAvail(FromSalesHeaderArchive, ToSalesHeader);

                        if not IncludeHeader and not RecalculateLines then begin
                            FromSalesHeaderArchive.TestField("Sell-to Customer No.", "Sell-to Customer No.");
                            FromSalesHeaderArchive.TestField("Bill-to Customer No.", "Bill-to Customer No.");
                            FromSalesHeaderArchive.TestField("Customer Posting Group", "Customer Posting Group");
                            FromSalesHeaderArchive.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromSalesHeaderArchive.TestField("Currency Code", "Currency Code");
                            FromSalesHeaderArchive.TestField("Prices Including VAT", "Prices Including VAT");
                        end;
                    end;
            end;

        OnAfterInitAndCheckSalesDocuments(
          FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo,
          FromSalesHeader, ToSalesHeader, ToSalesLine,
          FromSalesShipmentHeader, FromSalesInvoiceHeader, FromReturnReceiptHeader, FromSalesCrMemoHeader, FromSalesHeaderArchive,
          IncludeHeader, RecalculateLines);

        exit(true);
    end;

    procedure InitAndCheckPurchaseDocuments(FromDocType: Option; FromDocNo: Code[20]; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var FromPurchInvHeader: Record "Purch. Inv. Header"; var FromReturnShipmentHeader: Record "Return Shipment Header"; var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var FromPurchaseHeaderArchive: Record "Purchase Header Archive"): Boolean
    begin
        with ToPurchaseHeader do
            case FromDocType of
                PurchDocType::Quote,
                PurchDocType::"Blanket Order",
                PurchDocType::Order,
                PurchDocType::Invoice,
                PurchDocType::"Return Order",
                PurchDocType::"Credit Memo":
                    begin
                        FromPurchaseHeader.Get(PurchHeaderDocType(FromDocType), FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromPurchaseHeader."Posting Date")
                        then
                            exit(false);
                        if MoveNegLines then
                            DeletePurchLinesWithNegQty(FromPurchaseHeader, true);
                        CheckPurchDocItselfCopy(ToPurchaseHeader, FromPurchaseHeader);
                        if not IncludeHeader and not RecalculateLines then
                            CheckFromPurchaseHeader(FromPurchaseHeader, ToPurchaseHeader);
                    end;
                PurchDocType::"Posted Receipt":
                    begin
                        FromPurchRcptHeader.Get(FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromPurchRcptHeader."Posting Date")
                        then
                            exit(false);
                        if not IncludeHeader and not RecalculateLines then
                            CheckFromPurchaseRcptHeader(FromPurchRcptHeader, ToPurchaseHeader);
                    end;
                PurchDocType::"Posted Invoice":
                    begin
                        FromPurchInvHeader.Get(FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromPurchInvHeader."Posting Date")
                        then
                            exit(false);
                        FromPurchInvHeader.TestField("Prepayment Invoice", false);
                        WarnPurchInvoicePmtDisc(ToPurchaseHeader, FromPurchaseHeader, FromDocType, FromDocNo);
                        if not IncludeHeader and not RecalculateLines then
                            CheckFromPurchaseInvHeader(FromPurchInvHeader, ToPurchaseHeader);
                    end;
                PurchDocType::"Posted Return Shipment":
                    begin
                        FromReturnShipmentHeader.Get(FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromReturnShipmentHeader."Posting Date")
                        then
                            exit(false);
                        if not IncludeHeader and not RecalculateLines then
                            CheckFromPurchaseReturnShptHeader(FromReturnShipmentHeader, ToPurchaseHeader);
                    end;
                PurchDocType::"Posted Credit Memo":
                    begin
                        FromPurchCrMemoHdr.Get(FromDocNo);
                        if not CheckDateOrder(
                             "Posting No.", "Posting No. Series",
                             "Posting Date", FromPurchCrMemoHdr."Posting Date")
                        then
                            exit(false);
                        FromPurchCrMemoHdr.TestField("Prepayment Credit Memo", false);
                        WarnPurchInvoicePmtDisc(ToPurchaseHeader, FromPurchaseHeader, FromDocType, FromDocNo);
                        if not IncludeHeader and not RecalculateLines then
                            CheckFromPurchaseCrMemoHeader(FromPurchCrMemoHdr, ToPurchaseHeader);
                    end;
                PurchDocType::"Arch. Order",
                PurchDocType::"Arch. Quote",
                PurchDocType::"Arch. Blanket Order",
                PurchDocType::"Arch. Return Order":
                    begin
                        FromPurchaseHeaderArchive.Get(ArchPurchHeaderDocType(FromDocType), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo);
                        if not IncludeHeader and not RecalculateLines then begin
                            FromPurchaseHeaderArchive.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");
                            FromPurchaseHeaderArchive.TestField("Pay-to Vendor No.", "Pay-to Vendor No.");
                            FromPurchaseHeaderArchive.TestField("Vendor Posting Group", "Vendor Posting Group");
                            FromPurchaseHeaderArchive.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                            FromPurchaseHeaderArchive.TestField("Currency Code", "Currency Code");
                        end;
                    end;
            end;

        OnAfterInitAndCheckPurchaseDocuments(
          FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo,
          FromPurchaseHeader, ToPurchaseHeader,
          FromPurchRcptHeader, FromPurchInvHeader, FromReturnShipmentHeader, FromPurchCrMemoHdr, FromPurchaseHeaderArchive,
          IncludeHeader, RecalculateLines);

        exit(true);
    end;

    local procedure InitSalesLineFields(var ToSalesLine: Record "Sales Line")
    begin
        OnBeforeInitSalesLineFields(ToSalesLine);

        if ToSalesLine."Document Type" <> ToSalesLine."Document Type"::Order then begin
            ToSalesLine."Prepayment %" := 0;
            ToSalesLine."Prepayment VAT %" := 0;
            ToSalesLine."Prepmt. VAT Calc. Type" := 0;
            ToSalesLine."Prepayment VAT Identifier" := '';
            ToSalesLine."Prepayment VAT %" := 0;
            ToSalesLine."Prepayment Tax Group Code" := '';
            ToSalesLine."Prepmt. Line Amount" := 0;
            ToSalesLine."Prepmt. Amt. Incl. VAT" := 0;
        end;
        ToSalesLine."Prepmt. Amt. Inv." := 0;
        ToSalesLine."Prepmt. Amount Inv. (LCY)" := 0;
        ToSalesLine."Prepayment Amount" := 0;
        ToSalesLine."Prepmt. VAT Base Amt." := 0;
        ToSalesLine."Prepmt Amt to Deduct" := 0;
        ToSalesLine."Prepmt Amt Deducted" := 0;
        ToSalesLine."Prepmt. Amount Inv. Incl. VAT" := 0;
        ToSalesLine."Prepayment VAT Difference" := 0;
        ToSalesLine."Prepmt VAT Diff. to Deduct" := 0;
        ToSalesLine."Prepmt VAT Diff. Deducted" := 0;
        ToSalesLine."Prepmt. Amt. Incl. VAT" := 0;
        ToSalesLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
        ToSalesLine."Quantity Shipped" := 0;
        ToSalesLine."Qty. Shipped (Base)" := 0;
        ToSalesLine."Return Qty. Received" := 0;
        ToSalesLine."Return Qty. Received (Base)" := 0;
        ToSalesLine."Quantity Invoiced" := 0;
        ToSalesLine."Qty. Invoiced (Base)" := 0;
        ToSalesLine."Reserved Quantity" := 0;
        ToSalesLine."Reserved Qty. (Base)" := 0;
        ToSalesLine."Qty. to Ship" := 0;
        ToSalesLine."Qty. to Ship (Base)" := 0;
        ToSalesLine."Return Qty. to Receive" := 0;
        ToSalesLine."Return Qty. to Receive (Base)" := 0;
        ToSalesLine."Qty. to Invoice" := 0;
        ToSalesLine."Qty. to Invoice (Base)" := 0;
        ToSalesLine."Qty. Shipped Not Invoiced" := 0;
        ToSalesLine."Return Qty. Rcd. Not Invd." := 0;
        ToSalesLine."Shipped Not Invoiced" := 0;
        ToSalesLine."Return Rcd. Not Invd." := 0;
        ToSalesLine."Qty. Shipped Not Invd. (Base)" := 0;
        ToSalesLine."Ret. Qty. Rcd. Not Invd.(Base)" := 0;
        ToSalesLine."Shipped Not Invoiced (LCY)" := 0;
        ToSalesLine."Return Rcd. Not Invd. (LCY)" := 0;
        ToSalesLine."Job No." := '';
        ToSalesLine."Job Task No." := '';
        ToSalesLine."Job Contract Entry No." := 0;

        OnAfterInitSalesLineFields(ToSalesLine);
    end;

    local procedure InitPurchLineFields(var ToPurchLine: Record "Purchase Line")
    begin
        OnBeforeInitPurchLineFields(ToPurchLine);

        if ToPurchLine."Document Type" <> ToPurchLine."Document Type"::Order then begin
            ToPurchLine."Prepayment %" := 0;
            ToPurchLine."Prepayment VAT %" := 0;
            ToPurchLine."Prepmt. VAT Calc. Type" := 0;
            ToPurchLine."Prepayment VAT Identifier" := '';
            ToPurchLine."Prepayment VAT %" := 0;
            ToPurchLine."Prepayment Tax Group Code" := '';
            ToPurchLine."Prepmt. Line Amount" := 0;
            ToPurchLine."Prepmt. Amt. Incl. VAT" := 0;
        end;
        ToPurchLine."Prepmt. Amt. Inv." := 0;
        ToPurchLine."Prepmt. Amount Inv. (LCY)" := 0;
        ToPurchLine."Prepayment Amount" := 0;
        ToPurchLine."Prepmt. VAT Base Amt." := 0;
        ToPurchLine."Prepmt Amt to Deduct" := 0;
        ToPurchLine."Prepmt Amt Deducted" := 0;
        ToPurchLine."Prepmt. Amount Inv. Incl. VAT" := 0;
        ToPurchLine."Prepayment VAT Difference" := 0;
        ToPurchLine."Prepmt VAT Diff. to Deduct" := 0;
        ToPurchLine."Prepmt VAT Diff. Deducted" := 0;
        ToPurchLine."Prepmt. Amt. Incl. VAT" := 0;
        ToPurchLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
        ToPurchLine."Quantity Received" := 0;
        ToPurchLine."Qty. Received (Base)" := 0;
        ToPurchLine."Return Qty. Shipped" := 0;
        ToPurchLine."Return Qty. Shipped (Base)" := 0;
        ToPurchLine."Quantity Invoiced" := 0;
        ToPurchLine."Qty. Invoiced (Base)" := 0;
        ToPurchLine."Reserved Quantity" := 0;
        ToPurchLine."Reserved Qty. (Base)" := 0;
        ToPurchLine."Qty. Rcd. Not Invoiced" := 0;
        ToPurchLine."Qty. Rcd. Not Invoiced (Base)" := 0;
        ToPurchLine."Return Qty. Shipped Not Invd." := 0;
        ToPurchLine."Ret. Qty. Shpd Not Invd.(Base)" := 0;
        ToPurchLine."Qty. to Receive" := 0;
        ToPurchLine."Qty. to Receive (Base)" := 0;
        ToPurchLine."Return Qty. to Ship" := 0;
        ToPurchLine."Return Qty. to Ship (Base)" := 0;
        ToPurchLine."Qty. to Invoice" := 0;
        ToPurchLine."Qty. to Invoice (Base)" := 0;
        ToPurchLine."Amt. Rcd. Not Invoiced" := 0;
        ToPurchLine."Amt. Rcd. Not Invoiced (LCY)" := 0;
        ToPurchLine."Return Shpd. Not Invd." := 0;
        ToPurchLine."Return Shpd. Not Invd. (LCY)" := 0;

        OnAfterInitPurchLineFields(ToPurchLine);
    end;

    local procedure CopySalesJobFields(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesJobFields(ToSalesLine, FromSalesLine, IsHandled);
        if IsHandled then
            exit;

        ToSalesLine."Job No." := FromSalesLine."Job No.";
        ToSalesLine."Job Task No." := FromSalesLine."Job Task No.";
        if ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Invoice then
            ToSalesLine."Job Contract Entry No." :=
              CreateJobPlanningLine(ToSalesHeader, ToSalesLine, FromSalesLine."Job Contract Entry No.")
        else
            ToSalesLine."Job Contract Entry No." := FromSalesLine."Job Contract Entry No.";
    end;

    local procedure CopySalesLineExtText(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; DocLineNo: Integer; var NextLineNo: Integer)
    var
        ToSalesLine2: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesLineExtText(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, DocLineNo, NextLineNo, IsHandled);
        if IsHandled then
            exit;

        if (ToSalesHeader."Language Code" <> FromSalesHeader."Language Code") or RecalculateLines or CopyExtText then
            if TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, false) then begin
                TransferExtendedText.InsertSalesExtText(ToSalesLine);
                ToSalesLine2.SetRange("Document Type", ToSalesLine."Document Type");
                ToSalesLine2.SetRange("Document No.", ToSalesLine."Document No.");
                ToSalesLine2.FindLast;
                NextLineNo := ToSalesLine2."Line No.";
                exit;
            end;

        ToSalesLine."Attached to Line No." :=
          TransferOldExtLines.TransferExtendedText(DocLineNo, NextLineNo, FromSalesLine."Attached to Line No.");
    end;

    procedure CopySalesLinesToDoc(FromDocType: Option; ToSalesHeader: Record "Sales Header"; var FromSalesShipmentLine: Record "Sales Shipment Line"; var FromSalesInvoiceLine: Record "Sales Invoice Line"; var FromReturnReceiptLine: Record "Return Receipt Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
        OnBeforeCopySalesLinesToDoc(
          FromDocType, ToSalesHeader, FromSalesShipmentLine, FromSalesInvoiceLine, FromReturnReceiptLine, FromSalesCrMemoLine,
          LinesNotCopied, MissingExCostRevLink);
        CopyExtText := true;
        case FromDocType of
            SalesDocType::"Posted Shipment":
                CopySalesShptLinesToDoc(ToSalesHeader, FromSalesShipmentLine, LinesNotCopied, MissingExCostRevLink);
            SalesDocType::"Posted Invoice":
                CopySalesInvLinesToDoc(ToSalesHeader, FromSalesInvoiceLine, LinesNotCopied, MissingExCostRevLink);
            SalesDocType::"Posted Return Receipt":
                CopySalesReturnRcptLinesToDoc(ToSalesHeader, FromReturnReceiptLine, LinesNotCopied, MissingExCostRevLink);
            SalesDocType::"Posted Credit Memo":
                CopySalesCrMemoLinesToDoc(ToSalesHeader, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
        end;
        CopyExtText := false;
        OnAfterCopySalesLinesToDoc(
          FromDocType, ToSalesHeader, FromSalesShipmentLine, FromSalesInvoiceLine, FromReturnReceiptLine, FromSalesCrMemoLine,
          LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyPurchaseJobFields(var ToPurchLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyPurchaseJobFields(ToPurchLine, FromPurchLine, IsHandled);
        if IsHandled then
            exit;

        ToPurchLine.Validate("Job No.", FromPurchLine."Job No.");
        ToPurchLine.Validate("Job Task No.", FromPurchLine."Job Task No.");
        ToPurchLine.Validate("Job Line Type", FromPurchLine."Job Line Type");
    end;

    local procedure CopyPurchLineExtText(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; FromPurchLine: Record "Purchase Line"; DocLineNo: Integer; var NextLineNo: Integer)
    var
        ToPurchLine2: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyPurchLineExtText(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, DocLineNo, NextLineNo, IsHandled);
        if IsHandled then
            exit;

        if (ToPurchHeader."Language Code" <> FromPurchHeader."Language Code") or RecalculateLines or CopyExtText then
            if TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, false) then begin
                TransferExtendedText.InsertPurchExtText(ToPurchLine);
                ToPurchLine2.SetRange("Document Type", ToPurchLine."Document Type");
                ToPurchLine2.SetRange("Document No.", ToPurchLine."Document No.");
                ToPurchLine2.FindLast;
                NextLineNo := ToPurchLine2."Line No.";
                exit;
            end;

        ToPurchLine."Attached to Line No." :=
          TransferOldExtLines.TransferExtendedText(DocLineNo, NextLineNo, FromPurchLine."Attached to Line No.");
    end;

    procedure CopyPurchaseLinesToDoc(FromDocType: Option; ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var FromPurchInvLine: Record "Purch. Inv. Line"; var FromReturnShipmentLine: Record "Return Shipment Line"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
        OnBeforeCopyPurchaseLinesToDoc(
          FromDocType, ToPurchaseHeader, FromPurchRcptLine, FromPurchInvLine, FromReturnShipmentLine, FromPurchCrMemoLine,
          LinesNotCopied, MissingExCostRevLink);
        CopyExtText := true;
        case FromDocType of
            PurchDocType::"Posted Receipt":
                CopyPurchRcptLinesToDoc(ToPurchaseHeader, FromPurchRcptLine, LinesNotCopied, MissingExCostRevLink);
            PurchDocType::"Posted Invoice":
                CopyPurchInvLinesToDoc(ToPurchaseHeader, FromPurchInvLine, LinesNotCopied, MissingExCostRevLink);
            PurchDocType::"Posted Return Shipment":
                CopyPurchReturnShptLinesToDoc(ToPurchaseHeader, FromReturnShipmentLine, LinesNotCopied, MissingExCostRevLink);
            PurchDocType::"Posted Credit Memo":
                CopyPurchCrMemoLinesToDoc(ToPurchaseHeader, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
        end;
        CopyExtText := false;
        OnAfterCopyPurchaseLinesToDoc(
          FromDocType, ToPurchaseHeader, FromPurchRcptLine, FromPurchInvLine, FromReturnShipmentLine, FromPurchCrMemoLine,
          LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyShiptoCodeFromInvToCrMemo(var ToSalesHeader: Record "Sales Header"; FromSalesInvHeader: Record "Sales Invoice Header"; FromDocType: Option)
    begin
        if (FromDocType = SalesDocType::"Posted Invoice") and
           (FromSalesInvHeader."Ship-to Code" <> '') and
           (ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::"Credit Memo")
        then
            ToSalesHeader."Ship-to Code" := FromSalesInvHeader."Ship-to Code";
    end;

    local procedure TransferFieldsFromCrMemoToInv(var ToSalesHeader: Record "Sales Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        ToSalesHeader.Validate("Sell-to Customer No.", FromSalesCrMemoHeader."Sell-to Customer No.");
        ToSalesHeader.TransferFields(FromSalesCrMemoHeader, false);
        if (ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Invoice) and IncludeHeader then begin
            ToSalesHeader.CopySellToAddressToShipToAddress;
            ToSalesHeader.Validate("Ship-to Code", FromSalesCrMemoHeader."Ship-to Code");
        end;

        OnAfterTransferFieldsFromCrMemoToInv(ToSalesHeader, FromSalesCrMemoHeader, CopyJobData);
    end;

    local procedure CopyShippingInfoPurchOrder(var ToPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header")
    begin
        if (ToPurchaseHeader."Document Type" = ToPurchaseHeader."Document Type"::Order) and
           (FromPurchaseHeader."Document Type" = FromPurchaseHeader."Document Type"::Order)
        then begin
            ToPurchaseHeader."Ship-to Address" := FromPurchaseHeader."Ship-to Address";
            ToPurchaseHeader."Ship-to Address 2" := FromPurchaseHeader."Ship-to Address 2";
            ToPurchaseHeader."Ship-to City" := FromPurchaseHeader."Ship-to City";
            ToPurchaseHeader."Ship-to Country/Region Code" := FromPurchaseHeader."Ship-to Country/Region Code";
            ToPurchaseHeader."Ship-to County" := FromPurchaseHeader."Ship-to County";
            ToPurchaseHeader."Ship-to Name" := FromPurchaseHeader."Ship-to Name";
            ToPurchaseHeader."Ship-to Name 2" := FromPurchaseHeader."Ship-to Name 2";
            ToPurchaseHeader."Ship-to Post Code" := FromPurchaseHeader."Ship-to Post Code";
            ToPurchaseHeader."Ship-to Contact" := FromPurchaseHeader."Ship-to Contact";
            ToPurchaseHeader."Inbound Whse. Handling Time" := FromPurchaseHeader."Inbound Whse. Handling Time";
        end;
    end;

    local procedure SetSalespersonPurchaserCode(var SalespersonPurchaserCode: Code[20])
    begin
        if SalespersonPurchaserCode <> '' then
            if SalespersonPurchaser.Get(SalespersonPurchaserCode) then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    SalespersonPurchaserCode := ''
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesLine(var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; RecalculateAmount: Boolean; var CopyThisLine: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyArchSalesLine(var ToSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive"; FromSalesLineArchive: Record "Sales Line Archive"; RecalculateAmount: Boolean; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchLine(var ToPurchHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header"; FromPurchLine: Record "Purchase Line"; RecalculateAmount: Boolean; var CopyThisLine: Boolean; ToPurchLine: Record "Purchase Line"; MoveNegLines: Boolean; var RoundingLineInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyArchPurchLine(var ToPurchHeader: Record "Purchase Header"; FromPurchHeaderArchive: Record "Purchase Header Archive"; FromPurchLineArchive: Record "Purchase Line Archive"; RecalculateAmount: Boolean; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesHeader(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20]; IncludeHeader: Boolean; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean)
    begin
    end;

    local procedure AddSalesDocLine(var TempDocSalesLine: Record "Sales Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
        OnBeforeAddSalesDocLine(TempDocSalesLine, BufferLineNo, DocumentNo, DocumentLineNo);

        TempDocSalesLine."Document No." := DocumentNo;
        TempDocSalesLine."Line No." := DocumentLineNo;
        TempDocSalesLine."Shipment Line No." := BufferLineNo;
        TempDocSalesLine.Insert();
    end;

    local procedure GetSalesLineNo(var TempDocSalesLine: Record "Sales Line" temporary; BufferLineNo: Integer): Integer
    begin
        TempDocSalesLine.SetRange("Shipment Line No.", BufferLineNo);
        if not TempDocSalesLine.FindFirst then
            exit(0);
        exit(TempDocSalesLine."Line No.");
    end;

    local procedure GetSalesDocNo(var TempDocSalesLine: Record "Sales Line" temporary; BufferLineNo: Integer): Code[20]
    begin
        TempDocSalesLine.SetRange("Shipment Line No.", BufferLineNo);
        if not TempDocSalesLine.FindFirst then
            exit('');
        exit(TempDocSalesLine."Document No.");
    end;

    local procedure AddPurchDocLine(var TempDocPurchaseLine: Record "Purchase Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
        OnBeforeAddPurchDocLine(TempDocPurchaseLine, BufferLineNo, DocumentNo, DocumentLineNo);

        TempDocPurchaseLine."Document No." := DocumentNo;
        TempDocPurchaseLine."Line No." := DocumentLineNo;
        TempDocPurchaseLine."Receipt Line No." := BufferLineNo;
        TempDocPurchaseLine.Insert();
    end;

    local procedure GetPurchLineNo(var TempDocPurchaseLine: Record "Purchase Line" temporary; BufferLineNo: Integer): Integer
    begin
        TempDocPurchaseLine.SetRange("Receipt Line No.", BufferLineNo);
        if not TempDocPurchaseLine.FindFirst then
            exit(0);
        exit(TempDocPurchaseLine."Line No.");
    end;

    local procedure GetPurchDocNo(var TempDocPurchaseLine: Record "Purchase Line" temporary; BufferLineNo: Integer): Code[20]
    begin
        TempDocPurchaseLine.SetRange("Receipt Line No.", BufferLineNo);
        if not TempDocPurchaseLine.FindFirst then
            exit('');
        exit(TempDocPurchaseLine."Document No.");
    end;

    local procedure SetTrackingOnAssemblyReservation(AssemblyHeader: Record "Assembly Header"; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        QtyToAddAsBlank: Decimal;
    begin
        TempItemLedgerEntry.SetFilter("Lot No.", '<>%1', '');
        if TempItemLedgerEntry.IsEmpty then
            exit;

        ReservationEntry.SetRange("Source Type", DATABASE::"Assembly Header");
        ReservationEntry.SetRange("Source Subtype", AssemblyHeader."Document Type");
        ReservationEntry.SetRange("Source ID", AssemblyHeader."No.");
        ReservationEntry.SetRange("Source Ref. No.", 0);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        if ReservationEntry.FindSet then
            repeat
                TempReservationEntry := ReservationEntry;
                TempReservationEntry.Insert();
            until ReservationEntry.Next = 0;

        if TempItemLedgerEntry.FindSet then
            repeat
                TempTrackingSpecification."Entry No." += 1;
                TempTrackingSpecification."Item No." := TempItemLedgerEntry."Item No.";
                TempTrackingSpecification."Location Code" := TempItemLedgerEntry."Location Code";
                TempTrackingSpecification."Quantity (Base)" := TempItemLedgerEntry.Quantity;
                TempTrackingSpecification.CopyTrackingFromItemledgEntry(TempItemLedgerEntry);
                TempTrackingSpecification."Warranty Date" := TempItemLedgerEntry."Warranty Date";
                TempTrackingSpecification."Expiration Date" := TempItemLedgerEntry."Expiration Date";
                TempTrackingSpecification.Insert();
            until TempItemLedgerEntry.Next = 0;

        if TempTrackingSpecification.FindSet then
            repeat
                if GetItemTrackingCode(ItemTrackingCode, TempTrackingSpecification."Item No.") then
                    ReservationEngineMgt.AddItemTrackingToTempRecSet(
                        TempReservationEntry, TempTrackingSpecification, TempTrackingSpecification."Quantity (Base)",
                        QtyToAddAsBlank, ItemTrackingCode);
            until TempTrackingSpecification.Next = 0;
    end;

    local procedure GetItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; ItemNo: Code[20]): Boolean
    begin
        if not Item.Get(ItemNo) then
            exit(false);

        if Item."Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.Get(Item."Item Tracking Code");
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPurchDocLine(var TempDocPurchaseLine: Record "Purchase Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSalesDocLine(var TempDocSalesLine: Record "Sales Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchLines(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchInvLines(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromPurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchCrMemoLinesToDoc(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseLinesToDoc(FromDocType: Option; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var FromPurchInvLine: Record "Purch. Inv. Line"; var FromReturnShipmentLine: Record "Return Shipment Line"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchReturnShptLinesToDoc(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseJobFields(var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchLineExtText(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; FromPurchLine: Record "Purchase Line"; DocLineNo: Integer; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesShptLinesToDoc(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesShptLinesToBuffer(var FromSalesLine: Record "Sales Line"; var FromSalesShptLine: Record "Sales Shipment Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesInvLines(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesInvLine: Record "Sales Invoice Line"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesInvLinesToBuffer(var FromSalesLine: Record "Sales Line"; var FromSalesInvLine: Record "Sales Invoice Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesCrMemoLinesToDoc(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesCrMemoLinesToBuffer(var FromSalesLine: Record "Sales Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesReturnRcptLinesToDoc(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesReturnRcptLinesToBuffer(var FromSalesLine: Record "Sales Line"; var FromReturnReceiptLine: Record "Return Receipt Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesToPurchDoc(var ToPurchLine: Record "Purchase Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesLinesToDoc(FromDocType: Option; var ToSalesHeader: Record "Sales Header"; var FromSalesShipmentLine: Record "Sales Shipment Line"; var FromSalesInvoiceLine: Record "Sales Invoice Line"; var FromReturnReceiptLine: Record "Return Receipt Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesJobFields(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesLineExtText(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; DocLineNo: Integer; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesDocForInvoiceCancelling(var ToSalesHeader: Record "Sales Header"; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesDocForCrMemoCancelling(var ToSalesHeader: Record "Sales Header"; FromDocNo: Code[20]; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseDocForInvoiceCancelling(var ToPurchaseHeader: Record "Purchase Header"; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseDocForCrMemoCancelling(var ToPurchaseHeader: Record "Purchase Header"; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteNegSalesLines(FromDocType: Option; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobPlanningLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var JobContractEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetShipmentDateInLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransfldsFromSalesToPurchLine(var FromSalesLine: Record "Sales Line"; var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromSalesDocType: Option; var CopyPostedDeferral: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchHeader(var ToPurchHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20]; IncludeHeader: Boolean; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromPurchDocType: Option; var CopyPostedDeferral: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesHeader(SalesHeaderFrom: Record "Sales Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesShptHeader(SalesShipmentHeaderFrom: Record "Sales Shipment Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesInvHeader(SalesInvoiceHeaderFrom: Record "Sales Invoice Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesCrMemoHeader(SalesCrMemoHeaderFrom: Record "Sales Cr.Memo Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesReturnRcptHeader(ReturnReceiptHeaderFrom: Record "Return Receipt Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseHeader(PurchaseHeaderFrom: Record "Purchase Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseRcptHeader(PurchRcptHeaderFrom: Record "Purch. Rcpt. Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseInvHeader(PurchInvHeaderFrom: Record "Purch. Inv. Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseCrMemoHeader(PurchCrMemoHdrFrom: Record "Purch. Cr. Memo Hdr."; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseReturnShptHeader(ReturnShipmentHeaderFrom: Record "Return Shipment Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchDocAssgntToLine(var ToPurchaseLine: Record "Purchase Line"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesDocAssgntToLine(var ToSalesLine: Record "Sales Line"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyArchSalesLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyArchPurchLine(ToPurchHeader: Record "Purchase Header"; var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLineArchive: Record "Purchase Line Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedReceipt(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedShipment(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; FromSalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedPurchInvoice(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedReturnReceipt(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedReturnShipment(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToSalesHeader: Record "Sales Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; IncludeHeader: Boolean; RecalculateLines: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesHeaderArchive(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesHeaderDone(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromSalesShipmentHeader: Record "Sales Shipment Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header"; FromReturnReceiptHeader: Record "Return Receipt Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesHeaderDone(var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesInvLine(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesLineBuf: Record "Sales Line"; var FromSalesInvLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLinesToBufferFields(var TempSalesLine: Record "Sales Line" temporary; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLinesToDoc(FromDocType: Option; var ToSalesHeader: Record "Sales Header"; var FromSalesShipmentLine: Record "Sales Shipment Line"; var FromSalesInvoiceLine: Record "Sales Invoice Line"; var FromReturnReceiptLine: Record "Return Receipt Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyServContractLines(ToServiceContractHeader: Record "Service Contract Header"; FromDocType: Option; FromDocNo: Code[20]; var FormServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; IncludeHeader: Boolean; RecalculateLines: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchHeaderArchive(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchaseHeaderArchive: Record "Purchase Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchHeaderDone(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header"; FromPurchRcptHeader: Record "Purch. Rcpt. Header"; FromPurchInvHeader: Record "Purch. Inv. Header"; ReturnShipmentHeader: Record "Return Shipment Header"; FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; FromPurchaseHeaderArchive: Record "Purchase Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchHeaderDone(var ToPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchInvLines(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromPurchLineBuf: Record "Purchase Line"; var FromPurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchInvLine(FromPurchInvLine: Record "Purch. Inv. Line"; ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLinesToBufferFields(var TempPurchaseLine: Record "Purchase Line" temporary; FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchaseLinesToDoc(FromDocType: Option; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var FromPurchInvLine: Record "Purch. Inv. Line"; var FromReturnShipmentLine: Record "Return Shipment Line"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchCrMemoLine(FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchRcptLine(FromPurchRcptLine: Record "Purch. Rcpt. Line"; ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyReturnShptLine(FromReturnShipmentLine: Record "Return Shipment Line"; ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(var FromSalesLine2: Record "Sales Line"; var FromSalesLineBuf: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessServContractLine(var ToServContractLine: Record "Service Contract Line"; FromServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculatePurchLine(var PurchaseLine: Record "Purchase Line"; var ToPurchHeader: Record "Purchase Header"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultValuesToSalesLine(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultValuesToPurchLine(var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromCrMemoToInv(var ToSalesHeader: Record "Sales Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferTempAsmHeader(var TempAssemblyHeader: Record "Assembly Header" temporary; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromSalesDocType: Option; var CopyPostedDeferral: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromPurchDocType: Option; var CopyPostedDeferral: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLine(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLine(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocWithHeader(FromDocType: Option; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPostedDeferralsOnBeforeDeferralHeaderInsert(var DeferralHeader: Record "Deferral Header"; PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPostedDeferralsOnBeforeDeferralHeaderModify(var DeferralHeader: Record "Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPostedDeferralsOnBeforeDeferralLineInsert(var DeferralLine: Record "Deferral Line"; PostedDeferralLine: Record "Posted Deferral Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocWithHeader(FromDocType: Option; FromDocNo: Code[20]; var ToPurchHeader: Record "Purchase Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransfldsFromSalesToPurchLine(var FromSalesLine: Record "Sales Line"; var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAndCheckSalesDocuments(FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesShipmentHeader: Record "Sales Shipment Header"; var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var FromReturnReceiptHeader: Record "Return Receipt Header"; var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var FromSalesHeaderArchive: Record "Sales Header Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAndCheckPurchaseDocuments(FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var FromPurchInvHeader: Record "Purch. Inv. Header"; var FromReturnShipmentHeader: Record "Return Shipment Header"; var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var FromPurchaseHeaderArchive: Record "Purchase Header Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSalesLineFields(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPurchLineFields(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitToSalesLine(var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSalesLineFields(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPurchLineFields(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertToSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; FromDocType: Option; RecalcLines: Boolean; var ToSalesHeader: Record "Sales Header"; DocLineNo: Integer; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldSalesDocNoLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldSalesCombDocNoLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; CopyFromInvoice: Boolean; OldDocNo: Code[20]; OldDocNo2: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitToPurchLine(var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertToPurchLine(var ToPurchLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; FromDocType: Option; RecalcLines: Boolean; var ToPurchHeader: Record "Purchase Header"; DocLineNo: Integer; var NexLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldPurchDocNoLine(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldPurchCombDocNoLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; CopyFromInvoice: Boolean; OldDocNo: Code[20]; OldDocNo2: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPurchDoc(var ToPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesDoc(var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgEntry(var ToSalesHeader: Record "Sales Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendLedgEntry(var ToPurchaseHeader: Record "Purchase Header"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertToSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; RecalculateLines: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesToPurchDoc(var ToPurchLine: Record "Purchase Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertToPurchLine(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line"; RecalculateLines: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesHeader(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCleanSpecialOrderDropShipmentInSalesLine(var SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchaseHeader(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromSalesDocSalesLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromSalesLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesInvLine: Record "Sales Invoice Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line"; var FromSalesLine2: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromSalesCrMemoLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromSalesShptLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesShipmentLine: Record "Sales Shipment Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromReturnRcptLineBuffer(var ToSalesLine: Record "Sales Line"; FromReturnReceiptLine: Record "Return Receipt Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line"; CopyItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineFromPurchLineBuffer(var ToPurchLine: Record "Purchase Line"; FromPurchInvLine: Record "Purch. Inv. Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchaseLine: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineFromPurchCrMemoLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineFromPurchRcptLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromPurchRcptLine: Record "Purch. Rcpt. Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line"; CopyItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineFromReturnShptLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromReturnShipmentLine: Record "Return Shipment Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line"; CopyItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromOldSalesHeader(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; MoveNegLines: Boolean; IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromOldPurchHeader(var ToPurchHeader: Record "Purchase Header"; OldPurchHeader: Record "Purchase Header"; MoveNegLines: Boolean; IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesToPurchDoc(FromSalesHeader: Record "Sales Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesHeaderAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; IncludeHeader: Boolean; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesHeaderArchiveAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeaderArchive: Record "Sales Header Archive"; FromSalesLineArchive: Record "Sales Line Archive"; IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesRetRcptAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromReturnReceiptHeader: Record "Return Receipt Header"; IncludeHeader: Boolean; FromReturnRcptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesCrMemoAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; IncludeHeader: Boolean; FromSalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesInvoiceAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesInvoiceHeader: Record "Sales Invoice Header"; IncludeHeader: Boolean; FromSalesInvLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesShptAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesShipmentHeader: Record "Sales Shipment Header"; IncludeHeader: Boolean; FromSalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnAfterToSalesLineInsert(var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnBeforeToSalesLineInsert(var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive"; RecalculateLines: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnAfterToPurchLineInsert(var ToPurchLine: Record "Purchase Line"; FromPurchLineArchive: Record "Purchase Line Archive"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnBeforeToPurchLineInsert(var ToPurchLine: Record "Purchase Line"; FromPurchLineArchive: Record "Purchase Line Archive"; RecalculateLines: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchDocAssgntToLineOnAfterSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchDocAssgntToLineOnBeforeInsert(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; RecalculateLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesDocAssgntToLineOnAfterSetFilters(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesDocAssgntToLineOnBeforeInsert(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; RecalculateLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesToPurchDocOnAfterSetFilters(var FromSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesToPurchDocOnBeforePurchaseHeaderInsert(var ToPurchaseHeader: Record "Purchase Header"; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchLineOnBeforeCheckVATBusGroup(PurchaseLine: Record "Purchase Line"; var CheckVATBusGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailability(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var HideDialog: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnAfterTransferFields(var FromPurchaseLine: Record "Purchase Line"; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnAfterTransferFields(var FromPurchaseLine: Record "Purchase Line"; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchRcptLinesToDocOnAfterTransferFields(var FromPurchaseLine: Record "Purchase Line"; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchReturnShptLinesToDocOnAfterTransferFields(var FromPurchaseLine: Record "Purchase Line"; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var FromReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnAfterCopyPurchDocLines(FromDocType: Option; FromDocNo: Code[20]; FromPurchaseHeader: Record "Purchase Header"; IncludeHeader: Boolean; var ToPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCopyPurchDocRcptLine(var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCopyPurchDocInvLine(var FromPurchInvHeader: Record "Purch. Inv. Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCopyPurchDocReturnShptLine(var FromReturnShipmentHeader: Record "Return Shipment Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCopyPurchDocCrMemoLine(var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeToPurchHeaderInsert(var ToPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header"; MovNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeUpdatePurchInvoiceDiscountValue(var ToPurchaseHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocUpdateHeaderOnBeforeUpdateVendLedgerEntry(var ToPurchaseHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocWithoutHeader(var ToPurchaseHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20]; FromOccurenceNo: Integer; FromVersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopyLines(FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnAfterCopySalesDocLines(FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; FromSalesHeader: Record "Sales Header"; IncludeHeader: Boolean; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopySalesDocShptLine(var FromSalesShipmentHeader: Record "Sales Shipment Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopySalesDocInvLine(var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopySalesDocCrMemoLine(var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopySalesDocReturnRcptLine(var FromReturnReceiptHeader: Record "Return Receipt Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeToSalesHeaderInsert(var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeTransferPostedShipmentFields(var ToSalesHeader: Record "Sales Header"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnAfterTransferPostedInvoiceFields(var ToSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; OldSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnAfterTransferArchSalesHeaderFields(var ToSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeTransferPostedInvoiceFields(var ToSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeTransferPostedReturnReceiptFields(var ToSalesHeader: Record "Sales Header"; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeUpdateSalesInvoiceDiscountValue(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocInvLineOnAfterSetFilters(var ToSalesHeader: Record "Sales Header"; var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var FromSalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocCrMemoLineOnAfterSetFilters(var ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocShptLineOnAfterSetFilters(var ToSalesHeader: Record "Sales Header"; var FromSalesShipmentHeader: Record "Sales Shipment Header"; var FromSalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocRcptLineOnAfterSetFilters(var ToPurchHeader: Record "Purchase Header"; var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocReturnRcptLineOnAfterSetFilters(var ToSalesHeader: Record "Sales Header"; var FromReturnReceiptHeader: Record "Return Receipt Header"; var FromReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocSalesLineOnAfterSetFilters(FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocPurchLineOnAfterSetFilters(FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var ToPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocPurchLineOnAfterCopyPurchLine(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; IncludeHeader: Boolean; RecalculateLines: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocSalesLineArchiveOnAfterSetFilters(FromSalesHeaderArchive: Record "Sales Header Archive"; var FromSalesLineArchive: Record "Sales Line Archive"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocUpdateHeaderOnBeforeUpdateCustLedgerEntry(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocWithoutHeader(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20]; FromOccurenceNo: Integer; FromVersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLineOnAfterTransferFieldsToSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchRcptLinesToDocOnBeforeCopyPurchLine(ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnBeforeCopyPurchLine(ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnBeforeCopyPurchLine(ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchReturnShptLinesToDocOnBeforeCopyPurchLine(ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnBeforeCopySalesLine(ToSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnBeforeCopySalesLine(ToSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterGetFromSalesInvHeader(var ToSalesHeader: Record "Sales Header"; FromSalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterInsertOldSalesDocNoLine(ToSalesHeader: Record "Sales Header"; var SkipCopyFromDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnBeforeInsertOldSalesDocNoLine(ToSalesHeader: Record "Sales Header"; var SkipCopyFromDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterFromSalesHeaderTransferFields(var FromSalesHeader: Record "Sales Header"; FromSalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesCrMemoLinesToDocOnBeforeCopySalesLine(ToSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLineOnBeforeCheckVATBusGroup(SalesLine: Record "Sales Line"; var CheckVATBusGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLinesToBufferTransferFields(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLineOnAfterSetDimensions(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchLineOnAfterSetDimensions(var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLinesWithNegQtyOnAfterSetFilters(var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdSalesLinesPerILETransferFields(var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnAfterRecalculateSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesLineItemChargeAssignOnAfterValueEntryLoop(FromSalesHeader: Record "Sales Header"; ToSalesLine: Record "Sales Line"; ValueEntry: Record "Value Entry"; var TempToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary; var ToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; var ItemChargeAssgntNextLineNo: Integer; var SumQtyToAssign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchLineItemChargeAssignOnAfterValueEntryLoop(FromPurchHeader: Record "Purchase Header"; ToPurchLine: Record "Purchase Line"; ValueEntry: Record "Value Entry"; var TempToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var ToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssgntNextLineNo: Integer; var SumQtyToAssign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkJobPlanningLineOnAfterJobPlanningLineModify(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdPurchLinesPerILEOnBeforeCheckJobNo(FromPurchLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnAfterFilterEntryType(var FromPurchLineBuf: Record "Purchase Line" temporary; var ItemLedgEntryBuf: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchLineOnBeforeValidateQuantity(var ToPurchLine: Record "Purchase Line"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculatePurchLineOnAfterValidateQuantity(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateSalesLineOnAfterValidateQuantity(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;
}

