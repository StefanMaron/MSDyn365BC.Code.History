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
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        UnsupportedDocTypeErr: Label 'Unsupported prepayment document type.';

    procedure PostPrepmtInvoiceYN(var SalesHeader2: Record "Sales Header"; Print: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        SalesHeader.Copy(SalesHeader2);
        with SalesHeader do begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text000, "Document Type", "No."), true)
            then
                exit;

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
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        SalesHeader.Copy(SalesHeader2);
        with SalesHeader do begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text001, "Document Type", "No."), true)
            then
                exit;

            PostPrepmtDocument(SalesHeader, "Document Type"::"Credit Memo");

            if Print then
                GetReport(SalesHeader, 1);

            Commit();
            OnAfterPostPrepmtCrMemoYN(SalesHeader);

            SalesHeader2 := SalesHeader;
        end;
    end;

    local procedure PostPrepmtDocument(var SalesHeader: Record "Sales Header"; PrepmtDocumentType: Option)
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        OnBeforePostPrepmtDocument(SalesHeader, PrepmtDocumentType);

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        SalesPostPrepayments.SetDocumentType(PrepmtDocumentType);
        Commit();
        if not SalesPostPrepayments.Run(SalesHeader) then
            ErrorMessageHandler.ShowErrors;
    end;

    [Scope('OnPrem')]
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvoiceYN(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtCrMemoYN(var SalesHeader: Record "Sales Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
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
    local procedure OnBeforePostPrepmtDocument(var SalesHeader: Record "Sales Header"; PrepmtDocumentType: Option)
    begin
    end;
}

