page 20013 "APIV1 - Cust. Paym. Journals"
{
    APIVersion = 'v1.0';
    Caption = 'customerPaymentJournals', Locked = true;
    DelayedInsert = true;
    EntityName = 'customerPaymentJournal';
    EntitySetName = 'customerPaymentJournals';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Gen. Journal Batch";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field("code"; Name)
                {
                    ApplicationArea = All;
                    Caption = 'code', Locked = true;
                    ShowMandatory = true;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(lastModifiedDateTime; "Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                }
                field(balancingAccountId; BalAccountId)
                {
                    ApplicationArea = All;
                    Caption = 'balancingAccountId', Locked = true;
                }
                field(balancingAccountNumber; "Bal. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'balancingAccountNumber', Locked = true;
                    Editable = false;
                }
            }
            part(customerPayments; 5479)
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
        "Journal Template Name" := GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName();
    end;

    trigger OnOpenPage()
    begin
        SETRANGE("Journal Template Name", GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName());
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
}


