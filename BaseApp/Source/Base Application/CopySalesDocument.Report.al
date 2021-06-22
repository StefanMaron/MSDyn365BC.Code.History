report 292 "Copy Sales Document"
{
    Caption = 'Copy Sales Document';
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
                        ApplicationArea = Suite;
                        Caption = 'Document Type';
                        OptionCaption = 'Quote,Blanket Order,Order,Invoice,Return Order,Credit Memo,Posted Shipment,Posted Invoice,Posted Return Receipt,Posted Credit Memo,Arch. Quote,Arch. Order,Arch. Blanket Order,Arch. Return Order';
                        ToolTip = 'Specifies the type of document that is processed by the report or batch job.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo;
                        end;
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document No.';
                        ShowMandatory = true;
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
                        ApplicationArea = Suite;
                        BlankZero = true;
                        Caption = 'Doc. No. Occurrence';
                        Editable = false;
                        ToolTip = 'Specifies the number of times the No. value has been used in the number series.';
                    }
                    field(DocVersionNo; DocVersionNo)
                    {
                        ApplicationArea = Suite;
                        BlankZero = true;
                        Caption = 'Version No.';
                        Editable = false;
                        ToolTip = 'Specifies the version of the document to be copied.';
                    }
                    field(SellToCustNo; FromSalesHeader."Sell-to Customer No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sell-to Customer No.';
                        Editable = false;
                        ToolTip = 'Specifies the sell-to customer number that will appear on the new sales document.';
                    }
                    field(SellToCustName; FromSalesHeader."Sell-to Customer Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sell-to Customer Name';
                        Editable = false;
                        ToolTip = 'Specifies the sell-to customer name that will appear on the new sales document.';
                    }
                    field(IncludeHeader_Options; IncludeHeader)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you also want to copy the information from the document header. When you copy quotes, if the posting date field of the new document is empty, the work date is used as the posting date of the new document.';

                        trigger OnValidate()
                        begin
                            ValidateIncludeHeader;
                        end;
                    }
                    field(RecalculateLines; RecalculateLines)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Recalculate Lines';
                        ToolTip = 'Specifies that lines are recalculate and inserted on the sales document you are creating. The batch job retains the item numbers and item quantities but recalculates the amounts on the lines based on the customer information on the new document header. In this way, the batch job accounts for item prices and discounts that are specifically linked to the customer on the new header.';

                        trigger OnValidate()
                        begin
                            if (DocType = DocType::"Posted Shipment") or (DocType = DocType::"Posted Return Receipt") then
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
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::Quote, DocNo) then
                            ;
                    DocType::"Blanket Order":
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::"Blanket Order", DocNo) then
                            ;
                    DocType::Order:
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::Order, DocNo) then
                            ;
                    DocType::Invoice:
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::Invoice, DocNo) then
                            ;
                    DocType::"Return Order":
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::"Return Order", DocNo) then
                            ;
                    DocType::"Credit Memo":
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::"Credit Memo", DocNo) then
                            ;
                    DocType::"Posted Shipment":
                        if FromSalesShptHeader.Get(DocNo) then
                            FromSalesHeader.TransferFields(FromSalesShptHeader);
                    DocType::"Posted Invoice":
                        if FromSalesInvHeader.Get(DocNo) then
                            FromSalesHeader.TransferFields(FromSalesInvHeader);
                    DocType::"Posted Return Receipt":
                        if FromReturnRcptHeader.Get(DocNo) then
                            FromSalesHeader.TransferFields(FromReturnRcptHeader);
                    DocType::"Posted Credit Memo":
                        if FromSalesCrMemoHeader.Get(DocNo) then
                            FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                    DocType::"Arch. Order":
                        if FromSalesHeaderArchive.Get(FromSalesHeaderArchive."Document Type"::Order, DocNo, DocNoOccurrence, DocVersionNo) then
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                    DocType::"Arch. Quote":
                        if FromSalesHeaderArchive.Get(FromSalesHeaderArchive."Document Type"::Quote, DocNo, DocNoOccurrence, DocVersionNo) then
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                    DocType::"Arch. Blanket Order":
                        if FromSalesHeaderArchive.Get(FromSalesHeaderArchive."Document Type"::"Blanket Order", DocNo, DocNoOccurrence, DocVersionNo) then
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                    DocType::"Arch. Return Order":
                        if FromSalesHeaderArchive.Get(FromSalesHeaderArchive."Document Type"::"Return Order", DocNo, DocNoOccurrence, DocVersionNo) then
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                end;
                if FromSalesHeader."No." = '' then
                    DocNo := '';
            end;
            ValidateDocNo;

            OnAfterOpenPage;
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = ACTION::OK then
                if DocNo = '' then
                    Error(DocNoNotSerErr)
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforePreReport();

        SalesSetup.Get();
        CopyDocMgt.SetProperties(
          IncludeHeader, RecalculateLines, false, false, false, SalesSetup."Exact Cost Reversing Mandatory", false);
        CopyDocMgt.SetArchDocVal(DocNoOccurrence, DocVersionNo);

        OnPreReportOnBeforeCopySalesDoc(CopyDocMgt);

        CopyDocMgt.CopySalesDoc(DocType, DocNo, SalesHeader);
    end;

    var
        SalesHeader: Record "Sales Header";
        FromSalesHeader: Record "Sales Header";
        FromSalesShptHeader: Record "Sales Shipment Header";
        FromSalesInvHeader: Record "Sales Invoice Header";
        FromReturnRcptHeader: Record "Return Receipt Header";
        FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FromSalesHeaderArchive: Record "Sales Header Archive";
        SalesSetup: Record "Sales & Receivables Setup";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo","Arch. Quote","Arch. Order","Arch. Blanket Order","Arch. Return Order";
        DocNo: Code[20];
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        Text000: Label 'The price information may not be reversed correctly, if you copy a %1. If possible copy a %2 instead or use %3 functionality.';
        Text001: Label 'Undo Shipment';
        Text002: Label 'Undo Return Receipt';
        Text003: Label 'Quote,Blanket Order,Order,Invoice,Return Order,Credit Memo,Posted Shipment,Posted Invoice,Posted Return Receipt,Posted Credit Memo';
        DocNoOccurrence: Integer;
        DocVersionNo: Integer;
        DocNoNotSerErr: Label 'Select a document number to continue, or choose Cancel to close the page.';

    procedure SetSalesHeader(var NewSalesHeader: Record "Sales Header")
    begin
        NewSalesHeader.TestField("No.");
        SalesHeader := NewSalesHeader;
    end;

    local procedure ValidateDocNo()
    var
        DocType2: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
    begin
        if DocNo = '' then begin
            FromSalesHeader.Init();
            DocNoOccurrence := 0;
            DocVersionNo := 0;
        end else
            if FromSalesHeader."No." = '' then begin
                FromSalesHeader.Init();
                case DocType of
                    DocType::Quote,
                  DocType::"Blanket Order",
                  DocType::Order,
                  DocType::Invoice,
                  DocType::"Return Order",
                  DocType::"Credit Memo":
                        FromSalesHeader.Get(CopyDocMgt.SalesHeaderDocType(DocType), DocNo);
                    DocType::"Posted Shipment":
                        begin
                            FromSalesShptHeader.Get(DocNo);
                            FromSalesHeader.TransferFields(FromSalesShptHeader);
                            if SalesHeader."Document Type" in
                               [SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"]
                            then begin
                                DocType2 := DocType2::"Posted Invoice";
                                Message(Text000, SelectStr(1 + DocType, Text003), SelectStr(1 + DocType2, Text003), Text001);
                            end;
                        end;
                    DocType::"Posted Invoice":
                        begin
                            FromSalesInvHeader.Get(DocNo);
                            FromSalesHeader.TransferFields(FromSalesInvHeader);
                        end;
                    DocType::"Posted Return Receipt":
                        begin
                            FromReturnRcptHeader.Get(DocNo);
                            FromSalesHeader.TransferFields(FromReturnRcptHeader);
                            if SalesHeader."Document Type" in
                               [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]
                            then begin
                                DocType2 := DocType2::"Posted Credit Memo";
                                Message(Text000, SelectStr(1 + DocType, Text003), SelectStr(1 + DocType2, Text003), Text002);
                            end;
                        end;
                    DocType::"Posted Credit Memo":
                        begin
                            FromSalesCrMemoHeader.Get(DocNo);
                            FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                        end;
                    DocType::"Arch. Quote",
                    DocType::"Arch. Order",
                    DocType::"Arch. Blanket Order",
                    DocType::"Arch. Return Order":
                        begin
                            if not FromSalesHeaderArchive.Get(
                                 CopyDocMgt.ArchSalesHeaderDocType(DocType), DocNo, DocNoOccurrence, DocVersionNo)
                            then begin
                                FromSalesHeaderArchive.SetRange("No.", DocNo);
                                if FromSalesHeaderArchive.FindLast then begin
                                    DocNoOccurrence := FromSalesHeaderArchive."Doc. No. Occurrence";
                                    DocVersionNo := FromSalesHeaderArchive."Version No.";
                                end;
                            end;
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                        end;
                end;
            end;
        FromSalesHeader."No." := '';

        IncludeHeader :=
          (DocType in [DocType::"Posted Invoice", DocType::"Posted Credit Memo"]) and
          ((DocType = DocType::"Posted Credit Memo") <>
           (SalesHeader."Document Type" in
            [SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"])) and
          (SalesHeader."Bill-to Customer No." in [FromSalesHeader."Bill-to Customer No.", '']);

        OnBeforeValidateIncludeHeader(IncludeHeader);
        ValidateIncludeHeader;
        OnAfterValidateIncludeHeader(IncludeHeader, RecalculateLines);
    end;

    local procedure LookupDocNo()
    begin
        OnBeforeLookupDocNo(SalesHeader);

        case DocType of
            DocType::Quote,
            DocType::"Blanket Order",
            DocType::Order,
            DocType::Invoice,
            DocType::"Return Order",
            DocType::"Credit Memo":
                LookupSalesDoc;
            DocType::"Posted Shipment":
                LookupPostedShipment;
            DocType::"Posted Invoice":
                LookupPostedInvoice;
            DocType::"Posted Return Receipt":
                LookupPostedReturn;
            DocType::"Posted Credit Memo":
                LookupPostedCrMemo;
            DocType::"Arch. Quote",
            DocType::"Arch. Order",
            DocType::"Arch. Blanket Order",
            DocType::"Arch. Return Order":
                LookupSalesArchive;
        end;
        ValidateDocNo;
    end;

    local procedure LookupSalesDoc()
    begin
        OnBeforeLookupSalesDoc(FromSalesHeader, SalesHeader);

        FromSalesHeader.FilterGroup := 0;
        FromSalesHeader.SetRange("Document Type", CopyDocMgt.SalesHeaderDocType(DocType));
        if SalesHeader."Document Type" = CopyDocMgt.SalesHeaderDocType(DocType) then
            FromSalesHeader.SetFilter("No.", '<>%1', SalesHeader."No.");
        FromSalesHeader.FilterGroup := 2;
        FromSalesHeader."Document Type" := CopyDocMgt.SalesHeaderDocType(DocType);
        FromSalesHeader."No." := DocNo;
        if (DocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesHeader.SetCurrentKey("Document Type", "Sell-to Customer No.") then begin
                FromSalesHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromSalesHeader) = ACTION::LookupOK then
            DocNo := FromSalesHeader."No.";
    end;

    local procedure LookupSalesArchive()
    begin
        FromSalesHeaderArchive.Reset();
        FromSalesHeaderArchive.FilterGroup := 0;
        FromSalesHeaderArchive.SetRange("Document Type", CopyDocMgt.ArchSalesHeaderDocType(DocType));
        FromSalesHeaderArchive.FilterGroup := 2;
        FromSalesHeaderArchive."Document Type" := CopyDocMgt.ArchSalesHeaderDocType(DocType);
        FromSalesHeaderArchive."No." := DocNo;
        FromSalesHeaderArchive."Doc. No. Occurrence" := DocNoOccurrence;
        FromSalesHeaderArchive."Version No." := DocVersionNo;
        if (DocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesHeaderArchive.SetCurrentKey("Document Type", "Sell-to Customer No.") then begin
                FromSalesHeaderArchive."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesHeaderArchive.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromSalesHeaderArchive) = ACTION::LookupOK then begin
            DocNo := FromSalesHeaderArchive."No.";
            DocNoOccurrence := FromSalesHeaderArchive."Doc. No. Occurrence";
            DocVersionNo := FromSalesHeaderArchive."Version No.";
            RequestOptionsPage.Update(false);
        end;
    end;

    local procedure LookupPostedShipment()
    begin
        OnBeforeLookupPostedShipment(FromSalesShptHeader, SalesHeader);

        FromSalesShptHeader."No." := DocNo;
        if (DocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesShptHeader.SetCurrentKey("Sell-to Customer No.") then begin
                FromSalesShptHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesShptHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromSalesShptHeader) = ACTION::LookupOK then
            DocNo := FromSalesShptHeader."No.";
    end;

    local procedure LookupPostedInvoice()
    begin
        OnBeforeLookupPostedInvoice(FromSalesInvHeader, SalesHeader);

        FromSalesInvHeader."No." := DocNo;
        if (DocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesInvHeader.SetCurrentKey("Sell-to Customer No.") then begin
                FromSalesInvHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesInvHeader.Find('=><') then;
            end;
        FromSalesInvHeader.FilterGroup(2);
        FromSalesInvHeader.SetRange("Prepayment Invoice", false);
        FromSalesInvHeader.FilterGroup(0);
        if PAGE.RunModal(0, FromSalesInvHeader) = ACTION::LookupOK then
            DocNo := FromSalesInvHeader."No.";
    end;

    local procedure LookupPostedCrMemo()
    begin
        OnBeforeLookupPostedCrMemo(FromSalesCrMemoHeader, SalesHeader);

        FromSalesCrMemoHeader."No." := DocNo;
        if (DocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesCrMemoHeader.SetCurrentKey("Sell-to Customer No.") then begin
                FromSalesCrMemoHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesCrMemoHeader.Find('=><') then;
            end;
        FromSalesCrMemoHeader.FilterGroup(2);
        FromSalesCrMemoHeader.SetRange("Prepayment Credit Memo", false);
        FromSalesCrMemoHeader.FilterGroup(0);
        if PAGE.RunModal(0, FromSalesCrMemoHeader) = ACTION::LookupOK then
            DocNo := FromSalesCrMemoHeader."No.";
    end;

    local procedure LookupPostedReturn()
    begin
        OnBeforeLookupPostedReturn(FromReturnRcptHeader, SalesHeader);

        FromReturnRcptHeader."No." := DocNo;
        if (DocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromReturnRcptHeader.SetCurrentKey("Sell-to Customer No.") then begin
                FromReturnRcptHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromReturnRcptHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromReturnRcptHeader) = ACTION::LookupOK then
            DocNo := FromReturnRcptHeader."No.";
    end;

    local procedure ValidateIncludeHeader()
    begin
        RecalculateLines :=
          (DocType in [DocType::"Posted Shipment", DocType::"Posted Return Receipt"]) or not IncludeHeader;
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
    local procedure OnAfterValidateIncludeHeader(var IncludeHeader: Boolean; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocNo(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSalesDoc(var FromSalesHeader: Record "Sales Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedCrMemo(var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedInvoice(var FromSalesInvHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedShipment(var FromSalesShptHeader: Record "Sales Shipment Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedReturn(var FromReturnRcptHeader: Record "Return Receipt Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIncludeHeader(var DoIncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopySalesDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt.")
    begin
    end;
}

