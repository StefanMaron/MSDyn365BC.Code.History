page 5478 "Journal Lines Entity"
{
    Caption = 'journalLines', Locked = true;
    DelayedInsert = true;
    EntityName = 'journalLine';
    EntitySetName = 'journalLines';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field(journalDisplayName; GlobalJournalDisplayNameTxt)
                {
                    ApplicationArea = All;
                    Caption = 'JournalDisplayName', Locked = true;
                    ToolTip = 'Specifies the Journal Batch Name of the Journal Line';

                    trigger OnValidate()
                    begin
                        Error(CannotEditBatchNameErr);
                    end;
                }
                field(lineNumber; "Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'LineNumber', Locked = true;
                }
                field(accountId; "Account Id")
                {
                    ApplicationArea = All;
                    Caption = 'AccountId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Account Id" = BlankGUID then begin
                            "Account No." := '';
                            exit;
                        end;

                        GLAccount.SetRange(Id, "Account Id");
                        if not GLAccount.FindFirst then
                            Error(AccountIdDoesNotMatchAnAccountErr);

                        "Account No." := GLAccount."No.";
                    end;
                }
                field(accountNumber; "Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'AccountNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        if GLAccount."No." <> '' then begin
                            if GLAccount."No." <> "Account No." then
                                Error(AccountValuesDontMatchErr);
                            exit;
                        end;

                        if "Account No." = '' then begin
                            "Account Id" := BlankGUID;
                            exit;
                        end;

                        if not GLAccount.Get("Account No.") then
                            Error(AccountNumberDoesNotMatchAnAccountErr);

                        "Account Id" := GLAccount.Id;
                    end;
                }
                field(postingDate; "Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'PostingDate', Locked = true;
                }
                field(documentNumber; "Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'DocumentNumber', Locked = true;
                }
                field(externalDocumentNumber; "External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'ExternalDocumentNumber', Locked = true;
                }
                field(amount; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(comment; Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment', Locked = true;
                }
                field(dimensions; DimensionsJSON)
                {
                    ApplicationArea = All;
                    Caption = 'Dimensions', Locked = true;
                    ODataEDMType = 'Collection(DIMENSION)';
                    ToolTip = 'Specifies Journal Line Dimensions.';

                    trigger OnValidate()
                    begin
                        DimensionsSet := PreviousDimensionsJSON <> DimensionsJSON;
                    end;
                }
                field(lastModifiedDateTime; "Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if not FiltersChecked then begin
            CheckFilters;
            FiltersChecked := true;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
    begin
        TempGenJournalLine.Reset();
        TempGenJournalLine.Copy(Rec);

        Clear(Rec);
        GraphMgtJournalLines.SetJournalLineTemplateAndBatch(
          Rec, LibraryAPIGeneralJournal.GetBatchNameFromId(TempGenJournalLine.GetFilter("Journal Batch Id")));
        LibraryAPIGeneralJournal.InitializeLine(
          Rec, TempGenJournalLine."Line No.", TempGenJournalLine."Document No.", TempGenJournalLine."External Document No.");

        GraphMgtJournalLines.SetJournalLineValues(Rec, TempGenJournalLine);

        UpdateDimensions(false);
        SetCalculatedFields;
    end;

    trigger OnModifyRecord(): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.GetBySystemId(SystemId);

        if "Line No." = GenJournalLine."Line No." then
            Modify(true)
        else begin
            GenJournalLine.TransferFields(Rec, false);
            GenJournalLine.Rename("Journal Template Name", "Journal Batch Name", "Line No.");
            TransferFields(GenJournalLine, true);
        end;

        UpdateDimensions(true);
        SetCalculatedFields;

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CheckFilters;

        ClearCalculatedFields;

        "Document Type" := "Document Type"::" ";
        "Account Type" := "Account Type"::"G/L Account";
    end;

    trigger OnOpenPage()
    begin
        GraphMgtJournalLines.SetJournalLineFilters(Rec);
    end;

    var
        GLAccount: Record "G/L Account";
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
        LibraryAPIGeneralJournal: Codeunit "Library API - General Journal";
        FiltersNotSpecifiedErr: Label 'You must specify a journal batch ID or a journal ID to get a journal line.', Locked = true;
        CannotEditBatchNameErr: Label 'The Journal Batch Display Name isn''t editable.', Locked = true;
        AccountValuesDontMatchErr: Label 'The account values do not match to a specific Account.', Locked = true;
        AccountIdDoesNotMatchAnAccountErr: Label 'The "accountId" does not match to an Account.', Locked = true;
        AccountNumberDoesNotMatchAnAccountErr: Label 'The "accountNumber" does not match to an Account.', Locked = true;
        DimensionsJSON: Text;
        PreviousDimensionsJSON: Text;
        GlobalJournalDisplayNameTxt: Code[10];
        FiltersChecked: Boolean;
        DimensionsSet: Boolean;
        BlankGUID: Guid;

    local procedure SetCalculatedFields()
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GlobalJournalDisplayNameTxt := "Journal Batch Name";
        DimensionsJSON := GraphMgtComplexTypes.GetDimensionsJSON("Dimension Set ID");
        PreviousDimensionsJSON := DimensionsJSON;
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(GlobalJournalDisplayNameTxt);
        Clear(DimensionsJSON);
        Clear(PreviousDimensionsJSON);
        Clear(DimensionsSet);
    end;

    local procedure CheckFilters()
    begin
        if (GetFilter("Journal Batch Id") = '') and
           (GetFilter(SystemId) = '')
        then
            Error(FiltersNotSpecifiedErr);
    end;

    local procedure UpdateDimensions(LineExists: Boolean)
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        DimensionManagement: Codeunit DimensionManagement;
        NewDimensionSetId: Integer;
    begin
        if not DimensionsSet then
            exit;

        GraphMgtComplexTypes.GetDimensionSetFromJSON(DimensionsJSON, "Dimension Set ID", NewDimensionSetId);
        if "Dimension Set ID" <> NewDimensionSetId then begin
            "Dimension Set ID" := NewDimensionSetId;
            DimensionManagement.UpdateGlobalDimFromDimSetID(NewDimensionSetId, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if LineExists then
                Modify;
        end;
    end;
}

