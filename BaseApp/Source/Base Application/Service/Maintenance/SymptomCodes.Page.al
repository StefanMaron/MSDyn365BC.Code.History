namespace Microsoft.Service.Maintenance;

page 5926 "Symptom Codes"
{
    ApplicationArea = Service;
    Caption = 'Symptom Codes';
    PageType = List;
    SourceTable = "Symptom Code";
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
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the symptom.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the symptom code.';
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
        area(processing)
        {
            action("Import IRIS to Area/Symptom Code")
            {
                ApplicationArea = Service;
                Caption = 'Import IRIS to Area/Symptom Code';
                Image = Import;
                RunObject = XMLport "Imp. IRIS to Area/Symptom Code";
                ToolTip = 'Import the International Repair Coding System to define area and symptom codes for service items.';
            }
        }
    }
}

