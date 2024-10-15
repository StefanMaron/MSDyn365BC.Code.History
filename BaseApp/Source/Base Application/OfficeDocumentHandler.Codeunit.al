codeunit 1637 "Office Document Handler"
{
    TableNo = "Office Add-in Context";

    trigger OnRun()
    begin
        RedirectToDocument(Rec);
    end;

    var
        DocDoesNotExistMsg: Label 'Cannot find a document with the number %1.', Comment = '%1=The document number the hyperlink is attempting to open.';
        SuggestedItemsDisabledTxt: Label 'The suggested line items page has been disabled by the user.', Locked = true;

    procedure RedirectToDocument(TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        TempOfficeDocumentSelection: Record "Office Document Selection" temporary;
        DocNos: DotNet String;
        Separator: DotNet String;
        DocNo: Code[20];
    begin
        Separator := '|';
        DocNos := TempOfficeAddinContext."Regular Expression Match";
        foreach DocNo in DocNos.Split(Separator.ToCharArray) do begin
            TempOfficeAddinContext."Regular Expression Match" := DocNo;
            CollectDocumentMatches(TempOfficeDocumentSelection, DocNo, TempOfficeAddinContext);
        end;

        case TempOfficeDocumentSelection.Count of
            0:
                begin
                    TempOfficeAddinContext."Document No." := DocNo;
                    PAGE.Run(PAGE::"Office Doc Selection Dlg");
                end;
            1:
                OpenIndividualDocument(TempOfficeAddinContext, TempOfficeDocumentSelection);
            else // More than one document match, must have user pick
                PAGE.Run(PAGE::"Office Document Selection", TempOfficeDocumentSelection);
        end;
    end;

    procedure ShowDocumentSelection(DocSeries: Integer; DocType: Integer)
    var
        TempOfficeDocumentSelection: Record "Office Document Selection" temporary;
    begin
        with TempOfficeDocumentSelection do
            case DocSeries of
                Series::Sales:
                    GetSalesDocuments(TempOfficeDocumentSelection, DocSeries, DocType);
                Series::Purchase:
                    GetPurchaseDocuments(TempOfficeDocumentSelection, DocSeries, DocType);
            end;
        PAGE.Run(PAGE::"Office Document Selection", TempOfficeDocumentSelection);
    end;

    procedure HandleSalesCommand(Customer: Record Customer; TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeMgt: Codeunit "Office Management";
        OutlookCommand: DotNet OutlookCommand;
    begin
        case TempOfficeAddinContext.Command of
            OutlookCommand.NewSalesCreditMemo:
                Customer.CreateAndShowNewCreditMemo;
            OutlookCommand.NewSalesInvoice:
                if not OfficeMgt.CheckForExistingInvoice(Customer."No.") then
                    Customer.CreateAndShowNewInvoice;
            OutlookCommand.NewSalesQuote:
                Customer.CreateAndShowNewQuote;
            OutlookCommand.NewSalesOrder:
                Customer.CreateAndShowNewOrder;
        end;
    end;

    procedure HandlePurchaseCommand(Vendor: Record Vendor; TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OutlookCommand: DotNet OutlookCommand;
    begin
        case TempOfficeAddinContext.Command of
            OutlookCommand.NewPurchaseCreditMemo:
                Vendor.CreateAndShowNewCreditMemo;
            OutlookCommand.NewPurchaseInvoice:
                Vendor.CreateAndShowNewInvoice;
            OutlookCommand.NewPurchaseOrder:
                Vendor.CreateAndShowNewPurchaseOrder;
        end;
    end;

    procedure OpenIndividualDocument(TempOfficeAddinContext: Record "Office Add-in Context" temporary; TempOfficeDocumentSelection: Record "Office Document Selection" temporary)
    begin
        case TempOfficeDocumentSelection.Series of
            TempOfficeDocumentSelection.Series::Sales:
                OpenIndividualSalesDocument(TempOfficeAddinContext, TempOfficeDocumentSelection);
            TempOfficeDocumentSelection.Series::Purchase:
                OpenIndividualPurchaseDocument(TempOfficeAddinContext, TempOfficeDocumentSelection);
        end;
    end;

    local procedure CollectDocumentMatches(var TempOfficeDocumentSelection: Record "Office Document Selection" temporary; var DocNo: Code[20]; TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        DocNos: DotNet String;
        Separator: DotNet String;
    begin
        // We'll either have a document number already, or we'll need to process the RegularExpressionMatch
        // to derive the document number.
        if (TempOfficeAddinContext."Document No." = '') and (TempOfficeAddinContext."Regular Expression Match" <> '') then begin
            // Try to set DocNo by checking Expression for Window Title Key Words
            if not ExpressionContainsSeriesTitle(TempOfficeAddinContext."Regular Expression Match", DocNo, TempOfficeDocumentSelection) then
                // Last attempt, look for key English terms:  Quote, Order, Invoice, and Credit Memo
                ExpressionContainsKeyWords(TempOfficeAddinContext."Regular Expression Match", DocNo, TempOfficeDocumentSelection)
        end else
            if TempOfficeAddinContext."Document No." <> '' then begin
                DocNos := TempOfficeAddinContext."Document No.";
                Separator := '|';
                foreach DocNo in DocNos.Split(Separator.ToCharArray) do
                    with TempOfficeDocumentSelection do begin
                        SetSalesDocumentMatchRecord(DocNo, "Document Type"::Order, TempOfficeDocumentSelection);
                        SetSalesDocumentMatchRecord(DocNo, "Document Type"::Quote, TempOfficeDocumentSelection);
                        SetSalesDocumentMatchRecord(DocNo, "Document Type"::Invoice, TempOfficeDocumentSelection);
                        SetSalesDocumentMatchRecord(DocNo, "Document Type"::"Credit Memo", TempOfficeDocumentSelection);

                        SetPurchDocumentMatchRecord(DocNo, "Document Type"::Invoice, TempOfficeDocumentSelection);
                        SetPurchDocumentMatchRecord(DocNo, "Document Type"::"Credit Memo", TempOfficeDocumentSelection);
                        SetPurchDocumentMatchRecord(DocNo, "Document Type"::Order, TempOfficeDocumentSelection);
                    end;
            end;
    end;

    local procedure CreateDocumentMatchRecord(var TempOfficeDocumentSelection: Record "Office Document Selection" temporary; Series: Option; DocType: Option; DocNo: Code[20]; Posted: Boolean; DocDate: Date)
    begin
        TempOfficeDocumentSelection.Init;
        TempOfficeDocumentSelection.Validate("Document No.", DocNo);
        TempOfficeDocumentSelection.Validate("Document Date", DocDate);
        TempOfficeDocumentSelection.Validate("Document Type", DocType);
        TempOfficeDocumentSelection.Validate(Series, Series);
        TempOfficeDocumentSelection.Validate(Posted, Posted);
        if not TempOfficeDocumentSelection.Insert then;
    end;

    local procedure DocumentDoesNotExist(DocumentNo: Text[250])
    begin
        Message(DocDoesNotExistMsg, DocumentNo);
    end;

    local procedure ExpressionContainsKeyWords(Expression: Text[250]; var DocNo: Code[20]; var TempOfficeDocumentSelection: Record "Office Document Selection" temporary): Boolean
    var
        DummySalesHeader: Record "Sales Header";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
    begin
        with DummySalesHeader do
            case true of
                GetDocumentNumber(Expression, Format("Document Type"::Quote), DocNo):
                    SetSalesDocumentMatchRecord(DocNo, "Document Type"::Quote, TempOfficeDocumentSelection);
                GetDocumentNumber(Expression, Format("Document Type"::Order), DocNo):
                    begin
                        SetSalesDocumentMatchRecord(DocNo, "Document Type"::Order, TempOfficeDocumentSelection);
                        SetPurchDocumentMatchRecord(DocNo, "Document Type"::Order, TempOfficeDocumentSelection);
                    end;
                GetDocumentNumber(Expression, Format("Document Type"::Invoice), DocNo):
                    begin
                        SetSalesDocumentMatchRecord(DocNo, "Document Type"::Invoice, TempOfficeDocumentSelection);
                        SetPurchDocumentMatchRecord(DocNo, "Document Type"::Invoice, TempOfficeDocumentSelection);
                    end;
                GetDocumentNumber(Expression, Format("Document Type"::"Credit Memo"), DocNo):
                    begin
                        SetSalesDocumentMatchRecord(DocNo, "Document Type"::"Credit Memo", TempOfficeDocumentSelection);
                        SetPurchDocumentMatchRecord(DocNo, "Document Type"::"Credit Memo", TempOfficeDocumentSelection);
                    end;
                GetDocumentNumber(Expression, HyperlinkManifest.GetAcronymForPurchaseOrder, DocNo):
                    SetPurchDocumentMatchRecord(DocNo, TempOfficeDocumentSelection."Document Type"::Order, TempOfficeDocumentSelection);
                else
                    exit(false);
            end;
        exit(true);
    end;

    local procedure ExpressionContainsSeriesTitle(Expression: Text[250]; var DocNo: Code[20]; var TempOfficeDocumentSelection: Record "Office Document Selection" temporary): Boolean
    var
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
    begin
        with HyperlinkManifest do
            case true of
                GetDocumentNumber(Expression, GetNameForPurchaseCrMemo, DocNo):
                    SetPurchDocumentMatchRecord(DocNo, TempOfficeDocumentSelection."Document Type"::"Credit Memo", TempOfficeDocumentSelection);
                GetDocumentNumber(Expression, GetNameForPurchaseInvoice, DocNo):
                    SetPurchDocumentMatchRecord(DocNo, TempOfficeDocumentSelection."Document Type"::Invoice, TempOfficeDocumentSelection);
                GetDocumentNumber(Expression, GetNameForPurchaseOrder, DocNo):
                    SetPurchDocumentMatchRecord(DocNo, TempOfficeDocumentSelection."Document Type"::Order, TempOfficeDocumentSelection);
                GetDocumentNumber(Expression, GetNameForSalesCrMemo, DocNo):
                    SetSalesDocumentMatchRecord(DocNo, TempOfficeDocumentSelection."Document Type"::"Credit Memo", TempOfficeDocumentSelection);
                GetDocumentNumber(Expression, GetNameForSalesInvoice, DocNo):
                    SetSalesDocumentMatchRecord(DocNo, TempOfficeDocumentSelection."Document Type"::Invoice, TempOfficeDocumentSelection);
                GetDocumentNumber(Expression, GetNameForSalesOrder, DocNo):
                    SetSalesDocumentMatchRecord(DocNo, TempOfficeDocumentSelection."Document Type"::Order, TempOfficeDocumentSelection);
                GetDocumentNumber(Expression, GetNameForSalesQuote, DocNo):
                    SetSalesDocumentMatchRecord(DocNo, TempOfficeDocumentSelection."Document Type"::Quote, TempOfficeDocumentSelection);
                else
                    exit(false);
            end;
        exit(true);
    end;

    local procedure GetDocumentNumber(Expression: Text[250]; Keyword: Text; var DocNo: Code[20]) IsMatch: Boolean
    var
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        DocNoRegEx: DotNet Regex;
    begin
        DocNoRegEx := DocNoRegEx.Regex(StrSubstNo('(?i)(%1)[\#:\s]*(%2)', Keyword, HyperlinkManifest.GetNumberSeriesRegex));
        IsMatch := DocNoRegEx.IsMatch(Expression);
        if IsMatch then
            DocNo := DocNoRegEx.Replace(Expression, '$2');
    end;

    local procedure GetSalesDocuments(var TempOfficeDocumentSelection: Record "Office Document Selection" temporary; Series: Integer; DocType: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Unposted
        SalesHeader.SetRange("Document Type", DocType);
        if SalesHeader.FindSet then
            repeat
                CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series, DocType,
                  SalesHeader."No.", false, SalesHeader."Document Date");
            until SalesHeader.Next = 0;

        // Posted Invoices
        if DocType = TempOfficeDocumentSelection."Document Type"::Invoice then
            if SalesInvoiceHeader.FindSet then
                repeat
                    CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series, DocType,
                      SalesInvoiceHeader."No.", true, SalesInvoiceHeader."Document Date");
                until SalesInvoiceHeader.Next = 0;

        // Posted Credit Memos
        if DocType = TempOfficeDocumentSelection."Document Type"::"Credit Memo" then
            if SalesCrMemoHeader.FindSet then
                repeat
                    CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series, DocType,
                      SalesCrMemoHeader."No.", true, SalesCrMemoHeader."Document Date");
                until SalesCrMemoHeader.Next = 0;
    end;

    local procedure GetPurchaseDocuments(var TempOfficeDocumentSelection: Record "Office Document Selection" temporary; Series: Integer; DocType: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // Unposted
        PurchaseHeader.SetRange("Document Type", DocType);
        if PurchaseHeader.FindSet then
            repeat
                CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series, DocType,
                  PurchaseHeader."No.", false, PurchaseHeader."Document Date");
            until PurchaseHeader.Next = 0;

        // Posted Invoices
        if DocType = TempOfficeDocumentSelection."Document Type"::Invoice then
            if PurchInvHeader.FindSet then
                repeat
                    CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series, DocType,
                      PurchInvHeader."No.", true, PurchInvHeader."Document Date");
                until PurchInvHeader.Next = 0;

        // Posted Credit Memos
        if DocType = TempOfficeDocumentSelection."Document Type"::"Credit Memo" then
            if PurchCrMemoHdr.FindSet then
                repeat
                    CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series, DocType,
                      PurchCrMemoHdr."No.", true, PurchCrMemoHdr."Document Date");
                until PurchCrMemoHdr.Next = 0;
    end;

    local procedure OpenIndividualSalesDocument(TempOfficeAddinContext: Record "Office Add-in Context" temporary; TempOfficeDocumentSelection: Record "Office Document Selection" temporary)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        with TempOfficeDocumentSelection do
            if not Posted then
                if SalesHeader.Get("Document Type", "Document No.") then
                    case SalesHeader."Document Type" of
                        SalesHeader."Document Type"::Quote:
                            PAGE.Run(PAGE::"Sales Quote", SalesHeader);
                        SalesHeader."Document Type"::Order:
                            PAGE.Run(PAGE::"Sales Order", SalesHeader);
                        SalesHeader."Document Type"::Invoice:
                            PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
                        SalesHeader."Document Type"::"Credit Memo":
                            PAGE.Run(PAGE::"Sales Credit Memo", SalesHeader);
                    end else // No SalesHeader record found
                    DocumentDoesNotExist(TempOfficeAddinContext."Document No.")
            else begin
                if "Document Type" = "Document Type"::Invoice then
                    if SalesInvoiceHeader.Get("Document No.") then
                        PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvoiceHeader);
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if SalesCrMemoHeader.Get("Document No.") then
                        PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
            end;
    end;

    local procedure OpenIndividualPurchaseDocument(TempOfficeAddinContext: Record "Office Add-in Context" temporary; TempOfficeDocumentSelection: Record "Office Document Selection" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        with TempOfficeDocumentSelection do
            if not Posted then
                if PurchaseHeader.Get("Document Type", "Document No.") then
                    case PurchaseHeader."Document Type" of
                        PurchaseHeader."Document Type"::Invoice:
                            PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);
                        PurchaseHeader."Document Type"::"Credit Memo":
                            PAGE.Run(PAGE::"Purchase Credit Memo", PurchaseHeader);
                        PurchaseHeader."Document Type"::Order:
                            PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
                    end else // No PurchaseHeader record found
                    DocumentDoesNotExist(TempOfficeAddinContext."Document No.")
            else begin
                if "Document Type" = "Document Type"::Invoice then
                    if PurchInvHeader.Get("Document No.") then
                        PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if PurchCrMemoHdr.Get("Document No.") then
                        PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
            end;
    end;

    local procedure SetSalesDocumentMatchRecord(DocNo: Code[20]; DocType: Integer; var TempOfficeDocumentSelection: Record "Office Document Selection" temporary)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        with TempOfficeDocumentSelection do begin
            if SalesHeader.Get(DocType, DocNo) then
                CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series::Sales, DocType, DocNo, false, SalesHeader."Document Date");
            if SalesInvoiceHeader.Get(DocNo) and (DocType = "Document Type"::Invoice) then
                CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series::Sales, DocType, DocNo, true, SalesInvoiceHeader."Document Date");
            if SalesCrMemoHeader.Get(DocNo) and (DocType = "Document Type"::"Credit Memo") then
                CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series::Sales, DocType, DocNo, true, SalesCrMemoHeader."Document Date");
        end;
    end;

    local procedure SetPurchDocumentMatchRecord(DocNo: Code[20]; DocType: Integer; var TempOfficeDocumentSelection: Record "Office Document Selection" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        with TempOfficeDocumentSelection do begin
            if PurchaseHeader.Get(DocType, DocNo) then
                CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series::Purchase, DocType, DocNo, false, PurchaseHeader."Document Date");
            if PurchInvHeader.Get(DocNo) and (DocType = "Document Type"::Invoice) then
                CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series::Purchase, DocType, DocNo, true, PurchInvHeader."Document Date");
            if PurchCrMemoHdr.Get(DocNo) and (DocType = "Document Type"::"Credit Memo") then
                CreateDocumentMatchRecord(TempOfficeDocumentSelection, Series::Purchase, DocType, DocNo, true, PurchCrMemoHdr."Document Date");
        end;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnNewInvoice(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable and (Rec."Document Type" = Rec."Document Type"::Invoice) then begin
            OfficeMgt.GetContext(TempOfficeAddinContext);
            if TempOfficeAddinContext.IsAppointment then
                CreateOfficeInvoiceRecord(TempOfficeAddinContext."Item ID", Rec."No.", false);
        end;
    end;

    [EventSubscriber(ObjectType::Table, 112, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnPostInvoice(var Rec: Record "Sales Invoice Header"; RunTrigger: Boolean)
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable then begin
            OfficeMgt.GetContext(TempOfficeAddinContext);
            if TempOfficeAddinContext.IsAppointment then
                CreateOfficeInvoiceRecord(TempOfficeAddinContext."Item ID", Rec."No.", true);
        end;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteInvoice(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeInvoice: Record "Office Invoice";
        OfficeMgt: Codeunit "Office Management";
    begin
        if Rec.IsTemporary or (not OfficeMgt.IsAvailable) or (Rec."Document Type" <> Rec."Document Type"::Invoice) then
            exit;
        OfficeMgt.GetContext(TempOfficeAddinContext);
        if TempOfficeAddinContext.IsAppointment then begin
            if OfficeInvoice.Get(TempOfficeAddinContext."Item ID", Rec."No.", false) then
                OfficeInvoice.Delete;
        end;
    end;

    local procedure CreateOfficeInvoiceRecord(ItemID: Text[250]; DocNo: Code[20]; Posted: Boolean)
    var
        OfficeInvoice: Record "Office Invoice";
    begin
        if ItemID = '' then
            exit;

        OfficeInvoice.Init;
        OfficeInvoice."Item ID" := ItemID;
        OfficeInvoice."Document No." := DocNo;
        OfficeInvoice.Posted := Posted;
        if not OfficeInvoice.Insert then
            OfficeInvoice.Modify;
    end;

    [EventSubscriber(ObjectType::Page, 1637, 'OnDisableMessage', '', false, false)]
    local procedure DisableSuggestedLinesOnDisableMessage()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        OfficeMgt: Codeunit "Office Management";
    begin
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.AutomaticLineItemsDialogCode);
        SendTraceTag('00001KG', OfficeMgt.TraceCategory, VERBOSITY::Verbose, SuggestedItemsDisabledTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, 38, 'OnAfterInsertEvent', '', false, false)]
    local procedure GenerateLinesOnAfterInsertPurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        OfficeMgt: Codeunit "Office Management";
        HeaderRecRef: RecordRef;
    begin
        if Rec.IsTemporary then
            exit;

        if not OfficeMgt.IsAvailable then
            exit;

        HeaderRecRef.GetTable(Rec);
        GenerateLinesForDocument(HeaderRecRef);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterInsertEvent', '', false, false)]
    local procedure GenerateLinesOnAfterInsertSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        OfficeMgt: Codeunit "Office Management";
        HeaderRecRef: RecordRef;
    begin
        if not OfficeMgt.IsAvailable then
            exit;

        // Do not generate lines if there was already a quote
        if Rec."Quote No." <> '' then
            exit;

        HeaderRecRef.GetTable(Rec);
        GenerateLinesForDocument(HeaderRecRef);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterDeleteEvent', '', false, false)]
    local procedure UnlinkOfficeDocumentOnAfterDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        OfficeInvoice: Record "Office Invoice";
    begin
        if Rec.IsTemporary then
            exit;
        OfficeInvoice.UnlinkDocument(Rec."No.", false);
    end;

    [EventSubscriber(ObjectType::Table, 38, 'OnAfterDeleteEvent', '', false, false)]
    local procedure UnlinkOfficeDocumentOnAfterDeletePurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        OfficeInvoice: Record "Office Invoice";
    begin
        if Rec.IsTemporary then
            exit;
        OfficeInvoice.UnlinkDocument(Rec."No.", false);
    end;

    local procedure GenerateLinesForDocument(var HeaderRecRef: RecordRef)
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary;
        InstructionMgt: Codeunit "Instruction Mgt.";
        OfficeMgt: Codeunit "Office Management";
        EmailBody: Text;
    begin
        if InstructionMgt.IsEnabled(InstructionMgt.AutomaticLineItemsDialogCode) then begin
            OfficeMgt.GetContext(TempOfficeAddinContext);
            EmailBody := OfficeMgt.GetEmailBody(TempOfficeAddinContext);
            OnGenerateLinesFromText(HeaderRecRef, TempOfficeSuggestedLineItem, EmailBody);
            Commit;

            ConvertSuggestedLinesToDocumentLines(TempOfficeSuggestedLineItem, HeaderRecRef);
        end;
    end;

    local procedure ConvertSuggestedLinesToDocumentLines(var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; var HeaderRecRef: RecordRef)
    var
        PageAction: Action;
    begin
        if TempOfficeSuggestedLineItem.IsEmpty then
            exit;

        PageAction := PAGE.RunModal(PAGE::"Office Suggested Line Items", TempOfficeSuggestedLineItem);
        OnCloseSuggestedLineItemsPage(TempOfficeSuggestedLineItem, HeaderRecRef, PageAction);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseSuggestedLineItemsPage(var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; var HeaderRecRef: RecordRef; PageCloseAction: Action)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateLinesFromText(var HeaderRecRef: RecordRef; var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; EmailBody: Text)
    begin
    end;
}

