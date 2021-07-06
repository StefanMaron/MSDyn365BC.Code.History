report 492 "Copy Purchase Document"
{
    Caption = 'Copy Purchase Document';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentType; FromDocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        ToolTip = 'Specifies the type of document that is processed by the report or batch job.';

                        trigger OnValidate()
                        begin
                            FromDocNo := '';
                            ValidateDocNo;
                        end;
                    }
                    field(DocumentNo; FromDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo;
                        end;
                    }
                    field(DocNoOccurrence; FromDocNoOccurrence)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Doc. No. Occurrence';
                        Editable = false;
                        ToolTip = 'Specifies the number of times the No. value has been used in the number series.';
                    }
                    field(DocVersionNo; FromDocVersionNo)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Version No.';
                        Editable = false;
                        ToolTip = 'Specifies the version of the document to be copied.';
                    }
                    field(BuyfromVendorNo; FromPurchHeader."Buy-from Vendor No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Buy-from Vendor No.';
                        Editable = false;
                        ToolTip = 'Specifies the vendor according to the values in the Document No. and Document Type fields.';
                    }
                    field(BuyfromVendorName; FromPurchHeader."Buy-from Vendor Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Buy-from Vendor Name';
                        Editable = false;
                        ToolTip = 'Specifies the vendor according to the values in the Document No. and Document Type fields.';
                    }
                    field(IncludeHeader_Options; IncludeHeader)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you also want to copy the information from the document header. When you copy quotes, if the posting date field of the new document is empty, the work date is used as the posting date of the new document.';

                        trigger OnValidate()
                        begin
                            ValidateIncludeHeader;
                        end;
                    }
                    field(RecalculateLines; RecalculateLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Recalculate Lines';
                        ToolTip = 'Specifies that lines are recalculate and inserted on the purchase document you are creating. The batch job retains the item numbers and item quantities but recalculates the amounts on the lines based on the vendor information on the new document header. In this way, the batch job accounts for item prices and discounts that are specifically linked to the vendor on the new header.';

                        trigger OnValidate()
                        begin
                            if (FromDocType = FromDocType::"Posted Receipt") or (FromDocType = FromDocType::"Posted Return Shipment") then
                                RecalculateLines := true;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if FromDocNo <> '' then begin
                case FromDocType of
                    FromDocType::Quote:
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::Quote, FromDocNo) then
                            ;
                    FromDocType::"Blanket Order":
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::"Blanket Order", FromDocNo) then
                            ;
                    FromDocType::Order:
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::Order, FromDocNo) then
                            ;
                    FromDocType::Invoice:
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::Invoice, FromDocNo) then
                            ;
                    FromDocType::"Return Order":
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::"Return Order", FromDocNo) then
                            ;
                    FromDocType::"Credit Memo":
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::"Credit Memo", FromDocNo) then
                            ;
                    FromDocType::"Posted Receipt":
                        if FromPurchRcptHeader.Get(FromDocNo) then
                            FromPurchHeader.TransferFields(FromPurchRcptHeader);
                    FromDocType::"Posted Invoice":
                        if FromPurchInvHeader.Get(FromDocNo) then
                            FromPurchHeader.TransferFields(FromPurchInvHeader);
                    FromDocType::"Posted Return Shipment":
                        if FromReturnShptHeader.Get(FromDocNo) then
                            FromPurchHeader.TransferFields(FromReturnShptHeader);
                    FromDocType::"Posted Credit Memo":
                        if FromPurchCrMemoHeader.Get(FromDocNo) then
                            FromPurchHeader.TransferFields(FromPurchCrMemoHeader);
                    FromDocType::"Arch. Order":
                        if FromPurchHeaderArchive.Get(FromPurchHeaderArchive."Document Type"::Order, FromDocNo, FromDocNoOccurrence, FromDocVersionNo) then
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                    FromDocType::"Arch. Quote":
                        if FromPurchHeaderArchive.Get(FromPurchHeaderArchive."Document Type"::Quote, FromDocNo, FromDocNoOccurrence, FromDocVersionNo) then
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                    FromDocType::"Arch. Blanket Order":
                        if FromPurchHeaderArchive.Get(FromPurchHeaderArchive."Document Type"::"Blanket Order", FromDocNo, FromDocNoOccurrence, FromDocVersionNo) then
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                    FromDocType::"Arch. Return Order":
                        if FromPurchHeaderArchive.Get(FromPurchHeaderArchive."Document Type"::"Return Order", FromDocNo, FromDocNoOccurrence, FromDocVersionNo) then
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                end;
                if FromPurchHeader."No." = '' then
                    FromDocNo := '';
            end;
            ValidateDocNo;

            OnAfterOpenPage;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforePreReport();

        PurchSetup.Get();
        CopyDocMgt.SetProperties(
          IncludeHeader, RecalculateLines, false, false, false, PurchSetup."Exact Cost Reversing Mandatory", false);
        CopyDocMgt.SetArchDocVal(FromDocNoOccurrence, FromDocVersionNo);

        OnPreReportOnBeforeCopyPurchaseDoc(CopyDocMgt);

        CopyDocMgt.CopyPurchDoc(FromDocType, FromDocNo, PurchHeader);
    end;

    var
        PurchHeader: Record "Purchase Header";
        FromPurchHeader: Record "Purchase Header";
        FromPurchRcptHeader: Record "Purch. Rcpt. Header";
        FromPurchInvHeader: Record "Purch. Inv. Header";
        FromReturnShptHeader: Record "Return Shipment Header";
        FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        FromPurchHeaderArchive: Record "Purchase Header Archive";
        PurchSetup: Record "Purchases & Payables Setup";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        FromDocType: Enum "Purchase Document Type From";
        FromDocNo: Code[20];
        FromDocNoOccurrence: Integer;
        FromDocVersionNo: Integer;
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        Text000: Label 'The price information may not be reversed correctly, if you copy a %1. If possible, copy a %2 instead or use %3 functionality.';
        Text001: Label 'Undo Receipt';
        Text002: Label 'Undo Return Shipment';
        Text003: Label 'Quote,Blanket Order,Order,Invoice,Return Order,Credit Memo,Posted Receipt,Posted Invoice,Posted Return Shipment,Posted Credit Memo';

    procedure SetPurchHeader(var NewPurchHeader: Record "Purchase Header")
    begin
        NewPurchHeader.TestField("No.");
        PurchHeader := NewPurchHeader;
    end;

    local procedure ValidateDocNo()
    begin
        if FromDocNo = '' then begin
            FromPurchHeader.Init();
            FromDocNoOccurrence := 0;
            FromDocVersionNo := 0;
        end else
            if FromDocNo <> FromPurchHeader."No." then begin
                FromPurchHeader.Init();
                case FromDocType of
                    FromDocType::Quote,
                    FromDocType::"Blanket Order",
                    FromDocType::Order,
                    FromDocType::Invoice,
                    FromDocType::"Return Order",
                    FromDocType::"Credit Memo":
                        FromPurchHeader.Get(CopyDocMgt.GetPurchaseDocumentType(FromDocType), FromDocNo);
                    FromDocType::"Posted Receipt":
                        begin
                            FromPurchRcptHeader.Get(FromDocNo);
                            FromPurchHeader.TransferFields(FromPurchRcptHeader);
                            if PurchHeader."Document Type" in
                               [PurchHeader."Document Type"::"Return Order", PurchHeader."Document Type"::"Credit Memo"]
                            then
                                Message(Text000, SelectStr(1 + FromDocType.AsInteger(), Text003), SelectStr(1 + "Purchase Document Type From"::"Posted Invoice".AsInteger(), Text003), Text001);
                        end;
                    FromDocType::"Posted Invoice":
                        begin
                            FromPurchInvHeader.Get(FromDocNo);
                            FromPurchHeader.TransferFields(FromPurchInvHeader);
                        end;
                    FromDocType::"Posted Return Shipment":
                        begin
                            FromReturnShptHeader.Get(FromDocNo);
                            FromPurchHeader.TransferFields(FromReturnShptHeader);
                            if PurchHeader."Document Type" in
                               [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice]
                            then
                                Message(Text000, SelectStr(1 + FromDocType.AsInteger(), Text003), SelectStr(1 + "Purchase Document Type From"::"Posted Credit Memo".AsInteger(), Text003), Text002);
                        end;
                    FromDocType::"Posted Credit Memo":
                        begin
                            FromPurchCrMemoHeader.Get(FromDocNo);
                            FromPurchHeader.TransferFields(FromPurchCrMemoHeader);
                        end;
                    FromDocType::"Arch. Quote",
                    FromDocType::"Arch. Order",
                    FromDocType::"Arch. Blanket Order",
                    FromDocType::"Arch. Return Order":
                        begin
                            FindFromPurchHeaderArchive();
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                        end;
                end;
            end;
        FromPurchHeader."No." := '';

        IncludeHeader :=
          (FromDocType in [FromDocType::"Posted Invoice", FromDocType::"Posted Credit Memo"]) and
          ((FromDocType = FromDocType::"Posted Credit Memo") <>
           (PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo")) and
          (PurchHeader."Buy-from Vendor No." in [FromPurchHeader."Buy-from Vendor No.", '']);

        OnBeforeValidateIncludeHeader(IncludeHeader, FromDocType.AsInteger(), PurchHeader, FromPurchHeader);
        ValidateIncludeHeader;
    end;

    local procedure FindFromPurchHeaderArchive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindFromPurchHeaderArchive(FromPurchHeaderArchive, FromDocType, FromDocNo, FromDocNoOccurrence, FromDocVersionNo, IsHandled);
        if IsHandled then
            exit;

        if not FromPurchHeaderArchive.Get(
            CopyDocMgt.GetPurchaseDocumentType(FromDocType), FromDocNo, FromDocNoOccurrence, FromDocVersionNo)
        then begin
            FromPurchHeaderArchive.SetRange("No.", FromDocNo);
            if FromPurchHeaderArchive.FindLast then begin
                FromDocNoOccurrence := FromPurchHeaderArchive."Doc. No. Occurrence";
                FromDocVersionNo := FromPurchHeaderArchive."Version No.";
            end;
        end;
    end;

    local procedure LookupDocNo()
    begin
        OnBeforeLookupDocNo(PurchHeader);

        case FromDocType of
            FromDocType::Quote,
            FromDocType::"Blanket Order",
            FromDocType::Order,
            FromDocType::Invoice,
            FromDocType::"Return Order",
            FromDocType::"Credit Memo":
                LookupPurchDoc();
            FromDocType::"Posted Receipt":
                LookupPostedReceipt();
            FromDocType::"Posted Invoice":
                LookupPostedInvoice();
            FromDocType::"Posted Return Shipment":
                LookupPostedReturn();
            FromDocType::"Posted Credit Memo":
                LookupPostedCrMemo();
            FromDocType::"Arch. Quote",
            FromDocType::"Arch. Order",
            FromDocType::"Arch. Blanket Order",
            FromDocType::"Arch. Return Order":
                LookupPurchArchive();
        end;
        ValidateDocNo;
    end;

    local procedure LookupPurchDoc()
    begin
        OnBeforeLookupPurchDoc(FromPurchHeader, PurchHeader);

        FromPurchHeader.FilterGroup := 0;
        FromPurchHeader.SetRange("Document Type", CopyDocMgt.GetPurchaseDocumentType(FromDocType));
        if PurchHeader."Document Type" = CopyDocMgt.GetPurchaseDocumentType(FromDocType) then
            FromPurchHeader.SetFilter("No.", '<>%1', PurchHeader."No.");
        FromPurchHeader.FilterGroup := 2;
        FromPurchHeader."Document Type" := CopyDocMgt.GetPurchaseDocumentType(FromDocType);
        FromPurchHeader."No." := FromDocNo;
        if (FromDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromPurchHeader.SetCurrentKey("Document Type", "Buy-from Vendor No.") then begin
                FromPurchHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromPurchHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromPurchHeader) = ACTION::LookupOK then
            FromDocNo := FromPurchHeader."No.";
    end;

    local procedure LookupPurchArchive()
    begin
        FromPurchHeaderArchive.Reset();
        OnLookupPurchArchiveOnBeforeSetFilters(FromPurchHeaderArchive, PurchHeader);
        FromPurchHeaderArchive.FilterGroup := 0;
        FromPurchHeaderArchive.SetRange("Document Type", CopyDocMgt.GetPurchaseDocumentType(FromDocType));
        FromPurchHeaderArchive.FilterGroup := 2;
        FromPurchHeaderArchive."Document Type" := CopyDocMgt.GetPurchaseDocumentType(FromDocType);
        FromPurchHeaderArchive."No." := FromDocNo;
        FromPurchHeaderArchive."Doc. No. Occurrence" := FromDocNoOccurrence;
        FromPurchHeaderArchive."Version No." := FromDocVersionNo;
        if (FromDocNo = '') and (PurchHeader."Sell-to Customer No." <> '') then
            if FromPurchHeaderArchive.SetCurrentKey("Document Type", "Sell-to Customer No.") then begin
                FromPurchHeaderArchive."Sell-to Customer No." := PurchHeader."Sell-to Customer No.";
                if FromPurchHeaderArchive.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromPurchHeaderArchive) = ACTION::LookupOK then begin
            FromDocNo := FromPurchHeaderArchive."No.";
            FromDocNoOccurrence := FromPurchHeaderArchive."Doc. No. Occurrence";
            FromDocVersionNo := FromPurchHeaderArchive."Version No.";
            RequestOptionsPage.Update(false);
        end;
    end;

    local procedure LookupPostedReceipt()
    begin
        OnBeforeLookupPostedReceipt(FromPurchRcptHeader, PurchHeader);

        FromPurchRcptHeader."No." := FromDocNo;
        if (FromDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromPurchRcptHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                FromPurchRcptHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromPurchRcptHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromPurchRcptHeader) = ACTION::LookupOK then
            FromDocNo := FromPurchRcptHeader."No.";
    end;

    local procedure LookupPostedInvoice()
    begin
        OnBeforeLookupPostedInvoice(FromPurchInvHeader, PurchHeader);

        FromPurchInvHeader."No." := FromDocNo;
        if (FromDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromPurchInvHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                FromPurchInvHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromPurchInvHeader.Find('=><') then;
            end;
        FromPurchInvHeader.FilterGroup(2);
        FromPurchInvHeader.SetRange("Prepayment Invoice", false);
        FromPurchInvHeader.FilterGroup(0);
        if PAGE.RunModal(0, FromPurchInvHeader) = ACTION::LookupOK then
            FromDocNo := FromPurchInvHeader."No.";
    end;

    local procedure LookupPostedCrMemo()
    begin
        OnBeforeLookupPostedCrMemo(FromPurchCrMemoHeader, PurchHeader);

        FromPurchCrMemoHeader."No." := FromDocNo;
        if (FromDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromPurchCrMemoHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                FromPurchCrMemoHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromPurchCrMemoHeader.Find('=><') then;
            end;
        FromPurchCrMemoHeader.FilterGroup(2);
        FromPurchCrMemoHeader.SetRange("Prepayment Credit Memo", false);
        FromPurchCrMemoHeader.FilterGroup(0);
        if PAGE.RunModal(0, FromPurchCrMemoHeader) = ACTION::LookupOK then
            FromDocNo := FromPurchCrMemoHeader."No.";
    end;

    local procedure LookupPostedReturn()
    begin
        OnBeforeLookupPostedReturn(FromReturnShptHeader, PurchHeader);

        FromReturnShptHeader."No." := FromDocNo;
        if (FromDocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromReturnShptHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                FromReturnShptHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromReturnShptHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromReturnShptHeader) = ACTION::LookupOK then
            FromDocNo := FromReturnShptHeader."No.";
    end;

    local procedure ValidateIncludeHeader()
    begin
        RecalculateLines :=
          (FromDocType in [FromDocType::"Posted Receipt", FromDocType::"Posted Return Shipment"]) or not IncludeHeader;
    end;

    procedure SetParameters(NewFromDocType: Enum "Purchase Document Type From"; NewFromDocNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    begin
        FromDocType := NewFromDocType;
        FromDocNo := NewFromDocNo;
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalcLines;
    end;

#if not CLEAN17
    [Obsolete('Replaced by SetParameters().', '17.0')]
    procedure InitializeRequest(NewDocType: Option; NewDocNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    begin
        SetParameters("Purchase Document Type From".FromInteger(NewDocType), NewDocNo, NewIncludeHeader, NewRecalcLines);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFromPurchHeaderArchive(var FromPurchHeaderArchive: Record "Purchase Header Archive"; DocType: Enum "Purchase Document Type From"; DocNo: Code[20]; var DocNoOccurrence: Integer; var DocVersionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocNo(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPurchDoc(var FromPurchaseHeader: Record "Purchase Header"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedReceipt(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedInvoice(var FromPurchInvHeader: Record "Purch. Inv. Header"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedCrMemo(var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedReturn(var FromReturnShptHeader: Record "Return Shipment Header"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIncludeHeader(var DoIncludeHeader: Boolean; DocType: Option; var PurchHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupPurchArchiveOnBeforeSetFilters(var FromPurchHeaderArchive: Record "Purchase Header Archive"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyPurchaseDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt.")
    begin
    end;
}

