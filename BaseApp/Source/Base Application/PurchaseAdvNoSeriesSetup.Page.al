#if not CLEAN19
page 31036 "Purchase Adv. No. Series Setup"
{
    Caption = 'Purchase Adv. No. Series Setup (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Purchase Adv. Payment Template";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                InstructionalText = 'To fill the Document No. field automatically, you must set up a number series.';
                field("Advance Letter Nos."; Rec."Advance Letter Nos.")
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
                Caption = 'Purchase Adv. Paym. Templates (Obsolete)';
                Image = Setup;
                RunObject = Page "Purchase Adv. Paym. Templates";
                RunPageLink = Code = FIELD(Code);
                ToolTip = 'Specifies purchase adv. no. series setup';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Setup_Promoted; Setup)
                {
                }
            }
        }
    }

    [Obsolete('Replaced by Advanced Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetTemplateCode(TemplateCode: Code[10])
    begin
        FilterGroup(2);
        SetRange(Code, TemplateCode);
        FilterGroup(0);
    end;
}
#endif
