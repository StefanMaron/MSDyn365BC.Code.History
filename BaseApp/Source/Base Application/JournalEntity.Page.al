page 5482 "Journal Entity"
{
    Caption = 'journals', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'journal';
    EntitySetName = 'journals';
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
            part(journalLines; "Journal Lines Entity")
            {
                ApplicationArea = All;
                Caption = 'JournalLines', Locked = true;
                EntityName = 'journalLine';
                EntitySetName = 'journalLines';
                SubPageLink = "Journal Batch Id" = FIELD(Id);
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Journal Template Name" := GraphMgtJournal.GetDefaultJournalLinesTemplateName;
    end;

    trigger OnOpenPage()
    begin
        SetRange("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName);
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
        ThereIsNothingToPostErr: Label 'There is nothing to post.';
        CannotFindBatchErr: Label 'The General Journal Batch with ID %1 cannot be found.', Comment = '%1 - the ID of the general journal batch';

    [ServiceEnabled]
    procedure post(var ActionContext: DotNet WebServiceActionContext)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GetBatch(GenJournalBatch);
        PostBatch(GenJournalBatch);
        SetActionResponse(ActionContext, Id);
    end;

    local procedure PostBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if not GenJournalLine.FindFirst then
            Error(ThereIsNothingToPostErr);

        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLine);
    end;

    local procedure GetBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalBatch.SetRange(Id, Id);
        if not GenJournalBatch.FindFirst then
            Error(StrSubstNo(CannotFindBatchErr, Id));
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext; GenJournalBatchId: Guid)
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(FieldNo(Id), GenJournalBatchId);
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Journal Entity");
    end;
}

