#if not CLEAN19
page 6318 "PBI Report Labels"
{
    Caption = 'PBI Report Labels', Locked = true;
    Editable = false;
    PageType = List;
    SourceTable = "Power BI Report Labels";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by API page "Power BI Label Provider" in APIv2';
    ObsoleteTag = '19.0';

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
        PowerBILabelMgt.GetReportLabelsForUserLanguage(Rec, UserSecurityId());
    end;

}
#endif