table 560 "VAT Clause"
{
    Caption = 'VAT Clause';
    DrillDownPageID = "VAT Clauses";
    LookupPageID = "VAT Clauses";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Description 2"; Text[250])
        {
            Caption = 'Description 2';
        }
        field(10; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATClauseTranslation: Record "VAT Clause Translation";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATClauseTranslation.SetRange("VAT Clause Code", Code);
        VATClauseTranslation.DeleteAll();

        VATPostingSetup.SetRange("VAT Clause Code", Code);
        VATPostingSetup.ModifyAll("VAT Clause Code", '');
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime;
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;

    procedure TranslateDescription(Language: Code[10])
    var
        VATClauseTranslation: Record "VAT Clause Translation";
    begin
        if VATClauseTranslation.Get(Code, Language) then
            FillDescriptions(VATClauseTranslation.Description, VATClauseTranslation."Description 2");
    end;

    local procedure TryFindDescriptionByDocumentType(DocumentType: Enum "VAT Clause Document Type"; LanguageCode: Code[10]): Boolean
    var
        VATClauseByDocType: Record "VAT Clause by Doc. Type";
        VATClauseByDocTypeTrans: Record "VAT Clause by Doc. Type Trans.";
    begin
        if VATClauseByDocTypeTrans.get(Code, DocumentType, LanguageCode) then begin
            FillDescriptions(VATClauseByDocTypeTrans.Description, VATClauseByDocTypeTrans."Description 2");
            exit(true);
        end;

        if VATClauseByDocType.get(Code, DocumentType) then begin
            FillDescriptions(VATClauseByDocType.Description, VATClauseByDocType."Description 2");
            exit(true);
        end;
    end;

    procedure GetDescription(RecRelatedVariant: Variant)
    var
        DocumentType: Enum "VAT Clause Document Type";
        LanguageCode: Code[10];
    begin
        if not GetDocumentTypeAndLanguageCode(RecRelatedVariant, DocumentType, LanguageCode) then
            exit;

        if not TryFindDescriptionByDocumentType(DocumentType, LanguageCode) then
            TranslateDescription(LanguageCode);

        OnAfterGetDescription(Rec, DocumentType, LanguageCode)
    end;

    local procedure GetDocumentTypeAndLanguageCode(RecRelatedVariant: Variant; var DocumentType: Enum "VAT Clause Document Type"; var LanguageCode: Code[10]): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        RecRef: RecordRef;
        DataTypeManagement: Codeunit "Data Type Management";
        IsHandled: Boolean;
    begin
        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecRef) then
            exit(false);

        case RecRef.Number of
            database::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    if SalesHeader."Document Type" in [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"] then
                        DocumentType := DocumentType::"Credit Memo"
                    else
                        DocumentType := DocumentType::Invoice;
                    LanguageCode := SalesHeader."Language Code";
                    exit(true);
                end;
            database::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    DocumentType := DocumentType::Invoice;
                    LanguageCode := SalesInvoiceHeader."Language Code";
                    exit(true);
                end;
            database::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    DocumentType := DocumentType::"Credit Memo";
                    LanguageCode := SalesCrMemoHeader."Language Code";
                    exit(true);
                end;
            database::"Issued Fin. Charge Memo Header":
                begin
                    RecRef.SetTable(IssuedFinChargeMemoHeader);
                    DocumentType := DocumentType::"Finance Charge Memo";
                    LanguageCode := IssuedFinChargeMemoHeader."Language Code";
                    exit(true);
                end;
            database::"Issued Reminder Header":
                begin
                    RecRef.SetTable(IssuedReminderHeader);
                    DocumentType := DocumentType::Reminder;
                    LanguageCode := IssuedReminderHeader."Language Code";
                    exit(true);
                end;
            else begin
                    IsHandled := false;
                    OnGetDocumentTypeAndLanguageCode(Rec, RecRelatedVariant, DocumentType, LanguageCode, IsHandled);
                    exit(IsHandled);
                end;
        end;
    end;

    local procedure FillDescriptions(NewDescription: Text[250]; NewDescription2: Text[250])
    begin
        if NewDescription <> '' then
            Description := NewDescription;
        if NewDescription2 <> '' then
            "Description 2" := NewDescription2;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDescription(var VATClause: Record "VAT Clause"; DocumentType: Enum "VAT Clause Document Type"; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentTypeAndLanguageCode(VATClause: Record "VAT Clause"; RecRelatedVariant: Variant; var DocumentType: Enum "VAT Clause Document Type"; var LanguageCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

