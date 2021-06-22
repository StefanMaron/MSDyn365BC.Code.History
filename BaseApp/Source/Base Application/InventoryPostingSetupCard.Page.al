page 5831 "Inventory Posting Setup Card"
{
    Caption = 'Inventory Posting Setup Card';
    PageType = Card;
    SourceTable = "Inventory Posting Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location of the inventory posting.';
                }
                field("Invt. Posting Group Code"; "Invt. Posting Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code for the inventory posting group, in the combination of location and inventory posting group, that you are setting up.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of a combination of inventory posting groups and locations.';
                }
                field("Inventory Account"; "Inventory Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account to which to post transactions with the expected cost for items in this combination.';
                }
                field("Inventory Account (Interim)"; "Inventory Account (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the general ledger account to which to post transactions with the expected cost for items in this combination.';
                }
                group(Manufacturing)
                {
                    Caption = 'Manufacturing';

                    field("WIP Account"; "WIP Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to which to post transactions for items in WIP inventory in this combination.';
                    }
                    field("Material Variance Account"; "Material Variance Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the general ledger account to which to post material variance transactions for items in this combination.';
                    }
                    field("Capacity Variance Account"; "Capacity Variance Account")
                    {
                        ApplicationArea = Manufacturing;
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the general ledger account to which to post capacity variance transactions for items in this combination.';
                    }
                    field("Mfg. Overhead Variance Account"; "Mfg. Overhead Variance Account")
                    {
                        ApplicationArea = Manufacturing;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to which to post manufacturing overhead variance transactions for items in this combination.';
                    }
                    field("Cap. Overhead Variance Account"; "Cap. Overhead Variance Account")
                    {
                        ApplicationArea = Manufacturing;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to which to post capacity overhead variance transactions for items in this combination.';
                    }
                    field("Subcontracted Variance Account"; "Subcontracted Variance Account")
                    {
                        ApplicationArea = Manufacturing;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to which to post subcontracted variance transactions for items in this combination.';
                    }
                }
                group(Usage)
                {
                    Caption = 'Usage';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SuggestAccounts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Suggest Accounts';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Suggest G/L Accounts for selected setup.';

                trigger OnAction()
                begin
                    SuggestSetupAccounts;
                end;
            }
        }
    }
}

