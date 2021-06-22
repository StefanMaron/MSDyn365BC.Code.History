page 1011 "Job Resource Prices"
{
    Caption = 'Job Resource Prices';
    PageType = List;
    SourceTable = "Job Resource Price";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

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
                    ToolTip = 'Specifies the number of the related job.';
                }
                field("Job Task No."; "Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the job task if the resource price should only apply to a specific job task.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the price that you are setting up for the job should apply to a resource, to a resource group, or to all resources and resource groups.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the resource or resource group that this price applies to. The No. must correspond to your selection in the Type field.';
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the currency of the sales price if the price that you have set up in this line is in a foreign currency. Choose the field to see the available currency codes.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Unit Cost Factor"; "Unit Cost Factor")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the unit cost factor. If you have agreed with you customer that he should pay for certain resource usage by cost value plus a certain percent value to cover your overhead expenses, you can set up a unit cost factor in this field.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a line discount percent that applies to this resource, or resource group. This is useful, for example if you want invoice lines for the job to show a discount percent.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description of the resource, or resource group, you have entered in the Code field.';
                }
                field("Apply Job Discount"; "Apply Job Discount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether to apply a discount to the job. Select this field if the discount percent for this resource or resource group should apply to the job, even if the discount percent is zero.';
                    Visible = false;
                }
                field("Apply Job Price"; "Apply Job Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the price for this resource, or resource group, should apply to the job, even if the price is zero.';
                    Visible = false;
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
}

