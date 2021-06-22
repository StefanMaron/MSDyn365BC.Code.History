page 6318 "PBI Report Labels"
{
    Caption = 'PBI Report Labels', Locked = true;
    Editable = false;
    PageType = List;
    SourceTable = "Power BI Report Labels";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Label ID"; "Label ID")
                {
                    ApplicationArea = All;
                    Caption = 'Label ID', Locked = true;
                }
                field("Text Value"; "Text Value")
                {
                    ApplicationArea = All;
                    Caption = 'Text Value', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        PowerBILabelMgt: Codeunit "Power BI Label Mgt.";
    begin
        PowerBILabelMgt.GetReportLabels(Rec);
    end;
}

