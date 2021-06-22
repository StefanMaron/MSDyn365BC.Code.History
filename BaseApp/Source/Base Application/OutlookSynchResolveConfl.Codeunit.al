codeunit 5310 "Outlook Synch. Resolve Confl."
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'The synchronization failed because the synchronization data from Microsoft Outlook cannot be processed. Try again later and if the problem persists contact your system administrator.';
        Text002: Label 'The synchronization failed because the synchronization data from %1 could not be sent. Try again later and if the problem persists contact your system administrator.', Comment = '%1 - product name';

    [Scope('OnPrem')]
    procedure Process(UserID: Code[50]; var XMLMessage: Text)
    var
        OsynchOutlookMgt: Codeunit "Outlook Synch. Outlook Mgt.";
        ErrorLogXMLWriter: DotNet "OLSync.Common.XmlTextWriter";
    begin
        if not (StrLen(XMLMessage) > 0) then
            Error(Text001);

        ErrorLogXMLWriter := ErrorLogXMLWriter.XmlTextWriter;
        ErrorLogXMLWriter.WriteStartDocument;
        ErrorLogXMLWriter.WriteStartElement('SynchronizationMessage');

        OsynchOutlookMgt.ProcessOutlookChanges(UserID, XMLMessage, ErrorLogXMLWriter, true);

        if not IsNull(ErrorLogXMLWriter) then begin
            ErrorLogXMLWriter.WriteEndElement;
            ErrorLogXMLWriter.WriteEndDocument;

            XMLMessage := ErrorLogXMLWriter.ToString;
            Clear(ErrorLogXMLWriter);

            if StrLen(XMLMessage) = 0 then
                Error(Text002, PRODUCTNAME.Full);
        end;
    end;
}

