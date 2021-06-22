page 8452 "Advanced Intrastat Checklist"
{
    Caption = 'Advanced Intrastat Checklist Setup';
    PageType = List;
    SourceTable = "Advanced Intrastat Checklist";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the type of the object that this entry in the checklist uses.';
                }
                field("Object Id"; Rec."Object Id")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the object that this entry in the checklist uses.';
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the name of the object that this entry in the checklist uses.';
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number of the table field that this entry in the checklist uses.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the name of the table field that this entry in the checklist uses.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditFieldName();
                    end;
                }
                field("Filter Expression"; Rec."Filter Expression")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the filter expression that must be applied to the Intrastat journal line. The check for fields is run only on those lines that are passes the filter expression.';
                }
            }
        }
    }
}

