codeunit 142078 "UI IRS 1099"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Vendor 1099]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryLocalFunctionality: Codeunit "Library - Local Functionality";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryPurchase: Codeunit "Library - Purchase";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustEntriesOpensFromFormBoxPage()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRS1099AdjustmentsPage: TestPage "IRS 1099 Adjustments";
    begin
        // [SCENARIO 332661] Stan can open the "IRS 1099 Adjustments" page from the "IRS 1099 Form-Box" page under Basic application area setup

        Initialize();

        // [GIVEN] Application Area - Basic
        LibraryApplicationArea.EnableBasicSetup;

        // [GIVEN] IRS 1099 Code "A"
        LibraryLocalFunctionality.CreateIRS1099FormBox(IRS1099FormBox, 0);

        // [GIVEN] IRS Adjustment "I" exists for code "A"
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, LibraryPurchase.CreateVendorNo, IRS1099FormBox.Code, 0, 0);

        // [GIVEN] Open IRS 1099 Form-Box page
        IRS1099FormBoxPage.OpenEdit;

        // [GIVEN] Focus on Code "A"
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRS1099FormBox.Code);

        // [WHEN] Stan press "Adjustments" action
        IRS1099AdjustmentsPage.Trap;
        IRS1099FormBoxPage.Adjustments.Invoke;

        // [THEN] "IRS 1099 Adjustments" page shown with adjustment "I"
        IRS1099AdjustmentsPage."Vendor No.".AssertEquals(IRS1099Adjustment."Vendor No.");

        // Tear down
        IRS1099AdjustmentsPage.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownToAdjustmentsFromAdjustmentExistsField()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRS1099AdjustmentsPage: TestPage "IRS 1099 Adjustments";
    begin
        // [SCENARIO 332661] Stan can drill-down to adjustments from field "Adjustments Exists" on the "IRS 1099 Form-Box" page

        Initialize();

        // [GIVEN] Application Area - Basic
        LibraryApplicationArea.EnableBasicSetup;

        // [GIVEN] IRS 1099 Code "A"
        LibraryLocalFunctionality.CreateIRS1099FormBox(IRS1099FormBox, 0);

        // [GIVEN] IRS Adjustment "I" exists for code "A"
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, LibraryPurchase.CreateVendorNo, IRS1099FormBox.Code, 0, 0);

        // [GIVEN] Open IRS 1099 Form-Box page
        IRS1099FormBoxPage.OpenEdit;

        // [GIVEN] Focus on Code "A"
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRS1099FormBox.Code);

        // [WHEN] Stan drill-down "Adjustments Exists" field
        IRS1099AdjustmentsPage.Trap;
        IRS1099FormBoxPage."Adjustment Exists".DrillDown;

        // [THEN] "IRS 1099 Adjustments" page shown with adjustment "I"
        IRS1099AdjustmentsPage."Vendor No.".AssertEquals(IRS1099Adjustment."Vendor No.");

        // Tear down
        IRS1099AdjustmentsPage.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyAdjustmentsRelatedToParticularCodeOpens()
    var
        IRS1099FormBox: array[2] of Record "IRS 1099 Form-Box";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRS1099AdjustmentsPage: TestPage "IRS 1099 Adjustments";
    begin
        // [SCENARIO 332661] Only adjustments related to particular IRS 1099 code opens

        Initialize();

        // [GIVEN] Application Area - Basic
        LibraryApplicationArea.EnableBasicSetup;

        // [GIVEN] Two IRS 1099 Codes - "A" and "B"
        LibraryLocalFunctionality.CreateIRS1099FormBox(IRS1099FormBox[1], 0);
        LibraryLocalFunctionality.CreateIRS1099FormBox(IRS1099FormBox[2], 0);

        // [GIVEN] IRS Adjustment "I" exists for code "A"
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, LibraryPurchase.CreateVendorNo, IRS1099FormBox[1].Code, 0, 0);

        // [GIVEN] Open IRS 1099 Form-Box page
        IRS1099FormBoxPage.OpenEdit;

        // [GIVEN] Focus on Code "B"
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRS1099FormBox[2].Code);

        // [WHEN] Stan press "Adjustments" action
        IRS1099AdjustmentsPage.Trap;
        IRS1099FormBoxPage.Adjustments.Invoke;

        // [THEN] "IRS 1099 Adjustments" page shown with no records
        IRS1099AdjustmentsPage."Vendor No.".AssertEquals('');

        // Tear down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UI IRS 1099");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UI IRS 1099");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UI IRS 1099");
    end;
}

