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
                    if GlobalRecordID.TableNo <> 0 then
                        MainRecordRef := GlobalRecordID.GetRecord
                    else begin
                        if GlobalDocumentNo <> '' then
                            IncomingDocumentAttachment.SetRange("Document No.", GlobalDocumentNo);

                        if GlobalPostingDate <> 0D then
                            IncomingDocumentAttachment.SetRange("Posting Date", GlobalPostingDate);

                    end;

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

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if LoadedDataFromRecord then
            exit(FindFirst());

        if not FilterWasChanged() then
            exit(true);

        PreviousViewFilter := GetView();
        exit(LoadDataFromOnFindRecord());
    end;

    var
        MainRecordRef: RecordRef;
        GlobalRecordID: RecordID;
        StyleExpressionTxt: Text;
        CreateMainDocumentFirstErr: Label 'You must fill in any field to create a main record before you try to attach a document. Refresh the page and try again.';
        LoadedDataFromRecord: Boolean;
        PreviousViewFilter: text;
        GlobalDocumentNo: text;
        GlobalPostingDate: Date;

    procedure LoadDataFromOnFindRecord(): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentFound: Boolean;
        CurrentFilterGroup: Integer;
    begin
        CurrentFilterGroup := FilterGroup();
        FilterGroup(4);
        IncomingDocumentFound := FindIncomingDocumentFromFilters(IncomingDocument);
        GlobalDocumentNo := GetFilter("Document No.");
        Clear(GlobalPostingDate);
        if GetFilter("Posting Date") <> '' then
            if Evaluate(GlobalPostingDate, GetFilter("Posting Date")) then;

        FilterGroup(CurrentFilterGroup);

        Reset();
        DeleteAll();

        if not IncomingDocumentFound then
            exit(false);

        InsertFromIncomingDocument(IncomingDocument, Rec);
        exit(true);
    end;

    local procedure FindIncomingDocumentFromFilters(var IncomingDocument: Record "Incoming Document"): Boolean
    var
        IncomingDocumentEntryNo: Text;
    begin
        IncomingDocumentEntryNo := GetFilter("Incoming Document Entry No.");
        if IncomingDocumentEntryNo <> '' then
            exit(IncomingDocument.Get(IncomingDocumentEntryNo));

        exit(IncomingDocument.FindByDocumentNoAndPostingDate(IncomingDocument, GetFilter("Document No."), GetFilter("Posting Date")));
    end;

    local procedure FilterWasChanged(): Boolean
    var
        CurrentFilterGroup: Integer;
        CurrentViewFilter: Text;
    begin
        CurrentFilterGroup := FilterGroup();
        FilterGroup(4);
        CurrentViewFilter := GetView();
        FilterGroup(CurrentFilterGroup);
        exit(PreviousViewFilter <> CurrentViewFilter);
    end;

    procedure LoadDataFromRecord(MainRecordVariant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        LoadedDataFromRecord := true;

        if not DataTypeManagement.GetRecordRef(MainRecordVariant, MainRecordRef) then
            exit;

        DeleteAll();

        if not MainRecordRef.Get(MainRecordRef.RecordId) then
            exit;

        if GetIncomingDocumentRecord(MainRecordVariant, IncomingDocument) then
            InsertFromIncomingDocument(IncomingDocument, Rec);

        OnAfterLoadDataFromRecord(MainRecordRef);
        CurrPage.Update(false);
    end;

    procedure SetCurrentRecordID(NewRecordID: RecordID)
    begin
        if GlobalRecordID = NewRecordID then
            exit;

        GlobalRecordID := NewRecordID;
    end;

    procedure LoadDataFromIncomingDocument(IncomingDocument: Record "Incoming Document")
    begin
        DeleteAll();
        InsertFromIncomingDocument(IncomingDocument, Rec);
        CurrPage.Update(false);
    end;

    procedure GetIncomingDocumentRecord(MainRecordVariant: Variant; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        if not DataTypeManagement.GetRecordRef(MainRecordVariant, MainRecordRef) then
            exit(false);

        if MainRecordRef.Number = DATABASE::"Incoming Document" then begin
            IncomingDocument.Copy(MainRecordVariant);
            exit(true);
        end;

        exit(GetIncomingDocumentRecordFromRecordRef(IncomingDocument, MainRecordRef));
    end;

    local procedure GetIncomingDocumentRecordFromRecordRef(var IncomingDocument: Record "Incoming Document"; MainRecordRef: RecordRef): Boolean
    begin
        if IncomingDocument.FindFromIncomingDocumentEntryNo(MainRecordRef, IncomingDocument) then
            exit(true);
        if IncomingDocument.FindByDocumentNoAndPostingDate(MainRecordRef, IncomingDocument) then
            exit(true);
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLoadDataFromRecord(var MainRecordRef: RecordRef)
    begin
    end;
}