page 309 "Transport Methods"
{
    ApplicationArea = BasicEU, BasicNO;
    Caption = 'Transport Methods';
    PageType = List;
    SourceTable = "Transport Method";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies a code for the transport method.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies a description of the transport method.';
                }
                field("Port/Airport"; Rec."Port/Airport")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies if the transport mode entered has a port/airport code.';
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