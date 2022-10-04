#if not CLEAN20
codeunit 2820 "Native - Attachments"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        CleanupUnlinkedAttachments();
    end;

    var
        CleanupJobBufferHoursTxt: Label '6', Locked = true;
        AttachmentKeepDaysTxt: Label '5', Locked = true;

    [Scope('OnPrem')]
    procedure UpdateAttachments(DocumentId: Guid; NewAttachmentsJSON: Text; PreviousAttachmentsJSON: Text)
    var
        TempOldAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        TempNewAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        NativeEDMTypes: Codeunit "Native - EDM Types";
        GraphMgtAttachmentBuffer: Codeunit "Graph Mgt - Attachment Buffer";
    begin
        NativeEDMTypes.ParseAttachmentsJSON(PreviousAttachmentsJSON, TempOldAttachmentEntityBuffer, DocumentId);
        NativeEDMTypes.ParseAttachmentsJSON(NewAttachmentsJSON, TempNewAttachmentEntityBuffer, DocumentId);

        GraphMgtAttachmentBuffer.UpdateAttachments(TempOldAttachmentEntityBuffer, TempNewAttachmentEntityBuffer, DocumentId);
    end;

    [Scope('OnPrem')]
    procedure GenerateAttachmentsJSON(DocumentIdFilter: Text): Text
    var
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        NativeEDMTypes: Codeunit "Native - EDM Types";
        GraphMgtAttachmentBuffer: Codeunit "Graph Mgt - Attachment Buffer";
    begin
        TempAttachmentEntityBuffer.DeleteAll();
        GraphMgtAttachmentBuffer.LoadAttachments(TempAttachmentEntityBuffer, DocumentIdFilter, '');

        exit(NativeEDMTypes.WriteAttachmentsJSON(TempAttachmentEntityBuffer));
    end;

    local procedure CleanupUnlinkedAttachments()
    var
        UnlinkedAttachment: Record "Unlinked Attachment";
    begin
        UnlinkedAttachment.SetCurrentKey("Created Date-Time");
        UnlinkedAttachment.SetFilter(
          "Created Date-Time", '..%1',
          CreateDateTime(CalcDate(StrSubstNo('<-%1D>', AttachmentKeepDays()), Today), DT2Time(CurrentDateTime)));
        UnlinkedAttachment.DeleteAll(true);
    end;

    local procedure ScheduleCleanupJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobStartTime: DateTime;
        CleanupStartTime: DateTime;
    begin
        CleanupStartTime := CurrentDateTime + AttachmentKeepDays() * HoursPerDay() * MillisecondsPerHour();
        JobStartTime := CleanupStartTime + CleanupJobBufferHours() * MillisecondsPerHour();

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Native - Attachments");
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        JobQueueEntry.SetFilter("Earliest Start Date/Time", '%1..%2', CleanupStartTime, JobStartTime);
        if JobQueueEntry.FindFirst() then
            exit;

        JobQueueEntry.LockTable();
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Native - Attachments";
        JobQueueEntry."Earliest Start Date/Time" := JobStartTime;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure CleanupJobBufferHours(): Integer
    var
        Result: Integer;
    begin
        Evaluate(Result, CleanupJobBufferHoursTxt);
        exit(Result);
    end;

    local procedure AttachmentKeepDays(): Integer
    var
        Result: Integer;
    begin
        Evaluate(Result, AttachmentKeepDaysTxt);
        exit(Result);
    end;

    local procedure HoursPerDay(): Integer
    begin
        exit(24);
    end;

    local procedure MillisecondsPerHour(): Integer
    begin
        exit(3600000);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unlinked Attachment", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertUnlinkedAttachment(var Rec: Record "Unlinked Attachment"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        ScheduleCleanupJob();
    end;
}
#endif
