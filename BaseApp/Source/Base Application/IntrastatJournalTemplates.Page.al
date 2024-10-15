page 325 "Intrastat Journal Templates"
{
    ApplicationArea = VAT;
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
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the name of the Intrastat journal template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a description of the Intrastat journal template.';
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = VAT;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; "Page Caption")
                {
                    ApplicationArea = VAT;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Checklist Report ID"; "Checklist Report ID")
                {
                    ApplicationArea = VAT;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the checklist that can be printed if you click Actions, Print in the Intrastat journal window and then select Checklist Report.';
                    Visible = false;
                }
                field("Checklist Report Caption"; "Checklist Report Caption")
                {
                    ApplicationArea = VAT;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that you can print.';
                    Visible = false;
                }
                field("Perform. Country/Region Code"; "Perform. Country/Region Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the country/region code. It is mandatory field by creating documents with VAT registration number for other countries.';
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
                    ApplicationArea = VAT;
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

