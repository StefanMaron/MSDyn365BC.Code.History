page 463 "Jobs Setup"
{
    AccessByPermission = TableData Job = R;
    AdditionalSearchTerms = 'project setup';
    ApplicationArea = Jobs;
    Caption = 'Jobs Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Jobs Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Automatic Update Job Item Cost"; Rec."Automatic Update Job Item Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies in the Jobs Setup window that cost changes are automatically adjusted each time the Adjust Cost - Item Entries batch job is run. The adjustment process and its results are the same as when you run the Update Job Item Cost Batch Job.';
                }
                field("Apply Usage Link by Default"; Rec."Apply Usage Link by Default")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether job ledger entries are linked to job planning lines by default. Select this check box if you want to apply this setting to all new jobs that you create.';
                }
                field("Allow Sched/Contract Lines Def"; Rec."Allow Sched/Contract Lines Def")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Allow Budget/Billable Lines Def';
                    ToolTip = 'Specifies whether job lines can be of type Both Budget and Billable by default. Select this check box if you want to apply this setting to all new jobs that you create.';
                    Visible = JobSimplificationAvailable;
                }
                field("Default WIP Method"; Rec."Default WIP Method")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the default method to be used for calculating work in process (WIP). It is applied whenever you create a new job, but you can modify the value on the job card.';
                }
                field("Default WIP Posting Method"; Rec."Default WIP Posting Method")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies how the default WIP method is to be applied when posting Work in Process (WIP) to the general ledger. By default, it is applied per job.';
                }
                field("Default Job Posting Group"; Rec."Default Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the default posting group to be applied when you create a new job. This group is used whenever you create a job, but you can modify the value on the job card.';
                }
                field("Logo Position on Documents"; Rec."Logo Position on Documents")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies the position of your company logo on business letters and documents.';
                    Visible = JobSimplificationAvailable;
                }
                field("Document No. Is Job No."; Rec."Document No. Is Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies that the job number is also the document number in the ledger entries posted for the job.';
                }
            }
            group(Prices)
            {
                Caption = 'Prices';
                Visible = ExtendedPriceEnabled;
                field("Default Sales Price List Code"; Rec."Default Sales Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the existing sales price list that stores all new price lines created in the price worksheet page.';
                }
                field("Default Purch Price List Code"; Rec."Default Purch Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the existing purchase price list that stores all new price lines created in the price worksheet page.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Job Nos."; Rec."Job Nos.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to jobs. To see the number series that have been set up in the No. Series table, click the drop-down arrow in the field.';
                }
                field("Job WIP Nos."; Rec."Job WIP Nos.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to job WIP documents. To see the number series that have been set up in the No. Series table, click the drop-down arrow in the field.';
                }
                field("Price List Nos."; Rec."Price List Nos.")
                {
                    ApplicationArea = Jobs;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to job price lists.';
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
    }

    trigger OnInit()
    var
        Job: Record Job;
    begin
        JobSimplificationAvailable := Job.IsJobSimplificationAvailable();
    end;

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Reset();
        if not Get() then begin
            Init();
            Insert();
        end;
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ExtendedPriceEnabled: Boolean;
        JobSimplificationAvailable: Boolean;
}

