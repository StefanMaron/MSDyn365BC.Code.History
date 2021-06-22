page 110 "Customer Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Posting Groups';
    CardPageID = "Customer Posting Group Card";
    PageType = List;
    SourceTable = "Customer Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control5)
            {
                ShowCaption = false;
                field(ShowAllAccounts; ShowAllAccounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All Accounts';
                    ToolTip = 'Specifies that all possible setup fields related to G/L accounts are shown.';

                    trigger OnValidate()
                    var
                        ReminderTerms: Record "Reminder Terms";
                    begin
                        if ShowAllAccounts then begin
                            PmtDiscountVisible := true;
                            PmtToleranceVisible := true;
                            InvRoundingVisible := true;
                            ApplnRoundingVisible := true;
                            InterestAccountVisible := true;
                            AddFeeAccountVisible := true;
                            AddFeePerLineAccountVisible := true;
                        end else begin
                            SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);
                            ReminderTerms.SetAccountVisibility(InterestAccountVisible, AddFeeAccountVisible, AddFeePerLineAccountVisible);
                            UpdateAccountVisibilityBasedOnFinChargeTerms(InterestAccountVisible, AddFeeAccountVisible);
                        end;

                        CurrPage.Update;
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier for the customer posting group. This is what you choose when you assign the group to an entity or document.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the customer posting group.';
                }
                field("View All Accounts on Lookup"; "View All Accounts on Lookup")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that all possible accounts are shown when you look up from a field. If the check box is not selected, then only accounts related to the involved account category are shown.';
                }
                field("Receivables Account"; "Receivables Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the general ledger account to use when you post receivables from customers in this posting group.';
                }
                field("Service Charge Acc."; "Service Charge Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post service charges for customers in this posting group.';
                }
                field("Payment Disc. Debit Acc."; "Payment Disc. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post payment discounts granted to customers in this posting group.';
                    Visible = PmtDiscountVisible;
                }
                field("Payment Disc. Credit Acc."; "Payment Disc. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post reductions in payment discounts granted to customers in this posting group.';
                    Visible = PmtDiscountVisible;
                }
                field("Interest Account"; "Interest Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post interest from reminders and finance charge memos for customers in this posting group.';
                    Visible = InterestAccountVisible;
                }
                field("Additional Fee Account"; "Additional Fee Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post additional fees from reminders and finance charge memos for customers in this posting group.';
                    Visible = AddFeeAccountVisible;
                }
                field("Add. Fee per Line Account"; "Add. Fee per Line Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account that additional fees are posted to.';
                    Visible = AddFeePerLineAccountVisible;
                }
                field("Invoice Rounding Account"; "Invoice Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post amounts that result from invoice rounding when you post transactions for customers.';
                    Visible = InvRoundingVisible;
                }
                field("Debit Curr. Appln. Rndg. Acc."; "Debit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                    Visible = ApplnRoundingVisible;
                }
                field("Credit Curr. Appln. Rndg. Acc."; "Credit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                    Visible = ApplnRoundingVisible;
                }
                field("Debit Rounding Account"; "Debit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post rounding differences from a remaining amount.';
                }
                field("Credit Rounding Account"; "Credit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post rounding differences from a remaining amount.';
                }
                field("Payment Tolerance Debit Acc."; "Payment Tolerance Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post payment tolerance and payments for sales. This applies to this particular combination of business group and product group.';
                    Visible = PmtToleranceVisible;
                }
                field("Payment Tolerance Credit Acc."; "Payment Tolerance Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post payment tolerance and payments for sales. This applies to this particular combination of business group and product group.';
                    Visible = PmtToleranceVisible;
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
    }

    trigger OnOpenPage()
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);
        ReminderTerms.SetAccountVisibility(InterestAccountVisible, AddFeeAccountVisible, AddFeePerLineAccountVisible);
        UpdateAccountVisibilityBasedOnFinChargeTerms(InterestAccountVisible, AddFeeAccountVisible);
    end;

    var
        PmtDiscountVisible: Boolean;
        PmtToleranceVisible: Boolean;
        InvRoundingVisible: Boolean;
        ApplnRoundingVisible: Boolean;
        InterestAccountVisible: Boolean;
        AddFeeAccountVisible: Boolean;
        AddFeePerLineAccountVisible: Boolean;
        ShowAllAccounts: Boolean;

    local procedure UpdateAccountVisibilityBasedOnFinChargeTerms(var InterestAccountVisible: Boolean; var AddFeeAccountVisible: Boolean)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FinanceChargeTerms.SetRange("Post Interest", true);
        InterestAccountVisible := InterestAccountVisible or not FinanceChargeTerms.IsEmpty;

        FinanceChargeTerms.SetRange("Post Interest");
        FinanceChargeTerms.SetRange("Post Additional Fee", true);
        AddFeeAccountVisible := AddFeeAccountVisible or not FinanceChargeTerms.IsEmpty;
    end;
}

