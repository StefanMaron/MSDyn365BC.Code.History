page 1876 "Integration Services Setup"
{
    Caption = 'Integration Services Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "API Entities Setup";

    layout
    {
        area(content)
        {
            group("Customer Payments Service")
            {
                field("Customer Payments Batch Name"; "Customer Payments Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Default Customer Payments Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the default customer payments batch name of the integration journal.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenJournalLine: Record "Gen. Journal Line";
                        GraphMgtCustomerPaymentsLines: Codeunit "Graph Mgt - Customer Payments";
                    begin
                        GraphMgtCustomerPaymentsLines.SetCustomerPaymentsFilters(GenJournalLine);

                        CurrPage.SaveRecord;
                        GenJnlManagement.LookupName("Customer Payments Batch Name", GenJournalLine);
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        SafeGet;
    end;

    var
        GenJnlManagement: Codeunit GenJnlManagement;
}

