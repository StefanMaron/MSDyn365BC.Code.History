codeunit 134422 "Rep. Selections - Std. Stmt."
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Report Selection] [Standard Statement] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        Initialized: Boolean;
        CustomerEmailTxt: Label 'Customer@contoso.com';
        NoDataOutputErr: Label 'No data exists for the specified report filters.';
        TargetEmailAddressErr: Label 'The target email address has not been specified';
        ReqParametersTemplatesTok: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Standard Statement" id="1316"><Options><Field name="StartDate">%1</Field><Field name="EndDate">%2</Field><Field name="PrintEntriesDue">false</Field><Field name="PrintAllHavingEntry">false</Field><Field name="PrintAllHavingBal">true</Field><Field name="PrintReversedEntries">false</Field><Field name="PrintUnappliedEntries">false</Field><Field name="IncludeAgingBand">false</Field><Field name="PeriodLength">1M+CM</Field><Field name="DateChoice">0</Field><Field name="LogInteraction">true</Field><Field name="SupportedOutputMethod">%3</Field><Field name="ChosenOutputMethod">%4</Field><Field name="PrintIfEmailIsMissing">%5</Field></Options><DataItems><DataItem name="Customer">VERSION(1) SORTING(Field1) WHERE(Field1=1(%6))</DataItem><DataItem name="Integer">VERSION(1) SORTING(Field1)</DataItem><DataItem name="CurrencyLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="CustLedgEntryHdr">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DtldCustLedgEntries">VERSION(1) SORTING(Field9,Field4,Field3,Field10)</DataItem><DataItem name="CustLedgEntryFooter">VERSION(1) SORTING(Field1)</DataItem><DataItem name="OverdueVisible">VERSION(1) SORTING(Field1)</DataItem><DataItem name="CustLedgEntry2">VERSION(1) SORTING(Field3,Field36,Field43,Field37,Field11)</DataItem><DataItem name="OverdueEntryFooder">VERSION(1) SORTING(Field1)</DataItem><DataItem name="AgingBandVisible">VERSION(1) SORTING(Field1)</DataItem><DataItem name="AgingCustLedgEntry">VERSION(1) SORTING(Field3,Field36,Field43,Field37,Field11)</DataItem><DataItem name="AgingBandLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="LetterText">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>';
        StandardStatementReportOutputType: Option Print,Preview,Word,PDF,Email,XML;
        ConfirmStartJobQueueQst: Label 'Do you want to set the job queue entry up to run immediately?';
        UnexpectedConfirmationErr: Label 'Unxpected confimation.';
        StatementTitleDocxTxt: Label 'Statement for %1_%2 as of %3.docx';
        StatementTitlePdfTxt: Label 'Statement for %1 as of %2.pdf';
        StatementTitleHtmlTxt: Label 'Statement for %1 as of %2.html';
        StatementTitlePrintDocxTxt: Label 'Statement for %1 as of %2.docx';
        IgnoringFailureSendingEmailErr: Label 'A call to MailKit.Net.Smtp.SmtpClient.Connect failed with this message: No connection could be made because the target machine actively refused';
        MoreErrorsOnErrorMessagesPageErr: Label '%1 contains more errors than expected.';
        LessErrorsOnErrorMessagesPageErr: Label '%1 contains less errors than expected.';
        RequestParametersErr: Label 'Request parameters for the Standard Statement report have not been set up.';

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_BlankAddress()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize;

        PrepareCustomerWithEntries(Customer, '', GetStandardStatementReportID);
        Commit;

        ErrorMessages.Trap;
        RunReportFromCard(Customer, StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer.Find;
        Customer.TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_NoEntries()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize;

        PrepareCustomerWithoutEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        ErrorMessages.Trap;
        RunReportFromCard(Customer, StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer.Find;
        Customer.TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer()
    var
        Customer: Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize;

        PrepareCustomerWithEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportFromCard(Customer, StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(Customer.Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer.Find;
        Customer.TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataNoEmail_B_DataEmail_PrintIfEmailMissing()
    var
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        Customer: array[2] of Record Customer;
        XPath: Text;
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_NoDataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        ErrorMessages.Trap;
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataNoEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        Customer: array[2] of Record Customer;
        XPath: Text;
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_NoDataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        ErrorMessages.Trap;
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        XPath: Text;
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);

        // Report generated to Print
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0);

        // Report generated to Send email
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[2]."No.", 0);

        // Report generated for email body
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[2]."No.", 0);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        XPath: Text;
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap;
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        XPath: Text;
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[2]."No.", 0);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        XPath: Text;
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[2]."No.", 0);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        XPath: Text;
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        // pdf attachment Customer[1]
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0); // Customer No.
        // html body Customer[1]
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0); // Customer No.
        // generated that was not sent Customer[2]
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[2]."No.", 0); // Customer No.

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        ErrorMessages.Trap;
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap;
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap;
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap;
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap;
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        ErrorMessages.Trap;
        asserterror RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_BlankAddress()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize;

        PrepareCustomerWithEntries(Customer, '', GetStandardStatementReportID);
        Commit;

        RunBackgroundReportFromCard(Customer."No.", StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        AssertReportInboxEmpty;

        Customer.Find;
        Customer.TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_NoEntries()
    var
        Customer: Record Customer;
        ActivityLog: Record "Activity Log";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize;

        PrepareCustomerWithoutEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        ActivityLog.SetRange("User ID", UserId);
        Assert.RecordIsEmpty(ActivityLog);

        RunBackgroundReportFromCard(Customer."No.", StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        AssertReportInboxEmpty;

        Customer.Find;
        Customer.TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer()
    var
        Customer: Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize;

        PrepareCustomerWithEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(Customer."No.", StandardStatementReportOutputType::Email, false);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer));
        // added to zip docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer.Find;
        Customer.TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataNoEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_NoDataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataNoEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_NoDataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // added to zip
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox
        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // added to zip
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox
        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(Customer[1]."No.", StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // added to zip
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox
        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // added to zip
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox (Zip with two files)
        AssertReportInboxCountZip(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // added to zip docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox
        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountZip(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox (Zip with 2 files)
        AssertReportInboxCountZip(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox (Zip with 2 files)
        AssertReportInboxCountZip(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // word for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AssertActivityLog(TempErrorMessage);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // pdf for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountPdf(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // pdf for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountPdf(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // pdf to add to zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // pdf to add to zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountZip(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountPdf(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountPdf(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_SingleCustomer_BlankAddress()
    var
        Customer: Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        XPath: Text;
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" with entries, email is not specified and Customer "B" does not exist.
        Initialize;

        PrepareCustomerWithEntries(Customer, '', GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(Customer."No.", StandardStatementReportOutputType::Print, false);

        Customer.Find;
        Customer.TestField("Last Statement No.", 1);

        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer."No.", 0);

        Customer.Find;
        Customer.TestField("Last Statement No.", 1);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_SingleCustomer_NoEntries()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        ErrorMessages: TestPage "Error Messages";
        XPath: Text;
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" without entries and Customer "B" does not exist.
        Initialize;

        PrepareCustomerWithoutEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);

        ErrorMessages.Trap;
        asserterror RunReportWithParameters(Customer."No.", StandardStatementReportOutputType::Print, false);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer.Find;
        Customer.TestField("Last Statement No.", 0);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_SingleCustomer()
    var
        Customer: Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        XPath: Text;
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" with entries and Customer "B" does not exist.
        Initialize;

        PrepareCustomerWithEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(Customer."No.", StandardStatementReportOutputType::Print, false);

        Customer.Find;
        Customer.TestField("Last Statement No.", 1);

        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer."No.", 0);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_TwoCustomers_A_Data_B_Data()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        XPath: Text;
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" with entries and Customer "B" with entries. Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[2]."No.", 1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_TwoCustomers_A_NoData_B_Data()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        XPath: Text;
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" without entries and Customer "B" with entries.Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[2]."No.", 0);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_TwoCustomers_A_Data_B_NoData()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        XPath: Text;
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" with entries and Customer "B" without entries. Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        RepSelectionsStdStmt.GetLibraryVariableStorage(LibraryVariableStorageLocal);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorageLocal.DequeueText, '');
        XPath := '//ReportDataSet/DataItems/DataItem/Columns/Column';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(XPath, Customer[1]."No.", 0);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_TwoCustomers_A_NoData_B_NoData()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryVariableStorageLocal: Codeunit "Library - Variable Storage";
        ErrorMessages: TestPage "Error Messages";
        XPath: Text;
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" without entries and Customer "B" without entries. Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        BindSubscription(RepSelectionsStdStmt);

        ErrorMessages.Trap;
        asserterror RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorageLocal.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_SingleCustomer_BlankAddress()
    var
        Customer: Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to print when Customer "A" with entries, email is not specified and Customer "B" does not exist.
        Initialize;

        PrepareCustomerWithEntries(Customer, '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(Customer."No.", StandardStatementReportOutputType::Print, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePrintDocx);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer.Find;
        Customer.TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_SingleCustomer_NoEntries()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to print when Customer "A" without entries and Customer "B" without entries. Filter = "A"
        Initialize;

        PrepareCustomerWithoutEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(Customer."No.", StandardStatementReportOutputType::Print, false);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxEmpty;

        Customer.Find;
        Customer.TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_SingleCustomer()
    var
        Customer: Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to print when Customer "A" with entries and Customer "B" does not exist. Filter = "A"
        Initialize;

        PrepareCustomerWithEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(Customer."No.", StandardStatementReportOutputType::Print, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePrintDocx);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer.Find;
        Customer.TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_TwoCustomers_A_Data_B_Data()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to print when Customer "A" with entries and Customer "B" with entries. Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePrintDocx);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_TwoCustomers_A_NoData_B_Data()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to print when Customer "A" without entries and Customer "B" with entries. Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePrintDocx);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_TwoCustomers_A_Data_B_NoData()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to print when Customer "A" with entries and Customer "B" without entries. Filter = "A|B"
        Initialize;

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePrintDocx);
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxCountWord(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_TwoCustomers_A_NoData_B_NoData()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to print when Customer "A" without entries and Customer "B" without entries. Filter = "A|B"
        Initialize;

        PrepareCustomerWithoutEntries(Customer[1], '', GetStandardStatementReportID);
        PrepareCustomerWithoutEntries(Customer[2], '', GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty;

        AssertReportInboxEmpty;

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_AddExpectedErrorMessage()
    var
        ErrorMessage: Record "Error Message";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Can't insert non temporary error entry
        asserterror AddExpectedErrorMessage(ErrorMessage, 'Some error');
        Assert.ExpectedError('Error message record must be temporary');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CustomReportSelection_CheckSendToEmail()
    var
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: Record Customer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CheckEmailSendTo of TAB9657 throws error when "Send to Email" is blank
        Initialize;

        CreateCustomer(Customer);

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, Customer."No.", GetStandardStatementReportID, true, true,
          CustomReportLayout.InitBuiltInLayout(GetStandardStatementReportID, CustomReportLayout.Type::Word),
          '', CustomReportSelection.Usage::"C.Statement");

        asserterror CustomReportSelection.CheckEmailSendTo;

        Assert.ExpectedError(StrSubstNo('%1 in %2', TargetEmailAddressErr, CustomReportSelection.RecordId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_COD8811_Run_Xml_Negative()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Job Queue] [Xml] [UT]
        // [SCENARIO] Enqueue to print when Customer "A" with entries and Customer "B" with entries. Filter = "A|B"
        Initialize;

        JobQueueEntry.ID := CreateGuid;
        JobQueueEntry."User ID" := UserId;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Customer Statement via Queue";
        JobQueueEntry.Insert;
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);

        AddExpectedErrorMessage(TempErrorMessage, RequestParametersErr);
        AssertActivityLog(TempErrorMessage);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_DataEmail_SmtpError()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueueed email with Customer "A" having entries failed with SMTP error
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        // Email sending throws error (we don't handle it)
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(Customer[1]."No.", StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, IgnoringFailureSendingEmailErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1])); // buffer to add to report inbox
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Commit;
        AssertReportInboxCountPdf(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataEmail_SmtpError()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueueed email with Customers "A" and "B" both having entries failed with SMTP error
        Initialize;

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID);
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID);
        Commit;

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber;
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber;
        BindSubscription(LibraryTempNVBufferHandler);
        // Email sending throws error (we don't handle it)
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, IgnoringFailureSendingEmailErr);
        AddExpectedErrorMessage(TempErrorMessage, IgnoringFailureSendingEmailErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1])); // buffer to add to report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2])); // buffer to add to report inbox
        LibraryTempNVBufferHandler.AssertQueueEmpty;

        Commit;
        AssertReportInboxCountZip(1);

        Customer[1].Find;
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find;
        Customer[2].TestField("Last Statement No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        InventorySetup: Record "Inventory Setup";
        CompanyInformation: Record "Company Information";
        ReportLayoutSelection: Record "Report Layout Selection";
        JobQueueEntry: Record "Job Queue Entry";
        ActivityLog: Record "Activity Log";
        ReportInbox: Record "Report Inbox";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryVariableStorage.Clear;
        CustomReportSelection.DeleteAll;
        ReportSelections.DeleteAll;
        ReportLayoutSelection.DeleteAll;
        LibraryWorkflow.SetUpSMTPEmailSetup;
        LibrarySetupStorage.Restore;

        // Page opening may cause DB (i.e. Business Chart insertion) transaction. So, open, close, commit  and reopen
        CustomerCard.OpenView;
        CustomerCard.Close;

        // Job Queue Entry could not be deleted when test fails unexpectedly. That caused other false negative results
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Customer Statement via Queue");
        JobQueueEntry.SetRange("User ID", UserId);
        JobQueueEntry.DeleteAll;

        // We should clean legacy activity log. 
        ActivityLog.SetRange("User ID", UserId);
        ActivityLog.DeleteAll;

        // We should clean legacy report inbox. 
        ReportInbox.SetRange("User ID", UserId);
        ReportInbox.SetRange("Report ID", GetStandardStatementReportID());
        ReportInbox.DeleteAll();

        Commit;

        if Initialized then
            exit;

        Initialized := true;

        CompanyInformation.Get;
        CompanyInformation."SWIFT Code" := 'A';
        CompanyInformation.Modify;

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        Commit;

        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        BindSubscription(LibraryFileMgtHandler);
    end;

    local procedure AddExpectedErrorMessage(var TempErrorMessage: Record "Error Message" temporary; ErrorMessage: Text)
    begin
        Assert.IsTrue(TempErrorMessage.IsTemporary, 'Error message record must be temporary');
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, ErrorMessage);
    end;

    local procedure CreateCustomer(var Customer: Record Customer): Code[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);

        Customer.Validate(Name, LibraryUtility.GenerateGUID);
        Customer.Validate(Address, LibraryUtility.GenerateGUID);

        LibraryERM.CreateCountryRegion(CountryRegion);

        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate(City, LibraryUtility.GenerateGUID);
        Customer.Validate("Post Code", LibraryUtility.GenerateGUID);
        Customer.Modify(true);

        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));  // Take Random Unit Price greater than 1000 to avoid rounding issues.
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        ShippingAgent: Record "Shipping Agent";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        LibraryInventory.CreateShippingAgent(ShippingAgent);
        SalesHeader.Validate("Package Tracking No.", GenerateRandomPackageTrackingNo);
        SalesHeader.Validate("Shipping Agent Code", ShippingAgent.Code);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, 1);
    end;

    local procedure GetStandardStatementReportID(): Integer
    begin
        exit(REPORT::"Standard Statement");
    end;

    local procedure GenerateRandomPackageTrackingNo(): Text[30]
    var
        DummySalesHeader: Record "Sales Header";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummySalesHeader."Package Tracking No.")),
            1, MaxStrLen(DummySalesHeader."Package Tracking No.")));
    end;

    [Scope('OnPrem')]
    procedure GetLibraryVariableStorage(var LibraryVariableStorageReturn: Codeunit "Library - Variable Storage")
    begin
        LibraryVariableStorageReturn := LibraryVariableStorage;
    end;

    local procedure GetTwoCustomersFilter(Customer: array[2] of Record Customer): Text
    begin
        exit(StrSubstNo('%1|%2', Customer[1]."No.", Customer[2]."No."));
    end;

    local procedure GetStatementTitleDocx(Customer: Record Customer): Text
    begin
        exit(StrSubstNo(StatementTitleDocxTxt, Customer.Name, GetReportCaption(GetStandardStatementReportID), Format(WorkDate, 0, 9)));
    end;

    local procedure GetStatementTitlePdf(Customer: Record Customer): Text
    begin
        exit(StrSubstNo(StatementTitlePdfTxt, Customer.Name, Format(WorkDate, 0, 9)));
    end;

    local procedure GetStatementTitleHtml(Customer: Record Customer): Text
    begin
        exit(StrSubstNo(StatementTitleHtmlTxt, Customer.Name, Format(WorkDate, 0, 9)));
    end;

    local procedure GetStatementTitlePrintDocx(): Text
    begin
        exit(StrSubstNo(StatementTitlePrintDocxTxt, GetReportCaption(GetStandardStatementReportID), Format(WorkDate, 0, 9)));
    end;

    local procedure GetReportCaption(ReportID: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportID);
        exit(AllObjWithCaption."Object Caption")
    end;

    local procedure InsertCustomReportSelectionCustomer(var CustomReportSelection: Record "Custom Report Selection"; CustomerNo: Code[20]; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; SendToAddress: Text[200]; ReportUsage: Option)
    begin
        with CustomReportSelection do begin
            Init;
            Validate("Source Type", DATABASE::Customer);
            Validate("Source No.", CustomerNo);
            Validate(Usage, ReportUsage);
            Validate(Sequence, Count + 1);
            Validate("Report ID", ReportID);
            Validate("Use for Email Attachment", UseForEmailAttachment);
            Validate("Use for Email Body", UseForEmailBody);
            Validate("Email Body Layout Code", EmailBodyLayoutCode);
            Validate("Send To Email", SendToAddress);
            Insert(true);
        end;
    end;

    local procedure InsertReportSelections(var ReportSelections: Record "Report Selections"; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; ReportUsage: Option)
    begin
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.SetRange(Sequence, '1');
        ReportSelections.SetRange("Report ID", ReportID);
        if not ReportSelections.IsEmpty then
            exit;

        with ReportSelections do begin
            Init;
            Validate(Usage, ReportUsage);
            Validate(Sequence, '1');
            Validate("Report ID", ReportID);
            Validate("Use for Email Attachment", UseForEmailAttachment);
            Validate("Use for Email Body", UseForEmailBody);
            Validate("Email Body Layout Code", EmailBodyLayoutCode);
            Insert(true);
        end;
    end;

    local procedure PrepareCustomerWithEntries(var Customer: Record Customer; EmailAddress: Text; ReportId: Integer)
    var
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportLayoutCode: Code[20];
    begin
        CreateCustomer(Customer);
        CreateSalesInvoice(SalesHeader, Customer);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        InsertReportSelections(
          ReportSelections, GetStandardStatementReportID, false, false, '', ReportSelections.Usage::"C.Statement");

        CustomReportLayout.SetRange("Report ID", ReportId);
        CustomReportLayout.SetRange("Built-In", true);
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        if CustomReportLayout.FindFirst then
            CustomReportLayoutCode := CustomReportLayout.Code
        else
            CustomReportLayoutCode := CustomReportLayout.InitBuiltInLayout(ReportId, CustomReportLayout.Type::Word);

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, Customer."No.", ReportId, true, true,
          CustomReportLayoutCode, CopyStr(EmailAddress, 1, 200), CustomReportSelection.Usage::"C.Statement");
    end;

    local procedure PrepareCustomerWithoutEntries(var Customer: Record Customer; EmailAddress: Text; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportLayoutCode: Code[20];
    begin
        CreateCustomer(Customer);

        InsertReportSelections(
          ReportSelections, GetStandardStatementReportID, false, false, '', ReportSelections.Usage::"C.Statement");

        CustomReportLayout.SetRange("Report ID", ReportId);
        CustomReportLayout.SetRange("Built-In", true);
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        if CustomReportLayout.FindFirst then
            CustomReportLayoutCode := CustomReportLayout.Code
        else
            CustomReportLayoutCode := CustomReportLayout.InitBuiltInLayout(ReportId, CustomReportLayout.Type::Word);

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, Customer."No.", ReportId, true, true,
          CustomReportLayoutCode, CopyStr(EmailAddress, 1, 200), CustomReportSelection.Usage::"C.Statement");
    end;

    local procedure RunReportFromCard(Customer: Record Customer; ReportOutputType: Option; PrintIfEmailIsMissing: Boolean)
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryVariableStorage.Enqueue(ReportOutputType);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(PrintIfEmailIsMissing);

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);

        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard."Report Statement".Invoke;
        CustomerCard.Close;
    end;

    local procedure RunReportWithParameters(CustomerFilter: Text; ReportOutputType: Option; PrintRemaining: Boolean)
    var
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        OutputTypeInt: Integer;
        MethodTypeInt: Integer;
        ReportParameters: Text;
    begin
        OutputTypeInt := ReportOutputType;

        case ReportOutputType of
            StandardStatementReportOutputType::Email:
                MethodTypeInt := CustomLayoutReporting.GetEmailOption;
            StandardStatementReportOutputType::PDF:
                MethodTypeInt := CustomLayoutReporting.GetPDFOption;
            StandardStatementReportOutputType::Preview:
                MethodTypeInt := CustomLayoutReporting.GetPreviewOption;
            StandardStatementReportOutputType::Print:
                MethodTypeInt := CustomLayoutReporting.GetPrintOption;
            StandardStatementReportOutputType::Word:
                MethodTypeInt := CustomLayoutReporting.GetWordOption;
            StandardStatementReportOutputType::XML:
                MethodTypeInt := CustomLayoutReporting.GetXMLOption;
        end;

        ReportParameters :=
          StrSubstNo(
            ReqParametersTemplatesTok, Format(WorkDate, 0, 9), Format(WorkDate, 0, 9),
            OutputTypeInt, MethodTypeInt, Format(PrintRemaining, 0, 9), CustomerFilter);

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        CustomerLayoutStatement.RunReportWithParameters(ReportParameters);
    end;

    local procedure RunBackgroundReportFromCard(CustomerFilter: Text; ReportOutputType: Option; PrintRemaining: Boolean)
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        LibraryJobQueue: Codeunit "Library - Job Queue";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryVariableStorage.Enqueue(ReportOutputType);
        LibraryVariableStorage.Enqueue(CustomerFilter);
        LibraryVariableStorage.Enqueue(PrintRemaining);
        CustomerCard.OpenEdit;
        CustomerCard.FILTER.SetFilter("No.", CustomerFilter);
        CustomerCard.BackgroundStatement.Invoke;
        CustomerCard.Close;

        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        Assert.RecordCount(TempJobQueueEntry, 1);
        TempJobQueueEntry.TestField("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.TestField("Object ID to Run", CODEUNIT::"Customer Statement via Queue");

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Background);
        BindSubscription(TestClientTypeSubscriber);
        CODEUNIT.Run(TempJobQueueEntry."Object ID to Run", TempJobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, 9651, 'OnBeforeMergeDocument', '', false, false)]
    local procedure VerifyXmlContainsDatasetOnBeforeMergeDocument(ReportID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; InStrXmlData: InStream; PrinterName: Text; OutStream: OutStream; var Handled: Boolean; IsFileNameBlank: Boolean)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        FileManagement: Codeunit "File Management";
        XmlNodeDocument: DotNet XmlNode;
        XmlNodeFound: DotNet XmlNode;
        FileDotNet: DotNet File;
        FilePath: Text;
        FileText: Text;
        XmlHasDataset: Boolean;
    begin
        XMLDOMManagement.LoadXMLNodeFromInStream(InStrXmlData, XmlNodeDocument);
        XmlHasDataset := XMLDOMManagement.FindNode(XmlNodeDocument, 'DataItems', XmlNodeFound);

        if XmlHasDataset then
            XmlHasDataset := XmlNodeFound.ChildNodes.Count > 0;

        if not XmlHasDataset then
            exit;

        FilePath := FileManagement.ServerTempFileName('xml');
        LibraryVariableStorage.Enqueue(FilePath);
        FileText := XmlNodeDocument.OuterXml;
        FileDotNet.WriteAllText(FilePath, FileText);
    end;

    local procedure AssertActivityLog(var TempErrorMessage: Record "Error Message" temporary)
    var
        ActivityLog: Record "Activity Log";
    begin
        TempErrorMessage.FindSet;
        ActivityLog.SetRange("User ID", UserId);
        ActivityLog.FindSet;
        repeat
            Assert.ExpectedMessage(TempErrorMessage.Description, LibraryUtility.ConvertCRLFToBackSlash(ActivityLog.Description));
            ActivityLog.TestField(Status, ActivityLog.Status::Failed);
            ActivityLog.Next;
        until TempErrorMessage.Next = 0;

        Assert.RecordCount(ActivityLog, TempErrorMessage.Count);
    end;

    local procedure AssertErrorsOnErrorMessagesPage(ErrorMessages: TestPage "Error Messages"; var TempErrorMessage: Record "Error Message" temporary)
    var
        Stop: Boolean;
    begin
        TempErrorMessage.FindSet;
        repeat
            Assert.ExpectedMessage(TempErrorMessage.Description, ErrorMessages.Description.Value);
            ErrorMessages."Message Type".AssertEquals(TempErrorMessage."Message Type");
            Stop := TempErrorMessage.Next = 0;
            if not Stop then
                Assert.IsTrue(ErrorMessages.Next, StrSubstNo(LessErrorsOnErrorMessagesPageErr, ErrorMessages.Caption));
        until Stop;

        Assert.IsFalse(ErrorMessages.Next, StrSubstNo(MoreErrorsOnErrorMessagesPageErr, ErrorMessages.Caption));
    end;

    local procedure AssertReportInboxEmpty()
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.SetRange("Report ID", GetStandardStatementReportID);
        ReportInbox.SetRange("User ID", UserId);
        Assert.RecordIsEmpty(ReportInbox);
    end;

    local procedure AssertReportInboxCountWord(ExpectedCount: Integer)
    var
        ReportInbox: Record "Report Inbox";
    begin
        AssertReportInboxCountWithType(ExpectedCount, ReportInbox."Output Type"::Word);
    end;

    local procedure AssertReportInboxCountZip(ExpectedCount: Integer)
    var
        ReportInbox: Record "Report Inbox";
    begin
        AssertReportInboxCountWithType(ExpectedCount, ReportInbox."Output Type"::Zip);
    end;

    local procedure AssertReportInboxCountPdf(ExpectedCount: Integer)
    var
        ReportInbox: Record "Report Inbox";
    begin
        AssertReportInboxCountWithType(ExpectedCount, ReportInbox."Output Type"::PDF);
    end;

    local procedure AssertReportInboxCountWithType(ExpectedCount: Integer; OutputType: Option)
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.SetRange("Report ID", GetStandardStatementReportID);
        ReportInbox.SetRange("User ID", UserId);
        ReportInbox.FindSet;
        repeat
            ReportInbox.TestField("Output Type", OutputType);
            Assert.IsTrue(ReportInbox."Report Output".HasValue, 'Output must be saved in Report Inbox');
        until ReportInbox.Next = 0;
        Assert.RecordCount(ReportInbox, ExpectedCount);
        ReportInbox.DeleteAll;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementOKRequestPageHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement."Start Date".SetValue(WorkDate);
        StandardStatement."End Date".SetValue(WorkDate);
        StandardStatement.ReportOutput.SetValue(LibraryVariableStorage.DequeueInteger);
        StandardStatement.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText);
        StandardStatement.PrintMissingAddresses.SetValue(LibraryVariableStorage.DequeueBoolean);
        StandardStatement.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure StartJobQueueNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(ConfirmStartJobQueueQst, Question, UnexpectedConfirmationErr);
        Reply := false;
    end;
}

