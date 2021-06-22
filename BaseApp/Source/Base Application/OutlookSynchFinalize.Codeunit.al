codeunit 5311 "Outlook Synch. Finalize"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'The synchronization failed because the synchronization data from Microsoft Outlook cannot be processed. Try again later and if the problem persists contact your system administrator.';

    [Scope('OnPrem')]
    procedure Finalize(UserID: Code[50]; var XMLMessage: Text)
    var
        OSynchTypeConversion: Codeunit "Outlook Synch. Type Conv";
        XmlTextReader: DotNet "OLSync.Common.XmlTextReader";
        StartSynchTime: DateTime;
        TagName: Text[80];
        RootIterator: Text[38];
        StartSynchTimeText: Text[30];
    begin
        XmlTextReader := XmlTextReader.XmlTextReader;

        if not XmlTextReader.LoadXml(XMLMessage) then
            Error(Text001);

        TagName := XmlTextReader.RootLocalName;
        if TagName <> 'Finalize' then
            Error(Text001);

        XmlTextReader.SelectElements(RootIterator, 'Finalize');
        StartSynchTimeText := XmlTextReader.GetCurrentNodeAttribute(RootIterator, 'StartSynchTime');
        if not OSynchTypeConversion.TextToDateTime(StartSynchTimeText, StartSynchTime) then
            Error(Text001);

        UpdateLastSynchronizationTime(UserID, StartSynchTime);
        XMLMessage := '';
    end;

    local procedure UpdateLastSynchronizationTime(UserID: Code[50]; StartSynchTime: DateTime)
    var
        OSynchUserSetup: Record "Outlook Synch. User Setup";
    begin
        OSynchUserSetup.Reset();
        OSynchUserSetup.SetRange("User ID", UserID);
        if OSynchUserSetup.Find('-') then
            repeat
                OSynchUserSetup."Last Synch. Time" := StartSynchTime;
                OSynchUserSetup.Modify();
            until OSynchUserSetup.Next = 0;
    end;
}

