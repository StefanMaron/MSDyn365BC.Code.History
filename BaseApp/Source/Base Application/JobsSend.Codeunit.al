codeunit 1016 "Jobs-Send"
{
    TableNo = Job;

    trigger OnRun()
    begin
        Job.Copy(Rec);
        Code;
        Rec := Job;
    end;

    var
        Job: Record Job;

    local procedure "Code"()
    var
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
    begin
        if not ConfirmSend(Job, TempDocumentSendingProfile) then
            exit;

        ValidateElectronicFormats(TempDocumentSendingProfile);

        with Job do begin
            Get("No.");
            SetRecFilter;
            SendProfile(TempDocumentSendingProfile);
        end;
    end;

    local procedure ConfirmSend(Job: Record Job; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary): Boolean
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        Customer.Get(Job."Bill-to Customer No.");
        if OfficeMgt.IsAvailable then
            DocumentSendingProfile.GetOfficeAddinDefault(TempDocumentSendingProfile, OfficeMgt.AttachAvailable)
        else begin
            if not DocumentSendingProfile.Get(Customer."Document Sending Profile") then
                DocumentSendingProfile.GetDefault(DocumentSendingProfile);

            Commit();
            with TempDocumentSendingProfile do begin
                Copy(DocumentSendingProfile);
                SetDocumentUsage(Job);
                Insert;
            end;
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
            ElectronicDocumentFormat.ValidateElectronicJobsDocument(Job, DocumentSendingProfile."E-Mail Format");
        end;

        if (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No) and
           (DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Disk Format");
            ElectronicDocumentFormat.ValidateElectronicJobsDocument(Job, DocumentSendingProfile."Disk Format");
        end;

        if DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(DocumentSendingProfile."Electronic Format");
            ElectronicDocumentFormat.ValidateElectronicJobsDocument(Job, DocumentSendingProfile."Electronic Format");
        end;
    end;
}

