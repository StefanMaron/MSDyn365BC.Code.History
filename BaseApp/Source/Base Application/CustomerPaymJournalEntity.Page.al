#if not CLEAN18
page 5477 "Customer Paym. Journal Entity"
{
    Caption = 'customerPaymentJournals', Locked = true;
    DelayedInsert = true;
    EntityName = 'customerPaymentJournal';
    EntitySetName = 'customerPaymentJournals';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Gen. Journal Batch";
    ObsoleteState = Pending;
    ObsoleteReason = 'API version beta will be deprecated.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
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
                SubPageLink = "Journal Batch Id" = FIELD(SystemId);
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
#endif
