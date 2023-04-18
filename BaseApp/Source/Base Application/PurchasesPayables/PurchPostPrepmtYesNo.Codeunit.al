codeunit 445 "Purch.-Post Prepmt. (Yes/No)"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Do you want to post the prepayments for %1 %2?';
        Text001: Label 'Do you want to post a credit memo for the prepayments for %1 %2?';
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        UnsupportedDocTypeErr: Label 'Unsupported prepayment document type.';

    procedure PostPrepmtInvoiceYN(var PurchHeader2: Record "Purchase Header"; Print: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        PurchHeader.Copy(PurchHeader2);
        with PurchHeader do begin
            OnPostPrepmtInvoiceYNOnBeforeConfirmPostInvoice(PurchHeader);
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text000, "Document Type", "No."), true) then
                exit;

            PostPrepmtDocument(PurchHeader, "Document Type"::Invoice);

            if Print then begin
                Commit();
                GetReport(PurchHeader, 0);
            end;

            OnAfterPostPrepmtInvoiceYN(PurchHeader);

            PurchHeader2 := PurchHeader;
        end;
    end;

    procedure PostPrepmtCrMemoYN(var PurchHeader2: Record "Purchase Header"; Print: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        PurchHeader.Copy(PurchHeader2);
        with PurchHeader do begin
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text001, "Document Type", "No."), true) then
                exit;

            PostPrepmtDocument(PurchHeader, "Document Type"::"Credit Memo");

            if Print then
                GetReport(PurchHeader, 1);

            Commit();
            OnAfterPostPrepmtCrMemoYN(PurchHeader);

            PurchHeader2 := PurchHeader;
        end;
    end;

    local procedure PostPrepmtDocument(var PurchHeader: Record "Purchase Header"; PrepmtDocumentType: Enum "Purchase Document Type")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        OnBeforePostPrepmtDocument(PurchHeader, PrepmtDocumentType.AsInteger());

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchHeader.RecordId, 0, '');
        PurchPostPrepayments.SetDocumentType(PrepmtDocumentType.AsInteger());
        Commit();
        if not PurchPostPrepayments.Run(PurchHeader) then
            ErrorMessageHandler.ShowErrors();
    end;

    procedure Preview(var PurchHeader: Record "Purchase Header"; DocumentType: Option)
    var
        PurchPostPrepmtYesNo: Codeunit "Purch.-Post Prepmt. (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(PurchPostPrepmtYesNo);
        PurchPostPrepmtYesNo.SetDocumentType(DocumentType);
        GenJnlPostPreview.Preview(PurchPostPrepmtYesNo, PurchHeader);
    end;

    local procedure GetReport(var PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(PurchHeader, DocumentType, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        PurchInvHeader."No." := "Last Prepayment No.";
                        PurchInvHeader.SetRecFilter();
                        PurchInvHeader.PrintRecords(false);
                    end;
                DocumentType::"Credit Memo":
                    begin
                        PurchCrMemoHeader."No." := "Last Prepmt. Cr. Memo No.";
                        PurchCrMemoHeader.SetRecFilter();
                        PurchCrMemoHeader.PrintRecords(false);
                    end;
            end;
    end;

    [Scope('OnPrem')]
    procedure SetDocumentType(NewPrepmtDocumentType: Option)
    begin
        PrepmtDocumentType := NewPrepmtDocumentType;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvoiceYN(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtCrMemoYN(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        with PurchaseHeader do begin
            Copy(RecVar);
            Invoice := true;

            if PrepmtDocumentType in [PrepmtDocumentType::Invoice, PrepmtDocumentType::"Credit Memo"] then
                PurchasePostPrepayments.SetDocumentType(PrepmtDocumentType)
            else
                Error(UnsupportedDocTypeErr);
        end;

        PurchasePostPrepayments.SetPreviewMode(true);
        Result := PurchasePostPrepayments.Run(PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtDocument(var PurchaseHeader: Record "Purchase Header"; PrepmtDocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPrepmtInvoiceYNOnBeforeConfirmPostInvoice(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

