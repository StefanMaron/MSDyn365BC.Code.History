page 412 "Bank Rec. Line Match Details"
{
    Caption = 'Match Details';
    DataCaptionExpression = ' ';
    LinksAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Bank Acc. Reconciliation Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control7)
            {
                Caption = ' ';
                ShowCaption = false;
                field(MatchDetails; MatchDetails)
                {
                    Caption = ' ';
                    ShowCaption = false;
                    Editable = false;
                    Enabled = false;
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control8)
            {
                Caption = ' ';
                ShowCaption = false;
                part(ApplyBankLedgerEntries; "Applied Bank Acc. Ledger Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Ledger Entry';
                    SubPageLink = "Statement No." = FIELD("Statement No."),
                                  "Statement Line No." = FIELD("Statement Line No.");
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        PaymentMatchingDetails.SetRange("Statement Type", "Statement Type");
        PaymentMatchingDetails.SetRange("Statement No.", "Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", "Statement Line No.");
        PaymentMatchingDetails.SetRange("Bank Account No.", "Bank Account No.");
        PaymentMatchingDetails.SetFilter(Message, '<>''''');
        if PaymentMatchingDetails.FindLast() then
            MatchDetails := PaymentMatchingDetails.Message;
    end;

    var
        MatchDetails: Text;
}