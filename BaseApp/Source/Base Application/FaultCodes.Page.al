page 5927 "Fault Codes"
{
    ApplicationArea = Service;
    Caption = 'Fault Codes';
    DataCaptionFields = "Fault Area Code", "Symptom Code";
    PageType = List;
    SourceTable = "Fault Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Fault Area Code"; "Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault area associated with the fault code.';
                    Visible = FaultAreaCodeVisible;
                }
                field("Symptom Code"; "Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the symptom linked to the fault code.';
                    Visible = SymptomCodeVisible;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the fault.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the fault code.';
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
            action("Import IRIS to Fault Code")
            {
                ApplicationArea = Service;
                Caption = 'Import IRIS to Fault Code';
                Image = Import;
                RunObject = XMLport "Import IRIS to Fault Codes";
                ToolTip = 'Import the International Repair Coding System to define fault codes for service items.';
            }
        }
    }

    trigger OnInit()
    begin
        SymptomCodeVisible := true;
        FaultAreaCodeVisible := true;
    end;

    trigger OnOpenPage()
    begin
        FaultAreaCodeVisible := not CurrPage.LookupMode;
        SymptomCodeVisible := not CurrPage.LookupMode;
    end;

    var
        [InDataSet]
        FaultAreaCodeVisible: Boolean;
        [InDataSet]
        SymptomCodeVisible: Boolean;
}

