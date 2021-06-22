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
                    field(DocumentType; DocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        OptionCaption = 'Quote,Blanket Order,Order,Invoice,Return Order,Credit Memo,Posted Receipt,Posted Invoice,Posted Return Shipment,Posted Credit Memo,Arch. Quote,Arch. Order,Arch. Blanket Order,Arch. Return Order';
                        ToolTip = 'Specifies the type of document that is processed by the report or batch job.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo;
                        end;
                    }
                    field(DocumentNo; DocNo)
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
                    field(DocNoOccurrence; DocNoOccurrence)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Doc. No. Occurrence';
                        Editable = false;
                        ToolTip = 'Specifies the number of times the No. value has been used in the number series.';
                    }
                    field(DocVersionNo; DocVersionNo)
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
                            if (DocType = DocType::"Posted Receipt") or (DocType = DocType::"Posted Return Shipment") then
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
            if DocNo <> '' then begin
                case DocType of
                    DocType::Quote:
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::Quote, DocNo) then
                            ;
                    DocType::"Blanket Order":
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::"Blanket Order", DocNo) then
                            ;
                    DocType::Order:
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::Order, DocNo) then
                            ;
                    DocType::Invoice:
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::Invoice, DocNo) then
                            ;
                    DocType::"Return Order":
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::"Return Order", DocNo) then
                            ;
                    DocType::"Credit Memo":
                        if FromPurchHeader.Get(FromPurchHeader."Document Type"::"Credit Memo", DocNo) then
                            ;
                    DocType::"Posted Receipt":
                        if FromPurchRcptHeader.Get(DocNo) then
                            FromPurchHeader.TransferFields(FromPurchRcptHeader);
                    DocType::"Posted Invoice":
                        if FromPurchInvHeader.Get(DocNo) then
                            FromPurchHeader.TransferFields(FromPurchInvHeader);
                    DocType::"Posted Return Shipment":
                        if FromReturnShptHeader.Get(DocNo) then
                            FromPurchHeader.TransferFields(FromReturnShptHeader);
                    DocType::"Posted Credit Memo":
                        if FromPurchCrMemoHeader.Get(DocNo) then
                            FromPurchHeader.TransferFields(FromPurchCrMemoHeader);
                    DocType::"Arch. Order":
                        if FromPurchHeaderArchive.Get(FromPurchHeaderArchive."Document Type"::Order, DocNo, DocNoOccurrence, DocVersionNo) then
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                    DocType::"Arch. Quote":
                        if FromPurchHeaderArchive.Get(FromPurchHeaderArchive."Document Type"::Quote, DocNo, DocNoOccurrence, DocVersionNo) then
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                    DocType::"Arch. Blanket Order":
                        if FromPurchHeaderArchive.Get(FromPurchHeaderArchive."Document Type"::"Blanket Order", DocNo, DocNoOccurrence, DocVersionNo) then
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                    DocType::"Arch. Return Order":
                        if FromPurchHeaderArchive.Get(FromPurchHeaderArchive."Document Type"::"Return Order", DocNo, DocNoOccurrence, DocVersionNo) then
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                end;
                if FromPurchHeader."No." = '' then
                    DocNo := '';
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
        CopyDocMgt.SetArchDocVal(DocNoOccurrence, DocVersionNo);

        OnPreReportOnBeforeCopyPurchaseDoc(CopyDocMgt);

        CopyDocMgt.CopyPurchDoc(DocType, DocNo, PurchHeader);
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
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo","Arch. Quote","Arch. Order","Arch. Blanket Order","Arch. Return Order";
        DocNo: Code[20];
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        Text000: Label 'The price information may not be reversed correctly, if you copy a %1. If possible, copy a %2 instead or use %3 functionality.';
        Text001: Label 'Undo Receipt';
        Text002: Label 'Undo Return Shipment';
        Text003: Label 'Quote,Blanket Order,Order,Invoice,Return Order,Credit Memo,Posted Receipt,Posted Invoice,Posted Return Shipment,Posted Credit Memo';
        DocNoOccurrence: Integer;
        DocVersionNo: Integer;

    procedure SetPurchHeader(var NewPurchHeader: Record "Purchase Header")
    begin
        NewPurchHeader.TestField("No.");
        PurchHeader := NewPurchHeader;
    end;

    local procedure ValidateDocNo()
    var
        DocType2: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
    begin
        if DocNo = '' then begin
            FromPurchHeader.Init();
            DocNoOccurrence := 0;
            DocVersionNo := 0;
        end else
            if DocNo <> FromPurchHeader."No." then begin
                FromPurchHeader.Init();
                case DocType of
                    DocType::Quote,
                  DocType::"Blanket Order",
                  DocType::Order,
                  DocType::Invoice,
                  DocType::"Return Order",
                  DocType::"Credit Memo":
                        FromPurchHeader.Get(CopyDocMgt.PurchHeaderDocType(DocType), DocNo);
                    DocType::"Posted Receipt":
                        begin
                            FromPurchRcptHeader.Get(DocNo);
                            FromPurchHeader.TransferFields(FromPurchRcptHeader);
                            if PurchHeader."Document Type" in
                               [PurchHeader."Document Type"::"Return Order", PurchHeader."Document Type"::"Credit Memo"]
                            then begin
                                DocType2 := DocType2::"Posted Invoice";
                                Message(Text000, SelectStr(1 + DocType, Text003), SelectStr(1 + DocType2, Text003), Text001);
                            end;
                        end;
                    DocType::"Posted Invoice":
                        begin
                            FromPurchInvHeader.Get(DocNo);
                            FromPurchHeader.TransferFields(FromPurchInvHeader);
                        end;
                    DocType::"Posted Return Shipment":
                        begin
                            FromReturnShptHeader.Get(DocNo);
                            FromPurchHeader.TransferFields(FromReturnShptHeader);
                            if PurchHeader."Document Type" in
                               [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice]
                            then begin
                                DocType2 := DocType2::"Posted Credit Memo";
                                Message(Text000, SelectStr(1 + DocType, Text003), SelectStr(1 + DocType2, Text003), Text002);
                            end;
                        end;
                    DocType::"Posted Credit Memo":
                        begin
                            FromPurchCrMemoHeader.Get(DocNo);
                            FromPurchHeader.TransferFields(FromPurchCrMemoHeader);
                        end;
                    DocType::"Arch. Quote",
                    DocType::"Arch. Order",
                    DocType::"Arch. Blanket Order",
                    DocType::"Arch. Return Order":
                        begin
                            if not FromPurchHeaderArchive.Get(
                                 CopyDocMgt.ArchPurchHeaderDocType(DocType), DocNo, DocNoOccurrence, DocVersionNo)
                            then begin
                                FromPurchHeaderArchive.SetRange("No.", DocNo);
                                if FromPurchHeaderArchive.FindLast then begin
                                    DocNoOccurrence := FromPurchHeaderArchive."Doc. No. Occurrence";
                                    DocVersionNo := FromPurchHeaderArchive."Version No.";
                                end;
                            end;
                            FromPurchHeader.TransferFields(FromPurchHeaderArchive);
                        end;
                end;
            end;
        FromPurchHeader."No." := '';

        IncludeHeader :=
          (DocType in [DocType::"Posted Invoice", DocType::"Posted Credit Memo"]) and
          ((DocType = DocType::"Posted Credit Memo") <>
           (PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo")) and
          (PurchHeader."Buy-from Vendor No." in [FromPurchHeader."Buy-from Vendor No.", '']);

        OnBeforeValidateIncludeHeader(IncludeHeader, DocType);
        ValidateIncludeHeader;
    end;

    local procedure LookupDocNo()
    begin
        OnBeforeLookupDocNo(PurchHeader);

        case DocType of
            DocType::Quote,
          DocType::"Blanket Order",
          DocType::Order,
          DocType::Invoice,
          DocType::"Return Order",
          DocType::"Credit Memo":
                LookupPurchDoc;
            DocType::"Posted Receipt":
                LookupPostedReceipt;
            DocType::"Posted Invoice":
                LookupPostedInvoice;
            DocType::"Posted Return Shipment":
                LookupPostedReturn;
            DocType::"Posted Credit Memo":
                LookupPostedCrMemo;
            DocType::"Arch. Quote",
          DocType::"Arch. Order",
          DocType::"Arch. Blanket Order",
          DocType::"Arch. Return Order":
                LookupPurchArchive;
        end;
        ValidateDocNo;
    end;

    local procedure LookupPurchDoc()
    begin
        OnBeforeLookupPurchDoc(FromPurchHeader, PurchHeader);

        FromPurchHeader.FilterGroup := 0;
        FromPurchHeader.SetRange("Document Type", CopyDocMgt.PurchHeaderDocType(DocType));
        if PurchHeader."Document Type" = CopyDocMgt.PurchHeaderDocType(DocType) then
            FromPurchHeader.SetFilter("No.", '<>%1', PurchHeader."No.");
        FromPurchHeader.FilterGroup := 2;
        FromPurchHeader."Document Type" := CopyDocMgt.PurchHeaderDocType(DocType);
        FromPurchHeader."No." := DocNo;
        if (DocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromPurchHeader.SetCurrentKey("Document Type", "Buy-from Vendor No.") then begin
                FromPurchHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromPurchHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromPurchHeader) = ACTION::LookupOK then
            DocNo := FromPurchHeader."No.";
    end;

    local procedure LookupPurchArchive()
    begin
        FromPurchHeaderArchive.Reset();
        FromPurchHeaderArchive.FilterGroup := 0;
        FromPurchHeaderArchive.SetRange("Document Type", CopyDocMgt.ArchPurchHeaderDocType(DocType));
        FromPurchHeaderArchive.FilterGroup := 2;
        FromPurchHeaderArchive."Document Type" := CopyDocMgt.ArchPurchHeaderDocType(DocType);
        FromPurchHeaderArchive."No." := DocNo;
        FromPurchHeaderArchive."Doc. No. Occurrence" := DocNoOccurrence;
        FromPurchHeaderArchive."Version No." := DocVersionNo;
        if (DocNo = '') and (PurchHeader."Sell-to Customer No." <> '') then
            if FromPurchHeaderArchive.SetCurrentKey("Document Type", "Sell-to Customer No.") then begin
                FromPurchHeaderArchive."Sell-to Customer No." := PurchHeader."Sell-to Customer No.";
                if FromPurchHeaderArchive.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromPurchHeaderArchive) = ACTION::LookupOK then begin
            DocNo := FromPurchHeaderArchive."No.";
            DocNoOccurrence := FromPurchHeaderArchive."Doc. No. Occurrence";
            DocVersionNo := FromPurchHeaderArchive."Version No.";
            RequestOptionsPage.Update(false);
        end;
    end;

    local procedure LookupPostedReceipt()
    begin
        OnBeforeLookupPostedReceipt(FromPurchRcptHeader, PurchHeader);

        FromPurchRcptHeader."No." := DocNo;
        if (DocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromPurchRcptHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                FromPurchRcptHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromPurchRcptHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromPurchRcptHeader) = ACTION::LookupOK then
            DocNo := FromPurchRcptHeader."No.";
    end;

    local procedure LookupPostedInvoice()
    begin
        OnBeforeLookupPostedInvoice(FromPurchInvHeader, PurchHeader);

        FromPurchInvHeader."No." := DocNo;
        if (DocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromPurchInvHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                FromPurchInvHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromPurchInvHeader.Find('=><') then;
            end;
        FromPurchInvHeader.FilterGroup(2);
        FromPurchInvHeader.SetRange("Prepayment Invoice", false);
        FromPurchInvHeader.FilterGroup(0);
        if PAGE.RunModal(0, FromPurchInvHeader) = ACTION::LookupOK then
            DocNo := FromPurchInvHeader."No.";
    end;

    local procedure LookupPostedCrMemo()
    begin
        OnBeforeLookupPostedCrMemo(FromPurchCrMemoHeader, PurchHeader);

        FromPurchCrMemoHeader."No." := DocNo;
        if (DocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromPurchCrMemoHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                FromPurchCrMemoHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromPurchCrMemoHeader.Find('=><') then;
            end;
        FromPurchCrMemoHeader.FilterGroup(2);
        FromPurchCrMemoHeader.SetRange("Prepayment Credit Memo", false);
        FromPurchCrMemoHeader.FilterGroup(0);
        if PAGE.RunModal(0, FromPurchCrMemoHeader) = ACTION::LookupOK then
            DocNo := FromPurchCrMemoHeader."No.";
    end;

    local procedure LookupPostedReturn()
    begin
        FromReturnShptHeader."No." := DocNo;
        if (DocNo = '') and (PurchHeader."Buy-from Vendor No." <> '') then
            if FromReturnShptHeader.SetCurrentKey("Buy-from Vendor No.") then begin
                FromReturnShptHeader."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if FromReturnShptHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromReturnShptHeader) = ACTION::LookupOK then
            DocNo := FromReturnShptHeader."No.";
    end;

    local procedure ValidateIncludeHeader()
    begin
        RecalculateLines :=
          (DocType in [DocType::"Posted Receipt", DocType::"Posted Return Shipment"]) or not IncludeHeader;
    end;

    procedure InitializeRequest(NewDocType: Option; NewDocNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    begin
        DocType := NewDocType;
        DocNo := NewDocNo;
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalcLines;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage()
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
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIncludeHeader(var DoIncludeHeader: Boolean; DocType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyPurchaseDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt.")
    begin
    end;
}

