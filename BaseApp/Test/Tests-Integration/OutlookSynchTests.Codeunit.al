codeunit 139014 "Outlook Synch Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [INT] [Outlook Synch.] [UT]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        OsynchOutlookMgt: Codeunit "Outlook Synch. Outlook Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Initialized: Boolean;
        inputValue: Text;
        hashValue: Text;

    [Test]
    [Scope('OnPrem')]
    procedure ComputeHashEmptyInputTest()
    begin
        Initialize;

        inputValue := '';
        hashValue := OsynchOutlookMgt.ComputeHash(inputValue);
        Assert.AreEqual('', hashValue, 'The computed hash from empty input is not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComputeHashBase64InputTest()
    begin
        Initialize;

        inputValue := 'MDAwMDAwMDAwQkQyRjNGNUQyNjA5MTQ3ODg2NjFCMzg2MEFEN0I0MjQ0MDEyMDAw';
        hashValue := OsynchOutlookMgt.ComputeHash(inputValue);
        Assert.AreEqual('8ApKLToBSsXlsjyVpRoYZoRi3p8=', hashValue, 'The computed hash from base64 input is not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComputeHashXmlInputTest()
    begin
        Initialize;

        inputValue := GetXmlString;

        hashValue := OsynchOutlookMgt.ComputeHash(inputValue);
        Assert.AreEqual('Rg6BJ9J3gR3Kx5ICzyy33kCFIxw=', hashValue, 'The computed hash from xml input is not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetHashEntryIdTest()
    var
        XmlReaderIn: DotNet "OLSync.Common.XmlTextReader";
        rootIterator: Text[38];
        entryId: Text;
        "count": Integer;
        ignoredRootLocalName: Text;
    begin
        Initialize;

        inputValue := GetXmlString;

        XmlReaderIn := XmlReaderIn.XmlTextReader(inputValue);
        ignoredRootLocalName := XmlReaderIn.RootLocalName;
        SYSTEM.Clear(ignoredRootLocalName);

        count := XmlReaderIn.SelectElements(rootIterator, '*');
        Assert.IsTrue(count > 0, 'The SelectElelement did not return the expected root iterator');

        entryId := '';
        hashValue := OsynchOutlookMgt.GetEntryIDHash(entryId, XmlReaderIn, rootIterator);
        Assert.AreEqual('000000000BD2F3F5D260914788661B3860AD7B4244012000', entryId, 'EntryId is not valid');
        Assert.AreEqual('8E8upXCgkLkAX2mKcqLaVqY4tLw=', hashValue, 'Hash value is not valid');

        Clear(XmlReaderIn);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProcessOutlookMessageNoOutlookSynchUserErrorTest()
    var
        errorLogXMLWriter: DotNet "OLSync.Common.XmlTextWriter";
        errorLogMessage: Text;
        dateTimeValue: DateTime;
    begin
        Initialize;

        inputValue := GetXmlString;
        errorLogXMLWriter := errorLogXMLWriter.XmlTextWriter;
        errorLogXMLWriter.WriteStartDocument;
        errorLogXMLWriter.WriteStartElement('SynchronizationMessage');

        dateTimeValue := OsynchOutlookMgt.ProcessOutlookChanges('TEST963', inputValue, errorLogXMLWriter, true);

        if not IsNull(errorLogXMLWriter) then begin
            errorLogXMLWriter.WriteEndElement;
            errorLogXMLWriter.WriteEndDocument;

            errorLogMessage := errorLogXMLWriter.ToString;
            Clear(errorLogXMLWriter);
        end;

        Assert.AreEqual(
          '', Format(dateTimeValue), 'No User exist, so dateTime should be empty since StartSynchTime is not read from XML string');
        Assert.IsTrue(StrLen(errorLogMessage) = 66, 'Error message is not the expected length : ' + Format(StrLen(errorLogMessage)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProcessOutlookMessageNoSalesPersonErrorTest()
    var
        OsynchUserSetup: Record "Outlook Synch. User Setup";
        errorLogXMLWriter: DotNet "OLSync.Common.XmlTextWriter";
        errorLogMessage: Text;
        dateTimeValue: DateTime;
    begin
        Initialize;

        if not OsynchUserSetup.Get('TEST963') then begin
            OsynchUserSetup."User ID" := 'TEST963';
            OsynchUserSetup."Synch. Entity Code" := 'CONT_SP';
            OsynchUserSetup.Insert(true);
        end;

        inputValue := GetXmlString;
        errorLogXMLWriter := errorLogXMLWriter.XmlTextWriter;
        errorLogXMLWriter.WriteStartDocument;
        errorLogXMLWriter.WriteStartElement('SynchronizationMessage');

        dateTimeValue := OsynchOutlookMgt.ProcessOutlookChanges('TEST963', inputValue, errorLogXMLWriter, true);

        if not IsNull(errorLogXMLWriter) then begin
            errorLogXMLWriter.WriteEndElement;
            errorLogXMLWriter.WriteEndDocument;

            errorLogMessage := errorLogXMLWriter.ToString;
            Clear(errorLogXMLWriter);
        end;

        Assert.AreEqual(
          '2012-01-10T15:21:42Z', Format(dateTimeValue, 0, 9), 'No User exist, so dateTime should be empty since StartSynchTime is not read from XML string');
        Assert.IsTrue(StrLen(errorLogMessage) > 26, 'Error is not the expected lenght : ' + Format(StrLen(errorLogMessage)));
        OsynchUserSetup."User ID" := 'TEST963';
        OsynchUserSetup."Synch. Entity Code" := 'CONT_SP';
        if OsynchUserSetup.FindFirst then
            OsynchUserSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyStringIsNotValidOsyncUserTest()
    var
        OsynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
    begin
        Initialize;
        Assert.IsFalse(OsynchNAVMgt.IsOSyncUser(''), 'The empty string is not a valid OSync user');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UncofiguredUserIsNotValidOsyncUserTest()
    var
        OsynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
    begin
        Initialize;
        Assert.IsFalse(OsynchNAVMgt.IsOSyncUser('UNCONFIGUREDUSER'), 'UNCONFIGUREDUSER is not a valid OSync user');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfiguredUserIsValidOsyncUserTest()
    var
        OutlookSynchUserSetup: Record "Outlook Synch. User Setup";
        OsynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
        UserID: Code[20];
    begin
        Initialize;

        UserID := 'CONFIGUREDUSER';
        OutlookSynchUserSetup.Init;
        OutlookSynchUserSetup."User ID" := UserID;
        OutlookSynchUserSetup.Insert(false);

        Assert.IsTrue(OsynchNAVMgt.IsOSyncUser(UserID), 'CONFIGUREDUSER is a valid OSync user');
        OutlookSynchUserSetup.DeleteAll(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepareFieldValueForXMLWhenOptionField()
    var
        Currency: Record Currency;
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        "Integer": Integer;
        OutputText: Text;
    begin
        // [SCENARIO 267869] Option caption is formatted as text via PrepareFieldValueForXML codeunit Outlook Synch. Type Conv.
        Initialize;
        Integer := LibraryRandom.RandIntInRange(0, GetNumberOfOptionsForFieldNo(Currency, Currency.FieldNo("Invoice Rounding Type")));

        // [GIVEN] Option field, having OptionString = 'Option1,Option2,Option3' and Option value is set equal to 'Option2'
        Currency.Init;
        Currency.Code := LibraryUtility.GenerateGUID;
        Currency.Validate("Invoice Rounding Type", Integer);
        Currency.Insert(true);

        // [GIVEN] FieldRef to Option field
        RecRef.GetTable(Currency);
        FieldRef := RecRef.Field(Currency.FieldNo("Invoice Rounding Type"));

        // [WHEN] Prepare Field Value for XML via codeunit Outlook Synch. Type Conv.
        OutputText := OutlookSynchTypeConv.PrepareFieldValueForXML(FieldRef);

        // [THEN] OutputText = 'Option2'
        Assert.AreEqual(OutlookSynchTypeConv.OptionValueToText(Integer, FieldRef.OptionMembers), OutputText, '');
    end;

    [Normal]
    local procedure Initialize()
    begin
        if not Initialized then
            Initialized := true;
    end;

    local procedure GetNumberOfOptionsForFieldNo(RecVar: Variant; FieldNo: Integer): Integer
    var
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecVar);
        FieldRef := RecRef.Field(FieldNo);
        exit(TypeHelper.GetNumberOfOptions(FieldRef.OptionMembers));
    end;

    [Normal]
    local procedure GetXmlString() xmlString: Text
    begin
        xmlString := '<?xml version="1.0" encoding="utf-8"?>';
        xmlString := xmlString + '<SynchronizationMessage StartSynchTime="01/10/2012 15:21:42">';
        xmlString := xmlString + '<OutlookItem SynchEntityCode="CONT_SP">';
        xmlString := xmlString + '<EntryID>MDAwMDAwMDAwQkQyRjNGNUQyNjA5MTQ3ODg2NjFCMzg2MEFEN0I0MjQ0MDEyMDAw</EntryID>';
        xmlString := xmlString + '<Field Name="FullName">Test 1. Unit</Field>';
        xmlString := xmlString + '<Field Name="JobTitle"></Field>';
        xmlString := xmlString + '<Field Name="Email1Address">TEST963@contoso.com</Field>';
        xmlString := xmlString + '<Field Name="Email2Address"></Field>';
        xmlString := xmlString + '<Field Name="BusinessTelephoneNumber"></Field>';
        xmlString := xmlString + '<Field Name="Salesperson Code">TEST963</Field>';
        xmlString := xmlString + '</OutlookItem>';
        xmlString := xmlString + '</SynchronizationMessage>';
        exit(xmlString);
    end;
}

