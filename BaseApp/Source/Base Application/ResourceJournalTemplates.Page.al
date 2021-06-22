page 206 "Resource Journal Templates"
{
    ApplicationArea = Jobs;
    Caption = 'Resource Journal Templates';
    PageType = List;
    SourceTable = "Res. Journal Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of this journal.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the template for easy identification.';
                }
                field(Recurring; Recurring)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if this journal will contain recurring entries.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number series code used to assign document numbers to ledger entries that are posted from journals using this template.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Increment Batch Name"; "Increment Batch Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if batch names using this template are automatically incremented. Example: The posting following BATCH001 is automatically named BATCH002.';
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = Jobs;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; "Page Caption")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Test Report ID"; "Test Report ID")
                {
                    ApplicationArea = Jobs;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the test report that is printed when, on the Actions tab in the Posting group, you choose Test Report.';
                    Visible = false;
                }
                field("Test Report Caption"; "Test Report Caption")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that you selected in the Test Report ID field.';
                    Visible = false;
                }
                field("Posting Report ID"; "Posting Report ID")
                {
                    ApplicationArea = Jobs;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the posting report that you want associated with this journal.';
                    Visible = false;
                }
                field("Posting Report Caption"; "Posting Report Caption")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the posting report you selected in the Posting Report ID field.';
                    Visible = false;
                }
                field("Force Posting Report"; "Force Posting Report")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a report is printed automatically when you post.';
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
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action(Batches)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Resource Jnl. Batches";
                    RunPageLink = "Journal Template Name" = FIELD(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                }
            }
        }
    }
}

