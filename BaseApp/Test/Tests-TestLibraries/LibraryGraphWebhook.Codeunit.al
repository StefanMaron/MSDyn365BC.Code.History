codeunit 130624 "Library - Graph Webhook"
{
    TableNo = "Webhook Notification Trigger";

    trigger OnRun()
    var
        LibraryGraphSync: Codeunit "Library - Graph Sync";
    begin
        BindSubscription(GraphBackgroundSyncSubscr);
        LibraryGraphSync.RegisterMockConnections;
        LibraryGraphSync.MockIncomingContactId(ContactID, ChangeType);
    end;

    var
        GraphBackgroundSyncSubscr: Codeunit "Graph Background Sync. Subscr.";
}

