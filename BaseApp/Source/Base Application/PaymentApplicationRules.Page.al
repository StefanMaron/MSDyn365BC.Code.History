#if not CLEAN21
page 1252 "Payment Application Rules"
{
    AdditionalSearchTerms = 'payment matching rules,automatic payment application';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Application Rules';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Bank Pmt. Appl. Rule";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Rules)
            {
                field("Match Confidence"; Rec."Match Confidence")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your confidence in the application rule that you defined by the values in the Related Party Matched, Doc. No./Ext. Doc. No. Matched, and Amount Incl. Tolerance Matched fields on the line in the Payment Application Rules window.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the priority of the application rule in relation to other application rules that are defined as lines in the Payment Application Rules window. 1 represents the highest priority.';
                }
                field("Related Party Matched"; Rec."Related Party Matched")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how much information on the payment reconciliation journal line must match the open entry before the application rule will apply the payment to the open entry.';
                }
                field("Doc. No./Ext. Doc. No. Matched"; Rec."Doc. No./Ext. Doc. No. Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No./Ext. Document No. Matched';
                    ToolTip = 'Specifies if text on the payment reconciliation journal line must match with the value in the Document No. field or the External Document No. field on the open entry before the application rule will be used to automatically apply the payment to the open entry.';
                }
                field("Amount Incl. Tolerance Matched"; Rec."Amount Incl. Tolerance Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number of Entries Within Amount Tolerance Found';
                    ToolTip = 'Specifies how many entries must match the amount including payment tolerance, before the application rule will be used to apply a payment to the open entry.';
                }
                field("Direct Debit Collect. Matched"; Rec."Direct Debit Collect. Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Direct Debit Collection Matched';
                    ToolTip = 'Specifies if the Transaction ID value on the payment reconciliation journal line must match with the value in the related Transaction ID field in the Direct Debit Collect. Entries window.';
                }
                field("Review Required"; Rec."Review Required")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Review Required';
                    ToolTip = 'Specifies if bank statement lines matched with this rule will be shown as recommended for review.';
                }

                field("Apply Immediatelly"; Rec."Apply Immediatelly")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Immediatelly';
                    ToolTip = 'Specifies whether to search for alternative ledger entries that this line can be applied to. If turned on, the value is applied to the first match and alternative ledger entries are not considered.';
                    Visible = ApplyAutomaticallyVisible;
                }
#if not CLEAN19
                field("Variable Symbol Matched"; Rec."Variable Symbol Matched")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the match rule for variable symbol';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Specific Symbol Matched"; Rec."Specific Symbol Matched")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the match rule for specific symbol';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Constant Symbol Matched"; Rec."Constant Symbol Matched")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the match rule for constant symbol';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Bank Transaction Type"; Rec."Bank Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies bank transaction type for payment application rules ';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
#endif
            }
        }
    }

    actions
    {
        area(creation)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Merge to W1 where the area is called Processing';
            ObsoleteTag = '21.0';

            action(RestoreDefaultRules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restore Default Rules';
                Image = Restore;
                ToolTip = 'Delete the application rules and replace them with the default rules, which control whether payments are automatically applied to open ledger entries.';

                trigger OnAction()
                begin
                    if not Confirm(ResetToDefaultsQst) then
                        exit;

                    DeleteAll();
                    InsertDefaultMatchingRules();
                end;
            }

            action(AdvancedSettings)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advanced Settings';
                Image = Setup;
                ToolTip = 'Opens advanced settings for configuring payment application matching.';

#if CLEAN19
                trigger OnAction()
                var
                    BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
                    PaymentApplicationSettings: Page "Payment Application Settings";
                begin
                    BankPmtApplSettings.SetRange(PrimaryKey, GetDefaultCode());
                    PaymentApplicationSettings.SetTableView(BankPmtApplSettings);
                    PaymentApplicationSettings.Run();
                end;
#else
                trigger OnAction()
                var
                    PaymentApplicationSettings: Page "Payment Application Settings";
                begin
                    PaymentApplicationSettings.SetBankPmtApplRuleCode(Rec."Bank Pmt. Appl. Rule Code");
                    PaymentApplicationSettings.Run();
                end;
#endif
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RestoreDefaultRules_Promoted; RestoreDefaultRules)
                {
                }
                actionref(AdvancedSettings_Promoted; AdvancedSettings)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
    begin
        SetCurrentKey(Score);
        Ascending(false);
#if CLEAN19
        SetRange("Bank Pmt. Appl. Rule Code", GetDefaultCode());
        BankPmtApplSettings.GetOrInsert();
#else
        BankPmtApplSettings.GetOrInsert(Rec."Bank Pmt. Appl. Rule Code");
#endif
        ApplyAutomaticallyVisible := BankPmtApplSettings."Enable Apply Immediatelly";
    end;

    var
        ResetToDefaultsQst: Label 'All current payment application rules will be deleted and replaced with the default payment application rules.\\Do you want to continue?';
        ApplyAutomaticallyVisible: Boolean;
}


#endif