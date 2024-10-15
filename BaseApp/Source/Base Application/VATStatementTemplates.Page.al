page 318 "VAT Statement Templates"
{
    ApplicationArea = VAT;
    Caption = 'VAT Statement Templates';
    PageType = List;
    SourceTable = "VAT Statement Template";
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
                    ToolTip = 'Specifies the name of the VAT statement template you are about to create.';
                }
                field(Description; Description)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a description of the VAT statement template.';
                }
                field("VAT Statement Report ID"; "VAT Statement Report ID")
                {
                    ApplicationArea = VAT;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the report that you can print for the VAT statement template. The standard VAT statement report ID that comes with the program is entered by default. You can select a different VAT statement report ID if your program contains more than one.';
                    Visible = false;
                }
                field("VAT Statement Report Caption"; "VAT Statement Report Caption")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the name of the VAT statement report that can be printed. The field with the VAT statement name corresponding to the VAT statement report ID selected in the VAT Statement Report ID field.';
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
                action("Statement Names")
                {
                    ApplicationArea = VAT;
                    Caption = 'Statement Names';
                    Image = List;
                    RunObject = Page "VAT Statement Names";
                    RunPageLink = "Statement Template Name" = FIELD(Name);
                    ToolTip = 'View or edit special tables to manage the tasks necessary for settling Tax and reporting to the customs and tax authorities.';
                }
            }
        }
    }
}

