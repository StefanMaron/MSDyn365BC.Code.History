page 5144 "Saved Segment Criteria Subform"
{
    Caption = 'Saved Segment Criteria Subform';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Saved Segment Criteria Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = ActionTableIndent;
                IndentationControls = ActionTable;
                ShowCaption = false;
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the segment criteria line.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the type of information the line shows. There are two options: Action or Filter.';
                    Visible = false;
                }
                field(ActionTable; ActionTable)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Action/Table';
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the actions that you have performed (adding or removing contacts) in order to define the segment criteria. The related table is shown under each action.';
                }
                field("Filter"; Filter)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Filter';
                    ToolTip = 'Specifies which segment criteria are shown.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := Type = Type::Action;
        if Type <> Type::Action then
            ActionTableIndent := 1
        else
            ActionTableIndent := 0;
    end;

    var
        [InDataSet]
        StyleIsStrong: Boolean;
        [InDataSet]
        ActionTableIndent: Integer;
}

