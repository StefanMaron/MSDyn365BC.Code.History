codeunit 139017 "SMTP Mail Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        Assert: Codeunit "Assert";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        MailManagement: Codeunit "Mail Management";
        NameTxt: Label 'Test Name';
        Test1AddressTxt: Label 'test1@test.com';
        Test2AddressTxt: Label 'test2@test.com';
        Test3AddressTxt: Label 'test3@test.com';
        Test1AddressInternationalTxt: Label 'navre´Š¢cepient5@micros´Š¢oft.c´Š¢m';
        MultipleAddressesTxt: Label 'test%1@test.com; test%2@test.com; test%3@test.com';
        MultipleAddressesInternationalTxt: Label 'test1@test.com, navre´Š¢cepient5@micros´Š¢oft.c´Š¢m';
        SubjectTxt: Label 'Test Subject';
        BodyTxt: Label 'Test body without html block';
        BodyHTMLTxt: Label '<body><invalidTag>Test Message</invalidTag></body>';
        AttachmentName: Label 'Attachment1.txt';
        MediaSubType: Text;
        RecipientList: List of [Text];
        Body: Text;

    [Test]
    [Scope('OnPrem')]
    procedure InitializeTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] Initialize DotNets

        // [GIVEN] Uninitialized SMTP codeunit
        // [WHEN] Try to add a subject
        // [THEN] It will throw an exception about DotNet variable not initialized
        assertError SMTP.AddSubject(SubjectTxt);
        Assert.ExpectedError('A DotNet variable has not been instantiated.');

        // [WHEN] Initialize and add a subject
        ClearLastError();
        SMTP.Initialize();
        SMTP.AddSubject(SubjectTxt);

        // [THEN] No exceptions thrown
        Assert.AreEqual('', GetLastErrorText(), 'Exception was thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddFromTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] Add From address

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add From with name and address
        // [THEN] From name and address are added
        SMTP.AddFrom(NameTxt, Test1AddressTxt);
        Assert.AreEqual('"' + NameTxt + '"' + ' <' + Test1AddressTxt + '>', SMTP.GetFrom(), 'From name/address do not match.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddReceipientTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
        ResultRecipient: Text;
        Counter: Integer;
    begin
        // [SCENARIO] Add recipients

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one recipient
        Recipients.Add(Test1AddressTxt);
        SMTP.AddRecipients(Recipients);

        // [THEN] Recipient is added
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The recipient list does not contain a recipient.');
        end;

        // [GIVEN] Fresh initialized SMTP codeunit
        SMTP.Initialize();
        Clear(ResultRecipients);

        // [WHEN] Add multiple recipients
        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);
        SMTP.AddRecipients(Recipients);

        // [THEN] Recipients are added  
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The recipient list does not contain a recipient.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('NoConfirmHandler')]
    procedure AddMultipleRecepients()
    var
        TempEmailItem: Record "Email Item" temporary;
        SMTPMailTest: Codeunit "SMTP Mail Test";
        Recipients: List of [Text];
        RecipientsCount: Integer;
        i: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 332563] Add multiple recipients to "Send to" / "Send CC" / "Send BCC" fields of Email Item.
        Clear(RecipientList);
        SMTPMailSetupInitialize();

        // [GIVEN] Email Item with "Send to" / "Send CC" / "Send BCC" = 'test1@test.com; test2@test.com; test3@test.com'.
        TempEmailItem.Initialize();
        TempEmailItem."From Address" := Test1AddressTxt;
        TempEmailItem.Subject := SubjectTxt;
        TempEmailItem."Send to" := StrSubstNo(MultipleAddressesTxt, 1, 2, 3);
        TempEmailItem."Send CC" := StrSubstNo(MultipleAddressesTxt, 4, 5, 6);
        TempEmailItem."Send BCC" := StrSubstNo(MultipleAddressesTxt, 7, 8, 9);
        TempEmailItem."Message Type" := TempEmailItem."Message Type"::"From Email Body Template";

        SMTPMailTest.SetMediaSubtype('html');
        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);
        SMTPMailTest.SetRecipients(Recipients);

        // [WHEN] Run SendMailOrDownload function of Mail Management codeunit on this Email Item record.
        // [WHEN] Wait for GetEmailRecepientsOnBeforeSentViaSMTP subscriber catches OnBeforeSentViaSMTP event.
        BindSubscription(SMTPMailTest);

        MailManagement.SendMailOrDownload(TempEmailItem, true);
        UnBindSubscription(SMTPMailTest);

        TempEmailItem."Message Type" := TempEmailItem."Message Type"::"Custom Message";
        SMTPMailTest.SetMediaSubtype('plain');
        BindSubscription(SMTPMailTest);

        MailManagement.SendMailOrDownload(TempEmailItem, true);
        UnBindSubscription(SMTPMailTest);
        // [THEN] Email."To" / Email.Cc / Email.Bcc fields of DotNet object MimeMessage contain lists of all corresponding recipients.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTextAndHtmlMessage()
    var
        SMTP: Codeunit "SMTP Mail";
        SMTPMailTests: Codeunit "SMTP Mail Test";
    begin
        // [SCENARIO] Create email as plain text or as html
        Clear(RecipientList);
        SMTPMailTests.SetMediaSubtype('html');
        RecipientList.Add(Test1AddressTxt);
        SMTPMailTests.SetRecipients(RecipientList);
        SMTPMailTests.SetBody('<html>HTML message</html>');
        BindSubscription(SMTPMailTests);

        SMTPMailSetupInitialize();
        SMTP.Initialize();
        SMTP.CreateMessage('test', Test1AddressTxt, Test1AddressTxt, SubjectTxt, '<html>HTML message</html>', true);
        SMTP.CreateMessage('test', Test1AddressTxt, RecipientList, SubjectTxt, '<html>HTML message</html>', true);
        SMTP.CreateMessage('test', Test1AddressTxt, RecipientList, SubjectTxt, '<html>HTML message</html>');

        // Verify on the Event Subscriber
        UnbindSubscription(SMTPMailTests);

        SMTPMailTests.SetMediaSubtype('plain');
        SMTPMailTests.SetBody('TEXT message');
        BindSubscription(SMTPMailTests);

        SMTPMailSetupInitialize();
        SMTP.Initialize();
        SMTP.CreateMessage('test', Test1AddressTxt, Test1AddressTxt, SubjectTxt, 'TEXT message', false);
        SMTP.CreateMessage('test', Test1AddressTxt, RecipientList, SubjectTxt, 'TEXT message', false);

        // Verify on the Event Subscriber
        UnbindSubscription(SMTPMailTests);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateMessageWithMultipleRecipients()
    var
        SMTP: Codeunit "SMTP Mail";
        SMTPMailTests: Codeunit "SMTP Mail Test";
    begin
        // [SCENARIO] Create message with multiple recipients
        Clear(RecipientList);
        SMTPMailTests.SetMediaSubtype('html');
        RecipientList.Add(Test1AddressTxt);
        RecipientList.Add(Test2AddressTxt);
        RecipientList.Add(Test3AddressTxt);
        SMTPMailTests.SetRecipients(RecipientList);
        SMTPMailTests.SetBody('<html>HTML message</html>');
        BindSubscription(SMTPMailTests);

        SMTPMailSetupInitialize();
        SMTP.Initialize();
        SMTP.CreateMessage('test', Test1AddressTxt, 'test1@test.com,test2@test.com,test3@test.com', SubjectTxt, '<html>HTML message</html>', true);
        SMTP.CreateMessage('test', Test1AddressTxt, StrSubstNo(MultipleAddressesTxt, 1, 2, 3), SubjectTxt, '<html>HTML message</html>', true);
        SMTP.CreateMessage('test', Test1AddressTxt, RecipientList, SubjectTxt, '<html>HTML message</html>', true);
        SMTP.CreateMessage('test', Test1AddressTxt, RecipientList, SubjectTxt, '<html>HTML message</html>');

        // Verify on the Event Subscriber
        UnbindSubscription(SMTPMailTests);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddReceipientInvalidEmailTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
    begin
        // [SCENARIO] Add recipients with invalid emails

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one recipient with a bad email address
        // [THEN] Recipient is not added and an error is thrown
        Recipients.Add('bademailaddress');
        asserterror SMTP.AddRecipients(Recipients);
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // [WHEN] Add one recipient with a bad email address
        // [THEN] Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@@example.com');
        asserterror SMTP.AddRecipients(Recipients);
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one recipient with a bad email address
        // // [THEN] Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@example.@com');
        asserterror SMTP.AddRecipients(Recipients);
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one recipient with a bad email address
        // // [THEN] Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bad emailaddress@example.com');
        asserterror SMTP.AddRecipients(Recipients);
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one recipient with a bad email address
        // // [THEN] Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@exa mple.com');
        asserterror SMTP.AddRecipients(Recipients);
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddRecipientInternationalCharactersText()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
        ResultRecipient: Text;
        Counter: Integer;
    begin
        // [SCENARIO] Add recipients with international characters

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one recipient
        Recipients.Add(Test1AddressInternationalTxt);
        SMTP.AddRecipients(Recipients);

        // [THEN] Recipient is added
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The recipient list does not contain a recipient.');
        end;

        // [GIVEN] Fresh initialized SMTP codeunit
        SMTP.Initialize();
        Clear(ResultRecipients);

        // [WHEN] Add multiple recipients
        Recipients.Add(Test1AddressTxt);
        SMTP.AddRecipients(Recipients);

        // [THEN] Recipient is added
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The recipient list does not contain a recipient.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddCCTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
        ResultRecipient: Text;
        Counter: Integer;
    begin
        // [SCENARIO] Add CC recipients

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one CC recipient
        Recipients.Add(Test1AddressTxt);
        SMTP.AddCC(Recipients);

        // [THEN] CC Recipient is added
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The CC recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The CC recipient list does not contain a recipient.');
        end;

        // [GIVEN] Fresh initialized SMTP codeunit
        SMTP.Initialize();
        Clear(ResultRecipients);

        // [WHEN] Add multiple CC recipients    
        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);
        SMTP.AddCC(Recipients);

        // [THEN] CC Recipients are added  
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The CC recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The CC recipient list does not contain a recipient.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddCCInvalidEmailTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
    begin
        // [SCENARIO] Add CC recipients with invalid emails

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one CC recipient with a bad email address
        // [THEN] CC Recipient is not added and an error is thrown
        Recipients.Add('bademailaddress');
        asserterror SMTP.AddCC(Recipients);
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The CC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // [WHEN] Add one CC recipient with a bad email address
        // [THEN] CC Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@@example.com');
        asserterror SMTP.AddCC(Recipients);
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The CC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one CC recipient with a bad email address
        // // [THEN] CC Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@example.@com');
        asserterror SMTP.AddCC(Recipients);
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The CC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one CC recipient with a bad email address
        // // [THEN] CC Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bad emailaddress@example.com');
        asserterror SMTP.AddCC(Recipients);
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The CC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one CC recipient with a bad email address
        // // [THEN] CC Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@exa mple.com');
        asserterror SMTP.AddCC(Recipients);
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The CC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddCCInternationalCharactersText()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
        ResultRecipient: Text;
        Counter: Integer;
    begin
        // [SCENARIO] Add CC recipients with international characters

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one CC recipient
        Recipients.Add(Test1AddressInternationalTxt);
        SMTP.AddCC(Recipients);

        // [THEN] CC Recipient is added
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The CC recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The CC recipient list does not contain a recipient.');
        end;

        // [GIVEN] Fresh initialized SMTP codeunit
        SMTP.Initialize();
        Clear(ResultRecipients);

        // [WHEN] Add multiple CC recipients
        Recipients.Add(Test1AddressTxt);
        SMTP.AddCC(Recipients);

        // [THEN] CC Recipient is added
        SMTP.GetCC(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The CC recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The CC recipient list does not contain a recipient.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBCCTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
        ResultRecipient: Text;
        Counter: Integer;
    begin
        // [SCENARIO] Add BCC recipients

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one BCC recipient
        Recipients.Add(Test1AddressTxt);
        SMTP.AddBCC(Recipients);

        // [THEN] BCC Recipient is added
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The BCC recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The BCC recipient list does not contain a recipient.');
        end;

        // [GIVEN] Fresh initialized SMTP codeunit
        SMTP.Initialize();
        Clear(ResultRecipients);

        // [WHEN] Add multiple BCC recipients
        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);
        SMTP.AddBCC(Recipients);

        // [THEN] BCC Recipients are added  
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The BCC recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The BCC recipient list does not contain a recipient.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBCCInvalidEmailTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
    begin
        // [SCENARIO] Add BCC recipients with invalid emails

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one BCC recipient with a bad email address
        // [THEN] BCC Recipient is not added and an error is thrown
        Recipients.Add('bademailaddress');
        asserterror SMTP.AddBCC(Recipients);
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The BCC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // [WHEN] Add one BCC recipient with a bad email address
        // [THEN] BCC Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@@example.com');
        asserterror SMTP.AddBCC(Recipients);
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The BCC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one BCC recipient with a bad email address
        // // [THEN] BCC Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@example.@com');
        asserterror SMTP.AddBCC(Recipients);
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The BCC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one BCC recipient with a bad email address
        // // [THEN] BCC Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bad emailaddress@example.com');
        asserterror SMTP.AddBCC(Recipients);
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The BCC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');

        // // [WHEN] Add one BCC recipient with a bad email address
        // // [THEN] BCC Recipient is not added and an error is thrown
        Clear(Recipients);
        Recipients.Add('bademailaddress@exa mple.com');
        asserterror SMTP.AddBCC(Recipients);
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(0, ResultRecipients.Count(), 'The BCC recipient count does not match.');
        Assert.ExpectedError('Could not add recipient');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBCCInternationalCharactersText()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
        ResultRecipient: Text;
        Counter: Integer;
    begin
        // [SCENARIO] Add BCC recipients with international characters

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add one BCC recipient
        Recipients.Add(Test1AddressInternationalTxt);
        SMTP.AddBCC(Recipients);

        // [THEN] BCC Recipient is added
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The BCC recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The BCC recipient list does not contain a recipient.');
        end;

        // [GIVEN] Fresh initialized SMTP codeunit
        SMTP.Initialize();
        Clear(ResultRecipients);

        // [WHEN] Add multiple BCC recipients
        Recipients.Add(Test1AddressTxt);
        SMTP.AddBCC(Recipients);

        // [THEN] BCC Recipient is added
        SMTP.GetBCC(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The BCC recipient count does not match.');

        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The BCC recipient list does not contain a recipient.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddSubjectTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] Add and change subject

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add a subject
        // [THEN] Subject is added
        SMTP.AddSubject(SubjectTxt);
        Assert.AreEqual(SubjectTxt, SMTP.GetSubject(), 'Subject was added incorrectly');

        // [WHEN] Change subject
        // [THEN] Subject is changed
        SMTP.AddSubject(SubjectTxt + '2');
        Assert.AreEqual(SubjectTxt + '2', SMTP.GetSubject(), 'Subject was changed incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBodyTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] Add and change body

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add a body
        // [THEN] Body is added
        SMTP.AddBody(BodyTxt);
        Assert.AreEqual(BodyTxt, SMTP.GetBody(), 'Body was added incorrectly');

        // [WHEN] Change body
        // [THEN] Body is changed
        SMTP.AddBody(BodyTxt + '2');
        Assert.AreEqual(BodyTxt + '2', SMTP.GetBody(), 'Body was changed incorrectly');

        // [WHEN] Change to empty body
        // [THEN] Body is empty
        SMTP.AddBody('');
        Assert.AreEqual('', SMTP.GetBody(), 'Body was changed incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBodyHTMLTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] Add and change body with HTML block.

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add a body
        // [THEN] Body is added
        SMTP.AddBody(BodyHTMLTxt);
        Assert.AreEqual(BodyHTMLTxt, SMTP.GetBody(), 'Body was added incorrectly.');

        // [WHEN] Change body
        // [THEN] Body is changed
        SMTP.AddBody(BodyHTMLTxt + '2');
        Assert.AreEqual(BodyHTMLTxt + '2', SMTP.GetBody(), 'Body was changed incorrectly');

        // [WHEN] Change to empty body
        // [THEN] Body is empty
        SMTP.AddBody('');
        Assert.AreEqual('', SMTP.GetBody(), 'Body was changed incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBodyHTMLExternalImageTest()
    var
        SMTP: Codeunit "SMTP Mail";
        BodyHTMLExternalImageTxt: Label '<body><img src="https://localhost:8080/external.jpg" /><br /><p>Message</p></body>';
    begin
        // [SCENARIO] Add and change body with HTML block with an external image.

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add a body
        // [THEN] Body is added
        SMTP.AddBody(BodyHTMLExternalImageTxt);
        Assert.IsTrue(SMTP.GetBody().Contains(BodyHTMLExternalImageTxt), 'Body was added incorrectly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBodyHTMLBadTagTest()
    var
        SMTP: Codeunit "SMTP Mail";
        BodyHTMLBadTagTxt: Label '<body><invalidTag>Test Message</invalidTag><img src="data:image/png;base64,Zm9v"></igm></body>';
    begin
        // [SCENARIO] Add and change body with HTML block

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add a body
        // [THEN] Body is added
        SMTP.AddBody(BodyHTMLBadTagTxt);
        Assert.AreEqual(BodyHTMLBadTagTxt, SMTP.GetBody(), 'Body was added incorrectly.');

        // [WHEN] Change body
        // [THEN] Body is changed
        SMTP.AddBody(BodyHTMLBadTagTxt + '2');
        Assert.AreEqual(BodyHTMLBadTagTxt + '2', SMTP.GetBody(), 'Body was changed incorrectly');

        // [WHEN] Change to empty body
        // [THEN] Body is empty
        SMTP.AddBody('');
        Assert.AreEqual('', SMTP.GetBody(), 'Body was changed incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBodyHTMLContentIdTest()
    var
        SMTP: Codeunit "SMTP Mail";
        BodyHTMLBase64Txt: Label '<body><invalidTag>Test Message</invalidTag><img src="data:image/png;base64,Zm9v"></img></body>';
    begin
        // [SCENARIO] Base64 image should be converted to Content Id

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add a body
        // [THEN] Body is added
        SMTP.AddBody(BodyHTMLBase64Txt);
        Assert.AreEqual(1, SMTP.GetLinkedResourcesCount(), 'The number of converted base64 strings is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddBodyPlainTextTest()
    var
        SMTP: Codeunit "SMTP Mail";
        AppendTxt: Label 'Text to be appended.';
    begin
        // [SCENARIO] Add and change plain text body

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();

        // [WHEN] Add a plain text body
        // [THEN] Plain text body is added
        SMTP.AddTextBody(BodyTxt);
        Assert.AreEqual(BodyTxt, SMTP.GetBody(), 'The body contents are incorrect.');

        // [WHEN] Append more text to body
        // [THEN] Plain text body has appended text
        SMTP.AppendTextBody(AppendTxt);
        Assert.AreEqual(BodyTxt + AppendTxt, SMTP.GetBody(), 'The body contents are incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsBodyHTMLFormattedText()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] Check if the body is HTML formatted varying on html or plain text body

        // [GIVEN] Initialized SMTP codeunit
        SMTP.Initialize();
        // [THEN] The initialized body is not HTML formatted
        Assert.IsFalse(SMTP.IsBodyHtmlFormatted(), 'Body is HTML formatted.');

        // [WHEN] Add a plain text body
        // [THEN] Body is not HTML formatted
        SMTP.AddTextBody(BodyTxt);
        Assert.IsFalse(SMTP.IsBodyHtmlFormatted(), 'Body is HTML formatted.');

        // [WHEN] Append a plain text body
        // [THEN] Body is not HTML formatted
        SMTP.AppendTextBody(BodyTxt);
        Assert.IsFalse(SMTP.IsBodyHtmlFormatted(), 'Body is HTML formatted.');

        // [WHEN] Add a HTML text body
        // [THEN] Body is HTML formatted
        SMTP.AddBody(BodyHTMLTxt);
        Assert.IsTrue(SMTP.IsBodyHtmlFormatted(), 'Body is not HTML formatted.');

        // [WHEN] Append a HTML text body
        // [THEN] Body is HTML formatted
        SMTP.AppendBody(BodyHTMLTxt);
        Assert.IsTrue(SMTP.IsBodyHtmlFormatted(), 'Body is not HTML formatted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateMessageTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
        ResultRecipients: List of [Text];
        ResultRecipient: Text;
        Counter: Integer;
    begin
        // [SCENARIO] Create message

        // [GIVEN] Initialized SMTP codeunit, SMTP Mail Setup and List of recipients
        SMTP.Initialize();
        SMTPMailSetupInitialize();
        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);

        // [WHEN] Create message with From name and address, Recipients, Subject and Body
        SMTP.CreateMessage(NameTxt, Test1AddressTxt, Recipients, SubjectTxt, BodyTxt);

        // [THEN] From name and address is inserted
        Assert.AreEqual('"' + NameTxt + '"' + ' <' + Test1AddressTxt + '>', SMTP.GetFrom(), 'From name/address do not match.');

        // [THEN] Recipients are inserted
        SMTP.GetRecipients(ResultRecipients);
        Assert.AreEqual(Recipients.Count(), ResultRecipients.Count(), 'The recipient count does not match.');
        for Counter := 1 to ResultRecipients.Count() do begin
            ResultRecipients.Get(Counter, ResultRecipient);
            Assert.IsTrue(Recipients.Contains(ResultRecipient), 'The recipient list does not contain a recipient.');
        end;

        // [THEN] Subject is inserted
        Assert.AreEqual(SubjectTxt, SMTP.GetSubject(), 'Subject does not match');

        // [THEN] Body is inserted
        Assert.AreEqual(BodyTxt, SMTP.GetBody(), 'Body does not match.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAttachmentTest()
    var
        SMTP: Codeunit "SMTP Mail";
        FileManagement: Codeunit "File Management";
        TmpFile: File;
        ServerFileName: Text;
    begin
        // [SCENARIO] Add an attachment using a file path without a filename

        // [GIVEN] Initialized SMTP codeunit and temporary file 
        SMTP.Initialize();
        ServerFileName := FileManagement.ServerTempFileName('txt');

        TmpFile.Create(ServerFileName);
        TmpFile.Write(BodyTxt);
        TmpFile.Close();

        // [WHEN] Add attachment by file path  
        // [THEN] Attachment successfully added
        Assert.IsTrue(SMTP.AddAttachment(ServerFileName, ''), 'Attachment was not added.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAttachmentWithNameTest()
    var
        SMTP: Codeunit "SMTP Mail";
        FileManagement: Codeunit "File Management";
        TmpFile: File;
        ServerFileName: Text;
    begin
        // [SCENARIO] Add an attachment using a file path with a filename

        // [GIVEN] Initialized SMTP codeunit and temporary file 
        SMTP.Initialize();
        ServerFileName := FileManagement.ServerTempFileName('txt');

        TmpFile.Create(ServerFileName);
        TmpFile.Write(BodyTxt);
        TmpFile.Close();

        // [WHEN] Add attachment by file path  
        // [THEN] Attachment successfully added
        Assert.IsTrue(SMTP.AddAttachment(ServerFileName, AttachmentName), 'Attachment was not added.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAttachmentWithInternationalNameTest()
    var
        SMTP: Codeunit "SMTP Mail";
        FileManagement: Codeunit "File Management";
        TmpFile: File;
        ServerFileName: Text;
        AttachmentInternationalName: Label 'försäljningsfaktura.txt';
    begin
        // [SCENARIO] Add an attachment using a file path with a international filename

        // [GIVEN] Initialized SMTP codeunit and temporary file 
        SMTP.Initialize();
        ServerFileName := FileManagement.ServerTempFileName('txt');

        TmpFile.Create(ServerFileName);
        TmpFile.Write(BodyTxt);
        TmpFile.Close();

        // [WHEN] Add attachment by file path  
        // [THEN] Attachment successfully added
        Assert.IsTrue(SMTP.AddAttachment(ServerFileName, AttachmentInternationalName), 'Attachment was not added.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAttachmentNoFileTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] Add an attachment using a empty file path

        // [GIVEN] Initialized SMTP codeunit and temporary file 
        SMTP.Initialize();

        // [WHEN] Add empty attachment by file path  
        // [THEN] Attachment was not successfully added
        Assert.IsFalse(SMTP.AddAttachment('', AttachmentName), 'Attachment was added.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAttachmentStreamTest()
    var
        SMTP: Codeunit "SMTP Mail";
        InStr: InStream;
        TmpFile: File;
    begin
        // [SCENARIO] Add an attachment using a stream

        // [GIVEN] Initialized SMTP codeunit, temporary file and stream to file
        SMTP.Initialize();
        TmpFile.CreateTempFile();
        TmpFile.CreateInStream(InStr);
        TmpFile.Write(BodyTxt);

        // [WHEN] Add attachment by stream  
        // [THEN] Attachment successfully added
        Assert.IsTrue(SMTP.AddAttachmentStream(InStr, AttachmentName), 'Attachment was not added.');

        TmpFile.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddAttachmentStreamWithoutStreamTest()
    var
        SMTP: Codeunit "SMTP Mail";
        InStr: InStream;
        TmpFile: File;
    begin
        // [SCENARIO] Add an attachment using a stream to nothing

        // [GIVEN] Initialized SMTP codeunit and stream to nothing
        SMTP.Initialize();
        TmpFile.CreateInStream(InStr);

        // [WHEN] Add attachment by stream  
        // [THEN] Attachment not successfully added
        Assert.IsFalse(SMTP.AddAttachmentStream(InStr, AttachmentName), 'Attachment was added.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendShowErrorTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
    begin
        // [SCENARIO] Try to send mail and display a error to the user

        // [GIVEN] Initialized SMTP codeunit, SMTP Mail Setup and email
        SMTP.Initialize();
        SMTPMailSetupInitialize();

        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);
        SMTP.CreateMessage(NameTxt, Test1AddressTxt, Recipients, SubjectTxt, BodyHTMLTxt);

        // [WHEN] Send mail
        // [THEN] An error is thrown that the server could not be connected to
        asserterror SMTP.SendShowError();
        Assert.ExpectedError('No connection could be made because the target machine actively refused it');

        LibraryNotificationMgt.RecallNotificationsForRecord(SMTPMailSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
    begin
        // [SCENARIO] Try to send

        // [GIVEN] Initialized SMTP codeunit, SMTP Mail Setup and mail
        SMTP.Initialize();
        SMTPMailSetupInitialize();

        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);
        SMTP.CreateMessage(NameTxt, Test1AddressTxt, Recipients, SubjectTxt, BodyHTMLTxt);

        // [WHEN] Send mail
        // [THEN] Send fails as the server is not contactable
        Assert.IsFalse(SMTP.Send(), 'SMTP server should not be contactable.');

        LibraryNotificationMgt.RecallNotificationsForRecord(SMTPMailSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLastErrorWithoutErrorTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
    begin
        // [SCENARIO] Get last error that was thrown

        // [GIVEN] Initialized SMTP codeunit, SMTP Mail Setup and list of recipients
        SMTP.Initialize();
        SMTPMailSetupInitialize();
        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);

        // [WHEN] Create mail but not send
        // [THEN] No error
        SMTP.CreateMessage(NameTxt, Test1AddressTxt, Recipients, SubjectTxt, BodyHTMLTxt);
        Assert.AreEqual('', SMTP.GetLastSendMailErrorText(), 'The last error message should be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLastErrorWithErrorTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
    begin
        // [SCENARIO] Get last error that was thrown

        // [GIVEN] Initialized SMTP codeunit, SMTP Mail Setup and email
        SMTP.Initialize();
        SMTPMailSetupInitialize();
        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);
        SMTP.CreateMessage(NameTxt, Test1AddressTxt, Recipients, SubjectTxt, BodyHTMLTxt);

        // [WHEN] Send mail
        // [THEN] Send fails as the server is not contactable
        Assert.IsFalse(SMTP.Send(), 'SMTP server should not be contactable.');
        Assert.AreNotEqual('', SMTP.GetLastSendMailErrorText(), 'The last error message should not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLastErrorAfterRecreatingMailAfterSendTest()
    var
        SMTP: Codeunit "SMTP Mail";
        Recipients: List of [Text];
    begin
        // [SCENARIO] Get last error that was thrown

        // [GIVEN] Initialized SMTP codeunit, SMTP Mail Setup and email
        SMTP.Initialize();
        SMTPMailSetupInitialize();
        Recipients.Add(Test1AddressTxt);
        Recipients.Add(Test2AddressTxt);
        Recipients.Add(Test3AddressTxt);
        SMTP.CreateMessage(NameTxt, Test1AddressTxt, Recipients, SubjectTxt, BodyHTMLTxt);

        // [WHEN] Send mail
        // [THEN] Send fails as the server is not contactable
        Assert.IsFalse(SMTP.Send(), 'SMTP server should not be contactable.');
        Assert.AreNotEqual('', SMTP.GetLastSendMailErrorText(), 'The last error message should not be empty.');

        // [WHEN] Create message
        // [THEN] Error message is reset and there are no errors
        SMTP.CreateMessage(NameTxt, Test1AddressTxt, Recipients, SubjectTxt, BodyHTMLTxt);
        Assert.AreEqual('', SMTP.GetLastSendMailErrorText(), 'The last error message should be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsEnabledTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] Check if SMTP is enabled

        // [GIVEN] Initialized SMTP codeunit and SMTP Mail setup is not initialized
        SMTP.Initialize();
        SMTPMailSetupClear();

        // [WHEN] SMTP Mail Setup is not initialized
        // [THEN] SMTP is not enabled
        Assert.IsFalse(SMTP.IsEnabled(), 'SMTP is enabled.');

        // [WHEN] SMTP Mail Setup is initialized
        SMTPMailSetupInitialize();

        // [THEN] SMTP is enabled
        Assert.IsTrue(SMTP.IsEnabled(), 'SMTP is not enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetupThroughKeyVaultSetupTest()
    var
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
        SMTPMail: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] If a SMTP setup exists in the Key Vault, then that setup is used if no other setup exists

        // [GIVEN] No setup exists
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider;
        SMTPMailSetup.DeleteAll();
        Assert.IsFalse(SMTPMail.IsEnabled, 'SMTP Setup was not empty.');

        // [GIVEN] Some SMTP setup key vault secrets
        LibraryAzureKVMockMgmt.AddMockAzureKeyvaultSecretProviderMapping('AllowedApplicationSecrets', 'SmtpSetup');
        LibraryAzureKVMockMgmt.AddMockAzureKeyvaultSecretProviderMappingFromFile(
          'SmtpSetup',
          LibraryUtility.GetInetRoot + '\App\Test\Files\AzureKeyVaultSecret\SMTPSetupSecret.txt');

        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider;

        // [WHEN] It is checked whether SMTP is set up
        // [THEN] The SMTP setup from the key vault is used
        Assert.IsTrue(SMTPMail.IsEnabled, 'SMTP was not set up.');

        // Tear down key vault mock after use
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider;
    end;

    local procedure SMTPMailSetupInitialize()
    begin
        SMTPMailSetupClear();

        // Add a new test record
        SMTPMailSetup.Init();
        SMTPMailSetup."SMTP Server" := 'localhost';
        SMTPMailSetup."SMTP Server Port" := 9999;
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Anonymous;
        SMTPMailSetup.Insert();
    end;

    local procedure SMTPMailSetupClear()
    begin
        // Clear all old records
        SMTPMailSetup.DeleteAll();
        Commit();
    end;

    local procedure FormatToSemiColon(String: Text): Text
    begin
        exit(String.Replace(',', ';'));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SMTP Mail Internals", 'OnAfterCreateMessage', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterCreateMessage(Email: DotNet MimeMessage; BodyBuilder: DotNet MimeBodyBuilder)
    var
        TempBlob: Codeunit "Temp Blob";
        CancelationToken: DotNet CancellationToken;
        OutStream: OutStream;
        InStream: Instream;
        Recipients: List of [Text];
        Value: DotNet InternetAddress;
        TextValue: Text;
        Found: Boolean;
    begin
        TempBlob.CreateOutStream(OutStream);
        BodyBuilder.ToMessageBody().WriteTo(OutStream, CancelationToken);
        TempBlob.CreateInStream(InStream);
        InStream.Read(TextValue);

        Assert.IsTrue(TextValue.Contains(GetBody()), 'A different Email body was expected.');

        Assert.AreEqual('text', BodyBuilder.ToMessageBody().ContentType.MediaType, 'A different media type was expected.');
        Assert.AreEqual(GetMediaSubType(), BodyBuilder.ToMessageBody().ContentType.MediaSubType, 'A different media type was expected.');
        Assert.IsTrue(Format(Email.From.item(0)).Contains(Test1AddressTxt), 'A different Sender was expected.');
        Assert.AreEqual(SubjectTxt, Email.Subject, 'A different Subject was expected.');
        GetRecipients(Recipients);

        foreach TextValue in Recipients do begin
            Found := false;
            foreach Value in Email."To" do
                if Format(Value).Contains(TextValue) then
                    Found := true;
            Assert.IsTrue(Found, StrSubstNo('Address %1 was not in Recipient List', TextValue));
        end;
    end;

    procedure GetMediaSubtype(): Text
    begin
        exit(MediaSubType);
    end;

    procedure SetMediaSubtype(Value: Text)
    begin
        MediaSubType := Value;
    end;

    procedure GetRecipients(var Value: List of [Text]);
    begin
        Value := RecipientList;
    end;

    procedure SetRecipients(Value: List of [Text]);
    begin
        RecipientList := Value;
    end;

    procedure GetBody(): Text
    begin
        exit(Body);
    end;

    procedure SetBody(Value: Text)
    begin
        Body := Value;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnBeforeSentViaSMTP', '', false, false)]
    [Scope('OnPrem')]
    procedure GetRecepientsOnBeforeSentViaSMTP(var TempEmailItem: Record "Email Item" temporary; var SMTPMail: Codeunit "SMTP Mail")
    var
        Recipients: List of [Text];
        RecipientsCount: Integer;
        i: Integer;
    begin
        SMTPMail.GetRecipients(Recipients);
        RecipientsCount := Recipients.Count();
        Assert.AreEqual(3, RecipientsCount, '');
        for i := 1 to RecipientsCount do
            Assert.AreEqual(StrSubstNo('test%1@test.com', i), Recipients.Get(i), '');

        Clear(Recipients);
        SMTPMail.GetCC(Recipients);
        RecipientsCount := Recipients.Count();
        Assert.AreEqual(3, RecipientsCount, '');
        for i := 1 to RecipientsCount do
            Assert.AreEqual(StrSubstNo('test%1@test.com', i + 3), Recipients.Get(i), '');

        Clear(Recipients);
        SMTPMail.GetBCC(Recipients);
        RecipientsCount := Recipients.Count();
        Assert.AreEqual(3, RecipientsCount, '');
        for i := 1 to RecipientsCount do
            Assert.AreEqual(StrSubstNo('test%1@test.com', i + 6), Recipients.Get(i), '');
    end;
}