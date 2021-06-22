page 88 "Job Card"
{
    Caption = 'Job Card';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Prices,WIP,Navigate,Job,Print/Send';
    RefreshOnActivate = true;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a short description of the job.';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the customer who pays for the job.';

                    trigger OnValidate()
                    begin
                        BilltoCustomerNoOnAfterValidat;
                    end;
                }
                field("Bill-to Contact No."; "Bill-to Contact No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                field("Bill-to Name"; "Bill-to Name")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the customer who pays for the job.';
                }
                field("Bill-to Address"; "Bill-to Address")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the address of the customer to whom you will send the invoice.';
                }
                field("Bill-to Address 2"; "Bill-to Address 2")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies an additional line of the address.';
                }
                group(Control56)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field("Bill-to County"; "Bill-to County")
                    {
                        ApplicationArea = Jobs;
                        QuickEntry = false;
                        ToolTip = 'Specifies the county code of the customer''s billing address.';
                    }
                }
                field("Bill-to Post Code"; "Bill-to Post Code")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the postal code of the customer who pays for the job.';
                }
                field("Bill-to City"; "Bill-to City")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the city of the address.';
                }
                field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the country/region code of the customer''s billing address.';

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
                    end;
                }
                field("Bill-to Contact"; "Bill-to Contact")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the customer who pays for the job.';
                }
                field("Search Description"; "Search Description")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional description of the job for searching purposes.';
                }
                field("Person Responsible"; "Person Responsible")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the person at your company who is responsible for the job.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies when the job card was last modified.';
                }
                field("Project Manager"; "Project Manager")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the person who is assigned to manage the job.';
                    Visible = JobSimplificationAvailable;
                }
            }
            part(JobTaskLines; "Job Task Lines Subform")
            {
                ApplicationArea = Jobs;
                Caption = 'Tasks';
                SubPageLink = "Job No." = FIELD("No.");
                SubPageView = SORTING("Job Task No.")
                              ORDER(Ascending);
            }
            group(Posting)
            {
                Caption = 'Posting';
                field(Status; Status)
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies a current status of the job. You can change the status for the job as it progresses. Final calculations can be made on completed jobs.';

                    trigger OnValidate()
                    begin
                        if (Status = Status::Completed) and Complete then begin
                            RecalculateJobWIP;
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field("Job Posting Group"; "Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting group that links transactions made for the job with the appropriate general ledger accounts according to the general posting setup.';
                }
                field("WIP Method"; "WIP Method")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies the method that is used to calculate the value of work in process for the job.';
                }
                field("WIP Posting Method"; "WIP Posting Method")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies how WIP posting is performed. Per Job: The total WIP costs and the sales value is used to calculate WIP. Per Job Ledger Entry: The accumulated values of WIP costs and sales are used to calculate WIP.';
                }
                field("Allow Schedule/Contract Lines"; "Allow Schedule/Contract Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Allow Budget/Billable Lines';
                    Importance = Additional;
                    ToolTip = 'Specifies if you can add planning lines of both type Budget and type Billable to the job.';
                }
                field("Apply Usage Link"; "Apply Usage Link")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies whether usage entries, from the job journal or purchase line, for example, are linked to job planning lines. Select this check box if you want to be able to track the quantities and amounts of the remaining work needed to complete a job and to create a relationship between demand planning, usage, and sales. On a job card, you can select this check box if there are no existing job planning lines that include type Budget that have been posted. The usage link only applies to job planning lines that include type Budget.';
                }
                field("% Completed"; PercentCompleted)
                {
                    ApplicationArea = Jobs;
                    Caption = '% Completed';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the job''s estimated resource usage that has been posted as used.';
                }
                field("% Invoiced"; PercentInvoiced)
                {
                    ApplicationArea = Jobs;
                    Caption = '% Invoiced';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the job''s invoice value that has been posted as invoiced.';
                }
                field("% of Overdue Planning Lines"; PercentOverdue)
                {
                    ApplicationArea = Jobs;
                    Caption = '% of Overdue Planning Lines';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the percentage of the job''s planning lines where the planned delivery date has been exceeded.';
                }
            }
            group(Duration)
            {
                Caption = 'Duration';
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date on which the job actually starts.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date on which the job is expected to be completed.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date on which you set up the job.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the job. By default, the currency code is empty. If you enter a foreign currency code, it results in the job being planned and invoiced in that currency.';
                }
                field("Invoice Currency Code"; "Invoice Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code you want to apply when creating invoices for a job. By default, the invoice currency code for a job is based on what currency code is defined on the customer card.';
                }
                field("Exch. Calculation (Cost)"; "Exch. Calculation (Cost)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how job costs are calculated if you change the Currency Date or the Currency Code fields on a job planning Line or run the Change Job Planning Line Dates batch job. Fixed LCY option: The job costs in the local currency are fixed. Any change in the currency exchange rate will change the value of job costs in a foreign currency. Fixed FCY option: The job costs in a foreign currency are fixed. Any change in the currency exchange rate will change the value of job costs in the local currency.';
                }
                field("Exch. Calculation (Price)"; "Exch. Calculation (Price)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how job sales prices are calculated if you change the Currency Date or the Currency Code fields on a job planning Line or run the Change Job Planning Line Dates batch job. Fixed LCY option: The job prices in the local currency are fixed. Any change in the currency exchange rate will change the value of job prices in a foreign currency. Fixed FCY option: The job prices in a foreign currency are fixed. Any change in the currency exchange rate will change the value of job prices in the local currency.';
                }
            }
            group("WIP and Recognition")
            {
                Caption = 'WIP and Recognition';
                group("To Post")
                {
                    Caption = 'To Post';
                    field("WIP Posting Date"; "WIP Posting Date")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the posting date that was entered when the Job Calculate WIP batch job was last run.';
                    }
                    field("Total WIP Sales Amount"; "Total WIP Sales Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the total WIP sales amount that was last calculated for the job. The WIP sales amount is the value in the WIP Sales Job WIP Entries window minus the value of the Recognized Sales Job WIP Entries window. For jobs with the Cost Value or Cost of Sales WIP methods, the WIP sales amount is normally 0.';
                    }
                    field("Applied Sales G/L Amount"; "Applied Sales G/L Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the sum of all applied sales in the general ledger that are related to the job.';
                        Visible = false;
                    }
                    field("Total WIP Cost Amount"; "Total WIP Cost Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the total WIP cost amount that was last calculated for the job. The WIP cost amount is the value in the WIP Cost Job WIP Entries window minus the value of the Recognized Cost Job WIP Entries window. For jobs with Sales Value or Percentage of Completion WIP methods, the WIP cost amount is normally 0.';
                    }
                    field("Applied Costs G/L Amount"; "Applied Costs G/L Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the sum of all applied costs that is based on to the selected job in the general ledger.';
                        Visible = false;
                    }
                    field("Recog. Sales Amount"; "Recog. Sales Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the recognized sales amount that was last calculated for the job, which is the sum of the Recognized Sales Job WIP Entries.';
                    }
                    field("Recog. Costs Amount"; "Recog. Costs Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the recognized cost amount that was last calculated for the job. The value is the sum of the entries in the Recognized Cost Job WIP Entries window.';
                    }
                    field("Recog. Profit Amount"; CalcRecognizedProfitAmount)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Recog. Profit Amount';
                        ToolTip = 'Specifies the recognized profit amount for the job.';
                    }
                    field("Recog. Profit %"; CalcRecognizedProfitPercentage)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Recog. Profit %';
                        ToolTip = 'Specifies the recognized profit percentage for the job.';
                    }
                    field("Acc. WIP Costs Amount"; CalcAccWIPCostsAmount)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Acc. WIP Costs Amount';
                        ToolTip = 'Specifies the total WIP costs for the job.';
                        Visible = false;
                    }
                    field("Acc. WIP Sales Amount"; CalcAccWIPSalesAmount)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Acc. WIP Sales Amount';
                        ToolTip = 'Specifies the total WIP sales for the job.';
                        Visible = false;
                    }
                    field("Calc. Recog. Sales Amount"; "Calc. Recog. Sales Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the sum of the recognized sales amount that is associated with job tasks for the job.';
                        Visible = false;
                    }
                    field("Calc. Recog. Costs Amount"; "Calc. Recog. Costs Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the sum of the recognized costs amount that is associated with job tasks for the job.';
                        Visible = false;
                    }
                }
                group(Posted)
                {
                    Caption = 'Posted';
                    field("WIP G/L Posting Date"; "WIP G/L Posting Date")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the posting date that was entered when the Job Post WIP to General Ledger batch job was last run.';
                    }
                    field("Total WIP Sales G/L Amount"; "Total WIP Sales G/L Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the total WIP sales amount that was last posted to the general ledger for the job. The WIP sales amount is the value in the WIP Sales Job WIP G/L Entries window minus the value in the Recognized Sales Job WIP G/L Entries window. For jobs with the Cost Value or Cost of Sales WIP methods, the WIP sales amount is normally 0.';
                    }
                    field("Total WIP Cost G/L Amount"; "Total WIP Cost G/L Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the total WIP Cost amount that was last posted to the G/L for the job. The WIP Cost Amount for the job is the value WIP Cost Job WIP G/L Entries less the value of the Recognized Cost Job WIP G/L Entries. For jobs with WIP Methods of Sales Value or Percentage of Completion, the WIP Cost Amount is normally 0.';
                    }
                    field("Recog. Sales G/L Amount"; "Recog. Sales G/L Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the total recognized sales amount that was last posted to the general ledger for the job. The recognized sales G/L amount for the job is the sum of the entries in the Recognized Sales Job WIP G/L Entries window.';
                    }
                    field("Recog. Costs G/L Amount"; "Recog. Costs G/L Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the total Recognized Cost amount that was last posted to the general ledger for the job. The Recognized Cost G/L amount for the job is the sum of the Recognized Cost Job WIP G/L Entries.';
                    }
                    field("Recog. Profit G/L Amount"; CalcRecognizedProfitGLAmount)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Recog. Profit G/L Amount';
                        ToolTip = 'Specifies the profit amount that is recognized with the general ledger for the job.';
                    }
                    field("Recog. Profit G/L %"; CalcRecognProfitGLPercentage)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Recog. Profit G/L %';
                        ToolTip = 'Specifies the profit percentage that is recognized with the general ledger for the job.';
                    }
                    field("Calc. Recog. Sales G/L Amount"; "Calc. Recog. Sales G/L Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the sum of the recognized sales general ledger amount that is associated with job tasks for the job.';
                        Visible = false;
                    }
                    field("Calc. Recog. Costs G/L Amount"; "Calc. Recog. Costs G/L Amount")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the sum of the recognized costs general ledger amount that is associated with job tasks for the job.';
                        Visible = false;
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = FIELD("Bill-to Customer No.");
                Visible = false;
            }
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(167),
                              "No." = FIELD("No.");
            }
            part(Control1902136407; "Job No. of Prices FactBox")
            {
                ApplicationArea = Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Resource Filter" = FIELD("Resource Filter"),
                              "Posting Date Filter" = FIELD("Posting Date Filter"),
                              "Resource Gr. Filter" = FIELD("Resource Gr. Filter"),
                              "Planning Date Filter" = FIELD("Planning Date Filter");
                Visible = true;
            }
            part(Control1905650007; "Job WIP/Recognition FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = FIELD("No."),
                              "Resource Filter" = FIELD("Resource Filter"),
                              "Posting Date Filter" = FIELD("Posting Date Filter"),
                              "Resource Gr. Filter" = FIELD("Resource Gr. Filter"),
                              "Planning Date Filter" = FIELD("Planning Date Filter");
                Visible = false;
            }
            part("Job Details"; "Job Cost Factbox")
            {
                ApplicationArea = Jobs;
                Caption = 'Job Details';
                SubPageLink = "No." = FIELD("No.");
                Visible = JobSimplificationAvailable;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = true;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Job")
            {
                Caption = '&Job';
                Image = Job;
                action(JobPlanningLines)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job &Planning Lines';
                    Image = JobLines;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'View all planning lines for the job. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a job (Budget) or you can specify what you actually agreed with your customer that he should pay for the job (Billable).';

                    trigger OnAction()
                    var
                        JobPlanningLine: Record "Job Planning Line";
                        JobPlanningLines: Page "Job Planning Lines";
                    begin
                        TestField("No.");
                        JobPlanningLine.FilterGroup(2);
                        JobPlanningLine.SetRange("Job No.", "No.");
                        JobPlanningLine.FilterGroup(0);
                        JobPlanningLines.SetJobTaskNoVisible(true);
                        JobPlanningLines.SetTableView(JobPlanningLine);
                        JobPlanningLines.Editable := true;
                        JobPlanningLines.Run;
                    end;
                }
                action("&Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(167),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
                }
                action("&Statistics")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    RunObject = Page "Job Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View this job''s statistics.';
                }
                separator(Action64)
                {
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category7;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Job),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("&Online Map")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Online Map';
                    Image = Map;
                    ToolTip = 'View online map for addresses assigned to this job.';

                    trigger OnAction()
                    begin
                        DisplayMap;
                    end;
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal;
                    end;
                }
            }
            group("W&IP")
            {
                Caption = 'W&IP';
                Image = WIP;
                action("&WIP Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = '&WIP Entries';
                    Image = WIPEntries;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Job WIP Entries";
                    RunPageLink = "Job No." = FIELD("No.");
                    RunPageView = SORTING("Job No.", "Job Posting Group", "WIP Posting Date")
                                  ORDER(Descending);
                    ToolTip = 'View entries for the job that are posted as work in process.';
                }
                action("WIP &G/L Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'WIP &G/L Entries';
                    Image = WIPLedger;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Job WIP G/L Entries";
                    RunPageLink = "Job No." = FIELD("No.");
                    RunPageView = SORTING("Job No.")
                                  ORDER(Descending);
                    ToolTip = 'View the job''s WIP G/L entries.';
                }
            }
            group("&Prices")
            {
                Caption = '&Prices';
                Image = Price;
                action("&Resource")
                {
                    ApplicationArea = Suite;
                    Caption = '&Resource';
                    Image = Resource;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Job Resource Prices";
                    RunPageLink = "Job No." = FIELD("No.");
                    ToolTip = 'View this job''s resource prices.';
                }
                action("&Item")
                {
                    ApplicationArea = Suite;
                    Caption = '&Item';
                    Image = Item;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Job Item Prices";
                    RunPageLink = "Job No." = FIELD("No.");
                    ToolTip = 'View this job''s item prices.';
                }
                action("&G/L Account")
                {
                    ApplicationArea = Suite;
                    Caption = '&G/L Account';
                    Image = JobPrice;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Job G/L Account Prices";
                    RunPageLink = "Job No." = FIELD("No.");
                    ToolTip = 'View this job''s G/L account prices.';
                }
            }
            group("Plan&ning")
            {
                Caption = 'Plan&ning';
                Image = Planning;
                action("Resource &Allocated per Job")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource &Allocated per Job';
                    Image = ViewJob;
                    RunObject = Page "Resource Allocated per Job";
                    ToolTip = 'View this job''s resource allocation.';
                }
                action("Res. Gr. All&ocated per Job")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Res. Gr. All&ocated per Job';
                    Image = ResourceGroup;
                    RunObject = Page "Res. Gr. Allocated per Job";
                    ToolTip = 'View the job''s resource group allocation.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ledger E&ntries';
                    Image = JobLedger;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Job No." = FIELD("No.");
                    RunPageView = SORTING("Job No.", "Job Task No.", "Entry Type", "Posting Date")
                                  ORDER(Descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(processing)
        {
            group("&Copy")
            {
                Caption = '&Copy';
                Image = Copy;
                action("Copy Job Tasks &from...")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Copy Job Tasks &from...';
                    Ellipsis = true;
                    Image = CopyToTask;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Open the Copy Job Tasks page.';

                    trigger OnAction()
                    var
                        CopyJobTasks: Page "Copy Job Tasks";
                    begin
                        CopyJobTasks.SetToJob(Rec);
                        CopyJobTasks.RunModal;
                    end;
                }
                action("Copy Job Tasks &to...")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Copy Job Tasks &to...';
                    Ellipsis = true;
                    Image = CopyFromTask;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Open the Copy Jobs To page.';

                    trigger OnAction()
                    var
                        CopyJobTasks: Page "Copy Job Tasks";
                    begin
                        CopyJobTasks.SetFromJob(Rec);
                        CopyJobTasks.RunModal;
                    end;
                }
            }
            group(Action26)
            {
                Caption = 'W&IP';
                Image = WIP;
                action("<Action82>")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Calculate WIP';
                    Ellipsis = true;
                    Image = CalculateWIP;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'Run the Job Calculate WIP batch job.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                    begin
                        TestField("No.");
                        Job.Copy(Rec);
                        Job.SetRange("No.", "No.");
                        REPORT.RunModal(REPORT::"Job Calculate WIP", true, false, Job);
                    end;
                }
                action("<Action83>")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Post WIP to G/L';
                    Ellipsis = true;
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Run the Job Post WIP to G/L batch job.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                    begin
                        TestField("No.");
                        Job.Copy(Rec);
                        Job.SetRange("No.", "No.");
                        REPORT.RunModal(REPORT::"Job Post WIP to G/L", true, false, Job);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Job Actual to Budget")
            {
                ApplicationArea = Suite;
                Caption = 'Job Actual to Budget';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Job Actual To Budget";
                ToolTip = 'Compare budgeted and usage amounts for selected jobs. All lines of the selected job show quantity, total cost, and line amount.';
            }
            action("Job Analysis")
            {
                ApplicationArea = Suite;
                Caption = 'Job Analysis';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Job Analysis";
                ToolTip = 'Analyze the job, such as the budgeted prices, usage prices, and billable prices, and then compares the three sets of prices.';
            }
            action("Job - Planning Lines")
            {
                ApplicationArea = Suite;
                Caption = 'Job - Planning Lines';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Job - Planning Lines";
                ToolTip = 'View all planning lines for the job. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a job (budget) or you can specify what you actually agreed with your customer that he should pay for the job (billable).';
            }
            action("Job - Suggested Billing")
            {
                ApplicationArea = Suite;
                Caption = 'Job - Suggested Billing';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Job Suggested Billing";
                ToolTip = 'View a list of all jobs, grouped by customer, how much the customer has already been invoiced, and how much remains to be invoiced, that is, the suggested billing.';
            }
            action("Report Job Quote")
            {
                ApplicationArea = Suite;
                Caption = 'Preview Job Quote';
                Image = "Report";
                Promoted = true;
                PromotedCategory = Category8;
                ToolTip = 'Open the Job Quote report.';

                trigger OnAction()
                var
                    Job: Record Job;
                begin
                    Job.SetCurrentKey("No.");
                    Job.SetFilter("No.", "No.");
                    REPORT.Run(REPORT::"Job Quote", true, false, Job);
                end;
            }
            action("Send Job Quote")
            {
                ApplicationArea = Suite;
                Caption = 'Send Job Quote';
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Category8;
                ToolTip = 'Send the job quote to the customer. You can change the way that the document is sent in the window that appears.';

                trigger OnAction()
                begin
                    CODEUNIT.Run(CODEUNIT::"Jobs-Send", Rec);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        JobSimplificationAvailable := IsJobSimplificationAvailable;
    end;

    trigger OnOpenPage()
    begin
        SetNoFieldVisible;
        IsCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        JobSimplificationAvailable: Boolean;
        NoFieldVisible: Boolean;
        IsCountyVisible: Boolean;

    local procedure BilltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update;
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.JobNoIsVisible;
    end;
}

