codeunit 5979 "Service-Post and Send"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        ServiceHeader.Copy(Rec);
        Code;
        Rec := ServiceHeader;
    end;

    var
        ServiceHeader: Record "Service Header";
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.', Comment = '%1=Document Type e.g. Invoice';

    local procedure "Code"()
    var
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ServicePost: Codeunit "Service-Post";
    begin
        OnBeforeCode(ServiceHeader);

        with ServiceHeader do
            case "Document Type" of
                "Document Type"::Invoice,
              "Document Type"::"Credit Memo":
                    if not ConfirmPostAndSend(ServiceHeader, TempDocumentSendingProfile) then
                        exit;
                else
                    Error(NotSupportedDocumentTypeErr, "Document Type");
            end;

        TempDocumentSendingProfile.CheckElectronicSendingEnabled;
        ValidateElectronicFormats(TempDocumentSendingProfile);

        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);

        OnAfterPostAndBeforeSend(ServiceHeader);
        Commit();

        ServicePost.SendPostedDocumentRecord(ServiceHeader, TempDocumentSendingProfile);
    end;

    local procedure ConfirmPostAndSend(ServiceHeader: Record "Service Header"; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary): Boolean
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        Customer.Get(ServiceHeader."Bill-to Customer No.");
        if not DocumentSendingProfile.Get(Customer."Document Sending Profile") then
            DocumentSendingProfile.GetDefault(DocumentSendingProfile);

        Commit();
        TempDocumentSendingProfile.Copy(DocumentSendingProfile);
        TempDocumentSendingProfile.SetDocumentUsage(ServiceHeader);
        TempDocumentSendingProfile.Insert();
        if PAGE.RunModal(PAGE::"Post and Send Confirmation", TempDocumentSendingProfile) <> ACTION::Yes then
            exit(false);

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
            ElectronicDocumentFormat.ValidateElectronicServiceDocument(ServiceHeader, DocumentSendingProfile."E-Mail Format");
        end;

        if (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No) and
           (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Disk Format");
            ElectronicDocumentFormat.ValidateElectronicServiceDocument(ServiceHeader, DocumentSendingProfile."Disk Format");
        end;

        if DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Electronic Format");
            ElectronicDocumentFormat.ValidateElectronicServiceDocument(ServiceHeader, DocumentSendingProfile."Electronic Format");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndBeforeSend(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ServiceHeader: Record "Service Header")
    begin
    end;
}

