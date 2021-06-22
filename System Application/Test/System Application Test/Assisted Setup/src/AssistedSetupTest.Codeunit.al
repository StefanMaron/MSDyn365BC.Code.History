// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 132586 "Assisted Setup Test"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        LibraryAssert: Codeunit "Library Assert";
        AssistedSetupTest: Codeunit "Assisted Setup Test";
        LastPageIDRun: Integer;

    [Test]
    [HandlerFunctions('VideoLinkPageHandler,MySetupTestPageHandler,OtherSetupTestPageHandler')]
    procedure TestAssistedSetupsAreAdded()
    var
        AssistedSetupApi: Codeunit "Assisted Setup";
        AssistedSetup: TestPage "Assisted Setup";
        Info: ModuleInfo;
    begin
        Initialize();

        // [GIVEN] Subscribers are registered
        BindSubscription(AssistedSetupTest);

        // [WHEN] The subscribers are executed by opening the assisted setup page
        AssistedSetup.Trap();
        Page.Run(Page::"Assisted Setup");

        // [THEN] Two setups exist
        AssistedSetup.First();
        AssistedSetup.Name.AssertEquals('My Assisted Setup Test Page');
        AssistedSetup.Completed.AssertEquals(false);
        AssistedSetup.Help.AssertEquals('');
        AssistedSetup.Video.AssertEquals('');

        AssistedSetup.Next();
        AssistedSetup.Name.AssertEquals('Other Assisted Setup Test Page');
        AssistedSetup.Completed.AssertEquals(false);
        AssistedSetup.Help.AssertEquals('Read');
        AssistedSetup.Video.AssertEquals('Watch');

        // [WHEN] Start is invoked on the first
        AssistedSetup.First();
        LastPageIDRun := 0;
        AssistedSetup."Start Setup".Invoke();

        // [THEN] Check the last id run based on the subscriber
        LibraryAssert.AreEqual(Page::"My Assisted Setup Test Page", LastPageIDRun, 'First wizard did not run.');

        // [WHEN] Complete the first wizard
        NavApp.GetCurrentModuleInfo(Info);
        AssistedSetupApi.Complete(Info.Id(), Page::"My Assisted Setup Test Page");

        // [THEN] First wizard is completed
        LibraryAssert.IsTrue(AssistedSetupApi.IsComplete(Info.Id(), Page::"My Assisted Setup Test Page"), 'First wizard was not completed');

        // [WHEN] Completed wizard is run again
        AssistedSetup."Start Setup".Invoke();

        // [THEN] As subscriber sets Handled = true, nothing happens

        // [WHEN] Start is invoked on the second
        AssistedSetup.Last();
        LastPageIDRun := 0;
        AssistedSetup."Start Setup".Invoke();

        // [THEN] Check the last id run based on the subscriber
        LibraryAssert.AreEqual(Page::"Other Assisted Setup Test Page", LastPageIDRun, 'Second wizard did not run.');

        // [THEN] Second wizard is not completed
        LibraryAssert.IsFalse(AssistedSetupApi.IsComplete(Info.Id(), Page::"Other Assisted Setup Test Page"), 'Second  wizard was completed');

        // [WHEN] Click Watch on Video field
        AssistedSetup.Video.Drilldown();

        // [THEN] Video Link opens, and caught by modal page handler

        UnbindSubscription(AssistedSetupTest);
    end;

    local procedure Initialize();
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        AssistedSetupTestLibrary.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnRegister', '', true, true)]
    [Normal]
    procedure OnRegister()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        AssistedSetup.Add(Info.Id(), Page::"My Assisted Setup Test Page", 'My Assisted Setup Test Page', AssistedSetupGroup::WithoutLinks);
        AssistedSetup.Add(Info.Id(), Page::"Other Assisted Setup Test Page", 'Other Assisted Setup Test Page', AssistedSetupGroup::WithLinks, 'http://youtube.com', 'http://yahoo.com');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnAfterRun', '', true, true)]
    [Normal]
    procedure OnAfterRun(ExtensionID: Guid; PageID: Integer)
    begin
        LastPageIDRun := PageID;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnReRunOfCompletedSetup', '', true, true)]
    [Normal]
    procedure OnReRunOfCompletedSetup(ExtensionID: Guid; PageID: Integer; var Handled: Boolean)
    begin
        if PageID = Page::"My Assisted Setup Test Page" then
            Handled := true;
    end;

    [ModalPageHandler]
    procedure VideoLinkPageHandler(var VideoLink: TestPage "Video Link")
    begin
    end;

    [ModalPageHandler]
    procedure MySetupTestPageHandler(var MyAssistedSetupTestPage: TestPage "My Assisted Setup Test Page")
    begin
    end;

    [ModalPageHandler]
    procedure OtherSetupTestPageHandler(var OtherAssistedSetupTestPage: TestPage "Other Assisted Setup Test Page")
    begin
    end;
}