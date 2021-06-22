page 5826 "Inventory Posting Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Posting Setup';
    CardPageID = "Inventory Posting Setup Card";
    PageType = List;
    SourceTable = "Inventory Posting Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code for setting up posting groups of inventory to general ledger.';
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
                    ToolTip = 'Specifies a description of the combination of inventory posting groups and locations.';
                }
                field("View All Accounts on Lookup"; "View All Accounts on Lookup")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that all possible accounts are shown when you look up from a field. If the check box is not selected, then only accounts related to the involved account category are shown.';
                }
                field("Inventory Account"; "Inventory Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the G/L account that item transactions with this combination of location and inventory posting group are posted to.';
                }
                field("Inventory Account (Interim)"; "Inventory Account (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to which to post transactions with the expected cost for items in this combination.';
                }
                field("WIP Account"; "WIP Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post transactions for items in WIP inventory in this combination.';
                }
                field("Material Variance Account"; "Material Variance Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to which to post material variance transactions for items in this combination.';
                }
                field("Capacity Variance Account"; "Capacity Variance Account")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the general ledger account to which to post capacity variance transactions for items in this combination.';
                }
                field("Subcontracted Variance Account"; "Subcontracted Variance Account")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the general ledger account number to which to post subcontracted variance transactions for items in this combination.';
                }
                field("Cap. Overhead Variance Account"; "Cap. Overhead Variance Account")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the general ledger account number to which to post capacity overhead variance transactions for items in this combination.';
                }
                field("Mfg. Overhead Variance Account"; "Mfg. Overhead Variance Account")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the general ledger account number to which to post manufacturing overhead variance transactions for items in this combination.';
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
        area(processing)
        {
            action(SuggestAccounts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Suggest Accounts';
                Image = Default;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Set Default Accounts';

                trigger OnAction()
                begin
                    SuggestSetupAccounts;
                end;
            }
        }
    }
}

