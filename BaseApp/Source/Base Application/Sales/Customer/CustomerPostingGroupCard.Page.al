namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Reminder;

page 148 "Customer Posting Group Card"
{
    Caption = 'Customer Posting Group Card';
    PageType = Card;
    SourceTable = "Customer Posting Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier for the customer posting group. This is what you choose when you assign the group to an entity or document.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the customer posting group.';
                }
                field("Receivables Account"; Rec."Receivables Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the general ledger account to use when you post receivables from customers in this posting group.';
                }
                field("Service Charge Acc."; Rec."Service Charge Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post service charges for customers in this posting group.';
                }
                group(Discounts)
                {
                    Caption = 'Discounts';
                    field("Payment Disc. Debit Acc."; Rec."Payment Disc. Debit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post payment discounts granted to customers in this posting group.';
                        Visible = PmtDiscountVisible;
                    }
                    field("Payment Disc. Credit Acc."; Rec."Payment Disc. Credit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post reductions in payment discounts granted to customers in this posting group.';
                        Visible = PmtDiscountVisible;
                    }
                    field("Payment Tolerance Debit Acc."; Rec."Payment Tolerance Debit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post payment tolerance and payments for sales. This applies to this particular combination of business group and product group.';
                        Visible = PmtToleranceVisible;
                    }
                    field("Payment Tolerance Credit Acc."; Rec."Payment Tolerance Credit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post payment tolerance and payments for sales. This applies to this particular combination of business group and product group.';
                        Visible = PmtToleranceVisible;
                    }
                }
                group(Rounding)
                {
                    Caption = 'Rounding';
                    field("Invoice Rounding Account"; Rec."Invoice Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post amounts that result from invoice rounding when you post transactions for customers.';
                        Visible = InvRoundingVisible;
                    }
                    field("Debit Rounding Account"; Rec."Debit Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post rounding differences from a remaining amount.';
                    }
                    field("Credit Rounding Account"; Rec."Credit Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post rounding differences from a remaining amount.';
                    }
                    field("Debit Curr. Appln. Rndg. Acc."; Rec."Debit Curr. Appln. Rndg. Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                        Visible = ApplnRoundingVisible;
                    }
                    field("Credit Curr. Appln. Rndg. Acc."; Rec."Credit Curr. Appln. Rndg. Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                        Visible = ApplnRoundingVisible;
                    }
                }
                group(Reminders)
                {
                    Caption = 'Reminders';
                    field("Interest Account"; Rec."Interest Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post interest from reminders and finance charge memos for customers in this posting group.';
                        Visible = InterestAccountVisible;
                    }
                    field("Additional Fee Account"; Rec."Additional Fee Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post additional fees from reminders and finance charge memos for customers in this posting group.';
                        Visible = AddFeeAccountVisible;
                    }
                    field("Add. Fee per Line Account"; Rec."Add. Fee per Line Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account that additional fees are posted to.';
                        Visible = AddFeePerLineAccountVisible;
                    }
                }
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
        Rec.SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);
        ReminderTerms.SetAccountVisibility(InterestAccountVisible, AddFeeAccountVisible, AddFeePerLineAccountVisible);
    end;

    var
        PmtDiscountVisible: Boolean;
        PmtToleranceVisible: Boolean;
        InvRoundingVisible: Boolean;
        ApplnRoundingVisible: Boolean;
        InterestAccountVisible: Boolean;
        AddFeeAccountVisible: Boolean;
        AddFeePerLineAccountVisible: Boolean;
}

