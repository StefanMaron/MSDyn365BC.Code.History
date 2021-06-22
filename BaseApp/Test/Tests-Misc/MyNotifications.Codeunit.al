codeunit 139008 "My Notifications"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [My Notifications] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisableExistingNotification()
    var
        MyNotifications: Record "My Notifications";
        ID: array[2] of Guid;
    begin
        // [SCENARIO] Disable() returns TRUE if the notification is found and disabled
        // [GIVEN] Two notifications are enabled
        MyNotifications.DeleteAll();
        ID[1] := CreateGuid;
        MyNotifications.InsertDefault(ID[1], '', '', true);
        ID[2] := CreateGuid;
        MyNotifications.InsertDefault(ID[2], '', '', true);

        // [WHEN] Disable Notification 2
        Assert.IsTrue(MyNotifications.Disable(ID[2]), 'Should get TRUE for existing notification 2');
        // [THEN] Disable() returns TRUE; Notification 2 should be disabled,
        Assert.IsFalse(MyNotifications.IsEnabled(ID[2]), 'Notification 2 should be disabled');
        // [THEN] Notification 1 should be still enabled
        Assert.IsTrue(MyNotifications.IsEnabled(ID[1]), 'Notification 1 should be enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisableNotExistingNotification()
    var
        MyNotifications: Record "My Notifications";
        ID: array[2] of Guid;
    begin
        // [SCENARIO] Disable() returns FALSE if the notification is not found
        // [GIVEN] One notifications is enabled
        MyNotifications.DeleteAll();
        ID[1] := CreateGuid;
        MyNotifications.InsertDefault(ID[1], '', '', true);

        // [WHEN] try to Disable() not existing Notification 2
        ID[2] := CreateGuid;
        Assert.IsFalse(MyNotifications.Disable(ID[2]), 'Should get FALSE for not existing notification 2');
        // [THEN] Disable() returns FALSE
        // [THEN] Notification 1 should be still enabled
        Assert.IsTrue(MyNotifications.IsEnabled(ID[1]), 'Notification 1 should be enabled');
    end;
}

