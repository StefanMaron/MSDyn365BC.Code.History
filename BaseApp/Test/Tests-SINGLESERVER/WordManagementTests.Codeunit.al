codeunit 139021 "WordManagement Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [INT] [Word Management]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        WordManagement: Codeunit WordManagement;
        Initialized: Boolean;
        AddHeaderField: Integer;
        AddDataField: Integer;
        FieldCountMismatchErr: Label 'Number of fields in the word document header (%1) does not match number of fields with data (%2).', Comment = '%1 and %2 is a number';

    [Test]
    [Scope('OnPrem')]
    procedure IsWordDocumentExtensionDoc()
    begin
        Assert.IsTrue(WordManagement.IsWordDocumentExtension('DOC'), 'Expected DOC to be a valid word document extension');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsWordDocumentExtensionDocx()
    begin
        Assert.IsTrue(WordManagement.IsWordDocumentExtension('DOCX'), 'Expected DOCX to be a valid word document extension');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsNotWordDocumentExtension()
    begin
        Assert.IsFalse(
          WordManagement.IsWordDocumentExtension('someextension'), 'Expected someextension not to be a valid word document extension');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsWordDocumentExtensionDocIsCaseInsensitive()
    begin
        Assert.IsTrue(WordManagement.IsWordDocumentExtension('DOC'), 'Expected DOC to be a valid word document extension');
        Assert.IsTrue(WordManagement.IsWordDocumentExtension('doc'), 'Expected doc to be a valid word document extension');
        Assert.IsTrue(WordManagement.IsWordDocumentExtension('dOc'), 'Expected dOc to be a valid word document extension');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsWordDocumentExtensionDocCanContainExtensionDot()
    begin
        Assert.IsTrue(WordManagement.IsWordDocumentExtension('.doc'), 'Expected .doc to be a valid word document extension');
        Assert.IsTrue(WordManagement.IsWordDocumentExtension('.dOc'), 'Expected .dOc to be a valid word document extension');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsWordExtensionDocX()
    begin
        Assert.AreEqual('DOCX', WordManagement.GetWordDocumentExtension('14.0'), 'Expected version is not valid');
        Assert.AreEqual('DOCX', WordManagement.GetWordDocumentExtension('15,0'), 'Expected version is not valid');
        Assert.AreEqual('DOCX', WordManagement.GetWordDocumentExtension('16'), 'Expected version is not valid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsWordExtensionDoc()
    begin
        Assert.AreEqual('DOC', WordManagement.GetWordDocumentExtension('10.0'), 'Expected version is not valid');
        Assert.AreEqual('DOC', WordManagement.GetWordDocumentExtension('9,0'), 'Expected version is not valid');
        Assert.AreEqual('DOC', WordManagement.GetWordDocumentExtension('8'), 'Expected version is not valid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsWordExtensionInvalid()
    begin
        Assert.AreEqual('DOC', WordManagement.GetWordDocumentExtension('XXX'), 'Expected version is not valid');
        Assert.AreEqual('DOC', WordManagement.GetWordDocumentExtension(''), 'Expected version is not valid');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PopulateInterLogEntryWithoutMergeSource()
    var
        Attachment: Record Attachment;
        FileMgt: Codeunit "File Management";
        MergeFile: File;
        MergeFileNameServer: Text;
        MergeFileContent: Text;
        EntryNo: Integer;
        HeaderIsReady: Boolean;
    begin
        Initialize;
        HeaderIsReady := true;
        EntryNo := 10000;

        Attachment.SetRange("File Extension", 'DOC');
        Attachment.SetRange("Storage Type", 0);
        if not Attachment.FindFirst then
            Assert.Fail('No attachment record with DOC extension and Embedded storage type exists.');

        MergeFileNameServer := FileMgt.ServerTempFileName('.HTM');
        MergeFile.WriteMode := true;
        MergeFile.TextMode := true;
        MergeFile.Create(MergeFileNameServer);
        WordManagement.PopulateInterLogEntryToMergeSource(MergeFile, Attachment, EntryNo, HeaderIsReady, 0);
        MergeFile.Close;
        MergeFileContent := GetFileContent(MergeFileNameServer);

        Assert.AreEqual('', MergeFileContent, 'The merge file content is not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T080_CreateHeaderMergeFileOnly()
    var
        FileMgt: Codeunit "File Management";
        [RunOnClient]
        WordMergeFile: DotNet MergeHandler;
        RegEx: DotNet Regex;
        RegExOptions: DotNet RegexOptions;
        MergeFieldsOnly: Boolean;
        MergeFileNameClient: Text;
        MergeFileContent: Text;
        CountTD: Integer;
        CountTR: Integer;
    begin
        // [FEATURE] [UT]
        Initialize;
        MergeFileNameClient := FileMgt.ClientTempFileName('HTM');
        WordMergeFile := WordMergeFile.MergeHandler;

        // [WHEN] CreateHeader() with merge fields
        MergeFieldsOnly := true;
        WordManagement.CreateHeader(WordMergeFile, MergeFieldsOnly, MergeFileNameClient, '');
        Clear(WordMergeFile);

        // [THEN] Two rows, each of 48 fields.
        MergeFileContent := GetFileContent(MergeFileNameClient);
        CountTR := RegEx.Matches(MergeFileContent, '<TR>', RegExOptions.IgnoreCase).Count();
        Assert.AreEqual(2, CountTR, 'Number of TR elements are not as expected');

        CountTD := RegEx.Matches(MergeFileContent, '<TD>', RegExOptions.IgnoreCase).Count();
        Assert.IsTrue(CountTD >= 96, 'Number of TD elements are not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T081_CreateHeader()
    var
        FileMgt: Codeunit "File Management";
        [RunOnClient]
        WordMergeFile: DotNet MergeHandler;
        RegEx: DotNet Regex;
        RegExOptions: DotNet RegexOptions;
        MergeFieldsOnly: Boolean;
        MergeFileNameClient: Text;
        MergeFileContent: Text;
        CountTD: Integer;
        CountTR: Integer;
    begin
        // [FEATURE] [UT]
        Initialize;
        MergeFileNameClient := FileMgt.ClientTempFileName('HTM');
        WordMergeFile := WordMergeFile.MergeHandler;
        // [WHEN] CreateHeader() with no merge fields
        MergeFieldsOnly := false;
        WordManagement.CreateHeader(WordMergeFile, MergeFieldsOnly, MergeFileNameClient, '');
        Clear(WordMergeFile);

        // [THEN] One row with 48 fields.
        MergeFileContent := GetFileContent(MergeFileNameClient);
        CountTR := RegEx.Matches(MergeFileContent, '<TR>', RegExOptions.IgnoreCase).Count();
        Assert.AreEqual(1, CountTR, 'Number of TR elements are not as expected');

        CountTD := RegEx.Matches(MergeFileContent, '<TD>', RegExOptions.IgnoreCase).Count();
        Assert.IsTrue(CountTD >= 48, 'Number of TD elements are not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T082_AddFieldsFromSegmentLineToMergeSource()
    var
        Contact: Record Contact;
        SegLine: Record "Segment Line";
        TempInteractLogEntry: Record "Interaction Log Entry" temporary;
        FileMgt: Codeunit "File Management";
        [RunOnClient]
        WordMergeFile: DotNet MergeHandler;
        RegEx: DotNet Regex;
        RegExOptions: DotNet RegexOptions;
        MergeFileNameClient: Text;
        MergeFileContent: Text;
        CountTD: Integer;
        CountTR: Integer;
        ContactNo: Code[20];
        CompanyName: Text[100];
        FieldCount: Integer;
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] Segment Line for Contact 'C', where "Company Name" is 'X'
        SegLine.FindFirst;
        ContactNo := SegLine."Contact No.";
        Contact.Get(ContactNo);
        CompanyName := Contact."Company Name";

        // [GIVEN] CreateHeader() with no merge fields
        MergeFileNameClient := FileMgt.ClientTempFileName('HTM');
        WordMergeFile := WordMergeFile.MergeHandler;
        FieldCount := WordManagement.CreateHeader(WordMergeFile, false, MergeFileNameClient, '');
        // [WHEN] Add fields data from Segment Line
        WordManagement.AddFieldsToMergeSource(WordMergeFile, TempInteractLogEntry, SegLine, '', FieldCount);
        Clear(WordMergeFile);

        // [THEN] Contact's Name 'C' and "Company Name" 'X' is in the file
        MergeFileContent := GetFileContent(MergeFileNameClient);
        Assert.IsTrue(StrPos(MergeFileContent, ContactNo) > 0, 'Contact number was not in the merge file');
        Assert.IsTrue(StrPos(MergeFileContent, CompanyName) > 0, 'Contact company name was not in the merge file');

        // [THEN] Two rows, each of 48 fields.
        CountTR := RegEx.Matches(MergeFileContent, '<TR>', RegExOptions.IgnoreCase).Count();
        Assert.AreEqual(2, CountTR, 'Number of TR elements are not as expected');

        CountTD := RegEx.Matches(MergeFileContent, '<TD>', RegExOptions.IgnoreCase).Count();
        Assert.IsTrue(CountTD >= 96, 'Number of TD elements are not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T083_AddFieldsFromInteractLogEntryToMergeSource()
    var
        Contact: Record Contact;
        TempSegLine: Record "Segment Line" temporary;
        InteractLogEntry: Record "Interaction Log Entry";
        FileMgt: Codeunit "File Management";
        [RunOnClient]
        WordMergeFile: DotNet MergeHandler;
        RegEx: DotNet Regex;
        RegExOptions: DotNet RegexOptions;
        MergeFileNameClient: Text;
        MergeFileContent: Text;
        CountTD: Integer;
        CountTR: Integer;
        ContactNo: Code[20];
        CompanyName: Text[100];
        FieldCount: Integer;
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] InteractLogEntry for Contact 'C', where "Company Name" is 'X'
        FindInteractLogEntry(InteractLogEntry, Contact);
        CompanyName := Contact."Company Name";
        ContactNo := InteractLogEntry."Contact No.";

        // [GIVEN] CreateHeader() with no merge fields
        MergeFileNameClient := FileMgt.ClientTempFileName('HTM');
        WordMergeFile := WordMergeFile.MergeHandler;
        FieldCount := WordManagement.CreateHeader(WordMergeFile, false, MergeFileNameClient, '');

        // [WHEN] Add fields data from InteractLogEntry
        WordManagement.AddFieldsToMergeSource(WordMergeFile, InteractLogEntry, TempSegLine, '', FieldCount);
        Clear(WordMergeFile);

        // [THEN] Contact's Name 'C' and "Company Name" 'X' is in the file
        MergeFileContent := GetFileContent(MergeFileNameClient);
        Assert.IsTrue(StrPos(MergeFileContent, ContactNo) > 0, 'Contact number was not in the merge file');
        Assert.IsTrue(StrPos(MergeFileContent, CompanyName) > 0, 'Contact company name was not in the merge file');

        // [THEN] Two rows, each of 48 fields.
        CountTR := RegEx.Matches(MergeFileContent, '<TR>', RegExOptions.IgnoreCase).Count();
        Assert.AreEqual(2, CountTR, 'Number of TR elements are not as expected');

        CountTD := RegEx.Matches(MergeFileContent, '<TD>', RegExOptions.IgnoreCase).Count();
        Assert.IsTrue(CountTD >= 96, 'Number of TD elements are not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T084_AddLessFieldsThanInHeaderFail()
    var
        Contact: Record Contact;
        TempSegLine: Record "Segment Line" temporary;
        InteractLogEntry: Record "Interaction Log Entry";
        FileMgt: Codeunit "File Management";
        WordManagementTests: Codeunit "WordManagement Tests";
        [RunOnClient]
        WordMergeFile: DotNet MergeHandler;
        MergeFileNameClient: Text;
        FieldCount: Integer;
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] InteractLogEntry for Contact 'C', where "Company Name" is 'X', "Salutation Code" is 'S'
        FindInteractLogEntry(InteractLogEntry, Contact);
        // [GIVEN] Subscribe to add one data field and remove one header field
        WordManagementTests.SetFieldCount(-1, 1);
        BindSubscription(WordManagementTests);
        // [GIVEN] CreateHeader() with no merge fields
        MergeFileNameClient := FileMgt.ClientTempFileName('HTM');
        WordMergeFile := WordMergeFile.MergeHandler;
        FieldCount := WordManagement.CreateHeader(WordMergeFile, false, MergeFileNameClient, '');
        // [WHEN] Add fields data from InteractLogEntry
        asserterror WordManagement.AddFieldsToMergeSource(WordMergeFile, InteractLogEntry, TempSegLine, '', FieldCount);
        // [THEN] Error message:Number of fields in the word document header (47) does not match number of fields with data (49).
        Assert.ExpectedError(StrSubstNo(FieldCountMismatchErr, FieldCount, FieldCount + 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T085_AddMoreFieldsThanInHeaderFail()
    var
        Contact: Record Contact;
        TempSegLine: Record "Segment Line" temporary;
        InteractLogEntry: Record "Interaction Log Entry";
        FileMgt: Codeunit "File Management";
        WordManagementTests: Codeunit "WordManagement Tests";
        [RunOnClient]
        WordMergeFile: DotNet MergeHandler;
        MergeFileNameClient: Text;
        FieldCount: Integer;
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] InteractLogEntry for Contact 'C', where "Company Name" is 'X', "Salutation Code" is 'S'
        FindInteractLogEntry(InteractLogEntry, Contact);
        // [GIVEN] Subscribe to remove two data fields and add two header fields
        WordManagementTests.SetFieldCount(2, -2);
        BindSubscription(WordManagementTests);
        // [GIVEN] CreateHeader() with no merge fields
        MergeFileNameClient := FileMgt.ClientTempFileName('HTM');
        WordMergeFile := WordMergeFile.MergeHandler;
        FieldCount := WordManagement.CreateHeader(WordMergeFile, false, MergeFileNameClient, '');
        // [WHEN] Add fields data from InteractLogEntry
        asserterror WordManagement.AddFieldsToMergeSource(WordMergeFile, InteractLogEntry, TempSegLine, '', FieldCount);
        // [THEN] Error message:Number of fields in the word document header (50) does not match number of fields with data (46).
        Assert.ExpectedError(StrSubstNo(FieldCountMismatchErr, FieldCount, FieldCount - 4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T086_AddCustomFieldToHeaderAndData()
    var
        Contact: Record Contact;
        TempSegLine: Record "Segment Line" temporary;
        InteractLogEntry: Record "Interaction Log Entry";
        FileMgt: Codeunit "File Management";
        WordManagementTests: Codeunit "WordManagement Tests";
        [RunOnClient]
        WordMergeFile: DotNet MergeHandler;
        MergeFileNameClient: Text;
        FieldCount: Integer;
        MergeFileContent: Text;
        Pos: array[3] of Integer;
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] InteractLogEntry for Contact 'C', where "Company Name" is 'X', "Salutation Code" is 'S'
        FindInteractLogEntry(InteractLogEntry, Contact);
        // [GIVEN] Subscribe to add two data field and two header fields
        WordManagementTests.SetFieldCount(2, 2);
        BindSubscription(WordManagementTests);
        // [GIVEN] CreateHeader() with no merge fields
        MergeFileNameClient := FileMgt.ClientTempFileName('HTM');
        WordMergeFile := WordMergeFile.MergeHandler;
        FieldCount := WordManagement.CreateHeader(WordMergeFile, false, MergeFileNameClient, '');
        // [WHEN] Add fields data from InteractLogEntry
        WordManagement.AddFieldsToMergeSource(WordMergeFile, InteractLogEntry, TempSegLine, 'FaxMailToValue', FieldCount);
        Clear(WordMergeFile);

        // [THEN] "Salutation Code1" and "Salutation Code2" are in the file, 'FaxMailTo' is placed after
        MergeFileContent := GetFileContent(MergeFileNameClient);
        Pos[1] := StrPos(MergeFileContent, Contact.FieldName("Salutation Code") + '1');
        Pos[2] := StrPos(MergeFileContent, Contact.FieldName("Salutation Code") + '2');
        Pos[3] := StrPos(MergeFileContent, 'FaxMailTo');
        Assert.IsTrue(Pos[1] > 0, 'Salutation Code1 was not in the merge file');
        Assert.IsTrue(Pos[2] > Pos[1], 'Salutation Code2 was not in the merge file');
        Assert.IsTrue(Pos[3] > Pos[2], 'FaxMailTo was not after new fields');
        // [THEN] "S1" and "S2" are in the file, 'FaxMailToValue' is placed after
        Pos[1] := StrPos(MergeFileContent, Contact."Salutation Code" + '1');
        Pos[2] := StrPos(MergeFileContent, Contact."Salutation Code" + '2');
        Pos[3] := StrPos(MergeFileContent, 'FaxMailToValue');
        Assert.IsTrue(Pos[1] > 0, 'Salutation Code1 value was not in the merge file');
        Assert.IsTrue(Pos[2] > Pos[1], 'Salutation Code2 value was not in the merge file');
        Assert.IsTrue(Pos[3] > Pos[2], 'FaxMailToValue was not after new fields');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T100_ActivateIsAliveDeactivate()
    var
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: Codeunit WordApplicationHandler;
    begin
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive before Activate');
        // [WHEN] Activate()
        WordManagement.Activate(WordApplicationHandler, 1);
        // [THEN] WordApp is not alive
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive after Activate');
        WordManagement.Deactivate(1);
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive after Dectivate');
        Assert.IsFalse(WordManagement.IsActive, 'should not be active after Deactivate');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T101_IsActivateDoesNotStartWordApp()
    var
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: Codeunit WordApplicationHandler;
    begin
        Assert.IsFalse(WordManagement.IsActive, 'should not be active before Activate');
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive before Activate');
        // [GIVEN] Activate()
        WordManagement.Activate(WordApplicationHandler, 1);
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive after Activate');
        // [WHEN] IsActive()
        Assert.IsTrue(WordManagement.IsActive, 'should be active after Activate');
        // [THEN] WordApp is not alive
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive after IsActive');

        WordManagement.Deactivate(1);
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive after Dectivate');
        Assert.IsFalse(WordManagement.IsActive, 'should not be active after Deactivate');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T102_FirstActivateCannotBeDeactivatedWithOtherID()
    var
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: array[2] of Codeunit WordApplicationHandler;
    begin
        // [GIVEN] Activate(1)
        WordManagement.Activate(WordApplicationHandler[1], 1);
        Assert.IsTrue(WordManagement.IsActive, 'should be active after Activate(1)');
        // [GIVEN] Activate(2)
        WordManagement.Activate(WordApplicationHandler[2], 2);
        Assert.IsTrue(WordManagement.IsActive, 'should be active after Activate(2)');
        // [WHEN] Deactivate(2)
        WordManagement.Deactivate(2);
        // [THEN] IsActive is 'Yes'
        Assert.IsTrue(WordManagement.IsActive, 'should be active after Deactivate(2)');
        WordManagement.Deactivate(1);
        Assert.IsFalse(WordManagement.IsActive, 'should not be active after Deactivate(1)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T103_SecondActivateIsIgnored()
    var
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: array[2] of Codeunit WordApplicationHandler;
    begin
        // [GIVEN] Activate(1)
        WordManagement.Activate(WordApplicationHandler[1], 1);
        Assert.IsTrue(WordManagement.IsActive, 'should be active after Activate(1)');
        // [GIVEN] Activate(2)
        WordManagement.Activate(WordApplicationHandler[2], 2);
        Assert.IsTrue(WordManagement.IsActive, 'should be active after Activate(2)');

        // [WHEN] Deactivate(1)
        WordManagement.Deactivate(1);
        // [THEN] IsActive is 'No'
        Assert.IsFalse(WordManagement.IsActive, 'should not be active after Deactivate(1)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T104_CanRunWordAppDoesNotStartWordApp()
    var
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: Codeunit WordApplicationHandler;
    begin
        Assert.IsFalse(WordManagement.CanRunWordApp, 'CanRunWordApp is No before activate');
        Assert.IsFalse(WordManagement.IsActive, 'should not be active before Activate');
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive before Activate');
        // [GIVEN] Activate()
        WordManagement.Activate(WordApplicationHandler, 1);
        // [WHEN] CanRunWordApp
        Assert.IsTrue(WordManagement.CanRunWordApp, 'CanRunWordApp is Yes before activate');
        // [THEN] WordApp is not alive
        Assert.IsFalse(WordApplicationHandler.IsAlive, 'WordApplication should not be alive after Activate');

        WordManagement.Deactivate(1);
        Assert.IsFalse(WordManagement.CanRunWordApp, 'CanRunWordApp is No after Deactivate');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105_GetWordAppOnInactiveHandler()
    var
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: Codeunit WordApplicationHandler;
        [RunOnClient]
        WordApplication: DotNet ApplicationClass;
    begin
        Assert.IsFalse(WordManagement.TryGetWord(WordApplication), 'TryGetWord is No before activate');
        Assert.IsTrue(IsNull(WordApplication), 'WordApplication should be Null');
        // [GIVEN] Activate()
        WordManagement.Activate(WordApplicationHandler, 1);
        // [WHEN] TryGetWord()
        Assert.IsTrue(WordManagement.TryGetWord(WordApplication), 'TryGetWord is Yes after activate');
        // [THEN] WordApp is alive
        Assert.IsFalse(IsNull(WordApplication), 'WordApplication should not be Null');
        Assert.IsTrue(WordApplicationHandler.IsAlive, 'WordApplication should be alive after Activate');

        WordManagement.Deactivate(1);
        Assert.IsFalse(WordManagement.TryGetWord(WordApplication), 'TryGetWord is No after deactivate');
    end;

    local procedure Initialize()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        if not Initialized then begin
            MarketingSetup.Get();
            MarketingSetup."Mergefield Language ID" := 1033;
            MarketingSetup.Modify();

            Initialized := true;
        end;
    end;

    local procedure AddField(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Number: Integer; Value: Text)
    var
        i: Integer;
    begin
        if Number = 0 then
            exit;
        TempNameValueBuffer.FindLast;
        if Number > 0 then
            for i := 1 to Number do
                TempNameValueBuffer.AddNewEntry(Value + Format(i), '')
        else
            for i := -1 downto Number do
                if TempNameValueBuffer.Next(-1) <> 0 then
                    TempNameValueBuffer.Delete();
    end;

    local procedure FindInteractLogEntry(var InteractLogEntry: Record "Interaction Log Entry"; var Contact: Record Contact)
    var
        Salutation: Record Salutation;
    begin
        InteractLogEntry.FindFirst;
        Contact.Get(InteractLogEntry."Contact No.");
        if Contact."Salutation Code" = '' then begin
            Salutation.FindFirst;
            Contact.Validate("Salutation Code", Salutation.Code);
            Contact.Modify();
        end;
    end;

    local procedure GetFileContent(FileName: Text) FileContent: Text
    var
        [RunOnClient]
        File: DotNet File;
    begin
        FileContent := File.ReadAllText(FileName);
        File.Delete(FileName); // cleanup
    end;

    [Scope('OnPrem')]
    procedure SetFieldCount(HeaderField: Integer; DataField: Integer)
    begin
        AddDataField := DataField;
        AddHeaderField := HeaderField;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5054, 'OnAddFieldsToMergeSource', '', false, false)]
    local procedure OnAddFieldsToMergeSourceHandler(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Salesperson: Record "Salesperson/Purchaser"; Country: Record "Country/Region"; Contact: Record Contact; CompanyInfo: Record "Company Information"; SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
        AddField(TempNameValueBuffer, AddDataField, Contact."Salutation Code")
    end;

    [EventSubscriber(ObjectType::Codeunit, 5054, 'OnCreateHeaderAddFields', '', false, false)]
    local procedure OnCreateHeaderAddFieldsHandler(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Salesperson: Record "Salesperson/Purchaser"; Country: Record "Country/Region"; Contact: Record Contact; CompanyInfo: Record "Company Information"; SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
        AddField(TempNameValueBuffer, AddHeaderField, Contact.FieldName("Salutation Code"))
    end;
}

