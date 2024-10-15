page 11206 "Automatic Acc. Groups"
{
    Caption = 'Automatic Acc. Groups';
    PageType = ListPlus;
    SourceTable = "Automatic Acc. Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the automatic account group number in this field.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an appropriate description of the automatic account group in this field.';
                }
            }
            part(AccLines; "Automatic Acc. Line")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Automatic Acc. No." = FIELD("No.");
            }
        }
    }

    actions
    {
    }
}

