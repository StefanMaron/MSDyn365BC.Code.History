page 278 "Job Registers"
{
    ApplicationArea = Jobs;
    Caption = 'Job Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Job Register";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date on which you posted the entries in the journal.';
                }
                field("Creation Time"; "Creation Time")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the time on which you posted the entries in the journal.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Journal Batch Name"; "Journal Batch Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("From Entry No."; "From Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the first item entry number in the register.';
                }
                field("To Entry No."; "To Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the entry number of the last entry line you included before you posted the entries in the journal.';
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
            group("&Register")
            {
                Caption = '&Register';
                Image = Register;
                action("Job Ledger")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Ledger';
                    Image = JobLedger;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Job Reg.-Show Ledger";
                    ToolTip = 'View the job ledger entries.';
                }
            }
        }
    }
}

