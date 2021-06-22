codeunit 136505 "Time Sheets Permissions"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [HR] [Time Sheet] [Permissions]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        OpenUserSetupQst: Label 'You aren''t allowed to run this report. If you want, you can give yourself the Time Sheet Admin. rights, and then try again.\\ Do you want to do that now?';
        TimeSheetAdminErr: Label 'Time sheet administrator only is allowed to create time sheets.';

    [Test]
    [HandlerFunctions('ConfirmHandler,UserSetupPageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetsEmptyUSerSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] Only time sheet administrator can create time sheets
        // [SCENARIO] If user with no user setup can set himself as administrator a dialog appears to help him
        // [SCENARIO] navigate to the proper page

        // [GIVEN] User setup is empty but he has the permissions to set himself administrator
        UserSetup.DeleteAll;
        // [WHEN] User tries to run Report Create Time Sheets
        // [THEN] The report exits with error and the user is informed how to procceed
        asserterror REPORT.Run(REPORT::"Create Time Sheets", false);
        Assert.ExpectedError('');
        // Verify in ConfirmHandler

        // [GIVEN] User cannot set himself as Time Sheet administrator
        LibraryLowerPermissions.SetO365Basic;
        // [WHEN] User tries to run Report Create Time Sheets
        // [THEN] An error is raised that only time sheet administrators can generate timesheets
        asserterror REPORT.Run(REPORT::"Create Time Sheets", false);
        Assert.ExpectedError(TimeSheetAdminErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,UserSetupPageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetsNoRightsUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] Only time sheet administrator can create time sheets
        // [SCENARIO] If user with no permissions can set himself as administrator a dialog appears to help him
        // [SCENARIO] navigate to the proper page

        // [GIVEN] User setup exists, the user is not set as time sheet administrator
        // [GIVEN] but he has the permissions to set himself administrator
        UserSetup.Init;
        UserSetup."User ID" := UserId;
        UserSetup."Time Sheet Admin." := false;
        UserSetup.Insert;

        // [WHEN] User tries to run Report Create Time Sheets
        // [THEN] The report exits with error and the user is informed how to procceed
        asserterror REPORT.Run(REPORT::"Create Time Sheets", false);
        Assert.ExpectedError('');
        // Verify in ConfirmHandler

        // [GIVEN] User cannot set himself as Time Sheet administrator
        LibraryLowerPermissions.SetO365Basic;

        // [WHEN] User tries to run Report Create Time Sheets
        // [THEN] An error is raised that only time sheet administrators can generate timesheets
        asserterror REPORT.Run(REPORT::"Create Time Sheets", false);
        Assert.ExpectedError(TimeSheetAdminErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetsSuccess()
    var
        UserSetup: Record "User Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // [SCENARIO] Only time sheet administrator can create time sheets

        // [GIVEN] The user is set as time sheet administrator
        UserSetup.Init;
        UserSetup."User ID" := UserId;
        UserSetup."Time Sheet Admin." := true;
        UserSetup.Insert;

        LibraryLowerPermissions.SetO365Basic;

        // [WHEN] User tries to run Report Create Time Sheets
        CreateTimeSheets.InitParameters(WorkDate, 1, '', false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run;

        // [THEN] No error occurs
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(Question, OpenUserSetupQst, 'A different dialog was launched');
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure UserSetupPageHandler(var UserSetup: Page "User Setup")
    begin
    end;
}

