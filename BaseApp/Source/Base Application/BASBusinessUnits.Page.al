page 11604 "BAS Business Units"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BAS Business Units';
    PageType = List;
    SourceTable = "BAS Business Unit";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company, which will be added to the Group Company''s BAS.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BAS document that you want to consolidate.';
                }
                field("BAS Version"; "BAS Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BAS version number that the transaction was included in, and operates in conjunction with the BAS Doc. No.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Import Subsidiary")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Subsidiary';
                Image = Import;
                RunObject = Codeunit "Import Subsidiary";
                ToolTip = 'Import Subsidiary';
            }
        }
    }

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        GLSetup.TestField("Enable GST (Australia)", true);
    end;
}

