codeunit 142007 "Data Export Test Suite"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Export]

        IsInitialized := false;
    end;

    var
        DataExportManagement: Codeunit "Data Export Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure FormatForIndexXML_SpecialSymbols()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363817] The index.xml file created from the Business Data Export has special characters replaces with converted values.
        Initialize();

        // [GIVEN] Input string with any symbols of: ~!$^&*(){}[]\|;:"?/,<>@#`.-+=
        // [WHEN] DataExportManagement.FormatForIndexXML() is invoked
        // [THEN] Result should not contain any special symbols

        Assert.AreEqual('abcd', DataExportManagement.FormatForIndexXML('ab(){}[]<>cd'), '');
        Assert.AreEqual('efgh', DataExportManagement.FormatForIndexXML('ef+-=*/.gh'), '');
        Assert.AreEqual('ijkl', DataExportManagement.FormatForIndexXML('ij;:,!?kl'), '');
        Assert.AreEqual('mnop', DataExportManagement.FormatForIndexXML('mn$#@&~^op'), '');
        Assert.AreEqual('qrst', DataExportManagement.FormatForIndexXML('qr|\"`''st'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatForIndexXML_GermanSymbols()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363817] The index.xml file created from the Business Data Export has German special characters replaces with converted values.
        Initialize();

        // [GIVEN] Input string with any symbols of: Ä ä Ö ö Ü ü ß
        // [WHEN] DataExportManagement.FormatForIndexXML() is invoked
        // [THEN] Result should not contain any special symbols

        Assert.AreEqual('Ae__ae', DataExportManagement.FormatForIndexXML('Ä__ä'), '');
        Assert.AreEqual('Oe__oe', DataExportManagement.FormatForIndexXML('Ö__ö'), '');
        Assert.AreEqual('Ue__ue', DataExportManagement.FormatForIndexXML('Ü__ü'), '');
        Assert.AreEqual('Strasse', DataExportManagement.FormatForIndexXML('Straße'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatForIndexXML_LongText()
    var
        InputTxt: Text[1024];
        Index: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363817] The index.xml file created from the Business Data Export has maximum length of 50.
        Initialize();

        // [GIVEN] Input string with the length bigger then 50
        // [WHEN] DataExportManagement.FormatForIndexXML() is invoked
        // [THEN] The length of result should be 50 

        InputTxt := LibraryRandom.RandText(1024);
        Assert.AreEqual(CopyStr(InputTxt, 1, 50), DataExportManagement.FormatForIndexXML(InputTxt), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Data Export Test Suite");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Data Export Test Suite");
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Data Export Test Suite");
    end;
}