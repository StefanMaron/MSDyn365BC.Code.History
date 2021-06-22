page 325 "Intrastat Journal Templates"
{
    ApplicationArea = BasicEU;
    Caption = 'Intrastat Journal Templates';
    PageType = List;
    SourceTable = "Intrastat Jnl. Template";
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
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the name of the Intrastat journal template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a description of the Intrastat journal template.';
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = BasicEU;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; "Page Caption")
                {
                    ApplicationArea = BasicEU;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Checklist Report ID"; "Checklist Report ID")
                {
                    ApplicationArea = BasicEU;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the checklist that can be printed if you click Actions, Print in the Intrastat journal window and then select Checklist Report.';
                    Visible = false;
                }
                field("Checklist Report Caption"; "Checklist Report Caption")
                {
                    ApplicationArea = BasicEU;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that you can print.';
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
                    ApplicationArea = BasicEU;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Intrastat Jnl. Batches";
                    RunPageLink = "Journal Template Name" = FIELD(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                }
            }
        }
    }
}

