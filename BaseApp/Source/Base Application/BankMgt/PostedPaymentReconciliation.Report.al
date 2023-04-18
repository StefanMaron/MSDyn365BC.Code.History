report 1409 "Posted Payment Reconciliation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BankMgt/PostedPaymentReconciliation.rdlc';
    Caption = 'Posted Payment Reconciliation';

    dataset
    {
        dataitem("Posted Payment Recon. Hdr"; "Posted Payment Recon. Hdr")
        {
            DataItemTableView = SORTING("Bank Account No.", "Statement No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(ComanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PostedPaymentReconciliationTableCaptFltr; TableCaption + ': ' + PostedPaymentReconciliationFilter)
            {
            }
            column(PostedPaymentReconciliationFilter; PostedPaymentReconciliationFilter)
            {
            }
            column(StmtNo_PostedPaymentReconciliation; "Statement No.")
            {
                IncludeCaption = true;
            }
            column(Amt_PostedPaymentReconciliationLineStmt; "Posted Payment Recon. Line"."Statement Amount")
            {
            }
            column(AppliedAmt_PostedPaymentReconciliationLine; "Posted Payment Recon. Line"."Applied Amount")
            {
            }
            column(BankAccNo_PostedPaymentReconciliation; "Bank Account No.")
            {
            }
            column(PostedPaymentReconciliationCapt; PostedPaymentReconciliationCaptLbl)
            {
            }
            column(CurrReportPAGENOCapt; CurrReportPAGENOCaptLbl)
            {
            }
            column(PostedPaymentReconciliationLinTrstnDteCapt; PostedPaymentReconciliationLinTrstnDteCaptLbl)
            {
            }
            column(BnkAcStmtLinValDteCapt; BnkAcStmtLinValDteCaptLbl)
            {
            }
            dataitem("Posted Payment Recon. Line"; "Posted Payment Recon. Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Statement Line No.");
                column(TrnsctnDte_BnkAcStmtLin; Format("Transaction Date"))
                {
                }
                column(Type_PostedPaymentReconciliationLine; Type)
                {
                    IncludeCaption = true;
                }
                column(LineDocNo_PostedPaymentReconciliation; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(AppliedEntr_PostedPaymentReconciliationLine; "Applied Entries")
                {
                    IncludeCaption = true;
                }
                column(Amt1_PostedPaymentReconciliationLineStmt; "Statement Amount")
                {
                    IncludeCaption = true;
                }
                column(AppliedAmt1_PostedPaymentReconciliationLine; "Applied Amount")
                {
                    IncludeCaption = true;
                }
                column(Desc_PostedPaymentReconciliationLine; Description)
                {
                    IncludeCaption = true;
                }
                column(ValueDate_PostedPaymentReconciliationLine; Format("Value Date"))
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
        TotalCaption = 'Total';
    }

    trigger OnPreReport()
    begin
        PostedPaymentReconciliationFilter := "Posted Payment Recon. Hdr".GetFilters();
    end;

    var
        PostedPaymentReconciliationFilter: Text;
        PostedPaymentReconciliationCaptLbl: Label 'Posted Payment Reconciliation';
        CurrReportPAGENOCaptLbl: Label 'Page';
        PostedPaymentReconciliationLinTrstnDteCaptLbl: Label 'Transaction Date';
        BnkAcStmtLinValDteCaptLbl: Label 'Value Date';
}

