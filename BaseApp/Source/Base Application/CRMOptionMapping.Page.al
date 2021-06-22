page 5334 "CRM Option Mapping"
{
    ApplicationArea = Suite;
    UsageCategory = Lists;
    Caption = 'Common Data Service Option Mapping';

    Editable = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "CRM Option Mapping";
    SourceTableView = SORTING("Integration Table ID", "Integration Field ID", "Option Value");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Record"; RecordIDText)
                {
                    ApplicationArea = Suite;
                    Caption = 'Record';
                    ToolTip = 'Specifies the record in Business Central that is mapped to the option value in Common Data Service.';
                }
                field("Option Value"; "Option Value")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the numeric value of the mapped option value in Common Data Service.';
                }
                field("Option Value Caption"; "Option Value Caption")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the caption of the mapped option value in Common Data Service.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        RecordIDText := Format("Record ID");
    end;

    var
        RecordIDText: Text;
}

