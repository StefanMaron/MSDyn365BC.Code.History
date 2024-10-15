namespace Microsoft.HumanResources.Setup;

page 5217 "Employment Contracts"
{
    ApplicationArea = BasicHR;
    Caption = 'Employment Contracts';
    PageType = List;
    SourceTable = "Employment Contract";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a code for the employment contract.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description for the employment contract.';
                }
                field("No. of Contracts"; Rec."No. of Contracts")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of contracts associated with the entry.';
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

