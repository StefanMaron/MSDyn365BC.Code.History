page 5477 "Customer Paym. Journal Entity"
{
    Caption = 'customerPaymentJournals', Locked = true;
    DelayedInsert = true;
    EntityName = 'customerPaymentJournal';
    EntitySetName = 'customerPaymentJournals';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Gen. Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field("code"; Name)
                {
                    ApplicationArea = All;
                    Caption = 'code', Locked = true;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;
                }
                field(lastModifiedDateTime; "Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
                field(balancingAccountId; BalAccountId)
                {
                    ApplicationArea = All;
                    Caption = 'BalancingAccountId', Locked = true;
                }
                field(balancingAccountNumber; "Bal. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'BalancingAccountNumber', Locked = true;
                    Editable = false;
                }
            }
            part(customerPayments; "Customer Payments Entity")
            {
                ApplicationArea = All;
                Caption = 'customerPayments', Locked = true;
                EntityName = 'customerPayment';
                EntitySetName = 'customerPayments';
                SubPageLink = "Journal Batch Id" = FIELD(Id);
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Journal Template Name" := GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName;
    end;

    trigger OnOpenPage()
    begin
        SetRange("Journal Template Name", GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName);
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
}

