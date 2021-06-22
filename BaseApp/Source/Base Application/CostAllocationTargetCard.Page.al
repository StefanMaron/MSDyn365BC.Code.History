page 1109 "Cost Allocation Target Card"
{
    AutoSplitKey = true;
    Caption = 'Cost Allocation Target Card';
    PageType = Card;
    SourceTable = "Cost Allocation Target";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ID; ID)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID that applies to the cost allocation.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of this line.';
                }
                field("Target Cost Type"; "Target Cost Type")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the type of target cost.';
                }
                field("Target Cost Center"; "Target Cost Center")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the target cost center.';
                }
                field("Target Cost Object"; "Target Cost Object")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the target cost object.';
                }
                field("Allocation Target Type"; "Allocation Target Type")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies if the allocation comes from both budgeted and actual costs, only budgeted costs, or only actual costs.';
                }
                field("Percent per Share"; "Percent per Share")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the percentage if the chosen Allocation Target Type is Percent per Share.';
                }
                field("Amount per Share"; "Amount per Share")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount if the value in the Allocation Target Type field is Amount per Share.';
                }
                field(Base; Base)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether or not the base is static.';
                }
                field("Static Base"; "Static Base")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether or not the base is static.';
                }
                field("Static Weighting"; "Static Weighting")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether the values in the static base are weighted.';
                }
                field(Share; Share)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the values calculated from the Static Base and Static Weighting fields. ';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(Percent; Percent)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the percentage rate calculated based on all other allocation targets.';
                }
            }
            group("Dyn. Allocation")
            {
                Caption = 'Dyn. Allocation';
                field("No. Filter"; "No. Filter")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a filter for the numbers that are included. ';
                }
                field("Cost Center Filter"; "Cost Center Filter")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Filter"; "Cost Object Filter")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Date Filter Code"; "Date Filter Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a filter to filter the calculation of the dynamic allocation base by dates. You use the Date Filter Code field to define a dynamic date range without using a static date. If the allocation bases are updated, the date filter is automatically updated by using the work date.';
                }
                field("Group Filter"; "Group Filter")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a filter so that the dynamic calculation of the Share field is based on the chosen group. Leave the field blank for static allocation.';
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                field("Share Updated on"; "Share Updated on")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the date of when the Share field was last updated.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies when the allocation target card was last modified.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field(Comment; Comment)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a comment that applies to the cost allocation.';
                }
            }
        }
    }

    actions
    {
    }
}

