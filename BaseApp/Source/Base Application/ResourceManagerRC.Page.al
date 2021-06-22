page 8906 "Resource Manager Role Center"
{
    Caption = 'Resource Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Resources';
                action("Resources")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resources';
                    RunObject = page "Resource List";
                }
                action("Resource Groups")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Groups';
                    RunObject = page "Resource Groups";
                }
                action("Resource Price Changes")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Price Changes';
                    RunObject = page "Resource Price Changes";
                }
                action("Adjust Resource Costs/Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Resource Costs/Prices';
                    RunObject = report "Adjust Resource Costs/Prices";
                }
                group("Group1")
                {
                    Caption = 'Capacity';
                    action("Resource Capacity")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Capacity';
                        RunObject = page "Resource Capacity";
                    }
                    action("Resource Group Capacity")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Group Capacity';
                        RunObject = page "Res. Group Capacity";
                    }
                }
                group("Group2")
                {
                    Caption = 'Journals';
                    action("Resource Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Resource Journals';
                        RunObject = page "Resource Journal";
                    }
                    action("Recurring Journals")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Recurring Resource Journals';
                        RunObject = page "Recurring Resource Jnl.";
                    }
                }
                group("Group3")
                {
                    Caption = 'Entries/Registers';
                    action("Resource Registers")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Registers';
                        RunObject = page "Resource Registers";
                    }
                    action("Resource Capacity Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Capacity Entries';
                        RunObject = page "Res. Capacity Entries";
                    }
                    action("Resource Ledger Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Ledger Entries';
                        RunObject = page "Resource Ledger Entries";
                    }
                }
                group("Group4")
                {
                    Caption = 'Reports';
                    action("Resource Register")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Register';
                        RunObject = report "Resource Register";
                    }
                    action("Resource Statistics")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Statistics';
                        RunObject = report "Resource Statistics";
                    }
                    action("Resource Usage")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Usage';
                        RunObject = report "Resource Usage";
                    }
                    action("Resource - Cost Breakdown")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource - Cost Breakdown';
                        RunObject = report "Resource - Cost Breakdown";
                    }
                    action("Resource - List")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource - List';
                        RunObject = report "Resource - List";
                    }
                    action("Resource - Price List")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource - Price List';
                        RunObject = report "Resource - Price List";
                    }
                }
                group("Group5")
                {
                    Caption = 'Setup';
                    action("Resource Setup")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resources Setup';
                        RunObject = page "Resources Setup";
                        AccessByPermission = tabledata 156 = R;
                    }
                    action("Work Types")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Work Types';
                        RunObject = page "Work Types";
                    }
                    action("Units of Measure")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Units of Measure';
                        RunObject = page "Units of Measure";
                    }
                    action("Costs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Resource Costs';
                        RunObject = page "Resource Costs";
                    }
                    action("Prices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Resource Prices';
                        RunObject = page "Resource Prices";
                        AccessByPermission = tabledata 156 = R;
                    }
                    action("Rounding Methods")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Methods';
                        RunObject = page "Rounding Methods";
                        AccessByPermission = tabledata 156 = R;
                    }
                    action("Journal Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Resource Journal Templates';
                        RunObject = page "Resource Journal Templates";
                    }
                }
            }
            group("Group6")
            {
                Caption = 'Time Sheets';
                action("TimeSheet")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Time Sheets';
                    RunObject = page "Time Sheet List";
                }
                action("Manager Time Sheets")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Manager Time Sheets';
                    RunObject = page "Manager Time Sheet List";
                }
                action("Create TimeSheet Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Time Sheets';
                    RunObject = report "Create Time Sheets";
                }
                group("Group7")
                {
                    Caption = 'Entries/Registers';
                    action("Time Sheet Archive List")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Time Sheet Archives';
                        RunObject = page "Time Sheet Archive List";
                    }
                    action("Manager Time Sheet Archives")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Manager Time Sheet Archives';
                        RunObject = page "Manager Time Sheet Arc. List";
                    }
                }
            }
        }
    }
}