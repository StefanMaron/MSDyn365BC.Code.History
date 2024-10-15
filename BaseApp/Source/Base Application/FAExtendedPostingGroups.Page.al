#if not CLEAN18
page 31042 "FA Extended Posting Groups"
{
    Caption = 'FA Extended Posting Groups (Obsolete)';
    DataCaptionFields = "FA Posting Group Code", "FA Posting Type", "Code";
    PageType = List;
    SourceTable = "FA Extended Posting Group";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220014)
            {
                ShowCaption = false;
                field("FA Posting Type"; "FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the fixed asset posting type (disposal, acquisition, maintenance ...).';
                }
                field("Code"; Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the extended fixed asset posting group.';
                }
                field("Sales Acc. On Disp. (Gain)"; "Sales Acc. On Disp. (Gain)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the sales account on FA disposal (Gain).';
                    Visible = false;
                }
                field("Sales Acc. On Disp. (Loss)"; "Sales Acc. On Disp. (Loss)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the sales account on FA disposal (Los).';
                    Visible = false;
                }
                field("Book Val. Acc. on Disp. (Gain)"; "Book Val. Acc. on Disp. (Gain)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account for the book value gain account.';
                }
                field("Book Val. Acc. on Disp. (Loss)"; "Book Val. Acc. on Disp. (Loss)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account for the book value loss account.';
                }
                field("Maintenance Expense Account"; "Maintenance Expense Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post maintenance expenses for fixed assets to in this posting group.';
                }
                field("Maintenance Bal. Acc."; "Maintenance Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger maintenance balance account.';
                }
                field("Allocated Book Value % (Gain)"; "Allocated Book Value % (Gain)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the allocation gain book value percentage for fixed assets.';
                    Visible = false;
                }
                field("Allocated Book Value % (Loss)"; "Allocated Book Value % (Loss)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the allocation loss book value percentage for fixed assets.';
                    Visible = false;
                }
                field("Allocated Maintenance %"; "Allocated Maintenance %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the allocated maintenance percentage for the fixed asset posting group.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220002; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220004; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}
#endif
