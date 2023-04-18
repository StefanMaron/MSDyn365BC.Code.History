codeunit 133 "Send Incoming Document to OCR"
{
    TableNo = "Incoming Document";

    trigger OnRun()
    begin
        SendDocToOCR(Rec);
    end;

    var
        OCRWhenApprovalIsCompleteErr: Label 'The document can only be sent to the OCR service when the approval process is complete.';
        NoOcrAttachmentErr: Label 'There is no attachment of type PDF or Image.';
        NoAttachmentMarkedForOcrErr: Label 'You must select an attachment for use for OCR.';
        ShowMessages: Boolean;
        CannotRemoveFromJobQueueTxt: Label 'The document cannot be removed from queue since it is already sent.';
        CannotSendDocumentTxt: Label 'The document cannot be sent to the OCR service because its status is %1.', Comment = '%1 Status of the document for example: New, Released, Posted, Created, Rejected...';
        CannotScheduleDocumentTxt: Label 'The document cannot be scheduled for sending to the OCR service because its status is %1.', Comment = '%1 Status of the document for example: New, Released, Posted, Created, Rejected...';
        RemovedFromJobQueueTxt: Label 'The document was successfully removed from Job Queue.';
        DocumentHasBeenScheduledTxt: Label 'The document has been scheduled for sending to the OCR service.';
        DoYouWantToSetupOCRQst: Label 'The OCR service is not enabled.\\Do you want to open the OCR Service Setup window?';
        OCRServiceNotEnabledErr: Label 'The OCR service is not enabled.';

    [Scope('OnPrem')]
    procedure SendToJobQueue(var IncomingDocument: Record "Incoming Document")
    begin
        if not VerifySendToOCR(IncomingDocument, CannotScheduleDocumentTxt) then
            exit;

        IncomingDocument.TestField("OCR Status", IncomingDocument."OCR Status"::" ");
        IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::Ready;
        IncomingDocument.Modify();

        CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);
        ShowMessage(DocumentHasBeenScheduledTxt);
        OnAfterIncomingDocReadyForOCR(IncomingDocument);
    end;

    procedure RemoveFromJobQueue(var IncomingDocument: Record "Incoming Document")
    var
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
    begin
        with IncomingDocument do begin
            if "OCR Status" <> "OCR Status"::Ready then begin
                ShowMessage(CannotRemoveFromJobQueueTxt);
                exit;
            end;

            "OCR Status" := "OCR Status"::" ";
            ReleaseIncomingDocument.Reopen(IncomingDocument);
            Modify();
            ShowMessage(RemovedFromJobQueueTxt);
        end;
    end;

    [Scope('OnPrem')]
    procedure SendDocToOCR(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Get();
        if not OCRServiceSetup.Enabled then begin
            if not Confirm(DoYouWantToSetupOCRQst) then
                exit;
            PAGE.RunModal(PAGE::"OCR Service Setup", OCRServiceSetup);
            if not OCRServiceSetup.Enabled then
                Error(OCRServiceNotEnabledErr);
        end;

        if not VerifySendToOCR(IncomingDocument, CannotSendDocumentTxt) then
            exit;

        UpdateIncomingDocumentAttachmentForOCR(IncomingDocument);

        case IncomingDocument."OCR Status" of
            IncomingDocument."OCR Status"::" ":
                IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::Ready;
            IncomingDocument."OCR Status"::Ready:
                ;
            else
                exit;
        end;

        CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);

        IncomingDocument.LockTable();
        IncomingDocument.Find();
        // Check OCR Status due to it could be changed by another user in the meantime
        if IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Ready then begin
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
            IncomingDocumentAttachment.SetRange("Use for OCR", true);
            if not IncomingDocumentAttachment.FindFirst() then
                Error(NoAttachmentMarkedForOcrErr);
            IncomingDocumentAttachment.SendToOCR();
            IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::Sent;
            IncomingDocument.Modify();
        end;
        Commit();
        OnAfterIncomingDocSentToOCR(IncomingDocument);
    end;

    procedure ScheduleJobQueueReceive()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.ScheduleJobQueueReceive();
    end;

    [Scope('OnPrem')]
    procedure RetrieveDocFromOCR(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        OCRStatus: Integer;
    begin
        with IncomingDocument do begin
            if not ("OCR Status" in ["OCR Status"::Sent, "OCR Status"::"Awaiting Verification"]) then
                TestField("OCR Status", "OCR Status"::Sent);

            CheckNotCreated();
            LockTable();
            Find();
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
            IncomingDocumentAttachment.SetRange("Use for OCR", true);
            if IncomingDocumentAttachment.FindFirst() then begin
                OCRStatus := OCRServiceMgt.GetDocumentForAttachment(IncomingDocumentAttachment);
                if not (OCRStatus in ["OCR Status"::Success, "OCR Status"::Error, "OCR Status"::"Awaiting Verification"]) then
                    Error('');
            end;

            Find();

            case OCRStatus of
                "OCR Status"::Success:
                    SetStatusToReceived(IncomingDocument);
                "OCR Status"::"Awaiting Verification":
                    SetStatusToVerify(IncomingDocument);
                "OCR Status"::Error:
                    SetStatusToFailed(IncomingDocument);
            end;
        end;
    end;

    procedure SetStatusToReceived(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            Find();
            if ("OCR Status" = "OCR Status"::Success) and "OCR Process Finished" then
                exit;

            "OCR Status" := "OCR Status"::Success;
            "OCR Process Finished" := true;
            Modify();
            Commit();

            OnAfterIncomingDocReceivedFromOCR(IncomingDocument);
        end;
    end;

    procedure SetStatusToFailed(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            Find();
            "OCR Status" := "OCR Status"::Error;
            "OCR Process Finished" := true;
            Modify();
            Commit();

            OnAfterIncomingDocReceivedFromOCR(IncomingDocument);
        end;
    end;

    procedure SetStatusToVerify(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            Find();
            "OCR Status" := "OCR Status"::"Awaiting Verification";
            Modify();
            Commit();
        end;
    end;

    procedure TrySendToOCR(var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        exit(CODEUNIT.Run(CODEUNIT::"Send Incoming Document to OCR", IncomingDocument));
    end;

    procedure TryRetrieveFromOCR(var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        exit(CODEUNIT.Run(CODEUNIT::"Retrieve Document From OCR", IncomingDocument));
    end;

    local procedure VerifySendToOCR(var IncomingDocument: Record "Incoming Document"; ErrorMessage: Text): Boolean
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        with IncomingDocument do begin
            TestField(Posted, false);
            CheckNotCreated();

            if not (Status in [Status::New, Status::Released, Status::"Pending Approval"]) then begin
                ShowMessage(StrSubstNo(ErrorMessage, Format(Status)));
                exit(false);
            end;

            if "OCR Status" in ["OCR Status"::Sent, "OCR Status"::Success, "OCR Status"::"Awaiting Verification"] then begin
                ShowMessage(StrSubstNo(ErrorMessage, Format("OCR Status")));
                exit(false);
            end;

            OnCheckIncomingDocSetForOCRRestrictions();

            if ApprovalsMgmt.IsIncomingDocApprovalsWorkflowEnabled(IncomingDocument) and (Status = Status::New) then
                Error(OCRWhenApprovalIsCompleteErr);

            UpdateIncomingDocumentAttachmentForOCR(IncomingDocument);
        end;

        exit(true);
    end;

    local procedure UpdateIncomingDocumentAttachmentForOCR(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        with IncomingDocument do begin
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
            IncomingDocumentAttachment.SetFilter(Type, '%1|%2', IncomingDocumentAttachment.Type::PDF, IncomingDocumentAttachment.Type::Image);
            if IncomingDocumentAttachment.IsEmpty() then
                Error(NoOcrAttachmentErr);
            TestField("OCR Service Doc. Template Code");
            IncomingDocumentAttachment.SetRange("Use for OCR", true);
            if IncomingDocumentAttachment.IsEmpty() then begin
                IncomingDocumentAttachment.SetRange("Use for OCR");
                IncomingDocumentAttachment.SetRange("Main Attachment", true);
                IncomingDocumentAttachment.FindFirst();
                IncomingDocumentAttachment."Use for OCR" := true;
                IncomingDocumentAttachment.Modify();
            end;
        end;
    end;

    procedure SetShowMessages(NewShowMessages: Boolean)
    begin
        ShowMessages := NewShowMessages;
    end;

    local procedure ShowMessage(MessageText: Text)
    begin
        if ShowMessages then
            Message(MessageText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncomingDocReadyForOCR(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncomingDocSentToOCR(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncomingDocReceivedFromOCR(var IncomingDocument: Record "Incoming Document")
    begin
    end;
}

