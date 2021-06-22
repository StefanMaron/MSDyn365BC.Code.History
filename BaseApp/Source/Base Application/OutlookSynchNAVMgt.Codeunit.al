codeunit 5301 "Outlook Synch. NAV Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchLink: Record "Outlook Synch. Link";
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchField: Record "Outlook Synch. Field";
        OSynchUserSetup: Record "Outlook Synch. User Setup";
        OSynchSetupDetail: Record "Outlook Synch. Setup Detail";
        GlobalRecordIDBuffer: Record "Outlook Synch. Link" temporary;
        SortedEntitiesBuffer: Record "Outlook Synch. Lookup Name" temporary;
        Base64Convert: Codeunit "Base64 Convert";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        OSynchTypeConversion: Codeunit "Outlook Synch. Type Conv";
        OSynchOutlookMgt: Codeunit "Outlook Synch. Outlook Mgt.";
        OSynchProcessLine: Codeunit "Outlook Synch. Process Line";
        XMLWriter: DotNet "OLSync.Common.XmlTextWriter";
        Text001: Label 'The synchronization failed because the synchronization data could not be obtained from %1. Try again later and if the problem persists contact your system administrator.', Comment = '%1 - product name';
        Text002: Label 'The synchronization failed because the synchronization data from Microsoft Outlook cannot be processed. Try again later and if the problem persists contact your system administrator.';
        Text003: Label 'The synchronization failed because the correlation for the %1 field of the %2 entity cannot be found. Try again later and if the problem persists contact your system administrator.';
        Text004: Label 'The synchronization failed because an Outlook item of %1 entity could not be found in the synchronization folders.';
        Text005: Label 'The synchronization failed because the %1 and %2 entities contain the same entries. Try again later and if the problem persists contact your system administrator.';
        Text008: Label 'The synchronization cannot be performed because the tracking of data changes in %1 has not been activated. Try again later and if the problem persists contact your system administrator.', Comment = '%1 - product name';
        Text009: Label 'The synchronization failed because the correlation for the %1 field of the %2 collection in the %3 entity cannot be found. Try again later and if the problem persists contact your system administrator.';
        Text010: Label 'The synchronization failed because the synchronization data could not be obtained from %2 for the %1 entity. Try again later and if the problem persists contact your system administrator.', Comment = '%2 - product name';

    [Scope('OnPrem')]
    procedure StartSynchronization(UserID: Code[50]; var XMLMessage: Text; SynchronizeAll: Boolean)
    var
        SynchStartTime: DateTime;
    begin
        if not (StrLen(XMLMessage) > 0) then
            Error(Text001);

        SortedEntitiesBuffer.Reset();
        SortedEntitiesBuffer.DeleteAll();

        GetSortedEntities(UserID, SortedEntitiesBuffer, false);

        Clear(XMLWriter);
        XMLWriter := XMLWriter.XmlTextWriter;
        XMLWriter.WriteStartDocument;
        XMLWriter.WriteStartElement('SynchronizationMessage');

        if (not CheckChangeLogAvailability) and (not SynchronizeAll) then
            Error(Text008, PRODUCTNAME.Full);

        ProcessRenamedRecords(UserID);
        SynchStartTime := OSynchOutlookMgt.ProcessOutlookChanges(UserID, XMLMessage, XMLWriter, false);
        if SynchronizeAll then begin
            ProcessDeletedRecords(UserID);
            CollectNavisionChanges(UserID, SynchronizeAll, SynchStartTime);
        end else begin
            CollectNavisionChanges(UserID, SynchronizeAll, SynchStartTime);
            ProcessDeletedRecords(UserID);
        end;

        if not IsNull(XMLWriter) then begin
            XMLWriter.WriteEndElement;
            XMLWriter.WriteEndDocument;

            XMLMessage := XMLWriter.ToString;
            Clear(XMLWriter);

            if StrLen(XMLMessage) = 0 then
                Error(Text001, PRODUCTNAME.Full);
        end;
    end;

    [Scope('OnPrem')]
    procedure CollectConflictedEntities(UserID: Code[50]; var XMLMessage: Text)
    var
        EntityRecRef: RecordRef;
        TempEntityRecRef: RecordRef;
        EntityRecID: RecordID;
        XmlTextReader: DotNet "OLSync.Common.XmlTextReader";
        SynchEntityCode: Code[10];
        Container: Text;
        TagName: Text[80];
        RootIterator: Text[38];
        EntryIDHash: Text[32];
    begin
        XmlTextReader := XmlTextReader.XmlTextReader;

        if not XmlTextReader.LoadXml(XMLMessage) then
            Error(Text002);

        TagName := XmlTextReader.RootLocalName;
        if TagName <> 'RefreshTroubleshootingInfo' then
            Error(Text002);

        if XmlTextReader.SelectElements(RootIterator, '*') < 1 then
            exit;

        TagName := XmlTextReader.GetName(RootIterator);
        if TagName <> 'OutlookItem' then
            Error(Text002);

        if IsNull(XMLWriter) then
            XMLWriter := XMLWriter.XmlTextWriter;
        XMLWriter.WriteStartDocument;
        XMLWriter.WriteStartElement('SynchronizationMessage');

        if XmlTextReader.SelectElements(RootIterator, 'child::OutlookItem') > 0 then begin
            Clear(Container);
            GlobalRecordIDBuffer.Reset();
            GlobalRecordIDBuffer.DeleteAll();

            repeat
                Clear(EntityRecID);
                EntryIDHash := '';

                TagName := XmlTextReader.GetName(RootIterator);
                SynchEntityCode :=
                  CopyStr(XmlTextReader.GetCurrentNodeAttribute(RootIterator, 'SynchEntityCode'), 1, MaxStrLen(SynchEntityCode));

                OSynchUserSetup.Get(UserID, SynchEntityCode);
                OSynchEntity.Get(SynchEntityCode);
                EntryIDHash := OSynchOutlookMgt.GetEntryIDHash(Container, XmlTextReader, RootIterator);
                if EntryIDHash <> '' then begin
                    OSynchLink.Reset();
                    OSynchLink.SetRange("User ID", UserID);
                    OSynchLink.SetRange("Outlook Entry ID Hash", EntryIDHash);
                    if OSynchLink.FindFirst then begin
                        Evaluate(EntityRecID, Format(OSynchLink."Record ID"));
                        GlobalRecordIDBuffer.SetRange("Search Record ID", UpperCase(Format(EntityRecID)));
                        if not GlobalRecordIDBuffer.FindFirst then
                            if EntityRecRef.Get(EntityRecID) then begin
                                TempEntityRecRef.Open(EntityRecID.TableNo, true);
                                CopyRecordReference(EntityRecRef, TempEntityRecRef, false);
                                ProcessEntityRecords(TempEntityRecRef, SynchEntityCode);
                                TempEntityRecRef.Close;
                            end else begin
                                XMLWriter.WriteStartElement('DeletedOutlookItem');
                                XMLWriter.WriteAttribute('SynchEntityCode', SynchEntityCode);
                                XMLWriter.WriteAttribute('RecordID', Format(EntityRecID));
                                XMLWriter.WriteAttribute(
                                  'LastModificationTime',
                                  OSynchTypeConversion.SetDateTimeFormat(
                                    OSynchTypeConversion.LocalDT2UTC(OSynchOutlookMgt.GetLastModificationTime(EntityRecID))));
                                WriteLinkedOutlookEntryID(UserID, EntityRecID, XMLWriter);
                                XMLWriter.WriteEndElement;

                                UpdateGlobalRecordIDBuffer(EntityRecID, SynchEntityCode);
                            end;
                    end else begin
                        XMLWriter.WriteStartElement('DeletedOutlookItem');
                        XMLWriter.WriteAttribute('SynchEntityCode', SynchEntityCode);
                        XMLWriter.WriteAttribute('RecordID', '');
                        XMLWriter.WriteAttribute(
                          'LastModificationTime',
                          OSynchTypeConversion.SetDateTimeFormat(OSynchTypeConversion.LocalDT2UTC(0DT)));

                        XMLWriter.WriteStartElement('EntryID');
                        XMLWriter.WriteElementTextContent(Base64Convert.ToBase64(Container));
                        XMLWriter.WriteEndElement;

                        XMLWriter.WriteEndElement;
                    end;
                end else
                    OSynchOutlookMgt.WriteErrorLog(
                      UserID,
                      EntityRecID,
                      'Error',
                      SynchEntityCode,
                      StrSubstNo(Text004, SynchEntityCode),
                      XMLWriter,
                      Container);
            until not XmlTextReader.MoveNext(RootIterator);
        end;

        if not IsNull(XMLWriter) then begin
            XMLWriter.WriteEndElement;
            XMLWriter.WriteEndDocument;

            XMLMessage := XMLWriter.ToString;
            Clear(XMLWriter);

            if StrLen(XMLMessage) = 0 then
                Error(Text001);
        end;
    end;

    [Scope('OnPrem')]
    procedure CollectNavisionChanges(UserID: Code[50]; SynchronizeAll: Boolean; SynchStartTime: DateTime)
    begin
        if not SortedEntitiesBuffer.FindSet then
            exit;

        GlobalRecordIDBuffer.Reset();
        GlobalRecordIDBuffer.DeleteAll();

        repeat
            OSynchUserSetup.Get(UserID, SortedEntitiesBuffer.Name);
            OSynchEntity.Get(SortedEntitiesBuffer.Name);

            CollectEntityChanges(SynchronizeAll, SynchStartTime);
            CollectEntityElementChanges(SynchronizeAll, SynchStartTime);
        until SortedEntitiesBuffer.Next = 0;
    end;

    local procedure CollectEntityChanges(SynchronizeAll: Boolean; SynchStartTime: DateTime)
    var
        TempDeletedChangeLogEntry: Record "Change Log Entry" temporary;
        TempRecRef: RecordRef;
        TempRecRef1: RecordRef;
        NullRecRef: RecordRef;
        RecID: RecordID;
    begin
        TempDeletedChangeLogEntry.Reset();
        TempDeletedChangeLogEntry.DeleteAll();

        if not SynchronizeAll then begin
            TempRecRef.Open(OSynchEntity."Table No.", true);
            ProcessChangeLog(
              OSynchEntity."Table No.",
              OSynchUserSetup."Last Synch. Time",
              TempRecRef,
              TempDeletedChangeLogEntry);
        end else
            TempRecRef.Open(OSynchEntity."Table No.");

        OSynchFilter.Reset();
        OSynchFilter.SetFilter(
          "Record GUID",
          '%1|%2',
          OSynchEntity."Record GUID",
          OSynchUserSetup."Record GUID");

        TempRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, NullRecRef));
        if TempRecRef.Find('-') then
            repeat
                if SynchronizeAll then
                    ProcessEntityRecords(TempRecRef, OSynchUserSetup."Synch. Entity Code")
                else begin
                    Evaluate(RecID, Format(TempRecRef.RecordId));
                    if CheckTimeCondition(RecID, SynchStartTime) then begin
                        TempRecRef1.Open(OSynchEntity."Table No.", true);
                        CopyRecordReference(TempRecRef, TempRecRef1, false);
                        ProcessEntityRecords(TempRecRef1, OSynchUserSetup."Synch. Entity Code");
                        TempRecRef1.Close;
                    end;
                end;
            until TempRecRef.Next = 0;

        if not SynchronizeAll then
            if TempDeletedChangeLogEntry.Find('-') then
                ProcessDeletedEntityRecords(TempDeletedChangeLogEntry);

        TempDeletedChangeLogEntry.Reset();
        TempDeletedChangeLogEntry.DeleteAll();
        TempRecRef.Close;
    end;

    local procedure CollectEntityElementChanges(SynchronizeAll: Boolean; SynchStartTime: DateTime)
    var
        TempDeletedChangeLogEntry: Record "Change Log Entry" temporary;
        TempRecRef: RecordRef;
    begin
        if SynchronizeAll then
            exit;

        OSynchSetupDetail.Reset();
        OSynchSetupDetail.SetRange("User ID", OSynchUserSetup."User ID");
        OSynchSetupDetail.SetRange("Synch. Entity Code", OSynchUserSetup."Synch. Entity Code");
        if OSynchSetupDetail.Find('-') then
            repeat
                OSynchEntityElement.Get(OSynchSetupDetail."Synch. Entity Code", OSynchSetupDetail."Element No.");
                TempRecRef.Open(OSynchEntityElement."Table No.", true);
                ProcessChangeLog(
                  OSynchEntityElement."Table No.",
                  OSynchUserSetup."Last Synch. Time",
                  TempRecRef,
                  TempDeletedChangeLogEntry);

                if TempRecRef.Find('-') then
                    ProcessEntityElements(TempRecRef, SynchStartTime);
                if TempDeletedChangeLogEntry.Find('-') then
                    ProcessDeletedEntityElements(TempDeletedChangeLogEntry, SynchStartTime);

                TempRecRef.Close;
                TempDeletedChangeLogEntry.DeleteAll();
            until OSynchSetupDetail.Next = 0;
    end;

    local procedure ProcessEntityRecords(var EntityRecRefIn: RecordRef; SynchEntityCode: Code[10])
    var
        OSynchEntity1: Record "Outlook Synch. Entity";
        OSynchEntityElement1: Record "Outlook Synch. Entity Element";
        OSynchField1: Record "Outlook Synch. Field";
        OSynchFilter1: Record "Outlook Synch. Filter";
        OSynchUserSetup1: Record "Outlook Synch. User Setup";
        OSynchSetupDetail1: Record "Outlook Synch. Setup Detail";
        OSynchDependency1: Record "Outlook Synch. Dependency";
        EntityRecRef: RecordRef;
        EntityRecRefDependent: RecordRef;
        CollectionRecRef: RecordRef;
        CollectionRecRef1: RecordRef;
        NullRecRef: RecordRef;
        RecID: RecordID;
    begin
        if not EntityRecRefIn.Find('-') then
            exit;

        Evaluate(RecID, Format(EntityRecRefIn.RecordId));
        EntityRecRef.Open(RecID.TableNo, true);
        repeat
            CopyRecordReference(EntityRecRefIn, EntityRecRef, false);
        until EntityRecRefIn.Next = 0;

        OSynchEntity1.Get(SynchEntityCode);
        OSynchFilter1.Reset();
        OSynchFilter1.SetRange("Record GUID", OSynchEntity1."Record GUID");
        EntityRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, NullRecRef));
        if not EntityRecRef.Find('-') then
            exit;

        OSynchField1.Reset();
        OSynchField1.SetRange("Synch. Entity Code", SynchEntityCode);
        OSynchField1.SetFilter("Read-Only Status", '<>%1', OSynchField1."Read-Only Status"::"Read-Only in Outlook");
        OSynchField1.SetFilter("Outlook Property", '<>%1', '');
        if OSynchField1.IsEmpty then
            exit;

        OSynchUserSetup1.Get(OSynchUserSetup."User ID", SynchEntityCode);
        OSynchUserSetup1.CalcFields("No. of Elements");

        repeat
            GlobalRecordIDBuffer.SetRange("Search Record ID", UpperCase(Format(EntityRecRef.RecordId)));
            if not GlobalRecordIDBuffer.FindFirst then begin
                if OSynchUserSetup1."No. of Elements" > 0 then begin
                    OSynchSetupDetail1.Reset();
                    OSynchSetupDetail1.SetRange("User ID", OSynchUserSetup."User ID");
                    OSynchSetupDetail1.SetRange("Synch. Entity Code", SynchEntityCode);
                    if OSynchSetupDetail1.Find('-') then
                        repeat
                            OSynchEntityElement1.Get(OSynchSetupDetail1."Synch. Entity Code", OSynchSetupDetail1."Element No.");
                            OSynchEntityElement1.CalcFields("No. of Dependencies");
                            if OSynchEntityElement1."No. of Dependencies" > 0 then begin
                                OSynchDependency1.Reset();
                                OSynchDependency1.SetRange("Synch. Entity Code", OSynchEntityElement1."Synch. Entity Code");
                                OSynchDependency1.SetRange("Element No.", OSynchEntityElement1."Element No.");

                                OSynchFilter1.Reset();
                                OSynchFilter1.SetRange("Record GUID", OSynchEntityElement1."Record GUID");

                                CollectionRecRef.Open(OSynchEntityElement1."Table No.");
                                CollectionRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, EntityRecRef));
                                if CollectionRecRef.Find('-') then
                                    repeat
                                        GlobalRecordIDBuffer.SetRange("Search Record ID", UpperCase(Format(CollectionRecRef.RecordId)));
                                        if not GlobalRecordIDBuffer.FindFirst then begin
                                            if OSynchDependency1.Find('-') then
                                                repeat
                                                    CollectionRecRef1.Open(OSynchEntityElement1."Table No.", true);
                                                    CopyRecordReference(CollectionRecRef, CollectionRecRef1, false);

                                                    OSynchFilter1.Reset();
                                                    OSynchFilter1.SetRange("Record GUID", OSynchDependency1."Record GUID");

                                                    if OSynchDependency1.Condition <> '' then begin
                                                        OSynchFilter1.SetRange("Filter Type", OSynchFilter1."Filter Type"::Condition);
                                                        CollectionRecRef1.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, NullRecRef));
                                                    end;

                                                    if CollectionRecRef1.Find('-') then begin
                                                        OSynchFilter1.SetRange("Filter Type", OSynchFilter1."Filter Type"::"Table Relation");
                                                        OSynchDependency1.CalcFields("Depend. Synch. Entity Tab. No.");

                                                        EntityRecRefDependent.Open(OSynchDependency1."Depend. Synch. Entity Tab. No.");
                                                        EntityRecRefDependent.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, CollectionRecRef1));
                                                        if EntityRecRefDependent.Find('-') then
                                                            ProcessEntityRecords(EntityRecRefDependent, OSynchDependency1."Depend. Synch. Entity Code");
                                                        EntityRecRefDependent.Close;
                                                    end;
                                                    CollectionRecRef1.Close;
                                                until OSynchDependency1.Next = 0;
                                        end;
                                    until CollectionRecRef.Next = 0;
                                CollectionRecRef.Close;
                            end;
                        until OSynchSetupDetail1.Next = 0;
                end;

                InsertEntity(EntityRecRef, SynchEntityCode);
                Evaluate(RecID, Format(EntityRecRef.RecordId));
                UpdateGlobalRecordIDBuffer(RecID, SynchEntityCode);
            end else
                if GlobalRecordIDBuffer."User ID" <> SynchEntityCode then
                    Error(Text005, GlobalRecordIDBuffer."User ID", SynchEntityCode);
        until EntityRecRef.Next = 0;
        EntityRecRef.Close;
    end;

    local procedure ProcessDeletedEntityRecords(var TempDeletedChangeLogEntry: Record "Change Log Entry")
    var
        RecID: RecordID;
    begin
        if not TempDeletedChangeLogEntry.Find('-') then
            exit;

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", OSynchEntity.Code);
        OSynchField.SetFilter("Read-Only Status", '<>%1', OSynchField."Read-Only Status"::"Read-Only in Outlook");
        OSynchField.SetFilter("Outlook Property", '<>%1', '');
        if not OSynchField.Find('-') then
            exit;

        OSynchFilter.Reset();
        OSynchFilter.SetFilter("Record GUID", '%1|%2', OSynchEntity."Record GUID", OSynchUserSetup."Record GUID");

        repeat
            if CheckDeletedRecFilterCondition(TempDeletedChangeLogEntry, OSynchFilter) then begin
                ObtainRecordID(TempDeletedChangeLogEntry, RecID);
                GlobalRecordIDBuffer.SetRange("Search Record ID", UpperCase(Format(RecID)));
                if not GlobalRecordIDBuffer.FindFirst then begin
                    if OSynchLink.Get(OSynchUserSetup."User ID", RecID) then begin
                        XMLWriter.WriteStartElement('DeletedOutlookItem');
                        XMLWriter.WriteAttribute('SynchEntityCode', OSynchEntity.Code);
                        XMLWriter.WriteAttribute('RecordID', Format(RecID));
                        XMLWriter.WriteAttribute(
                          'LastModificationTime',
                          OSynchTypeConversion.SetDateTimeFormat(
                            OSynchTypeConversion.LocalDT2UTC(TempDeletedChangeLogEntry."Date and Time")));
                        WriteLinkedOutlookEntryID(OSynchUserSetup."User ID", RecID, XMLWriter);
                        XMLWriter.WriteEndElement;

                        UpdateGlobalRecordIDBuffer(RecID, OSynchEntity.Code);
                    end;
                end else
                    if GlobalRecordIDBuffer."User ID" <> OSynchEntity.Code then
                        Error(Text005, GlobalRecordIDBuffer."User ID", OSynchEntity.Code);
            end;
        until TempDeletedChangeLogEntry.Next = 0;
    end;

    local procedure ProcessEntityElements(var ChangedCollectionRecRef: RecordRef; SynchStartTime: DateTime)
    var
        OSynchFilter1: Record "Outlook Synch. Filter";
        TempOSynchFilter: Record "Outlook Synch. Filter" temporary;
        OSynchUserSetup1: Record "Outlook Synch. User Setup";
        ChangedCollectionRecRef1: RecordRef;
        EntityRecRef: RecordRef;
        TempEntityRecRef: RecordRef;
        TempEntityRecRef1: RecordRef;
        NullRecRef: RecordRef;
        EntityRecID: RecordID;
        CollectionElementRecID: RecordID;
    begin
        if not ChangedCollectionRecRef.Find('-') then
            exit;

        EntityRecRef.Open(OSynchEntity."Table No.");
        repeat
            OSynchFilter.Reset();
            OSynchFilter.SetRange("Record GUID", OSynchEntityElement."Record GUID");

            TempOSynchFilter.Reset();
            TempOSynchFilter.DeleteAll();

            ChangedCollectionRecRef1.Open(OSynchEntityElement."Table No.", true);
            CopyRecordReference(ChangedCollectionRecRef, ChangedCollectionRecRef1, false);

            OSynchFilter.SetFilter(Type, '<>%1', OSynchFilter.Type::FIELD);
            if OSynchFilter.FindFirst then
                ChangedCollectionRecRef1.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, NullRecRef));

            if ChangedCollectionRecRef1.Find('-') then begin
                OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                if OSynchFilter.FindFirst then begin
                    OSynchSetupMgt.ComposeFilterRecords(OSynchFilter, TempOSynchFilter, ChangedCollectionRecRef1, TempOSynchFilter.Type::CONST);

                    EntityRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(TempOSynchFilter, NullRecRef));
                    if EntityRecRef.Find('-') then begin
                        TempEntityRecRef.Open(OSynchEntity."Table No.", true);
                        repeat
                            CopyRecordReference(EntityRecRef, TempEntityRecRef, false);
                        until EntityRecRef.Next = 0;

                        OSynchUserSetup1.Get(OSynchUserSetup."User ID", OSynchEntityElement."Synch. Entity Code");
                        OSynchFilter1.Reset();
                        OSynchFilter1.SetRange("Record GUID", OSynchUserSetup1."Record GUID");
                        if OSynchFilter1.FindFirst then
                            TempEntityRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, NullRecRef));

                        if TempEntityRecRef.Find('-') then
                            repeat
                                Evaluate(EntityRecID, Format(TempEntityRecRef.RecordId));
                                Evaluate(CollectionElementRecID, Format(ChangedCollectionRecRef1.RecordId));
                                if CheckCollectionTimeCondition(EntityRecID, CollectionElementRecID, SynchStartTime) then begin
                                    TempEntityRecRef1.Open(OSynchEntity."Table No.", true);
                                    CopyRecordReference(TempEntityRecRef, TempEntityRecRef1, false);
                                    ProcessEntityRecords(TempEntityRecRef1, OSynchEntityElement."Synch. Entity Code");
                                    TempEntityRecRef1.Close;
                                end;
                            until TempEntityRecRef.Next = 0;

                        TempEntityRecRef.Close;
                    end;
                end;
            end;
            ChangedCollectionRecRef1.Close;
        until ChangedCollectionRecRef.Next = 0;
        EntityRecRef.Close;
    end;

    local procedure ProcessDeletedEntityElements(var TempDeletedChangeLogEntry: Record "Change Log Entry"; SynchStartTime: DateTime)
    var
        ChangeLogEntry: Record "Change Log Entry";
        OSynchFilter1: Record "Outlook Synch. Filter";
        TempOSynchFilter: Record "Outlook Synch. Filter" temporary;
        EntityRecRef: RecordRef;
        TempEntityRecRef: RecordRef;
        NullRecRef: RecordRef;
        RecID: RecordID;
    begin
        if not TempDeletedChangeLogEntry.Find('-') then
            exit;

        EntityRecRef.Open(OSynchEntity."Table No.");

        OSynchFilter1.Reset();
        OSynchFilter1.SetRange("Record GUID", OSynchEntityElement."Record GUID");
        if not OSynchFilter1.FindFirst then
            exit;

        ChangeLogEntry.SetCurrentKey("Table No.", "Primary Key Field 1 Value");
        ChangeLogEntry.SetRange("Table No.", TempDeletedChangeLogEntry."Table No.");
        ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchUserSetup."Last Synch. Time");
        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Deletion);

        repeat
            OSynchFilter1.SetFilter(Type, '<>%1', OSynchFilter1.Type::FIELD);

            if CheckDeletedRecFilterCondition(TempDeletedChangeLogEntry, OSynchFilter1) then begin
                TempOSynchFilter.Reset();
                TempOSynchFilter.DeleteAll();
                OSynchFilter1.SetRange(Type, OSynchFilter1.Type::FIELD);

                if OSynchFilter1.Find('-') then
                    repeat
                        ChangeLogEntry.SetRange("Primary Key", TempDeletedChangeLogEntry."Primary Key");
                        ChangeLogEntry.SetRange("Primary Key Field 1 Value", TempDeletedChangeLogEntry."Primary Key Field 1 Value");
                        ChangeLogEntry.SetRange("Field No.", OSynchFilter1."Field No.");

                        if ChangeLogEntry.FindLast then
                            OSynchSetupMgt.CreateFilterCondition(
                              TempOSynchFilter,
                              OSynchFilter1."Master Table No.",
                              OSynchFilter1."Master Table Field No.",
                              TempOSynchFilter.Type::CONST,
                              ChangeLogEntry."Old Value");
                    until OSynchFilter1.Next = 0;

                EntityRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(TempOSynchFilter, NullRecRef));
                if EntityRecRef.Find('-') then
                    repeat
                        Evaluate(RecID, Format(EntityRecRef.RecordId));
                        if OSynchLink.Get(OSynchUserSetup."User ID", RecID) then begin
                            TempEntityRecRef.Open(OSynchEntity."Table No.", true);
                            CopyRecordReference(EntityRecRef, TempEntityRecRef, false);
                            if OSynchLink."Synchronization Date" < TempDeletedChangeLogEntry."Date and Time" then
                                ProcessEntityRecords(TempEntityRecRef, OSynchEntityElement."Synch. Entity Code")
                            else
                                if SynchStartTime < TempDeletedChangeLogEntry."Date and Time" then
                                    ProcessEntityRecords(TempEntityRecRef, OSynchEntityElement."Synch. Entity Code");
                            TempEntityRecRef.Close;
                        end;
                    until EntityRecRef.Next = 0;
            end;
        until TempDeletedChangeLogEntry.Next = 0;
        EntityRecRef.Close;
    end;

    local procedure ProcessChangeLog(TableID: Integer; LastSynchTime: DateTime; var TempRecRef: RecordRef; var DeletedChangeLogEntry: Record "Change Log Entry")
    var
        ChangeLogEntry: Record "Change Log Entry";
        InsModChangeLogEntry: Record "Change Log Entry" temporary;
    begin
        ChangeLogEntry.SetCurrentKey("Table No.", "Date and Time");
        ChangeLogEntry.SetRange("Table No.", TableID);
        ChangeLogEntry.SetFilter("Date and Time", '>=%1', LastSynchTime);

        RemoveChangeLogDuplicates(ChangeLogEntry, InsModChangeLogEntry);

        InsModChangeLogEntry.SetRange("Type of Change", InsModChangeLogEntry."Type of Change"::Deletion);
        if InsModChangeLogEntry.Find('-') then
            repeat
                DeletedChangeLogEntry.Init();
                DeletedChangeLogEntry := InsModChangeLogEntry;
                DeletedChangeLogEntry.Insert();
            until InsModChangeLogEntry.Next = 0;

        InsModChangeLogEntry.DeleteAll();
        InsModChangeLogEntry.Reset();

        FindMasterRecByChangeLogEntry(InsModChangeLogEntry, TempRecRef);
    end;

    local procedure ProcessDependentEntity(OSynchEntityCode: Code[10]; var I: Integer; var TempOSynchEntityUnsorted: Record "Outlook Synch. Entity"; var TempOSynchLookupName: Record "Outlook Synch. Lookup Name")
    var
        OSynchDependency: Record "Outlook Synch. Dependency";
    begin
        OSynchDependency.SetRange("Synch. Entity Code", OSynchEntityCode);

        if OSynchDependency.Find('-') then
            repeat
                if not (TempOSynchEntityUnsorted.Get(OSynchDependency."Depend. Synch. Entity Code") and
                        TempOSynchEntityUnsorted.Mark)
                then
                    ProcessDependentEntity(
                      OSynchDependency."Depend. Synch. Entity Code",
                      I,
                      TempOSynchEntityUnsorted,
                      TempOSynchLookupName);
            until OSynchDependency.Next = 0;

        if TempOSynchEntityUnsorted.Get(OSynchEntityCode) then
            if not TempOSynchEntityUnsorted.Mark then begin
                TempOSynchLookupName.Init();
                TempOSynchLookupName."Entry No." := I;
                TempOSynchLookupName.Name := TempOSynchEntityUnsorted.Code;
                TempOSynchLookupName.Insert();
                TempOSynchEntityUnsorted.Mark(true);
                I := I + 1;
            end;
    end;

    procedure ProcessRenamedRecords(UserID: Code[50])
    var
        ChangeLogEntry: Record "Change Log Entry";
        TempChangeLogEntry: Record "Change Log Entry" temporary;
        TempChangeLogEntry1: Record "Change Log Entry" temporary;
        OSynchLink: Record "Outlook Synch. Link";
        TempRecRef: RecordRef;
        TempMasterRecRef: RecordRef;
        EntityKeyRef: KeyRef;
        EntityFieldRef: FieldRef;
        RecID: RecordID;
        Counter: Integer;
        KeyString: Text[250];
        IsRenamed: Boolean;
    begin
        if not SortedEntitiesBuffer.Find('-') then
            exit;

        repeat
            OSynchEntity.Get(SortedEntitiesBuffer.Name);
            OSynchUserSetup.Get(UserID, SortedEntitiesBuffer.Name);

            TempRecRef.Open(OSynchEntity."Table No.", true);
            EntityKeyRef := TempRecRef.KeyIndex(1);
            for Counter := 1 to EntityKeyRef.FieldCount do begin
                if KeyString <> '' then
                    KeyString := KeyString + '|';
                EntityFieldRef := EntityKeyRef.FieldIndex(Counter);
                KeyString := KeyString + Format(EntityFieldRef.Number);
            end;
            TempRecRef.Close;

            ChangeLogEntry.SetCurrentKey("Table No.", "Date and Time");
            ChangeLogEntry.SetRange("Table No.", OSynchEntity."Table No.");
            ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchUserSetup."Last Synch. Time");
            ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Modification);
            ChangeLogEntry.SetFilter("Field No.", KeyString);
            if ChangeLogEntry.Find('-') then begin
                TempChangeLogEntry.Reset();
                TempChangeLogEntry.DeleteAll();
                TempChangeLogEntry1.Reset();
                TempChangeLogEntry1.DeleteAll();

                repeat
                    TempChangeLogEntry.Init();
                    TempChangeLogEntry := ChangeLogEntry;
                    TempChangeLogEntry.Insert();
                until ChangeLogEntry.Next = 0;

                RemoveChangeLogDuplicates(TempChangeLogEntry, TempChangeLogEntry1);

                if TempChangeLogEntry1.Find('-') then
                    repeat
                        TempChangeLogEntry.Reset();
                        TempChangeLogEntry.SetRange("Primary Key Field 1 Value", TempChangeLogEntry1."Primary Key Field 1 Value");
                        if TempChangeLogEntry1."Primary Key Field 2 No." <> 0 then
                            TempChangeLogEntry.SetRange("Primary Key Field 2 Value", TempChangeLogEntry1."Primary Key Field 2 Value");
                        if TempChangeLogEntry1."Primary Key Field 3 No." <> 0 then
                            TempChangeLogEntry.SetRange("Primary Key Field 3 Value", TempChangeLogEntry1."Primary Key Field 3 Value");

                        ObtainRenamedRecordID(
                          TempChangeLogEntry,
                          TempChangeLogEntry1."Primary Key Field 1 No.",
                          TempChangeLogEntry1."Primary Key Field 2 No.",
                          TempChangeLogEntry1."Primary Key Field 3 No.",
                          RecID);

                        if RecID.TableNo <> 0 then
                            if OSynchLink.Get(OSynchUserSetup."User ID", RecID) then begin
                                TempMasterRecRef.Open(TempChangeLogEntry1."Table No.", true);
                                FindMasterRecByChangeLogEntry(TempChangeLogEntry1, TempMasterRecRef);

                                if Format(RecID) <> Format(TempMasterRecRef.RecordId) then begin
                                    Evaluate(RecID, Format(TempMasterRecRef.RecordId));
                                    OSynchLink.Rename(OSynchUserSetup."User ID", RecID);
                                    IsRenamed := true;
                                end;

                                TempMasterRecRef.Close;
                            end;
                    until TempChangeLogEntry1.Next = 0;
            end;
        until SortedEntitiesBuffer.Next = 0;

        if IsRenamed then
            Commit();
    end;

    procedure ProcessDeletedRecords(UserID: Code[50])
    var
        ChangeLogEntry: Record "Change Log Entry";
        TempChangeLogEntry: Record "Change Log Entry" temporary;
        OSynchLink: Record "Outlook Synch. Link";
        RecID: RecordID;
    begin
        if not SortedEntitiesBuffer.Find('-') then
            exit;

        repeat
            OSynchEntity.Get(SortedEntitiesBuffer.Name);
            OSynchUserSetup.Get(UserID, SortedEntitiesBuffer.Name);

            ChangeLogEntry.SetCurrentKey("Table No.", "Date and Time");
            ChangeLogEntry.SetRange("Table No.", OSynchEntity."Table No.");
            ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchUserSetup."Last Synch. Time");
            ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Deletion);
            if not ChangeLogEntry.IsEmpty then begin
                TempChangeLogEntry.Reset();
                TempChangeLogEntry.DeleteAll();

                RemoveChangeLogDuplicates(ChangeLogEntry, TempChangeLogEntry);

                if TempChangeLogEntry.Find('-') then
                    repeat
                        ObtainRecordID(TempChangeLogEntry, RecID);
                        if OSynchLink.Get(OSynchUserSetup."User ID", RecID) then
                            OSynchLink.Delete();
                    until TempChangeLogEntry.Next = 0;
            end;
        until SortedEntitiesBuffer.Next = 0;

        OSynchLink.Reset();
        OSynchLink.SetRange("User ID", OSynchUserSetup."User ID");
        OSynchLink.SetRange("Outlook Entry ID Hash", '');
        OSynchLink.DeleteAll();
    end;

    local procedure InsertEntity(EntityRecRef: RecordRef; SynchEntityCode: Code[10])
    var
        RecID: RecordID;
        LastModificationTime: DateTime;
    begin
        Evaluate(RecID, Format(EntityRecRef.RecordId));
        LastModificationTime := OSynchOutlookMgt.GetLastModificationTime(RecID);

        XMLWriter.WriteStartElement('OutlookItem');
        XMLWriter.WriteAttribute('SynchEntityCode', SynchEntityCode);
        XMLWriter.WriteAttribute('RecordID', Format(RecID));
        XMLWriter.WriteAttribute(
          'LastModificationTime',
          OSynchTypeConversion.SetDateTimeFormat(OSynchTypeConversion.LocalDT2UTC(LastModificationTime)));
        WriteLinkedOutlookEntryID(OSynchUserSetup."User ID", RecID, XMLWriter);

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", SynchEntityCode);
        OSynchField.SetFilter("Read-Only Status", '<>%1', OSynchField."Read-Only Status"::"Read-Only in Outlook");
        OSynchField.SetFilter("Outlook Property", '<>%1', '');
        OSynchField.SetRange("Element No.", 0);

        if OSynchField.Find('-') then
            InsertFields(EntityRecRef, false);

        OSynchUserSetup.CalcFields("No. of Elements");
        if OSynchUserSetup."No. of Elements" > 0 then
            InsertCollections(EntityRecRef, SynchEntityCode);

        XMLWriter.WriteEndElement;
    end;

    local procedure InsertCollections(EntityRecRef: RecordRef; SynchEntityCode: Code[10])
    var
        OSynchEntityElement1: Record "Outlook Synch. Entity Element";
        MasterRecRef: RecordRef;
        EntityRecID: RecordID;
        DependencyFound: Boolean;
    begin
        OSynchSetupDetail.Reset();
        OSynchSetupDetail.SetRange("User ID", OSynchUserSetup."User ID");
        OSynchSetupDetail.SetRange("Synch. Entity Code", SynchEntityCode);

        if OSynchSetupDetail.Find('-') then
            repeat
                OSynchEntityElement1.Get(OSynchSetupDetail."Synch. Entity Code", OSynchSetupDetail."Element No.");
                XMLWriter.WriteStartElement('Collection');
                XMLWriter.WriteAttribute('Name', OSynchEntityElement1."Outlook Collection");

                OSynchFilter.Reset();
                OSynchFilter.SetRange("Record GUID", OSynchEntityElement1."Record GUID");
                MasterRecRef.Open(OSynchEntityElement1."Table No.");
                MasterRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, EntityRecRef));
                if MasterRecRef.Find('-') then
                    repeat
                        Clear(EntityRecID);
                        DependencyFound := false;

                        OSynchEntityElement1.CalcFields("No. of Dependencies");
                        if OSynchEntityElement1."No. of Dependencies" = 0 then begin
                            XMLWriter.WriteStartElement('Element');
                            XMLWriter.WriteAttribute('RecordID', Format(MasterRecRef.RecordId));
                            DependencyFound := true;
                        end else begin
                            DependencyFound := FindDependentRecord(OSynchEntityElement1, MasterRecRef, EntityRecID);
                            if DependencyFound then begin
                                XMLWriter.WriteStartElement('Element');
                                XMLWriter.WriteAttribute('RecordID', Format(EntityRecID));
                                WriteLinkedOutlookEntryID(OSynchUserSetup."User ID", EntityRecID, XMLWriter);
                            end;
                        end;

                        if DependencyFound then begin
                            OSynchField.Reset();
                            OSynchField.SetRange("Synch. Entity Code", SynchEntityCode);
                            OSynchField.SetFilter("Read-Only Status", '<>%1', OSynchField."Read-Only Status"::"Read-Only in Outlook");
                            OSynchField.SetFilter("Outlook Property", '<>%1', '');
                            OSynchField.SetRange("Element No.", OSynchEntityElement1."Element No.");
                            OSynchField.SetRange("Search Field", false);
                            if OSynchField.Find('-') then
                                InsertFields(MasterRecRef, false);

                            OSynchField.SetRange("Read-Only Status");
                            OSynchField.SetRange("Search Field", true);
                            if OSynchField.Find('-') then
                                InsertFields(MasterRecRef, true);

                            XMLWriter.WriteEndElement;
                        end;
                    until MasterRecRef.Next = 0;
                XMLWriter.WriteEndElement;
                MasterRecRef.Close;
            until OSynchSetupDetail.Next = 0;
    end;

    local procedure InsertFields(SynchRecRef: RecordRef; SearchFields: Boolean)
    var
        OSynchField1: Record "Outlook Synch. Field";
        TempOSynchField: Record "Outlook Synch. Field" temporary;
        OSynchOptionCorrel: Record "Outlook Synch. Option Correl.";
        TempBlob: Codeunit "Temp Blob";
        RelatedRecRef: RecordRef;
        DateTimeRecRef: RecordRef;
        FieldRef: FieldRef;
        DateTimeFieldRef: FieldRef;
        InStrm: InStream;
        TempDateTime: DateTime;
        TempDate: Date;
        TempTime: Time;
        OptionId: Integer;
        FieldValueDefined: Boolean;
    begin
        repeat
            if not SearchFields then begin
                TempOSynchField.Reset();
                TempOSynchField.SetRange("Synch. Entity Code", OSynchField."Synch. Entity Code");
                TempOSynchField.SetRange("Element No.", OSynchField."Element No.");
                TempOSynchField.SetRange("Outlook Property", OSynchField."Outlook Property");
                if not TempOSynchField.Find('-') then begin
                    TempOSynchField.Init();
                    TempOSynchField := OSynchField;
                    TempOSynchField.Insert();
                end;
            end else begin
                TempOSynchField.Init();
                TempOSynchField := OSynchField;
                TempOSynchField.Insert();
            end;
        until OSynchField.Next = 0;

        TempOSynchField.Reset();
        if TempOSynchField.Find('-') then
            repeat
                if CheckSynchFieldCondition(SynchRecRef, TempOSynchField) then begin
                    FieldValueDefined := true;
                    if TempOSynchField."Table No." <> 0 then begin
                        OSynchFilter.Reset();
                        OSynchFilter.SetRange("Record GUID", TempOSynchField."Record GUID");
                        OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");

                        RelatedRecRef.Open(TempOSynchField."Table No.");
                        RelatedRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, SynchRecRef));
                        FieldValueDefined := RelatedRecRef.FindFirst;
                        if FieldValueDefined then
                            FieldRef := RelatedRecRef.Field(TempOSynchField."Field No.");
                    end else
                        FieldRef := SynchRecRef.Field(TempOSynchField."Field No.");

                    XMLWriter.WriteStartElement('Field');
                    XMLWriter.WriteAttribute('Name', TempOSynchField."Outlook Property");

                    if FieldValueDefined then
                        case FieldRef.Type of
                            FieldType::Time:
                                begin
                                    TempDate := 45010101D;
                                    if not Evaluate(TempTime, Format(FieldRef.Value)) then
                                        TempTime := 000000T;
                                    OSynchField1.Reset();
                                    OSynchField1.SetRange("Synch. Entity Code", TempOSynchField."Synch. Entity Code");
                                    OSynchField1.SetRange("Element No.", TempOSynchField."Element No.");
                                    OSynchField1.SetFilter("Line No.", '<>%1', TempOSynchField."Line No.");
                                    OSynchField1.SetRange("Outlook Property", TempOSynchField."Outlook Property");
                                    if OSynchField1.Find('-') then
                                        repeat
                                            GetDateTimeFieldRef(OSynchField1, TempOSynchField, SynchRecRef, RelatedRecRef, DateTimeFieldRef);
                                            if (DateTimeFieldRef.Type = FieldType::Date) and (Format(DateTimeFieldRef.Value) <> '') then
                                                if Evaluate(TempDate, Format(DateTimeFieldRef.Value)) then;
                                            DateTimeRecRef.Close;
                                        until OSynchField1.Next = 0;

                                    if OSynchTypeConversion.RunningUTC then
                                        TempDateTime := OSynchTypeConversion.LocalDT2UTC(CreateDateTime(TempDate, TempTime))
                                    else
                                        TempDateTime := CreateDateTime(TempDate, TempTime);
                                    if TempDate = 45010101D then
                                        TempDateTime := CreateDateTime(TempDate, DT2Time(TempDateTime));
                                    XMLWriter.WriteElementTextContent(OSynchTypeConversion.SetDateTimeFormat(TempDateTime));
                                end;
                            FieldType::Date:
                                begin
                                    TempTime := 000000T;
                                    if not Evaluate(TempDate, Format(FieldRef.Value)) or (TempDate = 0D) then
                                        TempDate := 45010101D;
                                    OSynchField1.Reset();
                                    OSynchField1.SetRange("Synch. Entity Code", TempOSynchField."Synch. Entity Code");
                                    OSynchField1.SetRange("Element No.", TempOSynchField."Element No.");
                                    OSynchField1.SetFilter("Line No.", '<>%1', TempOSynchField."Line No.");
                                    OSynchField1.SetRange("Outlook Property", TempOSynchField."Outlook Property");
                                    if OSynchField1.Find('-') then
                                        repeat
                                            GetDateTimeFieldRef(OSynchField1, TempOSynchField, SynchRecRef, RelatedRecRef, DateTimeFieldRef);
                                            if (DateTimeFieldRef.Type = FieldType::Time) and (Format(DateTimeFieldRef.Value) <> '') then
                                                if Evaluate(TempTime, Format(DateTimeFieldRef.Value)) then;
                                            DateTimeRecRef.Close;
                                        until OSynchField1.Next = 0;

                                    if OSynchTypeConversion.RunningUTC then
                                        TempDateTime := OSynchTypeConversion.LocalDT2UTC(CreateDateTime(TempDate, TempTime))
                                    else
                                        TempDateTime := CreateDateTime(TempDate, TempTime);
                                    if TempDate = 45010101D then
                                        TempDateTime := CreateDateTime(TempDate, DT2Time(TempDateTime));
                                    XMLWriter.WriteElementTextContent(OSynchTypeConversion.SetDateTimeFormat(TempDateTime));
                                end;
                            FieldType::BLOB:
                                begin
                                    Clear(InStrm);
                                    TempBlob.FromRecordRef(FieldRef.Record, FieldRef.Number);
                                    if TempBlob.HasValue then begin
                                        TempBlob.CreateInStream(InStrm);
                                        XMLWriter.WriteStreamData(InStrm);
                                    end;
                                end;
                            FieldType::Option:
                                begin
                                    OSynchOptionCorrel.Reset();
                                    OSynchOptionCorrel.SetRange("Synch. Entity Code", TempOSynchField."Synch. Entity Code");
                                    OSynchOptionCorrel.SetRange("Element No.", TempOSynchField."Element No.");
                                    OSynchOptionCorrel.SetRange("Field Line No.", TempOSynchField."Line No.");
                                    OptionId := OSynchTypeConversion.TextToOptionValue(Format(FieldRef.Value), FieldRef.OptionCaption);
                                    OSynchOptionCorrel.SetRange("Option No.", OptionId);
                                    if OSynchOptionCorrel.FindFirst then
                                        XMLWriter.WriteElementTextContent(Format(OSynchOptionCorrel."Enumeration No."))
                                    else
                                        if not OSynchSetupMgt.CheckOEnumeration(TempOSynchField) then
                                            XMLWriter.WriteElementTextContent(OSynchTypeConversion.PrepareFieldValueForXML(FieldRef))
                                        else begin
                                            if TempOSynchField."Element No." = 0 then
                                                Error(Text003, FieldRef.Caption, TempOSynchField."Synch. Entity Code");

                                            Error(Text009, FieldRef.Caption, TempOSynchField."Outlook Object", TempOSynchField."Synch. Entity Code");
                                        end;
                                end;
                            else
                                XMLWriter.WriteElementTextContent(OSynchTypeConversion.PrepareFieldValueForXML(FieldRef));
                        end;

                    XMLWriter.WriteEndElement;
                    RelatedRecRef.Close;
                end;
            until TempOSynchField.Next = 0;
    end;

    local procedure FindDependentRecord(OSynchEntityElement1: Record "Outlook Synch. Entity Element"; CollectionElementRecRef: RecordRef; var MasterRecID: RecordID): Boolean
    var
        OSynchEntity1: Record "Outlook Synch. Entity";
        OSynchFilter1: Record "Outlook Synch. Filter";
        OSynchDependency: Record "Outlook Synch. Dependency";
        EntityRecRef: RecordRef;
        TempEntityRecRef: RecordRef;
        TempCollectionElementRecRef: RecordRef;
        NullRecRef: RecordRef;
    begin
        TempCollectionElementRecRef.Open(OSynchEntityElement1."Table No.", true);
        CopyRecordReference(CollectionElementRecRef, TempCollectionElementRecRef, false);

        OSynchDependency.Reset();
        OSynchDependency.SetRange("Synch. Entity Code", OSynchEntityElement1."Synch. Entity Code");
        OSynchDependency.SetRange("Element No.", OSynchEntityElement1."Element No.");
        if OSynchDependency.Find('-') then
            repeat
                TempCollectionElementRecRef.Reset();
                OSynchFilter1.Reset();
                OSynchFilter1.SetRange("Record GUID", OSynchDependency."Record GUID");
                OSynchFilter1.SetRange("Filter Type", OSynchFilter1."Filter Type"::Condition);
                if OSynchFilter1.FindFirst then
                    TempCollectionElementRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, NullRecRef));

                if TempCollectionElementRecRef.Find('-') then begin
                    OSynchDependency.CalcFields("Depend. Synch. Entity Tab. No.");
                    OSynchFilter1.SetRange("Filter Type", OSynchFilter1."Filter Type"::"Table Relation");
                    if OSynchFilter1.FindFirst then begin
                        EntityRecRef.Open(OSynchDependency."Depend. Synch. Entity Tab. No.");
                        EntityRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, TempCollectionElementRecRef));
                        if EntityRecRef.Find('-') then begin
                            TempEntityRecRef.Open(OSynchDependency."Depend. Synch. Entity Tab. No.", true);
                            CopyRecordReference(EntityRecRef, TempEntityRecRef, false);
                            OSynchEntity1.Get(OSynchDependency."Depend. Synch. Entity Code");

                            OSynchFilter1.Reset();
                            OSynchFilter1.SetRange("Record GUID", OSynchEntity1."Record GUID");
                            TempEntityRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, NullRecRef));
                            if TempEntityRecRef.Find('-') then begin
                                Evaluate(MasterRecID, Format(TempEntityRecRef.RecordId));
                                exit(true);
                            end;
                            TempEntityRecRef.Close;
                        end;
                        EntityRecRef.Close;
                    end;
                end;
            until OSynchDependency.Next = 0;
        TempCollectionElementRecRef.Close;
    end;

    procedure CheckSynchFieldCondition(SynchRecRef: RecordRef; var OSynchField1: Record "Outlook Synch. Field"): Boolean
    var
        OSynchFilter1: Record "Outlook Synch. Filter";
        SynchRecRef1: RecordRef;
        NullRecRef: RecordRef;
        RecID: RecordID;
    begin
        if OSynchField1.Condition = '' then
            exit(true);

        Evaluate(RecID, Format(SynchRecRef.RecordId));
        SynchRecRef1.Open(RecID.TableNo, true);
        CopyRecordReference(SynchRecRef, SynchRecRef1, false);

        OSynchFilter1.Reset();
        OSynchFilter1.SetRange("Record GUID", OSynchField1."Record GUID");
        OSynchFilter1.SetRange("Filter Type", OSynchFilter1."Filter Type"::Condition);
        SynchRecRef1.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter1, NullRecRef));

        exit(not SynchRecRef1.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure CheckDeletedRecFilterCondition(var TempDeletedChangeLogEntry: Record "Change Log Entry"; var OSynchFilterIn: Record "Outlook Synch. Filter") IsMatched: Boolean
    var
        ChangeLogEntry: Record "Change Log Entry";
        TempRecRef: RecordRef;
        NullRecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        IsMatched := true;
        if not OSynchFilterIn.FindFirst then
            exit;

        ChangeLogEntry.SetCurrentKey("Table No.", "Primary Key Field 1 Value");
        ChangeLogEntry.SetRange("Table No.", TempDeletedChangeLogEntry."Table No.");
        ChangeLogEntry.SetRange("Primary Key Field 1 Value", TempDeletedChangeLogEntry."Primary Key Field 1 Value");
        ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchUserSetup."Last Synch. Time");
        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Deletion);
        ChangeLogEntry.SetRange("Primary Key", TempDeletedChangeLogEntry."Primary Key");

        TempRecRef.Open(TempDeletedChangeLogEntry."Table No.", true);
        TempRecRef.Init();

        if ChangeLogEntry.FindSet then
            repeat
                FieldRef := TempRecRef.Field(ChangeLogEntry."Field No.");
                if not
                   OSynchTypeConversion.EvaluateTextToFieldRef(
                     OSynchTypeConversion.SetValueFormat(ChangeLogEntry."Old Value", FieldRef),
                     FieldRef,
                     false)
                then
                    Error(Text010, OSynchEntity.Code, PRODUCTNAME.Full);
            until ChangeLogEntry.Next = 0;

        TempRecRef.Insert();

        TempRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilterIn, NullRecRef));
        IsMatched := TempRecRef.Find('-');
        TempRecRef.Close;
    end;

    procedure CheckTimeCondition(RecID: RecordID; SynchStartTime: DateTime): Boolean
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.SetCurrentKey("Table No.", "Primary Key Field 1 Value");
        OSynchProcessLine.FilterChangeLog(RecID, ChangeLogEntry);
        if ChangeLogEntry.FindLast then;

        OSynchLink.Reset();
        if OSynchLink.Get(OSynchUserSetup."User ID", RecID) then begin
            if (OSynchLink."Synchronization Date" >= ChangeLogEntry."Date and Time") and
               (OSynchLink."Synchronization Date" <= SynchStartTime)
            then
                exit(false);
            // Item was deleted during this synchronization so we should not return it.
            if (OSynchLink."Synchronization Date" >= SynchStartTime) and (OSynchLink."Outlook Entry ID Hash" = '') then
                exit(false);
        end;

        exit(true);
    end;

    procedure CheckCollectionTimeCondition(EntityRecID: RecordID; CollectionElementRecID: RecordID; SynchStartTime: DateTime): Boolean
    var
        ChangeLogEntry: Record "Change Log Entry";
        CollectionElementLMDT: DateTime;
    begin
        if CheckTimeCondition(EntityRecID, SynchStartTime) then
            exit(true);

        ChangeLogEntry.Reset();
        ChangeLogEntry.SetCurrentKey("Table No.", "Primary Key Field 1 Value");
        OSynchProcessLine.FilterChangeLog(CollectionElementRecID, ChangeLogEntry);
        if ChangeLogEntry.FindLast then
            CollectionElementLMDT := ChangeLogEntry."Date and Time";

        if OSynchLink.Get(OSynchUserSetup."User ID", EntityRecID) then
            if OSynchLink."Synchronization Date" < CollectionElementLMDT then
                exit(true)
            else
                if SynchStartTime < CollectionElementLMDT then
                    exit(true);
    end;

    local procedure SortEntitiesForXMLOutput(var TempOSynchEntityUnsorted: Record "Outlook Synch. Entity"; var TempOSynchLookupName: Record "Outlook Synch. Lookup Name")
    var
        OSynchDependency: Record "Outlook Synch. Dependency";
        LastIndex: Integer;
    begin
        TempOSynchLookupName.DeleteAll();

        if TempOSynchEntityUnsorted.Find('-') then begin
            OSynchDependency.Reset();
            if not OSynchDependency.IsEmpty then
                repeat
                    ProcessDependentEntity(
                      TempOSynchEntityUnsorted.Code,
                      LastIndex,
                      TempOSynchEntityUnsorted,
                      TempOSynchLookupName);
                until TempOSynchEntityUnsorted.Next = 0;

            if TempOSynchEntityUnsorted.Find('-') then
                repeat
                    if not TempOSynchEntityUnsorted.Mark then begin
                        TempOSynchLookupName.Init();
                        TempOSynchLookupName."Entry No." := LastIndex;
                        TempOSynchLookupName.Name := TempOSynchEntityUnsorted.Code;
                        TempOSynchLookupName.Insert();
                        LastIndex := LastIndex + 1;
                    end;
                until TempOSynchEntityUnsorted.Next = 0;
        end;
    end;

    local procedure ObtainRenamedRecordID(var ChangeLogEntry: Record "Change Log Entry"; PKField1No: Integer; PKField2No: Integer; PKField3No: Integer; var RecID: RecordID)
    var
        TempRecRef: RecordRef;
        ArrayFieldRef: array[3] of FieldRef;
    begin
        if not ChangeLogEntry.Find('-') then
            exit;

        TempRecRef.Open(ChangeLogEntry."Table No.", true);
        TempRecRef.Init();
        repeat
            case ChangeLogEntry."Field No." of
                ChangeLogEntry."Primary Key Field 1 No.":
                    begin
                        ArrayFieldRef[1] := TempRecRef.Field(PKField1No);
                        if not OSynchTypeConversion.EvaluateTextToFieldRef(ChangeLogEntry."Old Value", ArrayFieldRef[1], false) then
                            Error(Text001);
                    end;
                ChangeLogEntry."Primary Key Field 2 No.":
                    begin
                        ArrayFieldRef[2] := TempRecRef.Field(PKField2No);
                        if not OSynchTypeConversion.EvaluateTextToFieldRef(ChangeLogEntry."Old Value", ArrayFieldRef[2], false) then
                            Error(Text001);
                    end;
                ChangeLogEntry."Primary Key Field 3 No.":
                    begin
                        ArrayFieldRef[3] := TempRecRef.Field(PKField3No);
                        if not OSynchTypeConversion.EvaluateTextToFieldRef(ChangeLogEntry."Old Value", ArrayFieldRef[3], false) then
                            Error(Text001);
                    end;
            end;
        until ChangeLogEntry.Next = 0;
        TempRecRef.Insert();
        Evaluate(RecID, Format(TempRecRef.RecordId));
        TempRecRef.Close;
    end;

    [Scope('OnPrem')]
    procedure WriteLinkedOutlookEntryID(UserID: Code[50]; RecID: RecordID; var XMLTextWriter: DotNet "OLSync.Common.XmlTextWriter")
    var
        EntryIDContainer: Text;
    begin
        if not OSynchLink.Get(UserID, RecID) then
            exit;

        Clear(EntryIDContainer);
        if not OSynchLink.GetEntryID(EntryIDContainer) then
            exit;

        XMLTextWriter.WriteStartElement('EntryID');
        XMLTextWriter.WriteElementTextContent(Base64Convert.ToBase64(EntryIDContainer));
        XMLTextWriter.WriteEndElement;
    end;

    procedure RemoveChangeLogDuplicates(var ChangeLogEntry: Record "Change Log Entry"; var TempChangeLogEntry: Record "Change Log Entry")
    begin
        ChangeLogEntry.SetCurrentKey("Table No.", "Date and Time");
        ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchUserSetup."Last Synch. Time");
        TempChangeLogEntry.Reset();
        TempChangeLogEntry.DeleteAll();

        if ChangeLogEntry.Find('+') then
            repeat
                if ChangeLogEntry."Primary Key" <> TempChangeLogEntry."Primary Key" then begin
                    TempChangeLogEntry.SetRange("Primary Key", ChangeLogEntry."Primary Key");
                    if not TempChangeLogEntry.Find('-') then begin
                        TempChangeLogEntry.Init();
                        TempChangeLogEntry := ChangeLogEntry;
                        TempChangeLogEntry.Insert();
                    end;
                end;
            until ChangeLogEntry.Next(-1) = 0;

        TempChangeLogEntry.Reset();
    end;

    procedure ObtainRecordID(TempChangeLogEntry: Record "Change Log Entry"; var RecID: RecordID)
    var
        TempDeletedRecordRef: RecordRef;
        ArrayFieldRef: array[3] of FieldRef;
        KeyRef: KeyRef;
        I: Integer;
    begin
        TempDeletedRecordRef.Open(TempChangeLogEntry."Table No.", true);

        KeyRef := TempDeletedRecordRef.KeyIndex(1);
        for I := 1 to KeyRef.FieldCount do
            ArrayFieldRef[I] := KeyRef.FieldIndex(I);

        TempDeletedRecordRef.Init();

        if TempChangeLogEntry."Primary Key Field 1 No." > 0 then
            if TempChangeLogEntry."Primary Key Field 1 No." = ArrayFieldRef[1].Number then
                if not
                   OSynchTypeConversion.EvaluateTextToFieldRef(TempChangeLogEntry."Primary Key Field 1 Value", ArrayFieldRef[1], false)
                then
                    Error(Text001);

        if TempChangeLogEntry."Primary Key Field 2 No." > 0 then
            if TempChangeLogEntry."Primary Key Field 2 No." = ArrayFieldRef[2].Number then
                if not
                   OSynchTypeConversion.EvaluateTextToFieldRef(TempChangeLogEntry."Primary Key Field 2 Value", ArrayFieldRef[2], false)
                then
                    Error(Text001);

        if TempChangeLogEntry."Primary Key Field 3 No." > 0 then
            if TempChangeLogEntry."Primary Key Field 3 No." = ArrayFieldRef[3].Number then
                if not
                   OSynchTypeConversion.EvaluateTextToFieldRef(TempChangeLogEntry."Primary Key Field 3 Value", ArrayFieldRef[3], false)
                then
                    Error(Text001);

        TempDeletedRecordRef.Insert();

        Evaluate(RecID, Format(TempDeletedRecordRef.RecordId));
        TempDeletedRecordRef.Close;
    end;

    local procedure FindMasterRecByChangeLogEntry(var InsModChangeLogEntry: Record "Change Log Entry"; var TempRecRef: RecordRef)
    var
        MasterTableRef: RecordRef;
        RecID: RecordID;
    begin
        if not InsModChangeLogEntry.Find('-') then
            exit;

        MasterTableRef.Open(InsModChangeLogEntry."Table No.");

        repeat
            ObtainRecordID(InsModChangeLogEntry, RecID);
            if MasterTableRef.Get(RecID) then
                CopyRecordReference(MasterTableRef, TempRecRef, false);
        until InsModChangeLogEntry.Next = 0;

        MasterTableRef.Close;
    end;

    procedure CopyRecordReference(FromRec: RecordRef; var ToRec: RecordRef; ValidateOnInsert: Boolean)
    var
        FromField: FieldRef;
        ToField: FieldRef;
        Counter: Integer;
    begin
        if FromRec.Number <> ToRec.Number then
            exit;

        ToRec.Init();
        for Counter := 1 to FromRec.FieldCount do begin
            FromField := FromRec.FieldIndex(Counter);
            if not (FromField.Type in [FieldType::BLOB, FieldType::TableFilter]) then begin
                ToField := ToRec.Field(FromField.Number);
                ToField.Value := FromField.Value;
            end;
        end;
        ToRec.Insert(ValidateOnInsert);
    end;

    procedure GetSortedEntities(UserID: Code[50]; var EntitiesBuffer: Record "Outlook Synch. Lookup Name"; IsSchema: Boolean)
    var
        TempOSynchEntityUnsorted: Record "Outlook Synch. Entity" temporary;
    begin
        EntitiesBuffer.Reset();
        EntitiesBuffer.DeleteAll();

        OSynchUserSetup.Reset();
        OSynchUserSetup.SetRange("User ID", UserID);
        if not IsSchema then
            OSynchUserSetup.SetFilter("Synch. Direction", '<>%1', OSynchUserSetup."Synch. Direction"::"Outlook to Microsoft Dynamics NAV");

        if not OSynchUserSetup.Find('-') then
            exit;

        TempOSynchEntityUnsorted.Reset();
        TempOSynchEntityUnsorted.DeleteAll();

        repeat
            OSynchEntity.Get(OSynchUserSetup."Synch. Entity Code");
            TempOSynchEntityUnsorted.Init();
            TempOSynchEntityUnsorted := OSynchEntity;
            TempOSynchEntityUnsorted.Insert();
        until OSynchUserSetup.Next = 0;

        SortEntitiesForXMLOutput(TempOSynchEntityUnsorted, EntitiesBuffer);
    end;

    local procedure UpdateGlobalRecordIDBuffer(RecID: RecordID; SynchEntityCode: Code[10])
    begin
        GlobalRecordIDBuffer.SetRange("Search Record ID", UpperCase(Format(RecID)));
        if GlobalRecordIDBuffer.FindFirst then
            exit;

        GlobalRecordIDBuffer.Init();
        GlobalRecordIDBuffer."User ID" := SynchEntityCode;
        GlobalRecordIDBuffer."Record ID" := RecID;
        GlobalRecordIDBuffer."Search Record ID" := Format(RecID);
        GlobalRecordIDBuffer.Insert();
    end;

    local procedure CheckChangeLogAvailability(): Boolean
    var
        ChangeLogSetup: Record "Change Log Setup";
    begin
        if ChangeLogSetup.Get then
            exit(ChangeLogSetup."Change Log Activated");

        exit(false);
    end;

    procedure IsOSyncUser(UserID: Code[50]): Boolean
    var
        OutlookSynchUserSetup: Record "Outlook Synch. User Setup";
    begin
        if UserID = '' then
            exit(false);

        OutlookSynchUserSetup.SetRange("User ID", UserID);
        exit(not OutlookSynchUserSetup.IsEmpty);
    end;

    local procedure GetDateTimeFieldRef(OutlookSynchField: Record "Outlook Synch. Field"; TempOutlookSynchField: Record "Outlook Synch. Field" temporary; var SynchRecRef: RecordRef; var RelatedRecRef: RecordRef; var DateTimeFieldRef: FieldRef)
    var
        DateTimeRecRef: RecordRef;
    begin
        if OutlookSynchField."Table No." = TempOutlookSynchField."Table No." then begin
            if TempOutlookSynchField."Table No." = 0 then
                DateTimeFieldRef := SynchRecRef.Field(OutlookSynchField."Field No.")
            else
                DateTimeFieldRef := RelatedRecRef.Field(OutlookSynchField."Field No.");
        end else begin
            OSynchFilter.Reset();
            OSynchFilter.SetRange("Record GUID", OutlookSynchField."Record GUID");
            OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");

            DateTimeRecRef.Open(OutlookSynchField."Table No.");
            DateTimeRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, SynchRecRef));
            if DateTimeRecRef.Find('-') then
                DateTimeFieldRef := DateTimeRecRef.Field(OutlookSynchField."Field No.");
        end;
    end;
}

