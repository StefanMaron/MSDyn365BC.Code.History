page 12201 "Fattura Project Info"
{
    Caption = 'Fattura Project Info';
    PageType = List;
    SourceTable = "Fattura Project Info";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code that identifies the type of project.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        SetRecFilter();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        case GetFilter(Type) of
            'Project':
                Validate(Type, Type::Project);
            'Tender':
                Validate(Type, Type::Tender);
        end;
    end;
}

