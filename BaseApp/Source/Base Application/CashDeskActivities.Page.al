#if not CLEAN17
page 11749 "Cash Desk Activities"
{
    Caption = 'Cash Desk Activities (Obsolete)';
    PageType = CardPart;
    SourceTable = "Cash Desk Cue";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            cuegroup(Unposted)
            {
                Caption = 'Unposted';
                field("Open Documents"; "Open Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies cash desk documents with status open.';
                }
                field("Released Documents"; "Released Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies cash desk documents with status released.';
                }

                actions
                {
                    action("New Cash Document")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Cash Document';
                        RunObject = Page "Cash Document";
                        RunPageMode = Create;
                        ToolTip = 'Specifies the access to create new cash documents.';
                    }
                    action("Edit Cash Document")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Cash Document';
                        RunObject = Page "Cash Document";
                        ToolTip = 'Specifies the access to edit cash documents.';
                    }
                }
            }
            cuegroup(Posted)
            {
                Caption = 'Posted';
                field("Posted Documents"; "Posted Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies cash desk documents with status posted.';
                }

                actions
                {
                    action("Posted Cash Documents")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Cash Documents';
                        RunObject = Page "Posted Cash Document List";
                        RunPageMode = View;
                        ToolTip = 'Specifies the overview of posted cash documents.';
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        CashDeskManagement: Codeunit CashDeskManagement;
        CashDeskFilter: Text;
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        FilterGroup(2);
        CashDeskFilter := CashDeskManagement.GetCashDesksFilter;
        if CashDeskFilter <> '' then
            SetFilter("Cash Desk Filter", CashDeskFilter)
        else
            SetRange("Cash Desk Filter", '');
        SetRange("Date Filter", WorkDate);
        FilterGroup(0);
    end;
}
#endif