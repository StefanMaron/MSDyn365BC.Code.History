page 32000000 "Bank Reference File Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Reference File Setup';
    PageType = Card;
    SourceTable = "Reference File Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a bank account code for the reference file setup information.';
                }
                field("Inform. of Appl. Cr. Memos"; "Inform. of Appl. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the data of credit invoices applied to invoices to be relayed to the payee.';
                }
                field("Allow Comb. Domestic Pmts."; "Allow Comb. Domestic Pmts.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to combine all domestic payments into one recipient from one day for the same bank account.';
                    Visible = false;
                }
                field("Payment Journal Template"; "Payment Journal Template")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment journal template for the reference file setup information.';
                    Visible = false;
                }
                field("Payment Journal Batch"; "Payment Journal Batch")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payment journal batch for the reference setup information.';
                    Visible = false;
                }
            }
            group("Foreign Payments")
            {
                Caption = 'Foreign Payments';
                field("Due Date Handling"; "Due Date Handling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date processing applied to foreign payments.';
                }
                field("Default Service Fee Code"; "Default Service Fee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a foreign bank service fee code. For example, J = Payee pays foreign bank charges.';
                }
                field("Default Payment Method"; "Default Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method for foreign payments. For example, M = payment order.';
                }
                field("Exchange Rate Contract No."; "Exchange Rate Contract No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rate agreement number for a currency trade transaction with the bank.';
                }
                field("Allow Comb. Foreign Pmts."; "Allow Comb. Foreign Pmts.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to combine foreign payments into one recipient from one day for one bank account.';
                }
            }
            group(SEPA)
            {
                Caption = 'SEPA';
                field("Bank Party ID"; "Bank Party ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank party identifier for the Single Euro Payment Area (SEPA) payment file.';
                }
                field("File Name"; "File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full path of the Single Euro Payment Area (SEPA) payment file.';
                }
                field("Allow Comb. SEPA Pmts."; "Allow Comb. SEPA Pmts.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to combine SEPA payments into one receipt for one day for one bank account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FIBankTok: Label 'FI Electronic Banking', Locked = true;
    begin
        FeatureTelemetry.LogUptake('1000HN4', FIBankTok, Enum::"Feature Uptake Status"::Discovered);
    end;
}

