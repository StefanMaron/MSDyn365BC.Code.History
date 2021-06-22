page 550 "VAT Rate Change Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Rate Change Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "VAT Rate Change Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("VAT Rate Change Tool Completed"; "VAT Rate Change Tool Completed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT rate change conversion is complete.';
                }
                field("Perform Conversion"; "Perform Conversion")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the VAT rate conversion is performed on existing data.';
                }
            }
            group("Master Data")
            {
                Caption = 'Master Data';
                field("Update G/L Accounts"; "Update G/L Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for general ledger accounts.';
                }
                field("Account Filter"; "Account Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which accounts will be updated by setting appropriate filters.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpGLAccountFilter(Text));
                    end;
                }
                field("Update Items"; "Update Items")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for items.';
                }
                field("Item Filter"; "Item Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which items will be updated by setting appropriate filters.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpItemFilter(Text));
                    end;
                }
                field("Update Resources"; "Update Resources")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for resources.';
                }
                field("Resource Filter"; "Resource Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which resources will be updated by setting appropriate filters.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpResourceFilter(Text));
                    end;
                }
                field("Update Item Templates"; "Update Item Templates")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that VAT rate changes are updated for item categories.';
                }
                field("Update Item Charges"; "Update Item Charges")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the VAT rate change for item charges.';
                }
                field("Update Gen. Prod. Post. Groups"; "Update Gen. Prod. Post. Groups")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the VAT rate change for general product posting groups.';
                }
                field("Update Serv. Price Adj. Detail"; "Update Serv. Price Adj. Detail")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the VAT rate change for service price adjustment detail.';
                }
                field("Update Work Centers"; "Update Work Centers")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the VAT rate change for work centers.';
                }
                field("Update Machine Centers"; "Update Machine Centers")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the VAT rate change for machine centers.';
                }
            }
            group(Journals)
            {
                Caption = 'Journals';
                field("Update Gen. Journal Lines"; "Update Gen. Journal Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for general journal lines.';
                }
                field("Update Gen. Journal Allocation"; "Update Gen. Journal Allocation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for general journal allocation.';
                }
                field("Update Std. Gen. Jnl. Lines"; "Update Std. Gen. Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for standard general journal lines.';
                }
                field("Update Res. Journal Lines"; "Update Res. Journal Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for resource journal lines.';
                }
                field("Update Job Journal Lines"; "Update Job Journal Lines")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the VAT rate change for job journal lines.';
                }
                field("Update Requisition Lines"; "Update Requisition Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for requisition lines.';
                }
                field("Update Std. Item Jnl. Lines"; "Update Std. Item Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for standard item journal lines.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                field("Update Sales Documents"; "Update Sales Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for sales documents.';
                }
                field("Ignore Status on Sales Docs."; "Ignore Status on Sales Docs.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that all existing sales documents regardless of status, including documents with a status of released, are updated.';
                }
                field("Update Purchase Documents"; "Update Purchase Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate change for purchase documents.';
                }
                field("Ignore Status on Purch. Docs."; "Ignore Status on Purch. Docs.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies all existing purchase documents regardless of status, including documents with a status of released, are updated.';
                }
                field("Update Service Docs."; "Update Service Docs.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the VAT rate change for service lines.';
                }
                field("Ignore Status on Service Docs."; "Ignore Status on Service Docs.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that all existing service documents regardless of release status are updated.';
                }
                field("Update Production Orders"; "Update Production Orders")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the VAT rate change for production orders.';
                }
                field("Update Reminders"; "Update Reminders")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the VAT rate change for reminders.';
                }
                field("Update Finance Charge Memos"; "Update Finance Charge Memos")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the VAT rate change for finance charge memos.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("S&etup")
            {
                Caption = 'S&etup';
                Image = Setup;
                action("VAT Prod. Posting Group Conv.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Prod. Posting Group Conv.';
                    Image = Registered;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "VAT Prod. Posting Group Conv.";
                    ToolTip = 'View or edit the VAT product posting groups for VAT rate change conversion. The VAT product group codes determine calculation and posting of VAT according to the type of item or resource being purchased or the type of item or resource being sold. For each VAT product posting group conversion, the window contains a line where you specify if the current posting group will be updated by the new posting group.';
                }
                action("Gen. Prod. Posting Group Conv.")
                {
                    ApplicationArea = Suite;
                    Caption = 'Gen. Prod. Posting Group Conv.';
                    Image = GeneralPostingSetup;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Gen. Prod. Posting Group Conv.";
                    ToolTip = 'View or edit the general product posting groups for VAT rate change conversion. The general product posting group codes determine posting according to the type of item and resource being purchased or sold. For each general product posting group conversion, the window contains a line where you specify the current posting group that will be updated by the new posting group.';
                }
            }
            group("F&unction")
            {
                Caption = 'F&unction';
                Image = "Action";
                action("&Convert")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Convert';
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "VAT Rate Change Conversion";
                    ToolTip = 'Convert the selected VAT rate.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("VAT Rate Change Log Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Rate Change Log Entries';
                    Image = ChangeLog;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "VAT Rate Change Log Entries";
                    ToolTip = 'The general product posting group codes determine posting according to the type of item and resource being purchased or sold. For each general product posting group conversion, the window contains a line where you specify the current posting group that will be updated by the new posting group.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

