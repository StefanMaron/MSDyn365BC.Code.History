#if not CLEAN22
page 326 "Intrastat Jnl. Template List"
{
    Caption = 'Intrastat Jnl. Template List';
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Intrastat Jnl. Template";
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the name of the Intrastat journal template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a description of the Intrastat journal template.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = BasicEU;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Checklist Report ID"; Rec."Checklist Report ID")
                {
                    ApplicationArea = BasicEU;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the checklist that can be printed if you click Actions, Print in the intrastate journal window and then select Checklist Report.';
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
    }
}
#endif