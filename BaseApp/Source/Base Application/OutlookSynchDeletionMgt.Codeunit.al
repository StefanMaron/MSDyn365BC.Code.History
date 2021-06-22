codeunit 5303 "Outlook Synch. Deletion Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'APP', Locked = true;
        Text002: Label 'TASK', Locked = true;
        Text003: Label 'SEGMENT', Locked = true;
        OSynchOutlookMgt: Codeunit "Outlook Synch. Outlook Mgt.";
        OSynchProcessLine: Codeunit "Outlook Synch. Process Line";
        Text100: Label 'A deleted Outlook item cannot be synchronized because a conflict has occurred when processing the %1 entity.';
        Text101: Label 'An Outlook item from the %1 entity cannot be synchronized because the deleting of the %2 collection of this entity is not supported. Try again later and if the problem persists contact your system administrator.';

    [Scope('OnPrem')]
    procedure ProcessItem(OSynchUserSetup: Record "Outlook Synch. User Setup"; EntityRecID: RecordID; var ErrorLogXMLWriter: DotNet "OLSync.Common.XmlTextWriter"; StartSynchTime: DateTime)
    var
        EntityRecRef: RecordRef;
        Container: Text;
    begin
        if not EntityRecRef.Get(EntityRecID) then
            exit;

        if not OSynchProcessLine.CheckEntityIdentity(EntityRecID, OSynchUserSetup."Synch. Entity Code") then begin
            RemoveLink(OSynchUserSetup."User ID", EntityRecID);
            exit;
        end;

        if ConflictDetected(EntityRecRef, OSynchUserSetup, StartSynchTime) then begin
            Container := '';
            OSynchOutlookMgt.WriteErrorLog(
              OSynchUserSetup."User ID",
              EntityRecID,
              'Conflict',
              OSynchUserSetup."Synch. Entity Code",
              StrSubstNo(Text100, OSynchUserSetup."Synch. Entity Code"),
              ErrorLogXMLWriter,
              Container);

            Error('');
        end;

        case OSynchUserSetup."Synch. Entity Code" of
            Text001:
                ProcessAppointment(EntityRecRef);
            Text002:
                ProcessTask(EntityRecRef);
        end;

        RemoveLink(OSynchUserSetup."User ID", EntityRecID);
    end;

    local procedure ProcessTask(EntityRecRef: RecordRef)
    var
        EntityFieldRef: FieldRef;
        FieldID: Integer;
    begin
        FieldID := 17;

        EntityFieldRef := EntityRecRef.Field(FieldID);
        EntityFieldRef.Validate(true);
        EntityRecRef.Modify(true);
    end;

    local procedure ProcessAppointment(EntityRecRef: RecordRef)
    begin
        ProcessTask(EntityRecRef);
    end;

    procedure ProcessCollectionElements(var CollectionElementsBuffer: Record "Outlook Synch. Link"; OSynchEntityElement: Record "Outlook Synch. Entity Element"; EntityRecID: RecordID)
    var
        EntityRecRef: RecordRef;
        CollectionElementRecRef: RecordRef;
        RecID: RecordID;
    begin
        if not CollectionElementsBuffer.Find('-') then
            exit;

        if not EntityRecRef.Get(EntityRecID) then
            exit;

        if not OSynchProcessLine.CheckEntityIdentity(EntityRecID, OSynchEntityElement."Synch. Entity Code") then
            exit;

        repeat
            Evaluate(RecID, Format(CollectionElementsBuffer."Record ID"));
            if CollectionElementRecRef.Get(RecID) then
                case OSynchEntityElement."Synch. Entity Code" of
                    Text001:
                        begin
                            if OSynchEntityElement."Outlook Collection" = 'Links' then
                                ProcessAppointmentLinks(CollectionElementRecRef);

                            if OSynchEntityElement."Outlook Collection" = 'Recipients' then
                                ProcessAppointmentRecipients(CollectionElementRecRef);
                        end;
                    Text002:
                        if OSynchEntityElement."Outlook Collection" = 'Links' then
                            ProcessTaskLinks(CollectionElementRecRef);
                    Text003:
                        if OSynchEntityElement."Outlook Collection" = 'Members' then
                            ProcessDistListMembers(CollectionElementRecRef);
                    else
                        Error(Text101, OSynchEntityElement."Synch. Entity Code", OSynchEntityElement."Outlook Collection");
                end;
        until CollectionElementsBuffer.Next = 0;
    end;

    local procedure ProcessTaskLinks(var CollectionElementRecRef: RecordRef)
    var
        CollectionElementFieldRef: FieldRef;
        CodeVar: Code[20];
        FieldID: Integer;
    begin
        CodeVar := '';
        FieldID := 5;

        CollectionElementFieldRef := CollectionElementRecRef.Field(FieldID);
        CollectionElementFieldRef.Validate(CodeVar);
        CollectionElementRecRef.Modify(true);
    end;

    local procedure ProcessAppointmentRecipients(var CollectionElementRecRef: RecordRef)
    begin
        CollectionElementRecRef.Delete(true);
    end;

    local procedure ProcessAppointmentLinks(var CollectionElementRecRef: RecordRef)
    begin
        ProcessAppointmentRecipients(CollectionElementRecRef);
    end;

    local procedure ProcessDistListMembers(var CollectionElementRecRef: RecordRef)
    begin
        CollectionElementRecRef.Delete(true);
    end;

    local procedure RemoveLink(UserID: Code[50]; RecID: RecordID)
    var
        OSynchLink: Record "Outlook Synch. Link";
    begin
        if OSynchLink.Get(UserID, RecID) then begin
            OSynchLink."Outlook Entry ID Hash" := '';
            // Item has been deleted so we update the last sync time.
            OSynchLink."Synchronization Date" := CurrentDateTime;
            OSynchLink.Modify();
        end;
    end;

    local procedure ConflictDetected(SynchRecRef: RecordRef; OSynchUserSetup: Record "Outlook Synch. User Setup"; StartSynchTime: DateTime) IsConflict: Boolean
    var
        ChangeLogEntry: Record "Change Log Entry";
        OSynchLink: Record "Outlook Synch. Link";
        RecID: RecordID;
    begin
        Evaluate(RecID, Format(SynchRecRef.RecordId));

        if not OSynchLink.Get(OSynchUserSetup."User ID", RecID) then
            exit;

        ChangeLogEntry.SetCurrentKey("Table No.", "Primary Key Field 1 Value");
        OSynchProcessLine.FilterChangeLog(RecID, ChangeLogEntry);
        ChangeLogEntry.SetFilter("Type of Change", '<>%1', ChangeLogEntry."Type of Change"::Deletion);

        if OSynchLink."Synchronization Date" >= OSynchUserSetup."Last Synch. Time" then begin
            ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchUserSetup."Last Synch. Time");
            if not ChangeLogEntry.FindLast then
                exit;

            if ChangeLogEntry."Date and Time" <= OSynchLink."Synchronization Date" then
                exit;

            ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchLink."Synchronization Date");
        end else
            ChangeLogEntry.SetFilter("Date and Time", '>=%1&<=%2', OSynchUserSetup."Last Synch. Time", StartSynchTime);

        if not ChangeLogEntry.FindFirst then
            exit;

        IsConflict := OSynchProcessLine.IsConflictDetected(ChangeLogEntry, SynchRecRef, RecID.TableNo);
    end;
}

