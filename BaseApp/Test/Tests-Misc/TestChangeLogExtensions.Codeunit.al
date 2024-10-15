codeunit 139131 "Test Change Log Extensions"
{
    Permissions = TableData "Change Log Entry" = rimd;
    Subtype = Test;
    EventSubscriberInstance = manual;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Change Log Extensions]
    end;

    [Test]
    procedure TestWithNoSubscriber()
    var
        ChangeLogEntry: record "Change Log Entry";
        RecRef: RecordRef;
        ChangeLogMgtSubscriber2: codeunit "Change Log Mgt. Subscriber2";
        ChangeLogManagement: codeunit "Change Log Management";
    begin
        //[WHEN][There are no change log entries and no subscriber]
        ChangeLogEntry.DeleteAll();
        ChangeLogMgtSubscriber2.SetTableNo(Database::Customer);
        BindSubscription(ChangeLogMgtSubscriber2);

        //[IF][The user makes a change to a record that is to be logged]
        RecRef.Open(Database::Customer);
        RecRef.FindFirst();
        ChangeLogManagement.LogInsertion(RecRef);

        //[THEN][A change log entry is inserted into the database]
        UnBindSubscription(ChangeLogMgtSubscriber2);
        ChangeLogEntry.SetRange("Table No.", Database::Customer);
        ChangeLogEntry.FindFirst();
    end;

    [Test]
    procedure TestWithSubscriber()
    var
        ChangeLogEntry: record "Change Log Entry";
        RecRef: RecordRef;
        ChangeLogMgtSubscriber: codeunit "Change Log Mgt. Subscriber";
        ChangeLogMgtSubscriber2: codeunit "Change Log Mgt. Subscriber2";
        ChangeLogManagement: codeunit "Change Log Management";
    begin
        //[WHEN][There are no change log entries and no subscriber]
        ChangeLogEntry.DeleteAll();
        ChangeLogMgtSubscriber2.SetTableNo(Database::Vendor);
        BindSubscription(ChangeLogMgtSubscriber);
        BindSubscription(ChangeLogMgtSubscriber2);

        //[IF][The user makes a change to a record that is to be logged]
        RecRef.Open(Database::Vendor);
        RecRef.FindFirst();
        ChangeLogManagement.LogInsertion(RecRef);

        //[THEN][A change log entry is inserted into the database]
        UnBindSubscription(ChangeLogMgtSubscriber);
        UnBindSubscription(ChangeLogMgtSubscriber2);
        ChangeLogEntry.SetRange("Table No.", Database::Vendor);
        ASSERTERROR ChangeLogEntry.FindFirst();
    end;
}