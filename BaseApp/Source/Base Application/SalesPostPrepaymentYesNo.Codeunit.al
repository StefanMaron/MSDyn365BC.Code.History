#if not CLEAN19
codeunit 443 "Sales-Post Prepayment (Yes/No)"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Do you want to post the prepayments for %1 %2?';
        Text001: Label 'Do you want to post a credit memo for the prepayments for %1 %2?';
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        LetterNoToInvoice: Code[20];
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        UnsupportedDocTypeErr: Label 'Unsupported prepayment document type.';

    procedure PostPrepmtInvoiceYN(var SalesHeader2: Record "Sales Header"; Print: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Copy(SalesHeader2);
        with SalesHeader do begin
            if not ConfirmForDocument(SalesHeader, Text000) then
                exit;

            // NAVCZ
            if "Prepayment Type" = "Prepayment Type"::Advance then
                SalesPostAdvances.Invoice(SalesHeader)
            else
                // NAVCZ
                PostPrepmtDocument(SalesHeader, "Document Type"::Invoice);

            if Print then begin
                Commit();
                GetReport(SalesHeader, 0);
            end;

            OnAfterPostPrepmtInvoiceYN(SalesHeader);

            SalesHeader2 := SalesHeader;
        end;
    end;

    procedure PostPrepmtCrMemoYN(var SalesHeader2: Record "Sales Header"; Print: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesHeader.Copy(SalesHeader2);
        with SalesHeader do begin
            if not ConfirmForDocument(SalesHeader, Text001) then
                exit;

            // NAVCZ
            if "Prepayment Type" = "Prepayment Type"::Advance then begin
                if GetSelectedInvoices(SalesHeader, SalesInvHeader) then
                    SalesPostAdvances.CreditMemo(SalesHeader, SalesInvHeader)
                else
                    Print := false;
            end else
                // NAVCZ
                PostPrepmtDocument(SalesHeader, "Document Type"::"Credit Memo");

            if Print then
                GetReport(SalesHeader, 1);

            Commit();
            OnAfterPostPrepmtCrMemoYN(SalesHeader);

            SalesHeader2 := SalesHeader;
        end;
    end;

    local procedure ConfirmForDocument(var SalesHeader: Record "Sales Header"; ConfirmationText: Text) Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmForDocument(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmationText, SalesHeader."Document Type", SalesHeader."No."), true);
    end;

    local procedure PostPrepmtDocument(var SalesHeader: Record "Sales Header"; PrepmtDocumentType: Enum "Sales Document Type")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        OnBeforePostPrepmtDocument(SalesHeader, PrepmtDocumentType.AsInteger());

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesHeader.RecordId, 0, '');
        SalesPostPrepayments.SetDocumentType(PrepmtDocumentType.AsInteger());
        Commit();
        if not SalesPostPrepayments.Run(SalesHeader) then
            ErrorMessageHandler.ShowErrors;
    end;

    procedure Preview(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    var
        SalesPostPrepaymentYesNo: Codeunit "Sales-Post Prepayment (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(SalesPostPrepaymentYesNo);
        SalesPostPrepaymentYesNo.SetDocumentType(DocumentType);
        GenJnlPostPreview.Preview(SalesPostPrepaymentYesNo, SalesHeader);
    end;

    procedure GetReport(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(SalesHeader, DocumentType, IsHandled);
        if IsHandled then
            exit;

        with SalesHeader do
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        SalesInvHeader."No." := "Last Prepayment No.";
                        SalesInvHeader.SetRecFilter;
                        SalesInvHeader.PrintRecords(false);
                    end;
                DocumentType::"Credit Memo":
                    begin
                        SalesCrMemoHeader."No." := "Last Prepmt. Cr. Memo No.";
                        SalesCrMemoHeader.SetRecFilter;
                        SalesCrMemoHeader.PrintRecords(false);
                    end;
            end;
    end;

    [Scope('OnPrem')]
    procedure SetDocumentType(NewPrepmtDocumentType: Option)
    begin
        PrepmtDocumentType := NewPrepmtDocumentType;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetSelectedInvoices(SalesHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Invoice Header"): Boolean
    var
        PostedSalesInvoices: Page "Posted Sales Invoices";
    begin
        // NAVCZ
        with SalesHeader do begin
            SalesInvHeader.SetCurrentKey("Prepayment Order No.");
            SalesInvHeader.SetRange("Prepayment Order No.", "No.");
            if LetterNoToInvoice <> '' then
                SalesInvHeader.SetRange("Letter No.", LetterNoToInvoice);
            SalesInvHeader.SetFilter("Reversed By Cr. Memo No.", '%1', '');
            PostedSalesInvoices.SetTableView(SalesInvHeader);
            PostedSalesInvoices.LookupMode(true);
            if PostedSalesInvoices.RunModal = ACTION::LookupOK then begin
                PostedSalesInvoices.GetSelection(SalesInvHeader);
                exit(true);
            end;
            exit(false);
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetAdvLetterNo(LetterNo: Code[20])
    begin
        // NAVCZ
        Clear(SalesPostAdvances);
        LetterNoToInvoice := LetterNo;
        SalesPostAdvances.SetLetterNo(LetterNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvoiceYN(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtCrMemoYN(var SalesHeader: Record "Sales Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        with SalesHeader do begin
            Copy(RecVar);
            Invoice := true;

            if PrepmtDocumentType in [PrepmtDocumentType::Invoice, PrepmtDocumentType::"Credit Memo"] then
                SalesPostPrepayments.SetDocumentType(PrepmtDocumentType)
            else
                Error(UnsupportedDocTypeErr);
        end;

        SalesPostPrepayments.SetPreviewMode(true);
        Result := SalesPostPrepayments.Run(SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmForDocument(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtDocument(var SalesHeader: Record "Sales Header"; PrepmtDocumentType: Option)
    begin
    end;
}

#endif