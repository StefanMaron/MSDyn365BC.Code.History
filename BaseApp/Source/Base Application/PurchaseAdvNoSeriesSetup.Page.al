page 31036 "Purchase Adv. No. Series Setup"
{
    Caption = 'Purchase Adv. No. Series Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Purchase Adv. Payment Template";

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                InstructionalText = 'To fill the Document No. field automatically, you must set up a number series.';
                field("Advance Letter Nos."; "Advance Letter Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to advance letter.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Adv. Paym. Templates';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Purchase Adv. Paym. Templates";
                RunPageLink = Code = FIELD(Code);
                ToolTip = 'Specifies purchase adv. no. series setup';
            }
        }
    }

    [Scope('OnPrem')]
    procedure SetTemplateCode(TemplateCode: Code[10])
    begin
        FilterGroup(2);
        SetRange(Code, TemplateCode);
        FilterGroup(0);
    end;
}

