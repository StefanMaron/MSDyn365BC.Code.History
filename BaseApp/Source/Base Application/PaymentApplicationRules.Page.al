page 1252 "Payment Application Rules"
{
    AdditionalSearchTerms = 'payment matching rules,automatic payment application';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Application Rules';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bank Pmt. Appl. Rule";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Rules)
            {
                field("Match Confidence"; "Match Confidence")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your confidence in the application rule that you defined by the values in the Related Party Matched, Doc. No./Ext. Doc. No. Matched, and Amount Incl. Tolerance Matched fields on the line in the Payment Application Rules window.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the priority of the application rule in relation to other application rules that are defined as lines in the Payment Application Rules window. 1 represents the highest priority.';
                }
                field("Related Party Matched"; "Related Party Matched")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how much information on the payment reconciliation journal line must match the open entry before the application rule will apply the payment to the open entry.';
                }
                field("Doc. No./Ext. Doc. No. Matched"; "Doc. No./Ext. Doc. No. Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No./Ext. Document No. Matched';
                    ToolTip = 'Specifies if text on the payment reconciliation journal line must match with the value in the Document No. field or the External Document No. field on the open entry before the application rule will be used to automatically apply the payment to the open entry.';
                }
                field("Amount Incl. Tolerance Matched"; "Amount Incl. Tolerance Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number of Entries Within Amount Tolerance Found';
                    ToolTip = 'Specifies how many entries must match the amount including payment tolerance, before the application rule will be used to apply a payment to the open entry.';
                }
                field("Direct Debit Collect. Matched"; "Direct Debit Collect. Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Direct Debit Collection Matched';
                    ToolTip = 'Specifies if the Transaction ID value on the payment reconciliation journal line must match with the value in the related Transaction ID field in the Direct Debit Collect. Entries window.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(RestoreDefaultRules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restore Default Rules';
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Delete the application rules and replace them with the default rules, which control whether payments are automatically applied to open ledger entries.';

                trigger OnAction()
                begin
                    if not Confirm(ResetToDefaultsQst) then
                        exit;

                    DeleteAll();
                    InsertDefaultMatchingRules;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetCurrentKey(Score);
        Ascending(false);
    end;

    var
        ResetToDefaultsQst: Label 'All current payment application rules will be deleted and replaced with the default payment application rules.\\Do you want to continue?';
}

