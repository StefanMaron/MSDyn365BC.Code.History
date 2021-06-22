codeunit 132593 "OAuth Management Test"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Functionality of <<OAuth Management>> has been moved to System module, and the method tested in this codeunit has been removed.';
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteTag = '16.0';

    trigger OnRun()
    begin
        // [FEATURE] [OAuth] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPropertyFromCode()
    var
        OAuthManagement: Codeunit "OAuth Management";
    begin
        // [SCENARIO] An OAuth V1 authorization code has been retrieved and is parsed.
        // [THEN] Authorization codes are parsed correctly.

        Assert.AreEqual('', OAuthManagement.GetPropertyFromCode('a=12&b=23', ''), 'Property of empty code is not empty.');

        Assert.AreEqual('12', OAuthManagement.GetPropertyFromCode('a=12&bc=23', 'a'), 'First property not found.');
        Assert.AreEqual('23', OAuthManagement.GetPropertyFromCode('a=12&bc=23', 'bc'), 'Last property not found.');
        Assert.AreEqual('34', OAuthManagement.GetPropertyFromCode('a=12&e=34&bc=23', 'e'), 'Middle property not found.');
        Assert.AreEqual('', OAuthManagement.GetPropertyFromCode('a=12&bc=23', 'b'), 'No value found for non-property.');
    end;
}

