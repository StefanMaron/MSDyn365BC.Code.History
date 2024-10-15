page 12183 "Bill Posting Group"
{
    Caption = 'Bill Posting Group';
    DataCaptionFields = "No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bill Posting Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Payment Method"; "Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method codes that can be applied to customer bills.';
                }
                field("Bills For Collection Acc. No."; "Bills For Collection Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post bills for collection.';
                }
                field("Bills For Discount Acc. No."; "Bills For Discount Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post bills for discount.';
                }
                field("Bills Subj. to Coll. Acc. No."; "Bills Subj. to Coll. Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post bills subject to collection.';
                }
                field("Expense Bill Account No."; "Expense Bill Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post bank expenses.';
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
        ITPaymentBillTok: Label 'IT Issue Vendor Payments and Customer Bills', Locked = true;
    begin
        FeatureTelemetry.LogUptake('1000HQ6', ITPaymentBillTok, Enum::"Feature Uptake Status"::Discovered);
    end;
}

