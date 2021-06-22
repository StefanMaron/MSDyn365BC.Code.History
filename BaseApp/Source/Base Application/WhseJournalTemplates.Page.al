page 7321 "Whse. Journal Templates"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Journal Templates';
    PageType = List;
    SourceTable = "Warehouse Journal Template";
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
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name of the warehouse journal template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the warehouse journal template.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of transaction the warehouse journal template is being used for.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Registering No. Series"; "Registering No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign document numbers to the warehouse entries that are registered from this journal.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; "Page Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Test Report ID"; "Test Report ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the test report that is printed when you click Registering, Test Report.';
                    Visible = false;
                }
                field("Test Report Caption"; "Test Report Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that is printed when you click Registering, Test Report.';
                    Visible = false;
                }
                field("Registering Report ID"; "Registering Report ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the registering report that is printed when you click Registering, Register and Print.';
                    Visible = false;
                }
                field("Registering Report Caption"; "Registering Report Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the report that is printed when you click Registering, Register and Print.';
                    Visible = false;
                }
                field("Force Registering Report"; "Force Registering Report")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that a registering report is printed automatically when you register entries from the journal.';
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
                    ApplicationArea = Warehouse;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Whse. Journal Batches";
                    RunPageLink = "Journal Template Name" = FIELD(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                }
            }
        }
    }
}

