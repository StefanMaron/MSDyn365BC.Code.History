page 9015 "Job Project Manager RC"
{
    Caption = 'Project Manager', Comment = '{Dependency=Match,"ProfileDescription_PROJECTMANAGER"}';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control102; "Headline RC Project Manager")
            {
                ApplicationArea = Jobs;
            }
            part(Control33; "Project Manager Activities")
            {
                ApplicationArea = Jobs;
            }
            part("User Tasks Activities"; "User Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = Jobs;
            }
            part(Control77; "Team Member Activities")
            {
                ApplicationArea = Suite;
            }
            part(Control34; "My Jobs")
            {
                ApplicationArea = Jobs;
            }
            part("Job Actual Price to Budget Price"; "Job Act to Bud Price Chart")
            {
                ApplicationArea = Jobs;
                Caption = 'Job Actual Price to Budget Price';
            }
            part("Job Profitability"; "Job Profitability Chart")
            {
                ApplicationArea = Jobs;
                Caption = 'Job Profitability';
            }
            part("Job Actual Cost to Budget Cost"; "Job Act to Bud Cost Chart")
            {
                ApplicationArea = Jobs;
                Caption = 'Job Actual Cost to Budget Cost';
            }
            part(Control1907692008; "My Customers")
            {
                ApplicationArea = Jobs;
                Editable = false;
                Enabled = false;
                Visible = false;
            }
            part("Power BI Report Spinner Part"; "Power BI Report Spinner Part")
            {
                AccessByPermission = TableData "Power BI User Configuration" = I;
                ApplicationArea = Basic, Suite;
            }
            part(Control21; "My Job Queue")
            {
                ApplicationArea = Jobs;
                Visible = false;
            }
            part(Control31; "Report Inbox Part")
            {
                ApplicationArea = Jobs;
                Visible = false;
            }
            systempart(Control1901377608; MyNotes)
            {
                ApplicationArea = Jobs;
                Visible = false;
            }
        }
    }

    actions
    {
        area(embedding)
        {
            action(Jobs)
            {
                ApplicationArea = Jobs;
                Caption = 'Jobs';
                Image = Job;
                RunObject = Page "Job List";
                ToolTip = 'Define a project activity by creating a job card with integrated job tasks and job planning lines, structured in two layers. The job task enables you to set up job planning lines and to post consumption to the job. The job planning lines specify the detailed use of resources, items, and various general ledger expenses.';
            }
            action(JobsOnOrder)
            {
                ApplicationArea = Jobs;
                Caption = 'Open';
                RunObject = Page "Job List";
                RunPageView = WHERE(Status = FILTER(Open));
                ToolTip = 'Open the card for the selected record.';
            }
            action(JobsPlannedAndQuoted)
            {
                ApplicationArea = Jobs;
                Caption = 'Planned and Quoted';
                RunObject = Page "Job List";
                RunPageView = WHERE(Status = FILTER(Quote | Planning));
                ToolTip = 'View all planned and quoted jobs.';
            }
            action(JobsCompleted)
            {
                ApplicationArea = Jobs;
                Caption = 'Completed';
                RunObject = Page "Job List";
                RunPageView = WHERE(Status = FILTER(Completed));
                ToolTip = 'View all completed jobs.';
            }
            action(JobsUnassigned)
            {
                ApplicationArea = Jobs;
                Caption = 'Unassigned';
                RunObject = Page "Job List";
                RunPageView = WHERE("Person Responsible" = FILTER(''));
                ToolTip = 'View all unassigned jobs.';
            }
            action("Job Tasks")
            {
                ApplicationArea = Suite;
                Caption = 'Job Tasks';
                RunObject = Page "Job Task List";
                ToolTip = 'Define the various tasks involved in a job. You must create at least one job task per job because all posting refers to a job task. Having at least one job task in your job enables you to set up job planning lines and to post consumption to the job.';
            }
            action(Customers)
            {
                ApplicationArea = Jobs;
                Caption = 'Customers';
                Image = Customer;
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(Items)
            {
                ApplicationArea = Jobs;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action(Resources)
            {
                ApplicationArea = Jobs;
                Caption = 'Resources';
                RunObject = Page "Resource List";
                ToolTip = 'Manage your resources'' job activities by setting up their costs and prices. The job-related prices, discounts, and cost factor rules are set up on the respective job card. You can specify the costs and prices for individual resources, resource groups, or all available resources of the company. When resources are used or sold in a job, the specified prices and costs are recorded for the project.';
            }
        }
        area(sections)
        {
            group("Sales & Purchases")
            {
                Caption = 'Sales & Purchases';
                action("Sales Invoices")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Sales Invoices';
                    Image = Invoice;
                    RunObject = Page "Sales Invoice List";
                    ToolTip = 'Register your sales to customers and invite them to pay according to the delivery and payment terms by sending them a sales invoice document. Posting a sales invoice registers shipment and records an open receivable entry on the customer''s account, which will be closed when payment is received. To manage the shipment process, use sales orders, in which sales invoicing is integrated.';
                }
                action("Sales Credit Memos")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Sales Credit Memos';
                    RunObject = Page "Sales Credit Memos";
                    ToolTip = 'Revert the financial transactions involved when your customers want to cancel a purchase or return incorrect or damaged items that you sent to them and received payment for. To include the correct information, you can create the sales credit memo from the related posted sales invoice or you can create a new sales credit memo with copied invoice information. If you need more control of the sales return process, such as warehouse documents for the physical handling, use sales return orders, in which sales credit memos are integrated. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
                }
                action("Purchase Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    RunObject = Page "Purchase Order List";
                    ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
                }
                action("Purchase Invoices")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Invoices';
                    RunObject = Page "Purchase Invoices";
                    ToolTip = 'Create purchase invoices to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase invoices dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase invoices can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
                }
                action("Purchase Credit Memos")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Credit Memos';
                    RunObject = Page "Purchase Credit Memos";
                    ToolTip = 'Create purchase credit memos to mirror sales credit memos that vendors send to you for incorrect or damaged items that you have paid for and then returned to the vendor. If you need more control of the purchase return process, such as warehouse documents for the physical handling, use purchase return orders, in which purchase credit memos are integrated. Purchase credit memos can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature. Note: If you have not yet paid for an erroneous purchase, you can simply cancel the posted purchase invoice to automatically revert the financial transaction.';
                }
            }
            group(Action2)
            {
                Caption = 'Jobs';
                Image = Job;
                ToolTip = 'Create, plan, and execute tasks in project management. ';
                action(Action90)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Jobs';
                    Image = Job;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Job List";
                    ToolTip = 'Define a project activity by creating a job card with integrated job tasks and job planning lines, structured in two layers. The job task enables you to set up job planning lines and to post consumption to the job. The job planning lines specify the detailed use of resources, items, and various general ledger expenses.';
                }
                action(Open)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Open';
                    RunObject = Page "Job List";
                    RunPageView = WHERE(Status = FILTER(Open));
                    ToolTip = 'Open the card for the selected record.';
                }
                action(JobsPlannedAndQuotd)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Planned and Quoted';
                    RunObject = Page "Job List";
                    RunPageView = WHERE(Status = FILTER(Quote | Planning));
                    ToolTip = 'Open the list of all planned and quoted jobs.';
                }
                action(JobsComplet)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Completed';
                    RunObject = Page "Job List";
                    RunPageView = WHERE(Status = FILTER(Completed));
                    ToolTip = 'Open the list of all completed jobs.';
                }
                action(JobsUnassign)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Unassigned';
                    RunObject = Page "Job List";
                    RunPageView = WHERE("Person Responsible" = FILTER(''));
                    ToolTip = 'Open the list of all unassigned jobs.';
                }
                action(Action3)
                {
                    ApplicationArea = Suite;
                    Caption = 'Job Tasks';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Job Task List";
                    ToolTip = 'Open the list of ongoing job tasks. Job tasks represent the actual work that is performed in a job, and they enable you to set up job planning lines and to post consumption to the job.';
                }
                action("Job Registers")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Registers';
                    Image = JobRegisters;
                    RunObject = Page "Job Registers";
                    ToolTip = 'View auditing details for all job ledger entries. Every time an entry is posted, a register is created in which you can see the first and last number of its entries in order to document when entries were posted.';
                }
                action("Job Planning Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Planning Lines';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Job Planning Lines";
                    ToolTip = 'Open the list of ongoing job planning lines for the job. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a job (budget) or you can specify what you actually agreed with your customer that he should pay for the job (billable).';
                }
                action(JobJournals)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Journals';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Job Journal Batches";
                    RunPageView = WHERE(Recurring = CONST(false));
                    ToolTip = 'Record job expenses or usage in the job ledger, either by reusing job planning lines or by manual entry.';
                }
                action(JobGLJournals)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job G/L Journals';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "General Journal Batches";
                    RunPageView = WHERE("Template Type" = CONST(Jobs),
                                        Recurring = CONST(false));
                    ToolTip = 'Record job expenses or usage in job accounts in the general ledger. For expenses or usage of type G/L Account, use the job G/L journal instead of the job journal.';
                }
                action(RecurringJobJournals)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recurring Job Journals';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Job Journal Batches";
                    RunPageView = WHERE(Recurring = CONST(true));
                    ToolTip = 'Reuse preset journal lines to record recurring job expenses or usage in the job ledger.';
                }
            }
            group(Action91)
            {
                Caption = 'Resources';
                Image = Journals;
                ToolTip = 'Manage the people or machines that are used to perform job tasks. ';
                action(Action93)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resources';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Resource List";
                    ToolTip = 'Manage your resources'' job activities by setting up their costs and prices. The job-related prices, discounts, and cost factor rules are set up on the respective job card. You can specify the costs and prices for individual resources, resource groups, or all available resources of the company. When resources are used or sold in a job, the specified prices and costs are recorded for the project.';
                }
                action("Resource Groups")
                {
                    ApplicationArea = Suite;
                    Caption = 'Resource Groups';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Resource Groups";
                    ToolTip = 'Organize resources in groups, such as Consultants, for easier assignment of common values and to analyze financial figures by groups.';
                }
                action(ResourceJournals)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Journals';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Resource Jnl. Batches";
                    RunPageView = WHERE(Recurring = CONST(false));
                    ToolTip = 'Post usage and sales of your resources for internal use and statistics. Use time sheet entries as input. Note that unlike with job journals, entries posted with resource journals are not posted to G/L accounts.';
                }
                action(RecurringResourceJournals)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recurring Resource Journals';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Resource Jnl. Batches";
                    RunPageView = WHERE(Recurring = CONST(true));
                    ToolTip = 'Post recurring usage and sales of your resources for internal use and statistics in a journal that is preset for your usual posting.';
                }
                action("Resource Registers")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Registers';
                    Image = ResourceRegisters;
                    RunObject = Page "Resource Registers";
                    ToolTip = 'View auditing details for all resource ledger entries. Every time an entry is posted, a register is created in which you can see the first and last number of its entries in order to document when entries were posted.';
                }
            }
            group(Journals)
            {
                Caption = 'Journals';
                Image = Journals;
                ToolTip = 'Post entries directly to G/L accounts.';
                action(ItemJournals)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Item Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = WHERE("Template Type" = CONST(Item),
                                        Recurring = CONST(false));
                    ToolTip = 'Post item transactions directly to the item ledger to adjust inventory in connection with purchases, sales, and positive or negative adjustments without using documents. You can save sets of item journal lines as standard journals so that you can perform recurring postings quickly. A condensed version of the item journal function exists on item cards for quick adjustment of an items inventory quantity.';
                }
                action(RecurringItemJournals)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recurring Item Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = WHERE("Template Type" = CONST(Item),
                                        Recurring = CONST(true));
                    ToolTip = 'Post recurring item transactions directly to the item ledger in a journal that is preset for your usual posting.';
                }
            }
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                ToolTip = 'View the posting history for sales, shipments, and inventory.';
                action("Posted Shipments")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posted Shipments';
                    RunObject = Page "Posted Sales Shipments";
                    ToolTip = 'Open the list of posted shipments.';
                }
                action("Posted Sales Invoices")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posted Sales Invoices';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Invoices";
                    ToolTip = 'Open the list of posted sales invoices.';
                }
                action("Posted Sales Credit Memos")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posted Sales Credit Memos';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Credit Memos";
                    ToolTip = 'Open the list of posted sales credit memos.';
                }
                action("Posted Purchase Receipts")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posted Purchase Receipts';
                    RunObject = Page "Posted Purchase Receipts";
                    ToolTip = 'Open the list of posted purchase receipts.';
                }
                action("Posted Purchase Invoices")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posted Purchase Invoices';
                    RunObject = Page "Posted Purchase Invoices";
                    ToolTip = 'Open the list of posted purchase credit memos.';
                }
                action("Posted Purchase Credit Memos")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posted Purchase Credit Memos';
                    RunObject = Page "Posted Purchase Credit Memos";
                    ToolTip = 'Open the list of posted purchase credit memos.';
                }
                action("G/L Registers")
                {
                    ApplicationArea = Jobs;
                    Caption = 'G/L Registers';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    ToolTip = 'View auditing details for all G/L entries. Every time an entry is posted, a register is created in which you can see the first and last number of its entries in order to document when entries were posted.';
                }
                action(Action74)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Registers';
                    Image = JobRegisters;
                    RunObject = Page "Job Registers";
                    ToolTip = 'View auditing details for all item ledger entries. Every time an entry is posted, a register is created in which you can see the first and last number of its entries in order to document when entries were posted.';
                }
                action("Item Registers")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Item Registers';
                    Image = ItemRegisters;
                    RunObject = Page "Item Registers";
                    ToolTip = 'View auditing details for all item ledger entries. Every time an entry is posted, a register is created in which you can see the first and last number of its entries in order to document when entries were posted.';
                }
                action(Action76)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Registers';
                    Image = ResourceRegisters;
                    RunObject = Page "Resource Registers";
                    ToolTip = 'View auditing details for all resource ledger entries. Every time an entry is posted, a register is created in which you can see the first and last number of its entries in order to document when entries were posted.';
                }
            }
            group(SetupAndExtensions)
            {
                Caption = 'Setup & Extensions';
                Image = Setup;
                ToolTip = 'Overview and change system and application settings, and manage extensions and services';
                action("Assisted Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assisted Setup';
                    Image = QuestionaireSetup;
                    RunObject = Page "Assisted Setup";
                    ToolTip = 'Set up core functionality such as sales tax, sending documents as email, and approval workflow by running through a few pages that guide you through the information.';
                }
                action("Manual Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Manual Setup';
                    RunObject = Page "Manual Setup";
                    ToolTip = 'Define your company policies for business departments and for general activities by filling setup windows manually.';
                }
                action("Service Connections")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service Connections';
                    Image = ServiceTasks;
                    RunObject = Page "Service Connections";
                    ToolTip = 'Enable and configure external services, such as exchange rate updates, Microsoft Social Engagement, and electronic bank integration.';
                }
                action(Extensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extensions';
                    Image = NonStockItemSetup;
                    RunObject = Page "Extension Management";
                    ToolTip = 'Install Extensions for greater functionality of the system.';
                }
                action(Workflows)
                {
                    ApplicationArea = Suite;
                    Caption = 'Workflows';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page Workflows;
                    ToolTip = 'Set up or enable workflows that connect business-process tasks performed by different users. System tasks, such as automatic posting, can be included as steps in workflows, preceded or followed by user tasks. Requesting and granting approval to create new records are typical workflow steps.';
                }
            }
        }
        area(processing)
        {
            group(NewGroup)
            {
                Caption = 'New';
                action("Page Job")
                {
                    AccessByPermission = TableData Job = IMD;
                    ApplicationArea = Jobs;
                    Caption = 'Job';
                    Image = Job;
                    Promoted = true;
                    PromotedCategory = New;
                    RunObject = Page "Job Creation Wizard";
                    RunPageMode = Create;
                    ToolTip = 'Create a new job.';
                }
                action("Job J&ournal")
                {
                    AccessByPermission = TableData "Job Journal Template" = IMD;
                    ApplicationArea = Jobs;
                    Caption = 'Job J&ournal';
                    Image = JobJournal;
                    Promoted = true;
                    PromotedCategory = New;
                    RunObject = Page "Job Journal";
                    ToolTip = 'Prepare to post a job activity to the job ledger.';
                }
                action("Job G/L &Journal")
                {
                    AccessByPermission = TableData "Gen. Journal Template" = IMD;
                    ApplicationArea = Jobs;
                    Caption = 'Job G/L &Journal';
                    Image = GLJournal;
                    Promoted = true;
                    PromotedCategory = New;
                    RunObject = Page "Job G/L Journal";
                    ToolTip = 'Prepare to post a job activity to the general ledger.';
                }
                action("R&esource Journal")
                {
                    AccessByPermission = TableData "Res. Journal Template" = IMD;
                    ApplicationArea = Suite;
                    Caption = 'R&esource Journal';
                    Image = ResourceJournal;
                    Promoted = true;
                    PromotedCategory = New;
                    RunObject = Page "Resource Journal";
                    ToolTip = 'Prepare to post resource usage.';
                }
                action("Job &Create Sales Invoice")
                {
                    AccessByPermission = TableData "Job Task" = IMD;
                    ApplicationArea = Jobs;
                    Caption = 'Job &Create Sales Invoice';
                    Image = CreateJobSalesInvoice;
                    RunObject = Report "Job Create Sales Invoice";
                    ToolTip = 'Use a function to automatically create a sales invoice for one or more jobs.';
                }
                action("Update Job I&tem Cost")
                {
                    ApplicationArea = Suite;
                    Caption = 'Update Job I&tem Cost';
                    Image = "Report";
                    RunObject = Report "Update Job Item Cost";
                    ToolTip = 'Use a function to automatically update the cost of items used in jobs.';
                }
            }
            group(Reports)
            {
                Caption = 'Reports';
                group("Job Reports")
                {
                    Caption = 'Job Reports';
                    Image = ReferenceData;
                    action("Job &Analysis")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job &Analysis';
                        Image = "Report";
                        RunObject = Report "Job Analysis";
                        ToolTip = 'Analyze your jobs. For example, you can create a report that shows you the scheduled prices, usage prices, and contract prices, and then compares the three sets of prices.';
                    }
                    action("Job Actual To &Budget")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Actual To &Budget';
                        Image = "Report";
                        RunObject = Report "Job Actual To Budget";
                        ToolTip = 'Compare scheduled and usage amounts for selected jobs. All lines of the selected job show quantity, total cost, and line amount.';
                    }
                    action("Job - Pla&nning Line")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job - Pla&nning Line';
                        Image = "Report";
                        RunObject = Report "Job - Planning Lines";
                        ToolTip = 'Define job tasks to capture any information that you want to track for a job. You can use planning lines to add information such as what resources are required or to capture what items are needed to perform the job.';
                    }
                    separator(Action16)
                    {
                    }
                    action("Job Su&ggested Billing")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Su&ggested Billing';
                        Image = "Report";
                        RunObject = Report "Job Suggested Billing";
                        ToolTip = 'View a list of all jobs, grouped by customer, how much the customer has already been invoiced, and how much remains to be invoiced, that is, the suggested billing.';
                    }
                    action("Jobs per &Customer")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Jobs per &Customer';
                        Image = "Report";
                        RunObject = Report "Jobs per Customer";
                        ToolTip = 'View a list of all jobs, grouped by customer where you can compare the scheduled price, the percentage of completion, the invoiced price, and the percentage of invoiced amounts for each bill-to customer.';
                    }
                    action("Items per &Job")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Items per &Job';
                        Image = "Report";
                        RunObject = Report "Items per Job";
                        ToolTip = 'View which items are used for which jobs.';
                    }
                    action("Jobs per &Item")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Jobs per &Item';
                        Image = "Report";
                        RunObject = Report "Jobs per Item";
                        ToolTip = 'View on which job a specific item is used.';
                    }
                }
                group("Absence Reports")
                {
                    Caption = 'Absence Reports';
                    Image = ReferenceData;
                    ToolTip = 'Analyze employee absence.';
                    action("Employee - Staff Absences")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee - Staff Absences';
                        Image = "Report";
                        RunObject = Report "Employee - Staff Absences";
                        ToolTip = 'View a list of employee absences by date. The list includes the cause of each employee absence.';
                    }
                    action("Employee - Absences by Causes")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee - Absences by Causes';
                        Image = "Report";
                        RunObject = Report "Employee - Absences by Causes";
                        ToolTip = 'View a list of all your employee absences categorized by absence code.';
                    }
                }
            }
            group(Manage)
            {
                Caption = 'Manage';
                group(Timesheet)
                {
                    Caption = 'Time Sheet';
                    Image = Worksheets;
                    action("Create Time Sheets")
                    {
                        AccessByPermission = TableData "Time Sheet Header" = IMD;
                        ApplicationArea = Jobs;
                        Caption = 'Create Time Sheets';
                        Image = JobTimeSheet;
                        RunObject = Report "Create Time Sheets";
                        ToolTip = 'As the time sheet administrator, create time sheets for resources that have the Use Time Sheet check box selected on the resource card. Afterwards, view the time sheets that you have created in the Time Sheets window.';
                    }
                    action("Manage Time Sheets")
                    {
                        AccessByPermission = TableData "Time Sheet Header" = IMD;
                        ApplicationArea = Jobs;
                        Caption = 'Manager Time Sheets';
                        Image = JobTimeSheet;
                        RunObject = Page "Manager Time Sheet";
                        ToolTip = 'Approve or reject your resources'' time sheet entries in a window that contains lines for all time sheets that resources have submitted for review.';
                    }
                    action("Manager Time Sheet by Job")
                    {
                        AccessByPermission = TableData "Time Sheet Line" = IMD;
                        ApplicationArea = Jobs;
                        Caption = 'Manager Time Sheet by Job';
                        Image = JobTimeSheet;
                        RunObject = Page "Manager Time Sheet by Job";
                        ToolTip = 'Open the list of time sheets for which your name is filled into the Person Responsible field on the related job card.';
                    }
                    separator(Action5)
                    {
                    }
                    separator(Action7)
                    {
                    }
                }
                group(WIP)
                {
                    Caption = 'Job Closing';
                    Image = Job;
                    ToolTip = 'Perform various post-processing of jobs.';
                    action("Job Calculate &WIP")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Calculate &WIP';
                        Image = CalculateWIP;
                        RunObject = Report "Job Calculate WIP";
                        ToolTip = 'Calculate the general ledger entries needed to update or close the job.';
                    }
                    action("Jo&b Post WIP to G/L")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Jo&b Post WIP to G/L';
                        Image = PostOrder;
                        RunObject = Report "Job Post WIP to G/L";
                        ToolTip = 'Post to the general ledger the entries calculated for your jobs.';
                    }
                    action("Job WIP")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Job WIP';
                        Image = WIP;
                        RunObject = Page "Job WIP Cockpit";
                        ToolTip = 'Overview and track work in process for all of your projects. Each line contains information about a job, including calculated and posted WIP.';
                    }
                }
            }
            group(History)
            {
                Caption = 'History';
                action("Navi&gate")
                {
                    ApplicationArea = Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    RunObject = Page Navigate;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                }
            }
        }
    }
}

