codeunit 5305 "Outlook Synch. Process Line"
{

    trigger OnRun()
    begin
        case OSynchActionType of
            OSynchActionType::Insert:
                InsertItem;
            OSynchActionType::Modify:
                ProcessItem;
            OSynchActionType::Delete:
                OSynchDeletionMgt.ProcessItem(OSynchUserSetup, EntityRecID, ErrorLogXMLWriter, StartDateTime);
        end;
    end;

    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchUserSetup: Record "Outlook Synch. User Setup";
        ErrorConflictBuffer: Record "Outlook Synch. Link" temporary;
        Base64Convert: Codeunit "Base64 Convert";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        OSynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
        OSynchTypeConversion: Codeunit "Outlook Synch. Type Conv";
        OSynchDeletionMgt: Codeunit "Outlook Synch. Deletion Mgt.";
        OSynchOutlookMgt: Codeunit "Outlook Synch. Outlook Mgt.";
        XMLTextReader: DotNet "OLSync.Common.XmlTextReader";
        ErrorLogXMLWriter: DotNet "OLSync.Common.XmlTextWriter";
        EntityRecID: RecordID;
        OSynchActionType: Option Insert,Modify,Delete,Undefined;
        StartDateTime: DateTime;
        Container: Text;
        OEntryIDHash: Text[32];
        RootIterator: Text[38];
        SkipCheckForConflicts: Boolean;
        Text001: Label 'An Outlook item cannot be synchronized because the %1 field of the %2 entity cannot be processed. Try again later and if the problem persists contact your system administrator.';
        Text002: Label 'An Outlook item cannot be synchronized because the %1 collection of the %2 entity cannot be found. Try again later and if the problem persists contact your system administrator.';
        Text003: Label 'An Outlook item cannot be synchronized because a conflict has occurred when processing the %1 entity.';
        Text004: Label 'An Outlook item cannot be synchronized because a conflict has occurred when processing the %1 collection in the %2 entity.';
        Text005: Label 'An Outlook item of the %1 entity cannot be synchronized because the %2 collection depends on an Outlook item that could not be found in the synchronization folders.';
        Text006: Label 'An Outlook item of the %1 entity cannot be synchronized because the %2 collection has a dependency that does not exist. Try again later and if the problem persists contact your system administrator.';
        Text007: Label 'An Outlook item of the %1 entity cannot be synchronized because the %2 collection depends on an Outlook item that has not been synchronized. Try again later and if the problem persists contact your system administrator.';
        Text008: Label 'An Outlook item of the %1 entity cannot be synchronized because an error occurred when processing the %2 collection. Try again later and if the problem persists contact your system administrator.';
        Text009: Label 'An Outlook item of the %1 entity cannot be synchronized because a conflict occurred that could not be logged. Please contact your system administrator to change your synchronization settings.';
        Text010: Label 'An Outlook item cannot be synchronized because the %1 field of the %2 collection in the %3 entity cannot be processed. Try again later and if the problem persists contact your system administrator.';

    [Scope('OnPrem')]
    procedure SetGlobalParameters(var OSynchEntityIn: Record "Outlook Synch. Entity"; var OSynchUserSetupIn: Record "Outlook Synch. User Setup"; var ErrorConflictBufferIn: Record "Outlook Synch. Link" temporary; var XMLTextReaderIn: DotNet "OLSync.Common.XmlTextReader"; var ErrorLogXMLWriterIn: DotNet "OLSync.Common.XmlTextWriter"; RootIteratorIn: Text[38]; OSynchActionTypeIn: Integer; SearchRecID: Code[250]; ContainerIn: Text; OEntryIDHashIn: Text[32]; StartDateTimeIn: DateTime; SkipCheckForConflictsIn: Boolean)
    begin
        OSynchEntity := OSynchEntityIn;
        OSynchUserSetup := OSynchUserSetupIn;

        if ErrorConflictBufferIn.Find('-') then
            repeat
                ErrorConflictBuffer.Init();
                ErrorConflictBuffer := ErrorConflictBufferIn;
                ErrorConflictBuffer.Insert();
            until ErrorConflictBufferIn.Next = 0;

        XMLTextReader := XMLTextReaderIn;
        ErrorLogXMLWriter := ErrorLogXMLWriterIn;
        RootIterator := RootIteratorIn;
        OSynchActionType := OSynchActionTypeIn;
        Clear(EntityRecID);
        if SearchRecID <> '' then
            Evaluate(EntityRecID, SearchRecID);

        Container := ContainerIn;
        OEntryIDHash := OEntryIDHashIn;
        StartDateTime := StartDateTimeIn;
        SkipCheckForConflicts := SkipCheckForConflictsIn;
    end;

    local procedure ProcessItem()
    var
        OSynchLink: Record "Outlook Synch. Link";
        OSynchField: Record "Outlook Synch. Field";
        EntityRecRef: RecordRef;
        ModifiedEntityRecRef: RecordRef;
        RecID: RecordID;
    begin
        OSynchLink.Get(OSynchUserSetup."User ID", EntityRecID);
        if not EntityRecRef.Get(EntityRecID) then begin
            if SkipCheckForConflicts then begin
                OSynchLink.Delete();
                InsertItem;
                exit;
            end;
            OSynchOutlookMgt.WriteErrorLog(
              OSynchUserSetup."User ID",
              EntityRecID,
              'Conflict',
              OSynchEntity.Code,
              StrSubstNo(Text003, OSynchEntity.Code),
              ErrorLogXMLWriter,
              Container);
            Error('');
        end;

        if not CheckEntityIdentity(EntityRecID, OSynchUserSetup."Synch. Entity Code") then
            exit;

        if not SkipCheckForConflicts then
            if ConflictDetected(EntityRecRef, OSynchUserSetup."Last Synch. Time") then begin
                OSynchOutlookMgt.WriteErrorLog(
                  OSynchUserSetup."User ID",
                  EntityRecID,
                  'Conflict',
                  OSynchEntity.Code,
                  StrSubstNo(Text003, OSynchEntity.Code),
                  ErrorLogXMLWriter,
                  Container);
                Error('');
            end;

        ModifiedEntityRecRef := EntityRecRef.Duplicate;

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", OSynchEntity.Code);
        OSynchField.SetRange("Element No.", 0);
        ProcessProperties(OSynchField, ModifiedEntityRecRef, RootIterator, 0, false);

        ModifyRecRef(ModifiedEntityRecRef, EntityRecRef, 0);
        ProcessCollections(ModifiedEntityRecRef);

        Evaluate(RecID, Format(EntityRecRef.RecordId));
        UpdateSynchronizationDate(OSynchUserSetup."User ID", RecID);
    end;

    local procedure InsertItem()
    var
        OSynchLink: Record "Outlook Synch. Link";
        OSynchField: Record "Outlook Synch. Field";
        EntityRecRef: RecordRef;
        RecID: RecordID;
    begin
        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", OSynchEntity.Code);
        OSynchField.SetRange("Element No.", 0);

        EntityRecRef.Open(OSynchEntity."Table No.");
        EntityRecRef.LockTable();
        EntityRecRef.Init();
        ProcessFields(OSynchField, EntityRecRef, RootIterator, 0, false);
        EntityRecRef.Insert(true);

        OSynchLink.InsertOSynchLink(OSynchUserSetup."User ID", Container, EntityRecRef, OEntryIDHash);
        ProcessCollections(EntityRecRef);

        Evaluate(RecID, Format(EntityRecRef.RecordId));
        UpdateSynchronizationDate(OSynchUserSetup."User ID", RecID);

        EntityRecRef.Close;
    end;

    local procedure ProcessConstants(var OSynchField: Record "Outlook Synch. Field"; var RecRef: RecordRef)
    var
        KeyFieldsBuffer: Record "Outlook Synch. Lookup Name" temporary;
        FieldRef: FieldRef;
    begin
        KeyFieldsBuffer.Reset();
        KeyFieldsBuffer.DeleteAll();
        OSynchField.ClearMarks;

        if OSynchField.Find('-') then
            repeat
                if CheckKeyField(OSynchField."Master Table No.", OSynchField."Field No.") then begin
                    KeyFieldsBuffer.Init();
                    KeyFieldsBuffer."Entry No." := OSynchField."Field No.";
                    KeyFieldsBuffer.Name := CopyStr(OSynchField.DefaultValueExpression, 1, MaxStrLen(KeyFieldsBuffer.Name));
                    if KeyFieldsBuffer.Insert() then;
                end else
                    OSynchField.Mark(true);
            until OSynchField.Next = 0;

        if OSynchField.Find('-') then;
        KeyFieldsBuffer.Reset();
        if KeyFieldsBuffer.Find('-') then
            repeat
                FieldRef := RecRef.Field(KeyFieldsBuffer."Entry No.");
                if not
                   OSynchTypeConversion.EvaluateTextToFieldRef(
                     OSynchTypeConversion.SetValueFormat(KeyFieldsBuffer.Name, FieldRef),
                     FieldRef,
                     true)
                then
                    if OSynchField."Element No." = 0 then
                        Error(Text001, FieldRef.Caption, OSynchField."Synch. Entity Code")
                    else
                        Error(Text010, FieldRef.Caption, OSynchField."Outlook Object", OSynchField."Synch. Entity Code");
            until KeyFieldsBuffer.Next = 0;

        OSynchField.MarkedOnly(true);
        if OSynchField.Find('-') then
            repeat
                FieldRef := RecRef.Field(OSynchField."Field No.");
                if not
                   OSynchTypeConversion.EvaluateTextToFieldRef(
                     OSynchTypeConversion.SetValueFormat(OSynchField.DefaultValueExpression, FieldRef),
                     FieldRef,
                     true)
                then
                    if OSynchField."Element No." = 0 then
                        Error(Text001, FieldRef.Caption, OSynchField."Synch. Entity Code")
                    else
                        Error(Text010, FieldRef.Caption, OSynchField."Outlook Object", OSynchField."Synch. Entity Code");
            until OSynchField.Next = 0;
    end;

    local procedure ProcessProperties(var OSynchField: Record "Outlook Synch. Field"; var SynchRecRef: RecordRef; Iterator: Text[38]; ElementNo: Integer; ProcessOnlySearchFields: Boolean)
    var
        OSynchFilter: Record "Outlook Synch. Filter";
        TempOSynchFilter: Record "Outlook Synch. Filter" temporary;
        OSynchOptionCorrel: Record "Outlook Synch. Option Correl.";
        RelatedRecRef: RecordRef;
        NullRecRef: RecordRef;
        FldRef: FieldRef;
        RelatedFldRef: FieldRef;
        ChildIterator: Text[38];
        TagName: Text[250];
        OProperty: Text[80];
        OPropertyValue: Text[1024];
        OLOptionValue: Integer;
        ValidateFieldValue: Boolean;
    begin
        if XMLTextReader.GetAllCurrentChildNodes(Iterator, ChildIterator) > 0 then begin
            ValidateFieldValue := not ProcessOnlySearchFields;
            if ProcessOnlySearchFields then
                OSynchField.SetRange("Search Field", true);
            OSynchField.SetFilter("Read-Only Status", '<>%1', OSynchField."Read-Only Status"::"Read-Only in Microsoft Dynamics NAV");
            repeat
                TagName := XMLTextReader.GetName(ChildIterator);
                if TagName = 'Field' then begin
                    OProperty := XMLTextReader.GetCurrentNodeAttribute(ChildIterator, 'Name');
                    OSynchField.SetRange("Outlook Property", OProperty);
                    if OSynchField.Find('-') then
                        repeat
                            if OSynchNAVMgt.CheckSynchFieldCondition(SynchRecRef, OSynchField) then begin
                                OPropertyValue := CopyStr(XMLTextReader.GetValue(ChildIterator), 1, MaxStrLen(OPropertyValue));
                                if OSynchField."Table No." <> 0 then begin
                                    TempOSynchFilter.Reset();
                                    TempOSynchFilter.DeleteAll();

                                    OSynchFilter.Reset();
                                    OSynchFilter.SetRange("Record GUID", OSynchField."Record GUID");
                                    OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
                                    OSynchFilter.SetFilter(Type, '<>%1', OSynchFilter.Type::FIELD);
                                    OSynchSetupMgt.CopyFilterRecords(OSynchFilter, TempOSynchFilter);

                                    OSynchSetupMgt.CreateFilterCondition(
                                      TempOSynchFilter,
                                      OSynchField."Table No.",
                                      OSynchField."Field No.",
                                      TempOSynchFilter.Type::FILTER,
                                      OPropertyValue);

                                    RelatedRecRef.Open(OSynchField."Table No.");
                                    RelatedRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(TempOSynchFilter, NullRecRef));
                                    OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                                    if RelatedRecRef.Find('-') then begin
                                        if OSynchFilter.Find('-') then
                                            repeat
                                                FldRef := SynchRecRef.Field(OSynchFilter."Master Table Field No.");
                                                RelatedFldRef := RelatedRecRef.Field(OSynchFilter."Field No.");
                                                if RelatedFldRef.Type in [FieldType::Date, FieldType::Time] then
                                                    ProcessDateTimeProperty(SynchRecRef, OSynchField, OPropertyValue)
                                                else begin
                                                    if not
                                                       OSynchTypeConversion.EvaluateTextToFieldRef(
                                                         OSynchTypeConversion.SetValueFormat(Format(RelatedFldRef), RelatedFldRef),
                                                         FldRef,
                                                         ValidateFieldValue)
                                                    then
                                                        if ElementNo = 0 then
                                                            Error(Text001, FldRef.Caption, OSynchEntity.Code)
                                                        else
                                                            Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchEntity.Code);
                                                end;
                                            until OSynchFilter.Next = 0;
                                    end else
                                        if OPropertyValue = '' then begin
                                            if OSynchFilter.Find('-') then
                                                repeat
                                                    FldRef := SynchRecRef.Field(OSynchFilter."Master Table Field No.");
                                                    if not OSynchTypeConversion.EvaluateTextToFieldRef('', FldRef, ValidateFieldValue) then
                                                        if ElementNo = 0 then
                                                            Error(Text001, FldRef.Caption, OSynchEntity.Code)
                                                        else
                                                            Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchEntity.Code);
                                                until OSynchFilter.Next = 0;
                                        end else
                                            if OSynchFilter.FindFirst then begin
                                                FldRef := SynchRecRef.Field(OSynchFilter."Master Table Field No.");
                                                RelatedFldRef := RelatedRecRef.Field(OSynchFilter."Field No.");
                                                if ElementNo = 0 then
                                                    Error(Text001, FldRef.Caption, OSynchField."Synch. Entity Code");

                                                Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchField."Synch. Entity Code");
                                            end;
                                    RelatedRecRef.Close;
                                end else begin
                                    FldRef := SynchRecRef.Field(OSynchField."Field No.");

                                    case FldRef.Type of
                                        FieldType::Date, FieldType::Time:
                                            ProcessDateTimeProperty(SynchRecRef, OSynchField, OPropertyValue);
                                        FieldType::BLOB:
                                            ;
                                        FieldType::Option:
                                            if Evaluate(OLOptionValue, OPropertyValue) then begin
                                                OSynchOptionCorrel.Reset();
                                                OSynchOptionCorrel.SetRange("Synch. Entity Code", OSynchField."Synch. Entity Code");
                                                OSynchOptionCorrel.SetRange("Element No.", OSynchField."Element No.");
                                                OSynchOptionCorrel.SetRange("Field Line No.", OSynchField."Line No.");
                                                OSynchOptionCorrel.SetRange("Enumeration No.", OLOptionValue);
                                                if OSynchOptionCorrel.FindFirst then begin
                                                    if not
                                                       OSynchTypeConversion.EvaluateTextToFieldRef(
                                                         Format(OSynchOptionCorrel."Option No."),
                                                         FldRef,
                                                         ValidateFieldValue)
                                                    then
                                                        if ElementNo = 0 then
                                                            Error(Text001, FldRef.Caption, OSynchEntity.Code)
                                                        else
                                                            Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchEntity.Code);
                                                end else begin
                                                    if not OSynchSetupMgt.CheckOEnumeration(OSynchField) then begin
                                                        if not OSynchTypeConversion.EvaluateTextToFieldRef(OPropertyValue, FldRef, ValidateFieldValue) then
                                                            if ElementNo = 0 then
                                                                Error(Text001, FldRef.Caption, OSynchEntity.Code)
                                                            else
                                                                Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchEntity.Code);
                                                    end else
                                                        if ElementNo = 0 then
                                                            Error(Text001, FldRef.Caption, OSynchField."Synch. Entity Code")
                                                        else
                                                            Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchField."Synch. Entity Code");
                                                end;
                                            end else begin
                                                if not OSynchTypeConversion.EvaluateTextToFieldRef(OPropertyValue, FldRef, ValidateFieldValue) then
                                                    if ElementNo = 0 then
                                                        Error(Text001, FldRef.Caption, OSynchField."Synch. Entity Code")
                                                    else
                                                        Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchField."Synch. Entity Code");
                                            end;
                                        else begin
                                                if not OSynchTypeConversion.EvaluateTextToFieldRef(OPropertyValue, FldRef, ValidateFieldValue) then
                                                    if ElementNo = 0 then
                                                        Error(Text001, FldRef.Caption, OSynchField."Synch. Entity Code")
                                                    else
                                                        Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchField."Synch. Entity Code");
                                            end;
                                    end;
                                end;
                            end;
                        until OSynchField.Next = 0;
                end;
            until not XMLTextReader.MoveNext(ChildIterator);
        end;
        XMLTextReader.RemoveIterator(ChildIterator);
    end;

    local procedure ProcessRelationsAndConditions(var OSynchEntityElementIn: Record "Outlook Synch. Entity Element"; EntityRecRef: RecordRef; var CollectionRecRef: RecordRef; DependentRecRef: RecordRef)
    var
        OSynchEntity1: Record "Outlook Synch. Entity";
        OSynchFilter: Record "Outlook Synch. Filter";
        TempOSynchFilter: Record "Outlook Synch. Filter" temporary;
        KeyFieldsBuffer: Record "Outlook Synch. Lookup Name" temporary;
        OSynchDependency: Record "Outlook Synch. Dependency";
        TempDependentRecRef: RecordRef;
        NullRecRef: RecordRef;
        FieldRef: FieldRef;
        RecID: RecordID;
    begin
        TempOSynchFilter.Reset();
        TempOSynchFilter.DeleteAll();

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", OSynchEntityElementIn."Record GUID");
        OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
        OSynchSetupMgt.ComposeFilterRecords(OSynchFilter, TempOSynchFilter, EntityRecRef, TempOSynchFilter.Type::CONST);

        if OSynchEntityElementIn."No. of Dependencies" > 0 then begin
            Evaluate(RecID, Format(DependentRecRef.RecordId));
            TempDependentRecRef.Open(RecID.TableNo, true);
            OSynchNAVMgt.CopyRecordReference(DependentRecRef, TempDependentRecRef, false);

            OSynchDependency.Reset();
            OSynchDependency.SetRange("Synch. Entity Code", OSynchEntityElementIn."Synch. Entity Code");
            OSynchDependency.SetRange("Element No.", OSynchEntityElementIn."Element No.");
            OSynchDependency.CalcFields("Depend. Synch. Entity Tab. No.");
            OSynchDependency.SetRange("Depend. Synch. Entity Tab. No.", RecID.TableNo);
            if OSynchDependency.Find('-') then
                repeat
                    OSynchEntity1.Get(OSynchDependency."Depend. Synch. Entity Code");
                    OSynchFilter.Reset();
                    OSynchFilter.SetRange("Record GUID", OSynchEntity1."Record GUID");
                    if OSynchFilter.FindFirst then
                        TempDependentRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, NullRecRef));

                    if TempDependentRecRef.Find('-') then begin
                        OSynchFilter.Reset();
                        OSynchFilter.SetRange("Record GUID", OSynchDependency."Record GUID");
                        OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::Condition);
                        OSynchFilter.SetRange(Type, OSynchFilter.Type::CONST);
                        OSynchSetupMgt.CopyFilterRecords(OSynchFilter, TempOSynchFilter);

                        OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
                        OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                        OSynchSetupMgt.ComposeFilterRecords(OSynchFilter, TempOSynchFilter, TempDependentRecRef, TempOSynchFilter.Type::CONST);
                    end;
                until OSynchDependency.Next = 0;
            TempDependentRecRef.Close;
        end;

        KeyFieldsBuffer.Reset();
        KeyFieldsBuffer.DeleteAll();
        TempOSynchFilter.ClearMarks;

        if TempOSynchFilter.Find('-') then
            repeat
                if CheckKeyField(TempOSynchFilter."Table No.", TempOSynchFilter."Field No.") then begin
                    KeyFieldsBuffer.Init();
                    KeyFieldsBuffer."Entry No." := TempOSynchFilter."Field No.";
                    KeyFieldsBuffer.Name := CopyStr(TempOSynchFilter.GetFilterExpressionValue, 1, MaxStrLen(KeyFieldsBuffer.Name));
                    if KeyFieldsBuffer.Insert() then;
                end else
                    TempOSynchFilter.Mark(true);
            until TempOSynchFilter.Next = 0;

        KeyFieldsBuffer.Reset();
        if KeyFieldsBuffer.Find('-') then
            repeat
                FieldRef := CollectionRecRef.Field(KeyFieldsBuffer."Entry No.");
                if not
                   OSynchTypeConversion.EvaluateTextToFieldRef(
                     OSynchTypeConversion.SetValueFormat(KeyFieldsBuffer.Name, FieldRef),
                     FieldRef,
                     true)
                then
                    if OSynchEntityElementIn."Element No." = 0 then
                        Error(Text001, FieldRef.Caption, OSynchEntityElementIn."Synch. Entity Code")
                    else
                        Error(
                          Text010,
                          FieldRef.Caption,
                          OSynchEntityElementIn."Outlook Collection",
                          OSynchEntityElementIn."Synch. Entity Code");
            until KeyFieldsBuffer.Next = 0;

        TempOSynchFilter.MarkedOnly(true);
        TempOSynchFilter.SetCurrentKey("Table No.", "Field No."); // Defines validation order

        if TempOSynchFilter.Find('-') then
            repeat
                FieldRef := CollectionRecRef.Field(TempOSynchFilter."Field No.");
                if not
                   OSynchTypeConversion.EvaluateTextToFieldRef(
                     OSynchTypeConversion.SetValueFormat(TempOSynchFilter.GetFilterExpressionValue, FieldRef),
                     FieldRef,
                     true)
                then
                    if OSynchEntityElementIn."Element No." = 0 then
                        Error(Text001, FieldRef.Caption, OSynchEntityElementIn."Synch. Entity Code")
                    else
                        Error(
                          Text010,
                          FieldRef.Caption,
                          OSynchEntityElementIn."Outlook Collection",
                          OSynchEntityElementIn."Synch. Entity Code");
            until TempOSynchFilter.Next = 0;
    end;

    local procedure ProcessFields(var OSynchField: Record "Outlook Synch. Field"; var SynchRecRef: RecordRef; Iterator: Text[38]; ElementNo: Integer; ProcessOnlySearchFields: Boolean)
    var
        OSynchFieldBuffer: Record "Outlook Synch. Field" temporary;
        IsConst: Boolean;
    begin
        if not OSynchField.Find('-') then
            exit;

        repeat
            if OSynchField."Outlook Property" = '' then begin
                if not IsConst then begin
                    ProcessProperties(OSynchFieldBuffer, SynchRecRef, Iterator, ElementNo, ProcessOnlySearchFields);
                    OSynchFieldBuffer.Reset();
                    OSynchFieldBuffer.DeleteAll();
                end;

                if (OSynchField."Table No." = 0) and
                   (OSynchField."Read-Only Status" = OSynchField."Read-Only Status"::"Read-Only in Microsoft Dynamics NAV") and
                   (OSynchField.Condition = '')
                then begin
                    OSynchFieldBuffer.Init();
                    OSynchFieldBuffer.Copy(OSynchField);
                    OSynchFieldBuffer.Insert();
                end;

                IsConst := true;
            end else begin
                if IsConst then begin
                    ProcessConstants(OSynchFieldBuffer, SynchRecRef);
                    OSynchFieldBuffer.Reset();
                    OSynchFieldBuffer.DeleteAll();
                end;

                OSynchFieldBuffer.Init();
                OSynchFieldBuffer.Copy(OSynchField);
                OSynchFieldBuffer.Insert();

                IsConst := false;
            end;
        until OSynchField.Next = 0;

        if IsConst then
            ProcessConstants(OSynchFieldBuffer, SynchRecRef)
        else
            ProcessProperties(OSynchFieldBuffer, SynchRecRef, Iterator, ElementNo, ProcessOnlySearchFields);
    end;

    local procedure ProcessDateTimeProperty(var SynchRecRef: RecordRef; OSynchFieldIn: Record "Outlook Synch. Field"; OPropertyValue: Text[1024])
    var
        OSynchField: Record "Outlook Synch. Field";
        OSynchFilter: Record "Outlook Synch. Filter";
        TempOSynchFilter: Record "Outlook Synch. Filter" temporary;
        Field1: Record "Field";
        RelatedRecRef: RecordRef;
        NullRecRef: RecordRef;
        FldRef: FieldRef;
        RelatedFldRef: FieldRef;
        DateTimeVar: DateTime;
    begin
        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", OSynchFieldIn."Synch. Entity Code");
        OSynchField.SetRange("Element No.", OSynchFieldIn."Element No.");
        OSynchField.SetRange("Outlook Property", OSynchFieldIn."Outlook Property");
        if OSynchField.Find('-') then
            repeat
                if OSynchField."Table No." = 0 then
                    Field1.Get(OSynchField."Master Table No.", OSynchField."Field No.")
                else
                    Field1.Get(OSynchField."Table No.", OSynchField."Field No.");

                if (Field1.Type = Field1.Type::Time) or (Field1.Type = Field1.Type::Date) then begin
                    if DateTimeVar = 0DT then
                        OSynchTypeConversion.TextToDateTime(OPropertyValue, DateTimeVar);
                    if OSynchNAVMgt.CheckSynchFieldCondition(SynchRecRef, OSynchField) then
                        if OSynchField."Table No." = 0 then begin
                            FldRef := SynchRecRef.Field(OSynchField."Field No.");
                            if Field1.Type = Field1.Type::Time then
                                FldRef.Validate(DT2Time(DateTimeVar))
                            else
                                FldRef.Validate(DT2Date(DateTimeVar));
                        end else begin
                            TempOSynchFilter.Reset();
                            TempOSynchFilter.DeleteAll();

                            OSynchFilter.Reset();
                            OSynchFilter.SetRange("Record GUID", OSynchField."Record GUID");
                            OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
                            OSynchFilter.SetFilter(Type, '<>%1', OSynchFilter.Type::FIELD);
                            OSynchSetupMgt.CopyFilterRecords(OSynchFilter, TempOSynchFilter);

                            OSynchSetupMgt.CreateFilterCondition(
                              TempOSynchFilter,
                              OSynchField."Table No.",
                              OSynchField."Field No.",
                              TempOSynchFilter.Type::FILTER,
                              OSynchTypeConversion.SetDateTimeFormat(DateTimeVar));

                            RelatedRecRef.Open(OSynchField."Table No.");
                            RelatedRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(TempOSynchFilter, NullRecRef));
                            if RelatedRecRef.Find('-') then begin
                                OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                                if OSynchFilter.Find('-') then
                                    repeat
                                        FldRef := SynchRecRef.Field(OSynchFilter."Master Table Field No.");
                                        RelatedFldRef := RelatedRecRef.Field(OSynchFilter."Field No.");
                                        if not OSynchTypeConversion.EvaluateTextToFieldRef(Format(RelatedFldRef), FldRef, true) then
                                            if OSynchField."Element No." = 0 then
                                                Error(Text001, FldRef.Caption, OSynchField."Synch. Entity Code")
                                            else
                                                Error(Text010, FldRef.Caption, OSynchField."Outlook Object", OSynchField."Synch. Entity Code");
                                    until OSynchFilter.Next = 0;
                            end;
                            RelatedRecRef.Close;
                        end;
                end;
            until OSynchField.Next = 0;
    end;

    local procedure ProcessCollections(EntityRecRef: RecordRef)
    var
        CollectionElementsBuffer: Record "Outlook Synch. Link" temporary;
        CollectionsBuffer: RecordRef;
        ChildIterator: Text[38];
        ElementIterator: Text[38];
        ChildTagName: Text[250];
        OCollectionName: Text[80];
        CollectionTableID: Integer;
        CollectionElementNo: Integer;
        IsBufferUsed: Boolean;
    begin
        if XMLTextReader.GetAllCurrentChildNodes(RootIterator, ChildIterator) = 0 then begin
            XMLTextReader.RemoveIterator(ChildIterator);
            exit;
        end;

        CollectionTableID := 0;
        OSynchEntityElement.Reset();
        OSynchEntityElement.SetRange("Synch. Entity Code", OSynchEntity.Code);
        repeat
            ChildTagName := XMLTextReader.GetName(ChildIterator);
            if ChildTagName = 'Collection' then begin
                CollectionElementsBuffer.Reset();
                CollectionElementsBuffer.DeleteAll();

                OCollectionName := XMLTextReader.GetCurrentNodeAttribute(ChildIterator, 'Name');
                OSynchEntityElement.SetRange("Outlook Collection", OCollectionName);
                if OSynchEntityElement.FindFirst then begin
                    if XMLTextReader.GetAllCurrentChildNodes(ChildIterator, ElementIterator) > 0 then
                        repeat
                            ChildTagName := XMLTextReader.GetName(ElementIterator);
                            if ChildTagName = 'Element' then
                                CheckCollectionElement(OSynchEntityElement, ElementIterator);
                        until not XMLTextReader.MoveNext(ElementIterator);
                    XMLTextReader.RemoveIterator(ElementIterator);
                end else
                    Error(Text002, OCollectionName, OSynchEntityElement."Synch. Entity Code");

                if not SkipCheckForConflicts then
                    if CollectionConflictDetected(OSynchEntityElement, EntityRecRef, OSynchUserSetup."Last Synch. Time") then begin
                        OSynchOutlookMgt.WriteErrorLog(
                          OSynchUserSetup."User ID",
                          EntityRecRef.RecordId,
                          'Conflict',
                          OSynchEntityElement."Synch. Entity Code",
                          StrSubstNo(
                            Text004,
                            OSynchEntityElement."Outlook Collection",
                            OSynchEntityElement."Synch. Entity Code"),
                          ErrorLogXMLWriter,
                          Container);
                        Error('');
                    end;

                if XMLTextReader.GetAllCurrentChildNodes(ChildIterator, ElementIterator) > 0 then begin
                    if CollectionTableID <> OSynchEntityElement."Table No." then begin
                        CollectionElementNo := 0;
                        if CollectionTableID = 0 then
                            CollectionsBuffer.Open(OSynchEntityElement."Table No.", true);

                        if CollectionsBuffer.Find('-') then
                            ProcessCollectiosBuffer(CollectionElementsBuffer, CollectionsBuffer, CollectionTableID);

                        CollectionTableID := OSynchEntityElement."Table No.";
                        CollectionsBuffer.Close;
                        CollectionsBuffer.Open(CollectionTableID, true);
                        IsBufferUsed := true;
                    end;

                    repeat
                        ChildTagName := XMLTextReader.GetName(ElementIterator);
                        if ChildTagName = 'Element' then begin
                            CollectionElementNo := CollectionElementNo + 1;
                            ProcessCollectionElement(
                              OSynchEntityElement,
                              ElementIterator,
                              EntityRecRef,
                              CollectionElementsBuffer,
                              CollectionsBuffer,
                              CollectionElementNo);
                        end;
                    until not XMLTextReader.MoveNext(ElementIterator);
                end;

                XMLTextReader.RemoveIterator(ElementIterator);
                DeletedCollectionElements(CollectionElementsBuffer, OSynchEntityElement, EntityRecRef);
            end;
        until not XMLTextReader.MoveNext(ChildIterator);
        XMLTextReader.RemoveIterator(ChildIterator);

        if IsBufferUsed then
            if CollectionsBuffer.Find('-') then
                ProcessCollectiosBuffer(CollectionElementsBuffer, CollectionsBuffer, CollectionTableID);
    end;

    procedure ProcessCollectiosBuffer(var CollectionElementsBuffer: Record "Outlook Synch. Link"; CollectionsBuffer: RecordRef; TableID: Integer)
    var
        CollectionRecRef: RecordRef;
        RecID: RecordID;
    begin
        CollectionRecRef.Open(TableID);

        repeat
            OSynchNAVMgt.CopyRecordReference(CollectionsBuffer, CollectionRecRef, true);

            Evaluate(RecID, Format(CollectionRecRef.RecordId));

            CollectionElementsBuffer.Init();
            CollectionElementsBuffer."User ID" := OSynchUserSetup."User ID";
            CollectionElementsBuffer."Record ID" := RecID;
            if CollectionElementsBuffer.Insert() then;
        until CollectionsBuffer.Next = 0;

        CollectionRecRef.Close;
    end;

    local procedure ProcessCollectionElement(OSynchEntityElementIn: Record "Outlook Synch. Entity Element"; ElementIterator: Text[38]; EntityRecRef: RecordRef; var CollectionElementsBuffer: Record "Outlook Synch. Link"; var CollectionsBuffer: RecordRef; CollectionElementNo: Integer)
    var
        OSynchEntity1: Record "Outlook Synch. Entity";
        OSynchLink: Record "Outlook Synch. Link";
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchFilter1: Record "Outlook Synch. Filter";
        OSynchField: Record "Outlook Synch. Field";
        OSynchDependency: Record "Outlook Synch. Dependency";
        DependentRecRef: RecordRef;
        TempDependentRecRef: RecordRef;
        CollectionRecRef: RecordRef;
        TempCollectionRecRef: RecordRef;
        OriginalCollectionRecRef: RecordRef;
        NullRecRef: RecordRef;
        RecID: RecordID;
        ContainerLocal: Text;
        EntryIDHash: Text[32];
        ChildrenIterator: Text[38];
        IsFound: Boolean;
        IsOneToOneEntity: Boolean;
    begin
        if XMLTextReader.GetAllCurrentChildNodes(ElementIterator, ChildrenIterator) = 0 then
            exit;

        OSynchEntityElementIn.CalcFields("Table Caption", "Master Table No.", "No. of Dependencies");
        if OSynchEntityElementIn."No. of Dependencies" = 0 then begin
            OSynchField.Reset();
            OSynchField.SetRange("Synch. Entity Code", OSynchEntityElementIn."Synch. Entity Code");
            OSynchField.SetRange("Element No.", OSynchEntityElementIn."Element No.");

            TempCollectionRecRef.Open(OSynchEntityElementIn."Table No.", true);
            TempCollectionRecRef.Init();
            ProcessProperties(OSynchField, TempCollectionRecRef, ElementIterator, OSynchEntityElementIn."Element No.", true);
            TempCollectionRecRef.Insert();

            FindEntityElementBySearchField(
              OSynchEntityElementIn."Synch. Entity Code",
              OSynchEntityElementIn."Element No.",
              EntityRecRef,
              TempCollectionRecRef,
              RecID);
            TempCollectionRecRef.Close;

            if Format(RecID) = '' then begin
                if OSynchEntityElementIn."Master Table No." = OSynchEntityElementIn."Table No." then
                    ModifyCollectionElement(EntityRecRef.RecordId, OSynchEntityElementIn."Element No.", ElementIterator, CollectionElementsBuffer)
                else
                    PutCollectionElementToBuffer(
                      EntityRecRef,
                      NullRecRef,
                      OSynchEntityElementIn,
                      ElementIterator,
                      CollectionsBuffer,
                      CollectionElementNo);
            end else
                ModifyCollectionElement(RecID, OSynchEntityElementIn."Element No.", ElementIterator, CollectionElementsBuffer);
        end else begin
            Clear(ContainerLocal);
            IsOneToOneEntity := false;

            if XMLTextReader.GetName(ChildrenIterator) = 'EntryID' then begin
                ContainerLocal := Base64Convert.FromBase64(XMLTextReader.GetValue(ChildrenIterator));
                EntryIDHash := OSynchOutlookMgt.ComputeHash(ContainerLocal);
            end;

            OSynchLink.Reset();
            OSynchLink.SetRange("User ID", OSynchUserSetup."User ID");
            OSynchLink.SetRange("Outlook Entry ID Hash", EntryIDHash);
            OSynchLink.FindFirst;

            DependentRecRef.Get(OSynchLink."Record ID");
            Evaluate(RecID, Format(DependentRecRef.RecordId));

            OSynchFilter.Reset();
            OSynchFilter.SetRange("Record GUID", OSynchEntityElementIn."Record GUID");
            OSynchFilter.FindFirst;

            CollectionRecRef.Open(OSynchEntityElementIn."Table No.");
            CollectionRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, EntityRecRef));
            if not CollectionRecRef.Find('-') then
                if OSynchEntityElementIn."Master Table No." <> OSynchEntityElementIn."Table No." then begin
                    PutCollectionElementToBuffer(
                      EntityRecRef,
                      DependentRecRef,
                      OSynchEntityElementIn,
                      ElementIterator,
                      CollectionsBuffer,
                      CollectionElementNo);

                    exit;
                end else begin
                    CollectionRecRef := EntityRecRef.Duplicate;
                    IsOneToOneEntity := true;
                end;

            TempDependentRecRef.Open(RecID.TableNo, true);
            OSynchNAVMgt.CopyRecordReference(DependentRecRef, TempDependentRecRef, false);

            OSynchDependency.Reset();
            OSynchDependency.SetRange("Synch. Entity Code", OSynchEntityElementIn."Synch. Entity Code");
            OSynchDependency.SetRange("Element No.", OSynchEntityElementIn."Element No.");
            OSynchDependency.CalcFields("Depend. Synch. Entity Tab. No.");
            OSynchDependency.SetRange("Depend. Synch. Entity Tab. No.", RecID.TableNo);
            if OSynchDependency.Find('-') then
                repeat
                    OSynchEntity1.Get(OSynchDependency."Depend. Synch. Entity Code");
                    OSynchFilter.Reset();
                    OSynchFilter.SetRange("Record GUID", OSynchEntity1."Record GUID");
                    if OSynchFilter.FindFirst then
                        TempDependentRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, NullRecRef));

                    if TempDependentRecRef.Find('-') then
                        IsFound := true;
                until (OSynchDependency.Next = 0) or IsFound;

            OSynchFilter.Reset();
            OSynchFilter.SetRange("Record GUID", OSynchDependency."Record GUID");
            OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::Condition);

            OSynchFilter1.Reset();
            OSynchFilter1.SetRange("Record GUID", OSynchDependency."Record GUID");
            OSynchFilter1.SetRange("Filter Type", OSynchFilter1."Filter Type"::"Table Relation");
            OSynchFilter1.SetRange(Type, OSynchFilter1.Type::FIELD);

            if not IsOneToOneEntity then begin
                TempCollectionRecRef.Open(OSynchEntityElementIn."Table No.", true);
                repeat
                    OSynchNAVMgt.CopyRecordReference(CollectionRecRef, TempCollectionRecRef, false);
                until CollectionRecRef.Next = 0;

                TempCollectionRecRef.SetView(OSynchSetupMgt.ComposeTableView(OSynchFilter, OSynchFilter1, DependentRecRef));
                if TempCollectionRecRef.Find('-') then begin
                    Evaluate(RecID, Format(TempCollectionRecRef.RecordId));
                    ModifyCollectionElement(RecID, OSynchEntityElementIn."Element No.", ElementIterator, CollectionElementsBuffer);
                    exit;
                end;
                TempCollectionRecRef.Close;
            end;

            if OSynchEntityElementIn."Table No." = OSynchEntityElementIn."Master Table No." then begin
                Evaluate(RecID, Format(CollectionRecRef.RecordId));
                OSynchFilter.Reset();
                OSynchFilter.SetRange("Record GUID", OSynchEntityElementIn."Record GUID");
                OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                if not OneToOneRelation(OSynchFilter) then
                    Error(
                      Text008,
                      OSynchEntityElementIn."Synch. Entity Code",
                      OSynchEntityElementIn."Outlook Collection");

                OriginalCollectionRecRef := CollectionRecRef.Duplicate;
                if not SetRelation(CollectionRecRef, DependentRecRef, OSynchDependency) then
                    Error(
                      Text008,
                      OSynchDependency."Synch. Entity Code",
                      OSynchEntityElementIn."Outlook Collection");

                OSynchField.Reset();
                OSynchField.SetRange("Synch. Entity Code", OSynchEntityElementIn."Synch. Entity Code");
                OSynchField.SetRange("Element No.", OSynchEntityElementIn."Element No.");
                ProcessProperties(
                  OSynchField,
                  CollectionRecRef,
                  ElementIterator,
                  OSynchEntityElementIn."Element No.",
                  false);

                ModifyRecRef(CollectionRecRef, OriginalCollectionRecRef, OSynchEntityElementIn."Element No.");
                CollectionElementsBuffer.Init();
                CollectionElementsBuffer."User ID" := OSynchUserSetup."User ID";
                CollectionElementsBuffer."Record ID" := RecID;
                if CollectionElementsBuffer.Insert() then;
                exit;
            end;

            PutCollectionElementToBuffer(
              EntityRecRef,
              DependentRecRef,
              OSynchEntityElementIn,
              ElementIterator,
              CollectionsBuffer,
              CollectionElementNo);

            DependentRecRef.Close;
            TempDependentRecRef.Close;
            CollectionRecRef.Close;
        end;
    end;

    local procedure DeletedCollectionElements(var CollectionElementsBuffer: Record "Outlook Synch. Link"; OSynchEntityElementIn: Record "Outlook Synch. Entity Element"; EntityRecRef: RecordRef)
    var
        OSynchFilter: Record "Outlook Synch. Filter";
        DeletedCollectionElementsBuf: Record "Outlook Synch. Link" temporary;
        CollectionRecRef: RecordRef;
        RecID: RecordID;
    begin
        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", OSynchEntityElementIn."Record GUID");
        CollectionRecRef.Open(OSynchEntityElementIn."Table No.");
        CollectionRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, EntityRecRef));

        if not CollectionElementsBuffer.Find('-') then begin
            if not CollectionRecRef.Find('-') then
                exit;
        end;

        DeletedCollectionElementsBuf.Reset();
        DeletedCollectionElementsBuf.DeleteAll();

        repeat
            Evaluate(RecID, Format(CollectionRecRef.RecordId));
            if not CollectionElementsBuffer.Get(OSynchUserSetup."User ID", RecID) then begin
                DeletedCollectionElementsBuf.Init();
                DeletedCollectionElementsBuf."User ID" := OSynchUserSetup."User ID";
                DeletedCollectionElementsBuf."Record ID" := RecID;
                DeletedCollectionElementsBuf.Insert();
            end;
        until CollectionRecRef.Next = 0;

        Evaluate(RecID, Format(EntityRecRef.RecordId));
        OSynchDeletionMgt.ProcessCollectionElements(DeletedCollectionElementsBuf, OSynchEntityElementIn, RecID);
        CollectionRecRef.Close;
    end;

    local procedure ModifyCollectionElement(CollectionElementRecID: RecordID; ElementNo: Integer; ElementIterator: Text[38]; var CollectionElementsBuffer: Record "Outlook Synch. Link")
    var
        OSynchField: Record "Outlook Synch. Field";
        CollectionRecRef: RecordRef;
        ModifiedCollectionRecRef: RecordRef;
    begin
        CollectionRecRef.Get(CollectionElementRecID);

        ModifiedCollectionRecRef := CollectionRecRef.Duplicate;

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", OSynchEntity.Code);
        OSynchField.SetRange("Element No.", ElementNo);
        ProcessProperties(OSynchField, ModifiedCollectionRecRef, ElementIterator, ElementNo, false);

        ModifyRecRef(ModifiedCollectionRecRef, CollectionRecRef, ElementNo);

        CollectionRecRef.Close;

        CollectionElementsBuffer.Init();
        CollectionElementsBuffer."User ID" := OSynchUserSetup."User ID";
        CollectionElementsBuffer."Record ID" := CollectionElementRecID;
        if CollectionElementsBuffer.Insert() then;
    end;

    local procedure PutCollectionElementToBuffer(EntityRecRef: RecordRef; DependentRecRef: RecordRef; OSynchEntityElementIn: Record "Outlook Synch. Entity Element"; ElementIterator: Text[38]; var CollectionElementRecRef: RecordRef; CollectionElementNo: Integer)
    var
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchField: Record "Outlook Synch. Field";
        CollectionElementRecRef1: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        IntVar: Integer;
        BigIntVar: BigInteger;
        DecimaVar: Decimal;
    begin
        OSynchEntityElementIn.CalcFields("Master Table No.");
        if OSynchEntityElementIn."Master Table No." = OSynchEntityElementIn."Table No." then
            Error(Text008, OSynchEntityElementIn."Synch. Entity Code", OSynchEntityElementIn."Outlook Collection");

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", OSynchEntityElementIn."Synch. Entity Code");
        OSynchField.SetRange("Element No.", OSynchEntityElementIn."Element No.");

        CollectionElementRecRef.Init();
        ProcessRelationsAndConditions(
          OSynchEntityElementIn,
          EntityRecRef,
          CollectionElementRecRef,
          DependentRecRef);
        ProcessFields(
          OSynchField,
          CollectionElementRecRef,
          ElementIterator,
          OSynchEntityElementIn."Element No.",
          false);

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", OSynchEntityElementIn."Record GUID");
        OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);

        CollectionElementRecRef1.Open(OSynchEntityElementIn."Table No.");
        CollectionElementRecRef1.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, EntityRecRef));
        if CollectionElementRecRef1.Find('+') then begin
            KeyRef := CollectionElementRecRef1.KeyIndex(1);
            FldRef := KeyRef.FieldIndex(KeyRef.FieldCount);

            if FldRef.Type in [FieldType::Integer, FieldType::BigInteger, FieldType::Decimal, FieldType::GUID] then
                case FldRef.Type of
                    FieldType::Integer:
                        begin
                            Evaluate(IntVar, Format(CollectionElementRecRef1.FieldIndex(KeyRef.FieldCount).Value));
                            IntVar := IntVar + CollectionElementNo * 10000;
                        end;
                    FieldType::BigInteger:
                        begin
                            Evaluate(BigIntVar, Format(CollectionElementRecRef1.FieldIndex(KeyRef.FieldCount).Value));
                            BigIntVar := BigIntVar + CollectionElementNo * 10000;
                        end;
                    FieldType::Decimal:
                        begin
                            Evaluate(DecimaVar, Format(CollectionElementRecRef1.FieldIndex(KeyRef.FieldCount).Value));
                            DecimaVar := DecimaVar + CollectionElementNo * 10000;
                        end;
                    FieldType::GUID:
                        FldRef.Value := CreateGuid;
                end;
        end else begin
            IntVar := CollectionElementNo * 10000;
            BigIntVar := CollectionElementNo * 10000;
            DecimaVar := CollectionElementNo * 10000;
        end;

        KeyRef := CollectionElementRecRef.KeyIndex(1);
        FldRef := KeyRef.FieldIndex(KeyRef.FieldCount);

        if FldRef.Type in [FieldType::Integer, FieldType::BigInteger, FieldType::Decimal, FieldType::GUID] then
            case FldRef.Type of
                FieldType::Integer:
                    FldRef.Validate(IntVar);
                FieldType::BigInteger:
                    FldRef.Validate(BigIntVar);
                FieldType::Decimal:
                    FldRef.Validate(DecimaVar);
                FieldType::GUID:
                    FldRef.Value := CreateGuid;
            end;

        CollectionElementRecRef.Insert();
    end;

    local procedure SetRelation(CollectionElementRecRef: RecordRef; DependentRecRef: RecordRef; OSynchDependency: Record "Outlook Synch. Dependency"): Boolean
    var
        OSynchFilter: Record "Outlook Synch. Filter";
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", OSynchDependency."Record GUID");
        OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
        OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
        if OSynchFilter.Find('-') then
            repeat
                if (CollectionElementRecRef.Number <> OSynchFilter."Master Table No.") or
                   (DependentRecRef.Number <> OSynchFilter."Table No.")
                then
                    exit(false);

                SourceFieldRef := DependentRecRef.Field(OSynchFilter."Field No.");
                TargetFieldRef := CollectionElementRecRef.Field(OSynchFilter."Master Table Field No.");

                if SourceFieldRef.Type <> TargetFieldRef.Type then
                    exit(false);

                TargetFieldRef.Validate(SourceFieldRef.Value);
            until OSynchFilter.Next = 0;

        exit(true);
    end;

    local procedure ModifyRecRef(var RecRef: RecordRef; xRecRef: RecordRef; ElementNo: Integer)
    var
        OSynchEntityElement1: Record "Outlook Synch. Entity Element";
        FldRef: FieldRef;
        xFldRef: FieldRef;
        ArrayPKFldRef: array[3] of FieldRef;
        xArrayPKFldRef: array[3] of FieldRef;
        PKeyRef: KeyRef;
        i: Integer;
        IsChanged: Boolean;
    begin
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            xFldRef := xRecRef.FieldIndex(i);
            if FldRef.Class = FieldClass::Normal then
                if Format(FldRef.Value) <> Format(xFldRef.Value) then
                    IsChanged := true;
        end;

        if IsChanged then begin
            PKeyRef := RecRef.KeyIndex(1);
            for i := 1 to PKeyRef.FieldCount do begin
                ArrayPKFldRef[i] := PKeyRef.FieldIndex(i);
                xArrayPKFldRef[i] := xRecRef.KeyIndex(1).FieldIndex(i);
                if Format(ArrayPKFldRef[i].Value) <> Format(xArrayPKFldRef[i].Value) then
                    if ElementNo = 0 then
                        Error(Text001, ArrayPKFldRef[i].Caption, OSynchEntity.Code)
                    else begin
                        OSynchEntityElement1.Get(OSynchEntity.Code, ElementNo);
                        Error(Text010, ArrayPKFldRef[i].Caption, OSynchEntityElement1."Outlook Collection", OSynchEntity.Code);
                    end;
            end;

            RecRef.Modify(true);
        end;
    end;

    procedure UpdateSynchronizationDate(UserID: Code[50]; RecID: RecordID)
    var
        OSynchLink: Record "Outlook Synch. Link";
    begin
        if not OSynchLink.Get(UserID, RecID) then
            exit;

        OSynchLink."Synchronization Date" := CurrentDateTime;
        OSynchLink.Modify();
    end;

    local procedure CheckCollectionElement(OSynchEntityElementIn: Record "Outlook Synch. Entity Element"; CollectionIterator: Text[38])
    var
        OSynchEntity1: Record "Outlook Synch. Entity";
        OSynchLink: Record "Outlook Synch. Link";
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchDependency: Record "Outlook Synch. Dependency";
        DependentRecRef: RecordRef;
        TempDependentRecRef: RecordRef;
        NullRecRef: RecordRef;
        RecID: RecordID;
        ContainerLocal: Text;
        DependentEntityIDHash: Text[32];
        ElementChildIterator: Text[38];
        IsEmptyEntryID: Boolean;
        DependencyFound: Boolean;
    begin
        if XMLTextReader.GetAllCurrentChildNodes(CollectionIterator, ElementChildIterator) <= 0 then begin
            XMLTextReader.RemoveIterator(ElementChildIterator);
            exit;
        end;

        Clear(ContainerLocal);
        IsEmptyEntryID := true;

        if XMLTextReader.GetName(ElementChildIterator) = 'EntryID' then begin
            ContainerLocal := Base64Convert.FromBase64(XMLTextReader.GetValue(ElementChildIterator));
            IsEmptyEntryID := ContainerLocal = '';
        end;

        OSynchEntityElementIn.CalcFields("No. of Dependencies");

        if IsEmptyEntryID and (OSynchEntityElementIn."No. of Dependencies" > 0) then
            Error(
              Text005,
              OSynchEntityElementIn."Synch. Entity Code",
              OSynchEntityElementIn."Outlook Collection");

        if not IsEmptyEntryID and (OSynchEntityElementIn."No. of Dependencies" = 0) then
            Error(Text006, OSynchEntityElementIn."Synch. Entity Code", OSynchEntityElementIn."Outlook Collection");

        if not IsEmptyEntryID then begin
            ContainerLocal := Base64Convert.FromBase64(XMLTextReader.GetValue(ElementChildIterator));
            DependentEntityIDHash := OSynchOutlookMgt.ComputeHash(ContainerLocal);
            if DependentEntityIDHash = '' then
                Error(Text007, OSynchEntityElementIn."Synch. Entity Code", OSynchEntityElementIn."Outlook Collection");

            ErrorConflictBuffer.Reset();
            ErrorConflictBuffer.SetRange("Outlook Entry ID Hash", DependentEntityIDHash);
            if ErrorConflictBuffer.FindFirst then
                Error(
                  Text008,
                  OSynchEntityElementIn."Synch. Entity Code",
                  OSynchEntityElementIn."Outlook Collection");

            OSynchLink.Reset();
            OSynchLink.SetRange("User ID", OSynchUserSetup."User ID");
            OSynchLink.SetRange("Outlook Entry ID Hash", DependentEntityIDHash);
            if not OSynchLink.FindFirst then
                Error(
                  Text008,
                  OSynchEntityElementIn."Synch. Entity Code",
                  OSynchEntityElementIn."Outlook Collection");

            Evaluate(RecID, Format(OSynchLink."Record ID"));
            DependentRecRef.Get(RecID);
            TempDependentRecRef.Open(RecID.TableNo, true);
            OSynchNAVMgt.CopyRecordReference(DependentRecRef, TempDependentRecRef, false);

            OSynchDependency.Reset();
            OSynchDependency.SetRange("Synch. Entity Code", OSynchEntityElementIn."Synch. Entity Code");
            OSynchDependency.SetRange("Element No.", OSynchEntityElementIn."Element No.");
            OSynchDependency.CalcFields("Depend. Synch. Entity Tab. No.");
            OSynchDependency.SetRange("Depend. Synch. Entity Tab. No.", RecID.TableNo);
            if not OSynchDependency.Find('-') then
                Error(Text006, OSynchEntityElementIn."Synch. Entity Code", OSynchEntityElementIn."Outlook Collection");

            DependencyFound := false;
            repeat
                OSynchEntity1.Get(OSynchDependency."Depend. Synch. Entity Code");
                OSynchFilter.Reset();
                OSynchFilter.SetRange("Record GUID", OSynchEntity1."Record GUID");
                if OSynchFilter.FindFirst then
                    TempDependentRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, NullRecRef));

                if TempDependentRecRef.Find('-') then
                    DependencyFound := true;
            until OSynchDependency.Next = 0;

            if not DependencyFound then
                Error(Text006, OSynchEntityElementIn."Synch. Entity Code", OSynchEntityElementIn."Outlook Collection");
        end;
        XMLTextReader.RemoveIterator(ElementChildIterator);
    end;

    procedure CheckEntityIdentity(RecID: RecordID; SynchEntityCode: Code[10]): Boolean
    var
        OSynchEntity1: Record "Outlook Synch. Entity";
        OSynchFilter: Record "Outlook Synch. Filter";
        EntityRecRef: RecordRef;
        TempEntityRecRef: RecordRef;
        NullRecRef: RecordRef;
    begin
        OSynchEntity1.Get(SynchEntityCode);
        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", OSynchEntity1."Record GUID");
        OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::Condition);

        EntityRecRef.Get(RecID);
        TempEntityRecRef.Open(RecID.TableNo, true);
        OSynchNAVMgt.CopyRecordReference(EntityRecRef, TempEntityRecRef, false);
        TempEntityRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, NullRecRef));
        if not TempEntityRecRef.Find('-') then
            exit(false);

        exit(true);
    end;

    procedure CheckUserSettingsForConflicts(var SynchRecRef: RecordRef; TableID: Integer)
    var
        OSynchFilter: Record "Outlook Synch. Filter";
        TempRecRef: RecordRef;
        NullRecRef: RecordRef;
    begin
        if OSynchUserSetup."Synch. Direction" = OSynchUserSetup."Synch. Direction"::"Outlook to Microsoft Dynamics NAV" then
            Error(Text009, OSynchUserSetup."Synch. Entity Code");

        OSynchFilter.Reset();
        OSynchFilter.SetFilter(
          "Record GUID",
          '%1|%2',
          OSynchEntity."Record GUID",
          OSynchUserSetup."Record GUID");

        TempRecRef.Open(TableID, true);
        OSynchNAVMgt.CopyRecordReference(SynchRecRef, TempRecRef, false);
        TempRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, NullRecRef));
        if not TempRecRef.Find('-') then
            Error(Text009, OSynchUserSetup."Synch. Entity Code");
        TempRecRef.Close;
    end;

    procedure CheckKeyField(TableID: Integer; FieldID: Integer): Boolean
    var
        CheckRecordRef: RecordRef;
        CheckKeyRef: KeyRef;
        CheckFieldRef: FieldRef;
        Counter: Integer;
    begin
        CheckRecordRef.Open(TableID, true);
        CheckKeyRef := CheckRecordRef.KeyIndex(1);

        for Counter := 1 to CheckKeyRef.FieldCount do begin
            CheckFieldRef := CheckKeyRef.FieldIndex(Counter);
            if CheckFieldRef.Number = FieldID then
                exit(true);
        end;

        CheckRecordRef.Close;
    end;

    local procedure ConflictDetected(SynchRecRef: RecordRef; LastSynchTime: DateTime) IsConflict: Boolean
    var
        ChangeLogEntry: Record "Change Log Entry";
        OSynchLink: Record "Outlook Synch. Link";
        RecID: RecordID;
    begin
        Evaluate(RecID, Format(SynchRecRef.RecordId));

        if not OSynchLink.Get(OSynchUserSetup."User ID", RecID) then
            exit;

        ChangeLogEntry.SetCurrentKey("Table No.", "Primary Key Field 1 Value");
        FilterChangeLog(RecID, ChangeLogEntry);
        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Modification);

        if OSynchLink."Synchronization Date" >= LastSynchTime then begin
            ChangeLogEntry.SetFilter("Date and Time", '>=%1', LastSynchTime);
            if not ChangeLogEntry.FindLast then
                exit;

            if ChangeLogEntry."Date and Time" <= OSynchLink."Synchronization Date" then
                exit;

            ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchLink."Synchronization Date");
        end else
            ChangeLogEntry.SetFilter("Date and Time", '>=%1', LastSynchTime);

        if not ChangeLogEntry.FindFirst then
            exit;

        IsConflict := IsConflictDetected(ChangeLogEntry, SynchRecRef, RecID.TableNo);
    end;

    procedure IsConflictDetected(var ChangeLogEntry: Record "Change Log Entry"; SynchRecRef: RecordRef; TableNo: Integer) IsConflict: Boolean
    var
        OutlookSynchField: Record "Outlook Synch. Field";
    begin
        OutlookSynchField.Reset();
        OutlookSynchField.SetRange("Synch. Entity Code", OSynchEntity.Code);
        OutlookSynchField.SetRange("Element No.", 0);
        OutlookSynchField.SetFilter("Read-Only Status", '<>%1',
          OutlookSynchField."Read-Only Status"::"Read-Only in Microsoft Dynamics NAV");
        IsConflict := SetupFieldsModified(ChangeLogEntry, OutlookSynchField);

        if IsConflict then
            CheckUserSettingsForConflicts(SynchRecRef, TableNo);
    end;

    local procedure CollectionConflictDetected(OSynchEntityElementIn: Record "Outlook Synch. Entity Element"; EntityRecRef: RecordRef; LastSynchTime: DateTime) IsConflict: Boolean
    var
        ChangeLogEntry: Record "Change Log Entry";
        TempChangeLogEntry: Record "Change Log Entry" temporary;
        OSynchLink: Record "Outlook Synch. Link";
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchField: Record "Outlook Synch. Field";
        CollectionRecRef: RecordRef;
        CollectionFieldRef: FieldRef;
        RecID: RecordID;
        FilteringExpression: Text;
    begin
        Evaluate(RecID, Format(EntityRecRef.RecordId));
        if not OSynchLink.Get(OSynchUserSetup."User ID", RecID) then
            exit;

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", OSynchEntityElementIn."Record GUID");
        FilteringExpression := OSynchSetupMgt.ComposeTableFilter(OSynchFilter, EntityRecRef);

        ChangeLogEntry.SetCurrentKey("Table No.", "Date and Time");
        ChangeLogEntry.SetRange("Table No.", OSynchEntityElementIn."Table No.");

        if OSynchLink."Synchronization Date" >= LastSynchTime then begin
            ChangeLogEntry.SetFilter("Date and Time", '>=%1', LastSynchTime);
            if not ChangeLogEntry.FindLast then
                exit;
            if ChangeLogEntry."Date and Time" <= OSynchLink."Synchronization Date" then
                exit;
            ChangeLogEntry.SetFilter("Date and Time", '>=%1', OSynchLink."Synchronization Date");
        end else
            ChangeLogEntry.SetFilter("Date and Time", '>=%1&<=%2', LastSynchTime, StartDateTime);

        ChangeLogEntry.SetFilter("Type of Change", '<>%1', ChangeLogEntry."Type of Change"::Deletion);
        if not ChangeLogEntry.IsEmpty then begin
            ChangeLogEntry.SetCurrentKey("Table No.", "Primary Key Field 1 Value");
            CollectionRecRef.Open(OSynchEntityElementIn."Table No.");
            CollectionRecRef.SetView(FilteringExpression);
            if CollectionRecRef.Find('-') then
                repeat
                    Evaluate(RecID, Format(CollectionRecRef.RecordId));
                    FilterChangeLog(RecID, ChangeLogEntry);
                    if ChangeLogEntry.FindFirst then begin
                        OSynchField.Reset();
                        OSynchField.SetRange("Synch. Entity Code", OSynchEntityElementIn."Synch. Entity Code");
                        OSynchField.SetRange("Element No.", OSynchEntityElementIn."Element No.");
                        OSynchField.SetFilter("Read-Only Status", '<>%1', OSynchField."Read-Only Status"::"Read-Only in Microsoft Dynamics NAV");

                        IsConflict := SetupFieldsModified(ChangeLogEntry, OSynchField);
                        if IsConflict then begin
                            Evaluate(RecID, Format(EntityRecRef.RecordId));
                            CheckUserSettingsForConflicts(EntityRecRef, RecID.TableNo);
                            exit;
                        end;
                    end;
                until CollectionRecRef.Next = 0;
            CollectionRecRef.Close;
        end;

        ChangeLogEntry.SetRange("Primary Key Field 1 Value");
        ChangeLogEntry.SetRange("Primary Key Field 1 No.");
        ChangeLogEntry.SetRange("Primary Key Field 2 No.");
        ChangeLogEntry.SetRange("Primary Key Field 2 Value");
        ChangeLogEntry.SetRange("Primary Key Field 3 No.");
        ChangeLogEntry.SetRange("Primary Key Field 3 Value");

        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Deletion);
        ChangeLogEntry.SetCurrentKey("Table No.", "Date and Time");
        if ChangeLogEntry.IsEmpty then
            exit;

        TempChangeLogEntry.Reset();
        TempChangeLogEntry.DeleteAll();

        OSynchNAVMgt.RemoveChangeLogDuplicates(ChangeLogEntry, TempChangeLogEntry);
        ChangeLogEntry.SetCurrentKey("Table No.", "Primary Key Field 1 Value");
        if TempChangeLogEntry.Find('-') then
            repeat
                CollectionRecRef.Open(OSynchEntityElementIn."Table No.", true);
                CollectionRecRef.Init();
                ChangeLogEntry.SetRange("Primary Key", TempChangeLogEntry."Primary Key");
                ChangeLogEntry.SetRange("Primary Key Field 1 Value", TempChangeLogEntry."Primary Key Field 1 Value");
                if ChangeLogEntry.FindSet then
                    repeat
                        OSynchFilter.SetRange("Field No.", ChangeLogEntry."Field No.");
                        if OSynchFilter.FindFirst then begin
                            CollectionFieldRef := CollectionRecRef.Field(ChangeLogEntry."Field No.");
                            if not
                               OSynchTypeConversion.EvaluateTextToFieldRef(
                                 OSynchTypeConversion.SetValueFormat(ChangeLogEntry."Old Value", CollectionFieldRef),
                                 CollectionFieldRef,
                                 false)
                            then
                                Error(
                                  Text010,
                                  CollectionFieldRef.Caption,
                                  OSynchEntityElementIn."Outlook Collection",
                                  OSynchEntityElementIn."Synch. Entity Code");
                        end;
                    until ChangeLogEntry.Next = 0;
                CollectionRecRef.Insert();

                CollectionRecRef.SetView(FilteringExpression);
                IsConflict := CollectionRecRef.Find('-');
                if IsConflict then begin
                    Evaluate(RecID, Format(EntityRecRef.RecordId));
                    CheckUserSettingsForConflicts(EntityRecRef, RecID.TableNo);
                    exit;
                end;
                CollectionRecRef.Close;
            until TempChangeLogEntry.Next = 0;
    end;

    procedure FindEntityElementBySearchField(SynchEntityCode: Code[10]; ElementNo: Integer; EntityRecRef: RecordRef; TemplateEntityElementRecRef: RecordRef; var RecID: RecordID)
    var
        OSynchEntityElement1: Record "Outlook Synch. Entity Element";
        OSynchFilter: Record "Outlook Synch. Filter";
        TempOSynchFilter: Record "Outlook Synch. Filter" temporary;
        TempOSynchFilter1: Record "Outlook Synch. Filter" temporary;
        OSynchField: Record "Outlook Synch. Field";
        CollectionElementRecRef: RecordRef;
        TempCollectionElementRecRef: RecordRef;
        RelatedRecRef: RecordRef;
        NullRecRef: RecordRef;
        FieldRef: FieldRef;
        RelatedFieldRef: FieldRef;
    begin
        Clear(RecID);
        OSynchEntityElement1.Get(SynchEntityCode, ElementNo);
        TempCollectionElementRecRef.Open(OSynchEntityElement1."Table No.", true);

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", OSynchEntityElement1."Record GUID");
        if OSynchFilter.FindFirst then begin
            CollectionElementRecRef.Open(OSynchEntityElement1."Table No.");
            CollectionElementRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(OSynchFilter, EntityRecRef));
            if CollectionElementRecRef.Find('-') then
                repeat
                    OSynchNAVMgt.CopyRecordReference(CollectionElementRecRef, TempCollectionElementRecRef, false);
                until CollectionElementRecRef.Next = 0;
            CollectionElementRecRef.Close;
        end;

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", SynchEntityCode);
        OSynchField.SetRange("Element No.", ElementNo);
        OSynchField.SetRange("Search Field", true);
        if OSynchField.Find('-') then
            repeat
                if OSynchField."Table No." = 0 then begin
                    FieldRef := TemplateEntityElementRecRef.Field(OSynchField."Field No.");
                    OSynchSetupMgt.CreateFilterCondition(
                      TempOSynchFilter,
                      OSynchField."Master Table No.",
                      OSynchField."Field No.",
                      TempOSynchFilter.Type::FILTER,
                      Format(FieldRef.Value));
                end else begin
                    TempOSynchFilter1.Reset();
                    TempOSynchFilter1.DeleteAll();

                    OSynchFilter.Reset();
                    OSynchFilter.SetRange("Record GUID", OSynchField."Record GUID");
                    OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
                    OSynchFilter.SetRange(Type, OSynchFilter.Type::CONST);
                    OSynchSetupMgt.CopyFilterRecords(OSynchFilter, TempOSynchFilter1);

                    RelatedFieldRef := TemplateEntityElementRecRef.Field(OSynchField."Field No.");
                    OSynchSetupMgt.CreateFilterCondition(
                      TempOSynchFilter1,
                      OSynchField."Table No.",
                      OSynchField."Field No.",
                      TempOSynchFilter1.Type::FILTER,
                      Format(RelatedFieldRef.Value));

                    RelatedRecRef.Open(OSynchField."Table No.");
                    RelatedRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(TempOSynchFilter1, NullRecRef));
                    if RelatedRecRef.Find('-') then begin
                        OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                        if OSynchFilter.Find('-') then
                            repeat
                                FieldRef := TemplateEntityElementRecRef.Field(OSynchFilter."Master Table Field No.");
                                RelatedFieldRef := RelatedRecRef.Field(OSynchFilter."Field No.");

                                TempOSynchFilter.Reset();
                                TempOSynchFilter.SetRange("Field No.", OSynchFilter."Master Table Field No.");
                                if not TempOSynchFilter.FindFirst then
                                    OSynchSetupMgt.CreateFilterCondition(
                                      TempOSynchFilter,
                                      OSynchFilter."Master Table No.",
                                      OSynchFilter."Master Table Field No.",
                                      TempOSynchFilter.Type::FILTER,
                                      Format(RelatedFieldRef.Value));
                            until OSynchFilter.Next = 0;
                    end;
                    RelatedRecRef.Close;
                end;
            until OSynchField.Next = 0;

        TempOSynchFilter.Reset();
        if TempOSynchFilter.FindFirst then begin
            TempCollectionElementRecRef.SetView(OSynchSetupMgt.ComposeTableFilter(TempOSynchFilter, NullRecRef));

            if TempCollectionElementRecRef.Find('-') then
                Evaluate(RecID, Format(TempCollectionElementRecRef.RecordId));
        end;
    end;

    procedure FilterChangeLog(RecID: RecordID; var ChangeLogEntry: Record "Change Log Entry")
    var
        SynchRecRef: RecordRef;
        KeyRef: KeyRef;
        KeyFldRef: FieldRef;
        i: Integer;
        MaxKeyCount: Integer;
    begin
        SynchRecRef := RecID.GetRecord;

        ChangeLogEntry.SetRange("Table No.", RecID.TableNo);

        KeyRef := SynchRecRef.KeyIndex(1);
        MaxKeyCount := KeyRef.FieldCount;
        if MaxKeyCount > 3 then
            MaxKeyCount := 3;
        for i := 1 to MaxKeyCount do begin
            KeyFldRef := KeyRef.FieldIndex(i);
            case i of
                1:
                    begin
                        ChangeLogEntry.SetRange("Primary Key Field 1 No.", KeyFldRef.Number);
                        ChangeLogEntry.SetRange("Primary Key Field 1 Value", CopyStr(Format(KeyFldRef.Value, 0, 9), 1, 50));
                    end;
                2:
                    begin
                        ChangeLogEntry.SetRange("Primary Key Field 2 No.", KeyFldRef.Number);
                        ChangeLogEntry.SetRange("Primary Key Field 2 Value", CopyStr(Format(KeyFldRef.Value, 0, 9), 1, 50));
                    end;
                3:
                    begin
                        ChangeLogEntry.SetRange("Primary Key Field 3 No.", KeyFldRef.Number);
                        ChangeLogEntry.SetRange("Primary Key Field 3 Value", CopyStr(Format(KeyFldRef.Value, 0, 9), 1, 50));
                    end;
            end;
        end;
    end;

    procedure SetupFieldsModified(var ChangeLogEntry: Record "Change Log Entry"; var OSynchField: Record "Outlook Synch. Field"): Boolean
    var
        OSynchFilter: Record "Outlook Synch. Filter";
    begin
        if OSynchField.Find('-') then
            repeat
                if OSynchField."Table No." = 0 then begin
                    ChangeLogEntry.SetRange("Field No.", OSynchField."Field No.");
                    if ChangeLogEntry.Find('-') then begin
                        ChangeLogEntry.SetRange("Field No.");
                        exit(true);
                    end;
                end else begin
                    OSynchFilter.Reset();
                    OSynchFilter.SetRange("Record GUID", OSynchField."Record GUID");
                    OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
                    OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                    if OSynchFilter.Find('-') then
                        repeat
                            ChangeLogEntry.SetRange("Field No.", OSynchFilter."Master Table Field No.");
                            if ChangeLogEntry.Find('-') then begin
                                ChangeLogEntry.SetRange("Field No.");
                                exit(true);
                            end;
                        until OSynchFilter.Next = 0;
                end;
            until OSynchField.Next = 0;

        ChangeLogEntry.SetRange("Field No.");
    end;

    procedure OneToOneRelation(var OSynchFilter: Record "Outlook Synch. Filter"): Boolean
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        Counter: Integer;
    begin
        OSynchFilter.FindFirst;

        RecRef.Open(OSynchFilter."Table No.", true);
        KeyRef := RecRef.KeyIndex(1);

        for Counter := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(Counter);
            OSynchFilter.SetRange("Field No.", FieldRef.Number);
            if not OSynchFilter.FindFirst then
                exit(false);
        end;

        RecRef.Close;
        exit(true);
    end;
}

