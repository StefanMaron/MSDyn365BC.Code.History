page 5612 "FA Posting Group Card"
{
    Caption = 'FA Posting Group Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "FA Posting Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the G/L account that fixed asset expenses and costs are posted to when the fixed asset card contains this code.';
                }
                field("Acquisition Cost Account"; "Acquisition Cost Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post acquisition cost for fixed assets to in this posting group.';
                }
                field("Accum. Depreciation Account"; "Accum. Depreciation Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post accumulated depreciation to when you post depreciation for fixed assets.';
                }
                field("Write-Down Account"; "Write-Down Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post any write-downs for fixed assets to in this posting group.';
                }
                field("Appreciation Account"; "Appreciation Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post appreciation transactions for fixed assets to in this posting group.';
                }
                field("Custom 1 Account"; "Custom 1 Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post Custom-1 transactions for fixed assets to in this posting group.';
                }
                field("Custom 2 Account"; "Custom 2 Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post Custom-2 transactions for fixed assets to in this posting group.';
                }
                field("Maintenance Expense Account"; "Maintenance Expense Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post maintenance expenses for fixed assets to in this posting group.';
                }
                field("Acq. Cost Acc. on Disposal"; "Acq. Cost Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post acquisition cost to when you dispose of fixed assets in this posting group.';
                }
                field("Accum. Depr. Acc. on Disposal"; "Accum. Depr. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post accumulated depreciation to when you dispose of fixed assets in this posting group.';
                }
                field("Write-Down Acc. on Disposal"; "Write-Down Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post write-downs of fixed assets to when you dispose of fixed assets in this posting group.';
                }
                field("Appreciation Acc. on Disposal"; "Appreciation Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post appreciation to when you dispose of fixed assets in this posting group.';
                }
                field("Custom 1 Account on Disposal"; "Custom 1 Account on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post Custom-1 transactions to when you dispose of fixed assets in this posting group.';
                }
                field("Custom 2 Account on Disposal"; "Custom 2 Account on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post Custom-2 transactions to when you dispose of fixed assets in this posting group.';
                }
                field("Gains Acc. on Disposal"; "Gains Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post any gains to when you dispose of fixed assets in this posting group.';
                }
                field("Losses Acc. on Disposal"; "Losses Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post any losses to when you dispose of fixed assets in this posting group.';
                }
            }
            group("Balancing Account")
            {
                Caption = 'Balancing Account';
                field("Acquisition Cost Bal. Acc."; "Acquisition Cost Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post acquisition cost for fixed assets to in this posting group.';
                }
                field("Depreciation Expense Acc."; "Depreciation Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account number to post depreciation expense for fixed assets to in this posting group.';
                }
                field("Write-Down Expense Acc."; "Write-Down Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post write-downs for fixed assets to in this posting group.';
                }
                field("Appreciation Bal. Account"; "Appreciation Bal. Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post appreciation for fixed assets to in this posting group.';
                }
                field("Custom 1 Expense Acc."; "Custom 1 Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post custom-1 transactions for fixed assets to in this posting group.';
                }
                field("Custom 2 Expense Acc."; "Custom 2 Expense Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post custom-2 transactions for fixed assets to in this posting group.';
                }
                field("Sales Bal. Acc."; "Sales Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account to post sales when you dispose of fixed assets to in this posting group.';
                }
                field("Maintenance Bal. Acc."; "Maintenance Bal. Acc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post maintenance expenses for fixed assets to in this posting group.';
                }
                field("Write-Down Bal. Acc. on Disp."; "Write-Down Bal. Acc. on Disp.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post write-downs of fixed assets to when you dispose of fixed assets.';
                }
                field("Apprec. Bal. Acc. on Disp."; "Apprec. Bal. Acc. on Disp.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post appreciation transactions of fixed assets to when you dispose of fixed assets.';
                }
                field("Custom 1 Bal. Acc. on Disposal"; "Custom 1 Bal. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post custom-1 transactions of fixed assets to when you dispose of fixed assets.';
                }
                field("Custom 2 Bal. Acc. on Disposal"; "Custom 2 Bal. Acc. on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger balancing account number to post custom-2 transactions of fixed assets to when you dispose of fixed assets.';
                }
            }
            group("Gross Disposal")
            {
                Caption = 'Gross Disposal';
                group("Sales Acc. on Disposal")
                {
                    Caption = 'Sales Acc. on Disposal';
                    field("Sales Acc. on Disp. (Gain)"; "Sales Acc. on Disp. (Gain)")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Gain Account';
                        ToolTip = 'Specifies the G/L account number you want to post sales to when you dispose of fixed assets at a gain on book value.';
                    }
                    field("Sales Acc. on Disp. (Loss)"; "Sales Acc. on Disp. (Loss)")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Loss Account';
                        ToolTip = 'Specifies the G/L account number to which you want to post sales, when you dispose of fixed assets at a loss on book value.';
                    }
                }
                group("Book Value Acc. on Disposal")
                {
                    Caption = 'Book Value Acc. on Disposal';
                    field("Book Val. Acc. on Disp. (Gain)"; "Book Val. Acc. on Disp. (Gain)")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Gain Account';
                        ToolTip = 'Specifies the G/L account number you want the program to post assets'' book value to when you dispose of fixed assets at a gain on book value.';
                    }
                    field("Book Val. Acc. on Disp. (Loss)"; "Book Val. Acc. on Disp. (Loss)")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Loss Account';
                        ToolTip = 'Specifies the G/L account number to which to post assets'' book value, when you dispose of fixed assets at a loss on book value.';
                    }
                }
            }
            group(Allocation)
            {
                Caption = 'Allocation';
                label(Control102)
                {
                    ApplicationArea = FixedAssets;
                    CaptionClass = Text19064976;
                    ShowCaption = false;
                }
                field("Allocated Acquisition Cost %"; "Allocated Acquisition Cost %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Acquisition Cost';
                    ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                }
                field("Allocated Depreciation %"; "Allocated Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation';
                    ToolTip = 'Specifies the total percentage of depreciation that can be allocated when depreciation is posted.';
                }
                field("Allocated Write-Down %"; "Allocated Write-Down %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Write-Down';
                    ToolTip = 'Specifies the total percentage for write-down transactions that can be allocated when write-down transactions are posted.';
                }
                field("Allocated Appreciation %"; "Allocated Appreciation %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Appreciation';
                    ToolTip = 'Specifies the total percentage for appreciation transactions that can be allocated when appreciation transactions are posted.';
                }
                field("Allocated Custom 1 %"; "Allocated Custom 1 %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Custom 1';
                    ToolTip = 'Specifies the total percentage for custom-1 transactions that can be allocated when custom-1 transactions are posted.';
                }
                field("Allocated Custom 2 %"; "Allocated Custom 2 %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Custom 2';
                    ToolTip = 'Specifies the total percentage for custom-2 transactions that can be allocated when custom-2 transactions are posted.';
                }
                field("Allocated Maintenance %"; "Allocated Maintenance %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance';
                    ToolTip = 'Specifies the total percentage for maintenance transactions that can be allocated when maintenance transactions are posted.';
                }
                label(Control127)
                {
                    ApplicationArea = FixedAssets;
                    CaptionClass = Text19080001;
                    ShowCaption = false;
                }
                field("Allocated Gain %"; "Allocated Gain %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Gain';
                    ToolTip = 'Specifies the total percentage of gains on fixed assets that can be allocated, when gains are involved in the disposal of fixed assets.';
                }
                field("Allocated Loss %"; "Allocated Loss %")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Loss';
                    ToolTip = 'Specifies the total percentage for losses on fixed assets that can be allocated when losses are involved in the disposal of fixed assets.';
                }
                field("Allocated Book Value % (Gain)"; "Allocated Book Value % (Gain)")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Book Value (Gain)';
                    ToolTip = 'Specifies the sum that applies to book value gains.';
                }
                field("Allocated Book Value % (Loss)"; "Allocated Book Value % (Loss)")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Book Value (Loss)';
                    ToolTip = 'Specifies the sum that applies to book value gains.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("P&osting Gr.")
            {
                Caption = 'P&osting Gr.';
                Image = Group;
                group(Allocations)
                {
                    Caption = 'Allocations';
                    Image = Allocate;
                    action(Depreciation)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = FIELD(Code),
                                      "Allocation Type" = CONST(Depreciation);
                        ToolTip = 'Specifies whether depreciation entries posted to this depreciation book are posted both to the general ledger and the FA ledger.';
                    }
                    action(WriteDown)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Write-Down';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = FIELD(Code),
                                      "Allocation Type" = CONST("Write-Down");
                        ToolTip = 'Specifies whether write-down entries posted to this depreciation book should be posted to the general ledger and the FA ledger.';
                    }
                    action(Appreciation)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Appr&eciation';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = FIELD(Code),
                                      "Allocation Type" = CONST(Appreciation);
                        ToolTip = 'View or edit the FA allocations that apply to appreciations.';
                    }
                    action(Custom1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Custom 1';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = FIELD(Code),
                                      "Allocation Type" = CONST("Custom 1");
                        ToolTip = 'View or edit the FA allocations that apply to custom 1 values.';
                    }
                    action(Custom2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'C&ustom 2';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = FIELD(Code),
                                      "Allocation Type" = CONST("Custom 2");
                        ToolTip = 'View or edit the FA allocations that apply to custom 2 values.';
                    }
                    action(Maintenance)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Maintenance';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = FIELD(Code),
                                      "Allocation Type" = CONST(Maintenance);
                        ToolTip = 'View or edit the FA allocations that apply to maintenance.';
                    }
                    action(Gain)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Gain';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = FIELD(Code),
                                      "Allocation Type" = CONST(Gain);
                        ToolTip = 'View or edit the FA allocations that apply to gains.';
                    }
                    action(Loss)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Loss';
                        Image = Allocate;
                        RunObject = Page "FA Allocations";
                        RunPageLink = Code = FIELD(Code),
                                      "Allocation Type" = CONST(Loss);
                        ToolTip = 'View or edit the FA allocations that apply to losses.';
                    }
                }
            }
        }
    }

    var
        Text19064976: Label 'Allocated %';
        Text19080001: Label 'Allocated %';
}

