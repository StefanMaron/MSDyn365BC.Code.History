codeunit 136145 "Service Contracts II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service Contract] [Service]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be equal to ''%2''  in %3: %4=%5. Current value is ''%6''.', Comment = '%1=Field name,%2=Field value,%3=Table name,%4=Field name,%5=Field value,%6=Field value';
        NoOfLinesError: Label 'No. of lines in %1 must be %2.', Comment = '%1=Table name';
        NewServiceItemLineError: Label 'You cannot add a new Service Item Line because the service contract has expired. Renew the Expiration Date on the service contract.';
        LineNotCreatedErr: Label 'Service item line is not created.';
        CreateInvoiceMsg: Label 'Do you want to create an invoice for the period';
        CreateServiceOrderBatchErr: Label 'New Service Order must be created.';
        UnexpectedConfirmTextErr: Label 'Unexpected confirmation text.';
        CreateContrUsingTemplateQst: Label 'Do you want to create the contract using a contract template?';
        SignServContractQst: Label 'Do you want to sign service contract %1?', Comment = '%1 = Contract No.';
        NewLinesAddedConfirmQst: Label 'New lines have been added to this contract.\Would you like to continue?';
        CurrentSaveValuesId: Integer;
        NextPlannedServiceDateConfirmQst: Label 'The Next Planned Service Date field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?';

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,CreateContractServiceOrdersRequestPageHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceUpdationFromServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
        UnitPrice: Decimal;
    begin
        // Check updated Unit Price for posted Service Invoice Line created using CreateContractInvoices Batch Job.

        // 1. Setup: Create and Sign Service Contract, Create Service Order for Contract and Post it, Create Service Invoice for Contract and update Unit Price on Line.
        Initialize;
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)), 1);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        SignContract(ServiceContractHeader);
        RunCreateContractServiceOrders;
        UpdateAndPostServiceOrder(ServiceContractHeader."Contract No.");

        LibraryVariableStorage.Enqueue(CalcDate(ServiceContractHeader."Service Period", WorkDate));
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices;
        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        UnitPrice := ServiceLine."Unit Price";

        // 2. Exercise: Post Service Invoice using Page.
        ServiceInvoice.OpenEdit;
        ServiceInvoice.FILTER.SetFilter("No.", ServiceLine."Document No.");
        LibrarySales.DisableConfirmOnPostingDoc;
        ServiceInvoice.Post.Invoke;

        // 3. Verify: Verify Unit Price in Service Ledger Entries.
        VerifyServiceLedgerEntry(ServiceContractHeader."Contract No.", -UnitPrice);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnChangedNextPlannedServiceDateOnContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContract: TestPage "Service Contract";
    begin
        // Check Default Next Planned Service Date on Service Contract Line.

        // 1. Setup.
        Initialize;
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));

        // 2. Exercise: Open Service Contract Page because some code is written on Page.
        ServiceContract.OpenEdit;
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");

        // 3. Verify: Verify Next Planned Service Date.
        ServiceContract.ServContractLines."Next Planned Service Date".AssertEquals(WorkDate);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangedNextPlannedServiceDateOnContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContract: TestPage "Service Contract";
        FirstServiceDate: Date;
        ServicePeriod: DateFormula;
    begin
        // Check Next Planned Service Date and Service Period on Service Contract Line after updating them on Service Contract Header.

        // 1. Setup: Take Random First Service Date and Service Period. Update Service Contract Header.
        Initialize;
        FirstServiceDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'M>', WorkDate);
        Evaluate(ServicePeriod, '<' + Format(LibraryRandom.RandInt(10)) + 'M>');
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        ServiceContractHeader.Validate("Service Period", ServicePeriod);
        ServiceContractHeader.Validate("First Service Date", FirstServiceDate);
        ServiceContractHeader.Modify(true);

        // 2. Exercise: Open Service Contract Page. Using page because there is no data available on Service Contract Line Record when Line is not created.
        ServiceContract.OpenEdit;
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");

        // 3. Verify: Verify Service Period and Next Planned Service Date.
        ServiceContract.ServContractLines."Service Period".AssertEquals(ServicePeriod);
        ServiceContract.ServContractLines."Next Planned Service Date".AssertEquals(FirstServiceDate);
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractInvoiceWithDifferentPrepaidAndNonPrepaidAccounts()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // Check Moved From Prepaid Account field in Service Ledger Entries after posting Service Invoice with Service Contracts Account Group having different Accounts.

        // 1. Setup: Create and Sign Service Contract, Create Service Invoice and Post it.
        Initialize;
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        PostServiceInvoiceAndVerifyPrepaidAccount(ServiceContractAccountGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractInvoiceWithSamePrepaidAndNonPrepaidAccounts()
    begin
        // Check Moved From Prepaid Account field in Service Ledger Entries after posting Service Invoice with Service Contracts Account Group having similar Accounts.

        // 1. Setup: Create and Sign Service Contract, Create Service Invoice and Post it.
        Initialize;
        PostServiceInvoiceAndVerifyPrepaidAccount(CreateAndUpdateServiceContractAccountGroup);
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractCrMemoWithDifferentPrepaidAndNonPrepaidAccounts()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // Check Moved From Prepaid Account field in Service Ledger Entries after posting Service Credit Memo with Service Contracts Account Group having different Accounts.

        // Create Service Contract Account Group, Create and Sign Service Contract, Find Service Invoice and Post it, Create Service Credit Memo and Post.
        Initialize;
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        CreditMemoWithServiceContractAccountGroup(ServiceContractAccountGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContractCrMemoWithSamePrepaidAndNonPrepaidAccounts()
    begin
        // Check Moved From Prepaid Account field in Service Ledger Entries after posting Service Credit Memo with Service Contracts Account Group having similar Accounts.

        // Create and Sign Service Contract, Find Service Invoice and Post it, Create Service Credit Memo and Post.
        Initialize;
        CreditMemoWithServiceContractAccountGroup(CreateAndUpdateServiceContractAccountGroup);
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntryForServiceContractWithExpirationDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        OldWorkDate: Date;
        InvoiceDate: Date;
    begin
        // Test Amount on Service Ledger Entries for a Service Contract with Expiration Date and is created using the Service Contract Template on which Invoice Period is set to one Year.

        // 1. Setup: Create Service Contract Template, create and sign Service Contract.
        Initialize;
        OldWorkDate := WorkDate;
        InvoiceDate := SetNewWorkDate;

        CreateServiceContractTemplate(ServiceContractTemplate, true);
        LibraryVariableStorage.Enqueue(ServiceContractTemplate."No.");
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        CreateContractWithLine(
          ServiceContractHeader, ServiceContractTemplate."Serv. Contract Acc. Gr. Code", InvoiceDate,
          ServiceContractHeader."Service Period");
        SignContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(InvoiceDate);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");

        // 2. Exercise: Create Service Invoice using CreateContractInvoices Batch Job.
        RunCreateContractInvoices;

        // 3. Verify: Verify Amount in Service Ledger Entries.
        FindServiceLedgerEntries(ServiceLedgerEntry, ServiceContractHeader."Contract No.");
        Assert.AreEqual(12, ServiceLedgerEntry.Count, StrSubstNo(NoOfLinesError, ServiceLedgerEntry.TableCaption, 1));  // Service Ledger Entries must be 12 due to Yearly Invoice Period on Contract.
        VerifyServiceLedgerEntry(ServiceContractHeader."Contract No.", -Round(ServiceContractHeader."Annual Amount" / 12));  // Devide by 12 since the Invoice Period is Yearly.

        // 4. Tear Down: Reset the WORKDATE to original WORKDATE.
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemLineOnExpiredServiceContract()
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // Verify Program does not allow to add new Service Item line on Service Contract which is already expired.

        // 1. Setup: Create and sign Service Contract with Expiration Date. Open the Service Contract again.
        Initialize;
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        CreateContractWithLine(
          ServiceContractHeader, ServiceContractAccountGroup.Code, CalcDate('<CY>', WorkDate), ServiceContractHeader."Service Period");
        SignContract(ServiceContractHeader);
        ServiceContractHeader.Find;
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Find;
        SetExpirationDateLessThanLastInvoiceDate(ServiceContractHeader);

        // 2. Exercise: Add another Service Item line in the Service Contract.
        asserterror CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, 0D);  // Passing 0D for blank Contract Expiration Date.

        // 3. Verify: Verify error message which shows that Program does not allow to add new Service Item line on Service Contract which is already expired.
        Assert.ExpectedError(NewServiceItemLineError);
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AmountOnServiceInvoiceLineCreatedFromContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceLine: Record "Service Line";
        OldWorkDate: Date;
        InvoiceDate: Date;
        Amount: Decimal;
    begin
        // Test Amount on Service Invoice created from Service Contract with Invoice Period as Year and Prepaid False.

        // 1. Setup: Create Service Contract Template, create and sign Service Contract.
        Initialize;
        OldWorkDate := WorkDate;
        InvoiceDate := SetNewWorkDate;
        CreateServiceContractTemplate(ServiceContractTemplate, false);
        LibraryVariableStorage.Enqueue(ServiceContractTemplate."No.");
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        CreateContractWithLine(
          ServiceContractHeader, ServiceContractTemplate."Serv. Contract Acc. Gr. Code", InvoiceDate,
          ServiceContractHeader."Service Period");
        Amount := FindServiceContractLineAmount(ServiceContractHeader);
        SignContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(InvoiceDate);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");

        // 2. Exercise.
        RunCreateContractInvoices;

        // 3. Verify: Verify Amount in created Service Invoice.
        FindServiceLine(ServiceLine, ServiceContractHeader."Contract No.");
        ServiceLine.TestField(Amount, Amount);

        // 4. Tear Down: Reset the WORKDATE to original WORKDATE.
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AmountOnPostedServiceLineCreatedFromContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        OldWorkDate: Date;
        InvoiceDate: Date;
        Amount: Decimal;
    begin
        // Test Amount on Posted Service Invoice created from Service Contract with Invoice Period as Year and Prepaid False.

        // 1. Setup: Create and Sign Service Contract for Invoice Period Year, Create Contract Invoice from Service Contract.
        Initialize;
        OldWorkDate := WorkDate;
        InvoiceDate := SetNewWorkDate;
        CreateServiceContractTemplate(ServiceContractTemplate, false);
        LibraryVariableStorage.Enqueue(ServiceContractTemplate."No.");
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        CreateContractWithLine(
          ServiceContractHeader, ServiceContractTemplate."Serv. Contract Acc. Gr. Code", InvoiceDate,
          ServiceContractHeader."Service Period");
        Amount := FindServiceContractLineAmount(ServiceContractHeader);
        SignContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(InvoiceDate);
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        RunCreateContractInvoices;

        // 2. Exercise: Post the service Invoice that is created from Create Contract Invoice Batch Job.
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");

        // 3. Verify: Verify Amount in Posted Service Invoice.
        VerifyServiceInvoiceLineAmount(ServiceContractHeader."Contract No.", Amount);

        // 4. Tear Down: Reset the WORKDATE to original WORKDATE.
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure AddServiceContractLineWithEmptyContractHeaderExpiratoinDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractTemplate: Record "Service Contract Template";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Verify that service contract line can be added in case of empty expiration date

        // 1. Setup: Create Service Contract.
        Initialize;
        CreateServiceContractTemplate(ServiceContractTemplate, false);
        LibraryVariableStorage.Enqueue(''); // empty service contract template
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(false));
        ServiceContractHeader."Last Invoice Date" := WorkDate; // to cause expiration date analysis
        ServiceContractHeader.Modify();

        // 2. Exercise: add service contract line
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, 0D);

        // 3. Verify: line is created
        Assert.IsTrue(ServiceContractLine.Find, LineNotCreatedErr);
    end;

    [Test]
    [HandlerFunctions('ConditionalConfirmHandler,ServiceContractTemplateListHandler2,ConfirmCreateContractServiceOrdersRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateServiceOrderFromServiceContractWithTwoLines()
    var
        ServiceContractNo: Code[20];
        ServiceContractLine1No: Integer;
        ServiceContractLine2No: Integer;
        NextPlannedServiceDate1: Date;
        NextPlannedServiceDate2: Date;
    begin
        // [SCENARIO 360643] Create service order from second line of Service Contract after creating order from first line.
        CurrentSaveValuesId := REPORT::"Create Contract Service Orders"; // Ensure SaveValues is cleared by Initialize
        Initialize;
        // [GIVEN] Create Service Contract with two line are having different Next Planned Service Date.
        CreateServiceContractWithTwoLines(ServiceContractNo, ServiceContractLine1No, ServiceContractLine2No,
          NextPlannedServiceDate1, NextPlannedServiceDate2);
        // [GIVEN] Create Service Order from first line.
        RunCreateContractServiceOrdersWithDates(NextPlannedServiceDate1,
          LibraryRandom.RandDateFrom(NextPlannedServiceDate1, 10));
        // [WHEN] Create Service Order from second line.
        RunCreateContractServiceOrdersWithDates(NextPlannedServiceDate2,
          LibraryRandom.RandDateFrom(NextPlannedServiceDate2, 10));
        // [THEN] Must be created new Service order from second line of Service Contract.
        // [THEN] Field Response Date of Service Item Line must be correctly calculated.
        VerifyCreatedServiceOrder(ServiceContractNo, ServiceContractLine1No, ServiceContractLine2No);
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateContractInvWhenExpirationDateBeforeNextInvDate()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceItemNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Contract Expiration Date] [Create Service Invoice]
        // [SCENARIO 374724] Service Ledger Entry is not created for Contract Invoice Line when Expiration Date is before Next Invoice Date

        Initialize;
        // [GIVEN] Signed Service Contract with two lines ("Service Item No." = "A" and "B")
        LibraryVariableStorage.Enqueue(''); // empty service contract template
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), '<1M>', 2);
        SignContract(ServiceContractHeader);
        // [GIVEN] Expiration date in Service Contract Line with "Service Item No." = "A" is the day before Next Invoice Date = "X"
        ServiceItemNo :=
          ChangeExpirationDateOnContractLine(ServiceContractHeader, ServiceContractHeader."Next Invoice Date");

        // [WHEN] Run Create Contract Invoices batch job for Posting Date = "X"
        RunCreateContractInvoices;

        // [THEN] Service Ledger Entry for "Service Item No." = "A" and "Posting Date" = "X" is not created
        VerifyServiceLedgEntryDoesNotExist(
          ServiceContractHeader."Contract No.", ServiceItemNo, ServiceContractHeader."Next Invoice Date");
    end;

    [Test]
    [HandlerFunctions('SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateNonPreparedContractInvWhenExpirationDateBeforeNextInvPeriodStart()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceItemNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Contract Expiration Date]
        // [SCENARIO 375363] Service Ledger Entry is not created for Non Prepaid Contract Invoice Line when Expiration Date is before Next Invoice Period Start

        Initialize;
        // [GIVEN] Signed Non Prepaid Service Contract with two lines ("Service Item No." = "A" and "B")
        LibraryVariableStorage.Enqueue(CreateNonPrepaidServTemplateWithMonthInvPeriod);
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), '<1M>', 2);
        SignContract(ServiceContractHeader);

        // [GIVEN] Service Contract Line, where "Service Item No." = "A", "Expiration Date" = 23.01, "Next Invoice Period Start " = 24.01
        ServiceItemNo :=
          ChangeExpirationDateOnContractLine(ServiceContractHeader, ServiceContractHeader."Next Invoice Period Start");

        // [WHEN] Run Create Contract Invoices batch job for Posting Date = "X"
        RunCreateContractInvoices;

        // [THEN] Service Ledger Entry for "Service Item No." = "A" and "Posting Date" = 24.01 is not created
        VerifyServiceLedgEntryDoesNotExist(
          ServiceContractHeader."Contract No.", ServiceItemNo, ServiceContractHeader."Next Invoice Period Start");
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvoicePartialNonPrepaidServLine()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        SavedWorkDate: Date;
        InvoiceDate: Date;
    begin
        // [FEATURE] [Service Invoice] [Non-Prepaid Contract]
        // [SCENARIO 375877] Service Line created when invoice Non-Prepaid Contract with new Service Contract Line where "Starting Date" after "Next Invoice Period Start"
        // SCENARIO 376625 - Description line should show partial period

        // [GIVEN] Signed Non-Prepaid Service Contract with single line and Service Invoice for Period "X" - "Next Invoice Period Start"
        // [GIVEN] New Service Line where "Starting Date" after "Next Invoice Period Start" added after reopening Service Contract
        // [GIVEN] Locked Service Contract without additional service invoice and shifting "Next Invoice Period"
        Initialize;
        ScenarioWithNewServLineWhenStartingDateAfterNextInvPeriodStart(
          ServContractHeader, ServContractLine, SavedWorkDate, false, 0D, InvoiceDate);

        // [WHEN] Run Create Service Contract Invoices until the "Next Invoice Period End"
        RunCreateContractInvoices;

        // [THEN] Service Invoice created for new Service Line with non-zero amount
        VerifyServContractLineExistInServInvoice(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", false), InvoiceDate,
          StrSubstNo('%1 - %2', ServContractLine."Starting Date", ServContractHeader."Next Invoice Period End"));

        // Tear Down: Reset the WORKDATE to original WORKDATE.
        WorkDate := SavedWorkDate;
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvoicePartialPrepaidServLine()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
        SavedWorkDate: Date;
        InvoiceDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Service Invoice] [Prepaid Contract]
        // [SCENARIO 376109] New prepaid service contract line with "Starting Date" after "Next Invoice Period Start" should split by periods when posting
        // Based on SCENARIO 375878 - Service Line created when invoice Prepaid Contract with new Service Contract Line where "Starting Date" after "Next Invoice Period Start"

        // [GIVEN] Signed Prepaid Service Contract (Inv. Period = Year) with single line and Service Invoice for Period "X" with "Next Invoice Period Start"  = 01.01.15 (Annual amount = 100)
        // [GIVEN] New Service Line where "Starting Date" = 05.01.15 added after reopening Service Contract (Line amount for partial period = 95)
        // [GIVEN] Locked Service Contract without additional service invoice and shifting "Next Invoice Period"
        Initialize;
        ScenarioWithNewServLineWhenStartingDateAfterNextInvPeriodStart(
          ServContractHeader, ServContractLine, SavedWorkDate, true, 0D, InvoiceDate);

        ExpectedAmount :=
          Round(
            ServContractManagement.CalcContractLineAmount(
              ServContractLine."Line Amount", ServContractLine."Starting Date", ServContractHeader."Next Invoice Period End"));

        // [WHEN] Run Create Service Contract Invoices until the "Next Invoice Period End"
        RunCreateContractInvoices;

        // [THEN] 12 service lines created with total amount = 95
        VerifyServContractLineAmountSplitByPeriod(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true), InvoiceDate, 12, ExpectedAmount);

        // Tear Down: Reset the WORKDATE to original WORKDATE.
        WorkDate := SavedWorkDate;
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvoicePartialPrepaidServLineWithExpDateSamePeriod()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
        SavedWorkDate: Date;
        InvoiceDate: Date;
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Service Invoice] [Prepaid Contract] [Service Contract Expiration Date]
        // [SCENARIO 376109] New prepaid service contract line with "Starting Date" after "Next Invoice Period Start" and "Contract Expiration Date" in the same period should be posted as one partial period

        // [GIVEN] Signed Prepaid Service Contract (Inv. Period = Year) with single line and Service Invoice for Period "X" with "Next Invoice Period Start"  = 01.01.15 (Annual amount = 100)
        // [GIVEN] New Service Line where "Starting Date" = 05.01.15 and "Expiration Date" = 27.01.15 added after reopening Service Contract (Line amount for partial period = 5)
        // [GIVEN] Locked Service Contract without additional service invoice and shifting "Next Invoice Period"
        Initialize;
        ScenarioWithNewServLineWhenStartingDateAfterNextInvPeriodStart(
          ServContractHeader, ServContractLine, SavedWorkDate, true, CalcDate('<CM+1M-3D>', WorkDate), InvoiceDate);

        ExpectedAmount :=
          Round(
            ServContractManagement.CalcContractLineAmount(
              ServContractLine."Line Amount", ServContractLine."Starting Date", ServContractLine."Contract Expiration Date"));

        // [WHEN] Run Create Service Contract Invoices until the "Contract Expiration Date"
        RunCreateContractInvoices;

        // [THEN] 1 service line created with total amount = 5
        VerifyServContractLineAmountSplitByPeriod(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true), InvoiceDate, 1, ExpectedAmount);

        // Tear Down: Reset the WORKDATE to original WORKDATE.
        WorkDate := SavedWorkDate;
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceFromContractForCustomerPricesInclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Invoice] [Prices Incl. VAT]
        // [SCENARIO 377774] Service Invoice created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = TRUE
        Initialize;

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = TRUE. Period Amount = "A".
        // [WHEN] Create Service Invoice from Service Contract
        SignContractAndCreateServiceInvoice(ServiceContractHeader, true);

        // [THEN] Service Invoice has "Prices Incl. VAT" = FALSE, Amount = "A"
        VerifyServiceDocAmount(ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceFromContractForCustomerPricesExclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Invoice] [Prices Excl. VAT]
        // [SCENARIO 377774] Service Invoice created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = FALSE
        Initialize;

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = FALSE. Period Amount = "A".
        // [WHEN] Create Service Invoice from Service Contract
        SignContractAndCreateServiceInvoice(ServiceContractHeader, false);

        // [THEN] Created Service Invoice has "Prices Incl. VAT" = FALSE, Amount = "A"
        VerifyServiceDocAmount(ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceFromContractForCustomerPricesInclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [FEATURE] [Invoice] [Prices Incl. VAT]
        // [SCENARIO 377774] Posted Service Invoice created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = TRUE
        Initialize;

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = TRUE. Period Amount = "A".
        // [GIVEN] Service Invoice created from Service Contract
        // [WHEN] Post Service Invoice
        SignContractAndPostServiceInvoice(ServiceContractHeader, true);

        // [THEN] Posted Service Invoice has "Prices Incl. VAT" = FALSE, Amount = "A"
        // [THEN] Service Ledger Entry "Usage" Amount = "A"
        VerifyPostedServiceInvoiceAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceFromContractForCustomerPricesExclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [FEATURE] [Invoice] [Prices Excl. VAT]
        // [SCENARIO 377774] Posted Service Invoice created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = FALSE
        Initialize;

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = FALSE. Period Amount = "A".
        // [GIVEN] Service Invoice created from Service Contract
        // [WHEN] Post Service Invoice
        SignContractAndPostServiceInvoice(ServiceContractHeader, false);

        // [THEN] Posted Service Invoice has "Prices Incl. VAT" = FALSE, Amount = "A"
        // [THEN] Service Ledger Entry "Usage" Amount = "A"
        VerifyPostedServiceInvoiceAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoFromContractForCustomerPricesInclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Credit Memo] [Prices Incl. VAT]
        // [SCENARIO 377774] Service Credit Memo created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = TRUE
        Initialize;

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = TRUE. Period Amount = "A".
        // [GIVEN] Posted Service Invoice from Service Contract
        // [WHEN] Create Service Credit Memo from Service Contract
        SignContractAndPostServiceInvoice(ServiceContractHeader, true);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);

        // [THEN] Created Service Credit Memo has "Prices Incl. VAT" = FALSE, Amount = "A"
        VerifyServiceDocAmount(ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoFromContractForCustomerPricesExcllVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Credit Memo] [Prices Excl. VAT]
        // [SCENARIO 377774] Service Credit Memo created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = FALSE
        Initialize;

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = FALSE. Period Amount = "A".
        // [GIVEN] Posted Service Invoice from Service Contract
        // [WHEN] Create Service Credit Memo from Service Contract
        SignContractAndPostServiceInvoice(ServiceContractHeader, false);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);

        // [THEN] Created Service Credit Memo has "Prices Incl. VAT" = FALSE, Amount = "A"
        VerifyServiceDocAmount(ServiceHeader."Document Type"::"Credit Memo", ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoFromContractForCustomerPricesInclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Credit Memo] [Prices Incl. VAT]
        // [SCENARIO 377774] Posted Service Credit Memo created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = TRUE
        Initialize;

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = TRUE. Period Amount = "A".
        // [GIVEN] Posted Service Invoice from Service Contract
        // [GIVEN] Create Service Credit Memo from Service Contract
        // [WHEN] Post Service Credit Memo
        SignContractAndPostServiceInvoice(ServiceContractHeader, true);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Credit Memo has "Prices Incl. VAT" = FALSE, Amount = "A"
        // [THEN] Service Ledger Entry "Usage" Amount = -"A"
        VerifyPostedServiceCrMemoAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoFromContractForCustomerPricesExclVAT()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Credit Memo] [Prices Excl. VAT]
        // [SCENARIO 377774] Posted Service Credit Memo created from Service Contract has "Prices Incl. VAT" = FALSE for Customer with "Prices Incl. VAT" = FALSE
        Initialize;

        // [GIVEN] Service Contract for Customer with "Prices Incl. VAT" = FALSE. Period Amount = "A".
        // [GIVEN] Posted Service Invoice from Service Contract
        // [GIVEN] Create Service Credit Memo from Service Contract
        // [WHEN] Post Service Credit Memo
        SignContractAndPostServiceInvoice(ServiceContractHeader, false);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Credit Memo has "Prices Incl. VAT" = FALSE, Amount = "A"
        // [THEN] Service Ledger Entry "Usage" Amount = -"A"
        VerifyPostedServiceCrMemoAmount(ServiceContractHeader."Contract No.");
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MultipleServLinesGeneratedWhenSignAlreadySignedContractWithNewLine()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
        ExpectedAmount: Decimal;
        SavedWorkDate: Date;
    begin
        // [SCENARIO 379870] New prepaid service contract line with "Starting Date" after "Next Invoice Period Start" should split by periods when sign contract

        Initialize;
        // [GIVEN] Signed Service Contract with single line. Invoice Period = Year. Starting Year = 2017
        // [GIVEN] Posted Service Invoice for 2017 year. Next Invoice Period is 2018 year
        SavedWorkDate := WorkDate;
        WorkDate := CalcDate('<-CM>', WorkDate);
        ScenarioWithSignedAndInvoicedServiceContract(ServContractHeader);

        // [GIVEN] New Service Contract Line added with Starting Date = 01.01.2017, Amount = 100
        AddNewLineInServiceContractWithSpecificStartingDate(ServContractHeader, ServContractLine, 0D);
        ExpectedAmount :=
          Round(
            ServContractManagement.CalcContractLineAmount(
              ServContractLine."Line Amount", ServContractLine."Starting Date", ServContractHeader."Last Invoice Period End"));

        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(NewLinesAddedConfirmQst);
        LibraryVariableStorage.Enqueue(CreateInvoiceMsg);

        // [WHEN] Sign Service Contract with new line added
        SignContract(ServContractHeader);

        // [THEN] Posted Service Invoice created with 12 lines (one line = one month) and Total Amount = 100
        VerifyServContractLineAmountSplitByPeriod(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true), WorkDate, 12, ExpectedAmount);

        // Tear down
        WorkDate := SavedWorkDate;
    end;

    [Test]
    [HandlerFunctions('MultipleDialogsConfirmHandler,SelectServiceContractTemplateListHandler,CreateContractInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoRoundingVarianceOnMultipleServiceInvoiceWithFCYPrepaidContract()
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        SavedWorkDate: Date;
        CustomExchRate: Decimal;
    begin
        // [FEATURE] [FCY] [Rounding]
        // [SCENARIO 379879] Total amount is correct without rounding variance in Service Invoice with multiple lines for Prepaid Service Contract

        Initialize;
        SavedWorkDate := WorkDate;

        // [GIVEN] Prepaid Service Contract with FCY. Exchange Rate equal 1/7.95
        CustomExchRate := 1 / 7.95;
        CreateServiceContractHeaderWithCurrency(
          ServContractHeader, LibrarySales.CreateCustomerNo,
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, CustomExchRate, CustomExchRate));

        // [GIVEN] Service Contract Line has amount 39750
        CreateContractLineWithSpecficiAmount(ServContractLine, ServContractHeader, 39750);
        UpdateServContractHeader(ServContractHeader);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(CreateInvoiceMsg);
        SignContract(ServContractHeader);

        WorkDate := ServContractHeader."Next Invoice Period Start";
        LibraryVariableStorage.Enqueue(ServContractHeader."Next Invoice Period Start");
        LibraryVariableStorage.Enqueue(ServContractHeader."Contract No.");

        // [WHEN] Create Service Invoice
        RunCreateContractInvoices;

        // [THEN] Total amount of multiple Service Lines is 5000 (39750 * 1/7.95)
        VerifyServContractLineAmountSplitByPeriod(
          ServContractHeader."Contract No.", ServContractLine."Service Item No.",
          GetServContractGLAcc(ServContractHeader."Serv. Contract Acc. Gr. Code", true), WorkDate, 12, 5000);

        // Tear down
        WorkDate := SavedWorkDate;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,CreateContractInvoicesRequestPageHandler,MessageHandler,ServiceContractTemplateListHandler2')]
    [Scope('OnPrem')]
    procedure ServContractLineWithZeroAmountAndLineDiscCopiesToServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        SavedWorkDate: Date;
        ServiceItemNo: array[3] of Code[20];
    begin
        // [SCENARIO 220762] Posted Service Invoice must contains correct amounts of discount after creating from Service Contract if Service Contract Line contains 100% discount
        Initialize;
        SavedWorkDate := WorkDate;

        // [GIVEN] Signed Service Contract with 3 lines:
        // [GIVEN] The first line - "Discount %" = 100
        // [GIVEN] The second line - "Discount %" = 50
        // [GIVEN] The third line - "Discount %" = 0
        CreateServiceContractWithLinesWithDiscount(ServiceContractHeader, ServiceItemNo);
        SignContract(ServiceContractHeader);
        WorkDate := ServiceContractHeader."Next Invoice Period Start";
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Next Invoice Period Start");
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        ServiceLedgerEntry.DeleteAll();

        // [GIVEN] Create Service Invoice from Service Contract
        RunCreateContractInvoices;

        // [WHEN] Post Service Invoice
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");

        // [THEN] Posted Service Invoice contains lines:
        // [THEN] The first line - "Discount %" = 100
        VerifyPostedServiceInvoiceDiscount(ServiceContractHeader."Customer No.", ServiceItemNo[1], 100);

        // [THEN] The second line - "Discount %" = 50
        VerifyPostedServiceInvoiceDiscount(ServiceContractHeader."Customer No.", ServiceItemNo[2], 50);

        // [THEN] The third line - "Discount %" = 0
        VerifyPostedServiceInvoiceDiscount(ServiceContractHeader."Customer No.", ServiceItemNo[3], 0);

        // Teardown
        WorkDate := SavedWorkDate;
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConditionalNextPlannedDateConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractEmptyNextPlannedServiceDateConfirmationFalse()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO 303847] Answering "No" to confirmation dialog about empty "Next Planned Service Date" cancels signing the contract
        Initialize;

        // [GIVEN] Created Service Contract with one Line
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)), 1);
        Commit();

        // [GIVEN] "Next Planned Service Date" empty on the Service Contract Line
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceContractLine.Validate("Next Planned Service Date", 0D);
        ServiceContractLine.Modify(true);

        // [WHEN] Sign contract and answer "No" to empty "Next Planned Service Date" confirmation dialog
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        SignContract(ServiceContractHeader);

        // [THEN] No messages are shown
        // [THEN] Service contract is not signed
        VerifyServiceContractStatus(
          ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.", ServiceContractHeader.Status::" ");
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractEmptyNextPlannedServiceDateConfirmationTrue()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO 303847] Answering "Yes" to confirmation dialog about empty "Next Planned Service Date" allows signing the contract
        Initialize;

        // [GIVEN] Created Service Contract with one Line
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false), StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)), 1);
        Commit();

        // [GIVEN] "Next Planned Service Date" empty on the Service Contract Line
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceContractLine.Validate("Next Planned Service Date", 0D);
        ServiceContractLine.Modify(true);

        // [WHEN] Sign contract and answer "Yes" to empty "Next Planned Service Date" confirmation dialog
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        SignContract(ServiceContractHeader);

        // [THEN] Message "Service Invoice SCI0000022 was created."
        // [THEN] Service contract is signed
        VerifyServiceContractStatus(
          ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.", ServiceContractHeader.Status::Signed);
    end;

    [Test]
    [HandlerFunctions('DoNotCreateContrUsingTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateServHeaderWithBillToSellToVATCalcSetToBillToPayToNo()
    var
        Customer: array[2] of Record Customer;
        GLSetup: Record "General Ledger Setup";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 326175] When creating Service Invoice from Service Contract fields affecting VAT is taken from Bill-to Customer if "Bill-to/Sell-to VAT Calc." is set to "Bill-to/Pay-to No.".
        Initialize;

        LibraryERM.SetBillToSellToVATCalc(GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        CreateCustomerWithGenBusPostingGroup(Customer[1]);
        CreateCustomerWithGenBusPostingGroup(Customer[2]);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer[1]."No.");
        ServiceContractHeader.Validate("Bill-to Customer No.", Customer[2]."No.");
        ServiceContractHeader.Modify(true);

        ServiceHeader.Get(
          ServiceHeader."Document Type"::Invoice, ServContractManagement.CreateServHeader(ServiceContractHeader, WorkDate, true));

        Assert.AreEqual(Customer[2]."VAT Bus. Posting Group", ServiceHeader."VAT Bus. Posting Group", '');
        Assert.AreEqual(Customer[2]."VAT Registration No.", ServiceHeader."VAT Registration No.", '');
        Assert.AreEqual(Customer[2]."Country/Region Code", ServiceHeader."VAT Country/Region Code", '');
        Assert.AreEqual(Customer[2]."Gen. Bus. Posting Group", ServiceHeader."Gen. Bus. Posting Group", '');
    end;

    [Test]
    [HandlerFunctions('DoNotCreateContrUsingTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateServHeaderWithBillToSellToVATCalcSetToSellToBuyFromNo()
    var
        Customer: array[2] of Record Customer;
        GLSetup: Record "General Ledger Setup";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 326175] When creating Service Invoice from Service Contract fields affecting VAT are taken from Sell-to Customer if "Bill-to/Sell-to VAT Calc." is set to "Sell-to/Buy-from No.".
        Initialize;

        LibraryERM.SetBillToSellToVATCalc(GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        CreateCustomerWithGenBusPostingGroup(Customer[1]);
        CreateCustomerWithGenBusPostingGroup(Customer[2]);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer[1]."No.");
        ServiceContractHeader.Validate("Bill-to Customer No.", Customer[2]."No.");
        ServiceContractHeader.Modify(true);

        ServiceHeader.Get(
          ServiceHeader."Document Type"::Invoice, ServContractManagement.CreateServHeader(ServiceContractHeader, WorkDate, true));

        Assert.AreEqual(Customer[1]."VAT Bus. Posting Group", ServiceHeader."VAT Bus. Posting Group", '');
        Assert.AreEqual(Customer[1]."VAT Registration No.", ServiceHeader."VAT Registration No.", '');
        Assert.AreEqual(Customer[1]."Country/Region Code", ServiceHeader."VAT Country/Region Code", '');
        Assert.AreEqual(Customer[1]."Gen. Bus. Posting Group", ServiceHeader."Gen. Bus. Posting Group", '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Contracts II");
        LibraryVariableStorage.Clear;
        DeleteObjectOptionsIfNeeded;
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Contracts II");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        // Setup demonstration data
        LibraryService.SetupServiceMgtNoSeries;
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Contracts II");
    end;

    local procedure CreateAndUpdateServiceContractAccountGroup(): Code[10]
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        ServiceContractAccountGroup.Validate("Prepaid Contract Acc.", ServiceContractAccountGroup."Non-Prepaid Contract Acc.");  // To take similar Account as Non-Prepaid Contract Acc.
        ServiceContractAccountGroup.Modify(true);
        exit(ServiceContractAccountGroup.Code);
    end;

    local procedure CreateContractWithLine(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractAccountGroupCode: Code[10]; ContractExpirationDate: Date; PriceUpdatePeriod: DateFormula)
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ContractExpirationDate);
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroupCode);
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate);
        ServiceContractHeader.Validate("Price Update Period", PriceUpdatePeriod);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; ServicePeriod: Text; NoOfLines: Integer)
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        i: Integer;
    begin
        CreateServiceContractHeader(ServiceContractHeader, CustomerNo, ServicePeriod);
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        for i := 1 to NoOfLines do
            CreateContractWithLine(
              ServiceContractHeader, ServiceContractAccountGroup.Code, 0D, ServiceContractHeader."Service Period");  // Passing 0D for blank Contract Expiration Date.
    end;

    local procedure CreateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; ServicePeriod: Text)
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        Evaluate(ServiceContractHeader."Service Period", ServicePeriod);
    end;

    local procedure CreateServiceContractHeaderWithCurrency(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        // Pass confirmation dialog message to ConfirmHandler and Template No. in SelectServiceContractTemplateListHandler
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplate(ServiceContractTemplate, true));

        CreateServiceContractHeader(ServiceContractHeader, CustomerNo, '<1Y>');
        ServiceContractHeader.Validate("Currency Code", CurrencyCode);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header"; ContractExpirationDate: Date)
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", 10000 * LibraryRandom.RandIntInRange(10, 100));  // Use Random because value is not important.
        ServiceContractLine.Validate("Line Value", 10000 * LibraryRandom.RandIntInRange(10, 100));  // Use Random because value is not important.
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Validate("Contract Expiration Date", ContractExpirationDate);
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceContractLineWithDiscount(var ServiceItemNo: Code[20]; ServiceContractHeader: Record "Service Contract Header"; LineDiscount: Decimal)
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceContractHeader."Expiration Date");
        ServiceContractLine.Validate("Line Discount %", LineDiscount);
        ServiceContractLine.Modify(true);
        ServiceItemNo := ServiceContractLine."Service Item No.";
    end;

    local procedure CreateServiceContractTemplate(var ServiceContractTemplate: Record "Service Contract Template"; Prepaid: Boolean): Code[20]
    var
        DefaultServicePeriod: DateFormula;
    begin
        Evaluate(DefaultServicePeriod, '<1M>');  // Use 1 for monthly Service Period.
        LibraryService.CreateServiceContractTemplate(ServiceContractTemplate, DefaultServicePeriod);
        ServiceContractTemplate.Validate("Invoice Period", ServiceContractTemplate."Invoice Period"::Year);
        ServiceContractTemplate.Validate(Prepaid, Prepaid);
        ServiceContractTemplate.Validate("Combine Invoices", true);
        ServiceContractTemplate.Modify(true);
        exit(ServiceContractTemplate."No.");
    end;

    local procedure CreateContractLineWithSpecficiAmount(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header"; LineValue: Decimal)
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LineValue);
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceContractWithLinesWithDiscount(var ServiceContractHeader: Record "Service Contract Header"; var ServiceItemNo: array[3] of Code[20])
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo);
        CreateServiceContractLineWithDiscount(ServiceItemNo[1], ServiceContractHeader, 100);
        CreateServiceContractLineWithDiscount(ServiceItemNo[2], ServiceContractHeader, 50);
        CreateServiceContractLineWithDiscount(ServiceItemNo[3], ServiceContractHeader, 0);
        UpdateAnnualAmountInServiceContract(ServiceContractHeader);
        ServiceContractHeader.Validate("Starting Date", WorkDate);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceLineForServiceOrder(var ServiceHeader: Record "Service Header"; ContractNo: Code[20])
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.FindResource(Resource);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ContractNo);
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst;

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Take Random Quantity.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Take Random Unit Price.
        ServiceLine.Modify(true);
    end;

    local procedure CreditMemoWithServiceContractAccountGroup(ServiceContractAccountGroupCode: Code[10])
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
    begin
        // 1. Setup: Create and Sign Service Contract and Post Service Invoice created after signing the Contract, Create Credit Memo from Contract.
        SignContractAndPostServiceInvoiceWithAccGrCode(ServiceContractHeader, false, ServiceContractAccountGroupCode);
        CreateServiceCreditMemo(ServiceHeader, ServiceContractHeader);

        // 2. Exercise: Post Service Credit Memo created from Service Contract.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify that Moved From Prepaid Account Field is carrying TRUE.
        VerifyServiceLedgerEntries(ServiceContractHeader."Contract No.");
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceHeader.Get(
          ServiceHeader."Document Type"::"Credit Memo",
          ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine, false)); // Passing False to avoid Deletion of Service Contract Line.
    end;

    local procedure CreateNonPrepaidServTemplateWithMonthInvPeriod(): Code[20]
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        CreateServiceContractTemplate(ServiceContractTemplate, false);
        ServiceContractTemplate.Validate("Invoice Period", ServiceContractTemplate."Invoice Period"::Month);
        ServiceContractTemplate.Modify(true);
        exit(ServiceContractTemplate."No.");
    end;

    local procedure FindAndPostServiceInvoice(ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ContractNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateCustomer(NewPricesInclVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate("Prices Including VAT", NewPricesInclVAT);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateCustomerWithGenBusPostingGroup(var Customer: Record Customer)
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure FilterServiceLedgEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractNo: Code[20])
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractNo);
        ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::"Service Contract");
        ServiceLedgerEntry.SetRange("No.", ServiceContractNo);
    end;

    local procedure FindServiceLedgerEntries(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractNo: Code[20])
    begin
        FilterServiceLedgEntry(ServiceLedgerEntry, ServiceContractNo);
        ServiceLedgerEntry.FindSet;
    end;

    local procedure FindServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst;
    end;

    local procedure FindServiceContractLineAmount(ServiceContractHeader: Record "Service Contract Header"): Decimal
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        exit(ServiceContractLine."Line Amount");
    end;

    local procedure FindServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; ContractType: Option; ContractNo: Code[20])
    begin
        ServiceContractHeader.SetRange("Contract Type", ContractType);
        ServiceContractHeader.SetRange("Contract No.", ContractNo);
        ServiceContractHeader.FindLast;
    end;

    local procedure FindServiceDocumentHeader(var ServiceHeader: Record "Service Header"; DocumentType: Option; ContractNo: Code[20])
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindLast;
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ContractNo);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetFilter(Type, '<>''''');
        ServiceLine.FindFirst;
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; ContractNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Contract No.", ContractNo);
        ServiceInvoiceHeader.FindFirst;
    end;

    local procedure FindServiceCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ContractNo: Code[20])
    begin
        ServiceCrMemoHeader.SetRange("Contract No.", ContractNo);
        ServiceCrMemoHeader.FindFirst;
    end;

    local procedure PostServiceInvoiceAndVerifyPrepaidAccount(ServiceContractAccountGroupCode: Code[10])
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // 2. Exercise: Create and Sign Contract and Post Service Invoice created after signing Service Contract.
        SignContractAndPostServiceInvoiceWithAccGrCode(ServiceContractHeader, false, ServiceContractAccountGroupCode);

        // 3. Verify: Verify that Moved From Prepaid Account Field is carrying TRUE.
        VerifyServiceLedgerEntries(ServiceContractHeader."Contract No.");
    end;

    local procedure RunCreateContractInvoices()
    var
        CreateContractInvoices: Report "Create Contract Invoices";
    begin
        Commit();  // Required to avoid Test Failure.
        Clear(CreateContractInvoices);
        CreateContractInvoices.Run;
    end;

    local procedure RunCreateContractServiceOrders()
    var
        CreateContractServiceOrders: Report "Create Contract Service Orders";
    begin
        Commit();  // Required to avoid Test Failure.
        Clear(CreateContractServiceOrders);
        CreateContractServiceOrders.Run;
    end;

    local procedure RunCreateContractServiceOrdersWithDates(StartDate: Date; EndDate: Date)
    var
        CreateContractServiceOrders: Report "Create Contract Service Orders";
        CreateServOrders: Option "Create Service Order","Print Only";
    begin
        Commit();  // Required to avoid Test Failure.
        Clear(CreateContractServiceOrders);
        CreateContractServiceOrders.InitializeRequest(StartDate, EndDate, CreateServOrders::"Create Service Order");
        CreateContractServiceOrders.Run;
    end;

    local procedure SetNewWorkDate() NewDate: Date
    begin
        WorkDate := CalcDate('<-CY>', WorkDate);  // Set WORKDATE to the First Date of Current Year.
        NewDate := CalcDate('<CY>', WorkDate);  // Assign Last Date of Current Year in global variable.
    end;

    local procedure SignContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure SignContractAndCreateServiceInvoice(var ServiceContractHeader: Record "Service Contract Header"; CustomerPricesInclVAT: Boolean)
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        SignContractAndCreateServiceInvoiceWithAccGrCode(ServiceContractHeader, CustomerPricesInclVAT, ServiceContractAccountGroup.Code);
    end;

    local procedure SignContractAndCreateServiceInvoiceWithAccGrCode(var ServiceContractHeader: Record "Service Contract Header"; CustomerPricesInclVAT: Boolean; ServiceContractAccountGroupCode: Code[10])
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CreateCustomer(CustomerPricesInclVAT));
        Evaluate(ServiceContractHeader."Service Period", StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));
        CreateContractWithLine(ServiceContractHeader, ServiceContractAccountGroupCode, WorkDate, ServiceContractHeader."Service Period");
        SignContract(ServiceContractHeader);
    end;

    local procedure SignContractAndPostServiceInvoice(var ServiceContractHeader: Record "Service Contract Header"; CustomerPricesInclVAT: Boolean)
    begin
        SignContractAndCreateServiceInvoice(ServiceContractHeader, CustomerPricesInclVAT);
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");
    end;

    local procedure SignContractAndPostServiceInvoiceWithAccGrCode(var ServiceContractHeader: Record "Service Contract Header"; CustomerPricesInclVAT: Boolean; ServiceContractAccountGroupCode: Code[10])
    begin
        SignContractAndCreateServiceInvoiceWithAccGrCode(
          ServiceContractHeader, CustomerPricesInclVAT, ServiceContractAccountGroupCode);
        FindAndPostServiceInvoice(ServiceContractHeader."Contract No.");
    end;

    local procedure UpdateAndPostServiceOrder(ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceLineForServiceOrder(ServiceHeader, ContractNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure UpdateTemplateNoOnServiceContract(var ServiceContractTemplateList: TestPage "Service Contract Template List"; No: Text)
    begin
        ServiceContractTemplateList.FILTER.SetFilter("No.", No);
        ServiceContractTemplateList.OK.Invoke;
    end;

    local procedure UpdateAnnualAmountInServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        with ServiceContractHeader do begin
            CalcFields("Calcd. Annual Amount");
            Validate("Annual Amount", "Calcd. Annual Amount");
            Modify(true);
        end;
    end;

    local procedure UpdateServContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        UpdateAnnualAmountInServiceContract(ServiceContractHeader);
        ServiceContractHeader.Validate("Starting Date", WorkDate);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractWithTwoLines(var ServiceContractNo: Code[20]; var ServiceContractLine1No: Integer; var ServiceContractLine2No: Integer; var NextPlannedServiceDate1: Date; var NextPlannedServiceDate2: Date)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServicePeriod: DateFormula;
    begin
        GetDatesForServiceContractsLine(NextPlannedServiceDate1, NextPlannedServiceDate2);
        Evaluate(ServicePeriod, '<' + Format(LibraryRandom.RandInt(10)) + 'M>');
        with ServiceContractHeader do begin
            LibraryService.CreateServiceContractHeader(ServiceContractHeader, "Contract Type"::Contract, CreateCustomer(false));
            Validate("Service Period", ServicePeriod);
            Modify(true);
            ServiceContractLine1No :=
              CreateServiceContractLineWithNextPlannedServiceDate(ServiceContractHeader, NextPlannedServiceDate1);
            ServiceContractLine2No :=
              CreateServiceContractLineWithNextPlannedServiceDate(ServiceContractHeader, NextPlannedServiceDate2);
            SignContract(ServiceContractHeader);
            ServiceContractNo := "Contract No.";
        end;
    end;

    local procedure CreateServiceContractLineWithNextPlannedServiceDate(ServiceContractHeader: Record "Service Contract Header"; NextPlannedServiceDate: Date): Integer
    var
        ServiceItem: Record "Service Item";
        ServiceContractLine: Record "Service Contract Line";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        with ServiceContractLine do begin
            Validate("Next Planned Service Date", NextPlannedServiceDate);
            Validate("Line Value", LibraryRandom.RandDec(100, 2));
            Validate("Line Amount", "Line Value");
            Validate("Service Period", ServiceContractHeader."Service Period");
            Modify(true);
        end;
        UpdateAnnualAmountInServiceContract(ServiceContractHeader);
        exit(ServiceContractLine."Line No.");
    end;

    local procedure AddNewLineInServiceContractWithSpecificStartingDate(var ServContractHeader: Record "Service Contract Header"; var ServContractLine: Record "Service Contract Line"; ContractExpirationDate: Date)
    var
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        ServContractHeader.Find;
        LockOpenServContract.OpenServContract(ServContractHeader);
        CreateServiceContractLine(ServContractLine, ServContractHeader, 0D);
        ServContractLine.Validate("Starting Date", WorkDate);
        ServContractLine.Validate("Next Planned Service Date", ServContractLine."Starting Date");
        ServContractLine.Validate("Contract Expiration Date", ContractExpirationDate);
        ServContractLine.Modify(true);
        ServContractHeader.Find;
        UpdateAnnualAmountInServiceContract(ServContractHeader);
    end;

    local procedure ScenarioWithNewServLineWhenStartingDateAfterNextInvPeriodStart(var ServContractHeader: Record "Service Contract Header"; var ServContractLine: Record "Service Contract Line"; var SavedWorkDate: Date; Prepaid: Boolean; ContractExpirationDate: Date; var InvoiceDate: Date)
    var
        ServiceContractTemplate: Record "Service Contract Template";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        SavedWorkDate := WorkDate;
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        LibraryVariableStorage.Enqueue(
          CreateServiceContractTemplate(ServiceContractTemplate, Prepaid));

        CreateServiceContract(ServContractHeader, CreateCustomer(false), '<2Y>', 2);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(CreateInvoiceMsg);
        SignContract(ServContractHeader);

        WorkDate := ServContractHeader."Next Invoice Period Start" + 1;
        AddNewLineInServiceContractWithSpecificStartingDate(ServContractHeader, ServContractLine, ContractExpirationDate);
        LibraryVariableStorage.Enqueue(NewLinesAddedConfirmQst);

        LockOpenServContract.LockServContract(ServContractHeader);
        WorkDate := ServContractHeader."Next Invoice Period End";
        InvoiceDate := WorkDate;
        LibraryVariableStorage.Enqueue(InvoiceDate);
        LibraryVariableStorage.Enqueue(ServContractHeader."Contract No.");
    end;

    local procedure ScenarioWithSignedAndInvoicedServiceContract(var ServContractHeader: Record "Service Contract Header")
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        LibraryVariableStorage.Enqueue(CreateServiceContractTemplate(ServiceContractTemplate, true));
        CreateServiceContract(ServContractHeader, CreateCustomer(false), '<2Y>', 2);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServContractHeader."Contract No."));
        SignContract(ServContractHeader);
        ServContractHeader.Find;
        WorkDate := ServContractHeader."Next Invoice Period Start" + 1;
        LibraryVariableStorage.Enqueue(ServContractHeader."Next Invoice Period Start");
        LibraryVariableStorage.Enqueue(ServContractHeader."Contract No.");
        RunCreateContractInvoices;
    end;

    local procedure FindServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceContractLineNo: Integer; ServiceContractNo: Code[20])
    begin
        with ServiceItemLine do begin
            SetRange("Contract Line No.", ServiceContractLineNo);
            SetRange("Contract No.", ServiceContractNo);
            FindFirst;
        end;
    end;

    local procedure FilterServiceLine(var ServiceLine: Record "Service Line"; ContractNo: Code[20]; GLAccNo: Code[20]; PostingDate: Date)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Posting Date", PostingDate);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ContractNo);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.SetRange("No.", GLAccNo);
    end;

    local procedure SetExpirationDateLessThanLastInvoiceDate(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader."Expiration Date" := ServiceContractHeader."Last Invoice Date" - 1;
        ServiceContractHeader.Modify(true);
    end;

    local procedure GetDatesForServiceContractsLine(var NextPlannedServiceDate1: Date; var NextPlannedServiceDate2: Date)
    begin
        NextPlannedServiceDate1 := CalcDate('<+' + Format(LibraryRandom.RandInt(3)) + 'M>', WorkDate);
        NextPlannedServiceDate2 := CalcDate('<+' + Format(LibraryRandom.RandInt(3)) + 'M>', NextPlannedServiceDate1);
    end;

    local procedure GetServContractGLAcc(ServContractAccountGroupCode: Code[10]; Prepaid: Boolean): Code[20]
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        ServiceContractAccountGroup.Get(ServContractAccountGroupCode);
        if Prepaid then
            exit(ServiceContractAccountGroup."Prepaid Contract Acc.");
        exit(ServiceContractAccountGroup."Non-Prepaid Contract Acc.");
    end;

    local procedure GetServiceLedgerEntryPosAmount(ContractNo: Code[20]; EntryType: Option): Decimal
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        with ServiceLedgerEntry do begin
            SetRange("Service Contract No.", ContractNo);
            SetRange("Entry Type", EntryType);
            SetFilter(Amount, '>%1', 0);
            FindFirst;
            exit(Amount);
        end;
    end;

    local procedure GetServiceLedgerEntryNegAmount(ContractNo: Code[20]; EntryType: Option): Decimal
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        with ServiceLedgerEntry do begin
            SetRange("Service Contract No.", ContractNo);
            SetRange("Entry Type", EntryType);
            SetFilter(Amount, '<%1', 0);
            FindFirst;
            exit(Amount);
        end;
    end;

    local procedure GetServiceDocAmount(ServiceHeader: Record "Service Header"): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        with ServiceLine do begin
            SetRange("Document Type", ServiceHeader."Document Type");
            SetRange("Document No.", ServiceHeader."No.");
            CalcSums(Amount);
            exit(Amount);
        end;
    end;

    local procedure GetPostedServiceInvoiceAmount(ContractNo: Code[20]): Decimal
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ContractNo);
        with ServiceInvoiceLine do begin
            SetRange("Document No.", ServiceInvoiceHeader."No.");
            CalcSums(Amount);
            exit(Amount);
        end;
    end;

    local procedure GetPostedServiceCrMemoAmount(ContractNo: Code[20]): Decimal
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        FindServiceCrMemoHeader(ServiceCrMemoHeader, ContractNo);
        with ServiceCrMemoLine do begin
            SetRange("Document No.", ServiceCrMemoHeader."No.");
            CalcSums(Amount);
            exit(Amount);
        end;
    end;

    local procedure ChangeExpirationDateOnContractLine(var ServiceContractHeader: Record "Service Contract Header"; NextInvDate: Date): Code[20]
    var
        ServiceContractLine: Record "Service Contract Line";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        ServiceContractHeader.Find;
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        FindServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ServiceContractLine.Validate("Contract Expiration Date", NextInvDate - 1);
        ServiceContractLine.Modify(true);
        ServiceContractHeader.Find;
        LockOpenServContract.LockServContract(ServiceContractHeader);
        LibraryVariableStorage.Enqueue(CalcDate(ServiceContractHeader."Service Period", NextInvDate));
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        exit(ServiceContractLine."Service Item No.");
    end;

    local procedure VerifyPostedServiceInvoiceDiscount(CustomerNo: Code[20]; ServiceItemNo: Code[20]; DiscountPct: Decimal)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceLine.SetRange("Service Item No.", ServiceItemNo);
        ServiceInvoiceLine.FindFirst;
        ServiceInvoiceLine.TestField("Line Discount %", DiscountPct);
    end;

    local procedure VerifyServiceInvoiceLineAmount(ContractNo: Code[20]; Amount: Decimal)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Contract No.", ContractNo);
        ServiceInvoiceLine.FindFirst;
        ServiceInvoiceLine.TestField(Amount, Amount);
    end;

    local procedure VerifyServiceLedgerEntries(ServiceContractNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractNo);
        ServiceLedgerEntry.FindSet;
        repeat
            ServiceLedgerEntry.TestField("Moved from Prepaid Acc.", true);
        until ServiceLedgerEntry.Next = 0;
    end;

    local procedure VerifyServiceLedgerEntry(ServiceContractNo: Code[20]; AmountLCY: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        LibraryERM: Codeunit "Library - ERM";
    begin
        FindServiceLedgerEntries(ServiceLedgerEntry, ServiceContractNo);
        repeat
            Assert.AreNearlyEqual(
              AmountLCY, ServiceLedgerEntry."Amount (LCY)", LibraryERM.GetAmountRoundingPrecision,
              StrSubstNo(
                AmountError, ServiceLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, ServiceLedgerEntry.TableCaption,
                ServiceLedgerEntry.FieldCaption("Entry No."), ServiceLedgerEntry."Entry No.", ServiceLedgerEntry."Amount (LCY)"));
        until ServiceLedgerEntry.Next = 0;
    end;

    local procedure VerifyServiceLedgEntryDoesNotExist(ServiceContractNo: Code[20]; ServiceItemNo: Code[20]; PostingDate: Date)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FilterServiceLedgEntry(ServiceLedgerEntry, ServiceContractNo);
        ServiceLedgerEntry.SetRange("Service Item No. (Serviced)", ServiceItemNo);
        ServiceLedgerEntry.SetFilter("Posting Date", '%1..', PostingDate);
        Assert.RecordIsEmpty(ServiceLedgerEntry);
    end;

    local procedure VerifyCreatedServiceOrder(ServiceContractNo: Code[20]; ServiceContractLine1No: Integer; ServiceContractLine2No: Integer)
    var
        ServiceItemLine1: Record "Service Item Line";
        ServiceItemLine2: Record "Service Item Line";
    begin
        FindServiceItemLine(ServiceItemLine1, ServiceContractLine1No, ServiceContractNo);
        FindServiceItemLine(ServiceItemLine2, ServiceContractLine2No, ServiceContractNo);
        Assert.AreNotEqual(ServiceItemLine1."Document No.", ServiceItemLine2."Document No.", CreateServiceOrderBatchErr);
    end;

    local procedure VerifyServContractLineExistInServInvoice(ContractNo: Code[20]; ServItemNo: Code[20]; GLAccNo: Code[20]; PostingDate: Date; ExpectedDescription: Text)
    var
        ServiceLine: Record "Service Line";
        ServLedgerEntry: Record "Service Ledger Entry";
    begin
        FilterServiceLine(ServiceLine, ContractNo, GLAccNo, PostingDate);
        ServLedgerEntry.SetRange("Service Item No. (Serviced)", ServItemNo);
        FindServiceLedgerEntries(ServLedgerEntry, ContractNo);
        ServiceLine.SetRange("Appl.-to Service Entry", ServLedgerEntry."Entry No.");
        ServiceLine.FindFirst;
        ServiceLine.TestField(Description, ExpectedDescription);
        Assert.AreNotEqual(0, ServiceLine.Amount, ServiceLine.FieldCaption(Amount));
    end;

    local procedure VerifyServContractLineAmountSplitByPeriod(ContractNo: Code[20]; ServItemNo: Code[20]; GLAccNo: Code[20]; PostingDate: Date; NoOfLines: Integer; ExpectedAmount: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServLedgerEntry: Record "Service Ledger Entry";
        FromServLedgEntryNo: Integer;
    begin
        FilterServiceLine(ServiceLine, ContractNo, GLAccNo, PostingDate);
        ServLedgerEntry.SetRange("Service Item No. (Serviced)", ServItemNo);
        FindServiceLedgerEntries(ServLedgerEntry, ContractNo);
        FromServLedgEntryNo := ServLedgerEntry."Entry No.";
        ServLedgerEntry.FindLast;
        ServiceLine.SetRange("Appl.-to Service Entry", FromServLedgEntryNo, ServLedgerEntry."Entry No.");
        Assert.RecordCount(ServiceLine, NoOfLines);
        ServiceLine.CalcSums(Amount);
        ServiceLine.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyServiceDocAmount(DocumentType: Option; ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceDocumentHeader(ServiceHeader, DocumentType, ContractNo);
        Assert.IsFalse(ServiceHeader."Prices Including VAT", ServiceHeader.FieldCaption("Prices Including VAT"));
        Assert.AreEqual(
          -GetServiceLedgerEntryNegAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Sale),
          GetServiceDocAmount(ServiceHeader), ServiceLine.FieldCaption(Amount));
    end;

    local procedure VerifyServiceContractStatus(ContractType: Option; ContractNo: Code[20]; ExpectedStatus: Option)
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        FindServiceContractHeader(ServiceContractHeader, ContractType, ContractNo);
        Assert.AreEqual(ExpectedStatus, ServiceContractHeader.Status, 'Incorrect status.');
    end;

    local procedure VerifyPostedServiceInvoiceAmount(ContractNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Amount: Decimal;
    begin
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ContractNo);
        Assert.IsFalse(ServiceInvoiceHeader."Prices Including VAT", ServiceInvoiceHeader.FieldCaption("Prices Including VAT"));
        Amount := -GetServiceLedgerEntryNegAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Sale);
        Assert.AreEqual(
          Amount, GetPostedServiceInvoiceAmount(ContractNo), ServiceInvoiceLine.FieldCaption(Amount));
        Assert.AreEqual(
          Amount,
          GetServiceLedgerEntryPosAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Usage),
          ServiceLedgerEntry.FieldCaption(Amount));
    end;

    local procedure VerifyPostedServiceCrMemoAmount(ContractNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Amount: Decimal;
    begin
        FindServiceCrMemoHeader(ServiceCrMemoHeader, ContractNo);
        Assert.IsFalse(ServiceCrMemoHeader."Prices Including VAT", ServiceCrMemoHeader.FieldCaption("Prices Including VAT"));
        Amount := -GetServiceLedgerEntryNegAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Sale);
        Assert.AreEqual(
          Amount, GetPostedServiceCrMemoAmount(ContractNo), ServiceCrMemoLine.FieldCaption(Amount));
        Assert.AreEqual(
          -GetServiceLedgerEntryPosAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Sale),
          GetServiceLedgerEntryNegAmount(ContractNo, ServiceLedgerEntry."Entry Type"::Usage),
          ServiceLedgerEntry.FieldCaption(Amount));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateContractInvoicesRequestPageHandler(var CreateContractInvoices: TestRequestPage "Create Contract Invoices")
    var
        InvoiceDate: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Create Contract Invoices";
        LibraryVariableStorage.Dequeue(InvoiceDate);
        CreateContractInvoices.PostingDate.SetValue(Format(InvoiceDate));
        CreateContractInvoices.InvoiceToDate.SetValue(Format(InvoiceDate));
        CreateContractInvoices.CreateInvoices.SetValue(Format(CreateContractInvoices.CreateInvoices.GetOption(1)));  // Passing 1 for First Option.
        CreateContractInvoices."Service Contract Header".SetFilter("Contract No.", LibraryVariableStorage.DequeueText);
        CreateContractInvoices.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateContractServiceOrdersRequestPageHandler(var CreateContractServiceOrders: TestRequestPage "Create Contract Service Orders")
    begin
        CurrentSaveValuesId := REPORT::"Create Contract Service Orders";
        CreateContractServiceOrders.StartingDate.SetValue(Format(WorkDate));
        CreateContractServiceOrders.EndingDate.SetValue(Format(WorkDate));
        CreateContractServiceOrders.CreateServiceOrders.SetValue(Format(CreateContractServiceOrders.CreateServiceOrders.GetOption(1)));  // Passing 1 for First Option.
        CreateContractServiceOrders."Service Contract Header".SetFilter("Contract No.", LibraryVariableStorage.DequeueText);
        CreateContractServiceOrders.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConfirmCreateContractServiceOrdersRequestPageHandler(var CreateContractServiceOrders: TestRequestPage "Create Contract Service Orders")
    begin
        CurrentSaveValuesId := REPORT::"Create Contract Service Orders";
        CreateContractServiceOrders.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractTemplateListHandler(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        ServiceContractTemplate.SetRange("Invoice after Service", true);
        ServiceContractTemplate.FindFirst;
        UpdateTemplateNoOnServiceContract(ServiceContractTemplateList, ServiceContractTemplate."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractTemplateListHandler2(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    begin
        ServiceContractTemplateList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectServiceContractTemplateListHandler(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    begin
        UpdateTemplateNoOnServiceContract(ServiceContractTemplateList, LibraryVariableStorage.DequeueText);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageTest: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConditionalConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := StrPos(Message, CreateInvoiceMsg) = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DoNotCreateContrUsingTemplateConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := StrPos(Message, CreateContrUsingTemplateQst) = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConditionalNextPlannedDateConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := StrPos(Message, NextPlannedServiceDateConfirmQst) = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MultipleDialogsConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        // There should be no additonal confirm handler with CreateInvoiceMsg. If confirmation window opens then handler failes on the following assert

        Assert.AreNotEqual(0, StrPos(Question, LibraryVariableStorage.DequeueText), UnexpectedConfirmTextErr);
        Reply := true;
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;
}

