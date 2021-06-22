codeunit 138889 "SmartList Designer Setup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SmartList Designer]
    end;


    [Test]
    [Scope('OnPrem')]
    procedure TestNullPowerAppIdError()
    var
        setupPage: TestPage "SmartList Designer Setup";
        testValue: Guid;
    begin
        // [SCENARIO] User opens up setup page and tries to insert a null guid into the PowerAppId field

        // [GIVEN] User opens the page
        InitializePage(setupPage);

        with setupPage do begin
            // [WHEN] User inserts a null value
            // [THEN] An error occurs
            testValue := '00000000-0000-0000-0000-000000000000';
            asserterror SetupPart.PowerAppId.SetValue(testValue);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNullTenantIdError()
    var
        setupPage: TestPage "SmartList Designer Setup";
        testValue: Guid;
    begin
        // [SCENARIO] User opens up setup page and tries to insert a null guid into the PowerAppId field

        // [GIVEN] User opens the page
        InitializePage(setupPage);

        with setupPage do begin
            // [WHEN] User inserts a null value
            // [THEN] An error occurs
            testValue := '00000000-0000-0000-0000-000000000000';
            asserterror SetupPart.PowerAppTenantId.SetValue(testValue);
        end;
    end;

    local procedure InitializePage(var setupPage: TestPage "SmartList Designer Setup")
    begin
        Initialize();
        setupPage.Trap();
        Page.Run(PAGE::"SmartList Designer Setup");
    end;

    local procedure Initialize()
    var
        SmartListSetupTable: Record "SmartList Designer Setup";
    begin
        if not IsInitialized then begin
            SmartListSetupTable.DeleteAll();
        end;

        IsInitialized := true;
    end;

    var
        IsInitialized: Boolean;
}