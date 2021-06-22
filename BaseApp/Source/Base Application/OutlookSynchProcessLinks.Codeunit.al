codeunit 5309 "Outlook Synch. Process Links"
{

    trigger OnRun()
    begin
    end;

    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchLink: Record "Outlook Synch. Link";
        OSynchUserSetup: Record "Outlook Synch. User Setup";
        Base64Convert: Codeunit "Base64 Convert";
        OSynchTypeConversion: Codeunit "Outlook Synch. Type Conv";
        OSynchProcessLine: Codeunit "Outlook Synch. Process Line";
        OsynchOutlookMgt: Codeunit "Outlook Synch. Outlook Mgt.";
        ErrorXMLWriter: DotNet "OLSync.Common.XmlTextWriter";
        OResponseXMLTextReader: DotNet "OLSync.Common.XmlTextReader";
        StartDateTime: DateTime;
        RootIterator: Text[38];
        Text001: Label 'The synchronization failed because the synchronization data from Microsoft Outlook cannot be processed. Try again later and if the problem persists contact your system administrator.';
        Text002: Label 'The synchronization for an item in the %1 entity completed with an error. Please try to synchronize this item again later. If the problem persists contact your system administrator.';
        Text003: Label 'An Outlook item in the %1 entity was not synchronized because this entity does not exist. Try again later and if the problem persists contact your system administrator.';
        Text004: Label 'An Outlook item in the %1 entity was not synchronized because this item could not be found in the synchronization folders. Try again later and if the problem persists contact your system administrator.';
        Text005: Label 'An Outlook item in the %1 entity was not synchronized because the synchronization data from Microsoft Outlook cannot be processed. Try again later and if the problem persists contact your system administrator.';
        Text006: Label 'The synchronization failed because the synchronization data could not be sent from %1. Try again later and if the problem persists contact your system administrator.', Comment = '%1 - product name';

    [Scope('OnPrem')]
    procedure ProcessOutlookEntryIDResponse(UserID: Code[50]; var XMLMessage: Text)
    var
        EntityRecRef: RecordRef;
        EntityRecID: RecordID;
        EntryIDContainer: Text;
        NewEntryIDContainer: Text;
        SynchEntityCode: Code[10];
        TagName: Text[1024];
        EntityIterator: Text[38];
        OEntryIDHash: Text[32];
        NewOEntryIDHash: Text[32];
        RecordIDTextValue: Text[250];
        StartSynchTimeText: Text[30];
    begin
        OResponseXMLTextReader := OResponseXMLTextReader.XmlTextReader;

        if not OResponseXMLTextReader.LoadXml(XMLMessage) then
            Error(Text001);

        OSynchUserSetup.Reset();
        OSynchUserSetup.SetRange("User ID", UserID);
        if not OSynchUserSetup.FindFirst then
            exit;

        TagName := OResponseXMLTextReader.RootLocalName;
        if TagName <> 'PostUpdate' then
            Error(Text001);

        OResponseXMLTextReader.SelectElements(RootIterator, 'PostUpdate');
        StartSynchTimeText := OResponseXMLTextReader.GetCurrentNodeAttribute(RootIterator, 'StartSynchTime');
        if not OSynchTypeConversion.TextToDateTime(StartSynchTimeText, StartDateTime) then
            Error(Text001);

        if OResponseXMLTextReader.SelectElements(RootIterator, '*') < 1 then
            exit;

        TagName := OResponseXMLTextReader.GetName(RootIterator);
        if TagName <> 'BriefOutlookItem' then
            Error(Text001);

        if IsNull(ErrorXMLWriter) then begin
            ErrorXMLWriter := ErrorXMLWriter.XmlTextWriter;
            ErrorXMLWriter.WriteStartDocument;
            ErrorXMLWriter.WriteStartElement('PostUpdate');
        end;

        if OResponseXMLTextReader.SelectElements(RootIterator, 'child::BriefOutlookItem') > 0 then begin
            Clear(EntryIDContainer);
            Clear(NewEntryIDContainer);

            repeat
                OEntryIDHash := '';
                NewOEntryIDHash := '';
                Clear(EntityRecID);

                SynchEntityCode := CopyStr(
                    OResponseXMLTextReader.GetCurrentNodeAttribute(RootIterator, 'SynchEntityCode'), 1, MaxStrLen(SynchEntityCode));
                if OSynchUserSetup.Get(UserID, SynchEntityCode) then begin
                    if OSynchEntity.Get(SynchEntityCode) then begin
                        RecordIDTextValue := OResponseXMLTextReader.GetCurrentNodeAttribute(RootIterator, 'RecordID');
                        OResponseXMLTextReader.GetAllCurrentChildNodes(RootIterator, EntityIterator);
                        TagName := OResponseXMLTextReader.GetName(EntityIterator);
                        if TagName <> 'EntryID' then
                            Error(Text001);
                        OEntryIDHash := GetEntryIDHash(EntryIDContainer, EntityIterator);
                        if OEntryIDHash <> '' then begin
                            OResponseXMLTextReader.MoveNext(EntityIterator);
                            TagName := OResponseXMLTextReader.GetName(EntityIterator);
                            NewOEntryIDHash := GetEntryIDHash(NewEntryIDContainer, EntityIterator);
                            OSynchLink.Reset();
                            OSynchLink.SetRange("User ID", UserID);
                            OSynchLink.SetRange("Outlook Entry ID Hash", OEntryIDHash);
                            if OSynchLink.FindFirst then begin
                                Evaluate(EntityRecID, Format(OSynchLink."Record ID"));
                                EntityRecRef.Open(OSynchEntity."Table No.");
                                if TagName <> 'NewEntryID' then
                                    WriteErrorLog(
                                      EntityRecID,
                                      SynchEntityCode,
                                      Text001,
                                      StartDateTime,
                                      EntryIDContainer);
                                if NewOEntryIDHash <> '' then
                                    OSynchLink.PutEntryID(NewEntryIDContainer, NewOEntryIDHash)
                                else
                                    WriteErrorLog(
                                      EntityRecID,
                                      SynchEntityCode,
                                      StrSubstNo(Text004, SynchEntityCode),
                                      StartDateTime,
                                      NewEntryIDContainer);
                                EntityRecRef.Close;
                            end else
                                if RecordIDTextValue = '' then
                                    WriteErrorLog(
                                      EntityRecID,
                                      SynchEntityCode,
                                      StrSubstNo(Text005, SynchEntityCode),
                                      StartDateTime,
                                      EntryIDContainer)
                                else begin
                                    Evaluate(EntityRecID, RecordIDTextValue);
                                    EntityRecRef.Open(EntityRecID.TableNo);
                                    if EntityRecRef.Get(EntityRecID) then begin
                                        if NewOEntryIDHash <> '' then
                                            OSynchLink.InsertOSynchLink(OSynchUserSetup."User ID", NewEntryIDContainer, EntityRecRef, NewOEntryIDHash)
                                        else
                                            OSynchLink.InsertOSynchLink(OSynchUserSetup."User ID", EntryIDContainer, EntityRecRef, OEntryIDHash);
                                        OSynchProcessLine.UpdateSynchronizationDate(OSynchUserSetup."User ID", EntityRecID);
                                    end else
                                        WriteErrorLog(
                                          EntityRecID,
                                          SynchEntityCode,
                                          StrSubstNo(Text002, SynchEntityCode),
                                          StartDateTime,
                                          EntryIDContainer);
                                    EntityRecRef.Close;
                                end;
                        end else
                            WriteErrorLog(
                              EntityRecID,
                              SynchEntityCode,
                              StrSubstNo(Text004, SynchEntityCode),
                              StartDateTime,
                              EntryIDContainer);
                        OResponseXMLTextReader.RemoveIterator(EntityIterator);
                    end else
                        WriteErrorLog(
                          EntityRecID,
                          SynchEntityCode,
                          StrSubstNo(Text003, SynchEntityCode),
                          StartDateTime,
                          EntryIDContainer);
                end;
            until not OResponseXMLTextReader.MoveNext(RootIterator);
        end;

        OResponseXMLTextReader.RemoveIterator(RootIterator);
        Clear(OResponseXMLTextReader);

        ErrorXMLWriter.WriteEndElement;
        ErrorXMLWriter.WriteEndDocument;

        XMLMessage := ErrorXMLWriter.ToString;
        Clear(ErrorXMLWriter);

        if StrLen(XMLMessage) = 0 then
            Error(Text006, PRODUCTNAME.Full);
    end;

    [Scope('OnPrem')]
    procedure GetEntryIDHash(var Container: Text; EntityIterator: Text[38]) EntryIDHash: Text[32]
    begin
        if (OResponseXMLTextReader.GetName(EntityIterator) = 'EntryID') or
           (OResponseXMLTextReader.GetName(EntityIterator) = 'NewEntryID')
        then begin
            Container := Base64Convert.FromBase64(OResponseXMLTextReader.GetValue(EntityIterator));
            EntryIDHash := OsynchOutlookMgt.ComputeHash(Container);
        end;
    end;

    local procedure WriteErrorLog(ErrorRecordID: RecordID; SynchEntityCode: Code[10]; Description: Text[1024]; StartDateTimeIn: DateTime; Container: Text)
    begin
        ErrorXMLWriter.WriteStartElement('Error');
        ErrorXMLWriter.WriteAttribute('SynchEntityCode', SynchEntityCode);

        ErrorXMLWriter.WriteAttribute('RecordID', Format(ErrorRecordID));
        ErrorXMLWriter.WriteAttribute('OccurrenceTime', OSynchTypeConversion.SetDateTimeFormat(CurrentDateTime));
        ErrorXMLWriter.WriteAttribute('Description', Description);

        ErrorXMLWriter.WriteAttribute(
          'LastModificationTime',
          OSynchTypeConversion.SetDateTimeFormat(StartDateTimeIn));

        ErrorXMLWriter.WriteAttribute('RecordID', Format(ErrorRecordID));
        ErrorXMLWriter.WriteStartElement('EntryID');
        ErrorXMLWriter.WriteElementTextContent(Base64Convert.ToBase64(Container));
        ErrorXMLWriter.WriteEndElement;

        ErrorXMLWriter.WriteEndElement;
    end;
}

