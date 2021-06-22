page 193 "Incoming Doc. Attach. FactBox"
{
    Caption = 'Incoming Document Files';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Inc. Doc. Attachment Overview";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Indentation;
                IndentationControls = Name;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleExpressionTxt;
                    ToolTip = 'Specifies the name of the attached file.';

                    trigger OnDrillDown()
                    begin
                        NameDrillDown;
                    end;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the attached file.';
                }
                field("Created Date-Time"; "Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the incoming document line was created.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Export)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View File';
                Image = Document;
                Scope = Repeater;
                ToolTip = 'View the file that is attached to the incoming document record.';
                Visible = false;

                trigger OnAction()
                begin
                    NameDrillDown;
                end;
            }
            action(ImportNew)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attach File';
                Image = Attach;
                ToolTip = 'Attach a file to the incoming document record.';

                trigger OnAction()
                var
                    IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    IncomingDocument: Record "Incoming Document";
                begin
                    IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Incoming Document Entry No.");
                    IncomingDocumentAttachment.SetFiltersFromMainRecord(MainRecordRef, IncomingDocumentAttachment);

                    // check MainRecordRef is initialized
                    if MainRecordRef.Number <> 0 then
                        if not MainRecordRef.Get(MainRecordRef.RecordId) then
                            Error(CreateMainDocumentFirstErr);

                    if IncomingDocumentAttachment.Import then
                        if IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.") then
                            LoadDataFromIncomingDocument(IncomingDocument);
                end;
            }
            action(IncomingDoc)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Incoming Document';
                Image = Document;
                Scope = Repeater;
                ToolTip = 'View or create an incoming document record that is linked to the entry or document.';

                trigger OnAction()
                var
                    IncomingDocument: Record "Incoming Document";
                begin
                    if not IncomingDocument.Get("Incoming Document Entry No.") then
                        exit;
                    PAGE.RunModal(PAGE::"Incoming Document", IncomingDocument);

                    if IncomingDocument.Get(IncomingDocument."Entry No.") then
                        LoadDataFromIncomingDocument(IncomingDocument);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleExpressionTxt := GetStyleTxt;
    end;

    var
        MainRecordRef: RecordRef;
        StyleExpressionTxt: Text;
        CreateMainDocumentFirstErr: Label 'You must fill in any field to create a main record before you try to attach a document. Refresh the page and try again.';

    procedure LoadDataFromRecord(MainRecordVariant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        if not DataTypeManagement.GetRecordRef(MainRecordVariant, MainRecordRef) then
            exit;

        DeleteAll;

        if not MainRecordRef.Get(MainRecordRef.RecordId) then
            exit;

        if GetIncomingDocumentRecord(MainRecordVariant, IncomingDocument) then
            InsertFromIncomingDocument(IncomingDocument, Rec);

        OnAfterLoadDataFromRecord(MainRecordRef);

        CurrPage.Update(false);
    end;

    procedure LoadDataFromIncomingDocument(IncomingDocument: Record "Incoming Document")
    begin
        DeleteAll;
        InsertFromIncomingDocument(IncomingDocument, Rec);
        CurrPage.Update(false);
    end;

    procedure GetIncomingDocumentRecord(MainRecordVariant: Variant; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        if not DataTypeManagement.GetRecordRef(MainRecordVariant, MainRecordRef) then
            exit(false);

        case MainRecordRef.Number of
            DATABASE::"Incoming Document":
                begin
                    IncomingDocument.Copy(MainRecordVariant);
                    exit(true);
                end;
            else begin
                    if IncomingDocument.FindFromIncomingDocumentEntryNo(MainRecordRef, IncomingDocument) then
                        exit(true);
                    if IncomingDocument.FindByDocumentNoAndPostingDate(MainRecordRef, IncomingDocument) then
                        exit(true);
                    exit(false);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLoadDataFromRecord(var MainRecordRef: RecordRef)
    begin
    end;
}

