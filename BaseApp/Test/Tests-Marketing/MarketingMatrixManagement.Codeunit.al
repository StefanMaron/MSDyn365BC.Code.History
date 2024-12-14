codeunit 136211 "Marketing Matrix Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        No: Code[20];
        SalesCycleCode: Code[10];
        CurrentSalesCycleStage: Integer;
        EstimatedValue: Decimal;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Matrix Management");
        InitGlobalVariables();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Matrix Management");

        LibraryService.SetupServiceMgtNoSeries();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Matrix Management");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithSalesperson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Tasks: TestPage Tasks;
        TableOption: Option Salesperson,Team,Campaign,Contact;
    begin
        // Test Tasks matrix with Show as Lines Salesperson after creation of Task for Salesperson.

        // 1. Setup: Create Salesperson and Task for Salesperson.
        Initialize();
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Commit();

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        TempTask.CreateTaskFromTask(Task);

        // 2. Exercise: Run Show Matrix from Tasks page with Show as Lines Salesperson and Salesperson filter.
        Tasks.OpenEdit();
        Tasks.TableOption.SetValue(TableOption::Salesperson);
        Tasks.FilterSalesPerson.SetValue(SalespersonPurchaser.Code);
        Commit();
        Tasks.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Tasks Matrix performed on Tasks Matrix page handler.

        // 4. Teardown: Rollback the Salesperson filter on Tasks page.
        Tasks.FilterSalesPerson.SetValue('');
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithTeam()
    var
        Team: Record Team;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Tasks: TestPage Tasks;
        TableOption: Option Salesperson,Team,Campaign,Contact;
    begin
        // Test Tasks matrix with Show as Lines Team after creation of Task for Team.

        // 1. Setup: Create Team and Task for Team.
        Initialize();
        LibraryMarketing.CreateTeam(Team);
        Commit();

        Task.SetRange("Team Code", Team.Code);
        TempTask.CreateTaskFromTask(Task);

        // 2. Exercise: Run Show Matrix from Tasks page with Show as Lines Team and Team filter.
        Tasks.OpenEdit();
        Tasks.TableOption.SetValue(TableOption::Team);
        Tasks.FilterTeam.SetValue(Team.Code);
        Commit();
        Tasks.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Tasks Matrix performed on Tasks Matrix page handler.

        // 4. Teardown: Rollback the Team filter on Tasks page.
        Tasks.FilterTeam.SetValue('');
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithCampaign()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Tasks: TestPage Tasks;
        CampaignNo: Code[20];
        TableOption: Option Salesperson,Team,Campaign,Contact;
    begin
        // Test Tasks matrix with Show as Lines Campaign after creation of Task for Campaign.

        // 1. Setup: Create Salesperson, Campaign with Salesperson Code and Task for Campaign.
        Initialize();
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CampaignNo := CreateCampaign(SalespersonPurchaser.Code);
        Commit();

        Task.SetRange("Campaign No.", CampaignNo);
        TempTask.CreateTaskFromTask(Task);

        // 2. Exercise: Run Show Matrix from Tasks page with Show as Lines Campaign and Campaign filter.
        Tasks.OpenEdit();
        Tasks.TableOption.SetValue(TableOption::Campaign);
        Tasks.FilterCampaign.SetValue(CampaignNo);
        Commit();
        Tasks.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Tasks Matrix performed on Tasks Matrix page handler.

        // 4. Teardown: Rollback the Campaign filter on Tasks page.
        Tasks.FilterCampaign.SetValue('');
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithContact()
    var
        Contact: Record Contact;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Tasks: TestPage Tasks;
        TableOption: Option Salesperson,Team,Campaign,Contact;
    begin
        // Test Tasks matrix with Show as Lines Contact after creation of Task for Contact.

        // 1. Setup: Create Contact and Task for Contact.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        Commit();

        Task.SetRange("Contact No.", Contact."No.");
        TempTask.CreateTaskFromTask(Task);

        // 2. Exercise: Run Show Matrix from Tasks page with Show as Lines Contact and Contact filter.
        Tasks.OpenEdit();
        Tasks.TableOption.SetValue(TableOption::Contact);
        Tasks.FilterContact.SetValue(Contact."No.");
        Commit();
        Tasks.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Tasks Matrix performed on Tasks Matrix page handler.

        // 4. Teardown: Rollback the Contact filter on Tasks page.
        Tasks.FilterContact.SetValue('');
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithStatusNotStarted()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Tasks: TestPage Tasks;
        StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed;
        TableOption: Option Salesperson,Team,Campaign,Contact;
    begin
        // Test Tasks matrix with Show as Lines Salesperson and Status Filter Not Started after creation of Task for Salesperson.

        // 1. Setup: Create Salesperson and Task for Salesperson.
        Initialize();
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Commit();

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        TempTask.CreateTaskFromTask(Task);

        // 2. Exercise: Run Show Matrix from Tasks page with Show as Lines Salesperson, Salesperson filter and Status filter as
        // Not Started.
        Tasks.OpenEdit();
        Tasks.TableOption.SetValue(TableOption::Salesperson);
        Tasks.FilterSalesPerson.SetValue(SalespersonPurchaser.Code);
        Tasks.StatusFilter.SetValue(StatusFilter::"Not Started");
        Commit();
        Tasks.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Tasks Matrix performed on Tasks Matrix page handler.

        // 4. Teardown: Rollback the Salesperson and Status filter on Tasks page.
        Tasks.FilterSalesPerson.SetValue('');
        Tasks.StatusFilter.SetValue(StatusFilter::" ");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithStatusInProgress()
    var
        Task: Record "To-do";
        StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed;
    begin
        // Test Tasks matrix with Show as Lines Salesperson and Status Filter In Progress after creation of Task for Salesperson.

        TaskWithStatus(Task.Status::"In Progress", StatusFilter::"In Progress");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithStatusWaiting()
    var
        Task: Record "To-do";
        StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed;
    begin
        // Test Tasks matrix with Show as Lines Salesperson and Status Filter Waiting after creation of Task for Salesperson.

        TaskWithStatus(Task.Status::Waiting, StatusFilter::Waiting);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithStatusPostponed()
    var
        Task: Record "To-do";
        StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed;
    begin
        // Test Tasks matrix with Show as Lines Salesperson and Status Filter Postponed after creation of Task for Salesperson.

        TaskWithStatus(Task.Status::Postponed, StatusFilter::Postponed);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithoutValue')]
    [Scope('OnPrem')]
    procedure TaskWithStatusCompleted()
    var
        Task: Record "To-do";
        StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed;
    begin
        // Test Tasks matrix with Show as Lines Salesperson and Status Filter Completed after creation of Task for Salesperson.

        TaskWithStatus(Task.Status::Completed, StatusFilter::Completed);
    end;

    local procedure TaskWithStatus(Status: Enum "Task Status"; StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Tasks: TestPage Tasks;
        TableOption: Option Salesperson,Team,Campaign,Contact;
    begin
        // 1. Setup: Create Salesperson, Task for Salesperson and Change the Status of to-do as per parameter.
        Initialize();
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Commit();

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        TempTask.CreateTaskFromTask(Task);
        Task.FindFirst();
        ChangeStatusOfTask(Task, Status);

        // 2. Exercise: Run Show Matrix from Tasks page with Show as Lines Salesperson, Salesperson filter and Status filter as
        // per parameter.
        Tasks.OpenEdit();
        Tasks.TableOption.SetValue(TableOption::Salesperson);
        Tasks.FilterSalesPerson.SetValue(SalespersonPurchaser.Code);
        Tasks.StatusFilter.SetValue(StatusFilter);
        Commit();
        Tasks.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Tasks Matrix performed on Tasks Matrix page handler.

        // 4. Teardown: Rollback the Salesperson and Status filter on Tasks page.
        Tasks.FilterSalesPerson.SetValue('');
        Tasks.StatusFilter.SetValue(StatusFilter::" ");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithValue')]
    [Scope('OnPrem')]
    procedure TaskWithIncludeClosedTrue()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        Tasks: TestPage Tasks;
        StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed;
        TableOption: Option Salesperson,Team,Campaign,Contact;
    begin
        // Test Tasks matrix with Show as Lines Salesperson, Status Filter Completed and Include Closed as True after closing
        // the  created Task for Salesperson.

        // 1. Setup: Create Salesperson, Task for Salesperson and Change the Status of to-do to Completed.
        Initialize();
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Commit();

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        TempTask.CreateTaskFromTask(Task);
        Task.FindFirst();
        ChangeStatusOfTask(Task, Task.Status::Completed);

        // 2. Exercise: Run Show Matrix from Tasks page with Show as Lines Salesperson, Salesperson filter, Status filter as Completed
        // and Include Closed as True.
        Tasks.OpenEdit();
        Tasks.TableOption.SetValue(TableOption::Salesperson);
        Tasks.FilterSalesPerson.SetValue(SalespersonPurchaser.Code);
        Tasks.StatusFilter.SetValue(StatusFilter::Completed);
        Tasks.IncludeClosed.SetValue(true);
        Commit();
        Tasks.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Tasks Matrix performed on Tasks Matrix page handler.

        // 4. Teardown: Rollback the Salesperson, Status filter and Include Close on Tasks page.
        Tasks.FilterSalesPerson.SetValue('');
        Tasks.StatusFilter.SetValue(StatusFilter::" ");
        Tasks.IncludeClosed.SetValue(false);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,HandlerForNoOfOpportunities')]
    [Scope('OnPrem')]
    procedure OpportunityWithSalesperson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesCycle: Record "Sales Cycle";
        Opportunities: TestPage Opportunities;
        TableOption: Option SalesPerson,Campaign,Contact;
        OutPutOption: Option "No of Opportunities","Estimated Value (LCY)","Calc. Current Value (LCY)","Avg. Estimated Value (LCY)","Avg. Calc. Current Value (LCY)";
        ContactNo: Code[20];
    begin
        // Test Opportunity matrix with Show as Lines Salesperson after creation and updation of Opportunity for Contact with
        // Salesperson.

        // 1. Setup: Create Salesperson, Contact with Salesperson, Sales Cycle, Sales Cycle Stage, Create and Update Opportunity for
        // Contact.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        ContactNo := CreateContactWithSalesperson(SalespersonPurchaser.Code);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Assign global variable for page handler.
        SalesCycleCode := SalesCycle.Code;
        CurrentSalesCycleStage := CreateSalesCycleStage(SalesCycle.Code);
        No := SalespersonPurchaser.Code;
        CreateAndUpdateOpportunity(ContactNo);

        // 2. Exercise: Run Show Matrix from Opportunities page with Show as Lines Salesperson and Show as No of Opportunities.
        Opportunities.OpenEdit();
        Opportunities.TableOption.SetValue(TableOption::SalesPerson);
        Opportunities.OutPutOption.SetValue(OutPutOption::"No of Opportunities");
        Opportunities.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Opportunities Matrix performed on Opportunities Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,HandlerForNoOfOpportunities')]
    [Scope('OnPrem')]
    procedure OpportunityWithContact()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesCycle: Record "Sales Cycle";
        Opportunities: TestPage Opportunities;
        TableOption: Option SalesPerson,Campaign,Contact;
        OutPutOption: Option "No of Opportunities","Estimated Value (LCY)","Calc. Current Value (LCY)","Avg. Estimated Value (LCY)","Avg. Calc. Current Value (LCY)";
        ContactNo: Code[20];
    begin
        // Test Opportunity matrix with Show as Lines Contact after creation and updation of Opportunity for Contact with Salesperson.

        // 1. Setup: Create Salesperson, Contact with Salesperson, Sales Cycle, Sales Cycle Stage, Create and Update Opportunity for
        // Contact.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        ContactNo := CreateContactWithSalesperson(SalespersonPurchaser.Code);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Assign global variable for page handler.
        SalesCycleCode := SalesCycle.Code;
        CurrentSalesCycleStage := CreateSalesCycleStage(SalesCycle.Code);
        No := ContactNo;
        CreateAndUpdateOpportunity(ContactNo);

        // 2. Exercise: Run Show Matrix from Opportunities page with Show as Lines Contact and Show as No of Opportunities.
        Opportunities.OpenEdit();
        Opportunities.TableOption.SetValue(TableOption::Contact);
        Opportunities.OutPutOption.SetValue(OutPutOption::"No of Opportunities");
        Opportunities.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Opportunities Matrix performed on Opportunities Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,HandlerForNoOfOpportunities')]
    [Scope('OnPrem')]
    procedure OpportunityWithCampaign()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        SalesCycle: Record "Sales Cycle";
        TempOpportunity: Record Opportunity temporary;
        Opportunity: Record Opportunity;
        Opportunities: TestPage Opportunities;
        TableOption: Option SalesPerson,Campaign,Contact;
        OutPutOption: Option "No of Opportunities","Estimated Value (LCY)","Calc. Current Value (LCY)","Avg. Estimated Value (LCY)","Avg. Calc. Current Value (LCY)";
        ContactNo: Code[20];
    begin
        // Test Opportunity matrix with Show as Lines Campaign after creation and updation of Opportunity for Campaign.

        // 1. Setup: Create Salesperson, Contact with Salesperson, Campaign, Sales Cycle, Sales Cycle Stage, Create Opportunity,
        // Update Campaign on Opportunity and Update Opportunity.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        ContactNo := CreateContactWithSalesperson(SalespersonPurchaser.Code);
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Assign global variable for page handler.
        SalesCycleCode := SalesCycle.Code;
        CurrentSalesCycleStage := CreateSalesCycleStage(SalesCycle.Code);
        No := Campaign."No.";
        Opportunity.SetRange("Contact No.", ContactNo);
        TempOpportunity.CreateOppFromOpp(Opportunity);
        UpdateCampaignOnOpportunity(Opportunity, Campaign."No.");
        Opportunity.UpdateOpportunity();
        Commit();

        // 2. Exercise: Run Show Matrix from Opportunities page with Show as Lines Campaign and Show as No of Opportunities.
        Opportunities.OpenEdit();
        Opportunities.TableOption.SetValue(TableOption::Campaign);
        Opportunities.OutPutOption.SetValue(OutPutOption::"No of Opportunities");
        Opportunities.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Opportunities Matrix performed on Opportunities Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,HandlerForOpportunityValue')]
    [Scope('OnPrem')]
    procedure OpportunityAsEstimatedValueLCY()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesCycle: Record "Sales Cycle";
        Opportunities: TestPage Opportunities;
        TableOption: Option SalesPerson,Campaign,Contact;
        OutPutOption: Option "No of Opportunities","Estimated Value (LCY)","Calc. Current Value (LCY)","Avg. Estimated Value (LCY)","Avg. Calc. Current Value (LCY)";
        ContactNo: Code[20];
    begin
        // Test Opportunity matrix with Show as Lines SalesPerson and Show as Estimated Value (LCY) after creation and updation of
        // Opportunity for Contact with Salesperson.

        // 1. Setup: Create Salesperson, Contact with Salesperson, Sales Cycle, Sales Cycle Stage, Create and Update Opportunity for
        // Contact.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        ContactNo := CreateContactWithSalesperson(SalespersonPurchaser.Code);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Assign global variable for page handler.
        SalesCycleCode := SalesCycle.Code;
        CurrentSalesCycleStage := CreateSalesCycleStage(SalesCycle.Code);
        No := SalespersonPurchaser.Code;
        CreateAndUpdateOpportunity(ContactNo);
        EstimatedValue := CalculateEstimatedValue(ContactNo);

        // 2. Exercise: Run Show Matrix from Opportunities page with Show as Lines Salesperson and Show as Estimated Value (LCY).
        Opportunities.OpenEdit();
        Opportunities.TableOption.SetValue(TableOption::SalesPerson);
        Opportunities.OutPutOption.SetValue(OutPutOption::"Estimated Value (LCY)");
        Opportunities.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Opportunities Matrix performed on Opportunities Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,HandlerForOpportunityValue')]
    [Scope('OnPrem')]
    procedure OpportunityAsCurrentValueLCY()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesCycle: Record "Sales Cycle";
        Opportunities: TestPage Opportunities;
        TableOption: Option SalesPerson,Campaign,Contact;
        OutPutOption: Option "No of Opportunities","Estimated Value (LCY)","Calc. Current Value (LCY)","Avg. Estimated Value (LCY)","Avg. Calc. Current Value (LCY)";
        ContactNo: Code[20];
    begin
        // Test Opportunity matrix with Show as Lines SalesPerson and Show as Calc. Current Value (LCY) after creation and updation of
        // Opportunity for Contact with Salesperson.

        // 1. Setup: Create Salesperson, Contact with Salesperson, Sales Cycle, Sales Cycle Stage, Create and Update Opportunity for
        // Contact.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        ContactNo := CreateContactWithSalesperson(SalespersonPurchaser.Code);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Assign global variable for page handler.
        SalesCycleCode := SalesCycle.Code;
        CurrentSalesCycleStage := CreateSalesCycleStage(SalesCycle.Code);
        No := SalespersonPurchaser.Code;

        CreateAndUpdateOpportunity(ContactNo);
        EstimatedValue := CalculateCurrentValue(ContactNo);  // Assign global variable for page handler.

        // 2. Exercise: Run Show Matrix from Opportunities page with Show as Lines Salesperson and Show as Calc. Current Value (LCY).
        Opportunities.OpenEdit();
        Opportunities.TableOption.SetValue(TableOption::SalesPerson);
        Opportunities.OutPutOption.SetValue(OutPutOption::"Calc. Current Value (LCY)");
        Opportunities.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Opportunities Matrix performed on Opportunities Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,HandlerForOpportunityValue')]
    [Scope('OnPrem')]
    procedure OpportunityAsAverageEstimated()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesCycle: Record "Sales Cycle";
        Opportunities: TestPage Opportunities;
        TableOption: Option SalesPerson,Campaign,Contact;
        OutPutOption: Option "No of Opportunities","Estimated Value (LCY)","Calc. Current Value (LCY)","Avg. Estimated Value (LCY)","Avg. Calc. Current Value (LCY)";
        ContactNo: Code[20];
    begin
        // Test Opportunity matrix with Show as Lines SalesPerson and Show as Avg. Estimated Value (LCY) after creation and updation of
        // Opportunities for Contact with Salesperson.

        // 1. Setup: Create Salesperson, Contact with Salesperson, Sales Cycle, Sales Cycle Stage, Create and Update Opportunities for
        // Contact.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        ContactNo := CreateContactWithSalesperson(SalespersonPurchaser.Code);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Assign global variable for page handler.
        SalesCycleCode := SalesCycle.Code;
        CurrentSalesCycleStage := CreateSalesCycleStage(SalesCycle.Code);
        No := SalespersonPurchaser.Code;

        CreateAndUpdateOpportunity(ContactNo);
        CreateAndUpdateOpportunity(ContactNo);

        // Assign global variable for page handler, use 2 for average value.
        EstimatedValue := CalculateEstimatedValue(ContactNo) / 2;

        // 2. Exercise: Run Show Matrix from Opportunities page with Show as Lines Salesperson and Show as Avg. Estimated Value (LCY).
        Opportunities.OpenEdit();
        Opportunities.TableOption.SetValue(TableOption::SalesPerson);
        Opportunities.OutPutOption.SetValue(OutPutOption::"Avg. Estimated Value (LCY)");
        Opportunities.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Opportunities Matrix performed on Opportunities Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,HandlerForOpportunityValue')]
    [Scope('OnPrem')]
    procedure OpportunityAsAverageCurrent()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesCycle: Record "Sales Cycle";
        Opportunities: TestPage Opportunities;
        TableOption: Option SalesPerson,Campaign,Contact;
        OutPutOption: Option "No of Opportunities","Estimated Value (LCY)","Calc. Current Value (LCY)","Avg. Estimated Value (LCY)","Avg. Calc. Current Value (LCY)";
        ContactNo: Code[20];
    begin
        // Test Opportunity matrix with Show as Lines SalesPerson and Show as Avg. Calc. Current Value (LCY) after creation and updation of
        // Opportunities for Contact with Salesperson.

        // 1. Setup: Create Salesperson, Contact with Salesperson, Sales Cycle, Sales Cycle Stage, Create and Update Opportunities for
        // Contact.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        ContactNo := CreateContactWithSalesperson(SalespersonPurchaser.Code);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Assign global variable for page handler.
        SalesCycleCode := SalesCycle.Code;
        CurrentSalesCycleStage := CreateSalesCycleStage(SalesCycle.Code);
        No := SalespersonPurchaser.Code;

        CreateAndUpdateOpportunity(ContactNo);
        CreateAndUpdateOpportunity(ContactNo);

        // Assign global variable for page handler, use 2 for average value.
        EstimatedValue := CalculateCurrentValue(ContactNo) / 2;

        // 2. Exercise: Run Show Matrix from Opportunities page with Show as Lines Salesperson and Show as Avg. Calc. Current Value (LCY).
        Opportunities.OpenEdit();
        Opportunities.TableOption.SetValue(TableOption::SalesPerson);
        Opportunities.OutPutOption.SetValue(OutPutOption::"Avg. Calc. Current Value (LCY)");
        Opportunities.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Opportunities Matrix performed on Opportunities Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,ModalPageCloseOpportunityWon,MessageHandler,HandlerForNoOfOpportunities')]
    [Scope('OnPrem')]
    procedure OpportunityWithActionWon()
    var
        OptionStatusFilter: Option "In Progress",Won,Lost;
    begin
        // Test Opportunity matrix with Show as Lines SalesPerson and Status filter as Won after closing the Opportunity as Won action.

        OpportunityWithAction(OptionStatusFilter::Won);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerOpportunity,PageHandlerUpdateOpportunity,ModalPageCloseOpportunityLost,HandlerForNoOfOpportunities')]
    [Scope('OnPrem')]
    procedure OpportunityWithActionLost()
    var
        OptionStatusFilter: Option "In Progress",Won,Lost;
    begin
        // Test Opportunity matrix with Show as Lines SalesPerson and Status filter as Lost after closing the Opportunity as Lost action.

        OpportunityWithAction(OptionStatusFilter::Lost);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask,TasksMatrixHandlerWithContactNo')]
    [Scope('OnPrem')]
    procedure CheckContactNumberOnTaskMatrix()
    var
        Task: Record "To-do";
    begin
        // Check Program populates Contact No. on Task Matrix.
        Initialize();
        TaskShowMatrix(CreateContactAndTask(Task), Task."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTaskShowMatrix,TasksMatrixHandlerWithContactNo')]
    [Scope('OnPrem')]
    procedure CheckContactNumberOnTaskMatrixwithZeroContactNo()
    var
        Task: Record "To-do";
    begin
        // Check Program Do not populates Contact No. on Task Matrix.
        Initialize();
        Task.CreateTaskFromTask(Task);
        TaskShowMatrix('', Task."No.");
    end;

    local procedure OpportunityWithAction(OptionStatusFilter: Option "In Progress",Won,Lost)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesCycle: Record "Sales Cycle";
        Opportunity: Record Opportunity;
        Opportunities: TestPage Opportunities;
        TableOption: Option SalesPerson,Campaign,Contact;
        OutPutOption: Option "No of Opportunities","Estimated Value (LCY)","Calc. Current Value (LCY)","Avg. Estimated Value (LCY)","Avg. Calc. Current Value (LCY)";
        ContactNo: Code[20];
    begin
        // 1. Setup: Create Salesperson, Contact with Salesperson, Sales Cycle, Sales Cycle Stage, Create, Update Opportunity for
        // Contact and Close the Opportunity.
        Initialize();
        CreateSalespersonWithEmail(SalespersonPurchaser);
        ContactNo := CreateContactWithSalesperson(SalespersonPurchaser.Code);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Assign global variable for page handler.
        SalesCycleCode := SalesCycle.Code;
        CurrentSalesCycleStage := CreateSalesCycleStage(SalesCycle.Code);
        No := SalespersonPurchaser.Code;

        CreateAndUpdateOpportunity(ContactNo);
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.CloseOpportunity();
        Commit();

        // 2. Exercise: Run Show Matrix from Opportunities page with Show as Lines Salesperson, Show as No of Opportunities and Status
        // filter as per parameter.
        Opportunities.OpenEdit();
        Opportunities.TableOption.SetValue(TableOption::SalesPerson);
        Opportunities.OutPutOption.SetValue(OutPutOption::"No of Opportunities");
        Opportunities.OptionStatusFilter.SetValue(OptionStatusFilter);
        Opportunities.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Opportunities Matrix performed on Opportunities Matrix page handler.

        // 4. Teardown: Rollback the Status filter on Opportunities page.
        Opportunities.OptionStatusFilter.SetValue(OptionStatusFilter::"In Progress");
    end;

    local procedure CalculateCurrentValue(ContactNo: Code[20]) CurrentValue: Decimal
    var
        OpportunityEntry: Record "Opportunity Entry";
    begin
        OpportunityEntry.SetRange("Contact No.", ContactNo);
        OpportunityEntry.FindSet();
        repeat
            CurrentValue += OpportunityEntry."Calcd. Current Value (LCY)";
        until OpportunityEntry.Next() = 0;
    end;

    local procedure CalculateEstimatedValue(ContactNo: Code[20]) EstimatedValue: Decimal
    var
        OpportunityEntry: Record "Opportunity Entry";
    begin
        OpportunityEntry.SetRange("Contact No.", ContactNo);
        OpportunityEntry.FindSet();
        repeat
            EstimatedValue += OpportunityEntry."Estimated Value (LCY)";
        until OpportunityEntry.Next() = 0;
    end;

    local procedure ChangeStatusOfTask(Task: Record "To-do"; Status: Enum "Task Status")
    begin
        Task.Validate(Status, Status);
        Task.Modify(true);
    end;

    local procedure CreateAndUpdateOpportunity(ContactNo: Code[20])
    var
        TempOpportunity: Record Opportunity temporary;
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        TempOpportunity.CreateOppFromOpp(Opportunity);

        Opportunity.FindLast();
        Opportunity.UpdateOpportunity();
        Commit();
    end;

    local procedure CreateCampaign(SalespersonCode: Code[20]): Code[20]
    var
        Campaign: Record Campaign;
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Salesperson Code", SalespersonCode);
        Campaign.Modify(true);
        exit(Campaign."No.");
    end;

    local procedure CreateContactWithSalesperson(SalespersonCode: Code[20]): Code[20]
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Salesperson Code", SalespersonCode);
        Contact.Modify(true);
        exit(Contact."No.");
    end;

    local procedure CreateSalesCycleStage(SalesCycleCode: Code[10]): Integer
    var
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        LibraryMarketing.CreateSalesCycleStage(SalesCycleStage, SalesCycleCode);

        // Use Random for Completed %.
        SalesCycleStage.Validate("Completed %", LibraryRandom.RandDec(99, 2));
        SalesCycleStage.Validate("Chances of Success %", LibraryRandom.RandDec(99, 2));
        SalesCycleStage.Validate("Activity Code", FindActivityCode());
        SalesCycleStage.Modify(true);
        exit(SalesCycleStage.Stage);
    end;

    local procedure CreateSalespersonWithEmail(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        SalespersonPurchaser.Modify(true);
    end;

    local procedure CreateContactAndTask(var TempTask: Record "To-do" temporary): Code[20]
    var
        Contact: Record Contact;
        Task: Record "To-do";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);

        Task.SetRange("Contact No.", Contact."No.");
        TempTask.CreateTaskFromTask(Task);
        exit(Contact."No.");
    end;

    local procedure FindActivityCode(): Code[10]
    var
        Activity: Record Activity;
    begin
        LibraryMarketing.CreateActivity(Activity);
        exit(Activity.Code);
    end;

    local procedure FindCloseOpportunityCode(Type: Option): Code[10]
    var
        CloseOpportunityCode: Record "Close Opportunity Code";
    begin
        LibraryMarketing.CreateCloseOpportunityCode(CloseOpportunityCode);
        CloseOpportunityCode.Validate(Type, Type);
        CloseOpportunityCode.Modify(true);
        exit(CloseOpportunityCode.Code);
    end;

    local procedure InitGlobalVariables()
    begin
        SalesCycleCode := '';
        CurrentSalesCycleStage := 0;
        No := '';
        EstimatedValue := 0;
    end;

    local procedure OpportunityClose(var OpportunityEntry: Record "Opportunity Entry"; CloseOpportunityCode: Code[10]; ActionTaken: Option)
    begin
        OpportunityEntry.Validate("Action Taken", ActionTaken);
        OpportunityEntry.Validate("Close Opportunity Code", CloseOpportunityCode);

        // Use Random for Calcd. Current Value (LCY).
        OpportunityEntry.Validate("Calcd. Current Value (LCY)", LibraryRandom.RandDec(1000, 2));
        OpportunityEntry.CheckStatus();
        OpportunityEntry.FinishWizard();
    end;

    local procedure OpenShowMatrixTask(FilterContactNo: Code[20])
    var
        Tasks: TestPage Tasks;
        OutputOption: Option "No. of To-dos","Contact No.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        Commit();
        Tasks.OpenEdit();
        Tasks.OutputOption.SetValue(OutputOption::"Contact No.");
        Tasks.PeriodType.SetValue(PeriodType::Day);
        Tasks.FilterContact.SetValue(FilterContactNo);
        Tasks.ShowMatrix.Invoke();
    end;

    local procedure TaskShowMatrix(ContactNoOnMatrix: Code[20]; TaskNo: Code[20])
    begin
        // Setup: Create Contact and Task.
        LibraryVariableStorage.Enqueue(ContactNoOnMatrix);
        LibraryVariableStorage.Enqueue(TaskNo);

        // Exercise: Open Task Show Matrix.
        OpenShowMatrixTask(ContactNoOnMatrix);

        // Verify: Verify value on TasksMatrixHandlerWithContactNo.
    end;

    local procedure UpdateCampaignOnOpportunity(var Opportunity: Record Opportunity; CampaignNo: Code[20])
    begin
        Opportunity.FindFirst();
        Opportunity.Validate("Campaign No.", CampaignNo);
        Opportunity.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandlerForNoOfOpportunities(var OpportunitiesMatrix: TestPage "Opportunities Matrix")
    begin
        OpportunitiesMatrix.FindFirstField("No.", No);
        OpportunitiesMatrix.Field1.AssertEquals(1);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandlerForOpportunityValue(var OpportunitiesMatrix: TestPage "Opportunities Matrix")
    begin
        OpportunitiesMatrix.FindFirstField("No.", No);
        OpportunitiesMatrix.Field1.AssertEquals(EstimatedValue);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageCloseOpportunityLost(var CloseOpportunity: Page "Close Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        CloseOpportunityCode: Record "Close Opportunity Code";
        ActionTaken: Option " ",Next,Previous,Updated,Jumped,Won,Lost;
    begin
        TempOpportunityEntry.Init();
        CloseOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        OpportunityClose(TempOpportunityEntry, FindCloseOpportunityCode(CloseOpportunityCode.Type::Lost), ActionTaken::Lost);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageCloseOpportunityWon(var CloseOpportunity: Page "Close Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        CloseOpportunityCode: Record "Close Opportunity Code";
        ActionTaken: Option " ",Next,Previous,Updated,Jumped,Won,Lost;
    begin
        TempOpportunityEntry.Init();
        CloseOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        OpportunityClose(TempOpportunityEntry, FindCloseOpportunityCode(CloseOpportunityCode.Type::Won), ActionTaken::Won);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerForTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate(
          Description,
          CopyStr(
            LibraryUtility.GenerateRandomCode(TempTask.FieldNo(Description), DATABASE::"To-do"),
            1, LibraryUtility.GetFieldLength(DATABASE::"To-do", TempTask.FieldNo(Description))));
        TempTask.Validate(Date, WorkDate());

        TempTask.Modify();
        TempTask.CheckStatus();
        TempTask.FinishWizard(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerOpportunity(var CreateOpportunity: Page "Create Opportunity"; var Response: Action)
    var
        TempOpportunity: Record Opportunity temporary;
    begin
        TempOpportunity.Init();
        CreateOpportunity.GetRecord(TempOpportunity);
        TempOpportunity.Insert();
        TempOpportunity.Validate(Description, TempOpportunity."Contact No.");
        TempOpportunity.Validate("Sales Cycle Code", SalesCycleCode);

        TempOpportunity.CheckStatus();
        TempOpportunity.FinishWizard();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerForTaskShowMatrix(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate(
          Description,
          CopyStr(
            LibraryUtility.GenerateRandomCode(TempTask.FieldNo(Description), DATABASE::"To-do"),
            1, LibraryUtility.GetFieldLength(DATABASE::"To-do", TempTask.FieldNo(Description))));
        TempTask.Validate(Date, WorkDate());
        TempTask.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandlerUpdateOpportunity(var UpdateOpportunity: Page "Update Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
    begin
        TempOpportunityEntry.Init();
        UpdateOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.CreateStageList();
        TempOpportunityEntry.Validate("Action Type", TempOpportunityEntry."Action Type"::First);
        TempOpportunityEntry.Validate("Sales Cycle Stage", CurrentSalesCycleStage);

        // Use Random for Estimated Value (LCY) and Chances of Success %.
        TempOpportunityEntry.Validate("Estimated Value (LCY)", LibraryRandom.RandDec(100, 2));
        TempOpportunityEntry.Validate("Chances of Success %", LibraryRandom.RandDec(99, 2));
        TempOpportunityEntry.Validate("Estimated Close Date", WorkDate());
        TempOpportunityEntry.Modify();

        TempOpportunityEntry.CheckStatus2();
        TempOpportunityEntry.FinishWizard2();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TasksMatrixHandlerWithContactNo(var TasksMatrix: TestPage "Tasks Matrix")
    var
        ContactNo: Variant;
        TaskNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ContactNo);
        LibraryVariableStorage.Dequeue(TaskNo);
        TasksMatrix.FILTER.SetFilter("No.", TaskNo);
        TasksMatrix.Field1.AssertEquals(ContactNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TasksMatrixHandlerWithoutValue(var TasksMatrix: TestPage "Tasks Matrix")
    begin
        TasksMatrix.Field1.AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TasksMatrixHandlerWithValue(var TasksMatrix: TestPage "Tasks Matrix")
    begin
        TasksMatrix.Field1.AssertEquals(1);
    end;
}

