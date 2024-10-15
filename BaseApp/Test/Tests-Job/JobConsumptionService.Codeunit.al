codeunit 136301 "Job Consumption Service"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Job]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        Initialized: Boolean;
        UndoConsumptionJobError: Label 'You cannot undo consumption on the line because it has been already posted to Projects.';
        JobBlockedError: Label '%1 %2 must not be blocked with type %3.';
        UnknownError: Label 'Unknown error.';

    local procedure Initialize()
    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Consumption Service");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Consumption Service");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetCreditWarningsToNoWarnings();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Consumption Service");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceOrderFullJobConsumption()
    begin
        // Covers document number TC1.1 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating entries after posting Service Order with Full Job consumption.

        ConsumeService(1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceOrderPartJobConsumption()
    begin
        // Covers document number TC1.2 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating entries after posting Service Order with Partial Job consumption.

        ConsumeService(LibraryUtility.GenerateRandomFraction());
    end;

    local procedure ConsumeService(ConsumptionFactor: Decimal)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Create a new Service Order with Job attached on Service Lines.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, ConsumptionFactor);

        // 2. Exercise: Save the Service Lines in temporary table and post the Service Order as Ship and Consume.
        GetServiceLines(ServiceHeader, ServiceLine);
        CopyServiceLines(ServiceLine, TempServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Check that the Job Ledger Entry, Job Planning Lines correspond to the relevant Service Line. Check that the field
        // Posted Service Shipment No. of the Job Ledger Entry is updated to show Service Shipment No.
        VerifyServiceDocPostingForJob(TempServiceLine)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UndoConsumptionErrorForJob()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Covers document number TC1.3 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating that the system generates an error on performing Undo Consumption
        // for Service Lines that have been posted to Jobs.

        // 1. Setup: Create a new Service Order with Job attached on Service Lines. Post the Service Order as Ship and Consume.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, 1);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Find Service Shipment Lines and Undo Consumption.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        asserterror CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);

        // 3. Verify: Check that the application generates an error if Undo Consumption is performed for Service Lines that have been posted
        // to Jobs.
        Assert.AreEqual(StrSubstNo(UndoConsumptionJobError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobNoChangeAftrConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Job: Record Job;
    begin
        // Covers document number TC1.4 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating that the system generates an error on changing Job No. field
        // for Service Line that has been posted to Jobs.

        // 1. Setup: Setup and post the Service Order as Ship and Consume. Create a new Job.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, LibraryUtility.GenerateRandomFraction());
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        GetServiceLines(ServiceHeader, ServiceLine);

        LibraryJob.CreateJob(Job, ServiceLine."Bill-to Customer No.");

        // 2. Exercise: Change Job No. field.
        asserterror ServiceLine.Validate("Job No.", Job."No.");

        // 3. Verify: Check that the application generates an error if Job No. field is changed for Service Line that has been
        // posted to Jobs.
        VerifyJobConsumedError(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobTaskNoChangeAftrConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        JobTask: Record "Job Task";
        Job: Record Job;
    begin
        // Covers document number TC1.4 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating that the system generates an error on changing Job Task No. field
        // for Service Line that has been posted to Jobs.

        // 1. Setup: Setup and post the Service Order as Ship and Consume. Create a new Job Task.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, LibraryUtility.GenerateRandomFraction());
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        GetServiceLines(ServiceHeader, ServiceLine);
        Job.Get(ServiceLine."Job No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // 2. Exercise: Change Job Task No. field.
        asserterror ServiceLine.Validate("Job Task No.", JobTask."Job Task No.");

        // 3. Verify: Check that the application generates an error if Job Task No. field is changed for Service Line that has been
        // posted to Jobs.
        VerifyJobConsumedError(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure LineTypeChangeAftrConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC1.4 - refer to TFS ID 19910.
        // Test integration of Jobs with Service Management by validating that the system generates an error on changing Job Line Type field
        // for Service Line that has been posted to Jobs.

        // 1. Setup: Setup and post the Service Order as Ship and Consume.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, LibraryUtility.GenerateRandomFraction());
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        GetServiceLines(ServiceHeader, ServiceLine);

        // 2. Exercise: Change Job Line Type field.
        asserterror ServiceLine.Validate("Job Line Type", ServiceLine."Job Line Type"::" ");

        // 3. Verify: Check that the application generates an error if Job Line Type field is changed for Service Line that has been
        // posted to Jobs.
        VerifyJobConsumedError(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedJobOnServiceLineError()
    var
        Job: Record Job;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-JB-2 - refer to TFS ID 20892.
        // Test that it is impossible to specify Job No., assigned to a blocked job, on the Service Line.

        // 1. Setup: Create a new Job and set Blocked as All.
        Initialize();
        LibraryJob.CreateJob(Job);
        Job.Validate(Blocked, Job.Blocked::All);
        Job.Modify(true);

        // 2. Exercise: Create a new Service Order - Service Header, Service Line and try to assign the blocked Job on the Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Job."Bill-to Customer No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryJob.FindItem());
        asserterror ServiceLine.Validate("Job No.", Job."No.");

        // 3. Verify: Check that the application generates an error on assignment of blocked Job to Job No. field of Service Line.
        Assert.AreEqual(StrSubstNo(JobBlockedError, Job.TableCaption(), Job."No.", Job.Blocked), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankJobFieldsAfterJobChange()
    var
        ServiceHeader: Record "Service Header";
        Job: Record Job;
    begin
        // Covers document number TC-PP-JB-3 - refer to TFS ID 20892.
        // Test that the Job Task No. field is validated correctly after the Job No. field value has been changed.

        // 1. Setup: Create a new Service Order with a new Job attached on Service Lines. Create Service Lines for G/L Account. Create one
        // more new Job.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, 1);

        LibraryJob.CreateJob(Job, ServiceHeader."Bill-to Customer No.");

        // 2. Exercise: Change the Job No. on Service Lines as No. of new job created.
        ModifyJobNoOnServiceLines(ServiceHeader, Job."No.");

        // 3. Verify: Check that the Job Task No. and Job Line Type fields are blank after changing Job No. on Service Line.
        VerifyJobFieldsOnServiceLines(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankJobFieldsAfterJobDeletion()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-PP-JB-3 - refer to TFS ID 20892.
        // Test that the Job Task No. field is validated correctly after the Job No. field value has been deleted.

        // 1. Setup: Create a new Service Order with Job attached on Service Lines. Create Service Lines for G/L Account.
        Initialize();
        CreateServiceOrderWithJob(ServiceHeader, 1);

        // 2. Exercise: Change the Job No. on Service Lines as blank.
        ModifyJobNoOnServiceLines(ServiceHeader, '');

        // 3. Verify: Check that the Job Task No. and Job Line Type fields are blank after deleting Job No. value on Service Line.
        VerifyJobFieldsOnServiceLines(ServiceHeader);
    end;

    local procedure AttachJobTaskToServiceDoc(JobTask: Record "Job Task"; var ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        Counter: Integer;
    begin
        GetServiceLines(ServiceHeader, ServiceLine);
        repeat
            Counter += 1;
            ServiceLine.Validate("Job No.", JobTask."Job No.");
            ServiceLine.Validate("Job Task No.", JobTask."Job Task No.");
            ServiceLine.Validate("Job Line Type", Counter mod 4);  // Remainder of division by 4 ensures selection of each Job Line Type.
            ServiceLine.Modify(true)
        until ServiceLine.Next() = 0
    end;

    local procedure CopyServiceLines(var FromServiceLine: Record "Service Line"; var ToServiceLine: Record "Service Line")
    begin
        if FromServiceLine.FindSet() then
            repeat
                ToServiceLine.Init();
                ToServiceLine := FromServiceLine;
                ToServiceLine.Insert();
            until FromServiceLine.Next() = 0
    end;

    local procedure CreateServiceOrderWithJob(var ServiceHeader: Record "Service Header"; ConsumptionFactor: Decimal)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        Customer: Record Customer;
        Counter: Integer;
    begin
        // Create a new Job, Service Order - Service Header, Service Item Line and Service Lines of Job Line Type as blank,
        // Budget, Billable, Both Budget and Billable and Type as Item and Resource.


        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Advice", Customer."Shipping Advice"::Partial);
        Customer.Modify(true);
        LibraryJob.CreateJob(Job, Customer."No.");

        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Job."Bill-to Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        for Counter := 1 to 4 do begin
            CreateServiceLine(ServiceItemLine, ServiceLine.Type::Item, ConsumptionFactor, ServiceLine);
            CreateServiceLine(ServiceItemLine, ServiceLine.Type::Resource, ConsumptionFactor, ServiceLine);
        end;

        AttachJobTaskToServiceDoc(JobTask, ServiceHeader)
    end;

    local procedure CreateServiceLine(ServiceItemLine: Record "Service Item Line"; Type: Enum "Service Line Type"; ConsumptionFactor: Decimal; var ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
        ConsumableNo: Code[20];
    begin
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");

        ConsumableNo := LibraryJob.FindConsumable(LibraryJob.Service2JobConsumableType(Type));
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, ConsumableNo);

        ServiceLine.Validate(Description, Format(LibraryUtility.GenerateGUID()));
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Location Code", '');

        // Multiply by ConsumptionFactor to determine Full/Partial Qty. to Ship and Qty. to Consume.
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * ConsumptionFactor);
        ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship");
        ServiceLine.Modify(true)
    end;

    local procedure GetServiceLines(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure ModifyJobNoOnServiceLines(ServiceHeader: Record "Service Header"; JobNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLines(ServiceHeader, ServiceLine);
        repeat
            ServiceLine.Validate("Job No.", JobNo);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyServiceDocPostingForJob(ServiceLine: Record "Service Line")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        TempJobJournalLine: Record "Job Journal Line" temporary;
    begin
        // Get the document number from the posted shipment.
        case ServiceLine."Document Type" of
            ServiceLine."Document Type"::Order:
                ServiceShipmentHeader.SetRange("Order No.", ServiceLine."Document No.");
            ServiceLine."Document Type"::Invoice:
                ServiceShipmentHeader.SetRange("Order No.", ServiceLine."Document No.");
            else
                Assert.Fail(StrSubstNo('Unsupported service document type: %1', ServiceLine."Document Type"))
        end;
        Assert.AreEqual(1, ServiceShipmentHeader.Count, '# service shipment headers.');
        ServiceShipmentHeader.FindFirst();
        // Use a job journal line to verify.
        TempJobJournalLine."Job No." := ServiceLine."Job No.";
        TempJobJournalLine."Job Task No." := ServiceLine."Job Task No.";
        TempJobJournalLine."Document No." := ServiceShipmentHeader."No.";
        TempJobJournalLine."Line Type" := ServiceLine."Job Line Type";
        TempJobJournalLine.Description := ServiceLine.Description;
        TempJobJournalLine.Quantity := ServiceLine."Qty. to Consume";
        TempJobJournalLine."Unit Cost (LCY)" := ServiceLine."Unit Cost (LCY)";
        TempJobJournalLine."Unit Price (LCY)" := ServiceLine."Unit Price";
        TempJobJournalLine.Insert();

        LibraryJob.VerifyJobJournalPosting(false, TempJobJournalLine)
    end;

    local procedure VerifyJobConsumedError(ServiceLine: Record "Service Line")
    begin
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Quantity Consumed"), Format(0));
    end;

    local procedure VerifyJobFieldsOnServiceLines(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLines(ServiceHeader, ServiceLine);
        repeat
            ServiceLine.TestField("Job Task No.", '');
            ServiceLine.TestField("Job Line Type", ServiceLine."Job Line Type"::" ");
        until ServiceLine.Next() = 0
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;
}

