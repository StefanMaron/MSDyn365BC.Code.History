codeunit 132458 "Library - Job Queue"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        DoNotHandleCodeunitJobQueueEnqueueEvent: Boolean;
        DoNotHandleTableJobQueueEntryEvent: Boolean;
        TrackingJobQueueEntryID: Guid;
        MultipleTrackJobQueueEntryErr: Label 'Can''t track multiple job queue entries';

    [Scope('OnPrem')]
    procedure SetDoNotHandleCodeunitJobQueueEnqueueEvent(NewDoNotHandleCodeunitJobQueueEnqueueEvent: Boolean)
    begin
        DoNotHandleCodeunitJobQueueEnqueueEvent := NewDoNotHandleCodeunitJobQueueEnqueueEvent;
    end;

    [Scope('OnPrem')]
    procedure SetDoNotHandleTableJobQueueEntryEvent(NewDoNotHandleTableJobQueueEntryEvent: Boolean)
    begin
        DoNotHandleTableJobQueueEntryEvent := NewDoNotHandleTableJobQueueEntryEvent;
    end;

    [Scope('OnPrem')]
    procedure SetTrackingJobQueueEntry(JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsNullGuid(TrackingJobQueueEntryID) then
            Error(MultipleTrackJobQueueEntryErr);

        TrackingJobQueueEntryID := JobQueueEntry.ID;
    end;

    [Scope('OnPrem')]
    procedure GetCollectedJobQueueEntries(var TempJobQueueEntryDst: Record "Job Queue Entry" temporary)
    begin
        TempJobQueueEntryDst.Copy(TempJobQueueEntry, true);
    end;

    [Scope('OnPrem')]
    procedure FindAndRunJobQueueEntryByRecordId(RecordIdToProcess: RecordId)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordIdToProcess);
        JobQueueEntry.FindSet();
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Modify();
        Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure HandleCodeunitJobQueueEnqueueEventOnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        if DoNotHandleCodeunitJobQueueEnqueueEvent then
            exit;

        DoNotScheduleTask := true;
    end;

    [EventSubscriber(ObjectType::Table, 472, 'OnBeforeScheduleTask', '', false, false)]
    local procedure HandleTableJobQueueEntryEventOnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid)
    begin
        if DoNotHandleTableJobQueueEntryEvent then
            exit;

        TaskGUID := CreateGuid;
    end;

    [EventSubscriber(ObjectType::Table, 472, 'OnAfterInsertEvent', '', false, false)]
    local procedure CollectJobQueueEntryOnAfterInsertEvent(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not IsNullGuid(TrackingJobQueueEntryID) then
          exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, 472, 'OnAfterModifyEvent', '', false, false)]
    local procedure CollectJobQueueEntryOnAfterModifyEvent(var Rec: Record "Job Queue Entry";var xRec: Record "Job Queue Entry";RunTrigger: Boolean)
    var
        IsRecRegistered: Boolean;
    begin
        if Rec.IsTemporary then
          exit;

        if not IsNullGuid(TrackingJobQueueEntryID) then
          exit;

        IsRecRegistered := TempJobQueueEntry.Get(Rec.ID);
        TempJobQueueEntry.TransferFields(Rec);
        if IsRecRegistered then
          TempJobQueueEntry.Modify
        else
          TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, 472, 'OnAfterInsertEvent', '', false, false)]
    local procedure CollectTrackingJobQueueEntryOnAfterInsertEvent(var Rec: Record "Job Queue Entry";RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
          exit;

        if IsNullGuid(TrackingJobQueueEntryID) then
          exit;

        if Rec.ID <> TrackingJobQueueEntryID then
            exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.ID := CreateGuid;
        TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, 472, 'OnAfterModifyEvent', '', false, false)]
    local procedure CollectTrackingJobQueueEntryOnAfterModifyEvent(var Rec: Record "Job Queue Entry";var xRec: Record "Job Queue Entry";RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if IsNullGuid(TrackingJobQueueEntryID) then
          exit;

        if Rec.ID <> TrackingJobQueueEntryID then
            exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.ID := CreateGuid;
        TempJobQueueEntry.Insert();
    end;
}

