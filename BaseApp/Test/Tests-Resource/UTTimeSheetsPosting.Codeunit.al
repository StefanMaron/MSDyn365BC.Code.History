codeunit 136502 "UT Time Sheets Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet]
    end;

    var
        LibraryResource: Codeunit "Library - Resource";
        LibraryService: Codeunit "Library - Service";
        LibraryAssembly: Codeunit "Library - Assembly";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryJob: Codeunit "Library - Job";
#if not CLEAN23
        LibraryRandom: Codeunit "Library - Random";
#endif
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
#if not CLEAN23
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
#endif
        Text016: Label 'Time Sheet field %1 value is incorrect.';
        Text020: Label 'There is no Time Sheet';
        Text021: Label 'Unexpected time sheet searching error.';
        Text023: Label 'Quantity cannot be';
        Text024: Label '%1 field %2 value is incorrect.';
        Text027: Label 'Service Line field %1 value is incorrect.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestResTimeSheetLinePosting()
    var
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlLine: Record "Res. Journal Line";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        // function tests posting routines for time sheet line with Type = Resource
        Initialize();

        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // create time sheet line with type Resource
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');

        // create time sheet detail for first day
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", 1);
        // create time sheet detail for second day
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date" + 1, 2);

        // submit line
        TimeSheetApprovalMgt.Submit(TimeSheetLine);

        // approve line
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // create resource journal lines based on approved time sheet line
        FindResourceJournalBatch(ResJnlBatch);
        ResJnlLine."Journal Template Name" := ResJnlBatch."Journal Template Name";
        ResJnlLine."Journal Batch Name" := ResJnlBatch.Name;
        SuggestResourceJournalLines(ResJnlLine, TimeSheetHeader);

        // find and post created journal lines
        ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
        ResJnlLine.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        repeat
            ResJnlPostLine.RunWithCheck(ResJnlLine);
        until ResJnlLine.Next() = 0;

        // time sheet line must be marked as posted
        TimeSheetLine.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.");
        TimeSheetLine.TestField(Posted, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobTimeSheetLinePosting()
    var
        Resource: Record Resource;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        // function tests posting routines for time sheet line with Type = Job
        Initialize();

        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // find job and task
        LibraryTimeSheet.FindJob(Job);
        LibraryTimeSheet.FindJobTask(Job."No.", JobTask);
        // job's responsible person (resource) must have Owner ID filled in
        Resource.Get(Job."Person Responsible");
        Resource."Time Sheet Owner User ID" := UserId;
        Resource.Modify();

        // create time sheet line with type Job
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader,
          TimeSheetLine,
          TimeSheetLine.Type::Job,
          Job."No.",
          JobTask."Job Task No.",
          '',
          '');

        // create time sheet detail for first day
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", 1);
        // create time sheet detail for second day
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date" + 1, 2);

        // submit line
        TimeSheetApprovalMgt.Submit(TimeSheetLine);

        // approve line
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // create resource journal lines based on approved time sheet line
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, TimeSheetLine);

        // find and post created journal lines
        FilterJobJournalLineByBatchTemplate(JobJnlLine, JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name");
        JobJnlLine.SetRange(Type, JobJnlLine.Type::Resource);
        JobJnlLine.SetRange("No.", TimeSheetHeader."Resource No.");
        repeat
            JobJnlPostLine.RunWithCheck(JobJnlLine);
        until JobJnlLine.Next() = 0;

        // time sheet line must be marked as posted
        TimeSheetLine.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.");
        TimeSheetLine.TestField(Posted, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobTimeSheetLinePostingWithChargeableFalse()
    var
        Resource: Record Resource;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        // [SCENARIO 381031] Posting of Job Journal Lines based on Time Sheet with Chargeable = No
        Initialize();

        // [GIVEN] Approved Time Sheet for Resource "R" with Time Sheet Line where Chargeable = No
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", false);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        Resource.Get(TimeSheetHeader."Resource No.");
        Resource."Time Sheet Owner User ID" := UserId;
        Resource.Modify();

        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, Job."No.", JobTask."Job Task No.", '', '');
        TimeSheetLine.Validate(Chargeable, false);
        TimeSheetLine.Modify(true);
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", 1);

        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // [GIVEN] Job Journal Line is created for approved Time Sheet line
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, TimeSheetLine);
        FilterJobJournalLineByBatchTemplate(JobJnlLine, JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name");
        JobJnlLine.SetRange(Type, JobJnlLine.Type::Resource);
        JobJnlLine.SetRange("No.", TimeSheetHeader."Resource No.");
        JobJnlLine.FindFirst();

        // [WHEN] Job Journnal Line is posted
        JobJnlPostLine.RunWithCheck(JobJnlLine);

        // [THEN] Resource Ledger Entry is posted for Resource "R" with Chargeable = false
        ResLedgerEntry.SetRange("Resource No.", Resource."No.");
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Chargeable, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderShipConsume()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SavedServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify time sheet total quantity after ship and consume service order with timesheet resource.

        Initialize();
        LibraryTimeSheet.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify();

        // get values from service order
        SavedServiceLine.Copy(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        LibraryTimeSheet.CheckServiceTimeSheetLine(TimeSheetHeader, SavedServiceLine."Document No.", SavedServiceLine."Line No.",
          SavedServiceLine."Qty. to Consume", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderShip()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SavedServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify time sheet total quantity after ship service order with timesheet resource.

        Initialize();
        LibraryTimeSheet.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        // get values from service order
        SavedServiceLine.Copy(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        LibraryTimeSheet.CheckServiceTimeSheetLine(TimeSheetHeader, SavedServiceLine."Document No.", SavedServiceLine."Line No.",
          SavedServiceLine."Qty. to Ship", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWithoutTimeSheet_ServiceOrderShip()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Resource: Record Resource;
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify an error when trying to ship service order with time sheet resource.

        Initialize();

        // create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);

        // resource - person
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.Validate("Time Sheet Approver User ID", UserId);
        Resource.Modify();

        LibraryTimeSheet.CreateServiceOrder(ServiceHeader, WorkDate());

        // create service line
        CreateServiceLine(ServiceLine, ServiceHeader, Resource."No.", LibraryTimeSheet.GetRandomDecimal());

        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Assert.IsTrue(StrPos(GetLastErrorText, Text020) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyLinesFromTimeSheet_PostServiceOrderShip()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SavedServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Create time sheet resource and service order, copy service lines from time sheet into service order, ship service order, verify TS lines

        Initialize();
        // create time sheet with lines and linked to resource empty service order
        LibraryTimeSheet.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);

        // copy service lines from time sheet into service order
        TimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        // create service line
        CreateServiceLine(ServiceLine, ServiceHeader, TimeSheetHeader."Resource No.", LibraryTimeSheet.GetRandomDecimal());

        // get values from service order
        SavedServiceLine.Copy(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        LibraryTimeSheet.CheckServiceTimeSheetLine(TimeSheetHeader, SavedServiceLine."Document No.", SavedServiceLine."Line No.",
          SavedServiceLine."Qty. to Ship", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostServiceOrderShip_CopyLinesFromTimeSheet()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        ServiceLineQuantity: Decimal;
        ServiceHeaderNo: Code[20];
        ServiceLineNo: Integer;
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Ship service order with time sheet resource, create time sheet line and copy service lines from TS, verify Quantities in service lines.

        Initialize();
        // create service order with line and linked to resource empty time sheet
        LibraryTimeSheet.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        // get values from service order
        ServiceLineQuantity := ServiceLine."Qty. to Ship";
        ServiceHeaderNo := ServiceHeader."No.";
        ServiceLineNo := ServiceLine."Line No.";

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Service, '', '', ServiceHeader."No.", '');
        TimeSheetLine.Validate("Service Order No.", ServiceHeader."No.");
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", LibraryTimeSheet.GetRandomDecimal());
        // submit and approve lines
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // copy service lines from time sheet into service order
        TimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeaderNo);
        Assert.AreEqual(2, ServiceLine.Count,
          StrSubstNo(Text016, 'COUNT of rows'));

        ServiceLine.SetRange("Line No.", ServiceLineNo);
        ServiceLine.FindFirst();
        Assert.AreEqual(ServiceLineQuantity, ServiceLine.Quantity,
          StrSubstNo(Text016, ServiceLine.FieldCaption(Quantity)));

        ServiceLine.Reset();
        ServiceLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        ServiceLine.FindFirst();
        Assert.AreEqual(TimeSheetLine."Total Quantity", ServiceLine.Quantity,
          StrSubstNo(Text016, ServiceLine.FieldCaption(Quantity)));
    end;

    [Test]
    [HandlerFunctions('HndlConfirm')]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderUndoShipment()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        SavedServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Check Quantity in time sheet line after undo shipment of service order with time sheet resource.

        Initialize();
        LibraryTimeSheet.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        // get values from service order
        SavedServiceLine.Copy(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ServiceShipmentLine.SetRange("Order No.", SavedServiceLine."Document No.");
        ServiceShipmentLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);

        LibraryTimeSheet.CheckServiceTimeSheetLine(TimeSheetHeader, SavedServiceLine."Document No.", SavedServiceLine."Line No.",
          -SavedServiceLine."Qty. to Ship", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderPartialShipInvoice()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineQuantity: Decimal;
        ServiceHeaderNo: Code[20];
        ServiceLineNo: Integer;
        Iteration: Integer;
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Check Quantity in timesheet line after partially shipping & invoicing service order with time sheet resource in two steps.

        Initialize();
        LibraryTimeSheet.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        // get values from service order
        ServiceLineQuantity := ServiceLine."Qty. to Ship";
        ServiceHeaderNo := ServiceHeader."No.";
        ServiceLineNo := ServiceLine."Line No.";

        for Iteration := 1 to 2 do begin
            ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
            ServiceLine.SetRange("Document No.", ServiceHeaderNo);
            if ServiceLine.FindSet() then
                repeat
                    ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity / 2);
                    ServiceLine.Modify();
                until ServiceLine.Next() = 0;
            ServiceHeader.Find();
            LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
            LibraryTimeSheet.CheckServiceTimeSheetLine(TimeSheetHeader, ServiceHeaderNo, ServiceLineNo, ServiceLineQuantity / 2, true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderPartialShipConsume()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineQuantity: Decimal;
        ServiceHeaderNo: Code[20];
        ServiceLineNo: Integer;
        Iteration: Integer;
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Check Quantity in timesheet line after partially shipping & consuming service order with time sheet resource in two steps.

        Initialize();
        LibraryTimeSheet.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify();

        // get values from service order
        ServiceLineQuantity := ServiceLine."Qty. to Consume";
        ServiceHeaderNo := ServiceHeader."No.";
        ServiceLineNo := ServiceLine."Line No.";

        for Iteration := 1 to 2 do begin
            ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
            ServiceLine.SetRange("Document No.", ServiceHeaderNo);
            if ServiceLine.FindSet() then
                repeat
                    ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity / 2);
                    ServiceLine.Validate("Qty. to Invoice", 0);
                    ServiceLine.Modify();
                until ServiceLine.Next() = 0;
            ServiceHeader.Find();
            LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
            LibraryTimeSheet.CheckServiceTimeSheetLine(TimeSheetHeader, ServiceHeaderNo, ServiceLineNo, ServiceLineQuantity / 2, false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobJournal_PostingQtyMoreThanTimeSheetLine()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        Initialize();
        LibraryTimeSheet.InitJobScenario(TimeSheetHeader, TimeSheetLine);

        // create resource journal lines based on approved time sheet line
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, TimeSheetLine);

        // find and post created journal lines
        FilterJobJournalLineByBatchTemplate(JobJnlLine, JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name");
        JobJnlLine.SetRange(Type, JobJnlLine.Type::Resource);
        JobJnlLine.SetRange("No.", TimeSheetHeader."Resource No.");
        JobJnlLine.FindFirst();
        // change quantity to the next higher
        JobJnlLine.Validate(Quantity, TimeSheetLine."Total Quantity" + 10);
        JobJnlLine.Modify();

        asserterror JobJnlPostLine.RunWithCheck(JobJnlLine);
        Assert.IsTrue(StrPos(GetLastErrorText, Text023) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResourceJournal_PostingQtyMoreThanTimeSheetLine()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResJnlLine: Record "Res. Journal Line";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        Initialize();
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, false);

        FindResourceJournalBatch(ResJnlBatch);
        ResJnlLine."Journal Template Name" := ResJnlBatch."Journal Template Name";
        ResJnlLine."Journal Batch Name" := ResJnlBatch.Name;
        SuggestResourceJournalLines(ResJnlLine, TimeSheetHeader);

        // find and post created journal lines
        ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
        ResJnlLine.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        ResJnlLine.FindFirst();
        // change quantity to the next higher
        ResJnlLine.Validate(Quantity, TimeSheetLine."Total Quantity" + 10);
        ResJnlLine.Modify();

        asserterror ResJnlPostLine.RunWithCheck(ResJnlLine);
        Assert.IsTrue(StrPos(GetLastErrorText, Text023) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceOrder_PostingQtyMoreThanTimeSheetLine_Ship()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify that service order with service line having Quantity greater than timesheet line cannot be shipped.

        Initialize();
        LibraryTimeSheet.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);

        TimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.Validate(Quantity, TimeSheetLine."Total Quantity" + LibraryTimeSheet.GetRandomDecimal());
        ServiceLine.Modify();

        ServiceHeader.Find();
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.IsTrue(StrPos(GetLastErrorText, Text023) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceOrder_PostingQtyMoreThanTimeSheetLine_ShipConsume()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify that service order with service line having Quantity greater than timesheet line cannot be shipped and consumed.

        Initialize();
        LibraryTimeSheet.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);

        TimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.Validate(Quantity, TimeSheetLine."Total Quantity" + LibraryTimeSheet.GetRandomDecimal());
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify();

        ServiceHeader.Find();
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        Assert.IsTrue(StrPos(GetLastErrorText, Text023) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobJournal_PartialPosting()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        Delta: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();
        LibraryTimeSheet.InitJobScenario(TimeSheetHeader, TimeSheetLine);
        Delta := Round(TimeSheetLine."Total Quantity" * (LibraryTimeSheet.GetRandomDecimal() / 100), 0.00001);

        // create resource journal lines based on approved time sheet line
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, TimeSheetLine);

        TimeSheetLine.CalcFields("Total Quantity");

        CheckJobJnlLineRemainingQuantity(JobJnlLine, TimeSheetHeader."Resource No.", TimeSheetLine."Total Quantity");

        DocumentNo := 'JJL1';
        JobJnlLine.Validate("Document No.", DocumentNo);
        JobJnlLine.Validate(Quantity, Delta);
        JobJnlLine.Modify();
        JobJnlPostLine.RunWithCheck(JobJnlLine);
        CheckTimeSheetPostingEntry(TimeSheetLine, DocumentNo, Delta);

        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, TimeSheetLine);

        CheckJobJnlLineRemainingQuantity(JobJnlLine, TimeSheetHeader."Resource No.", TimeSheetLine."Total Quantity" - Delta);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResourceJournal_PartialPosting()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResJnlLine: Record "Res. Journal Line";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        Delta: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, false);
        Delta := TimeSheetLine."Total Quantity" * (LibraryTimeSheet.GetRandomDecimal() / 100);

        FindResourceJournalBatch(ResJnlBatch);
        ResJnlLine."Journal Template Name" := ResJnlBatch."Journal Template Name";
        ResJnlLine."Journal Batch Name" := ResJnlBatch.Name;
        SuggestResourceJournalLines(ResJnlLine, TimeSheetHeader);

        TimeSheetLine.CalcFields("Total Quantity");

        CheckResJnlLineRemainingQuantity(ResJnlLine, TimeSheetHeader."Resource No.", TimeSheetLine."Total Quantity");

        DocumentNo := 'RJL1';
        ResJnlLine.Validate("Document No.", DocumentNo);
        ResJnlLine.Validate(Quantity, Delta);
        ResJnlLine.Modify();
        ResJnlPostLine.RunWithCheck(ResJnlLine);
        // verifying posted values function
        CheckTimeSheetPostingEntry(TimeSheetLine, DocumentNo, Delta);
        // get a new line in the resource journal
        SuggestResourceJournalLines(ResJnlLine, TimeSheetHeader);

        CheckResJnlLineRemainingQuantity(ResJnlLine, TimeSheetHeader."Resource No.", TimeSheetLine."Total Quantity" - Delta);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceOrder_PartialPosting_Ship()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceHeaderNo: Code[20];
        ServiceLineNo: Integer;
        Delta: Decimal;
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify time sheet posting entry and Remaining Quantity in service line after partially shipping service order with time sheet resource.

        Initialize();
        LibraryTimeSheet.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);
        ServiceHeaderNo := ServiceHeader."No.";
        Delta := TimeSheetLine."Total Quantity" * (LibraryTimeSheet.GetRandomDecimal() / 100);

        TimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        TimeSheetLine.CalcFields("Total Quantity");
        CheckServicelLineRemainingQuantity(ServiceLine, ServiceHeaderNo, TimeSheetLine, TimeSheetLine."Total Quantity", false);
        ServiceLineNo := ServiceLine."Line No.";

        ServiceLine.Validate("Qty. to Ship", Delta);
        ServiceLine.Modify();
        ServiceHeader.Find();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ServiceShipmentLine.SetRange("Order No.", ServiceHeaderNo);
        ServiceShipmentLine.SetRange("Order Line No.", ServiceLineNo);
        ServiceShipmentLine.SetRange("No.", TimeSheetHeader."Resource No.");
        ServiceShipmentLine.FindFirst();
        CheckTimeSheetPostingEntry(TimeSheetLine, ServiceShipmentLine."Document No.", Delta);

        CheckServicelLineRemainingQuantity(ServiceLine, ServiceHeaderNo, TimeSheetLine, TimeSheetLine."Total Quantity" - Delta, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_AbsenceEntryPost()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Employee: Record Employee;
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        Quantity: Decimal;
    begin
        Initialize();

        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // create time sheet line with type Absence
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Resource No." := TimeSheetHeader."Resource No.";
        Employee.Modify();

        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Absence, '', '', '',
          GetCauseOfAbsenceCode());
        TimeSheetLine.Chargeable := false;
        TimeSheetLine.Modify();

        Quantity := LibraryTimeSheet.GetRandomDecimal();

        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", Quantity);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        CheckTimeSheetPostingEntry(TimeSheetLine, '', Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_AssemblyOrderPost()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SavedAssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        // create an assembly order with a resource line (Resource has property Use Time Sheet = TRUE), the time sheet of the resource exists
        LibraryTimeSheet.InitAssemblyBackwayScenario(TimeSheetHeader, AssemblyHeader, AssemblyLine, true);

        // get values from assembly line (with type 'Resource') of the assembly order
        SavedAssemblyLine.Copy(AssemblyLine);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        LibraryTimeSheet.CheckAssemblyTimeSheetLine(TimeSheetHeader, SavedAssemblyLine."Document No.", SavedAssemblyLine."Line No.",
          SavedAssemblyLine."Quantity to Consume");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWithoutTimeSheet_AssemblyOrderPost()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        // create an assembly order with a resource line (Resource has property Use Time Sheet = TRUE), the time sheet of the resource doesn't exist
        LibraryTimeSheet.InitAssemblyBackwayScenario(TimeSheetHeader, AssemblyHeader, AssemblyLine, false);

        asserterror LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        Assert.IsTrue(StrPos(GetLastErrorText, Text020) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_AssemblyOrderPostWithSimilarLines()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SavedAssemblyLine1: Record "Assembly Line";
        SavedAssemblyLine2: Record "Assembly Line";
    begin
        Initialize();
        // create an assembly order with a resource line (Resource has property Use Time Sheet = TRUE), the time sheet of the resource exists
        LibraryTimeSheet.InitAssemblyBackwayScenario(TimeSheetHeader, AssemblyHeader, AssemblyLine, true);
        // get values from the 1st assembly line (with type 'Resource') of the assembly order
        SavedAssemblyLine1.Copy(AssemblyLine);

        Resource.Get(TimeSheetHeader."Resource No.");
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, AssemblyLine.Type::Resource, TimeSheetHeader."Resource No.",
          Resource."Base Unit of Measure", 4, 2, '');
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Resource);
        AssemblyLine.FindLast();
        // get values from the 2nd assembly line (with type 'Resource') of the assembly order
        SavedAssemblyLine2.Copy(AssemblyLine);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        LibraryTimeSheet.CheckAssemblyTimeSheetLine(
          TimeSheetHeader, SavedAssemblyLine1."Document No.", SavedAssemblyLine1."Line No.",
          SavedAssemblyLine1."Quantity to Consume");
        LibraryTimeSheet.CheckAssemblyTimeSheetLine(
          TimeSheetHeader, SavedAssemblyLine2."Document No.", SavedAssemblyLine2."Line No.",
          SavedAssemblyLine2."Quantity to Consume");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_AssemblyOrderPartialPost()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SavedAssemblyLine: Record "Assembly Line";
        PostedAssemblyLine: Record "Posted Assembly Line";
        Delta: Decimal;
    begin
        Initialize();
        // create an assembly order with a resource line (Resource has property Use Time Sheet = TRUE), the time sheet of the resource exists
        LibraryTimeSheet.InitAssemblyBackwayScenario(TimeSheetHeader, AssemblyHeader, AssemblyLine, true);

        // get values from assembly order
        SavedAssemblyLine.Copy(AssemblyLine);

        // random quantity to post
        Delta := AssemblyHeader."Quantity to Assemble" * (LibraryTimeSheet.GetRandomDecimal() / 100);

        AssemblyHeader.SetRange("No.", SavedAssemblyLine."Document No.");
        AssemblyHeader.FindFirst();
        AssemblyHeader.Validate("Quantity to Assemble", Delta);
        AssemblyHeader.Modify();
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Resource);
        AssemblyLine.FindLast();
        SavedAssemblyLine.Copy(AssemblyLine);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        if TimeSheetLine.FindLast() then
            LibraryTimeSheet.CheckAssemblyTimeSheetLine(
              TimeSheetHeader, SavedAssemblyLine."Document No.", SavedAssemblyLine."Line No.", SavedAssemblyLine."Quantity to Consume");

        PostedAssemblyLine.SetRange("Order No.", SavedAssemblyLine."Document No.");
        PostedAssemblyLine.SetRange("Order Line No.", SavedAssemblyLine."Line No.");
        PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Resource);
        PostedAssemblyLine.SetRange("No.", TimeSheetHeader."Resource No.");
        PostedAssemblyLine.FindFirst();
        CheckTimeSheetPostingEntry(TimeSheetLine, PostedAssemblyLine."Document No.", PostedAssemblyLine.Quantity);
    end;

#if not CLEAN23
    [Test]
    [Scope('OnPrem')]
    procedure SuggestJobJournalLineTSLineDiscountPct()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheetLine: Record "Time Sheet Line";
        JobResourcePrice: Record "Job Resource Price";
        JobJnlLine: Record "Job Journal Line";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job] [Line Discount]
        // [SCENARIO 371948] Suggest Job Journal Line from Time Sheet with Line Discount %
        Initialize();
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        // [GIVEN] Job, Job Task and Job Resource Price with Line Discount % = "X"
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobResourcePriceWithLineDiscountPct(
          JobResourcePrice, JobTask."Job No.", JobTask."Job Task No.",
          JobResourcePrice.Type::Resource, TimeSheetHeader."Resource No.");
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [GIVEN] Approved and Submitted Time Sheet with Time Sheet Line for created Job Task
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job,
          Job."No.", JobTask."Job Task No.", '', '');
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", 1);
        LibraryTimeSheet.SubmitAndApproveTimeSheetLine(TimeSheetLine);

        // [WHEN] Suggest Job Journal Line from Time Sheet
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, TimeSheetLine);

        // [THEN] Created Job Journal Line has field Line Discount % = "X"
        FilterJobJournalLineByBatchTemplate(JobJnlLine, JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name");
        JobJnlLine.FindFirst();
        JobJnlLine.TestField("Line Discount %", JobResourcePrice."Line Discount %");
    end;
#endif

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT Time Sheets Posting");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT Time Sheets Posting");

        LibraryTimeSheet.Initialize();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateLocalData();

        // create current user id setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        Commit();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT Time Sheets Posting");
    end;

#if not CLEAN23
    local procedure CreateJobResourcePriceWithLineDiscountPct(var JobResourcePrice: Record "Job Resource Price"; JobNo: Code[20]; JobTaskNo: Code[20]; Type: Option; "Code": Code[20])
    begin
        LibraryJob.CreateJobResourcePrice(
          JobResourcePrice, JobNo, JobTaskNo,
          Type, Code, '', '');
        JobResourcePrice.Validate("Line Discount %", LibraryRandom.RandInt(10));
        JobResourcePrice.Modify(true);
    end;
#endif

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ResourceNo: Code[20]; Qty: Decimal)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        ServiceLine.Validate("Service Item Line No.", 10000);
        ServiceLine.Validate(Quantity, Qty);
        ServiceLine.Modify();
    end;

    [Normal]
    local procedure FindResourceJournalBatch(var ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        ResJournalTemplate.SetRange(Recurring, false);
        LibraryResource.FindResJournalTemplate(ResJournalTemplate);
        LibraryResource.FindResJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
    end;

    local procedure FilterJobJournalLineByBatchTemplate(var JobJournalLine: Record "Job Journal Line"; JobJournalTemplateName: Code[10]; JobJournalBatchName: Code[10])
    begin
        JobJournalLine.SetRange("Journal Template Name", JobJournalTemplateName);
        JobJournalLine.SetRange("Journal Batch Name", JobJournalBatchName);
    end;

    local procedure GetCauseOfAbsenceCode(): Code[10]
    var
        CauseOfAbsence: Record "Cause of Absence";
        HumanResourceUnitOfMeasure: Record "Human Resource Unit of Measure";
    begin
        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        with CauseOfAbsence do begin
            if "Unit of Measure Code" = '' then begin
                HumanResourceUnitOfMeasure.FindFirst();
                Validate("Unit of Measure Code", HumanResourceUnitOfMeasure.Code);
                Modify(true);
            end;
            exit(Code);
        end;
    end;

    local procedure SuggestJobJournalLines(var JobJnlLine: Record "Job Journal Line"; TimeSheetHeader: Record "Time Sheet Header"; TimeSheetLine: Record "Time Sheet Line")
    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        SuggestJobJnlLines: Report "Suggest Job Jnl. Lines";
    begin
        LibraryJob.GetJobJournalTemplate(JobJnlTemplate);
        LibraryJob.CreateJobJournalBatch(JobJnlTemplate.Name, JobJnlBatch);
        JobJnlLine."Journal Template Name" := JobJnlBatch."Journal Template Name";
        JobJnlLine."Journal Batch Name" := JobJnlBatch.Name;

        SuggestJobJnlLines.InitParameters(
          JobJnlLine,
          TimeSheetHeader."Resource No.",
          TimeSheetLine."Job No.",
          TimeSheetLine."Job Task No.",
          TimeSheetHeader."Starting Date",
          TimeSheetHeader."Ending Date");
        SuggestJobJnlLines.UseRequestPage(false);
        SuggestJobJnlLines.Run();
    end;

    local procedure SuggestResourceJournalLines(ResJnlLine: Record "Res. Journal Line"; TimeSheetHeader: Record "Time Sheet Header")
    var
        SuggestResJnlLines: Report "Suggest Res. Jnl. Lines";
    begin
        SuggestResJnlLines.InitParameters(
          ResJnlLine,
          TimeSheetHeader."Resource No.",
          TimeSheetHeader."Starting Date",
          TimeSheetHeader."Ending Date");
        SuggestResJnlLines.UseRequestPage(false);
        SuggestResJnlLines.Run();
    end;

    local procedure CheckTimeSheetPostingEntry(TimeSheetLine: Record "Time Sheet Line"; DocumentNo: Code[20]; Quantity: Decimal)
    var
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
    begin
        TimeSheetPostingEntry.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        TimeSheetPostingEntry.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        TimeSheetPostingEntry.SetRange("Document No.", DocumentNo);
        TimeSheetPostingEntry.FindLast();
        Assert.AreEqual(
          Quantity, TimeSheetPostingEntry.Quantity,
          StrSubstNo(Text024, TimeSheetPostingEntry.TableCaption(), TimeSheetPostingEntry.FieldCaption(Quantity)));
    end;

    local procedure CheckJobJnlLineRemainingQuantity(var JobJnlLine: Record "Job Journal Line"; ResourceNo: Code[20]; TimeSheetLineRemainingQuantity: Decimal)
    begin
        FilterJobJournalLineByBatchTemplate(JobJnlLine, JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name");
        JobJnlLine.SetRange(Type, JobJnlLine.Type::Resource);
        JobJnlLine.SetRange("No.", ResourceNo);
        JobJnlLine.FindLast();
        Assert.AreEqual(
          TimeSheetLineRemainingQuantity, JobJnlLine.Quantity, StrSubstNo(Text024, JobJnlLine.TableCaption(), JobJnlLine.FieldCaption(Quantity)));
    end;

    local procedure CheckResJnlLineRemainingQuantity(var ResJnlLine: Record "Res. Journal Line"; ResourceNo: Code[20]; TimeSheetLineRemainingQuantity: Decimal)
    begin
        ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
        ResJnlLine.SetRange("Resource No.", ResourceNo);
        ResJnlLine.FindLast();
        Assert.AreEqual(
          TimeSheetLineRemainingQuantity, ResJnlLine.Quantity, StrSubstNo(Text024, ResJnlLine.TableCaption(), ResJnlLine.FieldCaption(Quantity)));
    end;

    local procedure CheckServicelLineRemainingQuantity(var ServiceLine: Record "Service Line"; ServiceHeaderNo: Code[20]; TimeSheetLine: Record "Time Sheet Line"; TimeSheetLineRemainingQuantity: Decimal; Consume: Boolean)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeaderNo);
        ServiceLine.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        ServiceLine.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        ServiceLine.FindFirst();
        if not Consume then
            Assert.AreEqual(
              TimeSheetLineRemainingQuantity, ServiceLine."Qty. to Ship", StrSubstNo(Text027, ServiceLine.FieldCaption("Qty. to Ship")))
        else
            Assert.AreEqual(
              TimeSheetLineRemainingQuantity, ServiceLine."Qty. to Consume", StrSubstNo(Text027, ServiceLine.FieldCaption("Qty. to Consume")));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

