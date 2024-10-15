page 579 "Post Application"
{
    Caption = 'Post Application';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(JnlTemplateName; SelectGenJnlLine."Journal Template Name")
                {
                    ApplicationArea = BasicBE;
                    Caption = 'Journal Template Name';
                    TableRelation = "Gen. Journal Template";
                    ToolTip = 'Specifies the name of the journal template that is used for the posting.';

                    trigger OnValidate()
                    begin
                        SelectGenJnlLine."Journal Batch Name" := '';
                    end;
                }
                field(JnlBatchName; SelectGenJnlLine."Journal Batch Name")
                {
                    ApplicationArea = BasicBE;
                    Caption = 'Journal Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the name of the journal batch that is used for the posting.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        SelectGenJnlLine.TestField("Journal Template Name");
                        GenJournalTemplate.Get(SelectGenJnlLine."Journal Template Name");
                        GenJnlBatch.SetRange("Journal Template Name", SelectGenJnlLine."Journal Template Name");
                        GenJnlBatch."Journal Template Name" := SelectGenJnlLine."Journal Template Name";
                        GenJnlBatch.Name := SelectGenJnlLine."Journal Batch Name";
                        if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
                            SelectGenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                    end;

                    trigger OnValidate()
                    begin
                        if SelectGenJnlLine."Journal Batch Name" <> '' then begin
                            SelectGenJnlLine.TestField("Journal Template Name");
                            GenJnlBatch.Get(SelectGenJnlLine."Journal Template Name", SelectGenJnlLine."Journal Batch Name");
                        end;
                    end;
                }
                field(DocNo; DocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number of the entry to be applied.';
                }
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the entry to be applied.';
                }
            }
        }
    }

    actions
    {
    }

    var
        GenJournalTemplate: Record "Gen. Journal Template";
        SelectGenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
        PostingDate: Date;

    procedure SetValues(NewJnlTemplName: Code[10]; NewJnlBatchName: Code[10]; NewDocNo: Code[20]; NewPostingDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetValues(NewDocNo, NewPostingDate, IsHandled);
        if IsHandled then
            exit;

        SelectGenJnlLine."Journal Template Name" := NewJnlTemplName;
        SelectGenJnlLine."Journal Batch Name" := NewJnlBatchName;
        DocNo := NewDocNo;
        PostingDate := NewPostingDate;
    end;

    procedure GetValues(var NewJnlTemplName: Code[10]; var NewJnlBatchName: Code[10]; var NewDocNo: Code[20]; var NewPostingDate: Date)
    begin
        OnBeforeGetValues(NewDocNo, NewPostingDate);

        NewJnlTemplName := SelectGenJnlLine."Journal Template Name";
        NewJnlBatchName := SelectGenJnlLine."Journal Batch Name";
        NewDocNo := DocNo;
        NewPostingDate := PostingDate;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetValues(var NewDocNo: Code[20]; var NewPostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetValues(var NewDocNo: Code[20]; var NewPostingDate: Date)
    begin
    end;
}

