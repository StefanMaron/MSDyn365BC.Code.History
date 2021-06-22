codeunit 79 "Sales-Post and Send"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        if not Find then
            Error(NothingToPostErr);

        SalesHeader.Copy(Rec);
        Code;
        Rec := SalesHeader;
    end;

    var
        SalesHeader: Record "Sales Header";
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.', Comment = '%1=Document Type';
        NothingToPostErr: Label 'There is nothing to post.';

    local procedure "Code"()
    var
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        SalesPost: Codeunit "Sales-Post";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        HideDialog: Boolean;
    begin
        HideDialog := false;

        OnBeforePostAndSend(SalesHeader, HideDialog, TempDocumentSendingProfile);
        if not HideDialog then
            with SalesHeader do
                case "Document Type" of
                    "Document Type"::Invoice,
                  "Document Type"::"Credit Memo",
                  "Document Type"::Order:
                        if not ConfirmPostAndSend(SalesHeader, TempDocumentSendingProfile) then
                            exit;
                    else
                        Error(NotSupportedDocumentTypeErr, "Document Type");
                end;

        TempDocumentSendingProfile.CheckElectronicSendingEnabled;
        ValidateElectronicFormats(TempDocumentSendingProfile);

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            SalesPostYesNo.PostAndSend(SalesHeader);
            if not (SalesHeader.Ship or SalesHeader.Invoice) then
                exit;
        end else
            CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        OnAfterPostAndBeforeSend(SalesHeader);

        Commit();

        SalesPost.SendPostedDocumentRecord(SalesHeader, TempDocumentSendingProfile);

        OnAfterPostAndSend(SalesHeader);
    end;

    local procedure ConfirmPostAndSend(SalesHeader: Record "Sales Header"; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary): Boolean
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        Customer.Get(SalesHeader."Bill-to Customer No.");
        if OfficeMgt.IsAvailable then
            DocumentSendingProfile.GetOfficeAddinDefault(TempDocumentSendingProfile, OfficeMgt.AttachAvailable)
        else begin
            if not DocumentSendingProfile.Get(Customer."Document Sending Profile") then
                DocumentSendingProfile.GetDefault(DocumentSendingProfile);

            Commit();
            TempDocumentSendingProfile.Copy(DocumentSendingProfile);
            TempDocumentSendingProfile.SetDocumentUsage(SalesHeader);
            TempDocumentSendingProfile.Insert();

            OnBeforeConfirmAndSend(SalesHeader, TempDocumentSendingProfile);
            if PAGE.RunModal(PAGE::"Post and Send Confirmation", TempDocumentSendingProfile) <> ACTION::Yes then
                exit(false);
        end;

        exit(true);
    end;

    local procedure ValidateElectronicFormats(DocumentSendingProfile: Record "Document Sending Profile")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if (DocumentSendingProfile."E-Mail" <> DocumentSendingProfile."E-Mail"::No) and
           (DocumentSendingProfile."E-Mail Attachment" <> DocumentSendingProfile."E-Mail Attachment"::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."E-Mail Format");
            ElectronicDocumentFormat.ValidateElectronicSalesDocument(SalesHeader, DocumentSendingProfile."E-Mail Format");
        end;

        if (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No) and
           (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Disk Format");
            ElectronicDocumentFormat.ValidateElectronicSalesDocument(SalesHeader, DocumentSendingProfile."Disk Format");
        end;

        if DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Electronic Format");
            ElectronicDocumentFormat.ValidateElectronicSalesDocument(SalesHeader, DocumentSendingProfile."Electronic Format");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndBeforeSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmAndSend(SalesHeader: Record "Sales Header"; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAndSend(var SalesHeader: Record "Sales Header"; var HideDialog: Boolean; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary)
    begin
    end;
}

