page 5152 "Salutation Formulas"
{
    Caption = 'Salutation Formulas';
    DataCaptionFields = "Salutation Code";
    PageType = List;
    SourceTable = "Salutation Formula";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("Salutation Type"; "Salutation Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the salutation is formal or informal. Make your selection by clicking the field.';
                }
                field(Salutation; Salutation)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the salutation itself.';
                }
                field("Name 1"; "Name 1")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation. The options are: Job Title, First Name, Middle Name, Surname, Initials and Company Name.';
                }
                field("Name 2"; "Name 2")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation. The options are: Job Title, First Name, Middle Name, Surname, Initials and Company Name.';
                }
                field("Name 3"; "Name 3")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation. The options are: Job Title, First Name, Middle Name, Surname, Initials and Company Name.';
                }
                field("Name 4"; "Name 4")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation. The options are: Job Title, First Name, Middle Name, Surname, Initials and Company Name.';
                }
                field("Name 5"; "Name 5")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation.';
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

