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
                        Caption = 'Job - Transaction Detail';
                        RunObject = report "Job - Transaction Detail";
                    }
                    action("Job Register")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Register';
                        RunObject = report "Job Register";
                    }
                    action("Job Actual To Budget")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Actual To Budget';
                        RunObject = report "Job Actual To Budget";
                    }
                    action("Job WIP To G/L")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job WIP To G/L';
                        RunObject = report "Job WIP To G/L";
                    }
                    action("Job Sug. Billing")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Job Suggested Billing';
                        RunObject = report "Job Suggested Billing";
                    }
                    action("Jobs per Customer")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Jobs per Customer';
                        RunObject = report "Jobs per Customer";
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
                        Caption = 'Jobs per Item';
                        RunObject = report "Jobs per Item";
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
                        AccessByPermission = tabledata 167 = R;
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