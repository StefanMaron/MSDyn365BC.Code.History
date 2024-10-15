report 32000005 Payment
{
    DefaultLayout = RDLC;
    RDLCLayout = './Payment.rdlc';
    Caption = 'Payment';

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(No_BankAccount; "No.")
            {
            }
            column(Name_BankAccount; Name)
            {
            }
            column(BankAccNo_BankAccount; "Bank Account No.")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BankPaymentsCaption; BankPaymentsCaptionLbl)
            {
            }
            column(NoCaption_BankAccount; FieldCaption("No."))
            {
            }
            column(NameCaption_BankAccount; FieldCaption(Name))
            {
            }
            column(BankAccNoCaption_BankAccount; FieldCaption("Bank Account No."))
            {
            }
            dataitem("Ref. Payment - Exported"; "Ref. Payment - Exported")
            {
                DataItemLink = "Payment Account" = FIELD("No.");
                DataItemTableView = SORTING("Payment Date", "Vendor No.", "Entry No.") ORDER(Ascending) WHERE(Transferred = CONST(false), "Applied Payments" = CONST(false));
                RequestFilterFields = "Vendor No.";
                column(PmtDate_RefPmtExported; "Payment Date")
                {
                }
                column(MsgType_RefPmtExported; "Message Type")
                {
                }
                column(InvMsg_RefPmtExported; "Invoice Message")
                {
                }
                column(VendNo_RefPmtExported; "Vendor No.")
                {
                }
                column(Desc_RefPmtExported; Description)
                {
                }
                column(DocNo_RefPmtExported; "Document No.")
                {
                }
                column(AmtLCY_RefPmtExported; "Amount (LCY)")
                {
                }
                column(Amt_RefPmtExported; Amount)
                {
                }
                column(CurrCode_RefPmtExported; "Currency Code")
                {
                }
                column(PmtDateCaption_RefPmtExported; FieldCaption("Payment Date"))
                {
                }
                column(VendNoCaption_RefPmtExported; FieldCaption("Vendor No."))
                {
                }
                column(DescCaption_RefPmtExported; FieldCaption(Description))
                {
                }
                column(MsgTypeCaption_RefPmtExported; FieldCaption("Message Type"))
                {
                }
                column(InvMsgCaption_RefPmtExported; FieldCaption("Invoice Message"))
                {
                }
                column(DocNoCaption_RefPmtExported; FieldCaption("Document No."))
                {
                }
                column(AmtCaption_RefPmtExported; FieldCaption(Amount))
                {
                }
                column(CurrencyCodeCaption_RefPmtExported; FieldCaption("Currency Code"))
                {
                }
                column(AmtLCYCaption_RefPmtExported; FieldCaption("Amount (LCY)"))
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(No_RefPmtExported; "No.")
                {
                }
                column(PmtAcc_RefPmtExported; "Payment Account")
                {
                }
                column(AffiliatedToLine_RefPmtExported; "Affiliated to Line")
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        PageCaptionLbl: Label 'Page';
        BankPaymentsCaptionLbl: Label 'Bank Payments';
        TotalCaptionLbl: Label 'Total';
}

