page 12200 "Fattura Codes"
{
    Caption = 'Fattura Codes';
    PageType = List;
    SourceTable = "Fattura Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code that identifies the type.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
                field(Type; Type)
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
        SetRecFilter;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        case GetFilter(Type) of
            'Payment Terms':
                Validate(Type, Type::"Payment Terms");
            'Payment Method':
                Validate(Type, Type::"Payment Method");
        end;
    end;
}

