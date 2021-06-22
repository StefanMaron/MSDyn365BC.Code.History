page 1004 "Job Task List"
{
    Caption = 'Job Task List';
    CardPageID = "Job Task Card";
    DataCaptionFields = "Job No.";
    Editable = false;
    PageType = List;
    SourceTable = "Job Task";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related job.';
                }
                field("Job Task No."; "Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related job task.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the job task. You can enter anything that is meaningful in describing the task. The description is copied and used in descriptions on the job planning line.';
                }
                field("Job Task Type"; "Job Task Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the purpose of the account. Newly created accounts are automatically assigned the Posting account type, but you can change this. Choose the field to select one of the following five options:';
                }
                field("WIP-Total"; "WIP-Total")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the job tasks you want to group together when calculating Work In Process (WIP) and Recognition.';
                }
                field(Totaling; Totaling)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an interval or a list of job task numbers.';
                }
                field("Job Posting Group"; "Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the job posting group of the task.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Job Task")
            {
                Caption = '&Job Task';
                Image = Task;
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Job Task Dimensions";
                        RunPageLink = "Job No." = FIELD("Job No."),
                                      "Job Task No." = FIELD("Job Task No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            JobTask: Record "Job Task";
                            JobTaskDimensionsMultiple: Page "Job Task Dimensions Multiple";
                        begin
                            CurrPage.SetSelectionFilter(JobTask);
                            JobTaskDimensionsMultiple.SetMultiJobTask(JobTask);
                            JobTaskDimensionsMultiple.RunModal;
                        end;
                    }
                }
            }
        }
        area(processing)
        {
            action("Split Planning Lines")
            {
                ApplicationArea = Jobs;
                Caption = 'Split Planning Lines';
                Image = Splitlines;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Job Split Planning Line";
                ToolTip = 'Split planning lines of type Budget and Billable into two separate planning lines: Budget and Billable.';
            }
            action("Change Planning Line Dates")
            {
                ApplicationArea = Jobs;
                Caption = 'Change Planning Line Dates';
                Image = ChangeDates;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Report "Change Job Dates";
                ToolTip = 'Use a batch job to help you move planning lines on a job from one date interval to another.';
            }
            action("Copy Job Task From")
            {
                ApplicationArea = Jobs;
                Caption = 'Copy Job Task From';
                Ellipsis = true;
                Image = CopyFromTask;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Use a batch job to help you copy job task lines and job planning lines from one job task to another. You can copy from a job task within the job you are working with or from a job task linked to a different job.';

                trigger OnAction()
                var
                    Job: Record Job;
                    CopyJobTasks: Page "Copy Job Tasks";
                begin
                    if Job.Get("Job No.") then begin
                        CopyJobTasks.SetToJob(Job);
                        CopyJobTasks.RunModal;
                    end;
                end;
            }
            action("Copy Job Task To")
            {
                ApplicationArea = Jobs;
                Caption = 'Copy Job Task To';
                Ellipsis = true;
                Image = CopyToTask;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Use a batch job to help you copy job task lines and job planning lines from one job task to another. You can copy from a job task within the job you are working with or from a job task linked to a different job.';

                trigger OnAction()
                var
                    Job: Record Job;
                    CopyJobTasks: Page "Copy Job Tasks";
                begin
                    if Job.Get("Job No.") then begin
                        CopyJobTasks.SetFromJob(Job);
                        CopyJobTasks.RunModal;
                    end;
                end;
            }
        }
        area(reporting)
        {
            action("Job Actual to Budget")
            {
                ApplicationArea = Jobs;
                Caption = 'Job Actual to Budget';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Job Actual To Budget";
                ToolTip = 'Compare budgeted and usage amounts for selected jobs. All lines of the selected job show quantity, total cost, and line amount.';
            }
            action("Job Analysis")
            {
                ApplicationArea = Jobs;
                Caption = 'Job Analysis';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Job Analysis";
                ToolTip = 'Analyze the job, such as the budgeted prices, usage prices, and billable prices, and then compares the three sets of prices.';
            }
            action("Job - Planning Lines")
            {
                ApplicationArea = Jobs;
                Caption = 'Job - Planning Lines';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Job - Planning Lines";
                ToolTip = 'View all planning lines for the job. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a job (budget) or you can specify what you actually agreed with your customer that he should pay for the job (billable).';
            }
            action("Job - Suggested Billing")
            {
                ApplicationArea = Jobs;
                Caption = 'Job - Suggested Billing';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Job Suggested Billing";
                ToolTip = 'View a list of all jobs, grouped by customer, how much the customer has already been invoiced, and how much remains to be invoiced, that is, the suggested billing.';
            }
            action("Jobs - Transaction Detail")
            {
                ApplicationArea = Jobs;
                Caption = 'Jobs - Transaction Detail';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Job - Transaction Detail";
                ToolTip = 'View all postings with entries for a selected job for a selected period, which have been charged to a certain job. At the end of each job list, the amounts are totaled separately for the Sales and Usage entry types.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := "Job Task Type" <> "Job Task Type"::Posting;
    end;

    var
        [InDataSet]
        StyleIsStrong: Boolean;
}

