namespace Microsoft.Projects.Project.WIP;

page 1010 "Job WIP Methods"
{
    AdditionalSearchTerms = 'work in process  to general ledger methods,work in progress to general ledger methods, Job WIP Methods';
    ApplicationArea = Jobs;
    Caption = 'Project WIP Methods';
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
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the Project WIP Method. There are system-defined codes. In addition, you can create a Project WIP Method, and the code for it is in the list of Project WIP Methods.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description of the project WIP method. If the WIP method is system-defined, you cannot edit the description.';
                }
                field("Recognized Costs"; Rec."Recognized Costs")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a Recognized Cost option to apply when creating a calculation method for WIP. You must select one of the five options:';
                }
                field("Recognized Sales"; Rec."Recognized Sales")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a Recognized Sales option to apply when creating a calculation method for WIP. You must select one of the six options:';
                }
                field("WIP Cost"; Rec."WIP Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the calculation formula, depending on the parameters that you have specified when creating a calculation method for WIP. You can edit the check box, depending on the values set in the Recognized Costs and Recognized Sales fields.';
                }
                field("WIP Sales"; Rec."WIP Sales")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the parameters that apply when creating a calculation method for WIP. You can edit the check box, depending on the values set in the Recognized Costs and Recognized Sales fields.';
                }
                field(Valid; Rec.Valid)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a WIP method can be associated with a project when you are creating or modifying a project. If you select this check box in the Project WIP Methods window, you can then set the method as a default WIP method in the Projects Setup window.';
                }
                field("System Defined"; Rec."System Defined")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a Project WIP Method is system-defined.';
                }
            }
        }
    }

    actions
    {
    }
}

