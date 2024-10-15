page 17392 "Employee Journal Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Employee Journal Templates';
    PageType = List;
    SourceTable = "Employee Journal Template";
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign document numbers to ledger entries that are posted from journals using this template.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Page ID"; "Page ID")
                {
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Page Name"; "Page Name")
                {
                    DrillDown = false;
                    Visible = false;
                }
                field("Test Report ID"; "Test Report ID")
                {
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Test Report Name"; "Test Report Name")
                {
                    DrillDown = false;
                    Visible = false;
                }
                field("Posting Report ID"; "Posting Report ID")
                {
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Posting Report Name"; "Posting Report Name")
                {
                    DrillDown = false;
                    Visible = false;
                }
                field("Force Posting Report"; "Force Posting Report")
                {
                    ToolTip = 'Specifies whether a report is printed automatically when you post.';
                    Visible = false;
                }
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Employee Journal Batches";
                    RunPageLink = "Journal Template Name" = FIELD(Name);
                }
            }
        }
    }
}

