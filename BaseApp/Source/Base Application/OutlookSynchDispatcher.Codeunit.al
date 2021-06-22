codeunit 5313 "Outlook Synch. Dispatcher"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'The synchronization failed because the %1 user has no entities to synchronize. Try to synchronize again. If the problem continues, contact your system administrator.';

    procedure ExportSchema(var XMLMessage: Text)
    var
        OsynchExportSchema: Codeunit "Outlook Synch. Export Schema";
    begin
        AssertIsOSyncUser(UserId);
        OsynchExportSchema.Export(UserId, XMLMessage);
    end;

    procedure BeginQuickSync(var XMLMessage: Text)
    var
        OsynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
    begin
        AssertIsOSyncUser(UserId);
        OsynchNAVMgt.StartSynchronization(UserId, XMLMessage, false);
    end;

    procedure BeginFullSync(var XMLMessage: Text)
    var
        OsynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
    begin
        AssertIsOSyncUser(UserId);
        OsynchNAVMgt.StartSynchronization(UserId, XMLMessage, true);
    end;

    procedure PostUpdate(var XMLMessage: Text)
    var
        OsynchProcessLinks: Codeunit "Outlook Synch. Process Links";
    begin
        AssertIsOSyncUser(UserId);
        OsynchProcessLinks.ProcessOutlookEntryIDResponse(UserId, XMLMessage);
    end;

    procedure ResolveConflicts(var XMLMessage: Text)
    var
        OsynchResolveConfl: Codeunit "Outlook Synch. Resolve Confl.";
    begin
        AssertIsOSyncUser(UserId);
        OsynchResolveConfl.Process(UserId, XMLMessage);
    end;

    procedure Finalize(var XMLMessage: Text)
    var
        OsynchFinalize: Codeunit "Outlook Synch. Finalize";
    begin
        AssertIsOSyncUser(UserId);
        OsynchFinalize.Finalize(UserId, XMLMessage);
    end;

    procedure CollectConflictedEntities(var XMLMessage: Text)
    var
        OsynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
    begin
        AssertIsOSyncUser(UserId);
        OsynchNAVMgt.CollectConflictedEntities(UserId, XMLMessage);
    end;

    local procedure AssertIsOSyncUser(UserID: Code[50])
    var
        OsynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
    begin
        if not OsynchNAVMgt.IsOSyncUser(UserID) then
            Error(Text001, UserID);
    end;
}

