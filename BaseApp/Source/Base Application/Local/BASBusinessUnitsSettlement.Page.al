page 11613 "BAS Business Units-Settlement"
{
    Caption = 'BAS Business Units-Settlement';
    Editable = false;
    PageType = List;
    SourceTable = "BAS Business Unit";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company, which will be added to the Group Company''s BAS.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BAS document that you want to consolidate.';
                }
                field("BAS Version"; Rec."BAS Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BAS version number that the transaction was included in, and operates in conjunction with the BAS Doc. No.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;
}

