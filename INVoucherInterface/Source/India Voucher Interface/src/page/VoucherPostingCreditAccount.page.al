page 18933 "Voucher Posting Credit Account"
{
    Caption = 'Voucher Posting Credit Accounts';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Voucher Posting Credit Account";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Type"; "Account Type")
                {
                    Caption = 'Type';
                    ApplicationArea = Basic, Suite;
                }
                field("Account No."; "Account No.")
                {
                    Caption = 'Account No.';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if ("Type" = "Type"::"Cash Receipt Voucher") or ("Type" = "Type"::"Cash Payment Voucher") then
            "Account Type" := "Account Type"::"G/L Account";
        if ("Type" = "Type"::"Bank Receipt Voucher") or ("Type" = "Type"::"Bank Payment Voucher") then
            "Account Type" := "Account Type"::"Bank Account";
    end;
}