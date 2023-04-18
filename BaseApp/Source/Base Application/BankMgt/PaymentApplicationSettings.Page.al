page 1253 "Payment Application Settings"
{
    AdditionalSearchTerms = 'payment matching rules,automatic payment application';
    Caption = 'Payment Application Settings';
    ApplicationArea = Basic, Suite;
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "Bank Pmt. Appl. Settings";
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(Settings)
            {
                group(General)
                {
                    Caption = 'General Settings';

                    field(ApplyManDisableSuggestions; Rec."Apply Man. Disable Suggestions")
                    {
                        Caption = 'Disable Suggestions for Apply Manually page';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if the suggestions should be disabled for Apply Manually page. Use this setting if the opening of Apply Manually page takes too long.';
                    }

                    field(EnableApplyImmediatelly; Rec."Enable Apply Immediatelly")
                    {
                        Caption = 'Enable Apply Immediately Rules';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if certain rules should be applied immediatelly. If this value is set to true, if the rule is matched, then the system will not look for alternatives for the specific line. If this value is set to false, the system will search for alternatives, resulting in a higher confidence match.';
                    }

                    field(RelatedPartyNameMatching; Rec."RelatedParty Name Matching")
                    {
                        Caption = 'Related Party Name Matching';
                        ApplicationArea = All;
                        ToolTip = 'Specifies which algorithm to use to determaine related party. Set this value to disabled if your bank statements do not include the name of the related party name.';
                    }
                }

                group(LedgerEntriesSpecific)
                {
                    Caption = 'Ledger Entries Matching Settings';

                    field(CustLedgerEntriesMatching; Rec."Cust. Ledger Entries Matching")
                    {
                        Caption = 'Enable Customer Ledger Entries Matching';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if automatic matching should be enabled for Customer Ledger Entries.';
                    }

                    field(VendorLedgerEntriesMatching; Rec."Vendor Ledger Entries Matching")
                    {
                        Caption = 'Enable Vendor Ledger Entries Matching';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if automatic matching should be enabled for Vendor Ledger Entries.';
                    }
                    field(EmployeeLedgerEntriesMatching; Rec."Empl. Ledger Entries Matching")
                    {
                        Caption = 'Enable Employee Ledger Entries Matching';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if automatic matching should be enabled for Employee Ledger Entries.';
                    }
                    field(BankLedgerEntriesMatching; Rec."Bank Ledger Entries Matching")
                    {
                        Caption = 'Enable Bank Ledger Entries Matching';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if automatic matching should be enabled for Bank Ledger Entries.';
                    }

                    field(BankLedgClosingDocNoMatch; Rec."Bank Ledg Closing Doc No Match")
                    {
                        Caption = 'Match Closing Document No. on Bank Ledger Entries';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if the algorithm should search Vendor and Customer Ledger Entries when matching Bank Ledger Entries. This functionality should be used only if your process requires it, otherwise it has a high performance impact.';
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrInsert();
    end;
}