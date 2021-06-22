page 9620 "Page Fields"
{
    Caption = 'Add Field to Page';
    DeleteAllowed = false;
    Description = 'Place fields by dragging from the list to a position on the page.';
    Editable = true;
    InsertAllowed = false;
    InstructionalText = 'Place fields by dragging from the list to a position on the page.';
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Page Table Field";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = All;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                }
                field("Field ID"; "Field ID")
                {
                    ApplicationArea = All;
                    Caption = 'Field ID';
                    ToolTip = 'Specifies the ID of the field.';
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    OptionCaption = 'TableFilter,RecordID,OemText,Date,Time,DateFormula,Decimal,Media,MediaSet,Text,Code,NotSupported_Binary,BLOB,Boolean,Integer,OemCode,Option,BigInteger,Duration,GUID,DateTime';
                    ToolTip = 'Specifies the type of the field.';
                }
                field(Length; Length)
                {
                    ApplicationArea = All;
                    Caption = 'Length';
                    ToolTip = 'Specifies the length of the field.';
                }
                field(Caption; Caption)
                {
                    ApplicationArea = All;
                    Caption = 'Caption';
                    ToolTip = 'Specifies the caption of the field.';
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    OptionCaption = 'New,Ready,Placed';
                    Style = Favorable;
                    StyleExpr = FieldPlaced;
                    ToolTip = 'Specifies the field''s status, such as if the field is already placed on the page.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(View)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View';
                ShortCutKey = 'Return';
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';

                trigger OnAction()
                begin
                    // Comment to indicate to the server that this action must be run
                    // This action is here to override the default behavior of opening the card page with this record
                    // which is not desired in this case.
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DesignerPageId: Codeunit DesignerPageId;
    begin
        FieldPlaced := Status = 1;
        DesignerPageId.SetPageId("Page ID");
    end;

    var
        FieldPlaced: Boolean;
}

