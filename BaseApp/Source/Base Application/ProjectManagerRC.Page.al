page 8904 "Project Manager Role Center"
{
    Caption = 'Project Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Jobs';
                action("Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Jobs';
                    RunObject = page "Job List";
                }
                action("Job WIP Worksheet")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job WIP Cockpit';
                    RunObject = page "Job WIP Cockpit";
                }
                action("Manager Time Sheet by Job")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Manager Time Sheet by Job';
                    RunObject = page "Manager Time Sheet by Job";
                }
                action("Job Calculate WIP")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Calculate WIP';
                    RunObject = report "Job Calculate WIP";
                }
                action("Job Post WIP to G/L")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Post WIP to G/L';
                    RunObject = report "Job Post WIP to G/L";
                }
                action("Job Create Sales Invoice")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Create Sales Invoice';
                    RunObject = report "Job Create Sales Invoice";
                }
                group("Group1")
                {
                    Caption = 'Journals';
                    action("Job Journals")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Journals';
                        RunObject = page "Job Journal";
                    }
                    action("Job G/L Journals")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job G/L Journals';
                        RunObject = page "Job G/L Journal";
                    }
                    action("Recurring Journals")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Recurring Job Journals';
                        RunObject = page "Recurring Job Jnl.";
                    }
                }
                group("Group2")
                {
                    Caption = 'Register/Entries';
                    action("Job Registers")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Registers';
                        RunObject = page "Job Registers";
                    }
                    action("Job Ledger Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Ledger Entries';
                        RunObject = page "Job Ledger Entries";
                    }
                    action("Job WIP Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job WIP Entries';
                        RunObject = page "Job WIP Entries";
                    }
                    action("Job WIP G/L Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job WIP G/L Entries';
                        RunObject = page "Job WIP G/L Entries";
                    }
                    action("Resource Capacity Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Capacity Entries';
                        RunObject = page "Res. Capacity Entries";
                    }
                }
                group("Group3")
                {
                    Caption = 'Reports';
                    action("Job Analysis")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Analysis';
                        RunObject = report "Job Analysis";
                    }
                    action("Job - Planing Lines")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job - Planning Lines';
                        RunObject = report "Job - Planning Lines";
                    }
                    action("Job - Transaction Detail")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Cost Transaction Detail';
                        RunObject = Report "Job Cost Transaction Detail";
                    }
                    // action("Job - Transaction Detail1")
                    // {
                    //     Caption = 'Job Cost Transaction Detail';
                    //     RunObject = Report job co;
                    // }
                    action("Job Register")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Register';
                        RunObject = Report "Job Register";
                    }
                    action("Job WIP To G/L")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job WIP To G/L';
                        RunObject = report "Job WIP To G/L";
                    }
                    action("Jobs per Customer")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Customer Jobs (Cost)';
                        RunObject = Report "Customer Jobs (Cost)";
                    }
                    action("Job/Item")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Items per Job';
                        RunObject = report "Items per Job";
                    }
                    action("Item/Job")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Completed Jobs';
                        RunObject = Report "Completed Jobs";
                    }
                    // action("Item/Job1")
                    // {
                    //     Caption = 'Completed Jobs';
                    //     RunObject = Report "Completed Jobs";
                    // }
                    action("Jobs per Customer1")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Customer Jobs (Cost)';
                        RunObject = Report "Customer Jobs (Cost)";
                    }
                    action("Customer Jobs (Price)")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Customer Jobs (Price)';
                        RunObject = Report "Customer Jobs (Price)";
                    }
                    action("Job Actual to Budget (Cost)")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Actual to Budget (Cost)';
                        RunObject = Report "Job Actual to Budget (Cost)";
                    }
                    action("Job Actual to Budget (Price)")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Actual to Budget (Price)';
                        RunObject = Report "Job Actual to Budget (Price)";
                    }
                    action("Job Cost Suggested Billing")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Cost Suggested Billing';
                        RunObject = Report "Job Cost Suggested Billing";
                    }
                    action("Job Cost Budget")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Cost Budget';
                        RunObject = Report "Job Cost Budget";
                    }
                    action("Job List")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job List';
                        RunObject = Report "Job List";
                    }
                }
                group("Group4")
                {
                    Caption = 'Setup';
                    action("Jobs Setup")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Jobs Setup';
                        RunObject = page "Jobs Setup";
                        AccessByPermission = TableData "Job" = R;
                    }
                    action("Job Posting Groups")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Posting Groups';
                        RunObject = page "Job Posting Groups";
                    }
                    action("Job Journal Templates")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Journal Templates';
                        RunObject = page "Job Journal Templates";
                    }
                    action("Job WIP Methods")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job WIP Methods';
                        RunObject = page "Job WIP Methods";
                    }
                }
            }
        }
    }
}
