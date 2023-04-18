codeunit 137 "OCR Inc. Doc. via Job Queue"
{
    Permissions = TableData "Job Queue Entry" = rimd;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        IncomingDocument: Record "Incoming Document";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
        RecRef: RecordRef;
    begin
        TestField("Record ID to Process");
        RecRef.Get("Record ID to Process");
        RecRef.SetTable(IncomingDocument);
        IncomingDocument.Find();
        SetJobQueueStatus(IncomingDocument, IncomingDocument."Job Queue Status"::Processing);

        case IncomingDocument."OCR Status" of
            IncomingDocument."OCR Status"::Ready:
                if not SendIncomingDocumentToOCR.TrySendToOCR(IncomingDocument) then begin
                    SetJobQueueStatus(IncomingDocument, IncomingDocument."Job Queue Status"::Error);
                    Error(GetLastErrorText);
                end;
            IncomingDocument."OCR Status"::Sent, IncomingDocument."OCR Status"::"Awaiting Verification":
                if not (SendIncomingDocumentToOCR.TryRetrieveFromOCR(IncomingDocument) and
                        (IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Success))
                then begin
                    SetJobQueueStatus(IncomingDocument, IncomingDocument."Job Queue Status"::Processing);
                    Error(GetLastErrorText);
                end;
        end;

        SetJobQueueStatus(IncomingDocument, IncomingDocument."Job Queue Status"::" ");
    end;

    var
        OCRSendReceiveDescriptionTxt: Label 'OCR Incoming Document No. %1.', Comment = '%1 = document type, %2 = document number. Example: Post Purchase Order 1234.';
        IncomingDocumentScheduledMsg: Label 'Incoming Document No. %1 has been scheduled for OCR.', Comment = '%1=document type, %2=number, e.g. Order 123  or Invoice 234.';
        WrongJobQueueStatusErr: Label 'Incoming Document No. %1 cannot be processed because it has already been scheduled for OCR. Choose the Remove from Job Queue action to reset the job queue status and then OCR again.', Comment = '%1 = document type, %2 = document number. Example: Purchase Order 1234 or Invoice 1234.';

    local procedure SetJobQueueStatus(var IncomingDocument: Record "Incoming Document"; NewStatus: Option)
    begin
        IncomingDocument.LockTable();
        if IncomingDocument.Find() then begin
            IncomingDocument."Job Queue Status" := NewStatus;
            IncomingDocument.Modify();
            Commit();
        end;
    end;

    procedure EnqueueIncomingDoc(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            if not ("Job Queue Status" in ["Job Queue Status"::" ", "Job Queue Status"::Error]) then
                Error(WrongJobQueueStatusErr, "Entry No.");
            if Status = Status::New then
                CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);

            "Job Queue Status" := "Job Queue Status"::Scheduled;
            "Job Queue Entry ID" := EnqueueJobEntry(IncomingDocument);
            Modify();
            Message(IncomingDocumentScheduledMsg, "Entry No.");
        end;
    end;

    local procedure EnqueueJobEntry(IncomingDocument: Record "Incoming Document"): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"OCR Inc. Doc. via Job Queue";
            "Record ID to Process" := IncomingDocument.RecordId;
            // Set Timeout to prevent the Job Queue from hanging (eg. as a result of a printer dialog).
            "Maximum No. of Attempts to Run" := 10;
            "Rerun Delay (sec.)" := 5;
            Description :=
              CopyStr(StrSubstNo(OCRSendReceiveDescriptionTxt, IncomingDocument."Entry No."), 1, MaxStrLen(Description));
            "Notify On Success" := true;
            CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
            exit(ID);
        end;
    end;

    procedure CancelQueueEntry(var IncomingDocument: Record "Incoming Document")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with IncomingDocument do begin
            if "Job Queue Status" = "Job Queue Status"::" " then
                exit;
            if not IsNullGuid("Job Queue Entry ID") then
                JobQueueEntry.SetRange(ID, "Job Queue Entry ID");
            JobQueueEntry.SetRange("Record ID to Process", RecordId);
            if not JobQueueEntry.IsEmpty() then
                JobQueueEntry.DeleteAll(true);
            "Job Queue Status" := "Job Queue Status"::" ";
            Modify();
        end;
    end;
}

