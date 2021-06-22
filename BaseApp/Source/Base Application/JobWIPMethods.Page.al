page 1010 "Job WIP Methods"
{
    AdditionalSearchTerms = 'work in process  to general ledger methods,work in progress to general ledger methods';
    ApplicationArea = Jobs;
    Caption = 'Job WIP Methods';
    PageType = List;
    SourceTable = "Job WIP Method";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the Job WIP Method. There are system-defined codes. In addition, you can create a Job WIP Method, and the code for it is in the list of Job WIP Methods.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description of the job WIP method. If the WIP method is system-defined, you cannot edit the description.';
                }
                field("Recognized Costs"; "Recognized Costs")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a Recognized Cost option to apply when creating a calculation method for WIP. You must select one of the five options:';
                }
                field("Recognized Sales"; "Recognized Sales")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a Recognized Sales option to apply when creating a calculation method for WIP. You must select one of the six options:';
                }
                field("WIP Cost"; "WIP Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the calculation formula, depending on the parameters that you have specified when creating a calculation method for WIP. You can edit the check box, depending on the values set in the Recognized Costs and Recognized Sales fields.';
                }
                field("WIP Sales"; "WIP Sales")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the parameters that apply when creating a calculation method for WIP. You can edit the check box, depending on the values set in the Recognized Costs and Recognized Sales fields.';
                }
                field(Valid; Valid)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a WIP method can be associated with a job when you are creating or modifying a job. If you select this check box in the Job WIP Methods window, you can then set the method as a default WIP method in the Jobs Setup window.';
                }
                field("System Defined"; "System Defined")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a Job WIP Method is system-defined.';
                }
            }
        }
    }

    actions
    {
    }
}

