namespace Microsoft.FixedAssets.Ledger;

using Microsoft.FixedAssets.Maintenance;
using System.Security.User;

page 5627 "FA Registers"
{
    AdditionalSearchTerms = 'fixed asset registers';
    ApplicationArea = FixedAssets;
    Caption = 'FA Registers';
    Editable = false;
    PageType = List;
    SourceTable = "FA Register";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Journal Type"; Rec."Journal Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the type of journal (G/L or Fixed Asset) that the entries were posted from.';
                }
                field("G/L Register No."; Rec."G/L Register No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the G/L register that was created when the entries were posted.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date when the entries in the register were posted.';
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the time when the entries in the register were posted.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the first item entry number in the register.';
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the last FA entry number in the register.';
                }
                field("From Maintenance Entry No."; Rec."From Maintenance Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the first maintenance entry number in the register.';
                }
                field("To Maintenance Entry No."; Rec."To Maintenance Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the last maintenance entry number in the register.';
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
            group("&Register")
            {
                Caption = '&Register';
                Image = Register;
                action("F&A Ledger")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'F&A Ledger';
                    Image = FixedAssetLedger;
                    RunObject = Codeunit "FA Reg.-FALedger";
                    ToolTip = 'View the fixed asset ledger entries that are created when you post to fixed asset accounts. Fixed asset ledger entries are created by the posting of a purchase order, invoice, credit memo or journal line.';
                }
                action("Maintenance Ledger")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Ledger';
                    Image = MaintenanceLedgerEntries;
                    RunObject = Codeunit "FA Reg.-MaintLedger";
                    ToolTip = 'View the maintenance ledger entries for the selected fixed asset.';
                }
            }
        }
        area(processing)
        {
            action("Delete Empty")
            {
                ApplicationArea = All;
                Caption = 'Delete Empty Registers';
                Image = Delete;
                RunObject = Report "Delete Empty FA Registers";
                ToolTip = 'Find and delete empty FA registers.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("F&A Ledger_Promoted"; "F&A Ledger")
                {
                }
                actionref("Maintenance Ledger_Promoted"; "Maintenance Ledger")
                {
                }
            }
        }
    }
}

